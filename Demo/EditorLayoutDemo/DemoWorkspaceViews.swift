import SwiftUI

struct DemoSidebarView: View {
    @ObservedObject var model: DemoWorkspaceModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Atlas Workspace")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Native AppKit sizing, SwiftUI composition, and layout telemetry working together.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        DemoCapsule(text: "LIVE", tint: Color(red: 0.28, green: 0.76, blue: 0.65))
                        DemoCapsule(text: "STATEFUL", tint: Color(red: 0.44, green: 0.58, blue: 0.96))
                    }
                }

                DemoCard(title: "Files", subtitle: "Package surface") {
                    VStack(spacing: 8) {
                        ForEach(DemoFile.allCases) { file in
                            Button {
                                model.selectedFile = file
                                model.record("Opened \(file.rawValue)")
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: file.symbolName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(file == model.selectedFile ? Color.white : Color.accentColor)
                                        .frame(width: 18)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.rawValue)
                                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        Text(file.summary)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundStyle(file == model.selectedFile ? Color.white.opacity(0.78) : Color.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            file == model.selectedFile
                                                ? LinearGradient(
                                                    colors: [
                                                        Color(red: 0.27, green: 0.45, blue: 0.92),
                                                        Color(red: 0.27, green: 0.70, blue: 0.83)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.05),
                                                        Color.white.opacity(0.01)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                DemoCard(title: "Signal", subtitle: "What changed") {
                    VStack(alignment: .leading, spacing: 12) {
                        DemoSignalRow(
                            title: "Sidebar",
                            detail: model.layoutState.showsSidebar ? "Visible at \(formattedWidth(model.layoutState.sidebarWidth))" : "Collapsed",
                            tint: Color(red: 0.33, green: 0.74, blue: 0.84)
                        )
                        DemoSignalRow(
                            title: "Inspector",
                            detail: model.layoutState.showsInspector ? "Visible at \(formattedWidth(model.layoutState.inspectorWidth))" : "Collapsed",
                            tint: Color(red: 0.98, green: 0.57, blue: 0.36)
                        )
                        DemoSignalRow(
                            title: "Console",
                            detail: model.layoutState.showsBottomPanel ? "Visible at \(formattedWidth(model.layoutState.bottomHeight))" : "Collapsed",
                            tint: Color(red: 0.47, green: 0.83, blue: 0.56)
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color.clear)
    }
}

struct DemoContentView: View {
    @ObservedObject var model: DemoWorkspaceModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.13),
                    Color(red: 0.06, green: 0.07, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                DemoTabStrip(model: model)

                HStack(alignment: .top, spacing: 18) {
                    DemoCard(title: "Working Copy", subtitle: model.selectedFile.summary, accent: Color(red: 0.33, green: 0.74, blue: 0.84)) {
                        ScrollView {
                            Text(model.selectedFile.snippet)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color(red: 0.88, green: 0.92, blue: 0.98))
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(spacing: 18) {
                        DemoCard(title: "Live Chrome", subtitle: "What this package is showing off", accent: Color(red: 0.96, green: 0.57, blue: 0.36)) {
                            VStack(alignment: .leading, spacing: 12) {
                                DemoFeatureChip(
                                    icon: "arrow.left.and.right.square",
                                    title: "Resizable native panes",
                                    detail: "The package keeps the workspace flexible while sidebars and inspectors stay bounded."
                                )
                                DemoFeatureChip(
                                    icon: "waveform.path.ecg.rectangle",
                                    title: "Live layout snapshots",
                                    detail: "Widths and visibility now flow back out as structured state."
                                )
                                DemoFeatureChip(
                                    icon: "rectangle.bottomthird.inset.filled",
                                    title: "Bottom-panel aware",
                                    detail: "The nested split reports height changes so host apps can persist console layouts."
                                )
                            }
                        }

                        DemoCard(title: "Preset Intent", subtitle: model.activePreset.title, accent: Color(red: 0.46, green: 0.67, blue: 0.98)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(presetDescription(model.activePreset))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 10) {
                                    DemoCapsule(text: model.layoutState.showsSidebar ? "NAV ON" : "NAV OFF", tint: Color(red: 0.33, green: 0.74, blue: 0.84))
                                    DemoCapsule(text: model.layoutState.showsInspector ? "INSPECT ON" : "INSPECT OFF", tint: Color(red: 0.96, green: 0.57, blue: 0.36))
                                    DemoCapsule(text: model.layoutState.showsBottomPanel ? "CONSOLE ON" : "CONSOLE OFF", tint: Color(red: 0.47, green: 0.83, blue: 0.56))
                                }
                            }
                        }
                    }
                    .frame(width: 320)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                DemoCard(title: "Release Readiness", subtitle: "Three reasons this demo matters", accent: Color(red: 0.47, green: 0.83, blue: 0.56)) {
                    HStack(spacing: 12) {
                        DemoStatCard(value: "2-way", label: "layout state flow")
                        DemoStatCard(value: "3", label: "workspace presets")
                        DemoStatCard(value: "100%", label: "native split stack")
                    }
                }
            }
            .padding(22)
        }
    }

    private func presetDescription(_ preset: DemoLayoutPreset) -> String {
        switch preset {
        case .build:
            "Balanced chrome for editing with the console open and the inspector visible."
        case .review:
            "Broader content surface with a wider inspector for annotations and sign-off."
        case .focus:
            "Minimal shell that drops auxiliary chrome so the content region takes over."
        }
    }
}

struct DemoInspectorView: View {
    @ObservedObject var model: DemoWorkspaceModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DemoCard(title: "Layout Telemetry", subtitle: "Live state binding", accent: Color(red: 0.96, green: 0.57, blue: 0.36)) {
                    VStack(alignment: .leading, spacing: 16) {
                        DemoMetricBar(
                            label: "Sidebar width",
                            valueText: formattedWidth(model.layoutState.sidebarWidth),
                            progress: normalizedWidth(model.layoutState.sidebarWidth, minimum: 220, maximum: 360),
                            tint: Color(red: 0.33, green: 0.74, blue: 0.84)
                        )
                        DemoMetricBar(
                            label: "Inspector width",
                            valueText: formattedWidth(model.layoutState.inspectorWidth),
                            progress: normalizedWidth(model.layoutState.inspectorWidth, minimum: 260, maximum: 380),
                            tint: Color(red: 0.96, green: 0.57, blue: 0.36)
                        )
                        DemoMetricBar(
                            label: "Console height",
                            valueText: formattedWidth(model.layoutState.bottomHeight),
                            progress: normalizedWidth(model.layoutState.bottomHeight, minimum: 150, maximum: 280),
                            tint: Color(red: 0.47, green: 0.83, blue: 0.56)
                        )
                    }
                }

                DemoCard(title: "Binding Output", subtitle: "Current snapshot") {
                    VStack(alignment: .leading, spacing: 12) {
                        InspectorKeyValueRow(label: "showsSidebar", value: model.layoutState.showsSidebar ? "true" : "false")
                        InspectorKeyValueRow(label: "showsInspector", value: model.layoutState.showsInspector ? "true" : "false")
                        InspectorKeyValueRow(label: "showsBottomPanel", value: model.layoutState.showsBottomPanel ? "true" : "false")
                        InspectorKeyValueRow(label: "sidebarWidth", value: formattedWidth(model.layoutState.sidebarWidth))
                        InspectorKeyValueRow(label: "inspectorWidth", value: formattedWidth(model.layoutState.inspectorWidth))
                        InspectorKeyValueRow(label: "bottomHeight", value: formattedWidth(model.layoutState.bottomHeight))
                    }
                }

                DemoCard(title: "Notes", subtitle: "Why the API changed") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("`EditorSplitLayoutState` now works as a true layout contract, not just initial input.")
                        Text("Dragging the nested bottom panel updates the same state stream as sidebar and inspector visibility changes.")
                        Text("The demo toolbar drives presets through the public API instead of reaching into private layout math.")
                    }
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(18)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.09, blue: 0.11),
                    Color(red: 0.10, green: 0.08, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct DemoConsoleView: View {
    @ObservedObject var model: DemoWorkspaceModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.03, green: 0.04, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Activity Console")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                    DemoCapsule(text: "\(model.logs.count) events", tint: Color(red: 0.47, green: 0.83, blue: 0.56))
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(model.logs) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.47, green: 0.83, blue: 0.56))
                                    .frame(width: 76, alignment: .leading)

                                Text(entry.message)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.83, green: 0.89, blue: 0.96))

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct DemoTabStrip: View {
    @ObservedObject var model: DemoWorkspaceModel

    var body: some View {
        HStack(spacing: 10) {
            ForEach(DemoFile.allCases) { file in
                Button {
                    model.selectedFile = file
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: file.symbolName)
                        Text(file.rawValue)
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(file == model.selectedFile ? Color.white : Color.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                file == model.selectedFile
                                    ? LinearGradient(
                                        colors: [
                                            Color(red: 0.27, green: 0.45, blue: 0.92),
                                            Color(red: 0.27, green: 0.70, blue: 0.83)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.07),
                                            Color.white.opacity(0.02)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

private struct DemoCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let accent: Color
    @ViewBuilder var content: Content

    init(
        title: String,
        subtitle: String? = nil,
        accent: Color = Color(red: 0.46, green: 0.67, blue: 0.98),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(accent.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

private struct DemoFeatureChip: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(red: 0.96, green: 0.57, blue: 0.36))
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DemoSignalRow: View {
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct DemoMetricBar: View {
    let label: String
    let valueText: String
    let progress: CGFloat
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, proxy.size.width * progress))
                }
            }
            .frame(height: 12)
        }
    }
}

private struct DemoStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

private struct DemoCapsule: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.16))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(tint.opacity(0.45), lineWidth: 1)
                    )
            )
    }
}

private struct InspectorKeyValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
    }
}

private func normalizedWidth(_ value: CGFloat?, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
    guard let value else {
        return 0.06
    }

    let clampedValue = min(maximum, max(minimum, value))
    let range = max(1, maximum - minimum)
    return max(0.06, min(1, (clampedValue - minimum) / range))
}

private func formattedWidth(_ value: CGFloat?) -> String {
    guard let value else {
        return "hidden"
    }

    return "\(Int(value.rounded())) pt"
}
