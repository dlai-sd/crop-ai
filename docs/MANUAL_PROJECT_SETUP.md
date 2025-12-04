# 📋 GitHub Projects Manual Setup Guide

**Status**: Required - GitHub API Limitation  
**Last Updated**: December 4, 2025  
**Tech Note**: Projects V2 API does not support item/column modifications via tokens

---

## ⚠️ API Limitation Explanation

GitHub's Projects V2 API has a known limitation: **Personal Access Tokens (PATs) cannot programmatically**:
- Add issues to projects
- Create/modify project columns
- Rename projects
- Update project settings
- Query project structure

**This is not a bug** — it's by design. GitHub requires direct web UI interaction for project management.

---

## ✅ What CAN Be Done Programmatically

- ✅ Create issues with labels
- ✅ Link issues together
- ✅ Update issue descriptions
- ✅ Add milestones to issues
- ✅ Manage issue workflows

---

## 📊 What MUST Be Done Manually (Web UI)

This guide covers all manual steps needed to complete Projects 2, 3, and 4 setup.

---

# 🛠️ Manual Setup Steps

## **PROJECT 2: Phase 2: API & Data**

### Step 1: Rename Project
1. Go to: https://github.com/users/dlai-sd/projects/2
2. Click **⚙️ Settings** (gear icon, top right)
3. In "Project name" field, enter: `Phase 2: API & Data`
4. Click **Update**

### Step 2: Add Columns

The project needs 5 columns for API workflow:

1. Click **+ Add Column** button
2. Create columns in this order:

| # | Column Name | Type | Notes |
|---|-------------|------|-------|
| 1 | API Design | Status | Initial design & planning |
| 2 | Implementation | Status | Active development |
| 3 | Integration Testing | Status | Testing with other services |
| 4 | Ready for Deployment | Status | Tested & ready |
| 5 | Done | Status | Deployed to production |

### Step 3: Add Issues to "API Design" Column

Drag these 10 issues into the **API Design** column:

```
Issue #15: Phase 2: API Design & Architecture
Issue #16: Phase 2: Authentication API Implementation
Issue #17: Phase 2: Crop Prediction API Endpoint
Issue #18: Phase 2: Database Schema & Connection Pool
Issue #19: Phase 2: Data Transformation Pipeline
Issue #20: Phase 2: Error Handling & Validation
Issue #21: Phase 2: API Testing & Unit Tests
Issue #22: Phase 2: API Documentation (OpenAPI)
Issue #23: Phase 2: Performance Optimization
Issue #24: Phase 2: API Versioning Strategy
```

**How to drag issues:**
1. Type issue number in search box (e.g., `#15`)
2. Click on the issue in search results
3. Drag it to the **API Design** column
4. Repeat for all 10 issues

---

## **PROJECT 3: Phase 2: Backend & DeepLearn**

### Step 1: Rename Project
1. Go to: https://github.com/users/dlai-sd/projects/3
2. Click **⚙️ Settings** (gear icon, top right)
3. In "Project name" field, enter: `Phase 2: Backend & DeepLearn`
4. Click **Update**

### Step 2: Add Columns

The project needs 6 columns for backend workflow:

| # | Column Name | Type | Notes |
|---|-------------|------|-------|
| 1 | Backlog | Status | New tasks queue |
| 2 | ML Models (Development) | Status | ML-specific work |
| 3 | Backend Services (Development) | Status | Service development |
| 4 | Integration & Testing | Status | Testing phase |
| 5 | Deployment Ready | Status | Ready for production |
| 6 | Done | Status | Deployed & running |

### Step 3: Add Issues to "Backlog" Column

Drag these 10 issues into the **Backlog** column:

```
Issue #25: Phase 2: Backend Service Architecture
Issue #26: Phase 2: ML Model Training Pipeline
Issue #27: Phase 2: Model Inference Engine
Issue #28: Phase 2: Satellite Data Processing Service
Issue #29: Phase 2: Farmer Profile Service
Issue #30: Phase 2: Payment Gateway Integration
Issue #31: Phase 2: Message Queue & Event Bus
Issue #32: Phase 2: Backend Unit & Integration Tests
Issue #33: Phase 2: Logging & Monitoring
Issue #34: Phase 2: Backend Deployment Pipeline
```

---

## **PROJECT 4: Documentation & DevOps**

### Step 1: Rename Project
1. Go to: https://github.com/users/dlai-sd/projects/4
2. Click **⚙️ Settings** (gear icon, top right)
3. In "Project name" field, enter: `Documentation & DevOps`
4. Click **Update**

### Step 2: Add Columns

The project needs 7 columns for docs/devops workflow:

| # | Column Name | Type | Notes |
|---|-------------|------|-------|
| 1 | Docs Backlog | Status | Documentation tasks queue |
| 2 | Docs In Progress | Status | Active documentation work |
| 3 | Docs Review | Status | Awaiting documentation review |
| 4 | Published | Status | Live documentation |
| 5 | DevOps Backlog | Status | Infrastructure tasks queue |
| 6 | Infrastructure Ready | Status | Ready for deployment |
| 7 | Done | Status | Complete & deployed |

### Step 3: Add Issues to Columns

