import Foundation

struct ConceptExtractionResult {
    let deckTitle: String
    let sourceDescription: String
    let concepts: [EnrichedConcept]
    let report: ExtractionReport?
}

class AICardGenerationService {

    private let apiService = ClaudeAPIService.shared
    private let batchSize = 1

    func extractConcepts(from notes: String, userPreSummary: String? = nil, onProgress: (@Sendable (String) -> Void)? = nil) async throws -> ConceptExtractionResult {
        print("[ConceptExtraction] Starting extraction. Notes length: \(notes.count) chars, preSummary: \(userPreSummary != nil ? "\(userPreSummary!.count) chars" : "none")")

        let systemPrompt = ClaudePromptTemplates.conceptExtractionSystem
        let userMessage = ClaudePromptTemplates.conceptExtractionUser(notes: notes, userPreSummary: userPreSummary)
        print("[ConceptExtraction] System prompt length: \(systemPrompt.count), user message length: \(userMessage.count)")

        onProgress?("Analyzing your notes...")

        let response = try await apiService.sendMessage(
            system: systemPrompt,
            userMessage: userMessage,
            maxTokens: 16384,
            onProgress: onProgress
        )

        print("[ConceptExtraction] Got response: \(response.count) chars")

        onProgress?("Processing concepts...")

        let cleaned = response.cleanJSONString()

        switch parseConceptExtractionResponse(cleaned) {
        case .success(let result):
            return result
        case .failure(let parseError):
            print("[ConceptExtraction] Initial parse failed, attempting LLM repair...")
            onProgress?("[detail]Fixing malformed response...")

            let repaired = try await requestJSONRepair(malformedJSON: cleaned, parseError: parseError, onProgress: onProgress)

            switch parseConceptExtractionResponse(repaired) {
            case .success(let result):
                print("[ConceptExtraction] LLM repair succeeded, got \(result.concepts.count) concepts")
                return result
            case .failure(let retryError):
                print("[ConceptExtraction] LLM repair also failed: \(retryError)")
                throw ClaudeAPIError.decodingError("Failed to parse concepts after repair attempt: \(retryError.localizedDescription)")
            }
        }
    }

    func generateCards(for concepts: [EnrichedConcept], originalNotes: String, onProgress: (@Sendable (String) -> Void)? = nil) async throws -> [GeneratedFlashcard] {
        var allCards: [GeneratedFlashcard] = []

        let batches = stride(from: 0, to: concepts.count, by: batchSize).map {
            Array(concepts[$0..<min($0 + batchSize, concepts.count)])
        }

        let totalBatches = batches.count
        let expectedTotal = Self.expectedCardCount(for: concepts)

        for (batchIndex, batch) in batches.enumerated() {
            let conceptNames = batch.map { $0.title }.joined(separator: ", ")
            let progressFraction = Float(batchIndex) / Float(totalBatches)
            onProgress?("[progress]\(progressFraction)")
            onProgress?("Batch \(batchIndex + 1)/\(totalBatches): \(conceptNames) (\(allCards.count) of ~\(expectedTotal) cards done)")
            onProgress?("[detail]Starting API call...")

            let cards = try await generateCardsBatch(for: batch, originalNotes: originalNotes, onProgress: onProgress)
            allCards.append(contentsOf: cards)

            let completedFraction = Float(batchIndex + 1) / Float(totalBatches)
            onProgress?("[progress]\(completedFraction)")
            onProgress?("\(allCards.count) of ~\(expectedTotal) cards generated (\(batchIndex + 1)/\(totalBatches) batches)")
        }

        return allCards
    }

    private static func expectedCardCount(for concepts: [EnrichedConcept]) -> Int {
        concepts.reduce(0) { $0 + (($1.tier <= 1) ? 2 : 3) }
    }

    private func parseConceptExtractionResponse(_ cleaned: String) -> Result<ConceptExtractionResult, Error> {
        guard let data = cleaned.data(using: .utf8) else {
            return .failure(ClaudeAPIError.decodingError("Could not convert response to data"))
        }

        do {
            let result = try JSONDecoder().decode(ConceptExtractionResponse.self, from: data)
            print("[ConceptExtraction] Decoded \(result.concepts.count) concepts successfully")
            let enrichedConcepts = result.concepts.map { concept in
                EnrichedConcept(
                    conceptId: concept.conceptId,
                    title: concept.title,
                    summary: concept.summary,
                    importanceRationale: concept.importanceRationale,
                    relatedConcepts: concept.relatedConcepts,
                    relationshipNotes: concept.relationshipNotes,
                    needsVerification: concept.needsVerification,
                    verificationNote: concept.verificationNote,
                    contextNote: concept.contextNote,
                    sourceRefs: concept.sourceRefs,
                    userMentioned: concept.userMentioned,
                    userGapNote: concept.userGapNote,
                    tier: concept.tier ?? 1,
                    dependsOn: concept.dependsOn ?? [],
                    overview: concept.overview ?? ""
                )
            }
            return .success(ConceptExtractionResult(
                deckTitle: result.deckTitle,
                sourceDescription: result.sourceDescription,
                concepts: enrichedConcepts,
                report: result.extractionReport
            ))
        } catch {
            let preview = String(cleaned.prefix(500))
            print("[ConceptExtraction] Decoding FAILED. Response preview: \(preview)")
            print("[ConceptExtraction] Error: \(error)")
            return .failure(error)
        }
    }

