import AppKit

/// Belirli uygulamalardan gelen clipboard verisini yok sayma (V2 özelliği).
struct AppFilter {
    private static let excludedBundleIDs: Set<String> = [
        "com.1password.1password",
        "com.bitwarden.desktop",
        "com.apple.keychainaccess",
    ]

    static func shouldIgnoreClipboard() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return false
        }
        return excludedBundleIDs.contains(bundleID)
    }
}
