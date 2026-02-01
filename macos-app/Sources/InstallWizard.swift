import SwiftUI

// MARK: - Wizard Step Protocol

protocol WizardStep: Identifiable, CaseIterable, Equatable {
    var title: String { get }
}

extension WizardStep where Self: RawRepresentable, RawValue == Int {
    var id: Int { rawValue }
}

// MARK: - Wizard Progress Bar

struct WizardProgressBar<Step: WizardStep>: View where Step.AllCases: RandomAccessCollection {
    let currentStep: Step
    let steps: Step.AllCases

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep).map { steps.distance(from: steps.startIndex, to: $0) } ?? 0
    }

    private var progress: CGFloat {
        guard steps.count > 1 else { return 1 }
        return CGFloat(currentIndex) / CGFloat(steps.count - 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.separatorColor))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            // Step indicators
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepIndicator(step: step, index: index)
                    if index < steps.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }

    private func stepIndicator(step: Step, index: Int) -> some View {
        let isActive = index <= currentIndex
        let isCurrent = step == currentStep

        return VStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.accentColor : Color(.separatorColor))
                .frame(width: isCurrent ? 10 : 8, height: isCurrent ? 10 : 8)
                .animation(.easeInOut(duration: 0.2), value: isCurrent)

            Text(step.title)
                .font(.system(size: 9, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

// MARK: - Progress Steps View (Settings)

struct ProgressStepsView<Step: WizardStep>: View where Step.AllCases: RandomAccessCollection {
    let steps: Step.AllCases
    let currentStep: Step

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep).map { steps.distance(from: steps.startIndex, to: $0) } ?? 0
    }

    private var progress: CGFloat {
        guard steps.count > 1 else { return 1 }
        return CGFloat(currentIndex) / CGFloat(steps.count - 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(.separatorColor))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 3)

            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, wizardStep in
                    stepColumn(step: wizardStep, index: index)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func stepColumn(step: Step, index: Int) -> some View {
        let isActive = index <= currentIndex
        let isCurrent = step == currentStep

        return VStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.accentColor : Color(.separatorColor))
                .frame(width: 10, height: 10)

            Text(step.title)
                .font(.system(size: 11, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

// MARK: - Wizard Container

struct WizardContainer<Step: WizardStep, Content: View>: View where Step.AllCases: RandomAccessCollection {
    let title: String
    let currentStep: Step
    let onBack: (() -> Void)?
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    private var isFirstStep: Bool {
        Step.allCases.first == currentStep
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            WizardProgressBar(currentStep: currentStep, steps: Step.allCases)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            ScrollView {
                content()
                    .padding(16)
            }
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Button(action: { isFirstStep ? onClose() : onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)

            Spacer()

            Text(title)
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            // Balance spacer
            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Wizard Navigation Buttons

struct WizardNavigationButtons: View {
    let showBack: Bool
    let nextLabel: String
    let nextEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    init(
        showBack: Bool = true,
        nextLabel: String = "Next",
        nextEnabled: Bool = true,
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.showBack = showBack
        self.nextLabel = nextLabel
        self.nextEnabled = nextEnabled
        self.onBack = onBack
        self.onNext = onNext
    }

    var body: some View {
        HStack {
            if showBack {
                Button("Back") { onBack() }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
            }

            Spacer()

            Button(nextLabel) { onNext() }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(!nextEnabled)
        }
        .padding(.top, 12)
    }
}

// MARK: - Option Card

struct WizardOptionCard<Value: Equatable>: View {
    let value: Value
    let title: String
    let subtitle: String?
    let icon: AnyView?
    @Binding var selection: Value

    private var isSelected: Bool { selection == value }

    init(
        value: Value,
        title: String,
        subtitle: String? = nil,
        icon: AnyView? = nil,
        selection: Binding<Value>
    ) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._selection = selection
    }

    var body: some View {
        Button(action: { selection = value }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    icon
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentColor : Color(.separatorColor))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor : Color(.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
