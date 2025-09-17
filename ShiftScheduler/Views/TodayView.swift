import SwiftUI
import SwiftData

// MARK: - Shift Status Enumeration (shared with EnhancedShiftCard)
enum ShiftStatus {
    case upcoming
    case active
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }

    var icon: String {
        switch self {
        case .upcoming: return "clock"
        case .active: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Status Badge Component (shared with EnhancedShiftCard)
struct StatusBadge: View {
    let status: ShiftStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.08))
        )
    }
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @StateObject private var calendarService = CalendarService.shared
    @State private var scheduledShifts: [ScheduledShift] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var todayShift: ScheduledShift? {
        scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: Date())
        }
    }

    private var tomorrowShift: ScheduledShift? {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: tomorrow)
        }
    }

    private var thisWeekShifts: [ScheduledShift] {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()

        return scheduledShifts.filter { shift in
            shift.date >= startOfWeek && shift.date <= endOfWeek
        }
    }

    private var completedThisWeek: Int {
        // For now, return 0 as we don't have a completion tracking system yet
        0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !calendarService.isAuthorized {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.red)

                            Text("Calendar Access Required")
                                .font(.headline)

                            Text(calendarService.authorizationError ?? "ShiftScheduler needs calendar access to function properly.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)

                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        // Today Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(Date(), style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }

                            if let errorMessage = errorMessage {
                                Text("Error: \(errorMessage)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }

                            TodayShiftCard(shift: todayShift)
                        }
                        .padding(.horizontal)

                        // Quick Actions Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Spacer()

                                if todayShift != nil {
                                    // Status indicator for quick actions
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 6, height: 6)

                                        Text("Available")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            if todayShift != nil {
                                // Enhanced quick actions when there's a shift
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        EnhancedQuickActionButton(
                                            title: "Clock In",
                                            icon: "clock",
                                            color: .green,
                                            action: {}
                                        )
                                        EnhancedQuickActionButton(
                                            title: "Break",
                                            icon: "pause.circle",
                                            color: .orange,
                                            action: {}
                                        )
                                        EnhancedQuickActionButton(
                                            title: "Clock Out",
                                            icon: "clock.badge.checkmark",
                                            color: .red,
                                            action: {}
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                // Professional empty state for quick actions
                                VStack(spacing: 8) {
                                    Image(systemName: "bolt.slash")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(Color(.systemGray6))
                                        )

                                    VStack(spacing: 4) {
                                        Text("No quick actions available")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("Actions available during active shifts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray5), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Upcoming Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tomorrow")
                                .font(.title3)
                                .fontWeight(.semibold)

                            TomorrowShiftCard(shift: tomorrowShift)
                        }
                        .padding(.horizontal)

                        // This Week Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("This Week")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Spacer()

                                // Week progress indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.checkmark")
                                        .font(.caption2)
                                        .foregroundColor(.blue)

                                    Text("Week \(Calendar.current.component(.weekOfYear, from: Date()))")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.blue.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(.blue.opacity(0.25), lineWidth: 1)
                                        )
                                )
                            }

                            HStack(spacing: 16) {
                                EnhancedWeekStatView(
                                    count: thisWeekShifts.count,
                                    label: "Scheduled",
                                    color: .blue,
                                    icon: "calendar"
                                )
                                EnhancedWeekStatView(
                                    count: completedThisWeek,
                                    label: "Completed",
                                    color: .green,
                                    icon: "checkmark.circle.fill"
                                )
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadShifts()
            }
        }
    }

    private func loadShifts() {
        guard calendarService.isAuthorized else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()

                let shiftData = try await calendarService.fetchShifts(from: startOfWeek, to: endOfWeek)
                let shifts = shiftData.map { data in
                    let shiftType = shiftTypes.first { $0.id == data.shiftTypeId }
                    return ScheduledShift(from: data, shiftType: shiftType)
                }

                await MainActor.run {
                    self.scheduledShifts = shifts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct TodayShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false

    private var shiftStatus: ShiftStatus {
        guard let shift = shift, let shiftType = shift.shiftType else { return .upcoming }

        let now = Date()
        let calendar = Calendar.current

        // Check if shift is today
        if calendar.isDate(shift.date, inSameDayAs: now) {
            switch shiftType.duration {
            case .allDay:
                return .active
            case .scheduled(let startTime, let endTime):
                let shiftStart = startTime.toDate(on: shift.date)
                let shiftEnd = endTime.toDate(on: shift.date)

                if now < shiftStart {
                    return .upcoming
                } else if now >= shiftStart && now <= shiftEnd {
                    return .active
                } else {
                    return .completed
                }
            }
        } else if shift.date < now {
            return .completed
        } else {
            return .upcoming
        }
    }

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.2, green: 0.35, blue: 0.5) }

        // Use professional, muted color palette
        let hash = shiftType.symbol.hashValue
        let professionalColors: [Color] = [
            Color(red: 0.2, green: 0.35, blue: 0.5),   // Professional Blue
            Color(red: 0.25, green: 0.4, blue: 0.35),  // Forest Green
            Color(red: 0.4, green: 0.35, blue: 0.3),   // Warm Brown
            Color(red: 0.35, green: 0.3, blue: 0.4),   // Slate Purple
            Color(red: 0.4, green: 0.3, blue: 0.35),   // Muted Burgundy
            Color(red: 0.3, green: 0.4, blue: 0.4)     // Teal
        ]
        return professionalColors[abs(hash) % professionalColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Has shift scheduled - Enhanced design
                VStack(alignment: .leading, spacing: 12) {
                    // Status badge - simplified
                    HStack {
                        StatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content - cleaner, more professional layout
                    HStack(spacing: 14) {
                        // Symbol - simple circle without gradient
                        Text(shiftType.symbol)
                            .font(.title2)
                            .foregroundColor(cardColor)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(cardColor.opacity(0.15), lineWidth: 1)
                                    )
                            )

                        // Shift details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Add missing description
                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            // Time - simplified badge
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.08))
                            )

                            // Location
                            if let location = shiftType.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(location.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)

                // Active shift indicator - subtle
                if shiftStatus == .active {
                    Rectangle()
                        .fill(cardColor.opacity(0.3))
                        .frame(height: 2)
                }
            } else {
                // No shift scheduled - Professional empty state
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )

                    VStack(spacing: 4) {
                        Text("No shift scheduled")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Add shifts in the Schedule tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

struct EnhancedQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon - simple and professional
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.08))
                    )

                // Title
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 85, height: 85)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = pressing
            }
        }, perform: {})
        .simultaneousGesture(
            TapGesture().onEnded {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                action()
            }
        )
    }
}

