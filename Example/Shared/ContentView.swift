//
//  ContentView.swift
//  Shared
//
//  Created by oanhof on 20.04.22.
//

import SwiftUI

struct ContentView: View {
    @State
    private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
            }
            .tabItem {
                Label("Tab 1", systemImage: "globe")
            }
            .tag(1)
            
            NavigationView {
                SecondView()
            }
            .tabItem {
                Label("Tab 2", systemImage: "globe")
            }
            .tag(2)
        }
        .route(debugName: "ContentView") { info in
            var info = info
            
            if info.pathComponents.count > 1,
               info.pathComponents[0] == "tab",
               let tab = Int(info.pathComponents[1]) {
                selectedTab = tab
                info.pathComponents.removeFirst(2)
            }

            return info
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
