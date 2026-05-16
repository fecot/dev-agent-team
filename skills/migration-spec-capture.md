# Skill: Migration Spec Capture

## Purpose

Migration / UI Replica 系タスクで、**移植元（source）アプリの実値を機械計測してから実装に入る** ためのスキルです。色 / px / フォント / DOM 構造 / LocalStorage 実値 / API 実 shape を Playwright MCP（または同等のブラウザ自動操作 MCP）で採取し、`agents/implementation-driver.md` の「数値固定方針」と Phase 4 Implementation Plan に **px ベース** で書き起こせる状態を作ります。

「色は薄いグレー」「フォントは小さめ」のような曖昧記述を撲滅し、後追いでの「やっぱり違った」修正往復を抑制することが目的です。

## When to Use

以下のケースで使う:

- 既存アプリを別フレームワーク / 別言語へ移植する（例: AngularJS → React、Rails ERB → Next.js、jQuery → Vue）
- 既存 UI を別技術スタックで再現する（例: 別アプリの画面を SaaS 化、社内ツールを公開向けに作り直す）
- Figma デザインがなく、ground truth が「動いている既存画面」しかないケース
- 共通部品 / グローバル CSS の影響でローカル指定値と表示値が乖離している疑いがあるケース

新規アプリで Figma などのデザインソースが正であるケースには **使う必要がありません**。そちらはデザインソースを ground truth として実装してください。

## いつ使うか — 他 skill との棲み分け

近接する skill との使い分けを明示します:

- **`skills/legacy-modernization.md`** — 既存コードを残しつつ少しずつ境界を作る運用。**触り続ける** ことが前提。
- **`skills/migration-spec-capture.md`**（このスキル） — 既存アプリの **表示仕様** を機械計測し、別技術スタックで再現する準備をする。「source を残すか捨てるか」は問わない。
- **`skills/browser-verification.md`** — 実装後の検証ループ。target 側を計測し、source と差分が出ていないかを確認する。

このスキルは Phase 2（Discovery）で source を計測する用途。`browser-verification` は Phase 5（実装）で target を検証する用途。

## 前提

- **Playwright MCP（または同等のブラウザ自動操作 MCP）が利用可能** であること
- source アプリがローカル or 検証環境で起動できること
- 採取対象の画面に到達できる認証情報がある（必要なら）

利用不可環境では本スキルは適用外。代わりに `getComputedStyle` を取得する小さな JS スニペットを DevTools Console で手動実行 + コピー、という運用に切り替えること。ただし精度・カバレッジは大きく落ちる。

## 採取項目

### 1. Computed Style（要素ごと）

採取対象要素ごとに `getComputedStyle` で以下を取得:

- `font-size` / `font-weight` / `font-family` / `line-height`
- `color` / `background-color` / `border-color`（hex 表記に正規化）
- `padding-*` / `margin-*` / `gap`（px）
- `border-*-width` / `border-radius`（px）
- `width` / `height`（px）
- `display` / `position` / `z-index`
- `opacity` / `box-shadow` / `transform`

### 2. DOM 構造ツリー

- 採取対象画面のルートからの DOM ツリー（要素名 / class / id / data-* 属性）
- 動的に挿入される要素（モーダル / ツールチップ / ドロップダウン）は **発火後** にも採取する
- SVG / Canvas / iframe 内の構造（c3 等のチャートライブラリは SVG 内部寸法を要確認）

### 3. LocalStorage / SessionStorage / Cookie

- 全エントリの key / value / 型
- 特に **「想定される型」と「実際の値」のズレ**（例: 型宣言は number だが実値は string）
- 空文字 / null / undefined パターンの有無

### 4. API レスポンスの実 shape

- 画面が呼び出す API（XHR / fetch）の **実レスポンス** を採取
- TypeScript 型宣言ファイル / Swagger / OpenAPI スキーマと **突合**
- nullable / optional の実際の頻度（型では optional だが実値は常に存在 / 逆も）

### 5. 動的挙動

- イベント発火（hover / click / focus）時の class 変化 / style 変化
- アニメーション・トランジションの duration / easing
- 共通部品の初期値が **props 変更で更新されるか**（例: useState 初期値固定で外部データを反映できないバグ）

