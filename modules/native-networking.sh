#!/bin/sh

module_main() {
    log "Restaurando o gerenciador nativo de rede do Alpine (ifupdown-ng/networking)..."

    # O Alpine usa ifupdown-ng e o serviço networking como configuração padrão.
    # Não sobrescrevemos /etc/network/interfaces: ela contém a configuração
    # específica da máquina e deve ser preservada.
    apk add ifupdown-ng

    rc-update del networkmanager default 2>/dev/null || true
    rc-update del wpa_supplicant boot 2>/dev/null || true
    rc-update add networking boot
    rc-service networkmanager stop 2>/dev/null || true
    rc-service networking restart 2>/dev/null || rc-service networking start

    log "Gerenciador nativo restaurado. A configuração de /etc/network/interfaces foi preservada."
}
