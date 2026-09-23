#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(ALPINE_WIZARD_TEST=1 "$ROOT/bin/alpine-wizard" --plan)
printf '%s\n' "$output" | grep -F 'Modo planejamento: nenhuma alteração será feita.' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] NetworkManager' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Flatpak' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Ferramentas básicas' >/dev/null
printf '%s\n' 'test-plan: ok'
