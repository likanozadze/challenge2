//
//  GymTimerView.swift
//  Challenge2
//

import SwiftUI

/// Shows how long the user has been in the gym since checking in.
struct GymTimerView: View {
    let checkInDate: Date
    /// Mood level from the check-in slider: 0 = "A little", 1 = "Very".
    let moodLevel: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("TIME IN THE GYM")
                    .font(.caption)
                    .foregroundStyle(.white)

                // Re-renders once per second to update the elapsed time.
                TimelineView(.periodic(from: checkInDate, by: 1)) { context in
                    Text(elapsedString(at: context.date))
                        .font(.system(size: 64, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                Text("Since check in at \(checkInDate.formatted(date: .omitted, time: .shortened)) · stops when you finish or leave")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.card, in: .rect(cornerRadius: 24))
            .padding(.horizontal, 16)

            // A thick ring that closes as the mood level rises:
            // nothing at "A little", a full ring at "Very".
            // "A little" still shows a thin sliver; "Very" is a full ring.
            CrescentMoonShape(fill: 0.2 + 0.8 * moodLevel)
                .fill(Theme.purple)
                .frame(width: 226, height: 226)
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            Button("Check out") {
                dismiss()
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }

    /// Formats elapsed time as mm:ss, or h:mm:ss once past an hour.
    private func elapsedString(at date: Date) -> String {
        let total = max(0, Int(date.timeIntervalSince(checkInDate)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// A moon shape: a circle with an offset hole cut toward the upper right.
/// At 0 the hole covers everything, in between it pokes out past the edge
/// leaving a crescent with pointy tips, and at 1 it is centered, leaving a full ring.
struct CrescentMoonShape: Shape {
    var fill: Double

    var animatableData: Double {
        get { fill }
        set { fill = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let amount = min(max(fill, 0), 1)
        guard amount > 0 else { return Path() }

        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // The hole shrinks from larger than the moon (hidden) to 70% (full ring)
        // and slides from the upper right back to the center.
        let holeRadius = radius * (0.7 + 0.9 * pow(1 - amount, 1.5))
        let holeOffset = radius * 0.6 * pow(1 - amount, 0.5)
        let direction = CGPoint(x: cos(-Double.pi / 4), y: sin(-Double.pi / 4))
        let holeCenter = CGPoint(
            x: center.x + direction.x * holeOffset,
            y: center.y + direction.y * holeOffset
        )

        let moon = Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        let hole = Path(ellipseIn: CGRect(
            x: holeCenter.x - holeRadius, y: holeCenter.y - holeRadius,
            width: holeRadius * 2, height: holeRadius * 2
        ))
        return moon.subtracting(hole)
    }
}

#Preview {
    NavigationStack {
        GymTimerView(checkInDate: .now.addingTimeInterval(-31), moodLevel: 0)
    }
    .preferredColorScheme(.dark)
}
