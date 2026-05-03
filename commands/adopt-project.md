# Command: /adopt-project

> ⚠️ **このコマンドは現在プレースホルダーです。**
> `install.sh` の pre-flight チェック（このファイルの存在確認）を満たすために配置されています。
> 本実装は次のタスクで作成されます。

## 目的（予定）

`/adopt-project` は **対象リポジトリに dev-agent-team を導入する入口コマンド** です。`install.sh` で `~/.claude/commands/adopt-project.md` にシンボリックリンクが作られ、どのプロジェクトディレクトリからでもこのコマンドを発火できます。

## 想定される動作（次タスクで実装）

1. 対象リポジトリの状態を検出する
   - 既に `.dev-agent-team/` が存在するか
   - 既に `CLAUDE.md` が存在するか
   - 既存 `project-rules.md` のバージョン
2. 必要に応じて以下を構築する
   - `.dev-agent-team/` ディレクトリ
   - `templates/project-rules-template.md` を `.dev-agent-team/project-rules.md` にコピー
   - `dev_agent_team_version` のバージョンピン留め書き込み
3. 既存セットアップ検出時はアンケート形式で更新方針を確認
4. `CLAUDE.md` に dev-agent-team 連携の追記提案

## 関連ドキュメント

- [`docs/adoption-guide.md`](../docs/adoption-guide.md) — 既存リポジトリへの導入手順
- [`templates/project-rules-template.md`](../templates/project-rules-template.md) — Project Rules 雛形
- [`workflows/feature-development.md`](../workflows/feature-development.md) — Phase 0: Project Context Loading

## 進捗

- [x] プレースホルダー配置（`install.sh` テスト用）
- [ ] 本実装
