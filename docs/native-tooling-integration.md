# Native Tooling Integration — ネイティブ実行エンジンとの併用

Claude Code 本体が `/goal`・Dynamic Workflows・Agent Teams といった実行機能を提供するようになりました。このドキュメントは、**それらを dev-agent-team の 8 Phase ワークフローとどう併用するか**、そして **どこまで自律化を許すか** を定めます。

> 前提バージョン:
> - `/goal`: Claude Code v2.1.139 以降
> - Dynamic Workflows: v2.1.154 以降（Pro プランは `/config` で有効化が必要）
> - Claude Sonnet 5 / 1M context: v2.1.197 以降
> - `/review`（シングルパス）と `/code-review <level>`（多エージェント）の分離: v2.1.202 以降（v2.1.186〜201 は `/review` が `/code-review medium` 相当に統合されていた）
> - Agent Teams: 実験的機能（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` で有効化。v2.1.178 時点の仕様で、TeamCreate/TeamDelete 廃止のような破壊的変更が既に発生しており仕様変動リスクあり）
>
> 利用できない環境では本ドキュメントの該当節は「適用外」として読み飛ばしてよい。

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

### 1.1 エージェンシー・ラダー — 「AI がどこまで先に動くか」で機能を並べる

Claude 系機能は「**AI の自律度（エージェンシー）**」で 3 段に整理できる。段が上がるほど AI が先に動き、人間の関わりは「操作」から「確認」へ移る。

| 段 | 性質 | 代表機能 | この段の本質 |
|---|---|---|---|
| **Tier 1** | 人間起点 | Projects / Artifacts / Adaptive Thinking | AI は便利になるが、**仕事の進め方自体は変わらない**（人間が毎回動かす） |
| **Tier 2** | 継続学習 | Memory / CLAUDE.md / Roles | AI が **あなたの文脈を継続的に学習**し、指示の反復が減る |
| **Tier 3** | AI 起点 | Skills / Code / Scheduled Tasks / Dynamic Workflows / `/goal` / Agent Teams（実験的機能） | **AI が先に動き、人間は確認する**（自律ループ・並列実行・定期実行） |

> 出典: 「1%しか知らない Claude の 17 機能」（[@swarm_japan](https://x.com/swarm_japan/status/2060287955533738127) / 元 [@AnatoliKopadze](https://x.com/AnatoliKopadze/status/2057813254617858078)）の「エージェンシーで機能を並べる」枠組みを、dev-agent-team の対象（Claude Code の開発プロセス）に絞って再構成したもの。コンシューマ製品側の機能（Cowork / Chrome 拡張 / Design 等）は本キットの射程外なので割愛している。

**dev-agent-team の立ち位置**: 本キットが効くのは **Tier 3** だ。`/goal`・Dynamic Workflows・Scheduled routine はどれも Tier 3（AI 起点）のエンジンで、放っておくと「AI が先に動く」勢いのまま **人間の確認ゲートも飛び越えかねない**。dev-agent-team は Tier 3 に **「AI が先に動いてよい区間」と「必ず人間が確認する区間（Human Decision Point）」の線引き** を持ち込む。つまり本キットは、**確認ゲート付きで Tier 3 を安全に使うための型**である。§2（`/goal`）・§3（Dynamic Workflows）の併用ルールは、この線引きを機能別に具体化したものだ。

**導入の順番**: 17 機能を全部覚える必要はない。**いま自分がどの段にいるかを見極め、1 つ上の段の機能を 1 つ身につける** のが実務的だ。dev-agent-team の段階導入も同じで、まず Tier 2（CLAUDE.md / project-rules で文脈を固定）を整え、その上で Tier 3 のエンジン併用（§2 / §3）へ進むと破綻しにくい。

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

恒久的に毎ターン同じ検証を回したいなら Stop hook、その案件だけ収束させたいなら `/goal`。なお公式ドキュメントの明記どおり、**`/goal` は本質的にセッションスコープの prompt-based Stop hook のラッパー**である（この対応関係が §2.7 の hooks 化の根拠になる）。

### 2.5 Phase 5 での推奨設定（`autoMode.classifyAllShell`）

`autoMode.classifyAllShell` は、**全 shell コマンドを auto-mode の classifier に通してホワイトリスト判定させる** settings.json のキーです。`/goal` の機械的サブループ（テスト緑化 / lint / typecheck）を Phase 5 で回すとき、毎コマンドの手動承認を classifier 判定に置き換えられるため、ループが手動プロンプトで止まらず収束まで進みます。

- **推奨場面**: Phase 5 / 6 で `/goal` の機械的ループを回すとき（無人で収束させたい区間）。
- **ガードレール**: これは実行環境の利便設定であり、**キットの動作（Phase / Stop Condition / Human Decision Point）は変えません**。Phase 5 の Stop Condition「計画外の変更が必要になったら人間へ」と必ず併用し、classifier がホワイトリスト外と判定したコマンドや計画外の変更は、これまで通り人間に返します。
- **⚠️ 人間判断が必要**: プロジェクトごとに有効化するか否かは人間が決める（自動承認の許容度はリポジトリのリスク許容度に依存する）。設定の有無でキットの手順自体は変わらないため、本ドキュメントは「そういう設定があり、Phase 5 の `/goal` ループで有用」という案内に留めます。
- **設定の置き場所**: autoMode 系設定はもともと共有プロジェクト設定（`.claude/settings.json`）からは読み込まれず、**v2.1.207 以降は repo 内の `.claude/settings.local.json` からも読み込まれません**。したがって有効化は各利用者が **自分のユーザー設定（`~/.claude/settings.json`）** で行います。「プロジェクトごとに有効化するか否かは人間が決める」は変わりませんが、その決定の実装先はユーザー設定です。

### 2.6 auto mode の安全強化 — 破壊的コマンドの自動ブロック

auto mode 中は、明示指示がない限り **破壊的コマンド（`git reset --hard` / `git push --force` / `terraform destroy` 等）が自動でブロック**されます。`/goal` の機械的ループを auto mode で回していても、取り返しのつかない操作は勝手には走りません。

- これは dev-agent-team の **「人間ゲートをエンジンに越えさせない」原則と完全整合** する挙動です（情報注記のみ。キット側のガードレール変更は不要）。
- Phase 5 の `/goal` 条件テンプレを使う際の補足として: **破壊的操作はそもそも auto mode でブロックされる**ため、ループが誤って履歴改変やリソース破棄を行う心配はありません。実行が必要な破壊的操作は人間の明示指示に委ねます。
- 分類器の soft block は明示的なユーザー意図で解除されうる「事故防止レイヤー」です。ユーザー意図に関わらず **絶対に走らせない境界** が必要な場合は、§5.2 の permissions.deny ルールで恒久固定します（分類器より前に評価される）。
- 用語注記: 既定の permission mode の名称は v2.1.200 で「**Manual**」に統一されました（`--permission-mode manual` / `"defaultMode": "manual"`。旧称 `default` も併用可）。

### 2.7 Stop Condition の hooks 化 — 〔機械検証可〕のみ

キットの Stop Condition のうち **〔機械検証可〕タグ付きのもの** は、hooks で「文書上の約束」から「機械的に強制されるゲート」へ昇格できます。

| 〔機械検証可〕Stop Condition の例 | hooks 化の形 |
|---|---|
| テストが緑化していない（0 failures 未達） | Stop hook（prompt-based）でテスト結果を判定し、未達なら停止を差し戻す |
| lint / typecheck が 0 でない | Stop hook（command）で lint / typecheck を実行し、非 0 終了で差し戻す |
| Phase 単位タスクのチェックリスト未充足 | TaskCompleted hook + exit 2 で完了をブロック |

- **〔人間判断〕タグの Stop Condition は hooks 化禁止**。自動判定に置き換えること自体が人間ゲートの代行になるため、受入基準の承認・採用案の意思決定・マージ / リリース可否などは hook にしません（§5 の人間判断のコア）。
- フィードバック文言は **具体的な合格条件** で書く（「テストを直す」ではなく「`npm test` の全出力に `0 failures` が表示されるまで停止しない」）。
- prompt-based hook の判定タイムアウトは既定 30 秒（利用時に公式 docs で再確認のこと）。
- `TaskCreated` / `TaskCompleted` は通常のタスクシステム（TaskCreate ツール。キットが Phase 単位タスク管理で既に使用）で発火し、**Agent Teams は不要**。`TeammateIdle` のみ Agent Teams（実験的機能）前提です。

---

## 3. Dynamic Workflows の併用ルール

Dynamic Workflows は、Claude が生成する JavaScript で **数十〜数百の subagent を並列実行** する仕組みです。中間結果はスクリプト変数に保持され、Claude の context を圧迫しません。dev-agent-team では **単一フェーズ内の、人間ゲートを含まない大規模 fan-out** に使います。

### 3.1 使ってよい場面

- **Phase 2 Discovery の広域並列調査**（多ファイル / 多サブシステムを並列 reader で読む）
- **Migration サブフロー（`workflows/feature-development.md` §6.1）の多コンポーネント並列計測**
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
- **公式裏付け**: 公式ドキュメントは「**mid-run のユーザー入力は不可 — ステージ間のサインオフが必要なら、各ステージを別ワークフローとして実行せよ**」（Behavior and limits: "No mid-run user input — For sign-off between stages, run each stage as its own workflow"）と明記している。キットの「1 workflow = 1 フェーズ」ルールは、この公式設計と一致する。
- **ultracode の線引き**: プロンプト内キーワード `ultracode`（v2.1.160 で `workflow` から改称）は **そのタスク 1 件だけ** をワークフロー化するオプトインであり、§3.1 の適用場面ならフェーズ内で使ってよい。一方 **`/effort ultracode`（v2.1.203+）はセッション中の全ての実質的タスクを自動でワークフロー化するモード** で、(i) auto permission mode ではワークフロー起動プロンプト自体がスキップされ、(ii) Large workflow 警告も表示されなくなる。したがって **Human Decision Point を含む 8 Phase 運用中のセッションでは有効化しない**。使う場合は単一フェーズ内の大規模 fan-out 作業に限定し、フェーズ境界前に `/effort high` 等へ戻す（設定はセッション限りで、新セッションではリセットされる）。

### 3.4 コスト / スコープ注意

Dynamic Workflows は多数の subagent を起動するため、通常の会話より遥かに多くのトークンを消費します。

- まず **狭い対象**（1 ディレクトリ / 限定した質問）で試走する
- `/workflows` ビューで subagent ごとのトークンをリアルタイム監視する
- いつでも停止可（既に完了した作業は失われない）
- **規模の調整ノブ**: `/config` の「Dynamic workflow size」（v2.1.202+）で fan-out 規模を環境側から調整できる。既定は unrestricted で、small / medium / large はそれぞれ 5 / 15 / 50 エージェント未満を目安として Claude に助言するもの（**強制上限ではなく**、プロンプトの指示が優先される。ランタイム上限の同時 16 / 総数 1,000 は別途適用）
- **Large workflow 警告**: 25 エージェント超または予測 150 万トークン超で進捗行に警告が出る（v2.1.203+。advisory であり実行は止まらない。size guideline 設定時は警告閾値がその値に置き換わり、ultracode 有効時は警告自体が出ない — §3.3 の線引き参照）

**fan-out の信頼性**（公式 CHANGELOG 確認済み）:

- subagent は既定でバックグラウンド実行になり、親は完了通知で合流する（v2.1.198。通常セッションの subagent 挙動であり、Dynamic Workflow スクリプト内の並列性自体は従来どおり）
- レートリミット / サーバーエラーで切断された subagent は **部分成果を親へ返し**、API エラーは成功として偽装されず親に正しく伝播する（v2.1.199 のバグ修正）
- これを根拠に、Discovery fan-out で一部 reader が失敗しても workflow を中断せず、**部分 findings を回収し、未調査サブシステム / ファイルを「欠落」として明記した上で** 人間レビューに回すことをリカバリ手順とする（実装例: `dynamic-workflows/dev-agent-discovery.js`）。欠落を隠して完全なレポートを装わない — 欠落自体が人間の判断材料である。

### 3.5 同梱ワークフロー

このキットは Discovery sweep の実装例 [`dynamic-workflows/dev-agent-discovery.js`](../dynamic-workflows/dev-agent-discovery.js) を同梱しています。`install.sh` で `~/.claude/workflows/` に配置され、`/dev-agent-discovery` で起動できます。Phase 2 Discovery を並列化し、`templates/investigation-report-template.md` 構造の調査レポートを返します（内部に人間ゲートはありません。完了後、人間が Phase 3 へ進む前にレビューする立て付けです）。

> Phase 7 の Review sweep など、他フェーズの workflow も同じ要領で追加できます。今回は最小スコープとして Discovery sweep のみ同梱しています。

### 3.6 モデル / effort の非対称配分 — 司令塔はセッションモデル、実装は effort:low

Dynamic Workflows の `agent(prompt, { model, effort })` は、エージェント単位でモデルと reasoning effort を指定できます。ここでの原則は 1 つ:

> **判断は上流（司令塔）に集約し、実装層から判断を排除する。**

これは本キットの「AIは判断材料、判断は人間」をエージェント階層に適用した相似形です — **人間 → 司令塔 AI → 実装 AI** の順に判断が減っていく構造にします。effort:low のエージェントは「指示を文字通り、過不足なく実行する」モードになるため、司令塔が判断を済ませた精密な指示リストを渡せば、実装層の品質差は実質的に消えます。

| 層 | model | effort | 理由 |
|---|---|---|---|
| **司令塔**（分解・判断・指示生成・集約） | **省略**（メインセッションのモデルを継承） | high〜xhigh | 司令塔の判断ミスは全実装に伝播する。削らない |
| **実装**（精密指示の機械的適用） | 省略 or 下位ティア（`sonnet` 等） | **low**（Sonnet 5 は medium が安全ライン） | 判断済みの指示なら effort:low で品質差が出ず、トークンコストが最小になる |
| **検証**（敵対的 verify・判定） | 省略 | high〜xhigh | 誤判定が下流に流れる層。削らない |

`model` の既定は省略 = セッションモデルの継承です。つまり **「Claude Code で使用中のモデルがそのまま司令塔になる」** — セッションを Fable / Opus / Sonnet のどれで動かしていても、この配分はそのまま機能します。

**effort:low の実装が成立する条件（＝司令塔側の責務）:**

1. **指示が自己完結** — 対象ファイル・変更内容・従うべき規約・「〜以外は触らない」まで明記する
2. **判断余地を残さない** — 「適切に」「いい感じに」を含めない。low は最も安全な解釈（最小限の変更）に倒れる
3. **機械的検証をセットで渡す** — `bash -n` / `node --check` / grep 確認を指示に含める
4. **報告義務を課す** — 「迷って変更しなかった箇所を理由付きで報告」させる（黙って省略させない）
5. **司令塔が差分レビュー** — low の失敗は「静かに浅い」。diff 確認は司令塔側の必須工程

条件を満たさないタスク（判断・複数ファイルの整合調整が混ざる実装）は effort かティアを上げます。**コスト削減はまず実装層で行い、司令塔・検証層は削らない** — 実装の失敗はリトライで済むが、司令塔・検証の失敗は下流全体に伝播するという非対称性が根拠です。

> 補足: 同梱の `dev-agent-discovery.js` はこの配分を実装しています（reader = 機械的抽出なので低 effort、scope / synthesize = 判断層なのでセッション effort を継承）。なお Agent Teams / 通常の Task subagent には per-agent の effort 指定がない（セッション設定を継承する）ため、この細粒度配分は Dynamic Workflows 固有の利点です。

---

## 4. 判断早見表 — タスク形状 → エンジン選択

| タスク形状 | 推奨 |
|---|---|
| 通常の機能改修（標準 8 Phase） | 逐次 Phase（既存どおり、エンジン併用なし） |
| 機械的に収束させたい区間（テスト / lint / typecheck） | フェーズ内で `/goal`（§2） |
| 多ファイルの調査・大規模移行 | その**フェーズだけ** Dynamic Workflow（§3） |
| 精密指示済みの機械的実装（fan-out 内） | 実装エージェントを **effort:low** で回す（§3.6）。指示の精密化と差分レビューは司令塔（セッションモデル・high 以上）が担う |
| 多視点コードレビュー | ネイティブ `/code-review <level>`（指摘生成、v2.1.202+）。キット固有観点の敵対的 sweep は Dynamic Workflow（§3）。判定材料の整理はキット `/pr-review`、マージ可否の判断は人間 |
| 相互に議論・反証が必要な並列調査 / レビュー（競合仮説デバッグ等） | Agent Teams（§6、実験的機能）。単一フェーズ内に閉じ、フェーズ間の Human Decision Point はリードセッションで人間が承認 |
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

### 5.1 人間ゲートのランタイム裏付け

上記の「判断は人間」原則は文書上の約束に留まらず、Claude Code のランタイム側でも裏付けられています（公式 CHANGELOG 確認済み）:

1. **エージェント間メッセージは承認にならない** — エージェント間メッセージがユーザー承認として扱われない境界は従来から存在し、v2.1.198 で「親エージェントのメッセージは通常のタスク指示として扱い、**承認としては決して扱わない**（"an agent's message is still never treated as the user's approval"）」と明文化・再確認された。多段 subagent 構成でも、承認は人間からしか発生しない。
2. **AskUserQuestion は既定で人間を待ち続ける** — v2.1.200 以降、AskUserQuestion ダイアログは既定で自動続行しない（アイドルタイムアウトは `/config` での明示オプトイン）。Phase 承認を AskUserQuestion で実装する場合の安全根拠になる。**人間ゲートを担うセッションではアイドルタイムアウトをオプトインしない** こと。
3. **承認偽装の防止** — v2.1.205 以降、背景タスクの通知は「人間の入力は発生していない」と明示され、トランスクリプト改ざんは auto mode がブロックする。多段構成で「承認済み」という偽情報が下流に伝播するリスクへの対策で、§3.3 の「agent 間データは untrusted」原則と対をなす。

これは情報注記であり、キットの Phase / Stop Condition / Human Decision Point は変更しません。**型（プロセス規律）とエンジンの安全機構が二重防御になる** という構図です。

### 5.2 HDP 境界の恒久化 — permissions ルール

会話中に述べた境界（「main には push しないで」等）は auto mode の分類器がブロック信号として扱いますが、**context compaction でその発言が消えると境界も失われえます**。公式ドキュメントも「恒久保証が必要なら deny ルールにせよ」と明記しています。さらに v2.1.203 以降、main への単純な push は分類器のデフォルトブロック対象から外れたため、**HDP に相当する境界は permissions.deny / ask として settings.json に固定** します。

```jsonc
// .claude/settings.json（deny / ask は restrict 専用のため、project 側でも workspace trust なしで適用される）
{
  "permissions": {
    "deny": [
      "Bash(git push *)"        // push 全体を deny（基本形・公式 docs と同じ）。必要なら feature ブランチ push を allow で開ける
    ],
    "ask": [
      "Bash(npm run migrate *)" // DB migration は実行前に必ず人間へ確認
    ]
  }
}
```

- ⚠️ `Bash(git push origin main:*)` のような **引数を制約するパターンは fragile**（`git push -u origin main` / `git push origin HEAD:main` / 変数展開で素通りする）。「恒久保証」の文脈では広い deny を基本形とし、真の最終防衛線は **リモート側の branch protection / PreToolUse hook** に置く。
- `Tool(param:value)` 形式のパラメータマッチは **deny / ask 専用**（allow には使えない）。使えるのは `Agent(model:opus)` / `Bash(run_in_background:true)` など公式記載のパラメータのみで、**`Bash` の `command` や `Read` の `file_path` には使えない**（書いても無視され、起動時警告が出る）。
- 未承認 PR の自動マージは auto mode がブロックする（v2.1.195+、v2.1.205 まで段階拡張）。

**3 層の役割分担**（評価順）:

| 層 | 実体 | 強度 |
|---|---|---|
| ① permissions.deny / ask | 分類器より **前** に評価される物理固定 | ユーザー意図でも解除されない（bypassPermissions でも ask は強制プロンプト）。全モード適用 |
| ② auto mode 分類器 | 後段の事故防止レイヤー（§2.6） | soft block は明示的なユーザー意図で解除されうる。会話で述べた境界もここで読まれるが **compaction で消失しうる** |
| ③ Human Decision Point | 意思決定そのもの（人間） | **設定では代替不能**。①②はこの判断を守るための壁にすぎない |

プロジェクトとしてどの境界を固定したかは、Project Rules の「Execution Engine 方針」に記録します（`templates/project-rules-template.md` 参照）。

---

## 6. Agent Teams（実験的機能）の併用ルール

Agent Teams は、リードエージェントが複数のチームメイト（それぞれ独立した context window を持つ）をスポーンし、相互にメッセージングしながら並行作業する機能です（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` で有効化）。dev-agent-team では **単一フェーズ内・相互の議論/ 反証が価値を生むタスクに限って** 使います。

