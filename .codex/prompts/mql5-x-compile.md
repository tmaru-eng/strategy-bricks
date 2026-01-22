---
description: MQL5 コンパイルを X: ドライブ経由で実行するスラッシュコマンド。
---

## User Input

```text
$ARGUMENTS
```

ユーザー入力が空でない場合は必ず考慮すること。

## 実行ルール

- `.codex/skills/mql5-x-compile/SKILL.md` を読み、記載手順に厳密に従う。
- .mq5 / .mqh 編集後は必ずこのスキルを使用してコンパイルする。
- 失敗判定は exit code ではなく、.ex5 とログの生成で確認する。
- X: ドライブの前提条件が満たされていない場合は、スキルの「Prerequisites」に従う。
