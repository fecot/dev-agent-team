# Workflow: Feature Development

## 1. Workflow Overview

このワークフローは、曖昧なIssueや開発依頼を受け取り、**要件整理 → 既存コード調査 → 影響範囲分析 → 実装計画 → 安全な実装 → テスト設計 → PRレビュー → リリース確認** までを進めるための標準フローです。

`agents/` `commands/` `skills/` `templates/` を、個別ドキュメントではなく「IssueからPRまでの一連の開発プロセス」として連結して使うための司令塔の役割を果たします。

### 設計の前提

- **AIは伴走者、判断するのは人間**
- **小さな差分で進める**（フェーズを跳ばさない）
- **不明点は推測で埋めず、必ず確認事項として上げる**
- **各フェーズには明確な Stop Condition があり、満たせない場合は次に進まない**
- **対象リポジトリの Project Rules を、dev-agent-team の共通ルールより優先する**

### Rule Priority

このワークフローでの判断は以下の優先順位に従う:

1. **ユーザー（人間）の明示指示**
2. **対象リポジトリの Project Rules**
   （`CLAUDE.md` / `README.md` / `docs/` 配下 / `.github/pull_request_template.md` / `package.json` 等）
3. **dev-agent-team の共通 Workflow / Commands / Agents / Skills**
4. **一般的なベストプラクティス**

> dev-agent-team の共通ルールは、対象リポジトリの Project Rules を **上書きしない**。衝突した場合は対象リポジトリのルールを採用し、判断がつかなければ人間に確認する。

### 前提: Project Context Loading

8 Phase に入る前に、**Phase 0** として対象リポジトリの Project Rules・技術スタック・禁止事項を読み込む。Phase 0 を経ていない状態で Phase 1 以降に進んではならない。詳細は下記 Phase 0 を参照。

### Phase 一覧

| # | Phase | 主担当 Agent | 主要 Command / Skill / Template |
|---|---|---|---|
| 0 | Project Context Loading | — | `templates/project-rules-template.md` |
| 1 | Intake | `product-interpreter` | `commands/issue-to-plan.md` |
| 2 | Discovery | `codebase-explorer` | `commands/codebase-explore.md` / `skills/codebase-reading.md` / レガシー時は `skills/legacy-modernization.md` |
| 3 | Impact Analysis | `architecture-reviewer` | `skills/impact-analysis.md` / レガシー時は `skills/legacy-modernization.md` |
| 4 | Implementation Planning | `implementation-driver` | `templates/implementation-plan-template.md` / レガシー時は `skills/legacy-modernization.md` |
| 5 | Safe Implementation | `implementation-driver` | `commands/safe-implement.md` / `skills/safe-refactoring.md` / レガシー時は `skills/legacy-modernization.md` |
| 6 | Test Design | `test-strategist` | `skills/test-design.md` |
| 7 | Review Gate | `review-gatekeeper` | `commands/pr-review.md` / `templates/pr-description-template.md` |
| 8 | Release Check | `release-captain` | — |

---

## 2. Phases

### Phase 0: Project Context Loading

対象リポジトリのルール・技術スタック・禁止事項を読み込み、以降の Phase で従うべき制約を明確化する。**この Phase をスキップして Phase 1 に進んではならない。**

- **使用 Template**: `templates/project-rules-template.md`（対象リポジトリ側で記入する雛形）

#### Input
- 対象リポジトリの作業ディレクトリ
- 対象リポジトリ内に既に `CLAUDE.md` / `docs/` / `.github/` がある場合はそれら

#### Action
- 以下を順に読む:
  - 対象リポジトリの `CLAUDE.md`
  - `README.md`
  - `docs/` 配下の開発ルール
  - `.github/pull_request_template.md`
  - `package.json` / `composer.json` / `pyproject.toml` / `go.mod` などの技術スタック情報
  - テストコマンド / Lint / typecheck コマンド
  - 実際のディレクトリ構成（`src/` 直下を `Glob`）
