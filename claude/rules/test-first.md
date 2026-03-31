---
paths:
  - "**/*.rs"
  - "**/*.py"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.go"
  - "**/*.rb"
  - "**/*.java"
  - "**/*.kt"
---

# Test-First Workflow

Default to test-driven development when implementing features or fixing bugs. This is the baseline, not an optional extra.

## Entering a Codebase

Before writing any code, run the existing test suite. This accomplishes three things:

1. Locates and wires up the test harness for automatic reuse.
2. Reveals project scale and health (how many tests, how many pass).
3. Calibrates toward a testing mindset for the rest of the session.

If tests do not exist yet, say so explicitly. Suggest setting up the harness before implementing.

## Red/Green TDD

For new features and bug fixes:

1. **Red**: Write a failing test that captures the expected behavior or reproduces the bug. Run it. Confirm it fails.
2. **Green**: Write the minimum implementation to make the test pass. Run it. Confirm it passes.
3. **Refactor**: Clean up only if the code is unclear. Do not gold-plate.

Skipping the red confirmation risks writing a test that already passes without exercising the implementation. Always verify the failure first.

## Manual Testing Converts to Automated Tests

When manual testing (curl, browser, REPL) reveals an issue:

1. Write a failing test that reproduces the issue.
2. Fix the issue.
3. Confirm the test passes.

Do not fix the issue first and write the test after. The test should prove the fix works, not just document it retroactively.

## Style Conformance

When a project already has tests, match their style: framework, assertion patterns, naming conventions, file organization. Read at least two existing test files before writing new ones.

## When to Skip

TDD adds overhead that is not always justified. Skip for:

- Exploratory prototypes the user explicitly marks as throwaway.
- One-off scripts or data migrations.
- Configuration changes (YAML, TOML, env files).
- Documentation-only changes.

When skipping, say why. Do not silently omit tests.
