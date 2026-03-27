import AppKit

@MainActor
public final class EditorStackController: NSViewController {
    public let tabViewController = NSTabViewController()

    public override func loadView() {
        view = NSView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tabViewController.tabStyle = .unspecified
        addChild(tabViewController)

        let tabView = tabViewController.view
        tabView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabView)

        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabView.topAnchor.constraint(equalTo: view.topAnchor),
            tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    public func openTab(_ viewController: NSViewController, title: String) {
        viewController.title = title
        tabViewController.addChild(viewController)
    }

    public func closeTab(at index: Int) {
        guard tabViewController.tabViewItems.indices.contains(index) else {
            return
        }

        tabViewController.removeTabViewItem(tabViewController.tabViewItems[index])
    }
}
