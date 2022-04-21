//
//  Routing.swift
//  JumpBar
//
//  Created by oanhof on 22.04.22.
//

import SwiftUI

struct DeepLinkInfo: Hashable {
    var pathComponents: [String]
    var queryItems: [URLQueryItem]
}

private struct DeepLinkInfoKey: EnvironmentKey {
    static let defaultValue: DeepLinkInfo = DeepLinkInfo(pathComponents: [], queryItems: [])
}

extension EnvironmentValues {
    var deepLinkInfo: DeepLinkInfo {
        get { self[DeepLinkInfoKey.self] }
        set { self[DeepLinkInfoKey.self] = newValue }
    }
}

private struct RoutingRootModifier: ViewModifier {
    @State
    private var deepLinkInfo = DeepLinkInfoKey.defaultValue
    
    func body(content: Content) -> some View {
        content
            .environment(\.deepLinkInfo, deepLinkInfo)
            .onOpenURL { url in
                let queryItems: [URLQueryItem]
                
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    queryItems = components.queryItems ?? []
                } else {
                    queryItems = []
                }
                
                deepLinkInfo = DeepLinkInfo(pathComponents: Array(url.pathComponents.dropFirst()), queryItems: queryItems)
            }
    }
}

private struct RouteModifier: ViewModifier {
    var handler: (DeepLinkInfo) -> DeepLinkInfo
    
    @Environment(\.deepLinkInfo)
    private var deepLinkInfo
    
    @State
    private var unhandledDeepLinkInfo = DeepLinkInfoKey.defaultValue
    
    func body(content: Content) -> some View {
        content
            .environment(\.deepLinkInfo, unhandledDeepLinkInfo)
            .onAppear {
                handle(info: deepLinkInfo)
            }
            .onChange(of: deepLinkInfo) { newValue in
                handle(info: newValue)
            }
    }
    
    func handle(info: DeepLinkInfo) {
        unhandledDeepLinkInfo = handler(info)
    }
}

extension View {
    func routingRoot() -> some View {
        modifier(RoutingRootModifier())
    }
    
    func route(debugName: String? = nil, handle: @escaping (DeepLinkInfo) -> DeepLinkInfo) -> some View {
        modifier(RouteModifier(handler: { info in
            if let debugName = debugName {
                print("[Routing] current view: \(debugName), pathComponents: \(info.pathComponents), queryItems: \(info.queryItems)")
            }
            return handle(info)
        }))
    }
}

