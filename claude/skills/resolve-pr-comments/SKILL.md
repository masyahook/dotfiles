---
name: resolve-pr-comments
description: >-
  Reviews all open comments on a pull request (from humans or bots), evaluates
  their validity, addresses valid ones with code fixes or explanations, and
  posts a reply under each comment describing what was done. Resolves threads
  posted by AI/bots; leaves human threads unresolved. Disagrees politely when a
  comment is wrong or the code is intentional. Answers general questions with
  concise, beginner-friendly explanations and code snippets. Use when asked to
  resolve PR comments, address review feedback, respond to review threads, or
  triage pull request discussions.
---

# Resolve PR Comments

Work through every open review thread on a PR: fix valid issues, explain your reasoning, answer questions, and post a follow-up reply under each comment.

## Step 1 — Identify the PR

```bash
gh pr view --json number,headRefName,baseRefName,title,url
```

Store: `PR_NUMBER`, `HEAD_BRANCH`, `BASE_BRANCH`, `OWNER`, `REPO`.

Derive `OWNER`/`REPO` from the remote URL if needed:
```bash
git remote get-url origin
# e.g. https://github.com/masyahook/chairon-kg.git
```

## Step 2 — Fetch All Open Review Threads

```bash
gh api graphql \
  -F owner="<OWNER>" -F repo="<REPO>" -F pr=<PR_NUMBER> \
  -f query='
    query($owner: String!, $repo: String!, $pr: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          reviewThreads(first: 100) {
            nodes {
              id
              isResolved
              comments(first: 10) {
                nodes {
                  databaseId
                  body
                  path
                  line
                  author { login }
                  url
                }
              }
            }
          }
        }
      }
    }' \
  --jq '.data.repository.pullRequest.reviewThreads.nodes // [] | map(select(.isResolved == false))'
```

> Pass `pr` as a bare integer (`-F pr=4168`), not a string — the latter causes `Could not coerce value "" to Int`.

Also fetch general PR-level (non-diff) comments:
```bash
gh api "repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments" \
  --jq '[.[] | {id, body, author: .user.login, url: .html_url}]'
```

Build a **comment list**. For each item record:
- `thread_id` (for review threads) or `comment_id` (for issue comments)
- `author` login
- `body` text
- `path` + `line` (review threads only)
- `url`

## Step 3 — Classify Each Comment

For every comment, assign one of:

| Type | Description |
|------|-------------|
| **Bug / change-request** | Points to a real problem — needs a code fix |
| **Question** | Asks what something does or why it exists |
| **Disagreement / intentional** | Flags something the author thinks is wrong, but the code is correct as-is |
| **Nitpick / style** | Low-severity suggestion; use judgment |
| **Spam / noise** | Auto-generated chatter with no actionable content |

Detect **AI/bot authors** by checking for these signals:
- Login ends in `[bot]` (e.g. `github-actions[bot]`, `copilot[bot]`)
- Login is a known bot: `dependabot`, `renovate`, `sonarcloud`, `codecov`, `snyk-bot`, `codeclimate-bot`, `bugbot`
- Body follows a rigid templated structure typical of automated tools

## Step 4 — Triage Loop

Process each open comment one by one.

### 4a. Bug / change-request — apply a fix

1. Read the flagged file and line: check whether the issue is valid.
2. **If valid**: apply the fix using `StrReplace` / `Write`, commit, and push:

   ```bash
   git add <files>
   git commit -m "fix(<scope>): <short description>"
   git push
   ```

3. Post a reply under the comment (see §5) referencing the commit SHA.
4. **If the AI posted the thread** → resolve it after replying.

### 4b. Question — write a clear explanation

Assume the reader has **zero prior knowledge of this repo**. Your reply should:
- Define any repo-specific terms on first use (e.g. *"KG — the knowledge graph that maps drug–disease relationships"*)
- Prefer a short code snippet or concrete example over a paragraph of prose
- Be dense — every sentence should carry information a PR reviewer doesn't already have

### 4c. Disagreement — the code is intentional

Post a reply explaining the rationale. Be direct, not defensive. Example structure:

```
This is intentional — <one-sentence reason>.

<Optional: 1-2 sentence elaboration or trade-off explanation>
```

Do **not** change the code. Do **not** resolve the thread (leave it for the human reviewer to close).

### 4d. Nitpick / style — use judgment

Apply if the fix is trivial (< 3 lines) and clearly improves readability. Skip otherwise and note why.

### 4e. Spam / noise — skip

No reply needed. Do not resolve.

## Step 5 — Post a Reply Under Each Addressed Comment

### For review-thread comments (inline diff comments)

```bash
gh api "repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments/<COMMENT_ID>/replies" \
  -X POST \
  -f body="<REPLY_BODY>"
```

### For general PR-level comments

```bash
gh api "repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments" \
  -X POST \
  -f body="<REPLY_BODY>"
```

### Reply templates

**Fixed (with commit reference):**
```
Fixed in <commit-sha> — <one-line description of what changed>.
```

**Fixed (explanatory):**
```
Fixed in <commit-sha>.

<1-2 sentences explaining the root cause and the approach taken>
```

**Explanation / answer:**
```
<concise answer — define terms, add a snippet if helpful>
```

**Disagree:**
```
This is intentional — <reason>. <optional elaboration>
```

Keep replies short. A code snippet is often more useful than a paragraph.

## Step 6 — Resolve Bot/AI Threads

After posting a reply to a bot-authored thread, resolve it:

```bash
gh api graphql \
  -F threadId="<THREAD_ID>" \
  -f query='
    mutation($threadId: ID!) {
      resolveReviewThread(input: { threadId: $threadId }) {
        thread { isResolved }
      }
    }'
```

**Never resolve threads posted by human reviewers.**

## Edge Cases

| Situation | Action |
|-----------|--------|
| Comment refers to deleted/moved code | Note this in the reply; do not guess the new location |
| Fix requires changes to >3 files | Summarize the plan in a reply first, then apply |
| Comment is ambiguous | Ask for clarification in the reply; do not guess |
| Push fails (protected branch) | Post the diff in the reply instead; alert the user |
| No open threads found | Report "No open review threads found on PR #<N>" and exit |
| GraphQL `Could not coerce value "" to Int` | Ensure `-F pr=<N>` is an unquoted integer, not a string |
