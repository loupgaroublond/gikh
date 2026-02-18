import Testing
@testable import גיך

// Helper: extract text from each token in order.
private func texts(_ tokens: [Token]) -> [String] { tokens.map(\.text) }

// Helper: extract case labels without associated values for structural checks.
private enum TokenKind: Equatable {
    case keyword, identifier, stringLiteral, comment, whitespace,
         punctuation, operatorToken, numberLiteral, interpolationDelimiter, unknown

    init(_ t: Token) {
        switch t {
        case .keyword:               self = .keyword
        case .identifier:            self = .identifier
        case .stringLiteral:         self = .stringLiteral
        case .comment:               self = .comment
        case .whitespace:            self = .whitespace
        case .punctuation:           self = .punctuation
        case .operatorToken:         self = .operatorToken
        case .numberLiteral:         self = .numberLiteral
        case .interpolationDelimiter: self = .interpolationDelimiter
        case .unknown:               self = .unknown
        }
    }
}

private func kinds(_ tokens: [Token]) -> [TokenKind] { tokens.map(TokenKind.init) }

@Suite("Scanner")
struct ScannerTests {

    // MARK: - Whitespace

    @Test func whitespaceSpaces() {
        var s = Scanner(source: "   ")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.whitespace])
        #expect(texts(tokens) == ["   "])
    }

    @Test func whitespaceNewlines() {
        var s = Scanner(source: "\n\n")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.whitespace])
        #expect(texts(tokens) == ["\n\n"])
    }

    @Test func whitespaceMixed() {
        var s = Scanner(source: "  \t  \n")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.whitespace])
    }

    // MARK: - Line comments

    @Test func lineCommentBasic() {
        var s = Scanner(source: "// hello world\n")
        let tokens = s.scan()
        // Expect: comment, whitespace(newline)
        #expect(kinds(tokens) == [.comment, .whitespace])
        #expect(tokens[0].text == "// hello world")
    }

    @Test func lineCommentAtEndOfFile() {
        var s = Scanner(source: "// EOF comment")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.comment])
        #expect(tokens[0].text == "// EOF comment")
    }

    @Test func lineCommentPreservesContent() {
        let content = "// import func let var struct"
        var s = Scanner(source: content)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.comment])
        #expect(tokens[0].text == content)
    }

    // MARK: - Block comments

    @Test func blockCommentBasic() {
        var s = Scanner(source: "/* a comment */")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.comment])
        #expect(tokens[0].text == "/* a comment */")
    }

    @Test func blockCommentMultiline() {
        var s = Scanner(source: "/* line1\nline2\nline3 */")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.comment])
    }

    @Test func blockCommentPreservesKeywords() {
        let body = "/* func let var import */"
        var s = Scanner(source: body)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.comment])
        #expect(tokens[0].text == body)
    }

    // MARK: - Single-line string literals

    @Test func simpleStringLiteral() {
        var s = Scanner(source: #""hello""#)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
        #expect(tokens[0].text == "\"hello\"")
    }

    @Test func emptyStringLiteral() {
        var s = Scanner(source: #""""#)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
        #expect(tokens[0].text == "\"\"")
    }

    @Test func stringLiteralWithEscapeSequence() {
        var s = Scanner(source: #""line1\nline2""#)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
    }

    @Test func stringLiteralPreservesContent() {
        // Keywords inside a string must not become keyword tokens.
        var s = Scanner(source: #""func let var""#)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
    }

    // MARK: - String interpolation

    @Test func stringInterpolationSimple() {
        // "hello \(name)" → stringLiteral("hello "), interpolationDelimiter("\\("),
        //                    identifier("name"), interpolationDelimiter(")"),
        //                    stringLiteral("\"")   [closing quote fragment]
        // Actual breakdown depends on implementation — verify structural expectations:
        var s = Scanner(source: #""hello \(name)""#)
        let tokens = s.scan()
        let k = kinds(tokens)
        // Must contain at least one interpolationDelimiter for \(
        #expect(k.contains(.interpolationDelimiter))
        // The identifier "name" must be scanned inside the interpolation
        #expect(k.contains(.identifier))
        // Reconstruct: token texts joined must equal original source
        #expect(texts(tokens).joined() == "\"hello \\(name)\"")
    }

    @Test func stringInterpolationNestedParens() {
        // Nested parens inside interpolation: "\(foo(bar))"
        var s = Scanner(source: #""\(foo(bar))""#)
        let tokens = s.scan()
        // All tokens joined must equal source
        #expect(texts(tokens).joined() == "\"\\(foo(bar))\"")
        // There must be an interpolationDelimiter for \(
        #expect(kinds(tokens).contains(.interpolationDelimiter))
        // foo and bar must be scanned as identifiers
        let identifiers = tokens.compactMap { if case .identifier(let t, _) = $0 { return t } else { return nil } }
        #expect(identifiers.contains("foo"))
        #expect(identifiers.contains("bar"))
    }

    @Test func stringInterpolationWithExpression() {
        // "\(a + b)"
        var s = Scanner(source: #""\(a + b)""#)
        let tokens = s.scan()
        #expect(texts(tokens).joined() == "\"\\(a + b)\"")
        #expect(kinds(tokens).contains(.interpolationDelimiter))
    }

    // MARK: - Multi-line string literals

    @Test func multilineStringLiteral() {
        let src = "\"\"\"\nhello\nworld\n\"\"\""
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
        #expect(tokens[0].text == src)
    }

    @Test func multilineStringLiteralPreservesKeywords() {
        let src = "\"\"\"\nfunc let var\nstruct class\n\"\"\""
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
    }

    // MARK: - Raw string literals

    @Test func rawStringLiteralBasic() {
        // #"hello\nworld"# — the \n is literal, not an escape
        let src = ##"#"hello\nworld"#"##
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
        #expect(tokens[0].text == src)
    }

    @Test func rawStringLiteralDoubleHash() {
        let src = ###"##"no interpolation \(here)"##"###
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.stringLiteral])
        #expect(tokens[0].text == src)
    }

    // MARK: - Number literals

    @Test func integerLiteral() {
        var s = Scanner(source: "42")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.numberLiteral])
        #expect(tokens[0].text == "42")
    }

    @Test func floatLiteral() {
        var s = Scanner(source: "3.14")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.numberLiteral])
        #expect(tokens[0].text == "3.14")
    }

    @Test func hexLiteral() {
        var s = Scanner(source: "0xFF")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.numberLiteral])
        #expect(tokens[0].text == "0xFF")
    }

    @Test func binaryLiteral() {
        var s = Scanner(source: "0b1010")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.numberLiteral])
        #expect(tokens[0].text == "0b1010")
    }

    @Test func octalLiteral() {
        var s = Scanner(source: "0o17")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.numberLiteral])
        #expect(tokens[0].text == "0o17")
    }

    @Test func numberWithUnderscores() {
        var s = Scanner(source: "1_000_000")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.numberLiteral])
        #expect(tokens[0].text == "1_000_000")
    }

    // MARK: - Operators

    @Test func simpleOperators() {
        for op in ["+", "-", "*", "/", "=", "==", "!=", "<", ">", "<=", ">=", "&&", "||", "!"] {
            var s = Scanner(source: op)
            let tokens = s.scan()
            #expect(tokens.count == 1, "operator \(op.debugDescription)")
            #expect(kinds(tokens) == [.operatorToken], "operator \(op.debugDescription)")
            #expect(tokens[0].text == op, "operator \(op.debugDescription)")
        }
    }

    @Test func backslashOperator() {
        // In Mode C the division-like use of backslash is just an operator token
        var s = Scanner(source: "\\")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.operatorToken])
        #expect(tokens[0].text == "\\")
    }

    // MARK: - Punctuation

    @Test func punctuationTokens() {
        for p in ["(", ")", "{", "}", "[", "]", ",", ":", ";", "."] {
            var s = Scanner(source: p)
            let tokens = s.scan()
            #expect(tokens.count == 1, "punctuation \(p.debugDescription)")
            #expect(kinds(tokens) == [.punctuation], "punctuation \(p.debugDescription)")
            #expect(tokens[0].text == p, "punctuation \(p.debugDescription)")
        }
    }

    // MARK: - English keywords

    @Test func englishKeywordsRecognized() {
        let keywords = ["func", "let", "var", "return", "if", "else", "for", "in",
                        "while", "struct", "class", "protocol", "guard", "switch",
                        "case", "break", "continue", "do", "catch", "throw", "throws",
                        "async", "await", "static", "private", "public", "internal",
                        "extension", "import"]
        for kw in keywords {
            var s = Scanner(source: kw)
            let tokens = s.scan()
            #expect(tokens.count == 1, "keyword '\(kw)'")
            #expect(kinds(tokens) == [.keyword], "keyword '\(kw)'")
            #expect(tokens[0].text == kw, "keyword '\(kw)'")
        }
    }

    // MARK: - Yiddish keywords

    @Test func yiddishKeywordsRecognized() {
        // These are the keywords from the design doc
        let keywords = [
            "פֿונקציע",   // func
            "לאָז",        // let
            "באַשטימען",   // var
            "צוריק",       // return
            "אויב",        // if
            "אַנדערש",     // else
            "פֿאַר",        // for
            "אין",         // in
            "בשעת",        // while
            "סטרוקטור",    // struct
            "קלאַס",       // class
            "פּראָטאָקאָל",  // protocol
            "היטער",       // guard
            "וועקסל",      // switch
            "פֿאַל",        // case
            "ברעכן",       // break
            "ממשיכן",      // continue
            "טאָן",         // do
            "כאַפּן",       // catch
            "וואַרפֿן",     // throw
            "וואַרפֿט",     // throws
            "אַסינכראָן",   // async
            "וואַרטן",      // await
            "סטאַטיש",     // static
            "פּריוואַט",    // private
            "עפֿנטלעך",    // public
            "אינערלעך",    // internal
            "פֿאַרלענגערונג", // extension
            "אימפּאָרט",   // import
        ]
        for kw in keywords {
            var s = Scanner(source: kw)
            let tokens = s.scan()
            #expect(tokens.count == 1, "Yiddish keyword '\(kw)'")
            #expect(kinds(tokens) == [.keyword], "Yiddish keyword '\(kw)'")
            #expect(tokens[0].text == kw, "Yiddish keyword '\(kw)'")
        }
    }

    // MARK: - Identifiers (ASCII)

    @Test func asciiIdentifier() {
        for word in ["foo", "bar", "_baz", "camelCase", "PascalCase"] {
            var s = Scanner(source: word)
            let tokens = s.scan()
            #expect(tokens.count == 1, "identifier '\(word)'")
            #expect(kinds(tokens) == [.identifier], "identifier '\(word)'")
            #expect(tokens[0].text == word, "identifier '\(word)'")
        }
    }

    @Test func dollarIdentifier() {
        // $0, $1 etc. are valid in Swift closures
        var s = Scanner(source: "$0")
        let tokens = s.scan()
        #expect(tokens.count == 1)
        #expect(kinds(tokens) == [.identifier])
        #expect(tokens[0].text == "$0")
    }

    // MARK: - Identifiers (Yiddish Unicode)

    @Test func yiddishIdentifier() {
        let words = ["מענטש", "נאָמען", "עלטער", "באַשרײַבן", "יענקל"]
        for word in words {
            var s = Scanner(source: word)
            let tokens = s.scan()
            #expect(tokens.count == 1, "Yiddish identifier '\(word)'")
            // Should be .identifier (not keyword, not unknown)
            #expect(kinds(tokens) == [.identifier], "Yiddish identifier '\(word)'")
            #expect(tokens[0].text == word, "Yiddish identifier '\(word)'")
        }
    }

    // MARK: - Lossless reconstruction

    @Test func losslessReconstructionSimpleStatement() {
        let src = "let x = 42"
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(texts(tokens).joined() == src)
    }

    @Test func losslessReconstructionFunctionDecl() {
        let src = "func foo(_ x: Int) -> String { return \"hello\" }"
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(texts(tokens).joined() == src)
    }

    @Test func losslessReconstructionWithComment() {
        let src = "// comment\nlet x = 1\n"
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(texts(tokens).joined() == src)
    }

    @Test func losslessReconstructionYiddish() {
        let src = "לאָז מענטש = מענטש(נאָמען: \"יענקל\", עלטער: 30)"
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(texts(tokens).joined() == src)
    }

    // MARK: - Full source scan

    @Test func fullSourceMixedTokenTypes() {
        let src = """
        import Foundation

        struct Person {
            let name: String
            let age: Int

            func describe() -> String {
                return "\\(name) is \\(age) years old"
            }
        }
        """
        var s = Scanner(source: src)
        let tokens = s.scan()
        // Must reconstruct losslessly
        #expect(texts(tokens).joined() == src)
        // Must contain keywords
        let kwTexts = tokens.compactMap { if case .keyword(let t, _) = $0 { return t } else { return nil } }
        #expect(kwTexts.contains("import"))
        #expect(kwTexts.contains("struct"))
        #expect(kwTexts.contains("let"))
        #expect(kwTexts.contains("func"))
        #expect(kwTexts.contains("return"))
        // Must contain identifiers
        let idTexts = tokens.compactMap { if case .identifier(let t, _) = $0 { return t } else { return nil } }
        #expect(idTexts.contains("Person"))
        #expect(idTexts.contains("name"))
    }

    @Test func fullSourceYiddishModeC() {
        // Mode C: English keywords, Yiddish identifiers
        let src = """
        struct מענטש {
            let נאָמען: String
            let עלטער: Int
        }
        """
        var s = Scanner(source: src)
        let tokens = s.scan()
        #expect(texts(tokens).joined() == src)
        // struct and let are keywords
        let kws = tokens.compactMap { if case .keyword(let t, _) = $0 { return t } else { return nil } }
        #expect(kws.contains("struct"))
        #expect(kws.contains("let"))
        // מענטש, נאָמען, עלטער are identifiers (not in keyword set)
        let ids = tokens.compactMap { if case .identifier(let t, _) = $0 { return t } else { return nil } }
        #expect(ids.contains("מענטש"))
        #expect(ids.contains("נאָמען"))
        #expect(ids.contains("עלטער"))
    }
}
