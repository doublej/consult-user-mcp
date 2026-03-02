import SwiftUI

enum ColorPalette {
    static let colors: [String] = [
        "#3B82F6", // blue
        "#10B981", // emerald
        "#F59E0B", // amber
        "#EF4444", // red
        "#8B5CF6", // violet
        "#EC4899", // pink
        "#06B6D4", // cyan
        "#F97316", // orange
        "#84CC16", // lime
        "#6366F1", // indigo
        "#14B8A6", // teal
        "#A855F7", // purple
    ]

    static func assignColors(to blocks: [GridBlock]) -> [GridBlock] {
        blocks.enumerated().map { index, block in
            var b = block
            if b.color == nil {
                b.color = colors[index % colors.count]
            }
            return b
        }
    }

    static func swiftUIColor(from hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let rgb = UInt64(cleaned, radix: 16) else {
            return .blue
        }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
