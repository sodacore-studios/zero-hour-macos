#pragma once
struct NetworkInterface { int getFrameRate() const { return 60; } };
extern NetworkInterface* TheNetwork;
