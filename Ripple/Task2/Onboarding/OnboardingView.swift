//
//  OnboardingView.swift
//  Ripple
//
//  Task 2 — Duties 2.1 and 2.2
//  Welcome → focus area → starter habits → reminder time.
//

import Foundation
import SwiftUI
import SwiftData

/// The screens pushed after the welcome screen.
enum OnboardingStep: Hashable {
    case focusArea
    case starterHabits
    case reminders
}

struct OnboardingView: View {

    @Environment(\.modelContext) private var context

    @State private var path: [OnboardingStep] = []
    @State private var focusArea: FocusArea?
    @State private var selectedHabitNames: Set<String> = []
    @State private var remindersEnabled = true
    @State private var reminderTime = OnboardingView.defaultReminderTime
    @State private var isSaving = false
    @State private var errorMessage: String?

    /// Called after everything has been saved.
    var onFinished: () -> Void = {}

    var body: some View {
        NavigationStack(path: $path) {
            welcomeScreen
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .focusArea: focusAreaScreen
                    case .starterHabits: starterHabitsScreen
                    case .reminders: remindersScreen
                    }
                }
        }
        .alert(
            "Couldn't save your choices",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            RippleLottieView(
                name: "onboarding_welcome",
                loops: true,
                fallbackSymbol: "drop.circle.fill"
            )
            .frame(width: 220, height: 220)
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Welcome to Ripple")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("onboarding.welcomeTitle")

                Text("Small habits make big waves. Let's set Ripple up for you.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            primaryButton("Continue", identifier: "onboarding.continue") {
                path.append(.focusArea)
            }
        }
        .padding(24)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Focus area

    private var focusAreaScreen: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you want to work on?")
                        .font(.title2.bold())
                        .padding(.bottom, 4)

                    ForEach(FocusArea.allCases) { area in
                        focusAreaCard(area)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }

            primaryButton("Continue", identifier: "onboarding.focusContinue") {
                path.append(.starterHabits)
            }
            .disabled(focusArea == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Your Focus")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func focusAreaCard(_ area: FocusArea) -> some View {
        let isSelected = focusArea == area

        return Button {
            focusArea = area
            // Pre-select all starter habits for the chosen area.
            selectedHabitNames = Set(area.starterHabits.map(\.name))
        } label: {
            HStack(spacing: 16) {
                Image(systemName: area.icon)
                    .font(.title2)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(area.title)
                        .font(.headline)
                    Text(area.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.focus.\(area.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Starter habits

    private var starterHabitsScreen: some View {
        VStack(spacing: 16) {
            List {
                Section {
                    ForEach(focusArea?.starterHabits ?? []) { habit in
                        Toggle(isOn: binding(forHabit: habit.name)) {
                            Label {
                                VStack(alignment: .leading) {
                                    Text(habit.name)
                                    Text(habit.routine)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: habit.icon)
                            }
                        }
                        .accessibilityIdentifier("onboarding.habit.\(habit.name)")
                    }
                } header: {
                    Text("Suggested for \(focusArea?.title ?? "you")")
                } footer: {
                    Text("You can add, edit or remove habits any time later.")
                }
            }

            primaryButton("Continue", identifier: "onboarding.habitsContinue") {
                path.append(.reminders)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Starter Habits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(forHabit name: String) -> Binding<Bool> {
        Binding(
            get: { selectedHabitNames.contains(name) },
            set: { isOn in
                if isOn {
                    selectedHabitNames.insert(name)
                } else {
                    selectedHabitNames.remove(name)
                }
            }
        )
    }

    // MARK: - Reminders

    private var remindersScreen: some View {
        VStack(spacing: 16) {
            Form {
                Section {
                    Toggle("Remind me", isOn: $remindersEnabled)
                        .accessibilityIdentifier("onboarding.remindersToggle")

                    if remindersEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .accessibilityIdentifier("onboarding.reminderTime")
                    }
                } header: {
                    Text("When should we remind you?")
                } footer: {
                    Text("Ripple will send a daily reminder for your starter habits at this time. You can change it for each habit later.")
                }
            }

            primaryButton(
                isSaving ? "Saving…" : "Finish",
                identifier: "onboarding.finish",
                action: finish
            )
            .disabled(isSaving)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Saving

    private func finish() {
        guard let focusArea else {
            path = [.focusArea]
            return
        }

        isSaving = true

        let chosenHabits = focusArea.starterHabits.filter {
            selectedHabitNames.contains($0.name)
        }
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        do {
            let newHabits = try OnboardingSaver.save(
                focusArea: focusArea,
                starterHabits: chosenHabits,
                remindersEnabled: remindersEnabled,
                reminderHour: time.hour ?? 9,
                reminderMinute: time.minute ?? 0,
                in: context
            )

            Task {
                await OnboardingSaver.scheduleReminders(for: newHabits)
            }

            isSaving = false
            onFinished()
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func primaryButton(
        _ title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityIdentifier(identifier)
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(
            bySettingHour: 9, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(
            for: [Habit.self, HabitCompletion.self, JournalEntry.self, UserPreferences.self],
            inMemory: true
        )
}
