import Foundation

class AIGradingService {

    private let apiService = ClaudeAPIService.shared

    func gradeAnswer(question: String,
                     constraints: [String],
                     bulletPoints: [String],
                     modelParagraph: String,
                     gradingRubric: GradingRubric?,
                     studentAnswer: String) async throws -> GradingResponse {
        let response = try await apiService.sendMessage(
            system: ClaudePromptTemplates.gradingSystem,
            userMessage: ClaudePromptTemplates.gradingUser(
                question: question,
                constraints: constraints,
                bulletPoints: bulletPoints,
                modelParagraph: modelParagraph,
                gradingRubric: gradingRubric,
                studentAnswer: studentAnswer
            )
        )

        let cleaned = response.cleanJSONString()
        guard let data = cleaned.data(using: .utf8) else {
            throw ClaudeAPIError.decodingError("Could not convert response to data")
        }

        do {
            var result = try JSONDecoder().decode(GradingResponse.self, from: data)
            let clampedGrade = max(1, min(5, result.grade))
            var validatedHits = result.bulletPointsHit
            if validatedHits.count != bulletPoints.count {
                validatedHits = Array(repeating: false, count: bulletPoints.count)
            }
            result = GradingResponse(grade: clampedGrade, feedback: result.feedback, bulletPointsHit: validatedHits)
            return result
        } catch {
            throw ClaudeAPIError.decodingError("Failed to parse grading: \(error.localizedDescription)")
        }
    }

    func batchGrade(items: [(question: String, constraints: [String], bulletPoints: [String], modelParagraph: String, gradingRubric: GradingRubric?, studentAnswer: String)]) async throws -> [GradingResponse] {
        var results: [GradingResponse] = []
        for item in items {
            let result = try await gradeAnswer(
                question: item.question,
                constraints: item.constraints,
                bulletPoints: item.bulletPoints,
                modelParagraph: item.modelParagraph,
                gradingRubric: item.gradingRubric,
                studentAnswer: item.studentAnswer
            )
            results.append(result)
        }
        return results
    }
}
