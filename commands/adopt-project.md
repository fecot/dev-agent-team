# Command: /adopt-project

## Purpose

対象リポジトリに **dev-agent-team を導入する** 入口コマンド。`docs/adoption-guide.md` の Step 2〜5 を **対話的に半自動化** します。

このコマンドは [`docs/adoption-guide.md`](../docs/adoption-guide.md) と [`workflows/feature-development.md`](../workflows/feature-development.md) の手順を **実行可能な対話フローに翻訳** したものです。新規導入だけでなく、再実行（冪等性モード）にも対応します。

## Execution Rules（必ず守る）

- **LLM はルール内容を推測で埋めない**（dev-agent-team の根幹思想）
  - 自動検出してよい例: `package.json` の `dependencies` から「Next.js 14, Tailwind CSS 3」を抽出
  - 推測してはいけない例: 「DDD を採用しているはず」「カバレッジ80%が一般的」「個人情報は当然マスクするはず」
  - 自動検出した値も **「これで合っていますか？」確認プロンプト** を必ず挟む
- **静的テンプレートと動的アンケートを明確に分離**
  - 静的: `templates/claude-md-snippet.md` の内容は変数展開せず **そのまま** コピー
  - 動的: アンケート回答は **そのまま転記**（LLM が言い換え・整形しない）
- **すべての書き込みには利用者の確認を取る**
  - diff 提示 → 上書き / バックアップ（`.bak.YYYYMMDD-HHMMSS`）/ 中止 の **3選**
  - 一度の確認で複数ファイル同意取得は不可。ファイルごとに個別確認
- **Stop Condition に該当したら停止**
- **Rule Priority** を遵守: ユーザー指示 > 対象リポ Project Rules > dev-agent-team 共通 > 一般ベストプラクティス
- **対象リポジトリの所有物を尊重**: 既存 `CLAUDE.md` / `.gitignore` / `README.md` の内容を勝手に変更しない（追記・マーカー区間置換のみ）

## When to Use

- 対象リポジトリで **初めて dev-agent-team を使う** とき
- すでに導入済みだが、`project-rules.md` の **項目を更新したい** とき（冪等実行）
- dev-agent-team を **アップデートして** Project Rules を最新化したいとき
- 既存 `.dev-agent-team/` ディレクトリが **中途半端な状態** で、状況確認したいとき

## When Not to Use

- 個別の開発タスクを進めたいとき → `/run-feature-workflow` を使う
- `~/.claude/dev-agent-team/` 自体の変更（dev-agent-team 共通キット側の編集）

## 使い方

```
/adopt-project
/adopt-project --dry      # 状態診断のみ実行、書き込みなし
```

## Inputs

入力は不要。コマンドが対話的に質問します。

ただし以下を事前に把握していると進めやすい:

- 対象リポジトリの **目的**（このプロジェクトが解決したい課題）
- **テストコマンド**（実際に動くもの。`npm test` / `pnpm test` / `pytest` 等）
- **Lint / typecheck コマンド**
- **触ってはいけない領域**（レガシー凍結 / 自動生成 等）
- **マイグレーションツール**（DB 利用がある場合）
- **PR ルール**（ブランチ命名 / タイトル規約）

---

## Phase 0: 状態診断（5ステップ）

書き込みの前に、対象リポジトリの **現在状態を把握** します。`--dry` オプション指定時はここまでで終了し、診断結果のみレポートします。

### [1] dev-agent-team 本体のバージョン取得

```
Read: ~/.claude/dev-agent-team/version.txt
```

- **取得成功**: バージョン文字列（例: `v0.1.0`）を保持
- **取得失敗**: **Stop Condition** 発動
  - メッセージ: 「`~/.claude/dev-agent-team/version.txt` が見つかりません。インストールが壊れている可能性があります。`git clone https://github.com/fecot/dev-agent-team.git ~/.claude/dev-agent-team` でクローンを確認してください」

