import SwiftUI

struct AddBlockSheet: View {
    let col: Int
    let row: Int
    var onAdd: (String) -> Void

    @State private var label = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Block")
                .font(.headline)

            TextField("Block label", text: $label)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    guard !label.isEmpty else { return }
                    onAdd(label)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(label.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
