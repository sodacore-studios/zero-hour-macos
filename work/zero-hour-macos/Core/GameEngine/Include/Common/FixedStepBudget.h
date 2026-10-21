#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>

// Scheduling only: simulation still advances in unchanged fixed-size steps.
// Bound catch-up work so a stalled renderer cannot starve input or networking.
class FixedStepBudget {
public:
    static constexpr unsigned MaxSteps = 8;
    unsigned advance(double elapsed, double hz) {
        if (!std::isfinite(elapsed) || elapsed < 0 || !std::isfinite(hz) || hz <= 0) {
            reset(); return 0;
        }
        // A long suspension is not gameplay time. Resume without a large burst.
        if (elapsed > 0.25) { reset(); return 1; }
        debt += elapsed * hz;
        const double wholeSteps = std::floor(debt + 1e-9);
        const unsigned steps = static_cast<unsigned>((std::min)(wholeSteps, double(MaxSteps)));
        // Drop excess whole ticks, but retain fractional credit near the budget
        // ceiling (for example 118 logic Hz at 15 render Hz).
        debt = (std::max)(0.0, debt - wholeSteps);
        return steps;
    }
    void reset() { debt = 0; }
private:
    double debt = 0;
};

// Preserve overdue deadlines across ordinary slow render frames. Only abandon
// wall-clock debt after a long stall; never bypass lockstep command readiness.
inline bool consumeNetworkDeadline(int64_t now, int64_t delay, int64_t frequency, int64_t& next) {
    if (now < next) return false;
    if (next == 0 || now - next > frequency / 4) next = now + delay;
    else next += delay;
    return true;
}

// Network pacing must measure completed simulation ticks, not rendered frames.
class LogicRateWindow {
public:
    void reset() { initialized = false; }
    bool sample(uint32_t frame, int64_t milliseconds, double& rate) {
        if (!initialized || frame < firstFrame || milliseconds < firstTime) {
            firstFrame = frame; firstTime = milliseconds; initialized = true;
            return false;
        }
        const int64_t elapsed = milliseconds - firstTime;
        if (elapsed < 1000) return false;
        rate = (frame - firstFrame) * 1000.0 / elapsed;
        firstFrame = frame; firstTime = milliseconds;
        return true;
    }
private:
    bool initialized = false;
    uint32_t firstFrame = 0;
    int64_t firstTime = 0;
};
