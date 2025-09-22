#include "mlx_structured/error_handler.h"
#include "mlx_structured/grammar_compiler.h"
#include <xgrammar/matcher.h>

using namespace xgrammar;

extern "C" void* compile_ebnf_grammar(
    void* tokenizer_info,
    const char* ebnf_utf8,
    size_t ebnf_len
) {
    try {
        const std::string ebnf(ebnf_utf8, ebnf_len);
        auto& tokenizer_info_ptr = *static_cast<TokenizerInfo*>(tokenizer_info);
        auto* compiled_grammar_ptr = new CompiledGrammar(
            GrammarCompiler(tokenizer_info_ptr).CompileGrammar(Grammar::FromEBNF(ebnf))
        );
        return compiled_grammar_ptr;
    } catch (const std::exception& e) {
        catch_error(e.what());
        return nullptr;
    }
}

extern "C" void* compile_regex_grammar(
    void* tokenizer_info,
    const char* regex_utf8,
    size_t regex_len
) {
    try {
        const std::string regex(regex_utf8, regex_len);
        auto& tokenizer_info_ptr = *static_cast<TokenizerInfo*>(tokenizer_info);
        auto* compiled_grammar_ptr = new CompiledGrammar(
            GrammarCompiler(tokenizer_info_ptr).CompileRegex(regex)
        );
        return compiled_grammar_ptr;
    } catch (const std::exception& e) {
        catch_error(e.what());
        return nullptr;
    }
}

extern "C" void* compile_json_schema_grammar(
    void* tokenizer_info,
    const char* schema_utf8,
    size_t schema_len,
    int indent
) {
    try {
        const std::string schema(schema_utf8, schema_len);
        const std::optional<int> opt_indent = (indent >= 0) ? std::optional<int>(indent) : std::nullopt;
        auto& tokenizer_info_ptr = *static_cast<TokenizerInfo*>(tokenizer_info);
        auto* compiled_grammar_ptr = new CompiledGrammar(
            GrammarCompiler(tokenizer_info_ptr).CompileJSONSchema(schema, false, opt_indent, std::nullopt, true, std::nullopt)
        );
        return compiled_grammar_ptr;
    } catch (const std::exception& e) {
        catch_error(e.what());
        return nullptr;
    }
}

extern "C" void compiled_grammar_free(void* compiled_grammar) {
    if (compiled_grammar) {
        delete static_cast<CompiledGrammar*>(compiled_grammar);
    }
}
