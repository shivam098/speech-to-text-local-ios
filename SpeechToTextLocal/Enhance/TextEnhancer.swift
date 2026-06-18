import Foundation

/// Transforms a raw speech transcript into cleaner, more readable text.
///
/// Implementations can range from simple rule-based clean-up to an on-device
/// language model. The UI depends only on this protocol, so the engine can be
/// swapped without any view changes.
protocol TextEnhancer {
    func enhance(_ raw: String) -> String
}
