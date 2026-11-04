//
//  TodayView.swift
//  Ripple
//
//  Task 1 — Duty 1.1 (Today screen), 1.2 (add/edit/delete), 1.5 (saved data)
//  Shows today's quote and the user's habits grouped into routines.
//
//  AI USE: Written with Claude (Anthropic), model Claude Opus 5.5.
//  Prompt (paraphrased): "Build Task 1 piece 1 for our Ripple habit app —
//  a Today screen with morning/afternoon/evening routines and add/edit/delete,
//  saved with our team's existing SwiftData Habit model."
//  AI-generated: this entire file.
//

import SwiftUI
import SwiftData

struct TodayView: View {

    @Environment(\.modelContext) private var context

    /// Every saved habit, in the user's order. SwiftData keeps this up to date.
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var quote: Quote?
    @State private var showingAddForm = false
    @State private var habitBeingEdited: Habit?
    @State private var habitToDeleteAfterSheet: Habit?

    var body: some View {
        NavigationStack {
            List {
                quoteSection

                ForEach(Routine.allCases) { routine in
                    routineSection(routine)
                }
            }
            .navigationTitle("Today")
            .toolbar {
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
            .task {
                // Task 4's QuoteService: cached for the day, fallback quote if offline.
                quote = await QuoteService.shared.getDailyQuote()
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
            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
        }
    }

    @ViewBuilder
    private func routineSection(_ routine: Routine) -> some View {
        let habitsInRoutine = habitsIn(routine)

        Section {
            if habitsInRoutine.isEmpty {
                Text("No \(routine.rawValue.lowercased()) habits yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(habitsInRoutine) { habit in
                    Button {
                        habitBeingEdited = habit
                    } label: {
                        HabitRow(habit: habit)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.deleteHabitCompletely(habitsInRoutine[index])
                    }
                }
            }
        } header: {
            Label(routine.rawValue, systemImage: routine.symbol)
        }
    }

    // MARK: - Helpers

    private func habitsIn(_ routine: Routine) -> [Habit] {
        habits.filter { Routine(savedValue: $0.routine) == routine }
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
