#!/bin/bash
#
# dev-agent-team uninstaller
#
# 使い方:
#   cd ~/.claude/dev-agent-team
#   ./uninstall.sh
#
# このスクリプトは以下を行います:
#   - ~/.claude/commands/ に配置した各コマンド（COMMANDS[]）のシンボリックリンクを削除
#   - ~/.claude/workflows/ に配置した各 Dynamic Workflow（WORKFLOWS[]）のシンボリックリンクを削除
#
# このスクリプトは以下を行いません（手動で削除してください）:
#   - ~/.claude/dev-agent-team/ のクローン削除（rm -rf ~/.claude/dev-agent-team）
#   - 対象リポジトリの .dev-agent-team/ ディレクトリ
#
# 環境変数:
#   DEV_AGENT_TEAM_ROOT  クローン先（デフォルト: ~/.claude/dev-agent-team）
#   CLAUDE_COMMANDS_DIR  入口コマンドの配置先（デフォルト: ~/.claude/commands）
#   CLAUDE_WORKFLOWS_DIR Dynamic Workflow の配置先（デフォルト: ~/.claude/workflows）

set -euo pipefail

# ---- 設定 ----
DEV_AGENT_TEAM_ROOT="${DEV_AGENT_TEAM_ROOT:-${HOME}/.claude/dev-agent-team}"
CLAUDE_COMMANDS_DIR="${CLAUDE_COMMANDS_DIR:-${HOME}/.claude/commands}"
CLAUDE_WORKFLOWS_DIR="${CLAUDE_WORKFLOWS_DIR:-${HOME}/.claude/workflows}"

# install.sh と対称: グローバル配置されたコマンド・Dynamic Workflow の一覧（manifest.sh に一本化）
# shellcheck source=manifest.sh
source "$(dirname "$0")/manifest.sh"

# ---- カラー出力 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ---- 削除処理 ----

REMOVED=0
SKIPPED=0
PROTECTED=0
TOTAL=${#COMMANDS[@]}
INDEX=0

for cmd in "${COMMANDS[@]}"; do
  INDEX=$((INDEX + 1))
  TARGET="${CLAUDE_COMMANDS_DIR}/${cmd}"

  if [ ! -e "${TARGET}" ] && [ ! -L "${TARGET}" ]; then
    info "[${INDEX}/${TOTAL}] スキップ（存在しない）: ${TARGET}"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ -L "${TARGET}" ]; then
    LINK_TARGET="$(readlink "${TARGET}")"

    # リンク先が dev-agent-team 配下でなければ別ツールの symlink とみなして消さない
    case "${LINK_TARGET}" in
      "${DEV_AGENT_TEAM_ROOT}"/*) ;;
      *)
        warn "[${INDEX}/${TOTAL}] 別ツールの symlink のためスキップ: ${TARGET} -> ${LINK_TARGET}"
        PROTECTED=$((PROTECTED + 1))
        continue
        ;;
    esac

    info "[${INDEX}/${TOTAL}] 削除: ${TARGET} -> ${LINK_TARGET}"
    rm -f "${TARGET}"

    if [ ! -e "${TARGET}" ] && [ ! -L "${TARGET}" ]; then
      REMOVED=$((REMOVED + 1))
    else
      error "[${INDEX}/${TOTAL}] 削除に失敗: ${TARGET}"
      exit 1
    fi
  elif [ -e "${TARGET}" ]; then
    warn "[${INDEX}/${TOTAL}] 実ファイルを検出（dev-agent-team が作成したものではない可能性）: ${TARGET}"
    warn "        削除する場合は手動で実行してください: rm ${TARGET}"
    PROTECTED=$((PROTECTED + 1))
  fi
done

# Dynamic Workflow の symlink も対称に削除する
WF_TOTAL=${#WORKFLOWS[@]}
WF_INDEX=0

for wf in "${WORKFLOWS[@]}"; do
  WF_INDEX=$((WF_INDEX + 1))
  TARGET="${CLAUDE_WORKFLOWS_DIR}/${wf}"

  if [ ! -e "${TARGET}" ] && [ ! -L "${TARGET}" ]; then
    info "[wf ${WF_INDEX}/${WF_TOTAL}] スキップ（存在しない）: ${TARGET}"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ -L "${TARGET}" ]; then
    LINK_TARGET="$(readlink "${TARGET}")"

    # リンク先が dev-agent-team 配下でなければ別ツールの symlink とみなして消さない
    case "${LINK_TARGET}" in
      "${DEV_AGENT_TEAM_ROOT}"/*) ;;
      *)
        warn "[wf ${WF_INDEX}/${WF_TOTAL}] 別ツールの symlink のためスキップ: ${TARGET} -> ${LINK_TARGET}"
        PROTECTED=$((PROTECTED + 1))
        continue
        ;;
    esac

    info "[wf ${WF_INDEX}/${WF_TOTAL}] 削除: ${TARGET} -> ${LINK_TARGET}"
    rm -f "${TARGET}"

    if [ ! -e "${TARGET}" ] && [ ! -L "${TARGET}" ]; then
      REMOVED=$((REMOVED + 1))
    else
      error "[wf ${WF_INDEX}/${WF_TOTAL}] 削除に失敗: ${TARGET}"
      exit 1
    fi
  elif [ -e "${TARGET}" ]; then
    warn "[wf ${WF_INDEX}/${WF_TOTAL}] 実ファイルを検出（dev-agent-team が作成したものではない可能性）: ${TARGET}"
    warn "        削除する場合は手動で実行してください: rm ${TARGET}"
    PROTECTED=$((PROTECTED + 1))
  fi
done

echo ""
info "結果: 削除 ${REMOVED} 件 / 不在 ${SKIPPED} 件 / 保護（実ファイル・別ツール symlink） ${PROTECTED} 件"

if [ "${REMOVED}" -eq 0 ] && [ "${PROTECTED}" -eq 0 ]; then
  info "アンインストールするものがありませんでした。"
  exit 0
fi

# ---- 完了 ----

echo ""
info "✅ dev-agent-team のグローバルコマンドをアンインストールしました。"
echo ""
echo "クローン本体を削除する場合（任意）:"
echo "  rm -rf ${DEV_AGENT_TEAM_ROOT}"
echo ""
echo "各対象リポジトリの .dev-agent-team/ は手動で削除してください（必要なら）。"
echo ""
