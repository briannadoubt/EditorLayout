import AppKit
import EditorLayout
import SwiftUI

@main
struct EditorLayoutDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarDelegate {
    private var window: NSWindow?
    private var windowController: EditorSplitWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowController = EditorSplitWindowController(
            title: "Editor",
            configuration: EditorSplitConfiguration(
                sidebarMinimumWidth: 200,
                sidebarMaximumWidth: 340,
                inspectorMinimumWidth: 240,
                inspectorMaximumWidth: 380,
                bottomMinimumHeight: 140
            ),
            initialState: EditorSplitLayoutState(
                showsSidebar: true,
                showsInspector: true,
                showsBottomPanel: false
            )
        ) {
            PaneFillView(color: NSColor(srgbRed: 0.16, green: 0.19, blue: 0.24, alpha: 1))
        } content: {
            PaneFillView(color: NSColor(srgbRed: 0.10, green: 0.11, blue: 0.14, alpha: 1))
        } inspector: {
            PaneFillView(color: NSColor(srgbRed: 0.21, green: 0.15, blue: 0.18, alpha: 1))
        }
        self.windowController = windowController

        guard let window = windowController.window else {
            return
        }
        window.center()
        window.toolbarStyle = .unifiedCompact
        window.toolbar = makeToolbar()
        self.window = window
        windowController.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "EditorLayoutDemoToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        return toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .flexibleSpace, .toggleInspector]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .toggleInspector, .flexibleSpace]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard windowController != nil else {
            return nil
        }

        switch itemIdentifier {
        case .toggleSidebar:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Sidebar"
            item.image = NSImage(systemSymbolName: "sidebar.leading", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(toggleSidebar)
            return item

        case .toggleInspector:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Inspector"
            item.image = NSImage(systemSymbolName: "sidebar.trailing", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(toggleInspector)
            return item

        default:
            return nil
        }
    }

    @objc private func toggleSidebar() {
        guard let splitController = windowController?.editorSplitController else {
            return
        }

        splitController.setSidebarVisible(splitController.sidebarItem.isCollapsed)
    }

    @objc private func toggleInspector() {
        guard let splitController = windowController?.editorSplitController else {
            return
        }

        splitController.setInspectorVisible(splitController.inspectorItem.isCollapsed)
    }
}

private struct PaneFillView: View {
    let color: NSColor

    var body: some View {
        Color(nsColor: color)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension NSToolbarItem.Identifier {
    static let toggleSidebar = NSToolbarItem.Identifier("toggleSidebar")
    static let toggleInspector = NSToolbarItem.Identifier("toggleInspector")
}
