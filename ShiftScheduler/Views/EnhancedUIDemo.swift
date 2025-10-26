import SwiftUI

// MARK: - Enhanced UI Components Demo
struct EnhancedUIDemo: View {
    @State private var selectedDemo = 0

    var body: some View {
        NavigationView {
            VStack {
                Picker("Demo", selection: $selectedDemo) {
                    Text("Cards").tag(0)
                    Text("States").tag(1)
                    Text("Animations").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                switch selectedDemo {
                case 0:
                    CardDemoView()
                case 1:
                    StatesDemoView()
                case 2:
                    AnimationsDemoView()
                default:
                    CardDemoView()
                }
            }
            .navigationTitle("Enhanced UI Demo")
        }
    }
}

// MARK: - Card Demonstrations
struct CardDemoView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Group {
                    // Sample Morning Shift
                    EnhancedShiftCard(
                        shift: createSampleShift(
                            symbol: "☀️",
                            title: "Morning Shift",
                            startHour: 8,
                            endHour: 16,
                            locationName: "Main Office"
                        ),
                        onDelete: {
                            print("Delete morning shift")
                        },
                        onSwitch: {
                            print("Switch morning shift")
                        }
                    )

                    // Sample Evening Shift
                    EnhancedShiftCard(
                        shift: createSampleShift(
                            symbol: "🌙",
                            title: "Evening Shift",
                            startHour: 16,
                            endHour: 24,
                            locationName: "Downtown Branch"
                        ),
                        onDelete: {
                            print("Delete evening shift")
                        },
                        onSwitch: {
                            print("Switch evening shift")
                        }
                    )

                    // Sample All-Day Shift
                    EnhancedShiftCard(
                        shift: createSampleAllDayShift(
                            symbol: "📱",
                            title: "On-Call",
                            locationName: "Remote"
                        ),
                        onDelete: {
                            print("Delete on-call shift")
                        },
                        onSwitch: {
                            print("Switch on-call shift")
                        }
                    )

                    // Sample Weekend Shift
                    EnhancedShiftCard(
                        shift: createSampleShift(
                            symbol: "🏖️",
                            title: "Weekend Coverage",
                            startHour: 10,
                            endHour: 18,
                            locationName: "Beach Office",
                            daysAgo: 2
                        ),
                        onDelete: {
                            print("Delete weekend shift")
                        },
                        onSwitch: {
                            print("Switch weekend shift")
                        }
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - States Demonstration
struct StatesDemoView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Group {
                    // Status Badges
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status Badges")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack {
                            StatusBadge(status: .upcoming)
                            StatusBadge(status: .active)
                            StatusBadge(status: .completed)
                            StatusBadge(status: .cancelled)
                        }
                        .padding(.horizontal)
                    }

                    // Empty State
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Empty State")
                            .font(.headline)
                            .padding(.horizontal)

                        EnhancedEmptyState(selectedDate: Date())
                            .padding(.horizontal)
                    }

                    // Error State
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Error State")
                            .font(.headline)
                            .padding(.horizontal)

                        ErrorStateView(message: "Unable to load shifts. Please check your internet connection and try again.")
                            .padding(.horizontal)
                    }

                    // Loading State
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Loading State")
                            .font(.headline)
                            .padding(.horizontal)

                        EnhancedLoadingState()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Animations Demonstration
struct AnimationsDemoView: View {
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Interactive Card Animation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interactive Card")
                        .font(.headline)
                        .padding(.horizontal)

                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            scale = 0.95
                        }

                        Task {
                            try await Task.sleep(nanoseconds: 0.1.nanoseconds)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scale = 1.0
                            }
                        }
                    }) {
                        VStack(spacing: 16) {
                            HStack {
                                StatusBadge(status: .active)
                                Spacer()
                            }

                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)

                                    Text("🎯")
                                        .font(.title2)
                                        .rotationEffect(.degrees(rotation))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Interactive Demo")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text("Tap to see animations")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
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
                                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(scale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .onAppear {
                        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                }

                // Shimmer Effect Demo
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shimmer Loading Effect")
                        .font(.headline)
                        .padding(.horizontal)

                    ShimmerCardPlaceholder()
                        .padding(.horizontal)
                }

                // Color Demonstration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dynamic Colors")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach([("🏥", "Hospital"), ("🏢", "Office"), ("🏠", "Home"), ("🚗", "Mobile"), ("🏫", "School"), ("🏪", "Store")], id: \.0) { symbol, name in
                            VStack(spacing: 8) {
                                let hash = symbol.hashValue
                                let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
                                let color = colors[abs(hash) % colors.count]

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [color.opacity(0.2), color.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(symbol)
                                            .font(.title3)
                                    )

                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Helper Functions
private func createSampleShift(
    symbol: String,
    title: String,
    startHour: Int,
    endHour: Int,
    locationName: String,
    daysAgo: Int = 0
) -> ScheduledShift {
    // Create sample location
    let location = Location(
        id: UUID(),
        name: locationName,
        address: "\(locationName) Address"
    )

    // Create sample shift type
    let shiftType = ShiftType(
        symbol: symbol,
        duration: .scheduled(
            from: HourMinuteTime(hour: startHour, minute: 0),
            to: HourMinuteTime(hour: endHour, minute: 0)
        ),
        title: title,
        description: "Sample \(title.lowercased())",
        location: location
    )

    // Create scheduled shift
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return ScheduledShift(
        eventIdentifier: "sample-\(UUID().uuidString)",
        shiftType: shiftType,
        date: date
    )
}

private func createSampleAllDayShift(
    symbol: String,
    title: String,
    locationName: String,
    daysAgo: Int = 0
) -> ScheduledShift {
    // Create sample location
    let location = Location(
        id: UUID(),
        name: locationName,
        address: "\(locationName) Address"
    )

    // Create sample shift type
    let shiftType = ShiftType(
        symbol: symbol,
        duration: .allDay,
        title: title,
        description: "Sample \(title.lowercased())",
        location: location
    )

    // Create scheduled shift
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return ScheduledShift(
        eventIdentifier: "sample-\(UUID().uuidString)",
        shiftType: shiftType,
        date: date
    )
}

// MARK: - Preview
#Preview {
    EnhancedUIDemo()
}