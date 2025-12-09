# Git Branching Strategy for Crop AI

## Overview

This document defines the branching strategy for the Crop AI project, enabling focused development while minimizing integration risk. We follow a **modified Git Flow** with clear branch types, naming conventions, and workflows.

---

## Branch Types

### 1. **Production Branches** (Protected)

#### `main`
- **Purpose:** Production-ready code only
- **Protection Rules:**
  - Require pull request reviews (minimum 2)
  - Require status checks to pass (CI/CD)
  - Require up-to-date branches
  - Dismiss stale PR approvals
  - Require code owners review
- **Deployment:** Automatic deployment on merge (CD pipeline)
- **Merge From:** `release/*` and hotfix branches only
- **Frequency:** 1-2 deployments per sprint (every 1-2 weeks)

#### `develop`
- **Purpose:** Integration branch for features and bugfixes
- **Protection Rules:**
  - Require pull request reviews (minimum 1)
  - Require status checks to pass
  - Require up-to-date branches
- **Deployment:** Continuous testing environment
- **Merge From:** `feature/*`, `bugfix/*` branches
- **Frequency:** Multiple times per day

### 2. **Feature Branches** (Temporary)

#### Naming: `feature/<epic>-<feature-name>`

**Examples:**
- `feature/epic1-farm-list-screen`
- `feature/epic2-weather-widget`
- `feature/epic3-gamification-leaderboard`

**Workflow:**
1. Create from `develop`
2. Work on feature in isolation
3. Push regularly (at least daily)
4. Create PR when ready for review
5. Delete after merge to `develop`

**Rules:**
- One logical feature per branch
- Max lifetime: 2 weeks
- All CI checks must pass
- Code review required (minimum 1)
- No direct commits after PR created

---

### 3. **Epic Branches** (Long-lived)

#### Naming: `epic/<epic-number>-<epic-name>`

**Examples:**
- `epic/0-cicd-setup`
- `epic/1-crop-monitoring`
- `epic/2-ai-predictions`

**Purpose:**
- Organize multiple related features
- Reduce merge conflicts
- Enable parallel team work
- Staging before `develop` integration

**Workflow:**
1. Create from `develop` when epic starts
2. Features branch from `epic/*` instead of `develop`
3. Features PR directly to their epic branch
4. Merge epic to `develop` when complete
5. Delete after merge to `develop`

**Timeline:**
- Epic 0: Week -2 to 0 (2 weeks) - **[CI/CD Setup]**
- Epic 1: Week 1 to 4 (4 weeks) - **[Crop Monitoring]**
- Epic 2: Week 5 to 8 (4 weeks) - **[AI Predictions]**
- Epic 3: Week 9 to 12 (4 weeks) - **[Gamification]**
- Epic 4: Week 13 to 16 (4 weeks) - **[Marketplace]**
- Epic 5: Week 17 (1 week) - **[Polish & Integration]**

---

### 4. **Release Branches** (Temporary)

#### Naming: `release/<version>`

**Examples:**
- `release/1.0.0`
- `release/1.1.0`
- `release/2.0.0`

**Purpose:**
- Final testing and bugfixes before production
- Prepare metadata (version, changelog)
- Build production artifacts

**Workflow:**
1. Create from `develop` when ready for release
2. Only bugfixes and metadata changes
3. Increment version numbers
4. Merge to `main` (triggers deployment)
5. Tag with version number
6. Merge back to `develop` to sync hotfixes
7. Delete after merge to `main`

**Versioning:** Semantic Versioning (MAJOR.MINOR.PATCH)

---

### 5. **Hotfix Branches** (Emergency)

#### Naming: `hotfix/<issue-description>`

**Examples:**
- `hotfix/critical-login-crash`
- `hotfix/data-sync-bug`
- `hotfix/security-vulnerability`

**Purpose:**
- Fix critical production issues
- Bypass normal workflow for emergency

**Workflow:**
1. Create from `main` (not `develop`)
2. Fix issue + add test case
3. Merge to `main` (triggers deployment)
4. Tag with patch version increment
5. Merge back to `develop` to sync
6. Delete after merge to `main`

**SLA:** 4 hours max from issue report to production

---

### 6. **Spike/Research Branches** (Experimental)

#### Naming: `spike/<topic>`

**Examples:**
- `spike/flutter-performance-analysis`
- `spike/firebase-offline-sync`
- `spike/tflite-model-optimization`

**Purpose:**
- Research & proof-of-concept
- No merge to production directly
- Document findings

