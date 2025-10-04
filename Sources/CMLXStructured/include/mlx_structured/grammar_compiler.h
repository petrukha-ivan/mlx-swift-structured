#pragma once

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void* compile_ebnf_grammar(
    void* tokenizer_info,
    const char* ebnf_utf8,
    size_t ebnf_len
);

void* compile_regex_grammar(
    void* tokenizer_info,
    const char* regex_utf8,
    size_t regex_len
);

void* compile_json_schema_grammar(
    void* tokenizer_info,
    const char* schema_utf8,
    size_t schema_len,
    int indent
);

void* compile_structural_tag(
    void* tokenizer_info,
    const char* structural_tag_utf8,
    size_t structural_tag_len
);

void compiled_grammar_free(void* compiled_grammar);

#ifdef __cplusplus
}
#endif
