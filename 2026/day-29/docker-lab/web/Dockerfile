FROM scratch
LABEL maintainer="Robin Sishodia" description="mini-web: static web server, nginx stand-in"
ENV WEB_ROOT=/www PORT=80
COPY mini-web /mini-web
COPY index.html /www/index.html
EXPOSE 80
ENTRYPOINT ["/mini-web"]
