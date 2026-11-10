//
//  ContentView.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//
//  Task 1 (Anthony) + Task 2 (Kelsey): the app's two main screens.
//  TodayView holds the habit list; JournalView holds the daily journal.
//  They sit side by side in a tab bar.
//
//  JournalView brings its own NavigationStack, so it is used as a tab
//  rather than pushed inside another one (see JournalView.swift).
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
        }
    }
}
