# Day 18 – Functions & Intermediate Scripting

> Practice VM: Ubuntu 24.04 cloud microVM. All scripts are in this folder.

## Task 1: Functions – `functions.sh`
```bash
#!/bin/bash
greet() {
    echo "Hello, $1!"
}

add() {
    local sum=$(( $1 + $2 ))
    echo "$1 + $2 = $sum"
}

greet "Robin"
greet "DevOps"
add 10 25
```
```
$ ./functions.sh
Hello, Robin!
Hello, DevOps!
10 + 25 = 35
```
Inside a function, `$1`, `$2`… are the **function's** arguments, not the script's.

## Task 2: `disk_check.sh`
```bash
#!/bin/bash
check_disk()   { echo "--- Disk usage (/) ---"; df -h /; }
check_memory() { echo "--- Memory ---"; free -h; }
main() { check_disk; echo; check_memory; }
main
```
```
$ ./disk_check.sh
--- Disk usage (/) ---
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   15G   29G  34% /

--- Memory ---
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       474Mi       7.3Gi        13Mi       263Mi       7.4Gi
Swap:             0B          0B          0B
```
*(The committed script uses multi-line functions. They're condensed here for readability.)*

## Task 3: `set -euo pipefail` – `strict_demo.sh`
Each demo runs in a child `bash -c` so one failure doesn't stop the others:
```
$ ./strict_demo.sh
=== 1) set -u : using an undefined variable ===
without -u -> [] (empty, no error)
bash: line 1: UNDEFINED_VAR: unbound variable
exit code: 127

=== 2) set -e : a command fails ===
without -e -> script keeps going after failure
exit code: 1

=== 3) set -o pipefail : a command fails inside a pipe ===
0
without pipefail -> pipe exit code: 0
0
with pipefail -> pipe exit code: 1
```
| Flag | What it does | Why it matters |
|---|---|---|
| `-e` | Exit as soon as any command fails | Stops a deploy script from carrying on after a failed step |
| `-u` | Treat undefined variables as errors | A typo like `rm -rf "$DIRR/"` becomes an error instead of `rm -rf /` |
| `-o pipefail` | A pipe fails if **any** command in it fails | Without it, `cat missing | wc -l` "succeeds" because `wc` succeeded |

**The pipefail demo is the scariest one:** `cat` failed, but without pipefail the pipe returned **0 (success)**.

## Task 4: `local` – `local_demo.sh`
```bash
#!/bin/bash
with_local() {
    local msg="I am LOCAL to with_local()"
    echo "inside with_local:    $msg"
}
without_local() {
    leaked="I was set inside without_local() but I leak out"
    echo "inside without_local: $leaked"
}
with_local
echo "outside after with_local:    [${msg:-<empty>}]"
without_local
echo "outside after without_local: [$leaked]"
```
```
$ ./local_demo.sh
inside with_local:    I am LOCAL to with_local()
outside after with_local:    [<empty>]
inside without_local: I was set inside without_local() but I leak out
outside after without_local: [I was set inside without_local() but I leak out]
```
Bash variables are **global by default**. Without `local`, a function can silently overwrite a variable the rest of the script relies on.

## Task 5: `system_info.sh`
```bash
#!/bin/bash
set -euo pipefail

header() { echo; echo "=============================="; echo " $1"; echo "=============================="; }

host_info()   { header "Host & OS"; echo "Hostname : $(hostname)"
                echo "OS       : $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
                echo "Kernel   : $(uname -r)"; }
uptime_info() { header "Uptime"; uptime -p; }
disk_info()   { header "Top 5 largest directories in /var"; du -sh /var/* 2>/dev/null | sort -rh | head -5 || true; }
memory_info() { header "Memory"; free -h; }
cpu_info()    { header "Top 5 CPU processes"; ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6; }

main() {
    echo "System report generated: $(date '+%Y-%m-%d %H:%M:%S')"
    host_info; uptime_info; disk_info; memory_info; cpu_info
}
main
```
```
$ ./system_info.sh
System report generated: 2026-10-06 18:50:30

==============================
 Host & OS
==============================
Hostname : vm
OS       : Ubuntu 24.04.5 LTS
Kernel   : 6.18.44-fc-v70

==============================
 Uptime
==============================
up 1 minute

==============================
 Top 5 largest directories in /var
==============================
181M	/var/lib
4.8M	/var/cache
1.2M	/var/log
20K	/var/spool
4.0K	/var/tmp

==============================
 Memory
==============================
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       479Mi       7.3Gi        13Mi       275Mi       7.4Gi
Swap:             0B          0B          0B

==============================
 Top 5 CPU processes
==============================
  PID COMMAND         %CPU %MEM
   ... (the practice VM's own agent and system processes)
```
**Why `|| true` on the `du` line:** with `set -euo pipefail`, that pipeline can return non-zero even when the output is fine. `du` exits with an error if it hits an unreadable directory, and `head` closing the pipe early can make earlier commands fail. Without `|| true`, a single permission warning would kill the whole report.

## Key learnings
1. **Functions + a `main()` turn a script into readable building blocks.** Each function does one job.
2. **`set -euo pipefail` belongs at the top of every serious script.** pipefail especially, because pipes hide failures.
3. **Use `local` inside functions.** Bash variables are global by default and will leak.
