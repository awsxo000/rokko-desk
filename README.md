# RokkoDesk

**RokkoDesk** é uma ferramenta comunitária, modular e guiada para preparar o Alpine Linux como ambiente desktop, com foco inicial em jogos, Flatpak e uso diário.

O comando oficial do projeto é:

```sh
rokko-setup
```

> Estado atual: protótipo inicial. Os procedimentos específicos de cada módulo ainda devem ser revisados contra a documentação oficial do Alpine antes de uma versão pública estável.

## Personalidade

O RokkoDesk funciona como um guia técnico de preparação do sistema: explica cada etapa, apresenta as escolhas de forma clara e não aplica alterações sem uma confirmação explícita do usuário. A ferramenta deve ser amigável sem ser infantil e técnica sem exigir conhecimento desnecessário.

## Uso

No checkout do projeto, a ferramenta pode ser executada assim:

```sh
./bin/rokko-setup
```

Antes de aplicar qualquer mudança, é possível visualizar o plano:

```sh
./bin/rokko-setup --plan --yes
```

A opção `--yes` aceita as escolhas padrão da primeira versão e é útil para testes automatizados:

```sh
./bin/rokko-setup --yes
```

A execução real exige Alpine Linux e privilégios de root. O modo `--plan` pode ser executado em outro sistema para validar o fluxo da interface.

## Arquitetura

O executável principal contém apenas o fluxo de interação. Cada funcionalidade vive em um módulo independente em `modules/`. Essa separação permitirá incluir perfis e novas tarefas sem transformar o projeto em um script monolítico.

Os módulos iniciais são NetworkManager, Flatpak e ferramentas básicas de desktop. O módulo de NetworkManager instala `eudev`, `networkmanager` e `networkmanager-wifi`, prepara a configuração padrão, associa o usuário ao grupo `plugdev` quando possível e evita a concorrência com `networking` e `wpa_supplicant`. Configurações existentes são preservadas para revisão manual. Os próximos módulos previstos incluem áudio, gráficos, Steam/compatibilidade, criação de perfis e personalização. Cada módulo deverá ser idempotente, documentado e desativável.

## Empacotamento

A pasta `packaging/` contém um exemplo inicial de `APKBUILD`. O pacote deverá instalar o comando `rokko-setup` em `/usr/bin/rokko-setup` e os módulos compartilhados em `/usr/share/rokko-setup/`. O formato final, a versão mínima suportada e as dependências serão definidos depois da validação dos procedimentos e da política de empacotamento do Alpine.

## Princípios do projeto

- Não alterar o sistema sem uma escolha explícita do usuário.
- Oferecer planejamento antes da execução.
- Manter módulos pequenos e idempotentes.
- Não presumir NetworkManager em todas as instalações.
- Registrar claramente as mudanças realizadas.
- Diferenciar comportamento experimental de comportamento validado.
- Manter a identidade RokkoDesk separada da identidade oficial do Alpine Linux.

## Próximo passo

Incorporar a documentação oficial que será fornecida pelo mantenedor e revisar, módulo por módulo, os pacotes, serviços OpenRC, repositórios, permissões e condições de compatibilidade.

## Referência do módulo NetworkManager

O primeiro módulo foi baseado na documentação oficial do Alpine Wiki sobre [NetworkManager](https://wiki.alpinelinux.org/wiki/NetworkManager), consultada em 23 de setembro de 2026. A documentação recomenda habilitar o repositório `community`, configurar `eudev`, instalar `networkmanager` e `networkmanager-wifi`, usar o grupo `plugdev`, manter apenas o NetworkManager como serviço de gerenciamento de rede e configurar `NetworkManager.conf` com os plugins `ifupdown,keyfile` e `managed=true`.
