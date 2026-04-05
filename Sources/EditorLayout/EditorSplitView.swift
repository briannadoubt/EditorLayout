import AppKit
import SwiftUI

@MainActor
func editorSplitVisibilityBindings(
    from layoutState: Binding<EditorSplitLayoutState>
) -> (
    showsSidebar: Binding<Bool>,
    showsInspector: Binding<Bool>,
    showsBottomPanel: Binding<Bool>
) {
    (
        showsSidebar: Binding(
            get: { layoutState.wrappedValue.showsSidebar },
            set: { isVisible in
                var state = layoutState.wrappedValue
                state.showsSidebar = isVisible
                layoutState.wrappedValue = state
            }
        ),
        showsInspector: Binding(
            get: { layoutState.wrappedValue.showsInspector },
            set: { isVisible in
                var state = layoutState.wrappedValue
                state.showsInspector = isVisible
                layoutState.wrappedValue = state
            }
        ),
        showsBottomPanel: Binding(
            get: { layoutState.wrappedValue.showsBottomPanel },
            set: { isVisible in
                var state = layoutState.wrappedValue
                state.showsBottomPanel = isVisible
                layoutState.wrappedValue = state
            }
        )
    )
}

@MainActor
public struct EditorSplitView<Sidebar: View, Content: View, Inspector: View>: NSViewControllerRepresentable {
    @Binding private var showsSidebar: Bool
    @Binding private var showsInspector: Bool
    @Binding private var showsBottomPanel: Bool

    private let configuration: EditorSplitConfiguration
    private let sidebar: Sidebar
    private let content: Content
    private let inspector: Inspector
    private let bottom: AnyView?
    private let legacyLayoutState: Binding<EditorSplitLayoutState>?

