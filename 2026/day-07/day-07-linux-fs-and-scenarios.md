# Day 07 – Linux File System Hierarchy & Scenario-Based Practice

> Practice VM: Ubuntu 24.04 cloud microVM (hostname `vm`, no systemd).

## Part 1: File System Hierarchy

```
$ ls -l / | grep -E ' (etc|home|root|tmp|var|opt|usr)$'
drwxr-xr-x 88 root root  4096 Oct  4 19:13 etc
drwxr-xr-x  5 root root  4096 Oct  4 19:13 home
drwxr-xr-x 21 root root  4096 Oct  4 17:02 opt
drwx------ 16 root root  4096 Oct  4 19:11 root
drwxrwxrwt 11 root root  4096 Oct  4 19:13 tmp
drwxr-xr-x 12 root root  4096 Sep 17 02:20 usr
drwxr-xr-x 11 root root  4096 Sep 17 02:29 var
```

| Directory | Purpose | What I noticed | I would use this when... |
|---|---|---|---|
| `/` | The top of the whole tree. Everything starts here. | `bin`, `lib` and `sbin` are **symlinks** into `/usr` (`bin -> usr/bin`), the modern "merged /usr" layout | ...I need to find where anything lives |
| `/home` | Home directories for normal users | One folder per user (`/home/user`), each `drwxr-x---`, so other users can't look inside | ...a user's scripts or files are missing |
| `/root` | Home of the root user (not the same as `/`!) | `drwx------`: only root can even list it | ...checking root's `.bashrc` or keys |
| `/etc` | System-wide **configuration** | 88 entries, e.g. `adduser.conf`, `hostname`, `passwd`, `group` | ...changing a service's config (nginx, ssh) |
| `/var/log` | **Log files**, the first place to look during an incident | `dpkg.log` (package installs) was the biggest at 668K, plus my `demo-web.log` | ...anything breaks |
| `/tmp` | Temporary files, often cleared on reboot | `drwxrwxrwt`: the **t** (sticky bit) means users can only delete their own files | ...scratch work. Never store anything important here. |
| `/bin`, `/usr/bin` | User commands | `/bin -> usr/bin`, and `/usr/bin` holds **1,451** commands | ...checking a binary with `which <cmd>` |
| `/opt` | Optional / third-party software | `apache-maven-3.9.11`, `gradle-8.14.3`, `node22`, with symlinks `maven -> /opt/apache-maven-3.9.11` | ...installing vendor apps outside the package manager |

### Hands-on
```
$ du -sh /var/log/* 2>/dev/null | sort -h | tail -5
8.0K	/var/log/fontconfig.log
48K	/var/log/alternatives.log
60K	/var/log/bootstrap.log
388K	/var/log/apt
668K	/var/log/dpkg.log

$ cat /etc/hostname
vm

$ ls -la ~ | grep -E ' \.bashrc| \.profile'
-rw-r--r--  1 root root  3309 Oct  2 15:42 .bashrc
-rw-r--r--  1 root root   187 Oct  2 15:42 .profile
```
`du -sh ... | sort -h | tail -5` is my new favourite command: **the 5 biggest things in a folder**, which is perfect for a "disk full" alert.

---

## Part 2: Scenario Practice

### Scenario 1: `myapp` failed to start after a reboot
My order of commands:
1. `systemctl status myapp`: is it `failed`, `inactive`, or not found? What's the last log line?
2. `systemctl is-enabled myapp`: if it's `disabled`, it **was never set to start at boot**. That's the most common cause.
3. `journalctl -u myapp -n 50 --no-pager`: the actual error (bad config, missing file, port in use)
4. `journalctl -u myapp -b`: logs from **this boot only**
5. Fix it, then `sudo systemctl enable --now myapp` and check `status` again

*My VM doesn't run systemd (`journalctl` returns "No journal files were found"), so I practised this one as a written plan. I'll run it for real on an EC2 instance.*

### Scenario 2: the server is slow (high CPU), done for real
I started a CPU hog (`yes > /dev/null &`) and then hunted for it:
```
$ ps aux --sort=-%cpu | head -3
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       294 99.3  0.0   2728  1584 ?        R    19:13   0:02 yes
...
$ ps -o pid,stat,%cpu,etime,cmd -p 294
  PID STAT %CPU     ELAPSED CMD
  294 R    99.3       00:03 yes

$ kill 294; sleep 1; ps -p 294 || echo 'process gone'
process gone
```
- Found it straight away: PID 294 at **99.3% CPU**, state **R** (running).
- `kill` (SIGTERM) was enough, so I didn't need `kill -9`.
- In real life I'd **check what the process is before killing it**, because it might be a legitimate backup job.

### Scenario 3: where are the service's logs?
- systemd services: `journalctl -u docker -n 50`, and `journalctl -u docker -f` to follow
- Without systemd (my VM), ask the process where it writes:
```
$ lsof -p 269 | grep -E 'log|LISTEN'
python3 269 root    1w   REG  254,0      505 14057473 /var/log/demo-web.log
python3 269 root    3u  IPv4   1432      0t0      TCP *:http-alt (LISTEN)

$ ls -lt /var/log | head -3
-rw-r--r-- 1 root  root               505 Oct  4 19:13 demo-web.log
-rw-r--r-- 1 root  root            682125 Oct  4 17:03 dpkg.log
```
`lsof -p <PID>` shows every file a process has open, **including its log file**. `ls -lt` puts the most recently written log at the top.

### Scenario 4: "Permission denied" running backup.sh, done for real
```
$ ./backup.sh                       # as user "user"
bash: line 1: ./backup.sh: Permission denied

$ ls -l /home/user/backup.sh
-rw-r--r-- 1 user user 144 Oct  4 19:13 /home/user/backup.sh     # no x!

$ chmod +x /home/user/backup.sh
$ ls -l /home/user/backup.sh
-rwxr-xr-x 1 user user 144 Oct  4 19:13 /home/user/backup.sh

$ ./backup.sh
Backup done: /tmp/home-backup-2026-10-04.tar.gz
```

---

## Key learnings
1. **`/var/log` and `/etc` are where DevOps work happens**: logs to diagnose, configs to fix.
2. **Process first, then logs, then action.** Find the PID and see what it's doing before you kill or restart anything.
3. **"Permission denied" on a script almost always means a missing `x` bit.** Check with `ls -l` before reaching for `sudo`.
