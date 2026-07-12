# Command: /pr-review

## 概要

PRの内容をレビューし、指摘事項とPR説明文を生成するコマンド。

## 使い方

```
/pr-review <PRのdiff or ファイルパス>
```

## 実行内容

ReviewGatekeeper エージェントとして動作し、以下を実施:

1. 変更内容と要件の整合確認
2. コード品質レビュー
3. テストの網羅性確認
4. セキュリティ・パフォーマンス確認
5. PR説明文の生成
6. マージ判定材料の整理（**マージ可否の最終判断は人間が行う**）

## 出力

### レビュー結果
```
# PR Review

## 判定: Go / No Go / 条件付きGo

## 必須修正
- {{}}

## 推奨修正
- {{}}

## コメント
- {{}}
```

### PR説明文

[`templates/pr-description-template.md`](../templates/pr-description-template.md) に従う（関連イシュー / 変更しなかったこと / 影響範囲 / マイグレーション の各セクションを省略しない）。

## オプション

- `--description-only` : PR説明文のみ生成
- `--review-only` : レビュー結果のみ出力
- `--strict` : より厳格な基準でレビュー。具体的には (1) 推奨修正も必須修正として扱う (2) OWASP Top 10 の全項目を明示的に点検し、対象外の項目も「対象外の理由」を記録する

## Stop Condition

- 必須修正が未解消のまま「Go」を出さない
- マージ可否の最終判断は人間が行う（本コマンドの判定は判断材料であり、承認ではない）

## 関連ドキュメント

- [`workflows/feature-development.md`](../workflows/feature-development.md) — Phase 7: Review Gate（本コマンドが対応する Phase。詳細チェックリストはこちらが正）
- [`agents/review-gatekeeper.md`](../agents/review-gatekeeper.md) — 動作主体のエージェント定義
- ネイティブレビューとの棲み分け: 一次スキャンは `/review`（シングルパス）、指摘の網羅生成は `/code-review <level>`（多エージェント、v2.1.202+）。本コマンドは **判定観点の整理（Go / No Go / 条件付き Go）** を担い、生成された指摘の下流に位置する（[`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) §4）
