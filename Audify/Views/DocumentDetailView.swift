import SwiftUI


struct DocumentDetailView: View {
    let document: AudioDocument
    let viewModel: LibraryViewModel
    @Environment(AudioPlayerService.self) private var playerService
    @State private var backgroundColor: Color = Color(.systemBackground)

    var body: some View {
        ZStack {
            // Background (adaptive gradient when not in PDF view)
            if !playerService.isShowingPDF {
                LinearGradient(
                    stops: [
                        .init(color: backgroundColor, location: 0),
                        .init(color: backgroundColor, location: 0.7),
                        .init(color: .white, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut, value: backgroundColor)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                if playerService.isShowingPDF {
                    if let pdfURL = document.pdfURL {
                        PDFViewerRepresentable(url: pdfURL)
                    } else {
                        ContentUnavailableView("PDF Not Found", systemImage: "doc.questionmark")
                    }
                } else {
                    ZStack {
                        if let imageURL = document.imageURL, let uiImage = UIImage(contentsOfFile: imageURL.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .padding(24)
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                                .onAppear {
                                    backgroundColor = uiImage.edgeColor()
                                }
                        } else {
                            ContentUnavailableView("Generating Cover...", systemImage: "photo")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
 
                if playerService.isShowingPDF {
                    Divider()
                }


                if document.isReady {
                    PlayerControlsView(document: document)
                } else if document.isProcessing {
                    processingView
                } else if document.errorMessage != nil {
                    errorView
                } else {
                    generateView
                }
            }
        }
        .navigationTitle(document.author != nil ? "\(document.title) — \(document.author!)" : document.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            playerService.stop()
        }
    }


    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView(value: document.processingProgress)
            Text("Generating audio… \(Int(document.processingProgress * 100))%")
                .font(.subheadline)
        }
        .padding()
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.red)
            Text(document.errorMessage ?? "An unknown error occurred.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.generateAudio(for: document)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var generateView: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.generateAudio(for: document)
            } label: {
                Label("Generate Audio", systemImage: "waveform")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

