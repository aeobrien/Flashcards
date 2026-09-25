import Foundation

enum LogLevel: String {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

class DebugLogService {

    static let shared = DebugLogService()

    private let logFileName = "debug_logs.txt"
    private let maxLogSize = 500_000 // ~500KB, trim when exceeded
    private let queue = DispatchQueue(label: "com.flashcards.debuglog", qos: .utility)

    private var logFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(logFileName)
    }

    private init() {}

    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let entry = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(function)] \(message)\n"

        // Also print to console
        print(entry, terminator: "")

        queue.async { [weak self] in
            self?.appendToFile(entry)
        }
    }

    func readLogs() -> String {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return "(No logs yet)"
        }
        return (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "(Could not read logs)"
    }

    func clearLogs() {
        queue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.logFileURL)
        }
    }

    private func appendToFile(_ entry: String) {
        let fileManager = FileManager.default
        let url = logFileURL

        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }

        // Trim if too large: keep last half
        if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int, size > maxLogSize {
            trimLogFile()
        }

        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        handle.seekToEndOfFile()
        if let data = entry.data(using: .utf8) {
            handle.write(data)
        }
        handle.closeFile()
    }

    private func trimLogFile() {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: "\n")
        let keepFrom = lines.count / 2
        let trimmed = lines.suffix(from: keepFrom).joined(separator: "\n")
        try? trimmed.write(to: logFileURL, atomically: true, encoding: .utf8)
    }
}

// MARK: - Card Recovery

extension DebugLogService {

    private var recoveryFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("card_recovery.json")
    }

    var hasRecoveryFile: Bool {
        FileManager.default.fileExists(atPath: recoveryFileURL.path)
    }

    var recoveryFileDate: Date? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: recoveryFileURL.path) else { return nil }
        return attrs[.modificationDate] as? Date
    }

    func saveRecoveryData(cards: [GeneratedFlashcard], deckName: String, sourceDescription: String, concepts: [EnrichedConcept]) {
        let recovery = CardRecoveryData(
            deckName: deckName,
            sourceDescription: sourceDescription,
            cards: cards.map { CodableGeneratedFlashcard(from: $0) },
            concepts: concepts.map { CodableEnrichedConcept(from: $0) },
            savedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(recovery)
            try data.write(to: recoveryFileURL, options: .atomic)
            log("Recovery file saved: \(cards.count) cards, \(concepts.count) concepts")
        } catch {
            log("Failed to save recovery file: \(error)", level: .error)
        }
    }

    func loadRecoveryData() -> CardRecoveryData? {
        guard hasRecoveryFile else { return nil }
        do {
            let data = try Data(contentsOf: recoveryFileURL)
            return try JSONDecoder().decode(CardRecoveryData.self, from: data)
        } catch {
            log("Failed to load recovery file: \(error)", level: .error)
            return nil
        }
    }

    func deleteRecoveryFile() {
        try? FileManager.default.removeItem(at: recoveryFileURL)
        log("Recovery file deleted")
    }
}

// MARK: - Codable Recovery Models

struct CardRecoveryData: Codable {
    let deckName: String
    let sourceDescription: String
    let cards: [CodableGeneratedFlashcard]
    let concepts: [CodableEnrichedConcept]
    let savedAt: Date
}

struct CodableGeneratedFlashcard: Codable {
    let question: String
    let constraints: [String]
    let bulletPoints: [String]
    let modelParagraph: String
    let backgroundContext: [String]
    let conceptName: String
    let conceptId: String
    let cardType: String
    let cardTypeRationale: String?
    let gradingRubric: GradingRubricResponse?
    let needsVerification: Bool
    let verificationNote: String?
    let sourceRefs: [String]
    let cardId: String
    let tier: Int
    let dependsOnCards: [String]
    let isSelected: Bool

    init(from card: GeneratedFlashcard) {
        self.question = card.question
        self.constraints = card.constraints
        self.bulletPoints = card.bulletPoints
        self.modelParagraph = card.modelParagraph
        self.backgroundContext = card.backgroundContext
        self.conceptName = card.conceptName
        self.conceptId = card.conceptId
        self.cardType = card.cardType
        self.cardTypeRationale = card.cardTypeRationale
        self.gradingRubric = card.gradingRubric
        self.needsVerification = card.needsVerification
        self.verificationNote = card.verificationNote
        self.sourceRefs = card.sourceRefs
        self.cardId = card.cardId
        self.tier = card.tier
        self.dependsOnCards = card.dependsOnCards
        self.isSelected = card.isSelected
    }

    func toGeneratedFlashcard() -> GeneratedFlashcard {
        GeneratedFlashcard(
            question: question,
            constraints: constraints,
            bulletPoints: bulletPoints,
            modelParagraph: modelParagraph,
            backgroundContext: backgroundContext,
            conceptName: conceptName,
            conceptId: conceptId,
            cardType: cardType,
            cardTypeRationale: cardTypeRationale,
            gradingRubric: gradingRubric,
            needsVerification: needsVerification,
            verificationNote: verificationNote,
            sourceRefs: sourceRefs,
            cardId: cardId,
            tier: tier,
            dependsOnCards: dependsOnCards,
            isSelected: isSelected
        )
    }
}

struct CodableEnrichedConcept: Codable {
    let conceptId: String
    let title: String
    let summary: String
    let importanceRationale: String
    let relatedConcepts: [String]
    let relationshipNotes: String
    let needsVerification: Bool
    let verificationNote: String?
    let contextNote: String?
    let sourceRefs: [String]
    let userMentioned: String?
    let userGapNote: String?
    let tier: Int
    let dependsOn: [String]
    let overview: String?
    let isIncluded: Bool

    init(from concept: EnrichedConcept) {
        self.conceptId = concept.conceptId
        self.title = concept.title
        self.summary = concept.summary
        self.importanceRationale = concept.importanceRationale
        self.relatedConcepts = concept.relatedConcepts
        self.relationshipNotes = concept.relationshipNotes
        self.needsVerification = concept.needsVerification
        self.verificationNote = concept.verificationNote
        self.contextNote = concept.contextNote
        self.sourceRefs = concept.sourceRefs
        self.userMentioned = concept.userMentioned
        self.userGapNote = concept.userGapNote
        self.tier = concept.tier
        self.dependsOn = concept.dependsOn
        self.overview = concept.overview
        self.isIncluded = concept.isIncluded
    }

    func toEnrichedConcept() -> EnrichedConcept {
        EnrichedConcept(
            conceptId: conceptId,
            title: title,
            summary: summary,
            importanceRationale: importanceRationale,
            relatedConcepts: relatedConcepts,
            relationshipNotes: relationshipNotes,
            needsVerification: needsVerification,
            verificationNote: verificationNote,
            contextNote: contextNote,
            sourceRefs: sourceRefs,
            userMentioned: userMentioned,
            userGapNote: userGapNote,
            tier: tier,
            dependsOn: dependsOn,
            overview: overview ?? "",
            isIncluded: isIncluded
        )
    }
}
