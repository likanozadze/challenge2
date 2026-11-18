//
//  EnergyBackground.swift
//  Challenge2
//

import SwiftUI

// Animated background for the onboarding: soft glows in the onboarding
// colors drift around slowly while small specks of energy float upwards.
// Use "EnergyBackground(page: ...)" behind any page; page can be 0 on screens without pages.

// We can change these values to quickly test how the background looks and moves
enum EnergySettings {

    // The glows: one per color, the same colors as the onboarding icons
    static let glowColors: [Color] = [
        Color(red: 1, green: 0x92 / 255, blue: 0x30 / 255), // orange, spiral
        Color(red: 1, green: 0xD6 / 255, blue: 0),          // yellow, burst
        Color(red: 0, green: 0x91 / 255, blue: 1),          // blue, calm
    ]
    // Where each glow sits (0 = left/top edge, 1 = right/bottom edge)
    static let glowAnchors: [CGPoint] = [
        CGPoint(x: 0.15, y: 0.18),
        CGPoint(x: 0.9, y: 0.5),
        CGPoint(x: 0.25, y: 0.88),
    ]
    // How strong and big they are (size is the diameter compared to the screen width)
    static let glowOpacity: Double = 0.13
    static let glowSize: CGFloat = 0.95
    // How fast they wander around their spot
    static let glowSpeed: Double = 0.11

    // How many energy specks and how big
    static let particleCount = 35
    static let minParticleSize: CGFloat = 1
    static let maxParticleSize: CGFloat = 2.2

    // How bright they are
    static let minOpacity: Double = 0.08
    static let maxOpacity: Double = 0.45

    // How fast they rise (screen heights per second) and twinkle
    static let riseSpeed: Double = 0.009
    static let twinkleSpeed: Double = 1.0

    // How much everything slides when changing page (in screen widths per page).
    // The specks move more than the glows, which gives a sense of depth.
    static let glowParallax: Double = 0.09
    static let particleParallax: Double = 0.22
}

struct EnergyBackground: View {
    // How far the pages have scrolled, in pages (1.5 = halfway between page 2 and 3).
    // Pass the live scroll position so the background moves together with the swipe.
    var page: Double = 0

    // If the user has reduceMotion ON, everything stays still
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Specks are created once, so they don't jump around when the view redraws
    @State private var particles: [EnergyParticle] = (0..<EnergySettings.particleCount).map { _ in EnergyParticle.random() }

    var body: some View {
        // TimelineView redraws every frame, canvas draws everything in one go
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            let page = reduceMotion ? 0 : self.page

            Canvas { canvas, size in
                drawGlows(in: &canvas, size: size, time: time, page: page)
                drawParticles(in: &canvas, size: size, time: time, page: page)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawGlows(in canvas: inout GraphicsContext, size: CGSize, time: Double, page: Double) {
        for (index, color) in EnergySettings.glowColors.enumerated() {
            let anchor = EnergySettings.glowAnchors[index % EnergySettings.glowAnchors.count]
            // Each glow gets its own speed and offset so they don't move together
            let offset = Double(index) * 2.1
            let speed = EnergySettings.glowSpeed * (1 + 0.3 * Double(index))

            // Slow wandering loop around the anchor, plus the page slide
            let x = anchor.x + 0.12 * sin(time * speed + offset) - page * EnergySettings.glowParallax
            let y = anchor.y + 0.08 * cos(time * speed * 0.8 + offset)
            let center = CGPoint(x: x * size.width, y: y * size.height)

            // Gently breathes in size
            let radius = size.width * EnergySettings.glowSize / 2 * (1 + 0.08 * sin(time * 0.3 + offset))

            // A radial gradient that fades to clear gives the soft glow without needing a blur
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let gradient = Gradient(colors: [color.opacity(EnergySettings.glowOpacity), color.opacity(0)])
            canvas.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius)
            )
        }
    }

    private func drawParticles(in canvas: inout GraphicsContext, size: CGSize, time: Double, page: Double) {
        for particle in particles {
            // Small side to side sway, and move with the page slide.
            // Faster specks follow the slide more, which gives a sense of depth.
            let rawX = particle.x
                + sin(time * 0.4 + particle.phase) * 0.01
                - page * EnergySettings.particleParallax * particle.speed

            // Float upwards
            let rawY = particle.y - time * EnergySettings.riseSpeed * particle.speed

            // Wrap around, so a speck leaving one edge comes back on the other
            let x = rawX - rawX.rounded(.down)
            let y = rawY - rawY.rounded(.down)

            // Twinkle, brightness goes smoothly up and down
            let twinkle = (sin(time * EnergySettings.twinkleSpeed * particle.speed + particle.phase) + 1) / 2
            let opacity = EnergySettings.minOpacity + (EnergySettings.maxOpacity - EnergySettings.minOpacity) * twinkle

            let rect = CGRect(
                x: x * size.width - particle.size / 2,
                y: y * size.height - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            canvas.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
        }
    }
}

// Struct for one speck of energy: where it starts, how big it is and its own speed, so they don't all move together.
private struct EnergyParticle {
    let x: Double       // 0 = left edge, 1 = right edge
    let y: Double       // 0 = top, 1 = bottom
    let size: CGFloat
    let speed: Double
    let phase: Double   // offsets the twinkle so specks don't blink in sync

    // Randomizes the settings of a speck
    static func random() -> EnergyParticle {
        EnergyParticle(
            x: .random(in: 0...1),
            y: .random(in: 0...1),
            size: .random(in: EnergySettings.minParticleSize...EnergySettings.maxParticleSize),
            speed: .random(in: 0.5...1.5),
            phase: .random(in: 0...(2 * .pi))
        )
    }
}

#Preview {
    EnergyBackground()
        .background(.black)
}
