import SwiftUI

// MARK: - Today View

struct TodayView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Animation Constants
    private let todayCardAnimationDuration: Double = 0.6
    private let tomorrowCardAnimationDelay: Double = 0.2
    private let tomorrowCardAnimationDuration: Double = 0.6

    // MARK: - Animation State
    @State private var todayCardOffset: CGFloat = -400
    @State private var todayCardOpacity: Double = 0
    @State private var tomorrowCardOffset: CGFloat = 400
    @State private var tomorrowCardOpacity: Double = 0
    @State private var cardOffsets: [Int: CGFloat] = [:]
    @State private var cardOpacities: [Int: Double] = [:]

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
                        VStack(spacing: 0) {
                            // Today Section - Primary Card
                            SectionCard(accentColor: .orange, prominence: .primary) {
                                TodayShiftSection(
                                    cardOffset: $todayCardOffset,
                                    cardOpacity: $todayCardOpacity
                                )
                            }
                            .padding(.horizontal, 16)

                            // Spacing between major sections
                            Spacer().frame(height: 12)

                            // Tomorrow Section - Secondary Card
                            SectionCard(accentColor: .indigo, prominence: .secondary) {
                                TomorrowShiftSection()
                            }
                            .padding(.horizontal, 16)
                            .offset(x: tomorrowCardOffset)
                            .opacity(tomorrowCardOpacity)

                            // Spacing between major sections
                            Spacer().frame(height: 12)

                            // Week Summary Section - Tertiary Card
                            if !store.state.today.isLoading {
                                SectionCard(accentColor: .blue, prominence: .tertiary) {
                                    WeekSummarySection(
                                        cardOffsets: $cardOffsets,
                                        cardOpacities: $cardOpacities
                                    )
                                }
                                .padding(.horizontal, 16)
                            }

                            Spacer(minLength: 100)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .navigationTitle("Today")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(
                isPresented: .constant(store.state.today.showSwitchShiftSheet),
                onDismiss: {
                    Task {
                        await store.dispatch(action: .today(.switchShiftSheetDismissed))
                    }
                }
            ) {
                if let shift = store.state.today.selectedShift {
                    ShiftChangeSheet(currentShift: shift, feature: .today)
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { store.state.today.showAddShiftSheet },
                    set: { _ in }
                ),
                onDismiss: {
                    Task {
                        await store.dispatch(action: .today(.addShiftSheetDismissed))
                    }
                }
            ) {
                AddShiftModalView(
                    isPresented: Binding(
                        get: { store.state.today.showAddShiftSheet },
                        set: { _ in }
                    ),
                    availableShiftTypes: store.state.shiftTypes.shiftTypes,
                    preselectedDate: Date(),
                    currentError: store.state.today.currentError,
                    onAddShift: { date, shiftType, notes in
                        await store.dispatch(action: .today(.addShift(date: date, shiftType: shiftType, notes: notes)))
                    },
                    onDismissError: {
                        await store.dispatch(action: .today(.dismissError))
                    },
                    onCancel: {
                        Task {
                            await store.dispatch(action: .today(.addShiftSheetDismissed))
                        }
                    }
                )
            }
            .sheet(
                isPresented: .constant(store.state.schedule.showOverlapResolution),
                onDismiss: {
                    Task {
                        await store.dispatch(action: .schedule(.overlapResolutionDismissed))
                    }
                }
            ) {
                if let date = store.state.schedule.overlapDate,
                   !store.state.schedule.overlappingShifts.isEmpty {
                    OverlapResolutionSheet(
                        date: date,
                        overlappingShifts: store.state.schedule.overlappingShifts
                    )
                    .environment(\.reduxStore, store)
                }
            }
            .sheet(
                isPresented: .constant(store.state.schedule.showShiftDetail),
                onDismiss: {
                    Task {
                        await store.dispatch(action: .schedule(.shiftDetailDismissed))
                    }
                }
            ) {
                if let shift = store.state.schedule.selectedShiftForDetail {
                    ShiftDetailsView(initialShiftId: shift.id)
                        .environment(\.reduxStore, store)
                }
            }
            .task {
                await store.dispatch(action: .today(.loadShifts))

                todayCardOffset = -400
                todayCardOpacity = 0
                tomorrowCardOffset = 400
                tomorrowCardOpacity = 0

                try? await Task.sleep(seconds: 0.05)

                if !reduceMotion {
                    withAnimation(.spring(response: todayCardAnimationDuration, dampingFraction: 0.7, blendDuration: 0)) {
                        todayCardOffset = 0
                        todayCardOpacity = 1
                    }
                } else {
                    todayCardOffset = 0
                    todayCardOpacity = 1
                }

                try? await Task.sleep(seconds: tomorrowCardAnimationDelay)

                if !reduceMotion {
                    withAnimation(.spring(response: tomorrowCardAnimationDuration, dampingFraction: 0.7, blendDuration: 0)) {
                        tomorrowCardOffset = 0
                        tomorrowCardOpacity = 1
                    }
                } else {
                    tomorrowCardOffset = 0
                    tomorrowCardOpacity = 1
                }
            }
        }
    }
}

// MARK: - Today Shift Section

private struct TodayShiftSection: View {
    @Environment(\.reduxStore) var store
    @Binding var cardOffset: CGFloat
    @Binding var cardOpacity: Double

