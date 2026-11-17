//
//  Challenge2App.swift
//  Challenge2
//
//  Created by Lika Nozadze on 16/11/2026.
//

import SwiftUI

@main
struct Challenge2App: App {
    /// Onboarding is only shown until the user taps "Get started" once.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene
    {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            // The app is dark-only.
            .preferredColorScheme(.dark)
        }
    }
}