**Workflow:**
1. Create from `develop`
2. Experiment without constraints
3. Share findings in PR comments
4. Merge findings into documentation
5. Delete after learning documented

**Lifetime:** 3-5 days max

---

## Naming Convention

```
<type>/<epic-or-ticket>-<short-description>

Types: feature, bugfix, hotfix, release, epic, spike, chore, docs
```

**Examples:**
```
feature/epic1-farm-list
bugfix/epic1-location-sorting
chore/update-dependencies
docs/api-documentation
hotfix/auth-token-expiry
spike/offline-storage-analysis
```

---

## Pull Request Workflow

### 1. Create Feature Branch
```bash
# Update develop first
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/epic1-farm-list
```

### 2. Commit with Conventional Commits
```bash
# Format: <type>(<scope>): <message>

git commit -m "feat(epic1): add farm list screen with search"
git commit -m "test(epic1): add unit tests for farm filtering"
git commit -m "docs(epic1): update README with setup instructions"
```

**Types:** `feat`, `fix`, `test`, `docs`, `style`, `refactor`, `perf`, `chore`

### 3. Push & Create PR
```bash
git push origin feature/epic1-farm-list
# Then create PR via GitHub UI or CLI
```

### 4. PR Template (Auto-filled)
```markdown
## Description
Brief description of changes

## Related Issue
Closes #123 (if applicable)

## Type of Change
- [ ] Feature
- [ ] Bugfix
- [ ] Documentation

## Testing Done
- [ ] Unit tests added
- [ ] Widget tests passed
- [ ] Manual testing completed

## Screenshots/Demo
(if UI changes)

## Checklist
- [ ] Code follows project style guide
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings generated
```

### 5. Review & Approval
- Minimum 1 approval for `develop`
- Minimum 2 approvals for `main`
- All CI checks must pass
- Conflicts resolved

### 6. Merge Strategy
```bash
# Prefer: Squash and merge (for features)
# Use: Create a merge commit (for releases, epics)
# Avoid: Rebase and merge (breaks linear history)
```

---

## CI/CD Integration

### Triggers
| Branch Pattern | Trigger | Action |
|---|---|---|
| `main` | Push/PR | Full CI (tests, security, build) |
| `develop` | Push/PR | Full CI + coverage check |
| `feature/*`, `bugfix/*` | Push/PR | Basic CI (tests, linting) |
| `epic/*` | Push/PR | Full CI |
| `release/*` | Push/PR | Full CI + artifact build |
| `hotfix/*` | Push/PR | Full CI (fastest) |
| `spike/*` | Push | Skip CI (optional) |

### Status Checks Required
- ✅ Code review (CODEOWNERS)
- ✅ Flutter analyze (linting)
- ✅ Unit tests (80% coverage)
- ✅ Widget tests
- ✅ Security scan
- ✅ SonarQube quality gate
- ✅ Build APK/AAB/IPA (for main/develop)

---

## Deployment Pipeline

```
┌──────────────────────────────────────────────────────┐
│                    DEVELOPMENT                        │
│  Branches: feature/*, bugfix/*, spike/*              │
│  CI: Basic tests + linting                           │
│  Target: develop                                      │
└────────────┬─────────────────────────────────────────┘
             │
             ↓ (PR review + merge)
┌──────────────────────────────────────────────────────┐
│                    INTEGRATION                        │
│  Branch: develop                                      │
│  CI: Full tests + coverage + security                │
│  Deploy: Staging environment                         │
│  Duration: Continuous                                │
└────────────┬─────────────────────────────────────────┘
             │
             ↓ (Epic complete + team decision)
┌──────────────────────────────────────────────────────┐
│                    RELEASE PREP                       │
│  Branch: release/X.Y.Z                               │
│  CI: Full + artifact build                           │
│  Duration: 2-3 days (testing + fixes)                │
└────────────┬─────────────────────────────────────────┘
             │
             ↓ (Final approval)
┌──────────────────────────────────────────────────────┐
│                   PRODUCTION                          │
│  Branch: main                                         │
│  Deploy: App Store + Play Store + Web                │
│  Duration: 1 deployment per sprint (1-2 weeks)       │
└──────────────────────────────────────────────────────┘
```

---

## Conflict Resolution

### 1. Prevent Conflicts
```bash
# Keep branch up-to-date before PR
git checkout develop
git pull origin develop
git checkout feature/your-feature
git rebase develop
```

### 2. Resolve During PR
```bash
# If conflicts appear during merge:
git checkout develop
git pull origin develop
git checkout feature/your-feature
git rebase develop

# Resolve conflicts in editor
# Then force-push
git push origin feature/your-feature --force-with-lease
```

