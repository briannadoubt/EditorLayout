import EditorLayout
import SwiftUI

@main
struct EditorLayoutDemoApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            DemoEditorLayout()
        }
        .windowToolbarStyle(.unifiedCompact)
        .defaultLaunchBehavior(.presented)
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

private struct DemoEditorLayout: View {
    @State private var isInspectorPresented: Bool = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail

    var body: some View {
        EditorLayout(
            isInspectorPresented: $isInspectorPresented,
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn,
        ) {
            ZStack {}
        } content: {
            ZStack {}
        } inspector: {
            ZStack {}
        }
    }
}

#Preview("Editor Layout Demo") {
    DemoEditorLayout()
}
