[![CI](https://github.com/briannadoubt/EditorLayout/actions/workflows/ci.yml/badge.svg)](https://github.com/briannadoubt/EditorLayout/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)

# EditorLayout

`EditorLayout` is a macOS-first SwiftUI package for editor-style window shells with a left sidebar, a central workspace, and a right inspector.

It focuses on the hard parts of app chrome rather than app-specific content:

- stable native split sizing backed by `NSSplitViewController`
- independently collapsible left and right panes
- a single host container that can show or hide sidebar and inspector independently
- a simple SwiftUI API that lands on the macOS-native split view stack with minimal customization
- an Xcode-style split controller path with a regular right pane, bottom panel support, snap behavior, and layout state binding

## Requirements

- macOS 15+
- Xcode 16.3+ / Swift 6.2+

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/briannadoubt/EditorLayout.git", from: "0.1.0")
]
```

```swift
.product(name: "EditorLayout", package: "EditorLayout")
```

## Example

```swift
import EditorLayout
import SwiftUI

struct RootView: View {
    @State private var showsSidebar = true
    @State private var showsInspector = true

    var body: some View {
        EditorView(
            showsSidebar: $showsSidebar,
            showsInspector: $showsInspector
        ) {
            ProjectSidebar()
        } content: {
            EditorWorkspace()
        } inspector: {
            InspectorPanel()
        }
    }
}
```

## Xcode-Style Split Example

Use `EditorSplitView` when you want a regular split item on the right instead of AppKit's inspector semantics.

```swift
import EditorLayout
import SwiftUI

struct IDEWindow: View {
    @State private var layoutState = EditorSplitLayoutState(
        sidebarWidth: 220,
        inspectorWidth: 280,
        bottomHeight: 180,
        showsSidebar: true,
        showsInspector: true,
        showsBottomPanel: true
    )

    var body: some View {
        EditorSplitView(layoutState: $layoutState) {
            ProjectSidebar()
        } content: {
            EditorWorkspace()
        } inspector: {
            InspectorPanel()
        } bottom: {
            TerminalPanel()
        }
    }
}
```

`EditorSplitController` is also public if you need direct AppKit control, and `EditorStackController` provides a simple tab-backed content container for editor stacks.

## Demo App

Generate the local macOS demo project with `XcodeGen`:

```bash
brew install xcodegen
cd Demo
./generate_project.sh
open EditorLayoutDemo.xcodeproj
```

The demo project opens an Xcode-style shell built with `EditorSplitView`, including a bottom panel and toolbar-driven pane toggles, and references the local package from the repo root.

## Testing

```bash
swift test
```

## Releasing

Push a semver tag such as `0.1.0` or `v0.1.0` to run the release workflow and publish a GitHub release.

## License

MIT. See [LICENSE](LICENSE).