### 3. Merge Conflicts in Epic Branch
- Epic branch merges regularly from `develop`
- Features merge into epic first
- Reduces conflicts at `develop` level

---

## Team Workflows

### Scenario 1: Multiple Features in Same Epic
```
develop
  ├─ epic/1-crop-monitoring (Week 1)
  │   ├─ feature/epic1-farm-list
  │   ├─ feature/epic1-weather-widget
  │   └─ feature/epic1-offline-sync
  ├─ epic/2-ai-predictions (Week 5)
  │   ├─ feature/epic2-model-inference
  │   └─ feature/epic2-prediction-display
  └─ main (production)
```

**Workflow:**
1. Epic branches created at start
2. Multiple teams work on features in parallel
3. Features PR to epic branch (faster reviews, less risk)
4. Epic branch PR to develop when complete
5. No blocking between teams

### Scenario 2: Urgent Hotfix During Development
```
main → hotfix/critical-bug
       ├─ Fix + test
       ├─ Merge to main (deploy)
       └─ Merge to develop (sync)

develop (continues unaffected)
```

### Scenario 3: Release Cycle
```
develop → release/1.0.0
          ├─ Version bump
          ├─ Changelog
          ├─ Final tests
          ├─ Bugfixes only
          └─ Merge to main (deploy) + tag v1.0.0
             + merge back to develop
```

---

## Best Practices

### Daily Development
✅ **DO:**
- Create feature branches for all work
- Commit frequently (at least daily)
- Push to origin daily (backup)
- Keep branches small (<500 lines preferred)
- Rebase before creating PR (clean history)
- Write descriptive commit messages

❌ **DON'T:**
- Commit directly to `develop` or `main`
- Create branches from `main` (except hotfix)
- Force-push to public branches after PR created
- Merge without CI checks passing
- Mix unrelated changes in one PR
- Leave branches stale (merge or delete after 2 weeks)

### Code Review
✅ **DO:**
- Review code within 24 hours
- Test locally before approving
- Comment on concerns, not criticisms
- Request changes (don't just reject)
- Approve when quality threshold met

❌ **DON'T:**
- Approve without testing
- Merge own PRs
- Approve based on commit count alone
- Delay review for non-blocking feedback

### Git Hygiene
```bash
# Delete merged branches locally
git branch -d feature/epic1-completed

# Delete merged branches remotely
git push origin --delete feature/epic1-completed

# View branch status
git branch -vv

# Clean up stale tracking branches
git remote prune origin
```

---

## Metrics & Monitoring

### Branch Health
- Average PR lifetime: < 2 days
- Average review time: < 24 hours
- CI pass rate: > 95%
- Merge conflicts: < 2 per week (epic branches)

### Quality Gates
- Test coverage: ≥ 80% (tracked in PR)
- SonarQube: Quality gate must pass
- Security: 0 critical/high vulnerabilities
- Linting: All warnings resolved

---

## Quick Reference

```bash
# Create feature branch
git checkout develop && git pull
git checkout -b feature/epic1-farm-list

# Push and create PR
git push -u origin feature/epic1-farm-list

# Keep updated during development
git rebase develop  # (if no PR yet)
git pull origin develop  # (if PR exists)

# Delete after merge
git branch -D feature/epic1-farm-list
git push origin --delete feature/epic1-farm-list

# For emergency hotfix
git checkout main && git pull
git checkout -b hotfix/critical-bug
# ... fix ...
git push -u origin hotfix/critical-bug
```

---

## Troubleshooting

### "I committed to develop by mistake"
```bash
# Create new feature branch at current commit
git branch feature/my-feature
# Reset develop to origin
git reset --hard origin/develop
# Switch to feature branch
git checkout feature/my-feature
```

### "My branch is too far behind"
```bash
# Rebase onto latest develop
git fetch origin
git rebase origin/develop
# Force-push if already pushed
git push origin <branch> --force-with-lease
```

### "I need to undo a commit"
```bash
# Keep changes, undo commit
git reset --soft HEAD~1

# Remove commit + changes
git reset --hard HEAD~1

# Then push if already public
git push origin <branch> --force-with-lease
```

---

## Questions & Escalation

- **Branching questions:** Refer to this document
- **Conflict help:** Slack #development-support
- **CI/CD issues:** Slack #devops-support
- **Urgent hotfixes:** @dev-lead approval needed

---

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | Dec 9, 2025 | Initial branching strategy (Git Flow) |

---

**Last Updated:** December 9, 2025
**Maintained By:** Development Team
