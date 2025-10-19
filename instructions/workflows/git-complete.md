# Complete Git & GitHub Workflow Guide

GitHub Flowベースの完全なGit・GitHub運用ガイド

## 🔄 Basic Workflow

### 1. Issue-Driven Development
- 全ての作業はGitHub Issueから開始
- Issue作成時は適切なラベル付与
- ストーリーポイント最大5まで分割（例外的に8まで許容）

### 2. Branch Strategy
```bash
# Branch naming convention
{type}/{issue-number}_{description}

# Types:
# - feature/ : 新機能
# - fix/     : バグ修正
# - refactor/: リファクタリング
# - docs/    : ドキュメント
# - test/    : テスト
# - chore/   : 雑務

# Examples
feature/123_user_authentication
fix/456_session_timeout
refactor/789_extract_service
```

### 3. Development Process
```bash
# 1. Create branch from Issue
git checkout -b feature/123_description

# 2. Make changes and commit frequently
git status                    # Review changes
git add .                     # Stage related changes
git commit -m "message"       # Commit with proper format

# 3. Push and create PR
git push -u origin feature/123_description
gh pr create --title "#123: Brief description"
```

## 📝 Commit Message Format

### Required Convention
```
type(scope): #issue description [domain:xxx] [tags:keyword1,keyword2]
```

### Examples
```bash
feat(auth): #123 implement JWT authentication [domain:authentication] [tags:jwt,login]
fix(session): #456 resolve timeout issue [domain:session] [tags:timeout,cleanup]
refactor(user): #789 extract user service [domain:user] [tags:service,extraction]
```

### Commit Guidelines
- Keep commits atomic and focused
- Each commit should leave code in working state
- Write descriptive messages explaining the "why"
- Commit at logical checkpoints

## 🔍 Pull Request Rules

### Single PR Policy (CRITICAL)
- **Only one open PR allowed at a time**
- Complete current PR before starting new work
- Prevents merge conflicts and maintains quality

### PR Creation Process
1. **Title Format**: `#Issue-number: Brief description`
2. **Open in browser**: After creating, run `gh pr view --web <PR number>`
3. **Description Template**:markdown
## Overview
Brief summary of what, why, and how

## Changes
- Detailed change 1
- Detailed change 2

## Related Issues
Closes #123

## Testing
- [ ] Local tests passed
- [ ] CI checks green
```

### Review & Merge Process
1. Create PR with proper description
2. Wait for CI checks to pass
3. Address review feedback:
   - If within Issue scope: Fix immediately
   - If outside scope: Create new Issue
4. Merge after approval
5. Delete branch and close Issue

## 🔧 Commands & Tools

### Preferred Tools Priority
1. GitHub API tools (when available)
2. `gh` CLI command
3. Web interface for complex operations

### Common Git Commands
```bash
# Status and staging
git status
git add {files}
git add .

# Committing
git commit -m "type(scope): #issue description [domain:xxx] [tags:keywords]"

# Branch management
git checkout -b feature/123_description
git checkout main
git pull

# PR management
gh pr create --title "#123: Description" --body "..."
gh pr status
gh pr merge --squash
```

### Search Patterns for Git History
```bash
# By domain
git log --grep="[domain:authentication]" --oneline
git log --grep="[domain:user]" --oneline

# By tags
git log --grep="[tags:.*login.*]" --oneline
git log --grep="[tags:.*jwt.*]" --oneline

# By issue
git log --grep="#123"

# By type
git log --grep="feat.*[domain:.*]" --oneline
git log --grep="fix.*[domain:.*]" --oneline
```

## 📊 GitHub Issue Management

### Issue Structure
```markdown
## Problem
Clear description of the problem

## Solution
Proposed approach

## Acceptance Criteria
- [ ] Specific outcome 1
- [ ] Specific outcome 2

## Story Points
1-5 (max 8 for exceptional cases)
```

### Labels & Organization
- Apply appropriate labels consistently
- Link Issues to PRs properly
- Update Issue status throughout development
- Close Issues after PR merge

## 🚨 Persistent Documentation Requirements

### Critical for AI Continuity
As an AI without conversation continuity, you MUST:

1. **Immediately document** all discoveries in GitHub Issues
2. **Include specific details**: file names, line numbers, exact problems
3. **Propose solutions** or investigation paths
4. **Update existing Issues** with progress
5. **Record interruptions** with current state and next steps

### Documentation Standards
- Create Issues for all TODOs and improvements
- Comment on Issues with significant findings
- Link related Issues for traceability
- Record decisions and their rationale

## ⚡ Troubleshooting & Optimization

### Performance Investigation
```bash
# Find commits by domain and timeframe
git log --grep="[domain:authentication]" --since="1 month ago"
git log --grep="[domain:user]" --since="3 months ago"

# Investigate specific features
git log --name-only | grep auth
git log -- "src/auth/*"

# Cross-reference multiple domains
git log --grep="[domain:user].*[domain:session]"
```

### Quality Checks
- Ensure all commits reference Issues
- Verify proper domain/tag usage
- Check for atomic, logical commits
- Validate PR descriptions are complete

## 🎯 Git Workflow Patterns

### Merge Strategies

#### Squash and Merge（推奨）
```bash
# PRのコミットを1つにまとめる
# クリーンな履歴を維持
gh pr merge --squash
```

#### Rebase and Merge
```bash
# 線形履歴を維持
# コミット履歴を保持
git rebase main feature/branch
gh pr merge --rebase
```

### Conflict Resolution

#### Rebase時の解決
```bash
# 1. リベース開始
git rebase main

# 2. コンフリクト解決
git status  # コンフリクトファイル確認
# ファイル編集

# 3. 続行
git add .
git rebase --continue
```

#### Merge時の解決
```bash
# 1. マージ
git merge feature/branch

# 2. 解決（コンフリクトマーカーを編集）
# <<<<<<< HEAD
# 現在のブランチの内容
# =======
# マージするブランチの内容  
# >>>>>>> feature/branch

# 3. コミット
git add .
git commit
```

### Automation Hooks

#### pre-commit設定
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: eslint
        name: ESLint
        entry: npm run lint
        language: system
        files: \.(js|jsx|ts|tsx)$
```

#### CI/CD統合
```yaml
# .github/workflows/pr.yml
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test
      - run: npm run lint
```

### Best Practices Checklist
- [ ] ブランチ戦略選択（GitHub Flow推奨）
- [ ] コミット規約遵守
- [ ] PRテンプレート使用
- [ ] レビュー実施
- [ ] 自動化設定
- [ ] マージ戦略決定（Squash推奨）

This consolidated guide replaces the previous scattered Git documentation and provides a single source of truth for all Git & GitHub operations.