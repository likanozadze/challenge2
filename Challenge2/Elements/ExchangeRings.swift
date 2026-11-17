//
//  ExchangeRings.swift
//
//  The "Exchange" mood animation, built from icon.svg.
//  progress 0 = the icon (check-in in front, check-out hidden behind)
//  progress 1 = the mirrored icon (check-out in front, check-in peeking behind)
//
//  Drop this file into the Xcode project. No assets or packages needed.
//

/*
 To use it with your Mood enum:

 Play it once automatically when the view appears, for example on the check-out screen:

 ExchangeRingsPlayer(checkIn: session.checkInMood.color,
                     checkOut: session.checkOutMood.color)
     .frame(width: 240)

 Or trigger it yourself:

 @State private var progress = 0.0

 ExchangeRings(checkIn: inMood.color, checkOut: outMood.color, progress: progress)

 // when the user checks out:
 withAnimation(.moodExchange) { progress = 1 }

 Behavior:

 Progress: progress goes from 0 to 1. At 0 it shows your icon, with check-in in front and check-out hidden behind. At 1 it shows the mirrored icon, with check-out in front and check-in peeking from behind.
 Timing: .moodExchange uses the same 2.8-second ease-in-out curve as the web version.
 Reduce Motion: ExchangeRingsPlayer skips the animation and shows the final state.
 Static use: set progress to 0 or 1 to show either state without animating.

 If you’d also like an exported file for marketing or social posts, I can record it as a transparent MOV or a Lottie JSON. For the app itself, the SwiftUI view is the better choice.

 If you want to keep this work, I can move this session to a folder you choose.
 */

import SwiftUI

// MARK: - The view

/// Two crescents around a shared dark center. Animate `progress` from 0 to 1
/// with `withAnimation(.moodExchange) { progress = 1 }`.
struct ExchangeRings: View, Animatable {
    var checkIn: Color
    var checkOut: Color
    /// 0 = check-in state, 1 = check-out state. Animatable.
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            Self.draw(in: &context, size: size, progress: progress,
                      checkIn: checkIn, checkOut: checkOut)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text("Mood change"))
    }
}

extension Animation {
    /// The same ease-in-out cubic curve and timing as the web prototype.
    static let moodExchange = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 2.8)
}

// MARK: - Geometry (measured from icon.svg, in units of the hole radius)

private struct Crescent {
    var radius: Double   // outer circle radius
    var offset: Double   // distance of the outer circle's center from the hole's center
    var angle: Double    // direction of that offset, in degrees (0 = right, 90 = down)

    static func mix(_ a: Crescent, _ b: Crescent, _ t: Double) -> Crescent {
        Crescent(radius: a.radius + (b.radius - a.radius) * t,
                 offset: a.offset + (b.offset - a.offset) * t,
                 angle: a.angle + (b.angle - a.angle) * t)
    }

    var mirrored: Crescent { Crescent(radius: radius, offset: offset, angle: 180 - angle) }
}

private enum Icon {
    static let front = Crescent(radius: 1.22, offset: 0.233, angle: 155)  // purple in icon.svg
    static let back  = Crescent(radius: 1.30, offset: 0.114, angle: 116)  // yellow in icon.svg
    static let holeShift = CGPoint(x: 0.085, y: -0.102)                     // hole vs. icon center
    static let squash = 0.965                                               // icon is slightly wider than tall
}

extension ExchangeRings {
    fileprivate static func draw(in context: inout GraphicsContext, size: CGSize,
                                 progress: Double, checkIn: Color, checkOut: Color) {
        let q = min(max(progress, 0), 1)
        let s = min(size.width, size.height)
        let r = s * 0.25

        // The composition mirrors as it changes, so the hole slides from right to left of center.
        let holeX = Icon.holeShift.x + (-Icon.holeShift.x - Icon.holeShift.x) * q
        context.translateBy(x: size.width / 2 + holeX * r,
                            y: size.height / 2 + Icon.holeShift.y * r - s * 0.015)
        context.scaleBy(x: 1, y: Icon.squash)

        // Everything except the hole.
        var clip = Path()
        clip.addRect(CGRect(x: -size.width * 2, y: -size.height * 2,
                            width: size.width * 4, height: size.height * 4))
        clip.addEllipse(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
        context.clip(to: clip, style: FillStyle(eoFill: true))

        // Check-in: icon front crescent -> mirrored back crescent.
        let inShape = Crescent.mix(Icon.front, Icon.back.mirrored, q)
        // Check-out: drawn on top the whole time; starts hidden at the hole's edge,
        // sweeps under and around, and ends as the mirrored front crescent.
        let outEnd = Icon.front.mirrored
        let outShape = Crescent(radius: 1.0 + (outEnd.radius - 1.0) * q,
                                offset: outEnd.offset * q,
                                angle: 150 + (outEnd.angle - 150) * q)

        fill(inShape, r: r, color: checkIn, in: &context)
        fill(outShape, r: r, color: checkOut, in: &context)
    }

    private static func fill(_ c: Crescent, r: Double, color: Color, in context: inout GraphicsContext) {
        guard c.radius > 1.0005 || c.offset > 0.001 else { return }  // fully hidden behind the hole
        let a = c.angle * .pi / 180
        let center = CGPoint(x: cos(a) * c.offset * r, y: sin(a) * c.offset * r)
        let R = c.radius * r
        context.fill(Path(ellipseIn: CGRect(x: center.x - R, y: center.y - R, width: R * 2, height: R * 2)),
                     with: .color(color))
    }
}

// MARK: - Ready-made player

/// Shows the check-in state, waits briefly, then plays the exchange once.
/// Respects Reduce Motion by jumping straight to the end state.
struct ExchangeRingsPlayer: View {
    var checkIn: Color
    var checkOut: Color
    var delay: Duration = .seconds(0.6)

    @State private var progress = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ExchangeRings(checkIn: checkIn, checkOut: checkOut, progress: progress)
            .task {
                progress = 0
                if reduceMotion { progress = 1; return }
                try? await Task.sleep(for: delay)
                withAnimation(.moodExchange) { progress = 1 }
            }
    }
}

// MARK: - Preview

#Preview("Exchange") {
    struct Demo: View {
        @State private var progress = 0.0
        var body: some View {
            VStack(spacing: 32) {
                ExchangeRings(checkIn: .purple, checkOut: .yellow, progress: progress)
                    .frame(width: 280)
                Button(progress < 0.5 ? "Check out" : "Reset") {
                    withAnimation(.moodExchange) { progress = progress < 0.5 ? 1 : 0 }
                }
                Slider(value: $progress).padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .preferredColorScheme(.dark)
        }
    }
    return Demo()
}
