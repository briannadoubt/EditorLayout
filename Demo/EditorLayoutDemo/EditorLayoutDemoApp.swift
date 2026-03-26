import EditorLayout
import SwiftUI

@main
struct EditorLayoutDemoApp: App {
    var body: some SwiftUI.Scene {
        Window("Editor", id: "editor") {
            DemoEditorLayout()
        }
        .defaultSize(width: 900, height: 450)
    }
}

private struct DemoEditorLayout: View {
    @State private var showsSidebar = true
    @State private var showsInspector = true

    var body: some View {
        EditorView(
            showsSidebar: $showsSidebar,
            showsInspector: $showsInspector
        ) {
            EmptyView()
        } content: {
            EmptyView()
        } inspector: {
            List {}
                .listStyle(.sidebar)
        }
        .toolbar {
            Button("Sidebar", systemImage: "sidebar.left") {
                showsSidebar.toggle()
            }

            Button("Inspector", systemImage: "sidebar.right") {
                showsInspector.toggle()
            }
        }
    }
}

#Preview("Editor Layout Demo") {
    DemoEditorLayout()
}
