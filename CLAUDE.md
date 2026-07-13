# dev-agent-team — Claude Code Instructions

## このリポジトリの目的

Claude Code 向けの Agent Team / Skill / Command 構想を整理・開発するリポジトリ。
ドキュメントとマークダウンが中心。コードは補助的に含まれる場合がある。

## 作業ルール

- ドキュメントを更新する際は既存の文体・トーンを維持する
- エージェント定義を変更する場合は CONCEPT.md との整合を確認する
- コマンド・スキルを追加する場合はテンプレートに従う
- コミットメッセージは Conventional Commits 形式

## ファイル構成の規則

- `agents/` — エージェントの役割定義。1ファイル = 1エージェント
- `commands/` — スラッシュコマンドの仕様。実際の .md ファイルとして Claude Code に配置することを想定
- `skills/` — エージェントが使う汎用スキル定義
- `templates/` — 成果物テンプレート。変数は `{{変数名}}` 形式
- `examples/` — 具体的なサンプル。実際のユースケースで記述
- `workflows/` — 開発ワークフローの markdown 仕様（8 Phase の司令塔）
- `dynamic-workflows/` — Claude Code Dynamic Workflows の実行可能 JS。`workflows/`（markdown 仕様）とは別物
- `docs/` — 導入ガイド・ネイティブ機能併用ルールなどの解説ドキュメント

## 禁止事項

- 空のファイルをコミットしない
- テンプレートを埋めずに agent/skill を定義しない
- CONCEPT.md の方針に反する設計をしない
