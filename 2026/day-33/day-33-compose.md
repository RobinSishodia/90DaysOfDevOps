# Day 33 – Docker Compose: Multi-Container Basics

Lab environment: a cloud Linux workspace (not my local machine), Docker 29.8.2, Docker Compose v5.5.1. Docker Hub is blocked (see Day 29), so I can't pull `nginx`, `wordpress` or `mysql`. The runnable compose files use my own images from Day 29/32: `robin/mini-web:1.0` (nginx stand-in), `robin/mini-app:1.0` (WordPress stand-in) and `robin/mini-db:1.0` (MySQL stand-in). `../day-32/lab-images/build-all.sh` rebuilds the images. The exact WordPress + MySQL and nginx compose files the task describes are in `canonical-docker-hub/`. I could not run those here, so they are untested in this lab environment. Everything below is real output from this VM. I trimmed Compose's repeated "Creating/Starting" progress lines for readability.

| Folder | Task |
|---|---|
| `compose-basics/` | 2: single container |
| `wordpress-stack/` | 3: app + database + volume |
| `compose-commands/` | 4: the everyday commands |
| `env-vars/` | 5: inline variables and `.env` |
| `canonical-docker-hub/` | The real nginx and WordPress + MySQL files (not run here) |

## Task 1: Install & verify

```
$ docker compose version
Docker Compose version v5.5.1

$ docker compose version --short
5.5.1

$ which docker-compose
(nothing: no old standalone v1 binary)
```

Compose is a plugin of the `docker` CLI, so the command is `docker compose` (space), not the old `docker-compose` (hyphen). Docker Engine and Compose are already installed together.

## Task 2: Your first Compose file

`compose-basics/docker-compose.yml`:
```yaml
name: compose-basics
services:
  web:
    image: robin/mini-web:1.0        # real nginx: image: nginx:alpine
    ports:
      - "8084:80"
```

```
$ docker compose up -d
 Network compose-basics_default  Created
 Container compose-basics-web-1  Started

$ docker compose ps
NAME                   IMAGE                COMMAND       SERVICE   STATUS        PORTS
compose-basics-web-1   robin/mini-web:1.0   "/mini-web"   web       Up 1 second   0.0.0.0:8084->80/tcp

$ curl -s localhost:8084/
<h1>mini-web is up</h1><p>Default page baked into the base image.</p>   (inside the HTML)

$ docker compose down
 Container compose-basics-web-1  Removed
 Network compose-basics_default  Removed

$ docker ps -a | wc -l           -> 0 containers left
```

(`curl` instead of a browser: the workspace has no browser.) Compare with Day 30–32: the whole `docker run -d --name ... -p 8084:80 robin/mini-web:1.0` plus its cleanup is now a file I can commit, plus `up` and `down`. Compose also created a network, `compose-basics_default`, without being asked.

## Task 3: Two-container setup (app + database)

`wordpress-stack/docker-compose.yml`:
```yaml
name: wordpress-stack
services:
  db:                                  # <- service name = DNS name
    image: robin/mini-db:1.0           # real: mysql:8.0
    volumes:
      - db_data:/data                  # named volume (real: /var/lib/mysql)
  wordpress:
    image: robin/mini-app:1.0          # real: wordpress:latest
    depends_on:
      - db
    ports:
      - "8085:80"
    environment:
      DB_HOST: db                      # connects by SERVICE NAME (real: WORDPRESS_DB_HOST: db:3306)
      DB_PORT: "5432"
      SITE_TITLE: "Robin's Compose Blog"
volumes:
  db_data:
```

```
$ docker compose up -d
 Volume    wordpress-stack_db_data       Created
 Network   wordpress-stack_default       Created
 Container wordpress-stack-db-1          Started
 Container wordpress-stack-wordpress-1   Started

$ docker compose ps
NAME                          IMAGE                SERVICE     STATUS        PORTS
wordpress-stack-db-1          robin/mini-db:1.0    db          Up 1 second   5432/tcp
wordpress-stack-wordpress-1   robin/mini-app:1.0   wordpress   Up 1 second   0.0.0.0:8085->80/tcp

$ curl -s localhost:8085/health          <- the app asked the database, by name "db"
ok
$ curl -s -X POST -d 'Hello World - my first post' localhost:8085/post      -> post stored
$ curl -s -X POST -d 'Compose makes this easy' localhost:8085/post          -> post stored
$ curl -s localhost:8085/
<h1>Robin&#39;s Compose Blog</h1><p>env: ENVIRONMENT=unset DB_HOST=db</p>
1	16:25:21	Hello World - my first post
2	16:25:21	Compose makes this easy
```

