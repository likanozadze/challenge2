//
//  OnboardingView.swift
//  Challenge2
//

import SwiftUI

struct OnboardingPage: Identifiable {
    enum Icon {
        case spiral, intensity, calendar
    }

    let id: Int
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let icon: Icon
    /// The icon's color, used to tint the background light.
    let color: Color

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Feel the difference every visit makes",
            message: "Check in with how you feel when you arrive at the gym and again when you leave.\n\nThen see how each workout shifts your mood.",
            icon: .spiral,
            color: Color(red: 1, green: 0x92 / 255, blue: 0x30 / 255)
        ),
        OnboardingPage(
            id: 1,
            title: "Name the feeling, then how strong it is",
            message: "When you check in, tap the feeling that fits you right now.\n\nThen slide to show how strong it is.",
            icon: .intensity,
            color: Color(red: 1, green: 0xD6 / 255, blue: 0)
        ),
        OnboardingPage(
            id: 2,
            title: "Watch your journey take shape",
            message: "Every visit lands on your calendar, from how you walked in to how you left.\n\nFind out what makes you feel your best.",
            icon: .calendar,
            color: Color(red: 0, green: 0x91 / 255, blue: 1)
        ),
    ]
}

struct OnboardingView: View {
    var onFinish: () -> Void

    private let pages = OnboardingPage.all

    /// The page the scroll view has settled on.
    @State private var scrolledPage: Int? = 0
    /// How far the pages have scrolled, in pages (e.g. 0.5 = halfway to page 2).
    /// Updated live while swiping, so the background moves with the finger.
    @State private var scrollProgress: Double = 0
    /// Reset whenever the page changes so the icon animation replays.
    @State private var pageStart = Date.now

    private var selection: Int {
        scrolledPage ?? 0
    }

    private var isLastPage: Bool {
        selection == pages.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // A paging scroll view (instead of a page TabView) so we can
            // read the live scroll offset for the background.
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page, start: pageStart)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(page.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $scrolledPage)
            .onScrollGeometryChange(for: Double.self) { geometry in
                guard geometry.containerSize.width > 0 else { return 0 }
                return (geometry.contentOffset.x + geometry.contentInsets.leading) / geometry.containerSize.width
            } action: { _, progress in
                scrollProgress = progress
            }

            Group {
                PageIndicator(count: pages.count, selection: selection)

                Button(action: onFinish) {
                    Text("Get started")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(.white, in: .capsule)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 22)
                .padding(.top, 44)
                .padding(.bottom, 8)
                // Keep the button's space reserved so the indicator doesn't jump.
                .opacity(isLastPage ? 1 : 0)
                .disabled(!isLastPage)
                .accessibilityHidden(!isLastPage)
            }
            // Only the indicator and button animate on page change; the
            // background follows the scroll directly, with no delay.
            .animation(.easeInOut(duration: 0.25), value: selection)
        }
        .background {
            ZStack {
                Color.black
                // The light takes the color of the page's icon and blends while swiping
                MoodLight(colors: pages.map(\.color), position: scrollProgress)
                FilmGrain()
            }
            .ignoresSafeArea()
        }
        .onChange(of: selection) {
            pageStart = .now
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let start: Date

    var body: some View {
        VStack(spacing: 0) {
            Text(page.title)
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 44)

            // Fixed height so titles and text line up across pages.
            icon
                .frame(height: 290)
                .padding(.vertical, 40)

            Text(page.message)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var icon: some View {
        switch page.icon {
        case .spiral:
            SpiralIcon(start: start)
                .frame(width: 150, height: 180)
        case .intensity:
            IntensityIllustration(start: start)
        case .calendar:
            CalendarIllustration(start: start)
        }
    }
}

private struct PageIndicator: View {
    let count: Int
    let selection: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == selection ? Color.white : Color(white: 0.3))
                    .frame(width: index == selection ? 20 : 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(selection + 1) of \(count)")
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .preferredColorScheme(.dark)
}
