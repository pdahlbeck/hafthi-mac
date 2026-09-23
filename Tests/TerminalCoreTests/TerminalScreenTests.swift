import XCTest
@testable import TerminalCore

final class TerminalScreenTests: XCTestCase {
    func testFishStartupQueriesDoNotAppearInPrompt() {
        var screen = TerminalScreen()
        XCTAssertEqual(screen.consume("\u{1b}[0c"), ["\u{1b}[?1;2c"])
        XCTAssertEqual(screen.consume("\u{1b}P+q696e646e\u{1b}"), [])
        XCTAssertEqual(screen.consume("\\\u{1b}P+q71756572792d6f732d6e616d65\u{1b}\\❯ "), [])
        XCTAssertEqual(screen.text, "❯")
    }

    func testPromptRedrawAndCRLF() {
        var screen = TerminalScreen()
        XCTAssertEqual(screen.consume("❯ foo\r\u{1b}[K❯ fish\r\nready\r\n"), [])
        XCTAssertEqual(screen.text, "❯ fish\nready\n")
    }
}
