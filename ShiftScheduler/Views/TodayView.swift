import SwiftUI

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
    @Environment(\.reduxStore) var store
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Animation Constants
    private let todayCardAnimationDuration: Double = 0.6
    private let tomorrowCardAnimationDelay: Double = 0.2
    private let tomorrowCardAnimationDuration: Double = 0.6

    var body: some View {
        NavigationView {
            VStack {
                if !store.state.isCalendarAuthorized && store.state.isCalendarAuthorizationVerified {
                    // Calendar Authorization Required
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.red)

                        Text("Calendar Access Required")
                            .font(.headline)

                        Text("ShiftScheduler needs calendar access to function properly.")
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
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 20, pinnedViews: []) {
                            // Today Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)

                                        Text(Date(), style: .date)
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if store.state.today.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }

                                // Display today's shift
                                let todayShifts = store.state.today.scheduledShifts.filter { shift in
                                    Calendar.current.isDate(shift.date, inSameDayAs: Date())
                                }

                                if let shift = todayShifts.first {
                                    VStack(spacing: 12) {
                                        UnifiedShiftCard(shift: shift, onTap: nil)

                                        Button(action: {
                                            store.dispatch(action: .today(.switchShiftTapped(shift)))
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                Text("Switch Shift")
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }
                                    }
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)

                                        VStack(spacing: 4) {
                                            Text("No shift scheduled")
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            Text("Perfect day for rest")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
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
                            .padding(.horizontal, 16)
                            .padding(.top)
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .opacity
                                    )
                            )
                            .animation(
                                reduceMotion
                                    ? .easeInOut(duration: 0.1)
                                    : .easeOut(duration: todayCardAnimationDuration),
                                value: store.state.today.scheduledShifts
                            )

                            // Tomorrow Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)

                                    Text("Tomorrow")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }

                                // Display tomorrow's shift
                                let tomorrowShifts = store.state.today.scheduledShifts.filter { shift in
                                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                    return Calendar.current.isDate(shift.date, inSameDayAs: tomorrow)
                                }

                                UnifiedShiftCard(shift: tomorrowShifts.first, onTap: nil)
                            }
                            .padding(.horizontal, 16)
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity
                                    )
                            )
                            .animation(
                                reduceMotion
                                    ? .easeInOut(duration: 0.1)
                                    : .easeOut(duration: tomorrowCardAnimationDuration).delay(tomorrowCardAnimationDelay),
                                value: store.state.today.scheduledShifts
                            )

                            // Week Summary Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("This Week")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)

                                let weekShifts = store.state.today.scheduledShifts.filter { shift in
                                    let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                                    let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()
                                    return shift.date >= startOfWeek && shift.date <= endOfWeek
                                }

                                HStack(spacing: 12) {
                                    CompactWeekStatView(
                                        count: weekShifts.count,
                                        label: "Scheduled",
                                        color: .blue,
                                        icon: "calendar"
                                    )
                                    CompactWeekStatView(
                                        count: 0,
                                        label: "Completed",
                                        color: .green,
                                        icon: "checkmark.circle.fill"
                                    )
                                }
                                .padding(.horizontal, 16)
                            }

                            Spacer(minLength: 100)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .navigationTitle("Today")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
            .sheet(isPresented: .constant(store.state.today.showSwitchShiftSheet)) {
                if let shift = store.state.today.selectedShift {
                    ShiftChangeSheet(currentShift: shift, feature: .today)
                }
            }
            .onAppear {
                store.dispatch(action: .today(.task))
            }
        }
    }
}
// MARK: - Enhanced Today Shift Card with Visual Prominence
struct EnhancedTodayShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false
    @State private var pulseOpacity = 0.3

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

        let hash = shiftType.symbol.hashValue
        let vibrantColors: [Color] = [
            Color(red: 0.1, green: 0.5, blue: 0.8),   // Vibrant Blue
            Color(red: 0.2, green: 0.7, blue: 0.5),   // Emerald Green
            Color(red: 0.8, green: 0.4, blue: 0.2),   // Warm Orange
            Color(red: 0.6, green: 0.3, blue: 0.8),   // Purple
            Color(red: 0.8, green: 0.3, blue: 0.5),   // Magenta
            Color(red: 0.3, green: 0.7, blue: 0.7)    // Teal
        ]
        return vibrantColors[abs(hash) % vibrantColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Enhanced design with gradients and prominence
                VStack(alignment: .leading, spacing: 16) {
                    // Status badge with enhanced styling
                    HStack {
                        EnhancedStatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content with enhanced layout
                    HStack(spacing: 16) {
                        // Enhanced symbol with gradient background
                        Text(shiftType.symbol)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [cardColor, cardColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.2), lineWidth: 2)
                                    )
                                    .shadow(color: cardColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            )

                        // Enhanced shift details
                        VStack(alignment: .leading, spacing: 8) {
                            Text(shiftType.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            // Enhanced time badge
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)

                                Text(shiftType.timeRangeString)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(cardColor)
                                    .shadow(color: cardColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            )

                            // Enhanced location
                            let location = shiftType.location
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(cardColor)
                                Text(location.name)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(20)

                // Enhanced active indicator with pulse animation
                if shiftStatus == .active {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [cardColor, cardColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseOpacity = 0.8
                            }
                        }
                }
            } else {
                // Enhanced empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "calendar.badge.plus")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 6) {
                        Text("No shift scheduled")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Perfect day for rest or planning ahead")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: shift != nil ? [cardColor.opacity(0.3), cardColor.opacity(0.1)] : [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: shift != nil ? cardColor.opacity(0.15) : .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try await Task.sleep(nanoseconds: 0.15.nanoseconds)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Enhanced Status Badge
struct EnhancedStatusBadge: View {
    let status: ShiftStatus
    @State private var glowOpacity = 0.3

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .shadow(color: status.color.opacity(glowOpacity), radius: 4, x: 0, y: 0)
                .onAppear {
                    if status == .active {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            glowOpacity = 0.8
                        }
                    }
                }

            Text(status.displayName)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
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

// MARK: - Enhanced Tomorrow Shift Card with Visual Prominence
struct EnhancedTomorrowShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.3, green: 0.4, blue: 0.7) }

        let hash = shiftType.symbol.hashValue
        let elegantColors: [Color] = [
            Color(red: 0.3, green: 0.4, blue: 0.7),   // Elegant Blue
            Color(red: 0.3, green: 0.6, blue: 0.5),   // Sophisticated Green
            Color(red: 0.7, green: 0.5, blue: 0.3),   // Warm Amber
            Color(red: 0.5, green: 0.3, blue: 0.7),   // Rich Purple
            Color(red: 0.7, green: 0.3, blue: 0.5),   // Rose
            Color(red: 0.3, green: 0.6, blue: 0.6)    // Turquoise
        ]
        return elegantColors[abs(hash) % elegantColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Enhanced design with modern visual effects
                VStack(alignment: .leading, spacing: 14) {
                    // Tomorrow badge with enhanced styling
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.white)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .indigo.opacity(0.3), radius: 4, x: 0, y: 2)
                        )

                        Spacer()
                    }

                    // Main content with enhanced layout
                    HStack(spacing: 14) {
                        // Enhanced symbol with sophisticated design
                        Text(shiftType.symbol)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [cardColor, cardColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.15), lineWidth: 1)
                                    )
                                    .shadow(color: cardColor.opacity(0.3), radius: 6, x: 0, y: 3)
                            )

                        // Enhanced shift details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            // Enhanced time display
                            HStack(spacing: 5) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.25), lineWidth: 1)
                                    )
                            )

                            // Enhanced location
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(location.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(18)
            } else {
                // Enhanced empty state for tomorrow
                VStack(spacing: 14) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.white)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .indigo.opacity(0.3), radius: 4, x: 0, y: 2)
                        )

                        Spacer()
                    }

                    HStack(spacing: 14) {
                        // Enhanced empty state icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(.systemGray5), Color(.systemGray6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "bed.double.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("No shift scheduled")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("A well-deserved day off awaits")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(18)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: shift != nil ? [cardColor.opacity(0.25), cardColor.opacity(0.1)] : [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: shift != nil ? cardColor.opacity(0.1) : .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // Subtle shimmer effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60)
                .offset(x: shimmerOffset)
                .clipped()
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                        shimmerOffset = 400
                    }
                }
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
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
                            let location = shiftType.location
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

