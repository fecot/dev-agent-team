# Command: /codebase-explore

## 概要

キーワードや機能名を受け取り、コードベースを調査して地図を作るコマンド。実装前の文脈把握に使う。

## 使い方

```
/codebase-explore <キーワード or 機能名>
```

## 前提

- 対象リポジトリの `CLAUDE.md` と `.dev-agent-team/project-rules.md` があれば先に読む（`workflows/feature-development.md` の Rule Priority に従う）
- `.dev-agent-team/project-context.md` が既に生成済みならそれを流用してよい

## 実行内容

CodebaseExplorer エージェントとして動作し、以下を実行する:

1. 指定キーワードでコードベースを検索
2. 関連ファイル・クラス・関数を特定
3. データモデルとの関係を把握
4. 類似実装の発見
5. 既存のパターン・命名規則の確認

## 出力

[`templates/investigation-report-template.md`](../templates/investigation-report-template.md) に従う。

- **コマンド単独実行のクイック調査時のみ**、関連ファイル表 + 類似実装 + 命名・パターン への縮約可（縮約した旨をレポート冒頭に明記する）
- `/run-feature-workflow` の Phase 2 として実行する場合は縮約不可（フルテンプレート必須。Phase 2 Stop Condition のデータモデル・型定義確認と整合させるため）

## Stop Condition

- 調査で確信が持てない箇所は「要確認」と明示し、断言しない
- 調査結果は次フェーズへの自動入力ではなく、Phase 3 へ進む前に **人間がレビューする判断材料** である

## ユースケース

- 「この機能がどこに実装されているか分からない」
- 「同じような処理が他にあるか確認したい」
- 「このモデルがどこで使われているか知りたい」
- 新規参画メンバーのオンボーディング支援

## 関連ドキュメント

- [`workflows/feature-development.md`](../workflows/feature-development.md) — Phase 2: Discovery（本コマンドが対応する Phase）
- [`agents/codebase-explorer.md`](../agents/codebase-explorer.md) — 動作主体のエージェント定義
- [`skills/codebase-reading.md`](../skills/codebase-reading.md) — 調査の手法
- 多ファイル / 多サブシステムにまたがる広域並列調査は `/dev-agent-discovery`（[`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) §3.5）
