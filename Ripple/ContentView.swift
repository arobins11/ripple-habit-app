
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checklist")
                }

            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }
        }
    }
}
