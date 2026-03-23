//
//  MediaDiaryApp.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

@main
struct MediaDiaryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Work.self,
            Review.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
