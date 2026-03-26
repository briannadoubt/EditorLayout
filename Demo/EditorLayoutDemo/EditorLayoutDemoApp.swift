import EditorLayout
import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

@main
struct EditorLayoutDemoApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup("EditorLayout Demo") {
            DemoEditorLayout()
                .frame(minWidth: 960, minHeight: 640)
        }
        .defaultSize(width: 1280, height: 820)

        Settings {
            VStack(alignment: .leading, spacing: 12) {
                Text("EditorLayout Demo")
                    .font(.title2.bold())
                Text("This app hosts a sample shell built with the package's reusable EditorLayout container.")
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 420)
        }
    }
}

private struct DemoEditorLayout: View {
    @SceneStorage("editor.showLeftSidebar") private var showLeftSidebar: Bool = true
    @SceneStorage("editor.showInspector") private var showInspector: Bool = true
    @SceneStorage("editor.showBottomPanel") private var showBottomPanel: Bool = true

    @SceneStorage("editor.leftWidth") private var leftWidth: Double = 260
    @SceneStorage("editor.inspectorWidth") private var inspectorWidth: Double = 320
    @SceneStorage("editor.bottomHeight") private var bottomHeight: Double = 220

    var body: some View {
        EditorLayout(
            showsLeftSidebar: $showLeftSidebar,
            showsInspector: $showInspector,
            showsBottomPanel: $showBottomPanel,
            metrics: EditorLayoutMetrics(
                leftIdealWidth: leftWidth,
                rightIdealWidth: inspectorWidth,
                bottomIdealHeight: bottomHeight
            )
        ) {
            LeftSidebarView()
        } content: {
            EditorViewport()
                .background(Color.black)
        } inspector: {
            RightSidebarView()
                .background(.regularMaterial)
        } bottomPanel: {
            BottomPanelView()
        }
        .toolbar { toolbarContent }
        .overlay(alignment: .bottomTrailing) { bottomRightOverlay }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                withAnimation(.snappy) { showLeftSidebar.toggle() }
            } label: {
                Label("Toggle Left Sidebar", systemImage: "sidebar.leading")
            }
            .help("Show or hide the left sidebar")
            .keyboardShortcut("s", modifiers: [.command, .option])
        }

        ToolbarItem(placement: .automatic) {
            Button {
                withAnimation(.snappy) { showInspector.toggle() }
            } label: {
                Label("Toggle Inspector", systemImage: "sidebar.trailing")
            }
            .help("Show or hide the inspector")
            .keyboardShortcut("i", modifiers: [.command, .option])
        }

        ToolbarItem(placement: .automatic) {
            Button {
                withAnimation(.snappy) { showBottomPanel.toggle() }
            } label: {
                Label("Toggle Bottom Panel", systemImage: "rectangle.bottomthird.inset.filled")
            }
            .help("Show or hide the bottom panel")
            .keyboardShortcut("j", modifiers: [.command, .option])
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("Editor")
                    .font(.headline)
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var statusLine: String {
        var parts: [String] = []
        parts.append(showLeftSidebar ? "Left: On" : "Left: Off")
        parts.append(showInspector ? "Inspector: On" : "Inspector: Off")
        parts.append(showBottomPanel ? "Bottom: On" : "Bottom: Off")
        return parts.joined(separator: "  •  ")
    }

    @ViewBuilder
    private var bottomRightOverlay: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.snappy) { showBottomPanel.toggle() }
            } label: {
                Image(systemName: showBottomPanel ? "rectangle.bottomthird.inset.filled" : "rectangle.bottomthird.inset")
            }
            .help("Toggle bottom panel")

            Button {
                withAnimation(.snappy) { showInspector.toggle() }
            } label: {
                Image(systemName: "sidebar.trailing")
            }
            .help("Toggle inspector")
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(8)
        .editorOverlayButtonStyle()
    }
}

private extension View {
    @ViewBuilder
    func editorOverlayButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}

private struct LeftSidebarView: View {
    var body: some View {
        List {
            Section("Project") {
                ForEach(0..<12, id: \.self) { index in
                    Label("Item \(index + 1)", systemImage: "doc")
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct RightSidebarView: View {
    @State private var snapToGrid = true
    @State private var showGuides = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Inspector")
                    .font(.headline)
                Divider()

                GroupBox("Scene") {
                    VStack(alignment: .leading) {
                        Toggle("Snap to grid", isOn: $snapToGrid)
                        Toggle("Show guides", isOn: $showGuides)
                    }
                }

                GroupBox("Selection") {
                    VStack(alignment: .leading) {
                        LabeledContent("Name") {
                            TextField("Untitled", text: .constant("Entity"))
                        }
                        LabeledContent("Position") {
                            Text("0, 0, 0").monospaced()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
}

private struct BottomPanelView: View {
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Console", systemImage: "terminal")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.9))
                .foregroundStyle(.green)
        }
    }
}

private struct EditorViewport: View {
    var body: some View {
        BlankRealityView()
            .overlay(alignment: .topLeading) {
                Text("RealityView")
                    .font(.caption2)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
                    .opacity(0.6)
            }
    }
}

private struct BlankRealityView: View {
    var body: some View {
        #if canImport(RealityKit)
        if #available(macOS 15.0, *) {
            RealityView { _ in
            }
            .ignoresSafeArea(edges: [])
        } else {
            Color.black
        }
        #else
        Color.black
        #endif
    }
}

#Preview("Editor Layout Demo") {
    DemoEditorLayout()
        .frame(width: 1200, height: 800)
}
