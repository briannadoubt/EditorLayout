import AppKit
import SwiftUI

@MainActor
enum EditorSplitWindowResizeEdge {
    case leading
    case trailing
}

public enum EditorSplitWindowSidebarToggleBehavior: Sendable {
    case keepsWindowFrame
    case preservesContentWidth
}

@MainActor
func adjustedEditorSplitWindowFrame(
    currentFrame: NSRect,
    visibleFrame: NSRect?,
    minWidth: CGFloat,
    widthDelta: CGFloat,
    edge: EditorSplitWindowResizeEdge
) -> NSRect {
    guard abs(widthDelta) > 0.5 else {
        return currentFrame
    }

    let minimumWidth = currentFrame.width >= minWidth ? minWidth : currentFrame.width
    var targetWidth = max(minimumWidth, currentFrame.width + widthDelta)

    if widthDelta > 0, let visibleFrame {
        let maximumWidth: CGFloat
        switch edge {
        case .leading:
            maximumWidth = max(currentFrame.width, currentFrame.maxX - visibleFrame.minX)
        case .trailing:
            maximumWidth = max(currentFrame.width, visibleFrame.maxX - currentFrame.minX)
        }
        targetWidth = min(targetWidth, maximumWidth)
    }

    var adjustedFrame = currentFrame
    adjustedFrame.size.width = targetWidth

    switch edge {
    case .leading:
        adjustedFrame.origin.x = currentFrame.maxX - targetWidth
    case .trailing:
        adjustedFrame.origin.x = currentFrame.minX
    }

    return adjustedFrame
}

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
    private let sidebarToggleBehavior: EditorSplitWindowSidebarToggleBehavior

    public var layoutState: EditorSplitLayoutState {
        editorSplitController.layoutState
    }

    public var layoutStateDidChange: ((EditorSplitLayoutState) -> Void)? {
        get { editorSplitController.layoutStateDidChange }
        set { editorSplitController.layoutStateDidChange = newValue }
    }

    var visibleFrameProvider: (NSWindow) -> NSRect? = { window in
        if let screen = window.screen {
            return screen.visibleFrame
        }

        return NSScreen.screens.first(where: { $0.frame.intersects(window.frame) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
    }

    public init(
        title: String = "Editor",
        configuration: EditorSplitConfiguration = .init(),
        initialState: EditorSplitLayoutState = .init(),
        windowRect: NSRect = NSRect(x: 0, y: 0, width: 1200, height: 780),
        styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable],
        sidebarBackgroundMaterial: NSVisualEffectView.Material? = nil,
        inspectorBackgroundMaterial: NSVisualEffectView.Material? = nil,
        sidebarToggleBehavior: EditorSplitWindowSidebarToggleBehavior = .keepsWindowFrame,
        @ViewBuilder sidebar: () -> some View,
        @ViewBuilder content: () -> some View,
        @ViewBuilder inspector: () -> some View
    ) {
        self.sidebarToggleBehavior = sidebarToggleBehavior
        editorSplitController = EditorSplitController(
            sidebar: EditorHostingViewController(
                rootView: sidebar(),
                backgroundMaterial: sidebarBackgroundMaterial
            ),
            content: EditorHostingViewController(rootView: content()),
            inspector: EditorHostingViewController(
                rootView: inspector(),
                backgroundMaterial: inspectorBackgroundMaterial
            ),
            configuration: configuration,
            initialState: initialState
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
        sidebarBackgroundMaterial: NSVisualEffectView.Material? = nil,
        inspectorBackgroundMaterial: NSVisualEffectView.Material? = nil,
        sidebarToggleBehavior: EditorSplitWindowSidebarToggleBehavior = .keepsWindowFrame,
        @ViewBuilder sidebar: () -> some View,
        @ViewBuilder content: () -> some View,
        @ViewBuilder inspector: () -> some View,
        @ViewBuilder bottom: () -> some View
    ) {
        self.sidebarToggleBehavior = sidebarToggleBehavior
        editorSplitController = EditorSplitController(
            sidebar: EditorHostingViewController(
                rootView: sidebar(),
                backgroundMaterial: sidebarBackgroundMaterial
            ),
            content: EditorHostingViewController(rootView: content()),
            inspector: EditorHostingViewController(
                rootView: inspector(),
                backgroundMaterial: inspectorBackgroundMaterial
            ),
            bottom: EditorAnyHostingViewController(rootView: AnyView(bottom())),
            configuration: configuration,
            initialState: initialState
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

    public func setSidebarVisible(_ isVisible: Bool) {
        setPaneVisibility(isVisible, edge: .leading) { [editorSplitController] in
            editorSplitController.setSidebarVisible($0)
        }
    }

    public func setInspectorVisible(_ isVisible: Bool) {
        setPaneVisibility(isVisible, edge: .trailing) { [editorSplitController] in
            editorSplitController.setInspectorVisible($0)
        }
    }

    public func setBottomPanelVisible(_ isVisible: Bool) {
        editorSplitController.setBottomPanelVisible(isVisible)
    }

    @objc public func toggleSidebar(_ sender: Any?) {
        setSidebarVisible(editorSplitController.sidebarItem.isCollapsed)
    }

    @objc public func toggleInspector(_ sender: Any?) {
        setInspectorVisible(editorSplitController.inspectorItem.isCollapsed)
    }

    @objc public func toggleBottomPanel(_ sender: Any?) {
        guard let bottomItem = editorSplitController.bottomItem else {
            return
        }

        setBottomPanelVisible(bottomItem.isCollapsed)
    }

    @objc public func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(toggleSidebar(_:)):
            return editorSplitController.sidebarItem?.canCollapse == true
        case #selector(toggleInspector(_:)):
            return editorSplitController.inspectorItem?.canCollapse == true
        case #selector(toggleBottomPanel(_:)):
            return editorSplitController.bottomItem?.canCollapse == true
        default:
            return true
        }
    }

    public func applyLayoutState(_ state: EditorSplitLayoutState) {
        editorSplitController.applyLayoutState(state)
    }

    private func setPaneVisibility(
        _ isVisible: Bool,
        edge: EditorSplitWindowResizeEdge,
        applyVisibility: (Bool) -> Void
    ) {
        _ = editorSplitController.view

        guard let window else {
            applyVisibility(isVisible)
            return
        }

        guard sidebarToggleBehavior == .preservesContentWidth else {
            applyVisibility(isVisible)
            editorSplitController.view.layoutSubtreeIfNeeded()
            return
        }

        let contentWidthBefore = currentContentWidth()
        applyVisibility(isVisible)
        let contentWidthAfterToggle = currentContentWidth()
        let widthDelta = contentWidthBefore - contentWidthAfterToggle

        let adjustedFrame = adjustedEditorSplitWindowFrame(
            currentFrame: window.frame,
            visibleFrame: visibleFrameProvider(window),
            minWidth: window.minSize.width,
            widthDelta: widthDelta,
            edge: edge
        )

        if adjustedFrame.equalTo(window.frame) == false {
            window.setFrame(adjustedFrame, display: true, animate: false)
            editorSplitController.view.layoutSubtreeIfNeeded()
        }
    }

    private func currentContentWidth() -> CGFloat {
        editorSplitController.view.layoutSubtreeIfNeeded()
        return editorSplitController.contentItem.viewController.view.frame.width
    }
}
