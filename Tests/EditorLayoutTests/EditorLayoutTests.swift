import AppKit
import SwiftUI
import Testing
@testable import EditorLayout

@MainActor
@Test func editorLayoutAcceptsViewBuilders() async throws {
    let layout = EditorLayout(
        isSidebarPresented: .constant(true),
        isInspectorPresented: .constant(true),
        columnVisibility: .constant(.all),
        preferredCompactColumn: .constant(.detail)
    ) {
        Text("Sidebar")
    } content: {
        Text("Content")
    } inspector: {
        Text("Inspector")
    }

    _ = layout
}

@MainActor
@Test func editorViewAcceptsViewBuilders() async throws {
    let layout = EditorView(
        showsSidebar: .constant(true),
        showsInspector: .constant(true)
    ) {
        Text("Sidebar")
    } content: {
        Text("Content")
    } inspector: {
        Text("Inspector")
    }

    _ = layout
}

@MainActor
@Test func editorSplitViewAcceptsBottomPanelAndStateBinding() async throws {
    let layout = EditorSplitView(
        layoutState: .constant(
            .init(
                sidebarWidth: 210,
                inspectorWidth: 260,
                bottomHeight: 180,
                showsSidebar: true,
                showsInspector: true,
                showsBottomPanel: true
            )
        )
    ) {
        Text("Sidebar")
    } content: {
        Text("Content")
    } inspector: {
        Text("Inspector")
    } bottom: {
        Text("Bottom")
    }

    _ = layout
}

@MainActor
@Test func editorSplitViewAcceptsVisibilityBindings() async throws {
    let layout = EditorSplitView(
        showsSidebar: .constant(true),
        showsInspector: .constant(true),
        showsBottomPanel: .constant(true)
    ) {
        Text("Sidebar")
    } content: {
        Text("Content")
    } inspector: {
        Text("Inspector")
    } bottom: {
        Text("Bottom")
    }

    _ = layout
}

@MainActor
@Test func editorSplitViewLayoutStateVisibilityBindingsStayLive() async throws {
    var state = EditorSplitLayoutState(
        sidebarWidth: 220,
        inspectorWidth: 280,
        bottomHeight: 180,
        showsSidebar: true,
        showsInspector: true,
        showsBottomPanel: true
    )
    let layoutState = Binding(
        get: { state },
        set: { state = $0 }
    )

    let visibilityBindings = editorSplitVisibilityBindings(from: layoutState)

    #expect(visibilityBindings.showsSidebar.wrappedValue == true)
    #expect(visibilityBindings.showsInspector.wrappedValue == true)
    #expect(visibilityBindings.showsBottomPanel.wrappedValue == true)

    state.showsSidebar = false
    state.showsInspector = false
    state.showsBottomPanel = false

    #expect(visibilityBindings.showsSidebar.wrappedValue == false)
    #expect(visibilityBindings.showsInspector.wrappedValue == false)
    #expect(visibilityBindings.showsBottomPanel.wrappedValue == false)

    visibilityBindings.showsSidebar.wrappedValue = true
    visibilityBindings.showsInspector.wrappedValue = true
    visibilityBindings.showsBottomPanel.wrappedValue = true

    #expect(state.showsSidebar == true)
    #expect(state.showsInspector == true)
    #expect(state.showsBottomPanel == true)
}

@MainActor
@Test func editorSplitTypesExposeXcodeStyleStateAndConfiguration() async throws {
    let configuration = EditorSplitConfiguration(
        sidebarMinimumWidth: 190,
        sidebarMaximumWidth: 340,
        inspectorMinimumWidth: 240,
        inspectorMaximumWidth: 540,
        inspectorSnapThreshold: 170,
        sidebarSnapThreshold: 150,
        bottomMinimumHeight: 130,
        bottomSnapThreshold: 100
    )

    let state = EditorSplitLayoutState(
        sidebarWidth: 210,
        inspectorWidth: 300,
        bottomHeight: 180,
        showsSidebar: true,
        showsInspector: false,
        showsBottomPanel: true
    )

    #expect(configuration.sidebarMinimumWidth == 190)
    #expect(configuration.inspectorMaximumWidth == 540)
    #expect(state.sidebarWidth == 210)
    #expect(state.showsInspector == false)
}

