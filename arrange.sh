#!/bin/bash

# Arranges the internal + external display pair for the "My Display" panel's
# ARRANGEMENT section. The internal display is anchored at 0x0; the external
# display is placed left/top/right of it, aligned on the shared midpoint:
#   left/right -> vertical midpoints of both screens line up
#   top        -> horizontal midpoints of both screens line up
# Positions are computed in logical (post-scale) space, since that's the
# space Hyprland arranges monitors in.

set -euo pipefail

direction="${1:-}"
case "$direction" in
  left | top | right) ;;
  *)
    echo "Usage: arrange.sh left|top|right" >&2
    exit 1
    ;;
esac

monitors_json=$(hyprctl monitors -j)

internal=$(jq -r '
  [.[] | select(.disabled != true) | select(.name | test("^(eDP|LVDS|DSI)-"))][0].name // ""
' <<<"$monitors_json")

external=$(jq -r --arg internal "$internal" '
  [.[] | select(.disabled != true) | select(.name != $internal)][0].name // ""
' <<<"$monitors_json")

if [[ -z $internal || -z $external ]]; then
  echo "Need one enabled internal display and one enabled external display" >&2
  exit 1
fi

read -r int_w int_h int_scale <<<"$(jq -r --arg n "$internal" '
  .[] | select(.name == $n) | "\(.width) \(.height) \(.scale)"
' <<<"$monitors_json")"

read -r ext_w ext_h ext_scale <<<"$(jq -r --arg n "$external" '
  .[] | select(.name == $n) | "\(.width) \(.height) \(.scale)"
' <<<"$monitors_json")"

# Logical (post-scale) sizes, rounded to the nearest pixel.
read -r int_lw int_lh ext_lw ext_lh <<<"$(awk \
  -v iw="$int_w" -v ih="$int_h" -v is="$int_scale" \
  -v ew="$ext_w" -v eh="$ext_h" -v es="$ext_scale" \
  'BEGIN { printf "%d %d %d %d", iw/is+0.5, ih/is+0.5, ew/es+0.5, eh/es+0.5 }')"

round_half() { awk -v v="$1" 'BEGIN { printf "%d", (v >= 0 ? v + 0.5 : v - 0.5) }'; }

case "$direction" in
  left)
    ext_x=$(( -ext_lw ))
    ext_y=$(round_half "$(awk -v ih="$int_lh" -v eh="$ext_lh" 'BEGIN { print (ih - eh) / 2 }')")
    ;;
  right)
    ext_x=$int_lw
    ext_y=$(round_half "$(awk -v ih="$int_lh" -v eh="$ext_lh" 'BEGIN { print (ih - eh) / 2 }')")
    ;;
  top)
    ext_y=$(( -ext_lh ))
    ext_x=$(round_half "$(awk -v iw="$int_lw" -v ew="$ext_lw" 'BEGIN { print (iw - ew) / 2 }')")
    ;;
esac

hyprctl keyword monitor "${internal},preferred,0x0,${int_scale}" >/dev/null
hyprctl keyword monitor "${external},preferred,${ext_x}x${ext_y},${ext_scale}" >/dev/null

# Persist across restarts in monitors.lua, inside a clearly marked block so
# re-running this script (or picking a different direction) replaces it
# cleanly instead of piling up stale rules.
monitor_lua="$HOME/.config/hypr/monitors.lua"
begin_marker="-- omarchy-arrangement:begin (managed by the Display menu — edits inside are overwritten)"
end_marker="-- omarchy-arrangement:end"

if [[ -f $monitor_lua ]]; then
  tmp=$(mktemp)
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$monitor_lua" > "$tmp"

  {
    cat "$tmp"
    echo ""
    echo "$begin_marker"
    printf 'hl.monitor({ output = "%s", mode = "preferred", position = "0x0", scale = %s })\n' "$internal" "$int_scale"
    printf 'hl.monitor({ output = "%s", mode = "preferred", position = "%sx%s", scale = %s })\n' "$external" "$ext_x" "$ext_y" "$ext_scale"
    echo "$end_marker"
  } > "$monitor_lua"
  rm -f "$tmp"
fi
