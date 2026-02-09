import Foundation
import Speech
import AVFoundation
import Dependencies

// MARK: - Speech Client
// TCA Dependency for speech recognition using SFSpeechRecognizer

struct SpeechClient {
    /// Request authorization for speech recognition
    var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
    
    /// Start live transcription, returns an AsyncStream of transcription results
    var startTranscription: @Sendable () async throws -> AsyncStream<TranscriptionResult>
    
    /// Stop current transcription
    var stopTranscription: @Sendable () async -> Void
    
    /// Check if speech recognition is available
    var isAvailable: @Sendable () -> Bool
    
    /// Get current audio level (0.0 - 1.0) for waveform visualization
    var audioLevel: @Sendable () async -> Float
}

// MARK: - Transcription Result

struct TranscriptionResult: Equatable, Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Float
}

// MARK: - Speech Client Errors

enum SpeechClientError: Error, LocalizedError {
    case notAuthorized
    case notAvailable
    case audioEngineError(String)
    case recognitionError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .audioEngineError(let message):
            return "Audio error: \(message)"
        case .recognitionError(let message):
            return "Recognition error: \(message)"
        }
    }
}

// MARK: - Dependency Key

extension SpeechClient: DependencyKey {
    static let liveValue = SpeechClient.live
    static let testValue = SpeechClient.mock
    static let previewValue = SpeechClient.mock
}

extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension SpeechClient {
    
    static let live: SpeechClient = {
        // Shared state for the audio engine and recognition
        let audioState = AudioState()
        
        return SpeechClient(
            requestAuthorization: {
                await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { status in
                        continuation.resume(returning: status)
                    }
                }
            },
            
            startTranscription: {
                // Check authorization
                let status = SFSpeechRecognizer.authorizationStatus()
                guard status == .authorized else {
                    throw SpeechClientError.notAuthorized
                }
                
                // Check availability
                guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
                      recognizer.isAvailable else {
                    throw SpeechClientError.notAvailable
                }
                
                return AsyncStream { continuation in
                    Task {
                        do {
                            try await audioState.startRecording(
                                recognizer: recognizer,
                                onResult: { result in
                                    continuation.yield(result)
                                },
                                onError: { error in
                                    continuation.finish()
                                },
                                onFinished: {
                                    continuation.finish()
                                }
                            )
                        } catch {
                            continuation.finish()
                        }
                    }
                    
                    continuation.onTermination = { _ in
                        Task {
                            await audioState.stopRecording()
                        }
                    }
                }
            },
            
            stopTranscription: {
                await audioState.stopRecording()
            },
            
            isAvailable: {
                guard let recognizer = SFSpeechRecognizer(locale: Locale.current) else {
                    return false
                }
                return recognizer.isAvailable
            },
            
            audioLevel: {
                await audioState.currentAudioLevel
            }
        )
    }()
}

// MARK: - Audio State (Actor for thread safety)

private actor AudioState {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var _currentAudioLevel: Float = 0
    
    var currentAudioLevel: Float {
        _currentAudioLevel
    }
    
    func startRecording(
        recognizer: SFSpeechRecognizer,
        onResult: @escaping (TranscriptionResult) -> Void,
        onError: @escaping (Error) -> Void,
        onFinished: @escaping () -> Void
    ) async throws {
        // Stop any existing recording
        await stopRecording()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create audio engine and request
        let audioEngine = AVAudioEngine()
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        self.audioEngine = audioEngine
        self.recognitionRequest = recognitionRequest
        
        // Configure request for live transcription
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Add on-device recognition if available (iOS 13+)
        if #available(iOS 13, *) {
            if recognizer.supportsOnDeviceRecognition {
                recognitionRequest.requiresOnDeviceRecognition = false // Allow cloud for better accuracy
            }
        }
        
        // Get input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            // Send audio buffer to recognition request
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for waveform
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            Task { @MainActor in
                await self?.updateAudioLevel(level)
            }
        }
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let error = error {
                onError(error)
                return
            }
            
            if let result = result {
                let transcription = TranscriptionResult(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal,
                    confidence: result.bestTranscription.segments.last?.confidence ?? 0
                )
                onResult(transcription)
                
                if result.isFinal {
                    onFinished()
                }
            }
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() async {
        // Stop and clean up
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        _currentAudioLevel = 0
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func updateAudioLevel(_ level: Float) {
        _currentAudioLevel = level
    }
    
    private nonisolated func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        
        let frameCount = Int(buffer.frameLength)
        var sum: Float = 0
        
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameCount)
        // Normalize to 0-1 range with some amplification
        let normalized = min(1.0, average * 10)
        return normalized
    }
}

// MARK: - Mock Implementation

extension SpeechClient {
    static let mock = SpeechClient(
        requestAuthorization: {
            return .authorized
        },
        startTranscription: {
            AsyncStream { continuation in
                // Simulate transcription with delays
                Task {
                    let phrases = [
                        "Hello",
                        "Hello, this is",
                        "Hello, this is a test",
                        "Hello, this is a test of speech",
                        "Hello, this is a test of speech recognition"
                    ]
                    
                    for (index, phrase) in phrases.enumerated() {
                        try? await Task.sleep(for: .milliseconds(500))
                        let isFinal = index == phrases.count - 1
                        continuation.yield(TranscriptionResult(
                            text: phrase,
                            isFinal: isFinal,
                            confidence: 0.95
                        ))
                    }
                    continuation.finish()
                }
            }
        },
        stopTranscription: {},
        isAvailable: { true },
        audioLevel: { Float.random(in: 0.2...0.8) }
    )
}
