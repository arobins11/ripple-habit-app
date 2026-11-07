//
//  TodayView.swift
//  Ripple
//
//  Task 1 — Duty 1.1 (Today screen), 1.2 (add/edit/delete), 1.3 (reorder),
//  1.4 (routines + daily completion), 1.5 (saved data)
//  Shows today's quote and the user's habits grouped into routines,
//  with a checkbox to complete or undo each habit.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): Used our Group 3 proposal and Ripple
//  task sheet to help plan the file structure and build
//  these files for our Ripple habit tracker app.
//  AI-generated: this entire file.
//

import SwiftUI
import SwiftData

struct TodayView: View {

    @Environment(\.modelContext) private var context

    /// Every saved habit, in the user's order. SwiftData keeps this up to date.
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    /// Saved completion history (Task 4's HabitCompletion model).
    @Query private var completions: [HabitCompletion]

    @State private var quote: Quote?
    @State private var showingAddForm = false
    @State private var habitBeingEdited: Habit?
    @State private var habitToDeleteAfterSheet: Habit?

    /// The routine that was just finished, shown in a short banner.
    @State private var finishedRoutine: Routine?

    var body: some View {
        let today = Date()
        let doneToday = completedHabitIDs(on: today)

        NavigationStack {
            List {
                quoteSection

                ForEach(Routine.allCases) { routine in
                    routineSection(routine, today: today, doneToday: doneToday)
                }

                notScheduledSection(today: today)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Edit mode shows drag handles to reorder habits (and delete buttons).
                    EditButton()
                        .accessibilityIdentifier("editHabitsButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                    .accessibilityIdentifier("addHabitButton")
                }
            }
            .sheet(isPresented: $showingAddForm) {
                HabitFormView(habit: nil)
            }
            .sheet(item: $habitBeingEdited, onDismiss: finishPendingDelete) { habit in
                HabitFormView(habit: habit) {
                    habitToDeleteAfterSheet = habit
                }
            }
            .overlay(alignment: .bottom) {
                if let finishedRoutine {
                    routineCompleteBanner(finishedRoutine)
                }
            }
            .animation(.spring(duration: 0.4), value: finishedRoutine)
            .task {
                // Task 4's QuoteService: cached for the day, fallback quote if offline.
                quote = await QuoteService.shared.getDailyQuote()
            }
            .task(id: finishedRoutine) {
                // Hide the banner after a moment.
                guard finishedRoutine != nil else { return }
                try? await Task.sleep(for: .seconds(2.5))
                finishedRoutine = nil
            }
        }
    }

    // MARK: - Sections

    private var quoteSection: some View {
        Section {
            if let quote {
                VStack(alignment: .leading, spacing: 6) {
                    Text("“\(quote.text)”")
                        .italic()
                    Text("— \(quote.author)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .accessibilityIdentifier("dailyQuote")
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        } header: {
            // Today's date, e.g. "Wednesday, November 4"
            // Made by Anthony Robinson II
            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day().year())
        }
    }

    @ViewBuilder
    private func routineSection(_ routine: Routine, today: Date, doneToday: Set<UUID>) -> some View {
        let todaysHabits = habitsIn(routine).filter { $0.isScheduled(on: today) }
        let doneCount = todaysHabits.filter { doneToday.contains($0.id) }.count

        Section {
            if todaysHabits.isEmpty {
                Text("No \(routine.rawValue.lowercased()) habits today")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todaysHabits) { habit in
                    let isDone = doneToday.contains(habit.id)

                    HStack(spacing: 12) {
                        // Checkbox: complete or undo.
                        Button {
                            toggle(habit, routine: routine, routineHabits: todaysHabits,
                                   doneToday: doneToday, today: today)
                        } label: {
                            CompletionCheckbox(isComplete: isDone)
                        }
                        .buttonStyle(.borderless)
                        .sensoryFeedback(.selection, trigger: isDone)
                        .accessibilityLabel(isDone ? "Undo \(habit.name)" : "Complete \(habit.name)")
                        .accessibilityIdentifier("checkbox-\(habit.name)")

                        // Rest of the row: open the edit form.
                        Button {
                            habitBeingEdited = habit
                        } label: {
                            HabitRow(habit: habit, isComplete: isDone)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.deleteHabitCompletely(todaysHabits[index])
                    }
                }
                .onMove { source, destination in
                    reorder(routine, visibleHabits: todaysHabits, from: source, to: destination)
                }
            }
        } header: {
            HStack {
                Label(routine.rawValue, systemImage: routine.symbol)
                Spacer()
                if !todaysHabits.isEmpty {
                    if doneCount == todaysHabits.count {
                        Label("Done", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("\(doneCount) of \(todaysHabits.count)")
                    }
                }
            }
        }
    }

    /// Weekday habits that aren't due today, so they can still be edited.
    @ViewBuilder
    private func notScheduledSection(today: Date) -> some View {
        let otherDayHabits = habits.filter { !$0.isScheduled(on: today) }

        if !otherDayHabits.isEmpty {
            Section {
                ForEach(otherDayHabits) { habit in
                    Button {
                        habitBeingEdited = habit
                    } label: {
                        HabitRow(habit: habit)
                            .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Not scheduled today")
            } footer: {
                Text("These habits only appear on the days you picked.")
            }
        }
    }

    private func routineCompleteBanner(_ routine: Routine) -> some View {
        // TASK 3: swap this for CelebrationView (confetti) once it's ready.
        Label("\(routine.rawValue) routine complete!", systemImage: "party.popper.fill")
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: Capsule())
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityIdentifier("routineCompleteBanner")
    }

    // MARK: - Actions

    private func toggle(_ habit: Habit, routine: Routine, routineHabits: [Habit],
                        doneToday: Set<UUID>, today: Date) {
        let isNowComplete = context.toggleCompletion(for: habit, on: today)
        guard isNowComplete else { return }   // undo never celebrates

        // Was this the last unchecked habit in the routine?
        let routineFinished = routineHabits.allSatisfy {
            $0.id == habit.id || doneToday.contains($0.id)
        }
        if routineFinished {
            finishedRoutine = routine
        }
    }

    /// Saves the new order after the user drags a habit within a routine.
    /// Habits not scheduled today keep their place at the end of the routine.
    private func reorder(_ routine: Routine, visibleHabits: [Habit],
                         from source: IndexSet, to destination: Int) {
        var newOrder = visibleHabits
        newOrder.move(fromOffsets: source, toOffset: destination)

        let visibleIDs = Set(visibleHabits.map(\.id))
        let hiddenToday = habitsIn(routine).filter { !visibleIDs.contains($0.id) }

        context.saveOrder(newOrder + hiddenToday)
    }

    // MARK: - Helpers

    private func habitsIn(_ routine: Routine) -> [Habit] {
        habits.filter { Routine(savedValue: $0.routine) == routine }
    }

    /// IDs of the habits completed on the given day.
    private func completedHabitIDs(on date: Date) -> Set<UUID> {
        let calendar = Calendar.current
        return Set(
            completions
                .filter { calendar.isDate($0.completedAt, inSameDayAs: date) }
                .map(\.habitID)
        )
    }

    /// Deletes a habit chosen from the edit form, once that form has closed.
    private func finishPendingDelete() {
        if let habit = habitToDeleteAfterSheet {
            context.deleteHabitCompletely(habit)
            habitToDeleteAfterSheet = nil
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
