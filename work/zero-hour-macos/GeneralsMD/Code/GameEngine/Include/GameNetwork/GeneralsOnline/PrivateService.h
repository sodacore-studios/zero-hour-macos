#pragma once
#include <cstdlib>
#include <string>

// TheSuperHackers @feature: isolate self-hosted sessions from the public service.
namespace PrivateService {
inline const char* setting(const char* name, const char* fallback = "") {
    const char* value = std::getenv(name);
    return value && *value ? value : fallback;
}
inline bool enabled() { return std::string(setting("ZERO_HOUR_PRIVATE_SERVICE")) == "1"; }
inline std::string endpoint(const char* path) {
    std::string base = setting("ZERO_HOUR_SERVICE_URL", "http://127.0.0.1:9/env/prod/contract/1");
    while (!base.empty() && base.back() == '/') base.pop_back();
    // HTTP is only allowed for a local SSH-tunnel development endpoint.
    if (!(base.starts_with("https://") || base.starts_with("http://127.0.0.1:")) ||
        base.find_first_of("\r\n?#@\\") != std::string::npos)
        return "http://127.0.0.1:9/invalid-configuration";
    return base + "/" + path;
}
}
