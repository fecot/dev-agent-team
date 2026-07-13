# Skill: Legacy Modernization

## Purpose

レガシーアプリケーションを **段階的に育てる** ためのスキルです。既存コードを一気に Clean Architecture 化するためのものではなく、**既存構造を尊重しながら変更のたびに少しずつ境界を作り、将来の完全リプレイスや段階的移行に備える** ための型を提供します。

このスキルが目指すもの:

- レガシーアプリを **壊さず** 変更する
- 既存の Controller / Model / View / Service 構造を **尊重** する
- 新規ロジックは可能な範囲で **フレームワーク依存を薄く** する
- 将来のリプレイス時に **移行しやすい形** にする
- 変更ごとに **リプレイスのための知識を回収** する
- **既存仕様をドキュメント化しながら** 開発を進める

理想設計を持ち込んで一気に書き直すのではなく、**触る場所だけ少しずつ整える**。それが10回・100回と積み重なったとき、リプレイス計画が現実味を帯びてくる、という方針です。

## When to Use

以下のようなケースで使う:

- 古い MVC フレームワークや独自フレームワークのアプリケーション改修
- Controller が肥大化している機能の修正
- Model に業務ロジックと DB アクセスが混在している機能の修正
- View / Template に条件分岐や業務ロジックが入り込んでいる画面の修正
- Service があるが責務が曖昧になっているアプリケーションの修正
- 最終的にはリプレイス予定だが、当面は既存フレームワーク上で改修が必要な場合
- 既存機能を触るついでに、将来移行しやすい境界を作りたい場合

新規アプリケーションや、すでに Clean Architecture / Hexagonal Architecture などで設計されたアプリケーションには **使う必要がありません**。そちらは既存設計を素直に踏襲してください。

## Core Policy

レガシー改修時の行動原則です。**順序が重要** で、上から順に優先します。

- **既存構造を尊重する** — まずレガシーの作法を理解し、その作法で書けるかを最初に検討する
- **既存挙動を壊さない** — 構造改善より挙動維持が優先
- **大規模な構造変更を勝手に行わない** — 変更対象外のファイルに手を入れない
- **レガシーを一気に理想設計へ変えようとしない** — 1回の PR で全部直さない
- **新規ロジックは Controller に直接ベタ書きしない** — 増殖を止めるところから始める
- **Controller は入力取得・認可確認・Service 呼び出し・レスポンス生成に寄せる** — 業務処理を Controller に書かない
- **Service はユースケース単位の業務処理を担当する** — 「画面 = Service」ではなく「ユースケース = Service」で考える
- **Model は DB アクセスや既存 ORM 互換を中心に扱う** — 業務ロジックを Model に増やさない
- **View / Template に新しい業務ロジックを追加しない** — 表示判断のみに留める
- **フレームワーク依存は境界に閉じ込める** — Controller / Adapter / Repository の層に集約
- **変更対象外の古い実装を勝手に掃除しない** — 触る理由がないコードは触らない
- **新しい設計思想を持ち込む場合でも、既存チームが理解できる範囲に留める** — DDD 用語・クリーンアーキテクチャ用語を多用しない

## Recommended Change Options

レガシー改修時は、`workflows/feature-development.md` Phase 4（Implementation Planning）で **必ず以下の3案を出して** ください。dev-agent-team の標準ルール（最小変更案を必ず含める）を、レガシー文脈に特化させたものです。

### Option A: Minimal Change

- 既存構造内で **最小限の変更** を行う
- 既存の Controller に1行追加、既存の Model に1メソッド追加、のような触り方
- 影響範囲を最小化する
- リリース優先・hotfix 寄りの修正に向く
- **ただし、構造改善は限定的**
- リプレイス時の負債は変わらない or わずかに増える

### Option B: Local Cleanup

- 既存構造を尊重しながら、**Controller 肥大化や重複を軽く整理** する
- 業務処理を Service や専用クラスに寄せる
- 既存チームが読んだときに「いつもの書き方の延長」と感じられる範囲に留める
- 変更対象外の大規模整理は行わない
- 案A よりは行数が増えるが、レビュー負荷が大きく上がらない範囲
- リプレイス時の負債が **少し減る**

### Option C: Replacement-Ready Boundary

- 将来のリプレイスに備えて、**業務ロジックをフレームワーク依存から分離** する
- `SearchCondition` / `ValueObject` / UseCase-like Service / Adapter など、**小さな境界** を作る
- 外部依存・DB 依存・フレームワーク依存を業務ロジックに広げない
- ただし **大規模な再設計やディレクトリ大移動はしない**
- 設計用語を導入する場合は、PR 説明やコメントで「なぜこの境界を作ったか」を説明する
- **採用には人間判断を必要とする**（既存チームへの説明責任が発生するため）
- リプレイス時の負債が **明確に減る**

