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

terminal_columns() {
    columns=$(tput cols 2>/dev/null || true)
    case "$columns" in
        ''|*[!0-9]*) columns=80 ;;
    esac
    printf '%s' "$columns"
}

# ------------------------------------------------------------------------
# Ícones compatíveis. Usamos símbolos Unicode comuns por padrão para que
# apareçam mesmo quando o terminal não utiliza Nerd Font.
# ------------------------------------------------------------------------
ICON_REDE="◉"
ICON_FLATPAK="◆"
ICON_FERRAMENTAS="⚙"
ICON_PLANO="▤"
ICON_AJUDA="?"
ICON_SAIR="×"

# ------------------------------------------------------------------------
# Dependências de interface (gum + figlet). Só é exigido quando o fluxo
# realmente precisa desenhar um menu interativo; o modo `--plan --yes`
# continua funcionando sem essas ferramentas instaladas.
# ------------------------------------------------------------------------
check_gum_deps() {
    missing=''
    command -v gum    >/dev/null 2>&1 || missing="$missing gum"
    command -v figlet >/dev/null 2>&1 || missing="$missing figlet"
    [ -z "$missing" ] && return 0

    printf '\n[rokko-setup] dependências ausentes:%s\n\n' "$missing" >&2
    printf 'Instale de acordo com a sua distribuição:\n\n' >&2
    printf '  Alpine Linux : sudo apk add%s\n'    "$missing" >&2
    printf '  Arch Linux   : sudo pacman -S%s\n'  "$missing" >&2
    printf '  Debian/Ubuntu: sudo apt install%s\n' "$missing" >&2
    printf '  Fedora       : sudo dnf install%s\n\n' "$missing" >&2
    exit 1
}

# ------------------------------------------------------------------------
# Banner "ALPINE" + subtítulo "Rokko", centralizados na largura do
# terminal, usando figlet para o desenho e gum para a cor em truecolor.
# Sem TTY (ex.: saída redirecionada) cai para um cabeçalho simples.
# ------------------------------------------------------------------------
render_banner() {
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ] \
        && command -v figlet >/dev/null 2>&1 && command -v gum >/dev/null 2>&1; then

        cols=$(terminal_columns)
        banner_text=$(figlet -f big -- ALPINE 2>/dev/null) || banner_text='ALPINE'

        printf '\n'
        printf '%s\n' "$banner_text" | while IFS= read -r line; do
            len=$(printf '%s' "$line" | wc -m | tr -d ' ')
            pad=$(( (cols - len) / 2 ))
            [ "$pad" -lt 0 ] && pad=0
            printf '%*s' "$pad" ''
            gum style --foreground="#37E6FF" --bold -- "$line"
        done

        sub='Rokko'
        sublen=${#sub}
        subpad=$(( (cols - sublen) / 2 ))
        [ "$subpad" -lt 0 ] && subpad=0
        printf '%*s' "$subpad" ''
        gum style --foreground="#F5F5F5" -- "$sub"

        printf '\n'
        gum style --foreground="#1FA6BD" -- "$(printf '─%.0s' $(seq 1 "$cols"))"
        printf '\n'
    else
        printf '\n== ALPINE Rokko ==\n\n'
    fi
}

