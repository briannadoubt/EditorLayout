# Contributing to EditorLayout

## Setup

- Use Xcode 16.3 or newer with Swift 6.2 support.
- Clone the repo and work on a short-lived branch from `main`.
- Keep changes focused on layout infrastructure; app-specific chrome belongs in the host app, not this package.

## Local Checks

- Run `swift build`
- Run `swift test`

## Change Guidelines

- Add or update tests for layout or sizing behavior changes.
- Keep public API additions small and documented in `README.md`.
- Prefer deterministic sizing logic over environment-coupled heuristics where possible.

## Pull Requests

- Describe the user-visible behavior change.
- Call out any platform-specific assumptions.
- Include screenshots or recordings when a visual sizing change is easier to review that way.
