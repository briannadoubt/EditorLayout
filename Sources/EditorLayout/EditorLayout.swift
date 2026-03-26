import SwiftUI
#if os(macOS)
import AppKit
#endif

public struct EditorLayoutMetrics: Equatable, Sendable {
    public var leftMinWidth: CGFloat
    public var leftIdealWidth: CGFloat
    public var leftMaxWidth: CGFloat?
    public var centerMinWidth: CGFloat
    public var centerMinHeight: CGFloat
    public var rightMinWidth: CGFloat
    public var rightIdealWidth: CGFloat
    public var rightMaxWidth: CGFloat?
    public var bottomMinHeight: CGFloat
    public var bottomIdealHeight: CGFloat
    public var bottomMaxHeight: CGFloat?

    public init(
        leftMinWidth: CGFloat = 200,
        leftIdealWidth: CGFloat = 260,
        leftMaxWidth: CGFloat? = 420,
        centerMinWidth: CGFloat = 420,
        centerMinHeight: CGFloat = 300,
        rightMinWidth: CGFloat = 260,
        rightIdealWidth: CGFloat = 320,
        rightMaxWidth: CGFloat? = nil,
        bottomMinHeight: CGFloat = 120,
        bottomIdealHeight: CGFloat = 220,
        bottomMaxHeight: CGFloat? = 800
    ) {
        self.leftMinWidth = leftMinWidth
        self.leftIdealWidth = leftIdealWidth
        self.leftMaxWidth = leftMaxWidth
        self.centerMinWidth = centerMinWidth
        self.centerMinHeight = centerMinHeight
        self.rightMinWidth = rightMinWidth
        self.rightIdealWidth = rightIdealWidth
        self.rightMaxWidth = rightMaxWidth
        self.bottomMinHeight = bottomMinHeight
        self.bottomIdealHeight = bottomIdealHeight
        self.bottomMaxHeight = bottomMaxHeight
    }

    public static let standard = EditorLayoutMetrics()
}

/// A reusable editor-style shell that composes app content via view builders.
public struct EditorLayout<
    Sidebar: View,
    Content: View,
    Inspector: View,
    BottomPanel: View
