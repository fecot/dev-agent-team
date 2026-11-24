# Workflow: Feature Development

## 1. Workflow Overview

このワークフローは、曖昧なIssueや開発依頼を受け取り、**要件整理 → 既存コード調査 → 影響範囲分析 → 実装計画 → 安全な実装 → テスト設計 → PRレビュー → リリース確認** までを進めるための標準フローです。

`agents/` `commands/` `skills/` `templates/` を、個別ドキュメントではなく「IssueからPRまでの一連の開発プロセス」として連結して使うための司令塔の役割を果たします。

### 設計の前提

- **意図と、取り返しのつかない判断は人間。それ以外は AI が根拠つきで決めて進める**（判定の軸は可逆性。§3 の 3 区分）
- **小さな差分で進める**（フェーズを跳ばさない）
- **不明点は推測で埋めず、必ず確認事項として上げる**
- **各フェーズには明確な Stop Condition があり、満たせない場合は次に進まない**
- **対象リポジトリの Project Rules を、dev-agent-team の共通ルールより優先する**
- **タスク管理の粒度は Phase 単位まで**。タスク追跡ツール（TaskCreate 等）で管理するのは各 Phase であり、Phase 内の細かい実装ステップまで個別タスク化しない。Phase 内のステップは計画書（Phase 4）と実装ログ（Phase 5）で管理する（sub-task を作りすぎると追跡コストが本質作業を上回る）

### Rule Priority

このワークフローでの判断は以下の優先順位に従う:

1. **ユーザー（人間）の明示指示**
2. **対象リポジトリの Project Rules**
   （`CLAUDE.md` / `README.md` / `docs/` 配下 / `.github/pull_request_template.md` / `package.json` 等）
3. **dev-agent-team の共通 Workflow / Commands / Agents / Skills**
4. **一般的なベストプラクティス**

> dev-agent-team の共通ルールは、対象リポジトリの Project Rules を **上書きしない**。衝突した場合は対象リポジトリのルールを採用し、判断がつかなければ人間に確認する。

### ネイティブ実行エンジンの併用（任意）

このワークフローは「判断の型」であり、実行エンジンとは別レイヤーです。Claude Code 本体の `/goal`（自律ループ）や Dynamic Workflows（並列オーケストレーション）を **任意で併用** できます。ただし **人間ゲート（Human Decision Points / 承認系 Stop Condition）はエンジンに越えさせない** ことが大原則です。

- `/goal` は **機械的に収束させたい区間のみ**（テスト緑化 / lint / typecheck など、Phase 5・6 の検証可能な区間）。
- Dynamic Workflows は **単一フェーズ内の、人間ゲートを含まない大規模 fan-out のみ**（Phase 2 の広域調査 / Phase 7 の多視点レビュー / Migration 計測）。

> 詳細・条件テンプレ・ガードレールは [`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) を参照。

### Stop Condition のタグ付け規約

各 Phase の Stop Condition は、`/goal` で自動判定してよいか否かを区別する:

- **〔機械検証可〕** — Claude の出力（コマンド結果）で yes/no 判定できる。`/goal` で回してよい（例: テストが緑、typecheck 0、lint 解消）。
- **〔人間判断〕** — 承認・意思決定を要する。`/goal` でも Dynamic Workflow でも自動化しない。必ず人間が判断する。

タグのないものは **AI が自分で判定し、判定の根拠を Output に残す**（§3.2 の「中間成果物の受け入れ」）。`/goal` の終了条件や hooks には載せない（判定が文章の読み取りに依存するため）。判定に迷うものは〔人間判断〕として扱う。

この二分は、公式の Fable 5 プロンプティングガイドが推奨するチェックポイントパターン——「**破壊的・不可逆な操作 / 真のスコープ変更 / 本人にしか出せない入力** のときだけユーザーで停止する」——と一致する。〔人間判断〕はこの停止すべき 3 類型を Phase ごとに具体化したもの（[`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) §8.1 参照）。

