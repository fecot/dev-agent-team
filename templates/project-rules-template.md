---
dev_agent_team_version: v0.1.0
dev_agent_team_min_version: v0.1.0
---

# Project Rules: {{プロジェクト名}}

このファイルは、対象開発リポジトリ側に置く **プロジェクト固有ルール** の雛形です。`dev-agent-team` の共通ワークフローを使うとき、Claude Code は **Phase 0: Project Context Loading** でこのファイルを読み込み、以降のフェーズはここに書かれたルールを **共通ワークフローより優先** して進めます。

> **使い方**: このテンプレートを対象リポジトリのルートに `CLAUDE.md` として配置するか、`.dev-agent-team/project-rules.md` として置く。空欄のまま放置せず、不明な項目は「未確定（要確認）」と明記する。空欄は Phase 0 の Stop Condition に該当する。

## dev-agent-team Version Pinning

このファイル冒頭の YAML フロントマターは、対象プロジェクトの `project-rules.md` が **どのバージョンの dev-agent-team で動作することを想定しているか** を明示するためのものです。

- **`dev_agent_team_version`**: このプロジェクトをセットアップした時点での dev-agent-team のバージョン。`/adopt-project` 実行時に書き込まれる想定
- **`dev_agent_team_min_version`**: このプロジェクトが正しく動作するために最低限必要な dev-agent-team のバージョン。新しい Phase / Skill / Stop Condition に依存する内容を Project Rules に追記したら、このフィールドを上げる

Phase 0（Project Context Loading）はこの値を読み、ホーム配下の `~/.claude/dev-agent-team` の現在バージョンと比較します。**現在バージョンが `dev_agent_team_min_version` を下回る場合は Stop Condition** を発動し、`cd ~/.claude/dev-agent-team && git pull` での更新を人間に促します（このバージョンチェック挙動の実装は `commands/adopt-project.md` および Phase 0 側の責務）。

ホーム配下の dev-agent-team は **常に最新を追従** することを前提とし、プロジェクト側でバージョンを **ピン留めする** ことで「最新版で挙動が変わって急に Stop Condition が増えた」状態を避けつつ、過去バージョン依存の挙動も明示的に追跡できるようにしています。

---

## Project Overview

- **目的**: {{このプロジェクトが解決したい課題・提供価値}}
- **主な利用者**: {{ユーザー像 / 内部ツールなら利用部門}}
- **本番URL / 環境**: {{prod / staging / dev のURL等}}
- **リリース頻度**: {{毎日 / 週次 / スプリント単位 等}}

## Tech Stack

- **言語**: {{TypeScript / Go / Python ...}}
- **フレームワーク**: {{Next.js / NestJS / Rails / Django ...}}
- **DB**: {{PostgreSQL / MySQL / DynamoDB ...}}
- **インフラ**: {{AWS / GCP / Vercel ...}}
- **CI/CD**: {{GitHub Actions / CircleCI ...}}
- **パッケージマネージャ**: {{pnpm / npm / yarn / composer ...}}

### Runtime Commands

```
# テスト
{{npm test / pnpm test / go test ./... など}}

# 型チェック
{{npm run typecheck / tsc --noEmit / mypy など}}

# Lint / Format
{{npm run lint / npm run format / ruff など}}

# ローカル起動
{{npm run dev / docker compose up など}}

# マイグレーション
{{npm run migrate / rails db:migrate など}}
```

## Architecture Rules

- {{採用しているアーキテクチャ（レイヤード / DDD / Clean / フィーチャースライス 等）}}
- {{ドメイン境界・モジュール分割の原則}}
- {{依存方向の制約（例: domain は infrastructure に依存しない）}}

## Legacy Modernization Rules

> このセクションは、対象アプリケーションが **レガシー MVC アプリケーション** や独自フレームワーク採用アプリケーションの場合のみ記入してください。新規アプリ・既に Clean Architecture 等で設計されたアプリでは「該当なし」と明記して構いません。
>
> 詳細な行動原則は `~/.claude/dev-agent-team/skills/legacy-modernization.md` を参照。

