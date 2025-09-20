#include "mlx_structured.h"
#include <dlpack/dlpack.h>
#include <xgrammar/matcher.h>

using namespace xgrammar;

extern "C" void* grammar_matcher_new(void* compiled_grammar) {
    try {
        auto* compiled_grammar_ptr = static_cast<CompiledGrammar*>(compiled_grammar);
        auto* grammar_matcher_ptr = new GrammarMatcher(*compiled_grammar_ptr);
        return grammar_matcher_ptr;
    } catch (...) { // TODO: Add error descriptions
        return nullptr;
    }
}

extern "C" bool grammar_matcher_fill_next_token_bitmask(
    void* grammar_matcher,
    void* next_token_bitmask
) {
    try {
        auto* grammar_matcher_ptr = static_cast<GrammarMatcher*>(grammar_matcher);
        auto* next_token_bitmask_ptr = static_cast<DLTensor*>(next_token_bitmask);
        return grammar_matcher_ptr->FillNextTokenBitmask(next_token_bitmask_ptr);
    } catch (...) {
        return false;
    }
}

extern "C" bool grammar_matcher_accept_token(
    void* grammar_matcher,
    int32_t token_id
) {
    try {
        auto* grammar_matcher_ptr = static_cast<GrammarMatcher*>(grammar_matcher);
        return grammar_matcher_ptr->AcceptToken(token_id);
    } catch (...) {
        return false;
    }
}

extern "C" void grammar_matcher_reset(void* grammar_matcher) {
    try {
        auto* grammar_matcher_ptr = static_cast<GrammarMatcher*>(grammar_matcher);
        grammar_matcher_ptr->Reset();
    } catch (...) {
        return;
    }
}

extern "C" void grammar_matcher_free(void* grammar_matcher) {
    if (grammar_matcher) {
        delete static_cast<GrammarMatcher*>(grammar_matcher);
    }
}
