# Python Code Style

Applies to all `.py` files in the repository. This is the personal-default
version — a project's own `.claude/rules/python-style.md`, if present,
overrides or extends this.

## General Rules

- Always add **type hints** in all function signatures
- Use **Google-style docstrings** for ALL functions, including private ones (`_func`)
- Max function length: **100 lines**
- Max nesting depth: **4 levels**
- Match existing code style in the file you're modifying

## Writing clarity (docstrings, comments, instructions)

Write in plain, simple language — short, direct sentences over dense or
jargon-heavy phrasing. Introduce a technical term or a variable/concept from
elsewhere before you lean on it, even at the cost of repeating context.
Applies to docstrings, inline comments, and any instructions you write.

## Comment and Config Brevity

Comments and config-file parameter descriptions (YAML, TOML, etc.) must stay
short — a line or two stating what the setting does, not a narrative. Only
add a comment when the logic isn't self-evident. Don't inline stats,
migration history, root-cause writeups, or FIXME essays next to a config key
or comment; that belongs in the PR description or `docs/`, which is where a
reader looking for that context will already check. If a value's rationale
needs more than two lines, link to the doc instead of pasting it. This is
the canonical location for the rule — don't duplicate it elsewhere.

**Checkable limit:** a comment block (consecutive `#` lines, or one field's
worth of docstring prose beyond its required Args/Returns) stays under **4
lines**. If explaining a default needs more, write 1-2 lines of *behavior*
plus one line linking to a doc for the *why*. A run id, metric value/delta,
or an incident phrase ("crashed", "OOM'd", "hung for N minutes") appearing
inline is a signal that content belongs in the doc, not the comment — move
it on sight rather than trimming it in place. This applies equally to a
repeated rationale: state it once (in the doc, or in the one
docstring/comment closest to the code it governs) and have every other
reference to it be a link, not a restatement.

Before (7 lines, inline rationale):
```python
# Lowered 20 -> 8: the discriminators saturate (disc_acc/metadisc_acc ~1.0) by
# ~epoch 2 on every run, so a 20-epoch warmup froze the policy ~18 epochs
# longer than needed (~100 min of the 6h budget on run full-run-fixes-20260716)
# purely to keep an already-trained disc trained. Cut further to 2 after the
# ablation experiment confirmed no benefit from waiting longer. Upstream's
# 20/100 ratio isn't load-bearing here.
ac_update_delay: int = 2
```

After (2 lines + doc link):
```python
# Train discriminators alone for this many epochs before updating the AC.
# See docs/tuning_rationale.md for why 2 is enough.
ac_update_delay: int = 2
```

## Docstring Requirements

**All public/larger functions** require full docstrings with Args, Returns, and Example:

```python
def add_numbers(a: int, b: int) -> int:
    """Add two integers.

    Args:
        a: First number.
        b: Second number.

    Returns:
        Sum of a and b.

    Example:
        >>> add_numbers(2, 3)
        5
    """
```

**Private functions** (`_func`) - 1-2 line summary only:

```python
def _apply_age_filter(df: pd.DataFrame) -> pd.DataFrame:
    """Remove patients outside the valid age range."""
```

**Complex private functions** (> ~30 lines, non-trivial I/O) — add a short `Example:` block showing concrete input → output so a reader can verify their mental model without running the code.

## What to Avoid

- Don't create deep subfunctions to micro-optimize - prioritize clarity
- Don't add redundant null checks or defensive try/except for expected inputs
- Don't over-engineer for hypothetical future requirements - inline
  single-use variables/functions rather than abstracting prematurely

## Fail Fast, No Silent Fallbacks

**A silenced error doesn't disappear — it resurfaces three steps downstream
wearing a different bug's clothes.** Correctness beats uptime. If a load,
join, or filter breaks or comes back empty, `raise` — never log-and-skip,
default, or let execution carry on as if it succeeded, even if that stops
the whole run.

- Don't wrap loading/filtering in try/except to substitute a default, skip a
  file, or return an empty result on missing/malformed input — let it raise
  and propagate. Don't assume "upstream must be fine" and guard against an
  empty result either.
- Don't catch broad exceptions (`except Exception`) or swap in
  `logger.warning(...)` for a `raise`. Catch only the narrowest expected
  exception, and re-raise with context if you handle it at all.
- Hit a real failure while working (missing file, empty dataframe, broken
  assumption)? That's a bug — fix it at the source, not with a workaround in
  the caller.
