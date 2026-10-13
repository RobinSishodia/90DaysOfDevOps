# Day 32 – Docker Volumes & Networking

Practice VM: Ubuntu 24.04, Docker 29.8.2. Docker Hub is blocked (see Day 29), so I can't pull `postgres`, `mysql` or any app image. Same approach as Day 29–31: my own local images, all in `lab-images/` (`./build-all.sh` rebuilds them):

| Image | What it is |
|---|---|
| `robin/mini-db:1.0` | MySQL/Postgres stand-in. It keeps its data in `/data` (an append-only file), so *whether data survives depends only on whether `/data` is a volume*. HTTP API: `POST /rows`, `GET /rows`, `GET /health` |
| `robin/mini-app:1.0` | App/WordPress stand-in. Finds its database **by name** (`DB_HOST`), so it only works if container-name DNS works |
| `robin/ubuntu-tools:1.0` | My Ubuntu-mini + `curl` + `ping` (a tiny ICMP client I wrote in Go, because the VM has no `ping` binary to copy) |
| `robin/mini-web:1.0` | nginx stand-in from Day 29 |

I haven't run real Postgres/MySQL here. The persistence and networking behaviour comes from Docker itself and is the same for any image. Everything below is real output from this VM.

## Task 1: The problem

```
$ docker run -d --name db1 -p 5433:5432 robin/mini-db:1.0
$ curl -s -X POST -d 'robin, devops learner' localhost:5433/rows      -> inserted
$ curl -s -X POST -d 'day 32, volumes' localhost:5433/rows             -> inserted
$ curl -s -X POST -d 'hello from container 1' localhost:5433/rows      -> inserted
$ curl -s localhost:5433/rows
1	16:23:30	robin, devops learner
2	16:23:30	day 32, volumes
3	16:23:30	hello from container 1

$ docker stop db1 && docker rm db1
$ docker run -d --name db2 -p 5433:5432 robin/mini-db:1.0
$ curl -s localhost:5433/rows
(nothing - 0 rows)
```

**What happened:** the data was gone. A container's filesystem is a thin writable layer on top of the read-only image. When the container is removed, that layer is deleted with it, so everything written inside the container disappears. `db2` starts from the clean image, as if `db1` never existed.

**A subtlety I only noticed by looking closer.** My image (like the real `mysql` and `postgres` images) declares `VOLUME ["/data"]`. So Docker *did* put `/data` on a volume for `db1`, an anonymous one with a random 64-character name:

```
$ docker inspect db1 --format 'Mounts={{json .Mounts}}'
Mounts=[{"Type":"volume","Name":"49dbaf259ebf...","Destination":"/data","RW":true,...}]
```

`docker rm db1` leaves that volume behind. But `db2` got a brand new anonymous volume, so it looked empty. The data was still sitting on the disk, orphaned. At the end of the day `docker volume ls` showed two of those leftovers, and `docker volume prune` deleted them. Lesson: an anonymous volume survives, but nothing points at it. You need a *name* so the next container can find it again.

## Task 2: Named volumes

```
$ docker volume create db-data
$ docker run -d --name db3 -p 5433:5432 -v db-data:/data robin/mini-db:1.0
$ curl -s -X POST -d 'robin, devops learner' localhost:5433/rows
$ curl -s -X POST -d 'this row lives in a volume' localhost:5433/rows
$ curl -s localhost:5433/rows
1	16:23:33	robin, devops learner
2	16:23:33	this row lives in a volume

$ docker stop db3 && docker rm db3
$ docker run -d --name db4 -p 5433:5432 -v db-data:/data robin/mini-db:1.0     <- brand new container, same volume
$ curl -s localhost:5433/rows
1	16:23:33	robin, devops learner                                           <- the data is still there
2	16:23:33	this row lives in a volume
```

Verify:
```
$ docker volume inspect db-data
[{ "Driver": "local", "Mountpoint": "/var/lib/docker/volumes/db-data/_data", "Name": "db-data", "Scope": "local", ... }]

$ docker inspect db4 --format '{{range .Mounts}}type={{.Type}} name={{.Name}} dest={{.Destination}}{{end}}'
type=volume name=db-data dest=/data

$ cat /var/lib/docker/volumes/db-data/_data/rows.txt          <- the real file, on the host
16:23:33	robin, devops learner
16:23:33	this row lives in a volume
```

