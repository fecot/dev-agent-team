# Changelog

All notable changes to dev-agent-team will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

各エントリは以下の区分で記述します:

- **Added** — 新規機能・新規ファイル
- **Changed** — 既存挙動・既存ドキュメントの変更
- **Deprecated** — 将来削除予定の機能
- **Removed** — 削除した機能
- **Fixed** — バグ修正
- **Security** — セキュリティ関連の修正

> 運用注記: バージョンピン留め（`version.txt` / `dev_agent_team_min_version`）を実効に保つため、機能単位でこまめにリリースを切る。[Unreleased] を溜め込まない。

## [Unreleased]

## [v0.3.0] - 2026-08-24

### Added
- **型の二層と取り込み基準 — 価値の重心を「現場の台帳」へ寄せる再定位** (キット自身の多視点再評価由来: 廃止論 steelman / 擁護論 / 重複マトリクス / CHANGELOG 実績監査の 4 並列分析) — 棚卸しの結果、ネイティブ機能に丸ごと置き換えられた構成要素は 0 件で、多くは「ネイティブ機能を包んで適用範囲とガードレールを付加する」積層構造だった一方、(a) 汎用的な行動指針はモデル世代とともにデフォルト挙動へ吸収されていくこと、(b) 維持コストの主因がネイティブ機能の全量追随にあることが確認された。対応 3 点: (1) **`CONCEPT.md`「型とは何か」に二層論を追加** — 「汎用の賢さの明文化」（吸収されていく。原則 + why へ痩せさせ続ける）と「現場の台帳」（Known Risks / Decision Log / Migration チェックリスト。使うほど太り、吸収されない）を区別し、投資を後者に寄せる。`README.md` の「ネイティブ機能との関係」にも積層と重心移動を追記、(2) **ネイティブ機能の取り込み基準を新設（docs §1.2）** — 取り込むのは「人間ゲートの位置または強度が変わる変更」のみ。性能改善・UI 変更・ゲートに触れない新機能は意図的に追随しない。バージョンピンの新規追加も同基準（§7.3「発火点を増やさない」の自己適用として、維持コストに構造的上限を設ける）、(3) **§8.2 の粒度基準による agents/ 7 本・skills/ 8 本の監査を完了** — いずれも既に「原則 + why」粒度で大きな削減対象なし、と記録（定期的な全量再監査はしない）
- **Decision Log — 人間が下した判断を残して再利用する運用（`templates/project-rules-template.md` 新セクション）** — 外部発表「AIに持続力を与える 判断の長期記憶設計」（Eisuke Kawano 氏）の問題提起を一般化して取り込み。キットは Human Decision Point で **人間に判断させる型** は持っていたが、そこで出た答えの置き場が無く、実行ごとの Artifacts と一緒に消えていた（`docs/adoption-guide.md` §9 は「長期的に残したい判断は Wiki 等へ」としていたが、Phase 0 の読み込み対象外のため次の案件で再利用されない）。Known Risks と同じ「振り返りで育てる / 人間承認つき / ノイズを溜めない」運用を **判断** に拡張する: (1) Project Rules に **Decision Log**（判断 / 理由 / 再利用条件の 3 列）を新設、(2) **Phase 8 の振り返りに判断の抽出を追加** — 「次も同じ問いが来る」判断のみを対象とし、理由を必須にする（判断だけを残すと前提が変わったときに見直せず、ただの縛りになる）、(3) **Phase 0 で Decision Log を読む** — 関係する記録があればその前提から始め、同じ問いを人間に出し直さない。記録どうしの衝突 / 前提の不一致は AI が採用を決めず人間に戻す（Stop Condition 1 本を追加）、(4) **再利用条件による横断判定** — 「プロジェクトを問わず」の行は案件横断の原則の候補として人間に示す（引き上げ可否は人間が判断。キットの所有範囲は対象リポジトリまでとし、横断の記録置き場そのものは規定しない）。Human Decision Point に「Decision Log 追記」1 行、`agents/release-captain.md` の責務 / 出力テンプレ / 行動原則、`commands/run-feature-workflow.md` Phase 0 の読み込みリスト、`docs/native-tooling-integration.md` §5（エンジンに委譲しないもの）・§8.1、`docs/adoption-guide.md` §7・§9、`commands/adopt-project.md` の更新メニューに反映。**取り込まなかった項目**: 発表側の `vault/` ディレクトリ構造（キットは `.dev-agent-team/` + Project Rules を既に持ち、並行構造は衝突する）、判断記録の 3 つの探索手段（外部ツール依存。単一リポジトリ規模では参照をたどれば足りる）、最終 UI/UX の手触り確認（視覚仕様レビューゲートと `skills/browser-verification.md` で既出）
- **Scheduled Tasks / ルーチンの併用ルール（`docs/native-tooling-integration.md` §7 新設、旧 §7 Fable 5 は §8、旧 §8 Follow-up は §9 に繰り下げ）** — 実運用で起きたルーチン暴走（PR 作成後に「未マージで変化なしなら次のチェックインを再アーム」する自己チェックインが 2 日間で 185 回実行）を一般化。**人間ゲートは「越えさせない」だけでなく「待たせてもいけない」** ——人間の応答待ち（マージ / 承認 / 返信）を自動ループの監視対象にすると、人間が動くまで状態が変わらないため **終了条件が原理的に存在しない**（§7.1）。§7.2 に自己再発火を止める **4 層の歯止め（強度順: 能力を与えない > 回数を持たせる > 痕跡を残させる > 言葉で禁じる）** を §5.2 の 3 層と同じ体裁で定義（`/goal` の `or stop after N turns` = ②の実例、`disallowed-tools` = ①の実例として接続）。§7.3 発火点を増やさない（既存の定期実行に相乗り / 人間の処理速度も系の一部）、§7.4 通知抑制 + 自己再発火 = 検出不能の組み合わせ、§7.5 検出手順（使用量グラフには出ない。ルーチン一覧を「完了済みを含める」で確認）。§1.1 Tier 3・§4 判断早見表（2 行）・§5 冒頭・`CONCEPT.md` に接続、`workflows/feature-development.md` Phase 7 に「PR 作成後の監視責任は人間」、`templates/project-rules-template.md` の Execution Engine 方針に Scheduled Tasks の可否 / 自己再発火の上限 / 暴走確認手順の記録欄を追加
- **単位分割の設計 — 無主物リスト（`workflows/feature-development.md` §6.1）** — 実移行プロジェクトの QA 知見「単位分割された部分の品質は高く、不具合は分割の境界（どの単位にも属さない関心事）に集中する」を一般化して組み込み。複数単位に分割する移行 / 大規模改修では **最初の 1 単位に着手する前に** (1) 無主物リスト（どの単位にも属さない関心事の列挙と担当割当。列挙されなかった領域は「誰も見ていない」とみなす）、(2) 移行元の「理由があってそう書かれている仕組み」の棚卸し（理由不明を「不要」と判断して落とさない）、(3) データ取得層の方針決定（決めない場合も再判断ポイント =「2 つ目の単位が同じ API を叩いたとき」を記録）を行う。典型的な無主物 8 項目のチェックリスト付き。§6.1 Stop Condition 2 本（無主物リスト未作成での着手 / 取得方針未決定での再判断ポイント通過）と Human Decision Point 1 行（単位分割の設計・担当割当）を追加。Phase 5 追加要件に「リクエスト本数の実測（コードの共有と実行の共有は別物）」
- **データ取得の共有判定は「エンドポイント + パラメータ」で行う（`skills/impact-analysis.md` 新観点）** — 表示・見た目で共有を判断しない。エンドポイント → 利用箇所マトリクスを Phase 3 成果物に含める。作成時の注意 3 点（定数名と URL 文字列の両方で grep / 共有フック・共通コンポーネント経由の間接参照も追う / 実行回数は実測で確認）。`agents/architecture-reviewer.md` 行動原則・`skills/codebase-reading.md` 読解手順・`workflows/feature-development.md` §6.1 Phase 2 チェックリスト・`commands/run-feature-workflow.md` に接続
- **Fable 5 世代のプロンプト設計ガイド（§7 新設、旧 §7 Follow-up は §8 に繰り下げ）** — 公式 [Fable 5 プロンプティングガイド](https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/prompting-claude-fable-5) とキットの整合を整理: (1) **公式パターンがキットの型を裏打ち**（チェックポイント 3 類型「破壊的・不可逆 / 真のスコープ変更 / 本人にしか出せない入力」= Human Decision Point の定義と一致 / 独立検証サブエージェント > 自己批評 = Phase 7 多層レビューの根拠 / one-lesson-per-file メモリ = Known Risks 振り返り運用）、(2) **指示粒度の世代適合** — ゲート（Stop Condition / HDP / 禁止事項）は列挙を維持、行動手順のマイクロ指示は「原則 + why」への簡潔化候補とする線引き（公式「従来モデル向けスキルは Fable 5 には細かすぎ、品質を落としうる」）、(3) **委任・長時間実行パターン** — 証拠つき報告（ツール結果と突き合わせ）と why の伝達を §3.6 成立条件 1 / 4 に接続、interval 検証を Phase 5 に追記、長寿命サブエージェント + 非同期通信、(4) **禁止事項** — 内部推論をエコーさせる指示（`reasoning_extraction` refusal を誘発。キット既存文書は監査済みで該当なし）。`CONCEPT.md` に公式裏付けの段落、`workflows/feature-development.md` タグ付け規約にチェックポイント 3 類型との一致を追記
- **モデル / effort の非対称配分ガイド（§3.6 新設）** — Dynamic Workflows の `agent(prompt, {model, effort})` を使った層別配分の型: **司令塔（分解・判断・指示生成）= セッションモデル継承・high 以上 / 実装（精密指示の機械的適用）= effort:low（Sonnet 5 は medium 安全ライン）/ 検証 = high 以上**。「判断は上流に集約し、実装層から判断を排除する」——キットの核原則「AIは判断材料、判断は人間」をエージェント階層（人間 → 司令塔 AI → 実装 AI）に適用した相似形。effort:low の実装が成立する 5 条件（自己完結指示 / 判断余地ゼロ / 機械的検証の同梱 / 報告義務 / 司令塔の差分レビュー）と、「コスト削減は実装層で行い、司令塔・検証層は削らない」非対称性の根拠を明文化。§4 判断早見表に対応行を追加。`dynamic-workflows/dev-agent-discovery.js` に実装（reader = 低 effort・既定 medium・`args.readEffort` で上書き可 / scope・synthesize = セッション effort 継承）

