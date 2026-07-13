# dev-agent-team

Claude Code 向けの **開発支援キット本体** です。Agent / Command / Skill / Workflow / Template / Example をひとまとまりにし、IssueからPRまでの開発プロセスを型化することを目的にしています。

> このリポジトリでは記事・ストーリー類は管理しません。fecot.net 掲載用のコンテンツは別途そちら側で管理しています。

## 背景

SaaS開発の現場で感じてきた課題があります。

「実装は早いのに、レビューが通らない」「動くには動くが、影響範囲が読めていない」「要件を確認せず手を動かして後から手戻り」——こういったことが、チームの規模や経験に関係なく起きます。

このリポジトリは、そうした問題に対して「Claude Codeを使って開発プロセスを型化できないか」という個人的な試みとして始めました。

AIにただコードを書かせるのではなく、**要件整理・調査・設計・実装・テスト・PRレビューまでの流れを標準化し、誰が担当しても一定水準を踏める状態にすること**を目指しています。

## インストール

dev-agent-team はホーム配下に1回だけクローンし、入口コマンド `/adopt-project` をシンボリックリンクで `~/.claude/commands/` に配置します。これにより、**どのプロジェクトディレクトリからでも** `/adopt-project` を発火できます。

> **対応環境**: macOS / Linux（WSL2 含む）。Windows ネイティブはサポート外です。

```sh
# 1. ホーム配下にクローン
git clone https://github.com/fecot/dev-agent-team.git ~/.claude/dev-agent-team

# 2. インストールスクリプト実行
cd ~/.claude/dev-agent-team
./install.sh
```

これで `~/.claude/commands/adopt-project.md` がシンボリックリンクとして配置され、Claude Code から `/adopt-project` が呼べるようになります。

### 導入後の使い方

```
# 対象プロジェクトディレクトリで Claude Code を開く
/adopt-project
```

`/adopt-project` は対象リポジトリ側に `.dev-agent-team/` を構築し、Project Rules の雛形を配置します。詳しい導入フローは [`docs/adoption-guide.md`](docs/adoption-guide.md) を参照してください。

### 更新

```sh
cd ~/.claude/dev-agent-team && git pull
```

シンボリックリンク経由なので、`git pull` だけで最新版が反映されます。

### アンインストール

```sh
cd ~/.claude/dev-agent-team
./uninstall.sh

# 任意: クローン本体を削除
rm -rf ~/.claude/dev-agent-team
```

## 構成

```
dev-agent-team/
├── agents/             # 各フェーズを担当するエージェント定義
├── commands/           # Claude Codeで呼び出すスラッシュコマンド
├── skills/             # エージェントが使う汎用スキル
├── templates/          # 成果物のテンプレート
├── workflows/          # 上記をつなげた標準開発フロー（markdown 仕様）
├── dynamic-workflows/  # Claude Code ネイティブの Dynamic Workflow スクリプト（JS）
├── examples/           # サンプルイシューと処理例
├── docs/               # 導入ガイド・運用ドキュメント・トラブルシューティング
├── CHANGELOG.md        # リリースごとの変更履歴 (Keep a Changelog 形式)
├── version.txt         # dev-agent-team 本体のバージョン (/adopt-project が読む)
├── install.sh          # 入口コマンド・Dynamic Workflow のインストール
└── uninstall.sh        # 入口コマンド・Dynamic Workflow のアンインストール
```

> `workflows/`（人間が読む **プロセスの型**、markdown）と `dynamic-workflows/`（ランタイムが実行する **Dynamic Workflow スクリプト**、JS）は別物です。混同しないよう名前を分けています。

## ネイティブ機能との関係（なぜ冗長でないか）

Claude Code 本体は `/goal`（自律ループ）や Dynamic Workflows（並列オーケストレーション）といった便利機能を出しています。「それなら dev-agent-team は不要では?」という疑問への答えは **冗長ではない・レイヤーが違う** です。

