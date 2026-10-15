#!/bin/sh
# setup.sh - punto de entrada unico de devlab.
# Configura tu estacion de trabajo con un solo comando, desde cualquier
# dispositivo (Linux, Mac, WSL, Android/Termux). Solo requiere `sh`, y para el
# caso VPS tambien `ssh`.
#
# Uso directo (sin clonar nada):
#   curl -fsSL https://raw.githubusercontent.com/bit-crew/devlab/main/setup.sh | sh
#
# O si ya tienes el repo:
#   sh setup.sh
#
# Pregunta que configurar:
#   1) VPS (perfil vps)                        -> instala el entorno via SSH
#   2) Cliente / este equipo (perfil dc1)      -> bootstrap local (pendiente)
#
# Modelo de responsabilidades:
#   - Configurar el VPS: se hace desde CUALQUIER PC con IP + usuario + password
#     (la password temporal de OVH). Solo deja el VPS con el entorno instalado.
#     NO instala claves SSH: enlazar un cliente al VPS es tarea del cliente.
#   - Configurar el cliente (tablet, etc.): instala el entorno local, genera su
#     propia clave SSH y la registra en el VPS. (Paso siguiente, aun no aqui.)

set -eu

REPO_URL="https://github.com/bit-crew/devlab.git"
REPO_DIR="devlab"

log() { printf '\033[1;32m[setup]\033[0m %s\n' "$1"; }
err() { printf '\033[1;31m[setup]\033[0m %s\n' "$1" >&2; }

# Con `curl | sh`, stdin es el script, no el teclado. Leemos de /dev/tty para
# que las preguntas interactivas funcionen igual en pipe o en ejecucion normal.
if [ -r /dev/tty ]; then
    TTY=/dev/tty
else
    TTY=/dev/stdin
fi

ask() {
    # ask <prompt> <default>  -> imprime el valor leido (o el default)
    _prompt="$1"; _default="${2:-}"
    if [ -n "$_default" ]; then
        printf '%s [%s]: ' "$_prompt" "$_default" >/dev/tty
    else
        printf '%s: ' "$_prompt" >/dev/tty
    fi
    read -r _ans <"$TTY" || _ans=""
    [ -z "$_ans" ] && _ans="$_default"
    printf '%s' "$_ans"
}

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || echo '')"

# ---------------------------------------------------------------------------
# VPS: instala el entorno en un servidor remoto (perfil vps).
# Conexion con IP + usuario + password (interactiva). Sin claves SSH.
# ---------------------------------------------------------------------------
setup_vps() {
    command -v ssh >/dev/null 2>&1 || { err "'ssh' no esta instalado."; exit 1; }

    log "Datos del VPS (Enter para aceptar el valor entre corchetes):"
    VPS_HOST="$(ask 'IP publica del VPS' '')"
    VPS_USER="$(ask 'Usuario SSH' 'debian')"
    [ -n "$VPS_HOST" ] || { err "IP vacia. Aborto."; exit 1; }

    log "Objetivo: $VPS_USER@$VPS_HOST"
    log "Se conectara por SSH; escribe la password del VPS si la pide."

    # Bootstrap en frio: git/curl, clonar repo, ejecutar bootstrap.sh vps.
    # SSH usa lo que funcione: si este PC ya tiene clave en el VPS, entra por
    # clave; si no, pide password. -t asigna TTY para que un eventual prompt de
    # sudo (si no es NOPASSWD) pueda responderse.
    log "Instalando el entorno en el VPS (puede tardar varios minutos)..."
    ssh -t -o StrictHostKeyChecking=accept-new \
        "$VPS_USER@$VPS_HOST" "
        if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
            sudo apt-get update -y &&
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git curl;
        fi &&
        if [ -d $REPO_DIR/.git ]; then
            git -C $REPO_DIR pull --ff-only;
        else
            git clone $REPO_URL $REPO_DIR;
        fi &&
        cd $REPO_DIR && chmod +x bootstrap.sh && ./bootstrap.sh vps
    "

    log "VPS configurado con el entorno devlab."
    log "Entra con: ssh $VPS_USER@$VPS_HOST  (y ejecuta 'zsh' para el entorno)"
}

# ---------------------------------------------------------------------------
# Cliente: configura ESTA maquina (perfil dc1). Pendiente (siguiente paso).
# ---------------------------------------------------------------------------
setup_client() {
    err "La configuracion del cliente (dc1) aun no esta implementada."
    err "Por ahora solo esta disponible la opcion VPS."
    exit 1
}

# ---------------------------------------------------------------------------
# Punto de entrada: preguntar rol (o aceptarlo como argumento: dc1 | vps).
# ---------------------------------------------------------------------------
ROLE="${1:-}"
if [ -z "$ROLE" ]; then
    printf '\n¿Que quieres configurar?\n' >/dev/tty
    printf '  1) VPS\n' >/dev/tty
    printf '  2) Cliente (Este equipo)\n' >/dev/tty
    CHOICE="$(ask 'Opcion' '1')"
    case "$CHOICE" in
        1|vps|servidor|server) ROLE="vps" ;;
        2|dc1|cliente|client) ROLE="dc1" ;;
        *) err "Opcion invalida: $CHOICE"; exit 1 ;;
    esac
fi

case "$ROLE" in
    dc1) setup_client ;;
    vps) setup_vps ;;
    *)   err "Rol invalido: $ROLE (usa dc1 o vps)"; exit 1 ;;
esac
