import SwiftUI
import UIKit

/// Overlay invisible qui détecte un tap à deux doigts, geste réservé à
/// l'adulte pour fermer le mode montrer (plan §3.1).
struct TwoFingerTapper: UIViewRepresentable {

    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let recognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:)))
        recognizer.numberOfTouchesRequired = 2
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject {
        var parent: TwoFingerTapper

        init(parent: TwoFingerTapper) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            parent.action()
        }
    }
}
