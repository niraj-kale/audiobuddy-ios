//
//  ContentView.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 04/12/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            RecordingsListView()
                .tabItem {
                    Label("Recordings", systemImage: "waveform")
                }
                .tag(AppState.Tab.recordings)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppState.Tab.search)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppState.Tab.settings)
        }
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
}
