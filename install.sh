#!/usr/bin/env bash
# Instalador de dotfiles - srluis2080
# Uso: ./install.sh [--sin-paquetes] [-h]

set -Eeuo pipefail
trap 'echo -e "\n${ROJO:-}[ERROR] El script fallo en la linea $LINENO.${NC:-}" >&2' ERR

# ── Colores ────────────────────────────────────────────
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
ROJO='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${AZUL}$*${NC}"; }
paso()  { echo -e "\n${AMARILLO}[$1/$TOTAL_PASOS] $2${NC}"; }
aviso() { echo -e "${AMARILLO}  ! $*${NC}"; }
ok()    { echo -e "${VERDE}$*${NC}"; }

TOTAL_PASOS=5
INSTALAR_PAQUETES=1

# ── Argumentos ─────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --sin-paquetes) INSTALAR_PAQUETES=0 ;;
        -h|--help)
            echo "Uso: $0 [--sin-paquetes]"
            echo "  --sin-paquetes   Omite la instalacion de paquetes (solo copia configuraciones)"
            exit 0
            ;;
        *) echo "Opcion desconocida: $arg" >&2; exit 1 ;;
    esac
done

# ── Comprobaciones previas ─────────────────────────────
if [ "$EUID" -eq 0 ]; then
    echo -e "${ROJO}No ejecutes este script como root (se usaria el HOME de root).${NC}" >&2
    exit 1
fi

# Directorio del repositorio (funciona sin importar desde donde lo llames)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$DOTFILES_DIR/.config" ]; then
    echo -e "${ROJO}No encuentro la carpeta .config en $DOTFILES_DIR${NC}" >&2
    exit 1
fi

info "=========================================="
info "   Instalador de Dotfiles - srluis2080    "
info "=========================================="

# ── 1. Paquetes ────────────────────────────────────────
# Repos oficiales. Si alguno no esta (por ejemplo eww, que es del AUR),
# se instala con el ayudante de AUR.
PAQUETES=(
    hyprland
    waybar
    swaync
    fuzzel
    kitty
    eww
    thunar
    btop
    cava
    fastfetch
    fish
    yazi
    ttf-jetbrains-mono-nerd
    # Dependencias de los widgets de eww
    playerctl
    ddcutil
    grim
    slurp
    wl-clipboard
    libpulse          # pactl
    wireplumber       # wpctl
    bluez-utils       # bluetoothctl
    pavucontrol
    hyprsunset
    curl
    noto-fonts
)

