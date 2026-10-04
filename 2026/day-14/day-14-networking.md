# Day 14 – Networking Fundamentals & Hands-on Checks

> Practice VM: Ubuntu 24.04 cloud microVM. It has **no ping/traceroute/dig/ss installed** and sits behind an **egress proxy**, which turned into a good lesson in itself.

## OSI vs TCP/IP
| OSI (7 layers) | TCP/IP (4 layers) | Examples |
|---|---|---|
| L7 Application, L6 Presentation, L5 Session | **Application** | HTTP/HTTPS, DNS, SSH, TLS |
| L4 Transport | **Transport** | TCP (reliable, ordered), UDP (fast, no guarantees) |
| L3 Network | **Internet** | IP, ICMP (ping), routing |
| L2 Data Link, L1 Physical | **Link** | Ethernet, Wi-Fi, MAC addresses, cables |

- **IP** = L3 (addressing and routing). **TCP/UDP** = L4 (ports). **HTTP/HTTPS** = L7. **DNS** = L7, usually over **UDP port 53**.
- **Example:** `curl https://github.com` = DNS lookup (L7/UDP) → TCP handshake to 140.82.x.x:443 (L4/L3) → TLS handshake → HTTP request (L7).

## Hands-on

### My IP address
```
$ hostname -I
192.0.2.2
$ cat /proc/net/route | awk 'NR>1 {print $1, $2, $3}'
eth0 00000000 010200C0        ← default route, gateway in hex = 192.0.2.1
eth0 000200C0 00000000        ← local subnet 192.0.2.0/24
```
`192.0.2.0/24` is **TEST-NET-1**, a reserved "documentation" range, so this VM sits behind NAT.

### ping / traceroute
```
$ ping -c 4 github.com
ping: command not found
$ which traceroute tracepath
(nothing)
```
These tools aren't installed and can't be added, and ICMP is usually blocked in sandboxes anyway. **Alternative: measure latency at L4 with curl:**
```
$ for i in 1 2 3 4; do curl -s -o /dev/null -w "try $i: connect=%{time_connect}s total=%{time_total}s\n" http://localhost:8080/; done
try 1: connect=0.000144s total=0.001163s
try 2: connect=0.000364s total=0.001228s
try 3: connect=0.000123s total=0.000902s
try 4: connect=0.000137s total=0.000990s
```
**4/4 successful, so 0% loss**, with about 1 ms total on localhost.

### DNS
`dig` isn't installed, so I wrote **[minidig.py](./minidig.py)**, a small Python script that builds a raw DNS query and sends it over UDP:53 to 8.8.8.8:
```
$ python3 minidig.py github.com A
;; SERVER: 8.8.8.8#53  status: NOERROR  answers: 1
;; ANSWER SECTION:
github.com.            58     IN A      140.82.114.4

$ getent hosts github.com
140.82.114.4    github.com
```
**github.com → 140.82.114.4**, with a TTL of 58 seconds.

### Listening ports, ESTABLISHED vs LISTEN (`lsof` instead of `ss`/`netstat`)
I opened a connection to port 8080 with `nc` and left it open:
```
$ lsof -i -P -n | grep -E 'COMMAND|:8080|:8000'
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
python3   269 root    3u  IPv4   1432      0t0  TCP *:8080 (LISTEN)
python3   269 root    4u  IPv4   4128      0t0  TCP 127.0.0.1:8080->127.0.0.1:39170 (ESTABLISHED)
python3   808 root    3u  IPv4   3515      0t0  TCP *:8000 (LISTEN)
nc        812 root    3u  IPv4   4127      0t0  TCP 127.0.0.1:39170->127.0.0.1:8080 (ESTABLISHED)
```
- **LISTEN** = waiting for connections (`*:8080` means all interfaces).
- **ESTABLISHED** = an active connection. You see **both ends**: the client on a random high port (39170) and the server on 8080.

### HTTP status with curl
```
$ curl -s -o /dev/null -w 'status=%{http_code}  dns=%{time_namelookup}s  connect=%{time_connect}s  tls=%{time_appconnect}s  total=%{time_total}s\n' https://github.com
status=400  dns=0.000030s  connect=0.000230s  tls=0.188310s  total=0.247128s
$ curl -s -o /dev/null -w 'status=%{http_code}\n' https://github.com/RobinSishodia/90DaysOfDevOps
status=403
$ curl -s -o /dev/null -w 'status=%{http_code}\n' https://www.google.com
status=000
$ curl -sI http://localhost:8080/ | head -1
HTTP/1.0 200 OK
```
**Real-world lesson:** the VM goes out through an **egress proxy**. GitHub answered 400/403 to plain curl through the proxy, and Google gave **000**. 000 isn't an HTTP code at all. It means **no HTTP response came back** (blocked or unreachable). Locally, the server returns 200.

## Port probe
```
$ nc -zv localhost 8080
Connection to localhost (127.0.0.1) 8080 port [tcp/http-alt] succeeded!
$ nc -zv localhost 5432
nc: connect to localhost (127.0.0.1) port 5432 (tcp) failed: Connection refused
```
- 8080 is **reachable** ✅
- 5432 gives **Connection refused**: the host is up but nothing is listening (no PostgreSQL). **Next checks:** is the service running? Is it bound to `127.0.0.1` only? Is a firewall or security group blocking it?

## Reflection
- **Quickest feedback:** `curl -I` (or `curl -w '%{http_code}'`), because one command tests DNS, TCP, TLS and HTTP together.
- **DNS failure → check the Application layer (DNS) and UDP/53.** `getent hosts` / `dig`, `/etc/resolv.conf`.
- **HTTP 500 → the network is fine, it's the app (L7).** The request got there and the app crashed, so read the app logs.
- **Two more incident checks:** (1) "refused" vs "timed out": refused = nothing listening, timeout = firewall or routing. (2) Check proxy and firewall rules (`env | grep -i proxy`, security groups).
