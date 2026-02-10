import SwiftUI
import ComposableArchitecture

// MARK: - Gallery Card View
// Individual artwork card for the masonry grid

struct GalleryCardView: View {
    
    let artwork: GalleryFeature.ArtworkItem
    
    // Random height for masonry effect (in real app, use aspectRatio)
    private var cardHeight: CGFloat {
        CGFloat(150 + (artwork.aspectRatio * 50))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Artwork image area
            ZStack {
                // Placeholder/background color based on mood
                Color(hex: artwork.placeholderColor)
                
                // Real image or placeholder
                if let imageData = artwork.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectFill()
                } else {
                    // Placeholder artwork pattern
                    artworkPlaceholder
                }
                
                // Status overlay for generating/failed
                if artwork.status == .generating {
                    generatingOverlay
                } else if artwork.status == .failed {
                    failedOverlay
                } else if artwork.status == .pending {
                    pendingOverlay
                }
            }
            .frame(height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Entry info
            VStack(alignment: .leading, spacing: 2) {
                Text(artwork.entryTitle)
                    .font(.minaFootnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.minaPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let mood = artwork.mood {
                        Text(mood.emoji)
                            .font(.system(size: 10))
                    }
                    
                    Text(artwork.formattedDate)
                        .font(.minaCaption2)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Generating Overlay
    
    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                
                Text("Generating...")
                    .font(.minaCaption1)
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Failed Overlay
    
    private var failedOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("Failed")
                    .font(.minaCaption1)
                    .foregroundStyle(.white)
                
                if let error = artwork.errorMessage {
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
    
    // MARK: - Pending Overlay
    
    private var pendingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
            
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("Pending")
                    .font(.minaCaption1)
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Artwork Placeholder
    
    private var artworkPlaceholder: some View {
        GeometryReader { geometry in
            ZStack {
                // Abstract shapes based on art style
                switch artwork.artStyle.lowercased() {
                case "watercolor":
                    watercolorPattern(in: geometry.size)
                case "abstract":
                    abstractPattern(in: geometry.size)
                case "minimalist":
                    minimalistPattern(in: geometry.size)
                case "impressionist":
                    impressionistPattern(in: geometry.size)
                default:
                    dreamyPattern(in: geometry.size)
                }
                
                // Subtle texture overlay
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.15))
            }
        }
    }
    
    // MARK: - Art Style Patterns
    
    private func dreamyPattern(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width * 0.7)
                .offset(x: size.width * 0.2, y: -size.height * 0.1)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .teal.opacity(0.15)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: size.width * 0.5)
                .offset(x: -size.width * 0.2, y: size.height * 0.2)
        }
    }
    
    private func watercolorPattern(in size: CGSize) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.blue.opacity(0.25))
                .blur(radius: 20)
                .frame(width: size.width * 0.8, height: size.height * 0.4)
                .offset(y: -size.height * 0.15)
            
            Ellipse()
                .fill(Color.teal.opacity(0.2))
                .blur(radius: 15)
                .frame(width: size.width * 0.6, height: size.height * 0.5)
                .offset(x: size.width * 0.1, y: size.height * 0.1)
            
            Ellipse()
                .fill(Color.green.opacity(0.15))
                .blur(radius: 18)
                .frame(width: size.width * 0.5, height: size.height * 0.3)
                .offset(x: -size.width * 0.15, y: size.height * 0.25)
        }
    }
    
    private func abstractPattern(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.4))
                .frame(width: size.width * 0.4, height: size.height * 0.3)
                .rotationEffect(.degrees(15))
                .offset(x: -size.width * 0.15, y: -size.height * 0.15)
            
            Circle()
                .fill(Color.indigo.opacity(0.35))
                .frame(width: size.width * 0.35)
                .offset(x: size.width * 0.2, y: size.height * 0.1)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.yellow.opacity(0.3))
                .frame(width: size.width * 0.25, height: size.height * 0.2)
                .rotationEffect(.degrees(-10))
                .offset(x: size.width * 0.1, y: size.height * 0.2)
        }
    }
    
    private func minimalistPattern(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 2)
                .frame(width: size.width * 0.5)
            
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: 1, height: size.height * 0.4)
                .offset(x: -size.width * 0.15)
            
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: size.width * 0.3, height: 1)
                .offset(y: size.height * 0.15)
        }
    }
    
    private func impressionistPattern(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<12) { i in
                let angle = Double(i) * 30
                let distance = CGFloat.random(in: 0.1...0.35)
                let hue = Double(i) / 12.0
                
                Circle()
                    .fill(Color(hue: hue, saturation: 0.4, brightness: 0.9).opacity(0.3))
                    .frame(width: size.width * 0.15)
                    .offset(
                        x: cos(angle * .pi / 180) * size.width * distance,
                        y: sin(angle * .pi / 180) * size.height * distance
                    )
            }
        }
    }
}

// MARK: - AspectFill Modifier

private extension Image {
    func aspectFill() -> some View {
        self
            .scaledToFill()
            .clipped()
    }
}

// MARK: - Preview

#Preview {
    let samples = GalleryArtwork.samples.map { artwork in
        GalleryFeature.ArtworkItem(
            id: artwork.id,
            entryId: artwork.entryId,
            entryTitle: artwork.entryTitle,
            entryDate: artwork.entryDate,
            mood: artwork.mood,
            artStyle: artwork.artStyle,
            aspectRatio: artwork.aspectRatio,
            status: artwork.status
        )
    }
    
    return ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(samples) { artwork in
                GalleryCardView(artwork: artwork)
            }
        }
        .padding()
    }
    .background(Color.minaBackground)
}
