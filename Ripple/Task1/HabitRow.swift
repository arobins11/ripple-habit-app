//
//  HabitRow.swift
//  Ripple
//
//  Task 1 — Duty 1.1
//  One habit in the Today list. The checkbox is added in Duty 1.4.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): "Build Task 1 piece 1 for our Ripple habit app —
//  a Today screen with morning/afternoon/evening routines and add/edit/delete,
//  saved with our team's existing SwiftData Habit model."
//  AI-generated: this entire file.
//

import SwiftUI

struct HabitRow: View {

    let habit: Habit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            Text(habit.name)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())   // makes the whole row tappable
    }
}
