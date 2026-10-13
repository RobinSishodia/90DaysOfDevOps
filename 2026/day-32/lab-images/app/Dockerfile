# mini-app: tiny stand-in for an app container (WordPress). Talks to its database BY NAME (DB_HOST).
# Build:  CGO_ENABLED=0 go build -o mini-app .  &&  docker build -t robin/mini-app:1.0 .
FROM scratch
LABEL maintainer="Robin Sishodia" description="mini-app: WordPress stand-in that reads its DB by name"
ENV DB_HOST=mini-db DB_PORT=5432 SITE_TITLE="mini-app"
COPY mini-app /mini-app
EXPOSE 80
ENTRYPOINT ["/mini-app"]
