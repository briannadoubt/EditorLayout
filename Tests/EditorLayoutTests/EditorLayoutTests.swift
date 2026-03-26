import SwiftUI
import Testing
@testable import EditorLayout

@MainActor
@Test func editorLayoutAcceptsViewBuilders() async throws {
    let layout = EditorLayout(
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
@Test func nsEditorLayoutAcceptsViewBuilders() async throws {
    let layout = NSEditorLayout(
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
