# Day 28 – Revision Day (Days 1–27)

## Task 1: Self-assessment
✅ = confident (done hands-on) · 🔶 = needs work · ⬜ = not done yet

**Linux**
| Skill | Status | Evidence / gap |
|---|---|---|
| Navigation, files, text editing | ✅ | Days 03, 06, 10 |
| Processes (`ps`, `top`, `kill`, `pgrep`) | ✅ | Days 04, 05, 07 (found and killed a process using 99% CPU) |
| systemd (`systemctl`, `journalctl`) | 🔶 | My practice VM has no systemd. I know the commands but haven't run them live → do it on EC2 |
| Troubleshooting (`top`, `free`, `df`, `du`) | ✅ | Day 05 runbook |
| Filesystem hierarchy | ✅ | Day 07 |
| Users and groups | ✅ | Day 09 (plus setgid) |
| `chmod` / `chown` / `chgrp` | ✅ | Days 10–11 |
| LVM | 🔶 | Day 13: no LVM tools, so I did loop device + resize2fs instead → real `pvcreate/vgcreate/lvextend` still to do |
| Networking (`curl`, `nc`, DNS) | ✅ | Days 14–15, plus my own `minidig.py` |
| `ping`, `traceroute`, `ss`, `dig` | 🔶 | Not installed on my VM; I used alternatives |
| DNS, subnetting, ports | ✅ | Day 15 CIDR table |

**Shell scripting**
| Skill | Status | Evidence |
|---|---|---|
| Variables, arguments, `read` | ✅ | Days 16–17 |
| `if` / `case` | ✅ | Day 16 (`case` in my Day 21 cheat sheet) |
| `for` / `while` / `until` | ✅ | Day 17 |
| Functions + `local` | ✅ | Day 18 |
| grep / awk / sed / sort / uniq | ✅ | Day 20 log analyzer |
| `set -euo pipefail`, `trap` | ✅ | Day 18 demo, Day 21 |
| cron | 🔶 | Entries written, but cron isn't installed on my VM, so nothing ran on a schedule |

**Git and GitHub**
| Skill | Status | Evidence |
|---|---|---|
| init / add / commit / log | ✅ | Day 22 |
| Branches, push / pull / fetch | ✅ | Day 23 (local stand-in remote) |
| Clone vs fork | ✅ | Day 23 + my real fork sync on Day 01 |
| Merge, rebase, squash, stash, cherry-pick | ✅ | Day 24 (including a real conflict) |
| reset / revert / reflog | ✅ | Day 25 |
| Branching strategies | ✅ | Day 25 |
| GitHub CLI | 🔶 | Day 26: aliases and help only. Not logged in yet |

## Task 2: Weak-spot review (re-done)
1. **`set -euo pipefail`:** re-ran Day 18's `strict_demo.sh`:
   ```
   0
   without pipefail -> pipe exit code: 0
   0
   with pipefail -> pipe exit code: 1
   ```
   **Takeaway:** a pipe only reports its *last* command's exit code unless pipefail is on.
2. **Reset modes:** made a test commit, then `reset --soft` → `reset` (mixed) → `checkout --`, running `git status --short` each time:
   ```
   M  reset-demo.txt     ← after --soft: staged (first column)
    M reset-demo.txt     ← after mixed: unstaged (second column)
   (clean)               ← after discarding
   ```
   **Takeaway:** the *column* the `M` is in tells you staged vs unstaged.
3. **Cherry-pick dependencies:** `git show --stat 9586e6a` → `hotfix-log.txt | 1 +`. The commit only *modifies* a file that an earlier commit *created*, which is why Day 24's cherry-pick conflicted. **Takeaway:** check `git show --stat` before cherry-picking.

## Task 3: Quick-fire answers
1. **`chmod 755 script.sh`:** owner rwx, group r-x, others r-x. Everyone can run it, only the owner can edit it.
2. **Process vs service:** a process is any running program (it has a PID). A service is a long-running background process **managed by systemd** (starts at boot, restarts on failure, logs to the journal).
3. **What's using port 8080?** `ss -tulpn | grep :8080`, or `lsof -i :8080`.
4. **`set -euo pipefail`:** exit on error, error on undefined variables, and a pipeline fails if any command in it fails.
5. **`reset --hard` vs `revert`:** reset deletes commits (and changes) and rewrites history. Revert adds a new "undo" commit. For anything pushed, use revert.
6. **5-person team, weekly releases:** GitHub Flow with a release tag each week. Add a short-lived `release/x` branch only if a release needs stabilising.
7. **`git stash`:** temporarily shelves uncommitted work, e.g. an urgent hotfix arrives mid-feature. `stash` → switch → fix → come back → `stash pop`.
8. **Run a script daily at 3 AM:** `0 3 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1`
9. **`fetch` vs `pull`:** fetch downloads and updates `origin/*` without touching your files. Pull = fetch + merge.
10. **LVM:** a layer between disks and filesystems (PV → VG → LV). Volumes can be **resized online**, span several disks and be snapshotted. A plain partition is fixed in place.

## Task 4: Repo check
- ✅ Days 1–7 and 9–27 are committed to my fork, one folder per day.
- ⬜ **Day 08 (Nginx on a cloud server)** is still pending. I need a real EC2 instance.
- ✅ `git-commands.md` consolidated (Day 25), shell cheat sheet finished (Day 21), profile audit done (Day 27).

## Task 5: Teach-back, file permissions for a complete beginner
> Every file has **three groups of people**: the **owner**, the **group**, and **everyone else**. Each group can have three powers: **read (r = 4)**, **write (w = 2)** and **execute (x = 1)**. Add the numbers up to get one digit per group, so `rwx` = 7, `r-x` = 5 and `r--` = 4. That means **`chmod 755`** = "I can do everything, and everyone else can read and run it", which is perfect for a script. **`chmod 600`** = "only I can read or write it", which is perfect for an SSH key. If you get *Permission denied*, run `ls -l` first: the problem is usually a missing letter, not a need for `sudo`.

## What's next
Docker (Days 29–37), and catching up on the 🔶 items on a real EC2 instance: systemd, LVM, ping/ss/dig, cron and `gh auth`.
