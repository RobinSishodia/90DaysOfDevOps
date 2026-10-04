# Day 10 – File Permissions & File Operations

> Practice VM: Ubuntu 24.04, run as a **normal user** (`user`), because root ignores most permission checks. Output is shown as text instead of screenshots.

## Task 1: Files created
```
$ touch devops.txt
$ echo 'DevOps notes: permissions are rwx for owner, group, others' > notes.txt
$ vim script.sh            # typed: echo "Hello DevOps", then :wq
$ ls -l
-rw-r--r-- 1 user user  0 Oct  4 19:14 devops.txt
-rw-r--r-- 1 user user 59 Oct  4 19:14 notes.txt
-rw-r--r-- 1 user user 20 Oct  4 19:14 script.sh
```

## Task 2: Reading files
```
$ cat notes.txt
DevOps notes: permissions are rwx for owner, group, others

$ vim -R script.sh         # read-only mode
echo "Hello DevOps"

$ head -n 5 /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync

$ tail -n 5 /etc/passwd
user:x:30033:30033::/home/user:/bin/bash
tokyo:x:30034:30034::/home/tokyo:/bin/bash
berlin:x:30035:30035::/home/berlin:/bin/bash
professor:x:30036:30036::/home/professor:/bin/bash
nairobi:x:30037:30039::/home/nairobi:/bin/bash
```
`/etc/passwd` starts with system accounts (shell `nologin`) and ends with the users I created on Day 09.

## Task 3: Understanding permissions
```
-rw-r--r--  →  [-][rw-][r--][r--]
               type owner group others
```
| | r | w | x |
|---|---|---|---|
| Value | 4 | 2 | 1 |

`rw-r--r--` = 6 4 4 = **644**: the owner can read and write, the group and others can only read. **Nobody** could execute any of the 3 new files.

## Task 4: Changing permissions (before → after)
```
$ chmod +x script.sh && ./script.sh
Hello DevOps
$ chmod a-w devops.txt
$ chmod 640 notes.txt
$ mkdir project && chmod 755 project
$ ls -l
-r--r--r-- 1 user user    0 Oct  4 19:14 devops.txt
-rw-r----- 1 user user   59 Oct  4 19:14 notes.txt
drwxr-xr-x 2 user user 4096 Oct  4 19:14 project
-rwxr-xr-x 1 user user   20 Oct  4 19:14 script.sh
```
| File | Before | After | Meaning |
|---|---|---|---|
| script.sh | 644 `rw-r--r--` | 755 `rwxr-xr-x` | Anyone can run it, only I can edit it |
| devops.txt | 644 `rw-r--r--` | 444 `r--r--r--` | Read-only for everyone |
| notes.txt | 644 `rw-r--r--` | 640 `rw-r-----` | Group can read, others get nothing |
| project/ | (new) | 755 `rwxr-xr-x` | Normal directory permissions (`x` on a directory = can `cd` into it) |

## Task 5: Testing permissions (errors)
```
$ echo 'try' >> devops.txt
bash: line 1: devops.txt: Permission denied          ← no w bit

$ chmod -x script.sh && ./script.sh
bash: line 1: ./script.sh: Permission denied         ← no x bit

$ bash script.sh
Hello DevOps                                         ← bash only needs to READ the file
```

## Commands used
`touch`, `echo >`, `vim`, `vim -R`, `cat`, `head`, `tail`, `ls -l`, `chmod +x`, `chmod a-w`, `chmod 640`, `chmod 755`, `mkdir`

## 3 key learnings
1. **r = 4, w = 2, x = 1.** Add them up for each of owner, group and others: `755`, `644`, `640`, `600`.
2. **`./script.sh` needs `x`, but `bash script.sh` only needs `r`.** That's useful to know when you're debugging.
3. **Test permissions as a normal user.** Root bypasses read and write checks, so your tests will lie to you.
