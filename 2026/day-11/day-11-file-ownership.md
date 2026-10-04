# Day 11 – File Ownership (chown & chgrp)

> Practice VM: Ubuntu 24.04, run as root (only root can give files away). Output is shown as text instead of screenshots.

## Task 1: Owner vs group
```
$ ls -l /home/user
-rwxr-xr-x 1 user user  144 Oct  4 19:13 backup.sh
drwxr-xr-x 3 user user 4096 Oct  4 19:14 day10
            ↑    ↑
          owner group
```
- **Owner**: the single user the `rwx` in positions 2–4 applies to
- **Group**: everyone in that group gets the `rwx` in positions 5–7

## Task 2: Changing the owner
```
$ touch devops-file.txt && ls -l devops-file.txt
-rw-r--r-- 1 root root 0 Oct  4 19:14 devops-file.txt
$ chown tokyo devops-file.txt && ls -l devops-file.txt
-rw-r--r-- 1 tokyo root 0 Oct  4 19:14 devops-file.txt
$ chown berlin devops-file.txt && ls -l devops-file.txt
-rw-r--r-- 1 berlin root 0 Oct  4 19:14 devops-file.txt
```

## Task 3: Changing the group
```
$ touch team-notes.txt && ls -l team-notes.txt
-rw-r--r-- 1 root root 0 Oct  4 19:14 team-notes.txt
$ groupadd heist-team
$ chgrp heist-team team-notes.txt && ls -l team-notes.txt
-rw-r--r-- 1 root heist-team 0 Oct  4 19:14 team-notes.txt
```

## Task 4: Owner and group in one command
```
$ touch project-config.yaml && mkdir -p app-logs
$ ls -ld project-config.yaml app-logs
drwxr-xr-x 2 root root 4096 Oct  4 19:14 app-logs
-rw-r--r-- 1 root root    0 Oct  4 19:14 project-config.yaml

$ chown professor:heist-team project-config.yaml && chown berlin:heist-team app-logs
$ ls -ld project-config.yaml app-logs
drwxr-xr-x 2 berlin    heist-team 4096 Oct  4 19:14 app-logs
-rw-r--r-- 1 professor heist-team    0 Oct  4 19:14 project-config.yaml
```

## Task 5: Recursive ownership
```
$ mkdir -p heist-project/vault heist-project/plans
$ touch heist-project/vault/gold.txt heist-project/plans/strategy.conf
$ groupadd planners
$ chown -R professor:planners heist-project
$ ls -lR heist-project
heist-project:
drwxr-xr-x 2 professor planners 4096 Oct  4 19:14 plans
drwxr-xr-x 2 professor planners 4096 Oct  4 19:14 vault

heist-project/plans:
-rw-r--r-- 1 professor planners 0 Oct  4 19:14 strategy.conf

heist-project/vault:
-rw-r--r-- 1 professor planners 0 Oct  4 19:14 gold.txt
```
One command updated **every directory and file** in the tree.

## Task 6: Mixed ownership in one directory
```
$ useradd -m -s /bin/bash rio && useradd -m -s /bin/bash denver && groupadd vault-team && groupadd tech-team
$ mkdir -p bank-heist && touch bank-heist/access-codes.txt bank-heist/blueprints.pdf bank-heist/escape-plan.txt
$ chown tokyo:vault-team   bank-heist/access-codes.txt
$ chown berlin:tech-team   bank-heist/blueprints.pdf
$ chown nairobi:vault-team bank-heist/escape-plan.txt
$ ls -l bank-heist
-rw-r--r-- 1 tokyo   vault-team 0 Oct  4 19:14 access-codes.txt
-rw-r--r-- 1 berlin  tech-team  0 Oct  4 19:14 blueprints.pdf
-rw-r--r-- 1 nairobi vault-team 0 Oct  4 19:14 escape-plan.txt
```

## Commands used
`ls -l`, `ls -lR`, `chown user file`, `chgrp group file`, `chown user:group file`, `chown -R user:group dir`, `groupadd`, `useradd`

## 3 key learnings
1. **`chown user:group` does both in one step.** `chown :group` changes only the group, the same as `chgrp`.
2. **`chown -R` is powerful and dangerous.** Run it on the wrong path (say `/`) and you can break the system. Check the path twice.
3. **Ownership and permissions work together.** A real-world example: the nginx web root should be owned by `www-data`, or the server can't read its own files.
