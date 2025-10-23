import SwiftUI

// MARK: - Shift Display Card Component
/// Display-only shift card for ShiftChangeSheet - based on EnhancedShiftCard layout
/// Shows all shift information without interactive elements
struct ShiftDisplayCard: View {
    let shiftType: ShiftType
    let date: Date
    let label: String?
    let showBadge: Bool

    init(
        shiftType: ShiftType,
        date: Date,
        label: String? = nil,
        showBadge: Bool = false
    ) {
        self.shiftType = shiftType
        self.date = date
        self.label = label
        self.showBadge = showBadge
    }

    private var shiftStatus: ShiftStatus {
        let now = Date()
        let calendar = Calendar.current

        // Check if shift is today
        if calendar.isDate(date, inSameDayAs: now) {
            switch shiftType.duration {
            case .allDay:
                return .active
            case .scheduled(let startTime, let endTime):
                let shiftStart = startTime.toDate(on: date)
                let shiftEnd = endTime.toDate(on: date)

                if now < shiftStart {
                    return .upcoming
                } else if now >= shiftStart && now <= shiftEnd {
                    return .active
                } else {
                    return .completed
                }
            }
        } else if date < now {
            return .completed
        } else {
            return .upcoming
        }
    }

    private var cardColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 12) {
                // Header section with optional label badge and status
                HStack {
                    if let label = label, showBadge {
                        HStack(spacing: 6) {
                            Image(systemName: labelIcon)
                                .font(.caption2)
                                .foregroundStyle(.white)

                            Text(label)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [cardColor, cardColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: cardColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    } else {
                        StatusBadge(status: shiftStatus)
                    }

                    Spacer()
                }

                // Main content section
                HStack(spacing: 12) {
                    // Shift symbol with gradient background
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

                        Text(shiftType.symbol)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(cardColor)
                    }

                    // Shift details
                    VStack(alignment: .leading, spacing: 6) {
                        // Title
                        Text(shiftType.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // Time range with enhanced styling
                        HStack(spacing: 6) {
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
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(shiftType.location.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        if !shiftType.location.address.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(shiftType.location.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
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
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .padding(14)

            // Optional gradient footer for active shifts
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
    }

    private var labelIcon: String {
        guard let label = label else { return "circle.fill" }
        switch label.lowercased() {
        case "current": return "circle.fill"
        case "new": return "sparkles"
        default: return "circle.fill"
        }
    }
}

struct ShiftChangeSheet: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) private var dismiss

    let currentShift: ScheduledShift
    let feature: ShiftSwitchFeature  // 'today' or 'schedule'

    @State private var selectedShiftType: ShiftType?
    @State private var reason: String = ""
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    // Animation states for staggered entrance
    @State private var showCurrentShift = false
    @State private var showTransitionIndicator = false
    @State private var showNewShiftSection = false
    @State private var showReasonField = false
    @State private var showActionButtons = false
    @FocusState private var isReasonFocused: Bool

    /// Which feature is triggering the shift switch
    enum ShiftSwitchFeature {
        case today
        case schedule
    }

    /// Get available shift types excluding current shift
    private var availableShiftTypes: [ShiftType] {
        store.state.shiftTypes.shiftTypes.filter { $0.id != currentShift.shiftType?.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Current shift preview with entrance animation
                    currentShiftSection
                        .offset(y: showCurrentShift ? 0 : 30)
                        .opacity(showCurrentShift ? 1 : 0)

                    // Transition indicator between shifts
                    if currentShift.shiftType != nil && selectedShiftType != nil {
                        ShiftTransitionIndicator(
                            fromShift: currentShift.shiftType,
                            toShift: selectedShiftType
                        )
                        .offset(y: showTransitionIndicator ? 0 : 20)
                        .opacity(showTransitionIndicator ? 1 : 0)
                    }

                    // New shift picker with entrance animation
                    newShiftSection
                        .offset(y: showNewShiftSection ? 0 : 30)
                        .opacity(showNewShiftSection ? 1 : 0)

                    // Optional reason field with entrance animation
                    reasonSection
                        .offset(y: showReasonField ? 0 : 20)
                        .opacity(showReasonField ? 1 : 0)

                    // Action buttons with entrance animation
                    actionButtons
                        .offset(y: showActionButtons ? 0 : 20)
                        .opacity(showActionButtons ? 1 : 0)
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .navigationTitle("Switch Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Switch Shift?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Switch") {
                    Task {
                        await performSwitch()
                    }
                }
            } message: {
                if let newType = selectedShiftType {
                    Text("Are you sure you want to switch this shift to \(newType.symbol) \(newType.title)?")
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if showSuccess {
                    successToast
                }
            }
        }
        .onAppear {
            selectedShiftType = availableShiftTypes.first

            // Staggered entrance animations
            withAnimation(AnimationPresets.accessible(AnimationPresets.standardSpring).delay(0.1)) {
                showCurrentShift = true
            }
            withAnimation(AnimationPresets.accessible(AnimationPresets.standardSpring).delay(0.2)) {
                showTransitionIndicator = true
            }
            withAnimation(AnimationPresets.accessible(AnimationPresets.standardSpring).delay(0.3)) {
                showNewShiftSection = true
            }
            withAnimation(AnimationPresets.accessible(AnimationPresets.standardSpring).delay(0.4)) {
                showReasonField = true
            }
            withAnimation(AnimationPresets.accessible(AnimationPresets.standardSpring).delay(0.5)) {
                showActionButtons = true
            }
        }
        .onChange(of: store.state.today.showSwitchShiftSheet) { _, newValue in
            if !newValue && feature == .today {
                dismiss()
            }
        }
        .onChange(of: store.state.schedule.scheduledShifts) { _, _ in
            // No dismissal needed - sheet handles its own state
        }
    }

    // MARK: - View Components

    private var currentShiftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Shift")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let shiftType = currentShift.shiftType {
                ShiftDisplayCard(
                    shiftType: shiftType,
                    date: currentShift.date,
                    label: "Current",
                    showBadge: true
                )
            }
        }
    }

    private var newShiftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New Shift Type")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if availableShiftTypes.isEmpty {
                Text("No other shift types available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
            } else {
                // Enhanced picker with gradient styling
                Picker("Select Shift Type", selection: $selectedShiftType) {
                    Text("Select a shift type")
                        .tag(nil as ShiftType?)

                    ForEach(availableShiftTypes) { type in
                        HStack {
                            Text(type.symbol)
                            Text(type.title)
                        }
                        .tag(Optional(type))
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                }

                // Enhanced preview card for selected shift
                if let selected = selectedShiftType {
                    ShiftDisplayCard(
                        shiftType: selected,
                        date: currentShift.date,
                        label: "New",
                        showBadge: true
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
                }
            }
        }
        .animation(AnimationPresets.accessible(AnimationPresets.standardSpring), value: selectedShiftType)
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reason (Optional)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            TextField("Why are you switching this shift?", text: $reason, axis: .vertical)
                .focused($isReasonFocused)
                .lineLimit(3...5)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isReasonFocused
                                        ? ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.5)
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        }
                        .shadow(
                            color: isReasonFocused
                                ? ShiftColorPalette.glowColorForShift(selectedShiftType).opacity(0.2)
                                : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
                .animation(AnimationPresets.quickSpring, value: isReasonFocused)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            GlassActionButton(
                title: "Cancel",
                icon: "xmark",
                action: {
                    dismiss()
                }
            )

            GradientActionButton(
                title: "Switch Shift",
                icon: "arrow.triangle.2.circlepath",
                shiftType: selectedShiftType,
                isEnabled: selectedShiftType != nil && !isProcessing,
                isLoading: isProcessing,
                action: {
                    showConfirmation = true
                }
            )
        }
    }

    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ShiftColorPalette.colorForShift(selectedShiftType),
                                ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Shift switched successfully")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.3),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(
                        color: ShiftColorPalette.glowColorForShift(selectedShiftType).opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            }
            .padding(24)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.9)).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        )
        .animation(AnimationPresets.accessible(AnimationPresets.standardSpring), value: showSuccess)
    }

    // MARK: - Actions

    private func performSwitch() async {
        guard let newShiftType = selectedShiftType else { return }

        isProcessing = true
        errorMessage = nil

        let reasonText = reason.isEmpty ? nil : reason

        // Dispatch shift switch action based on feature
        switch feature {
        case .today:
            store.dispatch(action: .today(.performSwitchShift(currentShift, newShiftType, reasonText)))
        case .schedule:
            store.dispatch(action: .schedule(.performSwitchShift(currentShift, newShiftType, reasonText)))
        }

        // Show success feedback
        await MainActor.run {
            showSuccess = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // Dismiss after a delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        await MainActor.run {
            dismiss()
        }
    }
}
