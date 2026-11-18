//
//  FilmGrain.swift
//  Challenge2
//

import SwiftUI
import UIKit

// A barely visible, still noise texture to put over the black background.
// It gives the screen a tactile, printed feel that suits the hand-drawn icons.
// Use "FilmGrain()" as the top layer of a background; it doesn't move and ignores touches.

// We can change these values to quickly test how the grain looks
enum FilmGrainSettings {

    // How visible the grain is overall
    static let opacity: Double = 0.06

    // How many pixels get a speck (0 = none, 1 = every pixel)
    static let density: Double = 0.35

    // Size of the texture that gets repeated over the screen (in points)
    static let tileSize: CGFloat = 96
}

struct FilmGrain: View {
    var body: some View {
        Image(uiImage: Self.tile)
            .resizable(resizingMode: .tile)
            .opacity(FilmGrainSettings.opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // The noise is drawn once, the first time it's needed, and then reused
    // everywhere, so it costs nothing while the app is running.
    private static let tile: UIImage = {
        // Drawn at 3x, so each speck is a single pixel on the screen
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false

        let size = CGSize(width: FilmGrainSettings.tileSize, height: FilmGrainSettings.tileSize)
        let pixel = 1 / format.scale

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            for y in stride(from: 0, to: size.height, by: pixel) {
                for x in stride(from: 0, to: size.width, by: pixel) {
                    guard Double.random(in: 0..<1) < FilmGrainSettings.density else { continue }
                    // Each speck gets its own brightness so the grain looks natural
                    UIColor(white: 1, alpha: .random(in: 0.2...1)).setFill()
                    context.fill(CGRect(x: x, y: y, width: pixel, height: pixel))
                }
            }
        }
    }()
}

#Preview {
    ZStack {
        Color.black
        FilmGrain()
    }
}
