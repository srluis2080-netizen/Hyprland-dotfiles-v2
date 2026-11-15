#!/usr/bin/env bash
# Temporizador para eww.
# Uso: timer.sh status | toggle | reset | set <min> | scroll up|down | session-reset
# Estado en $XDG_RUNTIME_DIR (o /tmp). Requiere (opcional): notify-send, paplay

DIR="${XDG_RUNTIME_DIR:-/tmp}"
STATE="$DIR/eww-timer.state"
LOCK="$DIR/eww-timer.lock"

DEFAULT_MIN=30          # duracion inicial
MIN_SEC=60              # minimo ajustable: 1 min
MAX_SEC=$((180 * 60))   # maximo ajustable: 180 min
SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"

# Evita carreras entre el poll de cada segundo y los clics
exec 9> "$LOCK"
flock 9

TOTAL=$((DEFAULT_MIN * 60)); REMAIN=$TOTAL; END=0; RUNNING=0; SESSION=1

load() {
  [ -f "$STATE" ] || return 0
  local k v
  while IFS='=' read -r k v; do
    [[ "$v" =~ ^[0-9]+$ ]] || continue
    case "$k" in TOTAL|REMAIN|END|RUNNING|SESSION) printf -v "$k" '%s' "$v" ;; esac
  done < "$STATE"
}

save() {
  printf 'TOTAL=%s\nREMAIN=%s\nEND=%s\nRUNNING=%s\nSESSION=%s\n' \
    "$TOTAL" "$REMAIN" "$END" "$RUNNING" "$SESSION" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
}

now=$(date +%s)
load

# Si estaba corriendo y ya termino: notifica una sola vez y prepara la siguiente sesion
if [ "$RUNNING" = 1 ] && [ $((END - now)) -le 0 ]; then
  RUNNING=0; REMAIN=$TOTAL
  # 9>&- : los procesos en segundo plano no deben heredar el candado
  command -v notify-send >/dev/null 2>&1 && \
    notify-send -a "Temporizador" "Tiempo terminado" "Sesión $SESSION completada" 9>&- &
  [ -f "$SOUND" ] && command -v paplay >/dev/null 2>&1 && paplay "$SOUND" 9>&- &
  SESSION=$((SESSION + 1))
  save
fi

case "${1:-status}" in
  toggle)
    if [ "$RUNNING" = 1 ]; then
      REMAIN=$((END - now)); RUNNING=0
    else
      [ "$REMAIN" -le 0 ] && REMAIN=$TOTAL
      END=$((now + REMAIN)); RUNNING=1
    fi
    save ;;
  reset)
    RUNNING=0; REMAIN=$TOTAL; save ;;
  set)
    if [[ "${2:-}" =~ ^[0-9]+$ ]] && [ "$2" -ge 1 ] && [ "$2" -le 180 ]; then
      TOTAL=$(($2 * 60)); REMAIN=$TOTAL; RUNNING=0; save
    fi ;;
  scroll)
    if [ "$RUNNING" = 0 ]; then
      if [ "${2:-}" = up ]; then TOTAL=$((TOTAL + 60)); else TOTAL=$((TOTAL - 60)); fi
      [ "$TOTAL" -lt "$MIN_SEC" ] && TOTAL=$MIN_SEC
      [ "$TOTAL" -gt "$MAX_SEC" ] && TOTAL=$MAX_SEC
      REMAIN=$TOTAL; save
    fi ;;
  session-reset)
    SESSION=1; save ;;
  status) ;;
  *) echo "Uso: $0 status|toggle|reset|set <min>|scroll up|down|session-reset" >&2; exit 1 ;;
esac

# Salida JSON (todo como texto para comparar facil desde eww)
if [ "$RUNNING" = 1 ]; then left=$((END - now)); else left=$REMAIN; fi
[ "$left" -lt 0 ] && left=0
pct=$(( (TOTAL - left) * 100 / TOTAL ))
running=no; [ "$RUNNING" = 1 ] && running=yes
printf '{"time":"%02d:%02d","running":"%s","total":"%d","session":"%d","pct":"%d"}\n' \
  $((left / 60)) $((left % 60)) "$running" $((TOTAL / 60)) "$SESSION" "$pct"
