//
//  MoodLight.swift
//  Challenge2
//

import SwiftUI

// Background light: a single, very soft glow tinted with the current mood,
// as if the mood on screen is lighting the room. It mostly stays still and
// only reacts to what the user does (picking a mood, sliding the intensity, swiping).
//
// Examples:
//  - One mood:          MoodLight(color: .purple, intensity: 0.7)
//  - Blend while swiping: MoodLight(colors: [orange, yellow, blue], position: scrollProgress)
//  - Before -> after:   MoodLight(colors: [walkedInColor, leftColor], position: progress)

// We can change these values to quickly test how the light looks
enum MoodLightSettings {

    // Where the light comes from (.bottom = rising from the floor, .top = from the ceiling)
    static let source: UnitPoint = .bottom

    // How strong the light is at full intensity, right at the source
    static let opacity: Double = 0.28
    // How far it reaches (compared to the screen height)
    static let reach: Double = 0.85
    // How strong it still is at the lowest intensity (0 = off, 1 = same as full)
    static let minimumStrength: Double = 0.35

    // How long it takes to fade to a new mood or intensity (seconds)
    static let fadeDuration: Double = 0.8

    // Very slow breathing: how much it grows, and one full breath (seconds). 0 turns it off.
    static let breathAmount: Double = 0.04
    static let breathDuration: Double = 10
}

struct MoodLight: View {
    // The colors to blend between, and where we are between them
    // (0 = first color, 1 = second, 1.5 = halfway between second and third).
    var colors: [Color]
    var position: Double = 0
    // How strong the mood is (0...1), for example from the intensity slider
    var intensity: Double = 1

    // If the user has reduceMotion ON, the light doesn't breathe
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isBreathingIn = false

    init(colors: [Color], position: Double = 0, intensity: Double = 1) {
        self.colors = colors
        self.position = position
        self.intensity = intensity
    }

    init(color: Color, intensity: Double = 1) {
        self.init(colors: [color], intensity: intensity)
    }

    var body: some View {
        let color = blendedColor
        let strength = MoodLightSettings.opacity
            * (MoodLightSettings.minimumStrength + (1 - MoodLightSettings.minimumStrength) * min(max(intensity, 0), 1))

        GeometryReader { geometry in
            // The glow fades out gradually: strong at the source, softer halfway, gone at the edge
            Rectangle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: color.opacity(strength), location: 0),
                            .init(color: color.opacity(strength * 0.4), location: 0.45),
                            .init(color: color.opacity(0), location: 1),
                        ],
                        center: MoodLightSettings.source,
                        startRadius: 0,
                        endRadius: geometry.size.height * MoodLightSettings.reach
                    )
                )
                .scaleEffect(isBreathingIn ? 1 + MoodLightSettings.breathAmount : 1, anchor: MoodLightSettings.source)
        }
        // Fade smoothly when the mood or intensity changes.
        // The position is not animated, so the light follows a swipe without delay.
        .animation(.easeInOut(duration: MoodLightSettings.fadeDuration), value: colors)
        .animation(.easeInOut(duration: MoodLightSettings.fadeDuration), value: intensity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion, MoodLightSettings.breathAmount > 0 else { return }
            withAnimation(.easeInOut(duration: MoodLightSettings.breathDuration / 2).repeatForever(autoreverses: true)) {
                isBreathingIn = true
            }
        }
    }

    // The color at the current position, mixed between its two neighbours
    private var blendedColor: Color {
        guard let first = colors.first else { return .clear }
        guard colors.count > 1 else { return first }

        let clamped = min(max(position, 0), Double(colors.count - 1))
        let index = Int(clamped.rounded(.down))
        let next = min(index + 1, colors.count - 1)
        return colors[index].mix(with: colors[next], by: clamped - Double(index))
    }
}

#Preview {
    ZStack {
        Color.black
        MoodLight(color: Color(red: 0xDB / 255, green: 0x34 / 255, blue: 0xF2 / 255))
    }
}
