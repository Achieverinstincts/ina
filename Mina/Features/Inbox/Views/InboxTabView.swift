import SwiftUI
import ComposableArchitecture

// MARK: - Inbox Tab View
// Main inbox view showing unprocessed quick captures

struct InboxTabView: View {
    
    @Bindable var store: StoreOf<InboxFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                if store.isLoading && store.items.isEmpty {
                    loadingView
                } else if store.filteredItems.isEmpty {
                    emptyStateView
                } else {
                    inboxContent
                }
                
                // Floating record button
                VStack {
                    Spacer()
                    
                    if store.isRecording {
                        recordingIndicator
                    } else {
                        captureButton
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if store.unprocessedCount > 0 {
                        Text("\(store.unprocessedCount)")
                            .font(.minaCaption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.minaAccent)
                            .clipShape(Capsule())
                    }
                }
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
            .sheet(
                item: $store.scope(state: \.selectedItem, action: \.selectedItem)
            ) { detailStore in
                InboxItemDetailView(store: detailStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Quick Capture",
                isPresented: $store.isShowingCaptureOptions,
                titleVisibility: .visible
            ) {
                Button {
                    store.send(.startVoiceRecording)
                } label: {
                    Label("Voice Note", systemImage: "waveform")
                }
                
                Button {
                    store.send(.capturePhoto)
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                
                Button {
                    store.send(.scanDocument)
                } label: {
                    Label("Scan Document", systemImage: "doc.text.viewfinder")
                }
                
                Button("Cancel", role: .cancel) {
                    store.send(.hideCaptureOptions)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading inbox...")
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 56))
                .foregroundStyle(Color.minaSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.minaTitle3)
                    .foregroundStyle(Color.minaPrimary)
                
                Text(emptyStateMessage)
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if store.filter != .all {
                Button {
                    store.send(.filterChanged(.all))
                } label: {
                    Text("Show All Items")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaAccent)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyStateIcon: String {
        store.filter == .archived ? "archivebox" : "tray"
    }
    
    private var emptyStateTitle: String {
        switch store.filter {
        case .all: return "Inbox Empty"
        case .voiceNotes: return "No Voice Notes"
        case .photos: return "No Photos"
        case .scans: return "No Scans"
        case .archived: return "No Archived Items"
        }
    }
    
    private var emptyStateMessage: String {
        switch store.filter {
        case .all: return "Tap + to quickly capture voice notes, photos, or scanned documents"
        case .voiceNotes: return "Voice recordings will appear here"
        case .photos: return "Photos you capture will appear here"
        case .scans: return "Scanned documents will appear here"
        case .archived: return "Archived items will appear here"
        }
    }
    
    // MARK: - Inbox Content
    
    private var inboxContent: some View {
        VStack(spacing: 0) {
            // Filter pills
            filterPills
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            // Grouped list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.groupedItems, id: \.0) { group, items in
                        VStack(alignment: .leading, spacing: 8) {
                            // Date header
                            Text(group)
                                .font(.minaCaption1)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.minaSecondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)
                            
                            // Items
                            ForEach(items) { item in
                                InboxItemRow(item: item)
                                    .onTapGesture {
                                        store.send(.itemTapped(item))
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            store.send(.deleteItem(item.id))
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            store.send(.archiveItem(item.id))
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(Color.minaSecondary)
                                    }
                                    .swipeActions(edge: .leading) {
                                        if !item.isProcessed {
                                            Button {
                                                store.send(.convertToEntry(item.id))
                                            } label: {
                                                Label("Add to Journal", systemImage: "book")
                                            }
                                            .tint(Color.minaAccent)
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.bottom, 120) // Space for FAB
            }
        }
    }
    
    // MARK: - Filter Pills
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxFeature.InboxFilter.allCases) { filter in
                    FilterPill(
                        label: filter.label,
                        icon: filter.icon,
                        isSelected: store.filter == filter,
                        count: countForFilter(filter)
                    ) {
                        store.send(.filterChanged(filter))
                    }
                }
            }
        }
    }
    
    private func countForFilter(_ filter: InboxFeature.InboxFilter) -> Int? {
        switch filter {
        case .all:
            let count = store.items.filter { !$0.isArchived }.count
            return count > 0 ? count : nil
        case .voiceNotes:
            let count = store.items.filter { $0.type == .voiceNote && !$0.isArchived }.count
            return count > 0 ? count : nil
        case .photos:
            let count = store.items.filter { $0.type == .photo && !$0.isArchived }.count
            return count > 0 ? count : nil
        case .scans:
            let count = store.items.filter { $0.type == .scan && !$0.isArchived }.count
            return count > 0 ? count : nil
        case .archived:
            let count = store.items.filter { $0.isArchived }.count
            return count > 0 ? count : nil
        }
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        Button {
            store.send(.showCaptureOptions)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Quick Capture")
                    .font(.minaHeadline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.minaAccent)
            .clipShape(Capsule())
            .shadow(color: Color.minaAccent.opacity(0.3), radius: 8, y: 4)
        }
    }
    
    // MARK: - Recording Indicator
    
    private var recordingIndicator: some View {
        HStack(spacing: 12) {
            // Recording dot
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .opacity(0.8)
            
            // Duration
            Text(formatDuration(store.recordingDuration))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            Spacer()
            
            // Stop button
            Button {
                store.send(.stopVoiceRecording)
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.red)
        .clipShape(Capsule())
        .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal, 40)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let label: String
    let icon: String
    let isSelected: Bool
    var count: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(label)
                    .font(.minaSubheadline)
                
                if let count = count {
                    Text("\(count)")
                        .font(.minaCaption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.minaSecondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? .white : Color.minaPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.minaAccent : Color.minaCardSolid)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.minaDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Inbox Item Row

struct InboxItemRow: View {
    let item: InboxFeature.InboxItemState
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.type.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.type.label)
                        .font(.minaSubheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.minaPrimary)
                    
                    Spacer()
                    
                    Text(item.formattedTime)
                        .font(.minaCaption1)
                        .foregroundStyle(Color.minaSecondary)
                }
                
                Text(item.displayPreview)
                    .font(.minaFootnote)
                    .foregroundStyle(Color.minaSecondary)
                    .lineLimit(2)
                
                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(item.statusLabel)
                        .font(.minaCaption2)
                        .foregroundStyle(statusColor)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
    
    private var iconBackgroundColor: Color {
        switch item.type {
        case .voiceNote: return Color.purple.opacity(0.1)
        case .photo: return Color.blue.opacity(0.1)
        case .scan: return Color.orange.opacity(0.1)
        case .file: return Color.gray.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .voiceNote: return Color.purple
        case .photo: return Color.blue
        case .scan: return Color.orange
        case .file: return Color.gray
        }
    }
    
    private var statusColor: Color {
        if item.isProcessed {
            return Color.minaSuccess
        } else if item.transcription != nil {
            return Color.minaAccent
        } else {
            return Color.minaSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    InboxTabView(
        store: Store(initialState: InboxFeature.State()) {
            InboxFeature()
        }
    )
}
