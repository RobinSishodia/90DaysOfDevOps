# Day 06 – Reading and Writing Text Files

> Practice VM: Ubuntu 24.04 cloud microVM.

## Commands I ran
```
$ touch notes.txt                                            # create an empty file
$ echo 'Day 06 - Linux file I/O practice' > notes.txt        # > overwrite: write line 1
$ echo 'Logs, configs and scripts are all text files' >> notes.txt   # >> append: line 2
$ echo 'tee writes to a file AND shows the output' | tee -a notes.txt
tee writes to a file AND shows the output                    # printed AND appended
$ date '+Practised on: %Y-%m-%d' >> notes.txt                # append a command's output
$ uname -sr | tee -a notes.txt
Linux 6.18.44-fc-v64
$ printf 'Line 6: > overwrites\nLine 7: >> appends\nLine 8: head shows the top\nLine 9: tail shows the bottom\n' >> notes.txt
```

## Reading the file
```
$ cat notes.txt
Day 06 - Linux file I/O practice
Logs, configs and scripts are all text files
tee writes to a file AND shows the output
Practised on: 2026-10-04
Linux 6.18.44-fc-v64
Line 6: > overwrites
Line 7: >> appends
Line 8: head shows the top
Line 9: tail shows the bottom

$ wc -l notes.txt
9 notes.txt

$ head -n 2 notes.txt
Day 06 - Linux file I/O practice
Logs, configs and scripts are all text files

$ tail -n 2 notes.txt
Line 8: head shows the top
Line 9: tail shows the bottom

$ cat -n notes.txt | grep -i tee
     3	tee writes to a file AND shows the output
```

## The `>` trap
```
$ echo 'oops' > test.txt; echo 'replaced' > test.txt; cat test.txt
replaced
```
`>` **wipes the file** before writing. Use `>>` when you mean to add.

## What each one does
| Command | Effect |
|---|---|
| `>` | Redirect output into a file, **overwriting** it |
| `>>` | Redirect output to the **end** of a file |
| `tee file` | Write to a file **and** the screen (`-a` to append) |
| `cat` | Print the whole file |
| `head -n N` / `tail -n N` | First / last N lines |
| `tail -f` | Follow a file as it grows (live logs) |

## Why it matters in DevOps
- `echo "export ENV=prod" >> ~/.bashrc` adds a line to a config file.
- `./deploy.sh | tee deploy.log` lets you watch a deploy *and* keep a record.
- `sudo tee /etc/app.conf` is the way to write a root-owned file, because a plain `sudo echo ... > file` fails: the redirect runs as your user, not root.
- `tail -f /var/log/app.log` lets you watch an incident live.
