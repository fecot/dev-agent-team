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
- **Migration / UI Replica サブフロー** (PRA-11459 フィードバック由来) — `workflows/feature-development.md` § 6 にタスク種別サブフローを新設。通常 / Migration / UI Replica / Hotfix の 4 種別を定義し、Migration / UI Replica 種別では Phase 0 / 1 / 2 / 4 / 5 に追加チェックリスト（グローバル SCSS 所在 / source 実値計測 / ゴール定義承認 / 検証ループ）が発火する。タスク種別は人間が宣言し、自動判定はしない
- **`agents/product-interpreter.md` の数値化プロトコル** (PRA-11459 フィードバック由来) — UI / 見た目に関する曖昧な指示（「太い」「細い」「濃い」等）を、推測で実装せず計測した上で逆質問するプロトコルを追加。形容詞ホワイトリスト + 逆質問テンプレ + 範囲指示の条件確認ルール
- **`agents/implementation-driver.md` のゴール定義 / 数値固定方針** (PRA-11459 フィードバック由来) — Migration / UI Replica 種別の実装計画に「ゴール定義（完全 px 一致 / UX 同等 / 大幅改修）」と「数値固定方針（色 / フォント / レイアウト ratio）」セクションを必須化。Phase 5 開始前に CEO/PM 承認を得る運用に
- **`skills/migration-spec-capture.md`** 新規追加 (PRA-11459 フィードバック由来) — 移植元（source）アプリの実値（color / px / DOM / LocalStorage 実値 / API 実 shape / 共通部品の動的挙動）を Playwright MCP で機械計測する skill。Phase 2 の Discovery で source を計測し、Phase 4 の数値固定方針と Phase 5 の検証ベースラインとして使う
- **`skills/browser-verification.md`** 新規追加 (PRA-11459 フィードバック由来) — UI 変更時の検証ループ 6 ステップ（修正 → rebuild 確認 → cacheBust reload → 実機計測 → スクショ比較 → 数値+画像で報告）を標準形として定義。目視判定ではなく `getComputedStyle` / `getBoundingClientRect` の計測値を一次ソースにする
- **`commands/safe-implement.md` の検証ループ統合** (PRA-11459 フィードバック由来) — 「検証ループ（UI 変更時）」セクションを追加し、Migration / UI Replica 種別では必須、それ以外の UI 変更タスクでも強く推奨。セーフガードに「目視で完了扱いにしない」「UI 変更で検証ループ未通過のまま完了報告しない」を追加
- **`commands/adopt-project.md` 本実装** — プレースホルダーを差し替え、`docs/adoption-guide.md` Step 2〜5 を対話的に半自動化する入口コマンドの本実装。状態診断（5ステップ）/ 分岐 A〜E（新規導入 / 既存連携 / CLAUDE.md 新規作成 / 冪等性モード / バージョン差分モード）/ アンケート 3 階層設計 / `--dry` オプション / 完了レポート / Stop Conditions
- **`version.txt`** — リポジトリ直下に追加。`/adopt-project` の状態診断 [1] で読み込まれる dev-agent-team 本体のバージョン情報源。初期値: `v0.1.0`
- **`templates/claude-md-snippet.md`** — 対象リポジトリの `CLAUDE.md` に追記する静的スニペット。`<!-- dev-agent-team:start -->` / `<!-- dev-agent-team:end -->` マーカーで区切られ、`/adopt-project` 再実行時にマーカー間を安全に置換できる構造
- **`docs/troubleshooting.md`** 新規追加 (E3) — cmux など一部ターミナルでの `*.md` 表示変換問題の説明と、`xxd` / `od -c` での確認手順
- **アンケート段階1のレガシー判定 1問** (A1) — 段階1の最後に「このプロジェクトはレガシーアプリですか？」を追加し、Yes 時のみ段階3 H Legacy Modernization Rules を質問する流れに整理
- **SemVer 2.0 precedence rule の明文化** (D1) — `dev_agent_team_version` / `dev_agent_team_min_version` の比較ルールを SemVer 2.0 に固定。`v0.1.0 < v0.2.0 < v0.10.0 < v1.0.0` / プレリリース版は正式版より低い扱い / 不正フォーマットは Stop Condition
- **関連ツール候補ホワイトリスト** (F2) — 依存ライブラリから関連ツールを候補提示する際のホワイトリスト（SQLAlchemy → Alembic / Django → 組込 migration / Prisma → Prisma migrate / FastAPI → uvicorn / Next.js → migrate 該当なし）。リスト外は推測せず未確定のまま
- **「既存ファイル状況」セクション** (B1) — 状態診断の後、全分岐で `.git` / `CLAUDE.md` / `README.md` / 主要ファイル / `.gitignore` / `.dev-agent-team/` / `project-rules.md` の存在状態を一覧表示
- **状態診断記号の統一** (C1) — `✓` 良い状態 / `–` 中立な不在 / `✗` エラー / `N/A` 該当しない を仕様書で定義し、`--dry` 出力例にも反映
- **未確定項目の重要度ランク** (D6) — `必須` / `依頼依存` / `推奨` の3ランクを導入。完了レポートで `⚠️` `🔶` `ℹ️` のアイコン付きで警告
- **「3選プロンプト」用語定義セクション** (E1) — 書き込み確認・バージョン差分などで使う標準フォーマットを定義し、各分岐で同じ語彙を使うように整理
- **進捗表示「ファイル X/Y」** (E2) — 複数ファイルを書き込む際の進捗を明示
- **「未確定」と「該当なし」の使い分け定義** (B2) — `「未確定（要確認）」` は後で埋める必要あり（Phase 0 で Stop Condition の対象になりうる）、`「該当なし（理由）」` は構造的に該当しない（Stop Condition 対象外）。判定ルールも仕様書に記載
- **分岐 D で CLAUDE.md マーカーなし時の3選** (D3) — `[1]` 何もしない / `[2]` 分岐 B 相当を追加実行 / `[3]` 中止
- **検出スタックと既存記述の不整合検出時の警告と3選** (D4) — `package.json` 検出値と既存 `CLAUDE.md` の記述が衝突した場合、LLM は判定せず利用者に委譲（`[1]` 検出値採用 / `[2]` CLAUDE.md 採用 / `[3]` 手動入力）
- **仕様書末尾の TODO セクション** — 後回し論点として「各分岐の `--dry` 出力例追加」を記録

