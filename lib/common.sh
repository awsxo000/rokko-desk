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

terminal_lines() {
    lines=$(tput lines 2>/dev/null || true)
    case "$lines" in
        ''|*[!0-9]*) lines=24 ;;
    esac
    printf '%s' "$lines"
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

icon_mode=${ROKKO_ICON_MODE:-nerd}
case "$icon_mode" in
    none)
        ICON_REDE=''; ICON_FLATPAK=''; ICON_FERRAMENTAS=''; ICON_PLANO=''; ICON_SAIR=''
        ;;
    fallback)
        ICON_REDE='◉'; ICON_FLATPAK='◆'; ICON_FERRAMENTAS='⚙'; ICON_PLANO='▤'; ICON_SAIR='×'
        ;;
    *)
        ICON_REDE='󰖩'; ICON_FLATPAK='󰏖'; ICON_FERRAMENTAS='󰊗'; ICON_PLANO='󰈙'; ICON_SAIR='󰗼'
        ;;
esac

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
# Banner pontilhado "ROKKO" + subtítulo "Alpine", centralizados na largura do
# terminal, usando figlet para o desenho e gum para a cor em truecolor.
# Sem TTY (ex.: saída redirecionada) cai para um cabeçalho simples.
# ------------------------------------------------------------------------
dot_row() {
    dot_pattern=$1
    dot_output=''
    dot_pos=1
    while [ "$dot_pos" -le "${#dot_pattern}" ]; do
        dot_cell=$(printf '%s' "$dot_pattern" | cut -c "$dot_pos")
        [ "$dot_cell" = '1' ] && dot_output="${dot_output}● " || dot_output="${dot_output}  "
        dot_pos=$((dot_pos + 1))
    done
    printf '%s' "$dot_output"
}

render_dot_wordmark() {
    dot_rows='11110 10001 11110 10100 10010|01110 10001 10001 10001 01110|10001 10010 11100 10010 10001|10001 10010 11100 10010 10001|01110 10001 10001 10001 01110'
    old_ifs=$IFS; IFS='|'; set -- $dot_rows; IFS=$old_ifs
    dot_index=1
    while [ "$dot_index" -le 5 ]; do
        dot_line=''
        for dot_letter in "$@"; do
            dot_pattern=$(printf '%s' "$dot_letter" | cut -d ' ' -f "$dot_index")
            dot_line="${dot_line}$(dot_row "$dot_pattern")  "
        done
        printf '%s\n' "$dot_line"
        dot_index=$((dot_index + 1))
    done
}

