import Foundation

// A small, cursor-aware screen for shell prompts. Full-screen applications still
// require a complete VT emulator; this keeps ordinary Fish redraws usable.
public struct TerminalScreen {
    private var lines: [[Character]] = [[]]
    private var row = 0
    private var column = 0
    private var savedPosition = (row: 0, column: 0)
    private var state = 0 // 0: text, 1: escape, 2: CSI, 3: OSC, 4: OSC escape, 5: DCS, 6: DCS escape
    private var parameters = ""
    public private(set) var columns = 80
    private let maxLines = 5_000

    public init() {}

    public mutating func resize(columns: Int) {
        self.columns = max(1, columns)
    }

    // Replies to terminal queries are sent back to the PTY, not displayed.
    public mutating func consume(_ text: String) -> [String] {
        var replies: [String] = []
        // Swift treats CRLF as a single Character. Iterate scalars so the two
        // terminal control bytes remain separate even in the same read.
        for scalar in text.unicodeScalars {
            let character = Character(scalar)
            switch state {
            case 1:
                state = 0
                switch character {
                case "[": parameters = ""; state = 2
                case "]": state = 3
                case "P": state = 5
                case "7": savedPosition = (row, column)
                case "8": restorePosition()
                case "D": newline()
                case "E": row += 1; column = 0; ensureRow()
                case "M": row = max(0, row - 1)
                case "c":
                    let currentColumns = columns
                    self = TerminalScreen()
                    resize(columns: currentColumns)
                default: break
                }
            case 2:
                if character >= "@" && character <= "~" {
                    // Fish requires a Primary Device Attributes response at
                    // startup. Report a basic VT100-compatible terminal.
                    if character == "c" && (parameters.isEmpty || parameters == "0") {
                        replies.append("\u{1b}[?1;2c")
                    }
                    controlSequence(character)
                    state = 0
                } else if parameters.count < 80 {
                    parameters.append(character)
                } else {
                    state = 0
                }
            case 3:
                if character == "\u{7}" { state = 0 }
                else if character == "\u{1b}" { state = 4 }
            case 4:
                state = character == "\\" ? 0 : 3
            case 5:
                if character == "\u{1b}" { state = 6 }
                else if character == "\u{9c}" { state = 0 }
            case 6:
                state = character == "\\" || character == "\u{9c}" ? 0 : 5
            default:
                switch character {
                case "\u{1b}": state = 1
                case "\r": column = 0
                case "\n": newline()
                case "\u{8}": column = max(0, column - 1)
                case "\t":
                    let next = (column / 8 + 1) * 8
                    column = min(next, columns - 1)
                case "\u{7}": break // Shell bell; avoid a flash on every redraw.
                default:
                    if character >= " " { put(character) }
                }
            }
        }
        return replies
    }

    public var text: String {
        lines.map { line in
            let end = line.lastIndex(where: { $0 != " " }).map { $0 + 1 } ?? 0
            return String(line.prefix(end))
        }.joined(separator: "\n")
    }

    private mutating func put(_ character: Character) {
        ensureRow()
        if column >= columns { newline(); column = 0 }
        if column > lines[row].count {
            lines[row].append(contentsOf: repeatElement(" ", count: column - lines[row].count))
        }
        if column == lines[row].count { lines[row].append(character) }
        else { lines[row][column] = character }
        column += 1
    }

    private mutating func newline() {
        row += 1
        ensureRow()
    }

    private mutating func ensureRow() {
        while row >= lines.count { lines.append([]) }
        if lines.count > maxLines {
            let removed = lines.count - maxLines
            lines.removeFirst(removed)
            row -= removed
            savedPosition.row = max(0, savedPosition.row - removed)
        }
    }

    private mutating func restorePosition() {
        row = min(savedPosition.row, lines.count - 1)
        column = min(savedPosition.column, columns - 1)
    }

    private mutating func controlSequence(_ command: Character) {
        let args = parameters.split(separator: ";", omittingEmptySubsequences: false)
            .map { Int($0) ?? 0 }
        let first = args.first ?? 0
        let count = max(1, first)
        switch command {
        case "A": row = max(0, row - count)
        case "B": row += count; ensureRow()
        case "C": column = min(columns - 1, column + count)
        case "D": column = max(0, column - count)
        case "E": row += count; column = 0; ensureRow()
        case "F": row = max(0, row - count); column = 0
        case "G": column = min(columns - 1, count - 1)
        case "H", "f":
            row = min(lines.count - 1, max(0, count - 1))
            column = min(columns - 1, max(0, (args.count > 1 ? max(1, args[1]) : 1) - 1))
        case "K":
            ensureRow()
            if first == 2 { lines[row] = [] }
            else if first == 1 {
                let end = min(column + 1, lines[row].count)
                if end > 0 { lines[row].replaceSubrange(0..<end, with: repeatElement(" ", count: end)) }
            } else if column < lines[row].count { lines[row].removeSubrange(column...) }
        case "J":
            if first == 2 { lines = [[]]; row = 0; column = 0 }
            else if first == 0 {
                lines.removeSubrange((row + 1)..<lines.count)
                if column < lines[row].count { lines[row].removeSubrange(column...) }
            }
        case "s": savedPosition = (row, column)
        case "u": restorePosition()
        default: break // SGR, cursor visibility, bracketed paste, etc.
        }
    }
}
