//
//  CompletionCheckbox.swift
//  Ripple
//
//  Task 1 — Duty 1.4
//  Temporary checkbox until Task 2's HabitCompletionCheckmark is merged.
//
//  WHEN TASK 2 IS MERGED: in TodayView.swift, replace
//      CompletionCheckbox(isComplete: isDone)
//  with
//      HabitCompletionCheckmark(isComplete: isDone)
//  and delete this file. Both take the same `isComplete` value.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import SwiftUI

struct CompletionCheckbox: View {

    let isComplete: Bool
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
            .font(.system(size: size))
            .foregroundStyle(isComplete ? Color.green : Color.secondary)
            .contentTransition(.symbolEffect(.replace))
            .animation(.snappy, value: isComplete)
    }
}
