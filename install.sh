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

# グローバル配置するコマンド・Dynamic Workflow の一覧（manifest.sh に一本化）。
# ソースファイルと同じ DEV_AGENT_TEAM_ROOT から読み、両者が食い違わないようにする。
# shellcheck source=manifest.sh
source "${DEV_AGENT_TEAM_ROOT}/manifest.sh"

# 退避ファイルの接尾辞（実行ごとに一意）
BACKUP_SUFFIX=".bak.$(date +%Y%m%d-%H%M%S)"
BACKED_UP=0

# 1 件をリンクする。既存の配置先は次のように扱う:
#   - dev-agent-team 配下を指す symlink → 張り直す（自分のリンクの更新）
#   - それ以外（利用者の実ファイル・別ツールの symlink）→ 退避してからリンクする（黙って消さない）
# 引数: $1=ラベル $2=ソース $3=配置先
link_one() {
  local label="$1" source="$2" target="$3"

  if [ -L "${target}" ]; then
    case "$(readlink "${target}")" in
      "${DEV_AGENT_TEAM_ROOT}"/*) ;;
      *)
        warn "${label} 別ツールの symlink を退避: ${target} -> ${target}${BACKUP_SUFFIX}"
        mv "${target}" "${target}${BACKUP_SUFFIX}"
        BACKED_UP=$((BACKED_UP + 1))
        ;;
    esac
  elif [ -e "${target}" ]; then
    warn "${label} 既存の実ファイルを退避: ${target} -> ${target}${BACKUP_SUFFIX}"
    mv "${target}" "${target}${BACKUP_SUFFIX}"
    BACKED_UP=$((BACKED_UP + 1))
  fi

  ln -sfn "${source}" "${target}"

  if [ -L "${target}" ]; then
    info "${label} ${target} -> ${source}"
  else
    error "${label} シンボリックリンクの作成に失敗: ${target}"
    exit 1
  fi
}

# コマンドの frontmatter から description を取り出す（完了メッセージ用）
describe() {
  awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } /^description: / { sub(/^description: /, ""); print; exit }' "$1" 2>/dev/null || true
}

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

  link_one "[${INDEX}/${TOTAL}]" "${SOURCE}" "${TARGET}"
  INSTALLED=$((INSTALLED + 1))
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

    link_one "[${WF_INDEX}/${WF_TOTAL}]" "${WF_SOURCE}" "${WF_TARGET}"
    WF_INSTALLED=$((WF_INSTALLED + 1))
  done

  info "${WF_INSTALLED}/${WF_TOTAL} 個の Dynamic Workflow をインストールしました。"
  info "（利用には Claude Code v2.1.154 以降 + Dynamic Workflows の有効化が必要です）"
fi

# ---- 完了 ----

echo ""
info "✅ dev-agent-team のインストールが完了しました。"
echo ""
echo "利用可能になったコマンド:"
for cmd in "${COMMANDS[@]}"; do
  printf '  %-24s — %s\n' "/${cmd%.md}" "$(describe "${DEV_AGENT_TEAM_ROOT}/commands/${cmd}")"
done
echo ""
if [ "${#WORKFLOWS[@]}" -gt 0 ]; then
  echo "利用可能になった Dynamic Workflow（要 v2.1.154+ / 有効化）:"
  for wf in "${WORKFLOWS[@]}"; do
    echo "  /${wf%.js}"
  done
  echo ""
fi
if [ "${BACKED_UP}" -gt 0 ]; then
  warn "既存ファイル ${BACKED_UP} 件を ${BACKUP_SUFFIX} 付きで退避しました（不要なら手動で削除）。"
  echo ""
fi
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