# ------------------------------------------------------------------------
# Status do sistema, no formato "campo|campo|campo|campo" para ser
# desmembrado pelo chamador. "Load" (1 min) é usado em vez de um "CPU %"
# inventado, porque é o dado que dá para calcular de forma confiável em
# sh puro a partir de /proc/loadavg.
# ------------------------------------------------------------------------
system_status_panel() {
    status_version=$(cat /etc/alpine-release 2>/dev/null || printf '%s' 'ambiente de teste')
    status_load=$(awk '{print $1}' /proc/loadavg 2>/dev/null || printf '%s' '-')
    status_mem=$(awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { available=$2 } END { if (total) printf "%.1f/%.1f GB", (total-available)/1048576, total/1048576; else print "-" }' /proc/meminfo 2>/dev/null)
    if command -v ip >/dev/null 2>&1 && ip route show default 2>/dev/null | grep -q .; then
        status_net='conectada'
    else
        status_net='não detectada'
    fi
    printf '%s\n' "$status_version|$status_load|$status_mem|$status_net"
}

render_status_line() {
    status_data=$(system_status_panel)
    status_version=${status_data%%|*}
    status_rest=${status_data#*|}
    status_load=${status_rest%%|*}
    status_rest=${status_rest#*|}
    status_mem=${status_rest%%|*}
    status_net=${status_rest#*|}

    if command -v gum >/dev/null 2>&1 && [ -t 1 ]; then
        gum style --foreground="#8A8A8A" -- \
            "Alpine ${status_version} │ Load: ${status_load} │ RAM: ${status_mem} │ Rede: ${status_net}"
    else
        printf '%s\n' "Alpine ${status_version} │ Load: ${status_load} │ RAM: ${status_mem} │ Rede: ${status_net}"
    fi
}

render_shortcuts() {
    text=$1
    if command -v gum >/dev/null 2>&1 && [ -t 1 ]; then
        gum style --foreground="#8A8A8A" -- "$text"
    else
        printf '%s\n' "$text"
    fi
}

# ------------------------------------------------------------------------
# Menu genérico (submenus). Usa `gum choose`; a seleção final é
# recuperada comparando o texto escolhido com a lista original, então
# funciona mesmo com rótulos com ícone embutido.
# ------------------------------------------------------------------------
select_menu() {
    menu_prompt=$1
    shift
    [ "$#" -gt 0 ] || return 1

    clear_screen
    render_banner

    choice=$(gum choose \
        --header="$menu_prompt" \
        --header.foreground="#F5F5F5" \
        --cursor="▶ " \
        --cursor.foreground="#37E6FF" \
        --selected.background="#0E7C93" \
        --selected.foreground="#FFFFFF" \
        --no-show-help \
        --height="$(( $# + 1 ))" \
        "$@")
    rc=$?

    printf '\n'
    render_shortcuts "↑/↓ Navegar    Enter Selecionar    Ctrl+C Sair"

    [ "$rc" -eq 0 ] && [ -n "$choice" ] || return 1

    idx=1
    for item in "$@"; do
        if [ "$item" = "$choice" ]; then
            MENU_SELECTION=$idx
            return 0
        fi
        idx=$((idx + 1))
    done
    return 1
}

# ------------------------------------------------------------------------
# Menu principal: banner, o `gum choose` estilizado (barra de fundo no
# item ativo) e, logo abaixo, a linha de status + a barra de atalhos —
# na mesma ordem da referência visual do projeto.
# ------------------------------------------------------------------------
select_main_menu() {
    menu_prompt=$1
    shift
    [ "$#" -gt 0 ] || return 1

    clear_screen
    render_banner

    choice=$(gum choose \
        --header="$menu_prompt" \
        --header.foreground="#F5F5F5" \
        --cursor="▶ " \
        --cursor.foreground="#37E6FF" \
        --selected.background="#0E7C93" \
        --selected.foreground="#FFFFFF" \
        --no-show-help \
        --height="$(( $# + 1 ))" \
        "$@")
    rc=$?

    printf '\n'
    render_status_line
    printf '\n'
    render_shortcuts "↑/↓ Navegar    Enter Configurar    Ctrl+C Sair"

    [ "$rc" -eq 0 ] && [ -n "$choice" ] || return 1

    idx=1
    for item in "$@"; do
        if [ "$item" = "$choice" ]; then
            MENU_SELECTION=$idx
            return 0
        fi
        idx=$((idx + 1))
    done
    return 1
}

ask_yes_no() {
    question=$1
    default=${2:-n}
    if command -v gum >/dev/null 2>&1 && [ -t 1 ]; then
        if [ "$default" = "s" ]; then
            gum confirm --default=true -- "$question"
        else
            gum confirm --default=false -- "$question"
        fi
        return $?
    fi
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
