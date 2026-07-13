# Command: /issue-to-plan

## 概要

イシューを受け取り、実装計画まで一気通貫で作成するコマンド。ProductInterpreter → CodebaseExplorer → ArchitectureReviewer → ImplementationDriver の順で処理する。

## 使い方

```
/issue-to-plan <イシューURL or イシューの内容>
```

## 実行フロー

1. **ProductInterpreter** — 要件整理・完了条件・確認事項の出力
2. （確認事項がある場合は停止する — Stop Condition (1) 参照）
3. **CodebaseExplorer** — 関連コードの調査・類似実装の発見
4. **ArchitectureReviewer** — 影響範囲の分析
5. **ImplementationDriver** — 実装案（最小案・標準案）の提示。出力形式は [`templates/implementation-plan-template.md`](../templates/implementation-plan-template.md) に従う（本フローのとおり最小案を必ず含める）

## 出力

- 実装計画を以下のいずれかに保存する（どちらのレイアウトを使うかは対象リポジトリの既存運用に揃える。`commands/run-feature-workflow.md` と同じ判断基準）:
  - Run 単位レイアウト: `.dev-agent-team/runs/{{issue-id}}/implementation-plan.md`
  - Phase 単位互換レイアウト: `.dev-agent-team/plans/implementation-plan-{{issue-id}}.md`
- 原則 Git 管理しない一時成果物。詳細は [`docs/adoption-guide.md`](../docs/adoption-guide.md) §9 Artifacts Retention Policy
- `--dry` オプションは保存自体を行わないため、本保存先ルールの影響を受けない

## オプション

- `--minimal` : 最小変更案のみ出力
- `--no-code` : 実装案のコードを省略し、方針のみ出力
- `--dry` : ファイルに保存せずターミナル出力のみ

## Stop Condition

1. 確認事項が未回答のまま次工程へ進まない（実行フロー 2 で停止し、人間の回答を待つ）
2. 整理した受け入れ基準について人間の明示承認が取れていない場合、計画を確定しない（「確認事項がない」＝「承認済み」ではない。`workflows/feature-development.md` Phase 1 Stop Condition と同一規範）
3. 単独実行時も `.dev-agent-team/project-rules.md` が存在すれば Phase 0 相当として先に読み込む（`workflows/feature-development.md` Phase 0 参照）。存在しない場合は `/adopt-project` の実行を案内する

## 注意

このコマンドは実装を開始しない。計画を作るコマンドである。
実装は `/safe-implement` で別途行う。

## 関連ドキュメント

- [`workflows/feature-development.md`](../workflows/feature-development.md) — Phase 1〜4（本コマンドがカバーする範囲）
- [`templates/implementation-plan-template.md`](../templates/implementation-plan-template.md) — 実装計画の出力形式