render_banner() {
    if [ "${ROKKO_TUI:-0}" -eq 1 ]; then
        banner_color='\033[1;97m'
        grid_color='\033[2;31m'
        subtitle_color='\033[1;91m'
        reset_color='\033[0m'
        cols=$(terminal_columns)
        printf '\n'
        printf '%b%s%b\n' "$grid_color" "$(repeat_char '·' "$cols")" "$reset_color"
        dot_wordmark=$(render_dot_wordmark)
        printf '%s\n' "$dot_wordmark" | while IFS= read -r line; do
            len=$(printf '%s' "$line" | wc -m | tr -d ' ')
            pad=$(( (cols - len) / 2 )); [ "$pad" -lt 0 ] && pad=0
            printf '%*s%b%s%b\n' "$pad" '' "$banner_color" "$line" "$reset_color"
        done
        sub='ROKKO DESK'; sublen=${#sub}; subpad=$(( (cols - sublen) / 2 )); [ "$subpad" -lt 0 ] && subpad=0
        printf '%*s%b%s%b\n\n' "$subpad" '' "$subtitle_color" "$sub" "$reset_color"
        printf '%b%s%b\n' "$grid_color" "$(repeat_char '·' "$cols")" "$reset_color"
        return 0
    fi
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ] \
        && command -v figlet >/dev/null 2>&1 && command -v gum >/dev/null 2>&1; then

        cols=$(terminal_columns)
        figlet_font="$PROJECT_ROOT/assets/rokko.flf"
        [ -f "$figlet_font" ] || figlet_font=big
        banner_text=$(figlet -f "$figlet_font" -- ALPINE 2>/dev/null) || banner_text='ALPINE'

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
# desmembrado pelo chamador. A CPU é calculada por duas amostras de /proc/stat.
# ------------------------------------------------------------------------
cpu_snapshot() {
    awk '/^cpu / { print $2+$3+$4+$5+$6+$7+$8, $5+$6; exit }' /proc/stat 2>/dev/null
}

cpu_usage_percent() {
    cpu_first=$(cpu_snapshot || true)
    sleep 0.2
    cpu_second=$(cpu_snapshot || true)
    set -- $cpu_first
    cpu_total_first=${1:-0}
    cpu_idle_first=${2:-0}
    set -- $cpu_second
    cpu_total_second=${1:-0}
    cpu_idle_second=${2:-0}
    awk -v t1="$cpu_total_first" -v i1="$cpu_idle_first" \
        -v t2="$cpu_total_second" -v i2="$cpu_idle_second" \
        'BEGIN { d=t2-t1; if (d > 0) printf "%d", (1-(i2-i1)/d)*100; else printf "-" }'
}

system_status_panel() {
    status_version=$(cat /etc/alpine-release 2>/dev/null || printf '%s' 'ambiente de teste')
    status_cpu=$(cpu_usage_percent)
    status_mem=$(awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { available=$2 } END { if (total) printf "%.1f/%.1f GB", (total-available)/1048576, total/1048576; else print "-" }' /proc/meminfo 2>/dev/null)
    if command -v ip >/dev/null 2>&1 && ip route show default 2>/dev/null | grep -q .; then
        status_net='Conectado'
    else
        status_net='Desconectado'
    fi
    printf '%s\n' "$status_version|$status_cpu|$status_mem|$status_net"
}

render_status_line() {
    status_data=$(system_status_panel)
    status_version=${status_data%%|*}
    status_rest=${status_data#*|}
    status_cpu=${status_rest%%|*}
    status_rest=${status_rest#*|}
    status_mem=${status_rest%%|*}
    status_net=${status_rest#*|}

    if [ "${ROKKO_TUI:-0}" -eq 1 ]; then
        powerline_sep='▶'
        [ "${ROKKO_ICON_MODE:-nerd}" = 'nerd' ] && powerline_sep=''
        status_icon_alpine='▲'
        status_icon_cpu='▣'
        status_icon_ram='▤'
        status_icon_net='●'
        if [ "${ROKKO_ICON_MODE:-nerd}" = 'nerd' ]; then
            status_icon_alpine='󰣇'
            status_icon_cpu='󰍛'
            status_icon_ram='󰘚'
            status_icon_net='󰖩'
        elif [ "${ROKKO_ICON_MODE:-nerd}" = 'none' ]; then
            status_icon_alpine=''; status_icon_cpu=''; status_icon_ram=''; status_icon_net=''
        fi
        printf '\n'
        printf '\033[48;2;245;245;245m\033[38;2;25;35;45m  %s Alpine %s  \033[0m' "$status_icon_alpine" "$status_version"
        printf '\033[38;2;245;245;245m\033[48;2;45;121;174m%s\033[0m' "$powerline_sep"
        printf '\033[48;2;45;121;174m\033[38;2;255;255;255m  %s CPU %s%%  \033[0m' "$status_icon_cpu" "$status_cpu"
        printf '\033[38;2;45;121;174m\033[48;2;220;195;35m%s\033[0m' "$powerline_sep"
        printf '\033[48;2;220;195;35m\033[38;2;25;25;20m  %s RAM %s  \033[0m' "$status_icon_ram" "$status_mem"
        printf '\033[38;2;220;195;35m\033[48;2;35;145;105m%s\033[0m' "$powerline_sep"
        printf '\033[48;2;35;145;105m\033[38;2;255;255;255m  %s NET %s  \033[0m\n' "$status_icon_net" "$status_net"
    elif command -v gum >/dev/null 2>&1 && [ -t 1 ]; then
        gum style --foreground="#8A8A8A" -- \
            "Alpine ${status_version} │ CPU: ${status_cpu}% │ RAM: ${status_mem} │ Net: ${status_net}"
    else
        printf '%s\n' "Alpine ${status_version} │ CPU: ${status_cpu}% │ RAM: ${status_mem} │ Net: ${status_net}"
    fi
}

render_shortcuts() {
    text=$1
    if [ "${ROKKO_TUI:-0}" -eq 1 ]; then printf "\033[37m%s\033[0m\n" "$text"; elif command -v gum >/dev/null 2>&1 && [ -t 1 ]; then
        gum style --foreground="#8A8A8A" -- "$text"
    else
        printf '%s\n' "$text"
    fi
}

read_tui_key() {
    old_stty=$(stty -g 2>/dev/null) || return 1
    stty -icanon -echo min 1 time 0 2>/dev/null || return 1
    key=$(dd if=/dev/tty bs=1 count=1 2>/dev/null || true)
    if [ "$(printf '%s' "$key" | od -An -t x1 | tr -d ' \n')" = '1b' ]; then
        stty -icanon -echo min 0 time 1 2>/dev/null || true
        sequence=$(dd if=/dev/tty bs=1 count=2 2>/dev/null || true)
        case "$sequence" in
            '[A') key=up ;;
            '[B') key=down ;;
            '') key=escape ;;
            *) key=other ;;
        esac
    fi
    stty "$old_stty" 2>/dev/null || true
    case "$key" in
        '') MENU_KEY=enter ;;
        h|H) MENU_KEY=help ;;
        k) MENU_KEY=up ;;
        j) MENU_KEY=down ;;
        up|down|escape|other) MENU_KEY=$key ;;
        *) MENU_KEY=other ;;
    esac
}

repeat_char() {
    repeat_value=$1
    repeat_count=$2
    [ "$repeat_count" -gt 0 ] || return 0
    i=0
    while [ "$i" -lt "$repeat_count" ]; do
        printf '%s' "$repeat_value"
        i=$((i + 1))
    done
}