@MainActor
@Test func editorStackControllerManagesTabs() async throws {
    let controller = EditorStackController()
    _ = controller.view

    controller.openTab(NSViewController(), title: "First")
    controller.openTab(NSViewController(), title: "Second")

    #expect(controller.tabViewController.tabViewItems.count == 2)

    controller.closeTab(at: 0)

    #expect(controller.tabViewController.tabViewItems.count == 1)
}

@MainActor
@Test func editorSplitViewUsesPlainSidebarAndResizableInspectorItems() async throws {
    let controller = EditorSplitViewController(
        showsSidebar: true,
        showsInspector: true,
        sidebar: EmptyView(),
        content: EmptyView(),
        inspector: EmptyView(),
        onSidebarVisibilityChanged: { _ in },
        onInspectorVisibilityChanged: { _ in }
    )

    #expect(controller.splitViewItems.count == 3)
    #expect(controller.splitViewItems[0].behavior == .default)
    #expect(controller.splitViewItems[1].behavior == .default)
    #expect(controller.splitViewItems[2].behavior == .inspector)
    #expect(controller.splitViewItems[2].minimumThickness == 220)
    #expect(controller.splitViewItems[2].maximumThickness == NSSplitViewItem.unspecifiedDimension)

    _ = controller.view
    controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 450)
    controller.view.layoutSubtreeIfNeeded()

    let dividerEffectiveRect = controller.splitView(
        controller.splitView,
        effectiveRect: .zero,
        forDrawnRect: .zero,
        ofDividerAt: 1
    )
    #expect(dividerEffectiveRect.width >= 8)
}

@MainActor
@Test func editorSplitControllerMakesContentTheFlexiblePane() async throws {
    let controller = EditorSplitController(
        sidebar: NSViewController(),
        content: NSViewController(),
        inspector: NSViewController()
    )

    _ = controller.view

    #expect(controller.sidebarItem.holdingPriority == .defaultHigh)
    #expect(controller.contentItem.holdingPriority == .defaultLow)
    #expect(controller.inspectorItem.holdingPriority == .defaultHigh)
}

@MainActor
@Test func editorSplitControllerUsesNativeSidebarAndInspectorBehaviors() async throws {
    let controller = EditorSplitController(
        sidebar: NSViewController(),
        content: NSViewController(),
        inspector: NSViewController()
    )

    _ = controller.view

    #expect(controller.sidebarItem.behavior == .sidebar)
    #expect(controller.contentItem.behavior == .default)
    #expect(controller.inspectorItem.behavior == .inspector)
}

@MainActor
@Test func editorSplitControllerExpandsDividerHitTargets() async throws {
    let controller = EditorSplitController(
        sidebar: NSViewController(),
        content: NSViewController(),
        inspector: NSViewController()
    )

    _ = controller.view
    controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 450)
    controller.view.layoutSubtreeIfNeeded()

    let sidebarDividerRect = controller.splitView(
        controller.splitView,
        effectiveRect: .zero,
        forDrawnRect: .zero,
        ofDividerAt: 0
    )
    let inspectorDividerRect = controller.splitView(
        controller.splitView,
        effectiveRect: .zero,
        forDrawnRect: .zero,
        ofDividerAt: 1
    )

    #expect(sidebarDividerRect.width >= 8)
    #expect(inspectorDividerRect.width >= 8)
}

@MainActor
@Test func editorSplitControllerReportsManualVisibilityChanges() async throws {
    let controller = EditorSplitController(
        sidebar: NSViewController(),
        content: NSViewController(),
        inspector: NSViewController(),
        bottom: NSViewController()
    )

    var reportedStates: [(Bool, Bool, Bool)] = []
    controller.visibilityDidChange = { showsSidebar, showsInspector, showsBottomPanel in
        reportedStates.append((showsSidebar, showsInspector, showsBottomPanel))
    }

    _ = controller.view
    controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 450)
    controller.view.layoutSubtreeIfNeeded()

    controller.sidebarItem.isCollapsed = true
    controller.inspectorItem.isCollapsed = true
    controller.bottomItem?.isCollapsed = true
    controller.view.layoutSubtreeIfNeeded()
    controller.viewDidLayout()

    #expect(reportedStates.contains(where: { $0 == (false, false, false) }))
}

