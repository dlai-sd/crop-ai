# GitHub Branch Protection Rules

This file documents the branch protection configuration to implement via GitHub settings.

## Implementation Steps

Go to: GitHub Repository > Settings > Branches > Add branch protection rule

---

## Main Branch Protection

**Branch name pattern:** `main`

### Protection Settings
- [x] Require a pull request before merging
  - [x] Require approvals: **2**
  - [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging
  - [x] Require code owner review

- [x] Require status checks to pass before merging
  - Required status checks:
    - `flutter-ci / code-review`
    - `flutter-ci / unit-tests`
    - `flutter-ci / security-scan`
    - `flutter-ci / sonarqube`
    - `build / build-status`

- [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Require conversation resolution before merging
- [x] Include administrators in restrictions
- [x] Restrict who can push to matching branches
  - Allow: Deploy bot only (optional)

---

## Develop Branch Protection

**Branch name pattern:** `develop`

### Protection Settings
- [x] Require a pull request before merging
  - [x] Require approvals: **1**
  - [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging

- [x] Require status checks to pass before merging
  - Required status checks:
    - `flutter-ci / code-review`
    - `flutter-ci / unit-tests`
    - `flutter-ci / security-scan`
    - `flutter-ci / sonarqube`

- [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Require conversation resolution before merging

---

## Epic Branch Protection

**Branch name pattern:** `epic/*`

### Protection Settings
- [x] Require a pull request before merging
  - [x] Require approvals: **1**
  - [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging

- [x] Require status checks to pass before merging
  - Required status checks:
    - `flutter-ci / code-review`
    - `flutter-ci / unit-tests`
    - `flutter-ci / security-scan`
    - `flutter-ci / sonarqube`

- [x] Dismiss stale pull request approvals when new commits are pushed

---

## Release & Hotfix Branch Protection

**Branch name pattern:** `release/*`  
**Branch name pattern:** `hotfix/*`

### Protection Settings
- [x] Require a pull request before merging
  - [x] Require approvals: **1**
  - [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging

- [x] Require status checks to pass before merging
  - Same as epic branches

---

## CODEOWNERS Configuration

Create `.github/CODEOWNERS` file:

```
# Global code owner
*                          @dlai-sd/core-team

# Mobile app
/mobile/**                 @dev1 @dev2
/mobile/lib/**             @dev1 @dev2
/mobile/test/**            @dev1 @dev2

# CI/CD
/.github/workflows/**      @devops-engineer

# Backend
/backend/**                @backend-lead

# Documentation
*.md                       @dlai-sd/core-team

# Android specific
/mobile/android/**         @dev1 @dev2

# iOS specific
/mobile/ios/**             @dev1 @dev2
```

---

## Required Status Checks

These should be automatically detected from `.github/workflows/`:

### From `mobile-ci.yml`
- `flutter-ci / code-review` - Flutter analyze + format check
- `flutter-ci / unit-tests` - Unit tests + coverage
- `flutter-ci / security-scan` - Dependency audit + secrets
- `flutter-ci / sonarqube` - Code quality analysis

### From `mobile-build.yml`
- `build / build-status` - APK/AAB/IPA build verification

---

## Auto-merge Settings (Optional)

Enable auto-merge for:
- **Dependabot PRs:** Auto-merge patch updates
- **Renovate PRs:** Auto-merge patch updates
- **Internal refactors:** Manual merge preferred

---

## Bypass Rules

Only these accounts can bypass protection:
- GitHub admin (emergency only)
- Deploy bot (for automated releases)

**Log bypass events** for audit trail.

---

## Enforcement Rules

| Violation | Action |
|---|---|
| Merge without approval | Revert + meeting |
| Merge without CI pass | Revert + fix + retry |
| Bypass protection | Incident review |
| Stale branch merge | Revert to develop |

---

## Implementation Checklist

- [ ] Configure `main` branch protection
- [ ] Configure `develop` branch protection
- [ ] Configure `epic/*` branch protection
- [ ] Configure `release/*` branch protection
- [ ] Configure `hotfix/*` branch protection
- [ ] Add `.github/CODEOWNERS` file
- [ ] Set required status checks
- [ ] Enable dismissal of stale reviews
- [ ] Enable auto-updates for branches
- [ ] Test PR creation & validation
- [ ] Communicate rules to team

---

**Last Updated:** December 9, 2025
