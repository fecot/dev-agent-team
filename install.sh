#!/bin/bash
#
# dev-agent-team installer
#
# 前提:
#   git clone https://github.com/fecot/dev-agent-team.git ~/.claude/dev-agent-team
#
# 使い方:
#   cd ~/.claude/dev-agent-team
#   ./install.sh
#
# 環境変数（テスト・カスタム配置用）:
#   DEV_AGENT_TEAM_ROOT  クローン先（デフォルト: ~/.claude/dev-agent-team）
#   CLAUDE_COMMANDS_DIR  入口コマンドの配置先（デフォルト: ~/.claude/commands）
#   CLAUDE_WORKFLOWS_DIR Dynamic Workflow の配置先（デフォルト: ~/.claude/workflows）

set -euo pipefail

# ---- 設定 ----
DEV_AGENT_TEAM_ROOT="${DEV_AGENT_TEAM_ROOT:-${HOME}/.claude/dev-agent-team}"
CLAUDE_COMMANDS_DIR="${CLAUDE_COMMANDS_DIR:-${HOME}/.claude/commands}"
CLAUDE_WORKFLOWS_DIR="${CLAUDE_WORKFLOWS_DIR:-${HOME}/.claude/workflows}"

# グローバル配置するコマンド（dev-agent-team 本体に同梱）
COMMANDS=(
  "adopt-project.md"
  "run-feature-workflow.md"
  "issue-to-plan.md"
  "codebase-explore.md"
  "safe-implement.md"
  "pr-review.md"
)

# グローバル配置する Dynamic Workflow（dev-agent-team 本体に同梱）
# 注: 利用には Claude Code v2.1.154 以降 + Dynamic Workflows の有効化が必要。
WORKFLOWS=(
  "dev-agent-discovery.js"
)

# pre-flight チェックの基準ファイル（クローン済みかの判定に使う）
ENTRY_COMMAND="adopt-project.md"

# ---- カラー出力 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ---- pre-flight チェック ----

# OS チェック（macOS / Linux のみ）
case "$(uname -s)" in
  Darwin|Linux) ;;
  *)
    error "サポートされていない OS: $(uname -s)"
    error "dev-agent-team は macOS / Linux のみサポートしています。"
    error "Windows ネイティブはサポート外です（WSL2 は Linux 扱いで動作します）。"
    exit 1
    ;;
esac

# クローン済みリポジトリの検証
if [ ! -f "${DEV_AGENT_TEAM_ROOT}/commands/${ENTRY_COMMAND}" ]; then
  error "dev-agent-team が見つかりません: ${DEV_AGENT_TEAM_ROOT}"
  error ""
  error "先にリポジトリをクローンしてください:"
  error "  git clone https://github.com/fecot/dev-agent-team.git ${DEV_AGENT_TEAM_ROOT}"
  error "  cd ${DEV_AGENT_TEAM_ROOT}"
  error "  ./install.sh"
  exit 1
fi

# ---- インストール ----

info "dev-agent-team のコマンドをインストールしています（${#COMMANDS[@]} 個）..."

mkdir -p "${CLAUDE_COMMANDS_DIR}"

