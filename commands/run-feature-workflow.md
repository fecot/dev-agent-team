# Command: /run-feature-workflow

## Purpose

`workflows/feature-development.md` で定義した **8 Phase の標準開発フロー** を、Issue や開発依頼に対して順番に適用するための **入口コマンド** 。

このコマンドは「実装を進めるためのコマンド」ではなく、**Issue から PR、リリース確認までの開発プロセス全体を、抜け漏れなく安全に進めるためのオーケストレータ** として機能する。

- 個別のコマンド（`/issue-to-plan` `/codebase-explore` `/safe-implement` `/pr-review`）を、ワークフローに沿って **正しい順序で・適切な停止判断とともに** 呼び出す
- 各 Phase の Stop Condition を都度評価し、満たせないときは次に進まない
- Human Decision Point では人間の判断を待ち、勝手に進めない
- 実行中に作成・更新する成果物の置き場を統一し、後続の Phase が同じ前提で動けるようにする

## When to Use

以下のような変更で使う:

- 新機能追加
- 既存機能の仕様変更
- 影響範囲が複数レイヤー（UI / API / DB / バッチ / 権限など）にまたがる変更
- 実装前に要件整理や既存コード調査が必要な変更
- PR 前の品質を高めたい変更（レビューでの手戻りを減らしたい場合）

## When Not to Use

以下のケースでは使わない、または軽量フローに切り替える:

- typo 修正・コメント修正
- 文言だけの軽微な修正（i18n 文字列の一部置換など）
- 1 ファイルだけの明確な変更（影響が局所で、要件が自明）
- 緊急 hotfix で **Phase 1〜4 を完全に省略したい** ケース（本コマンドは Hotfix 種別を宣言すれば圧縮できるが、それでも各 Phase の Output は最低限残す。完全省略したい場合は本コマンドではなく直接実装に進む）

軽微な修正で本コマンドを使うと、フェーズオーバーヘッドのほうが大きくなる。判断に迷うなら、Phase 1 だけ実行して「Phase 2 以降が必要かどうか」自体を成果物にする運用でも良い。

## 使い方

```
/run-feature-workflow <イシューURL or イシュー本文 or 依頼内容>
```

## Inputs

以下を受け取れる。すべて任意だが、不足分は Phase 1 の確認事項として人間に問い直す:

