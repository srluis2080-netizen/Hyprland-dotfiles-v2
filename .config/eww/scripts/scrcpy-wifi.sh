#!/usr/bin/env bash
# Comparte la pantalla del movil por WiFi con scrcpy: busca la IP y el puerto solo.
# Uso: scrcpy-wifi.sh toggle | start [opciones de scrcpy...] | stop | pair
#   toggle  -> si scrcpy esta abierto lo cierra; si no, conecta y lo abre (lo usa el widget)
#   pair    -> vinculacion UNICA con el codigo de 6 digitos (ejecutalo en una terminal)
# Requiere: android-tools (adb), scrcpy. Recomendado: nmap (plan B si falla mDNS).
# En el movil (Android 11+): Opciones de desarrollador > Depuracion inalambrica.

PHONE_IP=""                  # opcional: IP fija del movil (si esta vacio se detecta)
PHONE_PORT=""                # opcional: puerto fijo (p. ej. 5555 tras "adb tcpip 5555"). Con IP y puerto fijos no se busca nada
ADB_PORT_RANGE="30000-50000" # rango donde Android pone el puerto de depuracion inalambrica
TITLE="Movil"

# ---- Opciones de scrcpy (adaptadas de tu scrcpy-usb.sh) ----
BITRATE="6M"                     # si hay cortes o lag por WiFi, prueba 4M
MAX_SIZE="1200"
FPS="60"
CODEC="--video-codec=h264"
AUDIO="--audio-codec=opus --audio-buffer=30"
TECLADO="--keyboard=uhid"        # uhid funciona por WiFi
MOUSE="--mouse=uhid"             # --mouse=aoa SOLO funciona por USB; uhid es la alternativa inalambrica
# --stay-awake solo actua si el movil esta enchufado a la corriente (es asi segun scrcpy)
EXTRAS="--turn-screen-off --stay-awake --power-off-on-close"

msg() {
  echo "$1: $2" >&2
  command -v notify-send >/dev/null 2>&1 && notify-send -a "Movil" "$1" "$2"
}

need() {
  command -v "$1" >/dev/null 2>&1 || { msg "Falta $1" "Instala el paquete: $2"; exit 1; }
}

mirror_running() { pgrep -x scrcpy >/dev/null 2>&1; }

# Serial de un movil ya conectado por red (ip:puerto o servicio mDNS)
connected_serial() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device" && ($1 ~ /:/ || $1 ~ /_adb-tls/) {print $1; exit}'
}

# IP del movil: la fija, o la que usa kdeconnectd en sus conexiones TCP
phone_ip() {
  if [ -n "$PHONE_IP" ]; then echo "$PHONE_IP"; return; fi
  ss -tnpH 2>/dev/null | awk '/kdeconnectd/ {print $5}' \
    | sed -E 's/^\[?(::ffff:)?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*$/\2/' \
    | grep -E '^[0-9.]+$' | head -n 1
}

AUTH_FAIL=0
SERIAL=""
try_connect() {   # try_connect ip:puerto
  local out
  out=$(timeout 8 adb connect "$1" 2>&1)
  if grep -qiE '^(already )?connected to' <<< "$out"; then SERIAL="$1"; return 0; fi
  grep -qiE 'authenticat|unauthorized' <<< "$out" && AUTH_FAIL=1
  return 1
}

# Busca IP y puerto y conecta con adb. Deja el resultado en $SERIAL.
discover_and_connect() {
  local ip entries entry="" ports p
  ip=$(phone_ip)

  # 0) IP y puerto fijos: conexion directa, sin buscar (si falla, sigue con la busqueda normal)
  if [ -n "$ip" ] && [ -n "$PHONE_PORT" ]; then
    try_connect "$ip:$PHONE_PORT" && return 0
  fi

  # 1) mDNS: Android anuncia el puerto aleatorio de la depuracion inalambrica
  entries=$(timeout 8 adb mdns services 2>/dev/null | awk '/_adb-tls-connect\._tcp/ {print $NF}')
  if [ -n "$entries" ]; then
    [ -n "$ip" ] && entry=$(grep -F "$ip:" <<< "$entries" | head -n 1)
    # solo se cae al primer servicio de la lista si NO fijaste PHONE_IP (evita conectar a otro movil)
    [ -z "$entry" ] && [ -z "$PHONE_IP" ] && entry=$(head -n 1 <<< "$entries")
    [ -n "$entry" ] && try_connect "$entry" && return 0
  fi

  [ -z "$ip" ] && return 1

  # 2) puerto clasico 5555 (si alguna vez hiciste: adb tcpip 5555)
  try_connect "$ip:5555" && return 0

  # 3) escaneo de puertos con nmap (plan B si mDNS no funciona)
  if command -v nmap >/dev/null 2>&1; then
    ports=$(nmap -p "$ADB_PORT_RANGE" --open -T4 -oG - "$ip" 2>/dev/null | grep -oE '[0-9]+/open' | cut -d/ -f1)
    for p in $ports; do
      try_connect "$ip:$p" && return 0
    done
  fi
  return 1
}

EXTRA_ARGS=()

start() {
  need adb android-tools
  need scrcpy scrcpy
  mirror_running && return 0

  SERIAL=$(connected_serial)
  if [ -z "$SERIAL" ]; then
    if ! discover_and_connect; then
      if [ "$AUTH_FAIL" = 1 ]; then
        msg "Movil sin vincular" "Ejecuta una sola vez en una terminal: scrcpy-wifi.sh pair"
      else
        msg "No encontre el movil" "Activa 'Depuracion inalambrica' (misma red WiFi). Sin mDNS necesito nmap y KDE Connect conectado."
      fi
      exit 1
    fi
  fi

  local opts=(-s "$SERIAL" --window-title "$TITLE"
              -b "$BITRATE" -m "$MAX_SIZE" --max-fps "$FPS")
  # las variables de opciones se dejan sin comillas a proposito (pueden traer varios argumentos)
  # shellcheck disable=SC2206
  opts+=($AUDIO $CODEC $EXTRAS $TECLADO $MOUSE "${EXTRA_ARGS[@]}")
  setsid -f scrcpy "${opts[@]}" >/dev/null 2>&1
  msg "Movil" "Compartiendo pantalla ($SERIAL)"
}

stop() { pkill -x scrcpy; }

pair() {
  need adb android-tools
  local entry code
  entry=$(timeout 8 adb mdns services 2>/dev/null | awk '/_adb-tls-pairing\._tcp/ {print $NF; exit}')
  if [ -z "$entry" ]; then
    echo "En el movil: Depuracion inalambrica > Vincular dispositivo con codigo."
    read -rp "IP:puerto de vinculacion: " entry
  else
    echo "Servicio de vinculacion encontrado: $entry"
  fi
  read -rp "Codigo de 6 digitos: " code
  adb pair "$entry" "$code"
}

CMD="${1:-toggle}"
[ $# -gt 0 ] && shift
EXTRA_ARGS=("$@")     # argumentos extra para scrcpy, p. ej.: scrcpy-wifi.sh start --no-audio

case "$CMD" in
  toggle) if mirror_running; then stop; else start; fi ;;
  start)  start ;;
  stop)   stop ;;
  pair)   pair ;;
  *) echo "Uso: $0 toggle|start|stop|pair" >&2; exit 1 ;;
esac
