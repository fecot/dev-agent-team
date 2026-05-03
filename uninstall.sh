#!/bin/bash
#
# dev-agent-team uninstaller
#
# 使い方:
#   cd ~/.claude/dev-agent-team
#   ./uninstall.sh
#
# このスクリプトは以下を行います:
#   - ~/.claude/commands/adopt-project.md のシンボリックリンクを削除
#
# このスクリプトは以下を行いません（手動で削除してください）:
#   - ~/.claude/dev-agent-team/ のクローン削除（rm -rf ~/.claude/dev-agent-team）
#   - 対象リポジトリの .dev-agent-team/ ディレクトリ
#
# 環境変数:
#   DEV_AGENT_TEAM_ROOT  クローン先（デフォルト: ~/.claude/dev-agent-team）
#   CLAUDE_COMMANDS_DIR  入口コマンドの配置先（デフォルト: ~/.claude/commands）

set -euo pipefail

# ---- 設定 ----
DEV_AGENT_TEAM_ROOT="${DEV_AGENT_TEAM_ROOT:-${HOME}/.claude/dev-agent-team}"
CLAUDE_COMMANDS_DIR="${CLAUDE_COMMANDS_DIR:-${HOME}/.claude/commands}"
ENTRY_COMMAND="adopt-project.md"
TARGET="${CLAUDE_COMMANDS_DIR}/${ENTRY_COMMAND}"

# ---- カラー出力 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ---- 削除対象の確認 ----

if [ ! -e "${TARGET}" ] && [ ! -L "${TARGET}" ]; then
  warn "シンボリックリンクが存在しません: ${TARGET}"
  info "アンインストールするものがありません。終了します。"
  exit 0
fi

if [ -L "${TARGET}" ]; then
  LINK_TARGET="$(readlink "${TARGET}")"
  info "シンボリックリンクを削除します: ${TARGET} -> ${LINK_TARGET}"
elif [ -e "${TARGET}" ]; then
  warn "シンボリックリンクではなく実ファイルが存在します: ${TARGET}"
  warn "dev-agent-team が作成したものではない可能性があります。"
  warn "削除を続行する場合は手動で削除してください: rm ${TARGET}"
  exit 1
fi

# ---- 削除 ----

rm -f "${TARGET}"

# ---- 検証 ----

if [ ! -e "${TARGET}" ] && [ ! -L "${TARGET}" ]; then
  info "削除しました: ${TARGET}"
else
  error "削除に失敗しました: ${TARGET}"
  exit 1
fi

# ---- 完了 ----

echo ""
info "✅ dev-agent-team の入口コマンドをアンインストールしました。"
echo ""
echo "クローン本体を削除する場合（任意）:"
echo "  rm -rf ${DEV_AGENT_TEAM_ROOT}"
echo ""
echo "対象リポジトリの .dev-agent-team/ は手動で削除してください（必要なら）。"
echo ""
