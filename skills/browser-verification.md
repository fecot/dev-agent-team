# Skill: Browser Verification

## Purpose

UI 変更を含む実装で、**「実装したけど反映されない」「思ったのと違う」のフィードバックループを 1 修正で完結させる** ためのスキルです。コード修正 → ビルド完了確認 → キャッシュバイパスリロード → 実機計測 → スクショ比較 → 報告、を 1 サイクルとする検証ループを標準形として提供します。

目視確認だけで「色が薄い」「広すぎる」と判断するのではなく、**`browser_evaluate` での計測値** を一次ソースにすることで、解釈違いの往復を防ぎます。

## When to Use

以下のケースで使う:

- Migration / UI Replica 系タスクの Phase 5（実装中の検証）
- 既存 UI を改修する際の差分検証
- 「Hot Reload が効いてるはずなのに反映されない」と感じたとき
- スクショレビューで「微妙にズレている」と言われた直後の差分計測

新規 UI（比較対象がない）の場合は、計測値の絶対値だけ取得して報告する形で部分適用できる。

## いつ使うか — 他 skill との棲み分け

- **`skills/migration-spec-capture.md`** — Phase 2 で source（既存）を計測する。ground truth を作る側。
- **`skills/browser-verification.md`**（このスキル） — Phase 5 で target（新実装）を計測する。差分を埋める側。

両スキルで採取する項目（computed style / DOM / px 値）は **同じ形式** に揃え、`.dev-agent-team/runs/{issue-id}/` 配下で source / target の対比表が作れる状態を目指す。

## 前提

- **Playwright MCP（または同等のブラウザ自動操作 MCP）が利用可能** であること
- target アプリの dev server が起動しており、HMR / rebuild の挙動が把握できていること
- 採取条件（viewport / データ件数 / 状態）が `migration-spec-capture` の採取時と揃っていること

利用不可環境では本スキルは適用外。代わりに DevTools での手動確認 + スクショに切り替えるが、検証ループの実効性は大きく落ちる。

## 検証ループ標準形（6 ステップ）

UI 変更を加えるたびに、以下の 6 ステップを **必ず順番に** 通す。1 ステップでも飛ばすと「反映されてない問題」「キャッシュ問題」「目視解釈違い」のどれを踏んでいるか切り分けられなくなる。

### Step 1: コード修正

- 計画書（Phase 4 実装計画）のステップに沿って修正する
- 1 修正 = 1 検証ループ。複数箇所をまとめて修正してから検証しない（差分要因が混ざる）

### Step 2: ビルド完了確認

- webpack / vite などの dev server の **rebuild が完了するまで待つ**
- 確認方法（Project Rules / Phase 0 で記録済みのもの）:
  - 出力 bundle の mtime をチェック（`stat` / `ls -la dist/`）
  - dev server の stdout / stderr に「compiled successfully」が出るまで待つ
  - HMR の WebSocket メッセージを Playwright で監視
- 「コード変更後、勝手に rebuild される」前提に依存しない（HMR 不調時に検知できないため）

### Step 3: キャッシュバイパス reload

- Playwright route interception で `Cache-Control: no-cache` / `Pragma: no-cache` を注入してから navigate
- ブラウザのディスクキャッシュ / サービスワーカーのキャッシュ / CDN キャッシュをすべてバイパスする想定
- 擬似インターフェース: `cacheBustReload(url)` — route で Cache-Control 注入 + `page.goto(url, { waitUntil: 'networkidle' })`

### Step 4: 当該要素の実機計測

- `page.evaluate(() => { ... })` で `getComputedStyle` / `getBoundingClientRect` を取得
- 擬似インターフェース: `measureElementPx(selector, props)` — 指定セレクタの computed style + bbox を返す
- 採取項目（最低限）:
  - font-size / color / padding / margin / border / width / height
  - bbox（x / y / width / height）
- source 側の `migration-spec.md` と **同じ項目** を採取する（差分が見えるように）

