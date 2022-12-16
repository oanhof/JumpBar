//
//  JumpBar.swift
//  JumpBar
//
//  Created by oanhof on 20.04.22.
//

import SwiftUI

public struct JumpBarSuggestion: Identifiable, Hashable {
    public var url: URL
    public var view: AnyView
    
    public var id: URL { url }
    
    public init(url: URL, @ViewBuilder view: () -> any View) {
        self.url = url
        self.view = AnyView(view())
    }
    
    public init(title: String, url: URL) {
        self.init(url: url) {
            Text(title)
        }
    }
    
    public static func == (lhs: JumpBarSuggestion, rhs: JumpBarSuggestion) -> Bool {
        lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

@MainActor
public protocol JumpBarProvider: ObservableObject {
    /// should be declared as @Published
    var suggestions: [JumpBarSuggestion] { get }
    
    func update(query: String) async
}

struct JumpBar<Content: View, Provider: JumpBarProvider>: View {
    @State
    private var barShown = false
    
    @State
    private var text = ""
    
    @FocusState
    private var textFieldFocused: Bool
    
    @State
    private var focusedSuggestion: JumpBarSuggestion?
    
    @Environment(\.openURL)
    private var openURL
    
    private let content: Content
    
    @StateObject
    private var provider: Provider
    
    init(provider: Provider, @ViewBuilder _ content: () -> Content) {
        self.content = content()
        self._provider = StateObject(wrappedValue: provider)
    }
    
    var body: some View {
        content
            .overlay {
                if barShown {
                    ZStack {
                        Rectangle()
                            .fill(.black.opacity(0.1))
                            .ignoresSafeArea()
                            .zIndex(2)
                            .onTapGesture {
                                barShown = false
                            }
                        
                        VStack {
                            JumpBarField(placeholder: "Jump to...", text: $text, onArrowUp: {
                                guard let focused = focusedSuggestion,
                                      let idx = provider.suggestions.firstIndex(of: focused),
                                        idx - 1 >= 0 else { return }
                                
                                focusedSuggestion = provider.suggestions[idx - 1]
                            }, onArrowDown: {
                                guard let focused = focusedSuggestion,
                                      let idx = provider.suggestions.firstIndex(of: focused),
                                      provider.suggestions.count > idx + 1 else { return }
                                
                                focusedSuggestion = provider.suggestions[idx + 1]
                            }, onSubmit: {
                                if let suggestion = focusedSuggestion {
                                    trigger(suggestion: suggestion)
                                }
                            })
                            .focused($textFieldFocused)
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                            .padding(.horizontal)
                            .offset(y: provider.suggestions.isEmpty ? -50 : 0)
                            
                            if !provider.suggestions.isEmpty {
                                ScrollView {
                                    ScrollViewReader { proxy in
                                        VStack(spacing: 0) {
                                            ForEach(provider.suggestions) { suggestion in
                                                Button {
                                                    trigger(suggestion: suggestion)
                                                } label: {
                                                    AnyView(suggestion.view)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .padding(.horizontal)
                                                        .padding(.vertical, 5)
                                                        .contentShape(Rectangle())
                                                }
                                                .buttonStyle(.plain)
                                                .padding(.vertical, 8)
                                                .id(suggestion)
                                                .background {
                                                    if focusedSuggestion == suggestion {
                                                        Color.gray.opacity(0.4)
                                                    }
                                                }
                                                
                                                Divider()
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        .onChange(of: focusedSuggestion) { newValue in
                                            proxy.scrollTo(newValue)
                                        }
                                    }
                                }
                                .background(.thinMaterial)
                                .frame(maxHeight: 500)
                                .fixedSize(horizontal: false, vertical: true)
                                .cornerRadius(12)
                                .shadow(radius: 10)
                                .padding()
                            }
                        }
                        .frame(maxWidth: 600)
                        .zIndex(3)
                        .task(id: text) {
                            await provider.update(query: text)
                        }
                    }
                    .onChange(of: provider.suggestions) { newValue in
                        if focusedSuggestion == nil {
                            focusedSuggestion = newValue.first
                        } else if let focusedSuggestion, !newValue.contains(focusedSuggestion) {
                            self.focusedSuggestion = newValue.first
                        }
                    }
                }
            }
            .keyboardShortcut("k", modifiers: .command) {
                barShown.toggle()
                
                if barShown == true {
                    textFieldFocused = true
                }
            }
            .animation(.default, value: barShown)
            .animation(.default, value: provider.suggestions)
    }
    
    func trigger(suggestion: JumpBarSuggestion) {
        barShown = false
        openURL(suggestion.url)
    }
}

struct JumpBar_Previews: PreviewProvider {
    static var previews: some View {
        JumpBar(provider: MockJumpBarProvider()) {
            Text("Test")
        }
    }
}

struct JumpBarModifier<Provider: JumpBarProvider>: ViewModifier {
    let provider: Provider
    
    func body(content: Content) -> some View {
        JumpBar(provider: provider) {
            content
        }
    }
}

extension View {
    public func jumpBar<Provider: JumpBarProvider>(provider: Provider) -> some View {
        modifier(JumpBarModifier(provider: provider))
    }
}

private class MockJumpBarProvider: JumpBarProvider {
    @Published
    var suggestions = [JumpBarSuggestion]()
    
    func update(query: String) async {
        suggestions = [
            JumpBarSuggestion(title: "Suggestion 1", url: URL(string: "jumpbar://suggestion1")!),
            JumpBarSuggestion(title: "Suggestion 2", url: URL(string: "jumpbar://suggestion2")!)
        ]
    }
}

struct KeyboardShortcutModifier: ViewModifier {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .background {
                Button {
                    action()
                } label: {
                    EmptyView()
                }
                .opacity(0)
                .keyboardShortcut(key, modifiers: modifiers)
            }
    }
}

extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        modifier(KeyboardShortcutModifier(key: key, modifiers: modifiers, action: action))
    }
}

struct JumpBarField: View {
    let placeholder: String
    