    public init(
        layoutState: Binding<EditorSplitLayoutState> = .constant(.init()),
        configuration: EditorSplitConfiguration = .init(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector
    ) {
        let visibilityBindings = editorSplitVisibilityBindings(from: layoutState)
        _showsSidebar = visibilityBindings.showsSidebar
        _showsInspector = visibilityBindings.showsInspector
        _showsBottomPanel = visibilityBindings.showsBottomPanel
        self.configuration = configuration
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
        bottom = nil
        legacyLayoutState = layoutState
    }

    public init<Bottom: View>(
        layoutState: Binding<EditorSplitLayoutState> = .constant(.init()),
        configuration: EditorSplitConfiguration = .init(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector,
        @ViewBuilder bottom: () -> Bottom
    ) {
        let visibilityBindings = editorSplitVisibilityBindings(from: layoutState)
        _showsSidebar = visibilityBindings.showsSidebar
        _showsInspector = visibilityBindings.showsInspector
        _showsBottomPanel = visibilityBindings.showsBottomPanel
        self.configuration = configuration
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
        self.bottom = AnyView(bottom())
        legacyLayoutState = layoutState
    }

    public init(
        showsSidebar: Binding<Bool> = .constant(true),
        showsInspector: Binding<Bool> = .constant(true),
        configuration: EditorSplitConfiguration = .init(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector
    ) {
        _showsSidebar = showsSidebar
        _showsInspector = showsInspector
        _showsBottomPanel = .constant(false)
        self.configuration = configuration
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
        bottom = nil
        legacyLayoutState = nil
    }

    public init<Bottom: View>(
        showsSidebar: Binding<Bool> = .constant(true),
        showsInspector: Binding<Bool> = .constant(true),
        showsBottomPanel: Binding<Bool> = .constant(true),
        configuration: EditorSplitConfiguration = .init(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector,
        @ViewBuilder bottom: () -> Bottom
    ) {
        _showsSidebar = showsSidebar
        _showsInspector = showsInspector
        _showsBottomPanel = showsBottomPanel
        self.configuration = configuration
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
        self.bottom = AnyView(bottom())
        legacyLayoutState = nil
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            showsSidebar: _showsSidebar,
            showsInspector: _showsInspector,
            showsBottomPanel: _showsBottomPanel,
            legacyLayoutState: legacyLayoutState
        )
    }

    public func makeNSViewController(context: Context) -> EditorSplitController {
        let sidebarController = EditorHostingViewController(rootView: sidebar)
        let contentController = EditorHostingViewController(rootView: content)
        let inspectorController = EditorHostingViewController(rootView: inspector)
        let bottomController = bottom.map { EditorAnyHostingViewController(rootView: $0) }

        let controller = EditorSplitController(
            sidebar: sidebarController,
            content: contentController,
            inspector: inspectorController,
            bottom: bottomController,
            configuration: configuration,
            initialState: resolvedLayoutState()
        )
        controller.layoutStateDidChange = { [weak coordinator = context.coordinator] state in
            coordinator?.applyReportedLayoutState(state)
        }

        context.coordinator.sidebarController = sidebarController
        context.coordinator.contentController = contentController
        context.coordinator.inspectorController = inspectorController
        context.coordinator.bottomController = bottomController
        context.coordinator.lastAppliedLayoutState = resolvedLayoutState()

        return controller
    }

    public func updateNSViewController(_ nsViewController: EditorSplitController, context: Context) {
        context.coordinator.showsSidebar = _showsSidebar
        context.coordinator.showsInspector = _showsInspector
        context.coordinator.showsBottomPanel = _showsBottomPanel
        context.coordinator.legacyLayoutState = legacyLayoutState

        context.coordinator.sidebarController?.update(rootView: sidebar)
        context.coordinator.contentController?.update(rootView: content)
        context.coordinator.inspectorController?.update(rootView: inspector)

        if let bottom {
            if let bottomController = context.coordinator.bottomController {
                bottomController.update(rootView: bottom)
            } else {
                let bottomController = EditorAnyHostingViewController(rootView: bottom)
                context.coordinator.bottomController = bottomController
                nsViewController.replaceBottomViewController(bottomController)
            }
        } else if context.coordinator.bottomController != nil {
            context.coordinator.bottomController = nil
            nsViewController.replaceBottomViewController(nil)
        }

        nsViewController.configuration = configuration

        let desiredLayoutState = resolvedLayoutState()
        if context.coordinator.lastAppliedLayoutState != desiredLayoutState {
            context.coordinator.lastAppliedLayoutState = desiredLayoutState
            nsViewController.applyLayoutState(desiredLayoutState)
        }
    }

    private func resolvedLayoutState() -> EditorSplitLayoutState {
        EditorSplitLayoutState(
            sidebarWidth: legacyLayoutState?.wrappedValue.sidebarWidth,
            inspectorWidth: legacyLayoutState?.wrappedValue.inspectorWidth,
            bottomHeight: legacyLayoutState?.wrappedValue.bottomHeight,
            showsSidebar: showsSidebar,
            showsInspector: showsInspector,
            showsBottomPanel: bottom == nil ? false : showsBottomPanel
        )
    }

    @MainActor
    public final class Coordinator {
        fileprivate var showsSidebar: Binding<Bool>
        fileprivate var showsInspector: Binding<Bool>
        fileprivate var showsBottomPanel: Binding<Bool>
        fileprivate var legacyLayoutState: Binding<EditorSplitLayoutState>?
        fileprivate var sidebarController: EditorHostingViewController<Sidebar>?
        fileprivate var contentController: EditorHostingViewController<Content>?
        fileprivate var inspectorController: EditorHostingViewController<Inspector>?
        fileprivate var bottomController: EditorAnyHostingViewController?
        fileprivate var lastAppliedLayoutState: EditorSplitLayoutState?

        fileprivate init(
            showsSidebar: Binding<Bool>,
            showsInspector: Binding<Bool>,
            showsBottomPanel: Binding<Bool>,
            legacyLayoutState: Binding<EditorSplitLayoutState>?
        ) {
            self.showsSidebar = showsSidebar
            self.showsInspector = showsInspector
            self.showsBottomPanel = showsBottomPanel
            self.legacyLayoutState = legacyLayoutState
        }

        fileprivate func applyReportedLayoutState(_ state: EditorSplitLayoutState) {
            lastAppliedLayoutState = state

            if let legacyLayoutState, legacyLayoutState.wrappedValue != state {
                Task { @MainActor [legacyLayoutState] in
                    legacyLayoutState.wrappedValue = state
                }
            }

            if showsSidebar.wrappedValue != state.showsSidebar {
                Task { @MainActor [showsSidebar] in
                    showsSidebar.wrappedValue = state.showsSidebar
                }
            }

            if showsInspector.wrappedValue != state.showsInspector {
                Task { @MainActor [showsInspector] in
                    showsInspector.wrappedValue = state.showsInspector
                }
            }

            if showsBottomPanel.wrappedValue != state.showsBottomPanel {
                Task { @MainActor [showsBottomPanel] in
                    showsBottomPanel.wrappedValue = state.showsBottomPanel
                }
            }
        }
    }
}
