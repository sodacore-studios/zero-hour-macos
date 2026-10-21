#include "InputEventBudget.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <vector>

int main() {
    // Simulate a queued press, continuous motion and release. Rendering must get
    // turns before the queue empties, without reordering or discarding input.
    std::vector<unsigned> handled;
    unsigned next = 0, frames = 0;
    while (next < 10000) {
        InputEventBudget budget(frames * 16);
        unsigned frameEvents = 0;
        while (budget.take(frames * 16) && next < 10000) {
            handled.push_back(next++);
            ++frameEvents;
        }
        assert(frameEvents > 0 && frameEvents <= 128);
        ++frames;
    }
    assert(frames > 1 && handled.size() == 10000);
    for (unsigned i = 0; i < handled.size(); ++i) assert(handled[i] == i);

    // Expensive event delivery must yield by elapsed time, not only event count.
    InputEventBudget slow(100);
    assert(slow.take(100)); assert(slow.take(102)); assert(!slow.take(104));
    // A suspended/late caller still makes progress, but cannot monopolize a frame.
    InputEventBudget late(100);
    assert(late.take(1000)); assert(!late.take(1000));
    InputEventBudget wrap(UINT32_MAX - 1);
    assert(wrap.take(UINT32_MAX - 1)); assert(wrap.take(0)); assert(!wrap.take(2));
    puts("PASS: continuous input yields to rendering, ordered delivery, slow events and clock wrap");
}
