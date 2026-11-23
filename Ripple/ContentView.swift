//
//  Anthony Robinson II
//  ContentView.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//
//  The app's main screens, one tab each:
//    Today    — Task 1 (Anthony): the habit list
//    Journal  — Task 2 (Kelsey): the daily journal
//    Progress — Task 3 (Francis): streaks and weekly progress
//    Calendar — Task 3 (Francis): past habit completions
//
//  Every one of these views brings its own NavigationStack, so they are
//  used as tabs rather than pushed inside another one.
//  Onboarding is attached one level up, in RippleApp.swift.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: the TabView below.
//

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

            HabitProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            CalendarHistoryView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }
}
