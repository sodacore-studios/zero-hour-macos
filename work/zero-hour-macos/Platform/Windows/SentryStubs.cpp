// Private builds do not initialize or send data to upstream Sentry telemetry.
#include "GameNetwork/GeneralsOnline/Vendor/sentry/sentry.h"
extern "C" {
sentry_options_t* sentry_options_new() { return nullptr; }
void sentry_options_set_dsn(sentry_options_t*, const char*) {}
void sentry_options_set_database_path(sentry_options_t*, const char*) {}
void sentry_options_set_release(sentry_options_t*, const char*) {}
void sentry_options_set_environment(sentry_options_t*, const char*) {}
void sentry_options_set_debug(sentry_options_t*, int) {}
void sentry_options_set_logger_level(sentry_options_t*, sentry_level_t) {}
void sentry_options_set_logger(sentry_options_t*, sentry_logger_function_t, void*) {}
void sentry_options_set_backend(sentry_options_t*, sentry_backend_t*) {}
int sentry_init(sentry_options_t*) { return 0; }
int sentry_close() { return 0; }
sentry_value_t sentry_value_new_object() { return {}; }
sentry_value_t sentry_value_new_string(const char*) { return {}; }
sentry_value_t sentry_value_new_int32(int32_t) { return {}; }
int sentry_value_set_by_key(sentry_value_t, const char*, sentry_value_t) { return 0; }
void sentry_set_context(const char*, sentry_value_t) {}
void sentry_set_extra(const char*, sentry_value_t) {}
void sentry_set_tag(const char*, const char*) {}
sentry_value_t sentry_value_new_message_event(sentry_level_t, const char*, const char*) { return {}; }
sentry_uuid_t sentry_capture_event(sentry_value_t) { return {}; }
}
