# Day 12 – Breather & Revision (Days 01–11)

## Mindset / plan check (Day 01)
- The goals are unchanged: finish all 90 days, build real end-to-end projects, and get interview-ready.
- **Adjustment:** my practice VM has no systemd and limited internet access, so I've learned the fallbacks (`pgrep`, `lsof`, log files). **Day 08 (cloud deployment) is still pending.** I'll do it on my own AWS EC2 instance, where I can also practise `systemctl`/`journalctl` for real.

## Re-run: processes and services (Days 04–05)
```
$ ps -o pid,stat,%cpu,%mem,etime,cmd -C python3
  PID STAT %CPU %MEM     ELAPSED CMD
  269 S     0.0  0.2       01:26 python3 -m http.server 8080 --directory /srv/demo-web

$ lsof -i :8080 -P -n
COMMAND PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
python3 269 root    3u  IPv4   1432      0t0  TCP *:8080 (LISTEN)
```
**Observation:** the server is still sleeping (S) and listening. `-C python3` selects a process by name, so I don't need to look up the PID first.

## Re-run: file operations (Days 06–11)
```
$ echo 'revision line 1' > rev.txt && echo 'revision line 2' >> rev.txt && cat rev.txt
revision line 1
revision line 2
$ cp rev.txt rev-backup.txt && chmod 600 rev-backup.txt && ls -l
-rw------- 1 root root 32 Oct  4 19:14 rev-backup.txt
-rw-r--r-- 1 root root 32 Oct  4 19:14 rev.txt
```

## Re-run: users and ownership (Days 09 & 11)
```
$ useradd -m -s /bin/bash helsinki && usermod -aG developers helsinki && id helsinki
uid=30040(helsinki) gid=30047(helsinki) groups=30047(helsinki),30037(developers)
$ touch helsinki-task.txt && chown helsinki:developers helsinki-task.txt && ls -l helsinki-task.txt
-rw-r--r-- 1 helsinki developers 0 Oct  4 19:14 helsinki-task.txt
```

## My 5 go-to incident commands (from Day 03)
1. `ps aux --sort=-%cpu | head` – what's eating the CPU
2. `df -h` + `du -sh /var/log/* | sort -h | tail` – is the disk full, and with what
3. `lsof -i :<port>` / `ss -tulpn` – what's listening
4. `tail -f <log>` / `journalctl -u <svc> -f` – live logs
5. `curl -I localhost:<port>` – does it actually respond

## Self-assessment
1. **3 biggest time-savers:**
   - `du -sh * | sort -h | tail`: finds what's filling a disk in seconds.
   - `ps aux --sort=-%cpu | head`: finds the CPU hog without scrolling through `top`.
   - `lsof -p <PID>`: shows a process's log files and ports, even without systemd.
2. **First 2–3 health checks for a service:** `systemctl status <svc>` (or `pgrep -a <name>`) → `ss -tulpn | grep <port>` (or `lsof -i :<port>`) → `curl -I localhost:<port>`
3. **A safe ownership/permission change:** `chown helsinki:developers helsinki-task.txt && ls -l helsinki-task.txt`. It targets one exact file, with no `-R` and no wildcards, and I verify straight after.
4. **Focus for the next 3 days:** LVM and storage (Day 13), networking checks (Day 14), and DNS, IP, subnets and ports (Day 15).

## What stuck
- **Permissions:** r=4, w=2, x=1, and always test as a normal user.
- **`usermod -aG`**, never `-G` on its own.
- **Gather evidence before restarting anything.**
