# Task 1 exactly as the task describes it (needs Docker Hub + Ubuntu mirrors).
# NOT run in my lab environment (registries blocked) - run it on a machine with internet:
#   docker build -t my-ubuntu:v1 -f my-first-image.Dockerfile .
#   docker run my-ubuntu:v1
FROM ubuntu
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
CMD ["echo", "Hello from my custom image!"]
