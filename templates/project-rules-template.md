# Project Rules: {{プロジェクト名}}

このファイルは、対象開発リポジトリ側に置く **プロジェクト固有ルール** の雛形です。`dev-agent-team` の共通ワークフローを使うとき、Claude Code は **Phase 0: Project Context Loading** でこのファイルを読み込み、以降のフェーズはここに書かれたルールを **共通ワークフローより優先** して進めます。

> **使い方**: このテンプレートを対象リポジトリのルートに `CLAUDE.md` として配置するか、`.dev-agent-team/project-rules.md` として置く。空欄のまま放置せず、不明な項目は「未確定（要確認）」と明記する。空欄は Phase 0 の Stop Condition に該当する。

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

- 必須レイヤー: {{単体 / 結合 / E2E のうちどれが必須か}}
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

- ブランチ命名: {{feature/* / fix/* / refactor/* ...}}
- PR タイトル規約: {{Conventional Commits 形式 等}}
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

---

## 更新ルール

- このファイルは **対象リポジトリの所有物** であり、`dev-agent-team` 側からは変更しない
- ルールが変わったら **このファイルを先に更新** してから実装に入る
- 不明・未確定な項目は空欄で残さず「未確定（要確認）」と明記する
