#!/bin/sh

module_main() {
    # TODO: validar nomes dos serviços e a sequência exata contra a documentação
    # oficial fornecida pelo mantenedor antes de publicar o pacote.
    apk add networkmanager
    rc-update add networkmanager default
    rc-service networkmanager start
}
