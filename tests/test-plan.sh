#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(ALPINE_WIZARD_TEST=1 "$ROOT/bin/rokko-setup" --plan --yes)
printf '%s\n' "$output" | grep -F 'Modo planejamento: nenhuma alteração será feita.' >/dev/null
printf '%s\n' "$output" | grep -F '[x] Rede: NetworkManager' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Flatpak' >/dev/null
printf '%s\n' "$output" | grep -F '[ ] Ferramentas básicas' >/dev/null

printf '%s\n' "$output" | grep -F 'Rede: NetworkManager' >/dev/null

# --plan --yes não deve exigir gum/figlet: garante estruturalmente que o
# caminho --yes nunca chama interactive_menu (única função que checa as
# dependências de UI via check_gum_deps).
awk '
    /^if \[ "\$ASSUME_YES" -eq 1 \]/ { in_yes_branch=1 }
    /^else$/ { in_yes_branch=0 }
    /^fi$/ { in_yes_branch=0 }
    in_yes_branch && /interactive_menu/ { found=1 }
    END { exit found ? 1 : 0 }
' "$ROOT/bin/rokko-setup" \
    || { printf 'o caminho --yes não deveria chamar interactive_menu (exigiria gum/figlet)\n' >&2; exit 1; }

grep -F 'check_gum_deps' "$ROOT/lib/common.sh" >/dev/null \
    || { printf 'lib/common.sh deveria checar gum/figlet via check_gum_deps\n' >&2; exit 1; }

printf '%s\n' 'test-plan: ok'
