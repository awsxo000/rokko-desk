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

Durante o uso interativo, navegue pelas opções com as teclas **↑** e **↓** e pressione **Enter** para selecionar. A interface usa `gum` para renderizar menus, seleção, cores e atalhos, e `figlet` para o wordmark **ALPINE**. A opção ativa recebe destaque visual em cyan/azul no estilo da referência do projeto. Em modo não interativo, o fluxo de planejamento continua disponível sem depender desses componentes visuais.

Para executar a interface interativa a partir do checkout, instale as dependências no Alpine:

```sh
sudo apk add gum figlet
```

## Organização por tópicos

A interface principal organiza a configuração em tópicos independentes. O usuário entra em `Rede`, `Flatpak` ou `Ferramentas de desktop e jogos`, configura aquele assunto e retorna ao menu principal. Em seguida, pode revisar o plano completo antes de aplicar qualquer alteração. O tópico de rede possui um submenu próprio para escolher NetworkManager, o gerenciador nativo do Alpine, manutenção da configuração atual ou restauração do padrão nativo. Em terminais largos, o menu principal apresenta a linha de status do sistema abaixo da seleção; em terminais menores, a interface continua compacta para evitar quebras.

## Arquitetura

O executável principal contém apenas o fluxo de interação. Cada funcionalidade vive em um módulo independente em `modules/`. Essa separação permitirá incluir perfis e novas tarefas sem transformar o projeto em um script monolítico.

Os módulos iniciais são NetworkManager, gerenciador nativo do Alpine, Flatpak e ferramentas básicas de desktop. Na etapa de rede, o usuário pode escolher NetworkManager, manter o gerenciador nativo `ifupdown-ng/networking`, não alterar a configuração atual ou restaurar o gerenciador nativo caso esteja usando NetworkManager. O módulo de NetworkManager instala `eudev`, `networkmanager` e `networkmanager-wifi`, prepara a configuração padrão, associa o usuário ao grupo `plugdev` quando possível e evita a concorrência com `networking` e `wpa_supplicant`. A restauração instala `ifupdown-ng`, desativa o NetworkManager e preserva `/etc/network/interfaces`. Os próximos módulos previstos incluem áudio, gráficos, Steam/compatibilidade, criação de perfis e personalização. Cada módulo deverá ser idempotente, documentado e desativável.

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

Os módulos de rede foram baseados na documentação oficial do Alpine Wiki sobre [NetworkManager](https://wiki.alpinelinux.org/wiki/NetworkManager) e [Configuração de rede](https://wiki.alpinelinux.org/wiki/Configure_Networking), consultadas em 23 de setembro de 2026. A documentação recomenda habilitar o repositório `community`, configurar `eudev`, instalar `networkmanager` e `networkmanager-wifi`, usar o grupo `plugdev`, manter apenas o NetworkManager como serviço de gerenciamento de rede e configurar `NetworkManager.conf` com os plugins `ifupdown,keyfile` e `managed=true`. Para o caminho nativo, o Alpine usa `ifupdown-ng`, `/etc/network/interfaces` e o serviço OpenRC `networking` no runlevel `boot`.
