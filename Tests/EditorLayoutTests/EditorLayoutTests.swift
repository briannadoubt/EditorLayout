import CoreGraphics
import Testing
@testable import EditorLayout

@Test func metricsDefaultToCappedLayout() async throws {
    let metrics = EditorLayoutMetrics()

    #expect(metrics.leftMaxWidth == 420)
    #expect(metrics.rightMaxWidth == 520)
    #expect(metrics.bottomMaxHeight == 800)
}

@Test func metricsCanDisableMaxConstraints() async throws {
    let metrics = EditorLayoutMetrics(
        leftMaxWidth: nil,
        rightMaxWidth: nil,
        bottomMaxHeight: nil
    )

    #expect(metrics.leftMaxWidth == nil)
    #expect(metrics.rightMaxWidth == nil)
    #expect(metrics.bottomMaxHeight == nil)
}

@Test func shellMinimumsComposeVisibleRegions() async throws {
    let metrics = EditorLayoutMetrics(
        leftMinWidth: 180,
        centerMinWidth: 260,
        centerMinHeight: 300,
        bottomMinHeight: 120
    )

    #expect(metrics.rootShellMinimumWidth(showsLeftSidebar: true) == 440)
    #expect(metrics.rootShellMinimumWidth(showsLeftSidebar: false) == 260)
    #expect(metrics.rootShellMinimumHeight(showsBottomPanel: true) == 420)
    #expect(metrics.rootShellMinimumHeight(showsBottomPanel: false) == 300)
}

@Test func dynamicInspectorMaxPreservesRootShellWidth() async throws {
    let metrics = EditorLayoutMetrics(
        leftMinWidth: 180,
        centerMinWidth: 260,
        rightMinWidth: 320,
        rightIdealWidth: 420,
        rightMaxWidth: nil
    )

    #expect(
        metrics.resolvedRightInspectorMaxWidth(
            windowContentWidth: 1_280,
            showsLeftSidebar: true
        ) == 840
    )
    #expect(
        metrics.resolvedRightInspectorMaxWidth(
            windowContentWidth: 600,
            showsLeftSidebar: true
        ) == 320
    )
    #expect(
        metrics.resolvedRightInspectorMaxWidth(
            windowContentWidth: nil,
            showsLeftSidebar: true
        ) == 420
    )
}
