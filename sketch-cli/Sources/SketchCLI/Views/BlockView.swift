import SwiftUI

struct BlockView: View {
    @Binding var block: GridBlock
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let gridColumns: Int
    let gridRows: Int
    var interactive: Bool = true
    var isNested: Bool = false
    var hoverOverride: Bool? = nil
    var displayNumber: String = ""
    var onDelete: (() -> Void)?
    var onRename: ((String) -> Void)?
    var onDuplicate: (() -> Void)?

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var isResizing = false
    @State private var resizeDelta: CGSize = .zero
    @State private var isEditing = false
    @State private var editText = ""
    @State private var dragCoordinates: String?
    @State private var resizePreview: String?
    @State private var isHovered = false

    /// hoverOverride wins when cycling; falls back to natural SwiftUI hover
    private var effectiveHover: Bool { hoverOverride ?? isHovered }

    private var blockColor: Color {
        ColorPalette.swiftUIColor(from: block.color ?? "#3B82F6")
    }

    private var currentW: CGFloat {
        let base = CGFloat(block.w) * cellWidth
        return isResizing ? max(cellWidth, base + resizeDelta.width) : base
    }

    private var currentH: CGFloat {
        let base = CGFloat(block.h) * cellHeight
        return isResizing ? max(cellHeight, base + resizeDelta.height) : base
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(blockColor.opacity(isDragging ? 0.5 : (isNested ? 0.35 : 0.25)))
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(blockColor, style: StrokeStyle(
                    lineWidth: (isDragging || effectiveHover) ? 2 : 1,
                    dash: isNested ? [4, 3] : []
                ))

            // Number badge at top-left
            VStack(spacing: 0) {
                HStack {
                    if isEditing {
                        TextField("Label", text: $editText)
                            .onSubmit {
                                if !editText.isEmpty {
                                    onRename?(editText)
                                }
                                isEditing = false
                            }
                            .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(Theme.textPrimary))
                        .padding(4)
                        .background(Color(Theme.cardBackground))
                        .cornerRadius(4)
                        .onExitCommand {
                            isEditing = false
                            editText = block.label
                        }
                    } else {
                        Text(displayNumber)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(blockColor.opacity(0.85))
                            .cornerRadius(4)
                            .padding(3)
                    }
                    Spacer()
                }
                Spacer()
            }

            if effectiveHover && !isEditing && !isDragging {
                Text(block.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(6)
            }

            if interactive {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        resizeHandle
                    }
                }
            }

            // Coordinate tooltip during drag
            if let coords = dragCoordinates {
                VStack {
                    Text(coords)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(6)
                        .shadow(radius: 4)
                        .offset(y: -8)
                    Spacer()
                }
            }

            // Size preview during resize
            if let preview = resizePreview {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(preview)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(6)
                            .shadow(radius: 4)
                            .offset(x: 8, y: 8)
                    }
                }
            }
        }
        .frame(width: currentW - (isNested ? 6 : 2), height: currentH - (isNested ? 6 : 2))
        .offset(isDragging ? dragOffset : .zero)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard interactive else { return }
            editText = block.label
            isEditing = true
        }
        .onHover { hovering in isHovered = hovering }
        .gesture(interactive ? dragGesture : nil)
        .contextMenu {
            if interactive {
                Button {
                    onDuplicate?()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .zIndex(effectiveHover ? 1 : 0)
    }

    private var resizeHandle: some View {
        ZStack {
            // Background circle for better visibility
            Circle()
                .fill(blockColor.opacity(0.2))
                .frame(width: 24, height: 24)

            Image(systemName: "arrow.down.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(blockColor.opacity(isResizing ? 1.0 : 0.7))
        }
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
        .gesture(resizeGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation

                // Show coordinate preview
                let colDelta = Int(round(value.translation.width / cellWidth))
                let rowDelta = Int(round(value.translation.height / cellHeight))
                let newX = max(0, min(gridColumns - block.w, block.x + colDelta))
                let newY = max(0, min(gridRows - block.h, block.y + rowDelta))
                dragCoordinates = "x: \(newX), y: \(newY)"
            }
            .onEnded { value in
                isDragging = false
                dragCoordinates = nil

                let colDelta = Int(round(value.translation.width / cellWidth))
                let rowDelta = Int(round(value.translation.height / cellHeight))
                block.x = max(0, min(gridColumns - block.w, block.x + colDelta))
                block.y = max(0, min(gridRows - block.h, block.y + rowDelta))
                dragOffset = .zero
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("canvas"))
            .onChanged { value in
                isResizing = true
                resizeDelta = value.translation

                // Show size preview
                let colDelta = Int(round(value.translation.width / cellWidth))
                let rowDelta = Int(round(value.translation.height / cellHeight))
                let newW = max(1, min(gridColumns - block.x, block.w + colDelta))
                let newH = max(1, min(gridRows - block.y, block.h + rowDelta))
                resizePreview = "\(newW)×\(newH)"
            }
            .onEnded { value in
                isResizing = false
                resizePreview = nil

                let colDelta = Int(round(value.translation.width / cellWidth))
                let rowDelta = Int(round(value.translation.height / cellHeight))
                block.w = max(1, min(gridColumns - block.x, block.w + colDelta))
                block.h = max(1, min(gridRows - block.y, block.h + rowDelta))
                resizeDelta = .zero
            }
    }
}