@MainActor
@Test func editorSplitControllerAppliesAndReportsLiveLayoutState() async throws {
    let controller = EditorSplitController(
        sidebar: NSViewController(),
        content: NSViewController(),
        inspector: NSViewController(),
        bottom: NSViewController()
    )

    var reportedState: EditorSplitLayoutState?
    controller.layoutStateDidChange = { state in
        reportedState = state
    }

    let desiredState = EditorSplitLayoutState(
        sidebarWidth: 250,
        inspectorWidth: 320,
        bottomHeight: 180,
        showsSidebar: true,
        showsInspector: true,
        showsBottomPanel: true
    )
    controller.applyLayoutState(desiredState)

    #expect(controller.layoutState == desiredState)

    _ = controller.view
    controller.view.frame = NSRect(x: 0, y: 0, width: 1200, height: 720)
    controller.view.layoutSubtreeIfNeeded()
    controller.viewDidAppear()

    let currentState = controller.layoutState
    #expect(currentState.sidebarWidth != nil)
    #expect(currentState.inspectorWidth != nil)
    #expect(abs((currentState.bottomHeight ?? 0) - 180) < 2)
    #expect(reportedState == currentState)
}

@MainActor
@Test func editorSplitControllerReportsBottomPanelResizesFromNestedSplitController() async throws {
    let controller = EditorSplitController(
        sidebar: NSViewController(),
        content: NSViewController(),
        inspector: NSViewController(),
        bottom: NSViewController()
    )

    var reportedBottomHeight: CGFloat?
    controller.layoutStateDidChange = { state in
        reportedBottomHeight = state.bottomHeight
    }

    _ = controller.view
    controller.view.frame = NSRect(x: 0, y: 0, width: 1100, height: 700)
    controller.view.layoutSubtreeIfNeeded()
    controller.viewDidAppear()

    guard let contentStackController = controller.contentStackController else {
        Issue.record("Expected content stack controller with bottom panel")
        return
    }

    let splitView = contentStackController.splitView
    let targetBottomHeight: CGFloat = 210
    let bottomDividerPosition = max(0, splitView.bounds.height - targetBottomHeight)
    splitView.setPosition(bottomDividerPosition, ofDividerAt: 0)
    contentStackController.splitViewDidResizeSubviews(
        Notification(name: NSSplitView.didResizeSubviewsNotification, object: splitView)
    )

    #expect(abs((reportedBottomHeight ?? 0) - targetBottomHeight) < 2)
}

@MainActor
@Test func adjustedEditorSplitWindowFrameExpandsFromLeadingEdge() async throws {
    let frame = adjustedEditorSplitWindowFrame(
        currentFrame: NSRect(x: 300, y: 120, width: 860, height: 420),
        visibleFrame: NSRect(x: 0, y: 0, width: 1600, height: 1000),
        minWidth: 860,
        widthDelta: 270,
        edge: .leading
    )

    #expect(frame.origin.x == 30)
    #expect(frame.width == 1130)
}

@MainActor
@Test func adjustedEditorSplitWindowFrameStopsAtVisibleFrameWhenLeadingEdgeWouldOverflow() async throws {
    let frame = adjustedEditorSplitWindowFrame(
        currentFrame: NSRect(x: 100, y: 120, width: 860, height: 420),
        visibleFrame: NSRect(x: 0, y: 0, width: 1200, height: 1000),
        minWidth: 860,
        widthDelta: 270,
        edge: .leading
    )

    #expect(frame.origin.x == 0)
    #expect(frame.width == 960)
}

@MainActor
@Test func adjustedEditorSplitWindowFrameShrinksFromTrailingEdge() async throws {
    let frame = adjustedEditorSplitWindowFrame(
        currentFrame: NSRect(x: 100, y: 120, width: 1180, height: 420),
        visibleFrame: NSRect(x: 0, y: 0, width: 1600, height: 1000),
        minWidth: 860,
        widthDelta: -320,
        edge: .trailing
    )

    #expect(frame.origin.x == 100)
    #expect(frame.width == 860)
}
