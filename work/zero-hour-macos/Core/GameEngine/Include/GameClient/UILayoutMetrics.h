// TheSuperHackers @feature macOS: preserve the authored 4:3 HUD proportions on wide displays.
#pragma once
#include "GameClient/Display.h"
namespace UILayoutMetrics {
inline Real width() {
#ifdef __APPLE__
    return min((Real)TheDisplay->getWidth(), (Real)TheDisplay->getHeight() * (4.0f / 3.0f));
#else
    return TheDisplay->getWidth();
#endif
}
inline Real offsetX() { return ((Real)TheDisplay->getWidth() - width()) * 0.5f; }
inline Coord2D fraction(const ICoord2D& p, bool root = false) {
    Coord2D v;
    v.x = (p.x - (root ? offsetX() : 0)) / width();
    v.y = (Real)p.y / TheDisplay->getHeight();
    return v;
}
inline ICoord2D pixels(const Coord2D& p) {
    ICoord2D v;
    v.x = (Int)(p.x * width() + offsetX());
    v.y = (Int)(p.y * TheDisplay->getHeight());
    return v;
}
}