### [2] 対象リポジトリの Git 管理確認

```
Bash: test -d .git
```

- **存在する**: 続行
- **存在しない**: 利用者に問う
  - 「このディレクトリは Git 管理されていません。`git init` を実行しますか？ [Y/n]」
  - **YES**: `git init` 実行 → 続行
  - **NO**: 警告のみ出して続行
    - 「Git 管理外のため、`.dev-agent-team/project-rules.md` の変更履歴は追跡されません」

### [3] 既導入チェック

```
Read: .dev-agent-team/project-rules.md
```

- **`.dev-agent-team/project-rules.md` あり** → **分岐D（冪等性モード）** へ。ステップ [4] のバージョン差分検出を続行
- **`.dev-agent-team/` あり + `project-rules.md` なし** → **中途半端状態**
  - 状況を提示: 「`.dev-agent-team/` は存在しますが `project-rules.md` がありません」
  - 利用者に判断を仰ぐ:
    - `[1]` 既存内容を残して新規 `project-rules.md` を作る（推奨）
    - `[2]` `.dev-agent-team/` をバックアップ（`.dev-agent-team.bak.YYYYMMDD-HHMMSS/`）して新規導入
    - `[3]` 中止
- **`.dev-agent-team/` なし** → **新規導入** へ。ステップ [5] の既存リポ判定に進む

### [4] バージョン差分検出（既導入時のみ）

```
Read: .dev-agent-team/project-rules.md の YAML frontmatter
   → dev_agent_team_version, dev_agent_team_min_version
```

- **現在 ≥ min_version**: 分岐D（冪等性モード）に進む
- **現在 < min_version**: **分岐E（バージョン差分モード）** 発動
  - メッセージ:
    ```
    現在の dev-agent-team: {{現在バージョン}}
    project-rules.md が要求する最低バージョン: {{min_version}}

    更新が必要です。以下を実行してください:
      cd ~/.claude/dev-agent-team && git pull

    更新後、再度 /adopt-project を実行してください。
    ```
  - 続行不可（Stop Condition）

### [5] 既存リポ判定（新規導入時のみ）

```
Glob: package.json | pyproject.toml | Gemfile | go.mod | Cargo.toml | composer.json
Read: CLAUDE.md
```

主要ファイルとは上記6種のいずれか1つでも存在することを指す。**モノレポやサブディレクトリのみのケースは「検出できず=新規扱い」** で割り切る。

| 主要ファイル | CLAUDE.md | 分岐 |
|---|---|---|
| あり | あり | **分岐 B**（連携セクション追記） |
| あり | なし | **分岐 C**（CLAUDE.md 新規作成 + 検出技術スタック反映） |
| なし | あり | **分岐 B** として扱う（既存 CLAUDE.md は尊重） |
| なし | なし | **分岐 A**（新規リポ） |

---

## 分岐 A / B / C: 新規導入モード

### 共通: 技術スタックの自動検出

`package.json` / `pyproject.toml` 等のマニフェストから以下を抽出:

- **言語・ランタイム**: ファイル種別から
- **主要 FW・ライブラリ**: dependencies の上位（`next`, `react`, `vue`, `svelte`, `nestjs`, `express`, `fastapi`, `django`, `rails`, `gin` 等）
- **Runtime Commands**: `scripts.test` / `scripts.lint` / `scripts.typecheck` / `scripts.dev` / `scripts.migrate` 相当

抽出結果は **「以下を検出しました。これで合っていますか？」** 形式で利用者に確認。LLM は推測で項目を補完しない。

### 分岐 A: 新規リポ

1. `git init`（[2] で同意済みのとき）
2. `CLAUDE.md` を新規作成
   - 内容: `templates/claude-md-snippet.md` の `<!-- dev-agent-team:start -->` 〜 `<!-- dev-agent-team:end -->` ブロックのみ
