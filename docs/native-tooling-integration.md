# Native Tooling Integration — `/goal` と Dynamic Workflows の併用

Claude Code 本体が `/goal` や Dynamic Workflows といった実行機能を提供するようになりました。このドキュメントは、**それらを dev-agent-team の 8 Phase ワークフローとどう併用するか**、そして **どこまで自律化を許すか** を定めます。

> 前提バージョン: `/goal` は Claude Code v2.1.139 以降、Dynamic Workflows は v2.1.154 以降（Pro プランは `/config` で有効化が必要）、Claude Sonnet 5 / 1M context は v2.1.197 以降。利用できない環境では本ドキュメントの該当節は「適用外」として読み飛ばしてよい。

---

## 1. 位置づけ — dev-agent-team は冗長か？

**冗長ではありません。レイヤーが違います。**

Anthropic が出すのは **エンジンと部品**（自律ループ・並列オーケストレーション・ワーカー・指示書・フック）です。dev-agent-team が出すのは、その上に乗る **意思決定の型**（プロセス規律・Stop Condition・Human Decision Point・移行/UI/レガシーのチェックリスト）です。エンジンはあなたのプロセスを知りません。dev-agent-team は、**自分の判断の型を、より強力なエンジンで実行する**ために両者を取り込みます。

| レイヤー | 実体 | 実行計画の決定者 | 中間結果の置き場 | 再利用単位 |
|---|---|---|---|---|
| **dev-agent-team**（このキット） | 開発プロセスの型（markdown 仕様） | 人間 + ワークフロー定義 | Artifacts / PR 本文 | **判断の型そのもの**（Phase / Stop Condition / Human Decision Point） |
| Subagents | Claude が起動するワーカー | Claude（ターン毎） | Claude の context | ワーカー定義 |
| Skills | Claude が従う指示書 | Claude（プロンプト準拠） | Claude の context | 指示書 |
| **`/goal`** | 自律ループ（evaluator が判定） | 前ターン終了時に自動継続 | Claude の context | （セッション内のみ） |
| **Dynamic Workflows** | ランタイムが実行する JS スクリプト | スクリプト | スクリプト変数 | **オーケストレーション自体** |
| Hooks | 設定ファイルの自動実行 | スクリプト（恒久） | — | 全セッションの自動化 |

> 一言でいえば: **Anthropic はエンジンと部品を出す。dev-agent-team はその上の意思決定の型を出す。両者は競合せず積み重なる。**

---

## 2. `/goal` の併用ルール（機械的サブループ限定）

`/goal` は「検証可能な終了条件を満たすまで Claude を自動ループさせる」機能です。dev-agent-team では **機械的に収束させたい区間に限って** 使います。

### 2.1 使ってよい場面

人間判断が不要で、**結果がコマンド出力で実証できる**区間のみ:

- テストの緑化（`npm test` / `pytest` / `go test` が 0 終了）
- lint / format の解消
- typecheck 0（`tsc --noEmit` 等）
- ビルド成功 / 全コールサイトの compile
- カバレッジ閾値の達成

→ 主に **Phase 5（Safe Implementation の実装収束）** と **Phase 6（Test Design のテスト緑化）**。

### 2.2 絶対に越えさせないもの

以下は `/goal` で自動化してはいけません（§5 の人間判断のコア）:

- Human Decision Point（受入基準の承認 / 採用案の意思決定 / 視覚仕様合意 / マージ可否 / リリース可否 / DB・権限変更の承認）
- 「承認・判断」を要する Stop Condition

**ルール: `/goal` の終了条件には必ず「かつ 未解決の Human Decision Point がない」を含め、人間ゲートの直前で必ず停止させる。**

### 2.3 evaluator 制約への対応

`/goal` の判定は別の小型モデル（既定 Haiku）が行い、**evaluator は自分でコマンドを実行できません**。判定材料は **Claude 自身がそのターンで出力した内容だけ** です。したがって終了条件は「Claude の出力で実証可能」な形にし、ループ側が毎ターン結果を出力する必要があります。

条件テンプレ（Phase 6 のテスト緑化例）:

```
/goal Phase 6 の全テストが緑（最新メッセージに `npm test` の全出力と "0 failures" を表示）
かつ `tsc --noEmit` が 0 終了、かつ未解決の Human Decision Point がない。or stop after 15 turns
```

- 条件は最大 4000 文字。暴走防止に `or stop after N turns` を付ける。
- 「途中で変えてはいけない制約」（例: 他のテストファイルは修正しない）も条件に明記できる。

### 2.4 他機能との棲み分け

