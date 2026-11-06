//
//  HabitRow.swift
//  Ripple
//
//  Task 1 — Duty 1.1 / 1.4
//  One habit in the Today list (icon + name). The checkbox sits beside it
//  in TodayView so tapping the name opens the edit form instead.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import SwiftUI

struct HabitRow: View {

    let habit: Habit
    var isComplete: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            Text(habit.name)
                .strikethrough(isComplete)
                .foregroundStyle(isComplete ? .secondary : .primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())   // makes the whole row tappable
        .animation(.easeInOut(duration: 0.2), value: isComplete)
    }
}
