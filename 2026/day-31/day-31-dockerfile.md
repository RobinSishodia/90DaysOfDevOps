# Day 31 – Dockerfile: Build Your Own Images

Lab environment: a cloud Linux workspace (not my local machine), Docker 29.8.2. Docker Hub and the Ubuntu apt mirrors are blocked (see Day 29), so I can't `FROM ubuntu`, `FROM nginx:alpine` or `apt-get install`. Same workaround as Day 29–30: I build on my own local base images — `robin/ubuntu-mini:24.04` (a rootfs from host binaries) and `robin/mini-web:1.0` (my nginx stand-in). Every Dockerfile in this folder was built and run for real. The exact Docker Hub versions the task asks for (`FROM ubuntu` + `apt-get install -y curl`, `FROM nginx:alpine`) are in `canonical-docker-hub/`. I could not run those here, so they are untested in this lab environment.

Files in this folder:

| Path | Task |
|---|---|
| `my-first-image/Dockerfile` (+ `make-curl-bundle.sh`) | 1 |
| `instructions/Dockerfile` + `hello.sh` | 2 |
| `cmd-vs-entrypoint/Dockerfile.cmd`, `.entrypoint`, `.both` | 3 |
| `web-app/Dockerfile` + `index.html` | 4 |
| `dockerignore-demo/` | 5 |
| `cache-demo/Dockerfile.unoptimized`, `Dockerfile.optimized` | 6 |
| `canonical-docker-hub/` | The task's original Dockerfiles (not run here) |

## Task 1: Your first Dockerfile

```dockerfile
FROM robin/ubuntu-mini:24.04
COPY curl-bundle/ /          # stand-in for: RUN apt-get update && apt-get install -y curl
CMD ["echo", "Hello from my custom image!"]
```

`apt` can't reach the mirrors, so `make-curl-bundle.sh` copies the host's `curl` and every shared library it needs into `./curl-bundle`, and `COPY` drops them at the same paths. That is what `apt install` does in the end: put a binary and its libraries into the filesystem.

```
$ docker build -t my-ubuntu:v1 my-first-image
$ docker images my-ubuntu:v1
IMAGE          ID             DISK USAGE   CONTENT SIZE
my-ubuntu:v1   edb9de7d1ac4   52.6MB       15.5MB

$ docker run --rm my-ubuntu:v1
Hello from my custom image!                      <- Verify: the message prints

$ docker run --rm my-ubuntu:v1 curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 ...     <- curl is "installed"
```

## Task 2: Dockerfile instructions

```dockerfile
FROM robin/ubuntu-mini:24.04                       # base image everything is stacked on
RUN mkdir -p /app && echo "built with docker build" > /app/build-info.txt   # runs at BUILD time
WORKDIR /app                                       # cwd for later instructions and the container
COPY hello.sh /app/hello.sh                        # host file -> image
EXPOSE 8080                                        # documents the port, does not publish it
CMD ["/bin/bash", "hello.sh"]                      # default command at RUN time
```

```
$ docker run --rm instr:v1
Hello from 1580497d7b3c
Working directory: /app
Files here: build-info.txt
hello.sh
Build info: built with docker build

$ docker image history instr:v1
IMAGE          CREATED BY                                      SIZE
65147262b84d   CMD ["/bin/bash" "hello.sh"]                    0B
<missing>      EXPOSE [8080/tcp]                               0B
<missing>      COPY hello.sh /app/hello.sh # buildkit          12.3kB
<missing>      WORKDIR /app                                    4.1kB
<missing>      RUN /bin/sh -c mkdir -p /app && echo "built …   12.3kB
<missing>                                                      16.6MB   (base image)

$ docker image inspect instr:v1 --format 'WorkingDir={{.Config.WorkingDir}} ExposedPorts={{json .Config.ExposedPorts}}'
WorkingDir=/app ExposedPorts={"8080/tcp":{}}
```

What each line does:
- `FROM` picks the starting filesystem. Every build starts here.
- `RUN` executes while the image is being built. Its result becomes a layer, so use it for installing things.
- `COPY` brings files from the build context (the folder I pass to `docker build`) into the image.
- `WORKDIR` sets the directory for the lines below it and for the running container. It also creates the directory if missing.
- `EXPOSE` is documentation only. Nothing is published until I use `-p` (or `-P`) at `docker run`.
- `CMD` is the default command for the container. It runs at start, not at build.

In `docker image history`, only `RUN` and `COPY` added real size. `CMD` and `EXPOSE` are 0 B metadata. (`WORKDIR` shows 4.1 kB because it created the `/app` directory.)

## Task 3: CMD vs ENTRYPOINT

**CMD only** (`CMD ["echo", "hello"]`):
```
$ docker run --rm my-cmd
hello
$ docker run --rm my-cmd echo goodbye       <- my words REPLACE the whole CMD
goodbye
$ docker run --rm my-cmd ls /               <- a completely different program runs
bin  dev  etc  home  lib  lib64  proc  root  sys  tmp  var
```

**ENTRYPOINT only** (`ENTRYPOINT ["echo"]`):
```
$ docker run --rm my-entry                  <- echo with no arguments: an empty line
(blank line)
$ docker run --rm my-entry hello world      <- my words are APPENDED as arguments
hello world
$ docker run --rm my-entry ls /             <- NOT run as ls: it is just echo's arguments
ls /
$ docker run --rm --entrypoint ls my-entry /    <- replacing ENTRYPOINT needs --entrypoint
bin  dev  etc  home  lib  lib64  proc  root  sys  tmp  var
```

