#pragma once
#include "Common/GameCommon.h"
#include <algorithm>
#include <cstdlib>
using std::min;
inline void timeBeginPeriod(int) {}
inline void timeEndPeriod(int) {}
struct GlobalData { bool m_useFpsLimit = true; bool m_TiVOFastMode = false; };
extern GlobalData* TheGlobalData;
