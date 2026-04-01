import AppKit

@MainActor
public struct EditorSplitConfiguration: Equatable, Sendable {
    public var sidebarMinimumWidth: CGFloat
    public var sidebarMaximumWidth: CGFloat
    public var contentMinimumWidth: CGFloat
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
        contentMinimumWidth: CGFloat = 270,
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
        self.contentMinimumWidth = contentMinimumWidth
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
    public var visibilityDidChange: ((Bool, Bool, Bool) -> Void)?
    public var layoutStateDidChange: ((EditorSplitLayoutState) -> Void)?

    public var layoutState: EditorSplitLayoutState {
        snapshotLayoutState()
    }

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
    private var pendingLayoutState: EditorSplitLayoutState
    private var lastKnownSidebarWidth: CGFloat?
    private var lastKnownInspectorWidth: CGFloat?
    private var lastKnownBottomHeight: CGFloat?
    private var lastReportedVisibility: EditorSplitVisibility?
    private var lastReportedLayoutState: EditorSplitLayoutState?

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
        pendingLayoutState = initialState
        lastKnownSidebarWidth = initialState.sidebarWidth
        lastKnownInspectorWidth = initialState.inspectorWidth
        lastKnownBottomHeight = initialState.bottomHeight
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
        applyInitialLayoutStateIfNeeded()
        hasAppliedInitialState = true
        reportActualStateIfNeeded(force: true)
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        reportActualStateIfNeeded()
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
        let dividerRect = drawnRect.standardized.isEmpty
            ? proposedEffectiveRect.standardized
            : drawnRect.standardized
        let dragRect = splitView.isVertical
            ? dividerRect.insetBy(dx: -4, dy: 0)
            : dividerRect.insetBy(dx: 0, dy: -4)

        return baseRect.union(dragRect)
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

    public func applyLayoutState(_ state: EditorSplitLayoutState) {
        let normalizedState = normalizedLayoutState(state)
        pendingLayoutState = normalizedState
        lastKnownSidebarWidth = normalizedState.sidebarWidth ?? lastKnownSidebarWidth
        lastKnownInspectorWidth = normalizedState.inspectorWidth ?? lastKnownInspectorWidth
        lastKnownBottomHeight = normalizedState.bottomHeight ?? lastKnownBottomHeight

        currentVisibility = EditorSplitVisibility(
            showsSidebar: normalizedState.showsSidebar,
            showsInspector: normalizedState.showsInspector,
            showsBottomPanel: normalizedState.showsBottomPanel
        )

        guard isViewLoaded else {
            return
        }

        applyVisibility(currentVisibility)
        applyLayoutMeasurements(using: normalizedState)
        reportActualStateIfNeeded(force: true)
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

    public override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
        reportActualStateIfNeeded()
    }

    private func setupLayout() {
        sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        contentItem = NSSplitViewItem(viewController: contentViewController)
        inspectorItem = NSSplitViewItem(inspectorWithViewController: inspectorViewController)

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
            stack.layoutStateDidChange = { [weak self] in
                self?.reportActualStateIfNeeded()
            }
            contentStackController = stack
            bottomItem = stack.bottomItem
            contentItem = NSSplitViewItem(viewController: stack)
        } else {
            contentStackController = nil
            bottomItem = nil
            contentItem = NSSplitViewItem(viewController: contentViewController)
        }

        configureContentItem()

