//
//  ContentView.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    Text(habit.name)
                }
                .onDelete(perform: deleteHabits)
            }
            .navigationTitle("Ripple Test")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Habit") {
                        let habit = Habit(name: "Drink Water")
                        context.insert(habit)
                        try? context.save()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Update Habit") {
                        if let habit = habits.first {
                            habit.name = "Exercise"
                            try? context.save()
                        }
                    }
                }
            }
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            context.delete(habits[index])
        }
        try? context.save()
    }
}

