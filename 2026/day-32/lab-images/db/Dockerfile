# mini-db: tiny stand-in for MySQL/Postgres (registries are blocked, see Day 29).
# Its "data directory" is /data - whether data survives depends only on whether /data is a volume.
# Build:  CGO_ENABLED=0 go build -o mini-db .  &&  docker build -t robin/mini-db:1.0 .
FROM scratch
LABEL maintainer="Robin Sishodia" description="mini-db: append-only data store, MySQL/Postgres stand-in"
ENV DATA_DIR=/data PORT=5432
COPY mini-db /mini-db
EXPOSE 5432
VOLUME ["/data"]
ENTRYPOINT ["/mini-db"]