- **タスク種別**（推奨明示）: `通常` / `Migration` / `UI Replica` / `Hotfix` のいずれか。詳細は [`workflows/feature-development.md` § 6 タスク種別サブフロー](../workflows/feature-development.md#6-タスク種別サブフロー) を参照
  - **自動判定はしない**（誤判定で誤サブフローが走るリスクを避けるため、人間が宣言する）
  - 宣言がない場合は `通常` として扱う
  - `Migration` / `UI Replica` 宣言時は Phase 0 / 1 / 2 / 4 / 5 に追加チェックリストが発火（前提: Playwright MCP 利用可能）
  - `Hotfix` 宣言時は Phase 1〜4 を圧縮、Phase 7 / 8 を通常以上に厳格化
- **Issue 本文**: タイトルと本文（GitHub Issue / Jira / Slack 抜粋など）
- **目的**: なぜこの変更が必要か（背景・期待する効果）
- **期待する変更**: ユーザー目線での変化、画面・APIの差分
- **制約**: スケジュール / リリース時期 / 互換性要件 / 性能要件
- **対象ブランチ**: 派生元ブランチ名、PR 先ブランチ
- **関連 URL**: 設計ドキュメント / Figma / 過去の類似 PR / 障害票
- **既知の注意点**: 触ってはいけない領域、過去のトラブル、依存サービスの不安定要素

不足している入力があっても **推測で埋めない**。空のまま Phase 1 に渡し、確認事項として上げる。

> **推奨**: 起動前に [`templates/issue-template.md`](../templates/issue-template.md) の必須セクション（背景・目的 / スコープ / 受け入れ基準）を埋めて投入する。未記入で起動した場合は Phase 1 でテンプレを提示して埋めるよう促す。「依頼者しか知らない情報」と「AI が Discovery で埋める情報」を分けて書く設計なので、全項目を埋める必要はない。

## Rule Priority

このコマンドが実行中に判断する際は、以下の優先順位を **必ず** 守る:

1. **ユーザー（人間）の明示指示**
2. **対象リポジトリの Project Rules**
   （`CLAUDE.md` / `README.md` / `docs/` 配下の開発ルール / `.github/pull_request_template.md` / 既存設定ファイル等）
3. **dev-agent-team の共通 Workflow / Commands / Agents / Skills**
4. **一般的なベストプラクティス**

> dev-agent-team の共通ルールは、対象リポジトリの Project Rules を **上書きしてはいけない**。衝突した場合は対象リポジトリのルールを採用し、それでも判断がつかない場合は人間に確認する。

## Execution Rules

このコマンドの実行中、以下のルールを **必ず** 守る:

- 上記 **Rule Priority** に従って判断する
- **Phase 0（Project Context Loading）を必ず最初に実行** する。Project Rules を読まずに Phase 1 以降には進まない
- `workflows/feature-development.md` を **必ず参照** する（各 Phase の Input / Action / Output / Stop Condition の定義はそちらが正）
- Phase を **飛ばさない**（軽量化したい場合でも明示的にスキップ理由を残す）
- 各 Phase で **Output を明示** する（後続 Phase が読める形で残す）
- **Stop Condition に該当したら次に進まない**（人間に確認 or 前 Phase に戻る）
- **Human Decision Point では人間の判断を待つ**（AI が代理判断しない）
- 実装中に **計画外の変更が必要になったら停止** し、Phase 4 の計画を更新してから再開する
- **既存設計を尊重** する（類似実装が見つかればパターンを踏襲）
- 差分は **小さく保つ**（1 PR に詰め込まない、ステップ単位でコミットを切る）
- 不明点は **推測で埋めず、確認事項** として出す
- リファクタリングと機能追加を **同一コミットに混ぜない**
- **タスク管理（TaskCreate 等）の粒度は Phase 単位まで**。Phase 内の細かい実装ステップは個別タスク化せず、計画書（Phase 4）と実装ログ（Phase 5）で管理する（sub-task の作りすぎを避ける）
- **UI を伴う変更では、Phase 4 で視覚仕様スケッチ（ASCII / mock 等）を作り、人間の合意を得てから Phase 5 に進む**（視覚仕様レビューゲート。合意なしに実装着手しない）
- **ネイティブ実行エンジン（`/goal` / Dynamic Workflows）の併用は任意**。使う場合は人間ゲートを越えさせない:
  - `/goal` は **機械的サブループ限定**（テスト緑化 / lint / typecheck など Phase 5・6 の検証可能な区間のみ）。終了条件に「かつ 未解決の Human Decision Point がない」を必ず含める
  - Dynamic Workflow は **単一フェーズ内の人間ゲートを含まない fan-out 限定**（Phase 2 調査 / Phase 7 レビュー / Migration 計測）。8 Phase 全体を 1 本の無人ワークフローにしない
  - 詳細は [`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md)

### Artifacts Retention Rules

成果物（Artifacts）は **一時的な開発ログ** として扱う。詳細は [`docs/adoption-guide.md` の Artifacts Retention Policy](../docs/adoption-guide.md#9-artifacts-retention-policy) を参照。実行時に守るルール:

- **Artifacts are temporary by default** — 生成した Artifacts は原則 Git 管理しない（`project-rules.md` を除く）
- **Do not commit generated artifacts unless the team explicitly decides to** — チームの明示的な合意がない限り、Artifacts をコミットしない
- **Summarize important decisions into the PR description** — 採用案・不採用案・影響範囲・テスト観点・リリース注意点は、Artifacts そのものではなく **PR 本文に要約** して残す（`templates/pr-description-template.md` を使う）
- **Avoid storing secrets, personal data, customer data, raw logs, or production data in artifacts** — APIキー / 個人情報 / 顧客データ / 本番ログの生データを Artifacts に書かない
- **If artifacts include sensitive data, stop and ask for human confirmation before continuing** — 機密情報が含まれる兆候を検知したら、即座に停止して人間の判断を仰ぐ

## Phase Execution Format

各 Phase の出力は以下の統一フォーマットで残す。後続 Phase が読み取りやすく、欠落も検出しやすくするため。

```
### Phase X: {Phase Name}

- Input: {このPhaseで参照した成果物・前Phaseの出力}
- Actions: {実施したアクション（箇条書き）}
- Findings: {判明したこと・調査で見つけた事実}
- Output: {このPhaseで生成した成果物のパス・名称}
- Risks: {検出したリスク（深刻度付き）}
- Stop Condition Check: {Stop Conditionそれぞれに対する評価。Pass / Fail / N/A}
- Human Decision Required: {このPhaseで人間に判断を求める事項。なければ "なし"}
- Next: {次にどのPhaseへ進むか、または停止する理由}
```

### 各 Phase で参照する Agent / Command / Skill / Template

| # | Phase | Agent | Command / Skill / Template |
|---|---|---|---|
| 0 | Project Context Loading | — | `templates/project-rules-template.md` |
| 1 | Intake | `agents/product-interpreter.md` | `commands/issue-to-plan.md` / `skills/requirement-analysis.md` |
| 2 | Discovery | `agents/codebase-explorer.md` | `commands/codebase-explore.md` / `skills/codebase-reading.md` |
| 3 | Impact Analysis | `agents/architecture-reviewer.md` | `skills/impact-analysis.md` |
| 4 | Implementation Planning | `agents/implementation-driver.md` | `templates/implementation-plan-template.md` |
| 5 | Safe Implementation | `agents/implementation-driver.md` | `commands/safe-implement.md` / `skills/safe-refactoring.md` |
| 6 | Test Design | `agents/test-strategist.md` | `skills/test-design.md` |
| 7 | Review Gate | `agents/review-gatekeeper.md` | `commands/pr-review.md` / `templates/pr-description-template.md` |
| 8 | Release Check | `agents/release-captain.md` | — |

> 注: レガシー改修時は `skills/legacy-modernization.md` を Phase 2〜5 で併用する。タスク種別（Migration / UI Replica / Hotfix）宣言時の追加参照は workflow 側の §2 / §6 が正。

## Phase 0: Project Context Loading

Phase 1 以降に進む前に、対象リポジトリのルール・技術スタック・禁止事項を読み込む。**この Phase をスキップしてはいけない。**

### 確認すること

以下を順に読み、見つかった内容を成果物に転記する:

- 対象リポジトリの `CLAUDE.md`
- `README.md`
- `docs/` 配下の開発ルール（コーディング規約 / ADR / 設計ドキュメント）
- `.github/pull_request_template.md`
- `package.json` / `composer.json` / `pyproject.toml` / `go.mod` 等の依存・スクリプト定義
- テストコマンド（`npm test` / `pytest` / `go test ./...` 等）
- Lint / typecheck コマンド
- ディレクトリ構成（実際の `src/` 直下を `Glob`）
- 禁止事項（Do Not セクション / 過去のポストモーテム）
- DB変更ルール（マイグレーションツール / 後方互換要件）
- API互換性ルール（破壊的変更時の手順 / バージョニング）
- フロントエンド実装ルール（状態管理 / スタイリング / アクセシビリティ）
- バックエンド実装ルール（認証・認可 / バリデーション / ジョブ）
- セキュリティ・個人情報の取り扱い
- PR ルール / Release ルール

対象リポジトリに `CLAUDE.md` / project rules ファイルが存在しない場合は、`templates/project-rules-template.md` をコピーして埋めることを **人間に提案** する。空欄のまま進めない。

### 成果物

- **対象リポジトリ側** に作成する: `.dev-agent-team/project-context.md`
  - 上記項目をそのまま転記したスナップショット
  - 「未確定」「未読」項目は明示的にラベルを付ける
  - 衝突点（Project Rules vs dev-agent-team 共通ルール）があれば併記する

### Stop Condition

以下のいずれかに該当したら Phase 1 に進まない:

- 対象リポジトリのルール（`CLAUDE.md` 等）の所在が確認できていない
- 技術スタック・テスト方法・Lint/typecheck コマンドが不明
- DB変更ルールが不明なまま、依頼内容に DB 変更が含まれる可能性がある
- 認証・権限・課金・個人情報に関わるルールが不明なまま、依頼内容にそれらが関与する
- Project Rules と dev-agent-team の共通ルールが衝突しており、優先順位の判断材料が揃っていない
- 衝突解消のための **人間の判断が未取得**

### Human Decision Required

- Project Rules ファイルが存在しない場合、テンプレートから新規作成するかどうか
- Project Rules と dev-agent-team の共通ルールが衝突した場合の採用方針

## Artifacts

実行中に作成・更新する成果物。`workflows/feature-development.md` の各 Phase Output と1対1で対応する。

> **Artifacts は原則として一時的な成果物** です。Git 管理は `project-rules.md` のみ推奨で、それ以外はチームの運用方針で扱います。詳細は [`docs/adoption-guide.md` の Artifacts Retention Policy](../docs/adoption-guide.md#9-artifacts-retention-policy) を参照。

### ディレクトリレイアウト

2方式をサポートする。新規導入なら **Run 単位レイアウトを推奨**。

#### Run 単位レイアウト（推奨）

Issue / Run 単位で1ディレクトリにまとまるため、後から追跡しやすく、削除・アーカイブ単位も明確になる。

```
.dev-agent-team/
├── project-rules.md
├── runs/
│   └── {{issue-id}}/
│       ├── project-context.md
│       ├── requirements.md
│       ├── investigation.md
│       ├── impact.md
│       ├── implementation-plan.md
│       ├── implementation-log.md
│       ├── test-plan.md
│       ├── pr-review.md
│       ├── pr-description.md
│       └── release-checklist.md
└── archive/
```

#### Phase 単位レイアウト（互換）

| 成果物 | 生成 Phase | パス例 |
|---|---|---|
| Project Context | Phase 0 | `.dev-agent-team/project-context.md` |
| Requirement Summary | Phase 1 | `.dev-agent-team/requirements/{{issue-id}}.md` |
| Investigation Report | Phase 2 | `.dev-agent-team/reports/investigation-{{issue-id}}.md` |
| Impact Analysis | Phase 3 | `.dev-agent-team/reports/impact-{{issue-id}}.md` |
| Implementation Plan | Phase 4 | `.dev-agent-team/plans/implementation-plan-{{issue-id}}.md` |
| Implementation Log | Phase 5 | `.dev-agent-team/logs/implementation-{{issue-id}}.md` |
| Test Plan | Phase 6 | `.dev-agent-team/plans/test-plan-{{issue-id}}.md` |
| PR Review Notes | Phase 7 | `.dev-agent-team/reviews/pr-review-{{issue-id}}.md` |
| PR Description | Phase 7 | `.dev-agent-team/reviews/pr-description-{{issue-id}}.md` |
| Release Checklist | Phase 8 | `.dev-agent-team/releases/release-checklist-{{issue-id}}.md` |

`.dev-agent-team/` ディレクトリは案件ごとの作業ディレクトリ配下に作る想定。`{{issue-id}}` は Issue 番号 / チケット ID / 短いスラッグなど、識別可能なものを使う。どちらのレイアウトを採用するかは Phase 0 で対象リポジトリの既存運用に揃える。

## オプション

- `--start-from <phase>`: 指定 Phase から開始（例: 既に要件整理済みなら `--start-from 2`）
- `--stop-after <phase>`: 指定 Phase で停止（例: `--stop-after 4` で計画レビューまで）
- `--no-artifacts`: 成果物ファイルを書き出さず、ターミナル出力のみ
- `--dry`: 実装は行わず、Phase 1〜4 と Phase 6（テスト計画）のみ実施

## 実行フロー（概要）

1. 入力された Issue / 依頼内容を解釈する（不足は確認事項として上げる）
2. **Phase 0 で対象リポジトリの Project Rules / 技術スタック / 禁止事項を読み込む**
3. Phase 1 から順に、上記 Phase Execution Format に従って実行する
4. 各 Phase 終了時に Stop Condition を評価し、Pass なら次へ、Fail なら停止する
5. Human Decision Required がある Phase では、人間の判断を受けるまで停止する
6. 全 Phase 完了後、生成された成果物のリストと、PR / リリースに必要な次アクションを提示する

## セーフガード

以下のいずれかに該当したら、Phase をまたいでも **停止して確認を求める**:

- 入力に対して Phase 1 の完了条件が定義できない
- DB 変更 / 権限変更 / 外部連携変更が見つかったのに、対応する観点が成果物に欠落している
- 実装案が 1 案しかない、または最小変更案がない
- 計画と実装の差分が説明不能なほど広がっている
- テスト観点が完了条件と紐づいていない
- ロールバック手順が「実行不可能」な状態（不可逆なマイグレーションなど）
- **Artifacts に機密情報（APIキー / 個人情報 / 顧客データ / 本番ログの生データ等）が含まれる兆候を検知した**

## 注意

- このコマンドは **判断材料を出すもの** であり、判断するのは人間。
- 「速く済ませる」より「抜け漏れを出さない」を優先する。慣れると各 Phase の判断は数分で済む。
- 軽微な修正には向かない。`When Not to Use` を確認してから起動する。
