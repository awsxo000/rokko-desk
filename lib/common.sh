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

read_menu_key() {
    old_stty=$(stty -g 2>/dev/null) || return 1
    stty -icanon -echo min 1 time 0 2>/dev/null || return 1
    key=$(dd if=/dev/tty bs=1 count=1 2>/dev/null || true)
    if [ "$(printf '%s' "$key" | od -An -t x1 | tr -d ' \n')" = "1b" ]; then
        key2=$(dd if=/dev/tty bs=1 count=1 2>/dev/null || true)
        key3=$(dd if=/dev/tty bs=1 count=1 2>/dev/null || true)
        case "$key2$key3" in
            '[A') key=up ;;
            '[B') key=down ;;
            '[C') key=right ;;
            '[D') key=left ;;
            *) key='' ;;
        esac
    fi
    stty "$old_stty" 2>/dev/null || true
    if [ -z "$key" ] || [ "$key" = "$(printf '\n')" ]; then
        MENU_KEY=enter
    else
        case "$key" in
            up|k) MENU_KEY=up ;;
            down|j) MENU_KEY=down ;;
            *) MENU_KEY=other ;;
        esac
    fi
}

pad_to_width() {
    pad_text=$1
    pad_width=$2
    pad_current=$(printf '%s' "$pad_text" | wc -m | tr -d ' ')
    printf '%s' "$pad_text"
    while [ "$pad_current" -lt "$pad_width" ]; do
        printf ' '
        pad_current=$((pad_current + 1))
    done
}

select_menu() {
    menu_prompt=$1
    shift
    menu_current=1
    menu_count=$#
    [ "$menu_count" -gt 0 ] || return 1

    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        ui_border='\033[2;37m'
        ui_title='\033[1;36m'
        ui_selected='\033[1;36m'
        ui_muted='\033[2;37m'
        ui_reset='\033[0m'
    else
        ui_border=''
        ui_title=''
        ui_selected=''
        ui_muted=''
        ui_reset=''
    fi

    while :; do
        clear_screen
        render_banner
        printf '%b\n' "${ui_border}╭────────────────────────────────────────────────────────────────────────────╮${ui_reset}"
        printf '%b%s%b\n' "${ui_border}│${ui_reset}  ${ui_title}" "$(pad_to_width "$menu_prompt" 72)" "${ui_reset}  ${ui_border}│${ui_reset}"
        printf '%b\n' "${ui_border}├────────────────────────────────────────────────────────────────────────────┤${ui_reset}"
        menu_index=1
        for menu_item in "$@"; do
            if [ "$menu_index" -eq "$menu_current" ]; then
                printf '%b%s%b\n' "${ui_border}│${ui_reset}  ${ui_selected}" "$(pad_to_width "$menu_item" 72)" "${ui_reset}  ${ui_border}│${ui_reset}"
            else
                printf '%b%s%b\n' "${ui_border}│${ui_reset}  " "$(pad_to_width "$menu_item" 72)" "  ${ui_border}│${ui_reset}"
            fi
            printf '%b%s%b\n' "${ui_border}│${ui_reset}    " "$(pad_to_width '' 70)" "  ${ui_border}│${ui_reset}"
            menu_index=$((menu_index + 1))
        done
        printf '%b\n' "${ui_border}╰────────────────────────────────────────────────────────────────────────────╯${ui_reset}"
        printf '%b\n' "${ui_muted}  ↑/↓ Navegar    Enter Selecionar    Ctrl+C Sair${ui_reset}"

        read_menu_key || return 1
        case "$MENU_KEY" in
            up)
                menu_current=$((menu_current - 1))
                [ "$menu_current" -ge 1 ] || menu_current=$menu_count
                ;;
            down)
                menu_current=$((menu_current + 1))
                [ "$menu_current" -le "$menu_count" ] || menu_current=1
                ;;
            enter)
                MENU_SELECTION=$menu_current
                return 0
                ;;
        esac
    done
}

ask_network_backend() {
    select_menu "Como você deseja gerenciar a rede?" \
        "NetworkManager — recomendado para desktop e Wi-Fi" \
        "Gerenciador nativo do Alpine — ifupdown-ng/networking" \
        "Manter a configuração atual — não alterar a rede" \
        "Restaurar o gerenciador nativo e desativar o NetworkManager" \
        "Voltar ao menu principal" || return 1
    case "$MENU_SELECTION" in
        1) NETWORK_BACKEND=networkmanager ;;
        2) NETWORK_BACKEND=native ;;
        3) NETWORK_BACKEND=keep ;;
        4) NETWORK_BACKEND=restore-native ;;
        5) return 1 ;;
    esac
    return 0
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