3. `.dev-agent-team/` ディレクトリ作成
4. `project-rules.md` 作成（後述「アンケートと書き込み」へ）
5. `.gitignore` 更新（後述「.gitignore 更新」へ）

### 分岐 B: 既存 `CLAUDE.md` あり

`CLAUDE.md` 末尾に連携セクションを追記する。**マーカー検出ロジック**:

```
Read: CLAUDE.md
Search: <!-- dev-agent-team:start --> と <!-- dev-agent-team:end -->
```

| 状態 | 処理 |
|---|---|
| **両マーカーあり** | マーカー間を `claude-md-snippet.md` の最新内容で **置換**（更新）。diff 提示 → 上書き / バックアップ / 中止 の3選 |
| **片方のみあり / 整合しない** | **Stop Condition**。「マーカーが整合しません。手動で修正してください」と案内 |
| **両マーカーなし** | ファイル末尾に `claude-md-snippet.md` の `<!-- dev-agent-team:start -->` 〜 `<!-- dev-agent-team:end -->` ブロックを **追記**。diff 提示 → 同上の3選 |

その後、分岐 A の Step 3〜5 と同じ処理。

### 分岐 C: 既存リポ + `CLAUDE.md` なし

1. `CLAUDE.md` を新規作成
   - 構成: 検出した技術スタックの簡潔な記述（任意） + `claude-md-snippet.md` のブロック
   - 技術スタック記述は **検出結果のみ**、推測加筆しない
2. `.dev-agent-team/` ディレクトリ作成
3. `project-rules.md` 作成（後述）
4. `.gitignore` 更新（後述）

---

## アンケートと書き込み（分岐 A / B / C 共通）

`templates/project-rules-template.md` をベースに、対話的に項目を埋めます。**LLM は質問の進行係 + 回答のフォーマッタに徹し、ルール内容を推測で生成しない**。

### 段階1: 必須質問（8問 + レガシー判定1問）

各質問は **責務を1つに絞る**（旧 Tech Stack のように混在しない）。これらが埋まらないと Phase 0 が Stop Condition で止まります。スキップは可能ですが、完了レポートで強い警告を出します。

| # | 質問 | 形式 |
|---|---|---|
| 1 | このプロジェクトの目的（何を解決するか） | 自由記述 |
| 2 | **言語** | 自動検出値があれば確認のみ |
| 3 | **フレームワーク・主要ライブラリ** | 自動検出値の確認、追加があれば記入 |
| 4 | **インフラ・CI/CD・パッケージマネージャ** | 自由記述（自動検出は限定的） |
| 5 | **Runtime Commands**（test / lint / typecheck / dev / migrate） | 各項目で **「該当なし」回答可**。検出値があれば確認、無い場合は実コマンド入力または「該当なし」 |
| 6 | DB 利用 + マイグレーションツール | 使う/使わない、使うなら種類とツール |
| 7 | 必須テストレイヤー（単体 / 結合 / E2E のうちどれを必須に） | 複数選択 |
| 8 | PR ルール（ブランチ命名 / PR タイトル規約） | 自由記述 |
| 9 | 触ってはいけない領域（Do Not 最低1項目） | 自由記述 |

#### Runtime Commands の質問形式（Q5 詳細）

各サブ項目で「該当なし」回答を許容する。例:

```
Runtime Commands を確認します。検出値があれば確認、無い場合は実コマンドを記入（または「該当なし」）:

- test: 検出値「jest」 → 確認しますか? [Y/n/該当なし]
- typecheck: 未検出 → 実コマンドを入力（例: tsc --noEmit）または「該当なし」
- lint: ...
- dev: ...
- migrate: ...
```

#### Q5/Q6 関連ツール候補ホワイトリスト

LLM が依存ライブラリから関連ツールを推測する際は、**以下のホワイトリストに基づく候補のみ提示**。リストにないものは推測せず「未確定」のまま:

