//
//  ContentView.swift
//  AudioBuddy
//
//  Main content view with tab navigation.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
            
            RecordingsListView()
                .tabItem {
                    Label("Recordings", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}
