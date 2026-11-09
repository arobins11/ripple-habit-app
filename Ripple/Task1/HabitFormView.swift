//
//  HabitFormView.swift
//  Ripple
//
//  Task 1 — Duty 1.2 (add / edit / delete) and Duty 1.3 (habit settings):
//  name, routine, icon, frequency (daily or specific weekdays) and reminder.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
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

    // The form edits copies of the habit's values; nothing is saved until Save.
    @State private var name: String
    @State private var routine: Routine
    @State private var icon: String
    @State private var repeatsDaily: Bool
    @State private var weekdays: Set<Int>
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date

    @State private var notificationsBlocked = false
    @State private var confirmingDelete = false

    init(habit: Habit?, defaultRoutine: Routine = .current, onDelete: (() -> Void)? = nil) {
        self.habit = habit
        self.onDelete = onDelete
        _name = State(initialValue: habit?.name ?? "")
        _routine = State(initialValue: habit.map { Routine(savedValue: $0.routine) } ?? defaultRoutine)
        _icon = State(initialValue: habit?.icon ?? "leaf")
        _repeatsDaily = State(initialValue: habit.map { $0.frequency != HabitFrequency.specificWeekdays } ?? true)
        _weekdays = State(initialValue: Set(habit?.weekdays ?? []))
        _reminderEnabled = State(initialValue: habit?.reminderEnabled ?? false)
        _reminderTime = State(initialValue: Self.time(hour: habit?.reminderHour ?? 9,
                                                      minute: habit?.reminderMinute ?? 0))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEditing: Bool { habit != nil }

    /// A habit needs a name, and a weekday habit needs at least one day.
    private var canSave: Bool {
        !trimmedName.isEmpty
            && trimmedName.count <= Self.maxNameLength
            && (repeatsDaily || !weekdays.isEmpty)
    }

    /// Keeps the habit's current icon in the grid even if it isn't a default option
    /// (for example, a starter habit from onboarding).
    private var iconOptions: [String] {
        let defaults = IconPicker.defaultOptions
        if let current = habit?.icon, !defaults.contains(current) {
            return [current] + defaults
        }
        return defaults
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                routineSection
                repeatSection
                reminderSection
                iconSection

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
                        .disabled(!canSave)
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
                .accessibilityIdentifier("confirmDeleteHabitButton")
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("e.g. Drink a glass of water", text: $name)
                .accessibilityIdentifier("habitNameField")
        } header: {
            Text("Habit name")
        } footer: {
            // Input validation: names must not be empty or longer than the limit.
            // (Cutting the text off while typing isn't reliable in iOS text fields,
            // so the form explains the limit and disables Save instead.)
            if trimmedName.isEmpty {
                Text("A habit needs a name before it can be saved.")
            } else if trimmedName.count > Self.maxNameLength {
                Text("Names can be up to \(Self.maxNameLength) characters. This one has \(trimmedName.count).")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("nameTooLongMessage")
            }
        }
    }

    private var routineSection: some View {
        Section("Routine") {
            Picker("Routine", selection: $routine) {
                ForEach(Routine.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("routinePicker")
        }
    }

    private var repeatSection: some View {
        Section {
            Picker("Repeat", selection: $repeatsDaily) {
                Text("Every day").tag(true)
                Text("Specific days").tag(false)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("frequencyPicker")

            if !repeatsDaily {
                WeekdayPicker(selection: $weekdays)
            }
        } header: {
            Text("Repeat")
        } footer: {
            if !repeatsDaily && weekdays.isEmpty {
                Text("Pick at least one day.")
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Remind me", isOn: $reminderEnabled)
                .accessibilityIdentifier("reminderToggle")
                .onChange(of: reminderEnabled) { _, isOn in
                    guard isOn else { return }
                    askForNotificationPermission()
                }

            if reminderEnabled {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .accessibilityIdentifier("reminderTimePicker")
            }
        } header: {
            Text("Reminder")
        } footer: {
            if notificationsBlocked {
                Text("Notifications are turned off for Ripple. You can turn them on in the Settings app.")
            } else if reminderEnabled && !repeatsDaily {
                Text("You'll only be reminded on the days you picked.")
            }
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            IconPicker(selection: $icon, options: iconOptions)
        }
    }

    // MARK: - Actions

    /// Asks iOS for notification permission the first time a reminder is turned on.
    /// If the user says no (now or earlier), the toggle switches back off.
    private func askForNotificationPermission() {
        Task {
            let granted = (try? await NotificationService.shared.requestPermission()) ?? false
            if !granted {
                reminderEnabled = false
                notificationsBlocked = true
            } else {
                notificationsBlocked = false
            }
        }
    }

    private func save() {
        guard canSave else { return }   // never save an empty name or a weekday habit with no days

        let savedHabit: Habit
        if let habit {
            // Moving to a different routine puts the habit at the end of that routine.
            if Routine(savedValue: habit.routine) != routine {
                habit.sortOrder = context.nextSortOrder(for: routine)
            }
            savedHabit = habit
        } else {
            savedHabit = Habit(name: trimmedName, sortOrder: context.nextSortOrder(for: routine))
            context.insert(savedHabit)
        }

        apply(to: savedHabit)
        try? context.save()

        // Task 4's NotificationService clears the old reminders first, then
        // schedules new ones only if the reminder is on (and only on picked weekdays).
        Task {
            try? await NotificationService.shared.scheduleReminder(for: savedHabit)
        }

        dismiss()
    }

    /// Copies the form's values onto the habit.
    private func apply(to habit: Habit) {
        habit.name = trimmedName
        habit.routine = routine.rawValue
        habit.icon = icon
        habit.frequency = repeatsDaily ? HabitFrequency.daily : HabitFrequency.specificWeekdays
        habit.weekdays = repeatsDaily ? [] : weekdays.sorted()
        habit.reminderEnabled = reminderEnabled

        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        habit.reminderHour = time.hour ?? 9
        habit.reminderMinute = time.minute ?? 0
    }

    /// Today's date at the given time, for the time picker.
    private static func time(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
