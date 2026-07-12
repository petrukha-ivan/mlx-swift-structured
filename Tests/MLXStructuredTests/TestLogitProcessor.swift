import Testing
@testable import MLXStructured
import MLX

struct LogitProcessorTests {

    struct StubGrammarMatcher: GrammarMatcher {
        let mask: MLXArray
        func nextTokenMask() -> MLXArray { mask }
        func accept(token: MLXArray) {}
        func reset() {}
        func isTerminated() -> Bool { false }
        func accept(string: String) {}
        func findJumpForwardString() -> String { "" }
    }

    @Test func `Process pads short mask to logits width`() {
        let grammarMatcher = StubGrammarMatcher(mask: MLXArray([0.0, -Float.infinity, 0.0]))
        let processor = GrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)

        let processed = processor.process(logits: MLXArray.zeros([1, 5]))
        let allowed = processed[0].exp().asArray(Int.self)

        #expect(allowed == [1, 0, 1, 0, 0])
    }

    @Test func `Process truncates long mask to logits width`() {
        let grammarMatcher = StubGrammarMatcher(mask: MLXArray([0.0, -Float.infinity, 0.0, -Float.infinity]))
        let processor = GrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)

        let processed = processor.process(logits: MLXArray.zeros([1, 3]))
        let allowed = processed[0].exp().asArray(Int.self)

        #expect(allowed == [1, 0, 1])
    }
}
