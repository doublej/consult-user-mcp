import SwiftUI

// MARK: - SwiftUI Preview Pane (Review Before Send)

struct SwiftUIPreviewPane: View {
    let bodyText: String

    private var projectName: String? {
        DialogManager.shared.getProjectName()
    }

    private var projectPath: String? {
        DialogManager.shared.getProjectPath()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let name = projectName, let path = projectPath {
                HStack {
                    Spacer(minLength: 0)
                    ProjectBadge(projectName: name, projectPath: path)
                }
            }

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.textSecondary.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: "eye.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Text("Response Preview")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            ScrollView {
                Text(bodyText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 360, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, projectName == nil ? 16 : 12)
        .padding(.bottom, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Response preview. \(bodyText)"))
    }
}