### 6.1 2 段ゲートの原則

チームメイトを plan mode に留め、リードが承認するまで実装させない運用ができますが、この **リードの plan approval は「品質フィルタ」であり、Human Decision Point の代替ではありません**。公式仕様上もリードは承認判断を自律的に行います（"The lead makes approval decisions autonomously" — 承認基準はプロンプトで注入可能）。

- **リード（AI）承認 = 品質フィルタ**: 計画の粒度・整合性チェック。承認基準はリードへのプロンプトで与える
- **人間承認 = 意思決定**: HDP（受入基準 / 採用案 / マージ / リリース / DB・権限変更）は、**人間がリードセッションで直接承認** する

「AI が AI を承認する仕組み」は最も誤解されやすい新機能であり、リード承認を人間ゲートの代替にした時点でキットの核原則が崩れます。

### 6.2 使ってよい場面

- 読み取り専用の並列レビュー・調査（research / review）— 公式もここから始めることを推奨
- 競合仮説デバッグ（同じバグに対して複数チームメイトが異なる仮説を並行検証し、相互に反証する）
- いずれも **単一フェーズ内に閉じる** こと。フェーズ境界の HDP はワークフロー同様、チームの外で人間に返す

**Dynamic Workflows との使い分け**: 結果の**集約**だけでよければ §3 の Dynamic Workflows / subagent で足りる。チームメイト同士の**相互通信・反証**が価値を生む場合のみ Agent Teams を使う（下記のトークンコスト約 7 倍に見合うかで判断）。

