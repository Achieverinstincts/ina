import SwiftUI
import UIKit
import ComposableArchitecture

// MARK: - Inbox Item Detail View
// Detail view for processing an inbox item

struct InboxItemDetailView: View {
    
    @Bindable var store: StoreOf<InboxItemDetailFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Type header
                        typeHeader
                        
                        // Content preview
                        contentPreview
                        
                        // Transcription (if available)
                        if let transcription = store.item.transcription {
                            transcriptionSection(transcription)
                        }
                        
                        // Actions
                        actionButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(store.item.type.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        store.send(.dismiss)
                    }
                    .foregroundStyle(Color.minaSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            store.send(.delete)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            store.send(.archive)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Type Header
    
    private var typeHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 56, height: 56)
                
                Image(systemName: store.item.type.systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.item.type.label)
                    .font(.minaTitle3)
                    .foregroundStyle(Color.minaPrimary)
                
                Text(formattedDateTime)
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            Spacer()
            
            // Status badge
            Text(store.item.statusLabel)
                .font(.minaCaption1)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var iconBackgroundColor: Color {
        switch store.item.type {
        case .voiceNote: return Color.purple.opacity(0.1)
        case .photo: return Color.blue.opacity(0.1)
        case .scan: return Color.orange.opacity(0.1)
        case .file: return Color.gray.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        switch store.item.type {
        case .voiceNote: return Color.purple
        case .photo: return Color.blue
        case .scan: return Color.orange
        case .file: return Color.gray
        }
    }
    
    private var statusColor: Color {
        if store.item.isProcessed {
            return Color.minaSuccess
        } else if store.item.transcription != nil {
            return Color.minaAccent
        } else {
            return Color.minaSecondary
        }
    }
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: store.item.createdAt)
    }
    
    // MARK: - Content Preview
    
    private var contentPreview: some View {
        Group {
            switch store.item.type {
            case .voiceNote:
                voiceNotePreview
            case .photo:
                photoPreview
            case .scan:
                scanPreview
            case .file:
                filePreview
            }
        }
    }
    
    private var voiceNotePreview: some View {
        VStack(spacing: 16) {
            // Waveform placeholder
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.purple.opacity(0.4))
                        .frame(width: 4, height: CGFloat.random(in: 10...40))
                }
            }
            .frame(height: 50)
            
            // Playback controls
            HStack(spacing: 20) {
                Text("0:00")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.minaSecondary.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: geo.size.width * store.playbackProgress, height: 4)
                    }
                }
                .frame(height: 4)
                
                Text("1:24")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            // Play button
            Button {
                store.send(.togglePlayback)
            } label: {
                Image(systemName: store.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.purple)
            }
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var photoPreview: some View {
        ZStack {
            Color.blue.opacity(0.1)
            
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.blue.opacity(0.5))
                
                Text("Photo Preview")
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var scanPreview: some View {
        ZStack {
            Color.orange.opacity(0.1)
            
            VStack(spacing: 12) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.orange.opacity(0.5))
                
                Text("Scanned Document")
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var filePreview: some View {
        ZStack {
            Color.gray.opacity(0.1)
            
            VStack(spacing: 12) {
                Image(systemName: "doc")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.gray.opacity(0.5))
                
                Text("File Attachment")
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Transcription Section
    
    private func transcriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.minaSecondary)
                
                Text("Transcription")
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaPrimary)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            
            Text(text)
                .font(.minaBody)
                .foregroundStyle(Color.minaPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.minaBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !store.item.isProcessed {
                // Convert to entry button
                Button {
                    store.send(.convertToEntry)
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Add to Journal")
                    }
                    .font(.minaHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.minaAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // View entry button
                Button {
                    // Cross-tab navigation not available; dismiss detail view for now
                    store.send(.dismiss)
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("View Journal Entry")
                    }
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.minaAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Archive button
            Button {
                store.send(.archive)
            } label: {
                HStack {
                    Image(systemName: "archivebox")
                    Text("Archive")
                }
                .font(.minaHeadline)
                .foregroundStyle(Color.minaSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.minaCardSolid)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.minaDivider, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let item = InboxFeature.InboxItemState(
        id: UUID(),
        type: .voiceNote,
        transcription: "This is a sample transcription of a voice note. It contains some thoughts about the day and ideas for future projects.",
        previewText: nil,
        createdAt: Date(),
        isProcessed: false,
        isArchived: false
    )
    
    return InboxItemDetailView(
        store: Store(initialState: InboxItemDetailFeature.State(item: item)) {
            InboxItemDetailFeature()
        }
    )
}
