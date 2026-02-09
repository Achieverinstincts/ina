import SwiftUI

// MARK: - Onboarding Chip
// Multi-select chip/tag for topics selection

struct OnboardingChip: View {
    let title: String
    let emoji: String?
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(
        title: String,
        emoji: String? = nil,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.emoji = emoji
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? Color.minaAccent : Color.minaSecondary)
                }
                
                Text(title)
                    .font(.minaSubheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.minaAccent : Color.minaPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.minaAccent.opacity(0.12) : Color.minaCardSolid)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.minaAccent : Color.minaDivider, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Chip Grid

struct OnboardingChipGrid<Item: Hashable & Identifiable>: View {
    let items: [Item]
    let selectedItems: Set<Item>
    let titleKeyPath: KeyPath<Item, String>
    let emojiKeyPath: KeyPath<Item, String>?
    let onToggle: (Item) -> Void
    
    init(
        items: [Item],
        selectedItems: Set<Item>,
        title: KeyPath<Item, String>,
        emoji: KeyPath<Item, String>? = nil,
        onToggle: @escaping (Item) -> Void
    ) {
        self.items = items
        self.selectedItems = selectedItems
        self.titleKeyPath = title
        self.emojiKeyPath = emoji
        self.onToggle = onToggle
    }
    
    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items) { item in
                OnboardingChip(
                    title: item[keyPath: titleKeyPath],
                    emoji: emojiKeyPath.map { item[keyPath: $0] },
                    isSelected: selectedItems.contains(item),
                    action: { onToggle(item) }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        OnboardingChip(
            title: "Gratitude",
            emoji: "🙏",
            isSelected: true,
            action: {}
        )
        
        OnboardingChip(
            title: "Mindfulness",
            emoji: "🧘",
            isSelected: false,
            action: {}
        )
        
        // Grid example
        FlowLayout(spacing: 10) {
            ForEach(JournalTopic.allCases) { topic in
                OnboardingChip(
                    title: topic.title,
                    emoji: topic.emoji,
                    isSelected: topic == .gratitude || topic == .mindfulness,
                    action: {}
                )
            }
        }
        .padding()
    }
    .padding()
    .background(Color.minaBackground)
}
