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

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Feel the difference every visit makes",
            message: "Check in with how you feel when you arrive at the gym and again when you leave.\n\nThen see how each workout shifts your mood.",
            icon: .spiral
        ),
        OnboardingPage(
            id: 1,
            title: "Name the feeling, then how strong it is",
            message: "When you check in, tap the feeling that fits you right now.\n\nThen slide to show how strong it is.",
            icon: .intensity
        ),
        OnboardingPage(
            id: 2,
            title: "Watch your journey take shape",
            message: "Every visit lands on your calendar, from how you walked in to how you left.\n\nFind out what makes you feel your best.",
            icon: .calendar
        ),
    ]
}

struct OnboardingView: View {
    var onFinish: () -> Void

    private let pages = OnboardingPage.all

    @State private var selection = 0
    /// Reset whenever the page changes so the icon animation replays.
    @State private var pageStart = Date.now

    private var isLastPage: Bool {
        selection == pages.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(pages) { page in
                    OnboardingPageView(page: page, start: pageStart)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

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
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: selection)
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
