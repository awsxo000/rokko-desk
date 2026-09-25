# ALPDesk

**ALPDesk** é uma ferramenta comunitária, modular e guiada para preparar o Alpine Linux como ambiente desktop, com foco inicial em jogos, Flatpak e uso diário.

O comando oficial do projeto é:

```sh
alp-setup
```

> Estado atual: protótipo inicial. Os procedimentos específicos de cada módulo ainda devem ser revisados contra a documentação oficial do Alpine antes de uma versão pública estável.

## Personalidade

O ALPDesk funciona como um guia técnico de preparação do sistema: explica cada etapa, apresenta as escolhas de forma clara e não aplica alterações sem uma confirmação explícita do usuário. A ferramenta deve ser amigável sem ser infantil e técnica sem exigir conhecimento desnecessário. O comando oficial é `alp-setup`; `rokko-setup` permanece apenas como compatibilidade temporária.

## Uso

No checkout do projeto, a ferramenta pode ser executada assim:

```sh
./bin/alp-setup
```

Antes de aplicar qualquer mudança, é possível visualizar o plano:

```sh
./bin/alp-setup --plan --yes
```

A opção `--yes` aceita as escolhas padrão da primeira versão e é útil para testes automatizados:

```sh
./bin/alp-setup --yes
```

A execução real exige Alpine Linux e privilégios de root. O modo `--plan` pode ser executado em outro sistema para validar o fluxo da interface.

O banner principal usa a arte Alpine no estilo visual do Fastfetch, com **ALPDesk** como subtítulo. A arte fica armazenada localmente para não executar Fastfetch nem recalcular informações a cada movimento do menu; o FIGlet permanece como fallback.

Durante o uso interativo, navegue pelas opções com as teclas **↑** e **↓** e pressione **Enter** para selecionar. A interface usa `gum` para cores e estilo, a logo Alpine em estilo Fastfetch e um TUI próprio para o painel arredondado, a faixa selecionada e o rodapé fixo. O painel usa uma largura maior, uma coluna exclusiva para os ícones e espaçamento reforçado entre ícone e rótulo. Abaixo do painel, o status usa blocos no estilo **Powerline** para Alpine, CPU, RAM e NET, com separadores em seta e cores independentes. A opção `H` abre a tela de ajuda. A seleção usa uma faixa cyan/azul e os ícones usam Nerd Font por padrão. O tamanho físico do ícone é controlado pelo tamanho da fonte do emulador de terminal; para vê-los maiores, aumente o tamanho da JetBrainsMono Nerd Font nas preferências do Konsole. Se a fonte não estiver configurada no terminal, use `ROKKO_ICON_MODE=fallback` para símbolos comuns ou `ROKKO_ICON_MODE=none` para ocultá-los.

Os ícones aparecem em badges maiores por padrão, por exemplo `[ 󰖩 ]`, para ocupar mais presença visual sem depender de fontes com tamanhos diferentes na mesma linha. Para voltar ao formato compacto, use `ROKKO_ICON_SIZE=compact`.

Para executar a interface interativa a partir do checkout, instale as dependências no Alpine:

```sh
sudo apk add gum figlet dialog fastfetch
```

O projeto escolhe **dialog** em vez de `whiptail` para widgets TUI, confirmações e listas. O `dialog` oferece uma API mais completa para a evolução dos menus, enquanto o TUI atual continua sendo usado nesta fase para preservar a navegação já validada.

O **fastfetch** é usado para exibir uma visão detalhada do sistema:

```sh
./bin/alp-setup --info
```

Instalação direta no Alpine:

```sh
sudo apk add dialog fastfetch
```

### Desenvolvimento e pré-visualização pelo GitHub

Depois do primeiro clone, não é necessário baixar ou extrair ZIPs a cada alteração:

```sh
git clone https://github.com/awsxo000/rokko-desk.git
cd rokko-desk
sudo apk add git gum figlet dialog fastfetch font-jetbrains-mono-nerd
chmod +x dev/run-preview.sh
./dev/run-preview.sh
```

Nas próximas vezes, basta executar:

```sh
cd rokko-desk
./dev/run-preview.sh
```