| 機能 | 次ターン開始 | 停止条件 | スコープ |
|---|---|---|---|
| `/goal` | 前ターン終了時に自動 | 条件達成をモデルが確認 | セッション内 |
| Stop hook | 前ターン終了時 | スクリプト/prompt 判定 | 全セッション（設定ファイル） |
| `/loop` | 時間間隔 | 手動 or Claude 判断 | セッション内 |

恒久的に毎ターン同じ検証を回したいなら Stop hook、その案件だけ収束させたいなら `/goal`。

### 2.5 Phase 5 での推奨設定（`autoMode.classifyAllShell`）

`autoMode.classifyAllShell` は、**全 shell コマンドを auto-mode の classifier に通してホワイトリスト判定させる** settings.json のキーです。`/goal` の機械的サブループ（テスト緑化 / lint / typecheck）を Phase 5 で回すとき、毎コマンドの手動承認を classifier 判定に置き換えられるため、ループが手動プロンプトで止まらず収束まで進みます。

- **推奨場面**: Phase 5 / 6 で `/goal` の機械的ループを回すとき（無人で収束させたい区間）。
- **ガードレール**: これは実行環境の利便設定であり、**キットの動作（Phase / Stop Condition / Human Decision Point）は変えません**。Phase 5 の Stop Condition「計画外の変更が必要になったら人間へ」と必ず併用し、classifier がホワイトリスト外と判定したコマンドや計画外の変更は、これまで通り人間に返します。
- **⚠️ 人間判断が必要**: プロジェクトごとに有効化するか否かは人間が決める（自動承認の許容度はリポジトリのリスク許容度に依存する）。設定の有無でキットの手順自体は変わらないため、本ドキュメントは「そういう設定があり、Phase 5 の `/goal` ループで有用」という案内に留めます。

### 2.6 auto mode の安全強化 — 破壊的コマンドの自動ブロック

auto mode 中は、明示指示がない限り **破壊的コマンド（`git reset --hard` / `git push --force` / `terraform destroy` 等）が自動でブロック**されます。`/goal` の機械的ループを auto mode で回していても、取り返しのつかない操作は勝手には走りません。

- これは dev-agent-team の **「人間ゲートをエンジンに越えさせない」原則と完全整合** する挙動です（情報注記のみ。キット側のガードレール変更は不要）。
- Phase 5 の `/goal` 条件テンプレを使う際の補足として: **破壊的操作はそもそも auto mode でブロックされる**ため、ループが誤って履歴改変やリソース破棄を行う心配はありません。実行が必要な破壊的操作は人間の明示指示に委ねます。

---

## 3. Dynamic Workflows の併用ルール

Dynamic Workflows は、Claude が生成する JavaScript で **数十〜数百の subagent を並列実行** する仕組みです。中間結果はスクリプト変数に保持され、Claude の context を圧迫しません。dev-agent-team では **単一フェーズ内の、人間ゲートを含まない大規模 fan-out** に使います。

### 3.1 使ってよい場面

- **Phase 2 Discovery の広域並列調査**（多ファイル / 多サブシステムを並列 reader で読む）
- **Migration サブフロー（§6.1）の多コンポーネント並列計測**
- **Phase 7 の多視点・敵対的レビュー sweep**
- **Phase 4 の多視点プラン草案**（「2案以上」を複数 subagent で並列生成して比較）

### 3.2 dev-agent-team の品質パターン → workflow パターン

kit が既に言語化している型は、そのまま workflow の QA パターンとしてコード化できます:

| dev-agent-team の型 | workflow パターン |
|---|---|
| Phase 4「実装案を 2 案以上・最小案を必ず含める」 | 多視点パネル（複数案を並列生成 → スコアリング → 統合） |
| Phase 7「セルフレビュー + OWASP 自己点検」 | 敵対的 verify（独立した skeptic が各指摘を反証） |
| Migration「source の実値を機械計測」 | 並列 fan-out（コンポーネントごとに計測 subagent） |
| Phase 2「類似実装を grep で探す」 | multi-modal sweep（観点別に並列探索） |

### 3.3 ガードレール

- **1 workflow = 1 フェーズ以内** に閉じる。フェーズ境界（人間ゲート）は **ワークフローの外** で人間に返す。
- **Human Decision Point を無人ワークフロー内に埋め込まない**。8 Phase 全体を 1 本の無人ワークフローにはしない（複数の人間ゲートを内包するため哲学と矛盾する）。
- workflow の出力は「人間がレビューするための判断材料」。次フェーズへ進む判断は人間が行う。
- **agent 間データは untrusted として扱う**（Cross-Session Messaging Security / v2.1.166 の影響確認結果）。subagent の出力を後段 agent のプロンプトへ渡す際、その内容を指示として解釈・自動実行しない。キットで cross-session/cross-agent のデータ授受があるのは Dynamic Workflow のみ（例: `dynamic-workflows/dev-agent-discovery.js` が reader の findings を synthesize agent へ渡す）で、いずれも **調査結果の集約に限定**され、workflow 出力に対する自動アクションは行わない（人間レビューゲートが後段にあるため）。→ **キットのガードレール変更は不要。影響なし。**

