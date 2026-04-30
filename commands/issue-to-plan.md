# Command: /issue-to-plan

## 概要

イシューを受け取り、実装計画まで一気通貫で作成するコマンド。ProductInterpreter → CodebaseExplorer → ArchitectureReviewer → ImplementationDriver の順で処理する。

## 使い方

```
/issue-to-plan <イシューURL or イシューの内容>
```

## 実行フロー

1. **ProductInterpreter** — 要件整理・完了条件・確認事項の出力
2. （確認事項がある場合は人間に確認を求めて停止）
3. **CodebaseExplorer** — 関連コードの調査・類似実装の発見
4. **ArchitectureReviewer** — 影響範囲の分析
5. **ImplementationDriver** — 実装案（最小案・標準案）の提示

## 出力

- `docs/plan-{{issue-id}}.md` として保存する
- 確認事項がある場合は、そこで処理を止めて人間の判断を待つ

## オプション

- `--minimal` : 最小変更案のみ出力
- `--no-code` : 実装案のコードを省略し、方針のみ出力
- `--dry` : ファイルに保存せずターミナル出力のみ

## 注意

このコマンドは実装を開始しない。計画を作るコマンドである。
実装は `/safe-implement` で別途行う。
