#!/bin/sh

if [ -z "${PROJECT_ROOT:-}" ]; then
    SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    if [ -d "$SCRIPT_DIR/../modules" ]; then
        PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
    else
        PROJECT_ROOT=/usr/share/rokko-setup
    fi
fi

log() { printf '[rokko-setup] %s\n' "$*"; }
die() { printf '[rokko-setup] erro: %s\n' "$*" >&2; exit 1; }

clear_screen() {
    if command -v clear >/dev/null 2>&1 && [ -t 1 ]; then clear; fi
}

render_banner() {
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        blue='\033[1;34m'
        cyan='\033[1;36m'
        white='\033[1;37m'
        reset='\033[0m'
    else
        blue=''
        cyan=''
        white=''
        reset=''
    fi

    printf '%b\n' "${blue}                  /\\        /\\                  ${reset}"
    printf '%b\n' "${blue}                 /  \\  /\\  /  \\                 ${reset}"
    printf '%b\n' "${blue}                / /\\ \\/  \\/ /\\ \\                ${reset}"
    printf '%b\n' "${blue}               /_/  \\____/  \\_\\               ${reset}"
    printf '%b\n' "${cyan}                    A L P I N E                    ${reset}"
    printf '%b\n' "${white}                        Rokko                       ${reset}"
    printf '\n'
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

ask_network_backend() {
    printf '\n%s\n' "Como você deseja gerenciar a rede?"
    printf '%s\n' "  1) NetworkManager — recomendado para desktop e Wi-Fi"
    printf '%s\n' "  2) Gerenciador nativo do Alpine — ifupdown-ng/networking"
    printf '%s\n' "  3) Manter a configuração atual — não alterar a rede"
    printf '%s\n' "  4) Restaurar o gerenciador nativo e desativar o NetworkManager"
    printf '%s\n' "  5) Voltar ao menu principal"
    while :; do
        printf '%s ' "Escolha [1-5]:"
        IFS= read -r answer || answer=''
        case "$answer" in
            1) NETWORK_BACKEND=networkmanager; return 0 ;;
            2) NETWORK_BACKEND=native; return 0 ;;
            3) NETWORK_BACKEND=keep; return 0 ;;
            4) NETWORK_BACKEND=restore-native; return 0 ;;
            5) return 1 ;;
            *) printf '%s\n' "Escolha 1, 2, 3 ou 4." ;;
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