struct TomorrowShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.2, green: 0.35, blue: 0.5) }

        // Use professional, muted color palette
        let hash = shiftType.symbol.hashValue
        let professionalColors: [Color] = [
            Color(red: 0.2, green: 0.35, blue: 0.5),   // Professional Blue
            Color(red: 0.25, green: 0.4, blue: 0.35),  // Forest Green
            Color(red: 0.4, green: 0.35, blue: 0.3),   // Warm Brown
            Color(red: 0.35, green: 0.3, blue: 0.4),   // Slate Purple
            Color(red: 0.4, green: 0.3, blue: 0.35),   // Muted Burgundy
            Color(red: 0.3, green: 0.4, blue: 0.4)     // Teal
        ]
        return professionalColors[abs(hash) % professionalColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Has shift scheduled - Compact but elegant design for tomorrow
                VStack(spacing: 12) {
                    // Tomorrow label
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                        )

                        Spacer()
                    }

                    // Main content - compact professional layout
                    HStack(spacing: 12) {
                        // Symbol - simple design
                        Text(shiftType.symbol)
                            .font(.title3)
                            .foregroundColor(cardColor)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(cardColor.opacity(0.15), lineWidth: 1)
                                    )
                            )

                        // Shift details - compact layout
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shiftType.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            // Add missing description for tomorrow
                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            // Time - simple text
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }

                            // Location if available
                            if let location = shiftType.location {
                                HStack(spacing: 3) {
                                    Image(systemName: "location")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(location.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)
            } else {
                // No shift scheduled - Clean minimal state
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                        )

                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // Empty state icon - professional
                        Image(systemName: "moon.stars")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("No shift scheduled")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text("Another day off to look forward to")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

struct WeekStatView: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct EnhancedWeekStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            // Icon - simple professional design
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.08))
                )

            // Count and label
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Simple progress indicator
            if count > 0 {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}