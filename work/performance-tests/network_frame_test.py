"""Compile the production network update with an empty render-message stream.

Only external transport/game services are stubbed. Extract complete functions so
this regression exercises the real update call order without assets or sockets.
"""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
source = (root / 'work/zero-hour-macos/Core/GameEngine/Source/GameNetwork/Network.cpp').read_text()
def function(start, end):
    return source[source.index(start):source.index(end, source.index(start))]

production = function('Int Network::getExecutionFrame()', '/**')
production += function('void Network::advanceCommandFrame()', 'Bool Network::processCommand')
production += function('void Network::update()', 'void Network::liteupdate()')
preamble = r'''
#include <cassert>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <vector>
using Int = int;
using UnsignedInt = unsigned;
using Bool = bool;
using __int64 = long long;
#define TRUE true
#define FALSE false
#define DEBUG_INFO_MAC(x) ((void)0)
#define DEBUG_LOG_LEVEL(level, x) ((void)0)
#define deleteInstance(x) delete (x)
struct GameLogic {
    unsigned frame = 0;
    bool multiplayer = false;
    unsigned getFrame() const { return frame; }
    bool isInMultiplayerGame() const { return multiplayer; }
} game;
GameLogic* TheGameLogic = &game;
struct NetCommandList {};
struct ConnectionManager {
    std::vector<int> ticks;
    int cleared = 0;
    NetCommandList* getFrameCommandList(unsigned frame) { assert(frame == 0); ++cleared; return new NetCommandList; }
    void processFrameTick(int frame) { ticks.push_back(frame); }
    void updateRunAhead(int, int, bool, int) {}
    void handleAllCommandsReady() {}
};
enum { NETLOCALSTATUS_PREGAME, NETLOCALSTATUS_INGAME, NETLOCALSTATUS_LEAVING, NETLOCALSTATUS_LEFT };
class Network {
public:
    ConnectionManager manager;
    ConnectionManager* m_conMgr = &manager;
    int m_localStatus = NETLOCALSTATUS_PREGAME;
    unsigned m_lastFrame = ~0u;
    int m_lastFrameCompleted = -1, m_lastExecutionFrame = 0;
    int m_runAhead = 15, m_frameRate = 30;
    bool m_frameDataReady = false, m_isStalling = false, m_didSelfSlug = false;
    long long m_nextFrameTime = 0;
    int getExecutionFrame();
    void advanceCommandFrame();
    void update();
    // No render tick or player input arrives during a catch-up step.
    void GetCommandsFromCommandList() {}
    void liteupdate() {}
    void endOfGameCheck() {}
    bool AllCommandsReady(unsigned) { return true; }
    bool timeForNewFrame() { return true; }
    void RelayCommandsToCommandList(unsigned) {}
};
'''
tests = r'''
int main() {
    Network network;
    // Network creation happens in the lobby, while the shell frame is already high.
    game.frame = 12000;
    network.update();
    assert(network.m_localStatus == NETLOCALSTATUS_PREGAME);
    assert(network.manager.ticks.empty() && network.manager.cleared == 0);
    game.multiplayer = true;
    game.frame = 0;
    network.update();
    assert(network.m_localStatus == NETLOCALSTATUS_PREGAME);
    assert(network.manager.ticks.empty());
    game.frame = 1;
    network.update();
    assert(network.m_localStatus == NETLOCALSTATUS_INGAME);
    assert(network.manager.cleared == 1);
    assert(network.manager.ticks.size() == 16);
    assert(network.manager.ticks.front() == 0 && network.manager.ticks.back() == 15);
    network.update();
    assert(network.manager.ticks.size() == 16);
    game.frame = 2;
    network.update();
    assert(network.manager.ticks.size() == 17 && network.manager.ticks.back() == 16);
    network.m_localStatus = NETLOCALSTATUS_LEAVING;
    game.frame = 3;
    network.update();
    assert(network.manager.ticks.size() == 17);
    Network delayed;
    delayed.update();
    assert(delayed.m_localStatus == NETLOCALSTATUS_INGAME);
    assert(delayed.manager.cleared == 1);
    assert(delayed.manager.ticks.back() == 17);
    puts("Network frames: empty catch-up streams, start, delayed start, repeated frame and leaving passed.");
}
'''
Path(sys.argv[1]).write_text(preamble + production + tests)
