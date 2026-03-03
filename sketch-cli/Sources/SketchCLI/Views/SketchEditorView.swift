import SwiftUI

@MainActor
class SketchEditorState: ObservableObject {
    @Published var layout: GridLayout {
        didSet {
            pushUndo(oldValue)
        }
    }
    let initialLayout: GridLayout
    var status: String = "cancelled"

    private var undoStack: [GridLayout] = []
    private var redoStack: [GridLayout] = []
    private var isUndoing = false

    init(layout: GridLayout) {
        self.layout = layout
        self.initialLayout = layout
    }

    private func pushUndo(_ layout: GridLayout) {
        guard !isUndoing else { return }
        undoStack.append(layout)
        redoStack.removeAll()
        if undoStack.count > 50 { undoStack.removeFirst() }
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        isUndoing = true
        redoStack.append(layout)
        layout = undoStack.removeLast()
        isUndoing = false
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        isUndoing = true
        undoStack.append(layout)
        layout = redoStack.removeLast()
        isUndoing = false
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}

struct SketchEditorView: View {
    @ObservedObject var state: SketchEditorState
    let titleText: String
    let descriptionText: String?

    @State private var showAddSheet = false
    @State private var addBlockCol = 0
    @State private var addBlockRow = 0
    @State private var stashedBlocks: [GridBlock] = []
    @State private var isDraggingBlock = false
    @State private var isOverStashZone = false
    @State private var isOverSidebarStash = false

    var body: some View {
        let nestingMap = DescriptionRenderer.detectNesting(state.layout.blocks)
        let blockNumbers = assignNumbers(blocks: state.layout.blocks, nestingMap: nestingMap)

        VStack(spacing: 0) {
            // Header
            titleBar
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Left sidebar + Canvas
            HStack(spacing: 12) {
                sidebar
                    .frame(width: 120)

                VStack(spacing: 8) {
                    let canvas = GridCanvasView(
                        layout: $state.layout,
                        stashedBlocks: $stashedBlocks,
                        interactive: true,
                        blockNumbers: blockNumbers,
                        onAddBlock: { col, row in
                            addBlockCol = col
                            addBlockRow = row
                            showAddSheet = true
                        },
                        onDragHintChanged: { dragging, overBottom, overSidebar in
                            isDraggingBlock = dragging
                            isOverStashZone = overBottom
                            isOverSidebarStash = overSidebar
                        },
                        nestingMap: nestingMap
                    )
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                    )

                    Group {
                        if let frameStr = state.layout.frame, let deviceFrame = DeviceFrame(rawValue: frameStr) {
                            DeviceFrameView(frame: deviceFrame) { canvas }
                        } else {
                            canvas
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if isDraggingBlock {
                            dropToStashHint(highlighted: isOverStashZone)
                                .padding(8)
                        }
                    }

                    if let annotations = state.layout.annotations, !annotations.isEmpty {
                        annotationLegend(annotations)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 20)

            // Footer
            footer
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
        .background(Color(Theme.windowBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showAddSheet) {
            AddBlockSheet(
                col: addBlockCol,
                row: addBlockRow,
                onAdd: { label in
                    let newBlock = GridBlock(
                        label: label,
                        x: addBlockCol, y: addBlockRow,
                        w: 1, h: 1,
                        color: ColorPalette.colors[state.layout.blocks.count % ColorPalette.colors.count]
                    )
                    state.layout.blocks.append(newBlock)
                }
            )
        }
    }

    // MARK: - Header

    private var titleBar: some View {
        HStack {
            ReportButton()
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(Theme.textPrimary))
                if let desc = descriptionText {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(Color(Theme.textSecondary))
                }
            }
            Spacer()
            Text("\(state.layout.columns)\u{00D7}\(state.layout.rows)")
                .font(.system(size: 12))
                .foregroundColor(Color(Theme.textMuted))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(white: 0.2))
                .clipShape(Capsule())
        }
        .background(WindowDragArea())
    }

    // MARK: - Sidebar (undo/redo, add, stash)

    private var sidebar: some View {
        VStack(spacing: 8) {
            // Undo/Redo
            HStack(spacing: 4) {
                sidebarIconButton(icon: "arrow.uturn.backward", enabled: state.canUndo) { state.undo() }
                    .help("Undo (⌘Z)")
                sidebarIconButton(icon: "arrow.uturn.forward", enabled: state.canRedo) { state.redo() }
                    .help("Redo (⌘⇧Z)")
            }

            // Add Element
            Button {
                addBlockCol = firstEmptyCell.col
                addBlockRow = firstEmptyCell.row
                showAddSheet = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Color(Theme.textSecondary))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(Theme.cardBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(Theme.border), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Drop zone (visible while dragging)
            if isDraggingBlock {
                sidebarStashDropZone(highlighted: isOverSidebarStash)
            }

            // Stash tray
            if !stashedBlocks.isEmpty {
                stashTray
            }

            Spacer()
        }
    }

    private func sidebarIconButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(enabled ? Color(Theme.textSecondary) : Color(Theme.textMuted))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(Theme.cardBackground))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Stash tray

    private var stashTray: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stash")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(Theme.textMuted))
                .textCase(.uppercase)

            ForEach(stashedBlocks) { block in
                stashChip(block: block)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(Theme.cardBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(Theme.border).opacity(0.5), lineWidth: 1)
        )
    }

