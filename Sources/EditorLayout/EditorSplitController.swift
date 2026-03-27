import AppKit

@MainActor
public struct EditorSplitConfiguration: Equatable, Sendable {
    public var sidebarMinimumWidth: CGFloat
    public var sidebarMaximumWidth: CGFloat
    public var inspectorMinimumWidth: CGFloat
    public var inspectorMaximumWidth: CGFloat
    public var inspectorSnapThreshold: CGFloat
    public var sidebarSnapThreshold: CGFloat
    public var bottomMinimumHeight: CGFloat
    public var bottomSnapThreshold: CGFloat
    public var snapAnimationDuration: TimeInterval

    public init(
        sidebarMinimumWidth: CGFloat = 180,
        sidebarMaximumWidth: CGFloat = 320,
        inspectorMinimumWidth: CGFloat = 220,
        inspectorMaximumWidth: CGFloat = 500,
        inspectorSnapThreshold: CGFloat = 160,
        sidebarSnapThreshold: CGFloat = 140,
        bottomMinimumHeight: CGFloat = 120,
        bottomSnapThreshold: CGFloat = 96,
        snapAnimationDuration: TimeInterval = 0.12
    ) {
        self.sidebarMinimumWidth = sidebarMinimumWidth
        self.sidebarMaximumWidth = sidebarMaximumWidth
        self.inspectorMinimumWidth = inspectorMinimumWidth
        self.inspectorMaximumWidth = inspectorMaximumWidth
        self.inspectorSnapThreshold = inspectorSnapThreshold
        self.sidebarSnapThreshold = sidebarSnapThreshold
        self.bottomMinimumHeight = bottomMinimumHeight
        self.bottomSnapThreshold = bottomSnapThreshold
        self.snapAnimationDuration = snapAnimationDuration
    }
}

@MainActor
public struct EditorSplitLayoutState: Equatable, Sendable {
    public var sidebarWidth: CGFloat?
    public var inspectorWidth: CGFloat?
    public var bottomHeight: CGFloat?
    public var showsSidebar: Bool
    public var showsInspector: Bool
    public var showsBottomPanel: Bool

    public init(
        sidebarWidth: CGFloat? = nil,
        inspectorWidth: CGFloat? = nil,
        bottomHeight: CGFloat? = nil,
        showsSidebar: Bool = true,
        showsInspector: Bool = true,
        showsBottomPanel: Bool = true
    ) {
        self.sidebarWidth = sidebarWidth
        self.inspectorWidth = inspectorWidth
        self.bottomHeight = bottomHeight
        self.showsSidebar = showsSidebar
        self.showsInspector = showsInspector
        self.showsBottomPanel = showsBottomPanel
    }
}

@MainActor
public final class EditorSplitController: NSSplitViewController {
    public var configuration: EditorSplitConfiguration {
        didSet {
            guard isViewLoaded else {
                return
            }

            applyConfiguration()
        }
    }

    public private(set) var sidebarViewController: NSViewController
    public private(set) var contentViewController: NSViewController
    public private(set) var inspectorViewController: NSViewController
    public private(set) var bottomViewController: NSViewController?

    public private(set) var sidebarItem: NSSplitViewItem!
    public private(set) var contentItem: NSSplitViewItem!
    public private(set) var inspectorItem: NSSplitViewItem!
    public private(set) var bottomItem: NSSplitViewItem?
    public private(set) var contentStackController: BottomPanelSplitController?

    private var hasAppliedInitialState = false
    private var currentVisibility: EditorSplitVisibility

