#pragma once
#include <cmath>
#include <cstdint>

// Presentation-only active wall time. Never used by simulation, saves or CRCs.
class MatchClock {
public:
    void reset() { seconds = 0; initialized = false; wasRunning = false; lastFrame = 0; }
    void update(double elapsed, uint32_t frame, bool inMatch, bool running, double logicHz) {
        if (!inMatch) { reset(); return; }
        if (!initialized || frame < lastFrame) {
            // Existing saves contain simulation frames, not historical wall time.
            seconds = logicHz > 0 ? frame / logicHz : 0;
            initialized = true;
        } else if (running && wasRunning && std::isfinite(elapsed) && elapsed > 0) {
            // Slow rendering must not make the displayed clock run slow as well.
            seconds += elapsed;
        }
        lastFrame = frame;
        wasRunning = running;
    }
    double elapsedSeconds() const { return seconds; }
private:
    double seconds = 0;
    uint32_t lastFrame = 0;
    bool initialized = false;
    bool wasRunning = false;
};
