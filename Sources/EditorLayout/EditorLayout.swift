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
    @Entry var toggleSidebar = ToggleSidebarAction(id: "toggleSidebar")
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
        // MARK: NavigationSplitView (Works the best, inspector has bad bugs when resizing)
        NavigationSplitView {
            sidebar
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 190, ideal: 270)
        } detail: {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .frame(minWidth: 240, idealWidth: 320)
                .layoutPriority(1)
        }
        .navigationSplitViewStyle(.balanced)
        .inspector(isPresented: $isInspectorPresented) {
            inspector
                .listStyle(.sidebar)
                .inspectorColumnWidth(min: 190, ideal: 270, max: 599)
                .toolbar {
                    Button("Inspector", systemImage: "sidebar.right") {
                        isInspectorPresented.toggle()
                    }
                }
        }
        
        // MARK: NavigationView (Looks the best, inspector has same problems and can't collapse sidebar
//        NavigationView {
//            sidebar
//                .listStyle(.sidebar)
//                .navigationSplitViewColumnWidth(min: 100, ideal: 270, max: 270)
//            content
//                .scrollEdgeEffectStyle(.soft, for: .top)
//                .frame(minWidth: 320)
//        }
        
        // MARK: HSplitView (Doesn't work without a lot of customization
//        HSplitView {
//            if isSidebarPresented {
//                sidebar
//                    .listStyle(.sidebar)
//                    .frame(minWidth: 100, idealWidth: 270)
//            }
//            content
//                .scrollEdgeEffectStyle(.soft, for: .top)
//                .headerProminence(isSidebarPresented ? .increased : .standard)
//                .frame(minWidth: 320)
//            if isInspectorPresented {
//                inspector
//                    .listStyle(.sidebar)
//                    .frame(minWidth: 100, idealWidth: 270)
//            }
//        }
//        .toolbar {
//            ToolbarItem(placement: .navigation) {
//                Button("Inspector", systemImage: "sidebar.left") {
//                    isSidebarPresented.toggle()
//                }
//            }
//            ToolbarItem(placement: .primaryAction) {
//                Button("Inspector", systemImage: "sidebar.right") {
//                    isInspectorPresented.toggle()
//                }
//            }
//        }
    }
}
