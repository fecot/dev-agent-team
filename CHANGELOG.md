# Changelog

All notable changes to dev-agent-team will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

各エントリは以下の区分で記述します:

- **Added** — 新規機能・新規ファイル
- **Changed** — 既存挙動・既存ドキュメントの変更
- **Deprecated** — 将来削除予定の機能
- **Removed** — 削除した機能
- **Fixed** — バグ修正
- **Security** — セキュリティ関連の修正

## [Unreleased]

### Added
- _次のリリース予定の項目を追記してください_

### Changed
- _次のリリース予定の項目を追記してください_

### Deprecated

### Removed

### Fixed

### Security

---

## [v0.1.0] - 2026-05-04

dev-agent-team キットの最初のタグ付きリリースです。`/adopt-project` を起点とした導入動線と、対象プロジェクト側でのバージョンピン留めの仕組みが揃いました。

### Added

- **`install.sh`** — `~/.claude/dev-agent-team` をクローンしたあと `/adopt-project` を `~/.claude/commands/` にシンボリックリンクで配置するインストールスクリプト。macOS / Linux 対応、`set -euo pipefail`、OS 判定 / pre-flight チェック / 上書き対応、`DEV_AGENT_TEAM_ROOT` / `CLAUDE_COMMANDS_DIR` の env override によるテスト容易性
- **`uninstall.sh`** — シンボリックリンクの安全な削除。実ファイル誤削除を防ぐ保護分岐 / 二重 uninstall の no-op 動作
- **`commands/adopt-project.md`**（プレースホルダー） — `/adopt-project` の入口ファイル。`install.sh` の symlink ターゲットとして機能。本実装は次リリース予定
- **`templates/project-rules-template.md` のバージョンピン留めフィールド** — 冒頭に YAML フロントマター `dev_agent_team_version` / `dev_agent_team_min_version` を追加し、対象プロジェクトの Project Rules がどのバージョンの dev-agent-team で動作することを想定しているかを明示できるように。Phase 0 でのバージョン比較・Stop Condition 発動を見据えた仕組み

[Unreleased]: https://github.com/fecot/dev-agent-team/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/fecot/dev-agent-team/releases/tag/v0.1.0
