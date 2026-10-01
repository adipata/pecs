import Foundation

public enum ParentCode {
    /// A parent code is 4 to 6 digits.
    public static func isValid(_ code: String) -> Bool {
        (4...6).contains(code.count) && code.allSatisfy { $0.isASCII && $0.isNumber }
    }
}
