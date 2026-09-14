# Testing Guidelines

Applies to all test files. This is the personal-default version — a
project's own `.claude/rules/testing.md`, if present, overrides or extends
this with project-specific structure, commands, and e2e requirements.

## Rules

- Use **pytest** with `pytest.fixture` and `monkeypatch` — never `unittest`
- Always implement tests through **functions**, never classes
- Test **general functionality + 1-2 edge cases max** — keep it minimal and maintainable
- Never test private/internal methods (those starting with `_`)

## Example Pattern

```python
import pytest
from mypackage.foo import bar


@pytest.fixture
def sample_input():
    return {"a": 1, "b": 2}


def test_bar_returns_result(sample_input):
    result = bar(sample_input)
    assert len(result) > 0


def test_bar_empty_input():
    result = bar({})
    assert result == []
```
