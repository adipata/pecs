import SwiftUI
import PictoCore

/// The discreet lock in child mode. Hold for 3 seconds to open parent mode.
struct ParentLockButton: View {
    let onUnlock: () -> Void
    @State private var isPressing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 44, height: 44)
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            Circle()
                .trim(from: 0, to: isPressing ? 1 : 0)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 50, height: 50)
                .animation(isPressing ? .linear(duration: 3) : .easeOut(duration: 0.2), value: isPressing)
        }
        .frame(width: 56, height: 56)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: 3, maximumDistance: 30) {
            isPressing = false
            onUnlock()
        } onPressingChanged: { pressing in
            isPressing = pressing
        }
        .accessibilityLabel("Mode parent")
        .accessibilityHint("Appui long de 3 secondes")
    }
}

/// Asks for the parent code.
struct ParentCodeEntryView: View {
    let onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var isWrong = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Code parent")
                    .font(.title2.weight(.semibold))
                SecureField("Code", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .frame(maxWidth: 220)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onSubmit(check)
                if isWrong {
                    Text("Code incorrect")
                        .foregroundStyle(.red)
                }
                Button("Valider", action: check)
                    .buttonStyle(.borderedProminent)
                    .disabled(!ParentCode.isValid(code))
                Spacer()
            }
            .padding(.top, 40)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }

    private func check() {
        let stored = UserDefaults.standard.string(forKey: SettingsKey.parentCode) ?? ""
        if !stored.isEmpty, code == stored {
            dismiss()
            onSuccess()
        } else {
            isWrong = true
            code = ""
        }
    }
}
