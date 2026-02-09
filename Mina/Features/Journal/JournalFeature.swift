import Foundation
import SwiftUI
import ComposableArchitecture
import SwiftData
import Speech
import UIKit
import PhotosUI

// MARK: - Journal Feature
// Parent reducer for the Journal (Home) tab with inline editing

@Reducer
struct JournalFeature {
    
    // MARK: - Cancel IDs
    
    enum CancelID: Hashable {
        case recording
        case transcription
    }
    
    // MARK: - Speech Authorization Status
    
    enum SpeechAuthorizationStatus: Equatable {
        case notDetermined
        case denied
        case restricted
        case authorized
        
        init(from status: SFSpeechRecognizerAuthorizationStatus) {
            switch status {
            case .notDetermined: self = .notDetermined
            case .denied: self = .denied
            case .restricted: self = .restricted
            case .authorized: self = .authorized
            @unknown default: self = .notDetermined
            }
        }
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Today's journal entries
        var entries: IdentifiedArrayOf<JournalEntryState> = []
        
        /// Current streak count
        var streak: Int = 0
        
        /// Loading state
        var isLoading: Bool = false
        
        /// Error message if any
        var errorMessage: String?
        
        /// Scroll to top trigger
        var scrollToTopTrigger: Int = 0
        
        /// Inline editing state
        var isEditing: Bool = false
        var editorText: String = ""
        var editorFocused: Bool = false
        
        /// Entry being edited (nil = new entry)
        var editingEntryId: UUID? = nil
        
        /// Voice recording state
        var isRecording: Bool = false
        var recordingDuration: TimeInterval = 0
        var audioLevels: [CGFloat] = [] // For waveform visualization
        var liveTranscription: String = "" // Live transcription text
        var speechAuthorizationStatus: SpeechAuthorizationStatus = .notDetermined
        
        /// Camera state
        var showingCameraOptions: Bool = false
        var showingCamera: Bool = false
        var showingDocumentScanner: Bool = false
        var cameraAuthorizationStatus: CameraAuthorizationStatus = .notDetermined
        var pendingAttachments: [CapturedImage] = [] // Photos/scans to attach to current entry
        
        /// Photo picker state
        var showingPhotoPicker: Bool = false
        var isLoadingPhotos: Bool = false
        
        /// Child: Active input bar state
        var activeInput = ActiveInputFeature.State()
        
        /// Child: Entry detail (for viewing/editing existing from list)
        @Presents var entryDetail: EntryEditorFeature.State?
        
        /// Child: Settings
        @Presents var settings: SettingsFeature.State?
        
        /// Whether the user is actively typing
        var isTyping: Bool {
            isEditing && editorFocused
        }
        
        /// Placeholder text
        var placeholderText: String {
            "Start writing your thoughts..."
        }
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // Lifecycle
        case onAppear
        case onDisappear
        
        // Data loading
        case loadEntries
        case entriesLoaded([JournalEntry])
        case loadStreak
        case streakLoaded(Int)
        case loadFailed(String)
        
        // User interactions
        case entryTapped(JournalEntryState.ID)
        case deleteEntry(JournalEntryState.ID)
        case entryDeleted
        case scrollToTopTapped
        case settingsTapped
        
        // Inline editing
        case startEditing
        case cancelEditing
        case saveEntry
        case entrySaved
        case editorTextChanged(String)
        case setEditorFocus(Bool)
        
        // Keyboard accessory actions
        case micTapped
        case cameraTapped
        case attachTapped
        case dismissKeyboard
        
        // Voice recording actions
        case startRecording
        case stopRecording
        case cancelRecording
        case confirmRecording
        case recordingTick
        case audioLevelUpdated(CGFloat)
        case transcriptionReceived(String)
        case liveTranscriptionUpdated(String, isFinal: Bool)
        case speechAuthorizationResponse(SpeechAuthorizationStatus)
        case speechError(String)
        
        // Camera actions
        case showCameraOptions
        case hideCameraOptions
        case takePhotoTapped
        case scanDocumentTapped
        case cameraAuthorizationResponse(CameraAuthorizationStatus)
        case photoCaptured(UIImage)
        case documentScanned([UIImage])
        case cameraCancelled
        case cameraError(String)
        case removePendingAttachment(UUID)
        
        // Photo picker actions
        case showPhotoPicker
        case hidePhotoPicker
        case photosSelected([PhotosPickerItem])
        case photosLoaded([PickedImage])
        case photoLoadError(String)
        
