import Foundation
import AVFoundation
#if canImport(WhisperKit)
import WhisperKit
#endif

enum TranscriptionState {
    case notDownloaded
    case downloading(progress: Double)
    case ready
    case error(String)
}

enum TranscriptionError: LocalizedError {
    case modelNotReady
    case microphonePermissionDenied
    case recordingFailed(String)
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotReady:
            return "Whisper model is not ready. Please download it in Settings."
        case .microphonePermissionDenied:
            return "Microphone access is required to record answers. Please enable it in Settings."
        case .recordingFailed(let detail):
            return "Recording failed: \(detail)"
        case .transcriptionFailed(let detail):
            return "Transcription failed: \(detail)"
        }
    }
}

class TranscriptionService {

    static let shared = TranscriptionService()

    private(set) var state: TranscriptionState = .notDownloaded

    private var audioEngine: AVAudioEngine?
    private var audioData: [Float] = []
    private var isRecording = false

    #if canImport(WhisperKit)
    private var whisperKit: WhisperKit?
    #endif

    private static let modelName = "openai_whisper-base.en"

    /// Persistent directory in Application Support for storing downloaded models
    private static var modelDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("WhisperKitModels")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Check if model files are already cached on disk
    var isModelCached: Bool {
        let modelPath = Self.modelDirectory.appendingPathComponent(Self.modelName)
        return FileManager.default.fileExists(atPath: modelPath.path)
    }

    private init() {
        // Check if model was previously downloaded to persistent storage
        if isModelCached {
            // Model files exist on disk but not loaded into memory yet
            // State stays .notDownloaded to indicate it needs prepareModel(),
            // but prepareModel() will load from local files (fast) instead of downloading (slow)
        }
    }

    // MARK: - Model Management

    func prepareModel() async throws {
        #if canImport(WhisperKit)
        if isModelReady { return }

        state = .downloading(progress: 0.5)
        do {
            let modelFolder = Self.modelDirectory.path
            let kit = try await WhisperKit(
                WhisperKitConfig(
                    model: Self.modelName,
                    modelFolder: modelFolder
                )
            )
            self.whisperKit = kit
            state = .ready
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
        #else
        state = .error("WhisperKit not available")
        throw TranscriptionError.modelNotReady
        #endif
    }

    var isModelReady: Bool {
        if case .ready = state { return true }
        return false
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            return false
        }

        return await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        guard !isRecording else { return }

        audioData = []
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let targetSampleRate: Double = 16000
        let ratio = inputFormat.sampleRate / targetSampleRate

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            let channelData = buffer.floatChannelData?[0]
            let frameCount = Int(buffer.frameLength)

            // Downsample to 16kHz mono
            var samples = [Float]()
            if ratio > 1.0 {
                var index: Double = 0
                while Int(index) < frameCount {
                    samples.append(channelData?[Int(index)] ?? 0)
                    index += ratio
                }
            } else {
                for i in 0..<frameCount {
                    samples.append(channelData?[i] ?? 0)
                }
            }
            self.audioData.append(contentsOf: samples)
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
        isRecording = true
    }

    func stopRecordingAndTranscribe() async throws -> String {
        guard isRecording, let engine = audioEngine else {
            throw TranscriptionError.recordingFailed("Not currently recording")
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        audioEngine = nil

        guard !audioData.isEmpty else {
            throw TranscriptionError.recordingFailed("No audio captured")
        }

        #if canImport(WhisperKit)
        guard let kit = whisperKit else {
            throw TranscriptionError.modelNotReady
        }

        do {
            let results = try await kit.transcribe(audioArray: audioData)
            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                throw TranscriptionError.transcriptionFailed("No speech detected")
            }
            return text
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }
        #else
        throw TranscriptionError.modelNotReady
        #endif
    }

    func cancelRecording() {
        guard isRecording, let engine = audioEngine else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        audioEngine = nil
        audioData = []
    }
}