// MARK: - Optimized Card Components for Better Performance

struct OptimizedTodayShiftCard: View {
    let shift: ScheduledShift?

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
                VStack(alignment: .leading, spacing: 12) {
                    // Status badge
                    HStack {
                        StatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content
                    HStack(spacing: 14) {
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
                                .frame(width: 50, height: 50)

                            Text(shiftType.symbol)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }

                        // Shift details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Time range with enhanced styling
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.caption2)
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
                                    .fill(cardColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Location with icon
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(location.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if !shiftType.location.address.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Shift description
                            if !shiftType.shiftDescription.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.alignleft")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.shiftDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)

                // Active shift indicator
                if shiftStatus == .active {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 6) {
                        Text("No shift scheduled")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Perfect day for rest or planning ahead")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct OptimizedTomorrowShiftCard: View {
    let shift: ScheduledShift?

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
                VStack(spacing: 12) {
                    // Tomorrow label
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.indigo.opacity(0.1))
                        )

                        Spacer()
                    }

                    // Main content
                    HStack(spacing: 14) {
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
                                .frame(width: 50, height: 50)

                            Text(shiftType.symbol)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }

                        // Shift details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Time range with enhanced styling
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.caption2)
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
                                    .fill(cardColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Location with icon
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(location.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if !shiftType.location.address.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Shift description
                            if !shiftType.shiftDescription.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.alignleft")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.shiftDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)
            } else {
                // Empty state
                VStack(spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.indigo.opacity(0.1))
                        )

                        Spacer()
                    }

                    HStack(spacing: 14) {
                        // Empty state icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(.systemGray5), Color(.systemGray6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "bed.double.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("No shift scheduled")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("A well-deserved day off awaits")
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
                        .stroke(cardColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct OptimizedWeekStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            // Icon
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
        )
    }
}

struct OptimizedQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon - simple and clean
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
            .frame(maxWidth: .infinity, minHeight: 85)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Components for Reduced Screen Real Estate

struct CompactQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(color.opacity(0.08))
                    )

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactWeekStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.08))
                )

            VStack(spacing: 1) {
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if count > 0 {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}

