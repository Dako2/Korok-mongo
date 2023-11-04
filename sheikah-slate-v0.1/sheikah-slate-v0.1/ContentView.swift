//
//  ContentView.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.
//

import SwiftUI

struct ContentView2: View {
    @State private var selectedTab = 1 // Default to ChatView

    var body: some View {
        TabView(selection: $selectedTab) {
            ConfigView()
                .tag(0)

            ChatView()
                .tag(1)

            FullMapView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic)) // hides the dots
        //.edgesIgnoringSafeArea(.top) // to let the views use the entire screen
    }
}

struct ContentView: View {
    @State private var selectedTab = 2 // Default to ChatView
    let currentUser = User(id: UserSettings.shared.userUUID, name: "SomeName")
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConfigView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Configure")
                }
                .tag(0)

            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
                .tag(1)
            
            FullMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(2)
            
        }
        //.tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))

    }
}