### 3.4 コスト / スコープ注意

Dynamic Workflows は多数の subagent を起動するため、通常の会話より遥かに多くのトークンを消費します。

- まず **狭い対象**（1 ディレクトリ / 限定した質問）で試走する
- `/workflows` ビューで subagent ごとのトークンをリアルタイム監視する
- いつでも停止可（既に完了した作業は失われない）

### 3.5 同梱ワークフロー

このキットは Discovery sweep の実装例 [`dynamic-workflows/dev-agent-discovery.js`](../dynamic-workflows/dev-agent-discovery.js) を同梱しています。`install.sh` で `~/.claude/workflows/` に配置され、`/dev-agent-discovery` で起動できます。Phase 2 Discovery を並列化し、`templates/investigation-report-template.md` 構造の調査レポートを返します（内部に人間ゲートはありません。完了後、人間が Phase 3 へ進む前にレビューする立て付けです）。

> Phase 7 の Review sweep など、他フェーズの workflow も同じ要領で追加できます。今回は最小スコープとして Discovery sweep のみ同梱しています。

---

## 4. 判断早見表 — タスク形状 → エンジン選択

| タスク形状 | 推奨 |
|---|---|
| 通常の機能改修（標準 8 Phase） | 逐次 Phase（既存どおり、エンジン併用なし） |
| 機械的に収束させたい区間（テスト / lint / typecheck） | フェーズ内で `/goal`（§2） |
| 多ファイルの調査・大規模移行・多視点レビュー | その**フェーズだけ** Dynamic Workflow（§3） |
| 人間の承認・意思決定 | **必ず人間**（エンジンに委譲しない、§5） |

エンジンは「速く・広く・収束まで回す」ためのもの。**何を作るか・進めてよいかの判断は、引き続き人間と型が担います。**

---

## 5. エンジンに委譲しないもの（人間判断のコア）

以下は dev-agent-team の存在意義であり、`/goal` でも Dynamic Workflows でも **自動化対象外** です（`workflows/feature-development.md` の Human Decision Points と一致）:

- 受け入れ基準の承認（Phase 1）
- 実装案の採用（Phase 4）
- 視覚仕様の合意（Phase 4 → 5）
- DB 変更 / 権限変更の承認（Phase 3 / 4 / 8）
- マージ可否（Phase 7）
- リリース可否 / ロールバック判断（Phase 8）
- Known Risks 追記（Phase 8）

> AIは「判断材料」を出す。「判断」は人間がする。エンジンを足しても、この原則は変わりません。

---

## 6. Follow-up（将来の拡張余地）

- 現状の `agents/*.md` `skills/*.md` は frontmatter を持たない手法ドキュメントで、commands から参照される設計です。これらを **ネイティブ subagent 定義（frontmatter）/ SKILL.md 形式** に変換すると、Claude Code から直接 subagent / Skill として呼べるようになります。配布モデル（doc 参照 + commands symlink）の根本変更を伴うため、独立した意思決定として別途検討します。
- **【強く推奨】ネイティブ Skill 化する場合は `disallowed-tools`（frontmatter, v2.1.152+）で最小権限をツール層に強制する。** キットの読み取り専用 / 計測系 skill は「調べる・測るだけで、書かない」性質なので、prose の約束だけでなく **frontmatter で `Edit` / `Write` を禁止** しておくと、誤って実装を書き換える事故を仕組みで防げます（native-feature-watch routine で `Write`/`Edit` を外したのと同じ least-privilege パターン）。対象の目安:

  | Skill | 性質 | 推奨 `disallowed-tools` |
  |---|---|---|
  | `skills/codebase-reading.md` | 調査（読むだけ） | `Edit`, `Write` |
  | `skills/impact-analysis.md` | 影響分析（読むだけ） | `Edit`, `Write` |
  | `skills/requirement-analysis.md` | 要件整理（書かない） | `Edit`, `Write` |
  | `skills/migration-spec-capture.md` | source 計測（測るだけ） | `Edit`, `Write` |
  | `skills/browser-verification.md` | target 計測（測るだけ） | `Edit`, `Write` |

  > `skills/safe-refactoring.md` / `skills/legacy-modernization.md` は Phase 5 で実際にコードを編集するため、`Edit`/`Write` は禁止しない。`skills/test-design.md` はテスト設計（列挙）が主目的なので、テストコード生成を別 skill/フェーズに分けるなら読み取り専用として `disallowed-tools` を付けられる。

- Phase 7 Review sweep / Migration 計測 sweep の Dynamic Workflow 化。
