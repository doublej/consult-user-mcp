import AVFoundation

// MARK: - Speech Delegate

class SpeechCompletionDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        super.init()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onComplete()
    }
}
