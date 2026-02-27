import AVFoundation


@Observable
class AudioPlayerService {
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0
    var currentTitle: String?
    var currentDocumentID: UUID?
    
    var isShowingPDF: Bool {
        didSet {
            UserDefaults.standard.set(isShowingPDF, forKey: "isShowingPDF")
        }
    }

    init() {
        // Register default value
        UserDefaults.standard.register(defaults: ["isShowingPDF": true])
        // Initialize from storage
        self.isShowingPDF = UserDefaults.standard.bool(forKey: "isShowingPDF")
    }


    private var player: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?


    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }


    var hasActiveSession: Bool {
        currentDocumentID != nil
    }


    func load(url: URL, title: String, documentID: UUID, startTime: TimeInterval = 0) {
        stop()


        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)


            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.enableRate = true
            player?.rate = playbackRate
            duration = player?.duration ?? 0
            
            seek(to: startTime)

            currentTitle = title
            currentDocumentID = documentID

            // Removed automatic play() call here
        } catch {
            print("Playback failed: \(error)")
        }
    }

    func play() {
        player?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }

    func stop() {
        player?.stop()
        isPlaying = false
        stopTimer()
        currentDocumentID = nil
        currentTitle = nil
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    func skipBackward() {
        let newTime = max(0, currentTime - 15)
        seek(to: newTime)
    }

    func skipForward() {
        let newTime = min(duration, currentTime + 15)
        seek(to: newTime)
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while isPlaying {
                currentTime = player?.currentTime ?? 0
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}

