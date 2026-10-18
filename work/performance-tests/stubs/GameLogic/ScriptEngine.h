#pragma once
struct ScriptEngine { bool isTimeFast() const { return false; } };
extern ScriptEngine* TheScriptEngine;
