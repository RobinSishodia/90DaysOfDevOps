# Shell Scripting Cheat Sheet

> My own reference, built from Days 16–20. Every example was tested in bash 5 on Ubuntu 24.04.

---

## 1. Basics

### Shebang
```bash
#!/bin/bash          # first line: which interpreter runs the script
#!/usr/bin/env bash  # portable: finds bash in $PATH
```
Without it, the script runs in whatever shell called it. Under `sh`/`dash`, bash-only syntax like `[[ ]]` breaks.

### Running a script
```bash
chmod +x script.sh && ./script.sh   # needs the x bit
bash script.sh                      # only needs r (bash reads the file)
source script.sh                    # runs in the CURRENT shell (variables persist)
```

### Comments
```bash
# full-line comment
echo "hi"   # inline comment
```

### Variables and quoting
```bash
NAME="Robin"            # no spaces around =
echo "Hi $NAME"         # double quotes → expands → Hi Robin
echo 'Hi $NAME'         # single quotes → literal → Hi $NAME
echo "${NAME}_backup"   # braces when text follows
TODAY=$(date +%F)       # command substitution
COUNT=$((5 + 3))        # arithmetic
echo "${PORT:-8080}"    # default if unset/empty
```

### User input
```bash
read -p "Name: " name
read -sp "Password: " pass   # silent (no echo)
```

### Arguments
| Var | Meaning |
|---|---|
| `$0` | script name |
| `$1..$9` | positional args |
| `$#` | number of args |
| `$@` | all args (as separate words) |
| `$?` | exit code of the last command |
| `$$` | PID of the current shell |

---

## 2. Operators and conditionals

### String tests
```bash
[ "$a" = "$b" ]    # equal
[ "$a" != "$b" ]   # not equal
[ -z "$a" ]        # empty
[ -n "$a" ]        # not empty
```

### Integer tests
```bash
[ "$n" -eq 5 ]  [ "$n" -ne 5 ]
[ "$n" -lt 5 ]  [ "$n" -gt 5 ]
[ "$n" -le 5 ]  [ "$n" -ge 5 ]
```

### File tests
| Test | True if… |
|---|---|
| `-f` | regular file exists |
| `-d` | directory exists |
| `-e` | anything exists |
| `-r` / `-w` / `-x` | readable / writable / executable |
| `-s` | file exists and is not empty |

### if / elif / else
```bash
if [ "$n" -gt 0 ]; then
    echo "positive"
elif [ "$n" -lt 0 ]; then
    echo "negative"
else
    echo "zero"
fi
```

### Logical operators
```bash
[ -f app.conf ] && echo "found"          # run if previous succeeded
cd /app || { echo "no /app"; exit 1; }   # run if previous failed
if ! command -v docker >/dev/null; then echo "install docker"; fi
[[ "$env" == "prod" && "$user" != "root" ]]   # bash [[ ]] allows && || inside
```

### case
```bash
case "$1" in
    start)   echo "starting" ;;
    stop)    echo "stopping" ;;
    restart) echo "restarting" ;;
    *)       echo "Usage: $0 {start|stop|restart}"; exit 1 ;;
esac
```

---

## 3. Loops
```bash
for pkg in nginx curl wget; do echo "$pkg"; done   # list
for i in {1..5}; do echo "$i"; done                # range
for ((i=0; i<5; i++)); do echo "$i"; done          # C-style

n=5; while [ "$n" -gt 0 ]; do echo $n; n=$((n-1)); done
until ping -c1 -W1 db >/dev/null 2>&1; do sleep 2; done   # wait until db is reachable

for f in /var/log/*.log; do echo "$f"; done        # files
while IFS= read -r line; do echo "$line"; done < hosts.txt   # lines of a file
for user in $(cut -d: -f1 /etc/passwd); do echo "$user"; done  # command output
```
`break` exits the loop, and `continue` skips to the next iteration.

---

## 4. Functions
```bash
greet() {
    local name="$1"          # local = doesn't leak outside
    echo "Hello, $name"
}
greet "Robin"

is_up() { curl -sf "$1" >/dev/null; }   # return value = exit code
if is_up http://localhost:8080; then echo "up"; fi

add() { echo $(( $1 + $2 )); }
result=$(add 2 3)        # "return" data via echo + command substitution → 5
```
`return N` sets the **exit status** (0–255). To return data, use `echo` and capture it.

---

## 5. Text processing
| Command | Common use |
|---|---|
| `grep -i -n -c -v -r -E` | ignore case, line numbers, count, invert, recursive, regex |
| `awk '{print $1}'` | print column 1 |
| `awk -F: '{print $1}' /etc/passwd` | custom delimiter |
| `awk '$9==500' access.log` | filter rows by a field |
| `sed 's/old/new/g' file` | replace (print) |
| `sed -i 's/old/new/g' file` | replace in place |
| `sed -n '10,20p' file` | print lines 10–20 |
| `cut -d, -f2 file.csv` | 2nd CSV column |
| `sort -n -r -k2 -u` | numeric, reverse, by column 2, unique |
| `uniq -c` | count adjacent duplicates (sort first!) |
| `tr 'a-z' 'A-Z'` / `tr -d '\r'` | translate / delete characters |
| `wc -l -w -c` | lines, words, bytes |
| `head -n 20` / `tail -n 20` / `tail -f` | top, bottom, follow |

---

## 6. Useful one-liners
```bash
# Top 10 IPs hitting nginx
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head

# Top 5 error messages (strip timestamp first)
grep ERROR app.log | sed -E 's/^[0-9-]+ [0-9:]+ //' | sort | uniq -c | sort -rn | head -5

# 5 biggest things in a directory
du -sh /var/log/* 2>/dev/null | sort -h | tail -5

# Delete logs older than 30 days
find /var/log/myapp -name "*.gz" -mtime +30 -delete

# Replace a value in every .conf file
sed -i 's/old-db-host/new-db-host/g' /etc/myapp/*.conf

# Restart a service only if it's down
systemctl is-active --quiet nginx || sudo systemctl restart nginx

# Watch memory every 2 seconds
watch -n 2 free -h

# Alert if the disk is over 80%
[ "$(df / --output=pcent | tail -1 | tr -dc 0-9)" -gt 80 ] && echo "DISK ALERT"
```

---

## 7. Error handling and debugging
```bash
set -e            # exit on any error
set -u            # error on undefined variables
set -o pipefail   # a pipe fails if any part fails
set -x            # print each command before running it (debug)
set -euo pipefail # ← put this at the top of every serious script

cmd
echo $?                  # 0 = success, anything else = failure
exit 1                   # signal failure to cron / CI

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT          # always clean up, even on error
trap 'echo "failed at line $LINENO"' ERR
```
Debug a script without editing it: `bash -x script.sh`

---

## 8. Quick reference
| Topic | Syntax |
|---|---|
| Variable | `VAR="x"` → `"$VAR"` / `"${VAR}"` |
| Default value | `"${VAR:-default}"` |
| Command output | `$(cmd)` |
| Math | `$((a + b))` |
| Args | `$1 $# $@ $0 $?` |
| If | `if [ cond ]; then …; elif …; else …; fi` |
| Case | `case $x in a) … ;; *) … ;; esac` |
| For | `for x in list; do …; done` |
| While | `while [ cond ]; do …; done` |
| Function | `name() { local v="$1"; … }` |
| Read a file | `while IFS= read -r l; do …; done < file` |
| Strict mode | `set -euo pipefail` |
| Cleanup | `trap '…' EXIT` |
| Cron | `m h dom mon dow cmd` → `0 2 * * * /path/script.sh` |
