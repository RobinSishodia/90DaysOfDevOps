# Git Commands Reference (Days 22–25)

## Setup & Config
| Command | What it does | Example |
|---|---|---|
| `git --version` | Check Git is installed | `git --version` |
| `git config --global user.name` | Set your commit name | `git config --global user.name "Robin Sishodia"` |
| `git config --global user.email` | Set your commit email | `git config --global user.email "me@users.noreply.github.com"` |
| `git config --global init.defaultBranch` | Default branch for new repos | `git config --global init.defaultBranch main` |
| `git config --list` | Show all settings | `git config --global --list` |

## Basic Workflow
| Command | What it does | Example |
|---|---|---|
| `git init` | Create a repo in the current folder | `git init` |
| `git clone <url>` | Copy a remote repo locally | `git clone https://github.com/user/repo.git` |
| `git status` | What's changed / staged / untracked | `git status -sb` |
| `git add` | Stage changes | `git add file.txt` · `git add .` |
| `git commit -m` | Save staged changes | `git commit -m "Add login form"` |
| `git commit -am` | Stage tracked files + commit | `git commit -am "Fix typo"` |
| `git restore <file>` | Discard unstaged changes in a file | `git restore app.conf` |
| `git restore --staged <file>` | Unstage (keep the changes) | `git restore --staged app.conf` |

## Viewing Changes
| Command | What it does |
|---|---|
| `git diff` | Unstaged changes |
| `git diff --staged` | Staged changes (what will be committed) |
| `git log --oneline` | Compact history |
| `git log --oneline --graph --all` | History of all branches as a graph |
| `git log main..origin/main` | Commits on the remote that you don't have yet |
| `git show <hash>` | One commit in detail |
| `git reflog` | Everywhere HEAD has been (your undo history) |

## Branching
| Command | What it does |
|---|---|
| `git branch` | List local branches |
| `git branch -a` | Include remote branches |
| `git branch <name>` | Create a branch |
| `git switch <name>` | Switch branch |
| `git switch -c <name>` | Create + switch |
| `git branch -d <name>` | Delete a (merged) branch |
| `git branch -D <name>` | Force delete |

## Remotes
| Command | What it does |
|---|---|
| `git remote -v` | List remotes |
| `git remote add origin <url>` | Connect to a remote |
| `git remote add upstream <url>` | Add the original repo of a fork |
| `git push -u origin <branch>` | Push and set tracking |
| `git fetch origin` | Download remote changes (no merge) |
| `git pull origin main` | Fetch + merge |
| `git fetch upstream && git merge upstream/main` | Sync a fork |

## Merging & Rebasing
| Command | What it does |
|---|---|
| `git merge <branch>` | Merge into the current branch (fast-forward if possible) |
| `git merge --no-ff <branch>` | Always create a merge commit |
| `git merge --squash <branch>` | Combine all commits into one staged change |
| `git merge --abort` | Cancel a conflicted merge |
| `git rebase main` | Replay the current branch on top of main |
| `git rebase --continue` / `--abort` | Continue or cancel after a conflict |
| `git cherry-pick <hash>` | Copy one commit onto the current branch |
| `git cherry-pick --continue` | Continue after resolving a conflict |

## Stashing
| Command | What it does |
|---|---|
| `git stash push -m "msg"` | Save uncommitted work |
| `git stash list` | List stashes |
| `git stash pop` | Apply the latest + remove it |
| `git stash apply stash@{1}` | Apply a specific stash, keep it |
| `git stash drop stash@{0}` / `git stash clear` | Delete one / all |

## Undoing
| Command | What it does |
|---|---|
| `git reset --soft HEAD~1` | Undo the commit, keep changes **staged** |
| `git reset HEAD~1` (`--mixed`) | Undo the commit, keep changes **unstaged** |
| `git reset --hard HEAD~1` | Undo the commit **and discard the changes** ⚠️ |
| `git reset --hard HEAD@{1}` | Jump back to an earlier state from reflog |
| `git revert <hash>` | New commit that undoes `<hash>` (safe for shared branches) |
