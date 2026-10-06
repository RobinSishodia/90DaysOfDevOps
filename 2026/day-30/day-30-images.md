# Day 30 – Docker Images & Container Lifecycle

> Practice VM: Ubuntu 24.04, Docker 29.8.2. Registries are blocked (see Day 29), so I worked with my three locally built images: `robin/hello`, `robin/mini-web:1.0` (nginx stand-in) and `robin/ubuntu-mini:24.04`.

## Task 1: Images
```
$ docker pull nginx
Error response from daemon: ... registry-1.docker.io ... Forbidden

$ docker images
IMAGE                     ID             DISK USAGE   CONTENT SIZE
robin/hello:latest        b6a1a375da2d       2.13MB          665kB
robin/mini-web:1.0        4525a846bfb0       8.03MB         2.39MB
robin/ubuntu-mini:24.04   88abb824042b       14.7MB         4.52MB
```
**Size comparison:** I couldn't pull `ubuntu` and `alpine` here. Their published sizes are roughly **~78 MB for `ubuntu:24.04`** and **~8 MB for `alpine`**. Alpine is about 10× smaller because it uses **musl + BusyBox** instead of glibc + GNU coreutils + apt. My own images show the same idea: a `FROM scratch` Go binary is **2 MB**, and a minimal Ubuntu rootfs with ~20 commands is **15 MB**. *Smaller image = faster pulls, fewer CVEs to patch.*

**Inspect:**
```
$ docker image inspect robin/mini-web:1.0 --format '...'
ID=sha256:4525a846bfb07d829ee9b7647011d2212d49d8244f1553e316ef70bfe259cac9
Arch=amd64/linux
Entrypoint=[/mini-web]
Env=[PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin WEB_ROOT=/www PORT=80]
ExposedPorts=map[80/tcp:map[]]
Labels=map[description:mini-web: static web server, nginx stand-in maintainer:Robin Sishodia]
```
**Tag and remove:**
```
$ docker tag robin/hello:latest robin/hello:old && docker images robin/hello
robin/hello:latest   b6a1a375da2d   2.13MB
robin/hello:old      b6a1a375da2d   2.13MB     ← same ID: a tag is just another name
$ docker rmi robin/hello:old
Untagged: robin/hello:old                       ← only the name was removed; the image stays
```

## Task 2: Layers
```
$ docker image history robin/mini-web:1.0
IMAGE          CREATED BY                                      SIZE
4525a846bfb0   ENTRYPOINT ["/mini-web"]                        0B
<missing>      EXPOSE [80/tcp]                                 0B
<missing>      COPY index.html /www/index.html # buildkit      12.3kB
<missing>      COPY mini-web /mini-web # buildkit              5.62MB
<missing>      ENV WEB_ROOT=/www PORT=80                       0B
<missing>      LABEL maintainer=Robin Sishodia description=…   0B

$ docker image history robin/ubuntu-mini:24.04
IMAGE          CREATED BY   SIZE      COMMENT
88abb824042b                10.2MB    Ubuntu-mini rootfs built from host binaries   ← docker import = ONE layer
```
- **Each Dockerfile instruction = one layer.** Only `COPY`/`RUN`/`ADD` add files and **size**. `ENV`, `LABEL`, `EXPOSE` and `ENTRYPOINT` are **0 B metadata** layers.
- **`<missing>`** isn't an error. Those intermediate layers simply don't have their own image ID with BuildKit.
- **Why layers matter (caching):** layers are cached and shared. Rebuilding with no changes reused every layer (no new image was created, see Task 5). That's why you put rarely-changing steps (installing dependencies) **before** frequently-changing ones (`COPY . .`).

