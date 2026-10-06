# Day 16 – Shell Scripting Basics

> Practice VM: Ubuntu 24.04 cloud microVM (no systemd). All scripts are in this folder. Interactive input was piped in with `echo` so the runs are reproducible.

## Task 1: First script – `hello.sh`
```bash
#!/bin/bash
# My first shell script
echo "Hello, DevOps!"
```
```
$ chmod +x hello.sh && ./hello.sh
Hello, DevOps!
```

### What happens without a shebang?
`no_shebang.sh` has no `#!` line and uses the bash-only `[[ ]]` test:
```
$ bash -c ./no_shebang.sh
No shebang here. My shell is: /usr/bin/bash
bash-only [[ ]] syntax worked

$ dash -c ./no_shebang.sh
No shebang here. My shell is: /usr/bin/dash
./no_shebang.sh: 2: [[: not found
```
**Without a shebang, the script runs in whatever shell launched it.** From bash it works. From `sh`/`dash` (the default `/bin/sh` on Ubuntu, used by cron and many CI systems) bash features break. **`#!/bin/bash` makes the interpreter explicit.**

## Task 2: Variables – `variables.sh`
```bash
#!/bin/bash
NAME="Robin"
ROLE="DevOps Engineer"
echo "Hello, I am $NAME and I am a $ROLE"
echo 'Single quotes: Hello, I am $NAME'
echo "Double quotes: Hello, I am $NAME"
```
```
$ ./variables.sh
Hello, I am Robin and I am a DevOps Engineer
Single quotes: Hello, I am $NAME
Double quotes: Hello, I am Robin
```
- **No spaces around `=`.** `NAME = "Robin"` would try to run a command called `NAME`.
- **Single quotes** = literal text. **Double quotes** = variables get expanded.

## Task 3: User input – `greet.sh`
```bash
#!/bin/bash
read -p "Enter your name: " name
read -p "Enter your favourite DevOps tool: " tool
echo "Hello $name, your favourite tool is $tool"
```
```
$ echo -e "Robin\nDocker" | ./greet.sh
Hello Robin, your favourite tool is Docker
```

## Task 4: Conditionals
**`check_number.sh`**
```bash
#!/bin/bash
read -p "Enter a number: " num
if [ "$num" -gt 0 ]; then
    echo "$num is positive"
elif [ "$num" -lt 0 ]; then
    echo "$num is negative"
else
    echo "The number is zero"
fi
```
```
$ echo 42 | ./check_number.sh
42 is positive
$ echo -7 | ./check_number.sh
-7 is negative
$ echo 0 | ./check_number.sh
The number is zero
```

**`file_check.sh`**
```bash
#!/bin/bash
read -p "Enter a file name: " file
if [ -f "$file" ]; then
    echo "File '$file' exists"
else
    echo "File '$file' does not exist"
fi
```
```
$ echo hello.sh | ./file_check.sh
File 'hello.sh' exists
$ echo missing.txt | ./file_check.sh
File 'missing.txt' does not exist
```

## Task 5: Putting it together – `server_check.sh`
```bash
#!/bin/bash
service="ssh"
read -p "Do you want to check the status of '$service'? (y/n): " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    if command -v systemctl >/dev/null && [ -d /run/systemd/system ]; then
        systemctl status "$service" --no-pager
    else
        echo "systemd is not running here - checking the process instead:"
        pgrep -a "${service}d" || echo "$service is not running"
    fi
else
    echo "Skipped."
fi
```
```
$ echo y | ./server_check.sh
systemd is not running here - checking the process instead:
ssh is not running
$ echo n | ./server_check.sh
Skipped.
```
My VM has no systemd (see Day 02), so I added a **fallback**: if systemd isn't running, check the process with `pgrep`. On a normal server it runs `systemctl status ssh`.

## Key learnings
1. **The shebang picks the interpreter.** Without it, `[[ ]]` and other bash features break under `sh`.
2. **`VAR=value` with no spaces, and quote your variables** (`"$file"`) so empty values and spaces don't break tests.
3. **Scripts should handle the environment they actually run in.** Checking `command -v` / `[ -d /run/systemd/system ]` before calling `systemctl` makes them portable.
