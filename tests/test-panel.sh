#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(
    # O teste força a seleção imediata sem exigir um terminal interativo.
    . "$ROOT/lib/common.sh"
    read_menu_key() { MENU_KEY=enter; }
    select_menu "Escolha um tópico para configurar:" \
        "Rede" \
        "Flatpak" \
        "Ferramentas de desktop e jogos" \
        "Revisar plano" \
        "Sair"
)
printf '%s\n' "$output" | while IFS= read -r line; do
    case "$line" in
        *│*)
            width=$(printf '%s' "$line" | wc -m | tr -d ' ')
            if [ "$width" -ne 78 ]; then
                printf 'linha com largura inválida: %s |%s|\n' "$width" "$line" >&2
                exit 1
            fi
            ;;
    esac
done
printf '%s\n' "$output" | grep -F '•' >/dev/null && exit 1 || true
printf '%s\n' "$output" | grep -F '●' >/dev/null && exit 1 || true
printf '%s\n' 'test-panel: ok'