### Fixed
- **`commands/adopt-project.md` の重複・開発メモを整理（751 → 725 行）** — 分岐 E の 3 選が用語セクションと二重定義だったのを分岐 E 側に一本化 / 重要度ランクのアイコン対応表が完了レポート節と二重だったのをランク表 1 箇所に集約 / コマンド仕様内に残っていた開発メモ（進捗チェックリスト・TODO 節）を削除
- **`CONCEPT.md` の Fable 5 段落の節番号参照を修正** — §7 → §8（PR #28 の節繰り下げ時の追随漏れ）
- **`commands/adopt-project.md` の更新メニューに `Execution Engine 方針` が欠けていた** — 同セクション追加時に更新メニューへ反映されておらず、診断・差分アップデートから選択できなかった（`[16]` として追加し、以降を繰り下げ）
- **`uninstall.sh` の symlink 削除に安全チェックを追加** — readlink でリンク先が `DEV_AGENT_TEAM_ROOT` 配下であることを検証し、配下でなければ「別ツールの symlink のためスキップ」として保護（他ツールの同名 symlink の誤削除を防止）
- **プレースホルダ記法の統一** — 実行時に決まるパス（`.dev-agent-team/runs/{issue-id}/` 等）は `{issue-id}`（単一波括弧）に統一（`{{}}` はテンプレ利用者が埋める変数、`{}` は実行時の可変値）。`docs/adoption-guide.md` / `skills/legacy-modernization.md` / `templates/project-rules-template.md` に適用
- **`examples/sample-workflow-output.md` の Artifacts パスを `docs/adoption-guide.md` §9 の推奨レイアウト（`runs/{issue-id}/` 単位）に整合**。Phase 0（Project Context Loading）の実行例も追加
- **`examples/sample-issue.md` を `templates/issue-template.md` の構造（必須 / 該当時のみ必須 / 任意）に再構成**（題材・内容は維持）

