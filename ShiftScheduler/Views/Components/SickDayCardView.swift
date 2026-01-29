import SwiftUI

/// Component for displaying a shift marked as sick day
/// Shows orange thermometer icon with "Out Sick" status and optional reason display
struct SickDayCardView: View {
    let shift: ScheduledShift
    let onTap: (() -> Void)?

    @State private var reasonExpanded = false
    @State private var showFullNoteSheet = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 12) {
                // Orange thermometer icon in circular background
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                    )

                // Out Sick text
                VStack(spacing: 4) {
                    Text("Out Sick")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    // Show reason if available, otherwise fallback text
                    if let reason = shift.reason, !reason.isEmpty {
                        ReasonSection(
                            reason: reason,
                            isExpanded: $reasonExpanded,
                            showFullNoteSheet: $showFullNoteSheet
                        )
                    } else {
                        Text("Tap to see details & edit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(.systemGray3).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            onTap?()
        }
        .sheet(isPresented: $showFullNoteSheet) {
            FullNoteSheetView(reason: shift.reason ?? "")
        }
    }
}

// MARK: - Private Views

private struct ReasonSection: View {
    let reason: String
    @Binding var isExpanded: Bool
    @Binding var showFullNoteSheet: Bool

    private var lineCount: Int {
        // Count actual lines by splitting on newlines
        reason.components(separatedBy: .newlines).count
    }

    private var characterCount: Int {
        reason.count
    }

    private var shouldShowExpansionControls: Bool {
        // Show if EITHER line count > 3 OR character count > 80
        lineCount > 3 || characterCount > 80
    }

    private var shouldShowFullNoteButton: Bool {
        // Show if EITHER line count > 6 OR character count > 240
        lineCount > 6 || characterCount > 240
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Reason text with adaptive line limit
            Text(reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? 6 : 3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Expansion controls (show if either threshold is exceeded)
            if shouldShowExpansionControls {
                HStack(spacing: 12) {
                    // Show more/less button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)

                    // "View Full Note" button (only when expanded and text exceeds 6 lines or 240 chars)
                    if isExpanded && shouldShowFullNoteButton {
                        Button(action: {
                            showFullNoteSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Text("View Full Note")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}

private struct FullNoteSheetView: View {
    let reason: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with icon
                    HStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.title2)
                            .foregroundColor(.orange)

                        Text("Sick Day Reason")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Divider()

                    // Full reason text
                    Text(reason)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}
