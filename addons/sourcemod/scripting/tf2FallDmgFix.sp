#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#undef REQUIRE_PLUGIN
// updater isn't REQUIRED but it is strongly recommended
#include <updater>

#define PLUGIN_VERSION      "0.0.12"

#define UPDATE_URL  "https://raw.githubusercontent.com/stephanieLGBT/tf2-FallDamageFixer/master/updatefile.txt"

// global floata for vertical velocity
new Float:vVec = 0.0;

public Plugin:myinfo =
{
    name                    = "Fall Damage Fixer",
    author                  = "stephanie",
    description             = "removes randomness from fall damage in tf2",
    version                 =  PLUGIN_VERSION,
    url                     = "https://stephanie.lgbt"
}

/*----------  Autoupdater  ----------*/

public OnPluginStart()
{
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

/*----------  Hook / Unhook SDK Stuff  ----------*/

// player fully in server
public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// player fully out of server
public OnClientDisconnect_Post(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/*----------  Actually do the calculation here  ----------*/

// this part is directly adapted from tf_gamerules.cpp (thanks to mastercomms for pointing me in the right direction)
// https://github.com/VSES/SourceEngine2007/blob/master/se2007/game/shared/tf/tf_gamerules.cpp#L2048

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    vVec = GetEntPropFloat(victim, Prop_Send, "m_flFallVelocity");
    // this prevents us hooking triggered fall dmg
    // the original dmg formula doesn't do fall dmg at or below 650 hu/s so if fall dmg is triggered there it's likely a trigger_hurt. let the game handle that. if not...
    // ...it'll be an edge case, so get the max fall dmg value and if the damage is above THAT then let the game handle it.
    // max velocity for a player in tf2 is 3500, 210 is the result of the below formula with that plugged in for Heavy's max health (without overheal) + the MAXIMUM POSSIBLE 20% random variance.
    if (vVec < 650 || damagetype == DMG_FALL && damage > 210)
    {
        return Plugin_Continue;
    }
    else if (damagetype == DMG_FALL)
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