### Changed
- **`commands/run-feature-workflow.md` の Inputs に「タスク種別」フィールド追加** (PRA-11459 フィードバック由来) — 通常 / Migration / UI Replica / Hotfix のいずれかを起動時に人間が宣言する仕様。自動判定はしない（誤判定で誤サブフローが走るリスク回避）。When Not to Use の Hotfix 記述を新サブフローと整合させた
- **README.md の Skills 一覧表に 2 行追加** — `migration-spec-capture` と `browser-verification` を一覧に追記
- **`docs/troubleshooting.md` の記述を一般化** — 旧記述は特定ツール名（cmux 等）を原因として名指ししていたが、その後の検証で真因は別の入力経路（チャットアプリのペースト時マークダウン自動変換）と判明。将来のツール側修正にも耐えるよう、特定ツール名を含めない一般化記述に置き換え、コードブロックでの囲みによる回避策も追記
- **アンケート段階1構造刷新** (A1) — 旧 7 問（Tech Stack に言語/DB/インフラ/CI/CD が混在、DB 質問が重複）を破棄し、責務を1つに絞った 8 問 + レガシー判定 1 問に刷新（目的 / 言語 / FW・主要ライブラリ / インフラ・CI/CD・パッケージマネージャ / Runtime Commands / DB / 必須テストレイヤー / PR ルール / Do Not）
- **段階2/3 の境界整理** (A2) — 段階2 推奨を 8 項目（Architecture / Coding / Frontend / Backend / API / Security / Release / Known Risks）、段階3 該当時のみを 1 項目（Legacy Modernization Rules）に再構成。Known Risks は段階3から段階2へ移動
- **Runtime Commands で「該当なし」回答許容** (F1) — 各サブ項目（test / lint / typecheck / dev / migrate）で `[Y/n/該当なし]` 回答を許容
- **3選プロンプトのラベル変更（既存ファイル更新時）** (C2) — 旧「上書き / バックアップ / 中止」から、新「そのまま追記（バックアップなし）/ バックアップを取ってから追記 / 中止」に変更。各オプションのアクションが明示的に
- **新規ファイル作成時は2選** (C3) — 旧 3 選（うちバックアップは新規作成では同等）を 2 選「作成 / 中止」に簡略化。仕様書で「新規作成と既存更新で選択肢が異なる」を明記
- **完了レポートを Next Steps と運用注意事項に分割** (C4) — 行動指示（Next Steps）と運用上の注意（Artifacts 管理 / `.bak.*` クリーンアップ）を分離
- **Test Rules / PR Rules の細目整理** (D5) — `templates/project-rules-template.md` の Test Rules と PR Rules を「主要項目（段階1で確認）」と「詳細項目（段階2で選ばれた場合のみ）」に分割
- **分岐 D マーカー無し時の挙動** (D3) — 旧版では未定義だった `.dev-agent-team/project-rules.md` ありで `CLAUDE.md` マーカーなしのケースを 3 選で扱うように
- **不整合検出時の挙動** (D4) — 旧版では未定義だった検出スタックと既存記述の不整合を、警告 + 3 選で利用者判断に委譲

### Removed
- **分岐 E の強制続行（bypass）オプション** (D2) — 旧 3 選 `[2]` の「強制的に進める（非推奨）」を完全削除。代替として「`min_version` 手動修正（救済策、利用者の手作業）」を提供。`/adopt-project` は `min_version` を書き換えず、利用者が `.dev-agent-team/project-rules.md` を手動で開いて編集する。bypass 関連の記述は仕様書から完全削除

### Fixed
- **`install.sh` / `uninstall.sh` を全コマンド対応に拡張** — v0.1.0 時点では `adopt-project.md` のみグローバル symlink していたため、`/run-feature-workflow` などのコマンドがどこからも呼べない不具合があった（仕様意図と実装のギャップ）。`install.sh` と `uninstall.sh` で `COMMANDS` 配列を導入し、`adopt-project.md` / `run-feature-workflow.md` / `issue-to-plan.md` / `codebase-explore.md` / `safe-implement.md` / `pr-review.md` の 6 コマンドすべてを `~/.claude/commands/` に symlink するように。これにより `install.sh` 1 回で全コマンドが任意プロジェクトでグローバルに使え、`/adopt-project` の責務はプロジェクト固有 artifact（`.dev-agent-team/project-rules.md` 等）の整備に集中する設計が実装と整合
- 実機反映には利用者側で `cd ~/.claude/dev-agent-team && git pull && ./install.sh` の実行が必要

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