- **対象アプリの構造**: {{MVC / 独自MVC / レイヤー混在 / Active Record パターン 等}}
- **採用フレームワーク特性**: {{古いMVCFW / 独自FW / ORM / テンプレートエンジン 等}}
- **リプレイス計画**: {{未定 / 検討中 / 段階的移行中 / 期日あり}}
- **触ってはいけない領域**: {{凍結された旧モジュール / 自動生成コード / 廃止予定で残置されている領域}}
- **業務ロジックの推奨配置**: {{Service 配下 / 専用クラス / Condition / DTO など}}
- **新設計を持ち込む際の制約**:
  - {{新しい設計用語の使用可否（例: DDD用語は避ける / ValueObject は OK 等）}}
  - {{ディレクトリ追加の可否}}
  - {{命名規則の制約}}
- **Characterization Test の方針**: {{書ける範囲 / 書けない場合の代替（手動確認・スクリーンショット比較）}}
- **Replacement Notes の保存先**: {{PR本文 / `.dev-agent-team/runs/{{issue-id}}/replacement-notes.md` / 社内Wiki}}
- **3案提示ルール**: レガシー改修時は Minimal Change / Local Cleanup / Replacement-Ready Boundary の **3案を必ず提示** する（{{案C採用には人間承認が必要かどうか}}）

## Directory Rules

```
{{ディレクトリ構成例}}
src/
├── {{features|domains|...}}/
├── {{components|presentation|...}}/
├── {{api|adapters|...}}/
└── ...
```

- 新規ファイルを置く場所のルール
- ファイル命名規則（kebab-case / snake_case / PascalCase）
- 1ファイルあたりの責務（例: 1コンポーネント1ファイル）

## Coding Rules

- 型安全方針（strict mode / any禁止 など）
- エラーハンドリング方針（例外 vs Result型 / 境界部のみで処理）
- ロギング方針（採用ロガー / 出力レベル / PII の扱い）
- Null / Optional の扱い
- 非同期処理の方針（Promise / async-await / Channel）
- import 順序・絶対パス vs 相対パス
- コメントの方針（書く時 / 書かない時）

## Database Rules

- マイグレーションツール: {{Prisma / Alembic / Flyway ...}}
- マイグレーションの方針:
  - {{後方互換を保つ / NOT NULL 追加時はデフォルト値必須 等}}
  - {{大規模テーブル変更の手順}}
- インデックス追加・変更の承認フロー
- データ削除・カラム削除の禁止 / 段階的廃止の手順
- トランザクション境界の方針
- N+1 検出の方針

## API Rules

- 公開API (REST / GraphQL / gRPC):
  - 互換性ルール（破壊的変更時の手順 / バージョニング）
  - エンドポイント命名規則
  - エラーレスポンスのフォーマット
- 内部API:
  - 認証方式
  - レートリミット
- 外部サービス連携:
  - 連携先と用途
  - 障害時のフォールバック方針

## Frontend Rules

- 状態管理: {{Redux / Zustand / TanStack Query / Context ...}}
- ルーティング規則
- スタイリング: {{Tailwind / CSS Modules / styled-components ...}}
- アクセシビリティ要件（WCAG 等）
- i18n 方針
- フォームバリデーション方針
- パフォーマンス予算（LCP / CLS 等）

## Backend Rules

- 認証・認可の実装ポリシー
- バリデーションの責任レイヤー
- バックグラウンドジョブ・キューの使い方
- 冪等性の担保が必要なエンドポイント
- 監査ログの記録方針

## Test Rules

主要項目（段階1で確認）:

- **必須レイヤー**: {{単体 / 結合 / E2E のうちどれが必須か}}

詳細項目（段階2で Test Rules を選んだ場合のみ追加質問）:

- カバレッジ目標
- モック方針: {{DBはモックしない / 外部APIは必ずモック等}}
- テストファイルの配置（`__tests__/` / `*.test.ts` 等）
- スナップショットテストの可否
- フィクスチャの管理方法
- フレーキーテスト発見時の対応

## Security / Privacy Rules

- 個人情報（PII）の定義と扱い
- 秘密情報の保存場所（KMS / SecretManager / .env 禁止）
- 認証トークン・セッションの取り扱い
- 監査が必要な操作（誰が・いつ・何をしたかの記録）
- OWASP Top 10 のうち特に注意する項目
- 依存ライブラリの脆弱性チェック頻度