- **dev-agent-team が出すのは「何を・なぜ」** — プロセスの型（Stop Condition / Human Decision Point / 各種チェックリスト）
- **ネイティブ機能が出すのは「どう動かすか」** — 速く・広く・収束まで回す実行エンジン

dev-agent-team は **自分の判断の型を、より強力なエンジンで実行する** ために両者を取り込みます。ただし **人間ゲートはエンジンに越えさせません**（`/goal` は機械的サブループ限定、Dynamic Workflow は単一フェーズ内の fan-out 限定）。併用ルール・条件テンプレ・ガードレールは [`docs/native-tooling-integration.md`](docs/native-tooling-integration.md) に定義しています。

## 対象リポジトリのルールを優先する

dev-agent-team は **共通の開発支援キット** です。実際に使うときは、対象リポジトリごとに技術スタック・ディレクトリ構成・テスト方法・禁止事項・PR ルール・DB変更ルールが異なります。そのため、このキットの共通ルールだけで進めず、**対象リポジトリの `CLAUDE.md` / `README` / `docs/` 配下のルールを優先** して読み込み、それに従ってワークフローを進めます。

### Rule Priority

判断に迷ったら、以下の優先順位で決定します。

1. **ユーザー（人間）の明示指示**
2. **対象リポジトリの Project Rules**（`CLAUDE.md` / `README.md` / `docs/` / `.github/pull_request_template.md` / `package.json` 等）
3. **dev-agent-team の共通 Workflow / Commands / Agents / Skills**
4. **一般的なベストプラクティス**

> dev-agent-team の共通ルールは、対象リポジトリの Project Rules を **上書きしてはいけません**。衝突した場合は対象リポジトリのルールを採用し、判断がつかなければ人間に確認します。

### Project Rules の整備

対象リポジトリに `CLAUDE.md` 等のルールファイルがない場合は、[`templates/project-rules-template.md`](templates/project-rules-template.md) をコピーして必要な項目を埋めてから利用してください。

ワークフロー実行時は **Phase 0: Project Context Loading** で対象リポジトリのルールを読み込み、`.dev-agent-team/project-context.md` に転記してから Phase 1 以降に進みます。Project Rules が確認できないときは、Stop Condition により Phase 1 には進みません。

### 既存リポジトリへの導入手順

実際のアプリケーションリポジトリへ導入する手順は、[`docs/adoption-guide.md`](docs/adoption-guide.md) にまとめています。最初に試すおすすめ題材・避けるべき題材・Project Rules の書き方のコツ・運用ルールも載せています。導入・運用でつまずいたときは [`docs/troubleshooting.md`](docs/troubleshooting.md) を参照してください。

### Artifacts は一時成果物として扱う

