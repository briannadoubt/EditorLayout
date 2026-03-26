import SwiftUI

/// A reusable editor-style shell that composes app content via view builders.
public struct EditorLayout<
    Sidebar: View,
    Content: View,
    Inspector: View
>: View {
    @Binding private var isInspectorPresented: Bool
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var preferredCompactColumn: NavigationSplitViewColumn

    private let sidebar: Sidebar
    private let content: Content
    private let inspector: Inspector

    public init(
        isInspectorPresented: Binding<Bool>,
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        preferredCompactColumn: Binding<NavigationSplitViewColumn>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector
    ) {
        _isInspectorPresented = isInspectorPresented
        _columnVisibility = columnVisibility
        _preferredCompactColumn = preferredCompactColumn
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
    }

    public var body: some View {
        NavigationSplitView(
//            columnVisibility: $columnVisibility,
//            preferredCompactColumn: $preferredCompactColumn
        ) {
            sidebar
                .navigationSplitViewColumnWidth(ideal: 280)
        } detail: {
            content
        }
        .inspector(isPresented: $isInspectorPresented) {
            inspector
                .interactionActivityTrackingTag("stuff")
                .inspectorColumnWidth(ideal: 280)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Inspector", systemImage: "sidebar.right") {
                            isInspectorPresented.toggle()
                        }
                    }
                }
        }
    }
}
