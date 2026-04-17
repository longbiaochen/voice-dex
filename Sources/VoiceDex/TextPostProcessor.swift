import Foundation

enum CleanupError: LocalizedError {
    case invalidConfiguration(ConfigError)
    case missingAuthTokenEnv(String)
    case requestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let error):
            return error.localizedDescription
        case .missingAuthTokenEnv(let envName):
            return "Cleanup 已启用，但环境变量 \(envName) 没有值。"
        case .requestFailed(let message):
            return "Cleanup 请求失败：\(message)"
        case .invalidResponse:
            return "Cleanup 返回了空文本。"
        }
    }
}

struct TextPostProcessor: Sendable {
    let cleanup: CleanupConfig

    func processIfNeeded(_ text: String) async throws -> String {
        guard cleanup.enabled else {
            return text
        }

        guard !cleanup.endpoint.isEmpty else {
            throw CleanupError.invalidConfiguration(.missingEndpoint)
        }
        guard !cleanup.model.isEmpty else {
            throw CleanupError.invalidConfiguration(.missingModel)
        }

        let token = ProcessInfo.processInfo.environment[cleanup.authTokenEnv] ?? ""
        guard !token.isEmpty else {
            throw CleanupError.missingAuthTokenEnv(cleanup.authTokenEnv)
        }

        var request = URLRequest(url: URL(string: cleanup.endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(cleanup.authHeaderPrefix) \(token)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": cleanup.model,
            "temperature": 0.1,
            "messages": [
                ["role": "system", "content": cleanup.systemPrompt],
                ["role": "user", "content": text],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CleanupError.requestFailed("missing HTTP response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let providerMessage = decodeProviderMessage(from: data) ?? "status \(httpResponse.statusCode)"
            throw CleanupError.requestFailed(providerMessage)
        }

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = object["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String,
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw CleanupError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeProviderMessage(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        if let error = object["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        return object["message"] as? String
    }
}
