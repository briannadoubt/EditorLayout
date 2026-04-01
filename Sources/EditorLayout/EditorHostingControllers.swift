import AppKit
import SwiftUI

@MainActor
final class EditorHostingViewController<Root: View>: NSViewController {
    private let hostingController: NSHostingController<Root>
    private let backgroundMaterial: NSVisualEffectView.Material?

    init(
        rootView: Root,
        backgroundMaterial: NSVisualEffectView.Material? = nil
    ) {
        hostingController = NSHostingController(rootView: rootView)
        self.backgroundMaterial = backgroundMaterial
        super.init(nibName: nil, bundle: nil)
        hostingController.sizingOptions = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        if let backgroundMaterial {
            let materialView = NSVisualEffectView()
            materialView.material = backgroundMaterial
            materialView.blendingMode = .withinWindow
            materialView.state = .followsWindowActiveState
            view = materialView
        } else {
            view = NSView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        embedHostedView()
    }

    func update(rootView: Root) {
        hostingController.rootView = rootView
    }

    private func embedHostedView() {
        let hostedView = hostingController.view

        addChild(hostingController)
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

@MainActor
final class EditorAnyHostingViewController: NSViewController {
    private let hostingController: NSHostingController<AnyView>

    init(rootView: AnyView) {
        hostingController = NSHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
        hostingController.sizingOptions = []
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
        embedHostedView()
    }

    func update(rootView: AnyView) {
        hostingController.rootView = rootView
    }

    private func embedHostedView() {
        let hostedView = hostingController.view

        addChild(hostingController)
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
