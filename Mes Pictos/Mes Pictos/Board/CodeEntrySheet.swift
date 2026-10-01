import SwiftUI

/// Saisie du code parent à 4 chiffres, avec pavé numérique intégré
/// (pas de clavier système, plus fiable pour un code court).
struct CodeEntrySheet: View {

    var onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var entered: String = ""
    @State private var wrongAttempt = false

    var body: some View {
        VStack(spacing: 28) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Mode parent")
                    .font(.title3.bold())
                Text("Entrez le code à 4 chiffres")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < entered.count
                              ? Color.accentColor
                              : Color.secondary.opacity(0.25))
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: wrongAttempt ? -8 : 0)

            keypad
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onChange(of: entered) { _, value in
            guard value.count == 4 else { return }
            if ParentLock.codeMatches(value) {
                Haptics.success()
                onSuccess()
                dismiss()
            } else {
                Haptics.warning()
                withAnimation(.default.repeatCount(3)) { wrongAttempt = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    wrongAttempt = false
                    entered = ""
                }
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 12) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 26) {
                    ForEach(row, id: \.self) { digit in
                        key("\(digit)")
                    }
                }
            }
            HStack(spacing: 26) {
                Color.clear.frame(width: 72, height: 60)
                key("0")
                Button {
                    if !entered.isEmpty { entered.removeLast() }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title3)
                        .frame(width: 72, height: 60)
                        .background(Color(uiColor: .secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func key(_ digit: String) -> some View {
        Button {
            guard entered.count < 4 else { return }
            entered += digit
        } label: {
            Text(digit)
                .font(.title2.bold())
                .frame(width: 72, height: 60)
                .background(Color(uiColor: .secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Écran de création / modification du code parent.
struct CodeSetupSheet: View {

    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var firstEntry: String?
    @State private var entered: String = ""
    @State private var prompt = "Choisissez un code à 4 chiffres"

    var body: some View {
        VStack(spacing: 28) {
            Text("Code parent")
                .font(.title3.bold())
            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < entered.count
                              ? Color.accentColor
                              : Color.secondary.opacity(0.25))
                        .frame(width: 16, height: 16)
                }
            }

            CodeSetupKeypad(onDigit: { digit in
                guard entered.count < 4 else { return }
                entered += digit
                if entered.count == 4 {
                    handleComplete()
                }
            }, onDelete: {
                if !entered.isEmpty { entered.removeLast() }
            })
        }
        .padding()
    }

    private func handleComplete() {
        if let first = firstEntry {
            if first == entered {
                ParentLock.setCode(entered)
                Haptics.success()
                onDone()
                dismiss()
            } else {
                Haptics.warning()
                prompt = "Les codes diffèrent — réessayez"
                firstEntry = nil
                entered = ""
            }
        } else {
            firstEntry = entered
            entered = ""
            prompt = "Confirmez le code"
        }
    }
}

/// Pavé réutilisé par l'écran de création du code.
private struct CodeSetupKeypad: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 26) {
                    ForEach(row, id: \.self) { digit in
                        Button {
                            onDigit("\(digit)")
                        } label: {
                            Text("\(digit)")
                                .font(.title2.bold())
                                .frame(width: 72, height: 60)
                                .background(Color(uiColor: .secondarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 26) {
                Color.clear.frame(width: 72, height: 60)
                Button {
                    onDigit("0")
                } label: {
                    Text("0")
                        .font(.title2.bold())
                        .frame(width: 72, height: 60)
                        .background(Color(uiColor: .secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.title3)
                        .frame(width: 72, height: 60)
                        .background(Color(uiColor: .secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