        // Child actions
        case entryDetail(PresentationAction<EntryEditorFeature.Action>)
        case activeInput(ActiveInputFeature.Action)
        case settings(PresentationAction<SettingsFeature.Action>)
        
        // Legacy (for compatibility)
        case newEntryTapped
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.databaseClient) var database
    @Dependency(\.dateClient) var dateClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.speechClient) var speechClient
    @Dependency(\.cameraClient) var cameraClient
    @Dependency(\.photoPickerClient) var photoPickerClient
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.activeInput, action: \.activeInput) {
            ActiveInputFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            // MARK: Lifecycle
                
            case .onAppear:
                return .merge(
                    .send(.loadEntries),
                    .send(.loadStreak)
                )
                
            case .onDisappear:
                return .none
                
            // MARK: Data Loading
                
            case .loadEntries:
                state.isLoading = true
                return .run { send in
                    do {
                        let entries = try await database.fetchTodayEntries()
                        await send(.entriesLoaded(entries))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case let .entriesLoaded(entries):
                state.isLoading = false
                state.entries = IdentifiedArrayOf(
                    uniqueElements: entries.map { JournalEntryState(entry: $0) }
                )
                return .none
                
            case .loadStreak:
                return .run { send in
                    do {
                        let streak = try await database.calculateStreak()
                        await send(.streakLoaded(streak))
                    } catch {
                        await send(.streakLoaded(0))
                    }
                }
                
            case let .streakLoaded(streak):
                state.streak = streak
                return .none
                
            case let .loadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            // MARK: User Interactions
                
            case let .entryTapped(id):
                guard let entryState = state.entries[id: id] else {
                    return .none
                }
                state.entryDetail = EntryEditorFeature.State(
                    mode: .editing(entryState.entry)
                )
                return .none
                
            case let .deleteEntry(id):
                guard let entryState = state.entries[id: id] else {
                    return .none
                }
                let entryId = entryState.entry.id
                return .run { send in
                    try await database.deleteEntry(entryId)
                    await send(.entryDeleted)
                }
                
            case .entryDeleted:
                return .send(.loadEntries)
                
            case .scrollToTopTapped:
                state.scrollToTopTrigger += 1
                return .none
                
            case .settingsTapped:
                state.settings = SettingsFeature.State()
                return .none
                
            // MARK: Inline Editing
                
            case .startEditing, .newEntryTapped:
                state.isEditing = true
                state.editorText = ""
                state.editingEntryId = nil
                state.editorFocused = true
                return .none
                
            case .cancelEditing:
                state.isEditing = false
                state.editorText = ""
                state.editingEntryId = nil
                state.editorFocused = false
                state.pendingAttachments = []
                return .none
                
            case .saveEntry:
                let content = state.editorText.trimmingCharacters(in: .whitespacesAndNewlines)
                let pendingImages = state.pendingAttachments
                
                guard !content.isEmpty || !pendingImages.isEmpty else {
                    // Empty entry with no attachments, just cancel
                    return .send(.cancelEditing)
                }
                
                let entryId = state.editingEntryId
                
                return .run { send in
                    do {
                        if let existingId = entryId {
                            // Update existing entry
                            try await database.updateEntryContent(existingId, content)
                            // TODO: Add attachments to existing entry
                        } else {
                            // Create attachments from pending images
                            var attachments: [JournalAttachment] = []
                            for captured in pendingImages {
                                let attachment = JournalAttachment(
                                    type: captured.type == .photo ? .image : .scan,
                                    data: captured.imageData,
                                    thumbnailData: captured.thumbnailData,
                                    mimeType: "image/jpeg"
                                )
                                attachments.append(attachment)
                            }
                            
                            // Create new entry with attachments
                            let entry = JournalEntry(
                                title: "",
                                content: content,
                                attachments: attachments
                            )
                            try await database.saveEntry(entry)
                        }
                        await send(.entrySaved)
                    } catch {
                        // Handle error
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .entrySaved:
                state.isEditing = false
                state.editorText = ""
                state.editingEntryId = nil
                state.editorFocused = false
                state.pendingAttachments = []
                return .merge(
                    .send(.loadEntries),
                    .send(.loadStreak)
                )
                
            case let .editorTextChanged(text):
                state.editorText = text
                return .none
                
            case let .setEditorFocus(focused):
                state.editorFocused = focused
                if !focused && state.editorText.isEmpty {
                    // Lost focus with empty text, cancel editing
                    state.isEditing = false
                }
                return .none
                
            // MARK: Keyboard Accessory Actions
                
            case .micTapped:
                // Start voice recording
                return .send(.startRecording)
                
            case .cameraTapped:
                // Show camera options (photo vs scan)
                return .send(.showCameraOptions)
                
            case .attachTapped:
                // Show photo picker
                return .send(.showPhotoPicker)
                
            case .dismissKeyboard:
                // Save if there's content, otherwise cancel
                if state.editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return .send(.cancelEditing)
                } else {
                    return .send(.saveEntry)
                }
                
            // MARK: Voice Recording
                
            case .startRecording:
                state.isRecording = true
                state.recordingDuration = 0
                state.audioLevels = []
                state.liveTranscription = ""
                
                // Generate initial random levels for visual effect
                for _ in 0..<30 {
                    state.audioLevels.append(CGFloat.random(in: 0.1...0.3))
                }
                
                return .run { send in
                    // Request authorization first
                    let status = await speechClient.requestAuthorization()
                    await send(.speechAuthorizationResponse(SpeechAuthorizationStatus(from: status)))
                }
                
            case let .speechAuthorizationResponse(status):
                state.speechAuthorizationStatus = status
                
                guard status == .authorized else {
                    state.isRecording = false
                    state.errorMessage = "Speech recognition not authorized. Please enable in Settings."
                    return .none
                }
                
                // Start actual transcription
                return .merge(
                    // Timer for duration and waveform
                    .run { send in
                        for await _ in self.clock.timer(interval: .milliseconds(100)) {
                            await send(.recordingTick)
                            // Get real audio level from speech client
                            let level = CGFloat(speechClient.audioLevel())
                            await send(.audioLevelUpdated(level))
                        }
                    }
                    .cancellable(id: CancelID.recording, cancelInFlight: true),
                    
                    // Live transcription stream
                    .run { send in
                        do {
                            let stream = try await speechClient.startTranscription()
                            for await result in stream {
                                await send(.liveTranscriptionUpdated(result.text, isFinal: result.isFinal))
                            }
                        } catch {
                            await send(.speechError(error.localizedDescription))
                        }
                    }
                    .cancellable(id: CancelID.transcription, cancelInFlight: true)
                )
                
            case .stopRecording:
                state.isRecording = false
                return .merge(
                    .cancel(id: CancelID.recording),
                    .cancel(id: CancelID.transcription),
                    .run { _ in
                        await speechClient.stopTranscription()
                    }
                )
                
            case .cancelRecording:
                state.isRecording = false
                state.recordingDuration = 0
                state.audioLevels = []
                state.liveTranscription = ""
                return .merge(
                    .cancel(id: CancelID.recording),
                    .cancel(id: CancelID.transcription),
                    .run { _ in
                        await speechClient.stopTranscription()
                    }
                )
                
            case .confirmRecording:
                // Stop recording and insert transcription
                let transcribedText = state.liveTranscription
                state.isRecording = false
                state.recordingDuration = 0
                state.audioLevels = []
                state.liveTranscription = ""
                
                // Insert transcribed text into editor
                if !transcribedText.isEmpty {
                    if state.editorText.isEmpty {
                        state.editorText = transcribedText
                    } else {
                        state.editorText += " " + transcribedText
                    }
                }
                
                return .merge(
                    .cancel(id: CancelID.recording),
                    .cancel(id: CancelID.transcription),
                    .run { _ in
                        await speechClient.stopTranscription()
                    }
                )
                
            case .recordingTick:
                state.recordingDuration += 0.1
                return .none
                
            case let .audioLevelUpdated(level):
                // Shift levels and add new one for waveform animation
                if state.audioLevels.count >= 30 {
                    state.audioLevels.removeFirst()
                }
                state.audioLevels.append(level)
                return .none
                
            case let .liveTranscriptionUpdated(text, isFinal):
                state.liveTranscription = text
                // If final, we could auto-confirm or just wait for user
                return .none
                
            case let .speechError(error):
                state.isRecording = false
                state.errorMessage = error
                return .merge(
                    .cancel(id: CancelID.recording),
                    .cancel(id: CancelID.transcription)
                )
                
            case let .transcriptionReceived(text):
                // Legacy - kept for compatibility
                if state.editorText.isEmpty {
                    state.editorText = text
                } else {
                    state.editorText += " " + text
                }
                return .none
                
            // MARK: Camera Actions
                
            case .showCameraOptions:
                state.showingCameraOptions = true
                return .none
                
            case .hideCameraOptions:
                state.showingCameraOptions = false
                return .none
                
            case .takePhotoTapped:
                state.showingCameraOptions = false
                // Check authorization first
                let status = cameraClient.authorizationStatus()
                if status == .authorized {
                    state.showingCamera = true
                    return .none
                } else if status == .notDetermined {
                    return .run { send in
                        let newStatus = await cameraClient.requestAuthorization()
                        await send(.cameraAuthorizationResponse(newStatus))
                    }
                } else {
                    state.errorMessage = "Camera access denied. Please enable in Settings."
                    return .none
                }
                
            case .scanDocumentTapped:
                state.showingCameraOptions = false
                guard cameraClient.isDocumentScannerAvailable() else {
                    state.errorMessage = "Document scanner is not available on this device."
                    return .none
                }
                // Check authorization first
                let status = cameraClient.authorizationStatus()
                if status == .authorized {
                    state.showingDocumentScanner = true
                    return .none
                } else if status == .notDetermined {
                    return .run { send in
                        let newStatus = await cameraClient.requestAuthorization()
                        await send(.cameraAuthorizationResponse(newStatus))
                    }
                } else {
                    state.errorMessage = "Camera access denied. Please enable in Settings."
                    return .none
                }
                
            case let .cameraAuthorizationResponse(status):
                state.cameraAuthorizationStatus = status
                if status == .authorized {
                    // Authorized, open camera (default to photo)
                    state.showingCamera = true
                } else {
                    state.errorMessage = "Camera access denied. Please enable in Settings."
                }
                return .none
                
            case let .photoCaptured(image):
                state.showingCamera = false
                // Create captured image and add to pending attachments
                if let captured = ImageUtilities.createCapturedImage(from: image, type: .photo) {
                    state.pendingAttachments.append(captured)
                }
                return .none
                
            case let .documentScanned(images):
                state.showingDocumentScanner = false
                // Create captured images for each scanned page
                for image in images {
                    if let captured = ImageUtilities.createCapturedImage(from: image, type: .scan) {
                        state.pendingAttachments.append(captured)
                    }
                }
                return .none
                
            case .cameraCancelled:
                state.showingCamera = false
                state.showingDocumentScanner = false
                return .none
                
            case let .cameraError(error):
                state.showingCamera = false
                state.showingDocumentScanner = false
                state.errorMessage = error
                return .none
                
            case let .removePendingAttachment(id):
                state.pendingAttachments.removeAll { $0.id == id }
                return .none
                
            // MARK: Photo Picker Actions
                
            case .showPhotoPicker:
                state.showingPhotoPicker = true
                return .none
                
            case .hidePhotoPicker:
                state.showingPhotoPicker = false
                return .none
                
            case let .photosSelected(items):
                state.showingPhotoPicker = false
                guard !items.isEmpty else { return .none }
                
                state.isLoadingPhotos = true
                return .run { send in
                    do {
                        let images = try await photoPickerClient.loadImages(items)
                        await send(.photosLoaded(images))
                    } catch {
                        await send(.photoLoadError(error.localizedDescription))
                    }
                }
                
            case let .photosLoaded(images):
                state.isLoadingPhotos = false
                // Convert PickedImages to CapturedImages and add to pending
                for image in images {
                    state.pendingAttachments.append(image.asCapturedImage)
                }
                return .none
                
            case let .photoLoadError(error):
                state.isLoadingPhotos = false
                state.errorMessage = error
                return .none
                
            // MARK: Child Actions
                
            case .entryDetail(.presented(.saveCompleted)):
                state.entryDetail = nil
                return .send(.loadEntries)
                
            case .entryDetail(.presented(.cancelTapped)):
                state.entryDetail = nil
                return .none
                
            case .entryDetail:
                return .none
                
            case .activeInput(.startNewEntry):
                return .send(.startEditing)
                
            case .activeInput:
                return .none
                
            case .settings(.presented(.dismissSettings)):
                state.settings = nil
                return .none
                
            case .settings:
                return .none
            }
        }
        .ifLet(\.$entryDetail, action: \.entryDetail) {
            EntryEditorFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
    }
}

// MARK: - Journal Entry State
// Wrapper for displaying entries in the list

struct JournalEntryState: Equatable, Identifiable {
    let id: UUID
    let entry: JournalEntry
    
    init(entry: JournalEntry) {
        self.id = entry.id
        self.entry = entry
    }
    
    static func == (lhs: JournalEntryState, rhs: JournalEntryState) -> Bool {
        lhs.id == rhs.id &&
        lhs.entry.title == rhs.entry.title &&
        lhs.entry.content == rhs.entry.content &&
        lhs.entry.updatedAt == rhs.entry.updatedAt
    }
}
