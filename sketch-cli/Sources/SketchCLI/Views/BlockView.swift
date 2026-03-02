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
    var onDragUpdate: ((CGSize?) -> Void)?
    var onDragEnd: ((Int, Int) -> Void)?

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

    private var importanceStyle: ImportanceStyle {
        ImportanceStyle.from(ContentInference.inferImportance(explicit: block.importance, role: block.role))
    }

    private var importanceFill: Double {
        if isDragging { return 0.5 }
        if isNested { return 0.35 }
        return importanceStyle.fillOpacity
    }

    private var importanceBorder: (width: CGFloat, dash: [CGFloat]) {
        if isDragging || effectiveHover { return (2.5, isNested ? [4, 3] : []) }
        let style = importanceStyle
        let dash: [CGFloat] = (style.dashed || isNested) ? [4, 3] : []
        return (CGFloat(style.strokeWidth), dash)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(blockColor.opacity(importanceFill))
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(blockColor, style: StrokeStyle(
                    lineWidth: importanceBorder.width,
                    dash: importanceBorder.dash
                ))

            // Wireframe content
            if let ct = ContentInference.resolve(explicit: block.content, label: block.label) {
                WireframeView(contentType: ct, color: blockColor)
            }

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
                        if let dir = block.flowDirection {
                            Text(dir == "row" ? "\u{2192}" : "\u{2193}")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(blockColor.opacity(0.7))
                        }
                    }
                    Spacer()
                }
                Spacer()
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
        .overlay {
            if effectiveHover && !isEditing && !isDragging {
                Text(block.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(6)
                    .allowsHitTesting(false)
            }
        }
        .modifier(ElevationShadow(level: ContentInference.inferElevation(explicit: block.elevation, label: block.label)))
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
        Canvas { context, size in
            let color = blockColor.opacity(isResizing ? 1.0 : 0.5)
            for i in 0..<3 {
                let offset = CGFloat(i) * 3.5
                var path = Path()
                path.move(to: CGPoint(x: size.width - 3 - offset, y: size.height - 1))
                path.addLine(to: CGPoint(x: size.width - 1, y: size.height - 3 - offset))
                context.stroke(path, with: .color(color), lineWidth: 1.5)
            }
        }
        .frame(width: 14, height: 14)
        .contentShape(Rectangle())
        .gesture(resizeGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
                onDragUpdate?(value.translation)

                let colDelta = Int(round(value.translation.width / cellWidth))
                let rowDelta = Int(round(value.translation.height / cellHeight))
                let newX = max(0, min(gridColumns - block.w, block.x + colDelta))
                let newY = max(0, min(gridRows - block.h, block.y + rowDelta))
                dragCoordinates = "x: \(newX), y: \(newY)"
            }
            .onEnded { value in
                isDragging = false
                dragCoordinates = nil
                dragOffset = .zero
                onDragUpdate?(nil)

                let colDelta = Int(round(value.translation.width / cellWidth))
                let rowDelta = Int(round(value.translation.height / cellHeight))
                onDragEnd?(colDelta, rowDelta)
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

private struct ElevationShadow: ViewModifier {
    let level: Int

    func body(content: Content) -> some View {
        let style = ElevationStyle.from(level)
        if style.radius > 0 {
            content.shadow(color: .black.opacity(style.opacity), radius: style.radius, y: style.yOffset)
        } else {
            content
        }
    }
}
