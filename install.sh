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

set -euo pipefail

# ---- 設定 ----
DEV_AGENT_TEAM_ROOT="${DEV_AGENT_TEAM_ROOT:-${HOME}/.claude/dev-agent-team}"
CLAUDE_COMMANDS_DIR="${CLAUDE_COMMANDS_DIR:-${HOME}/.claude/commands}"
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

info "dev-agent-team の入口コマンドをインストールしています..."

mkdir -p "${CLAUDE_COMMANDS_DIR}"

TARGET="${CLAUDE_COMMANDS_DIR}/${ENTRY_COMMAND}"
SOURCE="${DEV_AGENT_TEAM_ROOT}/commands/${ENTRY_COMMAND}"

if [ -e "${TARGET}" ] || [ -L "${TARGET}" ]; then
  warn "既存ファイルを検出: ${TARGET}"
  warn "シンボリックリンクで上書きします: -> ${SOURCE}"
fi

ln -sf "${SOURCE}" "${TARGET}"

# ---- 検証 ----

if [ -L "${TARGET}" ]; then
  info "シンボリックリンクを作成しました: ${TARGET} -> ${SOURCE}"
else
  error "シンボリックリンクの作成に失敗しました"
  exit 1
fi

# ---- 完了 ----

echo ""
info "✅ dev-agent-team のインストールが完了しました。"
echo ""
echo "次の手順:"
echo "  1. 対象プロジェクトのディレクトリで Claude Code を開く"
echo "  2. /adopt-project を実行する"
echo "  3. プロンプトに従って dev-agent-team をプロジェクトにセットアップする"
echo ""
echo "あとで dev-agent-team を更新する場合:"
echo "  cd ${DEV_AGENT_TEAM_ROOT} && git pull"
echo ""
echo "アンインストール:"
echo "  cd ${DEV_AGENT_TEAM_ROOT} && ./uninstall.sh"
echo ""