    private func generateCardsBatch(for concepts: [EnrichedConcept], originalNotes: String, onProgress: (@Sendable (String) -> Void)? = nil) async throws -> [GeneratedFlashcard] {
        let response = try await apiService.sendMessage(
            system: ClaudePromptTemplates.cardGenerationSystem,
            userMessage: ClaudePromptTemplates.cardGenerationUser(concepts: concepts, originalNotes: originalNotes),
            maxTokens: 12000,
            onProgress: onProgress
        )

        let conceptTitleMap = Dictionary(uniqueKeysWithValues: concepts.map { ($0.conceptId, $0.title) })

        // Try parsing, and if it fails, ask the LLM to repair the JSON
        let cleaned = response.cleanJSONString()
        switch parseCardGenerationResponse(cleaned, conceptTitleMap: conceptTitleMap) {
        case .success(let cards):
            return cards
        case .failure(let parseError):
            print("[CardGeneration] Initial parse failed, attempting LLM repair...")
            onProgress?("[detail]Fixing malformed response...")

            let repaired = try await requestJSONRepair(malformedJSON: cleaned, parseError: parseError, onProgress: onProgress)

            switch parseCardGenerationResponse(repaired, conceptTitleMap: conceptTitleMap) {
            case .success(let cards):
                print("[CardGeneration] LLM repair succeeded, got \(cards.count) cards")
                return cards
            case .failure(let retryError):
                print("[CardGeneration] LLM repair also failed: \(retryError)")
                throw ClaudeAPIError.decodingError("Failed to parse cards after repair attempt: \(retryError.localizedDescription)")
            }
        }
    }

    private func parseCardGenerationResponse(_ cleaned: String, conceptTitleMap: [String: String]) -> Result<[GeneratedFlashcard], Error> {
        guard let data = cleaned.data(using: .utf8) else {
            return .failure(ClaudeAPIError.decodingError("Could not convert response to data"))
        }

        do {
            let result = try JSONDecoder().decode(CardGenerationResponse.self, from: data)

            let cards = result.cards.map { card in
                GeneratedFlashcard(
                    question: card.front.question,
                    constraints: card.front.constraints ?? [],
                    bulletPoints: card.back.idealAnswerBullets,
                    modelParagraph: card.back.modelAnswerParagraph,
                    backgroundContext: card.back.backgroundContext ?? [],
                    conceptName: conceptTitleMap[card.conceptId] ?? card.conceptId,
                    conceptId: card.conceptId,
                    cardType: card.cardType,
                    cardTypeRationale: card.cardTypeRationale,
                    gradingRubric: card.gradingRubric,
                    needsVerification: card.needsVerification ?? false,
                    verificationNote: card.verificationNote,
                    sourceRefs: card.sourceRefs ?? [],
                    cardId: card.cardId ?? UUID().uuidString,
                    tier: card.tier ?? 1,
                    dependsOnCards: card.dependsOnCards ?? []
                )
            }
            return .success(cards)
        } catch {
            let preview = String(cleaned.prefix(500))
            print("[CardGeneration] Decoding failed. Response preview: \(preview)")
            print("[CardGeneration] Error: \(error)")
            return .failure(error)
        }
    }

    private func requestJSONRepair(malformedJSON: String, parseError: Error, onProgress: (@Sendable (String) -> Void)? = nil) async throws -> String {
        let systemPrompt = """
            You are a JSON repair assistant. You will be given a malformed JSON response and the parse error. \
            Fix the JSON so it is valid and matches the expected structure. Return ONLY the corrected JSON, no explanation or markdown fences.
            """

        // Truncate very large responses to stay within token limits
        let truncated: String
        if malformedJSON.count > 15000 {
            truncated = String(malformedJSON.prefix(15000)) + "\n... [TRUNCATED]"
        } else {
            truncated = malformedJSON
        }

        let userMessage = """
            The following JSON response failed to parse. Please fix it and return only valid JSON.

            Parse error:
            \(parseError.localizedDescription)

            Malformed JSON:
            \(truncated)
            """

        let repairResponse = try await apiService.sendMessage(
            system: systemPrompt,
            userMessage: userMessage,
            maxTokens: 12000,
            onProgress: onProgress
        )

        return repairResponse.cleanJSONString()
    }
}
