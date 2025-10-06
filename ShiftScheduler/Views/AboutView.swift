
import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "AboutView")

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?
}

struct AboutView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var calendarService = CalendarService.shared
    @State private var alertItem: AlertItem?

    // Animation states
    @State private var titleAppeared = false
    @State private var creatorAppeared = false
    @State private var roleAppeared = false
    @State private var descriptionAppeared = false
    @State private var buttonAppeared = false
    @State private var isPressed = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for top breathing room
                    Spacer()
                        .frame(height: 5)

                    // Animated app icon with particles
                    ZStack {
                        // Background particles
                        ParticleEffect(
                            particleCount: 12,
                            particleSize: 10,
                            animationDuration: 3.0,
                            color: .cyan.opacity(0.6)
                        )
                        .frame(width: 200, height: 200)

                        AnimatedAppIcon(size: 120) {
                            logger.debug("App icon tapped")
                        }
                    }
                    .padding(.bottom, 30)

                    // App name with staggered animation
                    Text("WorkEvents")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: titleAppeared ? 0 : 30)
                        .opacity(titleAppeared ? 1 : 0)
                        .padding(.bottom, 20)

                    // Creator card with glass effect
                    GlassCard(cornerRadius: 20, blurMaterial: .ultraThinMaterial) {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                SparkleIcon()

                                Text("Created by Farley Caesar")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                SparkleIcon()
                            }
                            .frame(maxWidth: .infinity)

                            Text("Developer")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .offset(y: roleAppeared ? 0 : 20)
                                .opacity(roleAppeared ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: creatorAppeared ? 0 : 30)
                    .opacity(creatorAppeared ? 1 : 0)
                    .padding(.bottom, 24)

                    // Description card with glass effect
                    GlassCard(cornerRadius: 20, blurMaterial: .regularMaterial) {
                        VStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(.cyan)
                                Text("Schedule Management")
                                    .font(.headline)
                            }

                            Text("Streamline your work schedule management with intuitive shift tracking and calendar integration")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)

                            HStack(spacing: 20) {
                                FeatureBadge(icon: "clock.fill", text: "Time Tracking")
                                FeatureBadge(icon: "calendar", text: "Calendar Sync")
                                FeatureBadge(icon: "bell.fill", text: "Reminders")
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: descriptionAppeared ? 0 : 30)
                    .opacity(descriptionAppeared ? 1 : 0)
                    .padding(.bottom, 40)

                    // Delete button with glass effect and press animation
                    Button(action: {
                        self.alertItem = AlertItem(
                            title: Text("Are you sure?"),
                            message: Text("This will permanently delete all data."),
                            primaryButton: .destructive(Text("Delete")) {
                                self.deleteAllData()
                            },
                            secondaryButton: .cancel()
                        )
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete All Data")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                }
                        }
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .offset(y: buttonAppeared ? 0 : 30)
                    .opacity(buttonAppeared ? 1 : 0)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard !UIAccessibility.isReduceMotionEnabled else { return }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPressed = true
                                }
                            }
                            .onEnded { _ in
                                guard !UIAccessibility.isReduceMotionEnabled else { return }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPressed = false
                                }
                            }
                    )
                    .padding(.bottom, 50)

                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
            .alert(item: $alertItem) { alertItem in
                if let secondaryButton = alertItem.secondaryButton {
                    return Alert(title: alertItem.title, message: alertItem.message, primaryButton: alertItem.primaryButton, secondaryButton: secondaryButton)
                } else {
                    return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.primaryButton)
                }
            }
            .onAppear {
                triggerStaggeredAnimations()
            }
        }
    }

    private func triggerStaggeredAnimations() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            // Immediately show all elements if reduced motion is enabled
            titleAppeared = true
            creatorAppeared = true
            roleAppeared = true
            descriptionAppeared = true
            buttonAppeared = true
            return
        }

        // Stagger animations with spring effects
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            titleAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            creatorAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            roleAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            descriptionAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
            buttonAppeared = true
        }
    }

    private func deleteAllData() {
        logger.debug("Delete all data requested")
        Task {
            do {
                // Delete all calendar events (shifts)
                if calendarService.isAuthorized {
                    let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
                    let endDate = Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date()
                    let shifts = try await calendarService.fetchShifts(from: startDate, to: endDate)

                    logger.debug("Deleting \(shifts.count) shifts from calendar")
                    for shift in shifts {
                        try await calendarService.deleteShift(withIdentifier: shift.eventIdentifier)
                    }
                }

                // Delete SwiftData models
                logger.debug("Deleting SwiftData models")
                try modelContext.delete(model: ShiftType.self)
                try modelContext.delete(model: Location.self)

                await MainActor.run {
                    logger.debug("All data deleted successfully")
                    self.alertItem = AlertItem(title: Text("Success"), message: Text("All data has been deleted successfully."), primaryButton: .default(Text("OK")), secondaryButton: nil)
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to delete all data: \(error.localizedDescription)")
                    self.alertItem = AlertItem(title: Text("Error"), message: Text("Failed to delete all data: \(error.localizedDescription)"), primaryButton: .default(Text("OK")), secondaryButton: nil)
                }
            }
        }
    }
}

// MARK: - Feature Badge Component

struct FeatureBadge: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .cyan.opacity(0.2), radius: 4, x: 0, y: 2)
                }

            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sparkle Icon Component

struct SparkleIcon: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .foregroundStyle(.yellow)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                guard !UIAccessibility.isReduceMotionEnabled else { return }

                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                }

                withAnimation(
                    .linear(duration: 3.0)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