### Step 5: スクショ取得 + side-by-side 比較

- target の現状スクショを取得（`page.screenshot({ clip: bbox })`）
- source の同要素スクショと並べる（事前に `migration-spec-capture` 時に取得済みのものを使う）
- 擬似インターフェース: `screenshotPair(sourceUrl, targetUrl, selector)` — 両 URL の同セレクタを並べたスクショを生成
- 出力先: `.dev-agent-team/runs/{issue-id}/screenshots/`（コミット禁止）

### Step 6: 数値 + 画像で報告

- 報告フォーマット:
  ```
  ## {selector} 検証結果
  - 修正内容: {1 行}
  - 計測値:
    - source: font-size 26px / color #353535 / padding 0 0 4px 0
    - target: font-size 26px / color #353535 / padding 0 0 4px 0
  - 差分: なし / あり ({項目} が {値} 違う)
  - スクショ: .dev-agent-team/runs/{issue-id}/screenshots/{selector}-{timestamp}.png
  - 判定: 完了 / 追加修正必要
  ```
- ユーザに「目視で確認してください」と丸投げしない。**計測値で判定** したうえで、最終判断のためにスクショを添える

## サポート操作の擬似インターフェース

実装担当（Claude）が Playwright MCP で実行する操作の **抽象名**。実コードではなく「やりたいこと」を共通語彙にする目的:

| 名前 | 機能 | 内部実装イメージ |
|---|---|---|
| `cacheBustReload(url)` | キャッシュバイパスで再読込 | `route('**/*', r => r.continue({ headers: { ...r.request().headers(), 'Cache-Control': 'no-cache' } }))` + `goto(url)` |
| `measureElementPx(selector, props)` | 要素の computed style + bbox を返す | `page.evaluate((s, p) => { const el = document.querySelector(s); const cs = getComputedStyle(el); return { ...Object.fromEntries(p.map(k => [k, cs[k]])), bbox: el.getBoundingClientRect() }; }, selector, props)` |
| `screenshotPair(sourceUrl, targetUrl, selector)` | 同要素を 2 URL で並べる | 2 ブラウザコンテキストで開き、両方の `screenshot({ clip: bbox })` を取得 → Pillow / sharp で横並びに合成 |
| `waitForRebuild(bundlePath)` | bundle の mtime 更新を待つ | `until` ループで `stat` 比較。タイムアウト 30s |

## 注意

- **本番 URL を target にしない**（誤って本番にスクショアクセスを記録するリスク）。dev / staging のみ
- 採取結果（スクショ含む）に **個人情報** が映り込む場合は、採取前にダミーデータに差し替える
- 検証ループを **CI で自動実行する** わけではない。Phase 5 中の人間 + AI の協調作業で、1 修正ごとに通す
- Playwright MCP が複数の dev server に並列でアクセスできない場合は、`screenshotPair` を 2 シリアル実行に分ける

## Stop Conditions

以下のいずれかに該当したら **完了報告しない**:

- Step 2（rebuild 完了確認）をスキップして Step 3 以降を実行した
- Step 4 で計測値を取得せず、Step 5 のスクショだけで判定しようとしている
- 計測値で source / target に差分が出ているのに「目視では同じに見える」で完了扱いにしようとしている
- target が production URL を指している
- 採取結果に個人情報が含まれているが、マスク / 差し替えが未対応

## このスキルが想定する使い方

- Phase 5（Safe Implementation）で `commands/safe-implement.md` から呼ばれる
- Migration / UI Replica 種別では **必須**、それ以外の UI 変更タスクでも **強く推奨**
- 検証結果は Phase 7（Review Gate）で PR 説明文に **差分計測表** として転記する（重要な差分のみ）
- 一連の検証ログは `.dev-agent-team/runs/{issue-id}/verification-log.md` に時系列で残す

> 「実装したけど反映されない」「思ったのと違う」を、目視ではなく計測値で 1 サイクル以内に決着させるためのスキルです。
