# Task 2: one Dockerfile that uses FROM, RUN, COPY, WORKDIR, EXPOSE and CMD

# FROM - the base image every other layer is stacked on
FROM robin/ubuntu-mini:24.04

# RUN - executes a command at BUILD time; its result is baked into a layer
RUN mkdir -p /app && echo "built with docker build" > /app/build-info.txt

# WORKDIR - sets the working directory for the instructions below and for the container
WORKDIR /app

# COPY - copies a file from the build context (host) into the image
COPY hello.sh /app/hello.sh

# EXPOSE - documents the port the app listens on (it does NOT publish it)
EXPOSE 8080

# CMD - the default command when the container starts (a run-time default, easy to override)
CMD ["/bin/bash", "hello.sh"]