- 以下のルールを抽出して整理する:
  - 禁止事項
  - DB変更ルール
  - API互換性ルール
  - フロントエンド実装ルール
  - バックエンド実装ルール
  - セキュリティ・個人情報の取り扱い
  - PR ルール
  - リリースルール
- 対象リポジトリに Project Rules ファイルが存在しない場合は、`templates/project-rules-template.md` をコピーして埋めることを **人間に提案** する

#### Output
- 対象リポジトリ側に `.dev-agent-team/project-context.md` を作成
  - 上記の確認内容のスナップショット
  - 「未確定」「未読」項目は明示的にラベルを付ける
  - Project Rules と dev-agent-team 共通ルールの **衝突点** があれば併記する

#### Next Phase に渡すもの
- Project Context のサマリ
- 衝突点があれば、人間が決めた優先方針

#### Stop Condition
- 対象リポジトリのルールの所在が確認できていない
- 技術スタック・テスト方法・Lint/typecheck コマンドが不明
- DB変更ルールが不明なまま、依頼内容に DB 変更が含まれる可能性がある
- 認証・権限・課金・個人情報に関わるルールが不明なまま、依頼内容にそれらが関与する
- Project Rules と dev-agent-team の共通ルールが衝突しており、優先順位の判断材料が揃っていない
- 衝突解消のための **人間の判断が未取得**

---

### Phase 1: Intake

入力されたIssueや開発依頼を受け取り、実装可能な要件に変換する。

- **使用 Command**: `commands/issue-to-plan.md`
- **主担当 Agent**: `agents/product-interpreter.md`
- **使用 Skill**: `skills/requirement-analysis.md`

#### Input
- GitHub Issue / Jira チケット / 口頭メモ / Slackでの依頼

#### Action
- 背景・目的（Why）を明確化する
- 曖昧な表現を具体的な条件に変換する
- スコープの境界（やること・やらないこと）を明示する
- 完了条件（Acceptance Criteria）を定義する
- 不明点を確認事項リストとして出力する

#### Output
- 要件整理ドキュメント（背景・目的 / やること / やらないこと / 完了条件 / 確認事項）

#### Next Phaseに渡すもの
- 整理済みの要件と完了条件
- 確認事項リスト（人間が回答するまで Phase 2 に進まない）

#### Stop Condition
- 要件が曖昧すぎて完了条件が定義できない
- 確認事項に対する人間の回答がない
- 「やらないこと」が決まっていない（スコープ無限大の状態）

---

### Phase 2: Discovery

既存コード・類似機能・関連ファイルを調査し、変更前の地図を作る。

- **使用 Command**: `commands/codebase-explore.md`
- **主担当 Agent**: `agents/codebase-explorer.md`
- **使用 Skill**: `skills/codebase-reading.md` / 対象がレガシー MVC アプリの場合は `skills/legacy-modernization.md` を併用

#### Input
- Phase 1 の要件整理ドキュメント

#### Action
- エントリポイントから関連ファイルを辿る
- データモデル（DBスキーマ、型定義）を把握する
- 類似実装を `grep` / `Glob` で探し、パターンを抽出する
- 命名規則・エラーハンドリング方針・テストの書き方を確認する

#### Output
- コードベース調査レポート（関連ファイル一覧 / 類似実装 / 既存パターン / 命名規則）
- `templates/investigation-report-template.md` を使用

#### Next Phaseに渡すもの
- 調査レポート
- 「変更が触るかもしれない」ファイルの暫定リスト

#### Stop Condition
- 関連ファイルが特定できていない
- 類似実装の有無が確認できていない
- データモデル・型定義の確認が漏れている

---

### Phase 3: Impact Analysis

変更がシステム全体に与える影響を整理する。

- **主担当 Agent**: `agents/architecture-reviewer.md`
- **使用 Skill**: `skills/impact-analysis.md` / レガシー改修なら `skills/legacy-modernization.md`（Controller / Model / View / Service の観点で影響を整理）

#### Input
- Phase 1 の要件整理
- Phase 2 の調査レポート