O script atualiza a cópia com `git pull --ff-only`, garante a permissão do executável e abre `alp-setup --plan`. Se você tiver alterações locais não commitadas, ele interrompe antes do `pull` para não sobrescrevê-las.

Para obter os ícones da referência, instale uma Nerd Font e selecione-a nas preferências do seu emulador de terminal:

```sh
sudo apk add font-jetbrains-mono-nerd
```

Exemplos de fallback:

```sh
ROKKO_ICON_MODE=fallback ./bin/alp-setup --plan
ROKKO_ICON_MODE=none ./bin/alp-setup --plan
```

## Organização por tópicos

A interface principal organiza a configuração em tópicos independentes. O usuário entra em `Rede`, `Flatpak` ou `Ferramentas de desktop e jogos`, configura aquele assunto e retorna ao menu principal. Em seguida, pode revisar o plano completo antes de aplicar qualquer alteração. O tópico de rede possui um submenu próprio para escolher NetworkManager, o gerenciador nativo do Alpine, manutenção da configuração atual ou restauração do padrão nativo. A linha de status apresenta a versão do Alpine, uso estimado da CPU, memória, conectividade e o rótulo `Net`, seguindo a referência visual. Em terminais menores, a interface continua compacta para evitar quebras.

## Arquitetura

O executável principal contém apenas o fluxo de interação. Cada funcionalidade vive em um módulo independente em `modules/`. Essa separação permitirá incluir perfis e novas tarefas sem transformar o projeto em um script monolítico.

Os módulos iniciais são NetworkManager, gerenciador nativo do Alpine, Flatpak e ferramentas básicas de desktop. Na etapa de rede, o usuário pode escolher NetworkManager, manter o gerenciador nativo `ifupdown-ng/networking`, não alterar a configuração atual ou restaurar o gerenciador nativo caso esteja usando NetworkManager. O módulo de NetworkManager instala `eudev`, `networkmanager` e `networkmanager-wifi`, prepara a configuração padrão, associa o usuário ao grupo `plugdev` quando possível e evita a concorrência com `networking` e `wpa_supplicant`. A restauração instala `ifupdown-ng`, desativa o NetworkManager e preserva `/etc/network/interfaces`. Os próximos módulos previstos incluem áudio, gráficos, Steam/compatibilidade, criação de perfis e personalização. Cada módulo deverá ser idempotente, documentado e desativável.

## Empacotamento

A pasta `packaging/` contém um exemplo inicial de `APKBUILD`. O pacote deverá instalar o comando `alp-setup` em `/usr/bin/alp-setup`. O antigo comando `rokko-setup` também é instalado como compatibilidade temporária. Os módulos compartilhados continuam em `/usr/share/rokko-setup/` para preservar instalações existentes. O formato final, a versão mínima suportada e as dependências serão definidos depois da validação dos procedimentos e da política de empacotamento do Alpine.

## Princípios do projeto

- Não alterar o sistema sem uma escolha explícita do usuário.
- Oferecer planejamento antes da execução.
- Manter módulos pequenos e idempotentes.
- Não presumir NetworkManager em todas as instalações.
- Registrar claramente as mudanças realizadas.
- Diferenciar comportamento experimental de comportamento validado.
- Manter a identidade ALPDesk separada da identidade oficial do Alpine Linux.

## Próximo passo

Incorporar a documentação oficial que será fornecida pelo mantenedor e revisar, módulo por módulo, os pacotes, serviços OpenRC, repositórios, permissões e condições de compatibilidade.

## Referência do módulo NetworkManager

Os módulos de rede foram baseados na documentação oficial do Alpine Wiki sobre [NetworkManager](https://wiki.alpinelinux.org/wiki/NetworkManager) e [Configuração de rede](https://wiki.alpinelinux.org/wiki/Configure_Networking), consultadas em 23 de setembro de 2026. A documentação recomenda habilitar o repositório `community`, configurar `eudev`, instalar `networkmanager` e `networkmanager-wifi`, usar o grupo `plugdev`, manter apenas o NetworkManager como serviço de gerenciamento de rede e configurar `NetworkManager.conf` com os plugins `ifupdown,keyfile` e `managed=true`. Para o caminho nativo, o Alpine usa `ifupdown-ng`, `/etc/network/interfaces` e o serviço OpenRC `networking` no runlevel `boot`.