〔機械検証可〕タグの Stop Condition は hooks で機械的に強制できる（[`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) §2.7 参照）。**〔人間判断〕は hooks 化しない**（自動判定 = 人間ゲートの代行になるため）。ただし〔人間判断〕の **手前の状態検出**（「push 先が Approve 済み PR のブランチか」など）は機械で判定でき、hook で止めて人間に返してよい。hook が代行してはいけないのは、止めた後の「進めてよいか」の判断だけ。

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
- Project Rules に **Environment Notes**（環境の恒久的な制約: ホスト制約 / 権限的に触れないパス / 外部連携の認証状態）があれば読み、以降の Phase の前提にする
- Project Rules に **Decision Log**（過去に人間が下した判断と理由）があれば読み、今回の依頼に関係する記録を拾う
  - 関係する記録があれば **その前提から始める**（前回と同じ問いを人間に出し直さない）
  - 記録どうしが衝突する / 記録の前提が今回の依頼と噛み合わない場合は、AI が採用を決めず **人間に判断を戻す**
- 対象リポジトリに Project Rules ファイルが存在しない場合は、`templates/project-rules-template.md` をコピーして埋めることを **人間に提案** する
- Project Rules 冒頭の `dev_agent_team_min_version` を、`~/.claude/dev-agent-team/version.txt` の現在バージョンと **SemVer で比較** する（比較規則は `commands/adopt-project.md` の「バージョン比較ルール」節）。現在バージョンが下回るなら `cd ~/.claude/dev-agent-team && git pull` を人間に促す。フィールドが無い（Project Rules が `CLAUDE.md` だけ等）場合は比較をスキップし、`project-context.md` に「未ピン留め」と記録する。形式が SemVer でなければ停止する

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
- Decision Log の記録どうしが衝突している、または記録の前提が今回の依頼と噛み合わないまま、どちらを採るかの人間の判断が未取得
- 衝突解消のための **人間の判断が未取得**
- 〔機械検証可〕`~/.claude/dev-agent-team` の現在バージョンが Project Rules の `dev_agent_team_min_version` を下回っている、または `dev_agent_team_min_version` が SemVer 形式でない

---

### Phase 1: Intake

入力されたIssueや開発依頼を受け取り、実装可能な要件に変換する。

- **使用 Command**: `commands/issue-to-plan.md`
- **主担当 Agent**: `agents/product-interpreter.md`
- **使用 Skill**: `skills/requirement-analysis.md`

#### Input
- GitHub Issue / Jira チケット / 口頭メモ / Slackでの依頼

#### Action
- 依頼内容が [`templates/issue-template.md`](../templates/issue-template.md) の **必須セクション**（背景・目的 / スコープ / 受け入れ基準）を満たしているかチェックする
- UI 変更 / 共通部品挙動 / データ罠が関与する依頼で、該当時のみ必須セクションが埋まっていなければ、テンプレを提示して埋めるよう促す
- 背景・目的（Why）を明確化する
- 曖昧な表現を具体的な条件に変換する
- スコープの境界（やること・やらないこと）を明示する
- 完了条件（Acceptance Criteria）を定義する
- 不明点を確認事項リストとして出力する
- 成果物の **届け先**（外部サービスへの書き込み・連携先・デプロイ先）がある依頼では、**そこへの到達可否・権限の確認を確認事項に含める**（環境・権限のブロックは作業の最終盤に発覚しがちなので、着手前に前倒しする。Environment Notes に既に記録があればそれを使う）

#### Output
- 要件整理ドキュメント（背景・目的 / やること / やらないこと / 完了条件 / 確認事項）

#### Next Phaseに渡すもの
- 整理済みの要件と完了条件
- 確認事項リスト（人間が回答するまで Phase 2 に進まない）

#### Stop Condition
- 要件が曖昧すぎて完了条件が定義できない
- 確認事項に対する人間の回答がない
- **整理した受け入れ基準（完了条件）について、人間の明示的な承認が取れていない**（「確認事項がない」＝「承認済み」ではない。受入基準を提示したうえで、人間が「これで進めてよい」と明示するまで Phase 2 に進まない）
- 「やらないこと」が決まっていない（スコープ無限大の状態）
- `templates/issue-template.md` の必須セクションが空欄のまま、推測で埋めて Phase 2 に進もうとしている

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
- コメント・docblock・README は **手がかりであって根拠ではない**。仕組みは実コード・依存定義・設定で確かめる（`skills/codebase-reading.md`）
- （任意）多ファイル・多サブシステムにまたがる広域調査は Dynamic Workflow で並列化できる（同梱 `/dev-agent-discovery`）。内部に人間ゲートは無い。出力は reader（subagent）由来の **untrusted データ** なので、計画の根拠にする主張は、メインセッションが出典のファイルを自分で開いて確かめてから使う（確かめていないものは〔未検証〕のまま渡し、Phase 4 の採用根拠にしない）。詳細は [`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md)

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

