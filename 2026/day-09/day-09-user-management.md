# Day 09 – Linux User & Group Management

> Practice VM: Ubuntu 24.04 cloud microVM, run as root. Terminal output is shown as text blocks instead of screenshots.

## 1. Users created
```
$ useradd -m -s /bin/bash tokyo && useradd -m -s /bin/bash berlin && useradd -m -s /bin/bash professor
$ passwd tokyo    # (and berlin, professor) – passwords set, not shown

$ grep -E '^(tokyo|berlin|professor):' /etc/passwd
tokyo:x:30034:30034::/home/tokyo:/bin/bash
berlin:x:30035:30035::/home/berlin:/bin/bash
professor:x:30036:30036::/home/professor:/bin/bash

$ ls -l /home | grep -E 'tokyo|berlin|professor'
drwxr-x---  2 berlin    berlin    4096 Oct  4 19:13 berlin
drwxr-x---  2 professor professor 4096 Oct  4 19:13 professor
drwxr-x---  2 tokyo     tokyo     4096 Oct  4 19:13 tokyo
```
- `-m` creates the home directory and `-s` sets the login shell.
- The `x` in `/etc/passwd` means the password hash lives in `/etc/shadow`.

## 2. Groups created
```
$ groupadd developers && groupadd admins
$ grep -E '^(developers|admins):' /etc/group
developers:x:30037:
admins:x:30038:
```

## 3. Group membership
```
$ usermod -aG developers tokyo
$ usermod -aG developers,admins berlin
$ usermod -aG admins professor

$ groups tokyo berlin professor
tokyo : tokyo developers
berlin : berlin developers admins
professor : professor admins

$ id berlin
uid=30035(berlin) gid=30035(berlin) groups=30035(berlin),30037(developers),30038(admins)
```
⚠️ **`-aG`, not `-G`.** Without `-a` (append), `usermod -G` **replaces** all of the user's groups.

## 4. Shared directory `/opt/dev-project`
```
$ mkdir -p /opt/dev-project && chgrp developers /opt/dev-project && chmod 775 /opt/dev-project
$ ls -ld /opt/dev-project
drwxrwxr-x 2 root developers 4096 Oct  4 19:13 /opt/dev-project

$ sudo -u tokyo touch /opt/dev-project/tokyo-file.txt         # ✅
$ sudo -u berlin touch /opt/dev-project/berlin-file.txt       # ✅
$ sudo -u professor touch /opt/dev-project/professor-file.txt # ❌ not in developers
touch: cannot touch '/opt/dev-project/professor-file.txt': Permission denied
```

**Bonus: the setgid bit.** New files got the *creator's* group (`tokyo tokyo`), not `developers`. `chmod g+s` fixes that:
```
$ chmod g+s /opt/dev-project && ls -ld /opt/dev-project
drwxrwsr-x 2 root developers 4096 Oct  4 19:13 /opt/dev-project
$ sudo -u tokyo touch /opt/dev-project/after-setgid.txt && ls -l /opt/dev-project
-rw-rw-r-- 1 tokyo  developers 0 Oct  4 19:14 after-setgid.txt   ← inherits the group
-rw-rw-r-- 1 berlin berlin     0 Oct  4 19:13 berlin-file.txt
-rw-rw-r-- 1 tokyo  tokyo      0 Oct  4 19:13 tokyo-file.txt
```

## 5. Team workspace
```
$ useradd -m -s /bin/bash nairobi && groupadd project-team
$ usermod -aG project-team nairobi && usermod -aG project-team tokyo
$ getent group project-team
project-team:x:30040:nairobi,tokyo

$ mkdir -p /opt/team-workspace && chgrp project-team /opt/team-workspace && chmod 775 /opt/team-workspace
$ sudo -u nairobi touch /opt/team-workspace/nairobi-plan.txt   # ✅
$ sudo -u tokyo touch /opt/team-workspace/tokyo-notes.txt      # ✅
$ sudo -u berlin touch /opt/team-workspace/berlin-try.txt      # ❌ not in project-team
touch: cannot touch '/opt/team-workspace/berlin-try.txt': Permission denied

$ ls -ld /opt/team-workspace; ls -l /opt/team-workspace
drwxrwxr-x 2 root project-team 4096 Oct  4 19:13 /opt/team-workspace
-rw-rw-r-- 1 nairobi nairobi 0 Oct  4 19:13 nairobi-plan.txt
-rw-rw-r-- 1 tokyo   tokyo   0 Oct  4 19:13 tokyo-notes.txt
```

## Commands used
`useradd -m -s`, `passwd`, `groupadd`, `usermod -aG`, `groups`, `id`, `getent group`, `chgrp`, `chmod 775`, `chmod g+s`, `sudo -u <user>`

## 3 key points
1. **Give access through groups, not individual users.** Add a person to a group and they get its access straight away.
2. **`usermod -aG`**: forgetting `-a` silently removes a user from all their other groups.
3. **Shared folders need `775` + setgid (`g+s`)** so every new file belongs to the team group.
