"""Exercise the production latency estimator with deterministic acknowledgements."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
source_path = root / 'work/zero-hour-macos/Core/GameEngine/Source/GameNetwork/FrameMetrics.cpp'
source = source_path.read_text()
start = source.index('void FrameMetrics::processLatencyResponse(')
end = source.index('void FrameMetrics::addCushion(', start)
preamble = r'''
#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <map>
using UnsignedInt = unsigned;
using Real = float;
using Int = int;
#define USE_NEW_FRAMEMETRIC_LOGIC 1
enum class ELogVerbosity { LOG_DEBUG };
// Logging is disabled, as in normal play, but function arguments still execute.
void NetworkLog(ELogVerbosity, const char*, ...) {}
time_t clockMs = 0;
time_t timeGetTime() { return clockMs; }
struct GlobalData { unsigned m_networkLatencyHistoryLength = 60; } globals;
GlobalData* TheGlobalData = &globals;
struct FrameMetrics {
    std::map<unsigned, time_t> m_mapPendingLatenciesLookup;
    std::map<unsigned, float> m_mapLatenciesLookup, m_mapLatenciesSorted;
    int oldestLatencyInMap = -1;
    float m_averageLatency = 0;
    void processLatencyResponse(unsigned frame);
};
void expect(float actual, float expected) {
    if (std::fabs(actual - expected) > 0.00001f) {
        std::fprintf(stderr, "Expected latency %.6f s, got %.6f s\n", expected, actual);
        std::exit(1);
    }
}
'''
tests = r'''
int main() {
    FrameMetrics stable;
    for (unsigned frame = 1; frame <= 60; ++frame) {
        stable.m_mapPendingLatenciesLookup[frame] = frame * 1000;
        clockMs = frame * 1000 + 120;
        stable.processLatencyResponse(frame);
        expect(stable.m_averageLatency, 0.120f);
    }
    stable.processLatencyResponse(999); // Unrequested acknowledgements do not alter the estimate.
    expect(stable.m_averageLatency, 0.120f);
    FrameMetrics jitter;
    const int delays[] = {80, 120, 400, 100, 1300};
    float sum = 0;
    for (unsigned i = 0; i < 5; ++i) {
        jitter.m_mapPendingLatenciesLookup[i] = i * 2000;
        clockMs = i * 2000 + delays[i];
        sum += delays[i] / 1000.0f;
        jitter.processLatencyResponse(i);
        expect(jitter.m_averageLatency, sum / (i + 1));
    }
    std::puts("Network latency: stable RTT, jitter, long delay and unknown acknowledgement passed.");
}
'''
Path(sys.argv[1]).write_text(preamble + source[start:end] + tests)
