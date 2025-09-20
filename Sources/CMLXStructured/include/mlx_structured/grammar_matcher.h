#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void* grammar_matcher_new(void* compiled_grammar);

bool grammar_matcher_fill_next_token_bitmask(
    void* grammar_matcher,
    void* next_token_bitmask
);

bool grammar_matcher_accept_token(
    void* grammar_matcher,
    int32_t token_id
);

void grammar_matcher_reset(void* grammar_matcher);

void grammar_matcher_free(void* grammar_matcher);

#ifdef __cplusplus
}
#endif
