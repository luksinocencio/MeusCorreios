# Meus Correios

App iOS em SwiftUI para acompanhar encomendas dos Correios a partir do código de rastreio
(ex.: `AA123456789BR`). Os pacotes ficam salvos no aparelho e a consulta usa a **API Rastro
oficial**, com as credenciais do próprio usuário.

## Documentação

| Documento | Conteúdo |
| --- | --- |
| [Arquitetura](Docs/arquitetura.md) | Camadas, fluxo de dados, injeção de dependências, convenções e limitações |
| [API dos Correios](Docs/api-correios.md) | Autenticação, endpoints, mapeamento dos DTOs, classificação de status, serviço falso |
| [Persistência (SwiftData)](Docs/persistencia-swiftdata.md) | Grafo de modelos, container, merge de eventos, migração da versão antiga |
| [Interface](Docs/interface.md) | Navegação, telas, componentes, tema claro/escuro, previews |
| [Desenvolvimento](Docs/desenvolvimento.md) | Setup, XcodeGen, build, dados locais, testes, estrutura de pastas |

## Como rodar

Requer Xcode 27 e [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
make generate
```

Isso regenera o `MeusCorreios.xcodeproj` a partir do `project.yml` e abre o Xcode. O `.xcodeproj`
não é versionado: **ao criar um arquivo novo, regenere o projeto**.

Para trabalhar sem credenciais dos Correios, use o `MCMockTrackingService` — instruções em
[Desenvolvimento](Docs/desenvolvimento.md#rodando-sem-credenciais-dos-correios).

## Telas

- **Meus Pacotes** — lista dos códigos salvos, com o último status de cada um e swipe para remover
- **Adicionar pacote** — código de rastreio (validado no formato oficial) e apelido opcional
- **Detalhe do pacote** — linha do tempo completa dos eventos, com pull-to-refresh
- **Ajustes** — tema da interface, ambiente da API e credenciais dos Correios

## Tecnologias

- Swift 5 / SwiftUI, iOS 26
- SwiftData para os pacotes, Chaveiro para as credenciais, `@AppStorage` para o tema
- Swift Concurrency (`async/await`) sobre `URLSession`, tudo na main actor
- XcodeGen, Makefile e shell scripts para o projeto

## Estrutura

```
MeusCorreios/
├── App/            MCApp (entry point, tema, ModelContainer)
├── APIClient/      MCTrackingServicing, serviço real (Correios), mock e DTOs
├── Extensions/     Código de rastreio, data, classificação/apresentação de status
├── Managers/       MCPackageStore + MCPackageRecord (SwiftData), MCCredentialsStore + MCKeychainStore
├── Models/         MCPackage, MCTrackingEvent, MCCorreiosCredentials, MCAppearance
├── Resources/      Assets.xcassets
├── ViewModels/     MCPackageListViewModel
└── Views/          Uma pasta por tela + componentes compartilhados
```

## API dos Correios

É uma **API restrita**: exige cadastro no [Meu Correios](https://www.correios.com.br/atendimento/developers)
e o serviço Rastro habilitado no cartão de postagem ou contrato. Configure as credenciais no
próprio app (engrenagem na lista); elas ficam **apenas no Chaveiro do aparelho**. Sem credenciais
válidas, a consulta falha com uma mensagem orientando a configurá-las.

Detalhes de autenticação, endpoints e tratamento de erro em [API dos Correios](Docs/api-correios.md).
