# Day 23 – Git Branching & Working with Remotes

> Practice VM: Ubuntu 24.04, Git 2.43.
> **About the "GitHub" parts:** I chose not to create extra repos on my GitHub account for practice. I used **local bare repositories as stand-ins for GitHub** (`/srv/git/*.git`). Git talks to them exactly as it talks to GitHub (`push`, `fetch`, `pull`, `remote`); only the URL differs.

## Task 1: Concepts
- **What is a branch?** A movable **pointer to a commit**. New commits on that branch move the pointer forward. Creating one is instant and cheap: it's a 41-byte file in `.git/refs/heads/`.
- **Why not commit everything to `main`?** Branches isolate work. A half-finished feature doesn't break `main`, several people can work in parallel, and changes get reviewed (as pull requests) before they're merged.
- **What is `HEAD`?** A pointer to **where you are right now**, usually the current branch (`HEAD → main → d417683`).
- **What happens to files when you switch branches?** Git rewrites the working directory to match that branch's latest commit. Files that only exist on the other branch **disappear** (and come back when you switch back).

## Task 2: Branching hands-on
```
$ git branch
* main
$ git branch feature-1 && git branch
  feature-1
* main
$ git switch feature-1
Switched to branch 'feature-1'
$ git switch -c feature-2          ← create + switch in one step
Switched to a new branch 'feature-2'
$ git checkout feature-1           ← the older command does the same thing
Switched to branch 'feature-1'
```
**`git switch` vs `git checkout`:** `checkout` does two unrelated jobs (switch branches *and* restore files), which is confusing and risky. Git 2.23 split it into **`git switch`** (branches) and **`git restore`** (files). I use `switch`.

A commit that only exists on `feature-1`:
```
$ echo "Feature 1: login page" > feature1.txt && git add . && git commit -m "Add feature1.txt on feature-1"
$ ls
feature1.txt  git-commands.md
$ git switch main && ls
git-commands.md                  ← feature1.txt is gone on main ✅
$ git branch -d feature-2
Deleted branch feature-2 (was d417683).
```

## Task 3: Push to a remote
```
$ git init --bare /srv/git/devops-git-practice.git      ← "GitHub" stand-in
$ git remote add origin /srv/git/devops-git-practice.git
$ git remote -v
origin	/srv/git/devops-git-practice.git (fetch)
origin	/srv/git/devops-git-practice.git (push)
$ git push -u origin main
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
$ git push -u origin feature-1
 * [new branch]      feature-1 -> feature-1
$ git --git-dir=/srv/git/devops-git-practice.git branch
  feature-1
* main                                                   ← both branches on the remote ✅
```
*(The first push to the empty repo also printed a harmless `push negotiation failed; proceeding anyway` warning.)*
On GitHub the only change is the URL: `git remote add origin https://github.com/RobinSishodia/devops-git-practice.git`.

**`origin` vs `upstream`:** `origin` = **your** copy (where you push). `upstream` = the **original** project you forked from (where you pull updates; usually you can't push there).

## Task 4: Pulling remote changes
I simulated "someone edited a file on GitHub" with a second clone that pushed a commit:
```
$ git fetch origin
   d417683..55ed141  main       -> origin/main
$ git status -sb
## main...origin/main [behind 1]
$ git log --oneline main..origin/main
55ed141 Update git-commands.md on remote
$ tail -1 git-commands.md
- `git show <hash>` - details of one commit                ← my files are NOT changed yet
$ git pull origin main
$ tail -1 git-commands.md
- Edited directly on the remote (simulating a GitHub web edit)   ← now they are
```
**`fetch` vs `pull`:** `fetch` **downloads** new commits and updates `origin/main` but **doesn't touch your files**, so it's safe to look first. `pull` = `fetch` + `merge` into your current branch.

## Task 5: Clone vs fork
```
$ git clone --bare ... /srv/git/upstream-project.git     ← "the original project"
$ git clone --bare /srv/git/upstream-project.git /srv/git/my-fork.git   ← "my fork"
$ git clone /srv/git/my-fork.git my-fork-clone && cd my-fork-clone
$ git remote add upstream /srv/git/upstream-project.git
$ git remote -v
origin	/srv/git/my-fork.git (fetch)
origin	/srv/git/my-fork.git (push)
upstream	/srv/git/upstream-project.git (fetch)
upstream	/srv/git/upstream-project.git (push)
```
The upstream project got a new commit, so I synced my fork:
```
$ git fetch upstream && git merge upstream/main && git push origin main
$ git log --oneline -2
3916d8f Upstream: new file
55ed141 Update git-commands.md on remote
```
| | Clone | Fork |
|---|---|---|
| What it is | A **local copy** of a repo on your machine | A **server-side copy** under your own GitHub account |
| Can you push? | Only if you have write access | Yes, it's yours |
| Use it when | It's your repo or your team's repo | Contributing to someone else's project (fork → PR) |

**Keeping a fork in sync:** `git fetch upstream && git merge upstream/main && git push origin main` (or GitHub's **Sync fork** button, which I used on Day 01).

## Key learnings
1. **A branch is just a pointer.** That's why Git branches are cheap and fast.
2. **`fetch` before `pull`.** Look at what changed before merging it into your work.
3. **`origin` = mine, `upstream` = theirs.** Forks keep up to date by fetching from `upstream`.
