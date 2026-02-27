import SwiftUI


struct PlayerControlsView: View {
    let document: AudioDocument
    @Environment(AudioPlayerService.self) private var playerService
    @State private var sliderValue: Double = 0
    @State private var isDragging: Bool = false


    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 4) {
                Slider(value: $sliderValue, in: 0...1) { editing in
                    if !editing {
                        playerService.seek(to: sliderValue * playerService.duration)
                    }
                    isDragging = editing
                }
                .tint(.black)


                HStack {
                    Text(formatTime(playerService.currentTime))
                    Spacer()
                    Text("-\(formatTime(max(0, playerService.duration - playerService.currentTime)))")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.black.opacity(0.6))
            }


            HStack(alignment: .center, spacing: 0) {
                // PDF Toggle (Left)
                Button {
                    withAnimation {
                        playerService.isShowingPDF.toggle()
                    }
                } label: {
                    Image(systemName: playerService.isShowingPDF ? "eye" : "eye.slash")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Skip Backward
                Button { playerService.skipBackward() } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Play/Pause
                Button { playerService.togglePlayPause() } label: {
                    Image(systemName: playerService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.black)
                        .frame(width: 64, height: 64)
                }

                Spacer()

                // Skip Forward
                Button { playerService.skipForward() } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Speed Control (Right)
                Menu {
                    ForEach([0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 2.0, 2.5], id: \.self) { rate in
                        Button {
                            playerService.setPlaybackRate(Float(rate))
                        } label: {
                            HStack {
                                Text("\(rate, specifier: "%.1fx")")
                                if playerService.playbackRate == Float(rate) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(playerService.playbackRate == floor(playerService.playbackRate) ? String(format: "%.0f", playerService.playbackRate) : String(format: "%.1f", playerService.playbackRate))
                            .font(.system(size: 20))
                        Text("x")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
        .onAppear {
            // Restore playback position on load
            let lastPos = document.lastPlaybackPosition
            sliderValue = lastPos / (playerService.duration > 0 ? playerService.duration : 1.0)
            
            // Load the audio if this document isn't already the active one
            if playerService.currentDocumentID != document.id, let url = document.audioURL {
                playerService.load(url: url, title: document.title, documentID: document.id, startTime: lastPos)
            }
        }
        .onChange(of: playerService.currentTime) { _, newTime in
            // Keep slider in sync while playing (unless user is dragging)
            if !isDragging {
                sliderValue = playerService.progress
            }
            
            // Persist playback position to the document model
            if playerService.currentDocumentID == document.id {
                document.lastPlaybackPosition = newTime
            }
        }
        .onChange(of: playerService.duration) { _, _ in
            // If the duration changes (e.g., after loading), refresh the slider
            if !isDragging {
                sliderValue = playerService.progress
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