### Changed
- **`install.sh` / `uninstall.sh` の COMMANDS / WORKFLOWS 配列を `manifest.sh` に一本化**（両スクリプトから source。追加・削除は manifest.sh のみ編集）
- **`CLAUDE.md` のファイル構成の規則に `workflows/` / `dynamic-workflows/` / `docs/` を追記**
- **README に「8 Phase」呼称の注記（Phase 0 を含めると 9 段階）と `docs/troubleshooting.md` への導線を追加**
- **agents 6 ファイル（architecture-reviewer / codebase-explorer / implementation-driver / release-captain / review-gatekeeper / test-strategist）に Stop Condition 節を追加** — 内容は複製せず `workflows/feature-development.md` の対応 Phase への参照に統一
- **`skills/` 基本 5 ファイル（codebase-reading / impact-analysis / requirement-analysis / safe-refactoring / test-design）の冒頭に対応 Phase を明記**
- **`agents/implementation-driver.md` の数値固定方針に、実測値は `skills/migration-spec-capture.md` の計測結果（Phase 2）から取得する旨を追記**。`agents/test-strategist.md` に使用スキル（`skills/test-design.md`）を追記

## [v0.2.0] - 2026-07-13

### Added
- **ネイティブ新機能の取り込み 第2弾（dev-agent-team-evolve ワークフロー由来、v2.1.198〜v2.1.207）** — 全提案を敵対的検証（哲学整合・重複・事実の3レンズ、公式 CHANGELOG / docs 裏取り）を通した上で反映:
  - **人間ゲートのランタイム裏付け（§5.1 新設）** — エージェント間メッセージは承認にならない（v2.1.198 で明文化・再確認）/ AskUserQuestion は既定で人間を待ち続ける（v2.1.200、アイドルタイムアウトはオプトイン）/ 承認偽装・トランスクリプト改ざんの防止（v2.1.205）。情報注記のみ・ガードレール変更なし。「型とエンジンの安全機構の二重防御」を `CONCEPT.md` にも1段落追記
  - **HDP 境界の permissions 恒久化ガイド（§5.2 新設）** — 会話で述べた境界は compaction で失われうるため、HDP 相当の境界は permissions.deny / ask で settings.json に固定する。広い deny 基本形 + 引数制約パターンの fragile 警告 + `Tool(param:value)` の制約（deny/ask 専用・Bash command 不可）+ 3層役割分担表（deny→分類器→HDP、評価順つき）。`templates/project-rules-template.md` の Execution Engine 方針に「HDP の permissions 固定」行を追加
  - **Stop Condition の hooks 化ガイド（§2.7 新設）** — 〔機械検証可〕タグの Stop Condition を Stop hook / TaskCompleted + exit 2 で機械的に強制する変換表。**〔人間判断〕の hooks 化は禁止**を明記。TaskCreated/TaskCompleted は Agent Teams 不要・TeammateIdle のみ Agent Teams 前提。§2.4 に「`/goal` は本質的にセッションスコープの prompt-based Stop hook のラッパー」（公式 docs 明記）を追記。`workflows/feature-development.md` のタグ規約に相互参照、Phase 6 Stop Condition に〔機械検証可〕項目（テスト緑化未達）を新規追加
  - **ultracode / Dynamic workflow size / autoMode 配布経路の反映** — §3.3 に公式 docs の「mid-run のユーザー入力不可 → サインオフはワークフロー分割」引用（「1 workflow = 1 フェーズ」の公式裏付け）と ultracode の線引き（キーワード `ultracode` はタスク単位オプトイン可 / `/effort ultracode`（v2.1.203+）は HDP を含むセッションでは有効化しない — auto mode で起動プロンプトスキップ + Large workflow 警告非表示のため）。§3.4 に Dynamic workflow size（v2.1.202+、unrestricted/small/medium/large、助言的）と Large workflow 警告（25 agents / 1.5M tokens、v2.1.203+）。§2.5 に autoMode はユーザー設定（`~/.claude/settings.json`）のみで有効化（v2.1.207 で settings.local.json 読み込み廃止）、`commands/safe-implement.md` も整合修正。§2.6 に permission mode「Manual」改称（v2.1.200）の用語注記
  - **レビューの3層分離（/review・/code-review 分離 v2.1.202 対応）** — `workflows/feature-development.md` Phase 7 に段階構造注記（一次スキャン = `/review` / 網羅生成 = `/code-review <level>` / 判定観点整理 = ReviewGatekeeper・`/pr-review` / **マージ判断 = 人間**）。§4 判断早見表の「多視点レビュー」を Dynamic Workflow から分離し二重推奨を解消。`commands/pr-review.md` を全面改修（PR 説明文をテンプレ参照に統一 / `--strict` 基準定義 / Stop Condition 節 / 関連ドキュメント節）
  - **subagent の信頼性前提の更新と部分結果リカバリ** — §3.4 に fan-out の信頼性注記（バックグラウンド既定化 v2.1.198 / 部分成果返却・エラー伝播 v2.1.199）と「欠落を明記して人間レビューに回す」リカバリ手順。`dynamic-workflows/dev-agent-discovery.js` に実装: reader 失敗の per-item catch、未調査ファイルの機械的算出（index 対応・部分出力の中身に非依存）、synthesize への「未調査として openQuestions に必ず列挙」指示、SCOPE_SCHEMA の「24 件」ハードコードを `${maxFiles}` に動的化
  - **Agent Teams（実験的機能）の併用ルール（§6 新設、旧 §6 Follow-up は §7 に繰り下げ）** — **2 段ゲートの原則**: リードの plan approval は品質フィルタであり Human Decision Point の代替ではない（公式仕様 "The lead makes approval decisions autonomously"）。使ってよい場面（読み取り専用並列レビュー / 競合仮説デバッグ、単一フェーズ内限定）、既知の制約（/resume・/rewind 非復元 / 権限のスポーン時継承と `--dangerously-skip-permissions` 全伝播 / トークン約 7 倍）、権限プロンプトはリードセッションに bubble up し人間が承認するランタイム裏付け、Dynamic Workflows との使い分け（集約だけなら §3 / 相互反証が価値を生むときのみ）。§1.1 Tier 3 と `CONCEPT.md` のエージェンシー・ラダーにも追加（「リードの承認は人間の承認ではない」）。前提バージョン注記を箇条書き化して v2.1.202 / Agent Teams を追記
