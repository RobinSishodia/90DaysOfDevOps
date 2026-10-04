# Day 15 – Networking Concepts: DNS, IP, Subnets & Ports

> Practice VM: Ubuntu 24.04. `dig` isn't installed, so I used my own [minidig.py](../day-14/minidig.py) from Day 14.

## Task 1: DNS
**What happens when I open `google.com`:** the browser checks its cache, then the OS asks a **resolver** (8.8.8.8 here). The resolver walks root → `.com` → `google.com`'s **nameservers**, gets the **A/AAAA record**, and caches it for the **TTL**. Then the browser opens a TCP connection to that IP on port 443.

| Record | What it does |
|---|---|
| **A** | Name → IPv4 address |
| **AAAA** | Name → IPv6 address |
| **CNAME** | Alias, one name pointing to another |
| **MX** | Mail server for the domain, with priority |
| **NS** | The authoritative nameservers for the domain |

```
$ python3 minidig.py google.com A
;; ANSWER SECTION:
google.com.            300    IN A      172.217.214.113
google.com.            300    IN A      172.217.214.101
google.com.            300    IN A      172.217.214.139
...                                     (6 A records)

$ python3 minidig.py google.com AAAA
google.com.            35     IN AAAA   2607:f8b0:4001:c79::8b   (+3 more)
$ python3 minidig.py www.github.com CNAME
www.github.com.        607    IN CNAME  github.com.
$ python3 minidig.py google.com MX
google.com.            246    IN MX     10 smtp.google.com.
$ python3 minidig.py google.com NS
google.com.            21600  IN NS     ns3.google.com.   (ns1–ns4)
```
**A record:** 172.217.214.113 (plus 5 more, for load balancing). **TTL: 300 s.** NS records have a much longer TTL (21600 s = 6 h) because they rarely change.

## Task 2: IP addressing
- **IPv4** = 32 bits written as 4 octets (0–255), e.g. `192.168.1.10`.
- **Public IPs** can be routed on the internet (e.g. `8.8.8.8`, GitHub's `140.82.114.4`). **Private IPs** only work inside a network and reach the internet through NAT.
- **Private ranges (RFC 1918):** `10.0.0.0/8`, `172.16.0.0/12` (172.16–172.31), `192.168.0.0/16`

```
$ hostname -I
192.0.2.2

$ python3 -c "import ipaddress ..."      # checked each IP with Python's ipaddress module
192.0.2.2       private=True  global=False
10.0.1.50       private=True  global=False
172.20.5.4      private=True  global=False
192.168.1.10    private=True  global=False
8.8.8.8         private=False  global=True
140.82.114.4    private=False  global=True
```
My VM's `192.0.2.2` isn't in an RFC 1918 range. It's **TEST-NET-1** (RFC 5737), a reserved block that isn't routable on the internet either, so it's NAT'd too.

## Task 3: CIDR & subnetting
`192.168.1.0/24`: the first **24 bits are the network** (192.168.1), and the last 8 bits are for hosts. That's 2⁸ = 256 addresses, and **254 usable**, because the network address `.0` and the broadcast address `.255` are reserved.

| CIDR | Subnet mask | Total IPs | Usable hosts |
|---|---|---|---|
| /8 | 255.0.0.0 | 16,777,216 | 16,777,214 |
| /16 | 255.255.0.0 | 65,536 | 65,534 |
| /24 | 255.255.255.0 | 256 | 254 |
| /26 | 255.255.255.192 | 64 | 62 |
| /28 | 255.255.255.240 | 16 | 14 |
| /30 | 255.255.255.252 | 4 | 2 |

*(Calculated with Python's `ipaddress` module, using the formula 2^(32−prefix) − 2.)*
*In AWS, a subnet reserves **5** addresses, so a /28 there gives 11 usable, not 14.*

**Why subnet?** It splits a network into smaller pieces for **security** (public web subnet vs private DB subnet), **less broadcast traffic**, and **organisation** (one subnet per team, environment or availability zone).

## Task 4: Ports
A port (0–65535) tells the OS **which application** on a machine should get the traffic. The IP finds the machine, and the port finds the process.

| Port | Service |
|---|---|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 53 | DNS |
| 3306 | MySQL |
| 6379 | Redis |
| 27017 | MongoDB |

```
$ lsof -i -P -n | grep LISTEN | grep -E ':8080|:8000'
python3   269 root    3u  IPv4   1432      0t0  TCP *:8080 (LISTEN)    ← demo web app
python3   808 root    3u  IPv4   3515      0t0  TCP *:8000 (LISTEN)    ← docs server
```
`ss -tulpn` isn't installed, so I used `lsof -i`. Both ports are Python web servers I started: **8080 = demo app**, **8000 = docs site**.

## Task 5: Putting it together
**`curl http://myapp.com:8080`:** DNS resolves `myapp.com` to an IP (A record, UDP/53). Then a TCP handshake to that IP on **port 8080**, then a plain **HTTP** request (no TLS, because it's `http`). If the server's IP is private, you need to be inside that network or go through a load balancer.

**The app can't reach the DB at `10.0.1.50:3306`:**
```
$ nc -zv -w 2 10.0.1.50 3306
nc: connect to 10.0.1.50 port 3306 (tcp) timed out
```
A **timeout** (not "refused") points to a **network block**: a security group or NACL, a missing route, or the app and DB being in different VPCs or subnets. Next checks: is MySQL running and bound to `0.0.0.0`, not `127.0.0.1`? Does the DB's security group allow 3306 *from the app's subnet*? Does `ping`/`traceroute` reach 10.0.1.50 at all?

## 3 key learnings
1. **The TTL controls how fast DNS changes spread.** Lower it *before* a migration, not during.
2. **/24 = 254 hosts, and each extra bit halves the subnet.** AWS reserves 5 IPs per subnet, not 2.
3. **"Refused" vs "timed out" is the fastest network diagnosis:** refused = the host is up but nothing is listening. Timeout = a firewall or routing problem.
