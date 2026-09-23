#!/bin/sh

module_main() {
    apk add flatpak
    if command -v rc-update >/dev/null 2>&1; then
        log "Flatpak instalado; nenhum serviço OpenRC é necessário."
    fi
}
