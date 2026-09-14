#!/bin/bash
export LC_NUMERIC=C LC_TIME=C
input=$(cat)

# Detect the active account from CLAUDE_CONFIG_DIR (set by the launching
# alias and inherited by this script regardless of which physical
# statusline.sh Claude Code ends up running due to settings precedence).
# Falls back to parsing transcript_path from the session JSON if the env
# var is somehow absent.
CONFIG_DIR="$CLAUDE_CONFIG_DIR"
if [ -z "$CONFIG_DIR" ]; then
    TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
    CONFIG_DIR=$(echo "$TRANSCRIPT" | grep -oE '/\.claude(-[a-zA-Z0-9_-]+)?/' | head -1 | tr -d '/')
fi
CONFIG_BASE=$(basename "${CONFIG_DIR:-.claude}")
case "$CONFIG_BASE" in
    .claude) ACCOUNT="default" ;;
    .claude-*) ACCOUNT="${CONFIG_BASE#.claude-}" ;;
    *) ACCOUNT="$CONFIG_BASE" ;;
esac

MODEL=$(echo "$input" | jq -r '.model.display_name')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
FIVE_H_USED=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK_USED=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
PR_NUMBER=$(echo "$input" | jq -r '.pr.number // empty')
PR_URL=$(echo "$input" | jq -r '.pr.url // empty')
PR_STATE=$(echo "$input" | jq -r '.pr.review_state // empty')

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; GRAY='\033[90m'; MAGENTA='\033[35m'; BLUE='\033[34m'; BRIGHT_CYAN='\033[96m'; BOLD='\033[1m'; RESET='\033[0m'
ANTHROPIC='\033[38;2;217;119;87m'
SEP="${GRAY} │ ${RESET}"

bar_color() {
    local pct=$1 base=${2:-$GREEN}
    if [ "$pct" -ge 90 ]; then echo "$RED"
    elif [ "$pct" -ge 70 ]; then echo "$YELLOW"
    else echo "$base"; fi
}

make_bar() {
    local pct=$1 width=${2:-10} filled empty fill pad
    filled=$((pct * width / 100)); empty=$((width - filled))
    printf -v fill "%${filled}s"; printf -v pad "%${empty}s"
    echo "${fill// /█}${pad// /░}"
}

BAR_COLOR=$(bar_color "$PCT" "$BRIGHT_CYAN")
BAR=$(make_bar "$PCT" 10)

TOTAL_SEC=$((DURATION_MS / 1000))
DAYS=$((TOTAL_SEC / 86400))
HOURS=$(((TOTAL_SEC % 86400) / 3600))
MINS=$(((TOTAL_SEC % 3600) / 60))
SECS=$((TOTAL_SEC % 60))

DURATION_FMT=""
[ "$DAYS" -gt 0 ] && DURATION_FMT="${DURATION_FMT}${DAYS}d "
[ "$HOURS" -gt 0 ] && DURATION_FMT="${DURATION_FMT}${HOURS}h "
[ "$MINS" -gt 0 ] || [ -n "$DURATION_FMT" ] && DURATION_FMT="${DURATION_FMT}${MINS}m "
DURATION_FMT="${DURATION_FMT}${SECS}s"

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

PR_FMT=""
if [ -n "$PR_NUMBER" ]; then
    case "$PR_STATE" in
        approved) PR_COLOR="$GREEN" ;;
        changes_requested) PR_COLOR="$RED" ;;
        draft) PR_COLOR="$GRAY" ;;
        *) PR_COLOR="$YELLOW" ;;
    esac
    PR_TEXT="#${PR_NUMBER}"
    if [ -n "$PR_URL" ]; then
        PR_LINK=$(printf '%b' "\e]8;;${PR_URL}\a${PR_TEXT}\e]8;;\a")
    else
        PR_LINK="$PR_TEXT"
    fi
    PR_FMT=" | ${PR_COLOR}🔀 ${PR_LINK}${RESET}"
fi

FIVE_H_SEG=""
if [ -n "$FIVE_H_USED" ]; then
    FIVE_H_INT=$(printf '%.0f' "$FIVE_H_USED")
    FIVE_H_BAR=$(make_bar "$FIVE_H_INT" 8)
    FIVE_H_COLOR=$(bar_color "$FIVE_H_INT" "$BLUE")
    FIVE_H_RESET_FMT=""
    [ -n "$FIVE_H_RESET" ] && FIVE_H_RESET_FMT=" ${GRAY}($(date -r "$FIVE_H_RESET" +"%H:%M" 2>/dev/null))${RESET}"
    FIVE_H_SEG="${BLUE}${BOLD}5h${RESET} ${FIVE_H_COLOR}${FIVE_H_BAR}${RESET} ${BOLD}${FIVE_H_INT}%${RESET}${FIVE_H_RESET_FMT}"
fi

WEEK_SEG=""
if [ -n "$WEEK_USED" ]; then
    WEEK_INT=$(printf '%.0f' "$WEEK_USED")
    WEEK_BAR=$(make_bar "$WEEK_INT" 8)
    WEEK_COLOR=$(bar_color "$WEEK_INT" "$MAGENTA")
    WEEK_RESET_FMT=""
    [ -n "$WEEK_RESET" ] && WEEK_RESET_FMT=" ${GRAY}($(date -r "$WEEK_RESET" +"%a %H:%M" 2>/dev/null))${RESET}"
    WEEK_SEG="${MAGENTA}${BOLD}wk${RESET} ${WEEK_COLOR}${WEEK_BAR}${RESET} ${BOLD}${WEEK_INT}%${RESET}${WEEK_RESET_FMT}"
fi

EFFORT_FMT=""
[ -n "$EFFORT" ] && EFFORT_FMT=" ($EFFORT)"
echo -e "${ANTHROPIC}[$MODEL$EFFORT_FMT | $ACCOUNT]${RESET} 📁 ${DIR}$BRANCH$PR_FMT"

COST_FMT=$(printf '$%.2f' "$COST")
LINE2="${BRIGHT_CYAN}${BOLD}ctx${RESET} ${BAR_COLOR}${BAR}${RESET} ${BOLD}${PCT}%${RESET}${SEP}${GREEN}${COST_FMT}${RESET}${SEP}⏱️ ${DURATION_FMT}"
[ -n "$FIVE_H_SEG" ] && LINE2="${LINE2}${SEP}${FIVE_H_SEG}"
[ -n "$WEEK_SEG" ] && LINE2="${LINE2}${SEP}${WEEK_SEG}"
echo -e "$LINE2"
exit 0