        if splitViewItems.indices.contains(1) {
            insertSplitViewItem(contentItem, at: 1)
        } else {
            addSplitViewItem(contentItem)
        }
    }

    private func configureContentItem() {
        contentItem.holdingPriority = .defaultLow

        if #available(macOS 26.0, *) {
            contentItem.automaticallyAdjustsSafeAreaInsets = true
        }
    }

    private func applyConfiguration() {
        sidebarItem.minimumThickness = configuration.sidebarMinimumWidth
        sidebarItem.maximumThickness = configuration.sidebarMaximumWidth
        sidebarItem.canCollapse = true
        sidebarItem.holdingPriority = .defaultHigh

        contentItem.minimumThickness = configuration.contentMinimumWidth

        inspectorItem.minimumThickness = configuration.inspectorMinimumWidth
        inspectorItem.maximumThickness = configuration.inspectorMaximumWidth
        inspectorItem.canCollapse = true
        inspectorItem.holdingPriority = .defaultHigh

        bottomItem?.minimumThickness = configuration.bottomMinimumHeight
        bottomItem?.holdingPriority = .defaultLow
        contentStackController?.configuration = configuration

        splitViewItems.forEach { $0.allowsFullHeightLayout = true }
    }

    private func applyVisibility(_ visibility: EditorSplitVisibility) {
        let previousVisibility = currentVisibility
        currentVisibility = visibility

        guard isViewLoaded else {
            return
        }

        if previousVisibility.showsSidebar,
           visibility.showsSidebar == false
        {
            let currentSidebarWidth = sidebarItem.viewController.view.frame.width
            if currentSidebarWidth > 0 {
                lastKnownSidebarWidth = currentSidebarWidth
            }
        }

        if sidebarItem.isCollapsed == visibility.showsSidebar {
            sidebarItem.isCollapsed = !visibility.showsSidebar
        }

        if previousVisibility.showsInspector,
           visibility.showsInspector == false
        {
            let currentInspectorWidth = inspectorItem.viewController.view.frame.width
            if currentInspectorWidth > 0 {
                lastKnownInspectorWidth = currentInspectorWidth
            }
        }

        if inspectorItem.isCollapsed == visibility.showsInspector {
            inspectorItem.isCollapsed = !visibility.showsInspector
        }

        if previousVisibility.showsBottomPanel,
           visibility.showsBottomPanel == false,
           let bottomItem
        {
            let currentBottomHeight = bottomItem.viewController.view.frame.height
            if currentBottomHeight > 0 {
                lastKnownBottomHeight = currentBottomHeight
            }
        }

        if let bottomItem, bottomItem.isCollapsed == visibility.showsBottomPanel {
            bottomItem.isCollapsed = !visibility.showsBottomPanel
        }

        view.layoutSubtreeIfNeeded()

        if previousVisibility.showsBottomPanel == false,
           visibility.showsBottomPanel,
           let contentStackController
        {
            restoreBottomPanelHeight(in: contentStackController)
        }
        reportActualStateIfNeeded(force: true)
    }

    private func applyInitialLayoutStateIfNeeded() {
        guard hasAppliedInitialState == false else {
            return
        }

        applyLayoutMeasurements(using: pendingLayoutState)
    }

    private func restoreBottomPanelHeight(in contentStackController: BottomPanelSplitController) {
        let splitView = contentStackController.splitView
        let targetHeight = max(
            configuration.bottomMinimumHeight,
            lastKnownBottomHeight ?? max(configuration.bottomMinimumHeight, 220)
        )
        let bottomDividerPosition = max(0, splitView.bounds.height - targetHeight)
        splitView.setPosition(bottomDividerPosition, ofDividerAt: 0)
        splitView.adjustSubviews()
        view.layoutSubtreeIfNeeded()
    }

    private func applyLayoutMeasurements(using state: EditorSplitLayoutState) {
        guard isViewLoaded else {
            return
        }

        view.layoutSubtreeIfNeeded()

        if let sidebarWidth = state.sidebarWidth,
           currentVisibility.showsSidebar {
            let clampedSidebarWidth = min(
                configuration.sidebarMaximumWidth,
                max(configuration.sidebarMinimumWidth, sidebarWidth)
            )
            splitView.setPosition(clampedSidebarWidth, ofDividerAt: 0)
            lastKnownSidebarWidth = clampedSidebarWidth
        }

        if let inspectorWidth = state.inspectorWidth,
           currentVisibility.showsInspector {
            let clampedInspectorWidth = min(
                configuration.inspectorMaximumWidth,
                max(configuration.inspectorMinimumWidth, inspectorWidth)
            )
            let minimumInspectorDividerPosition = currentVisibility.showsSidebar
                ? configuration.sidebarMinimumWidth
                : 0
            let inspectorDividerPosition = max(
                minimumInspectorDividerPosition,
                splitView.bounds.width - clampedInspectorWidth
            )
            splitView.setPosition(inspectorDividerPosition, ofDividerAt: 1)
            lastKnownInspectorWidth = clampedInspectorWidth
        }

        if let bottomHeight = state.bottomHeight,
           currentVisibility.showsBottomPanel,
           let contentStackController {
            let clampedBottomHeight = max(configuration.bottomMinimumHeight, bottomHeight)
            let splitView = contentStackController.splitView
            let bottomDividerPosition = max(0, splitView.bounds.height - clampedBottomHeight)
            splitView.setPosition(bottomDividerPosition, ofDividerAt: 0)
            lastKnownBottomHeight = clampedBottomHeight
        }

        splitView.adjustSubviews()
        view.layoutSubtreeIfNeeded()
        updateLastKnownDimensions()
    }

    private func reportActualStateIfNeeded(force: Bool = false) {
        let state = snapshotLayoutState()
        let actualVisibility = EditorSplitVisibility(
            showsSidebar: state.showsSidebar,
            showsInspector: state.showsInspector,
            showsBottomPanel: state.showsBottomPanel
        )

        if force || actualVisibility != lastReportedVisibility {
            currentVisibility = actualVisibility
            lastReportedVisibility = actualVisibility
            visibilityDidChange?(
                actualVisibility.showsSidebar,
                actualVisibility.showsInspector,
                actualVisibility.showsBottomPanel
            )
        }

        if force || state != lastReportedLayoutState {
            if hasAppliedInitialState {
                pendingLayoutState = state
            }
            lastReportedLayoutState = state
            layoutStateDidChange?(state)
        }
    }

    private func snapshotLayoutState() -> EditorSplitLayoutState {
        guard isViewLoaded else {
            return normalizedLayoutState(pendingLayoutState)
        }

        updateLastKnownDimensions()

        return EditorSplitLayoutState(
            sidebarWidth: lastKnownSidebarWidth,
            inspectorWidth: lastKnownInspectorWidth,
            bottomHeight: bottomViewController == nil ? nil : lastKnownBottomHeight,
            showsSidebar: !sidebarItem.isCollapsed,
            showsInspector: !inspectorItem.isCollapsed,
            showsBottomPanel: bottomItem.map { !$0.isCollapsed } ?? false
        )
    }

    private func updateLastKnownDimensions() {
        guard isViewLoaded else {
            return
        }

        let sidebarWidth = sidebarItem.viewController.view.frame.width
        if sidebarItem.isCollapsed == false, sidebarWidth > 0 {
            lastKnownSidebarWidth = sidebarWidth
        }

        let inspectorWidth = inspectorItem.viewController.view.frame.width
        if inspectorItem.isCollapsed == false, inspectorWidth > 0 {
            lastKnownInspectorWidth = inspectorWidth
        }

        if let bottomItem {
            let bottomHeight = bottomItem.viewController.view.frame.height
            if bottomItem.isCollapsed == false, bottomHeight > 0 {
                lastKnownBottomHeight = bottomHeight
            }
        }
    }

    private func normalizedLayoutState(_ state: EditorSplitLayoutState) -> EditorSplitLayoutState {
        EditorSplitLayoutState(
            sidebarWidth: state.sidebarWidth,
            inspectorWidth: state.inspectorWidth,
            bottomHeight: bottomViewController == nil ? nil : state.bottomHeight,
            showsSidebar: state.showsSidebar,
            showsInspector: state.showsInspector,
            showsBottomPanel: bottomViewController == nil ? false : state.showsBottomPanel
        )
    }

}

@MainActor
public final class BottomPanelSplitController: NSSplitViewController {
    var layoutStateDidChange: (() -> Void)?

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
        contentItem.holdingPriority = .defaultLow
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

    public override func viewDidLayout() {
        super.viewDidLayout()
        layoutStateDidChange?()
    }

    public override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
        layoutStateDidChange?()
    }

}

private struct EditorSplitVisibility: Equatable {
    var showsSidebar: Bool
    var showsInspector: Bool
    var showsBottomPanel: Bool
}
