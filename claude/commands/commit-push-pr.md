---
name: commit-push-pr
description: Commit changes, push to remote, and create/update PR with intelligent description
---

# Commit, Push, and Create PR

Commits all changes, pushes to remote, and creates (or updates existing) PR with smart description based on change complexity.

## Steps

1. **Commit changes**: Stage files explicitly after reviewing `git status`, commit with provided message (or generate one), include co-author
2. **Push to remote**: `git push` (or `git push -u origin <branch>` if new)
3. **Create/update PR**: Open new PR or update existing one

Note: Pre-commit hooks run automatically on commit.

## PR Description Rules

**Small fixes** (≤3 files, ≤100 lines, or >70% config):
- Before/after table with exact code/config changes
- Show specific snippets from diff

**Complex changes** (>3 files or >100 lines):
- High-level summary focusing on surface-level impacts
- Group by: core changes, config updates, API changes
- List files by category: core, config, tests

Always use base branch: `main`
