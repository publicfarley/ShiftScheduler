import SwiftUI

// MARK: - Shift Status Enumeration
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

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: ShiftStatus
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
                .scaleEffect(isAnimating && status == .active ? 1.2 : 1.0)
                .animation(
                    status == .active ?
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                        .none,
                    value: isAnimating
                )

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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

// MARK: - Enhanced Shift Card Component
struct EnhancedShiftCard: View {
    let shift: ScheduledShift
    let onDelete: (() -> Void)?

    @State private var isPressed = false
    @State private var showingDeleteConfirmation = false

    private var shiftStatus: ShiftStatus {
        guard let shiftType = shift.shiftType else { return .upcoming }

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
        guard let shiftType = shift.shiftType else { return .blue }

        // Create color based on shift symbol hash for consistency
        let hash = shiftType.symbol.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
        return colors[abs(hash) % colors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 16) {
                // Header section with status
                HStack {
                    StatusBadge(status: shiftStatus)
                    Spacer()

                    if let onDelete = onDelete {
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(.red.opacity(0.1))
                                        .opacity(isPressed ? 0.5 : 1.0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Main content section
                HStack(spacing: 16) {
                    // Shift symbol with animated background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .scaleEffect(isPressed ? 0.95 : 1.0)

                        if let shiftType = shift.shiftType {
                            Text(shiftType.symbol)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }
                    }

                    // Shift details
                    VStack(alignment: .leading, spacing: 8) {
                        if let shiftType = shift.shiftType {
                            // Title
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            // Time range with enhanced styling
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
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
                                    .fill(cardColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Location with icon
                            if let location = shiftType.location {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(location.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }

                    Spacer()
                }
            }
            .padding(20)

            // Optional gradient footer for visual appeal
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
        .confirmationDialog(
            "Delete Shift",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // Add haptic feedback for delete action
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
                onDelete?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this shift? This action cannot be undone.")
        }
    }
}

// MARK: - Enhanced Empty State Component
struct EnhancedEmptyState: View {
    let selectedDate: Date

    private var isToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .blue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 8) {
                Text(isToday ? "No shifts today" : "No shifts scheduled")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(isToday ?
                     "You have no shifts scheduled for today" :
                     "No shifts scheduled for \(dateFormatter.string(from: selectedDate))"
                )
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }

            // Action hint
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text("Tap \"Add Shift\" to schedule a new shift")
                        .font(.caption)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Loading State Component
struct EnhancedLoadingState: View {
    @State private var animationOffset = 0.0

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                ShimmerCardPlaceholder()
                    .opacity(1.0 - Double(index) * 0.2)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = 1.0
        }
    }
}

// MARK: - Shimmer Card Placeholder
struct ShimmerCardPlaceholder: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Status badge placeholder
                Capsule()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 80, height: 24)

                Spacer()

                // Delete button placeholder
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
            }

            HStack(spacing: 16) {
                // Symbol placeholder
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 8) {
                    // Title placeholder
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)

                    // Time placeholder
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 120, height: 16)

                    // Location placeholder
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 100, height: 14)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .shimmer(isAnimating: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerEffect: ViewModifier {
    let isAnimating: Bool
    @State private var animationOffset: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: animationOffset * UIScreen.main.bounds.width)
                    .animation(
                        isAnimating ?
                            .linear(duration: 1.5).repeatForever(autoreverses: false) :
                            .none,
                        value: animationOffset
                    )
            )
            .clipped()
            .onAppear {
                if isAnimating {
                    animationOffset = 1
                }
            }
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        modifier(ShimmerEffect(isAnimating: isAnimating))
    }
}

// MARK: - Preview Support
#Preview("Enhanced Shift Card") {
    VStack(spacing: 16) {
        // Sample shift for preview
        let sampleShift = ScheduledShift(
            eventIdentifier: "sample",
            shiftType: nil, // Would be populated with real data
            date: Date()
        )

        EnhancedShiftCard(shift: sampleShift) {
            print("Delete tapped")
        }

        EnhancedEmptyState(selectedDate: Date())

        EnhancedLoadingState()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}