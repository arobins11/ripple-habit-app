//
//  ContentView.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//
//  Task 1 (Anthony): the app's main screen is now the Today screen.
//  Brendon's original test buttons were replaced by TodayView, which
//  adds, edits and deletes habits through the same SwiftData models.
//  This stays the root view so Task 2 can still wrap it with
//  `ContentView().rippleOnboarding()` in RippleApp.swift.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): "Make the Today screen the app's main screen."
//  AI-generated: the body of this view (it now shows TodayView).
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TodayView()
    }
}
