import Foundation
import OSLog
import SwiftData

@MainActor
final class MCPackageStore: ObservableObject {
    @Published private(set) var packages: [MCPackage] = []

    private let context: ModelContext
    private var logger: Logger { Self.logger }
    private static let logger = Logger(subsystem: "com.devmeist3r.MeusCorreios", category: "MCPackageStore")

    /// Sem `context`, usa o container compartilhado do app (em disco) e migra
    /// uma única vez os pacotes salvos pela versão anterior em `UserDefaults`.
    init(context: ModelContext? = nil) {
        let usesSharedContext = context == nil
        self.context = context ?? Self.sharedContainer.mainContext
        if usesSharedContext {
            migrateLegacyStorageIfNeeded()
        }
        reload()
    }

    /// Store isolado em memória, para previews e testes.
    static func inMemory() -> MCPackageStore {
        MCPackageStore(context: ModelContext(makeContainer(inMemory: true)))
    }

    func upsert(_ package: MCPackage) {
        let record: MCPackageRecord
        if let existing = fetchRecord(id: package.id) {
            record = existing
        } else {
            record = MCPackageRecord(id: package.id, nickname: package.nickname)
            context.insert(record)
        }
        record.nickname = package.nickname
        merge(package.events, into: record)
        save()
        reload()
    }

    /// Casa os eventos recebidos da API com os já salvos pela `matchKey`: os que já existem
    /// são reaproveitados (mantendo o mesmo registro e o mesmo `id`), só os novos são inseridos
    /// e os que sumiram da origem são apagados.
    private func merge(_ events: [MCTrackingEvent], into record: MCPackageRecord) {
        var reusable = Dictionary(grouping: record.events, by: \.matchKey)

        let merged = events.map { event -> MCTrackingEventRecord in
            guard let existing = reusable[event.matchKey]?.first else {
                return MCTrackingEventRecord(event)
            }
            reusable[event.matchKey]?.removeFirst()
            // A classificação do status pode mudar entre versões do app.
            existing.status = event.status
            return existing
        }

        reusable.values.flatMap { $0 }.forEach { context.delete($0) }
        record.events = merged
    }

    func remove(at offsets: IndexSet) {
        for index in offsets {
            guard let record = fetchRecord(id: packages[index].id) else { continue }
            context.delete(record)
        }
        save()
        reload()
    }

    private func fetchRecord(id: String) -> MCPackageRecord? {
        let descriptor = FetchDescriptor<MCPackageRecord>(predicate: #Predicate { $0.id == id })
        return fetch(descriptor).first
    }

    private func reload() {
        let descriptor = FetchDescriptor<MCPackageRecord>(sortBy: [SortDescriptor(\.createdAt)])
        packages = fetch(descriptor).map(\.asPackage)
    }

    private func fetch(_ descriptor: FetchDescriptor<MCPackageRecord>) -> [MCPackageRecord] {
        do {
            return try context.fetch(descriptor)
        } catch {
            logger.error("Falha ao ler os pacotes: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            context.rollback()
            logger.error("Falha ao salvar os pacotes: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Migração da persistência antiga (UserDefaults)

    private static let legacyStorageKey = "MCPackageStore.packages"

    private func migrateLegacyStorageIfNeeded(defaults: UserDefaults = .standard) {
        guard let data = defaults.data(forKey: Self.legacyStorageKey) else { return }
        defer { defaults.removeObject(forKey: Self.legacyStorageKey) }

        guard let legacyPackages = try? JSONDecoder().decode([MCPackage].self, from: data) else {
            logger.error("Dados antigos em UserDefaults não puderam ser lidos; descartando.")
            return
        }

        let base = Date.now
        for (index, package) in legacyPackages.enumerated() where fetchRecord(id: package.id) == nil {
            // O offset preserva a ordem original da lista.
            let record = MCPackageRecord(
                id: package.id,
                nickname: package.nickname,
                createdAt: base.addingTimeInterval(Double(index) / 1_000)
            )
            record.events = package.events.map(MCTrackingEventRecord.init)
            context.insert(record)
        }
        save()
    }

    // MARK: - Container

    static let sharedContainer = makeContainer(inMemory: false)

    /// `true` quando o banco em disco não pôde ser aberto e o app está rodando
    /// só com memória — nada do que for adicionado sobrevive ao encerramento.
    private(set) static var isUsingFallbackStorage = false

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        do {
            return try makeContainer(isStoredInMemoryOnly: inMemory)
        } catch {
            // Um banco corrompido ou incompatível derrubaria o app no lançamento,
            // em loop, sem caminho de recuperação. Degrada para memória.
            logger.error("Banco local indisponível, usando armazenamento temporário: \(error.localizedDescription, privacy: .public)")
            isUsingFallbackStorage = true
            do {
                return try makeContainer(isStoredInMemoryOnly: true)
            } catch {
                fatalError("Não foi possível inicializar o banco de dados local: \(error)")
            }
        }
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        try ModelContainer(
            for: MCPackageRecord.self, MCTrackingEventRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        )
    }
}