>: View {
    @Binding private var showsLeftSidebar: Bool
    @Binding private var showsInspector: Bool
    @Binding private var showsBottomPanel: Bool
    @State private var windowContentWidth: CGFloat?

    private let metrics: EditorLayoutMetrics
    private let sidebar: Sidebar
    private let content: Content
    private let inspector: Inspector
    private let bottomPanel: BottomPanel

    public init(
        showsLeftSidebar: Binding<Bool>,
        showsInspector: Binding<Bool>,
        showsBottomPanel: Binding<Bool>,
        metrics: EditorLayoutMetrics = .standard,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder inspector: () -> Inspector,
        @ViewBuilder bottomPanel: () -> BottomPanel
    ) {
        _showsLeftSidebar = showsLeftSidebar
        _showsInspector = showsInspector
        _showsBottomPanel = showsBottomPanel
        self.metrics = metrics
        self.sidebar = sidebar()
        self.content = content()
        self.inspector = inspector()
        self.bottomPanel = bottomPanel()
    }

    public var body: some View {
        rootShell
        .background(windowWidthReader)
        .inspector(isPresented: $showsInspector) {
            inspectorFillContainer
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.clear)
                .clipped()
                .inspectorColumnWidth(
                    min: metrics.rightMinWidth,
                    ideal: metrics.rightIdealWidth,
                    max: resolvedRightInspectorMaxWidth
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
    }

    // Passing a nil max into SwiftUI's inspector column sizing can trigger
    // a macOS constraint update loop while the user resizes the inspector.
    // When no explicit app cap is provided, derive one from the current window
    // width so the inspector can grow until the workspace shell reaches its
    // minimum width, but no further.
    private var resolvedRightInspectorMaxWidth: CGFloat {
        #if os(macOS)
        let liveWindowWidth = windowContentWidth
            ?? NSApp.keyWindow?.contentLayoutRect.width
            ?? NSApp.mainWindow?.contentLayoutRect.width
        #else
        let liveWindowWidth = windowContentWidth
        #endif

        return metrics.resolvedRightInspectorMaxWidth(
            windowContentWidth: liveWindowWidth,
            showsLeftSidebar: showsLeftSidebar
        )
    }

    @ViewBuilder
    private var windowWidthReader: some View {
        #if os(macOS)
        if shouldTrackWindowWidth {
            WindowContentWidthReader(width: $windowContentWidth)
        } else {
            EmptyView()
        }
        #else
        EmptyView()
        #endif
    }

    private var shouldTrackWindowWidth: Bool {
        showsInspector && metrics.rightMaxWidth == nil
    }

    @ViewBuilder
    private var rootShell: some View {
        #if os(macOS)
        HSplitView {
            flexibleContainer(sidebar)
                .frame(
                    minWidth: resolvedLeftSidebarMinWidth,
                    idealWidth: resolvedLeftSidebarIdealWidth,
                    maxWidth: resolvedLeftSidebarMaxWidth,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .opacity(showsLeftSidebar ? 1 : 0)
                .allowsHitTesting(showsLeftSidebar)
                .accessibilityHidden(!showsLeftSidebar)

            flexibleContainer(centerColumn)
                .frame(minWidth: metrics.centerMinWidth, maxWidth: .infinity, alignment: .topLeading)
                .frame(minHeight: metrics.centerMinHeight, maxHeight: .infinity, alignment: .topLeading)
        }
        #else
        NavigationSplitView {
            if showsLeftSidebar {
                sidebar
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        } detail: {
            centerColumn
                .frame(
                    maxWidth: .infinity,
                    minHeight: metrics.centerMinHeight,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
        .navigationSplitViewStyle(.balanced)
        #endif
    }

    private var resolvedLeftSidebarMinWidth: CGFloat {
        showsLeftSidebar ? metrics.leftMinWidth : 0
    }

    private var resolvedLeftSidebarIdealWidth: CGFloat {
        showsLeftSidebar ? metrics.leftIdealWidth : 0
    }

    private var resolvedLeftSidebarMaxWidth: CGFloat? {
        guard showsLeftSidebar else { return 0 }
        return metrics.leftMaxWidth
    }

    @ViewBuilder
    private var inspectorFillContainer: some View {
        #if os(macOS)
        flexibleContainer(inspector)
        #else
        GeometryReader { proxy in
            inspector
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .topLeading
                )
        }
        #endif
    }

    @ViewBuilder
    private func flexibleContainer<Wrapped: View>(_ content: Wrapped) -> some View {
        #if os(macOS)
        FlexibleHostingContainer(content: content)
        #else
        content
        #endif
    }

    @ViewBuilder
    private var centerColumn: some View {
        if showsBottomPanel {
            VSplitView {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                bottomPanel
                    .frame(
                        minHeight: metrics.bottomMinHeight,
                        idealHeight: metrics.bottomIdealHeight,
                        maxHeight: metrics.bottomMaxHeight
                    )
            }
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

extension EditorLayoutMetrics {
    func rootShellMinimumWidth(showsLeftSidebar: Bool) -> CGFloat {
        centerMinWidth + (showsLeftSidebar ? leftMinWidth : 0)
    }

    func rootShellMinimumHeight(showsBottomPanel: Bool) -> CGFloat {
        centerMinHeight + (showsBottomPanel ? bottomMinHeight : 0)
    }

    func resolvedRightInspectorMaxWidth(
        windowContentWidth: CGFloat?,
        showsLeftSidebar: Bool
    ) -> CGFloat {
        if let rightMaxWidth {
            return rightMaxWidth
        }

        guard let windowContentWidth else {
            return max(rightIdealWidth, rightMinWidth)
        }

        return max(
            rightMinWidth,
            windowContentWidth - rootShellMinimumWidth(showsLeftSidebar: showsLeftSidebar)
        )
    }
}

@available(*, deprecated, renamed: "EditorLayout")
public typealias EditorLayoutContainer<
    Sidebar: View,
    Content: View,
    Inspector: View,
    BottomPanel: View
> = EditorLayout<Sidebar, Content, Inspector, BottomPanel>

#if os(macOS)
private struct WindowContentWidthReader: NSViewRepresentable {
    @Binding var width: CGFloat?

    func makeCoordinator() -> Coordinator {
        Coordinator(width: $width)
    }

    func makeNSView(context: Context) -> WindowContentWidthObserverView {
        let view = WindowContentWidthObserverView()
        view.onWidthChange = context.coordinator.updateWidth
        return view
    }

    func updateNSView(_ nsView: WindowContentWidthObserverView, context: Context) {
        nsView.onWidthChange = context.coordinator.updateWidth
        nsView.reportWindowWidthIfAvailable()
    }

    @MainActor
    final class Coordinator {
        @Binding private var width: CGFloat?

        init(width: Binding<CGFloat?>) {
            _width = width
        }

        func updateWidth(_ newWidth: CGFloat) {
            guard width.map({ abs($0 - newWidth) > 0.5 }) ?? true else { return }
            width = newWidth
        }
    }
}

@MainActor
final class WindowContentWidthObserverView: NSView {
    var onWidthChange: ((CGFloat) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureObserver()
        reportWindowWidthIfAvailable()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func reportWindowWidthIfAvailable() {
        guard let window else { return }
        onWidthChange?(window.contentLayoutRect.width)
    }

    private func configureObserver() {
        NotificationCenter.default.removeObserver(self)

        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowResize),
            name: NSWindow.didResizeNotification,
            object: window
        )
    }

    @objc
    private func handleWindowResize(_ notification: Notification) {
        reportWindowWidthIfAvailable()
    }
}

private struct FlexibleHostingContainer<Content: View>: NSViewRepresentable {
    let content: Content

    func makeNSView(context: Context) -> ContainerView {
        ContainerView(rootView: content)
    }

    func updateNSView(_ nsView: ContainerView, context: Context) {
        nsView.rootView = content
    }

    final class ContainerView: NSView {
        private let hostingView: NSHostingView<Content>

        init(rootView: Content) {
            hostingView = NSHostingView(rootView: rootView)
            super.init(frame: .zero)

            translatesAutoresizingMaskIntoConstraints = false
            wantsLayer = false

            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            hostingView.setContentHuggingPriority(.defaultLow, for: .vertical)
            hostingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            hostingView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

            addSubview(hostingView)
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

            setContentHuggingPriority(.defaultLow, for: .horizontal)
            setContentHuggingPriority(.defaultLow, for: .vertical)
            setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var rootView: Content {
            get { hostingView.rootView }
            set { hostingView.rootView = newValue }
        }

        override var intrinsicContentSize: NSSize {
            NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
    }
}
#endif