3案を出した上で、現場の状況（リリース時期 / レビュー体制 / リプレイス計画の進捗）に応じて **人間が** どれを採用するか判断します。

## Generic MVC Legacy Guidance

古い MVC / 独自 MVC アプリケーションを想定した、より具体的な指針です。

### Controller

- request / session / auth / response / view rendering などの **フレームワーク依存を Controller に閉じ込める**
- 入力バリデーションは Controller で行うか、専用の Validator に出す
- 業務分岐・計算・データ整形を Controller に書かない
- 認可ルールは Controller の入口でチェックする

### Service

- **ユースケース単位** の業務処理を担当
- 1メソッド = 1ユースケース のイメージ（厳密な単位ではなく、目安）
- request / response オブジェクトを直接受け取らない（Plain な引数 or DTO に変換してから渡す）
- DB アクセスは Model 経由に寄せる

### Model

- 既存 DB アクセス・既存 ORM 互換を **尊重**
- レガシーの Active Record パターンを無理に剥がさない
- ただし、業務処理（複数モデルにまたがる集計・複雑な条件分岐）を Model に新規追加しない

### Search / Condition / DTO

- 新規の業務条件は **Condition / Criteria / ValueObject / DTO** などに切り出せるか検討する
- request パラメータをそのまま Service に渡さない
- request → Condition への変換を Controller / Adapter で行い、Service は Condition だけを知る

### View / Template

- **表示以外の判断ロジックを増やさない**
- 「権限ごとに分岐して、特定ユーザーには別データを出す」のような分岐は Controller / Service 側に出す
- HTML 生成・整形・i18n のみに留める

### 持ち込まないもの

- raw query / request helper / global state / framework facade などを **業務ロジックの深い場所に広げない**
- 既存のグローバル状態（DB セッション・現在ユーザー・現在リクエスト）を Service の引数経由に変える努力を1回ごとに少し積む

### 命名

- **既存の命名規則に合わせる**
- 新しい設計を持ち込む場合も、**既存アプリケーションの読み手が理解できる名前** にする
- DDD 用語（Aggregate / Specification / DomainEvent 等）を多用しない。意味が伝わるなら平易な名前で十分
- 既存の Service や Model がある場合は、**まず責務と利用箇所を調べる**

## Characterization Test

既存挙動を守るため、**変更前** に可能な範囲で Characterization Test（仕様化テスト）を検討してください。

### 観点

- **今の入力に対して今の出力を固定** する（テストは「正しい挙動」ではなく「現状の挙動」を記録するためのもの）
- 正しいかどうかより、**まず既存挙動を記録** する。間違っていたとしても、まず固定してから直す
- 既存仕様が不明な場合は、**テストまたは手動確認観点として残す**
- テストが書けない場合は、**確認観点を PR に明記** する

### 種別ごとの観点

- **画面**: 変更前後の表示・検索条件・エラー表示・権限ごとの差分を確認する
- **API**: リクエスト/レスポンス契約・ステータスコード・エラーボディの形を固定する
- **バッチ**: 入力データ・出力データ・副作用・**再実行時の挙動**（冪等性）を確認する
- **連携処理**: 外部サービス呼び出しの順序・リトライ挙動・タイムアウトを確認する

### Characterization Test と回帰防止の関係

Characterization Test は「既存挙動を直す前に固定する」ものです。直したい挙動があるなら、

1. まず現状の挙動を Characterization Test で固定
2. その上で「直す」変更を行い、テストを修正する
3. PR で「ここが既存挙動、ここが今回直したい挙動」を明示する

の順で進めます。これによって、**意図せず壊れたのか、意図して直したのか** をレビュー時に区別できます。

## Replacement Notes

PR 説明や Artifacts に、以下の **Replacement Notes** を残してください。これは「将来のリプレイス担当者への手紙」です。

- **今回確認した既存仕様** — 触りながら判明した暗黙の仕様
- **今回分離した業務ロジック** — Controller / Model / View から剥がして Service / Condition / DTO 等に移したもの
- **将来リプレイス時に移行しやすくなった箇所** — フレームワーク依存が剥がれた箇所
- **まだレガシーフレームワーク依存が残っている箇所** — 今回は触らなかったが、いつか分離したい箇所
- **次回以降に切り出せそうな箇所** — 次に同じ機能を触るときの目印
- **触らなかった理由** — スコープ外と判断した範囲とその根拠
- **既存仕様として残すべき注意点** — 直感に反する挙動・歴史的経緯のある挙動
- **リプレイス時に再確認すべき外部依存や DB 依存** — マイグレーションが絡む依存

