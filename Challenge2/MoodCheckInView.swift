//
//  MoodCheckInView.swift
//  Challenge2
//

import SwiftUI

/// Lets the user rate how anxious they feel before checking in to the gym.
struct MoodCheckInView: View {
    /// 0 = "A little", 1 = "Very".
    @State private var level: Double = 0
    @State private var checkInDate: Date?
    /// Max distance (in points) the scribble drifts from its resting position in any direction.
    private let floatAmount: CGFloat = 2
    /// Seconds for one full drift cycle. Higher = slower.
    private let floatDuration: Double = 6

    var body: some View {
        VStack(spacing: 24) {
            TimelineView(.animation) { context in
                // Horizontal and vertical motion use slightly different periods so the
                // path never repeats a straight line and wanders gently in all directions.
                let t = context.date.timeIntervalSinceReferenceDate * 2 * .pi / floatDuration
                let x = sin(t) * floatAmount
                let y = sin(t * 1.37 + 1) * floatAmount

                ScribbleShape(intensity: level)
                    .stroke(
                        Theme.purple.opacity(0.4 + 0.6 * level),
                        style: StrokeStyle(lineWidth: 4 - level, lineCap: .round, lineJoin: .round)
                    )
                    .frame(height: 150)
                    .padding(.horizontal, 32)
                    .offset(x: x, y: y)
            }

            Text("anxious")
                .font(.title3.bold())
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                Text("Very")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.caption)

                MoodSlider(value: $level)

                Text("A little")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.caption)
            }

            Spacer(minLength: 0)

            Button("Check in") {
                checkInDate = .now
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .navigationDestination(item: $checkInDate) { date in
            GymTimerView(checkInDate: date, moodLevel: level)
        }
    }
}

/// A tall capsule slider that fills with purple from the bottom as the value increases.
struct MoodSlider: View {
    @Binding var value: Double

    private let width: CGFloat = 72
    private let height: CGFloat = 330
    /// Number of discrete stops the slider snaps to when released.
    private let steps = 4

    var body: some View {
        let fillHeight = width + value * (height - width)

        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Theme.track)

            Capsule()
                .fill(Theme.purple)
                .frame(height: fillHeight)

            // Tick dots marking each stop.
            VStack {
                ForEach(0..<steps, id: \.self) { _ in
                    Circle()
                        .fill(.black.opacity(0.35))
                        .frame(width: 4, height: 4)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, width / 2)

            // Handle line at the top of the fill.
            Capsule()
                .fill(.black.opacity(0.4))
                .frame(width: 30, height: 3)
                .padding(.bottom, fillHeight - 12)
        }
        .frame(width: width, height: height)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let raw = 1 - (drag.location.y - width / 2) / (height - width)
                    value = min(max(raw, 0), 1)
                }
                .onEnded { _ in
                    withAnimation(.spring(duration: 0.3)) {
                        value = (value * Double(steps)).rounded() / Double(steps)
                    }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Anxiety level")
        .accessibilityValue("\(Int(value * 100)) percent")
        .accessibilityAdjustableAction { direction in
            let step = 1 / Double(steps)
            switch direction {
            case .increment: value = min(value + step, 1)
            case .decrement: value = max(value - step, 0)
            @unknown default: break
            }
        }
    }
}

#Preview {
    NavigationStack {
        MoodCheckInView()
    }
    .preferredColorScheme(.dark)
}

/// Shared colors used across the check-in and gym timer screens.
enum Theme {
    /// Main accent purple used for the mood slider, scribble and moon.
    static let purple = Color(red: 201 / 255, green: 63 / 255, blue: 230 / 255)
    /// Unfilled slider track.
    static let track = Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)
    /// Background of cards such as the gym timer.
    static let card = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    /// Secondary label color for small captions.
    static let caption = Color.white.opacity(0.55)
}
