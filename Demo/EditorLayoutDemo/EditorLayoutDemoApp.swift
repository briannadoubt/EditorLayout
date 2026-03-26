import EditorLayout
import SwiftUI

@main
struct EditorLayoutDemoApp: App {
    @AppStorage("NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints") var visualizeMutuallyExclusiveConstraints: Bool = true
    init() {
        visualizeMutuallyExclusiveConstraints = true
    }
    var body: some SwiftUI.Scene {
        WindowGroup("Editor") {
            DemoEditorLayout()
        }
        .windowToolbarStyle(.unifiedCompact)
        .windowManagerRole(.automatic)
        .defaultLaunchBehavior(.presented)
        .menuBarExtraStyle(.window)
        .windowStyle(.automatic)
//        .defaultSize(width: 400, height: 200)
//        .windowResizability(.contentMinSize)
    }
}

private struct DemoEditorLayout: View {
    @State private var isSidebarPresented: Bool = true
    @State private var isInspectorPresented: Bool = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail

    var body: some View {
        EditorLayout(
            isSidebarPresented: $isSidebarPresented,
            isInspectorPresented: $isInspectorPresented,
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn,
        ) {
            List {
                Text("Rawr")
            }
        } content: {
            List {
                Text("Meow")
                    .padding()
            }
        } inspector: {
            List {}
        }
    }
}

#Preview("Editor Layout Demo") {
    DemoEditorLayout()
}
