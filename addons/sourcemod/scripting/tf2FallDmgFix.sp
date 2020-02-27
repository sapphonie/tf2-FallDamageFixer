#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#undef REQUIRE_PLUGIN
// updater isn't REQUIRED but it is strongly recommended
#include <updater>

#define PLUGIN_VERSION      "0.0.16"
#define UPDATE_URL          "https://raw.githubusercontent.com/stephanieLGBT/tf2-FallDamageFixer/master/updatefile.txt"

public Plugin:myinfo =
{
    name                    = "Fall Damage Derandomizer",
    author                  = "stephanie",
    description             = "removes randomness from fall damage in tf2 if tf_damage_disablespread is set to 1",
    version                 =  PLUGIN_VERSION,
    url                     = "https://stephanie.lgbt"
}

/*----------  Plugin Start  ----------*/

public OnPluginStart()
{
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
    HookConVarChange(FindConVar("tf_damage_disablespread"), DamageSpreadHook);
    DoSdkStuff();
}

/*----------  Updater Stuff  ----------*/

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

/*----------  Handle convar changes  ----------*/

public DamageSpreadHook(ConVar convar, const char[] oldValue, const char[] newValue)
{
    DoSdkStuff();
}

/*----------  SDK Stuff  ----------*/

DoSdkStuff()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        // don't hook fake or nonconnected clients
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            // only hook if tf_damage_disablespread is 1
            if (GetConVarBool(FindConVar("tf_damage_disablespread")))
            {
                SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            }
            else if (!GetConVarBool(FindConVar("tf_damage_disablespread")))
            {
                SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
}

// player fully in server
public OnClientPostAdminCheck(client)
{
    if (GetConVarBool(FindConVar("tf_damage_disablespread")))
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

/*----------  Actually do the calculation here  ----------*/

// this part is directly adapted from tf_gamerules.cpp (thanks to mastercomms for pointing me in the right direction)
// https://github.com/VSES/SourceEngine2007/blob/master/se2007/game/shared/tf/tf_gamerules.cpp#L2048

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    float vVec = GetEntPropFloat(victim, Prop_Send, "m_flFallVelocity");
    // this part prevents us hooking triggered fall dmg.
    // the original dmg formula doesn't do fall dmg at or below 650 hu/s so if fall dmg is triggered there it's likely a trigger_hurt. let the game handle that. if not...
    // ...it'll be an edge case, so get the max fall dmg value and if the damage is above THAT then let the game handle it.
    // max velocity for a player in tf2 is 3500, 210 is the result of the below formula with that plugged in for Heavy's max health (without overheal) + the MAXIMUM POSSIBLE 20% random variance.
    if (vVec < 650 || damagetype & DMG_FALL && damage > 210)
    {
        return Plugin_Continue;
    }
    else if (damagetype & DMG_FALL)
    {
        // original dmg formula
        float FallDamage    = 5 * (vVec / 300);
        // scale dmg according to maxhealth
        float FallRatio     = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, victim) / 100.0;
        FallDamage          = FallDamage * FallRatio;
        // randomness would go here but we dont want that, just dmg the client nonrandomly here instead
        SDKHooks_TakeDamage(victim, 0, 0, FallDamage, DMG_FALL, -1, NULL_VECTOR, NULL_VECTOR);
        // we're done, don't let the game handle the fall dmg because we just did
        return Plugin_Stop;
    }
    return Plugin_Continue;
}