instalar_paquetes() {
    if ! command -v pacman >/dev/null 2>&1; then
        aviso "pacman no encontrado: omito la instalacion de paquetes (solo para Arch)."
        return 0
    fi

    local oficiales=() aur=() p
    for p in "$@"; do
        # pacman -T devuelve 0 si ya esta instalado o si lo provee otro paquete
        # (por ejemplo eww-git provee eww): en ese caso no hay que tocarlo
        if pacman -T "$p" >/dev/null 2>&1; then
            continue
        elif pacman -Si "$p" >/dev/null 2>&1; then
            oficiales+=("$p")
        else
            aur+=("$p")
        fi
    done

    if [ "${#oficiales[@]}" -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${oficiales[@]}"
    fi

    if [ "${#aur[@]}" -gt 0 ]; then
        local helper=""
        if command -v paru >/dev/null 2>&1; then helper="paru"
        elif command -v yay >/dev/null 2>&1; then helper="yay"
        fi

        if [ -n "$helper" ]; then
            echo "  Paquetes del AUR con $helper: ${aur[*]}"
            "$helper" -S --needed --noconfirm "${aur[@]}"
        else
            aviso "No estan en los repos oficiales y no hay paru/yay: ${aur[*]}"
            aviso "Instalalos a mano desde el AUR (para eww puedes usar eww o eww-git)."
        fi
    fi
}

if [ "$INSTALAR_PAQUETES" -eq 1 ]; then
    paso 1 "Instalando paquetes necesarios..."
    instalar_paquetes "${PAQUETES[@]}"
else
    paso 1 "Instalacion de paquetes omitida (--sin-paquetes)"
fi

# Activar nullglob/dotglob: incluye archivos ocultos y no falla si no hay coincidencias
shopt -s nullglob dotglob

# ── 2. Respaldo ────────────────────────────────────────
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
paso 2 "Respaldando configuraciones existentes en: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

NOMBRES=()
for ruta in "$DOTFILES_DIR"/.config/*; do
    nombre="$(basename "$ruta")"
    NOMBRES+=("$nombre")
    if [ -e "$HOME/.config/$nombre" ]; then
        cp -a "$HOME/.config/$nombre" "$BACKUP_DIR/"
    fi
done

# Si no habia nada que respaldar, no dejes una carpeta vacia
rmdir "$BACKUP_DIR" 2>/dev/null && BACKUP_DIR="" || true

# ── 3. Configuraciones ─────────────────────────────────
paso 3 "Copiando configuraciones a ~/.config..."
mkdir -p "$HOME/.config"
cp -rf --preserve=mode "$DOTFILES_DIR/.config/." "$HOME/.config/"

# Los scripts dentro de las configuraciones (eww, waybar, hypr...) deben ser ejecutables
for nombre in "${NOMBRES[@]}"; do
    if [ -d "$HOME/.config/$nombre" ]; then
        find "$HOME/.config/$nombre" -type f -name '*.sh' -exec chmod +x {} +
    fi
done

# ── 4. Scripts personales ──────────────────────────────
paso 4 "Instalando scripts personales en ~/.local/bin..."
if [ -d "$DOTFILES_DIR/scripts" ]; then
    mkdir -p "$HOME/.local/bin"
    while IFS= read -r -d '' f; do
        rel="${f#"$DOTFILES_DIR/scripts/"}"
        install -Dm755 "$f" "$HOME/.local/bin/$rel"
    done < <(find "$DOTFILES_DIR/scripts" -type f -print0)
else
    echo "  (no hay carpeta scripts, omitido)"
fi

# ── 5. Fuentes ─────────────────────────────────────────
# fontconfig NO escanea ~/.config/fonts: las fuentes van en ~/.local/share/fonts
paso 5 "Instalando fuentes personalizadas..."
FUENTES_COPIADAS=0
for origen in "$DOTFILES_DIR/fonts" "$DOTFILES_DIR/.config/fonts"; do
    if [ -d "$origen" ]; then
        mkdir -p "$HOME/.local/share/fonts/dotfiles"
        cp -rf --preserve=mode "$origen/." "$HOME/.local/share/fonts/dotfiles/"
        FUENTES_COPIADAS=1
    fi
done

if [ "$FUENTES_COPIADAS" -eq 1 ]; then
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f >/dev/null 2>&1
        echo "  Cache de fuentes actualizada."
    fi
else
    echo "  (no hay carpeta fonts, omitido)"
fi

# ── Avisos finales ─────────────────────────────────────
echo
ok "Instalacion completada."
if [ -n "$BACKUP_DIR" ]; then
    ok "Tu configuracion anterior se guardo en: $BACKUP_DIR"
fi

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) aviso "~/.local/bin no esta en tu PATH. En fish: fish_add_path ~/.local/bin" ;;
esac

if command -v locale >/dev/null 2>&1 && ! locale -a 2>/dev/null | grep -qi '^es_ES'; then
    aviso "No esta generado el locale es_ES (los widgets muestran la fecha en ingles)."
    aviso "Descomenta 'es_ES.UTF-8 UTF-8' en /etc/locale.gen y ejecuta: sudo locale-gen"
fi

if command -v systemctl >/dev/null 2>&1 && ! systemctl is-enabled bluetooth.service >/dev/null 2>&1; then
    aviso "El servicio de Bluetooth no esta activo. Para bluetoothctl: sudo systemctl enable --now bluetooth"
fi

info "Reinicia tu sesion de Hyprland para aplicar todos los cambios."