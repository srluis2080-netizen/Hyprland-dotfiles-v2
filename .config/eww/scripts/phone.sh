#!/usr/bin/env bash
# Datos y acciones del movil via KDE Connect.
# Uso: phone.sh status | ring | clip
#   status -> JSON {"name","online","charge","charging","hot","icon"}
# Requiere: kdeconnect (daemon + kdeconnect-cli) y gdbus (glib2). Movil ya emparejado.

DEVICE_ID=""    # opcional: fija el ID de tu movil (mira el ID con: kdeconnect-cli -l)
LOW=15          # por debajo de este % se marca en rojo

# KDE Connect traduce su salida: se fuerza ingles para no depender del idioma del sistema
export LC_ALL=C LANGUAGE=en_US

KC()   { timeout 5 kdeconnect-cli "$@"; }
dbus() { timeout 4 gdbus call --session --dest org.kde.kdeconnect "$@" 2>/dev/null; }

# ---- Dispositivos por D-Bus (no depende del idioma) ----
# dbus_ids <solo_conectados> <solo_emparejados>  -> un ID por linea
dbus_ids() {
  dbus --object-path /modules/kdeconnect --method org.kde.kdeconnect.daemon.devices "$1" "$2" \
    | grep -oE "'[^']+'" | tr -d "'"
}
dbus_name() {
  dbus --object-path "/modules/kdeconnect/devices/$1" \
       --method org.freedesktop.DBus.Properties.Get org.kde.kdeconnect.device name \
    | sed -nE "s/^\(<'(.*)'>,\)$/\1/p"
}
pick_id() {   # elige DEVICE_ID si esta fijado; si no, el primero de la lista
  if [ -n "$DEVICE_ID" ]; then grep -xF "$DEVICE_ID" <<< "$1" | head -n 1
  else head -n 1 <<< "$1"; fi
}

# Devuelve "id|nombre|estado" (estado: "paired and reachable" o "paired"); vacio si no hay
find_device() {
  local ids id name
  ids=$(dbus_ids true true);  id=$(pick_id "$ids")
  if [ -n "$id" ]; then echo "$id|$(dbus_name "$id")|paired and reachable"; return 0; fi
  ids=$(dbus_ids false true); id=$(pick_id "$ids")
  if [ -n "$id" ]; then echo "$id|$(dbus_name "$id")|paired"; return 0; fi

  # Respaldo: kdeconnect-cli -l (salida en ingles: "- Nombre: id (paired and reachable)")
  local all pick
  all=$(KC -l 2>/dev/null | sed -nE 's/^- (.*): ([^ ]+) \((.*)\)$/\2|\1|\3/p')
  [ -z "$all" ] && return 0
  if [ -n "$DEVICE_ID" ]; then grep -F "$DEVICE_ID|" <<< "$all" | head -n 1; return 0; fi
  pick=$(grep '|paired and reachable$' <<< "$all" | head -n 1)
  [ -z "$pick" ] && pick=$(grep '|paired$' <<< "$all" | head -n 1)
  echo "$pick"
}

# Lee una propiedad de bateria por D-Bus (ruta nueva y, si falla, la antigua)
battery_prop() {
  local id=$1 p=$2 out
  out=$(dbus --object-path "/modules/kdeconnect/devices/$id/battery" \
        --method org.freedesktop.DBus.Properties.Get org.kde.kdeconnect.device.battery "$p") \
    && { echo "$out"; return 0; }
  dbus --object-path "/modules/kdeconnect/devices/$id" \
       --method "org.kde.kdeconnect.device.battery.$p"
}

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

IFS='|' read -r ID NAME STATE <<< "$(find_device)"

case "${1:-status}" in
  ring) [ "$STATE" = "paired and reachable" ] && KC -d "$ID" --ring ; exit 0 ;;
  clip) [ "$STATE" = "paired and reachable" ] && KC -d "$ID" --send-clipboard ; exit 0 ;;
esac

NAME="${NAME:-Movil}"
if [ "$STATE" != "paired and reachable" ]; then
  printf '{"name":"%s","online":"no","charge":"--","charging":"no","hot":"no","icon":"phone-off"}\n' "$(json_escape "$NAME")"
  exit 0
fi

charge=$(battery_prop "$ID" charge | tr -dc '0-9-')
chg_raw=$(battery_prop "$ID" isCharging)
charging=no; [[ "$chg_raw" == *true* ]] && charging=yes

if ! [[ "$charge" =~ ^[0-9]+$ ]] || [ "$charge" -gt 100 ]; then
  # conectado, pero sin dato de bateria (plugin desactivado o ruta desconocida)
  printf '{"name":"%s","online":"yes","charge":"--","charging":"%s","hot":"no","icon":"phone-white-0"}\n' "$(json_escape "$NAME")" "$charging"
  exit 0
fi

lit=$(( (charge + 9) / 10 ))
hot=no; color=white
if [ "$charging" = yes ] || [ "$charge" -le "$LOW" ]; then hot=yes; color=red; fi

printf '{"name":"%s","online":"yes","charge":"%s","charging":"%s","hot":"%s","icon":"phone-%s-%s"}\n' \
  "$(json_escape "$NAME")" "$charge" "$charging" "$hot" "$color" "$lit"