    public init(
        sidebar: NSViewController,
        content: NSViewController,
        inspector: NSViewController,
        bottom: NSViewController? = nil,
        configuration: EditorSplitConfiguration = .init(),
        initialState: EditorSplitLayoutState = .init()
    ) {
        sidebarViewController = sidebar
        contentViewController = content
        inspectorViewController = inspector
        bottomViewController = bottom
        self.configuration = configuration
        currentVisibility = EditorSplitVisibility(
            showsSidebar: initialState.showsSidebar,
            showsInspector: initialState.showsInspector,
            showsBottomPanel: initialState.showsBottomPanel && bottom != nil
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = true
        splitView.dividerStyle = .thin

        setupLayout()
        applyConfiguration()
        applyVisibility(currentVisibility)
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        hasAppliedInitialState = true
    }

    public func replaceContentViewController(_ controller: NSViewController) {
        contentViewController = controller

        if let contentStackController, let topItem = contentStackController.splitViewItems.first {
            topItem.viewController = controller
        } else {
            contentItem.viewController = controller
        }
    }

    public func replaceBottomViewController(_ controller: NSViewController?) {
        bottomViewController = controller

        guard isViewLoaded else {
            return
        }

        rebuildContentStack()
        applyConfiguration()
        applyVisibility(
            EditorSplitVisibility(
                showsSidebar: currentVisibility.showsSidebar,
                showsInspector: currentVisibility.showsInspector,
                showsBottomPanel: currentVisibility.showsBottomPanel && controller != nil
            )
        )
    }

    public func replaceSidebarViewController(_ controller: NSViewController) {
        sidebarViewController = controller
        sidebarItem.viewController = controller
    }

    public func replaceInspectorViewController(_ controller: NSViewController) {
        inspectorViewController = controller
        inspectorItem.viewController = controller
    }

    public func setSidebarVisible(_ isVisible: Bool) {
        guard currentVisibility.showsSidebar != isVisible else {
            return
        }

        var visibility = currentVisibility
        visibility.showsSidebar = isVisible
        applyVisibility(visibility)
    }

    public func setInspectorVisible(_ isVisible: Bool) {
        guard currentVisibility.showsInspector != isVisible else {
            return
        }

        var visibility = currentVisibility
        visibility.showsInspector = isVisible
        applyVisibility(visibility)
    }

    public func setBottomPanelVisible(_ isVisible: Bool) {
        guard bottomItem != nil else {
            return
        }

        guard currentVisibility.showsBottomPanel != isVisible else {
            return
        }

        var visibility = currentVisibility
        visibility.showsBottomPanel = isVisible
        applyVisibility(visibility)
    }

    @objc public override func toggleSidebar(_ sender: Any?) {
        setSidebarVisible(sidebarItem.isCollapsed)
    }

    @objc public override func toggleInspector(_ sender: Any?) {
        setInspectorVisible(inspectorItem.isCollapsed)
    }

    @objc public func toggleBottomPanel(_ sender: Any?) {
        guard let bottomItem else {
            return
        }

        setBottomPanelVisible(bottomItem.isCollapsed)
    }

    private func setupLayout() {
        sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        contentItem = NSSplitViewItem(viewController: contentViewController)
        inspectorItem = NSSplitViewItem(viewController: inspectorViewController)

        addSplitViewItem(sidebarItem)
        rebuildContentStack()
        addSplitViewItem(inspectorItem)
    }

    private func rebuildContentStack() {
        if splitViewItems.contains(contentItem) {
            removeSplitViewItem(contentItem)
        }

        if let bottomViewController {
            let stack = BottomPanelSplitController(
                content: contentViewController,
                bottom: bottomViewController,
                configuration: configuration
            )
            contentStackController = stack
            bottomItem = stack.bottomItem
            contentItem = NSSplitViewItem(viewController: stack)
        } else {
            contentStackController = nil
            bottomItem = nil
            contentItem = NSSplitViewItem(viewController: contentViewController)
        }

        contentItem.holdingPriority = .defaultLow

        if splitViewItems.indices.contains(1) {
            insertSplitViewItem(contentItem, at: 1)
        } else {
            addSplitViewItem(contentItem)
        }
    }

    private func applyConfiguration() {
        sidebarItem.minimumThickness = configuration.sidebarMinimumWidth
        sidebarItem.maximumThickness = configuration.sidebarMaximumWidth
        sidebarItem.canCollapse = true

        inspectorItem.minimumThickness = configuration.inspectorMinimumWidth
        inspectorItem.maximumThickness = configuration.inspectorMaximumWidth
        inspectorItem.canCollapse = true

        bottomItem?.minimumThickness = configuration.bottomMinimumHeight
        bottomItem?.holdingPriority = .defaultLow
        contentStackController?.configuration = configuration

        splitViewItems.forEach { $0.allowsFullHeightLayout = true }
    }

    private func applyVisibility(_ visibility: EditorSplitVisibility) {
        currentVisibility = visibility

        guard isViewLoaded else {
            return
        }

        if sidebarItem.isCollapsed == visibility.showsSidebar {
            sidebarItem.isCollapsed = !visibility.showsSidebar
        }

        if inspectorItem.isCollapsed == visibility.showsInspector {
            inspectorItem.isCollapsed = !visibility.showsInspector
        }

        if let bottomItem, bottomItem.isCollapsed == visibility.showsBottomPanel {
            bottomItem.isCollapsed = !visibility.showsBottomPanel
        }

        view.layoutSubtreeIfNeeded()
    }

}

@MainActor
public final class BottomPanelSplitController: NSSplitViewController {
    public var configuration: EditorSplitConfiguration {
        didSet {
            guard isViewLoaded else {
                return
            }

            bottomItem.minimumThickness = configuration.bottomMinimumHeight
            bottomItem.holdingPriority = .defaultLow
        }
    }

    public private(set) var contentItem: NSSplitViewItem!
    public private(set) var bottomItem: NSSplitViewItem!

    init(
        content: NSViewController,
        bottom: NSViewController,
        configuration: EditorSplitConfiguration
    ) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)

        contentItem = NSSplitViewItem(viewController: content)
        bottomItem = NSSplitViewItem(viewController: bottom)
        bottomItem.canCollapse = true
        bottomItem.holdingPriority = .defaultLow
        bottomItem.minimumThickness = configuration.bottomMinimumHeight

        addSplitViewItem(contentItem)
        addSplitViewItem(bottomItem)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = false
        splitView.dividerStyle = .thin
    }

}

private struct EditorSplitVisibility: Equatable {
    var showsSidebar: Bool
    var showsInspector: Bool
    var showsBottomPanel: Bool
}
