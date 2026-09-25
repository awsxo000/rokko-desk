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

Durante o uso interativo, navegue pelas opções com as teclas **↑** e **↓** e pressione **Enter** para selecionar. A interface usa `gum` para cores e estilo, um wordmark pontilhado próprio e um TUI para o painel arredondado, a faixa selecionada e o rodapé fixo. O topo usa pontos brancos, linhas de grade vermelha discreta e o wordmark **ROKKO DESK**; a moldura do painel acompanha a mesma linguagem técnica. O painel usa uma largura maior, uma coluna exclusiva para os ícones e espaçamento reforçado entre ícone e rótulo. Abaixo do painel, o status usa blocos no estilo **Powerline** para Alpine, CPU, RAM e NET, com separadores em seta e cores independentes. A opção `H` abre a tela de ajuda. A seleção usa uma faixa cyan/azul e os ícones usam Nerd Font por padrão. O tamanho físico do ícone é controlado pelo tamanho da fonte do emulador de terminal; para vê-los maiores, aumente o tamanho da JetBrainsMono Nerd Font nas preferências do Konsole. Se a fonte não estiver configurada no terminal, use `ROKKO_ICON_MODE=fallback` para símbolos comuns ou `ROKKO_ICON_MODE=none` para ocultá-los.

A camada visual usa **unicase** por padrão: os textos são exibidos em caixa alta para eliminar a diferença visual entre maiúsculas e minúsculas, aproximando-se de uma fonte técnica mais pesada. O modo pode ser desativado com `ROKKO_UI_CASE=normal`. Para uma aparência mais marcante, selecione **JetBrainsMono Nerd Font Bold** ou **JetBrainsMono Nerd Font** em tamanho maior no terminal.

Para executar a interface interativa a partir do checkout, instale as dependências no Alpine:

```sh
sudo apk add gum figlet
```

Para obter os ícones da referência, instale uma Nerd Font e selecione-a nas preferências do seu emulador de terminal:

```sh
sudo apk add font-jetbrains-mono-nerd
```

### Nothing Font / Ndot

O wordmark pontilhado do projeto foi inspirado na família Ndot. O repositório [`xeji01/nothingfont`](https://github.com/xeji01/nothingfont) fornece `Ndot55-Regular.otf`, `Ndot57-Regular.otf` e variantes caps. Esses arquivos não são redistribuídos pelo RokkoDesk: o próprio repositório informa que os direitos pertencem à NOTHING Tech.

Se você tiver autorização para usar a fonte, instale-a somente no seu usuário:

```sh
git clone --depth 1 https://github.com/xeji01/nothingfont /tmp/nothingfont
mkdir -p "$HOME/.local/share/fonts/nothing"
cp /tmp/nothingfont/fonts/Ndot57-Regular.otf "$HOME/.local/share/fonts/nothing/"
fc-cache -f "$HOME/.local/share/fonts"
```

Depois, selecione **Ndot 57** como fonte do perfil do terminal. A fonte altera o terminal inteiro; ela não pode ser aplicada apenas ao wordmark por ANSI. Se você não quiser alterar a fonte do terminal, o RokkoDesk continua usando o wordmark pontilhado próprio e a Nerd Font apenas para ícones.

Exemplos de fallback:

```sh
ROKKO_ICON_MODE=fallback ./bin/rokko-setup --plan
ROKKO_ICON_MODE=none ./bin/rokko-setup --plan
```

## Organização por tópicos

A interface principal organiza a configuração em tópicos independentes. O usuário entra em `Rede`, `Flatpak` ou `Ferramentas de desktop e jogos`, configura aquele assunto e retorna ao menu principal. Em seguida, pode revisar o plano completo antes de aplicar qualquer alteração. O tópico de rede possui um submenu próprio para escolher NetworkManager, o gerenciador nativo do Alpine, manutenção da configuração atual ou restauração do padrão nativo. A linha de status apresenta a versão do Alpine, uso estimado da CPU, memória, conectividade e o rótulo `Net`, seguindo a referência visual. Em terminais menores, a interface continua compacta para evitar quebras.

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
