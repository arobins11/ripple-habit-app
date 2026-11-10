
import SwiftUI
import Charts

struct CalendarHistoryView: View {

    private let calendar = Calendar.current

    // Sample completion history for October 2026
    private let completionDays: Set<Int> = [
        1, 2, 3, 5, 6, 7, 8, 10, 11,
        12, 14, 15, 16, 18, 19, 20,
        21, 23, 24, 26, 27, 28, 29
    ]

    // Sample habit completion rates
    private let habitRates: [(name: String, rate: Int)] = [
        ("Morning walk", 90),
        ("Read 10 pages", 70),
        ("Drink water", 100),
        ("Evening stretch", 40)
    ]

    private let year = 2026
    private let month = 10

    private var monthStart: Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: 1
            )
        )!
    }

    private var daysInMonth: Int {
        calendar.range(
            of: .day,
            in: .month,
            for: monthStart
        )!.count
    }

    private var weeklyData: [ProgressDay] {
        (23...29).map { day in
            ProgressDay(
                label: "\(day)",
                completions: completionDays.contains(day) ? 1 : 0
            )
        }
    }

    private var monthlyData: [ProgressDay] {
        (1...daysInMonth).map { day in
            ProgressDay(
                label: "\(day)",
                completions: completionDays.contains(day) ? 1 : 0
            )
        }
    }

    private var calendarCells: [Int?] {
        let firstWeekday = calendar.component(
            .weekday,
            from: monthStart
        )

        let leadingSpaces = firstWeekday - 1

        return Array<Int?>(
            repeating: nil,
            count: leadingSpaces
        ) + (1...daysInMonth).map { Optional($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Screen heading
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Completion History")
                            .font(.largeTitle)
                            .bold()

                        Text("See how consistently you build your habits.")
                            .foregroundStyle(.secondary)
                    }

                    // Calendar history
                    VStack(alignment: .leading, spacing: 14) {
                        Text("October 2026")
                            .font(.title2)
                            .bold()

                        HStack {
                            ForEach(
                                Array(
                                    ["S", "M", "T", "W", "T", "F", "S"]
                                        .enumerated()
                                ),
                                id: \.offset
                            ) { _, day in
                                Text(day)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible()),
                                count: 7
                            ),
                            spacing: 10
                        ) {
                            ForEach(
                                Array(calendarCells.enumerated()),
                                id: \.offset
                            ) { _, day in
                                if let day {
                                    let completed =
                                        completionDays.contains(day)

                                    Text("\(day)")
                                        .font(.subheadline)
                                        .fontWeight(
                                            completed ? .bold : .regular
                                        )
                                        .foregroundStyle(
                                            completed ? .white : .primary
                                        )
                                        .frame(
                                            maxWidth: .infinity,
                                            minHeight: 36
                                        )
                                        .background(
                                            completed
                                                ? Color.green
                                                : Color.gray.opacity(0.12)
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 9)
                                        )
                                } else {
                                    Color.clear
                                        .frame(height: 36)
                                }
                            }
                        }

                        Label(
                            "Completed habit day",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Weekly chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Progress")
                            .font(.title2)
                            .bold()

                        Text("Completed days from October 23–29")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Chart(weeklyData) { item in
                            BarMark(
                                x: .value("Day", item.label),
                                y: .value(
                                    "Completed",
                                    item.completions
                                )
                            )
                            .foregroundStyle(.green)
                            .cornerRadius(5)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Monthly chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Progress")
                            .font(.title2)
                            .bold()

                        Text("Completed days in October")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Chart(monthlyData) { item in
                            BarMark(
                                x: .value("Date", item.label),
                                y: .value(
                                    "Completed",
                                    item.completions
                                )
                            )
                            .foregroundStyle(.blue)
                            .cornerRadius(3)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: 5))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 200)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Habit completion rates
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Habit Consistency")
                            .font(.title2)
                            .bold()

                        Text("Sample completion rates")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(habitRates, id: \.name) { habit in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(habit.name)
                                        .fontWeight(.medium)

                                    Spacer()

                                    Text("\(habit.rate)%")
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }

                                ProgressView(
                                    value: Double(habit.rate),
                                    total: 100
                                )
                                .tint(
                                    habit.rate >= 80 ? .green :
                                    habit.rate >= 60 ? .orange : .red
                                )
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text(
                        "Sample data only. Saved completion history " +
                        "will be connected when the group data model is available."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct ProgressDay: Identifiable {
    let id = UUID()
    let label: String
    let completions: Int
}