    private func stashChip(block: GridBlock) -> some View {
        let color = ColorPalette.swiftUIColor(from: block.color ?? "#3B82F6")
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(block.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(Theme.textPrimary))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(Theme.cardHover).opacity(0.6))
        )
        .onTapGesture { restoreBlock(id: block.id) }
    }

    private func restoreBlock(id: String) {
        guard let idx = stashedBlocks.firstIndex(where: { $0.id == id }) else { return }
        let block = stashedBlocks.remove(at: idx)
        state.layout.blocks.append(block)
    }

    // MARK: - Drop hint

    private func sidebarStashDropZone(highlighted: Bool) -> some View {
        Label("Drop here", systemImage: "tray.and.arrow.down")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(highlighted ? .white : Color(Theme.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(highlighted ? Color.orange.opacity(0.6) : Color(Theme.cardBackground).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        highlighted ? Color.orange : Color(Theme.border),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                    )
            )
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.15), value: highlighted)
    }

    private func dropToStashHint(highlighted: Bool) -> some View {
        Label("Drop to stash", systemImage: "tray.and.arrow.down")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(highlighted ? .white : Color(Theme.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(highlighted ? Color.orange.opacity(0.6) : Color(Theme.cardBackground).opacity(0.7))
            )
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.15), value: highlighted)
    }

    // MARK: - Annotation legend

    private func annotationLegend(_ annotations: [Annotation]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(annotations.enumerated()), id: \.offset) { index, annotation in
                HStack(spacing: 6) {
                    ZStack {
                        Circle().fill(Color.orange).frame(width: 16, height: 16)
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text(annotation.text)
                        .font(.system(size: 11))
                        .foregroundColor(Color(Theme.textSecondary))
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(Theme.cardBackground))
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Drag to move · Resize from corner · Double-click to rename")
                    .font(.system(size: 10))
                    .foregroundColor(Color(Theme.textMuted))
                Text("⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete")
                    .font(.system(size: 10))
                    .foregroundColor(Color(Theme.textMuted).opacity(0.7))
            }
            .lineLimit(1)

            Spacer()

            FocusableButton(title: "Cancel", isPrimary: false) {
                state.status = "cancelled"
                NSApp.stopModal()
            }
            .frame(width: 110, height: 44)

            FocusableButton(title: "Accept", isPrimary: true) {
                state.status = state.layout == state.initialLayout ? "accepted" : "modified"
                NSApp.stopModal()
            }
            .frame(width: 130, height: 44)
        }
    }

    // MARK: - Helpers

    private var firstEmptyCell: (col: Int, row: Int) {
        for row in 0..<state.layout.rows {
            for col in 0..<state.layout.columns {
                let occupied = state.layout.blocks.contains { b in
                    col >= b.x && col < b.x + b.w && row >= b.y && row < b.y + b.h
                }
                if !occupied { return (col, row) }
            }
        }
        return (0, 0)
    }

    private func assignNumbers(blocks: [GridBlock], nestingMap: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        func recurse(parentId: String?, prefix: String) {
            let children = blocks
                .filter { nestingMap[$0.id] == parentId }
                .sorted { $0.y != $1.y ? $0.y < $1.y : $0.x < $1.x }

            for (i, block) in children.enumerated() {
                let number = "\(prefix)\(i + 1)"
                result[block.id] = number
                recurse(parentId: block.id, prefix: "\(number):")
            }
        }
        recurse(parentId: nil, prefix: "")
        return result
    }
}
