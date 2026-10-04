# Day 03 – Linux Commands Cheat Sheet

## Navigation and files
| Command | Use |
|---|---|
| `pwd` | Show the current directory |
| `ls -lah` | List all files with sizes, permissions and hidden files |
| `cd -` | Jump back to the previous directory |
| `mkdir -p a/b/c` | Create nested directories in one go |
| `cp -r src/ dest/` | Copy a directory recursively |
| `mv old new` | Move or rename a file |
| `rm -rf dir/` | Delete a directory and its contents (no undo!) |
| `find / -name "*.log" -mtime -1` | Find .log files modified in the last day |

## Viewing and searching text
| Command | Use |
|---|---|
| `cat file` | Print a whole file |
| `less file` | Scroll through a big file (`/` to search, `q` to quit) |
| `head -n 20 file` / `tail -n 20 file` | First or last 20 lines |
| `tail -f /var/log/syslog` | Follow a log live |
| `grep -i "error" app.log` | Search for text, ignoring case |
| `grep -rn "TODO" .` | Search recursively, with line numbers |
| `wc -l file` | Count lines |

## Processes
| Command | Use |
|---|---|
| `ps aux` | All running processes |
| `ps aux --sort=-%mem \| head` | Top memory users |
| `top` / `htop` | Live CPU and memory view |
| `pgrep -a nginx` | Find a PID by process name |
| `kill PID` / `kill -9 PID` | Stop a process gracefully / force it |
| `systemctl status nginx` | Check a service's status |
| `journalctl -u nginx --since "1 hour ago"` | Recent logs for a service |

## Disk and system
| Command | Use |
|---|---|
| `df -h` | Free disk space per file system |
| `du -sh *` | Size of each item in this directory |
| `free -h` | RAM and swap usage |
| `uptime` | How long the system has been up, and its load average |
| `uname -a` | Kernel and OS info |

## Permissions and users
| Command | Use |
|---|---|
| `chmod 755 script.sh` | rwx for the owner, r-x for everyone else |
| `chown user:group file` | Change a file's owner |
| `whoami` / `id` | Current user and their groups |
| `sudo -i` | Become root (carefully) |

## Networking
| Command | Use |
|---|---|
| `ping -c 4 google.com` | Is the host reachable? |
| `ip addr` | Show IP addresses and interfaces |
| `ss -tulpn` | Which ports are listening, and which process owns each |
| `curl -I https://example.com` | Check HTTP status and headers |
| `dig example.com +short` | DNS lookup |
| `lsof -i :8080` | Which process is using port 8080 |

## My troubleshooting order
`systemctl status` → `journalctl -u` → `top` / `free -h` / `df -h` → `ss -tulpn` → `curl`
