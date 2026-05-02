import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BrowseView()
                .tabItem { Label("Browse", systemImage: "list.bullet") }

            StudyView()
                .tabItem { Label("Study", systemImage: "rectangle.on.rectangle") }

            ProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
