import Foundation

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(String)
    case rateLimited
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Anthropic API key configured. Please add your key in Settings."
        case .invalidResponse:
            return "Invalid response from Claude API."
        case .httpError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let detail):
            return "Failed to parse API response: \(detail)"
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class ClaudeAPIService {

    static let shared = ClaudeAPIService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-5-20250929"
    private let apiVersion = "2023-06-01"
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0
    private let maxRetries = 2

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private init() {}

    func sendMessage(system: String, userMessage: String, maxTokens: Int = 4096, onProgress: (@Sendable (String) -> Void)? = nil) async throws -> String {
        guard let apiKey = KeychainHelper.shared.anthropicAPIKey else {
            log("No API key found in Keychain")
            throw ClaudeAPIError.noAPIKey
        }

        let keyPrefix = String(apiKey.prefix(10))
        let keySuffix = String(apiKey.suffix(4))
        log("API key loaded: \(keyPrefix)...\(keySuffix) (length: \(apiKey.count))")

        // Rate limiting: ensure minimum interval between requests
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minRequestInterval {
                log("Rate limiting: waiting \(minRequestInterval - elapsed)s")
                try await Task.sleep(nanoseconds: UInt64((minRequestInterval - elapsed) * 1_000_000_000))
            }
        }

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "stream": true,
            "system": system,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        log("Building streaming request — model: \(model), maxTokens: \(maxTokens)")
        log("System prompt length: \(system.count) chars, user message length: \(userMessage.count) chars")

        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: requestBody)
            log("Request body serialized: \(bodyData.count) bytes")
        } catch {
            log("JSON serialization FAILED: \(error)")
            throw ClaudeAPIError.networkError(error)
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 300
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = bodyData

        lastRequestTime = Date()
        let startTime = Date()
        log("Sending streaming request to \(baseURL)...")

        var lastError: Error?
        for attempt in 1...maxRetries {
            if attempt > 1 {
                let delay = Double(attempt) * 1.5
                log("Retry attempt \(attempt)/\(maxRetries) after \(delay)s delay...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                lastRequestTime = Date()
            }

            do {
                let result = try await performStreamingRequest(request, startTime: startTime, attempt: attempt, onProgress: onProgress)
                return result
            } catch let error as ClaudeAPIError {
                lastError = error
                // Only retry on rate limit or network errors
                switch error {
                case .rateLimited:
                    log("Rate limited, will retry...")
                    continue
                case .networkError(let underlying):
                    let nsError = underlying as NSError
                    if nsError.code == -1005 || nsError.code == -1001 {
                        log("Retryable network error, will retry...")
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            }
        }

        // All retries exhausted
        log("All \(maxRetries) attempts failed")
        if let lastError = lastError {
            throw lastError
        }
        throw ClaudeAPIError.invalidResponse
    }

    // MARK: - Streaming Implementation

    private func performStreamingRequest(_ request: URLRequest, startTime: Date, attempt: Int, onProgress: (@Sendable (String) -> Void)? = nil) async throws -> String {
        onProgress?("Connecting to AI...")

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            let nsError = error as NSError
            log("NETWORK ERROR (attempt \(attempt)) after \(String(format: "%.1f", elapsed))s")
            log("  Domain: \(nsError.domain), Code: \(nsError.code)")
            log("  Description: \(nsError.localizedDescription)")
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                log("  Underlying: \(underlyingError.domain) code \(underlyingError.code)")
            }
            throw ClaudeAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            log("Response is not HTTPURLResponse")
            throw ClaudeAPIError.invalidResponse
        }

        log("Stream connected: HTTP \(httpResponse.statusCode) (attempt \(attempt))")

        if httpResponse.statusCode == 429 {
            throw ClaudeAPIError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            var errorBody = ""
            for try await line in bytes.lines {
                errorBody += line
                if errorBody.count > 1000 { break }
            }
            log("HTTP error \(httpResponse.statusCode): \(errorBody.prefix(500))")
            throw ClaudeAPIError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse SSE stream and accumulate text deltas
        var fullText = ""
        var eventType = ""
        var lastReportedLength = 0
        let progressInterval = 500

        for try await line in bytes.lines {
            if line.hasPrefix("event: ") {
                eventType = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6))

                if eventType == "content_block_delta" {
                    if let jsonData = data.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let delta = json["delta"] as? [String: Any],
                       let text = delta["text"] as? String {
                        fullText += text

                        if fullText.count - lastReportedLength >= progressInterval {
                            lastReportedLength = fullText.count
                            let displayCount: String
                            if fullText.count >= 1000 {
                                displayCount = String(format: "%.1fK", Double(fullText.count) / 1000.0)
                            } else {
                                displayCount = "\(fullText.count)"
                            }
                            onProgress?("[detail]Receiving response... (\(displayCount) characters)")
                        }
                    }
                } else if eventType == "error" {
                    if let jsonData = data.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        log("Stream error event: \(message)")
                        throw ClaudeAPIError.httpError(statusCode: 0, message: message)
                    }
                } else if eventType == "message_start" {
                    log("Stream message_start received")
                    onProgress?("[detail]AI is generating...")
                } else if eventType == "message_stop" {
                    log("Stream message_stop received")
                }
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)
        log("Stream complete: \(fullText.count) chars in \(String(format: "%.1f", elapsed))s")

        if fullText.isEmpty {
            log("WARNING: Stream completed but no text content received")
            throw ClaudeAPIError.invalidResponse
        }

        return fullText
    }

    private func log(_ message: String) {
        print("[ClaudeAPI] \(message)")
    }
}

// MARK: - JSON Cleaning Helper

extension String {
    func cleanJSONString() -> String {
        var cleaned = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove markdown code fences if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
