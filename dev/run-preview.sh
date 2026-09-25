#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
    printf '%s\n' 'Há alterações locais não commitadas; não vou executar git pull.' >&2
    printf '%s\n' 'Salve ou descarte essas alterações antes de usar este comando.' >&2
    exit 1
fi

git pull --ff-only
chmod +x bin/rokko-setup

: "${ROKKO_ICON_MODE:=nerd}"
export ROKKO_ICON_MODE
exec ./bin/rokko-setup --plan
