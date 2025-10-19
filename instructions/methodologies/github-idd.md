# GitHub Issue-Driven Development

A systematic approach to software development where GitHub Issues serve as the foundation for all development activities.

## Core Principles

### Issue as Source of Truth
- Every task begins with a GitHub Issue
- Issues define scope, requirements, and acceptance criteria
- No code changes without an associated Issue
- Issues track progress and decisions

### Process Flow

1. **Issue Creation**
   - Clear problem statement
   - Acceptance criteria
   - Technical approach (if known)
   - Story points estimation

2. **Issue Reading**
   - **MANDATORY**: Read and understand Issue before starting work
   - Clarify requirements if unclear
   - Comment questions directly on Issue

3. **Development**
   - Create branch from Issue
   - Reference Issue in all commits
   - Update Issue with progress

4. **Completion**
   - Link PR to Issue
   - Close Issue when PR merged
   - Document learnings in Issue comments

## Issue Structure

### Required Elements
```markdown
## Problem
Clear description of the problem to solve

## Solution
Proposed approach (can be refined during development)

## Acceptance Criteria
- [ ] Specific measurable outcome 1
- [ ] Specific measurable outcome 2

## Technical Notes
Implementation considerations, constraints

## Story Points
Complexity estimation (1-5, max 8 for exceptional cases)
```

### Issue Types
- **Feature**: New functionality
- **Bug**: Problem to fix
- **Enhancement**: Improvement to existing feature
- **Documentation**: Documentation updates
- **Research**: Investigation tasks

## Development Workflow

### Starting Work
```bash
# 1. Read Issue thoroughly
# 2. Create branch
git checkout -b feature/123_issue_description

# 3. Start development with Issue context
```

### During Development
- Comment on Issue with blockers
- Update Issue with significant decisions
- Link related Issues
- Add discovered tasks as new Issues

### Completing Work
1. Ensure all acceptance criteria met
2. Create PR linking to Issue
3. Update Issue with completion notes
4. Close Issue after merge

## Benefits

### Traceability
- Every change linked to business need
- Decision history preserved
- Progress visible to all stakeholders

### Collaboration
- Asynchronous communication
- Clear ownership
- Reduced meetings

### Quality
- Clear requirements upfront
- Scope control
- Systematic approach

## Best Practices

### DO
- Start every session by reading the Issue
- Keep Issues focused and atomic
- Update Issues with important findings
- Link related Issues
- Use Issue templates

### DON'T
- Start coding without an Issue
- Create overly broad Issues
- Leave Issues without updates
- Close Issues without verification
- Ignore Issue comments

## Integration with Other Methodologies

### With TDD
1. Read Issue → Understand requirements
2. Write tests based on acceptance criteria
3. Implement to pass tests
4. Update Issue with test results

### With Scrum
- Issues = Sprint backlog items
- Issue points = Story points
- Issue milestones = Sprints
- Issue board = Sprint board

## Tools and Automation

### GitHub Features
- Issue templates
- Project boards
- Milestones
- Labels
- Automation with Actions

### CLI Commands
```bash
# Create Issue
gh issue create --title "..." --body "..."

# List Issues
gh issue list --assignee @me

# View Issue
gh issue view 123

# Update Issue
gh issue comment 123 --body "Progress update..."
```

## Metrics and Monitoring

### Key Metrics
- Issues created vs closed
- Average time to close
- Issues per PR
- Story points completed

### Health Indicators
- ✅ All PRs linked to Issues
- ✅ Issues updated regularly
- ✅ Clear acceptance criteria
- ❌ Orphaned PRs without Issues
- ❌ Stale Issues without updates