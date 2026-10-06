# Day 24 – Advanced Git: Merge, Rebase, Squash, Stash & Cherry-Pick

> Practice VM: Ubuntu 24.04, Git 2.43, in my local `devops-git-practice` repo.

## Task 1: Merge
### Fast-forward
```
$ git switch -c feature-login   # 2 commits: "Add login form", "Add login validation"
$ git switch main && git merge feature-login
Updating 55ed141..0db29e3
Fast-forward
 login.txt | 2 ++
```
**Fast-forward:** `main` had no new commits, so Git just **moved the `main` pointer forward**. No merge commit is created.

### Merge commit (both branches moved)
```
$ git switch -c feature-signup   # commit: "Add signup form"
$ git switch main                # commit: "Add merging section to notes"
$ git merge --no-edit feature-signup
Merge made by the 'ort' strategy.
$ git log --oneline --graph -6
*   ddfe6ef Merge branch 'feature-signup'
|\
| * 8da9c5c Add signup form
* | b850986 Add merging section to notes
|/
* 0db29e3 Add login validation
```
**Merge commit:** both branches had new commits, so Git created a commit with **two parents** that joins them.

### Merge conflict
Both branches changed line 1 of `git-commands.md`:
```
$ git merge feature-color
CONFLICT (content): Merge conflict in git-commands.md
Automatic merge failed; fix conflicts and then commit the result.
$ head -5 git-commands.md
<<<<<<< HEAD
# Git Commands Reference (GREEN)
=======
# Git Commands Reference (BLUE)
>>>>>>> feature-color
```
**A conflict happens** when both branches change the **same lines**, so Git can't choose. I edited the file to the version I wanted (`# Git Commands Reference`), then ran `git add` + `git commit` → `a92a44c Resolve title conflict`.

## Task 2: Rebase
Before (`main` moved after I branched):
```
* e04561b Dashboard widget 3
* 56b7705 Dashboard widget 2
* 67b2b41 Dashboard widget 1
| * 11a5691 Main: urgent hotfix
|/
*   a92a44c Resolve title conflict
```
```
$ git switch feature-dashboard && git rebase main
Successfully rebased and updated refs/heads/feature-dashboard.
```
After, one straight line:
```
* 9584cf4 Dashboard widget 3        ← new hashes!
* d94b127 Dashboard widget 2
* e112630 Dashboard widget 1
* 11a5691 Main: urgent hotfix
*   a92a44c Resolve title conflict
```
- **What rebase does:** it **replays** your commits on top of the latest `main`, creating **new commits** (look at the new hashes: `e04561b` → `9584cf4`).
- **vs merge:** merge keeps the real (branching) history plus a merge commit. Rebase gives a **linear** history, and the merge afterwards was a clean fast-forward.
- **Never rebase commits others already have:** rewriting shared history gives teammates "different" commits with the same changes, which causes duplicates and painful conflicts.
- **When to use it:** to update *your own* local feature branch with the latest `main` before opening a PR.

## Task 3: Squash merge vs regular merge
```
$ git log --oneline main..feature-profile | wc -l
5                                          ← 5 tiny commits
$ git merge --squash feature-profile && git commit -m "Add user profile page (squashed 5 commits)"
$ git log --oneline -2
111ec2b Add user profile page (squashed 5 commits)     ← 1 commit on main
9584cf4 Dashboard widget 3

$ git merge --no-ff --no-edit feature-settings          ← regular merge
*   088d8df Merge branch 'feature-settings'
|\
| * 22431d6 settings: option 2
| * 595d65c settings: option 1
|/
* 111ec2b Add user profile page (squashed 5 commits)
```
| | Squash merge | Regular merge |
|---|---|---|
| History on main | **1 clean commit** | All commits + a merge commit |
| Good for | Noisy WIP commits ("fix typo", "tweak 4") | Meaningful commits worth keeping |
| Trade-off | You lose the individual steps (harder to bisect or revert one part) | History gets busier |

## Task 4: Stash
**A surprise:** `git switch` *didn't* refuse with uncommitted changes. Git only blocks the switch if your change would be **overwritten** by the other branch's version of that file. Mine carried over to the other branch, which can be just as dangerous.
```
$ git stash push -m "wip notes"
Saved working directory and index state On main: wip notes
$ git stash push -m "profile idea"
$ git stash list
stash@{0}: On main: profile idea
stash@{1}: On main: wip notes
$ git stash apply stash@{1}         ← apply a specific (older) stash
 M git-commands.md
$ git stash list                    ← apply KEEPS it in the list
stash@{0}: On main: profile idea
stash@{1}: On main: wip notes
$ git stash pop stash@{0}           ← pop applies AND removes it
Dropped stash@{0} (25974e8c...)
$ git stash list
stash@{0}: On main: wip notes
```
**`pop` vs `apply`:** `pop` = apply + delete from the stash list. `apply` = apply but keep it, which is useful when you want the same changes on several branches. **When to use stash:** an urgent bug arrives mid-feature, so you stash, switch, fix, then come back and pop.

## Task 5: Cherry-pick
```
$ git log --oneline -3          (on feature-hotfix)
b64374e Experimental refactor
9586e6a Fix crash on empty input     ← I want ONLY this one
0494cdd Fix typo in README
$ git switch main && git cherry-pick 9586e6a
CONFLICT (modify/delete): hotfix-log.txt deleted in HEAD and modified in 9586e6a
```
**The real-world risk showed up straight away:** commit 2 *edited* `hotfix-log.txt`, but that file was *created* in commit 1, which I didn't pick. **Cherry-picked commits can depend on commits you left behind.** I resolved it by keeping only the fix:
```
$ echo "Fix crash on empty input" > hotfix-log.txt && git add hotfix-log.txt && git cherry-pick --continue
[main 6b4a072] Fix crash on empty input
$ git log --oneline main | grep -c "Experimental refactor"
0                                      ← the experimental commit stayed out ✅
```
- **What it does:** copies **one specific commit** onto your current branch, as a new commit with a new hash.
- **When to use it:** backporting a hotfix to a release branch, or rescuing one good commit from an abandoned branch.
- **Risks:** hidden dependencies (exactly what happened here), and duplicate commits if that branch gets merged later.

## Key learnings
1. **Fast-forward vs merge commit** depends only on whether `main` moved in the meantime.
2. **Rebase rewrites history.** Use it on your own branches, never on shared ones.
3. **Cherry-pick is surgical but fragile.** A commit can quietly depend on the commits around it.
