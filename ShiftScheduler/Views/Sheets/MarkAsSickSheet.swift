import SwiftUI

/// Modal sheet for marking a shift as sick day
/// Allows user to optionally provide a reason for marking the shift as sick
struct MarkAsSickSheet: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss

    let shift: ScheduledShift

    @State private var reason: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Shift details section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Shift Details")
                                .font(.headline)
                                .fontWeight(.semibold)

                            if let shiftType = shift.shiftType {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Date
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Date")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(shift.date, style: .date)
                                                .font(.body)
                                                .fontWeight(.medium)
                                        }

                                        Spacer()
                                    }

                                    Divider()

                                    // Shift Type
                                    HStack(spacing: 12) {
                                        Image(systemName: shiftType.symbol)
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Shift")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(shiftType.title)
                                                .font(.body)
                                                .fontWeight(.medium)
                                        }

                                        Spacer()
                                    }

                                    Divider()

                                    // Time
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Time")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(shiftType.timeRangeString)
                                                .font(.body)
                                                .fontWeight(.medium)
                                        }

                                        Spacer()
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }

                        Divider()
                            .padding(.vertical, 8)

                        // Reason section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reason (optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            TextEditor(text: $reason)
                                .font(.body)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray3), lineWidth: 1)
                                )

                            if reason.isEmpty {
                                Text("Add optional details about why you're marking this as sick")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                            .frame(minHeight: 20)
                    }
                    .padding(16)
                }

                // Action buttons
                VStack(spacing: 12) {
                    // Mark as Sick button
                    Button(action: {
                        Task {
                            await markAsSick()
                        }
                    }) {
                        HStack {
                            Image(systemName: "thermometer.medium")
                            Text("Mark as Sick")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange,
                                    Color.orange.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .disabled(store.state.today.isLoading)

                    // Cancel button
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                .padding(16)
            }
            .navigationTitle("Mark as Sick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func markAsSick() async {
        let reasonToSend = reason.trimmingCharacters(in: .whitespaces).isEmpty ? nil : reason
        await store.dispatch(action: .today(.markShiftAsSick(shift, reason: reasonToSend)))
        dismiss()
    }
}