Replacement Notes は **PR 本文に直接書く** か、`.dev-agent-team/runs/{issue-id}/replacement-notes.md` に分けて書きます。**毎回少しずつ書き溜める** ことに意味があります。一度に大きな設計書を作る代わりに、変更のたびに数行ずつ残し、それを将来のリプレイス計画の素材にします。

## Stop Conditions

以下のいずれかに該当したら **進めない**。`workflows/feature-development.md` の各 Phase Stop Condition と併せて評価します。

- 既存挙動が分からないまま変更しようとしている
- 影響範囲が Controller / Model / View / Service をまたぐのに、調査が不足している
- 大規模リファクタリングを伴うのに **人間承認** がない
- DB 変更や認証・権限変更を伴うのに **Project Rules が不明**
- リプレイス準備の名目で **既存仕様を勝手に変えようとしている**
- フレームワーク依存を分離するつもりが、逆に **依存を広げている**
- **テストまたは手動確認観点がない**
- 既存チームが理解できない新設計を、**説明なしに** 導入しようとしている

## Output Format

このスキルを使った場合、以下の形式で出力してください。`workflows/feature-development.md` の Phase Execution Format に乗る前提で、Phase 3〜4 で特に活用します。

```
## Legacy Modernization Output

### Legacy Context
{{対象アプリの構造（MVC / 独自 / 混在）/ 主要レイヤー / 採用 ORM / フレームワーク特性}}

### Existing Behavior
{{今回の変更対象が現在どう動いているか / 暗黙仕様 / 確認できた範囲とできなかった範囲}}

### Impact Scope
- Controller: {{}}
- Model: {{}}
- View / Template: {{}}
- Service: {{}}
- DB: {{}}
- 外部連携: {{}}

### Change Options

#### Option A: Minimal Change
- 概要: {{}}
- 変更ファイル: {{}}
- メリット: {{}}
- デメリット: {{}}
- リプレイス時の負債変化: なし or 微増

#### Option B: Local Cleanup
- 概要: {{}}
- 変更ファイル: {{}}
- メリット: {{}}
- デメリット: {{}}
- リプレイス時の負債変化: 少し減る

#### Option C: Replacement-Ready Boundary
- 概要: {{}}
- 変更ファイル: {{}}
- 作る境界: {{Condition / ValueObject / UseCase Service / Adapter}}
- メリット: {{}}
- デメリット: {{}}
- リプレイス時の負債変化: 明確に減る

### Recommended Option
{{A / B / C のどれを推奨するか、その理由}}

### Required Human Decision
- {{採用案の選択}}
- {{Option C を採用する場合は、新設計の名前・配置の合意}}

### Test / Characterization Plan
- 既存挙動の固定対象: {{}}
- テスト可能な範囲: {{単体 / 結合 / E2E / 手動}}
- 手動確認観点（テスト不能な箇所）: {{}}

### Replacement Notes
- 今回確認した既存仕様: {{}}
- 今回分離した業務ロジック: {{}}
- 移行しやすくなった箇所: {{}}
- まだレガシー依存が残っている箇所: {{}}
- 次回以降の切り出し候補: {{}}
- 触らなかった理由: {{}}
- 既存仕様として残すべき注意点: {{}}

### Risks
| リスク | 深刻度 | 対策 |
|---|---|---|
| {{}} | 高/中/低 | {{}} |

### Stop Condition Check
- 既存挙動の把握: Pass / Fail
- 影響範囲調査の十分性: Pass / Fail
- 大規模リファクタリングの人間承認: Pass / Fail / N/A
- DB / 認証・権限変更時の Project Rules 確認: Pass / Fail / N/A
- 既存仕様を勝手に変えていないか: Pass / Fail
- 依存を逆に広げていないか: Pass / Fail
- テスト / 手動確認観点の存在: Pass / Fail
- 新設計の説明: Pass / Fail / N/A
```

## このスキルが想定する使い方

- Phase 2（Discovery）で、レガシーアプリだと判断したらこのスキルを **追加で参照** する
- Phase 3（Impact Analysis）で、`Impact Scope` セクションに従って Controller / Model / View / Service の観点で影響を整理する
- Phase 4（Implementation Planning）で、上記 3案（Minimal / Local Cleanup / Replacement-Ready）を必ず提示する
- Phase 5（Safe Implementation）で、Core Policy と Generic MVC Legacy Guidance に従って実装を進める
- Phase 7（Review Gate）で、PR 本文に **Replacement Notes** を含める

> 一気に直さない。触る場所だけ少しずつ整える。それを積み上げていく。
