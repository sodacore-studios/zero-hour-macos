#include "Common/FixedStepBudget.h"
#include <cassert>
#include <cstdio>
#include <limits>

int main() {
    // One hour of gameplay must stay one hour at all supported render rates.
    for (int renderHz : {15, 20, 30, 60, 120, 144, 240}) {
        FixedStepBudget budget;
        unsigned steps = 0;
        for (int i = 0; i < renderHz * 3600; ++i) steps += budget.advance(1.0 / renderHz, 60);
        assert(steps == 60 * 3600);
    }
    // Irregular rendering must preserve elapsed simulation time, too.
    FixedStepBudget jitter;
    double seconds = 0;
    unsigned jitterSteps = 0;
    for (int i = 0; i < 100000; ++i) {
        const double elapsed = (i % 7 + 1) / 480.0;
        seconds += elapsed;
        jitterSteps += jitter.advance(elapsed, 60);
    }
    assert(std::abs(double(jitterSteps) - seconds * 60) < 1.0);
    FixedStepBudget budget;
    assert(budget.advance(1.0/120, 60) == 0);
    assert(budget.advance(1.0/120, 60) == 1);
    assert(budget.advance(0.2, 60) == 8);
    assert(budget.advance(3600, 60) == 1);
    assert(budget.advance(0, 60) == 0);
    assert(budget.advance(-1, 60) == 0);
    assert(budget.advance(1, 0) == 0);
    assert(budget.advance(std::numeric_limits<double>::infinity(), 60) == 0);
    assert(budget.advance(1, std::numeric_limits<double>::quiet_NaN()) == 0);
    assert(budget.advance(1.0/60, 30) == 0);
    budget.reset();
    assert(budget.advance(1.0/60, 30) == 0);
    // Render at 30 Hz while lockstep requires 60 Hz: two ready frames per draw.
    int64_t next = 0;
    unsigned steps = 0;
    constexpr int64_t frequency = 6000000, delay = frequency/60;
    for (int i = 0; i < 30*3600; ++i) {
        int64_t now = 1000000 + i * (frequency/30);
        for (unsigned j = 0; j < FixedStepBudget::MaxSteps && consumeNetworkDeadline(now,delay,frequency,next); ++j) ++steps;
    }
    assert(steps == 60*3600-1);
    assert(!consumeNetworkDeadline(next-1,delay,frequency,next));
    // A missing command never calls the deadline consumer. Resume with bounded debt.
    const int64_t resume = next + frequency*10;
    assert(consumeNetworkDeadline(resume,delay,frequency,next));
    assert(next == resume+delay);
    assert(!consumeNetworkDeadline(resume,delay,frequency,next));
    LogicRateWindow rates;
    double measured = -1;
    assert(!rates.sample(0, 0, measured));
    assert(!rates.sample(30, 500, measured));
    assert(rates.sample(60, 1000, measured) && measured == 60);
    assert(rates.sample(180, 3000, measured) && measured == 60);
    assert(rates.sample(180, 4000, measured) && measured == 0);
    assert(!rates.sample(1, 4100, measured));
    assert(!rates.sample(2, 4000, measured));
    rates.reset();
    assert(!rates.sample(100, 10000, measured));
    for (int renderHz : {15, 30, 60, 144}) {
        FixedStepBudget ticks;
        LogicRateWindow metric;
        unsigned frame = 0;
        metric.sample(0, 0, measured);
        for (int i = 1; i <= renderHz * 120; ++i) {
            frame += ticks.advance(1.0/renderHz, 60);
            if (metric.sample(frame, i * 1000LL / renderHz, measured))
                assert(measured >= 59 && measured <= 61);
        }
    }
    puts("Fixed-step pacing: one-hour, jitter, pause and lockstep deadline tests passed.");
}