## PR Rules

主要項目（段階1で確認）:

- **ブランチ命名**: {{feature/* / fix/* / refactor/* ...}}
- **PR タイトル規約**: {{Conventional Commits 形式 等}}

詳細項目（段階2で PR Rules を選んだ場合のみ追加質問）:

- PR 説明テンプレート: {{`.github/pull_request_template.md` の所在}}
- レビュアー指名ルール（CODEOWNERS の有無）
- 必須レビュー数
- マージ方式: {{squash / rebase / merge commit}}
- マージ前必須チェック: {{CI緑 / approval / linear history ...}}

## Release Rules

- リリース方式: {{即時 / 週次 / カナリア / フィーチャーフラグ ...}}
- リリース時間帯（業務時間外 / メンテナンス窓）
- 本番デプロイ承認者
- 段階的リリースが必須となる変更の種類
- ロールバック手順と判断基準
- ポストモーテムの運用

## Execution Engine 方針

> Claude Code ネイティブの `/goal` / Dynamic Workflows をこのプロジェクトで使うかの方針。詳細は dev-agent-team の `~/.claude/dev-agent-team/docs/native-tooling-integration.md` を参照。未使用なら「該当なし」と明記してよい。

- **`/goal` の使用**: {{許可 / 禁止 / 機械的サブループ限定（テスト緑化・lint・typecheck のみ） / 該当なし}}
- **Dynamic Workflows の使用**: {{許可 / 禁止 / 単一フェーズ内 fan-out 限定 / 該当なし}}（前提: Claude Code v2.1.154+ / 有効化済み）
- **人間ゲートの扱い**: 承認・意思決定（受入基準 / 採用案 / マージ / リリース / DB・権限変更）はエンジンに委譲せず必ず人間が判断する
- **HDP の permissions 固定**: {{deny / ask ルールとして settings.json に固定した境界の一覧（例: main への push 禁止） / 該当なし}}（会話で述べた境界は compaction で失われうるため、恒久保証は deny ルール。deny / ask は project 側 `.claude/settings.json` でも workspace trust なしで適用される）

## Do Not

- {{触ってはいけないファイル / ディレクトリ}}
- {{書いてはいけないコード / 使ってはいけないAPI}}
- {{過去の障害から学んだ禁止事項}}
- {{回避策的に放置されている箇所（リファクタ禁止）}}
- {{勝手にやってはいけない作業（DBマイグレーション・本番デプロイ・公開API変更 等）}}

## Human Approval Required

以下の変更は **必ず人間の承認** を得てから進める:

- DB スキーマ変更・マイグレーション実行
- 認証・認可ロジックの変更
- 課金・決済に関わるロジックの変更
- 個人情報の取り扱い方針の変更
- 公開API の破壊的変更
- 外部サービスとの新規連携・連携停止
- セキュリティ設定（CORS / CSP / TLS）の変更
- インフラ構成の変更
- 本番データの直接操作

## Known Risks

- {{既知の不具合 / 暫定対応中の箇所}}
- {{パフォーマンス上の弱点}}
- {{将来の負債として認識している箇所}}
- {{依存サービスで不安定なもの}}
- {{過去の障害の再発リスクが残っている領域}}
- {{過去の案件で踏んだ「次回また踏みそうな罠」（環境固有のビルド/キャッシュ挙動・見落としやすい前提・繰り返しハマった設定 等）}}

> このセクションは **振り返りで育てる**。Phase 8（Release Check）の振り返りで抽出した「次回防ぐべき項目」を、人間の承認のうえ 1 行ずつここに追記していく（追記提案は AI が出すが、書き込みの可否は人間が判断する）。同じ罠を毎回踏まないための蓄積場所。案件固有で再発しない事象は書かない（ノイズになる）。

---

## 更新ルール

- このファイルは **対象リポジトリの所有物** であり、`dev-agent-team` 側からは変更しない
- ルールが変わったら **このファイルを先に更新** してから実装に入る
- 不明・未確定な項目は空欄で残さず「未確定（要確認）」と明記する