#### Action
- 以下の観点で影響を洗い出す:
  - **UI**: 画面・コンポーネントの変更
  - **API**: エンドポイント・リクエスト/レスポンス契約の変更
  - **DB**: スキーマ変更・マイグレーションの要否
  - **バッチ**: 定期処理への影響
  - **外部連携**: 他サービス・Webhook への影響
  - **権限**: 認可ルール・ロールへの影響
  - **テスト**: 既存テストへの影響・追加が必要なテスト

#### Output
- 影響範囲マトリクス（観点 × 変更有無 × 深刻度 × 対策）
- リスクリスト

#### Next Phaseに渡すもの
- 影響範囲マトリクス
- 検討すべきリスク

#### Stop Condition
- DB変更があるのにマイグレーション戦略が未検討
- 権限変更があるのに既存ロールへの影響が未確認
- 外部連携への影響が未検証
- 「影響なし」と断言できる根拠がない

---

### Phase 4: Implementation Planning

実装案を複数提示し、採用案を選ぶ。

- **使用 Template**: `templates/implementation-plan-template.md`
- **主担当 Agent**: `agents/implementation-driver.md`
- **使用 Skill**: レガシー改修なら `skills/legacy-modernization.md`（Minimal Change / Local Cleanup / Replacement-Ready Boundary の3案を必ず提示）

#### Input
- Phase 1〜3 の出力すべて

#### Action
- 実装案を **2案以上** 出す
- **必ず最小変更案を含める**
- 各案について以下を明記:
  - 変更ファイル一覧
  - 実装ステップ
  - メリット・デメリット
  - テスト戦略の概略
  - リスクと対策
  - ロールバック手順

#### Output
- 実装計画ドキュメント（`templates/implementation-plan-template.md` 形式）

#### Next Phaseに渡すもの
- 採用された実装計画
- 不採用案とその理由（後で参照できるよう残す）

#### Stop Condition
- 実装案が1案しかない
- 最小変更案が提示されていない
- 採用案の意思決定が人間によって行われていない
- ロールバック手順が定義されていない

---

### Phase 5: Safe Implementation

計画に基づき、小さな差分で実装する。

- **使用 Command**: `commands/safe-implement.md`
- **主担当 Agent**: `agents/implementation-driver.md`
- **使用 Skill**: `skills/safe-refactoring.md` / レガシー改修なら `skills/legacy-modernization.md`（Core Policy・Generic MVC Legacy Guidance に従う）

#### Input
- Phase 4 の採用された実装計画

#### Action
- 計画書のステップ順に実装する
- 1ステップごとにテストを通す
- 計画から外れる変更を発見した場合、いったん停止して人間に確認する
- リファクタリングと機能追加を混ぜない

#### Output
- 実装済みコード
- 実装中に発見した「計画外の事項」一覧

#### Next Phaseに渡すもの
- 動作するコード
- 計画とのズレ・追加発見事項

#### Stop Condition
- 計画にない大きな変更が必要だと判明したのに、計画を更新せず進めようとしている
- テストを通さずにステップを進めている
- リファクタリングと機能追加が同一コミットに混在している
- 差分が大きすぎてレビュー不能

---

### Phase 6: Test Design

正常系・異常系・境界値・回帰観点を整理する。

- **主担当 Agent**: `agents/test-strategist.md`
- **使用 Skill**: `skills/test-design.md`

#### Input
- Phase 1 の完了条件
- Phase 5 の実装済みコード
- Phase 3 の影響範囲

#### Action
- 完了条件を **テスト可能な単位** に分解する
- 以下の観点でテストケースを列挙:
  - **正常系**: ハッピーパス
  - **異常系**: エラー入力・例外パス
  - **境界値**: 空・最大長・0・負値・型違い
  - **回帰観点**: 影響範囲のうち既存挙動が壊れていないか
- 単体・結合・E2E のどのレイヤで検証するかを決める