実装案を複数出し、採用案を選ぶ。案の違いが内部実装に閉じるなら AI が選び、理由を残す（§3.2）。

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
- **変更が UI（画面・コンポーネント・レイアウト・見た目）を伴う場合は、視覚仕様スケッチを作る**:
  - ASCII ワイヤーフレーム / mock / 既存画面の注釈付きスクショ等、技術手段は問わない（実装前に「何をどう見せるか」を視覚的に合意できる粒度であればよい）
  - 主要要素の配置・状態（通常 / hover / 空 / エラー / ローディング）・レスポンシブ時の振る舞いを表現する
  - スケッチは **実装の前に** 作り、完成後に PR でスケッチ・スクショ・計測値を並べて示す（事後確認 §3.3）。「何を見せたいか」自体が曖昧なら、意図の確定（§3.1）として先に人間に聞く
- 採用案を選び、**採用理由と退けた案** を計画書に残す。案の違いがユーザーに見える挙動・スコープ・不可逆性に及ぶ場合は、AI が選ばず人間に戻す

#### Output
- 実装計画ドキュメント（`templates/implementation-plan-template.md` 形式）
- UI を伴う場合: 視覚仕様スケッチ（実装前に作ったもの）

#### Next Phaseに渡すもの
- 採用された実装計画
- 不採用案とその理由（後で参照できるよう残す）
- UI を伴う場合: 視覚仕様スケッチ

#### Stop Condition
- 実装案が1案しかない
- 最小変更案が提示されていない
- 採用理由と退けた案が記録されていない
- 〔人間判断〕案の違いがユーザーに見える挙動・スコープ・不可逆性に及ぶのに、AI が採用案を決めようとしている
- ロールバック手順が定義されていない
- **UI を伴う変更なのに、視覚仕様スケッチを作らないまま Phase 5 に進もうとしている**（スケッチがないと、完成後の突き合わせ（§3.3）ができない）

---

### Phase 5: Safe Implementation

計画に基づき、小さな差分で実装する。

- **使用 Command**: `commands/safe-implement.md`
- **主担当 Agent**: `agents/implementation-driver.md`
- **使用 Skill**: `skills/safe-refactoring.md` / レガシー改修なら `skills/legacy-modernization.md`（Core Policy・Generic MVC Legacy Guidance に従う）

#### Input
- Phase 4 の採用された実装計画

