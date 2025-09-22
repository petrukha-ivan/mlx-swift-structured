#include "mlx_structured/error_handler.h"

static error_handler_closure _error_handler;

extern "C" void set_error_handler(error_handler_closure error_handler) {
    _error_handler = error_handler;
}

extern "C" void catch_error(const char* error_message) {
    if (_error_handler) {
        _error_handler(error_message);
    }
}
