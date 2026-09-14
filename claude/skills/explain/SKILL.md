---
name: explain
description: >
  Use when the user asks to explain, step-by-step, what was just done in
  the session (e.g. "explain what you did step-by-step", "walk me through
  this slowly"). Produces a slow, well-paced explanation that introduces
  context and concepts as it goes, grounded in concrete examples.
---

# Step-by-Step Explanation

Explain what was done in this session, slowly and clearly, introducing
context as you go rather than assuming the reader already has it.

Follow these rules when writing the explanation:

- Walk through what was done **step-by-step**, in plain, simple language.
- Ground every step in a **concrete example**: real (or realistic mock)
  data artifacts, a short code snippet, or a worked trace — not just
  abstract description.
- Introduce **every technical concept** the first time it's used, in
  plain words, before relying on it.
- Minimize jargon. If a technical term is unavoidable, explain it in
  plain words right after using it.
- For any **metric or number**, explain exactly how it's calculated —
  the formula in plain words plus a small worked example with real
  numbers.
- Assume the reader **does not remember the conversation** — write as a
  standalone document, building up context as it goes, not a recap that
  references "as discussed above."
- Output well-formatted text (headers, short paragraphs, code blocks
  where useful) — not a wall of prose.
- Add extra detail wherever it helps the reader follow along, even if
  not strictly asked for.
