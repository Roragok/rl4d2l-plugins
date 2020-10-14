#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#pragma newdecls required

#define DEBUG 0
#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))
#define MAX_PRECISION    3
#define MIN_PRECISION    0

Handle g_hVsBossBuffer = INVALID_HANDLE;
Handle hCvarPrecision = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "L4D2 Survivor Progress",
    author = "CanadaRox, Visor, Sir, devilesk",
    description = "Print survivor progress in flow percents.",
    version = "2.4.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_cur", CurrentCmd);
    RegConsoleCmd("sm_current", CurrentCmd);
    g_hVsBossBuffer = FindConVar("versus_boss_buffer");
    hCvarPrecision = CreateConVar("current_precision", "1", "Number of decimal places to display.", 0, true, float(MIN_PRECISION), true, float(MAX_PRECISION));
}

public Action CurrentCmd(int client, int args)
{
    int precision = GetConVarInt(hCvarPrecision);
    if (args) {
        char x[8];
        GetCmdArg(1, x, sizeof(x));
        precision = StringToInt(x);
        if (precision < MIN_PRECISION) precision = MIN_PRECISION;
        if (precision > MAX_PRECISION) precision = MAX_PRECISION;
    }
    float proximity = RoundToNearestN(GetProximity() * 100.0, precision);
    char msg[128];
    Format(msg, sizeof(msg), "\x01Current: \x04%%.%df%%%%", precision);
    PrintToChat(client, msg, proximity);

#if DEBUG
    PrintDebug("Round: %i. Flipped? %i", InSecondHalfOfRound(), GameRules_GetProp("m_bAreTeamsFlipped"));
    PrintDebug("Tank Enabled? %i %i", L4D2Direct_GetVSTankToSpawnThisRound(0), L4D2Direct_GetVSTankToSpawnThisRound(1));
    PrintDebug("Tank Flow %%: %f %f", L4D2Direct_GetVSTankFlowPercent(0), L4D2Direct_GetVSTankFlowPercent(1));
    PrintDebug("Witch Enabled? %i %i", L4D2Direct_GetVSWitchToSpawnThisRound(0), L4D2Direct_GetVSWitchToSpawnThisRound(1));
    PrintDebug("Witch Flow %%: %f %f", L4D2Direct_GetVSWitchFlowPercent(0), L4D2Direct_GetVSWitchFlowPercent(1));
#endif

    return Plugin_Handled;
}

stock float RoundToNearestN(float value, int places) {
    float power = Pow(10.0, float(places));
    return RoundToNearest(value * power) / power;
}

stock float GetProximity()
{
    float proximity = GetMaxSurvivorCompletion();
    if (proximity > 1.0) proximity = 1.0;
    if (proximity < 0.0) proximity = 0.0;
    return proximity;
}

stock float GetMaxSurvivorCompletion()
{
    float flow = 0.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsSurvivor(i))
        {
            flow = MAX(flow, L4D2Direct_GetFlowDistance(i));
        }
    }
#if DEBUG
    PrintDebug("Flow: %f. Max Dist: %f. Progress: %f", flow, L4D2Direct_GetMapMaxFlowDistance(), (flow + GetConVarFloat(g_hVsBossBuffer)) / L4D2Direct_GetMapMaxFlowDistance());
#endif
    return (flow + GetConVarFloat(g_hVsBossBuffer)) / L4D2Direct_GetMapMaxFlowDistance();
}

#if DEBUG
stock void PrintDebug(const char[] Message, any ...) {
    char DebugBuff[256];
    VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
    LogMessage(DebugBuff);
    PrintToChatAll(DebugBuff);
}
#endif