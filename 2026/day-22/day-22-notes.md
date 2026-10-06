# Day 22 – Introduction to Git: My First Repository

> Practice VM: Ubuntu 24.04, Git 2.43. The practice repo `devops-git-practice` lives on this VM (Days 22–25 build on it). Its `git-commands.md` is copied here.

## Task 1: Install and configure
```
$ git --version
git version 2.43.0
$ git config --global user.name "Robin Sishodia"
$ git config --global user.email "RobinSishodia@users.noreply.github.com"
$ git config --global init.defaultBranch main
$ git config --global --list | grep -E 'user.name|user.email|init'
user.name=Robin Sishodia
user.email=RobinSishodia@users.noreply.github.com
init.defaultbranch=main
```
I used GitHub's **noreply email** so my real address isn't baked into public commit history.

## Task 2: Create the repo
```
$ mkdir devops-git-practice && cd devops-git-practice && git init
Initialized empty Git repository in /root/devops-git-practice/.git/

$ ls -A .git
HEAD  branches  config  description  hooks  info  objects  refs

$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

## Task 3–4: First file, stage, commit
```
$ git status --short
?? git-commands.md            ← untracked
$ git add git-commands.md
$ git status --short
A  git-commands.md            ← staged (A = added)
$ git diff --staged --stat
 git-commands.md | 7 +++++++
 1 file changed, 7 insertions(+)
$ git commit -m "Add git-commands.md with setup and config commands"
$ git log
commit 0ad7423e4a008ba9bd9232380c5ea05dadbc40ff
Author: Robin Sishodia <RobinSishodia@users.noreply.github.com>
Date:   Tue Oct 6 18:53:37 2026 +0000

    Add git-commands.md with setup and config commands
```

## Task 5: Building history
```
$ git diff --stat               ← after adding the "Basic Workflow" section
 git-commands.md | 6 ++++++
$ git diff | head -12
@@ -5,3 +5,9 @@
 - `git config --list` - show all settings
+
+## Basic Workflow
+- `git init` - create a new repository
+- `git status` - see what changed / what is staged
...
$ git add . && git commit -m "Add basic workflow commands"
$ git add . && git commit -m "Add viewing changes commands"

$ git log --oneline
d417683 Add viewing changes commands
8f9b59a Add basic workflow commands
0ad7423 Add git-commands.md with setup and config commands
```

## Task 6: Concepts
1. **`git add` vs `git commit`:** `add` puts changes in the **staging area** (a draft of the next snapshot). `commit` saves that staged snapshot permanently into history with a message, author and timestamp.
2. **Why a staging area?** You can choose *exactly* what goes into each commit. For example, you might stage the bug fix but not the debug `echo` lines, giving small, focused, reviewable commits.
3. **What `git log` shows:** the commit hash (a unique ID), author, date and message, newest first. `--oneline` shortens it to hash + message.
4. **The `.git/` folder** *is* the repository: all commits (`objects/`), branches (`refs/`), the current branch (`HEAD`) and settings (`config`). Delete it and you have plain files with no history.
5. **The three areas:**
```
Working directory ──git add──► Staging area ──git commit──► Repository (.git)
   (files you edit)              (next snapshot)              (saved history)
```

## Key learnings
1. **Git saves snapshots, not diffs**, and every commit gets a hash ID.
2. **`git status` is the command to run constantly.** It always tells you which area each change is in.
3. **Small commits with clear messages** make `git log --oneline` read like a story.
