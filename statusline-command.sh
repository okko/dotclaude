#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

# Format directory: replace $HOME with ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Build the status line
parts=""

# Organization (from Claude Code account)
org=$(jq -r '.oauthAccount.organizationName // empty' "$HOME/.claude.json" 2>/dev/null)
parts="${org:-$(whoami)@$(hostname -s)}"

# Directory
[ -n "$short_cwd" ] && parts="$parts $short_cwd"

# Git branch (with dirty indicator)
[ -n "$branch" ] && parts="$parts ($branch$([ -n "$dirty" ] && printf '*'))"

# Model
[ -n "$model" ] && parts="$parts | $model"

# Context usage
[ -n "$used" ] && parts="$parts | ctx: $(printf '%.0f' "$used")%"

# Lines changed this session
[ -n "$added" ] && [ -n "$removed" ] && parts="$parts | +$added/-$removed"

# Money spent
[ -n "$cost" ] && parts="$parts | \$$(printf '%.2f' "$cost")"

printf '%s' "$parts"
