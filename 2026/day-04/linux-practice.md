# Day 04 – Linux Practice: Processes, Services and Logs

> Practice VM: Ubuntu 24.04 cloud microVM. **Target service:** a small web server (`python3 -m http.server 8080`) that writes its access log to `/var/log/demo-web.log`.

## 1. Process checks
```
$ pgrep -a python3
260 python3 -m http.server 8080 --directory /srv/demo-web

$ ps -o pid,ppid,user,stat,%cpu,%mem,etime,cmd -p 260
  PID  PPID USER     STAT %CPU %MEM     ELAPSED CMD
  260     1 root     S     0.2  0.2       00:37 python3 -m http.server 8080 --directory /srv/demo-web

$ top -b -n 1 | head -5
top - 18:04:31 up 6 min,  0 user,  load average: 0.33, 0.21, 0.08
Tasks:  64 total,   1 running,  63 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni, 95.2 id,  4.8 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   8031.1 total,   7539.1 free,    471.2 used,    236.2 buff/cache
```
- The server is running as PID 260. Its state is **S** (sleeping while it waits for requests), which is normal.
- The system is mostly idle: load is about 0.3, and there are no zombie or stopped processes.

## 2. Service checks
```
$ systemctl status cron
System has not been booted with systemd as init system (PID 1). Can't operate.

$ systemctl list-units --type=service | head -5
System has not been booted with systemd as init system (PID 1). Can't operate.

$ lsof -i :8080
COMMAND PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
python3 260 root    3u  IPv4   3088      0t0  TCP *:http-alt (LISTEN)
```
- `systemctl` doesn't work here because PID 1 isn't systemd (this is a microVM). Lesson: **check what's managing services before trusting `systemctl`.**
- Without systemd, I confirmed the service is healthy another way: it's **listening on port 8080**.

## 3. Log checks
```
$ tail -n 5 /var/log/demo-web.log
127.0.0.1 - - [04/Oct/2026 18:04:17] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [04/Oct/2026 18:04:17] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [04/Oct/2026 18:04:17] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [04/Oct/2026 18:04:17] code 404, message File not found
127.0.0.1 - - [04/Oct/2026 18:04:17] "GET /missing.html HTTP/1.1" 404 -

$ grep -c ' 200 ' /var/log/demo-web.log
3
$ grep ' 404 ' /var/log/demo-web.log
127.0.0.1 - - [04/Oct/2026 18:04:17] "GET /missing.html HTTP/1.1" 404 -
```
- There were 3 successful requests and 1 **404** for `/missing.html`. The 404 is a client asking for a file that doesn't exist, not a server failure.

## 4. Troubleshooting steps (my checklist)
1. **Is it running?** `pgrep -a <name>` / `systemctl status <svc>`
2. **Is it listening?** `lsof -i :<port>` / `ss -tulpn`
3. **Does it respond?** `curl -I localhost:<port>`
4. **What do the logs say?** `journalctl -u <svc>` / `tail -n 50 <logfile>` / `grep -i error`
5. **Is the box healthy?** `top`, `free -h`, `df -h`
6. **Fix and restart**, then re-check steps 1–4.

On a systemd VM, the same checks would be `systemctl status ssh` and `journalctl -u ssh -n 50`.
