//
// NPC HelicopterAttack
// Kar 2010-2011
//

#include <a_npc>

//------------------------------------------

main()
{
    printf("HelicopterAttack: running");
}

public OnRecordingPlaybackEnd()
{
    StartRecordingPlayback(PLAYER_RECORDING_TYPE_DRIVER, "HelicopterAttack");
}

public OnNPCModeInit()
{
	printf("HelicopterAttack: OnNPCModeInit");
}

//------------------------------------------

public OnNPCModeExit()
{
	printf("HelicopterAttack: OnNPCModeExit");
}

public OnNPCSpawn()
{
    StartRecordingPlayback(PLAYER_RECORDING_TYPE_DRIVER, "HelicopterAttack");
}