INSTALLED=0
TOTAL=${#COMMANDS[@]}
INDEX=0

for cmd in "${COMMANDS[@]}"; do
  INDEX=$((INDEX + 1))
  TARGET="${CLAUDE_COMMANDS_DIR}/${cmd}"
  SOURCE="${DEV_AGENT_TEAM_ROOT}/commands/${cmd}"

  # source の存在確認（リポジトリ内に該当ファイルがなければスキップして警告）
  if [ ! -f "${SOURCE}" ]; then
    warn "[${INDEX}/${TOTAL}] ソースファイルが見つかりません、スキップ: ${SOURCE}"
    continue
  fi

  if [ -e "${TARGET}" ] || [ -L "${TARGET}" ]; then
    warn "[${INDEX}/${TOTAL}] 既存ファイルを上書き: ${TARGET}"
  fi

  ln -sf "${SOURCE}" "${TARGET}"

  if [ -L "${TARGET}" ]; then
    info "[${INDEX}/${TOTAL}] ${TARGET} -> ${SOURCE}"
    INSTALLED=$((INSTALLED + 1))
  else
    error "[${INDEX}/${TOTAL}] シンボリックリンクの作成に失敗: ${TARGET}"
    exit 1
  fi
done

info "${INSTALLED}/${TOTAL} 個のコマンドをインストールしました。"

# ---- Dynamic Workflows のインストール ----

if [ "${#WORKFLOWS[@]}" -gt 0 ]; then
  info "dev-agent-team の Dynamic Workflow をインストールしています（${#WORKFLOWS[@]} 個）..."

  mkdir -p "${CLAUDE_WORKFLOWS_DIR}"

  WF_INSTALLED=0
  WF_TOTAL=${#WORKFLOWS[@]}
  WF_INDEX=0

  for wf in "${WORKFLOWS[@]}"; do
    WF_INDEX=$((WF_INDEX + 1))
    WF_TARGET="${CLAUDE_WORKFLOWS_DIR}/${wf}"
    WF_SOURCE="${DEV_AGENT_TEAM_ROOT}/dynamic-workflows/${wf}"

    if [ ! -f "${WF_SOURCE}" ]; then
      warn "[${WF_INDEX}/${WF_TOTAL}] ソースファイルが見つかりません、スキップ: ${WF_SOURCE}"
      continue
    fi

    if [ -e "${WF_TARGET}" ] || [ -L "${WF_TARGET}" ]; then
      warn "[${WF_INDEX}/${WF_TOTAL}] 既存ファイルを上書き: ${WF_TARGET}"
    fi

    ln -sf "${WF_SOURCE}" "${WF_TARGET}"

    if [ -L "${WF_TARGET}" ]; then
      info "[${WF_INDEX}/${WF_TOTAL}] ${WF_TARGET} -> ${WF_SOURCE}"
      WF_INSTALLED=$((WF_INSTALLED + 1))
    else
      error "[${WF_INDEX}/${WF_TOTAL}] シンボリックリンクの作成に失敗: ${WF_TARGET}"
      exit 1
    fi
  done

  info "${WF_INSTALLED}/${WF_TOTAL} 個の Dynamic Workflow をインストールしました。"
  info "（利用には Claude Code v2.1.154 以降 + Dynamic Workflows の有効化が必要です）"
fi

# ---- 完了 ----

echo ""
info "✅ dev-agent-team のインストールが完了しました。"
echo ""
echo "利用可能になったコマンド:"
echo "  /adopt-project          — 対象プロジェクトに dev-agent-team を導入"
echo "  /run-feature-workflow   — 8 Phase の標準開発フロー（入口）"
echo "  /issue-to-plan          — Issue を実装計画に変換"
echo "  /codebase-explore       — 既存コード調査"
echo "  /safe-implement         — 計画書ベースの安全な実装"
echo "  /pr-review              — PR 前レビュー"
echo ""
echo "利用可能になった Dynamic Workflow（要 v2.1.154+ / 有効化）:"
echo "  /dev-agent-discovery    — Phase 2 Discovery の広域並列調査"
echo ""
echo "次の手順:"
echo "  1. 対象プロジェクトのディレクトリで Claude Code を開く"
echo "  2. /adopt-project を実行してプロジェクトをセットアップ"
echo "  3. その後 /run-feature-workflow などで開発タスクを進める"
echo ""
echo "あとで dev-agent-team を更新する場合:"
echo "  cd ${DEV_AGENT_TEAM_ROOT} && git pull"
echo ""
echo "アンインストール:"
echo "  cd ${DEV_AGENT_TEAM_ROOT} && ./uninstall.sh"
echo ""
