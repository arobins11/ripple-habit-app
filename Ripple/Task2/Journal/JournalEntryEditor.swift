//
//  JournalEntryEditor.swift
//  Ripple
//
//  Task 2 — Duty 2.4
//  Write the entry for one day and pick a mood.
//

import Foundation
import SwiftUI
import SwiftData

struct JournalEntryEditor: View {

    /// The day this entry belongs to.
    let day: Date

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var mood: MoodRating = .okay
    @State private var didLoad = false
    @State private var errorMessage: String?

    @FocusState private var isEditorFocused: Bool

    var body: some View {
        Form {
            Section("How are you feeling?") {
                MoodPicker(selection: $mood)
            }

            Section("Your thoughts") {
                TextEditor(text: $text)
                    .frame(minHeight: 200)
                    .focused($isEditorFocused)
                    .accessibilityIdentifier("journal.editor")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(Text(day, format: .dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .accessibilityIdentifier("journal.save")
            }
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") { isEditorFocused = false }
                }
            }
        }
        .onAppear(perform: loadExisting)
    }

    private func loadExisting() {
        guard !didLoad else { return }
        didLoad = true

        if let existing = try? JournalStore.entry(on: day, in: context) {
            text = existing.content
            mood = MoodRating(storedValue: existing.mood)
        }
    }

    private func save() {
        do {
            try JournalStore.save(
                content: text,
                mood: mood.rawValue,
                on: day,
                in: context
            )
            dismiss()
        } catch {
            errorMessage = "Couldn't save your entry. Please try again."
        }
    }
}

/// A row of five mood buttons (1 = awful … 5 = great).
struct MoodPicker: View {

    @Binding var selection: MoodRating

    var body: some View {
        HStack {
            ForEach(MoodRating.allCases) { mood in
                Button {
                    selection = mood
                } label: {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: 32))
                            .scaleEffect(selection == mood ? 1.2 : 1)
                        Text(mood.label)
                            .font(.caption2)
                            .foregroundStyle(selection == mood ? Color.primary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selection == mood ? Color.accentColor.opacity(0.15) : .clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.label)
                .accessibilityAddTraits(selection == mood ? .isSelected : [])
                .accessibilityIdentifier("journal.mood.\(mood.rawValue)")
            }
        }
        .animation(.spring(response: 0.3), value: selection)
    }
}
