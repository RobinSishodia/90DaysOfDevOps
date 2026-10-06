# Day 29 – Introduction to Docker

> Practice VM: Ubuntu 24.04, Docker Engine 29.8.2.
> **Plot twist:** my VM **can't reach any container registry**. Docker Hub, GHCR, Quay and ECR Public all return `Forbidden`, so `docker pull nginx` / `ubuntu` / `hello-world` were impossible. Instead I **built my own images locally** (source in [`docker-lab/`](./docker-lab)):
> - `robin/hello`: a hello-world clone, a Go binary `FROM scratch`
> - `robin/mini-web:1.0`: a tiny static web server (my **nginx stand-in**) `FROM scratch`, which logs every request
> - `robin/ubuntu-mini:24.04`: an Ubuntu root filesystem built from the host's own `bash`/coreutils + libraries, loaded with `docker import`
>
> Every `docker` command below is real output.

## Task 1: What and why
**A container** is a normal Linux process that's **isolated** (namespaces: own PID tree, network, hostname, filesystem) and **limited** (cgroups: CPU/RAM), and that runs from an **image**: a packaged filesystem with the app plus everything it needs.
**Why:** "works on my machine" → works everywhere. The same image runs on a laptop, in CI and in production. It starts in milliseconds and many fit on one host.

**Containers vs VMs**
| | Virtual machine | Container |
|---|---|---|
| Includes | A full guest OS + its own kernel | Only the app + libraries; **shares the host kernel** |
| Size | GBs | MBs (my images: 2–15 MB) |
| Boot | Minutes | Milliseconds |
| Isolation | Stronger (hardware-level) | Process-level |

**Architecture**
```
  docker CLI (client) ──REST API──► dockerd (daemon) ──► containerd ──► runc ──► container
        │                                │
   docker run nginx                  image store ◄──pull/push──► Registry (Docker Hub, ECR, GHCR)
```
- **Client:** the `docker` command you type
- **Daemon (`dockerd`):** does the actual work (builds, runs, networks, volumes)
- **Image:** a read-only template made of layers
- **Container:** a running (or stopped) instance of an image, with a thin writable layer on top
- **Registry:** where images are stored and shared. *Mine was unreachable, hence the local builds.*

## Task 2: Install and hello-world
```
$ docker version --format 'Client: {{.Client.Version}}  Server: {{.Server.Version}}'
Client: 29.8.2  Server: 29.8.2

$ docker pull nginx
Error response from daemon: ... Head "https://registry-1.docker.io/v2/library/nginx/manifests/latest": Forbidden

$ docker images
IMAGE                     ID             DISK USAGE   CONTENT SIZE
robin/hello:latest        b6a1a375da2d       2.13MB          665kB
robin/mini-web:1.0        4525a846bfb0       8.03MB         2.39MB
robin/ubuntu-mini:24.04   88abb824042b       14.7MB         4.52MB

$ docker run robin/hello
Hello from Docker! (robin/hello - built FROM scratch)

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The daemon found the image robin/hello locally (I built it - no registry needed).
 3. The daemon created a new container from that image and ran this program.
 4. The daemon streamed this output back to the Docker client, which printed it.

Container hostname (= short container ID): da46afe36698
```
These are the same 4 steps the official `hello-world` explains, except step 2 would normally be "pulled from Docker Hub". **A container's hostname is its short container ID.**

## Task 3: Container basics
**Web server ("nginx") with a port mapping:**
```
$ docker run -d --name web -p 8080:80 robin/mini-web:1.0
408646a299042c246cc3ab106fc0e17095e5ef031cd81efef2369779ff05acfb

$ docker ps
CONTAINER ID   IMAGE                COMMAND       STATUS         PORTS                  NAMES
408646a29904   robin/mini-web:1.0   "/mini-web"   Up             0.0.0.0:8080->80/tcp   web

$ curl -s http://localhost:8080/
<h1>Hello from a container! 🐳</h1><p>Served by robin/mini-web (an nginx stand-in built FROM scratch).</p>
$ curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8080/missing.html
HTTP 404
```
**Interactive "Ubuntu" container:** there's no real terminal in my VM, so I piped the commands into `-i` (with a TTY it would be `docker run -it robin/ubuntu-mini:24.04`):
```
$ printf 'cat /etc/os-release | head -2\nhostname\nwhoami\nls /\nps\nexit\n' | docker run -i --name ubuntu-box robin/ubuntu-mini:24.04
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
1e494c5945bc
root
bin  dev  etc  home  lib  lib64  proc  root  sys  tmp
    PID TTY          TIME CMD
      1 ?        00:00:00 bash          ← bash is PID 1 inside the container!
     13 ?        00:00:00 ps
```
**Running vs all containers:**
```
$ docker ps
NAMES   STATUS   PORTS
web     Up       0.0.0.0:8080->80/tcp
$ docker ps -a
NAMES                 STATUS                      PORTS
ubuntu-box            Exited (0)
web                   Up                          0.0.0.0:8080->80/tcp
strange_brahmagupta   Exited (0)                  ← robin/hello: no --name, so Docker picked a random one
```
**Stop and remove:**
```
$ docker stop web bg-web tools
$ docker rm web ubuntu-box tools
```

## Task 4: Going further
**Foreground vs detached:**
```
$ timeout 3 docker run --rm --name fg-web -p 8081:80 robin/mini-web:1.0
2026/10/06 18:57:00 mini-web serving /www on :80
foreground run blocked the terminal until it was stopped (exit 124)

$ docker run -d --rm --name bg-web -p 8081:80 robin/mini-web:1.0
5acc7c9c12b3...                ← returns straight away, the container keeps running
$ docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
NAMES     STATUS                  PORTS
bg-web    Up Less than a second   0.0.0.0:8081->80/tcp
web       Up 4 seconds            0.0.0.0:8080->80/tcp
```
**Logs:**
```
$ docker logs web
2026/10/06 18:57:00 mini-web serving /www on :80
2026/10/06 18:57:00 172.17.0.1:49862 "GET / HTTP/1.1" "curl/8.5.0"
2026/10/06 18:57:00 172.17.0.1:49866 "GET /missing.html HTTP/1.1" "curl/8.5.0"
```
Requests arrive from `172.17.0.1`, the **docker0 bridge** (host → container via the port mapping).

**exec, and a lesson about `FROM scratch`:**
```
$ docker exec web ls /www
OCI runtime exec failed: exec: "ls": executable file not found in $PATH
```
My `mini-web` image contains **only one binary and one HTML file**: no shell, no `ls`. That's great for security (nothing for an attacker to use) and size, but you can't poke around inside it. With the Ubuntu-based image, exec works:
```
$ docker run -d --name tools robin/ubuntu-mini:24.04 sleep 300
$ docker exec tools bash -c 'echo "inside: $(hostname), pid1 = $(cat /proc/1/comm)"; ps'
inside: 12599c5262d3, pid1 = sleep
    PID TTY          TIME CMD
      1 ?        00:00:00 sleep
      8 ?        00:00:00 ps
```
Inside the container, `ps` shows only **2 processes**. That's PID namespace isolation in action.

## Key learnings
1. **A container is just an isolated process.** `ps` inside shows PID 1 = the app, nothing else.
2. **`-p host:container` + `-d` + `--name`** is the everyday way to run a service. `docker logs` replaces `tail -f` on a log file.
3. **Minimal images (`FROM scratch`) are tiny and secure but have no shell for debugging.** That's the trade-off behind choosing alpine, distroless or ubuntu bases.