#### Action
- 最初のコミットの前に **作業ブランチにいることを確認する**（`git branch --show-current`。コマンド連鎖の途中失敗で main / master 上のまま作業していた事故がある）
- ブランチ切り替え・マージ・push の前に **`git fetch` と `git status` でローカル状態を確かめる**。上流より遅れている / 未コミットの変更がある / リモートが未設定なら先に報告し、解消方法は人間が選ぶ（古いローカルブランチのまま進めて push が拒否され、多環境デプロイの途中でやり直しになった事故がある）。新しいブランチは最新の `origin/<base>` から切る
- 計画書のステップ順に実装する
- 1ステップごとにテストを通す
- ステージは **明示的に扱ったファイルだけ**（`git add -A` / `--renormalize` 等の一括ステージで意図しないファイルが混入する。使う場合はステージ後の差分を人間に見せる）
- 計画から外れる変更を発見したら、スコープ（ユーザーに見える挙動・不可逆性）が変わるかで分ける。変わるなら人間に戻し、変わらないなら実装ログに記録して計画を更新し、進める
- リファクタリングと機能追加を混ぜない
- 共有環境でコマンドを実行したら、**その環境の結果（CI の実行結果・ログ・ステータス）を確認してから** 次の環境へ進む。確認していない段階を「完了」と報告しない
- （任意）テスト緑化・lint 解消・typecheck 0 など **機械的に収束させたい区間** は `/goal` で自動ループできる。終了条件に「かつ 未解決の Human Decision Point がない」と回数上限を必ず含め、スコープの変わる計画外変更は人間に返す（[`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md)）
- （任意）長時間の実装では、**一定間隔で新しいコンテキストの検証サブエージェントに、実装計画・受け入れ基準との突き合わせ** をさせる（独立した検証は自己批評より優れる — 同 §8.3 interval 検証）

#### Output
- 実装済みコード
- 実装中に発見した「計画外の事項」一覧

#### Next Phaseに渡すもの
- 動作するコード
- 計画とのズレ・追加発見事項

#### Stop Condition
- 〔人間判断〕スコープの変わる計画外変更（ユーザーに見える挙動・スコープ・不可逆性が変わるもの）が必要だと判明したのに、人間に戻さず進めようとしている。スコープの変わらない計画外変更は、実装ログに記録し計画を更新して進めてよい（§3.2）
- 〔人間判断〕**取り返しのつかないリモート操作** を承認なしに行おうとしている — main / master・保護ブランチ・他人のブランチ・**Approve 済み PR** への push、force push、リモートブランチの削除、Secret 登録、タグ作成。**作業ブランチへの push と Draft PR の作成・更新は AI に委任**（§3.2。push のたびの承認は不要）
- 〔機械検証可〕テストを通さずにステップを進めている
- 〔機械検証可〕main / master 上でコミットしようとしている（作業ブランチの確認なしに最初のコミットを切らない）
- 〔機械検証可〕上流より遅れている / 未コミットの変更がある / リモートが未設定のまま、ブランチ切り替え・マージ・push に進もうとしている（`git fetch` 後の状態で判定できる。操作ごとにどの条件を見るかは [`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) §2.7）。**判定は機械、解消は人間** — `/goal` の終了条件で pull / stash / reset による自動解消をさせない
- 〔人間判断〕**共有環境**（dev / stg / 本番など、他の人やジョブと共有している環境）に対してコマンドを実行しようとしているのに、(1) 実行するコマンド、(2) 対象環境とパラメータ（対象月・対象 ID 等。取り違えやすいので **復唱する**）、(3) 何が書き込まれ・投入されるか、を提示して承認を得ていない。(3) は **コードを読んで確認** する。`--dry-run` のようなフラグ名や名前から安全だと推測しない（「dry-run なのにジョブが本当に投入された」事故がある。**フラグ名は名前であって保証ではない**）
- 〔機械検証可〕リファクタリングと機能追加が同一コミットに混在している
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
- **バグ修正では、修正前に失敗し修正後に通る再現テストを残す**。「修正後に通る」だけでは、そのテストがバグを捉えている証明にならない（修正前のコミットで実際に落ちることを確認する。同種のバグが QA 指摘として反復するのを止める）
- （任意）列挙したテストの **緑化** は `/goal` で自動ループできる（条件は「最新メッセージにテスト全出力と 0 failures を表示」など、出力で実証可能な形にする）

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
- バグ修正なのに、修正前に失敗することを確認した再現テストがない
- 〔機械検証可〕列挙したテストが実行されていない、または緑化していない（最新のテスト全出力で 0 failures が確認できない）

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
- テスト・ビルド・lint の失敗は、**この PR が持ち込んだものか、ベースブランチの時点で既にあったものか** を分けて報告する（ベースブランチでも同じコマンドを実行して比べる。既存の失敗を PR の責任にしない／PR の失敗を既存のせいにしない）
- PR説明を `templates/pr-description-template.md` に沿って生成する
- PR は **Draft で作る**。CI が緑になり、独立検証（新しいコンテキストのレビュアー。`/code-review` や Dynamic Workflow の敵対的 verify を含む）を通ったら、AI が Ready for review にする（§3.2）。通らなければ Draft のまま、何が通っていないかを報告する
- レビュー観点チェック:
  - DB変更があるならマイグレーション・後方互換が説明されているか
  - **バグ修正なら、そのバグが既に残したデータを確かめたか**（孤立レコード・不整合な値など）。差分に DB 変更がなくてもデータ補正が要ることがある。確認用の **読み取り専用クエリ** を用意し、共有環境での実行は人間に委ねる（Phase 5 の共有環境ゲート）
  - 「マイグレーション不要」「既存データに影響なし」は、**既存データの値・件数で確かめてから** 書かれているか
  - 権限変更があるなら影響ロールが明示されているか
  - 破壊的変更があるなら呼び出し元の追従が説明されているか
  - テスト結果が記載されているか
- セキュリティ観点（OWASP Top 10）の自己点検
- （任意）大きな差分のレビューは Dynamic Workflow で多視点・敵対的 verify（観点別 reviewer → 各指摘を独立 skeptic が反証）に並列化できる。マージ可否の判断は人間が行う（[`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md)）

> **レビューの段階構造**（ネイティブ機能との分担）: 一次スキャン = ネイティブ `/review`（シングルパス）、指摘の網羅生成 = ネイティブ `/code-review <level>`（多エージェント、v2.1.202+）、判定観点と Go / No Go / 条件付き Go の整理 = キットの ReviewGatekeeper・`/pr-review`、**マージ可否の判断 = 人間**。標準的なコードレビューはネイティブ `/code-review`、キット固有観点の敵対的 sweep やコード以外の成果物レビューは Dynamic Workflow（docs §3）。なお `/code-review` は内部で「広く生成 → 独立検証で反証 → フィルタ」の段階構造を取る（docs §3.2 の敵対的 verify と同型）。

#### Output
- 完成した PR 説明文
- セルフレビュー結果（懸念点・補足説明）

#### Next Phaseに渡すもの
- レビュー可能な PR

> **PR を出したら、その後を追いかける責任は人間にある。** マージ待ちの状態を AI に定期監視させない（「未マージなら再チェック」型のループは、人間が動くまで状態が変わらないため終了条件が存在しない）。進捗を知る手段は AI の再実行ではなく、GitHub の通知・レビュー依頼を使う。詳細は [`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) §7.1。