#### Output
- テストケース一覧（観点 / 入力 / 期待結果 / レイヤ）
- 完了条件 → テストケースのトレーサビリティ

#### Next Phaseに渡すもの
- 通過したテスト一覧
- カバレッジから漏れている領域（ある場合）

#### Stop Condition
- 完了条件と紐づかないテストしかない
- 異常系・境界値の観点が抜けている
- 影響範囲に含まれるのにテストされていない領域がある

---

### Phase 7: Review Gate

PR を出す前のセルフレビューと PR 説明文を作る。

- **使用 Command**: `commands/pr-review.md`
- **主担当 Agent**: `agents/review-gatekeeper.md`
- **使用 Template**: `templates/pr-description-template.md`

#### Input
- Phase 1〜6 の成果物すべて
- 実装済みコード

#### Action
- 差分を読み返し、計画とのズレを確認する
- PR説明を `templates/pr-description-template.md` に沿って生成する
- レビュー観点チェック:
  - DB変更があるならマイグレーション・後方互換が説明されているか
  - 権限変更があるなら影響ロールが明示されているか
  - 破壊的変更があるなら呼び出し元の追従が説明されているか
  - テスト結果が記載されているか
- セキュリティ観点（OWASP Top 10）の自己点検

#### Output
- 完成した PR 説明文
- セルフレビュー結果（懸念点・補足説明）

#### Next Phaseに渡すもの
- レビュー可能な PR

#### Stop Condition
- DB変更や権限変更があるのに、レビュー観点に明記されていない
- テスト観点が PR 説明から欠落している
- 計画と実装のズレが説明されていない
- 「Fix #123」しか書かれていない PR

---

### Phase 8: Release Check

リリース前の注意点・ロールバック・監視観点を整理する。

- **主担当 Agent**: `agents/release-captain.md`

#### Input
- Phase 4 の実装計画（リスク・ロールバック手順）
- Phase 7 で承認された PR

#### Action
- リリース手順を確認する（マイグレーション順序・フィーチャーフラグ・段階的リリース）
- ロールバック手順を再確認する
- 監視観点を整理する（メトリクス・ログ・アラート）
- リリース直後にチェックする項目をリスト化する

#### Output
- リリース手順書 / チェックリスト
- 監視ダッシュボード上で見るべき項目
- ロールバック判断基準

#### Next Phaseに渡すもの
- 人間によるリリース可否判断のための材料

#### Stop Condition
- DB変更があるのにマイグレーション順序が未確認
- ロールバック手順が「実行不可能」な状態（例: 不可逆なマイグレーション）
- 監視観点が定義されていない
- リリース可否を人間が判断していない

---

## 3. Human Decision Points

AIが勝手に進めず、**必ず人間が判断する** ポイント。

| 判断ポイント | 対応 Phase | 補足 |
|---|---|---|
| Project Rules の整備 | Phase 0 | ルールファイルがない場合、テンプレートから新規作成するか |
| ルール衝突の解消 | Phase 0 | Project Rules と dev-agent-team 共通ルールの優先方針 |
| 要件の最終決定 | Phase 1 | 確認事項への回答・スコープ確定 |
| 不明点の解消 | Phase 1〜3 | 推測で埋めない |
| 実装案の採用 | Phase 4 | 最小案 / 標準案のうちどれを採るか |
| DB変更の承認 | Phase 3 / 4 / 8 | スキーマ変更・マイグレーション戦略 |
| 権限変更の承認 | Phase 3 / 4 | 認可ルール変更 |
| 仕様変更の判断 | Phase 5 | 実装中に計画外の事項が見つかった時 |
| マージ可否 | Phase 7 | コードレビュー後 |
| リリース可否 | Phase 8 | 段階的リリース・即時全展開の判断 |
| ロールバック判断 | Phase 8 | リリース後の異常検知時 |

> AIは「判断材料」を出す。「判断」は人間がする。

---

## 4. Usage Example

`examples/sample-issue.md`（ユーザー一覧にメールアドレス検索機能を追加）を題材に、このワークフローをどう流すかの例。

