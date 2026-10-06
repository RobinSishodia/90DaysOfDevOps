# Day 27 – GitHub Profile Makeover

> I audited my profile at [github.com/RobinSishodia](https://github.com/RobinSishodia) (Oct 2026). I decided **not** to create, rename or delete repos as part of this exercise, so this file is the **audit + action plan**. Each change will be made deliberately.

## Task 1: Audit (looking at it as a stranger would)
| Question | Answer |
|---|---|
| Professional profile picture? | ✅ Yes |
| Bio filled in? | ✅ The profile README states my role, 11 certifications and target roles |
| Profile README? | ✅ **Already exists** (`RobinSishodia/RobinSishodia`): intro, certifications table, skills, featured work, background, contact |
| Pinned repos relevant? | ⚠️ To review: my strongest finished work (`salesforce-devops-pipeline`, `devops-salesforce-notes`) should be pinned first (plan in Task 4) |
| Do repos have descriptions? | ✅ My project repos all do |
| Would a recruiter understand my work in 30 seconds? | ✅ Yes for Salesforce. ⚠️ Three DevOps repos are marked 🚧 *planned*, so the 90-day challenge is currently my best **proof** of hands-on DevOps work |

**Repositories found:**
| Repo | Notes |
|---|---|
| `RobinSishodia` | Profile README ✅ |
| `salesforce-devops-pipeline` | Salesforce DX + GitHub Actions CI/CD ✅ (strongest project) |
| `devops-salesforce-notes` | Hashnode → Markdown backup via GitHub Actions ✅ |
| `robinsishodia.github.io` | Portfolio site ✅ |
| `90DaysOfDevOps` | ⚠️ Fork: still shows **upstream's description**, not mine |
| `aws-eks-gitops-argocd`, `jenkins-devsecops-pipeline`, `terraform-ansible-aws-infra` | 🚧 Structure only, code still to come |
| `skills-getting-started-with-github-copilot`, `skills-scale-institutional-knowledge-using-copilot-spaces` | GitHub Skills exercises: clutter for recruiters |

## Task 2: Profile README
Already in place. **Planned additions:**
- A **"Currently doing"** line: *"#90DaysOfDevOps: Day 30/90, Linux → Shell → Git → Docker"*, linking to my fork and Hashnode series.
- A link to the blog series on Hashnode.

## Task 3: Organise repositories (plan)
The task suggests separate `shell-scripts`, `python-scripts` and `devops-notes` repos. **My decision:** keep everything in **one** `90DaysOfDevOps` fork, organised by day, because:
- one link shows the whole journey and the daily commit streak
- splitting would duplicate files and scatter the history

What I *will* do:
- [ ] Give the fork its own description: *"My #90DaysOfDevOps journey: Linux, shell scripting, Git, Docker, K8s, Terraform on AWS. One folder per day, with real command output."*
- [ ] Add topics: `devops`, `linux`, `bash`, `docker`, `90daysofdevops`

## Task 4: Pin 6 repositories (plan)
1. `salesforce-devops-pipeline`
2. `90DaysOfDevOps`
3. `devops-salesforce-notes`
4. `robinsishodia.github.io`
5. `aws-eks-gitops-argocd` (once it has code)
6. `terraform-ansible-aws-infra` (once it has code)

## Task 5: Clean-up
- [ ] **Archive** the two GitHub Skills exercise repos (it keeps them but hides the clutter).
- [x] **Secrets check:** no credentials in my 90DaysOfDevOps files. I used the noreply commit email (Day 22) and didn't store any tokens (Day 26).
- [ ] Before each 🚧 repo goes public with code: run a secret scan (e.g. `gitleaks detect`), because Terraform/Jenkins projects are where AWS keys accidentally leak.

## Task 6: Three improvements and why
1. **The fork gets its own description and topics.** Right now it looks like an untouched copy of someone else's repo. With its own description it shows *my* work.
2. **Pin finished work first.** Recruiters spend seconds on a profile, so finished projects should be the first thing they see, not 🚧 plans.
3. **Archive the exercise repos.** Fewer, stronger repos signal focus.

*(Before/after screenshots will be added once the changes are made.)*