`/run-feature-workflow` で生成される Artifacts（要件整理 / 調査 / 計画 / レビュー等）は、**原則 Git 管理しません**。Git 管理を推奨するのは `.dev-agent-team/project-rules.md` のみです。重要な判断は PR 本文に要約して残し、Artifacts 本体はマージ後に削除または `.dev-agent-team/archive/` へ。詳しい方針・`.gitignore` 例は [`docs/adoption-guide.md` の §9 Artifacts Retention Policy](docs/adoption-guide.md#9-artifacts-retention-policy) を参照してください。

## まず使うなら

最初に [`workflows/feature-development.md`](workflows/feature-development.md) で 8 Phase の全体像を掴むのがおすすめです（Phase 0: Project Context Loading を含めると 9 段階ですが、慣例的に 8 Phase と呼びます）。実際の使い方は **A. オールインワン** と **B. 段階的** の 2 通りあります。

### A. オールインワン（推奨）

`/run-feature-workflow` を起動すると **Phase 0 → Phase 8 が自動進行** します。通常はこれだけで OK。

#### 起動前の準備

1. **依頼テンプレを埋める** — [`templates/issue-template.md`](templates/issue-template.md) の **必須セクション**（背景・目的 / スコープ / 受け入れ基準）を埋めます。UI 変更 / 共通部品挙動 / 既知の罠 が関与する依頼は、該当する「該当時のみ必須」ブロックも埋めます。「コードを読めば分かる情報は省略 OK、依頼者の頭の中にしかない情報に集中」が方針
2. **タスク種別を決める** — `通常` / `Migration` / `UI Replica` / `Hotfix` のいずれかを宣言します。Migration / UI Replica は Phase 0 / 2 / 4 / 5 に追加チェックが発火（[`workflows/feature-development.md` § 6](workflows/feature-development.md) 参照）。`通常` で十分なら省略可

#### 起動

```sh
# 一度だけ（プロジェクトごとのセットアップ）
/adopt-project

# 開発タスクごと（埋めた依頼テンプレを丸ごと貼り付け、必要ならタスク種別も）
/run-feature-workflow <Issue URL or 依頼テンプレ本文>
```

#### 起動後

Phase 0 → Phase 8 が **自動進行** します。各 Phase の **Stop Condition** / **Human Decision Required** で停止し、人間判断を待ちます。Phase 5（Safe Implementation）が UI 変更を含むなら、`skills/browser-verification.md` の検証ループ（rebuild 確認 / cacheBust reload / 実機計測 / スクショ比較）が 1 修正ごとに走ります。

### B. 段階的に叩く場合

各 Phase を個別に進めたいときは以下の順:

| 順 | コマンド | 担当 Phase | 役割 |
|---|---|---|---|
| - | `/adopt-project` | （セットアップ） | プロジェクト固有 artifact を整備（一度だけ） |
| 1 | `/issue-to-plan` | Phase 1〜4 | Issue → 要件整理 → 既存コード調査 → 影響範囲分析 → 実装計画 |
| 2 | `/codebase-explore` | Phase 2 | 既存コードの深掘り調査（単独利用可） |
| 3 | `/safe-implement` | Phase 5 | 計画書ベースで安全に実装 |
| 4 | `/pr-review` | Phase 7 | PR 前セルフレビュー + PR 説明文生成 |

Phase 3 / 6 / 8 は専用コマンドがなく、`/run-feature-workflow` 経由または対応 Agent（`architecture-reviewer` / `test-strategist` / `release-captain`）の直接呼び出しになります。

### 使い分けの目安

- **新機能 / 影響範囲が広い変更** → `/run-feature-workflow`（オールインワン、安全側）
- **既存コードの調査だけしたい** → `/codebase-explore` 単独
- **計画は固まっていて実装だけしたい** → `/safe-implement` 単独
- **PR 作成直前のセルフレビュー** → `/pr-review` 単独

迷ったら **`/run-feature-workflow`** を起点にすれば抜け漏れがなく進みます。

## Examples の読み方

[`examples/`](examples/) には、ワークフローの動作イメージを掴むためのサンプルがあります。

- [`examples/sample-issue.md`](examples/sample-issue.md) — `/run-feature-workflow` に投入する **架空のIssue**
- [`examples/sample-workflow-output.md`](examples/sample-workflow-output.md) — そのIssueに対する **8 Phase の出力サンプル**

読むときは以下を意識してください。

- **これは実装デモではなく、開発プロセスのデモです。** 実在するアプリケーションコードはありません。サンプル中のファイル名は「想定される調査対象」として書かれているだけで、実コードを保証するものではありません
- **小さな機能追加でも、要件整理・既存コード調査・影響範囲分析・テスト観点・PR 説明・リリース確認 までを扱います。** 「メールアドレス検索を追加する」程度の変更でも、全 Phase を通すと何が見えるかを示しています
- **dev-agent-team は「爆速開発ツール」ではありません。** 開発判断（要件確定・実装案採用・リリース可否）の品質を、担当者によらず一定水準に揃えるための「型」です。速さよりも、抜け漏れのない判断材料を順に積み上げることを優先します

サンプルの各 Phase に登場する `Output` `Stop Condition Check` `Human Decision Required` の **書き方の型** を、自身のIssueにそのまま流用できます。

## Skills 一覧

各エージェントが参照する汎用スキルです。Phase 内で必要に応じて呼び出します。

| Skill | 用途 |
|---|---|
| [`skills/requirement-analysis.md`](skills/requirement-analysis.md) | Phase 1: 要件を曖昧さなく整理する |
| [`skills/codebase-reading.md`](skills/codebase-reading.md) | Phase 2: 既存コードを素早く正確に読み解く |
| [`skills/impact-analysis.md`](skills/impact-analysis.md) | Phase 3: UI / API / DB / 権限 / テスト等への影響を整理する |
| [`skills/safe-refactoring.md`](skills/safe-refactoring.md) | Phase 5: 小さな差分で安全にリファクタする |
| [`skills/test-design.md`](skills/test-design.md) | Phase 6: 正常系・異常系・境界値・回帰観点でテスト設計する |
| [`skills/legacy-modernization.md`](skills/legacy-modernization.md) | レガシー MVC を尊重しつつ段階的に境界を作る（Phase 2〜5・7 で活用） |
| [`skills/migration-spec-capture.md`](skills/migration-spec-capture.md) | Phase 2: Migration / UI Replica で source の実値（色 / px / DOM / LocalStorage / API 実 shape）を Playwright MCP で機械計測する |
| [`skills/browser-verification.md`](skills/browser-verification.md) | Phase 5: UI 変更後の検証ループ（rebuild 確認 / cacheBust reload / 実機計測 / スクショ比較）を 1 修正ごとに通す |

## Templates 一覧

成果物テンプレートです。依頼時に埋めるもの / 対象リポジトリに配置するもの / Phase ごとの成果物として埋めるもの があります。

| Template | 用途 |
|---|---|
| [`templates/issue-template.md`](templates/issue-template.md) | Phase 1: 依頼者しか知らない情報を確実に渡すための型（必須 / 該当時のみ必須 / 任意 の 3 階層） |
| [`templates/project-rules-template.md`](templates/project-rules-template.md) | 対象リポジトリ側で記入する Project Rules の雛形（YAML フロントマターでバージョンピン留め） |
| [`templates/claude-md-snippet.md`](templates/claude-md-snippet.md) | 対象リポジトリの `CLAUDE.md` に追記する静的スニペット（マーカー区切りで `/adopt-project` 再実行時に安全に置換可能） |
| [`templates/investigation-report-template.md`](templates/investigation-report-template.md) | Phase 2: 既存コード調査レポートの雛形 |
| [`templates/implementation-plan-template.md`](templates/implementation-plan-template.md) | Phase 4: 実装計画の雛形（最小変更案 / 標準案 / 案 C を含む構造） |
| [`templates/pr-description-template.md`](templates/pr-description-template.md) | Phase 7: PR 説明文の雛形 |

## Dynamic Workflows 一覧

Claude Code ネイティブの Dynamic Workflow（並列オーケストレーション）です。`install.sh` で `~/.claude/workflows/` に配置され、`/<name>` で起動します。**利用には Claude Code v2.1.154 以降 + Dynamic Workflows の有効化が必要**です。人間ゲートを含む処理には使わず、単一フェーズ内の fan-out に限定します（[`docs/native-tooling-integration.md`](docs/native-tooling-integration.md) 参照）。

| Workflow | 用途 |
|---|---|
| [`dynamic-workflows/dev-agent-discovery.js`](dynamic-workflows/dev-agent-discovery.js) | Phase 2: Discovery の広域並列調査。候補ファイルを並列読解し investigation-report 構造のレポートを返す（`/dev-agent-discovery`） |

## 基本方針

- いきなり実装しない
- まず要件を整理する
- 既存コードを読む
- 類似実装を探す
- 影響範囲を明確にする
- 実装案を複数出す（最小変更案を必ず含める）
- テスト観点を明示する
- PR説明まで作る
- 不明点は推測で埋めず、確認事項として出す
- 既存設計を尊重する
- 小さな差分で進める

## ライセンス

MIT
