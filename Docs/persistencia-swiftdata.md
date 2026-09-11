# Persistência com SwiftData

A lista de pacotes acompanhados é salva localmente com **SwiftData**. Este documento descreve
como a camada está organizada, por que ela existe desta forma e o que observar ao evoluí-la.

> Credenciais da API **não** passam por aqui: ficam no Chaveiro, via `MCCredentialsStore` +
> `MCKeychainStore`. Preferências de interface (tema) ficam em `UserDefaults`, via `@AppStorage`.

## Duas camadas: domínio e persistência

| Camada | Tipos | Onde é usada |
| --- | --- | --- |
| Domínio | `MCPackage`, `MCTrackingEvent` (structs `Codable`) | ViewModels, Views, APIClient |
| Persistência | `MCPackageRecord`, `MCTrackingEventRecord` (`@Model`) | Apenas dentro de `MCPackageStore` |

Os `@Model` são classes de referência e não são `Sendable`; mantê-los confinados ao store evita
que referências gerenciadas vazem para as Views e preserva o `MCPackage` como um valor imutável
e fácil de testar. A conversão acontece em um único ponto: `MCPackageRecord.asPackage`.

## Grafo de modelos

```
MCPackageRecord
├── id: String            @Attribute(.unique)   — código de rastreio normalizado
├── nickname: String                            — apelido dado pelo usuário
├── createdAt: Date                             — ordem de exibição na lista
└── events: [MCTrackingEventRecord]             @Relationship(deleteRule: .cascade)
        ├── id: UUID
        ├── date: Date
        ├── location: String
        ├── status: MCTrackingStatus            — enum String, persistido direto
        ├── eventDescription: String            — "description" é reservado em NSObject
        └── package: MCPackageRecord?           — inverso da relação
```

- `id` único garante que o mesmo código de rastreio nunca duplique na lista.
- `deleteRule: .cascade` faz os eventos serem apagados junto com o pacote.
- `createdAt` existe porque a ordenação natural (`id`) embaralharia a lista; a ordem é a de
  inserção. Os eventos, por sua vez, são ordenados por data na conversão para domínio.

## Container

`MCPackageStore.sharedContainer` é um `ModelContainer` estático, criado uma única vez:

- `MCPackageStore()` (sem argumento) usa o `mainContext` desse container;
- `MCApp` injeta o **mesmo** container na hierarquia via `.modelContainer(_:)`, então o ambiente
  SwiftData fica disponível para futuras views com `@Query` sem abrir um segundo container;
- `MCPackageStore.inMemory()` cria um container com `isStoredInMemoryOnly: true`, usado nos
  `#Preview` e em testes — previews não escrevem no banco real nem disparam a migração legada.

Abrir mais de um container em disco sobre o mesmo arquivo causa disputa pelo SQLite; por isso o
container é compartilhado e o store nunca instancia um novo por conta própria.

## Leitura e escrita

`MCPackageStore` é `@MainActor` e `ObservableObject`. Ele publica `packages: [MCPackage]`, que o
`MCPackageListViewModel` espelha com `assign(to:)`. Toda escrita segue o mesmo ciclo:

```
mutação no ModelContext → save() → reload() → @Published packages → View
```

`reload()` refaz o fetch ordenado por `createdAt`. Falhas de fetch e de save são registradas com
`Logger` (subsystem `com.devmeist3r.MeusCorreios`); um `save()` que falha faz `rollback()` no
contexto, para não deixar mudanças pela metade em memória.

## Merge de eventos no `upsert`

A API Rastro não devolve um identificador por evento, e um refresh retorna a linha do tempo
inteira novamente. Apagar e recriar todos os eventos a cada atualização funcionava, mas gerava
escrita desnecessária e trocava o `UUID` de eventos que não mudaram — o que quebraria qualquer
funcionalidade ancorada nesse id (diff de "o que há de novo", notificações, animações de lista).

O `upsert` faz merge por **chave natural**:

```swift
matchKey = "\(date.timeIntervalSince1970)|\(location)|\(description)"
```

Para cada evento recebido:

- já existe um registro com a mesma chave → reaproveita o registro (mantém o `id`) e só atualiza
  o `status`, que pode mudar quando a lógica de classificação (`MCTrackingStatus.classify`) evolui;
- não existe → insere um novo registro;
- registros salvos que não apareceram na resposta → apagados.

Os candidatos são agrupados com `Dictionary(grouping:by:)` e consumidos um a um, então eventos
legitimamente duplicados (mesma data, local e descrição) são preservados na mesma quantidade.

## Migração da persistência anterior (`UserDefaults`)

Antes do SwiftData a lista era um JSON em `UserDefaults`, na chave `MCPackageStore.packages`.
Na primeira inicialização com o contexto compartilhado, `migrateLegacyStorageIfNeeded()`:

1. lê a chave antiga — se ela não existir, não faz nada;
2. decodifica `[MCPackage]` e insere os pacotes que ainda não estão no banco, dando a cada um um
   `createdAt` com offset incremental para preservar a ordem original;
3. remove a chave antiga (num `defer`, inclusive se o JSON estiver corrompido — dado ilegível não
   fica tentando migrar para sempre).

A migração roda **apenas** no contexto em disco. Quando o `MCPackageStore` recebe um contexto
injetado (previews, testes), ela é ignorada.

Esse código pode ser removido quando não houver mais instalações vindas da versão que usava
`UserDefaults`.

## Evoluindo o schema

Mudanças aditivas simples (nova propriedade opcional ou com valor padrão) são resolvidas pela
migração leve automática do SwiftData. Para mudanças que renomeiam, removem ou alteram o tipo de
uma propriedade, crie um `VersionedSchema` por versão e um `SchemaMigrationPlan`, passando-o em
`ModelContainer(for:migrationPlan:configurations:)` dentro de `makeContainer(inMemory:)`.

Ao testar localmente, apagar o app do simulador zera o banco:

```bash
xcrun simctl uninstall booted com.devmeist3r.MeusCorreios
```
