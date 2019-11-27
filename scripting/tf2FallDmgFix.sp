#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <updater>

#define PLUGIN_VERSION      "0.0.7"

#define UPDATE_URL	"https://raw.githubusercontent.com/stephanieLGBT/tf2-FallDamageFixer/master/updatefile.txt"

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
    if (damagetype == DMG_FALL)
    {
        float vVec = GetEntPropFloat(victim, Prop_Send, "m_flFallVelocity");
        // velocity HAS to be over 650 hu/s or we don't want fall dmg. this SHOULD get checked by the game but Just In Case...
        if (vVec > 650)
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
    }
    return Plugin_Continue;
}