    @Binding
    var text: String
    
    let onArrowUp: () -> Void
    let onArrowDown: () -> Void
    let onSubmit: () -> Void
    
    var body: some View {
        PlatformJumpBarField(placeholder: placeholder, text: $text, onArrowUp: onArrowUp, onArrowDown: onArrowDown, onSubmit: onSubmit)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if canImport(UIKit)

class CustomTextField: UITextField, UITextFieldDelegate {
    var onArrowUp: (() -> Void)?
    var onArrowDown: (() -> Void)?
    var onSubmit: (() -> Void)?
    
    init(onArrowUp: (() -> Void)? = nil, onArrowDown: (() -> Void)? = nil, onSubmit: (() -> Void)? = nil) {
        self.onArrowUp = onArrowUp
        self.onArrowDown = onArrowDown
        self.onSubmit = onSubmit
        
        super.init(frame: .zero)
        
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        switch presses.first?.key?.keyCode {
        case .keyboardUpArrow:
            onArrowUp?()
        case .keyboardDownArrow:
            onArrowDown?()
//        case .keyboardReturnOrEnter:
//            onSubmit?()
        default:
            super.pressesBegan(presses, with: event)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSubmit?()
        return false
    }
}

struct PlatformJumpBarField: UIViewRepresentable {
    let placeholder: String
    
    @Binding
    var text: String
    
    let onArrowUp: () -> Void
    let onArrowDown: () -> Void
    let onSubmit: () -> Void
    
    func makeUIView(context: Context) -> CustomTextField {
        let field = CustomTextField()
        
        field.addAction(UIAction(handler: { action in
            text = (action.sender as? UITextField)?.text ?? ""
        }), for: .editingChanged)
        
        return field
    }
    
    func updateUIView(_ uiView: CustomTextField, context: Context) {
        uiView.placeholder = placeholder
        uiView.text = text
        uiView.onArrowUp = onArrowUp
        uiView.onArrowDown = onArrowDown
        uiView.onSubmit = onSubmit
    }
}

#else

struct PlatformJumpBarField: View {
    let placeholder: String
    
    @Binding
    var text: String
    
    let onArrowUp: () -> Void
    let onArrowDown: () -> Void
    let onSubmit: () -> Void
    
    @FocusState
    private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onSubmit(onSubmit)
            .keyboardShortcut(.upArrow, modifiers: [], action: onArrowUp)
            .keyboardShortcut(.downArrow, modifiers: [], action: onArrowDown)
            .onAppear { isFocused = true }
    }
}

#endif
