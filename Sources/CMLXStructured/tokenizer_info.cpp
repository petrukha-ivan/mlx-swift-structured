#include "mlx_structured.h"
#include <xgrammar/matcher.h>

using namespace xgrammar;

extern "C" void* tokenizer_info_new(
    const char* const* vocab, size_t vocab_size, const int vocab_type,
    const int32_t* eos_tokens, size_t eos_tokens_size
) {
    try {
        std::vector<std::string> encoded_vocab;
        encoded_vocab.reserve(vocab_size);
        for (size_t i = 0; i < vocab_size; ++i) {
            encoded_vocab.emplace_back(vocab[i]);
        }
        
        std::vector<int32_t> stops;
        stops.reserve(eos_tokens_size);
        for (size_t i = 0; i < eos_tokens_size; ++i) {
            stops.emplace_back(eos_tokens[i]);
        }
        
        auto* tokenizer_info = new TokenizerInfo(encoded_vocab, VocabType(vocab_type), vocab_size, stops, false);
        return tokenizer_info;
    } catch (...) {
        return nullptr;
    }
}

extern "C" void tokenizer_info_free(void* tokenizer_info) {
    if (tokenizer_info) {
        delete static_cast<TokenizerInfo*>(tokenizer_info);
    }
}
