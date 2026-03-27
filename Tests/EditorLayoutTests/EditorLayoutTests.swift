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
@Test func editorSplitViewUsesNativeSidebarAndResizableInspectorItems() async throws {
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
    #expect(controller.splitViewItems[0].behavior == .sidebar)
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