## 出力先

```
.dev-agent-team/runs/{issue-id}/migration-spec.md
```

Run 単位レイアウトを採用していない場合は `.dev-agent-team/reports/migration-spec-{issue-id}.md` でも可。

## 出力例

```markdown
# Migration Spec: PRA-11459 ドーナツチャート widget

採取日時: 2026-05-16 10:23 JST
source URL: http://localhost:3001/dashboard/donut
target URL: http://localhost:3000/dashboard/donut

## .donut-graph__count
- font-size: 26px
- color: rgb(53, 53, 53) / #353535
- font-weight: 700
- margin: 0
- line-height: 1.2

## .donut-graph__count__unit
- font-size: 14px
- color: rgb(165, 165, 165) / #a5a5a5
- font-weight: 400
- margin-left: -4px
  - ※ 親要素内の半角スペース文字を打ち消すための負マージン（要再現）

## SVG 円グラフ
- canvas サイズ: 240 x 240 px
- 実際の円の径: 190 x 190 px（canvas の 79%）
- c3 default の radius padding に由来（chart.js では `cutout: '21%'` 相当）

## LocalStorage
- key: `dashboard.lastVisitedTab`
  - 宣言型: `number`（IKeyword.id）
  - 実値: `"3"`（string）← 型乖離あり
  - 空文字パターン: あり（初回訪問時）→ React 側 `?? default` で弾けないので明示的に `if (val === "") fallback` が必要

## API GET /api/widgets/donut
- 宣言 shape: `{ id: number, title: string, data: { label: string, value: number }[] }`
- 実 shape: `{ id: number, title: string | null, data: { label: string, value: number | string }[] }`
  - title が null 返却あり（タイトル未設定 widget）
  - value が string 返却あり（数値オーバーフロー時の文字列フォールバック）

## 共通部品: WidgetOptionSelectBox（要注意）
- AngularJS 版: `ng-options` で外部更新を自動反映
- React 版（再実装）の懸念: `useState(props.itemList)` で初期値固定 → 外部更新を反映できない
- → Phase 4 で `useEffect([props.itemList])` で同期するか、`itemList` を state にせず props 直接利用にする
```

## 注意

- **本番環境では絶対に採取しない**（顧客データ / 個人情報の流出リスク）。検証環境 or ローカル環境を使う
- LocalStorage / API レスポンスに **個人情報・認証トークン** が含まれる場合は、出力前にマスクするか採取自体を見送る
- 採取結果を Git にコミットしない（`.dev-agent-team/` 配下は `.gitignore` 推奨。詳細は [`docs/adoption-guide.md` Artifacts Retention Policy](../docs/adoption-guide.md#9-artifacts-retention-policy)）
- `getComputedStyle` の値は **viewport / カテゴリ数 / hover 状態** で変動する。採取条件（viewport サイズ / データ件数 / 状態）を必ずヘッダに記録する
- グローバル SCSS の上書き影響を切り分けたい場合は、ローカル指定値（`<style>` の宣言値）と最終的な computed value の **両方** を採取し、差分があれば「上書きされている」と判定する

## Stop Conditions

以下のいずれかに該当したら **進めない**:

- 採取条件（viewport / データ件数 / 状態）が定義されていない
- 採取結果に個人情報 / 認証トークン / 顧客データが含まれているが、マスク方針が未定
- source アプリが起動できず、Figma など代替 ground truth もない
- 採取項目のうち「LocalStorage / API 実 shape」を **未確認** のまま Phase 4 に進もうとしている（型乖離・空文字パターンの罠を踏むリスク）

## このスキルが想定する使い方

- Phase 2（Discovery）で、Migration / UI Replica 種別タスクの **必須プロセス** として実行する
- 採取結果を Phase 4 Implementation Plan の「数値固定方針」テーブルに転記する
- 採取結果を Phase 5 で `skills/browser-verification.md` の差分検出のベースラインとして使う
- 採取結果は `replacement-notes.md` 相当の **将来資産** として `.dev-agent-team/runs/{issue-id}/` に残す（重要な発見は PR 本文にも要約）

> 「実装してから違いに気付く」のではなく、「実装前に違いを言語化する」ためのスキルです。
