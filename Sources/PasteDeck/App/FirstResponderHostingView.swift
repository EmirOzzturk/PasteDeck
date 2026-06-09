import SwiftUI
import AppKit

/// Her zaman first responder olabilen hosting view.
/// SwiftUI view'lara klavye event'lerinin ulaşması için gerekli.
final class FirstResponderHostingView<Content: View>: NSHostingView<Content> {
    override var acceptsFirstResponder: Bool { true }
}
