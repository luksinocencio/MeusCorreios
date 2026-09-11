# Interface

SwiftUI puro, uma `NavigationStack` e duas sheets. Sem storyboards, sem UIKit. Português no
código; iPhone travado em retrato (o iPad aceita todas as orientações, via `Info.plist`).

## Navegação

```
MCPackageListView  (raiz, NavigationStack)
├── navigationDestination(String) → MCTrackingDetailView   (push, pelo id do pacote)
├── sheet → MCAddPackageView
└── sheet → MCSettingsView
```

O push usa `NavigationLink(value:)` com o **id do pacote**, não o pacote inteiro. O detalhe busca
`viewModel.packages.first { $0.id == packageID }` a cada render, então um refresh que altera a
lista atualiza a tela aberta — e, se o pacote for removido, a tela mostra "Pacote não encontrado"
em vez de exibir dados congelados.

## Telas

### Meus Pacotes — `MCPackageListView`

Raiz do app. Sem pacotes, mostra `MCEmptyStateView` com um botão que abre a sheet de adicionar.
Com pacotes, uma `List` de `MCPackageRow` com swipe-to-delete (`.onDelete`). Na toolbar:
engrenagem (Ajustes) à esquerda, `+` (adicionar) à direita.

É aqui que vive o `.alert("Ops")` alimentado por `viewModel.errorMessage`, usado pelos erros de
**atualização** (pull-to-refresh). Erros ao adicionar são apresentados pela própria sheet: um
alerta disparado por esta view enquanto a sheet está aberta faria o SwiftUI descartá-la.

É também a única View que cria o ViewModel, com `@StateObject` e um closure no init, para que a
instância sobreviva às recomposições e possa ser substituída nos previews:

```swift
init(viewModel: (() -> MCPackageListViewModel)? = nil)
```

### Adicionar pacote — `MCAddPackageView`

`Form` com código de rastreio (maiúsculas automáticas, sem autocorreção) e apelido opcional.
**Salvar** fica desabilitado enquanto o código não passar em `MCTrackingCode.isValid` ou enquanto
a consulta estiver em andamento, quando o botão vira um `ProgressView`. A sheet tem o **próprio**
`.alert`, com estado local: no erro ela continua aberta, com código e apelido preenchidos, e só
fecha quando a consulta dá certo.

### Detalhe do pacote — `MCTrackingDetailView`

Cabeçalho com o código e o status atual, e a seção "Linha do tempo" com os eventos em ordem
**decrescente** de data (mais recente primeiro), cada um como `MCTrackingEventRow`.
`.refreshable` refaz a consulta daquele pacote. O título é `package.displayName` — o apelido,
ou o código quando não há apelido.

### Ajustes — `MCSettingsView`

`Form` com quatro seções:

0. **Aviso de armazenamento** — só aparece se o banco local não pôde ser aberto e o app está
   rodando em memória (`MCPackageStore.isUsingFallbackStorage`).
1. **Aparência** — `Picker` de tema (Sistema / Claro / Escuro).
2. **Ambiente** — produção ou homologação.
3. **Autenticação** — modo (usuário e senha / contrato / cartão de postagem), usuário e senha.
4. **Dados do contrato** — contrato, DR e cartão de postagem; a seção só aparece quando o modo
   escolhido exige esses campos, e o cartão só no modo correspondente.

No rodapé, link para o portal de desenvolvedores e o aviso de que as credenciais ficam apenas no
Chaveiro do aparelho. Não existe botão "salvar" — só "Concluir", que fecha a sheet: o `didSet` de
`MCCredentialsStore.credentials` agenda a gravação com um debounce de 500 ms (sem ele, cada tecla
custaria um delete + add no Chaveiro), e o `.onDisappear` chama `saveNow()` para nada se perder
se o app for encerrado dentro dessa janela.

## Componentes compartilhados

| Componente | Uso |
| --- | --- |
| `MCPackageRow` | Linha da lista: apelido, código (se diferente do apelido), status atual e `ProgressView` quando aquele pacote está sendo consultado |
| `MCTrackingEventRow` | Item da linha do tempo: ícone colorido do status, descrição, local e data formatada |
| `MCEmptyStateView` | Estado vazio da lista, com CTA que abre a sheet de adicionar |

## Status: ícone e cor

Definidos em `MCTrackingStatus+Presentation`, separados da lógica que decide o status.

| Status | SF Symbol | Cor |
| --- | --- | --- |
| Postado | `shippingbox` | accent |
| Em trânsito | `shippingbox.and.arrow.backward` | accent |
| Na unidade de distribuição | `building.2` | accent |
| Saiu para entrega | `bicycle` | accent |
| Entregue | `checkmark.circle.fill` | verde |
| Tentativa de entrega não efetuada | `exclamationmark.triangle.fill` | vermelho |

A cor accent vem de `Resources/Assets.xcassets/AccentColor.colorset`.

## Tema claro/escuro

`MCAppearance` (`sistema` / `claro` / `escuro`) é salvo em `UserDefaults` com `@AppStorage`, na
chave `MCAppearance.selected`. `MCApp` lê o valor e aplica `.preferredColorScheme(_:)` na raiz —
`nil` no caso `sistema`, deixando o app seguir o aparelho. Como o modificador está na raiz da
`WindowGroup`, o tema também vale para as sheets.

`MCSettingsView` declara o **mesmo** `@AppStorage`; a sincronia entre o picker e a raiz é do
próprio `UserDefaults`, sem binding manual entre as telas.

Nenhuma cor do app é fixada em hex: tudo sai de `Color.accentColor`, `.green`, `.red` e dos estilos
semânticos (`.secondary`, `.tertiary`), que já se adaptam aos dois temas.

## Previews

Toda View tem `#Preview`, sempre com dependências falsas — `MCMockTrackingService` para a rede e
`MCPackageStore.inMemory()` para o banco. Nenhum preview escreve no banco real nem dispara a
migração da persistência antiga.

```swift
MCPackageListViewModel(store: .inMemory(), service: MCMockTrackingService())
```

## Acessibilidade e pendências

- Os textos usam estilos dinâmicos (`.headline`, `.caption`), então Dynamic Type funciona; não há,
  porém, `accessibilityLabel` customizado nos ícones de status.
- Não há estado de carregamento na primeira abertura (a lista vem do banco, instantânea).
- Sem tratamento explícito de offline além da mensagem genérica de falha de requisição.
