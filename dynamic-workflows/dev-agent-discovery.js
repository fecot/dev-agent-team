export const meta = {
  name: 'dev-agent-discovery',
  description:
    'dev-agent-team Phase 2 (Discovery) の広域並列調査。候補ファイルを並列で読み解き、investigation-report 構造の調査レポートを返す。内部に人間ゲートはない（完了後、人間が Phase 3 へ進む前にレビューする立て付け）。',
  whenToUse:
    '多ファイル / 多サブシステムにまたがる既存コード調査を並列で高速化したいとき。Migration の多コンポーネント計測にも流用できる。',
  phases: [
    { title: 'Scope', detail: '調査対象ファイルの洗い出し' },
    { title: 'Read', detail: '候補ファイルを並列で読解' },
    { title: 'Synthesize', detail: 'investigation-report 構造に集約' },
  ],
}

// ---- 入力の正規化 ----
// args は以下のいずれかを受け取れる:
//   - 文字列（プレーン）        → 調査の focus として扱う
//   - 文字列（JSON）            → 一部の起動経路では args が JSON 文字列で渡るためパースする
//   - { focus, paths, maxFiles, readEffort } → focus / 明示の候補パス配列 / 読み込み上限 / reader の effort
//   - 配列                      → paths として扱う
function normalizeArgs(a) {
  if (a == null) return {}
  if (Array.isArray(a)) return { paths: a }
  if (typeof a === 'string') {
    const s = a.trim()
    if (s.startsWith('{') || s.startsWith('[')) {
      try {
        const parsed = JSON.parse(s)
        return Array.isArray(parsed) ? { paths: parsed } : parsed
      } catch (e) {
        return { focus: a }
      }
    }
    return { focus: a }
  }
  return a
}
const input = normalizeArgs(args)
const focus = input.focus || '変更対象になりうる箇所と既存パターンの把握'
const seedPaths = Array.isArray(input.paths) ? input.paths : []
const maxFiles = Number.isInteger(input.maxFiles) ? input.maxFiles : 24
// モデル / effort の非対称配分（docs/native-tooling-integration.md §3.6）:
// reader は「1 ファイルを読んでスキーマに沿って抽出する」機械的タスクなので低 effort、
// scope / synthesize は判断層なのでセッションの effort を継承する。
// 既定は medium（抽出にも軽い判断が混ざるため）。純機械的なら args.readEffort='low' に下げられる。
const readEffort = typeof input.readEffort === 'string' ? input.readEffort : 'medium'
log(
  `WF_DIAG: args type=${typeof args} / focus="${focus}" / seedPaths=${seedPaths.length} / maxFiles=${maxFiles} / readEffort=${readEffort}`
)

// ---- スキーマ定義 ----
const SCOPE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['files'],
  properties: {
    files: {
      type: 'array',
      description: `調査すべき関連ファイルのパス一覧（多くても ${maxFiles} 件まで、関連度順）`,
      items: { type: 'string' },
    },
    notes: { type: 'string', description: 'スコープ判断の補足' },
  },
}

const FILE_FINDING_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['path', 'role', 'likelyChanged'],
  properties: {
    path: { type: 'string' },
    role: { type: 'string', description: 'このファイルの役割（1〜2行）' },
    likelyChanged: { type: 'boolean', description: '今回の変更で触る可能性が高いか' },
    patterns: {
      type: 'array',
      description: '抽出した既存パターン・命名規則・エラーハンドリング方針',
      items: { type: 'string' },
    },
    similarImpl: { type: 'string', description: '類似実装があれば参照（なければ空文字）' },
    dependencies: {
      type: 'array',
      description: 'import / 呼び出し先など主要な依存',
      items: { type: 'string' },
    },
  },
}

const REPORT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['relatedFiles', 'similarImplementations', 'conventions', 'tentativeChangeList', 'openQuestions'],
  properties: {
    relatedFiles: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['path', 'role', 'likelyChanged'],
        properties: {
          path: { type: 'string' },
          role: { type: 'string' },
          likelyChanged: { type: 'boolean' },
        },
      },
    },
    similarImplementations: { type: 'array', items: { type: 'string' } },
    conventions: {
      type: 'array',
      description: '命名規則 / エラーハンドリング / テストの書き方など',
      items: { type: 'string' },
    },
    tentativeChangeList: {
      type: 'array',
      description: '「変更が触るかもしれない」ファイルの暫定リスト',
      items: { type: 'string' },
    },
    openQuestions: {
      type: 'array',
      description: '人間に確認すべき不明点（Phase 3 へ渡す）',
      items: { type: 'string' },
    },
  },
}