- **エージェンシー・ラダー（Tier 1〜3）による位置づけ整理** — 「1%しか知らない Claude の 17 機能」（[@swarm_japan](https://x.com/swarm_japan/status/2060287955533738127) / 元 [@AnatoliKopadze](https://x.com/AnatoliKopadze/status/2057813254617858078)）の「AI の自律度で機能を並べる」枠組みを取り込み。`docs/native-tooling-integration.md` § 1.1 に Tier 定義表（Tier 1 人間起点 / Tier 2 継続学習 / Tier 3 AI 起点）を新設し、**dev-agent-team は Tier 3（AI 起点）に確認ゲート（Human Decision Point）の線引きを持ち込む型** と位置づけ。`CONCEPT.md` に段階導入の語り口として 1 段落を追加。コンシューマ製品側の機能（Cowork / Chrome 拡張 / Design 等）は本キットの射程外として割愛
- **ネイティブ新機能の取り込み（native-feature-watch 由来）** — Claude Code の新機能を `docs/native-tooling-integration.md` の判断軸（型 vs エンジン / 人間ゲートを越えさせない）で評価し、以下を反映:
  - **前提バージョン注記に Claude Sonnet 5 / 1M context（v2.1.197+）を追記**（冒頭 NOTE）
  - **`autoMode.classifyAllShell`（§2.5 新設）** — 全 shell コマンドを auto-mode classifier でホワイトリスト判定させる設定。Phase 5/6 の `/goal` 機械的ループを手動承認で止めずに収束させる推奨設定。キットの手順は不変・⚠️有効化は人間判断。`commands/safe-implement.md` にも設定提案として言及
  - **auto mode の破壊的コマンド自動ブロック（§2.6 新設）** — `git reset --hard` / `git push --force` / `terraform destroy` 等が明示指示なしにブロックされる挙動を情報注記。既存の「人間ゲートを越えさせない」原則と整合（ガードレール変更なし）
  - **Cross-Session Messaging Security（v2.1.166）影響確認（§3.3）** — キットの cross-session データ授受は Dynamic Workflow のみ（subagent findings → synthesize）で集約専用・後段に人間レビューゲートあり → 影響なし。「agent 間データは untrusted 扱い」を §3.3 と `dynamic-workflows/dev-agent-discovery.js` のコメントに明文化
  - **`disallowed-tools`（Skills frontmatter, v2.1.152+）を最小権限強制として強く推奨（§7）** — ネイティブ Skill 化する際、読み取り専用/計測系 skill（codebase-reading / impact-analysis / requirement-analysis / migration-spec-capture / browser-verification）は `Edit`/`Write` を frontmatter で禁止する。対象マッピング表を追加（`safe-refactoring` / `legacy-modernization` は編集するため対象外）
- **`docs/native-tooling-integration.md`** 新規追加 — Claude Code ネイティブの `/goal`（自律ループ）/ Dynamic Workflows（並列オーケストレーション）と 8 Phase ワークフローの併用ルールを定義。「dev-agent-team は冗長か?」への回答（型 vs エンジンのレイヤー対比表）、`/goal` は機械的サブループ限定（evaluator 制約に合わせた条件テンプレ付き）、Dynamic Workflows は単一フェーズ内 fan-out 限定、判断早見表、エンジンに委譲しない人間判断のコア、を収録。**人間ゲートをエンジンに越えさせない**ことを大原則に
- **`dynamic-workflows/dev-agent-discovery.js`** 新規追加 — Phase 2 Discovery を並列化する Dynamic Workflow の実装例。候補ファイルを並列読解し `templates/investigation-report-template.md` 構造のレポート（関連ファイル / 類似実装 / 既存パターン / 暫定変更候補 / 確認事項）を返す。内部に人間ゲートは無く、完了後に人間が Phase 3 へ進む前にレビューする立て付け。`args` で focus / paths を受け取れる。`/dev-agent-discovery` で起動（要 Claude Code v2.1.154+ / 有効化）
- **Stop Condition のタグ付け規約** — `workflows/feature-development.md` に〔機械検証可〕（`/goal` で自動判定してよい）/〔人間判断〕（自動化しない）の区別を導入。タグなしは人間判断寄りとして扱う。Phase 5 の機械的 Stop Condition に適用例を付与
- **`templates/project-rules-template.md` の Execution Engine 方針セクション** — プロジェクト側で `/goal` / Dynamic Workflows の使用方針（許可 / 禁止 / 限定）と人間ゲートの扱いを宣言できる項目を追加
- **視覚仕様レビューゲート（Phase 4 → 5）** (マイグレーション振り返りフィードバック由来、一般化して追加) — UI（画面・コンポーネント・レイアウト・見た目）を伴う変更では、Phase 4 で視覚仕様スケッチ（ASCII ワイヤーフレーム / mock / 注釈付きスクショ等）を作り、Phase 5 開始前に人間が合意するゲートを新設。「実装してから『思っていたのと違う』」の手戻りを防ぐ。`workflows/feature-development.md` の Phase 4 Action/Output/Stop Condition + Human Decision Points、`agents/implementation-driver.md` の出力テンプレ/セルフチェック/行動原則、`commands/run-feature-workflow.md` Execution Rules、`commands/safe-implement.md` 実行フロー/セーフガードに反映。Migration に限らず UI 変更全般に適用
- **振り返りによる Known Risks 蓄積運用（Phase 8）** (マイグレーション振り返りフィードバック由来、一般化して追加) — Phase 8（Release Check）に振り返りステップを追加。「次回また踏みそうな罠」を 1 行ずつ抽出し、対象リポジトリの Project Rules の Known Risks への追記を人間に提案する（同じ罠を毎回踏むのを止める蓄積運用）。`workflows/feature-development.md` Phase 8 Action/Output + Human Decision Points、`agents/release-captain.md` 責務/出力/行動原則、`templates/project-rules-template.md` の Known Risks セクションに反映。追記は提案であり Project Rules の書き換え可否は人間が判断する
- **受け入れ基準の明示承認を Stop Condition 化（Phase 1）** (マイグレーション振り返りフィードバック由来、一般化して追加) — 受入基準を列挙しただけでは Phase 2 に進まず、人間が「これで進めてよい」と明示承認するまで停止する Stop Condition を追加（「確認事項がない」＝「承認済み」ではない）。認識ズレを早い段階で炙り出す。`workflows/feature-development.md` Phase 1 + `agents/product-interpreter.md` Stop Condition に反映
- **タスク粒度の指針** (マイグレーション振り返りフィードバック由来、一般化して追加) — タスク追跡（TaskCreate 等）の粒度は Phase 単位までとし、Phase 内の細かい実装ステップは計画書/実装ログで管理する方針を明文化（sub-task の作りすぎを防ぐ）。`workflows/feature-development.md` 設計の前提 + `commands/run-feature-workflow.md` Execution Rules に反映
- **`templates/issue-template.md`** 新規追加 (PRA-11459 振り返り由来) — 依頼者しか知らない情報を確実に渡すための Phase 1 Intake テンプレート。必須（背景・目的 / スコープ / 受け入れ基準）/ 該当時のみ必須（UI 変更 / 共通部品挙動 / 既知の罠）/ 任意（制約 / 関連情報）の 3 階層構造。「コードを読めば分かる情報は省略 OK、依頼者の頭の中にしかない情報に集中」という方針を冒頭で明示。`commands/run-feature-workflow.md` Inputs / `workflows/feature-development.md` Phase 1 Action / `agents/product-interpreter.md` の行動原則 + Stop Condition から参照される
- **Migration / UI Replica サブフロー** (PRA-11459 フィードバック由来) — `workflows/feature-development.md` § 6 にタスク種別サブフローを新設。通常 / Migration / UI Replica / Hotfix の 4 種別を定義し、Migration / UI Replica 種別では Phase 0 / 1 / 2 / 4 / 5 に追加チェックリスト（グローバル SCSS 所在 / source 実値計測 / ゴール定義承認 / 検証ループ）が発火する。タスク種別は人間が宣言し、自動判定はしない
- **`agents/product-interpreter.md` の数値化プロトコル** (PRA-11459 フィードバック由来) — UI / 見た目に関する曖昧な指示（「太い」「細い」「濃い」等）を、推測で実装せず計測した上で逆質問するプロトコルを追加。形容詞ホワイトリスト + 逆質問テンプレ + 範囲指示の条件確認ルール
- **`agents/implementation-driver.md` のゴール定義 / 数値固定方針** (PRA-11459 フィードバック由来) — Migration / UI Replica 種別の実装計画に「ゴール定義（完全 px 一致 / UX 同等 / 大幅改修）」と「数値固定方針（色 / フォント / レイアウト ratio）」セクションを必須化。Phase 5 開始前に CEO/PM 承認を得る運用に
- **`skills/migration-spec-capture.md`** 新規追加 (PRA-11459 フィードバック由来) — 移植元（source）アプリの実値（color / px / DOM / LocalStorage 実値 / API 実 shape / 共通部品の動的挙動）を Playwright MCP で機械計測する skill。Phase 2 の Discovery で source を計測し、Phase 4 の数値固定方針と Phase 5 の検証ベースラインとして使う
- **`skills/browser-verification.md`** 新規追加 (PRA-11459 フィードバック由来) — UI 変更時の検証ループ 6 ステップ（修正 → rebuild 確認 → cacheBust reload → 実機計測 → スクショ比較 → 数値+画像で報告）を標準形として定義。目視判定ではなく `getComputedStyle` / `getBoundingClientRect` の計測値を一次ソースにする
- **`commands/safe-implement.md` の検証ループ統合** (PRA-11459 フィードバック由来) — 「検証ループ（UI 変更時）」セクションを追加し、Migration / UI Replica 種別では必須、それ以外の UI 変更タスクでも強く推奨。セーフガードに「目視で完了扱いにしない」「UI 変更で検証ループ未通過のまま完了報告しない」を追加
- **`commands/adopt-project.md` 本実装** — プレースホルダーを差し替え、`docs/adoption-guide.md` Step 2〜5 を対話的に半自動化する入口コマンドの本実装。状態診断（5ステップ）/ 分岐 A〜E（新規導入 / 既存連携 / CLAUDE.md 新規作成 / 冪等性モード / バージョン差分モード）/ アンケート 3 階層設計 / `--dry` オプション / 完了レポート / Stop Conditions
- **`version.txt`** — リポジトリ直下に追加。`/adopt-project` の状態診断 [1] で読み込まれる dev-agent-team 本体のバージョン情報源。初期値: `v0.1.0`
- **`templates/claude-md-snippet.md`** — 対象リポジトリの `CLAUDE.md` に追記する静的スニペット。`<!-- dev-agent-team:start -->` / `<!-- dev-agent-team:end -->` マーカーで区切られ、`/adopt-project` 再実行時にマーカー間を安全に置換できる構造
- **`docs/troubleshooting.md`** 新規追加 (E3) — cmux など一部ターミナルでの `*.md` 表示変換問題の説明と、`xxd` / `od -c` での確認手順
- **アンケート段階1のレガシー判定 1問** (A1) — 段階1の最後に「このプロジェクトはレガシーアプリですか？」を追加し、Yes 時のみ段階3 H Legacy Modernization Rules を質問する流れに整理
- **SemVer 2.0 precedence rule の明文化** (D1) — `dev_agent_team_version` / `dev_agent_team_min_version` の比較ルールを SemVer 2.0 に固定。`v0.1.0 < v0.2.0 < v0.10.0 < v1.0.0` / プレリリース版は正式版より低い扱い / 不正フォーマットは Stop Condition
- **関連ツール候補ホワイトリスト** (F2) — 依存ライブラリから関連ツールを候補提示する際のホワイトリスト（SQLAlchemy → Alembic / Django → 組込 migration / Prisma → Prisma migrate / FastAPI → uvicorn / Next.js → migrate 該当なし）。リスト外は推測せず未確定のまま
- **「既存ファイル状況」セクション** (B1) — 状態診断の後、全分岐で `.git` / `CLAUDE.md` / `README.md` / 主要ファイル / `.gitignore` / `.dev-agent-team/` / `project-rules.md` の存在状態を一覧表示
- **状態診断記号の統一** (C1) — `✓` 良い状態 / `–` 中立な不在 / `✗` エラー / `N/A` 該当しない を仕様書で定義し、`--dry` 出力例にも反映
- **未確定項目の重要度ランク** (D6) — `必須` / `依頼依存` / `推奨` の3ランクを導入。完了レポートで `⚠️` `🔶` `ℹ️` のアイコン付きで警告
- **「3選プロンプト」用語定義セクション** (E1) — 書き込み確認・バージョン差分などで使う標準フォーマットを定義し、各分岐で同じ語彙を使うように整理
- **進捗表示「ファイル X/Y」** (E2) — 複数ファイルを書き込む際の進捗を明示
- **「未確定」と「該当なし」の使い分け定義** (B2) — `「未確定（要確認）」` は後で埋める必要あり（Phase 0 で Stop Condition の対象になりうる）、`「該当なし（理由）」` は構造的に該当しない（Stop Condition 対象外）。判定ルールも仕様書に記載
- **分岐 D で CLAUDE.md マーカーなし時の3選** (D3) — `[1]` 何もしない / `[2]` 分岐 B 相当を追加実行 / `[3]` 中止
- **検出スタックと既存記述の不整合検出時の警告と3選** (D4) — `package.json` 検出値と既存 `CLAUDE.md` の記述が衝突した場合、LLM は判定せず利用者に委譲（`[1]` 検出値採用 / `[2]` CLAUDE.md 採用 / `[3]` 手動入力）
- **仕様書末尾の TODO セクション** — 後回し論点として「各分岐の `--dry` 出力例追加」を記録

### Changed
- **ネイティブ実行エンジン併用のポインタを各所に追加** — `workflows/feature-development.md`（Rule Priority 直後に併用節 + Phase 2/5/6/7 に 1 行注記）、`commands/run-feature-workflow.md`（Execution Rules）、`README.md`（「ネイティブ機能との関係」節 + 構成図に `dynamic-workflows/` + Dynamic Workflows 一覧）、`CONCEPT.md`（「型とエンジンは別レイヤー」段落）から `docs/native-tooling-integration.md` を参照
- **`install.sh` / `uninstall.sh` に `WORKFLOWS` 配列を追加** — `dynamic-workflows/*.js` を `~/.claude/workflows/` に symlink 配置 / 削除する処理を追加（`CLAUDE_WORKFLOWS_DIR` env override 対応）。コマンドの symlink 処理と対称
- **Migration サブフロー Phase 2 に「全画面スクショ + 可視要素インベントリ」を必須化** (マイグレーション振り返りフィードバック由来) — `skills/migration-spec-capture.md` の採取項目に「0. 全画面スクリーンショット + 可視要素インベントリ」を追加し、`workflows/feature-development.md` § 6.1 Phase 2 チェックリストにも反映。コード/要件から拾った要素だけ計測すると「画面に存在するのに認識していない要素」を丸ごと見落とすため、実機の見た目から要素を棚卸しする。あわせて「ロジックと CSS（専用スタイルシートの所在）を両方 Discovery する（CSS を後回しにしない）」を明記。Stop Condition も追加
- **`skills/browser-verification.md` のキャッシュバイパスを `no-store` に強化** (マイグレーション振り返りフィードバック由来) — Step 3 / `cacheBustReload` の注入ヘッダを `Cache-Control: no-cache` から `no-store` に変更（レスポンスのキャッシュ保存自体を抑止し、古い bundle を掴む事故を防ぐ）。「反映されない体感の多くはキャッシュ起因。目視で悩む前に定型手順として通す」旨を追記
- **`commands/run-feature-workflow.md` の Inputs に「タスク種別」フィールド追加** (PRA-11459 フィードバック由来) — 通常 / Migration / UI Replica / Hotfix のいずれかを起動時に人間が宣言する仕様。自動判定はしない（誤判定で誤サブフローが走るリスク回避）。When Not to Use の Hotfix 記述を新サブフローと整合させた
- **README.md の Skills 一覧表に 2 行追加** — `migration-spec-capture` と `browser-verification` を一覧に追記
- **`docs/troubleshooting.md` の記述を一般化** — 旧記述は特定ツール名（cmux 等）を原因として名指ししていたが、その後の検証で真因は別の入力経路（チャットアプリのペースト時マークダウン自動変換）と判明。将来のツール側修正にも耐えるよう、特定ツール名を含めない一般化記述に置き換え、コードブロックでの囲みによる回避策も追記
- **アンケート段階1構造刷新** (A1) — 旧 7 問（Tech Stack に言語/DB/インフラ/CI/CD が混在、DB 質問が重複）を破棄し、責務を1つに絞った 8 問 + レガシー判定 1 問に刷新（目的 / 言語 / FW・主要ライブラリ / インフラ・CI/CD・パッケージマネージャ / Runtime Commands / DB / 必須テストレイヤー / PR ルール / Do Not）
- **段階2/3 の境界整理** (A2) — 段階2 推奨を 8 項目（Architecture / Coding / Frontend / Backend / API / Security / Release / Known Risks）、段階3 該当時のみを 1 項目（Legacy Modernization Rules）に再構成。Known Risks は段階3から段階2へ移動
- **Runtime Commands で「該当なし」回答許容** (F1) — 各サブ項目（test / lint / typecheck / dev / migrate）で `[Y/n/該当なし]` 回答を許容
- **3選プロンプトのラベル変更（既存ファイル更新時）** (C2) — 旧「上書き / バックアップ / 中止」から、新「そのまま追記（バックアップなし）/ バックアップを取ってから追記 / 中止」に変更。各オプションのアクションが明示的に
- **新規ファイル作成時は2選** (C3) — 旧 3 選（うちバックアップは新規作成では同等）を 2 選「作成 / 中止」に簡略化。仕様書で「新規作成と既存更新で選択肢が異なる」を明記
- **完了レポートを Next Steps と運用注意事項に分割** (C4) — 行動指示（Next Steps）と運用上の注意（Artifacts 管理 / `.bak.*` クリーンアップ）を分離
- **Test Rules / PR Rules の細目整理** (D5) — `templates/project-rules-template.md` の Test Rules と PR Rules を「主要項目（段階1で確認）」と「詳細項目（段階2で選ばれた場合のみ）」に分割
- **分岐 D マーカー無し時の挙動** (D3) — 旧版では未定義だった `.dev-agent-team/project-rules.md` ありで `CLAUDE.md` マーカーなしのケースを 3 選で扱うように
- **不整合検出時の挙動** (D4) — 旧版では未定義だった検出スタックと既存記述の不整合を、警告 + 3 選で利用者判断に委譲

### Removed
- **分岐 E の強制続行（bypass）オプション** (D2) — 旧 3 選 `[2]` の「強制的に進める（非推奨）」を完全削除。代替として「`min_version` 手動修正（救済策、利用者の手作業）」を提供。`/adopt-project` は `min_version` を書き換えず、利用者が `.dev-agent-team/project-rules.md` を手動で開いて編集する。bypass 関連の記述は仕様書から完全削除

### Fixed
- **`/issue-to-plan` の保存先を Artifacts Retention Policy に整合** — 保存先を `docs/plan-{{issue-id}}.md`（Git 管理領域への保存＝キット自身のポリシー違反）から `.dev-agent-team/runs/{{issue-id}}/implementation-plan.md`（Run 単位）/ `.dev-agent-team/plans/implementation-plan-{{issue-id}}.md`（Phase 単位互換）に修正。あわせて `templates/implementation-plan-template.md` への参照・Stop Condition 節（確認事項未回答で進まない / 受入基準の人間明示承認 / 単独実行時の Phase 0 相当読み込み）・関連ドキュメント節を追加
- **ドキュメント間の参照・記述不整合を一括修正** — (1) `workflows/feature-development.md` §6 冒頭の発火 Phase「0 / 1 / 2 / 5」を「0 / 1 / 2 / 4 / 5」に修正（§6.1 の Phase 4 追加項目 = ゴール定義・数値固定方針の人間承認が発火一覧から漏れていた） (2) `commands/run-feature-workflow.md` の Phase 参照表にレガシー併用と種別時の正参照の注記を追加 (3) `docs/adoption-guide.md` の §8 欠番を解消（導入コマンドとバージョン運用の短い節を新設。§9 のアンカーは据え置き）し、§3 に `/adopt-project` による半自動化の案内を追加 (4) `agents/product-interpreter.md` 逆質問テンプレの計測手段を source=migration-spec-capture / target=browser-verification の両スキル併記に修正 (5) `docs/native-tooling-integration.md` §3.1 の「§6.1」参照を `workflows/feature-development.md` §6.1 と明示
- **templates 配布物の整合修正** — (1) `templates/implementation-plan-template.md` に「実装案の比較」節（案 A 最小変更・必須 / 案 B 標準 / 案 C 任意 + レガシー時 3 案読み替え注記 + 採用決定は人間の注記）を追加し、Phase 4 Stop Condition「最小変更案を必ず含める」を成果物構造で担保。「実装方針」は「採用案の詳細方針」に改名 (2) `templates/project-rules-template.md` の相対リンク 2 箇所（コピー先で必ず壊れる）をキット絶対パス `~/.claude/dev-agent-team/...` 表記に変更 (3) `templates/claude-md-snippet.md` の静的コピー本文中の `{{issue-id}}` を既存スキルと同じ `{issue-id}` 表記に変更（`{{}}` = テンプレ変数の規約を維持）
- **`/codebase-explore` を型に準拠** — 出力を独自簡易フォーマットから `templates/investigation-report-template.md` 準拠に変更（単独実行のクイック調査時のみ縮約可・Phase 2 実行時はフル必須）。前提節（Rule Priority 準拠の事前読み込み）・Stop Condition 節（断言しない / 調査結果は人間がレビューする判断材料）・関連ドキュメント節（`/dev-agent-discovery` との使い分け含む）を追加。`agents/codebase-explorer.md` の出力フォーマットには内部整理用の位置づけ注記を追加
- **`install.sh` / `uninstall.sh` を全コマンド対応に拡張** — v0.1.0 時点では `adopt-project.md` のみグローバル symlink していたため、`/run-feature-workflow` などのコマンドがどこからも呼べない不具合があった（仕様意図と実装のギャップ）。`install.sh` と `uninstall.sh` で `COMMANDS` 配列を導入し、`adopt-project.md` / `run-feature-workflow.md` / `issue-to-plan.md` / `codebase-explore.md` / `safe-implement.md` / `pr-review.md` の 6 コマンドすべてを `~/.claude/commands/` に symlink するように。これにより `install.sh` 1 回で全コマンドが任意プロジェクトでグローバルに使え、`/adopt-project` の責務はプロジェクト固有 artifact（`.dev-agent-team/project-rules.md` 等）の整備に集中する設計が実装と整合
- 実機反映には利用者側で `cd ~/.claude/dev-agent-team && git pull && ./install.sh` の実行が必要

---

## [v0.1.0] - 2026-05-04

dev-agent-team キットの最初のタグ付きリリースです。`/adopt-project` を起点とした導入動線と、対象プロジェクト側でのバージョンピン留めの仕組みが揃いました。

### Added

- **`install.sh`** — `~/.claude/dev-agent-team` をクローンしたあと `/adopt-project` を `~/.claude/commands/` にシンボリックリンクで配置するインストールスクリプト。macOS / Linux 対応、`set -euo pipefail`、OS 判定 / pre-flight チェック / 上書き対応、`DEV_AGENT_TEAM_ROOT` / `CLAUDE_COMMANDS_DIR` の env override によるテスト容易性
- **`uninstall.sh`** — シンボリックリンクの安全な削除。実ファイル誤削除を防ぐ保護分岐 / 二重 uninstall の no-op 動作
- **`commands/adopt-project.md`**（プレースホルダー） — `/adopt-project` の入口ファイル。`install.sh` の symlink ターゲットとして機能。本実装は次リリース予定
- **`templates/project-rules-template.md` のバージョンピン留めフィールド** — 冒頭に YAML フロントマター `dev_agent_team_version` / `dev_agent_team_min_version` を追加し、対象プロジェクトの Project Rules がどのバージョンの dev-agent-team で動作することを想定しているかを明示できるように。Phase 0 でのバージョン比較・Stop Condition 発動を見据えた仕組み

[Unreleased]: https://github.com/fecot/dev-agent-team/compare/v0.3.0...HEAD
[v0.3.0]: https://github.com/fecot/dev-agent-team/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/fecot/dev-agent-team/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/fecot/dev-agent-team/releases/tag/v0.1.0
