
import SwiftUI

struct HabitProgressView: View {
    // Sample data for testing.
    // We will connect this to saved habit history later.
    private let currentStreak = 7
    private let bestStreak = 14
    private let completedHabits = 24
    private let weeklyGoal = 30

    private let recentProgress: [(day: String, completed: Int)] = [
        ("Fri", 3),
        ("Sat", 4),
        ("Sun", 2),
        ("Mon", 5),
        ("Tue", 3),
        ("Wed", 4),
        ("Thu", 3)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Your Progress")
                        .font(.largeTitle)
                        .bold()

                    Text("Every small step counts.")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        statCard(
                            title: "Current Streak",
                            value: "\(currentStreak)",
                            symbol: "flame.fill",
                            color: .orange
                        )

                        statCard(
                            title: "Best Streak",
                            value: "\(bestStreak)",
                            symbol: "trophy.fill",
                            color: .yellow
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            "Completed Habits",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.headline)

                        Text("\(completedHabits)")
                            .font(.system(size: 38, weight: .bold))

                        Text("This week's sample total")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ProgressView(
                            value: Double(completedHabits),
                            total: Double(weeklyGoal)
                        )
                        .tint(.green)

                        Text("\(completedHabits) of \(weeklyGoal) weekly completions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent Progress")
                            .font(.title2)
                            .bold()

                        ForEach(recentProgress, id: \.day) { item in
                            HStack {
                                Text(item.day)
                                    .frame(width: 45, alignment: .leading)

                                HStack(spacing: 3) {
                                    ForEach(0..<item.completed, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(.green)
                                            .frame(height: 12)
                                    }
                                }

                                Text("\(item.completed)")
                                    .fontWeight(.semibold)
                                    .frame(width: 25)
                            }
                        }

                        Text("Sample completions per day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private func statCard(
        title: String,
        value: String,
        symbol: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 32, weight: .bold))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

