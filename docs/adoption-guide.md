# Adoption Guide: 既存リポジトリへの導入

このガイドは、`dev-agent-team` を **既存の開発リポジトリ** に導入するための手順書です。dev-agent-team のドキュメントを単体で読むだけでは「自分のリポジトリでどう使い始めるか」が見えづらいので、ここで段取りと注意点を整理します。

---

## 1. dev-agent-team の位置づけ

dev-agent-team は **アプリケーションコードではありません**。Claude Code を使って IssueからPRまでの開発プロセスを進めるための **共通キット**（Agent / Command / Skill / Workflow / Template / Example）です。

- このリポジトリには、対象リポジトリの実コードは入りません
- 対象リポジトリ側に必要なのは「ルール」と「コンテキスト」（後述）
- 共通キットは「型」、対象リポジトリのルールは「中身」。両者を組み合わせて初めてワークフローが回ります

そのため、**対象リポジトリ側にもいくつかのファイルを置く必要があります**。

---

## 2. 対象リポジトリ側に必要なもの

導入後、対象リポジトリには以下が存在する状態にします。

| ファイル / ディレクトリ | 作る人 | 役割 | Git管理方針 |
| --- | --- | --- | --- |
| `CLAUDE.md` | 対象リポジトリ管理者 | Claude Codeに対象プロジェクトの前提・作業ルールを伝える | Git管理推奨 |
| `.dev-agent-team/project-rules.md` | 対象リポジトリ管理者 | 技術スタック、ディレクトリ構成、テスト方法、禁止事項、承認必須領域を定義する | Git管理推奨 |
| `.dev-agent-team/project-context.md` | Claude Code | Phase 0でProject Rulesやリポジトリ情報を読み取って生成する実行時コンテキスト | 運用に応じて判断 |
| `.dev-agent-team/requirements/` | Claude Code | Phase 1の要件整理成果物を保存する | 運用に応じて判断 |
| `.dev-agent-team/reports/` | Claude Code | 調査レポート、影響範囲分析を保存する | 運用に応じて判断 |
| `.dev-agent-team/plans/` | Claude Code | 実装計画、テスト計画を保存する | 運用に応じて判断 |
| `.dev-agent-team/reviews/` | Claude Code | PRレビュー、PR説明文を保存する | 運用に応じて判断 |
| `.dev-agent-team/releases/` | Claude Code | リリース前チェックリストを保存する | 運用に応じて判断 |

`project-rules.md` は、対象リポジトリの開発ルールそのものなので Git 管理を推奨します。一方で、`project-context.md` や各Phaseの成果物は、チームの運用に応じて Git 管理するか、PR作成時の一時成果物として扱うかを決めてください。

`.dev-agent-team/` ディレクトリは、**ワークフロー実行で生成される成果物の置き場** として機能します。`requirements/` 〜 `releases/` までの各サブディレクトリは、ワークフロー実行時に必要に応じて自動的に作られていく想定です（最初から手で作っておく必要はありません）。

---

## 3. 導入手順

新規に dev-agent-team を導入するときの段取りです。

### Step 1. 対象リポジトリに `CLAUDE.md` があるか確認する

すでに `CLAUDE.md` がある場合は、その中で

- 技術スタック
- テスト・Lint・typecheck コマンド
- 触ってはいけない領域
- 人間承認が必要な変更

が記述されているかを確認します。記述があれば Step 2 で重複しないよう調整します。

### Step 2. テンプレートをコピーして `.dev-agent-team/project-rules.md` を作る

`dev-agent-team` 側の [`templates/project-rules-template.md`](../templates/project-rules-template.md) を、対象リポジトリの `.dev-agent-team/project-rules.md` としてコピーします。

```sh
mkdir -p .dev-agent-team
cp <path-to-dev-agent-team>/templates/project-rules-template.md \
   .dev-agent-team/project-rules.md
```

### Step 3. テンプレートを埋める

特に以下の項目を、推測ではなく **実際に動くコマンド・実在するパス** で記入します。

- **Tech Stack** — 言語・フレームワーク・DB・パッケージマネージャ
- **Runtime Commands** — `test` / `typecheck` / `lint` / `dev` / `migrate` の **正確な** コマンド
- **Directory Rules** — 実在するディレクトリ構造
- **Database Rules** — マイグレーションツールと後方互換ルール
- **Do Not** — 触ってはいけないディレクトリ・ファイル
- **Human Approval Required** — DBマイグレーション / 認証認可 / 課金 / 個人情報 / 公開API破壊的変更 のうち、自分のリポジトリで該当するもの

不明な項目は空欄で残さず、「未確定（要確認）」と明記します。空欄は Phase 0 の Stop Condition に該当して、ワークフローが進みません。

### Step 4. Claude Code で `/run-feature-workflow` を起動する

Issue や開発依頼を渡してワークフローを起動します。

```
/run-feature-workflow <イシューURL or イシュー本文>
```

### Step 5. Phase 0: Project Context Loading が実行される

Claude Code は最初に対象リポジトリの

- `CLAUDE.md`
- `.dev-agent-team/project-rules.md`
- `README.md`
- `docs/` 配下
- `.github/pull_request_template.md`
- `package.json` / `composer.json` / `pyproject.toml` / `go.mod` 等

を読み込み、内容を `.dev-agent-team/project-context.md` にスナップショットします。

### Step 6. 生成された `project-context.md` を人間が確認する

Phase 1 に進む前に、`.dev-agent-team/project-context.md` を **必ず人間が目を通します**。

