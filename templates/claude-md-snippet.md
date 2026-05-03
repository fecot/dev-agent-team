# Claude Code 向け CLAUDE.md 連携スニペット

> **目的**: 対象リポジトリの `CLAUDE.md` に追記する **dev-agent-team 連携セクション** の静的テンプレートです。
>
> `/adopt-project` コマンドはこのファイルを **そのままコピー** して、対象リポジトリの `CLAUDE.md` 末尾に追記します。LLM が変数展開や推測加筆をしてはいけません。
>
> セクション境界は `<!-- dev-agent-team:start -->` / `<!-- dev-agent-team:end -->` のマーカーで囲み、再実行時は **このマーカー間を再生成** することで安全に上書きできます。

---

以下の `<!-- dev-agent-team:start -->` から `<!-- dev-agent-team:end -->` までを、対象リポジトリの `CLAUDE.md` 末尾にそのままコピーします。

```markdown
<!-- dev-agent-team:start -->
## dev-agent-team 連携

このリポジトリは [dev-agent-team](https://github.com/fecot/dev-agent-team) を使った開発プロセスに対応しています。Claude Code でこのリポジトリを開くと、以下のルールが有効になります。

### Rule Priority（判断優先順位）

判断に迷ったら、以下の優先順位で決定してください。

1. **ユーザー（人間）の明示指示**
2. **このリポジトリの Project Rules**（`CLAUDE.md` / `README.md` / `docs/` / `.dev-agent-team/project-rules.md` 等）
3. **dev-agent-team の共通 Workflow / Commands / Agents / Skills**
4. **一般的なベストプラクティス**

dev-agent-team の共通ルールは、このリポジトリの Project Rules を **上書きしてはいけません**。衝突した場合はこのリポジトリのルールを採用し、判断がつかなければ人間に確認してください。

### 参照場所

- **共通キット本体**: `~/.claude/dev-agent-team/`
- **このリポジトリの Project Rules**: `.dev-agent-team/project-rules.md`
- **ワークフロー実行時の成果物**: `.dev-agent-team/runs/{{issue-id}}/`（原則 Git 管理しない一時成果物）

### 利用方法

開発タスクが発生したら、Claude Code で以下のスラッシュコマンドを起動してください。

- **`/run-feature-workflow`** — 8 Phase の標準開発フロー（Issue → 要件整理 → 既存コード調査 → 影響範囲分析 → 実装計画 → 安全な実装 → テスト設計 → PR レビュー → リリース確認）
- **`/adopt-project`** — このリポジトリの dev-agent-team 設定を再構成・更新（冪等実行可能）

各 Phase には Stop Condition と Human Decision Point が定義されており、抜け漏れがあれば次に進みません。判断材料は AI が出しますが、**判断は人間が行います**。

### Artifacts の取り扱い

`/run-feature-workflow` で生成される成果物は **原則 Git 管理しません**（`.dev-agent-team/project-rules.md` のみ Git 管理推奨）。重要な判断は **PR 本文に要約** して残し、Artifacts 本体はマージ後に削除または `.dev-agent-team/archive/` へ移動します。詳細は `~/.claude/dev-agent-team/docs/adoption-guide.md` の §9 Artifacts Retention Policy を参照してください。

### dev-agent-team のバージョン管理

`.dev-agent-team/project-rules.md` 冒頭の YAML フロントマターでバージョンをピン留めしています。`~/.claude/dev-agent-team` の現在バージョンが `dev_agent_team_min_version` を下回る場合、Phase 0 で Stop Condition が発動します。その場合は以下を実行してください:

```sh
cd ~/.claude/dev-agent-team && git pull
```

<!-- dev-agent-team:end -->
```

---

## 実装メモ

このスニペットを書き込む側（`/adopt-project`）の実装注意:

- **マーカー検出**: `<!-- dev-agent-team:start -->` と `<!-- dev-agent-team:end -->` の両方が見つかれば、その間を **このスニペット内容で置換** する（更新）
- **片方しかない / 整合しない**: 警告を出して中止。利用者に手動修正を促す
- **両方ない**: ファイル末尾にスニペット全体を **追記** する（新規）
- **書き込み前**: 必ず diff を提示し、上書き / `.bak.YYYYMMDD-HHMMSS` バックアップ / 中止 の3選を取る
- **Markdown コードフェンスの扱い**: 上の \`\`\`markdown ブロック内の内容のみが書き込み対象。コードフェンス行（\`\`\`markdown / \`\`\`）自体は対象 CLAUDE.md には含めない
