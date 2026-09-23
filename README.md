# Alpine Wizard

**Alpine Wizard** é uma ferramenta comunitária, modular e guiada para automatizar configurações pós-instalação do Alpine Linux, com foco inicial em desktops e jogos integrados ao Flatpak.

> Estado atual: protótipo inicial. Os procedimentos específicos de cada módulo ainda devem ser revisados contra a documentação oficial do Alpine antes de uma versão pública estável.

## Uso

A ferramenta foi desenhada para ser executada no terminal:

```sh
./bin/alpine-wizard
```

Antes de aplicar qualquer mudança, é possível visualizar o plano:

```sh
./bin/alpine-wizard --plan
```

A opção `--yes` aceita as escolhas padrão da primeira versão e é útil para testes automatizados:

```sh
./bin/alpine-wizard --yes
```

A execução real exige Alpine Linux e privilégios de root. O modo `--plan` pode ser executado em outro sistema para validar o fluxo da interface.

## Arquitetura

O executável principal contém apenas o fluxo de interação. Cada funcionalidade vive em um módulo independente em `modules/`. Essa separação permitirá incluir perfis e novas tarefas sem transformar o projeto em um script monolítico.

Os próximos módulos previstos são NetworkManager, Flatpak, ferramentas básicas de desktop, áudio, gráficos, Steam/compatibilidade e criação de perfis. Cada módulo deverá ser idempotente, documentado e desativável.

## Empacotamento

A pasta `packaging/` será usada para preparar o pacote APK do Alpine. O formato final, o nome do pacote, a versão mínima suportada e as dependências serão definidos depois da validação dos procedimentos e da política de empacotamento do Alpine.

## Princípios do projeto

- Não alterar o sistema sem uma escolha explícita do usuário.
- Oferecer planejamento antes da execução.
- Manter módulos pequenos e idempotentes.
- Não presumir NetworkManager em todas as instalações.
- Registrar claramente as mudanças realizadas.
- Diferenciar comportamento experimental de comportamento validado.

## Próximo passo

Incorporar a documentação oficial que será fornecida pelo mantenedor e revisar, módulo por módulo, os pacotes, serviços OpenRC, repositórios, permissões e condições de compatibilidade.
