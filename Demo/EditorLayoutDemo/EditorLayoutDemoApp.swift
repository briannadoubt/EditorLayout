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
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = DemoWorkspaceModel()
    private var window: NSWindow?
    private var windowController: EditorSplitWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowController = EditorSplitWindowController(
            title: "EditorLayout Demo",
            configuration: EditorSplitConfiguration(
                sidebarMinimumWidth: 220,
                sidebarMaximumWidth: 360,
                contentMinimumWidth: 520,
                inspectorMinimumWidth: 260,
                inspectorMaximumWidth: 380,
                bottomMinimumHeight: 150
            ),
            initialState: model.layoutState,
            windowRect: NSRect(x: 0, y: 0, width: 1440, height: 840),
            sidebarBackgroundMaterial: .sidebar,
            inspectorBackgroundMaterial: .sidebar
        ) {
            DemoSidebarView(model: model)
        } content: {
            DemoContentView(model: model)
        } inspector: {
            DemoInspectorView(model: model)
        } bottom: {
            DemoConsoleView(model: model)
        }
        windowController.layoutStateDidChange = { [weak self] state in
            self?.model.syncLayoutState(state)
        }
        self.windowController = windowController

        guard let window = windowController.window else {
            return
        }

        window.setFrameAutosaveName("EditorLayoutDemoWindow")
        window.setFrame(NSRect(x: 0, y: 0, width: 1440, height: 840), display: false)
        window.center()
        window.minSize = NSSize(width: 1240, height: 720)
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
        window.toolbar = nil
        self.window = window

        model.record("Booted the demo workspace")
        windowController.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@MainActor
final class DemoWorkspaceModel: ObservableObject {
    @Published var layoutState = DemoLayoutPreset.build.layoutState
    @Published var activePreset: DemoLayoutPreset = .build
    @Published var selectedFile: DemoFile = .splitController
    @Published var logs: [DemoLogEntry] = [
        DemoLogEntry(message: "Loaded split view controllers"),
        DemoLogEntry(message: "Prepared live layout telemetry"),
        DemoLogEntry(message: "Waiting for your next move")
    ]

    func syncLayoutState(_ state: EditorSplitLayoutState) {
        layoutState = state
    }

    func record(_ message: String) {
        logs.insert(DemoLogEntry(message: message), at: 0)
        if logs.count > 14 {
            logs.removeLast(logs.count - 14)
        }
    }
}

@MainActor
enum DemoLayoutPreset: Int, CaseIterable {
    case build
    case review
    case focus

    var title: String {
        switch self {
        case .build:
            "Build"
        case .review:
            "Review"
        case .focus:
            "Focus"
        }
    }

    var shortTitle: String {
        switch self {
        case .build:
            "Build"
        case .review:
            "Review"
        case .focus:
            "Focus"
        }
    }

    var layoutState: EditorSplitLayoutState {
        switch self {
        case .build:
            EditorSplitLayoutState(
                sidebarWidth: 260,
                inspectorWidth: 300,
                bottomHeight: 190,
                showsSidebar: true,
                showsInspector: true,
                showsBottomPanel: true
            )

        case .review:
            EditorSplitLayoutState(
                sidebarWidth: 240,
                inspectorWidth: 340,
                bottomHeight: 220,
                showsSidebar: true,
                showsInspector: true,
                showsBottomPanel: false
            )

        case .focus:
            EditorSplitLayoutState(
                sidebarWidth: 240,
                inspectorWidth: 320,
                bottomHeight: 180,
                showsSidebar: false,
                showsInspector: false,
                showsBottomPanel: false
            )
        }
    }
}

enum DemoFile: String, CaseIterable, Identifiable {
    case splitView = "EditorSplitView.swift"
    case splitController = "EditorSplitController.swift"
    case windowController = "EditorSplitWindowController.swift"
    case hostingControllers = "EditorHostingControllers.swift"
    case demoApp = "EditorLayoutDemoApp.swift"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .splitView:
            "square.split.2x1"
        case .splitController:
            "slider.horizontal.below.rectangle"
        case .windowController:
            "macwindow"
        case .hostingControllers:
            "rectangle.stack"
        case .demoApp:
            "sparkles.rectangle.stack"
        }
    }

    var summary: String {
        switch self {
        case .splitView:
            "Two-way SwiftUI bridge"
        case .splitController:
            "Native AppKit split orchestration"
        case .windowController:
            "Window-sized chrome wrapper"
        case .hostingControllers:
            "View embedding and materials"
        case .demoApp:
            "Preset-driven demo shell"
        }
    }

    var snippet: String {
        switch self {
        case .splitView:
            """
            public struct EditorSplitView: NSViewControllerRepresentable {
                @Binding private var showsSidebar: Bool
                @Binding private var showsInspector: Bool
                @Binding private var showsBottomPanel: Bool

                public func updateNSViewController(
                    _ controller: EditorSplitController,
                    context: Context
                ) {
                    controller.applyLayoutState(resolvedLayoutState())
                }
            }
            """

        case .splitController:
            """
            public final class EditorSplitController: NSSplitViewController {
                public var layoutStateDidChange: ((EditorSplitLayoutState) -> Void)?

                public func applyLayoutState(_ state: EditorSplitLayoutState) {
                    applyVisibility(...)
                    applyLayoutMeasurements(using: state)
                }
            }
            """

        case .windowController:
            """
            public final class EditorSplitWindowController: NSWindowController {
                public func setSidebarVisible(_ isVisible: Bool) { ... }
                public func setInspectorVisible(_ isVisible: Bool) { ... }
                public func applyLayoutState(_ state: EditorSplitLayoutState) { ... }
            }
            """

        case .hostingControllers:
            """
            final class EditorHostingViewController<Root: View>: NSViewController {
                init(rootView: Root, backgroundMaterial: NSVisualEffectView.Material? = nil) {
                    hostingController = NSHostingController(rootView: rootView)
                }
            }
            """

        case .demoApp:
            """
            let windowController = EditorSplitWindowController(
                sidebarBackgroundMaterial: .sidebar,
                inspectorBackgroundMaterial: .sidebar
            ) {
                DemoSidebarView(model: model)
            } content: {
                DemoContentView(model: model)
            } inspector: {
                DemoInspectorView(model: model)
            } bottom: {
                DemoConsoleView(model: model)
            }
            """
        }
    }
}

struct DemoLogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let message: String
}
