[![CI](https://github.com/briannadoubt/EditorLayout/actions/workflows/ci.yml/badge.svg)](https://github.com/briannadoubt/EditorLayout/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)

# EditorLayout

`EditorLayout` is a macOS-first SwiftUI package for editor-style window shells with a left sidebar, a central workspace, a right inspector, and an optional bottom panel.

It focuses on the hard parts of app chrome rather than app-specific content:

- stable split and inspector sizing
- dynamic inspector width caps that preserve the minimum editor shell
- a single host container that can show or hide sidebar, inspector, and bottom panel independently
- a native macOS layout path with a SwiftUI fallback path for other Apple platforms

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
    @State private var showsLeftSidebar = true
    @State private var showsInspector = true
    @State private var showsBottomPanel = false

    var body: some View {
        EditorLayout(
            showsLeftSidebar: $showsLeftSidebar,
            showsInspector: $showsInspector,
            showsBottomPanel: $showsBottomPanel
        ) {
            ProjectSidebar()
        } content: {
            EditorWorkspace()
        } inspector: {
            InspectorPanel()
        } bottomPanel: {
            ConsolePanel()
        }
    }
}
```

Use `EditorLayoutMetrics` to tune minimum, ideal, and maximum sizes for each region when your app needs a different shell profile.

`EditorLayoutContainer` remains available as a deprecated compatibility alias if you already shipped code against the older name.

## Demo App

Generate the local macOS demo project with `XcodeGen`:

```bash
brew install xcodegen
cd Demo
./generate_project.sh
open EditorLayoutDemo.xcodeproj
```

The demo project opens a sample app-specific shell built with `EditorLayout` and references the local package from the repo root.

## Testing

```bash
swift test
```

## Releasing

Push a semver tag such as `0.1.0` or `v0.1.0` to run the release workflow and publish a GitHub release.

## License

MIT. See [LICENSE](LICENSE).
