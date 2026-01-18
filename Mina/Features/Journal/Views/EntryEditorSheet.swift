import SwiftUI
import ComposableArchitecture

// MARK: - Entry Editor Sheet
// Full-screen sheet for creating/editing journal entries

struct EntryEditorSheet: View {
    
    @Bindable var store: StoreOf<EntryEditorFeature>
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.minaBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title field
                    TitleFieldView(
                        title: $store.title,
                        placeholder: store.aiSuggestedTitle ?? "Title"
                    )
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Content editor
                    ContentEditorView(
                        content: $store.content,
                        isFocused: $isContentFocused
                    )
                    
                    // Attachments preview
                    if !store.attachments.isEmpty {
                        AttachmentsPreviewView(
                            attachments: store.attachments,
                            onRemove: { id in
                                store.send(.removeAttachment(id))
                            }
                        )
                    }
                    
                    // Mood selector
                    MoodSelectorView(
                        selectedMood: store.mood,
                        onSelect: { mood in
                            store.send(.moodSelected(mood))
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelTapped)
                    }
                    .foregroundStyle(Color.minaSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.saveTapped)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(store.canSave ? Color.minaAccent : Color.minaSecondary)
                    .disabled(!store.canSave)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    ActiveInputBar(store: store.scope(state: \.activeInput, action: \.activeInput))
                }
            }
        }
        .interactiveDismissDisabled(store.hasContent)
        .onAppear {
            // Auto-focus content field for new entries
            if case .creating = store.mode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isContentFocused = true
                }
            }
        }
    }
}

// MARK: - Title Field View

private struct TitleFieldView: View {
    
    @Binding var title: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $title)
            .font(.minaTitle3)
            .foregroundStyle(Color.minaPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

// MARK: - Content Editor View

private struct ContentEditorView: View {
    
    @Binding var content: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if content.isEmpty {
                Text("What's on your mind?")
                    .font(.minaBody)
                    .foregroundStyle(Color.minaTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
            
            // Text editor
            TextEditor(text: $content)
                .font(.minaBody)
                .foregroundStyle(Color.minaPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .focused(isFocused)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Attachments Preview View

private struct AttachmentsPreviewView: View {
    
    let attachments: [AttachmentState]
    let onRemove: (AttachmentState.ID) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(attachments) { attachment in
                    AttachmentThumbnail(
                        attachment: attachment,
                        onRemove: { onRemove(attachment.id) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.minaBackground)
    }
}

// MARK: - Attachment Thumbnail

private struct AttachmentThumbnail: View {
    
    let attachment: AttachmentState
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.minaCardBackground)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: attachment.type.systemImage)
                        .font(.title2)
                        .foregroundStyle(Color.minaSecondary)
                )
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white, Color.minaSecondary)
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Mood Selector View

private struct MoodSelectorView: View {
    
    let selectedMood: Mood?
    let onSelect: (Mood?) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("How are you feeling?")
                .font(.minaCaption1)
                .foregroundStyle(Color.minaSecondary)
            
            HStack(spacing: 16) {
                ForEach(Mood.allCases) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        onTap: {
                            onSelect(selectedMood == mood ? nil : mood)
                        }
                    )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.minaCardBackground)
    }
}

// MARK: - Mood Button

private struct MoodButton: View {
    
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title2)
                
                Text(mood.label)
                    .font(.minaCaption2)
                    .foregroundStyle(isSelected ? Color.minaPrimary : Color.minaSecondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.minaAccent.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.minaAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("New Entry") {
    EntryEditorSheet(
        store: Store(
            initialState: EntryEditorFeature.State(mode: .creating)
        ) {
            EntryEditorFeature()
        }
    )
}

#Preview("Editing") {
    EntryEditorSheet(
        store: Store(
            initialState: EntryEditorFeature.State(
                mode: .editing(JournalEntry.sample)
            )
        ) {
            EntryEditorFeature()
        }
    )
}
