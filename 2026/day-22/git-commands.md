# Git Commands Reference

## Setup & Config
- `git --version` - check Git is installed. Example: `git --version`
- `git config --global user.name "Name"` - set your name for commits
- `git config --global user.email "me@example.com"` - set your email for commits
- `git config --list` - show all settings

## Basic Workflow
- `git init` - create a new repository
- `git status` - see what changed / what is staged
- `git add <file>` - stage a file (`git add .` stages everything)
- `git commit -m "msg"` - save staged changes as a commit

## Viewing Changes
- `git diff` - unstaged changes
- `git diff --staged` - staged changes (what will be committed)
- `git log` - full commit history
- `git log --oneline` - one line per commit
- `git show <hash>` - details of one commit
