import Foundation

enum BlockRole: String, Codable, CaseIterable {
    case header, sidebar, canvas, footer, toolbar, panel
}

enum ImportanceLevel: String, Codable, CaseIterable {
    case primary, secondary, tertiary
}

enum DeviceFrame: String, Codable, CaseIterable {
    case browser, phone, tablet
}

/// Shared visual constants for importance levels, used by both SwiftUI and SVG renderers.
struct ImportanceStyle {
    let fillOpacity: Double
    let strokeWidth: Double
    let dashed: Bool

    static func from(_ level: ImportanceLevel) -> ImportanceStyle {
        switch level {
        case .primary: return ImportanceStyle(fillOpacity: 0.35, strokeWidth: 2.5, dashed: false)
        case .secondary: return ImportanceStyle(fillOpacity: 0.25, strokeWidth: 1.5, dashed: false)
        case .tertiary: return ImportanceStyle(fillOpacity: 0.12, strokeWidth: 0.5, dashed: true)
        }
    }
}

/// Shared shadow constants for elevation levels, used by both SwiftUI and SVG renderers.
struct ElevationStyle {
    let opacity: Double
    let radius: Double
    let yOffset: Double

    static let levels: [ElevationStyle] = [
        ElevationStyle(opacity: 0, radius: 0, yOffset: 0),        // 0 — none
        ElevationStyle(opacity: 0.1, radius: 2, yOffset: 1),      // 1
        ElevationStyle(opacity: 0.15, radius: 6, yOffset: 3),     // 2
        ElevationStyle(opacity: 0.2, radius: 12, yOffset: 6),     // 3
    ]

    static func from(_ level: Int) -> ElevationStyle {
        levels[min(3, max(0, level))]
    }
}

/// Shared role-zone tint values (r, g, b, a), used by both SwiftUI and SVG renderers.
struct RoleZoneTint {
    let r: Double, g: Double, b: Double, a: Double

    static func from(_ role: BlockRole) -> RoleZoneTint {
        switch role {
        case .header, .footer: return RoleZoneTint(r: 160, g: 140, b: 120, a: 0.05)
        case .sidebar, .toolbar: return RoleZoneTint(r: 120, g: 140, b: 170, a: 0.05)
        case .canvas, .panel: return RoleZoneTint(r: 128, g: 128, b: 128, a: 0.03)
        }
    }

    var rgba: String { "rgba(\(Int(r)),\(Int(g)),\(Int(b)),\(a))" }
}