#### Stop Condition
- DB変更や権限変更があるのに、レビュー観点に明記されていない
- バグ修正なのに、そのバグが既に残したデータ（補正の要否）を確認していない。または、確認用の読み取り専用クエリを用意して人間に委ねたことが PR に書かれていない
- テスト観点が PR 説明から欠落している
- 計画と実装のズレが説明されていない
- 「Fix #123」しか書かれていない PR
- 〔人間判断〕**Approve 済みの PR** に追加コミットを push しようとしている（レビューを通った内容を黙って変えることになる。承認済み PR への無断 push で PR 閉鎖・ブランチ削除の後始末になった事故がある）。Draft や未承認の PR への push は §3.2 で委任済み
- 〔機械検証可〕CI が緑でない（CI が存在しない・checks が 0 件を含む）、または独立検証（新しいコンテキストのレビュアー）を通っていないのに、Draft を Ready for review にしようとしている
- 〔人間判断〕レビューコメント・チケット・チャットなど、**他人が読む場所への投稿** を承認なしに行おうとしている

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
- **振り返り（Retrospective）**: この案件で踏んだ「次回また踏みそうな罠」を 1 行ずつ抽出する
  - 例: 環境固有のビルド/キャッシュ挙動、繰り返しハマった設定、見落としやすい依存・前提
  - 抽出した項目を、対象リポジトリの Project Rules（`project-rules.md` / `CLAUDE.md`）の **Known Risks に追記することを人間に提案** する（提案であり、追記の可否は人間が判断する。Project Rules は対象リポジトリの所有物のため勝手に書き換えない）
  - 案件固有で再発しない事象は蓄積しない（ノイズになる）。「次回の別案件でも防ぎたい」ものだけを残す
- **判断の記録（Decision Log）**: この案件の Human Decision Point で人間が下した判断、および **人間が覆した AI の委任判断**（§3.2）のうち、**次も同じ問いが来るもの** を「判断 / 理由 / 再利用条件」の 3 点で抽出する
  - 例: 採用した実装案とその決め手、共通部品を使うか画面固有に置くかの線引き、性能と可読性のどちらを優先したか
  - **理由を必ず添える**。判断だけを残すと、前提が変わったときに見直せず、ただの縛りになる
  - 再利用条件（この案件のみ / 同じスタックなら / プロジェクトを問わず）を書き、**「プロジェクトを問わず」のものは案件横断の原則の候補** として人間に示す
  - 抽出した項目を、Project Rules の **Decision Log に追記することを人間に提案** する（Known Risks と同じ扱い。提案であり、追記の可否は人間が判断する）
  - 一度きりの判断（この案件でしか出てこない選択）は蓄積しない（ノイズになる）

#### Output
- リリース手順書 / チェックリスト
- 監視ダッシュボード上で見るべき項目
- ロールバック判断基準
- 振り返りで抽出した「次回防ぐべき項目」（Known Risks 追記の提案リスト）
- 振り返りで抽出した「判断 / 理由 / 再利用条件」（Decision Log 追記の提案リスト）

#### Next Phaseに渡すもの
- 人間によるリリース可否判断のための材料
- Known Risks への追記提案（人間が承認すれば Project Rules に反映）
- Decision Log への追記提案（同上。次の案件の Phase 0 で読まれ、同じ問いの再説明を減らす）

#### Stop Condition
- DB変更があるのにマイグレーション順序が未確認
- ロールバック手順が「実行不可能」な状態（例: 不可逆なマイグレーション）
- 監視観点が定義されていない
- リリース可否を人間が判断していない

---

## 3. Human Decision Points と委任の区分

判定の軸は 1 つ — **取り返しがつくか、外に出るか**。取り返しがつかないもの・外に出るものは人間が事前に承認し、取り返しがつくものは AI が根拠と証拠を残して進める。

> 人間は **意図** を決め、**取り返しのつかない一歩** を承認する。それ以外の判断は AI が根拠つきで下し、人間はいつでも覆せる。

### 3.1 事前承認（Human Decision Point — AI は止まって待つ）

本キットで「Human Decision Point（HDP）」と書くときは、この表を指す。

