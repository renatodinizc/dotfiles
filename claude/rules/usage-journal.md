# Usage Journal

Temporary rule for collecting usage data to improve these AI dotfiles. Remove after the trial period.

## During Sessions

Keep mental notes as you work:

- Which rules or protocols activated (IHP tier 1/2/3, staff-engineer checks, rust-engineering patterns, operational discipline)
- Moments where a rule improved the outcome
- Moments where a rule caused friction or was irrelevant
- Situations where you lacked guidance that a rule could have provided
- User corrections to your approach (these reveal gaps in the rules)

## At Session End

When the user indicates they are wrapping up, when a major unit of work completes, or when you sense a natural stopping point, append a structured entry to `~/.claude/usage-logs/YYYY-MM-DD.md` (create the file and directory if they do not exist).

Use this format:

```
## HH:MM | {project or context}

**Rules activated:** {which rules/protocols fired, be specific}
**Effective:** {what improved the outcome, with a concrete example}
**Friction:** {what caused friction, was ignored, or did not help}
**Missing:** {gaps where the user had to explain something the rules should cover}
**Corrections:** {user corrections to your approach}
```

## Guidelines

- Be honest. If no rules activated, say that. If you cannot tell whether something was effective, say that.
- Specific over vague. "IHP-T2 challenged caching assumption, user accepted and changed approach" beats "rules were helpful."
- Keep entries under 10 lines. This is a log, not an essay.
- If the session was trivial (quick question, no substantial work), skip the entry entirely.
- Do not ask for permission to write the log. Just write it as part of wrapping up.
