# Desenvolvimento

## Requisitos

- macOS com **Xcode 27** (validado na 27.0) e a plataforma iOS instalada
- **iOS 26** como deployment target (`project.yml`)
- [**XcodeGen**](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Gerando o projeto

O `.xcodeproj` **não é versionado** (está no `.gitignore`) — ele é gerado a partir do
`project.yml`. Consequência prática: **todo arquivo novo exige regenerar o projeto**, senão ele
não entra no target e o build ignora o arquivo.

```bash
make generate
```

O alvo fecha o Xcode, apaga o `.xcodeproj` e os `.DS_Store`, roda o `xcodegen` e reabre o projeto.
Dá para controlar as duas pontas:

```bash
make generate close=no   # não fecha o Xcode antes
make generate open=no    # não reabre o Xcode depois
make clean               # só remove o .xcodeproj e os .DS_Store
```

Se o Xcode já estiver aberto e você não quiser perder o estado, `xcodegen generate` sozinho
resolve — basta reabrir o projeto em seguida.

O `project.yml` usa um `targetTemplate` (`iOSApp`) com `sources: [MeusCorreios]`, ou seja, a pasta
inteira entra no target por convenção de diretório: crie o arquivo no lugar certo e regenere.

## Build e execução pela linha de comando

```bash
xcodebuild -project MeusCorreios.xcodeproj -scheme MeusCorreios \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

Para rodar num simulador específico:

```bash
xcrun simctl list devices booted
xcodebuild -project MeusCorreios.xcodeproj -scheme MeusCorreios \
  -destination 'id=<UDID>' -derivedDataPath /tmp/DD build
xcrun simctl install <UDID> /tmp/DD/Build/Products/Debug-iphonesimulator/MeusCorreios.app
xcrun simctl launch <UDID> com.devmeist3r.MeusCorreios
```

## Rodando sem credenciais dos Correios

A API é restrita. Para trabalhar na interface sem conta, troque o serviço padrão em
`MCPackageListViewModel`:

```swift
self.service = service ?? MCMockTrackingService()
```

`MCMockTrackingService` é determinístico (o mesmo código gera sempre a mesma linha do tempo) e
tem um atraso artificial de 0,5 s, o que deixa visíveis os estados de carregamento. Os `#Preview`
já usam esse serviço — para muita coisa de UI, o canvas do Xcode basta.

## Onde os dados ficam (e como limpar)

| Dado | Onde | Como zerar |
| --- | --- | --- |
| Pacotes e eventos | SwiftData (`default.store` no container do app) | desinstalar o app |
| Credenciais | Chaveiro (`com.devmeist3r.MeusCorreios.credentials`) | desinstalar o app |
| Tema | `UserDefaults`, chave `MCAppearance.selected` | desinstalar, ou `defaults delete` |

```bash
xcrun simctl uninstall booted com.devmeist3r.MeusCorreios
xcrun simctl spawn booted defaults delete com.devmeist3r.MeusCorreios MCAppearance.selected
```

Para inspecionar o banco do simulador:

```bash
find ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application \
  -name 'default.store' 2>/dev/null
```

## Testes

O projeto **ainda não tem target de testes**. Enquanto não tiver, a camada de persistência — que
é a parte com lógica não trivial — pode ser exercitada compilando os arquivos direto para macOS,
já que `MCPackageStore` e seus modelos não dependem de UIKit:

```bash
swiftc -O -parse-as-library \
  MeusCorreios/Models/MCTrackingEvent.swift \
  MeusCorreios/Models/MCPackage.swift \
  MeusCorreios/Managers/MCPackageRecord.swift \
  MeusCorreios/Managers/MCPackageStore.swift \
  harness.swift -o harness && ./harness
```

Onde `harness.swift` monta um `MCPackageStore.inMemory()` (ou passa um `ModelContext` próprio,
para conseguir contar registros) e chama `upsert`/`remove`. Foi assim que o merge de eventos e a
ausência de registros órfãos foram verificados.

Um target de testes de verdade (`MeusCorreiosTests` no `project.yml`, com Swift Testing) é o
próximo passo natural: as candidatas óbvias são `MCTrackingCode`, `MCTrackingStatus.classify`,
o merge do `MCPackageStore` e o mapeamento dos DTOs.

## Convenções de código

- Prefixo `MC` em todos os tipos; arquivo com o nome do tipo principal.
- Uma pasta por tela em `Views/`, componentes compartilhados em `Views/Shared/`.
- Extensões nomeadas por assunto: `MCTrackingStatus+Classification`, `+Presentation`.
- Dependências injetadas pelo `init`, com default que monta o grafo real.
- Comentários (em português) reservados para o **porquê** — regra de negócio da API, decisão de
  arquitetura — não para repetir o que o código já diz.
- `.editorconfig`: 2 espaços em `.sh`, tab em `Makefile`.

## Estrutura de pastas

```
MeusCorreios/
├── App/            MCApp — entry point, tema e injeção do ModelContainer
├── APIClient/      Protocolo, serviço real, serviço falso, DTOs
├── Extensions/     Validação de código, parse de data, classificação e apresentação de status
├── Managers/       MCPackageStore + MCPackageRecord (SwiftData), MCCredentialsStore + MCKeychainStore
├── Models/         MCPackage, MCTrackingEvent, MCCorreiosCredentials, MCAppearance
├── Resources/      Assets.xcassets (AppIcon, AccentColor)
├── ViewModels/     MCPackageListViewModel
└── Views/          Uma pasta por tela + Shared/
```
