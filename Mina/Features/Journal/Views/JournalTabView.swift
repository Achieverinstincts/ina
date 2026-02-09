import SwiftUI
import ComposableArchitecture
import VisionKit
import PhotosUI

// MARK: - Journal Tab View
// Main container view for the Journal (Home) tab with inline editing

struct JournalTabView: View {
    
    @Bindable var store: StoreOf<JournalFeature>
    @FocusState private var isEditorFocused: Bool
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    var body: some View {
        ZStack {
            // Background
            Color.minaBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (always visible)
                JournalHeaderView(
                    streak: store.streak,
                    onLogoTap: { store.send(.scrollToTopTapped) },
                    onSettingsTap: { store.send(.settingsTapped) }
                )
                
                // Content area
                contentView
            }
            
            // Camera options sheet
            if store.showingCameraOptions {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.hideCameraOptions)
                    }
                
                VStack {
                    Spacer()
                    CameraActionSheet(
                        isPresented: Binding(
                            get: { store.showingCameraOptions },
                            set: { if !$0 { store.send(.hideCameraOptions) } }
                        ),
                        onTakePhoto: { store.send(.takePhotoTapped) },
                        onScanDocument: { store.send(.scanDocumentTapped) },
                        isScannerAvailable: VNDocumentCameraViewController.isSupported
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.showingCameraOptions)
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: isEditorFocused) { _, newValue in
            store.send(.setEditorFocus(newValue))
        }
        .onChange(of: store.editorFocused) { _, newValue in
            isEditorFocused = newValue
        }
        .sheet(item: $store.scope(state: \.entryDetail, action: \.entryDetail)) { store in
            EntryEditorSheet(store: store)
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.showingCamera },
            set: { if !$0 { store.send(.cameraCancelled) } }
        )) {
            CameraPickerView(
                onCapture: { image in
                    store.send(.photoCaptured(image))
                },
                onCancel: {
                    store.send(.cameraCancelled)
                }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.showingDocumentScanner },
            set: { if !$0 { store.send(.cameraCancelled) } }
        )) {
            DocumentScannerView(
                onScan: { images in
                    store.send(.documentScanned(images))
                },
                onCancel: {
                    store.send(.cameraCancelled)
                }
            )
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: Binding(
                get: { store.showingPhotoPicker },
                set: { if !$0 { store.send(.hidePhotoPicker) } }
            ),
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotos) { _, newValue in
            if !newValue.isEmpty {
                store.send(.photosSelected(newValue))
                selectedPhotos = []
            }
        }
        .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
            SettingsView(store: settingsStore)
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if store.isEditing {
            // Inline editor mode
            inlineEditorContent
        } else if store.isLoading && store.entries.isEmpty {
            // Loading state
            LoadingView()
        } else if store.entries.isEmpty {
            // Empty state - tappable to start editing
            EmptyStateView {
                store.send(.startEditing)
            }
        } else {
            // Entry list
            EntryListView(store: store)
        }
    }
    
    // MARK: - Inline Editor Content
    
    private var inlineEditorContent: some View {
        VStack(spacing: 0) {
            // Text editor area
            ScrollView {
                VStack(spacing: 12) {
                    InlineEditorView(
                        text: Binding(
                            get: { store.editorText },
                            set: { store.send(.editorTextChanged($0)) }
                        ),
                        placeholder: store.placeholderText,
                        isFocused: $isEditorFocused
                    )
                    .frame(minHeight: 150)
                    
                    // Pending attachments preview
                    if !store.pendingAttachments.isEmpty {
                        pendingAttachmentsView
                    }
                    
                    // Loading indicator for photo picker
                    if store.isLoadingPhotos {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.minaSecondary)
                            Text("Loading photos...")
                                .font(.minaCaption)
                                .foregroundStyle(Color.minaSecondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            
            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                KeyboardAccessoryBar(
                    streak: store.streak,
                    isRecording: store.isRecording,
                    audioLevels: store.audioLevels,
                    liveTranscription: store.liveTranscription,
                    onMicTap: { store.send(.micTapped) },
                    onCameraTap: { store.send(.cameraTapped) },
                    onAttachTap: { store.send(.attachTapped) },
                    onDismissTap: { store.send(.dismissKeyboard) },
                    onConfirmRecording: { store.send(.confirmRecording) },
                    onCancelRecording: { store.send(.cancelRecording) }
                )
            }
        }
    }
    
    // MARK: - Pending Attachments View
    
    private var pendingAttachmentsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments")
                .font(.minaCaption)
                .foregroundStyle(Color.minaSecondary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.pendingAttachments, id: \.id) { captured in
                        PendingAttachmentThumbnail(
                            imageData: captured.thumbnailData ?? captured.imageData,
                            type: captured.type,
                            onRemove: {
                                store.send(.removePendingAttachment(captured.id))
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Entry List View

private struct EntryListView: View {
    
    @Bindable var store: StoreOf<JournalFeature>
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Invisible anchor for scroll-to-top
                    Color.clear
                        .frame(height: 1)
                        .id("top")
                    
                    ForEach(store.entries) { entryState in
                        EntryRowView(entry: entryState.entry)
                            .onTapGesture {
                                store.send(.entryTapped(entryState.id))
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.send(.deleteEntry(entryState.id))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    
                    // Bottom padding for floating bar
                    Color.clear
                        .frame(height: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .onChange(of: store.scrollToTopTrigger) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.minaSecondary)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    JournalTabView(
        store: Store(
            initialState: JournalFeature.State(
                entries: IdentifiedArrayOf(
                    uniqueElements: JournalEntry.samples.map { JournalEntryState(entry: $0) }
                ),
                streak: 7
            )
        ) {
            JournalFeature()
        }
    )
}

#Preview("Empty State") {
    JournalTabView(
        store: Store(
            initialState: JournalFeature.State()
        ) {
            JournalFeature()
        }
    )
}

#Preview("Editing Mode") {
    JournalTabView(
        store: Store(
            initialState: JournalFeature.State(
                streak: 5,
                isEditing: true,
                editorFocused: true
            )
        ) {
            JournalFeature()
        }
    )
}

#Preview("Recording Mode") {
    JournalTabView(
        store: Store(
            initialState: JournalFeature.State(
                streak: 5,
                isEditing: true,
                editorFocused: true,
                isRecording: true,
                audioLevels: (0..<30).map { _ in CGFloat.random(in: 0.2...1.0) }
            )
        ) {
            JournalFeature()
        }
    )
}
