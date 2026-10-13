# Task 1: my first Dockerfile (runnable offline version)
# Base: my own Ubuntu-mini image (registries are blocked on the practice VM, see Day 29).
FROM robin/ubuntu-mini:24.04

# Stand-in for:  RUN apt-get update && apt-get install -y curl
# apt can't reach the Ubuntu mirrors here, so make-curl-bundle.sh copies the host's curl
# and its shared libraries into ./curl-bundle and COPY puts them at the same paths.
COPY curl-bundle/ /

# Default command: print the greeting
CMD ["echo", "Hello from my custom image!"]
