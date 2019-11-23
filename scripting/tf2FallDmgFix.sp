#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION      "0.0.5"

public Plugin:myinfo =
{
    name                    = "Fall Damage Fixer",
    author                  = "stephanie",
    description             = "removes randomness from fall damage in tf2",
    version                 =  PLUGIN_VERSION,
    url                     = "https://stephanie.lgbt"
};

public OnPluginStart()
{

}

public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect_Post(client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

float abs(float x)                                                                              // this and other vector code borrowed from speedo.smx by JoinedSenses
{
   return (x > 0) ? x : -x;
}

public getTF2MaxHealth(client)                                                                  // borrowed from https://forums.alliedmods.net/showpost.php?p=2521025&postcount=4
{
    return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
                                                                                                // this next part is directly adapted from tf_gamerules.cpp (thanks to mastercomms for pointing me in the right direction)
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)           // https://github.com/VSES/SourceEngine2007/blob/master/se2007/game/shared/tf/tf_gamerules.cpp#L2048
{
    if (damagetype == DMG_FALL)
    {
        float abVec[3];
        GetEntPropVector(victim, Prop_Data, "m_vecVelocity", abVec);

        float vVec = abs(abVec[2]);
        if (vVec > 650)
        {
            float FallDamage    = 5 * (vVec / 300);
            float FallRatio     = getTF2MaxHealth(victim) / 100.0;
            FallDamage          = FallDamage * FallRatio;
            SDKHooks_TakeDamage(victim, 0, 0, FallDamage, DMG_FALL, -1, NULL_VECTOR, NULL_VECTOR);
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}
