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
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: status.icon)
                .font(.caption2)
                .foregroundColor(status.color)
                .scaleEffect(isAnimating && status == .active ? 1.2 : 1.0)
                .animation(
                    status == .active ?
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                        .none,
                    value: isAnimating
                )

            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            if status == .active {
                isAnimating = true
            }
        }
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
                                // Enhanced empty state for quick actions
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.gray.opacity(0.1), .gray.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)

                                        Image(systemName: "bolt.slash.fill")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }

                                    VStack(spacing: 4) {
                                        Text("No quick actions available")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("Quick actions are available when you have a shift scheduled")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.gray.opacity(0.2), lineWidth: 1)
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
        guard let shiftType = shift?.shiftType else { return .blue }

        // Create color based on shift symbol hash for consistency
        let hash = shiftType.symbol.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
        return colors[abs(hash) % colors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Has shift scheduled - Enhanced design
                VStack(spacing: 16) {
                    // Status badge for today's shift
                    HStack {
                        StatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content with enhanced styling
                    HStack(spacing: 16) {
                        // Symbol with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .scaleEffect(isPressed ? 0.95 : 1.0)

                            Text(shiftType.symbol)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }

                        // Shift details
                        VStack(alignment: .leading, spacing: 8) {
                            Text(shiftType.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            // Time with icon and styling
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Location with enhanced styling
                            if let location = shiftType.location {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(location.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(20)

                // Active shift indicator
                if shiftStatus == .active {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [cardColor.opacity(0.4), cardColor.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                }
            } else {
                // No shift scheduled - Enhanced empty state
                VStack(spacing: 16) {
                    // Animated icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.15), .blue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)

                        Text("😴")
                            .font(.system(size: 32))
                    }

                    VStack(spacing: 8) {
                        Text("No shift scheduled")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Enjoy your day off!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Call to action hint
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)

                            Text("Schedule shifts in the Schedule tab")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.blue.opacity(0.1))
                        )
                    }
                }
                .padding(24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(shift?.shiftType != nil ? cardColor.opacity(0.2) : .blue.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
            VStack(spacing: 10) {
                // Icon with enhanced background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .scaleEffect(isPressed ? 0.95 : 1.0)

                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }

                // Title with enhanced styling
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(width: 90, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
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
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
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
        guard let shiftType = shift?.shiftType else { return .orange }

        // Create color based on shift symbol hash for consistency
        let hash = shiftType.symbol.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
        return colors[abs(hash) % colors.count]
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

                    // Main content - more compact layout
                    HStack(spacing: 12) {
                        // Symbol with background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .scaleEffect(isPressed ? 0.95 : 1.0)

                            Text(shiftType.symbol)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }

                        // Shift details - compact layout
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shiftType.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            // Time badge
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.25), lineWidth: 1)
                                    )
                            )

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
                        // Empty state icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.gray.opacity(0.15), .gray.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Text("😊")
                                .font(.title3)
                        }

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
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(shift?.shiftType != nil ? cardColor.opacity(0.2) : .gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
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
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .scaleEffect(isPressed ? 0.95 : 1.0)

                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            // Count with enhanced styling
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            // Progress indicator (if needed)
            if count > 0 {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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

#Preview {
    TodayView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}