#!/usr/bin/env bash
# Uso de CPU (%) desde la ultima vez que se ejecuto. Sin top, sin sleep.
F="${XDG_RUNTIME_DIR:-/tmp}/eww-cpu.prev"
read -r _ u n s i w q sq st _ < /proc/stat
total=$((u + n + s + i + w + q + sq + st))
idle=$((i + w))
pct=0
if [ -f "$F" ]; then
  read -r pt pi < "$F"
  dt=$((total - pt)); di=$((idle - pi))
  [ "$dt" -gt 0 ] && pct=$(( 100 * (dt - di) / dt ))
fi
echo "$total $idle" > "$F"
echo "$pct"
