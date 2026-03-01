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

    var body: some View {
        let nestingMap = DescriptionRenderer.detectNesting(state.layout.blocks)
        let blockNumbers = assignNumbers(blocks: state.layout.blocks, nestingMap: nestingMap)

        VStack(spacing: 0) {
            titleBar
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Sidebar (Add Element) + Canvas + Legend
            HStack(spacing: 12) {
                addElementSidebar
                    .frame(width: 120)

                GridCanvasView(
                    layout: $state.layout,
                    interactive: true,
                    blockNumbers: blockNumbers,
                    onAddBlock: { col, row in
                        addBlockCol = col
                        addBlockRow = row
                        showAddSheet = true
                    },
                    nestingMap: nestingMap
                )
            }
            .padding(.horizontal, 16)

            // Bottom row: instructions left, undo/redo + buttons right
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drag to move · Resize from corner · Double-click to rename · ⌥ Cycle layers")
                        .font(.system(size: 11))
                        .foregroundColor(Color(Theme.textMuted))
                    Text("⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete")
                        .font(.system(size: 10))
                        .foregroundColor(Color(Theme.textMuted).opacity(0.7))
                }
                .lineLimit(1)

                Spacer()

                // Undo/Redo buttons
                HStack(spacing: 8) {
                    Button {
                        state.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(state.canUndo ? Color(Theme.textSecondary) : Color(Theme.textMuted))
                    }
                    .buttonStyle(.plain)
                    .disabled(!state.canUndo)
                    .help("Undo (⌘Z)")

                    Button {
                        state.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .foregroundColor(state.canRedo ? Color(Theme.textSecondary) : Color(Theme.textMuted))
                    }
                    .buttonStyle(.plain)
                    .disabled(!state.canRedo)
                    .help("Redo (⌘⇧Z)")
                }

                FocusableButton(title: "Cancel", isPrimary: false) {
                    state.status = "cancelled"
                    NSApp.stopModal()
                }
                .frame(width: 120, height: 48)

                FocusableButton(title: "Accept", isPrimary: true) {
                    state.status = state.layout == state.initialLayout ? "accepted" : "modified"
                    NSApp.stopModal()
                }
                .frame(width: 140, height: 48)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
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

    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
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

    private var addElementSidebar: some View {
        VStack {
            Button {
                addBlockCol = firstEmptyCell.col
                addBlockRow = firstEmptyCell.row
                showAddSheet = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                    Text("Add Element")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(Theme.textSecondary))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
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

            Spacer()
        }
    }

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