| 判断ポイント | 対応 Phase | 補足 |
|---|---|---|
| Project Rules の整備 | Phase 0 | ルールファイルがない場合、テンプレートから新規作成するか |
| ルール衝突の解消 | Phase 0 | Project Rules と dev-agent-team 共通ルールの優先方針 |
| 意図の確定（要件・スコープ・受け入れ基準） | Phase 1 | Grill のように AI が問い詰めて固めてよいが、**最後の「これで進める」は人間が言う**（Grill の終了を承認とみなさない） |
| 不明点の解消 | Phase 1〜3 | 推測で埋めない |
| 単位分割の設計・無主物リストの担当割当 | §6.1（最初の 1 単位の着手前） | Migration / 大規模改修を複数単位に分割する場合。共有データの取得方針を含む（「決めない」も選べるが、再判断ポイントを記録する） |
| DB スキーマ変更・権限変更の方針 | Phase 3 / 4 / 8 | スキーマ変更・マイグレーション戦略・認可ルール変更 |
| スコープの変わる変更 | Phase 4 / 5 | 案の違いや計画外の変更が、ユーザーに見える挙動・スコープ・不可逆性に及ぶとき |
| 共有環境での実行 | Phase 5〜8 | dev / stg / 本番など共有環境へのコマンド実行。コマンド・対象環境・パラメータ・書き込まれるものを提示し、承認を得てから実行 |
| 取り返しのつかないリモート操作 | Phase 5〜8 | main / master・保護ブランチ・他人のブランチ・Approve 済み PR への push、force push、リモートブランチ削除、Secret 登録、タグ作成 |
| 外部への投稿 | Phase 7 | PR レビューコメント・チケット・チャットなど、他人が読む場所への投稿。自分の PR の本文更新は委任（§3.2）に含むが、レビュースレッドへの返信は他人が読むので事前承認 |
| マージ可否 | Phase 7 | コードレビュー後 |
| リリース可否 | Phase 8 | 段階的リリース・即時全展開の判断 |
| ロールバック判断 | Phase 8 | リリース後の異常検知時 |

### 3.2 AI に委任（AI が決めて進め、根拠と証拠を残す）

| 判断 | 対応 Phase | 残すもの |
|---|---|---|
| 実装案の採用 | Phase 4 | 採用理由と退けた案（計画書と PR 本文）。案の違いがスコープに及ぶなら §3.1 に戻す |
| 中間成果物の受け入れ（調査・影響分析・計画・テスト設計） | Phase 2〜6 | 各 Phase の Output。Stop Condition を満たしたら、人間を待たずに次の Phase へ進む |
| スコープの変わらない計画外変更 | Phase 5 | 実装ログへの記録と計画の更新 |
| 作業ブランチへの push・Draft PR の作成 / 更新 | Phase 5〜7 | push のたびの承認は不要。PR 本文に何を変えたかを書く。**前提（満たさなければ §3.1 として扱う）**: リモートで main / 保護ブランチへの直接 push が拒否される（branch protection 等）/ 作業ブランチへの push で共有環境へのデプロイやジョブ投入が起動しない（CI 定義を読んで確認）/ Draft PR が使える |
| Draft → Ready for review | Phase 7 | CI が緑、かつ独立検証（新しいコンテキストのレビュアー）を通過していること。**CI が存在しない・checks が 0 件なら緑とみなさず、Ready にしない**（Draft のまま報告し、Ready は人間が決める）。CI の完了待ちは同じセッション内で時間上限つき（例: `gh pr checks --watch` に上限を付ける）とし、超えたら Draft のまま状態を報告して終了する。予約や再アームで待たない（docs §7.1）。Ready にするとレビュー依頼の通知が飛ぶことを PR 本文で前提にしておく |

**委任が成り立つ条件**（4 つすべて）: (1) 取り返しがつく、(2) 機械検証か独立検証で確かめられる（中間成果物は、各 Phase の Stop Condition を AI が判定し、その根拠を Output に残すことで代える）、(3) 証拠つきで報告する、(4) ループには回数上限と終了条件がある。どれかを欠くなら §3.1 として扱う。人間はいつでも委任された判断を覆せる（覆した判断は Decision Log の候補）。

### 3.3 事後確認（AI が進め、人間は後からまとめて見る）

| 判断 | 対応 Phase | 見せ方 |
|---|---|---|
| 視覚仕様 | Phase 4 → 7 | AI がスケッチを作って実装し、完成後にスケッチ・スクショ・計測値を並べて PR で示す。「何を見せたいか」が曖昧なら §3.1（意図の確定）として先に聞く |
| Known Risks 追記 | Phase 8 | 振り返りで抽出した「次回防ぐべき項目」を、追記案として完了報告にまとめる |
| Decision Log 追記 | Phase 8 | 下した判断・理由・再利用条件を追記案としてまとめる。案件横断の原則へ引き上げるかを含む |