    var body: some View {
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

            let todayShifts = store.state.today.scheduledShifts.filter { shift in
                shift.startsOn(date: Date())
            }

            if !todayShifts.isEmpty {
                ZStack(alignment: .top) {
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 200)

                        Divider()
                            .padding(.vertical, 4)

                        if let firstShift = todayShifts.first {
                            QuickActionsView(shift: firstShift)
                        }
                    }

                    VStack {
                        MultiShiftCarousel(shifts: todayShifts)
                            .frame(minHeight: 200)
                        Spacer()
                    }
                    .zIndex(1)
                }
                .offset(x: cardOffset)
                .opacity(cardOpacity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        Text("No shift scheduled")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Add today's shift or enjoy your day off")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        Task {
                            await store.dispatch(action: .today(.addShiftButtonTapped))
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))

                            Text("Add Shift")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .indigo]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .offset(x: cardOffset)
                .opacity(cardOpacity)
            }
        }
    }
}

// MARK: - Tomorrow Shift Section

private struct TomorrowShiftSection: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)

                Text("Tomorrow")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            let tomorrowShifts = store.state.today.scheduledShifts.filter { shift in
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                return shift.startsOn(date: tomorrow)
            }

            CompactMultiShiftCarousel(shifts: tomorrowShifts)
        }
    }
}

// MARK: - Week Summary Section

private struct WeekSummarySection: View {
    @Environment(\.reduxStore) var store
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Binding var cardOffsets: [Int: CGFloat]
    @Binding var cardOpacities: [Int: Double]

    var body: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let next7Days = Calendar.current.date(byAdding: .day, value: 6, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"
        let todayString = dateFormatter.string(from: today)
        let next7DaysString = dateFormatter.string(from: next7Days)
        let dateRangeText = "\(todayString) – \(next7DaysString)"

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.callout)
                        .foregroundColor(.blue)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("7 Day Outlook")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(dateRangeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            let weekShifts = store.state.today.scheduledShifts.filter { shift in
                return shift.date >= today && shift.date <= next7Days
            }

            let shiftTypeCounts = Dictionary(grouping: weekShifts, by: { $0.shiftType?.id })
                .compactMap { (typeId, shifts) -> ShiftTypeSummary? in
                    guard let shiftType = shifts.first?.shiftType else { return nil }
                    return ShiftTypeSummary(shiftType: shiftType, count: shifts.count)
                }
                .filter { $0.count > 0 }
                .sorted { $0.count > $1.count }

            if shiftTypeCounts.isEmpty {
                EmptyWeekSummaryCard(onScheduleShifts: {
                    Task {
                        await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))
                    }
                })
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(shiftTypeCounts.enumerated()), id: \.element.id) { index, typeCount in
                            Button(action: {
                                Task {
                                    await store.dispatch(action: .schedule(.filterShiftTypeChanged(typeCount.shiftType)))
                                    await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                ShiftTypeCountCard(
                                    shiftType: typeCount.shiftType,
                                    count: typeCount.count,
                                    scheduledShifts: weekShifts
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .offset(x: cardOffsets[index] ?? 200)
                            .opacity(cardOpacities[index] ?? 0)
                        }
                    }
                }
                .onAppear {
                    for (index, _) in shiftTypeCounts.enumerated() {
                        Task {
                            if !reduceMotion {
                                try? await Task.sleep(nanoseconds: UInt64(0.08 * Double(index) * 1_000_000_000))
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    cardOffsets[index] = 0
                                    cardOpacities[index] = 1
                                }
                            } else {
                                cardOffsets[index] = 0
                                cardOpacities[index] = 1
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Today View with Animations") {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St")

    let morningShift = ShiftType(
        id: UUID(),
        symbol: "🌅",
        duration: .scheduled(
            from: HourMinuteTime(hour: 6, minute: 0),
            to: HourMinuteTime(hour: 14, minute: 0)
        ),
        title: "Morning Shift",
        description: "Early morning shift with team briefing",
        location: sampleLocation
    )

    let eveningShift = ShiftType(
        id: UUID(),
        symbol: "🌆",
        duration: .scheduled(
            from: HourMinuteTime(hour: 14, minute: 0),
            to: HourMinuteTime(hour: 22, minute: 0)
        ),
        title: "Evening Shift",
        description: "Evening shift with handover",
        location: sampleLocation
    )

    let todayShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: morningShift,
        date: Date()
    )

    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    let tomorrowShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: eveningShift,
        date: tomorrowDate
    )

    let previewStore: Store = {
        var state = AppState()
        state.today.scheduledShifts = [todayShift, tomorrowShift]
        state.today.isLoading = false
        state.isCalendarAuthorized = true
        state.isCalendarAuthorizationVerified = true
        state.locations.locations = [sampleLocation]
        state.shiftTypes.shiftTypes = [morningShift, eveningShift]

        return Store(
            state: state,
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: [
                scheduleMiddleware,
                todayMiddleware,
                locationsMiddleware,
                shiftTypesMiddleware,
                changeLogMiddleware,
                settingsMiddleware,
                loggingMiddleware
            ]
        )
    }()

    TodayView()
        .environment(\.reduxStore, previewStore)
}
