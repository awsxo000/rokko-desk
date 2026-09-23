#!/bin/sh

PROJECT_ROOT=${PROJECT_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}

log() { printf '[alpine-wizard] %s\n' "$*"; }
die() { printf '[alpine-wizard] erro: %s\n' "$*" >&2; exit 1; }

clear_screen() {
    if command -v clear >/dev/null 2>&1 && [ -t 1 ]; then clear; fi
}

ask_yes_no() {
    question=$1
    default=${2:-n}
    while :; do
        if [ "$default" = "s" ]; then suffix='[S/n]'; else suffix='[s/N]'; fi
        printf '%s %s ' "$question" "$suffix"
        IFS= read -r answer || answer=''
        answer=$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')
        [ -z "$answer" ] && answer=$default
        case "$answer" in
            s|sim|y|yes) return 0 ;;
            n|nao|não|no) return 1 ;;
            *) printf 'Responda s ou n.\n' ;;
        esac
    done
}

require_alpine() {
    if [ "${ALPINE_WIZARD_TEST:-0}" = "1" ]; then return 0; fi
    [ -f /etc/alpine-release ] || die "este programa precisa ser executado no Alpine Linux"
}

require_root() {
    [ "$(id -u)" -eq 0 ] || die "esta operação precisa ser executada como root"
}

run_module() {
    name=$1
    module="$PROJECT_ROOT/modules/$name.sh"
    [ -f "$module" ] || die "módulo não encontrado: $name"
    log "Executando módulo: $name"
    # shellcheck disable=SC1090
    . "$module"
    module_main
}
