import Foundation
import ComposableArchitecture

// MARK: - Entry Editor Feature
// Reducer for creating and editing journal entries

@Reducer
struct EntryEditorFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Editor mode (creating new or editing existing)
        var mode: EditorMode
        
        /// Entry title
        var title: String = ""
        
        /// Entry content/body
        var content: String = ""
        
        /// Selected mood
        var mood: Mood?
        
        /// Attached media
        var attachments: [AttachmentState] = []
        
        /// Whether currently saving
        var isSaving: Bool = false
        
        /// Error message
        var errorMessage: String?
        
        /// Whether keyboard is visible
        var isKeyboardVisible: Bool = false
        
        /// AI-generated title suggestion
        var aiSuggestedTitle: String?
        
        /// Whether AI is generating
        var isAIGenerating: Bool = false
        
        /// Child: Active input bar state
        var activeInput = ActiveInputFeature.State()
        
        /// Original entry ID (for editing)
        var originalEntryId: UUID?
        
        init(mode: EditorMode) {
            self.mode = mode
            
            switch mode {
            case .creating:
                self.title = ""
                self.content = ""
                self.mood = nil
                self.attachments = []
                self.originalEntryId = nil
                
            case .editing(let entry):
                self.title = entry.title
                self.content = entry.content
                self.mood = entry.mood
                self.attachments = entry.attachments.map { AttachmentState(attachment: $0) }
                self.originalEntryId = entry.id
            }
        }
        
        /// Whether content has been modified
        var hasContent: Bool {
            !title.isEmpty || !content.isEmpty || !attachments.isEmpty
        }
        
        /// Whether save button should be enabled
        var canSave: Bool {
            hasContent && !isSaving
        }
    }
    
    enum EditorMode: Equatable {
        case creating
        case editing(JournalEntry)
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // User interactions
        case titleChanged(String)
        case contentChanged(String)
        case moodSelected(Mood?)
        case saveTapped
        case cancelTapped
        
        // Save flow
        case saveEntry
        case saveCompleted
        case saveFailed(String)
        
        // AI actions
        case generateTitleTapped
        case titleGenerated(String)
        case generatePromptTapped
        case promptGenerated(String)
        case aiGenerationFailed(String)
        
        // Attachment actions
        case addAttachment(AttachmentState)
        case removeAttachment(AttachmentState.ID)
        
        // Keyboard
        case keyboardWillShow
        case keyboardWillHide
        
        // Child actions
        case activeInput(ActiveInputFeature.Action)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.databaseClient) var database
    @Dependency(\.dateClient) var dateClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.geminiClient) var geminiClient
    
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
                
            // MARK: User Interactions
                
            case let .titleChanged(title):
                state.title = title
                return .none
                
            case let .contentChanged(content):
                state.content = content
                return .none
                
            case let .moodSelected(mood):
                state.mood = mood
                return .none
                
            case .saveTapped:
                guard state.canSave else { return .none }
                return .send(.saveEntry)
                
            case .cancelTapped:
                return .run { _ in
                    await dismiss()
                }
                
            // MARK: Save Flow
                
            case .saveEntry:
                state.isSaving = true
                let title = state.title.isEmpty ? (state.aiSuggestedTitle ?? "Untitled") : state.title
                let content = state.content
                let mood = state.mood
                let mode = state.mode
                let originalId = state.originalEntryId
                
                return .run { send in
                    do {
                        switch mode {
                        case .creating:
                            let entry = JournalEntry(
                                title: title,
                                content: content,
                                mood: mood
                            )
                            try await database.createEntry(entry)
                            
                        case .editing:
                            if let entryId = originalId,
                               var entry = try await database.fetchEntry(entryId) {
                                entry.title = title
                                entry.content = content
                                entry.mood = mood
                                try await database.updateEntry(entry)
                            }
                        }
                        await send(.saveCompleted)
                    } catch {
                        await send(.saveFailed(error.localizedDescription))
                    }
                }
                
            case .saveCompleted:
                state.isSaving = false
                return .none
                
            case let .saveFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none
                
            // MARK: AI Actions
                
            case .generateTitleTapped:
                guard !state.content.isEmpty else { return .none }
                state.isAIGenerating = true
                let content = state.content
                
                return .run { [geminiClient] send in
                    do {
                        let prompt = "Generate a short, evocative journal entry title for the following content: \(content). Return only the title, nothing else."
                        let title = try await geminiClient.generateText(prompt)
                        await send(.titleGenerated(title.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } catch {
                        await send(.aiGenerationFailed(error.localizedDescription))
                    }
                }
                
            case let .titleGenerated(title):
                state.isAIGenerating = false
                state.aiSuggestedTitle = title
                if state.title.isEmpty {
                    state.title = title
                }
                return .none
                
            case .generatePromptTapped:
                state.isAIGenerating = true
                
                return .run { [geminiClient] send in
                    do {
                        let prompt = "Generate one creative, thought-provoking journal writing prompt. Return only the prompt text, nothing else."
                        let result = try await geminiClient.generateText(prompt)
                        await send(.promptGenerated(result.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } catch {
                        await send(.aiGenerationFailed(error.localizedDescription))
                    }
                }
                
            case let .promptGenerated(prompt):
                state.isAIGenerating = false
                if state.content.isEmpty {
                    state.content = prompt + "\n\n"
                }
                return .none
                
            case let .aiGenerationFailed(message):
                state.isAIGenerating = false
                state.errorMessage = message
                return .none
                
            // MARK: Attachment Actions
                
            case let .addAttachment(attachment):
                state.attachments.append(attachment)
                return .none
                
            case let .removeAttachment(id):
                state.attachments.removeAll { $0.id == id }
                return .none
                
            // MARK: Keyboard
                
            case .keyboardWillShow:
                state.isKeyboardVisible = true
                return .none
                
            case .keyboardWillHide:
                state.isKeyboardVisible = false
                return .none
                
            // MARK: Child Actions
                
            case .activeInput(.micTapped):
                // Handled by parent JournalFeature
                return .none
                
            case .activeInput(.cameraTapped):
                // Handled by parent JournalFeature
                return .none
                
            case .activeInput(.scanTapped):
                // Handled by parent JournalFeature
                return .none
                
            case .activeInput(.attachTapped):
                // Handled by parent JournalFeature
                return .none
                
            case .activeInput:
                return .none
            }
        }
    }
}

// MARK: - Attachment State

struct AttachmentState: Equatable, Identifiable {
    let id: UUID
    let type: AttachmentType
    let data: Data
    let thumbnailData: Data?
    let filename: String?
    
    init(
        id: UUID = UUID(),
        type: AttachmentType,
        data: Data,
        thumbnailData: Data? = nil,
        filename: String? = nil
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.thumbnailData = thumbnailData
        self.filename = filename
    }
    
    init(attachment: JournalAttachment) {
        self.id = attachment.id
        self.type = attachment.type
        self.data = attachment.data
        self.thumbnailData = attachment.thumbnailData
        self.filename = attachment.filename
    }
}
