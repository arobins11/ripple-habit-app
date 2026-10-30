//
//  JournalStore.swift
//  Ripple
//
//  Task 2 — Duty 2.4
//  Saving and loading journal entries with Task 4's JournalEntry model.
//  There is one entry per day: saving again on the same day updates it.
//

import Foundation
import SwiftData

/// The 1–5 mood scale stored in `JournalEntry.mood`.
enum MoodRating: Int, CaseIterable, Identifiable {
    case awful = 1
    case bad = 2
    case okay = 3
    case good = 4
    case great = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .awful: "😞"
        case .bad: "🙁"
        case .okay: "😐"
        case .good: "🙂"
        case .great: "😄"
        }
    }

    var label: String {
        switch self {
        case .awful: "Awful"
        case .bad: "Bad"
        case .okay: "Okay"
        case .good: "Good"
        case .great: "Great"
        }
    }

    /// Turns any stored Int into a valid rating (out-of-range → nearest).
    init(storedValue: Int) {
        let clamped = min(max(storedValue, 1), 5)
        self = MoodRating(rawValue: clamped) ?? .okay
    }
}

enum JournalStore {

    /// The entry written on the same calendar day as `day`, if any.
    static func entry(
        on day: Date,
        in context: ModelContext,
        calendar: Calendar = .current
    ) throws -> JournalEntry? {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return nil
        }

        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= start && entry.date < end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    /// Creates or updates the entry for `day`.
    @discardableResult
    static func save(
        content: String,
        mood: Int,
        on day: Date = Date(),
        in context: ModelContext,
        calendar: Calendar = .current
    ) throws -> JournalEntry {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeMood = MoodRating(storedValue: mood).rawValue

        let entry: JournalEntry
        if let existing = try self.entry(on: day, in: context, calendar: calendar) {
            existing.content = text
            existing.mood = safeMood
            entry = existing
        } else {
            entry = JournalEntry(date: day, content: text, mood: safeMood)
            context.insert(entry)
        }

        try context.save()
        return entry
    }
}