| 検出 | 候補提示 |
|---|---|
| SQLAlchemy | Alembic（マイグレーション） |
| Django | Django 組込 migration |
| Prisma | Prisma migrate |
| FastAPI | uvicorn（ASGI サーバ） |
| Next.js | Next.js 組込 migration なし（migrate は **該当なし** 候補） |

ホワイトリストに該当しない依存は **推測せず未確定のまま** 利用者に質問。

#### 段階1の最後: レガシー判定

```
このプロジェクトはレガシーアプリ（古い独自FW、レガシーMVC等）ですか？ [Y/n]
```

- **Yes** → 段階3 H（Legacy Modernization Rules）を質問する
- **No** → 段階3 H をスキップ（「該当なし」と記載）

### 段階2: 推奨質問（任意・8項目）

スキップ可。スキップ時は **「未確定（要確認）」** マーカーを残します。各質問は **「該当しますか？該当する場合は記入をお願いします（スキップ可）」** 形式で進める。

- **A.** Architecture Rules（採用設計、依存方向）
- **B.** Coding Rules（型安全方針、エラーハンドリング、ロギング）
- **C.** Frontend Rules（フロント案件のとき）
- **D.** Backend Rules（バックエンド案件のとき）
- **E.** API Rules（API 提供あり）
- **F.** Security/Privacy Rules（PII 取り扱いあり）
- **G.** Release Rules（リリース方式）
- **I.** Known Risks（既知の不具合・パフォーマンス弱点・将来の負債）

各セクションが選ばれた場合、`templates/project-rules-template.md` の **詳細項目** を追加質問する（例: Test Rules を選んだら「カバレッジ目標 / モック方針 / テスト配置 ...」を順に聞く）。選ばれなかったセクションは「未確定（要確認）」のまま。

### 段階3: 該当時のみ（1項目）

段階1の最後のレガシー判定で **Yes** と回答された場合のみ:

- **H.** Legacy Modernization Rules — `templates/project-rules-template.md` の Legacy Modernization Rules セクションの全項目を質問

レガシー判定 No の場合、Legacy Modernization Rules セクションには **「該当なし（新規アプリ・モダンアーキテクチャのため）」** と記載。

### project-rules.md の書き込み

1. `templates/project-rules-template.md` を読み込む
2. YAML frontmatter の値を設定:
   - `dev_agent_team_version`: `~/.claude/dev-agent-team/version.txt` の値
   - `dev_agent_team_min_version`: 同上（初回は version と同じ）
3. 各セクションを利用者の回答で埋める。スキップ項目は `{{...}}` プレースホルダーを **「未確定（要確認）」** に置換
4. diff 提示 → 上書き / バックアップ（`.bak.YYYYMMDD-HHMMSS`）/ 中止 の3選

### `.gitignore` 更新

