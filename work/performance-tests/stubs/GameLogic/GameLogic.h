#pragma once
struct GameLogic {
    bool isGamePaused() const { return false; }
    bool isInReplayGame() const { return false; }
};
extern GameLogic* TheGameLogic;
