import SwiftUI

@main
struct Kanji_StudyApp: App {
    @StateObject private var store = KanjiStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
