import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Today Screen") {
                    TodayView()
                }

                NavigationLink("Progress Tracking") {
                    HabitProgressView()
                }

                NavigationLink("Calendar History & Charts") {
                    CalendarHistoryView()
                }

                NavigationLink("Celebration Test") {
                    CelebrationView(message: "You reached your goal!")
                }
            }
            .navigationTitle("Ripple Testing")
        }
    }
}
