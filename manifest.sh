#!/bin/bash
#
# dev-agent-team manifest
#
# install.sh / uninstall.sh から source される共通定義。
# グローバル配置するコマンド・Dynamic Workflow の一覧をここに一本化する。
# 追加・削除はこのファイルだけを編集すればよい。

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
