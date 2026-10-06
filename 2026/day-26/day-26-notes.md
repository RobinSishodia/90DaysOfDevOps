# Day 26 – GitHub CLI (`gh`): Manage GitHub from the Terminal

> Practice VM: Ubuntu 24.04, `gh` 2.89.0.
> **Honest status:** my practice VM is **not logged in** to GitHub. I decided not to put a personal access token on it, and its network blocks most GitHub API calls. So everything that talks to GitHub (repos, issues, PRs, runs) is written below as a **runbook** to run on my own laptop after `gh auth login`. Everything local (install, auth status, aliases, help and flags) was run for real.

## Task 1: Install and authenticate
```
$ gh --version
gh version 2.89.0 (2026-03-26)

$ gh auth status
You are not logged into any GitHub hosts. To log in, run: gh auth login
```
**Authentication methods `gh` supports:**
- **Web browser flow** (the default): `gh auth login`. It shows a one-time code that you approve in the browser.
- **Personal access token:** `gh auth login --with-token < token.txt` (classic PAT), or the `GH_TOKEN` / `GITHUB_TOKEN` environment variable. This is how CI uses it.
- **Git protocol:** HTTPS or SSH (it can upload an existing SSH key).
- **GitHub Enterprise:** `gh auth login --hostname github.mycompany.com`
- Check with `gh auth status`, switch accounts with `gh auth switch`.

## Task 2: Repositories (runbook)
```bash
gh repo create gh-cli-test --public --add-readme --description "Testing GitHub CLI"
gh repo clone RobinSishodia/gh-cli-test
gh repo view RobinSishodia/gh-cli-test
gh repo list RobinSishodia --limit 20
gh repo view --web                     # open in the browser
gh repo delete RobinSishodia/gh-cli-test --yes   # needs the delete_repo scope: gh auth refresh -s delete_repo
```

## Task 3: Issues (runbook)
```bash
gh issue create --title "Add LVM notes" --body "Redo Day 13 with real LVM on EC2" --label "documentation"
gh issue list
gh issue view 1
gh issue close 1 --comment "Done on EC2"
```
**`gh issue` in automation:**
- A nightly cron or CI job that **opens an issue when a check fails**, e.g. `gh issue create --title "Backup failed $(date +%F)" --body "$(tail -50 backup.log)" --label incident`
- A script that lists stale issues with `gh issue list --label bug --json number,title,updatedAt` and pings the owners

## Task 4: Pull requests (runbook)
```bash
git switch -c docs/gh-notes
echo "gh notes" >> notes.md && git commit -am "Add gh notes"
git push -u origin docs/gh-notes
gh pr create --fill                      # title/body from the commits
gh pr list
gh pr view 1                             # status, reviewers
gh pr checks 1                           # CI status
gh pr merge 1 --squash --delete-branch
```
**Merge methods** (checked locally):
```
$ gh pr merge --help
  -m, --merge    Merge the commits with the base branch
  -r, --rebase   Rebase the commits onto the base branch
  -s, --squash   Squash the commits into one commit and merge it into the base branch
```
These are the same three options as Day 24 (merge commit, rebase, squash). There's also `--auto` to merge automatically once checks pass.

**Reviewing someone else's PR:**
```bash
gh pr checkout 42          # get their branch locally and test it
gh pr diff 42
gh pr review 42 --approve
gh pr review 42 --request-changes --body "Please add tests for the empty-input case"
gh pr review 42 --comment --body "LGTM except one nit"
```

## Task 5: GitHub Actions from the terminal (runbook)
```bash
gh run list --repo TrainWithShubham/90DaysOfDevOps --limit 5
gh run view <run-id> --log-failed       # only the failing step's logs
gh workflow list
gh workflow run deploy.yml -f env=staging
gh run watch                            # follow a run live
```
**In a CI/CD pipeline:** trigger downstream workflows (`gh workflow run`), wait for them (`gh run watch --exit-status`), and fetch the failing logs straight into a Slack alert. No browser needed.

## Task 6: Advanced
**Aliases** (run for real):
```
$ gh alias set prs 'pr list --state open --limit 10'
$ gh alias set myrepos 'repo list RobinSishodia --limit 20'
$ gh alias list
co: pr checkout
myrepos: repo list RobinSishodia --limit 20
prs: pr list --state open --limit 10
```
| Command | What it's for | Example |
|---|---|---|
| `gh api` | Call any REST/GraphQL endpoint with your auth | `gh api repos/RobinSishodia/90DaysOfDevOps --jq .stargazers_count` |
| `gh gist` | Create or share snippets | `gh gist create cheatsheet.md --public` |
| `gh release` | Create releases and upload assets | `gh release create v1.0 ./dist/app.tar.gz --notes "First release"` |
| `gh alias` | Your own shortcuts | `gh alias set prs 'pr list'` |
| `gh search repos` | Search GitHub | `gh search repos "90DaysOfDevOps" --sort stars --limit 5` |
| `--json` + `--jq` | Machine-readable output for scripts | `gh pr list --json number,title --jq '.[].title'` |

## Key learnings
1. **`gh` keeps you in the terminal.** Repos, issues, PRs and CI runs without opening a browser.
2. **`--json` + `--jq` make `gh` scriptable.** That's what makes it useful for DevOps automation.
3. **Treat tokens carefully.** Use `GH_TOKEN` in CI from a secret, and the browser flow on your laptop. Never paste tokens into shared machines.
