import SwiftUI

@MainActor public struct ToggleSidebarAction: Identifiable, Equatable {
    
    public let id: String
    
    public nonisolated init(id: String) {
        self.id = id
    }
    
    public func callAsFunction() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)),
            with: nil
        )
    }
}

public extension EnvironmentValues {
    @Entry var toggleSidebar: ToggleSidebarAction = .init(id: "toggleSidebar")
}

/// A reusable editor-style shell that composes app content via view builders.
public struct EditorLayout<
    Sidebar: View,
    Content: View,
    Inspector: View
>: View {
    @Binding private var isSidebarPresented: Bool
    @Binding private var isInspectorPresented: Bool
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var preferredCompactColumn: NavigationSplitViewColumn

    private let sidebar: Sidebar
    private let content: Content
    private let inspector: Inspector

    public init(
        isSidebarPresented: Binding<Bool>,
        isInspectorPresented: Binding<Bool>,
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        preferredCompactColumn: Binding<NavigationSplitViewColumn>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector
    ) {
        _isSidebarPresented = isSidebarPresented
        _isInspectorPresented = isInspectorPresented
        _columnVisibility = columnVisibility
        _preferredCompactColumn = preferredCompactColumn
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
    }

    public var body: some View {
//        NavigationSplitView {
//            sidebar
//                .listStyle(.sidebar)
//                .navigationSplitViewColumnWidth(ideal: 270)
//        } detail: {
//            content
//                .scrollEdgeEffectStyle(.soft, for: .top)
//                .frame(minWidth: 320)
//        }
//        .navigationSplitViewStyle(.balanced)
        NavigationView {
            sidebar
                .listStyle(.sidebar)
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .frame(minWidth: 320)
        }
        .inspector(isPresented: $isInspectorPresented) {
            inspector
                .listStyle(.sidebar)
                .inspectorColumnWidth(min: 100, ideal: 270, max: 599)
                .toolbar {
                    Button("Inspector", systemImage: "sidebar.right") {
                        isInspectorPresented.toggle()
                    }
                }
        }
    }
}
