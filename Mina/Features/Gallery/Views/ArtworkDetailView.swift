import SwiftUI
import ComposableArchitecture

// MARK: - Artwork Detail View
// Full-screen view of a single artwork with actions

struct ArtworkDetailView: View {
    
    @Bindable var store: StoreOf<ArtworkDetailFeature>
    @Environment(\.dismiss) private var dismiss
    
    // Computed card height matching gallery card logic
    private var artworkHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32
        return screenWidth * CGFloat(store.artwork.aspectRatio)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Artwork display
                        artworkDisplay
                        
                        // Entry info
                        entryInfoSection
                        
                        // Actions
                        actionButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.dismiss)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.minaSecondary)
                            .padding(8)
                            .background(Color.minaCardSolid)
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            store.send(.shareButtonTapped)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            store.send(.saveButtonTapped)
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                        }
                        
                        Divider()
                        
                        Button {
                            store.send(.regenerateButtonTapped)
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.minaSecondary)
                            .padding(8)
                            .background(Color.minaCardSolid)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Artwork Display
    
    private var artworkDisplay: some View {
        ZStack {
            // Placeholder color
            Color(hex: store.artwork.placeholderColor)
            
            // Real image or placeholder
            if let imageData = store.artwork.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                // Artwork pattern (same as card)
                artworkPattern
            }
            
            // AI badge
            VStack {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("AI Generated")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(12)
                }
                
                Spacer()
            }
        }
        .frame(height: min(artworkHeight, 500))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.minaShadow, radius: 10, y: 4)
    }
    
    private var artworkPattern: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced dreamy pattern for detail view
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.4), .pink.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .offset(x: geometry.size.width * 0.15, y: -geometry.size.height * 0.1)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .teal.opacity(0.2)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.2, y: geometry.size.height * 0.25)
                    .blur(radius: 15)
                
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: geometry.size.width * 0.4)
                    .offset(x: geometry.size.width * 0.25, y: geometry.size.height * 0.15)
                    .blur(radius: 18)
                
                // Sparkle overlay
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
    }
    
    // MARK: - Entry Info Section
    
    private var entryInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and date
            VStack(alignment: .leading, spacing: 4) {
                Text(store.artwork.entryTitle)
                    .font(.minaTitle2)
                    .foregroundStyle(Color.minaPrimary)
                
                Text(formattedFullDate)
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            // Metadata row
            HStack(spacing: 16) {
                // Mood
                if let mood = store.artwork.mood {
                    MetadataChip(
                        icon: nil,
                        emoji: mood.emoji,
                        label: mood.label
                    )
                }
                
                // Art style
                MetadataChip(
                    icon: "paintbrush.fill",
                    emoji: nil,
                    label: store.artwork.artStyle.capitalized
                )
            }
            
            // View entry button
            Button {
                store.send(.openEntryTapped)
            } label: {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14))
                    
                    Text("View Journal Entry")
                        .font(.minaSubheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.minaAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.minaAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: store.artwork.entryDate)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                store.send(.shareButtonTapped)
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Artwork")
                }
                .font(.minaHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.minaAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Save button
            Button {
                store.send(.saveButtonTapped)
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save to Photos")
                }
                .font(.minaHeadline)
                .foregroundStyle(Color.minaAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.minaCardSolid)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.minaAccent, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Metadata Chip

private struct MetadataChip: View {
    let icon: String?
    let emoji: String?
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.minaSecondary)
            }
            
            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 14))
            }
            
            Text(label)
                .font(.minaCaption1)
                .foregroundStyle(Color.minaPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.minaBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    let sample = GalleryArtwork.sample
    let artwork = GalleryFeature.ArtworkItem(
        id: sample.id,
        entryId: sample.entryId,
        entryTitle: sample.entryTitle,
        entryDate: sample.entryDate,
        mood: sample.mood,
        artStyle: sample.artStyle,
        aspectRatio: sample.aspectRatio,
        status: sample.status
    )
    
    return ArtworkDetailView(
        store: Store(initialState: ArtworkDetailFeature.State(artwork: artwork)) {
            ArtworkDetailFeature()
        }
    )
}
