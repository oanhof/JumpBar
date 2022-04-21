//
//  JumpBarApp.swift
//  Shared
//
//  Created by oanhof on 20.04.22.
//

import SwiftUI
import JumpBar

@main
struct JumpBarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"]) // avoid opening a new window with openURL on macOS
                .routingRoot()
                .jumpBar(provider: TestJumpBarProvider())
        }
    }
}

struct TestJumpBarProvider: JumpBarProvider {
    func suggestions(for text: String) async -> [JumpBarSuggestion] {
        let results = [
            JumpBarSuggestion(title: "Tab 1", url: URL(string: "jumpbar://root/tab/1")!),
            JumpBarSuggestion(title: "Tab 2", url: URL(string: "jumpbar://root/tab/2")!),
            JumpBarSuggestion(title: "Tab 2 / View 1", url: URL(string: "jumpbar://root/tab/2/view/1")!),
            JumpBarSuggestion(title: "Tab 2 / View 2", url: URL(string: "jumpbar://root/tab/2/view/2")!),
            JumpBarSuggestion(title: "Tab 2 / View 3", url: URL(string: "jumpbar://root/tab/2/view/3")!)
        ]
        
        return results
            .filter { $0.title.localizedCaseInsensitiveContains(text) }
    }
}
