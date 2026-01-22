---
description: resolve-ai-pr-reviews スキルを使用してAIのPRレビューフィードバックを解決します。
---

## User Input

```text
$ARGUMENTS
```

続行する前に、ユーザーの入力を必ず考慮してください（空でない場合）。

## Execution Rules

- `.codex/skills/resolve-ai-pr-reviews/SKILL.md` を読み、厳密に従う。
- `gh` を使って CodeRabbit/Gemini のコメントを収集し、未解決事項を日本語で要約する。
- 修正を適用し、Geminiスレッドを解決し、push し、指示どおり再レビュー依頼を行う。
- Gemini再レビュー依頼は `/gemini review` を使用する。