> 事後確認の項目も、**Project Rules への書き込みは人間の承認後**（Project Rules は対象リポジトリの所有物）。止まらずにまとめて出す、という意味であって、AI が書き込んでよいという意味ではない。

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

→ 案B は再利用のための汎用化でスコープが広がるため、採用は人間（§3.1「スコープの変わる変更」）。**人間が案Aを採用** し、「ユーザー数が少ない現状ではシンプルさを優先」と理由を残す。案の違いが内部実装だけ（同じ挙動をどう書くか）なら、AI が採用して理由を残し、そのまま Phase 5 へ進む。

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
6. 計画外の事項が見つかったら計画を更新する。スコープが変わるものは、更新した計画を人間に見せてから進める

> このワークフローは「速さ」より「抜け漏れのなさ」を優先するための型です。慣れれば各 Phase の判断は数分で済みます。

---

## 6. タスク種別サブフロー

`/run-feature-workflow` 起動時に、**人間が** タスク種別を以下から宣言する。種別により、Phase 0 / 1 / 2 / 4 / 5 に **追加項目** が発火する。種別を宣言しない場合は「通常」扱い。

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
- SCSS / CSS の **構文制約**（例: `//` コメント不可、ネスト深さ制限）を `project-context.md` に記録し、恒久ルールとして `project-rules.md` へ追記することを **人間に提案** する（Project Rules は対象リポジトリの所有物のため、AI は直接書き換えない）
- webpack / vite / その他バンドラの **rebuild 完了確認方法**（出力 bundle の mtime / dev server の出力ログ）を `project-context.md` に記録

#### Phase 1 追加項目

- **ゴール定義** を要件成果物に明記（完全再現 / 部分改善 / 大幅改修 のいずれか）
- 「**source の現状値 = target の目標値**」が暗黙のデフォルトであることを明文化（特に色 / フォント / px サイズ）
- 受け入れ基準を「source スクショ vs target スクショ」とする旨を完了条件に追加
- 形容詞による曖昧な指示が含まれていれば `agents/product-interpreter.md` の **数値化プロトコル** に従って数値化する

#### Phase 2 追加チェックリスト

`skills/migration-spec-capture.md` を使って source 側を機械計測し、以下を Discovery レポートに含める:

- [ ] source 画面の **全画面スクリーンショット + 可視要素インベントリ** を取得（コードを読むだけでは気付けない「画面に存在するが要件・コードから拾えていない要素」を、実機の見た目から洗い出す。例: 一覧の補助グラフ、状態バッジ、フッタ等を丸ごと見落とすことを防ぐ）
- [ ] source テンプレ HTML を **全文確認**（部分抜粋ではなく）
- [ ] source の **ロジック（controller / view-model の state / event）と CSS（専用スタイルシートの所在パス特定）を両方** Discovery（ロジックだけ追って CSS を後回しにしない。見た目仕様は専用スタイルシートに宿る）
- [ ] source 専用 SCSS / CSS から色 / padding / font-size / margin / border を **px / hex 単位で抽出**
- [ ] 上記クラスを **上書きしているグローバル SCSS** の有無を `grep` で確認
- [ ] LocalStorage 全エントリの **実値ダンプ**（型乖離 / 空文字 / null パターンを検出）
- [ ] API レスポンスの **実 shape ダンプ**（TypeScript 型宣言ファイルとのズレを検出）
- [ ] 使用ライブラリの **差分マッピング表**（例: c3 → chart.js の設定対応表）
- [ ] 共通部品の **動的データ更新挙動**（useState 初期値固定 / props 変更時の再レンダリング有無）
- [ ] **エンドポイント + パラメータ → 利用単位のマトリクス** を作成（共有判定は表示・見た目ではなく **エンドポイント + パラメータ** で行う。作成手順の注意は `skills/impact-analysis.md` の「データ取得の共有関係」）
- [ ] 移行元の「**理由があってそう書かれている仕組み**」の棚卸し（例: リクエスト URL 長・ペイロードサイズの制約回避、サーバ側への状態退避、キャッシュ / 重複排除層）。どの単位にも属さないものは下記「単位分割の設計」の無主物リストに登録する。**理由が不明な実装を「不要」と判断して落とさない**

#### 単位分割の設計 — 無主物リスト（複数単位に分割する場合）

