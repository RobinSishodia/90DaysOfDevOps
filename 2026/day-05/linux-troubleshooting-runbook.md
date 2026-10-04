# Day 05 – Linux Troubleshooting Runbook

**Target:** `demo-web`, a Python web server (`python3 -m http.server 8080`), PID 260
**Host:** Ubuntu 24.04.5 LTS cloud microVM, kernel 6.18, 8 GB RAM, no systemd

## Environment basics
```
$ uname -a
Linux vm 6.18.44-fc-v64 #1 SMP PREEMPT_DYNAMIC @0 x86_64 x86_64 x86_64 GNU/Linux
$ uptime
 18:04:45 up 6 min,  0 user,  load average: 0.26, 0.20, 0.07
```
- The VM booted 6 minutes ago, so this is a fresh box. A load average of 0.26 is very low.

## Filesystem
```
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   14G   31G  31% /
$ du -sh /var/log /srv/demo-web
1.2M	/var/log
8.0K	/srv/demo-web
```
- The root disk is 31% used. Logs take only 1.2 MB, so there's **no risk of the disk filling up**.

## CPU and memory snapshot
```
$ ps -o pid,%cpu,%mem,rss,vsz,stat,etime,cmd -p 260
  PID %CPU %MEM   RSS    VSZ STAT     ELAPSED CMD
  260  0.2  0.2 20512 100728 S          00:37 python3 -m http.server 8080 --directory /srv/demo-web
$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       476Mi       7.4Gi        13Mi       237Mi       7.4Gi
Swap:             0B          0B          0B
```
- The service uses about 20 MB of RAM and 0.2% CPU. That's healthy.
- 7.4 GB is available. There's **no swap**, so if memory runs out, the kernel's OOM killer would end processes rather than slow down.

## Disk and I/O snapshot
```
$ vmstat 1 3
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0      0 7714580   7348 235616    0    0     0     0  127  116  1  1 99  0  0
$ cat /proc/260/io | head -4
rchar: 1884504
wchar: 444
syscr: 210
syscw: 8
```
- CPU is 99% idle with `wa` = 0, so nothing is waiting on disk. `b` = 0 means no blocked processes.
- The service has read about 1.8 MB and written very little, as you'd expect for a static file server.

## Network snapshot
```
$ lsof -i -P -n -a -p 260
COMMAND PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
python3 260 root    3u  IPv4   3088      0t0  TCP *:8080 (LISTEN)
$ curl -sI http://localhost:8080/ | head -2
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.13.16
```
- The server is listening on **all interfaces, port 8080**, and returns **200 OK**.

## Log analysis
```
$ tail -n 3 /var/log/demo-web.log
127.0.0.1 - - [04/Oct/2026 18:04:17] code 404, message File not found
127.0.0.1 - - [04/Oct/2026 18:04:17] "GET /missing.html HTTP/1.1" 404 -
127.0.0.1 - - [04/Oct/2026 18:04:47] "HEAD / HTTP/1.1" 200 -
$ grep -c ' 404 ' /var/log/demo-web.log
1
```
- There's one 404, for a missing file. It's a client-side error and the service itself is fine.

## Key findings
- The service is **healthy**: running, listening, answering with 200, and using little CPU and RAM.
- There's **no resource pressure**: disk 31%, memory 6%, I/O wait 0.
- **Risks:** there's no systemd, so nothing will restart the service if it crashes. The log file has no rotation. There's no swap.

## If this worsens
1. **Service stops responding:** check `pgrep -a python3` and `lsof -i :8080`, then capture `tail -n 100` of the log *before* restarting it. On a systemd host, use `systemctl status` / `journalctl -u`.
2. **High CPU or memory:** run `top -p 260` and `ps -o rss`. If RSS keeps growing, suspect a memory leak, restart the service, and open a bug with the evidence.
3. **Disk filling up:** run `df -h` and `du -sh /var/log/*`, then set up `logrotate` and compress or archive old logs.
4. **Escalate:** if it's still failing after one restart, page the service owner with the outputs above, plus a timeline of what changed recently.
