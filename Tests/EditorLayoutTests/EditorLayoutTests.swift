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
@Test func editorSplitViewUsesNativeSidebarAndContentListItems() async throws {
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
    #expect(controller.splitViewItems[2].behavior == .contentList)
}