render_gradient_line() {
    gradient_text=$1
    gradient_width=$2
    gradient_pad=$(pad_to_width "$gradient_text" "$gradient_width")
    printf '│  '
    printf '\033[48;2;25;154;174m\033[38;2;255;255;255m%s\033[0m' "$gradient_pad"
    printf '│\n'
}

render_menu_line() {
    menu_line_text=$1
    menu_line_width=$2
    menu_line_icon=${menu_line_text%%  *}
    menu_line_label=${menu_line_text#"$menu_line_icon"}
    if [ "$menu_line_icon" = "$menu_line_text" ] || [ "${ROKKO_ICON_MODE:-nerd}" = 'none' ]; then
        printf '│  %s│\n' "$(pad_to_width "$menu_line_text" "$menu_line_width")"
        return 0
    fi
    menu_line_label=${menu_line_label#  }
    # O ícone ocupa uma coluna e os dois espaços ao redor ocupam duas;
    # portanto o rótulo precisa preencher exatamente width - 3 colunas.
    printf '│  \033[1;96m%s\033[0m  %s│\n' "$menu_line_icon" "$(pad_to_width "$menu_line_label" "$((menu_line_width - 3))")"
}

show_help_screen() {
    clear_screen
    render_banner
    help_width=64
    printf '╭%s╮\n' "$(repeat_char '─' "$help_width")"
    printf '│ %s │\n' "$(pad_to_width 'Ajuda do RokkoDesk' "$help_width")"
    printf '├%s┤\n' "$(repeat_char '─' "$help_width")"
    printf '│ %s │\n' "$(pad_to_width '↑/↓ ou J/K   Navegar pelas opções' "$help_width")"
    printf '│ %s │\n' "$(pad_to_width 'Enter         Abrir o tópico selecionado' "$help_width")"
    printf '│ %s │\n' "$(pad_to_width 'H             Mostrar esta ajuda' "$help_width")"
    printf '│ %s │\n' "$(pad_to_width 'Esc           Voltar ao menu anterior' "$help_width")"
    printf '│ %s │\n' "$(pad_to_width 'Ctrl+C        Sair' "$help_width")"
    printf '╰%s╯\n\n' "$(repeat_char '─' "$help_width")"
    printf 'Pressione qualquer tecla para voltar...'
    read_tui_key || true
}

draw_tui_panel() {
        printf '\033[2;31m╭%s╮\033[0m\n' "$(repeat_char '─' "$((panel_width - 2))")"
        printf '│  %s│\n' "$(pad_to_width "$menu_prompt" "$inner_width")"
        printf '\033[2;31m├%s┤\033[0m\n' "$(repeat_char '─' "$((panel_width - 2))")"
        menu_index=1
        for menu_item in "$@"; do
            if [ "$menu_index" -eq "$menu_current" ]; then
                render_gradient_line "$menu_item" "$inner_width"
            else
                render_menu_line "$menu_item" "$inner_width"
            fi
            menu_index=$((menu_index + 1))
        done
        printf '\033[2;31m╰%s╯\033[0m\n' "$(repeat_char '─' "$((panel_width - 2))")"
        render_status_line
        printf '\n'
        render_shortcuts "[↑/↓] Navegar  •  [Enter] Configurar  •  [H] Ajuda  •  [Ctrl+C] Sair"
}

select_tui_menu() {
    menu_prompt=$1
    shift
    menu_count=$#
    menu_current=1
    [ "$menu_count" -gt 0 ] || return 1
    panel_width=$(terminal_columns)
    [ "$panel_width" -gt 110 ] && panel_width=110
    [ "$panel_width" -lt 72 ] && panel_width=72
    inner_width=$((panel_width - 4))
    ROKKO_TUI=1

    clear_screen
    render_banner
    printf '\033[s'
    printf '\033[?25l'
    draw_tui_panel "$@"
    while :; do
        read_tui_key || { unset ROKKO_TUI; return 1; }
        case "$MENU_KEY" in
            up)
                menu_current=$((menu_current - 1)); [ "$menu_current" -ge 1 ] || menu_current=$menu_count
                printf '\033[u\033[0J'
                draw_tui_panel "$@"
                ;;
            down)
                menu_current=$((menu_current + 1)); [ "$menu_current" -le "$menu_count" ] || menu_current=1
                printf '\033[u\033[0J'
                draw_tui_panel "$@"
                ;;
            help)
                show_help_screen
                clear_screen
                render_banner
                printf '\033[s\033[?25l'
                draw_tui_panel "$@"
                ;;
            escape) printf '\033[?25h'; unset ROKKO_TUI; return 1 ;;
            enter) printf '\033[?25h'; MENU_SELECTION=$menu_current; unset ROKKO_TUI; return 0 ;;
        esac
    done
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

    if [ -t 1 ] && [ -t 0 ]; then
        select_tui_menu "$menu_prompt" "$@"
        return $?
    fi

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

    if [ -t 1 ] && [ -t 0 ]; then
        select_tui_menu "$menu_prompt" "$@"
        return $?
    fi

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
