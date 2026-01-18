import SwiftUI
import ComposableArchitecture

// MARK: - Journal Tab View
// Main container view for the Journal (Home) tab
// Matches the reference design: warm cream background, minimalist aesthetic

struct JournalTabView: View {
    
    @Bindable var store: StoreOf<JournalFeature>
    
    var body: some View {
        ZStack {
            // Background
            Color.minaBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                JournalHeaderView(
                    streak: store.streak,
                    onLogoTap: { store.send(.scrollToTopTapped) },
                    onSettingsTap: { store.send(.settingsTapped) }
                )
                
                // Content
                if store.isLoading && store.entries.isEmpty {
                    LoadingView()
                } else if store.entries.isEmpty {
                    EmptyStateView {
                        store.send(.newEntryTapped)
                    }
                } else {
                    EntryListView(store: store)
                }
            }
            
            // Floating Input Bar
            VStack {
                Spacer()
                FloatingInputBar {
                    store.send(.newEntryTapped)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { store in
            EntryEditorSheet(store: store)
        }
        .sheet(item: $store.scope(state: \.entryDetail, action: \.entryDetail)) { store in
            EntryEditorSheet(store: store)
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