対象を複数の単位（画面 / コンポーネント / 機能）に分割して 1 単位ずつ移行する場合、**最初の 1 単位に着手する前に** 本項を実施する。単位分割自体は正しい（並行作業できる・レビュー単位が小さい・リリース可能な状態を保てる）。ただし **作業を単位分割すると、その単位に属さない関心事に担当者がいなくなる**。単位ごとの品質が高くても、分割の境界に落ちた領域に不具合が集中する。

- **無主物リストを作る** — 分割の設計と同時に「どの単位にも属さない関心事」を列挙し、それぞれに担当（どの単位が持つか / 独立タスクにするか）を割り当てる。**列挙されなかった領域は「誰も見ていない」とみなす**
- **移行元の仕組みを載せる** — Phase 2 追加チェックリストで棚卸しした「理由があってそう書かれている仕組み」は、単位ごとの移行では誰にも移行されない。無主物リストに載せて担当を決める
- **データ取得層の方針を決める** — 複数単位がそれぞれデータを取る構成では、共有データの重複取得は **発生することが確定している**。何もしない / 重複排除層を作る / クエリキャッシュライブラリを使う、のいずれかを着手前に決める。判断が難しければ「決めない」でもよいが、**判断すべき箇所として無主物リストに明示的に記録** し、**再判断ポイント = 2 つ目の単位が同じ API（同一エンドポイント + パラメータ）を叩いたとき** と明記する

典型的な無主物のチェックリスト:

- [ ] データ取得層（キャッシュ / 重複排除 / 同時実行の扱い）
- [ ] 全単位に共通する UI 部品（ヘッダ・メニュー・空状態・ローディング）
- [ ] 出力・エクスポート（印刷 / PDF / 画像 / CSV。**画面表示とは別のコードパスを通る**）
- [ ] 状態の永続化（localStorage / Cookie / サーバ側セッションのキー名と形式）
- [ ] グローバルな条件変更に対する全単位の追従
- [ ] リクエスト URL 長・ペイロードサイズの制約回避
- [ ] エラー処理・リトライ・認証切れの扱い
- [ ] 計測・ログ・アナリティクス

> Migration に限らず、大規模改修を複数単位に分割して進める場合も本項を適用する。

#### Phase 4 追加項目

- `agents/implementation-driver.md` の **ゴール定義 / 数値固定方針** セクションを必ず埋め、Phase 5 開始前に 承認者（Project Rules で定義。ゴール定義は意図の確定 = §3.1）の承認を得る

#### Phase 5 追加要件

- `skills/browser-verification.md` の **検証ループ（6 ステップ）** を **1 修正ごとに必ず通す**
- 「実装したけど反映されない」「色が違う」のフィードバックは目視ではなく `browser_evaluate` での実測値で報告する
- 共有データを扱う単位の実装後は、**リクエスト本数を実測** で確認する（source で 1 本だった取得が target で N 本に増えていないか。**コードの共有と実行の共有は別物** — 「共有フックを作った」は「リクエストが 1 本になった」を意味しない）

#### Stop Condition 追加

- source の実値（色 / px / DOM 構造）が未計測のまま Phase 4 に進もうとしている
- ゴール定義（完全 px 一致 / UX 同等 / 大幅改修）が未承認のまま Phase 5 に進もうとしている
- Phase 5 で UI 変更を行ったのに `skills/browser-verification.md` の検証ループを通していない
- 複数単位に分割する移行なのに、**無主物リスト**（どの単位にも属さない関心事の列挙と担当割当）を作らないまま最初の単位の実装に着手しようとしている
- 共有データの取得方針が未決定のまま、**2 つ目の単位が同じ API（同一エンドポイント + パラメータ）を叩こうとしている**（「決めない」を選んだ場合の再判断ポイント）

### 6.2 Hotfix サブフロー

Phase 1〜4 を **圧縮**（要件は既知 / 影響範囲は限定 / 計画案は最小 1 案）して Phase 5 に最短到達する代わりに、Phase 7 / 8 は **通常以上に厳格** にする。

#### Stop Condition の上書き・追加

- Phase 4 の「実装案が 1 案しかない」は、Hotfix では **「最小案 1 案 + 退けた代替案とその理由を 1 行」** に置き換える（案を並べる時間より、なぜ最小案で足りるかの説明を優先する）
- 〔人間判断〕Phase 7: ロールバック手順と、リリース直後に見る監視項目が PR に書かれていない
- 〔人間判断〕Phase 8: 恒久対応（根本原因の修正・再発防止）を別 Issue として起票するか、不要と判断した理由を残していない
- Phase 7 のレビュー観点（DB 変更・権限・テスト結果）は **省略しない**。圧縮してよいのは Phase 1〜4 だけ
