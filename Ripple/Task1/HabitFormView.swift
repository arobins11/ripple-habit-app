//
//  HabitFormView.swift
//  Ripple
//
//  Task 1 — Duty 1.2 (add / edit / delete) and the start of Duty 1.3
//  (routine picker). Frequency, weekdays, icon and reminder come in 1.3.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): "Build Task 1 piece 1 for our Ripple habit app —
//  a Today screen with morning/afternoon/evening routines and add/edit/delete,
//  saved with our team's existing SwiftData Habit model."
//  AI-generated: this entire file.
//

import SwiftUI
import SwiftData

struct HabitFormView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = adding a new habit, otherwise editing this one.
    let habit: Habit?

    /// Called when the user deletes the habit from this form.
    /// The Today screen does the actual delete after the sheet closes,
    /// so this form never reads a habit that no longer exists.
    var onDelete: (() -> Void)? = nil

    static let maxNameLength = 60

    @State private var name: String
    @State private var routine: Routine
    @State private var confirmingDelete = false

    init(habit: Habit?, defaultRoutine: Routine = .current, onDelete: (() -> Void)? = nil) {
        self.habit = habit
        self.onDelete = onDelete
        _name = State(initialValue: habit?.name ?? "")
        _routine = State(initialValue: habit.map { Routine(savedValue: $0.routine) } ?? defaultRoutine)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEditing: Bool { habit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Drink a glass of water", text: $name)
                        .accessibilityIdentifier("habitNameField")
                        .onChange(of: name) { _, newValue in
                            // Input validation: cap very long names.
                            if newValue.count > Self.maxNameLength {
                                name = String(newValue.prefix(Self.maxNameLength))
                            }
                        }
                } header: {
                    Text("Habit name")
                } footer: {
                    if trimmedName.isEmpty {
                        Text("A habit needs a name before it can be saved.")
                    }
                }

                Section("Routine") {
                    Picker("Routine", selection: $routine) {
                        ForEach(Routine.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("routinePicker")
                }

                if isEditing {
                    Section {
                        Button("Delete Habit", role: .destructive) {
                            confirmingDelete = true
                        }
                        .accessibilityIdentifier("deleteHabitButton")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty)
                        .accessibilityIdentifier("saveHabitButton")
                }
            }
            .confirmationDialog(
                "Delete this habit and its history?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Habit", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            }
        }
    }

    private func save() {
        let cleanName = trimmedName
        guard !cleanName.isEmpty else { return }   // never save an empty name

        if let habit {
            // Moving to a different routine puts the habit at the end of that routine.
            if Routine(savedValue: habit.routine) != routine {
                habit.sortOrder = context.nextSortOrder(for: routine)
            }
            habit.name = cleanName
            habit.routine = routine.rawValue
        } else {
            let newHabit = Habit(
                name: cleanName,
                routine: routine.rawValue,
                sortOrder: context.nextSortOrder(for: routine)
            )
            context.insert(newHabit)
        }

        try? context.save()
        dismiss()
    }
}
