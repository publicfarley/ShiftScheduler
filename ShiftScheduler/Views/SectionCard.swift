import SwiftUI

/// A reusable section card component with glassmorphism styling and prominence levels
/// Used to provide clear visual separation between different content sections
struct SectionCard<Content: View>: View {
    let accentColor: Color
    let prominence: Prominence
    @ViewBuilder let content: () -> Content

    enum Prominence {
        case primary    // Today section
        case secondary  // Tomorrow section
        case tertiary   // Next 7 Days section

        var cornerRadius: CGFloat {
            switch self {
            case .primary: 18
            case .secondary: 16
            case .tertiary: 16
            }
        }

        var padding: CGFloat {
            switch self {
            case .primary: 20
            case .secondary: 16
            case .tertiary: 20
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .primary: 10
            case .secondary: 6
            case .tertiary: 8
            }
        }

        var shadowYOffset: CGFloat {
            switch self {
            case .primary: 5
            case .secondary: 3
            case .tertiary: 4
            }
        }

        var accentOpacity: CGFloat {
            switch self {
            case .primary: 0.3
            case .secondary: 0.15
            case .tertiary: 0.2
            }
        }

        var gradientOpacity: CGFloat {
            switch self {
            case .primary: 0.15
            case .secondary: 0.08
            case .tertiary: 0.1
            }
        }

        var shadowColorOpacity: CGFloat {
            switch self {
            case .primary: 0.15
            case .secondary: 0.08
            case .tertiary: 0.1
            }
        }
    }

    var body: some View {
        content()
            .padding(prominence.padding)
            .background {
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: prominence.cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: prominence.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(prominence.gradientOpacity),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Subtle border with gradient using accent color
                    RoundedRectangle(cornerRadius: prominence.cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(prominence.accentOpacity),
                                    accentColor.opacity(prominence.accentOpacity * 0.5),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(
                    color: .black.opacity(0.08),
                    radius: prominence.shadowRadius,
                    x: 0,
                    y: prominence.shadowYOffset
                )
                .shadow(
                    color: accentColor.opacity(prominence.shadowColorOpacity),
                    radius: prominence.shadowRadius * 2,
                    x: 0,
                    y: prominence.shadowRadius
                )
            }
    }
}

// MARK: - Preview

#Preview("Primary Card") {
    ScrollView {
        VStack(spacing: 20) {
            SectionCard(accentColor: .orange, prominence: .primary) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Today, Nov 16")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Text("Your shift content goes here")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)

            SectionCard(accentColor: .indigo, prominence: .secondary) {
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
                    Text("Tomorrow's shift content")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)

            SectionCard(accentColor: .blue, prominence: .tertiary) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.callout)
                            .foregroundColor(.blue)
                        Text("Next 7 Days")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    Text("7-day shift summary content")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
    .background(Color(.systemBackground))
}