The task says "access WordPress in your browser and set it up". My stand-in has no setup wizard, so creating the two posts through its API is the equivalent step.

**Stop and restart with `down` and `up`: is the data still there?**
```
$ docker compose down
 Container wordpress-stack-wordpress-1   Removed
 Container wordpress-stack-db-1          Removed
 Network   wordpress-stack_default       Removed          <- containers and network gone

$ docker volume ls
local     wordpress-stack_db_data                          <- the volume is still here

$ docker compose up -d
$ curl -s localhost:8085/
<h1>Robin&#39;s Compose Blog</h1> ...
1	16:25:21	Hello World - my first post                    <- data survived
2	16:25:21	Compose makes this easy
```

Yes, the data is still there. `docker compose down` removes containers and networks but **keeps named volumes**. The volume is named `<project>_<volume>` (`wordpress-stack_db_data`). The new containers mounted it again and found the old files.

**What Compose did for me automatically** (Day 32's manual steps):
- Created a network (`wordpress-stack_default`) and put both services on it.
- Registered each **service name** as a DNS name (`db`), so `DB_HOST: db` just works.
- Created and mounted the named volume.
- Started `db` before `wordpress` (`depends_on`).

## Task 4: Compose commands

`compose-commands/` has a `web` service built from `./web/Dockerfile` and a `db` service. First `docker compose up -d` built the web image on the fly (it also tried to pull `robin/compose-web:dev` first and got "Forbidden" from the blocked registry, then built it locally).

| What I wanted | Command | Real output (trimmed) |
|---|---|---|
| Start in detached mode | `docker compose up -d` | `Container compose-commands-db-1 Started` / `...web-1 Started` |
| View running services | `docker compose ps` | `compose-commands-db-1 ... Up 1 second 5432/tcp` and `compose-commands-web-1 ... Up 1 second 0.0.0.0:8086->80/tcp` |
| Logs of all services | `docker compose logs` | `db-1  \| mini-db ready, data dir /data...` and `web-1 \| mini-web serving /www on :80`, then my requests |
| Logs of one service | `docker compose logs web` | only the `web-1 \|` lines (no `db-1`) |
| Follow logs live | `docker compose logs -f --tail 2 web` | printed the last 2 lines, then my new `GET /` request appeared live |
| Stop without removing | `docker compose stop` | `Container compose-commands-web-1 Stopped` / `...db-1 Stopped` |
| ...and what it left behind | `docker compose ps -a` | both containers listed as `Exited (2)` (still exist) |
| Start them again | `docker compose start` | `Started`, same containers |
| Rebuild after a change | `docker compose up -d --build` | `Image robin/compose-web:dev Built`, `web-1 Recreated` (db untouched: `Running`) |
| Remove containers + networks | `docker compose down` | `Container ... Removed` / `Network compose-commands_default Removed` |
| ...and also the volumes | `docker compose down -v` | `Volume compose-commands_db_data Removed` |

Details worth keeping:

```
$ docker compose logs
db-1   | 2026/10/13 16:25:35 mini-db ready, data dir /data, listening on :5432
web-1  | 2026/10/13 16:25:35 mini-web serving /www on :80
web-1  | 2026/10/13 16:25:36 172.19.0.1:52744 "GET / HTTP/1.1" "curl/8.5.0"
web-1  | 2026/10/13 16:25:36 172.19.0.1:52760 "GET /missing.html HTTP/1.1" "curl/8.5.0"
```
Compose prefixes each line with the service name (`db-1`, `web-1`), so interleaved logs stay readable.

Rebuild after a change:
```
$ curl -s localhost:8086/
<h1>compose-commands: version 1</h1>
(edit web/index.html)
$ curl -s localhost:8086/                      <- still the old version, the image is unchanged
<h1>compose-commands: version 1</h1>
$ docker compose up -d --build
 Image robin/compose-web:dev  Built
 Container compose-commands-db-1   Running      <- not touched
 Container compose-commands-web-1  Recreated    <- only the changed service
$ curl -s localhost:8086/
<h1>compose-commands: version 2 (rebuilt)</h1>
```
`up -d --build` rebuilds only what changed and recreates only the affected container.

`down` vs `down -v`:
```
$ docker compose down
$ docker volume ls -q | grep compose-commands
compose-commands_db_data         <- data kept
$ docker compose down -v
$ docker volume ls -q | grep compose-commands || echo '(volume gone)'
(volume gone)                    <- data deleted
```
`stop` keeps the containers (`ps -a` still lists them). `down` removes containers and networks but keeps volumes. `down -v` removes the volumes too, which is the one that deletes data.

## Task 5: Environment variables

`env-vars/docker-compose.yml` uses both ways. `env-vars/.env.example` is the template (`cp .env.example .env`; the real `.env` is in `.gitignore`).

```yaml
services:
  app:
    image: robin/mini-app:1.0
    ports:
      - "${APP_PORT}:80"                # from .env
    environment:
      ENVIRONMENT: development          # written directly in the compose file
      DB_HOST: db
      DB_PORT: "5432"
      SITE_TITLE: ${SITE_TITLE}         # from .env
```
`.env`:
```
SITE_TITLE=Robin's .env-powered site
APP_PORT=8087
```

**Verify the variables are picked up.** First, `docker compose config` shows the file after substitution:
```
$ docker compose config
...
    environment:
      DB_HOST: db
      DB_PORT: "5432"
      ENVIRONMENT: development
      SITE_TITLE: Robin's .env-powered site       <- substituted from .env
    ports:
      - mode: ingress
        target: 80
        published: "8087"                          <- APP_PORT from .env
```
Second, the running container and the app itself:
```
$ docker compose up -d
$ docker inspect env-vars-app-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E 'ENVIRONMENT|DB_|SITE_TITLE'
DB_PORT=5432
SITE_TITLE=Robin's .env-powered site
ENVIRONMENT=development
DB_HOST=db

$ curl -s localhost:8087/
<h1>Robin&#39;s .env-powered site</h1><p>env: ENVIRONMENT=development DB_HOST=db</p>
```
The page title came from `.env` and `ENVIRONMENT=development` from the compose file.

**Change `.env` only, without touching the compose file:**
```
SITE_TITLE=Changed in .env only
APP_PORT=8088

$ docker compose up -d
$ curl -s localhost:8088/
<h1>Changed in .env only</h1><p>env: ENVIRONMENT=development DB_HOST=db</p>
```
The title and the published port both changed with no edit to `docker-compose.yml`.

**Precedence and mistakes:**
```
$ SITE_TITLE='From my shell' docker compose config | grep SITE_TITLE
      SITE_TITLE: From my shell              <- a shell variable beats .env

(with .env deleted)
$ docker compose config
level=warning msg="The \"SITE_TITLE\" variable is not set. Defaulting to a blank string."
level=warning msg="The \"APP_PORT\" variable is not set. Defaulting to a blank string."
```
A missing `.env` doesn't fail, Compose just warns and substitutes an empty string. In `docker compose config` that left `SITE_TITLE: ""` and a `ports:` entry with only `target: 80` and no `published` port, so Docker would pick a random host port instead of 8087. That is easy to miss, so read the warnings.

Inline vs `.env`: inline values suit non-secret settings that belong to the app definition. `.env` keeps environment-specific values and secrets out of the committed compose file (and `.env` stays out of git). It is also how the same compose file runs in dev and prod with different values.

## Key learnings
- One `docker-compose.yml` replaces a pile of `docker network create` / `docker volume create` / `docker run ...` commands. It is documentation and automation at once, and it can be committed to git.
- Compose gives every project its own network and makes each **service name** a DNS name, so `DB_HOST: db` is all an app needs.
- `stop` keeps containers, `down` removes containers + networks, `down -v` also deletes volumes. Mixing those up is how data gets lost.
- `up -d --build` rebuilds and recreates only the services that changed.
- Variables can be inline or come from `.env`. `docker compose config` shows what Compose will really use, and that is the best way to debug substitution. A shell variable beats `.env`, and a missing variable silently becomes an empty string.
- Honest limitation: I couldn't run real WordPress/MySQL/nginx here. I used my own stand-in images, and the real files are in `canonical-docker-hub/` for a machine with internet access. Compose behaviour (networks, DNS, volumes, `.env`) is identical.
