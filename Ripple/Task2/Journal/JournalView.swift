//
//  JournalView.swift
//  Ripple
//
//  Task 2 — Duties 2.4 and 2.5
//  Today's entry, past entries, and the optional privacy lock.
//
//  For whoever builds the app's navigation: JournalView has its own
//  NavigationStack, so use it as a tab (or sheet) rather than pushing it
//  inside another NavigationStack, e.g.
//
//      JournalView()
//          .tabItem { Label("Journal", systemImage: "book.closed") }
//

import Foundation
import SwiftUI
import SwiftData

struct JournalView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query private var preferences: [UserPreferences]

    @State private var isUnlocked = false
    @State private var lockErrorMessage: String?

    private var isLockEnabled: Bool {
        preferences.first?.journalLockEnabled == true
    }

    private var todaysEntry: JournalEntry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var pastEntries: [JournalEntry] {
        entries.filter { !Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLockEnabled && !isUnlocked {
                    JournalLockScreen { isUnlocked = true }
                } else {
                    entryList
                }
            }
            .navigationTitle("Journal")
        }
        // Lock again whenever the app goes to the background.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                isUnlocked = false
            }
        }
        .alert(
            "Journal Lock",
            isPresented: Binding(
                get: { lockErrorMessage != nil },
                set: { if !$0 { lockErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(lockErrorMessage ?? "")
        }
    }

    // MARK: - List

    private var entryList: some View {
        List {
            Section("Today") {
                NavigationLink {
                    JournalEntryEditor(day: Date())
                } label: {
                    if let todaysEntry {
                        JournalEntryRow(entry: todaysEntry)
                    } else {
                        Label("Write today's entry", systemImage: "square.and.pencil")
                    }
                }
                .accessibilityIdentifier("journal.todayRow")
            }

            Section("Past Entries") {
                if pastEntries.isEmpty {
                    Text("Your past entries will appear here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pastEntries) { entry in
                        NavigationLink {
                            JournalEntryEditor(day: entry.date)
                        } label: {
                            JournalEntryRow(entry: entry)
                        }
                    }
                    .onDelete(perform: deletePastEntries)
                }
            }

            Section {
                Toggle(
                    "Lock with \(JournalLockService.methodName)",
                    isOn: Binding(
                        get: { isLockEnabled },
                        set: { newValue in
                            Task { await setLock(newValue) }
                        }
                    )
                )
                .accessibilityIdentifier("journal.lockToggle")
            } header: {
                Text("Privacy")
            } footer: {
                Text("When on, your journal stays hidden until you unlock it.")
            }
        }
    }

    // MARK: - Actions

    private func deletePastEntries(at offsets: IndexSet) {
        let toDelete = offsets.map { pastEntries[$0] }
        for entry in toDelete {
            context.delete(entry)
        }
        try? context.save()
    }

    private func setLock(_ enabled: Bool) async {
        // Confirm the user can authenticate before turning the lock on,
        // so nobody locks themselves out.
        if enabled {
            let result = await JournalLockService.authenticate(
                reason: "Turn on the journal lock"
            )
            if case .failure(let error) = result {
                if error != .cancelled {
                    lockErrorMessage = error.message
                }
                return
            }
            isUnlocked = true
        }

        do {
            let prefs = try UserPreferencesStore.current(in: context)
            prefs.journalLockEnabled = enabled
            try context.save()
        } catch {
            lockErrorMessage = "Couldn't save the lock setting."
        }
    }
}

/// One row in the journal list.
struct JournalEntryRow: View {

    let entry: JournalEntry

    var body: some View {
        let mood = MoodRating(storedValue: entry.mood)

        HStack(alignment: .top, spacing: 12) {
            Text(mood.emoji)
                .font(.title)
                .accessibilityLabel("Mood: \(mood.label)")

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)

                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalView()
        .modelContainer(
            for: [Habit.self, HabitCompletion.self, JournalEntry.self, UserPreferences.self],
            inMemory: true
        )
}
