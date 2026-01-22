---
description: Resolve AI PR review feedback using the resolve-ai-pr-reviews skill.
---

## User Input

```text
$ARGUMENTS
```

You MUST consider the user input before proceeding (if not empty).

## Execution Rules

- Read `.codex/skills/resolve-ai-pr-reviews/SKILL.md` and follow it strictly.
- Use `gh` to collect CodeRabbit/Gemini comments and summarize unresolved items in Japanese.
- Apply fixes, resolve Gemini threads, push changes, and request re-review as instructed.
- Use `/gemini review` when requesting Gemini re-review.
