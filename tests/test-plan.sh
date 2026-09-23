#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(ALPINE_WIZARD_TEST=1 "$ROOT/bin/rokko-setup" --plan --yes)
printf '%s\n' "$output" | grep -F 'Modo planejamento: nenhuma alteração será feita.' >/dev/null
printf '%s\n' "$output" | grep -F '[x] Rede: NetworkManager' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Flatpak' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Ferramentas básicas' >/dev/null

printf '%s\n' "$output" | grep -F 'Rede: NetworkManager' >/dev/null
grep -F 'Use ↑/↓ para navegar e Enter para selecionar.' "$ROOT/lib/common.sh" >/dev/null

printf '%s\n' 'test-plan: ok'