[`docs/adoption-guide.md` §9 Artifacts Retention Policy](../docs/adoption-guide.md#9-artifacts-retention-policy) のテンプレートを使う。**バックアップファイルも除外** する点に注意（タイムスタンプ付き `.bak.*` は機密情報を含む可能性があるため Git 管理しない）。

```gitignore
# dev-agent-team artifacts (transient)
.dev-agent-team/project-context.md
.dev-agent-team/requirements/
.dev-agent-team/reports/
.dev-agent-team/plans/
.dev-agent-team/reviews/
.dev-agent-team/releases/
.dev-agent-team/runs/
.dev-agent-team/archive/

# ただし project-rules.md は Git 管理から除外しない
!.dev-agent-team/project-rules.md

# /adopt-project が作成するバックアップファイル
*.bak.*
```

処理:

- **`.gitignore` あり**: 末尾に dev-agent-team セクションを追記。**重複検出**（コメント `# dev-agent-team artifacts (transient)` で識別）した場合は重複追記しない
- **`.gitignore` なし**: 上記内容で新規作成

書き込み前に diff 提示 → 上書き / バックアップ / 中止 の3選。

---

## 分岐 D: 冪等性モード

利用者が再実行してきたケース。`.dev-agent-team/project-rules.md` が既に存在し、バージョン差分も Stop に該当しない状態。

### 現在の状態提示

```
✓ dev-agent-team v{{現在バージョン}} を検出しました
✓ .dev-agent-team/project-rules.md が見つかりました
  - dev_agent_team_version: {{書き込まれているバージョン}}
  - dev_agent_team_min_version: {{書き込まれている min_version}}
  - 直近の更新日時: {{ファイルmtime}}
```

### メニュー方式での対象選択

```
どの項目を更新しますか?
  [1] Project Overview
  [2] Tech Stack
  [3] Runtime Commands
  [4] Architecture Rules
  [5] Legacy Modernization Rules
  [6] Directory Rules
  [7] Coding Rules
  [8] Database Rules
  [9] API Rules
 [10] Frontend Rules
 [11] Backend Rules
 [12] Test Rules
 [13] Security / Privacy Rules
 [14] PR Rules
 [15] Release Rules
 [16] Do Not
 [17] Human Approval Required
 [18] Known Risks
  [a] すべて確認
  [v] バージョンピン留めのみ更新
  [q] 終了
```

### 選択した項目の詳細確認

選択された項目について現在値を提示:

```
Tech Stack: 現在の値:
  - 言語: TypeScript
  - フレームワーク: Next.js 14
  - DB: PostgreSQL

新しい値を入力してください（変更なしならEnter、複数行は終わりに空行）:
```

### 変更がある場合: diff 提示

通常の書き込みフローと同じ。上書き / バックアップ / 中止 の3選。

### バージョン更新

利用者が「上書き」または「バックアップ」を選んだ場合、`dev_agent_team_version` を `~/.claude/dev-agent-team/version.txt` の値に **自動更新**。`dev_agent_team_min_version` は **手動で利用者に確認** （新しい Phase / Skill / Stop Condition に依存していなければ据え置き、依存していれば上げる）。

`[v] バージョンピン留めのみ更新` を選んだ場合は、`dev_agent_team_version` のみ自動更新し、他の項目は触らない。

---

## 分岐 E: バージョン差分モード（再掲）

ステップ [4] で発生。利用者に選ばせる:

```
このプロジェクトは dev-agent-team {{min_version}} 以上を要求しますが、
現在のホーム配下は {{現在バージョン}} です。

  [1] dev-agent-team を更新する手順を表示（推奨）
  [2] 強制的に進める（非推奨。Stop Condition を意図的にバイパス）
  [3] 中止
```

- `[1]`: 以下を案内して終了
  ```
  cd ~/.claude/dev-agent-team
  git pull
  # 更新後、再度 /adopt-project を実行してください
  ```
- `[2]`: **強い警告** を出した上で、Stop Condition を bypass フラグ付きで記録（後続の `/run-feature-workflow` が再評価できるよう project-context.md に残す）
- `[3]`: 即終了

---

## `--dry` オプション

書き込みを一切行わず、状態診断結果のみレポートします。テスト・初回確認に有用。

出力例:

```
[Dry Run Mode] 書き込みは行いません

== 状態診断 ==
[1] dev-agent-team: v0.1.0 (~/.claude/dev-agent-team/version.txt)
[2] Git 管理: ✓ (.git ディレクトリあり)
[3] 既導入: ✗ (.dev-agent-team/ なし)
[4] バージョン差分: N/A
[5] 既存リポ判定:
    主要ファイル: package.json 検出
    CLAUDE.md: あり
    → 分岐 B (連携セクション追記)

== 検出した技術スタック ==
- 言語: TypeScript (package.json)
- フレームワーク: Next.js 14 (dependencies.next)
- テストランナー: Vitest (devDependencies.vitest)
- Runtime Commands:
  - test: pnpm test
  - lint: pnpm lint
  - typecheck: pnpm typecheck

== もし実行したら ==
書き込み対象:
  - CLAUDE.md (連携セクション追記)
  - .dev-agent-team/project-rules.md (新規作成)
  - .gitignore (dev-agent-team セクション追記)

実行する場合は --dry なしで再度 /adopt-project を起動してください。
```

---

## 完了レポート

成功時:

```
✅ /adopt-project が完了しました。

== 作成・更新したファイル ==
- CLAUDE.md (連携セクション追記)
- .dev-agent-team/project-rules.md (新規作成)
- .gitignore (dev-agent-team セクション追記)

== 未確定項目 ==
以下が「未確定（要確認）」のままです（{{N}}項目）:
- Architecture Rules
- Coding Rules
- ...

⚠️ このまま /run-feature-workflow を起動すると、Phase 0 で Stop Condition が発動する可能性があります。
   時間を取って .dev-agent-team/project-rules.md を埋めてください。

== Next Steps ==
1. .dev-agent-team/project-rules.md の未確定項目を埋める
2. project-rules.md を Git にコミット
3. 開発タスクが発生したら /run-feature-workflow を起動
4. ワークフロー成果物 (.dev-agent-team/runs/, reports/, plans/ 等) は
   原則 Git 管理しない。重要な判断は PR 本文に要約して残す
   (詳細: ~/.claude/dev-agent-team/docs/adoption-guide.md §9)

== バックアップファイル ==
{{もし作成されたファイルがあれば}}
- CLAUDE.md.bak.20260504-014320

不要になったらまとめて削除してください: rm *.bak.*
```

失敗時:

```
❌ /adopt-project が中断されました。

== 中断箇所 ==
{{Phase / 分岐名}}

== 理由 ==
{{Stop Condition または利用者中止の内容}}

== 影響 ==
{{書き込み済みファイルがあれば一覧、なければ「変更なし」}}

== ロールバック手順 ==
{{バックアップファイルがあれば復旧コマンド、なければ「不要」}}
```

---

## Stop Conditions（停止条件まとめ）

以下のいずれかに該当したら **停止して人間に確認**:

- `~/.claude/dev-agent-team/version.txt` が読み取れない
- 対象リポジトリが Git 管理外で、利用者が `git init` を拒否し、それでも .dev-agent-team/ 作成に異論がある
- `.dev-agent-team/` が存在するが `project-rules.md` がなく、利用者が中断を選択
- `dev_agent_team_min_version > 現在バージョン` で、利用者が更新せず強制続行を選ばない
- `CLAUDE.md` のマーカーが片方しかない / 整合しない
- 必須質問（段階1）の回答収集中に利用者が中断
- 書き込み diff 提示で利用者が「中止」を選択（部分的な書き込みがあればロールバック手順を提示）

## Human Decision Required（人間判断必須項目）

- すべての書き込み（diff 提示後の3選）
- `git init` 実行可否
- `.dev-agent-team/` 中途半端状態時の対処方針
- 段階1の必須質問への回答（または明示的なスキップ）
- バージョン差分時の対処（更新 / 強制続行 / 中止）
- 段階2 / 段階3 の各項目を埋めるか、未確定で残すか

## 関連ドキュメント

- [`docs/adoption-guide.md`](../docs/adoption-guide.md) — 既存リポジトリへの導入手順（§9 Artifacts Retention Policy 含む）
- [`workflows/feature-development.md`](../workflows/feature-development.md) — Phase 0: Project Context Loading の振る舞い
- [`templates/project-rules-template.md`](../templates/project-rules-template.md) — Project Rules 雛形（バージョンピン留めフィールド入り）
- [`templates/claude-md-snippet.md`](../templates/claude-md-snippet.md) — 対象リポジトリの CLAUDE.md に追記する静的スニペット

## 進捗

- [x] プレースホルダー配置（`install.sh` テスト用、v0.1.0）
- [x] 本実装（このファイル、v0.2.0 予定）
