#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(ALPINE_WIZARD_TEST=1 "$ROOT/bin/rokko-setup" --plan --yes)
printf '%s\n' "$output" | grep -F 'Modo planejamento: nenhuma alteração será feita.' >/dev/null
printf '%s\n' "$output" | grep -F '[x] NetworkManager' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Flatpak' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Ferramentas básicas' >/dev/null

native_output=$(printf '2\nn\nn\n' | ALPINE_WIZARD_TEST=1 "$ROOT/bin/rokko-setup" --plan)
printf '%s\n' "$native_output" | grep -F '[x] Gerenciador nativo do Alpine (ifupdown-ng/networking)' >/dev/null
printf '%s\n' "$native_output" | grep -F 'Modo planejamento: nenhuma alteração será feita.' >/dev/null

printf '%s\n' 'test-plan: ok'
