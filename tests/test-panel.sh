#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FAKE_BIN=$(mktemp -d)
trap 'rm -rf "$FAKE_BIN"' EXIT

# gum falso: sem TTY não dá pra exercitar o gum de verdade, então este
# dublê simula "o usuário escolheu o 3º item" e deixa a gente testar a
# lógica de select_menu (o mapeamento de volta para MENU_SELECTION).
cat > "$FAKE_BIN/gum" <<'FAKE'
#!/bin/sh
if [ "${1:-}" = "choose" ]; then
    shift
    n=0
    chosen=''
    for arg in "$@"; do
        case "$arg" in
            --*) continue ;;
        esac
        n=$((n + 1))
        [ "$n" -eq 3 ] && chosen=$arg
    done
    printf '%s\n' "$chosen"
    exit 0
fi
# "gum style" e qualquer outro subcomando: apenas devolve os argumentos
# que não são flags, sem cor nenhuma (irrelevante para este teste).
shift
for arg in "$@"; do
    case "$arg" in --*) continue ;; esac
    printf '%s\n' "$arg"
done
exit 0
FAKE
chmod +x "$FAKE_BIN/gum"

cat > "$FAKE_BIN/figlet" <<'FAKE'
#!/bin/sh
printf 'ALPINE\n'
FAKE
chmod +x "$FAKE_BIN/figlet"

PATH="$FAKE_BIN:$PATH"
export PATH

selection=$(
    . "$ROOT/lib/common.sh"
    select_menu "Escolha um tópico para configurar:" \
        "Rede" "Flatpak" "Ferramentas de desktop e jogos" "Revisar plano" "Sair" >/dev/null
    printf '%s\n' "$MENU_SELECTION"
)

[ "$selection" = "3" ] || {
    printf 'select_menu escolheu o item errado: %s (esperado 3)\n' "$selection" >&2
    exit 1
}

for icon in ICON_REDE ICON_FLATPAK ICON_FERRAMENTAS ICON_PLANO ICON_AJUDA ICON_SAIR; do
    value=$(sh -c ". '$ROOT/lib/common.sh'; printf '%s' \"\$$icon\"")
    [ -n "$value" ] || {
        printf 'ícone vazio: %s\n' "$icon" >&2
        exit 1
    }
done

# check_gum_deps precisa falhar (exit 1) quando gum/figlet não existem.
EMPTY_BIN=$(mktemp -d)
trap 'rm -rf "$FAKE_BIN" "$EMPTY_BIN"' EXIT
if (
    PATH="$EMPTY_BIN"
    export PATH
    . "$ROOT/lib/common.sh"
    check_gum_deps
) >/dev/null 2>&1; then
    printf 'check_gum_deps deveria falhar sem gum/figlet instalados\n' >&2
    exit 1
fi

printf '%s\n' 'test-panel: ok'
