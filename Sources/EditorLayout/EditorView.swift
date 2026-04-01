import AppKit
import SwiftUI

@MainActor
public struct EditorView<Sidebar: View, Content: View, Inspector: View>: NSViewControllerRepresentable {
    @Binding private var showsSidebar: Bool
    @Binding private var showsInspector: Bool

    private let sidebar: Sidebar
    private let content: Content
    private let inspector: Inspector

    public init(
        showsSidebar: Binding<Bool> = .constant(true),
        showsInspector: Binding<Bool> = .constant(true),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector
    ) {
        _showsSidebar = showsSidebar
        _showsInspector = showsInspector
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(showsSidebar: _showsSidebar, showsInspector: _showsInspector)
    }

    public func makeNSViewController(context: Context) -> EditorSplitViewController<Sidebar, Content, Inspector> {
        EditorSplitViewController(
            showsSidebar: showsSidebar,
            showsInspector: showsInspector,
            sidebar: sidebar,
            content: content,
            inspector: inspector,
            onSidebarVisibilityChanged: context.coordinator.setSidebarVisibility(_:),
            onInspectorVisibilityChanged: context.coordinator.setInspectorVisibility(_:)
        )
    }

    public func updateNSViewController(
        _ nsViewController: EditorSplitViewController<Sidebar, Content, Inspector>,
        context: Context
    ) {
        context.coordinator.showsSidebar = _showsSidebar
        context.coordinator.showsInspector = _showsInspector

        nsViewController.update(
            showsSidebar: showsSidebar,
            showsInspector: showsInspector,
            sidebar: sidebar,
            content: content,
            inspector: inspector
        )
    }

    @MainActor
    public final class Coordinator {
        fileprivate var showsSidebar: Binding<Bool>
        fileprivate var showsInspector: Binding<Bool>

        fileprivate init(showsSidebar: Binding<Bool>, showsInspector: Binding<Bool>) {
            self.showsSidebar = showsSidebar
            self.showsInspector = showsInspector
        }

        fileprivate func setSidebarVisibility(_ isVisible: Bool) {
            guard showsSidebar.wrappedValue != isVisible else {
                return
            }

            Task { @MainActor [showsSidebar] in
                showsSidebar.wrappedValue = isVisible
            }
        }

        fileprivate func setInspectorVisibility(_ isVisible: Bool) {
            guard showsInspector.wrappedValue != isVisible else {
                return
            }

            Task { @MainActor [showsInspector] in
                showsInspector.wrappedValue = isVisible
            }
        }
    }
}

@MainActor
public final class EditorSplitViewController<Sidebar: View, Content: View, Inspector: View>: NSSplitViewController {
    private let sidebarController: EditorPaneViewController<Sidebar>
    private let contentController: EditorPaneViewController<Content>
    private let inspectorController: EditorPaneViewController<Inspector>

    private let sidebarItem: NSSplitViewItem
    private let contentItem: NSSplitViewItem
    private let inspectorItem: NSSplitViewItem

    private let onSidebarVisibilityChanged: (Bool) -> Void
    private let onInspectorVisibilityChanged: (Bool) -> Void
    private var lastReportedSidebarVisibility: Bool
    private var lastReportedInspectorVisibility: Bool

    init(
        showsSidebar: Bool,
        showsInspector: Bool,
        sidebar: Sidebar,
        content: Content,
        inspector: Inspector,
        onSidebarVisibilityChanged: @escaping (Bool) -> Void,
        onInspectorVisibilityChanged: @escaping (Bool) -> Void
    ) {
        self.onSidebarVisibilityChanged = onSidebarVisibilityChanged
        self.onInspectorVisibilityChanged = onInspectorVisibilityChanged
        lastReportedSidebarVisibility = showsSidebar
        lastReportedInspectorVisibility = showsInspector

        sidebarController = EditorPaneViewController(rootView: sidebar)
        contentController = EditorPaneViewController(rootView: content)
        inspectorController = EditorPaneViewController(rootView: inspector)

        sidebarItem = NSSplitViewItem(viewController: sidebarController)
        contentItem = NSSplitViewItem(viewController: contentController)
        inspectorItem = NSSplitViewItem(inspectorWithViewController: inspectorController)
        inspectorItem.minimumThickness = 220
        inspectorItem.maximumThickness = NSSplitViewItem.unspecifiedDimension

        sidebarItem.isCollapsed = !showsSidebar
        inspectorItem.isCollapsed = !showsInspector

        super.init(nibName: nil, bundle: nil)

        addSplitViewItem(sidebarItem)
        addSplitViewItem(contentItem)
        addSplitViewItem(inspectorItem)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        reportActualVisibilityIfNeeded()
    }

    public override func toggleSidebar(_ sender: Any?) {
        super.toggleSidebar(sender)
        scheduleVisibilityReport()
    }

    public override func toggleInspector(_ sender: Any?) {
        super.toggleInspector(sender)
        scheduleVisibilityReport()
    }

    public override func splitView(
        _ splitView: NSSplitView,
        effectiveRect proposedEffectiveRect: NSRect,
        forDrawnRect drawnRect: NSRect,
        ofDividerAt dividerIndex: Int
    ) -> NSRect {
        let baseRect = super.splitView(
            splitView,
            effectiveRect: proposedEffectiveRect,
            forDrawnRect: drawnRect,
            ofDividerAt: dividerIndex
        )

        guard dividerIndex == splitViewItems.count - 2 else {
            return baseRect
        }

        let dividerRect = drawnRect.standardized.isEmpty ? proposedEffectiveRect.standardized : drawnRect.standardized
        let dragRect = dividerRect.insetBy(dx: -4, dy: 0)
        return baseRect.union(dragRect)
    }

    func update(
        showsSidebar: Bool,
        showsInspector: Bool,
        sidebar: Sidebar,
        content: Content,
        inspector: Inspector
    ) {
        sidebarController.update(rootView: sidebar)
        contentController.update(rootView: content)
        inspectorController.update(rootView: inspector)

        applyVisibility(showsSidebar: showsSidebar, showsInspector: showsInspector)
    }

    private func applyVisibility(showsSidebar: Bool, showsInspector: Bool) {
        if showsSidebar != !sidebarItem.isCollapsed {
            super.toggleSidebar(nil)
        }

        if showsInspector != !inspectorItem.isCollapsed {
            super.toggleInspector(nil)
        }

        scheduleVisibilityReport()
    }

    private func reportActualVisibilityIfNeeded() {
        let isSidebarVisible = !sidebarItem.isCollapsed
        if lastReportedSidebarVisibility != isSidebarVisible {
            lastReportedSidebarVisibility = isSidebarVisible
            onSidebarVisibilityChanged(isSidebarVisible)
        }

        let isInspectorVisible = !inspectorItem.isCollapsed
        if lastReportedInspectorVisibility != isInspectorVisible {
            lastReportedInspectorVisibility = isInspectorVisible
            onInspectorVisibilityChanged(isInspectorVisible)
        }
    }

    private func scheduleVisibilityReport() {
        DispatchQueue.main.async { [weak self] in
            self?.reportActualVisibilityIfNeeded()
        }
    }
}

@MainActor
private final class EditorPaneViewController<Root: View>: NSViewController {
    private let hostingController: NSHostingController<Root>

    init(rootView: Root) {
        hostingController = NSHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHostedContent()
    }

    func update(rootView: Root) {
        hostingController.rootView = rootView
    }

    private func configureHostedContent() {
        let hostedView = hostingController.view

        addChild(hostingController)

        hostedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
