#!/usr/bin/env swift

import SwiftUI
import AppKit

struct AppIconView: View {
    let size: CGSize
    let symbolName: String

    var body: some View {
        ZStack {
            // Rounded square background (iOS app icon shape)
            RoundedRectangle(cornerRadius: size.width * 0.2237, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.0, green: 0.67, blue: 0.71),
                            Color(red: 0.0, green: 0.48, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // SF Symbol
            Image(systemName: symbolName)
                .font(.system(size: size.width * 0.45, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size.width, height: size.height)
    }
}

@MainActor
func generateAppIcon(size: CGSize, symbolName: String, outputPath: String) -> Bool {
    let renderer = ImageRenderer(content: AppIconView(size: size, symbolName: symbolName))
    renderer.scale = 1.0

    guard let cgImage = renderer.cgImage else { return false }
    let nsImage = NSImage(cgImage: cgImage, size: size)

    guard let tiffData = nsImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        return false
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Saved: \(outputPath)")
        return true
    } catch {
        print("Error: \(error)")
        return false
    }
}

@MainActor
func main() async {
    let basePath = "ShiftScheduler/Assets.xcassets/AppIcon.appiconset"
    let size = CGSize(width: 1024, height: 1024)
    let symbolName = "calendar.badge.clock"

    _ = generateAppIcon(size: size, symbolName: symbolName, outputPath: "\(basePath)/app-icon-1024.png")
    _ = generateAppIcon(size: size, symbolName: symbolName, outputPath: "\(basePath)/app-icon-1024-dark.png")
    _ = generateAppIcon(size: size, symbolName: symbolName, outputPath: "\(basePath)/app-icon-1024-tinted.png")
}

await main()
