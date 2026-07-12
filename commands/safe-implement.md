# Command: /safe-implement

## 概要

実装計画に基づき、安全に実装を進めるコマンド。既存設計を尊重し、最小差分で進める。

## 使い方

```
/safe-implement <plan-file or 実装方針>
```

## 実行フロー

1. 実装計画を読み込む（`/issue-to-plan` の出力 or インライン入力）
   - **UI を伴う実装の場合**: 着手前に「視覚仕様スケッチ（ASCII / mock 等）が人間に合意済みか」を確認する。未合意なら Phase 4 に戻し、合意を得てから着手する（視覚仕様レビューゲート）
2. ImplementationDriver として実装を開始
3. 実装中に不明点が出たら停止して確認を求める
4. 実装完了後にセルフレビューを実施
5. TestStrategist としてテスト観点を出力
6. テストコードを生成

## 検証ループ（UI 変更時）

UI に影響する実装では、**1 修正ごとに** `skills/browser-verification.md` の 6 ステップ検証ループを通す:

1. コード修正
2. ビルド完了確認（bundle mtime / dev server ログ）
3. キャッシュバイパス reload（Playwright route interception）
4. 当該要素を `browser_evaluate` で実機計測
5. スクショ取得 + source 版と side-by-side
6. **数値 + 画像で報告**（目視判定で完了扱いにしない）

`/run-feature-workflow` で **Migration / UI Replica 種別** を宣言している場合は必須。それ以外の UI 変更タスクでも強く推奨。前提として Playwright MCP が利用可能であること。

詳細は [`skills/browser-verification.md`](../skills/browser-verification.md) を参照。

## 機械的ループの自動化（任意設定）

Phase 5 でテスト緑化 / lint / typecheck を `/goal` の機械的サブループで収束させる場合、ユーザー設定（`~/.claude/settings.json`）の `autoMode.classifyAllShell`（全 shell コマンドを auto-mode classifier でホワイトリスト判定）を有効化すると、手動承認でループが止まりにくくなる。auto mode 中は破壊的コマンド（`git reset --hard` / `git push --force` / `terraform destroy` 等）が明示指示なしに自動ブロックされるため、無人ループでも取り返しのつかない操作は走らない。

ただし **Phase 5 のセーフガード（計画外変更は人間へ）は維持** する。⚠️ プロジェクトごとに有効化するかは人間判断。詳細は [`docs/native-tooling-integration.md`](../docs/native-tooling-integration.md) § 2.5 / § 2.6。

## 原則

- 計画にないことをやらない
- 「ついでに直す」をしない
- 1PRに含める変更を最小化する
- コミットは意味のある単位で細かく切る

## 出力

- 実装コード
- テストコード
- セルフレビュー結果
- `/pr-review` への入力となるサマリ
- （UI 変更時）`skills/browser-verification.md` の検証ログ

## セーフガード

以下の場合は実装を止めて確認を求める:

- 計画にない変更が必要になった場合
- 影響範囲が計画より広がった場合
- 既存の設計パターンと矛盾する場合
- テストが書けない実装になりそうな場合
- **UI を伴う実装なのに、視覚仕様スケッチの人間合意がないまま着手しようとした場合**
- **UI を変更したのに `skills/browser-verification.md` の検証ループを通していない状態で完了報告しようとした場合**
- **計測値で source / target の差分が残っているのに「目視では同じに見える」で完了扱いにしようとした場合**
