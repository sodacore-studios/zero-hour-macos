#pragma once
#include <cstdint>

// Bound OS event work so sustained mouse motion cannot starve the next frame.
// Unsigned subtraction also handles the millisecond clock wrapping around.
class InputEventBudget {
public:
    explicit InputEventBudget(std::uint32_t start) : start_(start) {}
    bool take(std::uint32_t now) {
        if (count_ >= 128 || (count_ != 0 && std::uint32_t(now - start_) >= 4))
            return false;
        ++count_;
        return true;
    }
private:
    std::uint32_t start_;
    unsigned count_ = 0;
};
