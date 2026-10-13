# ubuntu-tools: my Ubuntu-mini image + curl (copied from the host) + mini-ping (own ICMP client).
# Used for exec / ping / curl experiments. Needs ./curl-bundle (see day-31/my-first-image/make-curl-bundle.sh)
# and ./ping (CGO_ENABLED=0 go build -o ping .)
FROM robin/ubuntu-mini:24.04
COPY curl-bundle/ /
COPY ping /bin/ping
CMD ["sleep", "600"]
