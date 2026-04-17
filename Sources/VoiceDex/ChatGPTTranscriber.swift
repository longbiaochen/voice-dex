import Foundation

enum TranscriptionError: LocalizedError {
    case invalidAudio
    case payloadTooLarge
    case transcriptionFailed(String)
    case invalidResponse
    case missingAuthTokenEnv(String)

    var errorDescription: String? {
        switch self {
        case .invalidAudio:
            return "录音文件无效。"
        case .payloadTooLarge:
            return "录音文件超过 10 MB，当前实现不发送。"
        case .transcriptionFailed(let message):
            return "ChatGPT 转写失败：\(message)"
        case .invalidResponse:
            return "ChatGPT 转写返回了空文本。"
        case .missingAuthTokenEnv(let envName):
            return "缺少转写 API key，请设置环境变量 \(envName)。"
        }
    }
}

struct ChatGPTTranscriber: Sendable {
    let authClient: CodexAuthClient
    let config: TranscriptionConfig

    func transcribe(_ audio: RecordedAudio) async throws -> String {
        let data = try Data(contentsOf: audio.fileURL)
        guard !data.isEmpty else {
            throw TranscriptionError.invalidAudio
        }
        guard data.count <= 10 * 1024 * 1024 else {
            throw TranscriptionError.payloadTooLarge
        }

        switch config.provider {
        case .codexChatGPTBridge:
            let authStatus = try authClient.fetchAuthStatus(includeToken: true, refreshToken: true)
            guard let token = authStatus.authToken else {
                throw CodexAuthError.missingToken
            }
            return try await transcribeViaChatGPTBridge(audioData: data, token: token)
        case .openAICompatible:
            return try await transcribeViaOpenAICompatible(audioData: data)
        }
    }

    private func transcribeViaChatGPTBridge(audioData: Data, token: String) async throws -> String {
        var request = URLRequest(url: URL(string: config.chatGPTURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(makeBoundary())", forHTTPHeaderField: "Content-Type")
        let boundary = request.value(forHTTPHeaderField: "Content-Type")!.split(separator: "=").last.map(String.init) ?? makeBoundary()
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            audioData: audioData,
            extraFields: [:]
        )

        return try await executeTranscriptionRequest(request, providerLabel: "ChatGPT")
    }

    private func transcribeViaOpenAICompatible(audioData: Data) async throws -> String {
        let token = ProcessInfo.processInfo.environment[config.openAIAuthTokenEnv] ?? ""
        guard !token.isEmpty else {
            throw TranscriptionError.missingAuthTokenEnv(config.openAIAuthTokenEnv)
        }

        let boundary = makeBoundary()
        var request = URLRequest(url: URL(string: config.openAITranscriptionURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            audioData: audioData,
            extraFields: [
                "model": config.openAIModel,
            ]
        )

        return try await executeTranscriptionRequest(request, providerLabel: "OpenAI-compatible")
    }

    private func executeTranscriptionRequest(_ request: URLRequest, providerLabel: String) async throws -> String {
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.transcriptionFailed("\(providerLabel) missing HTTP response")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let providerMessage = decodeProviderMessage(from: responseData) ?? "status \(httpResponse.statusCode)"
            throw TranscriptionError.transcriptionFailed(providerMessage)
        }

        let object = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        if let text = object?["text"] as? String, !text.isEmpty {
            return text
        }
        if let text = object?["transcript"] as? String, !text.isEmpty {
            return text
        }

        throw TranscriptionError.invalidResponse
    }

    private func makeBoundary() -> String {
        "VoiceDex-\(UUID().uuidString)"
    }

    private func makeMultipartBody(boundary: String, audioData: Data, extraFields: [String: String]) -> Data {
        var body = Data()
        for (name, value) in extraFields.sorted(by: { $0.key < $1.key }) {
            body.append(contentsOf: "--\(boundary)\r\n".utf8)
            body.append(contentsOf: "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8)
            body.append(contentsOf: "\(value)\r\n".utf8)
        }
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"voice.wav\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: audio/wav\r\n\r\n".utf8)
        body.append(audioData)
        body.append(contentsOf: "\r\n--\(boundary)--\r\n".utf8)
        return body
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
