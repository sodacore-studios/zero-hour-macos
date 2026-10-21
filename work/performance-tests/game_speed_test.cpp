// Exercise the production FramePacer with isolated platform/game dependencies.
#include "PreRTS.h"
#include "Common/FramePacer.h"
#include "Common/FixedStepBudget.h"
#include "GameClient/View.h"
#include "GameLogic/GameLogic.h"
#include "GameLogic/ScriptEngine.h"
#include "GameNetwork/NetworkInterface.h"
#include <cassert>
#include <cstdio>

GlobalData globals;
GlobalData* TheGlobalData = &globals;
View* TheTacticalView = nullptr;
GameLogic* TheGameLogic = nullptr;
ScriptEngine* TheScriptEngine = nullptr;
NetworkInterface* TheNetwork = nullptr;
FrameRateLimit::FrameRateLimit() : m_freq(1), m_start(0) {}
Real FrameRateLimit::wait(UnsignedInt fps) { return Real(m_freq + m_start) / fps; }
void FrameRateLimit::reset() { m_start = 0; }

int main() {
    FramePacer pacer;
    assert(pacer.getActualLogicTimeScaleFps() == 60);
    // Every slider position, including a render ceiling below the simulation rate.
    for (int slider = 15; slider <= 60; ++slider) {
        pacer.setSkirmishGameSpeed(slider);
        for (int renderHz : {15, 30, 60, 144}) {
            pacer.setFramesPerSecondLimit(renderHz);
            pacer.enableFramesPerSecondLimit(true);
            FixedStepBudget budget;
            unsigned ticks = 0;
            for (int i = 0; i < renderHz * 60; ++i)
                ticks += budget.advance(1.0 / renderHz, pacer.getActualLogicTimeScaleFps());
            assert(ticks == unsigned(slider * 2 * 60));
        }
    }
    // Unlimited is still bounded per draw so input/network work is not starved.
    pacer.setSkirmishGameSpeed(1000);
    FixedStepBudget unlimited;
    assert(unlimited.advance(1.0 / 60, pacer.getActualLogicTimeScaleFps()) == FixedStepBudget::MaxSteps);
    // Pause/halt and network pacing override the local selection.
    pacer.setTimeFrozen(true);
    assert(pacer.getActualLogicTimeScaleFps() == 0);
    assert(pacer.getActualLogicTimeScaleFps(FramePacer::IgnoreFrozenTime) > 60);
    pacer.setTimeFrozen(false);
    pacer.setGameHalted(true);
    assert(pacer.getActualLogicTimeScaleFps() == 0);
    pacer.setGameHalted(false);
    NetworkInterface network;
    TheNetwork = &network;
    for (int slider : {15, 30, 60, 1000}) {
        pacer.setSkirmishGameSpeed(slider);
        assert(pacer.getActualLogicTimeScaleFps() == 60);
    }
    TheNetwork = nullptr;
    pacer.setLogicTimeScaleFps(90);
    pacer.enableLogicTimeScale(true);
    assert(pacer.getActualLogicTimeScaleFps() == 90);
    // New match/load/replay must not inherit an unlimited or keyboard override.
    for (int resetOrInvalid : {0, -1, 14, 61, 1001}) {
        pacer.setSkirmishGameSpeed(resetOrInvalid);
        assert(pacer.getActualLogicTimeScaleFps() == 60);
        assert(!pacer.isLogicTimeScaleEnabled());
    }
    puts("Skirmish speed: all slider positions, render independence, unlimited, pause, network and reset passed.");
}
