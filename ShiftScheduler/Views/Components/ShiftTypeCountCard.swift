import SwiftUI

struct ShiftTypeCountCard: View {
    let shiftType: ShiftType
    let count: Int
    let scheduledShifts: [ScheduledShift]

    @State private var isPressed = false

    private var cardColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    private var daysWithShifts: String {
        let dayNames = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        let calendar = Calendar.current
        var daysSet = Set<Int>()

        for shift in scheduledShifts.filter({ $0.shiftType?.id == shiftType.id }) {
            let weekday = calendar.component(.weekday, from: shift.date)
            // weekday: 1 = Sunday, 2 = Monday, etc.
            daysSet.insert(weekday)
        }

        // Get today's weekday (1 = Sunday, 2 = Monday, etc.)
        let todayWeekday = calendar.component(.weekday, from: Date())

        // Sort days starting from today, wrapping around the week
        let sortedDays = daysSet.sorted { day1, day2 in
            let distance1 = (day1 - todayWeekday + 7) % 7
            let distance2 = (day2 - todayWeekday + 7) % 7
            return distance1 < distance2
        }

        let displayDays = sortedDays.map { dayIndex -> String in
            let adjustedIndex = dayIndex == 1 ? 6 : dayIndex - 2
            return dayNames[adjustedIndex]
        }

        return displayDays.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: 4) {
            // Top row: Symbol and Title
            HStack(spacing: 6) {
                // Symbol in smaller colored circle
                Text(shiftType.symbol)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        cardColor.opacity(0.15),
                                        cardColor.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(cardColor.opacity(0.3), lineWidth: 1)
                            )
                    )

                // Shift Title
                Text(shiftType.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }

            // Count Display - Compact, aligned with symbol
            HStack(spacing: 6) {
                // Spacer to align number with symbol (32pt frame)
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(cardColor)
                    .frame(width: 32, alignment: .center)

                Text(count == 1 ? "shift" : "shifts")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Progress Indicator and Day indicators combined
            if count > 0 {
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    cardColor.opacity(0.6),
                                    cardColor.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .cornerRadius(1)

                    // Day indicators
                    Text(daysWithShifts)
                        .font(.body)
                        .bold()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: 115, height: 73)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    cardColor.opacity(0.3),
                                    cardColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: cardColor.opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: isPressed
        )
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shiftType.title), \(count) \(count == 1 ? "shift" : "shifts") scheduled")
        .accessibilityHint("Double tap to view these shifts in the schedule")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    let shiftType = ShiftType(
        id: UUID(),
        symbol: "🌅",
        duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Morning Shift",
        description: "Standard morning shift",
        location: Location(
            id: UUID(),
            name: "Main Office",
            address: "123 Main St"
        )
    )

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let shifts = [
        ScheduledShift(id: UUID(), eventIdentifier: UUID().uuidString, shiftType: shiftType, date: today),
        ScheduledShift(id: UUID(), eventIdentifier: UUID().uuidString, shiftType: shiftType, date: calendar.date(byAdding: .day, value: 1, to: today)!),
        ScheduledShift(id: UUID(), eventIdentifier: UUID().uuidString, shiftType: shiftType, date: calendar.date(byAdding: .day, value: 2, to: today)!),
        ScheduledShift(id: UUID(), eventIdentifier: UUID().uuidString, shiftType: shiftType, date: calendar.date(byAdding: .day, value: 5, to: today)!),
        ScheduledShift(id: UUID(), eventIdentifier: UUID().uuidString, shiftType: shiftType, date: calendar.date(byAdding: .day, value: 6, to: today)!)
    ]

    ShiftTypeCountCard(
        shiftType: shiftType,
        count: 5,
        scheduledShifts: shifts
    )
}
