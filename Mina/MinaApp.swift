import SwiftUI
import SwiftData
import ComposableArchitecture

// MARK: - Mina App Entry Point

@main
struct MinaApp: App {
    
    /// Root TCA store
    static let store = Store(initialState: AppReducer.State()) {
        AppReducer()
    }
    
    /// SwiftData model container
    let modelContainer: ModelContainer
    
    init() {
        // Initialize SwiftData container
        do {
            let schema = Schema([
                JournalEntry.self,
                JournalAttachment.self,
                InboxItem.self,
                GalleryArtwork.self,
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none // Enable for CloudKit sync
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        // Configure appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
                .modelContainer(modelContainer)
        }
    }
    
    // MARK: - Appearance Configuration
    
    private func configureAppearance() {
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.minaCardSolid)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.minaBackground)
        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}

// MARK: - App View (Root)

struct AppView: View {
    
    @Bindable var store: StoreOf<AppReducer>
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
            // Tab 1: Journal (Home)
            JournalTabView(
                store: store.scope(state: \.journal, action: \.journal)
            )
            .tabItem {
                Label("Journal", systemImage: "book.fill")
            }
            .tag(AppReducer.Tab.journal)
            
            // Tab 2: Gallery
            GalleryTabView(
                store: store.scope(state: \.gallery, action: \.gallery)
            )
            .tabItem {
                Label("Gallery", systemImage: "photo.on.rectangle.angled")
            }
            .tag(AppReducer.Tab.gallery)
            
            // Tab 3: Inbox
            InboxTabView(
                store: store.scope(state: \.inbox, action: \.inbox)
            )
            .tabItem {
                Label("Inbox", systemImage: "tray.fill")
            }
            .tag(AppReducer.Tab.inbox)
            
            // Tab 4: Insights
            InsightsTabView(
                store: store.scope(state: \.insights, action: \.insights)
            )
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppReducer.Tab.insights)
        }
        .tint(Color.minaAccent)
        .fullScreenCover(
            item: $store.scope(state: \.onboarding, action: \.onboarding)
        ) { onboardingStore in
            OnboardingContainerView(store: onboardingStore)
        }
        .onAppear {
            store.send(.appDidLaunch)
        }
    }
}

// MARK: - Placeholder Tab View

struct PlaceholderTabView: View {
    
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        ZStack {
            Color.minaBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.minaSecondary)
                
                Text(title)
                    .font(.minaTitle2)
                    .foregroundStyle(Color.minaPrimary)
                
                Text(description)
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
                    .multilineTextAlignment(.center)
                
                Text("Coming Soon")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaTertiary)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    AppView(
        store: Store(initialState: AppReducer.State()) {
            AppReducer()
        }
    )
}
