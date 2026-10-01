import Foundation
import LocalAuthentication
import Security

/// Verrou du mode parent (plan §3.1) : appui long de 3 s, complété par un
/// code à 4 chiffres et/ou Face ID. Le code est stocké dans le trousseau,
/// jamais dans les réglages en clair.
enum ParentLock {

    private static let service = "fr.mespictos.parentlock"
    private static let account = "parent-code"

    // MARK: - Code

    static func hasCode() -> Bool {
        code() != nil
    }

    static func codeMatches(_ candidate: String) -> Bool {
        code() == candidate
    }

    static func setCode(_ code: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(code.utf8),
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func clearCode() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func code() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Face ID / Touch ID

    static func biometricsAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Authentification système (Face ID avec repli sur le code de l'appareil).
    static func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Utiliser le code"
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Déverrouiller le mode parent de Mes Pictos.")
        } catch {
            return false
        }
    }
}