A named volume is storage that Docker manages on the host, outside any container's lifecycle. The container just mounts it at `/data`. Removing the container doesn't touch it, and the next container with `-v db-data:/data` picks up exactly where the last one stopped. Only `docker volume rm db-data` deletes the data.

## Task 3: Bind mounts

```
$ cat site/index.html
<h1>Version 1 - served from my host folder</h1>

$ docker run -d --name bind-web -p 8082:80 -v /home/claude/lab/site:/www robin/mini-web:1.0
$ curl -s localhost:8082/
<h1>Version 1 - served from my host folder</h1>

$ echo '<h1>Version 2 - edited on the host, container untouched</h1>' > site/index.html
$ curl -s localhost:8082/          <- no rebuild, no restart
<h1>Version 2 - edited on the host, container untouched</h1>

$ docker inspect bind-web --format '{{range .Mounts}}type={{.Type}} source={{.Source}} dest={{.Destination}}{{end}}'
type=bind source=/home/claude/lab/site dest=/www
```

(`/www` is where my mini-web serves files. With nginx it's `/usr/share/nginx/html`. I used `curl` instead of a browser refresh because the VM has no browser.)

**Named volume vs bind mount:**

| | Named volume | Bind mount |
|---|---|---|
| Created with | `-v db-data:/data` (a name) | `-v /host/path:/container/path` (an absolute host path) |
| Where the data lives | Docker's own area (`/var/lib/docker/volumes/...`), managed by Docker | Exactly the host folder I name |
| Managed by | Docker (`docker volume ls/inspect/rm`) | Me. Docker just points at my folder |
| Best for | Persistent app data (databases) | Development (live-edit code and config), sharing host files |
| Portable | Yes, no dependency on the host's folder layout | No, depends on the host path existing |
| `docker volume ls` | Shows up | Does not show up |

Rule of thumb: **volumes for data the container owns, bind mounts for files I want to edit from the host.**

## Task 4: Docker networking basics

```
$ docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
2684c597c705   bridge    bridge    local
11f3552944a0   host      host      local
61f56e3cd115   none      null      local

$ docker network inspect bridge --format 'Driver={{.Driver}} Subnet={{(index .IPAM.Config 0).Subnet}} Gateway={{(index .IPAM.Config 0).Gateway}}'
Driver=bridge Subnet=172.17.0.0/16 Gateway=172.17.0.1
```

Two containers on the default bridge:
```
$ docker run -d --name c1 robin/ubuntu-tools:1.0
$ docker run -d --name c2 robin/ubuntu-tools:1.0
$ docker network inspect bridge --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}'
c1 172.17.0.2/16
c2 172.17.0.3/16

$ docker exec c1 ping -c 2 c2                  <- by NAME
ping: c2: Name or service not known

$ docker exec c1 ping -c 2 172.17.0.3          <- by IP
16 bytes from 172.17.0.3: icmp_seq=1 ttl=64 time=0.173 ms
16 bytes from 172.17.0.3: icmp_seq=2 ttl=64 time=0.177 ms
2 packets transmitted, 2 received, 0% packet loss
```

By IP works, by name doesn't. On the default bridge containers can reach each other, but there is no name resolution between them. Container IPs also change every time a container is recreated, so IPs are useless for hard-coding.

## Task 5: Custom networks

```
$ docker network create my-app-net
$ docker run -d --name n1 --network my-app-net robin/ubuntu-tools:1.0
$ docker run -d --name n2 --network my-app-net robin/ubuntu-tools:1.0

$ docker exec n1 ping -c 2 n2
PING n2 (172.18.0.3): 8 data bytes
16 bytes from 172.18.0.3: icmp_seq=1 ttl=64 time=0.638 ms
2 packets transmitted, 2 received, 0% packet loss
$ docker exec n2 ping -c 2 n1
PING n1 (172.18.0.2): 8 data bytes
2 packets transmitted, 2 received, 0% packet loss
```

Names work now. The reason is visible in each container's `/etc/resolv.conf`:

```
default bridge:                         custom network (my-app-net):
nameserver 8.8.8.8                      nameserver 127.0.0.11
nameserver 8.8.4.4                      # Based on host file: '/etc/resolv.conf' (internal resolver)
(copied from the host)                  # ExtServers: [host(8.8.8.8) host(8.8.4.4)]
```

**Why custom networks allow name-based communication but the default bridge doesn't:** on a user-defined network, Docker runs an embedded DNS server at `127.0.0.11` and registers each container's name (and any `--network-alias`) with it. When `n1` looks up `n2`, that DNS server answers with `n2`'s current IP, even after the container is recreated with a new address. The default bridge has no such registration. Its containers just get the host's DNS servers, which know nothing about container names (only the legacy `--link` flag worked around it). Custom networks also give isolation: only containers on the same network can see each other.

## Task 6: Put it together

```
$ docker network create shop-net
$ docker volume create shop-db-data
$ docker run -d --name mini-db  --network shop-net -v shop-db-data:/data robin/mini-db:1.0
$ docker run -d --name shop-app --network shop-net -p 8083:80 \
      -e DB_HOST=mini-db -e SITE_TITLE='Robin Shop' robin/mini-app:1.0
```

Verify the app container reaches the database **by container name**:
```
$ docker run --rm --network shop-net robin/ubuntu-tools:1.0 ping -c 2 mini-db
PING mini-db (172.19.0.2): 8 data bytes
2 packets transmitted, 2 received, 0% packet loss

$ docker run --rm --network shop-net robin/ubuntu-tools:1.0 curl -s http://mini-db:5432/health
ok

$ curl -s localhost:8083/health            <- shop-app asks mini-db and reports back
ok
$ curl -s -X POST -d 'first post via the app'  localhost:8083/post     -> post stored
$ curl -s -X POST -d 'second post via the app' localhost:8083/post     -> post stored
$ curl -s localhost:8083/
<h1>Robin Shop</h1><p>env: ENVIRONMENT=unset DB_HOST=mini-db</p><pre>1	16:24:04	first post via the app
2	16:24:04	second post via the app
</pre>
```

The two sides of the conversation, from the logs:
```
$ docker logs mini-db
mini-db ready, data dir /data, listening on :5432
INSERT "first post via the app" from 172.19.0.3:39364
INSERT "second post via the app" from 172.19.0.3:39372
SELECT -> 2 rows to 172.19.0.3:39384

$ docker logs shop-app
mini-app "Robin Shop" starting on :80, database at http://mini-db:5432/rows
stored post "first post via the app" via http://mini-db:5432/rows
```

Only the name `mini-db` appears in the app's config. There is no IP address anywhere.

Then I destroyed the database container and brought it back to check both ideas at once:
```
$ docker rm -f mini-db
$ curl -s -o /dev/null -w 'app while db is down: HTTP %{http_code}\n' localhost:8083/health
app while db is down: HTTP 503

$ docker run -d --name mini-db --network shop-net -v shop-db-data:/data robin/mini-db:1.0
$ curl -s localhost:8083/health
ok
$ curl -s localhost:8083/
<h1>Robin Shop</h1> ... 1  first post via the app / 2  second post via the app
```

While the DB was gone the app returned 503. As soon as a new container with the same **name** joined the same network, the app found it with no config change. And the posts were still there, because of the **volume**. The new database container has a different IP and none of the old container's filesystem. This is the pattern that Docker Compose automates tomorrow.

## Cleanup
```
$ docker rm -f $(docker ps -aq)
$ docker volume prune -f          # removed the orphaned anonymous volumes from Task 1
$ docker network rm my-app-net shop-net
```

## Key learnings
- A container's own filesystem dies with the container. Anything that must survive goes on a **volume**.
- An **anonymous** volume (from `VOLUME` in the image, or `-v /path`) survives but is orphaned, because nothing can find it. Always use a **named** volume for real data, and watch `docker volume ls` for leftovers.
- **Named volume** = Docker-managed persistence. **Bind mount** = my own host folder, live-editable. Use volumes for databases and bind mounts for development.
- Default bridge: reachable by IP only. **User-defined network: built-in DNS, reachable by container name** (via `127.0.0.11`).
- Put app + DB on one custom network, point the app at the DB's *name*, and put the DB's data on a named volume. That is the building block of every multi-container setup.
- Honest limitation: I used my own `mini-db`/`mini-app` instead of MySQL/Postgres/WordPress because Docker Hub is blocked here. The Docker behaviours shown (volumes, bind mounts, DNS, networks) are identical for the real images.