### Phase 1 — Intake

`/issue-to-plan` でイシューを投入し、ProductInterpreter が要件整理を出力する。

確認事項として以下を上げて停止:
- フロントのみでフィルタリング？ それとも API クエリ？
- ユーザー数のパフォーマンス要件は？

→ **人間が回答** したら Phase 2 へ。

### Phase 2 — Discovery

`/codebase-explore` を実行。CodebaseExplorer が以下を発見:
- `pages/users/index.tsx`, `components/UserTable.tsx` が変更対象候補
- `pages/products/index.tsx` に **類似実装あり**（フロントのみで `filter()` する方式）
- 既存規則: 検索の命名は `filter` 系（`filterQuery` を使っている）

### Phase 3 — Impact Analysis

ArchitectureReviewer が観点別に整理:
- UI: ユーザー一覧画面の変更（影響あり）
- API: 影響なし（フロントのみで完結）
- DB: 変更なし
- 権限・外部連携: 影響なし
- テスト: `UserTable` の単体テスト追加が必要

リスク: ユーザー数が多い場合の描画パフォーマンス（中）→ `useMemo` で対応。

### Phase 4 — Implementation Planning

ImplementationDriver が2案提示:
- **案A（最小変更）**: `UserTable` にフィルタ input を追加、`filter()` で絞り込み
- **案B（標準）**: `useUserFilter` フックに切り出して再利用可能にする

→ **人間が案Aを採用**。「ユーザー数が少ない現状ではシンプルさを優先」と理由を残す。

### Phase 5 — Safe Implementation

`/safe-implement` で計画書通りに実装。
- ステップ1: フィルタ用 state を追加してテスト
- ステップ2: input UI を追加してテスト
- ステップ3: `filter()` ロジックを追加してテスト

### Phase 6 — Test Design

TestStrategist が完了条件をテストケースに分解:
- 部分一致で絞り込まれる（正常系）
- 大文字小文字を区別しない（正常系）
- 0件のとき空状態メッセージ（境界値）
- 入力クリアで全件表示に戻る（回帰）

### Phase 7 — Review Gate

`/pr-review` を実行。`pr-description-template.md` で PR 説明文を生成。
- 変更内容、テスト結果、影響範囲、ロールバック手順を明記
- DB変更・権限変更なし（明示）

### Phase 8 — Release Check

ReleaseCaptain が:
- フィーチャーフラグなしで即時リリース可と判断
- 監視観点: ユーザー一覧画面のレンダリング時間メトリクス
- ロールバック: PR Revert で即時復旧可能（DB変更なし）

→ **人間がリリース可否を最終判断** してデプロイ。

---

## 5. このワークフローの使い方

1. **対象リポジトリに `CLAUDE.md` / Project Rules があるか確認** する。なければ `templates/project-rules-template.md` をコピーして埋める
2. `commands/run-feature-workflow.md` を起動する。Phase 0 で Project Context を読み込ませる
3. Phase 1 の確認事項に回答する
4. 各 Phase の Stop Condition を満たさない限り、次に進まない
5. Human Decision Points では必ず人間が判断する
6. 計画外の事項が見つかったら、いったん停止して計画を更新する

> このワークフローは「速さ」より「抜け漏れのなさ」を優先するための型です。慣れれば各 Phase の判断は数分で済みます。

---

## 6. タスク種別サブフロー

`/run-feature-workflow` 起動時に、**人間が** タスク種別を以下から宣言する。種別により、Phase 0 / 1 / 2 / 5 に **追加項目** が発火する。種別を宣言しない場合は「通常」扱い。

| 種別 | 判定基準 | 追加サブフロー |
|---|---|---|
| 通常 | 下記いずれにも該当しない新機能・改修 | なし（§2 の標準 Phase のみ） |
| Migration | 既存コードを別 FW / 別言語に移植する（例: AngularJS → React, Rails → Go） | 6.1 を発火 |
| UI Replica | 既存 UI（別アプリ / Figma / 旧画面）を別技術スタックで再現する | 6.1 を発火（Migration と同じ） |
| Hotfix | 本番不具合の最小修正。Phase 1〜4 を圧縮して Phase 5 へ最短到達 | 6.2 を発火 |

