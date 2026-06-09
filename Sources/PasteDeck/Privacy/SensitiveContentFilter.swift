import Foundation

/// Hassas içerik filtresi (V2 özelliği).
/// Şifre, kredi kartı, API key gibi pattern'leri tespit eder.
struct SensitiveContentFilter {
    private static let patterns: [(String, String)] = [
        ("credit_card", #"\b(?:\d[ -]*?){13,16}\b"#),
        ("iban", #"[A-Z]{2}\d{2}[A-Z0-9]{1,30}"#),
        ("api_key", #"(?:api[_-]?key|token|secret)[\s=:]+['"]?[A-Za-z0-9_\-\.]{20,}"#),
    ]

    static func isSensitive(_ text: String) -> Bool {
        for (_, pattern) in patterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
}
