#!/bin/sh

module_main() {
    log "Instalando NetworkManager, suporte a Wi-Fi e eudev..."
    apk add eudev networkmanager networkmanager-wifi

    # O Alpine recomenda plugdev para permitir que o usuário comum utilize
    # as interfaces do NetworkManager.
    target_user=${SUDO_USER:-${USER:-}}
    if [ -n "$target_user" ] && [ "$target_user" != "root" ] && id "$target_user" >/dev/null 2>&1; then
        addgroup "$target_user" plugdev 2>/dev/null || true
        log "Usuário '$target_user' associado ao grupo plugdev; será necessário entrar novamente na sessão."
    else
        log "Nenhum usuário não-root foi identificado; o grupo plugdev deverá ser configurado manualmente."
    fi

    install -d -m 755 /etc/NetworkManager
    if [ ! -e /etc/NetworkManager/NetworkManager.conf ]; then
        cat > /etc/NetworkManager/NetworkManager.conf <<'CONFIG'
[main]
dhcp=internal
plugins=ifupdown,keyfile

[ifupdown]
managed=true
CONFIG
        log "Criado /etc/NetworkManager/NetworkManager.conf."
    else
        log "Configuração existente preservada: /etc/NetworkManager/NetworkManager.conf."
        log "Verifique se ela contém plugins=ifupdown,keyfile e managed=true."
    fi

    # O NetworkManager não deve concorrer com os serviços tradicionais.
    # Só removemos os serviços dos runlevels; a parada imediata é feita
    # apenas quando o serviço está ativo.
    if rc-service networking status >/dev/null 2>&1; then
        rc-service networking stop || true
    fi
    if rc-service wpa_supplicant status >/dev/null 2>&1; then
        rc-service wpa_supplicant stop || true
    fi
    rc-update del networking boot 2>/dev/null || true
    rc-update del wpa_supplicant boot 2>/dev/null || true
    rc-update add networkmanager default
    rc-service networkmanager restart 2>/dev/null || rc-service networkmanager start

    log "NetworkManager configurado. Para Wi-Fi, use nmtui ou nmcli após relogar."
}
