# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

- Renamed the reusable builder-based shell to `EditorLayout` so apps import the composable API directly.
- Kept `EditorLayoutContainer` as a deprecated compatibility alias for existing integrations.
- Moved the demo sample view out of the package product and into the demo app target.

## 0.1.0 - 2026-03-25

- Added a local macOS demo app generated with `XcodeGen` and backed by the package's built-in `EditorLayout` sample view.
- Extended CI to validate both the Swift package and the generated demo app project.
- Added a tag-driven GitHub release workflow for semver releases.
- Aligned `EditorLayoutMetrics` defaults with the intended package behavior: a capped left sidebar, a dynamic right inspector cap, and a capped bottom panel.
