import SwiftUI

struct DocumentCard: View {
    let document: AudioDocument
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Square Cover Image
            Group {
                if let imageURL = document.imageURL, let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    // Placeholder for documents without an image or while generating
                    ZStack {
                        Color(.secondarySystemFill)
                        if document.isProcessing {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack(alignment: .center, spacing: 0) {
                    Group {
                        if let author = document.author {
                            Text(author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else if document.isProcessing {
                            Text("Generating...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 8)

                    // Menu Button moved next to author/name
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .contentShape(Rectangle())
    }
}