## Task 3: Lifecycle of ONE container
```
$ docker create --name life -p 8090:80 robin/mini-web:1.0      → life: Created
$ docker start life                                             → life: Up Less than a second
$ docker pause life                                             → life: Up (Paused)
$ curl -m 2 http://localhost:8090/                              → HTTP 000 (request timed out while paused)
$ docker unpause life                                           → life: Up 2 seconds
$ curl http://localhost:8090/                                   → HTTP 200
$ docker stop life                                              → life: Exited (2)
$ docker restart life                                           → life: Up Less than a second
$ docker kill life                                              → life: Exited (137)
$ docker rm life                                                → (life is gone)
```
```
Created ─start─► Running ─pause─► Paused ─unpause─► Running ─stop─► Exited ─restart─► Running ─kill─► Exited ─rm─► (deleted)
```
- **pause** freezes the process (cgroup freezer). It still "exists", but requests hang: `HTTP 000`.
- **stop** = SIGTERM (then SIGKILL after 10 s). **kill** = SIGKILL immediately → exit code **137** (128 + 9).
- My Go server exits with code **2** on SIGTERM, because it has no graceful-shutdown handler. A production app should catch SIGTERM and exit 0 cleanly.

## Task 4: Working with containers
**Logs, and following them live:**
```
$ docker logs web
2026/10/06 18:57:35 mini-web serving /www on :80
2026/10/06 18:57:35 172.17.0.1:58348 "GET / HTTP/1.1" "curl/8.5.0"
2026/10/06 18:57:35 172.17.0.1:58352 "GET /index.html HTTP/1.1" "curl/8.5.0"
2026/10/06 18:57:35 172.17.0.1:58354 "GET /admin HTTP/1.1" "curl/8.5.0"

$ docker logs -f web          (then I sent a request from another shell)
...
2026/10/06 18:57:36 172.17.0.1:58356 "GET /live-request HTTP/1.1" "curl/8.5.0"   ← appeared live
```
**Shell inside a container + a bind mount:**
```
$ docker run -d --name shell-box -v /root/docker-lab/web:/data:ro robin/ubuntu-mini:24.04 sleep 300
$ docker exec shell-box bash -c 'cd /; ls; ls -l /data | head -4'
bin  data  dev  etc  home  lib  lib64  proc  root  sys  tmp
-rw-r--r-- 1 root root     222 Oct  6 18:56 Dockerfile
-rw-r--r-- 1 root root     203 Oct  6 18:56 index.html
-rw-r--r-- 1 root root     628 Oct  6 18:56 main.go
$ docker exec shell-box cat /etc/os-release | head -1
PRETTY_NAME="Ubuntu 24.04.5 LTS"
```
**Inspect: IP, ports, mounts:**
```
$ docker inspect web --format 'IP={{.NetworkSettings.Networks.bridge.IPAddress}}  Ports={{json .NetworkSettings.Ports}}'
IP=172.17.0.2  Ports={"80/tcp":[{"HostIp":"0.0.0.0","HostPort":"8080"}]}

$ docker inspect shell-box --format 'Mounts={{range .Mounts}}{{.Source}} -> {{.Destination}} (rw={{.RW}}){{end}}'
Mounts=/root/docker-lab/web -> /data (rw=false)
```

## Task 5: Cleanup
```
$ docker ps -q | wc -l
4
$ docker stop $(docker ps -q) | wc -l && docker ps -q | wc -l
4
0
$ docker ps -a --format '{{.Names}}: {{.Status}}'
extra2: Exited (137)       ← sleep ignored SIGTERM → killed after 10 s
extra1: Exited (137)
shell-box: Exited (137)
web: Exited (2)
strange_brahmagupta: Exited (0)

$ docker container prune -f
Deleted Containers: (5 IDs)
Total reclaimed space: 24.58kB

$ docker images -f dangling=true      ← none: the rebuild reused cached layers
$ docker image prune -f
Total reclaimed space: 0B

$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          3         0         24.9MB    24.89MB (99%)
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     9         0         17.26MB   7.115MB
```
**A lesson from the exit codes:** `sleep` as **PID 1** ignores SIGTERM (PID 1 gets no default signal handlers), so `docker stop` waited 10 s and then SIGKILLed it (**137**). That's why images use `tini` / `--init`, or apps handle SIGTERM themselves.

## Key learnings
1. **Images are stacks of cached layers.** Only filesystem-changing instructions add size, and their order decides how well the cache works.
2. **stop ≠ kill.** Exit code 137 means it was SIGKILLed, and PID 1 has to handle SIGTERM itself (or use `--init`).
3. **`docker inspect` is the source of truth** for IPs, ports, mounts and config. `docker system df` + `prune` keep the disk clean.
