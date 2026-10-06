# Day 25 – Git Reset vs Revert & Branching Strategies

> Practice VM: Ubuntu 24.04, Git 2.43, in my local `devops-git-practice` repo. The consolidated `git-commands.md` (Days 22–25) is in this folder.

## Task 1: Reset hands-on
Setup: three commits, `A`, `B`, `C`, each adding a line to `reset-demo.txt`.
```
$ git log --oneline -3
7f82c55 Commit C
34e6d17 Commit B
bf6621a Commit A
```
**`--soft`:** the commit is undone, and the changes stay **staged**
```
$ git reset --soft HEAD~1 && git log --oneline -1 && git status --short
34e6d17 Commit B
M  reset-demo.txt          ← M in the first column = staged
```
**`--mixed` (the default):** the commit is undone, and the changes stay in the working directory, **unstaged**
```
$ git reset --mixed HEAD~1 && git status --short
Unstaged changes after reset:
M	reset-demo.txt
 M reset-demo.txt          ← M in the second column = unstaged
```
**`--hard`:** the commit **and** the changes are gone
```
$ git reset --hard HEAD~1
HEAD is now at 34e6d17 Commit B
$ git status --short        ← (nothing)
$ cat reset-demo.txt
commit A
commit B                    ← line C has vanished from the file
```
**Rescued with `reflog`:**
```
$ git reflog -4
34e6d17 HEAD@{0}: reset: moving to HEAD~1
7f82c55 HEAD@{1}: commit: Commit C
...
$ git reset --hard HEAD@{1} && cat reset-demo.txt
commit A
commit B
commit C                    ← back ✅
```
*Fun detail: each time I re-committed "Commit C" it got the **same hash** (`7f82c55`). Same content, parent, author, message and timestamp (to the second) means an identical hash. Git hashes are content-addressed.*

**Answers:**
- `--soft` keeps changes staged, `--mixed` keeps them unstaged, `--hard` throws them away.
- **`--hard` is the destructive one.** Uncommitted work is gone for good. Committed work can be recovered from `reflog` for a while, but only locally.
- **Use `--soft`** to redo the last commit message or squash a few local commits. **Use `--mixed`** to un-stage or reorganise commits. **Use `--hard`** only to throw away local experiments.
- **Never reset commits that are already pushed.** Teammates' history no longer matches, and you'd need a force-push.

## Task 2: Revert hands-on
```
$ git log --oneline -3
0d47434 Add revert-Z.txt
bae7d3e Add revert-Y.txt      ← undo this middle one
c219850 Add revert-X.txt
$ git revert --no-edit HEAD~1
[main 6b0d43f] Revert "Add revert-Y.txt"
$ git log --oneline -4
6b0d43f Revert "Add revert-Y.txt"     ← NEW commit that undoes Y
0d47434 Add revert-Z.txt
bae7d3e Add revert-Y.txt              ← original is still in history
c219850 Add revert-X.txt
$ ls revert-*.txt
revert-X.txt
revert-Z.txt                          ← Y is gone, Z untouched
```
Revert **adds** a commit that does the opposite, so history is never rewritten. That's why it's safe on shared branches: everyone just pulls one more commit.

## Task 3: Reset vs revert
| | `git reset` | `git revert` |
|---|---|---|
| What it does | Moves the branch pointer back (optionally discarding changes) | Creates a new commit that undoes a previous one |
| History | **Rewritten** (commits disappear) | **Preserved** (an undo commit is added) |
| Safe on shared/pushed branches? | ❌ No | ✅ Yes |
| Use it when | Cleaning up **local, unpushed** work | Undoing something already on `main` or in production |

## Task 4: Branching strategies
### GitFlow
```
main     ──●────────────────●──────── (releases only, tagged)
            \              /
release      \        ●──●            (stabilise v1.2)
              \      /    \
develop  ──●───●──●─●──────●──────── (integration)
              \  /
feature        ●●                     (feature/login)
hotfix  (from main → merged into main AND develop)
```
- **How it works:** long-lived `main` + `develop`, plus `feature/*`, `release/*` and `hotfix/*` branches.
- **Used for:** software with **scheduled, versioned releases** (mobile apps, installed products).
- ✅ Very structured, and releases can be stabilised separately. ❌ Heavy and slow, with lots of merges. Overkill for continuous deployment.

### GitHub Flow
```
main  ──●───────●──────────●───  (always deployable)
         \     / (PR+review)
feature   ●──●
```
- **How it works:** one `main` that's always deployable. Every change is a short branch → pull request → review → merge → deploy.
- **Used for:** web apps and SaaS that **deploy many times a day**.
- ✅ Simple and fast. ❌ No built-in way to maintain several release versions at once.

### Trunk-Based Development
```
main/trunk ──●─●─●─●─●─●──  (everyone merges at least daily)
              \/  \/
          tiny branches (hours, not days) + feature flags
```
- **How it works:** everyone commits to `trunk` very frequently, with tiny short-lived branches (or none). Unfinished features are hidden behind **feature flags**.
- **Used for:** high-performing teams with **strong CI/CD and automated tests** (Google, for example).
- ✅ Few merge conflicts, true continuous integration. ❌ Needs excellent test coverage and discipline.

### My picks
- **A startup shipping fast:** **GitHub Flow.** It's simple, everything goes through PRs, and deploys are continuous.
- **A large team with scheduled releases:** **GitFlow** (or release branches on top of trunk-based).
- **An open-source example:** **Kubernetes** develops on one main branch (trunk-style), with release branches (`release-1.x`) cut for each version and fixes cherry-picked into them. That's exactly where Day 24's cherry-pick fits in.

## Key learnings
1. **reset = rewrite history, revert = add history.** Once something is pushed, revert.
2. **`git reflog` is the safety net.** Even `--hard` resets can be undone locally.
3. **The branching strategy should follow how you release,** not the other way round.