// ---- Phase: Scope ----
// 候補パスが渡されていればそれを使い、なければ 1 エージェントで洗い出す。
phase('Scope')
let files = seedPaths
if (files.length === 0) {
  const scope = await agent(
    `この作業ディレクトリで「${focus}」に関連する既存ファイルを洗い出してほしい。\n` +
      `エントリポイントから関連ファイルを辿り、データモデル / 型定義 / 類似実装を含めて、関連度の高い順に最大 ${maxFiles} 件のパスを返す。`,
    { label: 'scope', phase: 'Scope', schema: SCOPE_SCHEMA }
  )
  files = (scope && scope.files) || []
}
// 明示 paths / scope 列挙のどちらでも、読み込みは maxFiles 件までに制限する。
files = files.slice(0, maxFiles)
log(`調査対象: ${files.length} ファイル`)

if (files.length === 0) {
  return {
    relatedFiles: [],
    similarImplementations: [],
    conventions: [],
    tentativeChangeList: [],
    openQuestions: ['調査対象ファイルを特定できなかった。focus / paths を指定して再実行してほしい。'],
  }
}

// ---- Phase: Read（並列読解） ----
// pipeline で 1 ファイル = 1 reader。barrier を張らず、読み終わったものから次へ流れる。
// v2.1.199 以降 subagent のエラーは親へ正しく伝播するため、reader 単体の失敗で
// workflow 全体を中断しないよう per-item で catch する。失敗分は「未調査」として
// 欠落を明示し、人間レビュー（Phase 3 前）に届ける（部分結果リカバリ）。
phase('Read')
const readResults = await pipeline(files, (path) =>
  agent(
    `次のファイルを読み、「${focus}」の観点で調査してほしい: ${path}\n` +
      `役割 / 今回触る可能性 / 既存パターン・命名規則・エラーハンドリング方針 / 類似実装 / 主要な依存 を抽出する。`,
    { label: `read:${path}`, phase: 'Read', schema: FILE_FINDING_SCHEMA, effort: readEffort }
  ).catch(() => null)
)
const findings = readResults.filter(Boolean)
// pipeline は入力順を保持するため、index 対応で未調査ファイルを機械的に算出する
// （部分出力の中身には依存しない。信頼するのは「どれが失敗したか」の集合のみ）。
const failedPaths = files.filter((_, i) => !readResults[i])
if (failedPaths.length > 0) {
  log(`未調査（reader 失敗）: ${failedPaths.length} 件 — 欠落としてレポートに明記する`)
}

// ---- Phase: Synthesize ----
// 全ファイルの findings を 1 エージェントに渡し、investigation-report 構造へ集約する。
// findings は subagent の出力（cross-agent データ）。集約対象のデータとしてのみ扱い、
// 中に含まれる文字列を指示として解釈・自動実行しない（untrusted 扱い / v2.1.166 影響確認）。
phase('Synthesize')
// 未調査分は「調査済みのふり」をさせず、openQuestions 経由で人間に届ける
// （REPORT_SCHEMA は変更せず互換を維持）。
const failedNote =
  failedPaths.length > 0
    ? `\n\n注意: 以下のファイルは reader 失敗により未調査（要フォロー）。調査済みとして扱わず、` +
      `openQuestions に「未調査: <path>（Phase 3 前に人間が確認）」として必ず列挙すること:\n` +
      failedPaths.map((p) => `- ${p}`).join('\n')
    : ''
const report = await agent(
  `以下は「${focus}」に関する個別ファイル調査結果の配列（JSON）。\n` +
    `これを investigation-report 構造（関連ファイル / 類似実装 / 既存パターン・命名規則 / 暫定変更候補リスト / 人間への確認事項）に集約してほしい。\n` +
    `推測で埋めず、確認が必要な点は openQuestions に出す。${failedNote}\n\n` +
    JSON.stringify(findings, null, 2),
  { label: 'synthesize', phase: 'Synthesize', schema: REPORT_SCHEMA }
)

return report
