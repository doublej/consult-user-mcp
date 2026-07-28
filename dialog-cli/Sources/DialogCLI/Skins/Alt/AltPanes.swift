import SwiftUI

struct AltNotifyView: View {
    let spec: NotifySpec

    var body: some View {
        AltPane(
            kicker: "notify",
            title: spec.title,
            bodyText: spec.body,
            accent: Theme.Colors.accentBlue
        )
    }
}

struct AltPreviewView: View {
    let spec: PreviewSpec

    var body: some View {
        AltPane(
            kicker: "preview",
            title: "Response Preview",
            bodyText: spec.body,
            accent: Theme.Colors.textSecondary
        )
    }
}
