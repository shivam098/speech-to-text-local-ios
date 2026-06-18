import Foundation

/// Offline, rule-based transcript clean-up.
///
/// Removes filler words/phrases and stutters, collapses immediate repetition,
/// normalises whitespace and punctuation, and fixes capitalisation — all without
/// a network connection.
struct RuleBasedTextEnhancer: TextEnhancer {

    /// Standalone disfluencies removed wherever they appear as whole words.
    var fillerWords: [String] = [
        "um", "umm", "uh", "uhh", "uhm", "er", "err",
        "ah", "ahh", "hmm", "mm", "mmm", "mhm", "eh"
    ]

    /// Multi-word filler phrases removed wherever they appear.
    var fillerPhrases: [String] = [
        "you know", "i mean"
    ]

    func enhance(_ raw: String) -> String {
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }
        var text = raw
        text = removeFillerPhrases(text)
        text = removeFillerWords(text)
        text = collapseRepeatedWords(text)
        text = cleanUpStrayPunctuation(text)
        text = normaliseWhitespace(text)
        text = capitaliseSentences(text)
        text = capitaliseStandaloneI(text)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Steps

    private func removeFillerPhrases(_ text: String) -> String {
        guard !fillerPhrases.isEmpty else { return text }
        let alternation = fillerPhrases
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return text.replacingMatches(of: "\\b(?:\(alternation))\\b,?", with: "")
    }

    private func removeFillerWords(_ text: String) -> String {
        guard !fillerWords.isEmpty else { return text }
        let alternation = fillerWords
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return text.replacingMatches(of: "\\b(?:\(alternation))\\b,?", with: "")
    }

    private func collapseRepeatedWords(_ text: String) -> String {
        text.replacingMatches(of: "\\b(\\w+)(\\s+\\1\\b)+", with: "$1")
    }

    private func cleanUpStrayPunctuation(_ text: String) -> String {
        var t = text
        t = t.replacingMatches(of: "\\s+([,.!?;:])", with: "$1")      // no space before punctuation
        t = t.replacingMatches(of: "([,;:])(?=\\S)", with: "$1 ")     // ensure a space after , ; :
        t = t.replacingMatches(of: "(?:\\s*,\\s*){2,}", with: ", ")   // collapse repeated commas
        t = t.replacingMatches(of: "(^|[.!?]\\s*),\\s*", with: "$1")  // drop comma at a sentence start
        return t
    }

    private func normaliseWhitespace(_ text: String) -> String {
        var t = text
        t = t.replacingMatches(of: "[ \\t]+", with: " ")
        t = t.replacingMatches(of: " *\\n *", with: "\n")
        t = t.replacingMatches(of: "\\n{3,}", with: "\n\n")
        return t
    }

    private func capitaliseSentences(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var capitaliseNext = true
        for character in text {
            if capitaliseNext, character.isLetter {
                result.append(contentsOf: String(character).uppercased())
                capitaliseNext = false
            } else {
                result.append(character)
            }
            if character == "." || character == "!" || character == "?" {
                capitaliseNext = true
            }
        }
        return result
    }

    private func capitaliseStandaloneI(_ text: String) -> String {
        text.replacingMatches(of: "\\bi\\b", with: "I")
    }
}

private extension String {
    func replacingMatches(of pattern: String,
                          with template: String,
                          options: NSRegularExpression.Options = [.caseInsensitive]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return self
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }
}
