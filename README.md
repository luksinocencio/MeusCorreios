# Meus Correios

App em SwiftUI para acompanhar o rastreamento de encomendas dos Correios a partir do código de rastreio (ex.: `AA123456789BR`).

## Tecnologias utilizadas
- Swift 5 / SwiftUI (iOS 16+)
- Swift Concurrency (`async/await`)
- XcodeGen, Makefile, Shell

## Como rodar

```bash
make generate
```

Isso regenera o `MeusCorreios.xcodeproj` a partir do `project.yml` e abre o Xcode.

## Telas
- **Meus Pacotes** — lista dos códigos de rastreio salvos, com o último status de cada um
- **Adicionar pacote** — formulário para incluir um novo código de rastreio (com apelido opcional)
- **Detalhe do pacote** — linha do tempo completa dos eventos de rastreamento, com pull-to-refresh

- **Ajustes** — credenciais da API oficial dos Correios (usuário, senha, contrato/cartão de postagem), salvas no Keychain

## Estrutura

```
MeusCorreios/
├── App/            MCApp (entry point)
├── APIClient/      MCTrackingServicing, implementação real (Correios) e mock
├── Managers/       MCPackageStore (UserDefaults), MCCredentialsStore + MCKeychainStore
├── Models/         MCPackage, MCTrackingEvent, MCCorreiosCredentials
├── ViewModels/     MCPackageListViewModel
├── Views/          Uma pasta por tela + componentes compartilhados
└── Extensions/     Validação de código de rastreio, classificação/apresentação de status
```

## Integração com a API oficial dos Correios

Baseado no [Portal de desenvolvedores dos Correios](https://www.correios.com.br/atendimento/developers) (Manual de Integração, seção "API Rastro"). É uma **API restrita**: exige cadastro no Meu Correios e o serviço Rastro habilitado no cartão de postagem/contrato.

- **Autenticação**: `POST {base}/token/v1/autentica[/contrato|/cartaopostagem]` com Basic Auth (usuário/senha) → retorna um token Bearer com validade (`MCCorreiosAuthService`, cacheado em memória até expirar).
- **Rastreamento**: `GET {base}/srorastro/v1/objetos/{codigo}?resultado=T` com `Authorization: Bearer {token}` (`MCCorreiosTrackingService`).
- **Ambientes**: produção `https://api.correios.com.br` e homologação `https://apihom.correios.com.br`, configuráveis em Ajustes.

Configure suas credenciais no app (botão de engrenagem na lista). Sem credenciais válidas, a consulta falha com uma mensagem orientando a configurá-las. `MCMockTrackingService` continua disponível (usado nos `#Preview`) para desenvolvimento offline e testes.
