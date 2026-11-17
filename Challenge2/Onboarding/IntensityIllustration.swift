//
//  IntensityIllustration.swift
//  Challenge2
//
//  Onboarding page 2: a mini check-in screen where the intensity slider
//  moves up and down and the energized burst grows and shrinks with it.
//

import SwiftUI

struct IntensityIllustration: View {
    var start: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Timeline (seconds) of one up-and-down loop.
    private static let riseDuration = 1.4
    private static let holdDuration = 0.6
    private static var loopDuration: Double { 2 * (riseDuration + holdDuration) }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            // With Reduce Motion, show a settled burst at a fixed level.
            let time = reduceMotion ? 1 : context.date.timeIntervalSince(start)
            let level = reduceMotion ? 0.7 : Self.level(at: time)

            VStack(spacing: 8) {
                BurstIcon(time: time, intensity: level)
                    .frame(width: 96, height: 96)

                Text("energized")
                    .font(.caption.bold())
                    .foregroundStyle(.white)

                IntensitySlider(level: level, color: BurstIcon.color)
                    .padding(.top, 4)
            }
        }
        .accessibilityHidden(true)
    }

    /// Slider level (0...1): rise, hold at the top, fall, hold at the bottom.
    private static func level(at time: TimeInterval) -> Double {
        let phase = time.truncatingRemainder(dividingBy: loopDuration)
        let progress: Double
        switch phase {
        case ..<riseDuration:
            progress = Easing.easeInOut(phase / riseDuration)
        case ..<(riseDuration + holdDuration):
            progress = 1
        case ..<(2 * riseDuration + holdDuration):
            progress = 1 - Easing.easeInOut((phase - riseDuration - holdDuration) / riseDuration)
        default:
            progress = 0
        }
        // Never fully empty or full, like a real "A little" / "Very" pick.
        return 0.1 + 0.85 * progress
    }
}

/// Vertical capsule slider matching the check-in screen.
private struct IntensitySlider: View {
    let level: Double
    let color: Color

    private let trackWidth: CGFloat = 44
    private let trackHeight: CGFloat = 120

    var body: some View {
        VStack(spacing: 6) {
            Text("Very")
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.6))

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color(white: 0.2))

                // The fill starts as a circle (the knob) and grows upwards.
                Capsule()
                    .fill(color)
                    .frame(height: trackWidth + (trackHeight - trackWidth) * level)

                // Step markers along the track.
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        Spacer(minLength: 0)
                        Circle()
                            .fill(.black.opacity(0.35))
                            .frame(width: 3, height: 3)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, trackWidth / 2)
            }
            .frame(width: trackWidth, height: trackHeight)

            Text("A little")
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.6))
        }
    }
}

#Preview {
    IntensityIllustration(start: .now)
        .padding()
        .background(.black)
}
