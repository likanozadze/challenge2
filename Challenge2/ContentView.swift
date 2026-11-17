//
//  ContentView.swift
//  Challenge2
//
//  Created by Lika Nozadze on 16/11/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MoodCheckInView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
