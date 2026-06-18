import XCTest
@testable import SpeechToTextLocal

final class RuleBasedTextEnhancerTests: XCTestCase {

    private let enhancer = RuleBasedTextEnhancer()

    func testRemovesFillerWordsAndCapitalises() {
        XCTAssertEqual(enhancer.enhance("um i think uh we should go"),
                       "I think we should go")
    }

    func testCollapsesImmediateRepetition() {
        XCTAssertEqual(enhancer.enhance("i think the the report is good"),
                       "I think the report is good")
    }

    func testRemovesFillerPhrase() {
        XCTAssertEqual(enhancer.enhance("we should, you know, send it"),
                       "We should, send it")
    }

    func testRemovesLeadingFillerPhrase() {
        XCTAssertEqual(enhancer.enhance("i mean we should go"),
                       "We should go")
    }

    func testKeepsMeaningfulWords() {
        XCTAssertEqual(enhancer.enhance("i really like coffee"),
                       "I really like coffee")
    }

    func testEmptyInputReturnsEmpty() {
        XCTAssertEqual(enhancer.enhance("   "), "")
    }
}
