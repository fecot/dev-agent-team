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
├── agents/          # 各フェーズを担当するエージェント定義
├── commands/        # Claude Codeで呼び出すスラッシュコマンド
├── skills/          # エージェントが使う汎用スキル
├── templates/       # 成果物のテンプレート
├── workflows/       # 上記をつなげた標準開発フロー
├── examples/        # サンプルイシューと処理例
├── docs/            # 導入ガイド・運用ドキュメント
├── CHANGELOG.md     # リリースごとの変更履歴 (Keep a Changelog 形式)
├── version.txt      # dev-agent-team 本体のバージョン (/adopt-project が読む)
├── install.sh       # 入口コマンド /adopt-project のインストール
└── uninstall.sh     # 入口コマンドのアンインストール
```

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

実際のアプリケーションリポジトリへ導入する手順は、[`docs/adoption-guide.md`](docs/adoption-guide.md) にまとめています。最初に試すおすすめ題材・避けるべき題材・Project Rules の書き方のコツ・運用ルールも載せています。

### Artifacts は一時成果物として扱う

`/run-feature-workflow` で生成される Artifacts（要件整理 / 調査 / 計画 / レビュー等）は、**原則 Git 管理しません**。Git 管理を推奨するのは `.dev-agent-team/project-rules.md` のみです。重要な判断は PR 本文に要約して残し、Artifacts 本体はマージ後に削除または `.dev-agent-team/archive/` へ。詳しい方針・`.gitignore` 例は [`docs/adoption-guide.md` の §9 Artifacts Retention Policy](docs/adoption-guide.md#9-artifacts-retention-policy) を参照してください。

## まず使うなら

個別の Agent / Command / Skill / Template を眺めるだけでは、実際の開発フローには落ちません。最初に `workflows/feature-development.md` を読み、`commands/run-feature-workflow.md` を入口にしてフローを起動するのが最短ルートです。

1. [`workflows/feature-development.md`](workflows/feature-development.md) を読む — IssueからPRまでの全体像をつかむ
2. [`commands/run-feature-workflow.md`](commands/run-feature-workflow.md) を起動する — 8 Phase を順番に進める入口コマンド
3. [`commands/issue-to-plan.md`](commands/issue-to-plan.md) でIssueを実装計画に変換する（Phase 1〜4）
4. [`commands/codebase-explore.md`](commands/codebase-explore.md) で既存コードを調査する（Phase 2）
5. [`commands/safe-implement.md`](commands/safe-implement.md) で小さな差分で実装する（Phase 5）
6. [`commands/pr-review.md`](commands/pr-review.md) でPR前レビューを行う（Phase 7）

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
