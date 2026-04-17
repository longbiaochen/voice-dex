import AVFoundation
import Foundation

struct RecordedAudio: Sendable {
    let fileURL: URL
    let durationMs: Int
}

enum RecorderError: LocalizedError {
    case microphoneDenied
    case recorderInitFailed
    case recorderStartFailed
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "没有麦克风权限，无法开始录音。"
        case .recorderInitFailed:
            return "无法初始化录音器。"
        case .recorderStartFailed:
            return "录音启动失败。"
        case .noActiveRecording:
            return "当前没有录音中的会话。"
        }
    }
}

@MainActor
final class AudioRecorder {
    private let sampleRateHz: Int
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    init(sampleRateHz: Int) {
        self.sampleRateHz = sampleRateHz
    }

    func startRecording() async throws {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        guard granted else {
            throw RecorderError.microphoneDenied
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-dex-\(UUID().uuidString).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: sampleRateHz,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]

        let recorder = try AVAudioRecorder(url: tempURL, settings: settings)
        recorder.isMeteringEnabled = false
        guard recorder.prepareToRecord(), recorder.record() else {
            throw RecorderError.recorderStartFailed
        }

        self.recorder = recorder
        self.fileURL = tempURL
    }

    func stopRecording() throws -> RecordedAudio {
        guard let recorder, let fileURL else {
            throw RecorderError.noActiveRecording
        }

        recorder.stop()
        self.recorder = nil
        self.fileURL = nil

        return RecordedAudio(
            fileURL: fileURL,
            durationMs: Int((recorder.currentTime * 1000).rounded())
        )
    }
}