**Both together** (`ENTRYPOINT ["echo", "Greeting:"]` + `CMD ["hello"]`):
```
$ docker run --rm my-both
Greeting: hello                             <- CMD supplies the default argument
$ docker run --rm my-both from-the-command-line
Greeting: from-the-command-line             <- my argument replaces only CMD
```

**When to use which:**
- **CMD** is a default command that users are expected to override. Good for general-purpose images (a base OS image, a dev image) where `docker run image bash` or `docker run image ls` should just work.
- **ENTRYPOINT** is for an image that is one specific program, like a CLI tool or a service. The container always runs that program, and users only pass arguments.
- **Both together** is the cleanest pattern: ENTRYPOINT is the program, CMD is its default arguments. `docker run image` uses the defaults and `docker run image --other-flag` swaps them out.
- Always use exec form (`["a","b"]`), not shell form, so the process is PID 1 and receives `docker stop`'s SIGTERM (Day 30 lesson).

## Task 4: Simple web app image

`web-app/index.html` is a small static page. The Dockerfile:

```dockerfile
FROM robin/mini-web:1.0                       # stand-in for nginx:alpine
COPY index.html /www/index.html               # nginx would be /usr/share/nginx/html/
```

```
$ docker build -t my-website:v1 web-app
$ docker run -d --name site -p 8081:80 my-website:v1
$ curl -i http://localhost:8081/
HTTP/1.1 200 OK
Content-Length: 247
Content-Type: text/html; charset=utf-8

<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Robin's first container website</title></head>
<body>
  <h1>Hello from my custom Docker image!</h1>

$ docker logs site
2026/10/13 16:21:46 mini-web serving /www on :80
2026/10/13 16:21:47 172.17.0.1:39564 "GET / HTTP/1.1" "curl/8.5.0"
```

I used `curl` instead of a browser because the workspace has no browser. `-p 8081:80` maps host port 8081 to container port 80. The `docker logs` line proves the request reached the container. With real nginx the Dockerfile is the same two lines, see `canonical-docker-hub/web-app.Dockerfile`.

## Task 5: .dockerignore

`dockerignore-demo/setup-demo.sh` builds a throw-away project (outside the repo, so the fake `.git` doesn't confuse git) with `app.js`, `package.json`, `node_modules/`, `.git/`, `README.md`, `notes.md` and `.env`. The Dockerfile does `COPY . /app` and then `ls -a /app`.

`.dockerignore`:
```
node_modules
.git
*.md
.env
```

```
BEFORE (no .dockerignore)                 AFTER (with .dockerignore)
$ docker run --rm ignore-test:without     $ docker run --rm ignore-test:with
.                                         .
..                                        ..
.env            <- secret leaked!         .dockerignore
.git                                      Dockerfile
Dockerfile                                app.js
README.md                                 package.json
app.js
node_modules
notes.md
package.json
```

The build context sent to the daemon also shrank:
```
without .dockerignore:  #4 transferring context: 487B
with .dockerignore:     #4 transferring context: 120B
```

The ignored files are not in the image. The savings here are tiny because my demo files are tiny. A real `node_modules` or `.git` is often hundreds of MB, and then the context transfer is where you feel it.

Why it matters:
- **Security:** `.env` (secrets) and `.git` (the full history) must never ship inside an image, because anyone who can pull the image can read them.
- **Speed:** a smaller build context uploads faster.
- **Cache:** a changed `notes.md` no longer invalidates `COPY . .`.
- **Size:** no junk in the image.

`.dockerignore` itself still shows up in the image because `COPY .` copies it. That is harmless.

## Task 6: Build optimization

Same image, two layer orders. The "slow step" is `RUN sleep 4 ...`, standing in for `pip install` or `npm install`.

**Before** (`Dockerfile.unoptimized`): `COPY . /app` first, then the slow step.
**After** (`Dockerfile.optimized`): `COPY requirements.txt` first, then the slow step, then `COPY app.sh` last.

```
UNOPTIMIZED
build 1 (cold):                      4.8 s   all steps run
build 2 (nothing changed):           0.4 s   COPY . /app CACHED, RUN CACHED
build 3 (added ONE line to app.sh):  4.8 s   COPY . /app re-ran -> RUN re-ran (not cached)

OPTIMIZED
build 1 (cold):                      5.1 s
build 2 (added ONE line to app.sh):  0.4 s   WORKDIR, COPY requirements.txt, RUN all CACHED;
                                             only COPY app.sh re-ran
```

Final run of the optimized image shows the change made it in: `app version 1` then `app version 2`.

**Why layer order matters for build speed:** Docker caches each layer, keyed on the instruction and its inputs (for `COPY`, the file contents). The moment one layer's cache is invalidated, every layer after it is rebuilt, even if they didn't change. So put things that rarely change (base image, dependency install) first and things that change all the time (my own code) last. The unoptimized file loses the whole 4-second dependency step on every one-line code edit. The optimized file loses only the cheap final `COPY`. With real `npm install` or `pip install` steps that is the difference between a 1-minute and a 2-second rebuild.

## Key learnings
- A Dockerfile is a recipe where each instruction is a layer. `RUN`/`COPY` add size, `CMD`/`EXPOSE`/`ENV` are metadata.
- **CMD = overridable default. ENTRYPOINT = the program itself.** `ENTRYPOINT` + `CMD` together gives a fixed program with default, overridable arguments.
- `.dockerignore` is a security feature as well as a speed one: keep `.env` and `.git` out of images.
- Order Dockerfile lines from least to most frequently changed. The cache does the rest.
- Honest limitation: I couldn't run `FROM ubuntu` / `apt-get` / `nginx:alpine` here, only my stand-ins. The instructions and behaviours (CMD/ENTRYPOINT, COPY, WORKDIR, EXPOSE, cache, `.dockerignore`) are identical with the real images.