> 種別の **自動判定は行わない**（誤判定で誤サブフローが走るリスクを避けるため）。`/run-feature-workflow` の Inputs で必ず明示する。

### 6.1 Migration / UI Replica サブフロー

「source（既存）= ground truth、target（新）= 再現対象」という構図で、**実値を実測してから実装する** ことを徹底する。前提: **Playwright MCP（または同等のブラウザ自動操作 MCP）が利用可能** であること。利用不可環境では本サブフローは適用外とする。

#### Phase 0 追加項目

- グローバル SCSS / Tailwind / リセット CSS の **所在を把握** し、`project-context.md` に記録
- ブラウザキャッシュ対策標準（hard reload / Playwright route interception）を確認し、`project-context.md` に記録
- SCSS / CSS の **構文制約**（例: `//` コメント不可、ネスト深さ制限）を `project-rules.md` に追記
- webpack / vite / その他バンドラの **rebuild 完了確認方法**（出力 bundle の mtime / dev server の出力ログ）を `project-context.md` に記録

#### Phase 1 追加項目

- **ゴール定義** を要件成果物に明記（完全再現 / 部分改善 / 大幅改修 のいずれか）
- 「**source の現状値 = target の目標値**」が暗黙のデフォルトであることを明文化（特に色 / フォント / px サイズ）
- 受け入れ基準を「source スクショ vs target スクショ」とする旨を完了条件に追加
- 形容詞による曖昧な指示が含まれていれば `agents/product-interpreter.md` の **数値化プロトコル** に従って数値化する

#### Phase 2 追加チェックリスト

`skills/migration-spec-capture.md` を使って source 側を機械計測し、以下を Discovery レポートに含める:

- [ ] source テンプレ HTML を **全文確認**（部分抜粋ではなく）
- [ ] source controller / view-model の state / event を Discovery
- [ ] source 専用 SCSS / CSS から色 / padding / font-size / margin / border を **px / hex 単位で抽出**
- [ ] 上記クラスを **上書きしているグローバル SCSS** の有無を `grep` で確認
- [ ] LocalStorage 全エントリの **実値ダンプ**（型乖離 / 空文字 / null パターンを検出）
- [ ] API レスポンスの **実 shape ダンプ**（TypeScript 型宣言ファイルとのズレを検出）
- [ ] 使用ライブラリの **差分マッピング表**（例: c3 → chart.js の設定対応表）
- [ ] 共通部品の **動的データ更新挙動**（useState 初期値固定 / props 変更時の再レンダリング有無）

#### Phase 4 追加項目

- `agents/implementation-driver.md` の **ゴール定義 / 数値固定方針** セクションを必ず埋め、Phase 5 開始前に CEO/PM 承認を得る

#### Phase 5 追加要件

- `skills/browser-verification.md` の **検証ループ（6 ステップ）** を **1 修正ごとに必ず通す**
- 「実装したけど反映されない」「色が違う」のフィードバックは目視ではなく `browser_evaluate` での実測値で報告する

#### Stop Condition 追加

- source の実値（色 / px / DOM 構造）が未計測のまま Phase 4 に進もうとしている
- ゴール定義（完全 px 一致 / UX 同等 / 大幅改修）が未承認のまま Phase 5 に進もうとしている
- Phase 5 で UI 変更を行ったのに `skills/browser-verification.md` の検証ループを通していない

### 6.2 Hotfix サブフロー

Phase 1〜4 を **圧縮**（要件は既知 / 影響範囲は限定 / 計画案は最小 1 案）して Phase 5 に最短到達する代わりに、Phase 7 / 8 は **通常以上に厳格** にする（ロールバック手順 / 監視観点を必ず明記、レビュー観点を省略しない）。詳細は別途運用知見が溜まり次第追記。
