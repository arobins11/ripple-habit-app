//
//  HabitSettingsControls.swift
//  Ripple
//
//  Task 1 — Duty 1.3
//  The weekday picker and SF Symbols icon picker used in the habit form.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import SwiftUI

/// Seven round buttons (S M T W T F S) for picking which days a habit repeats.
/// Uses Calendar weekday numbers: 1 = Sunday … 7 = Saturday,
/// the same numbers NotificationService schedules reminders with.
struct WeekdayPicker: View {

    @Binding var selection: Set<Int>

    private let letters = Calendar.current.veryShortWeekdaySymbols   // S, M, T, ...
    private let fullNames = Calendar.current.weekdaySymbols          // Sunday, Monday, ...

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { day in
                let isOn = selection.contains(day)

                Button {
                    if isOn {
                        selection.remove(day)
                    } else {
                        selection.insert(day)
                    }
                } label: {
                    Text(letters[day - 1])
                        .font(.subheadline.bold())
                        .frame(width: 36, height: 36)
                        .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15),
                                    in: Circle())
                        .foregroundStyle(isOn ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(fullNames[day - 1])
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("weekday-\(day)")
            }
        }
        .padding(.vertical, 4)
    }
}

/// A grid of SF Symbols to choose a habit's icon.
struct IconPicker: View {

    @Binding var selection: String
    let options: [String]

    /// Icons offered for every habit.
    static let defaultOptions = [
        "leaf", "drop.fill", "figure.walk", "dumbbell.fill",
        "bed.double.fill", "moon.zzz.fill", "sun.max.fill", "cup.and.saucer.fill",
        "fork.knife", "book.fill", "pencil", "brain.head.profile",
        "heart.fill", "pills.fill", "music.note", "iphone.slash"
    ]

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { name in
                let isOn = name == selection

                Button {
                    selection = name
                } label: {
                    Image(systemName: name)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .foregroundStyle(isOn ? Color.accentColor : Color.primary)
                        .background(isOn ? Color.accentColor.opacity(0.15) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isOn ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