- 技術スタックの認識が正しいか
- テストコマンドが正しく拾われているか
- 禁止事項が漏れていないか
- 「未確定」「未読」ラベルが残っている項目がないか
- Project Rules と dev-agent-team 共通ルールに **衝突点** があれば、どちらを採用するか方針を決める

このタイミングで認識のズレを直しておかないと、Phase 1 以降の判断が狂います。

### Step 7. 問題なければ Phase 1 以降へ進む

Phase 0 を確認後、Phase 1（Intake）へ進めます。以降は通常のワークフロー通り、各 Phase の Stop Condition と Human Decision Point に従って進みます。

---

## 4. 最初に試すおすすめ題材

dev-agent-team を初めて導入するときは、**変更範囲が小さく、判断が単純な題材** から始めるのがおすすめです。ワークフロー全体の手触りを掴みやすく、Project Rules の不足に気付くきっかけにもなります。

- 一覧画面に検索条件を追加する
- 既存画面に表示項目を1つ追加する
- CSV 出力に項目を1つ追加する
- 既存 API レスポンスに項目を1つ追加する（破壊的変更でない範囲）
- 管理画面の文言修正や軽微な UI 改善

これらは

- 影響範囲がフロント中心 or 1レイヤーに収まりやすい
- DB / 権限 / 課金 / 個人情報 / 外部連携への影響が小さい
- ロールバックが容易（PR Revert で完結する）

という共通点があります。Phase 0 → Phase 8 を一通り経験するのに向いています。

---

## 5. 最初に避けるべき題材

逆に、以下のような題材は **dev-agent-team の導入直後には避けてください**。Project Rules に書かれていない領域に踏み込みやすく、Stop Condition で止まり続けるか、逆に過剰な判断を AI に委ねてしまうリスクがあります。

- 認証・権限まわり（ログイン・SSO・ロール変更）
- 課金・決済まわり（プラン変更・Stripe / SaaS 利用料の計算）
- 大規模 DB 変更（テーブル分割・大量データのマイグレーション）
- 個人情報の取り扱い変更（保存場所・暗号化・出力）
- 外部連携の大幅変更（連携先追加・廃止・契約変更を伴うもの）
- 緊急 hotfix（停止判断が多いワークフローは緊急対応に向かない。別途 hotfix workflow を用意）
- 仕様が固まっていない大きな新機能（Phase 1 に入る前に Issue 自体の検討が必要）

これらに取り組むのは、Project Rules が十分整備された **後** にしてください。

---

## 6. Project Rules を書くときのコツ

Project Rules は「Claude Code に正確に伝わる文書」である必要があります。以下を意識してください。

- **曖昧な「いい感じに」を避ける** — 「適切なテストを書いてください」ではなく、「単体テストは vitest で `*.test.ts` に書く。カバレッジ80%以上」のように具体化する
- **実行コマンドは正確に書く** — `npm test` なのか `pnpm test` なのか、引数があるのかを正確に。ワンライナーでコピペで動く形にする
- **触ってはいけないディレクトリを書く** — レガシーで触ると壊れる箇所、自動生成で手で編集禁止な箇所、廃止予定で凍結している箇所
- **承認が必要な領域を書く** — DB変更 / 認証認可 / 課金 / 個人情報 / 公開API の破壊的変更 / インフラ構成の変更 など、「人間の承認なしには進めてはいけない」境界線を明示
- **過去に壊れた領域や注意点を書く** — ポストモーテムから学んだ禁止事項、回避策的に放置している箇所、依存サービスで不安定なもの
- **PR テンプレートやレビュー観点を書く** — `.github/pull_request_template.md` の内容や、CODEOWNERS のルール、レビューで必ず見ている観点

ルールは **長文の散文より、箇条書きと具体例** のほうが Claude Code に伝わります。

---

## 7. 運用ルール

導入後の継続的な使い方について。

- **Project Rules は定期的に更新する** — 技術スタックやコマンドが変わったら、コードと同じタイミングでルールも更新する。古いルールは害でしかない
- **ワークフロー実行後の成果物は PR に添付・参照する** — `.dev-agent-team/plans/implementation-plan-*.md` や `pr-description-*.md` を PR にリンクすると、レビュアーが判断材料を辿れる
- **Stop Condition が出たら無理に進めない** — Stop Condition は「ここで止まれ」というシグナルです。バイパスせず、足りない情報を埋めるか、人間に判断を仰ぐ
- **Human Decision Point は人間が判断する** — 採用案・DB変更承認・リリース可否は AI に委ねない。判断材料は AI が出すが、判断は人間がする
- **失敗事例が出たら Project Rules に反映する** — レビューで指摘されたパターン、本番で起きた問題、見落とした観点は、次回以降の Phase 0 で拾えるように **Project Rules に追記** する。これによって型は時間とともに鍛えられる

---

## 8. まとめ

導入の最短ルート:

1. 対象リポジトリに `.dev-agent-team/project-rules.md` を作る（テンプレートをコピー）
2. 技術スタック・コマンド・禁止事項・承認必須領域を **正確に** 埋める
3. 小さめの題材で `/run-feature-workflow` を試す
4. Phase 0 の出力（`project-context.md`）を人間が確認してから Phase 1 へ進む
5. 失敗・気付きを Project Rules に反映していく

dev-agent-team は **使い始めてからも育てていく** ものです。最初から完璧な Project Rules を書こうとせず、小さく始めて、現場のフィードバックでルールを厚くしていってください。
