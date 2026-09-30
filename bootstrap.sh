#!/bin/sh
# bootstrap.sh - server-setup para Debian 13 (DC-1 y VPS).
# Idempotente: se puede correr multiples veces sin romper nada.
#
# Uso:
#   ./bootstrap.sh dc1     # maquina local
#   ./bootstrap.sh vps     # servidor
#
# Flujo:
#   1. Instala paquetes de sistema (apt) segun perfil desde packages/apt.txt
#   2. Instala chezmoi si falta
#   3. chezmoi init --apply  -> aplica dotfiles y corre scripts run_once
#      (rustup, uv, cargo, binarios y clonado del agent viven en los run_once)

set -eu

REPO_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
PKG_FILE="$REPO_DIR/packages/apt.txt"

log() { printf '\033[1;32m[bootstrap]\033[0m %s\n' "$1"; }
err() { printf '\033[1;31m[bootstrap]\033[0m %s\n' "$1" >&2; }

# --- Validar perfil ---
PROFILE="${1:-}"
if [ "$PROFILE" != "dc1" ] && [ "$PROFILE" != "vps" ]; then
    err "Perfil invalido. Uso: $0 <dc1|vps>"
    exit 1
fi
log "Perfil seleccionado: $PROFILE"

# --- 1. Paquetes de sistema (apt) ---
if ! command -v apt-get >/dev/null 2>&1; then
    err "apt-get no encontrado. Este script requiere Debian/Ubuntu."
    exit 1
fi

if [ ! -f "$PKG_FILE" ]; then
    err "No existe $PKG_FILE"
    exit 1
fi

# Selecciona paquetes cuyo perfil es 'both' o coincide con el perfil actual.
# Ignora comentarios y lineas vacias.
PACKAGES="$(awk -v p="$PROFILE" '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    ($2 == "both" || $2 == p) { print $1 }
' "$PKG_FILE")"

if [ -n "$PACKAGES" ]; then
    log "Actualizando indice de paquetes apt..."
    sudo apt-get update -y
    log "Instalando paquetes: $(echo "$PACKAGES" | tr '\n' ' ')"
    # DEBIAN_FRONTEND=noninteractive evita prompts durante la instalacion.
    # shellcheck disable=SC2086
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES
else
    log "No hay paquetes para el perfil $PROFILE"
fi

# En Debian, fd-find instala el binario 'fdfind' y bat instala 'batcat'.
# Creamos symlinks en ~/.local/bin para usarlos como 'fd' y 'bat'.
mkdir -p "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log "Symlink fd -> fdfind creado en ~/.local/bin"
fi
if command -v batcat >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    log "Symlink bat -> batcat creado en ~/.local/bin"
fi

# --- 2. chezmoi ---
if ! command -v chezmoi >/dev/null 2>&1; then
    log "Instalando chezmoi en ~/.local/bin..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# --- 3. chezmoi init --apply ---
# Exporta el perfil para que las plantillas lo consuman sin preguntar de nuevo.
export CHEZMOI_PROFILE="$PROFILE"
log "Aplicando dotfiles con chezmoi (source: $REPO_DIR/home)..."
chezmoi init --apply --source "$REPO_DIR/home" --promptString "profile=$PROFILE"

log "Bootstrap completo para perfil $PROFILE."
log "Abre una nueva shell zsh para cargar el entorno."
