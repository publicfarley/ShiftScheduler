import SwiftUI

/// A view modifier that dismisses the keyboard when tapping outside text input fields.
/// This solves the critical UX issue where keyboards block CTAs and action buttons.
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         VStack {
///             TextField("Search...", text: $searchText)
///             // Other content
///         }
///         .dismissKeyboardOnTap()
///     }
/// }
/// ```
struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                dismissKeyboard()
            }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

/// Extension to make the keyboard dismissal modifier easy to apply
extension View {
    /// Dismisses the keyboard when the user taps anywhere in this view.
    /// Perfect for preventing keyboard blocking of CTAs and action buttons.
    ///
    /// - Returns: A view that dismisses the keyboard on tap
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }
}

/// A custom view that can be used as a tappable background to dismiss the keyboard.
/// This is useful when you want to add dismissal behavior to specific areas without
/// affecting other tap gestures.
///
/// Usage:
/// ```swift
/// ZStack {
///     KeyboardDismissArea()
///     VStack {
///         TextField("Input", text: $text)
///         Button("Save") { }
///     }
/// }
/// ```
struct KeyboardDismissArea: View {
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

/// A scroll view that automatically dismisses the keyboard when dragging.
/// This provides a more natural UX for scrollable content with text fields.
///
/// Usage:
/// ```swift
/// KeyboardDismissingScrollView {
///     VStack {
///         TextField("Name", text: $name)
///         TextField("Email", text: $email)
///         // More content
///     }
/// }
/// ```
struct KeyboardDismissingScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

/// Global keyboard utility functions for manual control
enum KeyboardDismisser {
    /// Manually dismiss the keyboard from anywhere in the app
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
