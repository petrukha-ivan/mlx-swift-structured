#pragma once

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

void *grammar_matcher_new(void *compiled_grammar);

bool grammar_matcher_fill_next_token_bitmask(void *grammar_matcher, void *next_token_bitmask);

bool grammar_matcher_accept_token(void *grammar_matcher, int32_t token_id);

bool grammar_matcher_accept_string(void *grammar_matcher, const char *string);

char *grammar_matcher_find_jump_forward_string(void *grammar_matcher);

void grammar_matcher_string_free(char *string);

void grammar_matcher_reset(void *grammar_matcher);

bool grammar_matcher_is_terminated(void *grammar_matcher);

void grammar_matcher_free(void *grammar_matcher);

#ifdef __cplusplus
}
#endif