#### **Drag to "Docs Backlog" (5 issues):**
```
Issue #35: Phase 2: API Documentation (Swagger/OpenAPI)
Issue #36: Phase 2: Architecture Documentation
Issue #37: Phase 2: Development Setup Guide
Issue #38: Phase 2: Deployment Guide
Issue #39: Phase 2: Contributing Guidelines
```

#### **Drag to "DevOps Backlog" (5 issues):**
```
Issue #40: Phase 2: Docker & Container Setup
Issue #41: Phase 2: Kubernetes Deployment Config
Issue #42: Phase 2: CI/CD Pipeline Setup (GitHub Actions)
Issue #43: Phase 2: Monitoring & Alerting Setup
Issue #44: Phase 2: Security & Compliance
```

---

# 📝 Step-by-Step: Adding an Issue to a Project

### Method 1: Drag & Drop (Quickest)

1. Open the project board
2. Search for issue number in the top search box (e.g., `#15`)
3. Click the issue link that appears in search results
4. The issue card will appear
5. **Drag the card** to the target column
6. **Drop** to add it to that column

### Method 2: Via Issue Detail View

1. Go to issue: https://github.com/dlai-sd/crop-ai/issues/15
2. Scroll down to "Projects" section
3. Click **Link a project**
4. Select project from dropdown (e.g., "Phase 2: API & Data")
5. Choose the column (e.g., "API Design")
6. Click **Add to project**

---

# ✅ Verification Checklist

Once you've manually set up all projects, verify:

## **Project 1: CropAI Development**
- [ ] Project renamed to "CropAI Development"
- [ ] 6 columns created (Backlog, Todo, In Progress, Under Review, Approved, Done)
- [ ] Issue #1 in "Done" column
- [ ] Issues #2-#11 in "Backlog" column

## **Project 2: Phase 2: API & Data**
- [ ] Project renamed to "Phase 2: API & Data"
- [ ] 5 columns created (API Design, Implementation, Integration Testing, Ready for Deployment, Done)
- [ ] Issues #15-#24 all added to "API Design" column
- [ ] All issues visible in project board

## **Project 3: Phase 2: Backend & DeepLearn**
- [ ] Project renamed to "Phase 2: Backend & DeepLearn"
- [ ] 6 columns created (Backlog, ML Models, Backend Services, Integration & Testing, Deployment Ready, Done)
- [ ] Issues #25-#34 all added to "Backlog" column
- [ ] All issues visible in project board

## **Project 4: Documentation & DevOps**
- [ ] Project renamed to "Documentation & DevOps"
- [ ] 7 columns created (Docs Backlog, Docs In Progress, Docs Review, Published, DevOps Backlog, Infrastructure Ready, Done)
- [ ] Issues #35-#39 added to "Docs Backlog" column
- [ ] Issues #40-#44 added to "DevOps Backlog" column
- [ ] All 10 issues visible in project board

---

# 🚀 After Manual Setup

Once all projects are set up:

1. **Assign Issues to Team Members**
   - Click issue → Add "Assignee" field
   - Select team member

2. **Link Related Issues**
   - In issue details → Click "Link issue"
   - Select related issues across projects

3. **Move Issues as Work Progresses**
   - Drag issues between columns as status changes
   - Update issue descriptions with progress notes

4. **Use Project Views**
   - View all issues across projects
   - Filter by assignee, label, status
   - Track progress toward milestones

---

# 📊 Project Board Views (After Setup)

Each project will display:

```
PROJECT 2: Phase 2: API & Data
┌─────────────┬──────────────┬─────────────────┬──────────────────┬─────┐
│ API Design  │ Implementation│ Integration Test│ Ready for Deploy │Done │
├─────────────┼──────────────┼─────────────────┼──────────────────┼─────┤
│ #15         │              │                 │                  │     │
│ #16         │              │                 │                  │     │
│ #17         │              │                 │                  │     │
│ ... (10)    │              │                 │                  │     │
└─────────────┴──────────────┴─────────────────┴──────────────────┴─────┘
```

---

# 🔧 Troubleshooting

### Issue won't drag to column
- **Solution**: Try Method 2 (Via Issue Detail View)
- Verify issue has been created (check GitHub issues list)

### Project not showing renamed name
- **Solution**: Refresh page (Ctrl+R or Cmd+R)
- Wait 10-15 seconds for GitHub to sync

### Column won't be created
- **Solution**: 
  - Check project settings are unlocked
  - Try renaming instead of creating new column
  - Reload project page

### Can't see issue in search
- **Solution**:
  - Check issue exists: https://github.com/dlai-sd/crop-ai/issues
  - Verify issue number is correct
  - Try searching by title instead of number

---

# 📞 Support

If you encounter issues during manual setup:

1. Check the **Verification Checklist** above
2. Review screenshots of expected column structure
3. Verify all issues #15-#44 exist in repository
4. Ensure you have push access to the repository

---

## 🎯 Expected Outcome

After completing all manual steps:
- ✅ 4 fully configured GitHub Projects
- ✅ 41 issues organized into proper projects
- ✅ Clear workflow columns for each team
- ✅ Ready for Phase 2 development to begin

---

**Last Updated**: December 4, 2025  
**Status**: Manual setup required (GitHub API limitation)  
**Estimated Time**: 20-30 minutes for all 4 projects
