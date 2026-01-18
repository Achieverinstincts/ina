# Mina - iOS Journaling App

A premium, multi-modal AI journaling app built with SwiftUI and The Composable Architecture (TCA).

## Requirements

- **Xcode 15.0+**
- **iOS 17.0+**
- **macOS Sonoma 14.0+** (for development)

## Quick Start

### 1. Create Xcode Project

1. Open Xcode
2. Create new project: **File → New → Project**
3. Select **iOS → App**
4. Configure:
   - Product Name: `Mina`
   - Team: Your development team
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we configure SwiftData manually)
5. Click **Create**

### 2. Add Dependencies (Swift Package Manager)

1. Go to **File → Add Package Dependencies**
2. Add the following packages:

```
https://github.com/pointfreeco/swift-composable-architecture
```
- Version: **1.10.0** or later
- Add to target: `Mina`

### 3. Copy Source Files

Copy all files from the generated `Mina/` folder into your Xcode project:

```
Mina/
├── MinaApp.swift                    # Replace generated App file
├── App/
│   └── AppReducer.swift
├── DesignSystem/
│   ├── MinaColors.swift
│   ├── MinaTypography.swift
│   └── Components/
│       └── PillView.swift
├── Models/
│   ├── JournalEntry.swift
│   └── Attachment.swift
├── Services/
│   ├── DatabaseClient.swift
│   └── DateClient.swift
└── Features/
    └── Journal/
        ├── JournalFeature.swift
        ├── EntryEditorReducer.swift
        ├── ActiveInputReducer.swift
        └── Views/
            ├── JournalTabView.swift
            ├── JournalHeaderView.swift
            ├── EntryRowView.swift
            ├── EmptyStateView.swift
            ├── FloatingInputBar.swift
            ├── EntryEditorSheet.swift
            └── ActiveInputBar.swift
```

### 4. Configure Assets

Create the following color sets in `Assets.xcassets`:

| Color Name | Light Mode | Usage |
|------------|------------|-------|
| `AppBackground` | `#FDF8F3` | Main background |
| `AppCardSolid` | `#FFFFFF` | Card backgrounds |
| `AppPrimary` | `#1A1A1A` | Primary text |
| `AppSecondary` | `#8E8E93` | Secondary text |
| `AppAccent` | `#FF6B35` | Accent/streak color |

### 5. Delete Generated Files

Remove these auto-generated files (we replace them):
- `ContentView.swift`
- Original `MinaApp.swift`

### 6. Build & Run

1. Select an iOS 17+ simulator or device
2. Press **⌘R** to build and run

## Project Structure

```
Mina/
├── App/                    # App entry point and root reducer
├── DesignSystem/           # Colors, typography, reusable components
├── Models/                 # SwiftData models
├── Services/               # TCA dependencies (database, date, etc.)
├── Features/               # Feature modules (TCA pattern)
│   ├── Journal/            # Journal tab (implemented)
│   ├── Gallery/            # Gallery tab (placeholder)
│   ├── Inbox/              # Inbox tab (placeholder)
│   └── Insights/           # Insights tab (placeholder)
└── Resources/              # Assets, localization
```

## Architecture

### The Composable Architecture (TCA)

This app uses TCA 1.10+ with the latest patterns:

- **`@Reducer` macro** - Defines reducers with less boilerplate
- **`@ObservableState`** - Observable state without manual ViewStore
- **`@Bindable`** - Two-way bindings in SwiftUI views
- **`@Dependency`** - Dependency injection for testability

### Data Flow

```
User Action → View → Store.send(Action) → Reducer → State Change → View Update
                                              ↓
                                         Side Effects (async)
                                              ↓
                                         Database/API
```

### SwiftData

Models use `@Model` macro for persistence:
- `JournalEntry` - Main journal entries
- `JournalAttachment` - Media attachments
- `InboxItem` - Unprocessed quick captures

## Features Implemented

### Journal Tab (Tab 1)
- ✅ Today's entries list
- ✅ Receipt-style entry rows
- ✅ Streak counter
- ✅ Entry creation/editing
- ✅ Mood selection
- ✅ Empty state
- ✅ Floating input bar

### Keyboard Accessory
- ✅ AI sparkle menu (UI only)
- ✅ Mic button (UI + state)
- ✅ Camera button (UI only)
- ✅ Scan button (UI only)
- ✅ Attach button (UI only)
- ✅ Dismiss keyboard

## TODO / Future Work

### High Priority
- [ ] Implement voice recording (SFSpeechRecognizer)
- [ ] Implement camera capture
- [ ] Implement document scanning (VisionKit)
- [ ] Connect AI service for title generation
- [ ] Gallery tab implementation
- [ ] Inbox tab implementation
- [ ] Insights tab implementation

### Medium Priority
- [ ] CloudKit sync
- [ ] Dark mode support
- [ ] Haptic feedback
- [ ] Animations polish
- [ ] Widget extension

### Low Priority
- [ ] Apple Watch companion
- [ ] Shortcuts integration
- [ ] Export functionality

## Design Tokens

### Colors (from reference)

| Token | Hex | Usage |
|-------|-----|-------|
| `minaBackground` | `#FDF8F3` | Warm cream background |
| `minaCardSolid` | `#FFFFFF` | White cards |
| `minaPrimary` | `#1A1A1A` | Primary text |
| `minaSecondary` | `#8E8E93` | Secondary text |
| `minaTertiary` | `#C7C7CC` | Placeholder text |
| `minaAccent` | `#FF6B35` | Orange accent |
| `minaAI` | `#8B5CF6` | AI/sparkle purple |

### Typography

All fonts use SF Pro (system font):

| Style | Size | Weight |
|-------|------|--------|
| `minaLargeTitle` | 34pt | Bold |
| `minaTitle2` | 22pt | Bold |
| `minaHeadline` | 17pt | Semibold |
| `minaBody` | 17pt | Regular |
| `minaSubheadline` | 15pt | Regular |
| `minaCaption1` | 12pt | Regular |

## Testing

### Unit Tests

TCA reducers are fully testable:

```swift
@Test
func testLoadEntries() async {
    let store = TestStore(
        initialState: JournalFeature.State()
    ) {
        JournalFeature()
    } withDependencies: {
        $0.databaseClient.fetchTodayEntries = { JournalEntry.samples }
    }
    
    await store.send(.onAppear)
    await store.receive(.loadEntries)
    await store.receive(.entriesLoaded(JournalEntry.samples)) {
        $0.entries = IdentifiedArrayOf(...)
    }
}
```

### UI Tests

SwiftUI Previews are included for all views.

## Troubleshooting

### "No such module 'ComposableArchitecture'"

Ensure TCA package is added correctly:
1. File → Packages → Reset Package Caches
2. Product → Clean Build Folder (⇧⌘K)
3. Rebuild

### SwiftData Migration Issues

For development, you can reset the container:
```swift
// In MinaApp.init()
let config = ModelConfiguration(isStoredInMemoryOnly: true)
```

### Build Errors After Copying Files

Ensure all files are added to the Mina target:
1. Select each file in Project Navigator
2. Check "Target Membership" in File Inspector

## License

Proprietary - All rights reserved.

## Contact

[Your contact information]