### 6.3 既知の制約

- `/resume`・`/rewind` とも in-process チームメイトを復元しない（復元後、リードが存在しないチームメイトへメッセージを送ろうとしたら新規スポーンを指示する）
- 権限はスポーン時にリードから継承される。**リードが `--dangerously-skip-permissions` で動いていると全チームメイトに伝播する** ため、HDP を含む運用では使わない
- トークンは標準セッションの **約 7 倍**（plan mode 併用時・公式 costs ページの目安）。チームメイトごとに独立 context window を持ち、チームサイズにほぼ比例して増える。チームメイトのモデルは Sonnet 推奨、作業完了したチームメイトは明示的に shut down する
- ファイル所有権を分離する（同一ファイルを複数チームメイトが編集しない）

### 6.4 ランタイム側の裏付け（情報注記）

チームメイトの権限プロンプトは **リードセッションに bubble up し、人間が直接承認** します。チームメイトは権限承認を代行できず、拒否された操作を別チームメイト経由で迂回することもできません（auto mode の分類器も agent 間の承認主張を untrusted として扱う）。この挙動は §3.3 の「agent 間データは untrusted」および §5.1 の「エージェント間メッセージは承認にならない」と完全整合します。→ キットのガードレール変更は不要。

> キットの `agents/*.md` をネイティブ subagent 定義化すればチームメイト定義として再利用できます（公式 docs "Use subagent definitions for teammates"）。これは §7 Follow-up の subagent 定義化と同一の意思決定です。

---

## 7. Follow-up（将来の拡張余地）

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
