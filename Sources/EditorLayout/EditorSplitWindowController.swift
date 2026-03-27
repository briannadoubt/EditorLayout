import AppKit
import SwiftUI

@MainActor
public extension EditorSplitController {
    convenience init<Sidebar: View, Content: View, Inspector: View>(
        configuration: EditorSplitConfiguration = .init(),
        initialState: EditorSplitLayoutState = .init(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector
    ) {
        self.init(
            sidebar: EditorHostingViewController(rootView: sidebar()),
            content: EditorHostingViewController(rootView: content()),
            inspector: EditorHostingViewController(rootView: inspector()),
            configuration: configuration,
            initialState: initialState
        )
    }

    convenience init<Sidebar: View, Content: View, Inspector: View, Bottom: View>(
        configuration: EditorSplitConfiguration = .init(),
        initialState: EditorSplitLayoutState = .init(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector,
        @ViewBuilder bottom: () -> Bottom
    ) {
        self.init(
            sidebar: EditorHostingViewController(rootView: sidebar()),
            content: EditorHostingViewController(rootView: content()),
            inspector: EditorHostingViewController(rootView: inspector()),
            bottom: EditorAnyHostingViewController(rootView: AnyView(bottom())),
            configuration: configuration,
            initialState: initialState
        )
    }
}

@MainActor
public final class EditorSplitWindowController: NSWindowController {
    public let editorSplitController: EditorSplitController

    public init(
        title: String = "Editor",
        configuration: EditorSplitConfiguration = .init(),
        initialState: EditorSplitLayoutState = .init(),
        windowRect: NSRect = NSRect(x: 0, y: 0, width: 1200, height: 780),
        styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable],
        @ViewBuilder sidebar: () -> some View,
        @ViewBuilder content: () -> some View,
        @ViewBuilder inspector: () -> some View
    ) {
        editorSplitController = EditorSplitController(
            configuration: configuration,
            initialState: initialState,
            sidebar: sidebar,
            content: content,
            inspector: inspector
        )

        let window = NSWindow(
            contentRect: windowRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = editorSplitController
        window.toolbarStyle = .unifiedCompact

        super.init(window: window)
    }

    public init(
        title: String = "Editor",
        configuration: EditorSplitConfiguration = .init(),
        initialState: EditorSplitLayoutState = .init(),
        windowRect: NSRect = NSRect(x: 0, y: 0, width: 1200, height: 780),
        styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable],
        @ViewBuilder sidebar: () -> some View,
        @ViewBuilder content: () -> some View,
        @ViewBuilder inspector: () -> some View,
        @ViewBuilder bottom: () -> some View
    ) {
        editorSplitController = EditorSplitController(
            configuration: configuration,
            initialState: initialState,
            sidebar: sidebar,
            content: content,
            inspector: inspector,
            bottom: bottom
        )

        let window = NSWindow(
            contentRect: windowRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = editorSplitController
        window.toolbarStyle = .unifiedCompact

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
