import SwiftUI

// MARK: - Entry Row View
// "Receipt-style" row showing timestamp, title, preview, and media icons

struct EntryRowView: View {
    
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Timestamp + Media Icons
            HStack {
                // Timestamp
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
                
                Spacer()
                
                // Media type indicators
                MediaIconsView(mediaTypes: entry.mediaTypes)
            }
            
            // Row 2: Title (bold)
            Text(entry.displayTitle)
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
                .lineLimit(1)
            
            // Row 3: Content preview
            Text(entry.contentPreview)
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
                .lineLimit(1)
            
            // Row 4: Mood indicator (if set)
            if let mood = entry.mood {
                MoodBadgeView(mood: mood)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color.minaCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Media Icons View

private struct MediaIconsView: View {
    
    let mediaTypes: [AttachmentType]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(mediaTypes, id: \.self) { type in
                Text(type.icon)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Mood Badge View

private struct MoodBadgeView: View {
    
    let mood: Mood
    
    var body: some View {
        HStack(spacing: 4) {
            Text(mood.emoji)
                .font(.caption)
            Text(mood.label)
                .font(.minaCaption2)
                .foregroundStyle(Color.minaSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.minaBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        EntryRowView(entry: JournalEntry.sample)
        
        EntryRowView(entry: JournalEntry(
            title: "Quick thought",
            content: "Just a brief note about something I noticed today while walking home from work."
        ))
        
        EntryRowView(entry: JournalEntry(
            title: "Dinner with friends",
            content: "Amazing evening at the new Italian place downtown.",
            mood: .great
        ))
    }
    .padding()
    .background(Color.minaBackground)
}
