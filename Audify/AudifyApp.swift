import SwiftUI
import SwiftData


@main
struct AudifyApp: App {
    @State private var playerService = AudioPlayerService()


    var sharedModelContainer: ModelContainer = {
        let schema = Schema([AudioDocument.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(playerService)
        }
        .modelContainer(sharedModelContainer)
    }
}
