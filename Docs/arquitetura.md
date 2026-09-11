# Arquitetura

O **Meus Correios** é um app iOS de tela única (mais duas modais) que consulta a API Rastro dos
Correios e guarda localmente os pacotes acompanhados. Não há backend próprio: o app fala direto
com a API oficial, usando as credenciais do próprio usuário.

## Camadas

```
          Views (SwiftUI)                 MCPackageListView, MCAddPackageView,
                │                          MCTrackingDetailView, MCSettingsView
                │  @Published
        MCPackageListViewModel            orquestra: valida, chama a API, salva, expõe erro
           ╱            ╲
   MCPackageStore    MCTrackingServicing  persistência local │ acesso à rede
        │                    ╲
   SwiftData             MCCorreiosTrackingService ── MCCorreiosAuthService ── MCCredentialsStore
   (@Model)              MCMockTrackingService                                      │
                                                                                 Keychain
```

Regras que sustentam esse desenho:

- **A View não conhece persistência nem rede.** Ela recebe um `MCPackageListViewModel` e só lê
  `packages`, `errorMessage` e `isLoading(_:)`.
- **O ViewModel não conhece SwiftData nem `URLSession`.** Ele fala com o `MCPackageStore` e com
  o protocolo `MCTrackingServicing`.
- **Os tipos de domínio são structs.** `MCPackage` e `MCTrackingEvent` são valores `Codable`,
  usados de ponta a ponta. As classes `@Model` do SwiftData ficam confinadas ao store
  (ver [persistência](persistencia-swiftdata.md)).
- **Tudo roda na main actor.** Store, ViewModel e serviços são `@MainActor`; o trabalho
  assíncrono acontece dentro de `async/await` sobre `URLSession`, que já sai da main thread por
  conta própria. Não há filas nem locks manuais no projeto.

## Injeção de dependências

Todos os tipos recebem suas dependências pelo `init`, com um valor padrão que monta o grafo real:

```swift
init(store: MCPackageStore? = nil,
     credentialsStore: MCCredentialsStore? = nil,
     service: MCTrackingServicing? = nil)
```

Assim o app não precisa de nenhum container de DI, e previews/testes trocam o que precisam:

```swift
MCPackageListViewModel(store: .inMemory(), service: MCMockTrackingService())
```

## Fluxo: adicionar um pacote

1. `MCAddPackageView` habilita **Salvar** apenas quando `MCTrackingCode.isValid(code)` — 2 letras,
   9 dígitos, 2 letras.
2. `viewModel.add(code:nickname:)` normaliza o código (trim + maiúsculas) e marca o id em
   `loadingIDs`, o que faz a linha da lista mostrar um `ProgressView`.
3. `MCCorreiosTrackingService.trackPackage(code:)` pede um token ao `MCCorreiosAuthService`
   (que reaproveita o token em memória enquanto válido) e chama a API Rastro.
4. A resposta vira `MCPackage` com os eventos já classificados
   (ver [API dos Correios](api-correios.md)).
5. O apelido digitado é aplicado ao pacote e `store.upsert(_:)` grava no SwiftData.
6. O store republica `packages`; o ViewModel espelha via `assign(to:)`; a lista se atualiza.
7. Se algo falha, `add(code:nickname:)` **propaga** o erro: a sheet apresenta o alerta por conta
   própria e continua aberta, com o que foi digitado. Um alerta disparado pela raiz enquanto a
   sheet está aberta faria o SwiftUI descartar a sheet junto — e o formulário com ela.

## Fluxo: atualizar (pull-to-refresh)

Mesmo caminho, entrando por `viewModel.refresh(_:)` a partir do `.refreshable` do detalhe. A
diferença está no `upsert`: os eventos que já existem são reaproveitados em vez de recriados,
preservando o `id` de cada evento. O detalhe está em [persistência](persistencia-swiftdata.md).

## Estado e erros

| Estado | Onde vive | Como chega na View |
| --- | --- | --- |
| Lista de pacotes | SwiftData → `MCPackageStore.packages` | `assign(to:)` → `@Published packages` |
| Carregando | `loadingIDs: Set<String>` no ViewModel | `viewModel.isLoading(package)` |
| Erro no refresh | `errorMessage: String?` no ViewModel | `.alert` em `MCPackageListView` |
| Erro ao adicionar | `@State` local na sheet | `.alert` em `MCAddPackageView` |
| Credenciais | Keychain → `MCCredentialsStore.credentials` | `@ObservedObject` em `MCSettingsView` |
| Tema | `UserDefaults` via `@AppStorage` | `.preferredColorScheme` em `MCApp` |

Os erros de rede e de autenticação são modelados em `MCTrackingError`, um `LocalizedError` cujas
mensagens já são o texto exibido ao usuário, em português e orientando a ação
("Configure suas credenciais da API dos Correios em Ajustes."). Erros de persistência não viram
alerta: são registrados com `Logger` e o `save()` faz rollback.

## Convenções

- **Prefixo `MC`** em todos os tipos do app.
- **Uma pasta por tela** em `Views/`, com `Views/Shared/` para componentes reutilizados.
- **Textos de interface em português**, diretamente no código (o projeto ainda não usa
  `Localizable.strings`; `developmentLanguage` é `pt-BR`).
- **Extensões separadas por responsabilidade**: `MCTrackingStatus+Classification` (regra de
  negócio) e `MCTrackingStatus+Presentation` (ícone e cor) não se misturam.
- **`#Preview` em toda View**, sempre com dependências falsas — `MCMockTrackingService` e
  `MCPackageStore.inMemory()`, nunca a API real ou o banco em disco.

## Limitações conhecidas

- Não há target de testes no `project.yml`; a verificação da camada de persistência é feita
  compilando os arquivos para macOS (receita em [desenvolvimento](desenvolvimento.md)).
- A atualização é manual (pull-to-refresh); não há background refresh nem notificações.
- Sem paginação ou limite na lista: o app busca a linha do tempo inteira a cada atualização,
  que é o que a API devolve.
