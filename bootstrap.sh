#!/bin/sh
# bootstrap.sh - server-setup multiplataforma (Debian, Termux/Android, macOS).
# Idempotente: se puede correr multiples veces sin romper nada.
#
# Uso:
#   ./bootstrap.sh dc1     # maquina cliente (local)
#   ./bootstrap.sh vps     # servidor
#
# Detecta el gestor de paquetes (apt | pkg | brew) y usa la columna adecuada
# de packages/system.txt. Luego instala chezmoi y aplica dotfiles + run_once.

set -eu

REPO_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
PKG_FILE="$REPO_DIR/packages/system.txt"

log() { printf '\033[1;32m[bootstrap]\033[0m %s\n' "$1"; }
err() { printf '\033[1;31m[bootstrap]\033[0m %s\n' "$1" >&2; }

# --- Validar perfil ---
PROFILE="${1:-}"
if [ "$PROFILE" != "dc1" ] && [ "$PROFILE" != "vps" ]; then
    err "Perfil invalido. Uso: $0 <dc1|vps>"
    exit 1
fi
log "Perfil seleccionado: $PROFILE"

# --- Detectar gestor de paquetes ---
# Termux define $PREFIX con com.termux y trae 'pkg'. Debian trae 'apt-get'.
# macOS trae 'brew'. La columna en system.txt se elige segun esto.
detect_pkgmgr() {
    if [ -n "${PREFIX:-}" ] && command -v pkg >/dev/null 2>&1 && \
       printf '%s' "$PREFIX" | grep -q com.termux; then
        echo "pkg"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    else
        echo ""
    fi
}

PKGMGR="$(detect_pkgmgr)"
if [ -z "$PKGMGR" ]; then
    err "No se detecto apt, pkg (Termux) ni brew. Gestor no soportado."
    exit 1
fi
log "Gestor de paquetes detectado: $PKGMGR"

if [ ! -f "$PKG_FILE" ]; then
    err "No existe $PKG_FILE"
    exit 1
fi

# --- Seleccionar la columna del gestor ---
# Columnas de system.txt: 1=id 2=perfil 3=apt 4=pkg 5=brew
case "$PKGMGR" in
    apt)  COL=3 ;;
    pkg)  COL=4 ;;
    brew) COL=5 ;;
esac

# Paquetes del perfil (both o el actual), tomando la columna del gestor.
# Se ignoran comentarios, vacias y los marcados '-' (no aplica en ese gestor).
PACKAGES="$(awk -v p="$PROFILE" -v c="$COL" '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    ($2 == "both" || $2 == p) && $c != "-" { print $c }
' "$PKG_FILE")"

# --- Instalar paquetes segun gestor ---
if [ -n "$PACKAGES" ]; then
    PKGLIST="$(echo "$PACKAGES" | tr '\n' ' ')"
    log "Instalando ($PKGMGR): $PKGLIST"
    case "$PKGMGR" in
        apt)
            sudo apt-get update -y
            # shellcheck disable=SC2086
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $PKGLIST
            ;;
        pkg)
            pkg update -y
            # shellcheck disable=SC2086
            pkg install -y $PKGLIST
            ;;
        brew)
            # shellcheck disable=SC2086
            brew install $PKGLIST
            ;;
    esac
else
    log "No hay paquetes para el perfil $PROFILE en $PKGMGR"
fi

# En Debian, fd-find instala 'fdfind' y bat instala 'batcat'; symlinks a fd/bat.
# En Termux/brew los binarios ya se llaman fd/bat, asi que esto solo aplica a apt.
mkdir -p "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log "Symlink fd -> fdfind creado en ~/.local/bin"
fi
if command -v batcat >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    log "Symlink bat -> batcat creado en ~/.local/bin"
fi

# --- chezmoi ---
if ! command -v chezmoi >/dev/null 2>&1; then
    log "Instalando chezmoi en ~/.local/bin..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# --- chezmoi init --apply ---
export CHEZMOI_PROFILE="$PROFILE"
GIT_NAME="$(git config --global user.name 2>/dev/null || echo devlab)"
GIT_EMAIL="$(git config --global user.email 2>/dev/null || echo devlab@localhost)"

log "Aplicando dotfiles con chezmoi (source: $REPO_DIR/home)..."
chezmoi init --apply --source "$REPO_DIR/home" \
    --promptDefaults \
    --promptString "profile=$PROFILE" \
    --promptString "gitName=$GIT_NAME" \
    --promptString "gitEmail=$GIT_EMAIL"

log "Bootstrap completo para perfil $PROFILE ($PKGMGR)."
log "Abre una nueva shell zsh para cargar el entorno."
