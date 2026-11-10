//
//  HabitCompletionCheckmark.swift
//  Ripple
//
//  Task 2 — Duty 2.3
//  The habit-completion animation for Task 1 (Duty 1.4).
//
//  FOR TASK 1 — use it in one line wherever the checkbox goes:
//
//      HabitCompletionCheckmark(isComplete: isDoneToday)
//
//  It shows an empty circle or a filled checkmark, and plays the
//  completion animation once each time `isComplete` changes to true.
//  It is display-only: keep your own Button / onTapGesture around it
//  to actually mark the habit complete or undo it.
//

import Foundation
import SwiftUI

struct HabitCompletionCheckmark: View {

    let isComplete: Bool
    var size: CGFloat = 28

    @State private var isCelebrating = false

    var body: some View {
        ZStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: size))
                .foregroundStyle(isComplete ? Color.accentColor : Color.secondary)
                .contentTransition(.symbolEffect(.replace))

            if isCelebrating {
                RippleLottieView(
                    name: "habit_complete",
                    loops: false,
                    fallbackSymbol: "sparkle",
                    onFinished: { isCelebrating = false }
                )
                .frame(width: size * 2.4, height: size * 2.4)
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isComplete) { _, nowComplete in
            isCelebrating = nowComplete
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isComplete ? "Completed" : "Not completed")
    }
}

private struct HabitCompletionCheckmarkDemo: View {
    @State private var done = false

    var body: some View {
        Button { done.toggle() } label: {
            HabitCompletionCheckmark(isComplete: done)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HabitCompletionCheckmarkDemo()
}
