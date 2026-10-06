# Day 17 – Loops, Arguments & Error Handling

> Practice VM: Ubuntu 24.04 cloud microVM. All scripts are in this folder.

## Task 1: For loops
**`for_loop.sh`**
```bash
#!/bin/bash
for fruit in Apple Banana Mango Orange Grapes; do
    echo "Fruit: $fruit"
done
```
```
$ ./for_loop.sh
Fruit: Apple
Fruit: Banana
Fruit: Mango
Fruit: Orange
Fruit: Grapes
```
**`count.sh`**
```bash
#!/bin/bash
for i in {1..10}; do
    echo "$i"
done
```
```
$ ./count.sh
1
2
...
10
```

## Task 2: While loop – `countdown.sh`
```bash
#!/bin/bash
read -p "Enter a number to count down from: " n
while [ "$n" -ge 0 ]; do
    echo "$n"
    n=$((n - 1))
done
echo "Done!"
```
```
$ echo 5 | ./countdown.sh
5
4
3
2
1
0
Done!
```

## Task 3: Command-line arguments
**`greet.sh`**
```bash
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi
echo "Hello, $1!"
```
```
$ ./greet.sh Robin
Hello, Robin!
$ ./greet.sh; echo "exit code: $?"
Usage: ./greet.sh <name>
exit code: 1
```
**`args_demo.sh`**
```bash
#!/bin/bash
echo "Script name   (\$0): $0"
echo "Arg count     (\$#): $#"
echo "All arguments (\$@): $@"
echo "First arg     (\$1): $1"
```
```
$ ./args_demo.sh docker k8s terraform
Script name   ($0): ./args_demo.sh
Arg count     ($#): 3
All arguments ($@): docker k8s terraform
First arg     ($1): docker
```

## Task 4 + 5: Install packages (with a root check) – `install_packages.sh`
```bash
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: please run as root (sudo $0)"
    exit 1
fi

packages=(nginx curl wget)

for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "[OK]       $pkg is already installed"
    else
        echo "[MISSING]  $pkg - installing..."
        if timeout 120 apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
            echo "[INSTALLED] $pkg"
        else
            echo "[FAILED]   $pkg could not be installed (check network / apt sources)"
        fi
    fi
done
```
```
$ runuser -u tokyo -- ./install_packages.sh; echo "exit code: $?"
ERROR: please run as root (sudo ./install_packages.sh)
exit code: 1

$ ./install_packages.sh
[MISSING]  nginx - installing...
[FAILED]   nginx could not be installed (check network / apt sources)
[OK]       curl is already installed
[OK]       wget is already installed
```
- **The root check works:** a normal user (`tokyo` from Day 09) is refused.
- **nginx failed for real:** my practice VM can't reach the Ubuntu package mirrors. The script **reported the failure and carried on** with the other packages instead of crashing. That's the behaviour you want in automation.

## Task 5: Error handling – `safe_script.sh`
```bash
#!/bin/bash
set -e
DIR=/tmp/devops-test

mkdir -p "$DIR" || { echo "ERROR: cannot create $DIR"; exit 1; }
cd "$DIR"       || { echo "ERROR: cannot cd into $DIR"; exit 1; }
touch notes.txt || { echo "ERROR: cannot create notes.txt"; exit 1; }
echo "Created $DIR/notes.txt"

cd /does/not/exist || { echo "ERROR: /does/not/exist is missing - stopping"; exit 1; }
echo "You will never see this line"
```
```
$ ./safe_script.sh; echo "exit code: $?"
Created /tmp/devops-test/notes.txt
./safe_script.sh: line 15: cd: /does/not/exist: No such file or directory
ERROR: /does/not/exist is missing - stopping
exit code: 1
```

## Key learnings
1. **`"${array[@]}"` + `for`** is how to loop over a list of packages, servers or files cleanly.
2. **Always validate input:** print a usage message and `exit 1` (`$#`, `-z "$1"`). A non-zero exit code is what CI/CD and cron use to detect failure.
3. **`set -e` stops on errors, and `cmd || { msg; exit 1; }` explains *why*.** Root checks (`$EUID`) stop scripts from half-running without permissions.
