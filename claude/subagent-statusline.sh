#!/bin/bash
export LC_NUMERIC=C LC_TIME=C
input=$(cat)

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-.claude}"
CONFIG_BASE=$(basename "$CONFIG_DIR")
case "$CONFIG_BASE" in
    .claude) ACCOUNT="default" ;;
    .claude-*) ACCOUNT="${CONFIG_BASE#.claude-}" ;;
    *) ACCOUNT="$CONFIG_BASE" ;;
esac

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

echo "$input" | jq -c '.tasks[]' | while IFS= read -r task; do
    ID=$(echo "$task" | jq -r '.id')
    MODEL_RAW=$(echo "$task" | jq -r '.model // "?"')
    # Turn a resolved model id like "claude-sonnet-5" or "claude-haiku-4-5-20251001"
    # into a friendlier display form ("Sonnet 5", "Haiku 4.5").
    MODEL_BASE=$(echo "$MODEL_RAW" | sed -E 's/^claude-//; s/-[0-9]{8}$//')
    IFS='-' read -r MODEL_FAMILY MODEL_V1 MODEL_V2 <<< "$MODEL_BASE"
    if [ -n "$MODEL_FAMILY" ]; then
        MODEL_FAMILY_CAP="$(echo "${MODEL_FAMILY:0:1}" | tr '[:lower:]' '[:upper:]')${MODEL_FAMILY:1}"
        if [ -n "$MODEL_V2" ]; then
            MODEL="$MODEL_FAMILY_CAP $MODEL_V1.$MODEL_V2"
        elif [ -n "$MODEL_V1" ]; then
            MODEL="$MODEL_FAMILY_CAP $MODEL_V1"
        else
            MODEL="$MODEL_FAMILY_CAP"
        fi
    else
        MODEL="$MODEL_RAW"
    fi
    EFFORT=$(echo "$task" | jq -r '.effort // empty')
    CTXSIZE=$(echo "$task" | jq -r '.contextWindowSize // empty')
    TOKENS=$(echo "$task" | jq -r '.tokenCount // 0')
    CWD=$(echo "$task" | jq -r '.cwd // empty')

    PCT=0
    if [ -n "$CTXSIZE" ] && [ "$CTXSIZE" -gt 0 ] 2>/dev/null; then
        PCT=$(( TOKENS * 100 / CTXSIZE ))
    fi

    if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
    elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
    else BAR_COLOR="$GREEN"; fi

    FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
    printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
    BAR="${FILL// /█}${PAD// /░}"

    EFFORT_FMT=""
    [ -n "$EFFORT" ] && EFFORT_FMT=" ($EFFORT)"

    DIR_FMT=""
    [ -n "$CWD" ] && DIR_FMT=" 📁 ${CWD##*/}"

    CONTENT=$(printf '%b' "${CYAN}[$MODEL$EFFORT_FMT | $ACCOUNT]${RESET}$DIR_FMT ${BAR_COLOR}${BAR}${RESET} ${PCT}%")

    jq -n --arg id "$ID" --arg content "$CONTENT" '{id: $id, content: $content}'
done
exit 0
