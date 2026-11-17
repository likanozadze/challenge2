//
//  CalendarIllustration.swift
//  Challenge2
//
//  Onboarding page 3: a simple month grid where visits pop in and each
//  visit tile keeps flipping between the walking-in and leaving feelings.
//

import SwiftUI

struct CalendarIllustration: View {
    var start: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Visit {
        let day: Int
        let walkedIn: ImageResource
        let left: ImageResource
    }

    private static let visits: [Visit] = [
        // Days picked so the visits are scattered across rows and columns.
        Visit(day: 2, walkedIn: .anxious, left: .calm),
        Visit(day: 12, walkedIn: .stressed, left: .satisfied),
        Visit(day: 15, walkedIn: .drained, left: .energized),
        Visit(day: 20, walkedIn: .down, left: .motivated),
        Visit(day: 24, walkedIn: .busy, left: .calm),
    ]

    private static let dayCount = 30
    private static let cellSize: CGFloat = 34
    private static let spacing: CGFloat = 6
    private static let columns = Array(
        repeating: GridItem(.fixed(cellSize), spacing: spacing),
        count: 7
    )

    // Timeline (seconds).
    private static let firstVisitDelay = 0.5
    private static let visitStagger = 0.25
    private static let firstFlipDelay = 1.8
    private static let flipStagger = 0.15
    private static let holdDuration = 1.2
    private static let flipDuration = 0.5

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            // With Reduce Motion, show all visits on their walking-in side.
            let time = reduceMotion ? 10 : context.date.timeIntervalSince(start)

            LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                ForEach(1...Self.dayCount, id: \.self) { day in
                    if let index = Self.visits.firstIndex(where: { $0.day == day }) {
                        visitCell(Self.visits[index], index: index, time: time)
                    } else {
                        Text(day, format: .number)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(white: 0.45))
                            .frame(width: Self.cellSize, height: Self.cellSize)
                    }
                }
            }
            .opacity(Easing.clamp(time / 0.4))
        }
        .fixedSize()
        .accessibilityHidden(true)
    }

    private func visitCell(_ visit: Visit, index: Int, time: TimeInterval) -> some View {
        let appearTime = time - Self.firstVisitDelay - Double(index) * Self.visitStagger
        let flipTime = time - Self.firstFlipDelay - Double(index) * Self.flipStagger
        let angle = reduceMotion ? 0 : Self.flipAngle(at: flipTime)
        // Between 90° and 270° the back (leaving feeling) faces the viewer.
        let showsBack = angle > 90 && angle < 270

        return ZStack {
            tile(visit.walkedIn, day: visit.day)
                .opacity(showsBack ? 0 : 1)
            tile(visit.left, day: visit.day)
                // Pre-rotate the back so it isn't mirrored once flipped.
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                .opacity(showsBack ? 1 : 0)
        }
        // Flip top to bottom, like a split-flap display.
        .rotation3DEffect(.degrees(-angle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .scaleEffect(Easing.easeOutBack(appearTime / 0.4))
        .opacity(Easing.clamp(appearTime / 0.2))
    }

    private func tile(_ mood: ImageResource, day: Int) -> some View {
        VStack(spacing: 2) {
            Image(mood)
                .resizable()
                .scaledToFit()
                .frame(height: 15)
            Text(day, format: .number)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: Self.cellSize, height: Self.cellSize)
        .background(Color(white: 0.15), in: .rect(cornerRadius: 8))
    }

    /// Rotation in degrees: hold walking-in, flip to leaving, hold, flip on
    /// round to walking-in again (always turning the same direction).
    private static func flipAngle(at time: TimeInterval) -> Double {
        guard time > 0 else { return 0 }
        let loop = 2 * (holdDuration + flipDuration)
        let phase = time.truncatingRemainder(dividingBy: loop)
        switch phase {
        case ..<holdDuration:
            return 0
        case ..<(holdDuration + flipDuration):
            return 180 * Easing.easeInOut((phase - holdDuration) / flipDuration)
        case ..<(2 * holdDuration + flipDuration):
            return 180
        default:
            return 180 + 180 * Easing.easeInOut((phase - 2 * holdDuration - flipDuration) / flipDuration)
        }
    }
}

#Preview {
    CalendarIllustration(start: .now)
        .padding()
        .background(.black)
}
