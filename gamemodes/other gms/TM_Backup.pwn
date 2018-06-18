/*
					© Karim "Kar" K. F. Cambridge 2010 - 2018
								All Rights Reserved

							   	Twisted Metal: SA-MP

	Unauthorized copying or distribution of this file via any medium is strictly prohibited
	
							Proprietary and confidential
*/

/*
	 * List of authors:
	 *
	 *		Karim K. F. Cambridge (Kar)		-		Founder, Owner & Lead Developer.
	 *
	 * http://www.lvcnr.net
	 * http://wiki.lvcnr.net
	 * https://forum.lvcnr.net
*/

//Vehicular Combat

/*todo

Make exprience show at end of game (textdraw)

Profiles
Garages
Customization

find some lightning attack
find some way to do energy shields

1000 - Car Spoiler
1001 - Car Spoiler 2
1002 - Car Spoiler 3
1003 - Car Spoiler 4
1004 - Car Hood Scoop 1
1005 - Car Hood Scoop 2
1006 - Car Hood Scoop 3
1013 - Headlights
1018 - Exhaust Pipe
1019 - Exhaust Pipe 2
1020 - Exhaust Pipe 3

*/

/* Testers:

Lorenc_
Tenshi
Saurik
Pghpunkid
Anthony_Vernon
Rac3r (AdrenalineX Owner)
wHoOpEr
AndreT
Nicolas.
King_Hual
Niko_boy

*/

/* Credits:

Nero_3D (missile Xangle help), Backwardsman97 (basic missile firing help),
[NoV]Austin (ricochet reflection), Hiddos (Hit bar base),
King_Hual (Class selection idea, time to time help), wHoOpEr (ideas),
RyDeR` (Polygon function)

*/
#include <a_samp>
#if defined MAX_PLAYERS
	#undef MAX_PLAYERS
	#define MAX_PLAYERS 128
#endif
#if defined MAX_VEHICLES
	#undef MAX_VEHICLES
	#define MAX_VEHICLES 128
#endif
#include <sscanf2>
#include <a_mysql>
#include <irc>
#include <foreach>
#include <zcmd>
#include <gl_common>
//#include <rnpc>

#if defined RNPC_SPEED_SPRINT
#define RNPC_INCLUDED

enum e_RNPCS
{
	t_Name[MAX_PLAYER_NAME - 4],
	t_NPCID,
	t_NPCVehicle,
	t_NPCTimer
}
#define MAX_TWISTED_NPCS 1
new Twisted_NPCS[MAX_TWISTED_NPCS][e_RNPCS], IsRNPC[MAX_PLAYERS] = {-1, ...},
	Twisted_NPC_Names[MAX_TWISTED_NPCS][MAX_PLAYER_NAME - 4] =
	{
	    "TM_Roadkill"
	}, Twisted_NPC_Names_Used[MAX_TWISTED_NPCS];

stock ConnectRNPCS()
{
	new nameid = -1;
	for(new i = 0; i < sizeof(Twisted_NPCS); i++)
	{
	    Twisted_NPCS[i][t_NPCID] = INVALID_PLAYER_ID;
	    nameid = random(sizeof(Twisted_NPC_Names));
	    if(Twisted_NPC_Names_Used[nameid] == 1) continue;
	    Twisted_NPC_Names_Used[nameid] = 1;
	    ConnectRNPC(Twisted_NPC_Names[nameid]);
	}
	return 1;
}

CMD:connectrnpc(playerid, params[])
{
	new npcid = -1;
    for(new i = 0; i < sizeof(Twisted_NPCS); i++)
	{
	    if(Twisted_NPCS[i][t_NPCID] != INVALID_PLAYER_ID) continue;
		npcid = i;
	}
	if(npcid == -1) return SendClientMessage(playerid, -1, "No NPC Slots Free");
	Twisted_NPCS[npcid][t_NPCID] = ConnectRNPC("Kar_RNPC");
	if(Twisted_NPCS[npcid][t_NPCVehicle] == 0)
	{
	    Twisted_NPCS[npcid][t_NPCVehicle] = CreateVehicle(420, 0.0, 0.0, 25.0, 0.0, -1, -1, 0);
	}
	InitializeRNPCVehicle(Twisted_NPCS[npcid][t_NPCID], Twisted_NPCS[npcid][t_NPCVehicle]);
	return 1;
}

stock InitializeRNPCVehicle(npcid, npcvehicle)
{
    PutPlayerInVehicle(npcid, npcvehicle, 0);
	RNPC_CreateBuild(npcid, PLAYER_RECORDING_TYPE_DRIVER);
	RNPC_AddMovementAlt(19.377, -5.580, 3.0, 3.653, 13.014, 3.0, RNPC_SPEED_RUN);
	RNPC_SetAcceleration(0.010);
	RNPC_FinishBuild();
	RNPC_StartBuildPlayback(npcid, 0, npcvehicle);
	return 1;
}
CMD:putrnpcinvehicle(playerid, params[])
{
    new id, npcid;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "Usage: /putrnpcinvehicle [id]");
    if(IsRNPC[id] == -1) return SendClientMessage(playerid, -1, "Error: Invalid RNPC");
    npcid = IsRNPC[id];
	InitializeRNPCVehicle(Twisted_NPCS[npcid][t_NPCID], Twisted_NPCS[npcid][t_NPCVehicle]);
	return 1;
}

CMD:bringrnpc(playerid, params[])
{
	new id, npcid;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "Usage: /bringrnpc [id]");
    if(IsRNPC[id] == -1) return SendClientMessage(playerid, -1, "Error: Invalid RNPC");
    npcid = IsRNPC[id];
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	if(IsPlayerInVehicle(Twisted_NPCS[npcid][t_NPCID], Twisted_NPCS[npcid][t_NPCVehicle]))
	{
		SetVehiclePos(Twisted_NPCS[npcid][t_NPCVehicle], x, y, z);
		PutPlayerInVehicle(Twisted_NPCS[npcid][t_NPCID], Twisted_NPCS[npcid][t_NPCVehicle], 0);
	}
	else
	{
	    MoveRNPC(Twisted_NPCS[npcid][t_NPCID], x, y, z, RNPC_SPEED_RUN);
	}
	return 1;
}

CMD:rnpcfollower(playerid, params[])
{
    new id, npcid;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "Usage: /rnpcfollower [id]");
    if(IsRNPC[id] == -1) return SendClientMessage(playerid, -1, "Error: Invalid RNPC");
    npcid = IsRNPC[id];
	KillTimer(Twisted_NPCS[npcid][t_NPCTimer]);
	FollowPlayer(Twisted_NPCS[npcid][t_NPCID], playerid, npcid);
	return 1;
}
CMD:stoprnpcfollower(playerid, params[])
{
    new id, npcid;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "Usage: /stoprnpcfollower [id]");
    if(IsRNPC[id] == -1) return SendClientMessage(playerid, -1, "Error: Invalid RNPC");
    npcid = IsRNPC[id];
	KillTimer(Twisted_NPCS[npcid][t_NPCTimer]);
	return 1;
}

stock FollowPlayer(npcid, targetid, npcindex = 0)
{
    Twisted_NPCS[npcindex][t_NPCTimer] = SetTimerEx("Follower", 500, true, "iii", npcid, targetid, npcindex);
}
forward Follower(npcid, targetid, npcindex);
public Follower(npcid, targetid, npcindex)
{
    new Float:x, Float:y, Float:z, Float:accel = 0.0;
    GetPlayerPos(targetid, x, y, z);
    if(IsPlayerInVehicle(npcid, Twisted_NPCS[npcindex][t_NPCVehicle]))
	{
	    new Float:distance;
	    switch(IsPlayerInAnyVehicle(targetid))
	    {
	    	case 1: distance = GetVehicleDistanceFromVehicle(Twisted_NPCS[npcindex][t_NPCVehicle], GetPlayerVehicleID(targetid));
	        default: distance = GetPlayerDistanceToVehicle(targetid, Twisted_NPCS[npcindex][t_NPCVehicle]);
		}
		if(distance < 5.0) return 1;
        accel = distance / 30.0;
	}
    MoveRNPC(npcid, x, y, z, accel, accel);
    return 1;
}

CMD:testvehiclernpc(playerid, params[])
{
    new id, npcid;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "Usage: /testvehiclernpc [id]");
    if(IsRNPC[id] == -1) return SendClientMessage(playerid, -1, "Error: Invalid RNPC");
    npcid = IsRNPC[id];
	new Float:x, Float:y, Float:z, Float:nx, Float:ny, Float:nz, Float:angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerPos(playerid, nx, ny, nz);
	GetPlayerFacingAngle(playerid, angle);
	nx += ( 15.0 * floatsin( -angle, degrees ) );
   	ny += ( 15.0 * floatcos( -angle, degrees ) );
    RNPC_CreateBuild(Twisted_NPCS[npcid][t_NPCID], PLAYER_RECORDING_TYPE_DRIVER); // start build mode
    RNPC_SetInternalPos(x, y, z);
    RNPC_SetDriverHealth(100);
	RNPC_SetAcceleration(0.010);
	RNPC_AddMovementAlt(x, y, z, nx, ny, nz, 0.15);
	RNPC_FinishBuild(); // end the build mode and finish the build

	RNPC_StartBuildPlayback(Twisted_NPCS[npcid][t_NPCID], 0, Twisted_NPCS[npcid][t_NPCVehicle]);
	return 1;
}

CMD:testrnpc(playerid, params[])
{
    new id, npcid;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "Usage: /testrnpc [id]");
    if(IsRNPC[id] == -1) return SendClientMessage(playerid, -1, "Error: Invalid RNPC");
    npcid = IsRNPC[id];
    RNPC_CreateBuild(Twisted_NPCS[npcid][t_NPCID], PLAYER_RECORDING_TYPE_ONFOOT); // start build mode
	RNPC_SetWeaponID(32); // Set weapon
	RNPC_AddPause(500); // wait a bit
	RNPC_AddMovement(0.0, 0.0, 0.0, 20.0, 20.0, 0.0); // start moving
	RNPC_ConcatMovement(0.0, 20.0, 0.0);  // Continue walking
	RNPC_AddPause(200); // wait a bit again
	RNPC_SetKeys(128); // aim straight forward
	RNPC_AddPause(500);
	RNPC_SetKeys(128 + 4); // Start shooting straight forward
	RNPC_AddPause(500);
	for (new i = 0; i < 360; i+=20) {
	    // Makes the NPC rotate slowly
	    RNPC_SetAngleQuats(0.0, i, 0.0);
	    RNPC_AddPause(150);
	}
	RNPC_SetKeys(128); // stop shooting
	RNPC_AddPause(500);
	RNPC_SetKeys(0); // stop aiming
	RNPC_FinishBuild(); // end the build mode and finish the build

	RNPC_StartBuildPlayback(Twisted_NPCS[npcid][t_NPCID]);
	return 1;
}

#else

#define MAP_ANDREAS_MODE_NONE			0
#define MAP_ANDREAS_MODE_MINIMAL		1
#define MAP_ANDREAS_MODE_MEDIUM			2	// currently unused
#define MAP_ANDREAS_MODE_FULL			3
#define MAP_ANDREAS_MODE_NOBUFFER		4

native MapAndreas_Init(mode);
native MapAndreas_FindZ_For2DCoord(Float:X, Float:Y, &Float:Z);
native MapAndreas_FindAverageZ(Float:X, Float:Y, &Float:Z);
native MapAndreas_Unload();

#endif

native IsValidVehicle(vehicleid);

// game helpers
native Float:MPDistanceCameraToLocation(Float:CamX, Float:CamY, Float:CamZ, Float:ObjX, Float:ObjY, Float:ObjZ, Float:FrX, Float:FrY, Float:FrZ); // calculates how distant target aim is from camera data pointed towards a certain point
native Float:MPGetVehicleUpsideDown(vehicleid); // returns values such as 1.0 as pointing up, -1.0 is totally upside down. returns -5.0 if car id is not 1..2000.
native MPGetAimTarget(PlayerID, Float:SeekRadius = 50.0); // returns player that this player is aiming at or invalid player id if no player in target area.
native MPGetTrailerTowingVehicle(vehicleid); // finds the vehicle that this trailer is attached to, returns invalid_vehicle_id if invalid or not attached to any towing vehicle.
native MPGetVehicleDriver(vehicleid); // gets vehicle driver id or invalid player id - does a quick reverse vehicle to player id lookup.
native MPGetVehicleDriverCount(vehicleid); // returns number of drivers a car has (important to solve 2 drivers 1 car issue - if you wrote any decent anticheat you know what i mean)
native MPGetVehicleOccupantCnt(vehicleid); // returns number of player a vehicle is carrying
native MPGetVehicleSurfersCnt(vehicleid); // returns number of players surfing a vehicle

native MPProjectPointOnVehicle(vehicleid, Float:v1x, Float:v1y, Float:v1z, &Float:resx, &Float:resy, &Float:resz, worldspace = 0); // projects a point on vehicle's rotation on all 3 axes.
native MPProjectPointOnPlayer(playerid, Float:v1x, Float:v1y, Float:v1z, &Float:resx, &Float:resy, &Float:resz); // projects a point on player's facing angle (x - sideways, y front/back, z = up/down).

// pure math
native Float:FMPVecLength(Float:v1x, Float:v1y, Float:v1z); // calculates length of a simple XYZ 3d vector (FAST,less precision)
native Float:MPClamp360(Float:value);
native Float:MPDistance(Float:v1x, Float:v1y, Float:v1z, Float:v2x, Float:v2y, Float:v2z);  // distance between 2 points
native Float:MPDistancePointLine(Float:PointX, Float:PointY, Float:PointZ, Float:LineSx, Float:LineSy, Float:LineSz, Float:LineEx, Float:LineEy, Float:LineEz); // [url]http://paulbourke.net/geometry/pointline/[/url] returns super huge number 10000000 if outside of range of specified the lie segment.
native Float:MPDotProduct(Float:v1x, Float:v1y, Float:v1z, Float:v2x, Float:v2y, Float:v2z);
native Float:MPFDistance(Float:v1x, Float:v1y, Float:v1z, Float:v2x, Float:v2y, Float:v2z); // distance between 2 points (faster but less precise)
native Float:MPFSQRT(Float:value);  // Faster sqrt (google the 0x5f3759df method)
native Float:MPVecLength(Float:v1x, Float:v1y, Float:v1z); // calculates length of a simple XYZ 3d vector
native MPCrossProduct(Float:v1x, Float:v1y, Float:v1z, Float:v2x, Float:v2y, Float:v2z, &Float:resx, &Float:resy, &Float:resz);
native MPFNormalize(&Float:vx, &Float:vy, &Float:vz); // fast float normalization of a vector to unit-length (makes whatever vector 1.0 long, purely to preserve direction and be able to scale it controllably)
native MPInterpolatePoint(Float:v1x, Float:v1y, Float:v1z, Float:v2x, Float:v2y, Float:v2z, &Float:resx, &Float:resy, &Float:resz, Float:distance);

#define GetDistanceBetweenPoints MPFDistance

stock FIXES_SetPlayerCheckpoint(playerid, Float:x, Float:y, Float:z, Float:size)
{
    DisablePlayerCheckpoint(playerid);
    return SetPlayerCheckpoint(playerid, x, y, z, size);
}
#define SetPlayerCheckpoint FIXES_SetPlayerCheckpoint
stock FIXES_SetPlayerRaceCheckpoint(playerid, type, Float:x, Float:y, Float:z, Float:nextx, Float:nexty, Float:nextz, Float:size)
{
    DisablePlayerRaceCheckpoint(playerid);
    return SetPlayerRaceCheckpoint(playerid, type, x, y, z, nextx, nexty, nextz, size);
}
#define SetPlayerRaceCheckpoint FIXES_SetPlayerRaceCheckpoint

new Selecting_Textdraw[MAX_PLAYERS] = {-1, ...};
stock tm_SelectTextdraw(playerid, hovercolor)
{
	Selecting_Textdraw[playerid] = hovercolor;
	return SelectTextDraw(playerid, hovercolor);
}
#define SelectTextdraw tm_SelectTextdraw

stock tm_CancelSelectTextdraw(playerid, color)
{
	Selecting_Textdraw[playerid] = -1;
	return CancelSelectTextdraw(playerid);
}
#define CancelSelectTextdraw tm_CancelSelectTextdraw

stock tm_SetPlayerHealth(playerid, Float:health)
{
	printf("[Twisted Metal Event: tm_SetPlayerHealth]");
	return SetPlayerHealth(playerid, health);
}
#define SetPlayerHealth tm_SetPlayerHealth

#define KEY_AIM                   (128)

/*stock FIXES_CreateObject(modelid, Float:X, Float:Y, Float:Z, Float:rX, Float:rY, Float:rZ, Float:DrawDistance = 0.0)
{
    printf("[System: CreateObject] - %d, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f", modelid, X, Y, Z, rX, rY, rZ, DrawDistance);
    return CreateObject(modelid, X, Y, Z, rX, rY, rZ, DrawDistance);
}
#define CreateObject FIXES_CreateObject
*/

stock FIXES_KillTimer(&timerid)
{
    //printf("[System: KillTimer] - %d", timerid);
    new rtimer = KillTimer(timerid);
    timerid = 0;
    return rtimer;
}
#define KillTimer FIXES_KillTimer

stock GetPointZPos(Float: point_X, Float: point_Y, &Float: point_Z)
{
	if(!(-3000.0 < point_X < 3000.0 || -3000.0 < point_Y < 3000.0)) return 0;

	static File: z_Map_File ;
	if(!z_Map_File)
	{
		z_Map_File = fopen("SAfull.hmap", io_read);
		if(!z_Map_File) return 0;
	}
	new z_Data[2 char] ;
	fseek(z_Map_File, (-6000 * (floatround(point_Y, point_Y <= 0.0 ? floatround_ceil : floatround_floor) - 3000) + floatround(point_X, point_X <= 0.0 ? floatround_ceil : floatround_floor) + 3000) * 2);
	fblockread(z_Map_File, z_Data, 2 char);

	point_Z = (z_Data[1 / 2] & 0x0000FFFF) * 0.01;
	return 1;
}

#define SAMP_03d 		(true)
#define Server_Version 	"0.5.5"
#define Server_Website 	"lvcnr.net"

#define THREAD:%1(%2)			\
			forward Thread_%1(%2);	\
			public Thread_%1(%2)

#define MYSQL_HOST ""
#define MYSQL_USER ""
#define MYSQL_PASS ""
#define MYSQL_DB   ""

new GlobalQuery[640];
new GlobalString[320];

#pragma unused GlobalQuery

new McHandle;

#define USE_MYSQL 	(true)
#define ENABLE_NPC 	(true)

#define BOT_1_NICKNAME 		""
#define BOT_1_REALNAME 		""
#define BOT_1_USERNAME 		""

#define IRC_SERVER 			"irc.tl"
#define IRC_PORT 			(6667)
#define IRC_CHANNEL 		"#tm"
#define ECHO_IRC_CHANNEL 	"#tm.echo"
#define ADMIN_IRC_CHANNEL 	"#tm.admins"

#define IRC_BOT_PASSWORD ""
#define IRC_BOT_ADMIN_CHAN_KEY ""

#define MAX_IRC_BOTS (1)

new gBotID[MAX_IRC_BOTS], gGroupID;

new gBotNames[MAX_IRC_BOTS][9] =
{
	{"Roadkill"}
};

#undef INVALID_TEXT_DRAW
#define INVALID_TEXT_DRAW       Text:0xFFFF

#define INVALID_PLAYER_TEXT_DRAW       PlayerText:0xFFFF

#define HOLDING(%0) \
	((newkeys & (%0)) == (%0))
#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define RELEASED(%0) \
	(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))

#define MAX_PLAYER_BARS				7
#define INVALID_PLAYER_BAR_VALUE	(Float:0xFFFFFFFF)
#define INVALID_PLAYER_BAR_ID		(PlayerBar:-1)
#define pb_percent(%1,%2,%3,%4)	((%1 - 6.0) + ((((%1 + 6.0 + %2 - 2.0) - %1) / %3) * %4))
//pb_percent(x, width, max, value)

/*
native PlayerBar:CreatePlayerProgressBar(playerid, Float:x, Float:y, Float:width=55.5, Float:height=3.2, color, Float:max=100.0, color2 = 0, color1 = 0);
native DestroyPlayerProgressBar(playerid, PlayerBar:barid);
native ShowPlayerProgressBar(playerid, PlayerBar:barid);
native HidePlayerProgressBar(playerid, PlayerBar:barid);
native SetPlayerProgressBarValue(playerid, PlayerBar:barid, Float:value);
native Float:GetPlayerProgressBarValue(playerid, PlayerBar:barid);
native SetPlayerProgressBarMaxValue(playerid, PlayerBar:barid, Float:max);
native SetPlayerProgressBarColor(playerid, PlayerBar:barid, color);
native UpdatePlayerProgressBar(playerid, PlayerBar:barid);
*/

forward PlayerBar:CreatePlayerProgressBar(playerid, Float:x, Float:y, Float:width, Float:height, color, Float:max = 100.0, color2 = -1, color1 = -1);
forward Float:GetPlayerProgressBarValue(playerid, PlayerBar:barid);

enum e_pbar
{
	Float:pb_x,
	Float:pb_y,
	Float:pb_w,
	Float:pb_h,
	Float:pb_m,
	Float:pb_v,
	PlayerText:pb_t1,
	PlayerText:pb_t2,
	PlayerText:pb_t3,
	pb_color,
	bool:pb_created
}

static pBars[MAX_PLAYERS][MAX_PLAYER_BARS][e_pbar];

stock PlayerBar:CreatePlayerProgressBar(playerid, Float:x, Float:y, Float:width, Float:height, color, Float:max = 100.0, color2 = -1, color1 = -1)
{
	new barid;
	for(barid = 0; barid < MAX_PLAYER_BARS; ++barid) // Changed from `pBars` to `MAX_PLAYER_BARS` rather than getting the size of the second cell
		if(!pBars[playerid][barid][pb_created]) break;

	if(pBars[playerid][barid][pb_created] || barid == MAX_PLAYER_BARS) return INVALID_PLAYER_BAR_ID;

	new PlayerText:in_t = pBars[playerid][barid][pb_t1] = CreatePlayerTextDraw(playerid, x, y, "_");
	PlayerTextDrawUseBox		(playerid, in_t, 1);
	PlayerTextDrawTextSize		(playerid, in_t, x + width, 0.0);
	PlayerTextDrawLetterSize	(playerid, in_t, 1.0, height / 10);
	PlayerTextDrawBoxColor		(playerid, in_t, (color1 == -1) ? (0x00000000 | (color & 0x000000FF)) : color1);

	in_t = pBars[playerid][barid][pb_t2] = CreatePlayerTextDraw(playerid, x + 1.2, y + 2.15, "_");
	PlayerTextDrawUseBox		(playerid, in_t, 1);
	PlayerTextDrawTextSize		(playerid, in_t, x + width - 2.0, 0.0);
	PlayerTextDrawLetterSize	(playerid, in_t, 1.0, height / 10 - 0.44);
	PlayerTextDrawBoxColor		(playerid, in_t, (color2 == -1) ? ((color & 0xFFFFFF00) | (0x66 & ((color & 0x000000FF) / 2))) : color2);

	in_t = pBars[playerid][barid][pb_t3] = CreatePlayerTextDraw(playerid, x + 1.2, y + 2.15, "_");
	PlayerTextDrawTextSize		(playerid, in_t, pb_percent(x, width, max, 1.0), 0.0);
	PlayerTextDrawLetterSize	(playerid, in_t, 1.0, height / 10 - 0.44);
	PlayerTextDrawBoxColor		(playerid, in_t, color);

	pBars[playerid][barid][pb_x] = x;
	pBars[playerid][barid][pb_y] = y;
	pBars[playerid][barid][pb_w] = width;
	pBars[playerid][barid][pb_h] = height;
	pBars[playerid][barid][pb_m] = max;
	pBars[playerid][barid][pb_color] = color;
	pBars[playerid][barid][pb_created] = true;
	return PlayerBar:barid;
}

stock DestroyPlayerProgressBar(playerid, PlayerBar:barid)
{
	if(barid != INVALID_PLAYER_BAR_ID && PlayerBar:-1 < barid < PlayerBar:MAX_PLAYER_BARS)
	{
		if(!pBars[playerid][_:barid][pb_created]) return 0;
		PlayerTextDrawDestroy(playerid, pBars[playerid][_:barid][pb_t1]);
		PlayerTextDrawDestroy(playerid, pBars[playerid][_:barid][pb_t2]);
		PlayerTextDrawDestroy(playerid, pBars[playerid][_:barid][pb_t3]);

		pBars[playerid][_:barid][pb_t1] = PlayerText:0;
		pBars[playerid][_:barid][pb_t2] = PlayerText:0;
		pBars[playerid][_:barid][pb_t3] = PlayerText:0;
		pBars[playerid][_:barid][pb_x] = 0.0;
		pBars[playerid][_:barid][pb_y] = 0.0;
		pBars[playerid][_:barid][pb_w] = 0.0;
		pBars[playerid][_:barid][pb_h] = 0.0;
		pBars[playerid][_:barid][pb_m] = 0.0;
		pBars[playerid][_:barid][pb_v] = 0.0;
		pBars[playerid][_:barid][pb_color] = 0;
		pBars[playerid][_:barid][pb_created] = false;
		return 1;
	}
	return 0;
}

stock ShowPlayerProgressBar(playerid, PlayerBar:barid)
{
	if(IsPlayerConnected(playerid) && barid != INVALID_PLAYER_BAR_ID && PlayerBar:-1 < barid < PlayerBar:MAX_PLAYER_BARS)
	{
		if(!pBars[playerid][_:barid][pb_created]) return 0;
		PlayerTextDrawShow(playerid, pBars[playerid][_:barid][pb_t1]);
		PlayerTextDrawShow(playerid, pBars[playerid][_:barid][pb_t2]);
		PlayerTextDrawShow(playerid, pBars[playerid][_:barid][pb_t3]);
		return 1;
	}
	return 0;
}

stock HidePlayerProgressBar(playerid, PlayerBar:barid)
{
	if(IsPlayerConnected(playerid) && barid != INVALID_PLAYER_BAR_ID && PlayerBar:-1 < barid < PlayerBar:MAX_PLAYER_BARS)
	{
		if(!pBars[playerid][_:barid][pb_created]) return 0;
		PlayerTextDrawHide(playerid, pBars[playerid][_:barid][pb_t1]);
		PlayerTextDrawHide(playerid, pBars[playerid][_:barid][pb_t2]);
		PlayerTextDrawHide(playerid, pBars[playerid][_:barid][pb_t3]);
		return 1;
	}
	return 0;
}

stock SetPlayerProgressBarValue(playerid, PlayerBar:barid, Float:value)
{
	if(barid == INVALID_PLAYER_BAR_ID || PlayerBar:MAX_PLAYER_BARS < barid < PlayerBar:-1) return 0;

	if(pBars[playerid][_:barid][pb_created])
	{
		value = (value < 0.0) ? (0.0) : (value > pBars[playerid][_:barid][pb_m]) ? (pBars[playerid][_:barid][pb_m]) : (value);
		PlayerTextDrawUseBox(playerid, pBars[playerid][_:barid][pb_t3], value > 0.0);
        pBars[playerid][_:barid][pb_v] = value;
		PlayerTextDrawTextSize(playerid, pBars[playerid][_:barid][pb_t3], pb_percent(pBars[playerid][_:barid][pb_x], pBars[playerid][_:barid][pb_w], pBars[playerid][_:barid][pb_m], value), 0.0);
		return 1;
	}
	return 0;
}

stock Float:GetPlayerProgressBarValue(playerid, PlayerBar:barid)
{
	if(barid == INVALID_PLAYER_BAR_ID || PlayerBar:MAX_PLAYER_BARS < barid < PlayerBar:-1) return INVALID_PLAYER_BAR_VALUE;
	if(pBars[playerid][_:barid][pb_created]) return pBars[playerid][_:barid][pb_v];
	return INVALID_PLAYER_BAR_VALUE;
}

stock SetPlayerProgressBarMaxValue(playerid, PlayerBar:barid, Float:max)
{
	if(barid == INVALID_PLAYER_BAR_ID || PlayerBar:MAX_PLAYER_BARS < barid < PlayerBar:-1) return 0;
	if(pBars[playerid][_:barid][pb_created])
	{
		pBars[playerid][_:barid][pb_m] = max;
		SetPlayerProgressBarValue(playerid, barid, pBars[playerid][_:barid][pb_v]);
		return 1;
	}
	return 0;
}

stock SetPlayerProgressBarColor(playerid, PlayerBar:barid, color, color2 = 0, color1 = 0)
{
	if(barid == INVALID_PLAYER_BAR_ID || PlayerBar:MAX_PLAYER_BARS < barid < PlayerBar:-1) return 0;
	if(pBars[playerid][_:barid][pb_created])
	{
		pBars[playerid][_:barid][pb_color] = color;
		PlayerTextDrawBoxColor(playerid, pBars[playerid][_:barid][pb_t1], (color1 == 0) ? (0x00000000 | (color & 0x000000FF)) : color1);
		PlayerTextDrawBoxColor(pBars[playerid][_:barid][pb_t2], (color2 == 0) ? ((color & 0xFFFFFF00) | (0x66 & ((color & 0x000000FF) / 2))) : color2);
		PlayerTextDrawBoxColor(playerid, pBars[playerid][_:barid][pb_t3], color);
		return 1;
	}
	return 0;
}

stock UpdatePlayerProgressBar(playerid, PlayerBar:barid)
{
	return ShowPlayerProgressBar(playerid, barid);
}

new Text3D:PausedText[MAX_PLAYERS],
 	PlayerUpdate[MAX_PLAYERS char],
 	Paused[MAX_PLAYERS],
 	PauseTime[MAX_PLAYERS],
	iCurrentState[MAX_PLAYERS];

forward OnPlayerPause(playerid);
forward OnPlayerUnPause(playerid);
forward IsPlayerPaused(playerid);

#define NUM_FERRIS_CAGES        10
#define FERRIS_WHEEL_ID         18877
#define FERRIS_BASE_ID          18878
#define FERRIS_CAGE_ID          18879
#define FERRIS_DRAW_DISTANCE    300.0
#define FERRIS_WHEEL_SPEED      0.01

#define FERRIS_WHEEL_Z_ANGLE  	0.0 // This is the heading the entire ferris wheel is at (beware of gimbal lock)

new Float:gFerrisOrigin[3] = {-2304.808, 2348.459, 19.0};

// Cage offsets for attaching to the main wheel
new Float:gFerrisCageOffsets[NUM_FERRIS_CAGES][3] = {
{0.0699, 0.0600, -11.7500},
{-6.9100, -0.0899, -9.5000},
{11.1600, 0.0000, -3.6300},
{-11.1600, -0.0399, 3.6499},
{-6.9100, -0.0899, 9.4799},
{0.0699, 0.0600, 11.7500},
{6.9599, 0.0100, -9.5000},
{-11.1600, -0.0399, -3.6300},
{11.1600, 0.0000, 3.6499},
{7.0399, -0.0200, 9.3600}
};

// SA-MP objects
new gFerrisWheel;
new gFerrisBase;
new gFerrisCages[NUM_FERRIS_CAGES];

forward RotateWheel();

new Float:gCurrentTargetYAngle = 0.0; // Angle of the Y axis of the wheel to rotate to.
new gWheelTransAlternate = 0; // Since MoveObject requires some translation target to intepolate
						    // rotation, the world pos target is alternated by a small amount.

#define cBlue "{009BFF}"
#define cSAMP "{a9c4e4}"
#define cSAMPRed "{E33667}"
#define cBrightYellow "{FAF87F}"
#define cRed "{FF0000}"
#define cTeal "{02D9F5}"
#define cLime "{19E03D}"
#define cGold "{FFD700}"
#define cGreen "{33FF33}"
#define cWhite "{FFFFFF}"
#define cPurple "{A82FED}"
#define cYellow "{FFEF00}"
#define cNiceBlue "{30AEFC}"
#define cLightBlue "{33CCFF}"

#define GOLD 0xFFD700FF
#define RED 0xFF0000FF
#define BLUE 0x4242FFFF
#define LIME 0x00FF00FF
#define TEAL 0x00F5FF99
#define PINK 0xE100E1AA
#define GREEN 0x33FF33AA
#define White 0xFFFFFFF
#define WHITE 0xFFFFFFF
#define YELLOW 0xF4F400FF
#define ORANGE 0xFFA500FF
#define system 0x00CCCCFF
#define BlueMsg  0x0BBF6AA
#define LIGHTGREY 0xD3D3D3FF
#define LIGHTBLUE2 0x33CCFFAA
#define ANNOUNCEMENT 0xa9c4e4ff
#define ROYALBLUE 0x4169E1FF
#define COLOR_ADMIN 0xA5EA15FF
#define COLOR_GREY 0xBEBEBEAA
#define COLOR_WHITE 0xFFFFFFAA

#define RegDialog 6500
#define LoginDialog 6501

#define MISSILE_SPEED 60.0
#define MISSILE_FIRE_KEY KEY_ACTION
#define MACHINE_GUN_KEY KEY_CROUCH
#define Missile_Update_Index 15
#define Reaper_Chainsaw 341
#define Reaper_Chainsaw_Index 3
#define Reaper_Chainsaw_Flame_Index 4
#define Darkside_Mask 6
#define Reaper_Chainsaw_Bone 5
#define REAPER_RPG_WEAPON 33
#define Shadow_Coffin 2896

//18728	smoke_flare - Roadkill's special
//19270 MapMarker_Fire - Roadkill's Special

#define Crazy8 474
#define Crimson_Fury 473
#define Junkyard_Taxi 420
#define Junkyard_Dog 525
#define Brimstone 576
#define Outlaw 599
#define Reaper 463
#define Mr.Grimm Reaper
#define Roadkill 541
#define Thumper 412
#define Spectre 475
#define Darkside 514
#define Shadow 442
#define Meat_Wagon 479
#define Vermin 482
#define Warthog_TM3 470
#define ManSalughter 455 //deprecated, should return later
#define Hammerhead 444
#define Sweet_Tooth 423

#define Machine_Gun 3002 /*pool ball*//*19718 custom bullet*//*18633 - Wrench*/
#define Missile_Default_Object 3790 //345 //
#define Missile_Napalm_Object 1222
#define Missile_RemoteBomb_Object 1370
#define Missile_Smoke_Object 18716

/*smoke textures*/

#define INVALID_MISSILE_ID -1

#define Missile_Special 0
#define Missile_Fire 1
#define Missile_Homing 2
#define Missile_Power 3
#define Missile_Napalm 4
#define Missile_Lightning 5
#define Missile_Environmentals 5
#define Missile_Ricochet 6
#define Missile_Stalker 7
#define Missile_RemoteBomb 8
#define MIN_MISSILEID 0
#define MAX_MISSILEID 9
#define Missile_Machine_Gun 9
#define Missile_Machine_Gun_Upgrade 10
#define Missile_Fall 25
#define Missile_Ram 26

#define Energy_Mines 11
#define Energy_EMP 12
#define Energy_Shield 13
#define Energy_Invisibility 14

#define ENERGY_WEAPONS_INDEX 11
#define MAX_DAMAGEABLE_MISSILES 13
#define TOTAL_WEAPONS 15

#define SPECIAL_MISSILE_SLOT 			25
#define MAX_MACHINE_GUN_SLOTS 			26
#define MAX_MISSILE_SLOTS 				26
#define MAX_COMPLETE_SLOTS 				26

stock ReturnMissileColor(missileid)
{
	new color = 0xFFFFFFAA;
	switch(missileid)
	{
	    case Missile_Homing: color = 0xB51BE0AA;
        case Missile_Fire, Missile_Special: color = 0xFF9500AA;
        case Missile_Power: color = 0xFF0000AA;
        case Missile_Napalm: color = 0xFEBF10AA;
        case Missile_Stalker: color = 0xFFB5FDAA;
        case Missile_Ricochet: color = 0x0000FFAA;
        case Missile_RemoteBomb: color = 0x09FF00AA;
	}
	return ShiftRGBAToARGB(color);
}

stock ShiftRGBAToARGB(rgba)
{
	return rgba >>> 8 | rgba << 24;
}

new EMPTime[MAX_PLAYERS] = {0, ...};

new Missile_Material_Index = 0;
#define Missile_Texture "missiles_sfs"
#define Missile_Texture_Name "white"
CMD:mmi(playerid, params[])
{
    Missile_Material_Index = strval(params);
	return 1;
}
/*
model: missile_01_sfxr

Tex: white
Tex: black64
Tex: yellow_64

texture: missiles_sfs

trilby04
ws_greyfoam
ws_packingcase1
dogcart06
dogcart05
yellow_64
black64
white
*/

#define MAX_TEAMS 2

#define TEAM_CLOWNS 0
#define TEAM_DOLLS 1

#define INVALID_GAME_TEAM -1

#define PLAYER_TEAM_COLOUR 0x00FF00FF
#define RIVAL_TEAM_COLOUR 0xFF0000FF

enum e_TeamInfo
{
	TI_Team_Name[24],
	TI_Skin_ID,
	TI_Textdraw_S[16],
	Text:TI_Textdraw,
	Text:TI_Textdraw_N,
	TI_Score
};
new Team_Info[MAX_TEAMS][e_TeamInfo] =
{
	{"The Clowns", 264, "LD_TATT:6clown", INVALID_TEXT_DRAW, INVALID_TEXT_DRAW, 0},
	//{"The Skulls", 66, "", INVALID_TEXT_DRAW},
	{"The Dolls", 193, "LD_TATT:12bndit", INVALID_TEXT_DRAW, INVALID_TEXT_DRAW, 0}
	//{"The Holy Men", 142, "", INVALID_TEXT_DRAW}
};
new gTeam_Player_Count[MAX_TEAMS],
	gTeam_Lives[MAX_TEAMS] = {6, ...},
	gHunted_Player[MAX_TEAMS] = {INVALID_PLAYER_ID,...};

new Iterator:Vehicles<MAX_VEHICLES>;
new Vehicle_Interior[MAX_VEHICLES];

new TwistedDeathArray[29][42] =
{
    {"Junkyard Dog's Taxi Slam"}, // Death Taxi ALT
	{"Preacher's Slave Dynamite"}, //
	{"Outlaw's Gun Turret and Grenade Launcher"}, // Gun Turret and Blood Missiles ALT
	{"Mr. Grimms Chainsaw"}, // Chainsaw 2012 - RPG (Rocket Propelled Grenade) ALT
	{"Roadkill's Series Missiles"}, //
	{"Thumper's Jet Stream Of Fire"},
	{"Spectre's Screaming Fiery Missile"},
	{"Darkside's Darkside Slam"}, //50. Cal Tri-Gun ALT
	{"Shadow's Death Coffin"}, // Reticle Death Coffin ALT 70 Damage, 60 Damage normal
	{"Meat Wagon's Gurney Bomb"},
	{"Vermin's Rat Rocket"}, // Piloted Rat Rocket
	{"Patriot Swarmers"}, // Patriot Swarmers
	{"Man Salughter's Boulder Throw"},
	{"Hammerheads RAM Attack"},
	{"Sweet Tooth's Missile Rack"}, // 2012 Laughing Ghost maybe ALT it?
	{"Fell To Death"},
	{"Rammed"},
	{"Fire Missile"},
	{"Homing Missile"},
	{"Power Missile"},
	{"Napalm Missile"},
	{"Environmentals"},
	{"Ricochet Missile"},
	{"Stalker Missile"},
	{"Remote Bomb"},
	{"Machine Gun"},
	{"Mega Gun"},
	{"Drop Mine"},
	{"EMP"}
};

/*

Deadliest Vehicle / Character - Reaper / Mr.Grimm
Weakest Vehicle / Character - Reaper / Mr.Grimm
Most Defensive Vehicle / Character - Darkside / Dollface
Most Offensive Vehicle / Chacacter - Roadkill / John Doe

Special Tips

R* At any time during your special weapon, press the down button to fire in reverse. Press Down button again to return to normal.

Death Warrant:

Health Press Fire To activate Special Weapon. Pan Vehicle around for nice bullet spray or keep locked on vehicle while bullets are firing.

Charge up the alt Special Weapon by holding the fire button, when the charge meter gets into red, release and quickly hold the fire button again.Audio_CreateTCPServer
R*
Max damage: 65

Meat Wagon:

The gurney will home in on enemies and explode on contact

You will be able to drive the gurney if the alt Special Weapon is enabled. Drive it just like a car
or press fire again to detonate near a group of enemies. Watch out, you can run out of fuel.

Use your Alt Special Weapon to manually control the gurney

Vermin:

Vermin's Rocket will will in on enemies

You will be able to fly the Rat Rocket if the alt Special Weapon is enabled. Use the Arrow Keys
to speed up or slow down. You can even stop in mid air.

Junkyard dog:

Fire the taxi at enemies or drop it in traffic for a hidden surprise.
Use your Special Weapon to ready up a taxi behind your truck, then throw it at your opponents.
Use alt Special Weapon to drop Health Taxi to nearby teammates. This is only for team games.
The Health Taxi will only give health to your teammates, not you.
While in a non-team game, alt Special Weapon switches your taxi to a Death Taxi.

Outlaw:
Special Weapon auto targets enemies. Tapping the R2 button while firing adds grenades into the mix.
Outlaw's Special Weapon allows you to toggle the targeted enemy using the R3 button.
At any time during your Special Weapon, press the DOWN button to fire in reverse. Press DOWN button again to return to normal.
Rear fire your Special Weapon to automatically target opponents behind you.

Reaper:
The Chainsaw Special Weapon may not track enemies very well but will do a lot of damage if it connects.
Do a wheelie to set fire to the chainsaw for extra damage.
Drag the Chainsaw Special Weapon on the ground by doing a wheelie. Once it is heated up you will do even more damage if you can line up the shot.
Perform a wheelie by pulling back on the Left Stick.
Use the alt Special Weapon to manually target opponents with an RPG
After firing your RPG, waiting until stage 2 to detonate will increase the damage and range.

Roadkill:
Charge Special Weapon by holding the Fire button until the charge bar is full, then release the Fire button to fire a stream of bullets.
Charge up the alt Special Weapon by holding the Fire button. When the charge meter gets into the red, release and quickly hold the fire button again. Repeat to fully charge. Beware of overcharging.
Rear fire the Special Weapon to drop mines.
Your alt Special Weapon is harder to use but causes a lot more damage.

Darkside:
Rear fire your special weapon to drop mines behind you.
Hold fire on your Special Weapon to perform a deadly turbo ram.
Enable your alt Special Weapon and hold the fire button to unleash minigun fury on your enemies.
When using the minigun click the R3 button to change the targeted enemy.

Shadow:
The farther the coffin travels the larger the explosion. This inflicts more damage in a bigger radius.
Manually detonate the coffin by pressing the Fire button.
Use your alt Special Weapon to manually target opponents with your coffin.
The longer your coffin Special Weapon travels the more damage it does.

*/

#define EFFECT_RANDOM           20
#define EFFECT_FIX_DEFAULT      10
#define EFFECT_FIX_Z            0.008
#define EFFECT_MULTIPLIER               0.05
#define EFFECT_HELI_VEL                 0.1
#define EFFECT_EXPLOSIONTYPE    1
#define EFFECT_EXPLOSIONOFFSET  -1.2
#define EFFECT_EXPLOSIONRADIUS  2.5

forward Float:GetTwistedMetalMaxHealth(modelid);
stock Float:GetTwistedMetalMaxHealth(modelid)
{
	new Float:health;
    switch(modelid)
	{
	    case Brimstone: health = 150.0;
		case Thumper: health = 150.0;
		case Spectre: health = 180.0;
	    case Reaper: health = 90.0;
	    case Crimson_Fury: health = 110.0;
		case Roadkill: health = 160.0;
		case Vermin: health = 205.0;
		case Meat_Wagon: health = 210.0;
		case Shadow: health = 230.0;
		case Outlaw: health = 240.0;
		case Sweet_Tooth: health = 250.0;
		case Hammerhead: health = 260.0;
		case Junkyard_Dog: health = 260.0;
		case Warthog_TM3: health = 270.0;
		case ManSalughter: health = 270.0;
		case Darkside: health = 280.0;
		default: health = 150.0;
	}
	return health;
}

#define MAX_TURBO 300.0

forward Float:GetTwistedMetalMaxTurbo(modelid);
stock Float:GetTwistedMetalMaxTurbo(modelid)
{
	new Float:turbo;
    switch(modelid)
	{
	    case Brimstone: turbo = MAX_TURBO;
		case Thumper: turbo = MAX_TURBO;
		case Spectre: turbo = MAX_TURBO;
	    case Reaper: turbo = MAX_TURBO;
	    case Crimson_Fury: turbo = MAX_TURBO;
		case Roadkill: turbo = MAX_TURBO;
		case Vermin: turbo = MAX_TURBO;
		case Meat_Wagon: turbo = MAX_TURBO;
		case Shadow: turbo = MAX_TURBO;
		case Outlaw: turbo = MAX_TURBO + 50.0;
		case Sweet_Tooth: turbo = MAX_TURBO + 100.0;
		case Hammerhead: turbo = MAX_TURBO;
		case Junkyard_Dog: turbo = MAX_TURBO + 50.0;
		case Warthog_TM3: turbo = MAX_TURBO;
		case ManSalughter: turbo = MAX_TURBO + 100.0;
		case Darkside: turbo = MAX_TURBO + 150.0;
		default: turbo = MAX_TURBO;
	}
	return turbo;
}

#define MAX_ENERGY 100.0

forward Float:GetTwistedMetalMaxEnergy(modelid);
stock Float:GetTwistedMetalMaxEnergy(modelid)
{
	new Float:energy;
    switch(modelid)
	{
	    case Brimstone: energy = MAX_ENERGY;
		case Thumper: energy = MAX_ENERGY;
		case Spectre: energy = MAX_ENERGY;
	    case Reaper: energy = MAX_ENERGY;
	    case Crimson_Fury: energy = MAX_ENERGY;
		case Roadkill: energy = MAX_ENERGY;
		case Vermin: energy = MAX_ENERGY;
		case Meat_Wagon: energy = MAX_ENERGY;
		case Shadow: energy = MAX_ENERGY;
		case Outlaw: energy = MAX_ENERGY + 10.0;
		case Sweet_Tooth: energy = MAX_ENERGY + 15.0;
		case Hammerhead: energy = MAX_ENERGY;
		case Junkyard_Dog: energy = MAX_ENERGY + 10.0;
		case Warthog_TM3: energy = MAX_ENERGY;
		case ManSalughter: energy = MAX_ENERGY + 15.0;
		case Darkside: energy = MAX_ENERGY + 20.0;
		default: energy = MAX_ENERGY;
	}
	return energy;
}

/*
Crimson Fury -- 110 Health
Talon --- 120 Health
Kamikaze --- 150 Health
Axel --- 170 Health
Death Warrant --- 180
Road Boat --- 210 Health
Juggernaut --- 400 Health*/

#define INVISIBILITY_INDEX 100

new Float:VehicleOffsetX[MAX_VEHICLES],
 	Float:VehicleOffsetY[MAX_VEHICLES],
 	Float:VehicleOffsetZ[MAX_VEHICLES];

new Nitro_Bike_Object[MAX_PLAYERS] = {INVALID_OBJECT_ID, ...};

#define MAX_MISSILE_LIGHTS 10

new
    pMissileid[MAX_PLAYERS],
 	Mine_Timer[MAX_PLAYERS],
 	pFiring_Missile[MAX_PLAYERS],
 	WasDamaged[MAX_VEHICLES],
 	Vehicle_Using_Environmental[MAX_VEHICLES],
 	Vehicle_Smoke[MAX_VEHICLES][MAX_MISSILE_SLOTS],
 	Vehicle_Missile[MAX_VEHICLES][MAX_MISSILE_SLOTS],
 	Vehicle_Missile_Currentslotid[MAX_VEHICLES],
 	Vehicle_Missile_Lights[MAX_VEHICLES][MAX_MISSILE_LIGHTS],
 	Vehicle_Missile_Lights_Attached[MAX_VEHICLES][MAX_MISSILE_LIGHTS],
 	Vehicle_Missile_Following[MAX_VEHICLES][MAX_MISSILE_SLOTS],
 	Vehicle_Missile_Reset_Fire_Time[MAX_VEHICLES],
 	Vehicle_Missile_Reset_Fire_Slot[MAX_VEHICLES],

 	Vehicle_Machine_Gun[MAX_VEHICLES][MAX_MACHINE_GUN_SLOTS],
 	Vehicle_Machine_Mega_Gun[MAX_VEHICLES][MAX_MACHINE_GUN_SLOTS],
 	Vehicle_Machine_Gunid[MAX_VEHICLES],
 	Vehicle_Machine_Gun_Flash[MAX_VEHICLES][2],
 	Vehicle_Machine_Gun_Object[MAX_VEHICLES][2],
 	Vehicle_Machine_Gun_Currentid[MAX_VEHICLES],
 	Vehicle_Machine_Gun_CurrentSlot[MAX_VEHICLES],
 	Machine_Gun_Firing_Timer[MAX_PLAYERS],

 	pLastAttacked[MAX_VEHICLES],
	pLastAttackedMissile[MAX_VEHICLES],
	pLastAttackedTime[MAX_VEHICLES],
	pCurrentlyAttacking[MAX_VEHICLES],
	pCurrentlyAttackingMissile[MAX_VEHICLES],
	Float:pCurrentlyAttackingDamage[MAX_VEHICLES][MAX_DAMAGEABLE_MISSILES]
;

new
    Object_Slot[MAX_OBJECTS] = {-1, ...},
	Object_Type[MAX_OBJECTS] = {-1, ...},
	Object_Owner[MAX_OBJECTS] = {INVALID_VEHICLE_ID, ...},
	Object_OwnerEx[MAX_OBJECTS] = {INVALID_PLAYER_ID, ...}
;

stock FIXES_DestroyObject(&objectid)
{
    //printf("[System: DestroyObject] - %d", objectid);
    //SetObjectMaterial(objectid, 0, 19341, "invalid", "invalid", 0);
    new rdo = DestroyObject(objectid);
    objectid = INVALID_OBJECT_ID;
    return rdo;
}
#define DestroyObject FIXES_DestroyObject

forward UpdateMissile(playerid, id, objectid, missileid, slot, vehicleid);
forward MissileUpdate();
forward Explode_Missile(playerid, vehicleid, slot, missileid);
forward OnVehicleFire(playerid, vehicleid, slot, missileid, objectid);
forward Destroy_Object(objectid);
forward SendRandomMsg();
forward UpdatePlayerHUD(playerid);
forward Pickup_Update();

new Special_Missile_Timer[MAX_PLAYERS];

#define MAX_PRELOADED_OBJECTS 14
new Preloading_Objects[MAX_PLAYERS][MAX_PRELOADED_OBJECTS];
new Objects_Preloaded[MAX_PLAYERS];

stock GetFreeMissileLightSlot(vehicleid)
{
	new L, rL = -1;
	for(L = 0; L < MAX_MISSILE_LIGHTS; L++)
	{
	    if(!IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
		{
		    rL = L;
			break;
		}
	}
	return rL;
}

stock GetFreeMissileSlot(vehicleid)
{
	Vehicle_Missile_Currentslotid[vehicleid]++;
	if(Vehicle_Missile_Currentslotid[vehicleid] >= MAX_MISSILE_SLOTS)
	{
		Vehicle_Missile_Currentslotid[vehicleid] = 0;
	}
	return Vehicle_Missile_Currentslotid[vehicleid];
}

#define MAX_GAME_LOBBIES 3
#define MAX_PLAYERS_PER_LOBBY 32
#define INVALID_GAME_ID (-1)
#define MAX_MAP_SELECTION 8

enum e_Games
{
	g_Map_id,
	g_Gamemode,
	g_Gamemode_Time,
	g_Gamemode_Countdown_Time,
	Text:g_Gamemode_Time_Text,
	g_Virtual_World,
	g_Voting_Time,
	bool:g_Has_Moving_Lift,
	g_Players,
	g_Lobby_gName[32],
	Text:g_Lobby_Box,
	Text:g_Lobby_Name,
	Text:g_Lobby_Type,
	Text:g_Lobby_Map,
	Text:g_Lobby_gState,
	Text:g_Lobby_Players,
	Text:g_Lobby_Time,
	VoteList[MAX_MAP_SELECTION],
 	mVotes[MAX_MAP_SELECTION]
};
new gGameData[MAX_GAME_LOBBIES][e_Games];

stock UpdateLobbyTD(Text:TextdrawID, string[])
{
	new index = -1, text[2][16], text2[32], str[64], spacecount = 0;
	format(str, sizeof(str), "%s", string);
	while((index = strfind(string, " ", true, (index + 1))) != -1)
	{
	    spacecount++;
	    if(spacecount >= 2 && index > 9)
	    {
	        sscanf(string, "p< >s[16]s[16]s[32]", text[0], text[1], text2);
			format(str, sizeof(str), "%s %s~n~%s", text[0], text[1], text2);
			//printf("[System: UpdateLobbyTD] - str: %s - index: %d", str, index);
	        break;
	    }
	}
    TextDrawSetString(TextdrawID, str);
	return 1;
}

#define MAX_MAPS 64

#define INVALID_MAP_ID (MAX_MAPS + 1)

#define MAP_SKYSCRAPERS	1
#define	MAP_DOWNTOWN 	2
#define	MAP_HANGER18	3
#define	MAP_SUBURBS 	4
#define	MAP_DIABLO_PASS	5

#define MAP_NORMAL_Z 0.0
#define MAP_SKYSCRAPER_Z 43.0
#define MAP_DOWNTOWN_Z 31.0
#define MAP_SUBURBS_Z 0.4
#define MAP_DIABLO_PASS_Z 0.0

#define MAX_MAP_TYPES 2

#define MAP_TYPE_NORMAL 0
#define MAP_TYPE_RACE 1

enum e_s_Maps
{
	m_Name[32],
	m_Type,
	m_ID,
	Float:m_LowestZ,
	m_CheckLowestZ,
	m_Weatherid,
	m_Interpolation_Index,
	m_Environmental_Name[32],
	m_Max_Grids,
	Float:m_max_X, Float:m_min_X, Float:m_max_Y, Float:m_min_Y
};
new s_Maps[MAX_MAPS][e_s_Maps];

new Iterator:Maps<MAX_MAPS>,
	Iterator:Race_Maps<MAX_MAPS>,
	Iterator:Map_Selection[MAX_GAME_LOBBIES]<MAX_MAP_SELECTION>;

CreateMap(mapname[32], map_type)
{
	new map_id = -1;
	for(new i = 1; i < MAX_MAPS; i++)
	{
		if(s_Maps[i][m_ID] <= 0)
		{
			map_id = i;
			break;
		}
	}
	if(map_id == -1) return printf("[System Map Error] - Map Limit Reached (%d)", MAX_MAPS);
	printf("Map Name: %s(%d)", mapname, map_id);
	s_Maps[map_id][m_ID] = map_id;
	strmid(s_Maps[map_id][m_Name], mapname, false, strlen(mapname), 32);
	s_Maps[map_id][m_Type] = map_type;
	s_Maps[map_id][m_LowestZ] = 0.0;
	s_Maps[map_id][m_CheckLowestZ] = 1;
	s_Maps[map_id][m_Weatherid] = 666;
	s_Maps[map_id][m_Interpolation_Index] = 0;
	strmid(s_Maps[map_id][m_Environmental_Name], "Environmental", false, strlen("Environmental"), 32);
    s_Maps[map_id][m_Max_Grids] = 3;
    s_Maps[map_id][m_min_X] = s_Maps[map_id][m_min_Y] = -20000.0;
    s_Maps[map_id][m_max_X] = s_Maps[map_id][m_max_Y] = 20000.0;
	switch(map_type)
	{
	    case MAP_TYPE_NORMAL:
	    {
	        if(!Iter_Contains(Maps, map_id))
			{
				Iter_Add(Maps, map_id);
			}
	    }
	    case MAP_TYPE_RACE:
	    {
	        if(!Iter_Contains(Race_Maps, map_id))
			{
				Iter_Add(Race_Maps, map_id);
			}
	    }
	}
	return map_id;
}

#define MD_TYPE_Name 0
#define MD_TYPE_ID 1
#define MD_TYPE_Type 2
#define MD_TYPE_LowestZ 3
#define MD_TYPE_CheckLowestZ 4
#define MD_TYPE_Weatherid 5
#define MD_TYPE_IP_Index 6
#define MD_TYPE_EN_Name 7
#define MD_TYPE_Grid_Index 8
#define MD_TYPE_WB_max_X 9
#define MD_TYPE_WB_min_X 10
#define MD_TYPE_WB_max_Y 11
#define MD_TYPE_WB_min_Y 12

#define MD_Integer 0
#define MD_String 1
#define MD_Float 2

SetMapData(mapid, md_type, mvalue[], valuetype = MD_Integer)
{
    new value, Float:fvalue;
	switch(valuetype)
	{
		case MD_Integer: value = strval(mvalue);
		case MD_Float: fvalue = floatstr(mvalue);
	}
	switch(md_type)
	{
	    case MD_TYPE_Name: strmid(s_Maps[mapid][m_Name], mvalue, 0, strlen(mvalue), 32);
	    case MD_TYPE_ID: s_Maps[mapid][m_ID] = value;
	    case MD_TYPE_Type: s_Maps[mapid][m_Type] = value;
     	case MD_TYPE_LowestZ: s_Maps[mapid][m_LowestZ] = fvalue;
	    case MD_TYPE_CheckLowestZ: s_Maps[mapid][m_CheckLowestZ] = value;
	    case MD_TYPE_Weatherid: s_Maps[mapid][m_Weatherid] = value;
     	case MD_TYPE_IP_Index: s_Maps[mapid][m_Interpolation_Index] = value;
     	case MD_TYPE_EN_Name: strmid(s_Maps[mapid][m_Environmental_Name], mvalue, 0, strlen(mvalue), 32);
     	case MD_TYPE_Grid_Index: s_Maps[mapid][m_Max_Grids] = value;
     	case MD_TYPE_WB_max_X: s_Maps[mapid][m_max_X] = fvalue;
     	case MD_TYPE_WB_min_X: s_Maps[mapid][m_min_X] = fvalue;
     	case MD_TYPE_WB_max_Y: s_Maps[mapid][m_max_Y] = fvalue;
     	case MD_TYPE_WB_min_Y: s_Maps[mapid][m_min_Y] = fvalue;
	}
	return 1;
}

forward Float:GetMapZ(Mapid);
Float:GetMapZ(Mapid)
{
	if(Mapid < 0 || Mapid >= MAX_MAPS) return 0.0;
	return s_Maps[Mapid][m_LowestZ];
}

#define MAX_MAP_OBJECTS MAX_OBJECTS / 2

enum Map_Enum
{
	m_Mapid,
	m_Model,
	Float:m_X,
	Float:m_Y,
 	Float:m_Z,
 	Float:m_rX,
	Float:m_rY,
 	Float:m_rZ,
 	Float:m_DrawDistance
};
new m_Map_Positions[MAX_MAP_OBJECTS][Map_Enum];
new m_Map_Objects[MAX_MAP_OBJECTS];

stock AddMapObject(mapid, modelid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, Float:drawdistance = 0.0)
{
    new m = -1;
    for(new mp; mp < sizeof(m_Map_Positions); mp++)
	{
	    if( m_Map_Positions[mp][m_Model] != 0 ) continue;
	    m = mp;
	    break;
	}
	if(m == -1) return 0;
	m_Map_Positions[m][m_Mapid] = mapid;
	m_Map_Positions[m][m_Model] = modelid;
	m_Map_Positions[m][m_X] = x;
	m_Map_Positions[m][m_Y] = y;
	m_Map_Positions[m][m_Z] = z;
	m_Map_Positions[m][m_rX] = rx;
 	m_Map_Positions[m][m_rY] = ry;
  	m_Map_Positions[m][m_rZ] = rz;
  	m_Map_Positions[m][m_DrawDistance] = drawdistance;
	return 1;
}

#define MAX_MAP_PICKUPS 	(MAX_PICKUPS / 64) + 96 // 64

enum Pickups_data
{
 	Float:PickupX,
  	Float:PickupY,
   	Float:PickupZ,
   	Modelid,
   	Type,
    Pickupid,
    VirtualWorld,
	bool:Created,
	Pickuptype,
	Text3D:Pickuptext
};
new PickupInfo[MAX_MAP_PICKUPS][Pickups_data],
	PickupSlots[sizeof(PickupInfo)] = {0, ...};

#define PICKUPTYPE_HEALTH 0
#define PICKUPTYPE_TURBO 1
#define PICKUPTYPE_MACHINE_GUN_UPGRADE 2
#define PICKUPTYPE_HOMING_MISSILE 3
#define PICKUPTYPE_FIRE_MISSILE 4
#define PICKUPTYPE_POWER_MISSILE 5
#define PICKUPTYPE_NAPALM_MISSILE 6
#define PICKUPTYPE_ENVIRONMENTALS 7
#define PICKUPTYPE_RICOCHETS_MISSILE 8
#define PICKUPTYPE_STALKER_MISSILE 9
#define PICKUPTYPE_REMOTEBOMBS 10
#define PICKUPTYPE_LIGHTNING 11

enum e_Maps_PickupInfo
{
	PI_Mapid,
	PI_Pickuptype,
	Float:PI_pX,
	Float:PI_pY,
	Float:PI_pZ
}

#define MAX_MAPS_PICKUPS 500
new Maps_PickupInfo[MAX_MAPS_PICKUPS][e_Maps_PickupInfo];

stock AddMapPickup(mapid, pickuptype, Float:x, Float:y, Float:z)
{
    new m = -1;
    for(new mp; mp < sizeof(Maps_PickupInfo); mp++)
	{
	    if( Maps_PickupInfo[mp][PI_Mapid] != 0 ) continue;
	    m = mp;
	    break;
	}
	if(m == -1) return 0;
	Maps_PickupInfo[m][PI_Mapid] = mapid;
	Maps_PickupInfo[m][PI_Pickuptype] = pickuptype;
	Maps_PickupInfo[m][PI_pX] = x;
	Maps_PickupInfo[m][PI_pY] = y;
	Maps_PickupInfo[m][PI_pZ] = z;
	return 1;
}

#define MAP_ALL_DATA 0
#define MAP_DATA_OBJECTS 1
#define MAP_DATA_PICKUPS 2

stock LoadMapData(dataid, mapid = MAX_MAPS)
{
	switch(dataid)
	{
	    case MAP_ALL_DATA:
	    {
			mysql_function_query(McHandle, "SELECT * FROM `Maps`", true, "Thread_OnMapDataLoad", "i", MAX_MAPS);
		}
		case MAP_DATA_OBJECTS:
	    {
		    format(GlobalQuery, sizeof(GlobalQuery), "SELECT * FROM `Maps_Objects` WHERE `Mapid` = %d LIMIT 0,%d", mapid, MAX_MAP_OBJECTS);
			mysql_function_query(McHandle, GlobalQuery, true, "Thread_OnMapObjectsLoad", "i", MAX_MAPS);
		}
		case MAP_DATA_PICKUPS:
	    {
		    format(GlobalQuery, sizeof(GlobalQuery), "SELECT * FROM `Maps_Pickups` WHERE `Mapid` = %d LIMIT 0,%d", mapid, MAX_MAP_PICKUPS);
			mysql_function_query(McHandle, GlobalQuery, true, "Thread_OnMapPickupsLoad", "i", MAX_MAPS);
		}
	}
	return;
}

THREAD:OnMapObjectsLoad(extraid)
{
    new rows, fields, mapname[32], mapid, data[12], modelid,
	Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, Float:drawdistance;
	cache_get_data(rows, fields, McHandle);
	for(new row = 0; row < rows; row++)
	{
	    if(row >= MAX_MAP_OBJECTS)
		{
		    printf("[System - OnMapObjectsLoad: Max Object Limit Reached]");
			break;
		}
		cache_get_row(row, 0, mapname, McHandle); // map name
	    cache_get_row(row, 1, data, McHandle); // map id
	    mapid = strval(data);
	    cache_get_row(row, 2, data, McHandle); // model
	    modelid = strval(data);
	    cache_get_row(row, 3, data, McHandle); // x
	    x = floatstr(data);
	    cache_get_row(row, 4, data, McHandle); // y
	    y = floatstr(data);
	    cache_get_row(row, 5, data, McHandle); // z
	    z = floatstr(data);
	    cache_get_row(row, 6, data, McHandle); // rx
	    rx = floatstr(data);
	    cache_get_row(row, 7, data, McHandle); // ry
	    ry = floatstr(data);
	    cache_get_row(row, 8, data, McHandle); // rz
	    rz = floatstr(data);
	    cache_get_row(row, 9, data, McHandle); // Draw_Distance
	    drawdistance = floatstr(data);
	    AddMapObject(mapid, modelid, x, y, z, rx, ry, rz, drawdistance);
	}
	return 1;
}

THREAD:OnMapPickupsLoad(extraid)
{
    new rows, fields, mapname[32], mapid, pickuptype, data[12], Float:x, Float:y, Float:z;
	cache_get_data(rows, fields, McHandle);
	for(new row = 0; row < rows; row++)
	{
	    if(row >= MAX_MAP_PICKUPS)
		{
		    printf("[System - OnMapPickupsLoad: Max Pickups Limit Reached]");
			break;
		}
		cache_get_row(row, 0, mapname, McHandle); // map name
	    cache_get_row(row, 1, data, McHandle); // map id
	    mapid = strval(data);
	    #pragma unused mapid, mapname
	    cache_get_row(row, 2, data, McHandle); // pickuptype
	    pickuptype = strval(data);
	    cache_get_row(row, 3, data, McHandle); // x
	    x = floatstr(data);
	    cache_get_row(row, 4, data, McHandle); // y
	    y = floatstr(data);
	    cache_get_row(row, 5, data, McHandle); // z
	    z = floatstr(data);
	    CreatePickupEx(14, x, y, z, 0, pickuptype);
	}
	return 1;
}

THREAD:OnMapDataLoad(extraid)
{
	new rows, fields, mapname[32], mapid, maptype, data[12];
	cache_get_data(rows, fields, McHandle);
	for(new row = 0; row < rows; row++)
	{
	    if(row >= MAX_MAPS) break;
	    cache_get_row(row, 0, mapname, McHandle); // map name
	    cache_get_row(row, 1, data, McHandle); // map type
	    maptype = strval(data);
	    mapid = CreateMap(mapname, maptype);
	    cache_get_row(row, 2, data, McHandle); // map id
	    SetMapData(mapid, MD_TYPE_ID, data, MD_String);
	    cache_get_row(row, 3, data, McHandle); // lowest z
	    SetMapData(mapid, MD_TYPE_LowestZ, data, MD_Float);
	    cache_get_row(row, 4, data, McHandle); // check lowest z
	    SetMapData(mapid, MD_TYPE_CheckLowestZ, data, MD_Integer);
	    cache_get_row(row, 5, data, McHandle); // weather id
	    SetMapData(mapid, MD_TYPE_Weatherid, data, MD_Integer);
	    cache_get_row(row, 6, data, McHandle); // Amount of Interpolation views per map
	    SetMapData(mapid, MD_TYPE_IP_Index, data, MD_Integer);
	    cache_get_row(row, 7, data, McHandle); // Environmental Missile name
	    SetMapData(mapid, MD_TYPE_EN_Name, data, MD_String);
	    cache_get_row(row, 8, data, McHandle); // Grid Index / Max Grids Per Map
	    SetMapData(mapid, MD_TYPE_Grid_Index, data, MD_Integer);
	}
	return 1;
}

public OnQueryError(errorid, error[], callback[], query[], connectionHandle)
{
    printf("EID: %d | Error: %s | Query: %s", errorid, error, query);
	switch(errorid)
	{
		case CR_COMMAND_OUT_OF_SYNC: {
			mysql_free_result();
			printf("[Mysql: Error - Callback: %s] - Commands Out Of Sync For - Query: %s", callback, query);
		}
		case ER_UNKNOWN_TABLE: printf("[Mysql: Error - Callback: %s] - Unknown table '%s' in %s - callback: %s", callback, error, query);
		case ER_SYNTAX_ERROR: printf("[Mysql: Error - Callback: %s] - Something is wrong in your syntax, query: %s", callback, query);
		case CR_SERVER_GONE_ERROR, CR_SERVER_LOST, CR_SERVER_LOST_EXTENDED: mysql_reconnect();
	}
	return 1;
}

new pFirstTimeViewingMap[MAX_PLAYERS] = {1, ...};

forward OnMapBegin(gameid, gamemode, mapid);
forward OnMapFinish(gameid, gamemode, mapid);
forward OnGameBegin(gameid);

#define MAX_GAMEMODES 7

#define DEATHMATCH 0
#define TEAM_DEATHMATCH 1
#define HUNTED 2
#define TEAM_HUNTED 3
#define LAST_MAN_STANDING 4
#define TEAM_LAST_MAN_STANDING 5
#define RACE 6

new Text:iSpawn_Text;

new iGamemode_MaxTime = (10 * 60),
	iGamemode_CountDownMaxTime = 45;

enum s_GameModes
{
	GM_Name[32 + 12]
};
new s_Gamemodes[MAX_GAMEMODES][s_GameModes] =
{
	{"Deathmatch"},
	{"Team Deathmatch"},
	{"Hunted"},
	{"Team Hunted"},
	{"Last Man Standing"},
	{"Team Last Man Standing"},
	{"Race (Deathrace)"}
};
new gmVotes[MAX_GAMEMODES];

#define MAX_LIFTS 2

new MovingLifts[MAX_LIFTS],
	MovingLiftPickup[MAX_LIFTS],
	MovingLiftStatus[MAX_LIFTS];

enum e_MovingLifts
{
	L_Mapid,
	L_Objectid,
	Float:L_X,
	Float:L_Y,
	Float:L_Z,
	Float:L_RX,
	Float:L_RY,
	Float:L_RZ,
	Float:L_Move_Z_Index,
	Float:L_Move_Speed
}
new MovingLiftArray[MAX_LIFTS][e_MovingLifts] =
{
	{MAP_DOWNTOWN, 16773, -2084.7964, -984.2720, 31.2, 90.0, 90.0, 90.0, 33.2, 6.0},
	{MAP_DOWNTOWN, 16773, -2083.0549, -781.6403, 31.2, 90.0, 90.0, 90.0, 33.2, 6.0}
};

new HelicopterAttack = INVALID_OBJECT_ID;

#define d_type_none 0
#define d_type_close 1
#define d_type_far 2
stock GetTwistedMissileName(missileid, vehicleid = 0, bool:checkspecial = false, alt_special = 0, distance_type = d_type_none, mapid = INVALID_MAP_ID)
{
	new str[32];
	switch(missileid)
	{
	    case Missile_Special:
		{
		    switch(checkspecial)
		    {
		        case true:
		        {
		            switch(GetVehicleModel(vehicleid))
		            {
			            case Junkyard_Dog: str = "Taxi Slam";
						case Brimstone: str = "Slave Dynamite";
						case Outlaw: str = "SUV Turret";
						case Reaper:
						{
						    switch(alt_special)
						    {
						        case 2: str = "RPG";
								case 1: str = "Flame Saw";
								default: str = "Mr. Grimms Chainsaw";
							}
						}
						case Roadkill: str = "Series Missiles";
						case Thumper: str = "Jet Stream Of Fire";
						case Spectre: str = "Screaming Fiery Missile";
						case Darkside: str = "Darkside Slam";
						case Shadow:
						{
							switch(alt_special)
						    {
								case 1: str = "Coffin Bomb Blast";
								default: str = "Death Coffin";
							}
						}
						case Meat_Wagon:
						{
						    switch(alt_special)
						    {
								case 1: str = "Piloted Gurney Bomb";
								default: str = "Gurney Bomb";
							}
						}
						case Vermin:
						{
						    switch(alt_special)
						    {
								case 1: str = "Piloted Rat Rocket";
								default: str = "Rat Rocket";
							}
						}
						case Warthog_TM3:
						{
						    switch(alt_special)
						    {
								case 1: str = "Patriot Swarmers";
								default: str = "Patriot Swarmers";
							}
						}
						case ManSalughter: str = "Boulder Throw";
						case Hammerhead: str = "RAM Attack";
						case Sweet_Tooth: str = "Missile Rack";
					}
		        }
				default: str = "Special";
			}
		}
	    case Missile_Fire: str = "Fire";
	    case Missile_Homing: str = "Homing";
	    case Missile_Power: str = "Power";
	    case Missile_Napalm: str = "Napalm";
	    case Missile_Ricochet: str = "Ricochet";
	    case Missile_Stalker: str = "Stalker";
	    case Missile_Environmentals:
		{
		    if(mapid >= 0 && mapid < MAX_MAPS)
		    {
  				str = s_Maps[mapid][m_Environmental_Name];
  			}
		}
	    case Missile_RemoteBomb: str = "Remote Bomb";
	    case Missile_Machine_Gun: str = "Machine Gun";
	    case Missile_Machine_Gun_Upgrade: str = "Mega Gun";
	    case Energy_Mines: str = "Drop Mine";
	    case Energy_EMP: str = "EMP";
	    case Energy_Shield: str = "Shield";
	    case Energy_Invisibility: str = "Invisibility";
	    default: str = "Unknown";
	}
	switch(distance_type)
 	{
 	    case d_type_close:
		{
		    strcat(str, " Close!", _);
		}
		case d_type_far:
		{
		    strcat(str, " Far!", _);
		}
 	}
	return str;
}

#define MAX_TIMETEXTS 7

#define TIMETEXT_TOP_2 	0
#define TIMETEXT_TOP 	1
#define TIMETEXT_MIDDLE 2
#define TIMETEXT_POINTS 3
#define TIMETEXT_MIDDLE_LARGE 4
#define TIMETEXT_MIDDLE_SUPER_LARGE 5
#define TIMETEXT_BOTTOM 6

#define TM_STATUS_COLOUR1 0xF5E000FF
#define TM_STATUS_COLOUR2 0xFF0000FF
#define TM_STATUS_COLOUR3 0xFFFFFFFF
#define TM_STATUS_COLOUR4 0xFFA600FF

new StatusTextColors[MAX_TIMETEXTS] =
{
    TM_STATUS_COLOUR1,
    TM_STATUS_COLOUR1,
    TM_STATUS_COLOUR2,
    TM_STATUS_COLOUR4,
    TM_STATUS_COLOUR3,
    TM_STATUS_COLOUR4,
    TM_STATUS_COLOUR3
};

new Float:StatusTextPositions[MAX_TIMETEXTS][2] =
{
    {320.0, 131.0},
    {320.0, 143.0},
    {320.0, 163.0},
    {320.0, 158.0},
    {320.0, 175.0},
    {320.0, 200.0},
    {320.0, 330.0}
};

new Float:StatusTextLetterSize[MAX_TIMETEXTS][2] =
{
    {0.45, 1.8},
    {0.50, 2.0},
    {0.60, 2.2},
    {0.30, 1.4},
    {0.90, 3.0},
    {1.10, 3.4},
    {0.60, 2.2}
};

enum pStatusinfo
{
    StatusIndex,
    StatusTime,
	StatusTextTimer[MAX_TIMETEXTS],
	PlayerText:StatusText[MAX_TIMETEXTS]
}
new pStatusInfo[MAX_PLAYERS][pStatusinfo];

#define MAX_STATUS_TEXT_LENGTH 32 + 4

new Status_Text[MAX_PLAYERS][MAX_TIMETEXTS][MAX_STATUS_TEXT_LENGTH];
//#define Speedometer_Needle_Index 8

#define MAX_XP_STATUSES 6

#define ENERGY_COLOUR 0x0097FCFF
#define EXPRIENCE_COLOUR 0xC20000FF

enum pTextinfo
{
    PlayerText:pTextWrapper,
	PlayerText:AimingPlayer,
	PlayerText:AimingBox,
	PlayerText:pHealthBar,
	PlayerText:pMissileSign[MAX_MISSILEID],
	PlayerText:pLevelText,
	PlayerText:pEXPText,
	PlayerText:pEXPStatus[MAX_XP_STATUSES],
	PlayerText:pKillStreakText,
	PlayerText:Mega_Gun_IDX,
	PlayerText:Mega_Gun_Sprite,
	//Text:TDSpeedClock[16],
	//Text:SpeedoMeterNeedle[8],
	PlayerBar:pAiming_Health_Bar,
	PlayerBar:pEnergyBar,
	PlayerBar:pTurboBar,
	PlayerBar:pExprienceBar,
	PlayerBar:pChargeBar,
	PlayerText:pTeam_Sprite,
	PlayerText:pTeam_Score,
	PlayerText:pRival_Team_Sprite,
	PlayerText:pRival_Team_Score,
	PlayerText:pGarage_Go_Back
};
new pTextInfo[MAX_PLAYERS][pTextinfo];
new pEXPTextStatus[MAX_PLAYERS][MAX_XP_STATUSES];
new pEXPTextStatusTimer[MAX_PLAYERS][MAX_XP_STATUSES];
new pEXPTextStatusText[MAX_PLAYERS][MAX_XP_STATUSES][32];
new pEXPTextStatusChanged[MAX_PLAYERS][MAX_XP_STATUSES];

new Text:Players_Online_Textdraw = INVALID_TEXT_DRAW;

#define MAX_SPECIAL_OBJECTS 7

#define DEFAULT_CHARGE_INDEX 20.0

enum pInfo
{
    CanExitVeh,
    pSkinid,
    pSkin,
    pTurbo,
	pEnergy,
	pSpawned,
	pLastVeh,
    Turbo_Tick,
    Turbo_Timer,
    Float:pCharge_Index,
    pCharge_Timer,
    pSpecialObjects[MAX_SPECIAL_OBJECTS],
    pMissiles[TOTAL_WEAPONS],/*0 - Special, 1 - Fires, 2 - Homing, 3 - Napalms, 4 - Powers, 5 - Environments,
    6 - Ricochets, 7- Stalkers, 8 - Remote Bombs*/
    pMissile_Special_Time,
    pSpecial_Missile_Update,
    pSpecial_Missile_Vehicle,
    pSpecial_Missile_Object,
    pSpecial_Using_Alt,
    pMissile_Charged,
    Float:pDamageToPlayer[MAX_PLAYERS],
    Float:pDamageDone,
    Float:pDamageTaken,
    g_pExprience,
    g_pPoints,
    gTeam,
    gRival_Team,
	gGameID,
	pKillStreaking,
    pUsername[24],
    pPassword[16],
    pIP[17],
    pRegistered[20],
	pLastVisit,
	AdminLevel,
    pDonaterRank,
    Money,
    Score,
	Kills,
	Deaths,
	Assists,
	pKillStreaks,
	pExprience,
	pLast_Exp_Gained,
	pLevel,
	pTier_Points,
	Float:pTravelled_Distance,
	pFavourite_Vehicle,
	pFavourite_Map,
	pRegular,
	LoggedSeconds,
	LoggedMinutes,
	LoggedHours,
	LoggedDays,
	bool:pGender,
	EnvironmentalCycle_Timer,
	pBurnout,
	pBurnoutTimer,
	Camera_Mode,
 	Camera_Object
};

//new DeActiveSpeedometer[MAX_PLAYERS char];
new PlayerInfo[MAX_PLAYERS][pInfo];
new IsLogged[MAX_PLAYERS];
new Muted[MAX_PLAYERS];

new pSpectate_Random_Teammate[MAX_PLAYERS];

#define BitFlag_Get(%0,%1)            ((%0) & (%1))   // Returns zero (false) if the flag isn't set.
#define BitFlag_On(%0,%1)             ((%0) |= (%1))  // Turn on a flag.
#define BitFlag_Off(%0,%1)            ((%0) &= ~(%1)) // Turn off a flag.
#define BitFlag_Toggle(%0,%1)         ((%0) ^= (%1))  // Toggle a flag (swap true/false).

enum Account_Flags:(<<= 1)
{
	ACCOUNT_UPDATE_ADMIN = 1,
	ACCOUNT_UPDATE_KILLS,
	ACCOUNT_UPDATE_DEATHS,
	ACCOUNT_UPDATE_ASSISTS,
	ACCOUNT_UPDATE_KILLSTREAKS,
	ACCOUNT_UPDATE_EXPRIENCE,
	ACCOUNT_UPDATE_LAST_EXPRIENCE,
	ACCOUNT_UPDATE_LEVEL
};
new Account_Flags:Account_Saving_Update[MAX_PLAYERS];

ToggleAccountSavingVar(playerid, Account_Flags:var)
{
    if(!BitFlag_Get(Account_Saving_Update[playerid], var))
	{
	    BitFlag_On(Account_Saving_Update[playerid], var);
	}
}

new Current_Vehicle[MAX_PLAYERS];
new Current_Car_Index[MAX_PLAYERS];

#define TM_SELECTION_X -2404.533447
#define TM_SELECTION_Y -598.653503
#define TM_SELECTION_Z 132.648437
#define TM_SELECTION_ANGLE 189.156631

#define TM_SELECTION_CAMERA_X -2404.533447 + (15 * floatsin(-(294.587921 - 180.0), degrees))
#define TM_SELECTION_CAMERA_Y -598.653503 + (15 * floatcos(-(294.587921 - 180.0), degrees))
#define TM_SELECTION_CAMERA_Z 135.648437

#define TM_SELECTION_LOOKAT_X -2404.533447
#define TM_SELECTION_LOOKAT_Y -598.653503
#define TM_SELECTION_LOOKAT_Z 132.648437

#define HUD_MISSILES 0
#define HUD_ENERGY 1
new pHUDStatus[MAX_PLAYERS] = {HUD_MISSILES, ...};

new Text:Tutorial_Arrows[10] = {INVALID_TEXT_DRAW, ...},
	Text:Tutorial_Numbers[10] = {INVALID_TEXT_DRAW, ...},
	Text:pHud_Box = INVALID_TEXT_DRAW,
	Text:pHud_UpArrow = INVALID_TEXT_DRAW,
	Text:pHud_LeftArrow = INVALID_TEXT_DRAW,
	Text:pHud_RightArrow = INVALID_TEXT_DRAW,
	Text:pHud_UpArrowKey = INVALID_TEXT_DRAW,
	Text:pHud_LeftArrowKey = INVALID_TEXT_DRAW,
	Text:pHud_RightArrowKey = INVALID_TEXT_DRAW,
	Text:pHud_HealthSign = INVALID_TEXT_DRAW,
	Text:pHud_BoxSeparater = INVALID_TEXT_DRAW,
	Text:pHud_SecondBox = INVALID_TEXT_DRAW,
	Text:pHud_EnergySign = INVALID_TEXT_DRAW,
	Text:pHud_TurboSign = INVALID_TEXT_DRAW,
	Text:Navigation_S[9] = {INVALID_TEXT_DRAW, ...},
	Text:Navigation_Game_S[8] = {INVALID_TEXT_DRAW, ...};

#define NAVIGATION_COLOUR 0xFA1919AA

#define NAVIGATION_INDEX_MULTIPLAYER 0
#define NAVIGATION_INDEX_GARAGE 1
#define NAVIGATION_INDEX_OPTIONS 2
#define NAVIGATION_INDEX_HELP 3

#define NAVIGATION_INDEX_LOBBY 0

#pragma unused pHud_UpArrowKey, pHud_LeftArrowKey, pHud_RightArrowKey

new pName[MAX_PLAYERS][MAX_PLAYER_NAME];
Playername(playerid)
{
    return pName[playerid];
}
new Float:Race_Sandstorm[51][3] = // raceid 2
{
	{1421.851,827.1125,7.2214}, // left side diablo pass start
	{1421.851,832.828,7.2214}, // Middle diablo pass start
	{1421.851,838.421,7.2214}, // Right side diablo pass start
	{1354.7850,833.5051,6.4302},
	{1180.3613,824.6801,9.2342},
	{1061.4458,780.6996,10.2979},
	{887.7937,705.5621,10.6422},
	{760.2805,662.1089,10.7087},
	{567.0075,668.4058,3.2638},
	{381.6089,754.8764,5.7425},
	{218.6937,730.1298,5.7440},
	{102.6613,668.5835,5.1407},
	{-47.9433,593.8580,12.2452},
	{-303.3610,549.4077,15.9327},
	{-473.4297,574.0391,16.6376},
	{-627.5323,643.2344,16.2487},
	{-798.6367,752.8325,17.7108},
	{-839.6288,893.0654,24.5104},
	{-859.5345,1053.5231,24.7561},
	{-886.0832,1182.4075,30.4311},
	{-971.4880,1304.0643,40.0529},
	{-1117.8082,1125.6691,37.2683},
	{-1270.4042,973.1876,44.4607},
	{-1405.5059,831.3101,47.0741},
	{-1536.3539,694.2156,44.5243},
	{-1646.1067,578.2405,39.3058},
	{-1739.5006,499.2254,38.1284},
	{-1835.3051,394.4664,16.6242},
	{-1805.4392,366.2700,16.6258},
	{-1702.7667,485.5859,37.8732},
	{-1639.0970,562.2017,39.0102},
	{-1461.2721,750.1494,46.1058},
	{-1309.5441,908.8261,45.7788},
	{-1133.0054,1096.0944,38.0701},
	{-1011.2737,1173.5907,33.9574},
	{-927.6167,1018.7233,21.4330},
	{-886.1157,834.8148,19.1145},
	{-764.4874,712.0309,17.8335},
	{-666.6068,676.8901,16.2660},
	{-466.6797,592.7137,16.6924},
	{-231.8521,575.0251,15.2673},
	{-49.4826,615.3744,11.7747},
	{88.9444,685.1351,4.9183},
	{350.0574,776.9515,5.7066},
	{536.7059,703.6653,2.7575},
	{781.9974,687.4899,10.8904},
	{990.8502,743.8273,10.2260},
	{1114.7557,809.9848,10.2031},
	{1302.0201,834.3081,7.1103},
	{1385.2485,836.5121,6.3536},
	{1477.6008,834.4986,6.3564}
};

forward SetCP(playerid, PrevCP, NextCP, MaxCP, rType);
forward Race_Loop();

#define MAX_RACE_CHECKPOINTS 52
#define RACE_CHECKPOINT_SIZE 9.0
#define MAX_STARTING_GRIDS 4

new Float:Race_Checkpoints[MAX_RACE_CHECKPOINTS][3];

new Total_Race_Checkpoints,
 	Total_Race_Laps,
 	RaceType = 0,
 	r_Index,
 	PlayersCount[MAX_STARTING_GRIDS],
	Float:RaceVehCoords[MAX_STARTING_GRIDS][4],
	Race_Top3_Positions[3] = {INVALID_PLAYER_ID, ...},
	Race_Top3_Positions_Finished[3] = {0, ...};

new CP_Progress[MAX_PLAYERS],
 	Race_Current_Lap[MAX_PLAYERS],
 	Race_Position[MAX_PLAYERS],
 	Race_Old_Position[MAX_PLAYERS],
	Race_Object[MAX_PLAYERS] = {INVALID_OBJECT_ID, ...};

new p_Position[MAX_PLAYERS],
	p_Old_Position[MAX_PLAYERS];

#define PVRP_Create 0
#define PVRP_Update 1
#define PVRP_Destroy 2

enum E_RACE_POS
{
	E_RACE_POS_CP,
	E_RACE_POS_LAP,
	Float:E_RACE_POS_TOGO,
	E_RACE_POS_POS
}

new PlayerText:Race_Box[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...};
new PlayerText:Race_Box_Outline[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...};
new PlayerText:Race_Box_Text[MAX_PLAYERS][4];

public Race_Loop()
{
    for(new opos = 0; opos < 3; opos++)
	{
	    if(Race_Top3_Positions[opos] != INVALID_PLAYER_ID && Race_Top3_Positions_Finished[opos] == 0)
	    {
	        Race_Top3_Positions[opos] = INVALID_PLAYER_ID;
	    }
	}
	new racePos[MAX_PLAYERS][E_RACE_POS];
	foreach (Player, playerid)
	{
	    if(PlayerInfo[playerid][pSpawned] == 0) continue;
	    if(CP_Progress[playerid] == Total_Race_Checkpoints) continue;
		new pos = 0, cp = CP_Progress[playerid], lap = Race_Current_Lap[playerid],
			Float:x, Float:y, Float:z, Float:togo;
		GetPlayerPos(playerid, x, y, z);
		x -= Race_Checkpoints[cp][0];
		y -= Race_Checkpoints[cp][1];
		z -= Race_Checkpoints[cp][2];
		togo = ((x * x) + (y * y) + (z * z)) ^ 0.5;
		racePos[playerid][E_RACE_POS_LAP] = lap;
		racePos[playerid][E_RACE_POS_CP] = cp;
		racePos[playerid][E_RACE_POS_TOGO] = togo;
		foreach (Player, p)
		{
		    if (playerid == p) continue;
		    racePos[p][E_RACE_POS_LAP] = Race_Current_Lap[p];
		    racePos[p][E_RACE_POS_CP] = CP_Progress[p];

		    GetPlayerPos(p, x, y, z);
		    x -= Race_Checkpoints[CP_Progress[p]][0];
			y -= Race_Checkpoints[CP_Progress[p]][1];
			z -= Race_Checkpoints[CP_Progress[p]][2];
		    racePos[p][E_RACE_POS_TOGO] = ((x * x) + (y * y) + (z * z)) ^ 0.5;

			if(racePos[p][E_RACE_POS_LAP] > lap)
			{
			    pos++;
			    continue;
			}
			if(racePos[p][E_RACE_POS_CP] > cp)
			{
			    pos++;
			    continue;
			}
			if(racePos[p][E_RACE_POS_CP] == cp && racePos[p][E_RACE_POS_TOGO] < togo)
			{
			    pos++;
			    //SendClientMessageFormatted(playerid, -1, "pos++ (%d) - p: %s(%d) is ahead", pos, Playername(p), p);
			    //SendClientMessageFormatted(playerid, -1, "%s Conditions - lap: %d - cp: %d - togo: %0.2f  VS  ME - lap: %d - cp: %d - togo: %0.2f",
				//Playername(p), racePos[p][E_RACE_POS_LAP], racePos[p][E_RACE_POS_CP], racePos[p][E_RACE_POS_TOGO], lap, cp, togo);
			}
			//else racePos[p][E_RACE_POS_POS]++;
		}
		racePos[playerid][E_RACE_POS_POS] = pos;
		//SendClientMessageFormatted(playerid, -1, "final pos (%d)", pos);
		++racePos[playerid][E_RACE_POS_POS];
	}
	foreach (Player, playerid)
	{
	    if(PlayerInfo[playerid][pSpawned] == 0) continue;
	    if(CP_Progress[playerid] == Total_Race_Checkpoints) continue;
	    /*racePos[playerid][E_RACE_POS_POS] ++ ;*/
	    Race_Old_Position[playerid] = Race_Position[playerid];
		Race_Position[playerid] = racePos[playerid][E_RACE_POS_POS];
		if(Race_Position[playerid] != Race_Old_Position[playerid])
		{
		    SendClientMessageFormatted(playerid, -1, "Your new Position: %d", Race_Position[playerid]);
		    new text[4];
		    format(text, sizeof(text), "%d", Race_Position[playerid]);
		    PlayerVehicleRacePosition(playerid, PVRP_Update, text);
		}
		if(1 <= Race_Position[playerid] <= 3)
		{
		    Race_Top3_Positions[Race_Position[playerid] - 1] = playerid;
		}
		if(Race_Position[playerid] >= 4)
		{
		    format(GlobalString, sizeof(GlobalString), "%d   %s", Race_Position[playerid], Playername(playerid));
		    PlayerTextDrawColor(playerid, Race_Box_Text[playerid][3], 0x00FF00FF);
			PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][3], GlobalString);
			PlayerTextDrawShow(playerid, Race_Box_Text[playerid][3]);
		}
		else PlayerTextDrawHide(playerid, Race_Box_Text[playerid][3]);
	}
}

CMD:top3(playerid, params[])
{
    for(new opos = 0; opos < 3; opos++)
	{
	    if(Race_Top3_Positions[opos] != INVALID_PLAYER_ID)
	    {
	        SendClientMessageFormatted(playerid, -1, "%s - Position: %d", Playername(Race_Top3_Positions[opos]), opos + 1);
	    }
	}
    return 1;
}

CMD:position(playerid, params[])
{
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
	    case RACE: SendClientMessageFormatted(playerid, -1, "Position: %d - Old Position: %d - cp: %d", Race_Position[playerid], Race_Old_Position[playerid], CP_Progress[playerid]);
		default: SendClientMessageFormatted(playerid, -1, "Position: %d - Old Position: %d - xp: %d", p_Position[playerid], p_Old_Position[playerid], GetPlayerGamePoints(playerid));
	}
	return 1;
}

CMD:setcpprogress(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
	    case RACE:
	    {
	        CP_Progress[playerid] = strval(params);
    		SendClientMessageFormatted(playerid, -1, "CP Progress Changed To %d", CP_Progress[playerid]);
		}
		default: SendClientMessage(playerid, -1, "This gamemode does not support this command - Please use in the RACE Gamemode");
	}
	return 1;
}

CMD:hunted(playerid, params[])
{
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
	    case HUNTED:
	    {
	        if(gHunted_Player[0] == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "There is no current hunted player");
    		SendClientMessageFormatted(playerid, -1, "The Current Hunted Player Is: %s(%d)", Playername(gHunted_Player[0]), gHunted_Player[0]);
		}
		default: SendClientMessage(playerid, -1, "This gamemode does not support this command - Please use in the HUNTED Gamemode");
	}
	return 1;
}

CMD:addpickup(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new pickuptype[32], pickuptypei = -1, vehicleid = GetPlayerVehicleID(playerid),
		Float:x, Float:y, Float:z;
    if(sscanf(params, "s[32]", pickuptype))
	{
	    SendClientMessage(playerid, -1, "Usage: /addpickup [pickup type]");
	    SendClientMessage(playerid, -1, "[pickup type: health, turbo, machinegun, fire, homing, power, napalm, environmental, lightning, ricochet, stalker, remotebomb]");
        return 1;
    }
	if(strcmp(pickuptype, "health", true) == 0) pickuptypei = PICKUPTYPE_HEALTH;
	else if(strcmp(pickuptype, "turbo", true) == 0) pickuptypei = PICKUPTYPE_TURBO;
	else if(strcmp(pickuptype, "machinegun", true) == 0) pickuptypei = PICKUPTYPE_MACHINE_GUN_UPGRADE;
	else if(strcmp(pickuptype, "fire", true) == 0) pickuptypei = PICKUPTYPE_FIRE_MISSILE;
	else if(strcmp(pickuptype, "homing", true) == 0) pickuptypei = PICKUPTYPE_HOMING_MISSILE;
	else if(strcmp(pickuptype, "power", true) == 0) pickuptypei = PICKUPTYPE_POWER_MISSILE;
	else if(strcmp(pickuptype, "napalm", true) == 0) pickuptypei = PICKUPTYPE_NAPALM_MISSILE;
	else if(strcmp(pickuptype, "environmental", true) == 0) pickuptypei = PICKUPTYPE_ENVIRONMENTALS;
	else if(strcmp(pickuptype, "lightning", true) == 0) pickuptypei = PICKUPTYPE_LIGHTNING;
	else if(strcmp(pickuptype, "ricochet", true) == 0) pickuptypei = PICKUPTYPE_RICOCHETS_MISSILE;
	else if(strcmp(pickuptype, "stalker", true) == 0) pickuptypei = PICKUPTYPE_STALKER_MISSILE;
	else if(strcmp(pickuptype, "remotebomb", true) == 0) pickuptypei = PICKUPTYPE_REMOTEBOMBS;
    switch(vehicleid)
    {
        case 0: GetPlayerPos(playerid, x, y, z);
        default:
        {
            GetVehiclePos(vehicleid, x, y, z);
        }
    }
    AddMapPickup(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], pickuptypei, x, y, z);
    CreatePickupEx(14, x, y, z, 0, pickuptypei);
    SendClientMessageFormatted(playerid, -1, ""#cSAMPRed"Pickup Added: "#cNiceBlue"%s "#cWhite"Placed at your position", pickuptype);
    format(GlobalQuery, sizeof(GlobalQuery), "INSERT INTO `Maps_Pickups` (`MapName`, `Mapid`, `Pickup_Type`, `x`, `y`, `z`) VALUES ('%s', %d, %d, %0.4f, %0.4f, %0.4f)", s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Name], gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], pickuptypei, x, y, z);
	mysql_function_query(McHandle, GlobalQuery, true, "Thread_NoReturnThread", "i", gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]);
	return 1;
}

CMD:deletepickup(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new mode;
    if(sscanf(params, "D(0)", mode)) return SendClientMessage(playerid, -1, "Usage: /deletepickup [mode off / on (0 / 1)]");
    SetPVarInt(playerid, "Pickup_Deletion_Mode", mode);
    SendClientMessageFormatted(playerid, -1, "Pickup Deletion Mode: %s", (mode == 0) ? (""#cRed"OFF") : (""#cLime"ON"));
	if(mode == 1)
	{
	    SendClientMessage(playerid, -1, "Pickup Deletion Mode Activated, Enter the pickup you want to delete.");
	}
	return 1;
}

stock PlayerVehicleRacePosition(playerid, type, text[4])
{
	new vehicleid = Current_Vehicle[playerid], Float:x, Float:y, Float:z;
	switch(type)
	{
	    case PVRP_Create:
	    {
	        if(IsValidObject(Race_Object[playerid]))
	        {
	            DestroyObject(Race_Object[playerid]);
	            Race_Object[playerid] = INVALID_OBJECT_ID;
	        }
	        Race_Object[playerid] = CreateObject(19477, x, y, z, 0.0, 0.0, 0.0, 125.0);
	        GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, x, y, z);
			SetObjectMaterialText(Race_Object[playerid], text, 0, OBJECT_MATERIAL_SIZE_32x32,
			"Courier New", 48, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
			AttachObjectToVehicle(Race_Object[playerid], vehicleid, 0.0, -0.2, z, 0.0, 0.0, 90.0);
	    }
	    case PVRP_Update:
	    {
	        if(IsValidObject(Race_Object[playerid]))
	        {
	            DestroyObject(Race_Object[playerid]);
	            Race_Object[playerid] = INVALID_OBJECT_ID;
	        }
	        Race_Object[playerid] = CreateObject(19477, x, y, z, 0.0, 0.0, 0.0, 125.0);
	        GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, x, y, z);
			SetObjectMaterialText(Race_Object[playerid], text, 0, OBJECT_MATERIAL_SIZE_32x32,
			"Courier New", 48, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
			AttachObjectToVehicle(Race_Object[playerid], vehicleid, 0.0, -0.2, z, 0.0, 0.0, 90.0);
	    }
	    case PVRP_Destroy:
	    {
	        if(IsValidObject(Race_Object[playerid]))
	        {
	            DestroyObject(Race_Object[playerid]);
	            Race_Object[playerid] = INVALID_OBJECT_ID;
	        }
	    }
	}
	return 1;
}

stock SetPositionalBox(playerid, count)
{
	if(count > 4) count = 4;
    new Float:oaddy = (count > 2) ? 0.2 : 0.0;
	new Float:addy = (count > 2) ? 0.2 : 0.0;
	--count;
	PlayerTextDrawLetterSize(playerid, Race_Box_Outline[playerid], 0.0, 1.1299995 + ( 1.0 * count ) + oaddy);
	PlayerTextDrawLetterSize(playerid, Race_Box[playerid], 0.0, 0.70 + ( 1.0 * count ) + addy);
	PlayerTextDrawShow(playerid, Race_Box_Outline[playerid]);
	PlayerTextDrawShow(playerid, Race_Box[playerid]);
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
    //printf("[System: OnPlayerEnterRaceCheckpoint] - Playerid: %d", playerid);
    PlayerPlaySoundEx(playerid, 1137);
	if(CP_Progress[playerid] == Total_Race_Checkpoints - 1 && Race_Current_Lap[playerid] < Total_Race_Laps)
	{
	    CP_Progress[playerid] = s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Max_Grids];
	    Race_Current_Lap[playerid]++;
		SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
	}
	else if(CP_Progress[playerid] == Total_Race_Checkpoints - 1 && Race_Current_Lap[playerid] == Total_Race_Laps)
	{
		new Position = Race_Position[playerid];
		DisablePlayerRaceCheckpoint(playerid);
		CP_Progress[playerid] = Total_Race_Checkpoints;
		SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "Race: %s(%d) Finished The Race In %d%s Position", Playername(playerid), playerid, Position, returnOrdinal(Position));
		if(1 <= Position <= 3)
		{
		    Race_Top3_Positions_Finished[Race_Position[playerid] - 1] = 1;
		}
    }
	else
	{
		CP_Progress[playerid]++;
		SetCP(playerid, CP_Progress[playerid], (CP_Progress[playerid] + 1), Total_Race_Checkpoints, RaceType);
	}
	return 1;
}

stock returnOrdinal(number)
{
    new ordinal[4][3] = { "st", "nd", "rd", "th" } ;
    number = number < 0 ? -number : number;
    return (((10 < (number % 100) < 14)) ? ordinal[3] : (0 < (number % 10) < 4) ? ordinal[((number % 10) - 1)] : ordinal[3]);
}

public SetCP(playerid, PrevCP, NextCP, MaxCP, rType)
{
	//DisablePlayerRaceCheckpoint(playerid);
	if(rType == 0)
	{
		if(NextCP == MaxCP) SetPlayerRaceCheckpoint(playerid, 1, Race_Checkpoints[PrevCP][0], Race_Checkpoints[PrevCP][1], Race_Checkpoints[PrevCP][2], Race_Checkpoints[NextCP][0], Race_Checkpoints[NextCP][1], Race_Checkpoints[NextCP][2], RACE_CHECKPOINT_SIZE);
			else SetPlayerRaceCheckpoint(playerid, 0, Race_Checkpoints[PrevCP][0], Race_Checkpoints[PrevCP][1], Race_Checkpoints[PrevCP][2], Race_Checkpoints[NextCP][0], Race_Checkpoints[NextCP][1], Race_Checkpoints[NextCP][2], RACE_CHECKPOINT_SIZE);
	}
	else if(rType == 3)
	{
		if(NextCP == MaxCP) SetPlayerRaceCheckpoint(playerid, 4, Race_Checkpoints[PrevCP][0], Race_Checkpoints[PrevCP][1], Race_Checkpoints[PrevCP][2], Race_Checkpoints[NextCP][0], Race_Checkpoints[NextCP][1], Race_Checkpoints[NextCP][2], RACE_CHECKPOINT_SIZE);
			else SetPlayerRaceCheckpoint(playerid, 3, Race_Checkpoints[PrevCP][0], Race_Checkpoints[PrevCP][1], Race_Checkpoints[PrevCP][2], Race_Checkpoints[NextCP][0], Race_Checkpoints[NextCP][1], Race_Checkpoints[NextCP][2], RACE_CHECKPOINT_SIZE);
	}
	return 1;
}
public Pickup_Update()
{
    new pid = -1, iter, Float:distance, Float:maxdist = 25.0;
	foreach(Player, playerid)
	{
	    if(PlayerInfo[playerid][pSpawned] == 0) continue;
		for(iter = 0; iter < sizeof(PickupSlots); iter++)
		{
		    if(PickupSlots[iter] != 1) continue;
		    if(PickupInfo[iter][Created] == false) continue;
		    distance = GetPlayerDistanceFromPoint(playerid, PickupInfo[iter][PickupX],
				PickupInfo[iter][PickupY], PickupInfo[iter][PickupZ]);
	        if(distance < maxdist)
		    {
		        pid = iter;
		    	maxdist = distance;
		    }
		}
		if(pid != -1)
		{
			SetPlayerCheckpoint(playerid, PickupInfo[pid][PickupX], PickupInfo[pid][PickupY],
				PickupInfo[pid][PickupZ], 1.7);
 			SetPVarInt(playerid, "pClosest_Pickup", pid);
 		}
 		else if(GetPVarType(playerid, "pClosest_Pickup"))
 		{
 		    DeletePVar(playerid, "pClosest_Pickup");
 		    DisablePlayerCheckpoint(playerid);
 		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if(GetPVarType(playerid, "pClosest_Pickup"))
    {
        new iter_pickup = GetPVarInt(playerid, "pClosest_Pickup");
		if(PickupInfo[iter_pickup][Created] == true)
		{
			DisablePlayerCheckpoint(playerid);
			OnPlayerPickUpPickup(playerid, PickupInfo[iter_pickup][Pickupid]);
		}
	}
	return 1;
}

SelectTeams(playerid)
{
    TextDrawShowForPlayer(playerid, Team_Info[TEAM_CLOWNS][TI_Textdraw]);
    TextDrawShowForPlayer(playerid, Team_Info[TEAM_CLOWNS][TI_Textdraw_N]);
    TextDrawShowForPlayer(playerid, Team_Info[TEAM_DOLLS][TI_Textdraw]);
    TextDrawShowForPlayer(playerid, Team_Info[TEAM_DOLLS][TI_Textdraw_N]);
 	SelectTextDraw(playerid, 0xFFD700FF);
 	SetPVarInt(playerid, "pSelecting_Team", 1);
 	return 1;
}

HideAllTeams(playerid, bool:cancel = true)
{
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pTeam_Sprite]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pRival_Team_Sprite]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pTeam_Score]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pRival_Team_Score]);
    PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pTeam_Sprite]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pRival_Team_Sprite]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pTeam_Score]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pRival_Team_Score]);
	TextDrawHideForPlayer(playerid, Team_Info[TEAM_CLOWNS][TI_Textdraw]);
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_CLOWNS][TI_Textdraw_N]);
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_DOLLS][TI_Textdraw]);
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_DOLLS][TI_Textdraw_N]);
    pTextInfo[playerid][pTeam_Sprite] = INVALID_PLAYER_TEXT_DRAW;
    pTextInfo[playerid][pRival_Team_Sprite] = INVALID_PLAYER_TEXT_DRAW;
    pTextInfo[playerid][pTeam_Score] = INVALID_PLAYER_TEXT_DRAW;
    pTextInfo[playerid][pRival_Team_Score] = INVALID_PLAYER_TEXT_DRAW;
    if(cancel == true)
    {
    	CancelSelectTextDraw(playerid);
    }
   	SetPVarInt(playerid, "pSelecting_Team", 0);
	return 1;
}

public OnMapBegin(gameid, gamemode, mapid)
{
    gGameData[gameid][g_Map_id] = mapid;
    gGameData[gameid][g_Gamemode_Countdown_Time] = iGamemode_CountDownMaxTime;
    LoadMapData(MAP_DATA_OBJECTS, mapid);
	LoadMapData(MAP_DATA_PICKUPS, mapid);
	printf("[System: OnMapBegin] - Gameid: %d - Gamemode: %s(%d) - Map: %s(%d)", gameid, s_Gamemodes[gamemode][GM_Name], gamemode, s_Maps[mapid][m_Name], mapid);
    switch(gamemode)
    {
        case TEAM_LAST_MAN_STANDING: gGameData[gameid][g_Gamemode_Time] = iGamemode_MaxTime + (2 * 60);
        default: gGameData[gameid][g_Gamemode_Time] = iGamemode_MaxTime;
    }
    for(new i = 0; i < MAX_TEAMS; i++)
    {
        gTeam_Player_Count[i] = 0;
        gTeam_Lives[i] = 0;
    }
	switch(gamemode)
	{
	    case DEATHMATCH: {}
	    case HUNTED: {}
	    case LAST_MAN_STANDING: {}
	    case TEAM_DEATHMATCH, TEAM_HUNTED, TEAM_LAST_MAN_STANDING:
		{
		    foreach(Player, i)
		    {
		        PlayerInfo[i][gTeam] = INVALID_GAME_TEAM;
		        PlayerInfo[i][gRival_Team] = INVALID_GAME_TEAM;
                SelectTeams(i);
				SendClientMessage(i, -1, "Select A Team Before The Game Begins!");
		    }
		}
	    case RACE:
		{
		    Total_Race_Checkpoints = 0;
 			Total_Race_Laps = 1;
 			RaceType = 0;
 			r_Index = 0;
 			for(new pc = 0; pc < sizeof(PlayersCount); pc++)
 			{
				PlayersCount[pc] = 0;
			}
			for(new r = 0, size = sizeof(Race_Sandstorm); r < size; r++)
			{
			    Race_Checkpoints[r][0] = Race_Sandstorm[r][0];
			    Race_Checkpoints[r][1] = Race_Sandstorm[r][1];
			    Race_Checkpoints[r][2] = Race_Sandstorm[r][2];
			}
			Total_Race_Checkpoints = sizeof(Race_Sandstorm);
		    RaceVehCoords[0][0] = Race_Checkpoints[0][0];
		    RaceVehCoords[0][1] = Race_Checkpoints[0][1];
		    RaceVehCoords[0][2] = Race_Checkpoints[0][2];
			RaceVehCoords[1][0] = Race_Checkpoints[1][0];
		    RaceVehCoords[1][1] = Race_Checkpoints[1][1];
		    RaceVehCoords[1][2] = Race_Checkpoints[1][2];
		    RaceVehCoords[2][0] = Race_Checkpoints[2][0];
		    RaceVehCoords[2][1] = Race_Checkpoints[2][1];
		    RaceVehCoords[2][2] = Race_Checkpoints[2][2];
		    RaceVehCoords[0][3] = Angle2D(Race_Checkpoints[s_Maps[mapid][m_Max_Grids]][0],
									Race_Checkpoints[s_Maps[mapid][m_Max_Grids]][1],
			 					Race_Checkpoints[s_Maps[mapid][m_Max_Grids] + 1][0],
							 	Race_Checkpoints[s_Maps[mapid][m_Max_Grids] + 1][1] );
    		MPClamp360(RaceVehCoords[0][3]);
    		RaceVehCoords[1][3] = RaceVehCoords[0][3];
    		RaceVehCoords[2][3] = RaceVehCoords[0][3];

		    for(new i = 0; i < MAX_PLAYERS; i++)
		    {
		        CP_Progress[i] = s_Maps[mapid][m_Max_Grids];
	    		Race_Current_Lap[i] = 1;
				Race_Position[i] = 0;
				Race_Old_Position[i] = 0;
				p_Position[i] = 0;
				p_Old_Position[i] = 0;
				SetCP(i, CP_Progress[i], CP_Progress[i] + 1, Total_Race_Checkpoints, RaceType);
		    }
		    for(new opos = 0; opos < 3; opos++)
			{
			    if(Race_Top3_Positions[opos] != INVALID_PLAYER_ID)
			    {
			        Race_Top3_Positions[opos] = INVALID_PLAYER_ID;
			    }
			    if(Race_Top3_Positions_Finished[opos] != 0)
			    {
			        Race_Top3_Positions_Finished[opos] = 0;
			    }
			}
		    Race_Loop();
		    //deathmatch surprise, "RACE BATTLE" kill all opponents to win
		}
	}
	switch(gamemode)
	{
	    //case RACE:{}
	    case DEATHMATCH,
		TEAM_DEATHMATCH,
		HUNTED,
		TEAM_HUNTED,
		LAST_MAN_STANDING,
		TEAM_LAST_MAN_STANDING:
		{
			for(new m = 0, mp = sizeof(m_Map_Positions); m < mp; m++)
			{
			    if( m_Map_Positions[m][m_Mapid] != mapid ) continue;
			    m_Map_Objects[m] = CreateObject(m_Map_Positions[m][m_Model], m_Map_Positions[m][m_X], m_Map_Positions[m][m_Y], m_Map_Positions[m][m_Z], m_Map_Positions[m][m_rX], m_Map_Positions[m][m_rY], m_Map_Positions[m][m_rZ], m_Map_Positions[m][m_DrawDistance]);
			}
			for(new p = 0, mp = sizeof(Maps_PickupInfo); p < mp; p++)
			{
			    if( Maps_PickupInfo[p][PI_Mapid] != mapid ) continue;
			    CreatePickupEx(14, Maps_PickupInfo[p][PI_pX], Maps_PickupInfo[p][PI_pY], Maps_PickupInfo[p][PI_pZ], 0, Maps_PickupInfo[p][PI_Pickuptype]);
			}
			for(new i = 0; i < MAX_LIFTS; i++)
			{
			    if(IsValidObject(MovingLifts[i]))
				{
					DestroyObject(MovingLifts[i]);
					MovingLifts[i] = INVALID_OBJECT_ID;
				}
			    if( MovingLiftArray[i][L_Mapid] != mapid ) continue;
				MovingLifts[i] = CreateObject(MovingLiftArray[i][L_Objectid], MovingLiftArray[i][L_X], MovingLiftArray[i][L_Y], MovingLiftArray[i][L_Z], MovingLiftArray[i][L_RX], MovingLiftArray[i][L_RY], MovingLiftArray[i][L_RZ]);
				MovingLiftPickup[i] = CreatePickup(1247, 14, MovingLiftArray[i][L_X], MovingLiftArray[i][L_Y], MovingLiftArray[i][L_Z] - 0.6);
				MovingLiftStatus[i] = 0;
				gGameData[gameid][g_Has_Moving_Lift] = true;
			}
			switch(mapid)
			{
			    case MAP_DOWNTOWN:
			    {
			        if(IsValidObject(HelicopterAttack))
					{
						DestroyObject(HelicopterAttack);
                        HelicopterAttack = INVALID_OBJECT_ID;
					}
			    	HelicopterAttack = CreateObject(10757, -2025, -860, 50.0, 22, 11, 180, 150.0);//x, y, z, rx, ry, rz
				}
				case MAP_SUBURBS: SetTimer("RotateWheel", 3 * 1000, false);
			}
		}
    }
    foreach(Player, playerid)
    {
        PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], "0");
		PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
        HideKillStreak(playerid);
    }
    for(new playerid = 0; playerid < MAX_PLAYERS; playerid++)
	{
	    PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 0;
		pFirstTimeViewingMap[playerid] = 1;
		PlayerInfo[playerid][pKillStreaking] = -1;
	}
	new str[64];
	format(str, sizeof(str), "map %s", s_Maps[mapid][m_Name]);
	SendRconCommand(str);
	TextDrawSetString(gGameData[gameid][g_Lobby_gState], "COUNTDOWN");
	switch(gamemode)
	{
	    case LAST_MAN_STANDING: format(GlobalString, sizeof(GlobalString), "Last Man~n~Standing");
	    case TEAM_DEATHMATCH: format(GlobalString, sizeof(GlobalString), "Team~n~Deathmatch");
	    //case TEAM_LAST_MAN_STANDING: format(GlobalString, sizeof(GlobalString), "Team Last~n~Man Standing");
	    default: format(GlobalString, sizeof(GlobalString), "%s", s_Gamemodes[gamemode][GM_Name]);
	}
	UpdateLobbyTD(gGameData[gameid][g_Lobby_Type], GlobalString);
	UpdateLobbyTD(gGameData[gameid][g_Lobby_Map], s_Maps[mapid]);
	return 1;
}
#define MAP_GAMEMODE_DIALOG 3200
#define MAP_VOTE_DIALOG 3201
#define VOTE_ID_GAMEMODE 0
#define VOTE_ID_MAP 1

public OnMapFinish(gameid, gamemode, mapid)
{
    printf("[System: OnMapFinish] - Gameid: %d - Gamemode: %s(%d) - Map: %s(%d)", gameid, s_Gamemodes[gamemode][GM_Name], gamemode, s_Maps[mapid][m_Name], mapid);
	switch(gamemode)
	{
	    case DEATHMATCH, HUNTED:
	    {
	        new winnerid = INVALID_PLAYER_ID, winnerscore = 0, score = 0, bool:drawn = false;
			foreach(Player, playerid)
			{
			    score = GetPlayerGamePoints(playerid);
		        if(score > winnerscore)
		        {
		            winnerid = playerid;
		            winnerscore = score;
		            drawn = false;
		        }
		        else if(score == winnerscore) drawn = true;
			}
			if(drawn == false)
			{
				if(winnerid != INVALID_PLAYER_ID)
				{
				    PlayerPlaySoundEx(winnerid, 5448); // "You Win!"
				    foreach(Player, i)
				    {
        				if(PlayerInfo[i][gGameID] != gameid) continue;
				        SendClientMessageFormatted(i, GOLD, "%s(%d) "#cWhite"Has Won The Deathmatch Game", Playername(winnerid), winnerid);
				        if(winnerid == i) continue;
				        PlayerPlaySoundEx(i, 7023); // "Loser!"
				    }
				}
				else
				{
				    foreach(Player, i)
				    {
				        if(PlayerInfo[i][gGameID] != gameid) continue;
				        PlayerPlaySoundEx(i, 7023); // "Loser!"
				        SendClientMessage(i, GOLD, "The Game Has Been Drawn With No Winners");
				    }
				}
			}
			else
			{
			    foreach(Player, i)
			    {
	    			if(PlayerInfo[i][gGameID] != gameid) continue;
			        PlayerPlaySoundEx(i, 7023); // "Loser!"
			        SendClientMessage(i, GOLD, "The Game Has Been Drawn With No Winners");
			    }
			}
			gHunted_Player[0] = INVALID_PLAYER_ID;
		}
		case LAST_MAN_STANDING:
		{
		    new g_Winnerid = INVALID_PLAYER_ID, drawn = 0;
		    foreach(Player, i)
		    {
		        if(PlayerInfo[i][pSpawned] == 1) continue;
		        if(g_Winnerid != INVALID_PLAYER_ID)
		        {
		            g_Winnerid = INVALID_PLAYER_ID;
		            drawn = 1;
		            break;
		        }
		        g_Winnerid = i;
		    }
		    if(g_Winnerid == INVALID_PLAYER_ID || drawn == 1) // drawn
	        {
			    foreach(Player, i)
				{
	    			if(PlayerInfo[i][gGameID] != gameid) continue;
			    	SendClientMessage(i, GOLD, "The Game Has Been Drawn With No Winners");
			    	PlayerPlaySoundEx(i, 7023); // "Loser!"
				}
	        }
	        else
	        {
	            PlayerPlaySoundEx(g_Winnerid, 5448); // "You Win!"
	            foreach(Player, i)
			    {
	    			if(PlayerInfo[i][gGameID] != gameid) continue;
	    			SendClientMessageFormatted(i, GOLD, "%s(%d) "#cWhite"Has Won The Deathmatch Game", Playername(g_Winnerid), g_Winnerid);
			        if(g_Winnerid == i) continue;
			        PlayerPlaySoundEx(i, 7023); // "Loser!"
			    }
	        }
		}
		case RACE:
		{
		    TemporaryRaceQuitList(.playerid = INVALID_PLAYER_ID, .action = 2);
			if(Race_Top3_Positions[0] != INVALID_PLAYER_ID)
			{
			    PlayerPlaySound(Race_Top3_Positions[0], 5448, 0.0, 0.0, 0.0); // "You win!"
			    foreach(Player, i)
			    {
	    			if(PlayerInfo[i][gGameID] != gameid) continue;
			    	SendClientMessageFormatted(i, GOLD, "%s(%d) "#cWhite"Has Won The Race", Playername(Race_Top3_Positions[0]), Race_Top3_Positions[0]);
				}
			}
		}
		case TEAM_DEATHMATCH, TEAM_HUNTED, TEAM_LAST_MAN_STANDING:
		{
		    new winnerteamid = -1, winnerscore = 0, bool:drawn = false, loserteamid;
		    for(new ti = 0; ti < sizeof(Team_Info); ti++)
			{
			    if(gGameData[gameid][g_Gamemode] == TEAM_LAST_MAN_STANDING)
			    {
			        Team_Info[ti][TI_Score] = gTeam_Lives[ti];
			    }
		    	if(Team_Info[ti][TI_Score] > winnerscore)
		    	{
		    	    winnerteamid = ti;
		    	    winnerscore = Team_Info[ti][TI_Score];
		    	    if(drawn != false)
		    	    {
		    	        drawn = false;
		    	    }
		    	}
		    	else if(Team_Info[ti][TI_Score] == winnerscore) drawn = true;
			}
			if(winnerteamid == TEAM_CLOWNS)
			{
			    loserteamid = TEAM_DOLLS;
			}
			else if(winnerteamid == TEAM_DOLLS) loserteamid = TEAM_CLOWNS;
			if(drawn == true)
			{
			    foreach(Player, i)
				{
	    			if(PlayerInfo[i][gGameID] != gameid) continue;
			    	SendClientMessage(i, GOLD, "The Game Has Drawn!");
				}
			}
			else
			{
			    if(gGameData[gameid][g_Gamemode] == TEAM_LAST_MAN_STANDING)
			    {
			    	format(GlobalString, sizeof(GlobalString), "Your Team Loses!");
				}
				else format(GlobalString, sizeof(GlobalString), "Your Team Loses! (%d To %d)", Team_Info[winnerteamid][TI_Score], Team_Info[loserteamid][TI_Score]);
				foreach(Player, i)
			    {
			        if(PlayerInfo[i][gTeam] == winnerteamid)
			        {
			        	TimeTextForPlayer( TIMETEXT_MIDDLE_SUPER_LARGE, i, "Your Team Wins!", 3000, PLAYER_TEAM_COLOUR );
					}
					else TimeTextForPlayer( TIMETEXT_MIDDLE_SUPER_LARGE, i, GlobalString, 3000, RIVAL_TEAM_COLOUR );
				}
			    SendClientMessageFormatted(INVALID_PLAYER_ID, GOLD, "%s "#cWhite"Has Won!", Team_Info[winnerteamid][TI_Team_Name]);
			}
		}
	}
	foreach(Player, i)
	{
	    if(GetPVarType(i, "pRegistration_Tutorial")) continue;
	    if(PlayerInfo[i][gGameID] != gameid) continue;
	    TogglePlayerSpectating(i, false);
	    PlayerInfo[i][pLast_Exp_Gained] = PlayerInfo[i][g_pExprience];
	    ToggleAccountSavingVar(i, ACCOUNT_UPDATE_LAST_EXPRIENCE);
	    PlayerInfo[i][g_pExprience] = 0;
	    SendClientMessageFormatted(i, -1, ""#cTeal"Exprience Gained: "#cWhite"%d", PlayerInfo[i][pLast_Exp_Gained]);
	    SendClientMessageFormatted(i, -1, ""#cTeal"New Exprience: "#cWhite"%d", PlayerInfo[i][pExprience]);
	    ResetPlayerGamePoints(i);
	    HideAllTeams(i);
	    for(new rb = 0; rb < 4; rb++)
		{
		    PlayerTextDrawHide(i, Race_Box_Text[i][rb]);
		}
		PlayerTextDrawHide(i, Race_Box_Outline[i]);
		PlayerTextDrawHide(i, Race_Box[i]);
		PlayerTextDrawHide(i, pTextInfo[i][AimingBox]);
		PlayerTextDrawHide(i, pTextInfo[i][AimingPlayer]);
		PlayerTextDrawHide(i, pTextInfo[i][Mega_Gun_IDX]);
		PlayerTextDrawHide(i, pTextInfo[i][Mega_Gun_Sprite]);
		PlayerInfo[i][gTeam] = INVALID_GAME_TEAM;
		PlayerInfo[i][gRival_Team] = INVALID_GAME_TEAM;
		pSpectate_Random_Teammate[i] = 0;
		KillTimer(Special_Missile_Timer[i]);
  		PlayerInfo[i][pMissile_Special_Time] = 0;
  		PlayerInfo[i][pMissile_Charged] = Missile_Special;
  		if(IsValidObject(Race_Object[i]))
        {
            DestroyObject(Race_Object[i]);
            Race_Object[i] = INVALID_OBJECT_ID;
        }
	    if(PlayerInfo[i][pSpawned] == 0) continue;
	    SetPlayerHealth(i, -1);
	    ForceClassSelection(i);
	    TogglePlayerSpectating(i, true);
    	TogglePlayerSpectating(i, false);
	    PlayerInfo[i][pSpawned] = 0;
	    HidePlayerHUD(i);
	}
    for(new m = 0, mo = sizeof(m_Map_Objects); m < mo; m++)
	{
	    if(IsValidObject(m_Map_Objects[m]))
	    {
	    	DestroyObject(m_Map_Objects[m]);
	    	m_Map_Objects[m] = INVALID_OBJECT_ID;
	    }
	}
	gGameData[gameid][g_Has_Moving_Lift] = false;
	for(new i = 0; i < MAX_LIFTS; i++)
	{
	    if(IsValidObject(MovingLifts[i]))
		{
			DestroyObject(MovingLifts[i]);
			MovingLifts[i] = INVALID_OBJECT_ID;
		}
	}
	for(new p = 0, pm = sizeof(PickupInfo); p < pm; p++)
	{
	    if(PickupInfo[p][Pickupid] == -1) continue;
	    DestroyPickupEx(p);
	}
	switch(mapid)
	{
	    case MAP_DOWNTOWN:
	    {
	        if(IsValidObject(HelicopterAttack))
			{
				DestroyObject(HelicopterAttack);
				HelicopterAttack = INVALID_OBJECT_ID;
			}
		}
	}
	TextDrawSetString(gGameData[gameid][g_Lobby_gState], "GAME ENDING");
	TextDrawSetString(gGameData[gameid][g_Lobby_Type], "BEING SELECTED");
	TextDrawSetString(gGameData[gameid][g_Lobby_Map], "BEING SELECTED");
	gGameData[gameid][g_Voting_Time] = 1;
	gGameData[gameid][g_Gamemode_Time] = 6;
	mapid = (MAX_MAPS + 1);
	SetTimerEx("StartVoting", 7500, false, "i", gameid);
	return 1;
}

forward StartVoting(gameid);
public StartVoting(gameid)
{
	GlobalString = "\0";
	for(new g = 0, gm = sizeof(s_Gamemodes); g < gm; g++)
	{
	    strcat(GlobalString, s_Gamemodes[g][GM_Name]);
	    strcat(GlobalString, "\n");
	}
	foreach(Player, playerid)
	{
	    if(PlayerInfo[playerid][gGameID] != gameid) continue;
	    SendClientMessage(playerid, -1, "Gamemode Voting Has Began! - Cast Your Votes");
		ShowPlayerDialog(playerid, MAP_GAMEMODE_DIALOG, DIALOG_STYLE_LIST, "Vote For The Next "#cYellow"Gamemode "#cWhite"Type", GlobalString, "Proceed", "");
	}
	SetTimerEx("EndVotingTime", 20000, false, "ii", VOTE_ID_GAMEMODE, gameid);
	gGameData[gameid][g_Gamemode_Time] = 18;
	TextDrawSetString(gGameData[gameid][g_Lobby_gState], "MODE VOTING");
	return 1;
}

forward EndVotingTime(voteid, gameid);
public EndVotingTime(voteid, gameid)
{
	if(gameid == INVALID_GAME_ID) return printf("[System Error: EndVotingTime] - voteid: %d - gameid: %d", voteid, gameid);
	switch(voteid)
	{
	    case VOTE_ID_GAMEMODE:
	    {
			new highest = -1, VoteListIndex;
			for(new g = 0, gm = sizeof(s_Gamemodes); g < gm; g++)
			{
			    if(gmVotes[g] > highest)
				{
					highest = g;
				}
			    gmVotes[g] = 0;
			}
			if(highest == -1)
			{
			    highest = random(MAX_GAMEMODES);
			}
			gGameData[gameid][g_Gamemode] = highest;
			TextDrawSetString(gGameData[gameid][g_Lobby_Type], s_Gamemodes[gGameData[gameid][g_Gamemode]][GM_Name]);
			GlobalString = "\0";
			for(new m = 0, gm = sizeof(s_Maps); m < gm; m++)
			{
			    if(-1 <= s_Maps[m][m_ID] <= 0) continue;
			    if(Iter_Count(Map_Selection[gameid]) >= MAX_MAP_SELECTION
					|| VoteListIndex >= MAX_MAP_SELECTION) continue;
			    switch(gGameData[gameid][g_Gamemode])
			    {
			        case RACE: if(s_Maps[m][m_Type] != MAP_TYPE_RACE) continue;
			        default: if(s_Maps[m][m_Type] == MAP_TYPE_RACE) continue;
			    }
			    gGameData[gameid][VoteList][VoteListIndex] = m;
			    strcat(GlobalString, s_Maps[m][m_Name]);
			    strcat(GlobalString, "\n");
			    ++VoteListIndex;
			    if(!Iter_Contains(Map_Selection[gameid], m))
				{
					Iter_Add(Map_Selection[gameid], m);
				}
                if((m + 1) < gm)
                {
                    if(strlen(GlobalString) + strlen(s_Maps[m + 1][m_Name]) > sizeof(GlobalString)) break;
                }
			}
			gGameData[gameid][g_Voting_Time] = 2;
			foreach(Player, playerid)
			{
			    if(PlayerInfo[playerid][gGameID] != gameid) continue;
			    SendClientMessage(playerid, -1, "Gamemode Voting Time Has "#cSAMP"Expired!");
			    SendClientMessage(playerid, -1, "Beginning Map Vote - Cast Your Vote For The Best Map!");
			    SendClientMessageFormatted(playerid, -1, "The Next Mode Will Be "#cYellow"%s", s_Gamemodes[gGameData[gameid][g_Gamemode]][GM_Name]);
				ShowPlayerDialog(playerid, MAP_VOTE_DIALOG, DIALOG_STYLE_LIST, "Vote For The Next "#cBlue"Map", GlobalString, "Proceed", "");
			}
			SetTimerEx("EndVotingTime", 15000, false, "ii", VOTE_ID_MAP, gameid);
			gGameData[gameid][g_Gamemode_Time] = 14;
			gGameData[gameid][g_Gamemode_Countdown_Time] = 0;
			TextDrawSetString(gGameData[gameid][g_Lobby_gState], "MAP VOTING");
		}
		case VOTE_ID_MAP:
		{
		    gGameData[gameid][g_Voting_Time] = 0;
			new newmap = -1, maxvotes = 0;
			foreach(Map_Selection[gameid], m)
			{
			    if(gGameData[gameid][mVotes][m] > maxvotes)
				{
					newmap = m;
					maxvotes = gGameData[gameid][mVotes][m];
				}
			    gGameData[gameid][mVotes][m] = 0;
			}
			if(newmap == -1)
			{
			    newmap = Iter_Random(Map_Selection[gameid]);
			    foreach(Player, playerid)
				{
				    if(PlayerInfo[playerid][gGameID] != gameid) continue;
			    	SendClientMessage(playerid, -1, "Noone Voted - Random Map Assigned");
			    }
			}
			gGameData[gameid][g_Map_id] = newmap;
			gGameData[gameid][g_Gamemode_Time] = 2;
			foreach(Player, playerid)
			{
			    if(PlayerInfo[playerid][gGameID] != gameid) continue;
			    SendClientMessage(playerid, -1, "Map Voting Time Has "#cSAMP"Expired!");
			    SendClientMessageFormatted(playerid, -1, "The Next Map Will Be "#cBlue"%s(%d)", s_Maps[gGameData[gameid][g_Map_id]][m_Name], gGameData[gameid][g_Map_id]);
			}
			SetTimerEx("OnMapBegin", 5, false, "iii", gameid, gGameData[gameid][g_Gamemode], gGameData[gameid][g_Map_id]);
			Iter_Clear(Map_Selection[gameid]);
			TextDrawSetString(gGameData[gameid][g_Lobby_gState], "MAP LOADING");
			TextDrawSetString(gGameData[gameid][g_Lobby_Map], "NONE SELECTED");
		}
	}
	return 1;
}

CMD:setgtime(playerid, params[])
{
	new time;
	if(sscanf(params, "d", time)) return 1;
   	gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Time] = time;
	return 1;
}
CMD:setgctime(playerid, params[])
{
	new time;
	if(sscanf(params, "d", time)) return 1;
   	gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Countdown_Time] = time;
	return 1;
}
#define DIALOG_TUTORIAL 500
#define DIALOG_TUTORIAL_HUD 501
#define DIALOG_TUTORIAL_GAMEMODES 502
#define DIALOG_TUTORIAL_WEAPONS 503
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_TUTORIAL:
	    {
	        switch(response)
	        {
	            case 0:
	            {
	                return 1;
	            }
	            default:
	            {
	                new tutorial[1024 + 256];
		        	++listitem;
			        switch(listitem)
			        {
			            case 1:
			            {
			                for(new ta = 0, tas = sizeof(Tutorial_Arrows); ta < tas; ta++)
							{
								TextDrawShowForPlayer(playerid, Tutorial_Arrows[ta]);
								TextDrawShowForPlayer(playerid, Tutorial_Numbers[ta]);
						    }
			                strcat(tutorial, ""#cBlue"1. \t"#cYellow"Online Player Count & Current Player In Line Of Sight\n");
						    strcat(tutorial, ""#cBlue"2. \t"#cYellow"Minimap\n");
							strcat(tutorial, ""#cBlue"3. \t"#cYellow"Game Level "#cWhite" - Displays Your Current Level\n");
							strcat(tutorial, ""#cBlue"4. \t"#cYellow"Exprience Bar "#cWhite" - Shows Current Exprience Progress\n");
							strcat(tutorial, ""#cBlue"5. \t"#cYellow"Exprience Amount "#cWhite" - Shows Current Numeric Exprience\n");
							strcat(tutorial, ""#cBlue"6. \t"#cYellow"Turbo Bar "#cWhite" - Shows Current Turbo Left\n");
							strcat(tutorial, ""#cBlue"7. \t"#cYellow"Energy Bar "#cWhite" - Shows Current Energy Left\n");
							strcat(tutorial, ""#cBlue"8. \t"#cYellow"Current Weapon\n");
							strcat(tutorial, ""#cBlue"9. \t"#cYellow"Health\n");
							strcat(tutorial, ""#cBlue"10. \t"#cYellow"Game Time\n");
						    ShowPlayerDialog(playerid, DIALOG_TUTORIAL_HUD, DIALOG_STYLE_MSGBOX,
							""cSAMP"Twisted Metal SA-MP - Tutorial | HUD",
							tutorial, "Go Back", "");
						}
						case 2:
						{
				            strcat(tutorial, ""#cBlue"Deathmatch \t\t- "#cWhite"Players must fight each other in the level and score points with enemy kills.\n");
						    strcat(tutorial, ""#cBlue"Team Deathmatch \t- "#cWhite"Players must destroy as many players on the opposing team as possible before time runs out.\n");
							strcat(tutorial, ""#cBlue"Hunted \t\t\t- "#cWhite"One player is the \"Hunted\" which means that he/she will be targeted by everyone.\n\t\t\t  If a player kills the \"Hunted\", he/she gets a point but will become the \"Hunted\".\n\t\t\t  Killing another player while being the \"Hunted\" is also awarded a point.\n");
							strcat(tutorial, ""#cBlue"Team Hunted \t\t- "#cWhite"One player on each team is the \"Hunted\" which means that he/she will be targeted by\n\t\t\t  everyone on the opposing team.\n");
							strcat(tutorial, ""#cBlue"Last Man Standing \t- "#cWhite"Each player has a specific number of lives and the player will not respawn if\n\t\t\t  he/she runs out of lives and is killed.\n");
							strcat(tutorial, ""#cBlue"Team Last Man Standing - "#cWhite"Each team has a specific number of lives. The team lives are shared to everyone\n\t\t\t  in the team. If a team runs out of lives, a player of that team will not respawn if he/she is killed.\n");
							strcat(tutorial, ""#cBlue"Race \t\t\t- "#cWhite"Players must get to checkpoints and destroy anyone in their path.\n");
						    ShowPlayerDialog(playerid, DIALOG_TUTORIAL_GAMEMODES, DIALOG_STYLE_MSGBOX,
							""cSAMP"Twisted Metal SA-MP - Tutorial | The Gamemodes Explained",
							tutorial, "Go Back", "");
						}
						case 3:
						{
				            strcat(tutorial, ""#cBlue"Fire Missile \t- "#cWhite"Slight homing ability and the most common weapon - 16 pts damage\n");
						    strcat(tutorial, ""#cBlue"Homing Missile \t- "#cWhite"Strong homing ability - 12 pts damage\n");
							strcat(tutorial, ""#cBlue"Power Missile \t- "#cWhite"No homing ability but very powerful - 75 pts damage\n");
							strcat(tutorial, ""#cBlue"Stalker Missile \t- "#cWhite"Homing + Power combo missile; able to be charged for more homing capabilities - 45 pts damage\n");
							strcat(tutorial, ""#cBlue"Napalm \t- "#cWhite"Fire once to launch, fire again to drop; land a direct hit to inflict extra damage and ignite an\n\t\t  enemy on fire - 35 pts Bullseye damage, 20 Medium, 10 Far\n");
							strcat(tutorial, ""#cBlue"Remote Bomb \t- "#cWhite"Bonus damage longer you allow to sit. (Stage 1: 35 pts- Stage 2: 50 Cooked Bomb pts)\n");
							strcat(tutorial, ""#cBlue"Ricochet \t- "#cWhite"Able to be charged up, launched, and detonated much like Napalm.\n\t\t  (25 pts dmg) Bonus damage inflicted when richoched off a wall. (35 pts Bounce Bonus)\n");
							strcat(tutorial, ""#cBlue"Mega Guns \t- "#cWhite"Increased damage and fire rate to mounted guns. One pickup loads 150 shots.\n");
						    ShowPlayerDialog(playerid, DIALOG_TUTORIAL_WEAPONS, DIALOG_STYLE_MSGBOX,
							""cSAMP"Twisted Metal SA-MP - Tutorial | The Weapons Explained",
							tutorial, "Go Back", "");
						}
						case 4:
						{
				            strcat(tutorial, "Step 1:\t"#cBlue"Click Multi-Player\n");
						    strcat(tutorial, "Step 2:\t"#cBlue"Choose a Vehicle\n");
							strcat(tutorial, "Step 3:\t"#cBlue"Click Spawn\n");
							strcat(tutorial, "\nType /controls to view the server controls");
							ShowPlayerDialog(playerid, DIALOG_TUTORIAL_WEAPONS, DIALOG_STYLE_MSGBOX,
							""cSAMP"Twisted Metal SA-MP - Tutorial | The Weapons Explained",
							tutorial, "Go Back", "");
						}
					}
      			}
			}
	    }
	    case DIALOG_TUTORIAL_HUD:
	    {
	        for(new ta = 0, tas = sizeof(Tutorial_Arrows); ta < tas; ta++)
			{
				TextDrawHideForPlayer(playerid, Tutorial_Arrows[ta]);
				TextDrawHideForPlayer(playerid, Tutorial_Numbers[ta]);
		    }
	        return cmd_tutorial(playerid, "");
	    }
	    case DIALOG_TUTORIAL_GAMEMODES, DIALOG_TUTORIAL_WEAPONS:
	    {
			return cmd_tutorial(playerid, "");
	    }
	    case MAP_GAMEMODE_DIALOG:
	    {
	        if(gGameData[PlayerInfo[playerid][gGameID]][g_Voting_Time] != 1) return SendClientMessage(playerid, -1, "You Have Voted Too Late, Gamemode Voting Time Has Already Expired");
			if(strfind(s_Gamemodes[listitem][GM_Name], "Last Man Standing") != -1) // and Team LMS
			{
				if(Iter_Count(Player) < 3)
    			{
		            return SendClientMessage(playerid, -1, "This Gamemode Requires 3(+) Players To Play.");
		        }
			}
			SendClientMessageFormatted(playerid, -1, "You Have Voted For Gamemode "#cGreen"%s(%d)", s_Gamemodes[listitem][GM_Name], listitem);
			gmVotes[listitem]++;
			if(PlayerInfo[playerid][pSpawned] == 0)
			{
				TextDrawShowForPlayer(playerid, gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Time_Text]);
			}
	    }
	    case MAP_VOTE_DIALOG:
	    {
	        if(gGameData[PlayerInfo[playerid][gGameID]][g_Voting_Time] != 2) return SendClientMessage(playerid, -1, "You Have Voted Too Late, Map Voting Time Has Already Expired");
			SendClientMessageFormatted(playerid, -1, "You Have Voted For Map "#cGreen"%s(%d)", s_Maps[gGameData[PlayerInfo[playerid][gGameID]][VoteList][listitem]][m_Name], gGameData[PlayerInfo[playerid][gGameID]][VoteList][listitem]);
			gGameData[PlayerInfo[playerid][gGameID]][mVotes][gGameData[PlayerInfo[playerid][gGameID]][VoteList][listitem]]++;
	    }
	}
	if(dialogid == LoginDialog)
 	{
  		if(!response || isnull(inputtext))
  		{
      		format(GlobalString, sizeof(GlobalString), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP\n\n{FAF87F}Account: "#cWhite"%s\n\n{FF0000}Please Enter Your Password Below:", Playername(playerid));
  	 		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Login To Twisted Metal: SA-MP", GlobalString, "Login", "Cancel");
  	 		return 1;
  		}
		if(strlen(inputtext) > 20)
		{
      		format(GlobalString, sizeof(GlobalString), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP\n\n{FAF87F}Account: "#cWhite"%s\n\n{FF0000}Your Password Must Be Less Than 20 characters!", Playername(playerid));
  	 		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Login To Twisted Metal: SA-MP", GlobalString, "Login", "Cancel");
            return 1;
		}
 		new lEscape[2][MAX_PLAYER_NAME];
		mysql_real_escape_string(Playername(playerid), lEscape[0]);
		mysql_real_escape_string(inputtext, lEscape[1]);
		format(GlobalString, sizeof(GlobalString), "SELECT * FROM `Accounts` WHERE `Username` = '%s' AND `Password` = '%s' LIMIT 0,1", lEscape[0], lEscape[1]);
		mysql_function_query(McHandle, GlobalString, true, "Thread_OnUserLogin", "i", playerid);
	}
	if(dialogid == RegDialog)
 	{
        if(!response || isnull(inputtext)) //new a_Query[128 + 12];
        {
      		format(GlobalString, sizeof(GlobalString), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP: "#cWhite"%s\n\n{FF0000}Please Enter A Password Below To Register:", Playername(playerid));
  	 		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Register An Account", GlobalString, "Register", "");
            return 1;
		}
        if(strlen(inputtext) <= 3)
        {
      		format(GlobalString, sizeof(GlobalString), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP: "#cWhite"%s\n\n{FF0000}Your Password Cannot Be Less Than 4 Characters\nPlease Enter A Password 4 Or More Characters Higher To Register:", Playername(playerid));
  	 		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Register An Account", GlobalString, "Register", "");
            return 1;
		}
        if(strlen(inputtext) > 20)
        {
      		format(GlobalString, sizeof(GlobalString), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP: "#cWhite"%s\n\n{FF0000}Your Password Cannot Be More Than 20 Characters\nPlease Enter A Password 20 Or Less Characters Higher To Register:", Playername(playerid));
  	 		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Register An Account", GlobalString, "Register", "");
			return 1;
		}
    	if(IsLogged[playerid] == 1) return SendClientMessage(playerid, RED, "You are already logged in.");
    	new Query[96];
		format(Query, sizeof(Query), "SELECT `Username` FROM `Accounts` WHERE `Username` = '%s' LIMIT 0,1", Playername(playerid));
	   	mysql_function_query(McHandle, Query, false, "Thread_OnUserRegister", "is", playerid, inputtext);
	}
	return 1;
}

THREAD:NoReturnThread(extraid)
{
    return 1;
}

CMD:state(playerid, params[])
{
	SendClientMessageFormatted(playerid, -1, "Player State: %d", GetPlayerState(playerid));
	return 1;
}

THREAD:OnUserLogin(playerid)
{
    new rows, fields, result[32];
    cache_get_data(rows, fields, McHandle);
	if(rows == 1)
	{
	    IsLogged[playerid] = 1;
	    SetPVarInt(playerid, "pCanTalk", 1);
		cache_get_row(0, 0, PlayerInfo[playerid][pUsername]); //cache_get_row(0, "Username", PlayerInfo[playerid][pUsername]);
		cache_get_row(0, 1, PlayerInfo[playerid][pPassword]);
		cache_get_row(0, 2, PlayerInfo[playerid][pIP]);
		cache_get_row(0, 3, PlayerInfo[playerid][pRegistered]);
		cache_get_row(0, 4, result);
		PlayerInfo[playerid][pLastVisit] = strval(result);
		cache_get_row(0, 5, result);
		PlayerInfo[playerid][AdminLevel] = strval(result);
		cache_get_row(0, 6, result);
		PlayerInfo[playerid][pDonaterRank] = strval(result);
		cache_get_field_content(0, "Money", result);
		PlayerInfo[playerid][Money] = strval(result);
		cache_get_field_content(0, "Kills", result);
		PlayerInfo[playerid][Kills] = strval(result);
		cache_get_field_content(0, "Deaths", result);
		PlayerInfo[playerid][Deaths] = strval(result);

		cache_get_field_content(0, "Assists", result);
		PlayerInfo[playerid][Assists] = strval(result);
		cache_get_field_content(0, "pKillStreaks", result);
		PlayerInfo[playerid][pKillStreaks] = strval(result);

		cache_get_field_content(0, "pExprience", result);
		PlayerInfo[playerid][pExprience] = strval(result);
		cache_get_field_content(0, "pLast_Exp_Gained", result);
		PlayerInfo[playerid][pLast_Exp_Gained] = strval(result);
		cache_get_field_content(0, "pLevel", result);
		PlayerInfo[playerid][pLevel] = strval(result);
		cache_get_field_content(0, "pTier_Points", result);
		PlayerInfo[playerid][pTier_Points] = strval(result);
		SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);
		cache_get_field_content(0, "pTravelled_Distance", result);
		PlayerInfo[playerid][pTravelled_Distance] = floatstr(result);

		cache_get_field_content(0, "pFavourite_Vehicle", result);
		PlayerInfo[playerid][pFavourite_Vehicle] = strval(result);
		cache_get_field_content(0, "pFavourite_Map", result);
		PlayerInfo[playerid][pFavourite_Map] = strval(result);

		cache_get_field_content(0, "Seconds", result);
		PlayerInfo[playerid][LoggedSeconds] = strval(result);
		cache_get_field_content(0, "Minutes", result);
		PlayerInfo[playerid][LoggedMinutes] = strval(result);
		cache_get_field_content(0, "Hours", result);
		PlayerInfo[playerid][LoggedHours] = strval(result);
		cache_get_field_content(0, "Days", result);
		PlayerInfo[playerid][LoggedDays] = strval(result);

		format(result, sizeof(result), "Level: %d", PlayerInfo[playerid][pLevel]);
    	PlayerTextDrawSetString(playerid, pTextInfo[playerid][pLevelText], result);
    	format(result, sizeof(result), "XP: %d", PlayerInfo[playerid][pExprience]);
	    PlayerTextDrawSetString(playerid, pTextInfo[playerid][pEXPText], result);

    	SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pExprienceBar], 1000);
        SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pExprienceBar], float((PlayerInfo[playerid][pExprience] - ((PlayerInfo[playerid][pLevel] - 1) * 1000))));
		if(GetPVarInt(playerid, "pFirst_Gameplay") == 0)
		{
			SendClientMessageFormatted(playerid, -1, ""#cNiceBlue"Welcome Back "#cWhite"%s", Playername(playerid));
            for(new i = 0; i < sizeof(Navigation_S); i++)
            {
                TextDrawShowForPlayer(playerid, Navigation_S[i]);
            }
            SetTimerEx("SpawnPlayerEx", 100, false, "i", playerid);
            //CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
            //SelectTextDraw(playerid, NAVIGATION_COLOUR);
            //TogglePlayerSpectating(playerid, false);
		}
		else
		{
		    SetPVarInt(playerid, "pRegistration_Tutorial", 1);
		    TextDrawShowForPlayer(playerid, iSpawn_Text);
		    SelectTextDraw(playerid, 0xFFD700FF);
			SetTimerEx("Registration_Tutorial", 5000, false, "i", playerid);
		}
	}
	else if(rows > 1)
	{
	    SendClientMessage(playerid, RED, "Error: Multiple Accounts Found - Please Report This At "#Server_Website" In The Server Bugs Section.");
		SafeKick(playerid, "Multiple Accounts Found.");
	}
	else
	{
		SendClientMessage(playerid, RED, "You have entered an Invalid Password, Please enter your correct password to continue!");
		format(GlobalString, sizeof(GlobalString), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP\n\n{FAF87F}Account: "#cWhite"%s\n\n{FF0000}Please Enter Your Password Below\n{FF0000}Or Suffer Consequences:",Playername(playerid));
		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Login To Twisted Metal: SA-MP", GlobalString, "Login", "Cancel");
		SetPVarInt(playerid, "WrongPass", GetPVarInt(playerid, "WrongPass") + 1);
    	if(GetPVarInt(playerid, "WrongPass") == 3)
     	{
     	    SetPVarInt(playerid, "WrongPass", 0);
			SendClientMessageFormatted(INVALID_PLAYER_ID, PINK, "Twisted Kick: %s(%d) Has Been Kicked From The Server - Reason: Failed To Login.", Playername(playerid), playerid);
			//IRC_GroupSayFormatted(gGroupID, ECHO_IRC_CHANNEL, "13**(AUTO KICK)** %s(%d) Has Been Kicked From The Server - Reason: Failed To Login.", Playername(playerid), playerid);
			//IRC_GroupSayFormatted(gGroupID, ADMIN_IRC_CHANNEL, "13**(AUTO KICK)** %s(%d) Has Been Kicked From The Server - Reason: Failed To Login.", Playername(playerid), playerid);
      		SendClientMessage(playerid, 0xF60000AA, "Maximum incorrect passwords entered - you have been kicked.");
      		SafeKick(playerid, "Failing To Login");
      	}
	}
	return 1;
}

forward Registration_Tutorial(playerid);
public Registration_Tutorial(playerid)
{
    InterpolateCameraPos(playerid, 2694.757568, -2352.101562, 40.479072, -2172.573242, 2056.373779, 79.361602, 90000);
	InterpolateCameraLookAt(playerid, 2694.728027, -2347.103027, 40.359199, -2175.464355, 2060.436767, 78.995948, 45000);
    return 1;
}

THREAD:OnUserRegister(playerid, inputtext[])
{
    printf("[Thread: OnUserRegister] - %s(%d) - %s", Playername(playerid), playerid, inputtext);
    mysql_store_result();
    if(mysql_num_rows() != 0)
 	{
 	    mysql_free_result();
  		SendClientMessage(playerid, RED, "Error: This Account Already Exists!");
      	return 1;
    }
    else
    {
        mysql_free_result();
        SetPVarInt(playerid, "pCanTalk", 1);
        SetPVarInt(playerid, "pFirst_Gameplay", 1);
	 	new Escape[4][MAX_PLAYER_NAME], pip[17], y, m, d, Query[156 + 32];
		getdate(y, m, d);
		GetPlayerIp(playerid, pip, sizeof(pip));
		PlayerInfo[playerid][pLastVisit] = gettime();
		format(Query, sizeof(Query), "%02d:%02d:%04d", d, m, y);
		mysql_real_escape_string(Playername(playerid), Escape[0]);
        mysql_real_escape_string(inputtext, Escape[1]);
		mysql_real_escape_string(pip, Escape[2]);
		mysql_real_escape_string(Query, Escape[3]);
		format(Query, sizeof(Query), "INSERT INTO `Accounts` (`Username`,`Password`,`IP`,`pRegistered`,`pLastVisit`) VALUES ('%s', '%s', '%s', '%s', %d)", Escape[0], Escape[1], Escape[2], Escape[3], PlayerInfo[playerid][pLastVisit]);
		mysql_function_query(McHandle, Query, false, "Thread_NoReturnThread", "i", playerid);
		ClearPreChat(playerid);
       	SendClientMessageFormatted(playerid, 0xFAF87FFF, ""#cYellow"Welcome "#cWhite"%s "#cYellow"- You Have Successfully Registered On "#cBlue"Twisted Metal: SA-MP "#cYellow"- Enjoy Your Stay.", Playername(playerid));
    	SendClientMessage(playerid, -1, "Type "#cNiceBlue"/tutorial "#cWhite"To Learn More About The Server");
		TogglePlayerSpectating(playerid, true);
		CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
		format(Query, sizeof(Query), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP\n\n{FAF87F}Account: "#cWhite"%s\n\nPlease Re-Enter Your Password Confirm The Registration Process:", Playername(playerid));
  	 	ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Re-Authenticate To Twisted Metal: SA-MP", Query, "Login", "Cancel");
	}
	return 1;
}
stock UpdatePlayerDate(playerid)
{
	if(IsLogged[playerid] == 0) return 1;
  	PlayerInfo[playerid][pLastVisit] = gettime();
   	format(GlobalQuery, sizeof(GlobalQuery), "UPDATE `Accounts` SET `pLastVisit` = UNIX_TIMESTAMP() WHERE `Username` = '%s' LIMIT 1", Playername(playerid));
    mysql_function_query(McHandle, GlobalQuery, false, "Thread_NoReturnThread", "i", playerid);
	return 1;
}

stock minrand(min, max) return random(max-min)+min; //By Alex "Y_Less" Cole
stock Float:floatrand(Float:min, Float:max) //By Alex "Y_Less" Cole
{
	new imin = floatround(min);
	return floatdiv(float(random((floatround(max)-imin)*100)+(imin*100)),100.0);
}

stock CreateVehicleEx(vehicletype, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay)
{
	new id = CreateVehicle(vehicletype, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay);
    if(!Iter_Contains(Vehicles, id))
	{
		Iter_Add(Vehicles, id);
	}
	SetVehicleParamsEx(id, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF);
    Vehicle_Interior[id] = 0;
    Vehicle_Missile_Currentslotid[id] = 0;
    Vehicle_Using_Environmental[id] = 0;
    Vehicle_Machine_Gun_Currentid[id] = 0;
    Vehicle_Machine_Gun_CurrentSlot[id] = 0;
    CallRemoteFunction("OnVehicleSpawn", "i", id);
	return id;
}

stock DestroyVehicleEx(vehicleid)
{
	DestroyVehicle(vehicleid);
	if(Iter_Contains(Vehicles, vehicleid))
	{
	    new next;
		Iter_SafeRemove(Vehicles, vehicleid, next);
	}
	Vehicle_Interior[vehicleid] = 0;
	return 1;
}

stock LinkVehicleToInteriorEx(vehicleid, interiorid)
{
	Vehicle_Interior[vehicleid] = interiorid;
	return LinkVehicleToInterior(vehicleid, interiorid);
}
stock GetVehicleInterior(vehicleid) return Vehicle_Interior[vehicleid];

#define CreateVehicle CreateVehicleEx
#define DestroyVehicle DestroyVehicleEx
#define LinkVehicleToInterior LinkVehicleToInteriorEx

#define M_PI 3.141592653589793238462643

stock Float:PointAngle(vehicleid, Float:xa, Float:ya, Float:xb, Float:yb)
{
	new Float:carangle, Float:xc, Float:yc, Float:angle;
	xc = floatabs(floatsub(xa, xb));
	yc = floatabs(floatsub(ya, yb));
	if (yc == 0.0 || xc == 0.0)
	{
		if(yc == 0 && xc > 0) angle = 0.0;
		else if(yc == 0 && xc < 0) angle = 180.0;
		else if(yc > 0 && xc == 0) angle = 90.0;
		else if(yc < 0 && xc == 0) angle = 270.0;
		else if(yc == 0 && xc == 0) angle = 0.0;
	}
	else
	{
		angle = atan(xc / yc);
		if(xb > xa && yb <= ya) angle += 90.0;
		else if(xb <= xa && yb < ya) angle = floatsub(90.0, angle);
		else if(xb < xa && yb >= ya) angle -= 90.0;
		else if(xb >= xa && yb > ya) angle = floatsub(270.0, angle);
	}
	GetVehicleZAngle(vehicleid, carangle);
	return floatadd(angle, -carangle);
}

forward Float:Angle2D(Float:PointAx, Float:PointAy, Float:PointBx, Float:PointBy);
stock Float:Angle2D(Float:PointAx, Float:PointAy, Float:PointBx, Float:PointBy)
{
    new Float:Angle;
    Angle = -atan2(PointBx - PointAx, PointBy - PointAy);
    return Angle;
}

/*stock Float:GetDistanceBetweenPoints(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    x1 -= x2,y1 -= y2,z1 -= z2;
    return floatsqroot((x1 * x1) + (y1 * y1) + (z1 * z1));
}*/

forward Float:GetPlayerDistanceToVehicle(playerid, vehicleid);
forward Float:GetVehicleDistanceFromVehicle(vehicleid, f_vehicleid);

stock Float:GetPlayerDistanceToVehicle(playerid, vehicleid)
{
    new Float:vpos[3];
    GetVehiclePos(vehicleid, vpos[0], vpos[1], vpos[2]);
    return GetPlayerDistanceFromPoint(playerid, vpos[0], vpos[1], vpos[2]);
}

stock Float:GetVehicleDistanceFromVehicle(vehicleid, f_vehicleid)
{
    new Float:vpos[3];
    GetVehiclePos(vehicleid, vpos[0], vpos[1], vpos[2]);
    return GetVehicleDistanceFromPoint(f_vehicleid, vpos[0], vpos[1], vpos[2]);
}


stock GetTwistedMetalName(modelid)
{
	new str[14] = "Unknown";
	switch(modelid)
	{
	    case Junkyard_Dog: str = "Junkyard Dog";
	    case Brimstone: str = "Brimstone";
	    case Outlaw: str = "Outlaw";
	    case Reaper: str = "Reaper";
	    case Roadkill: str = "Roadkill";
	    case Thumper: str = "Thumper";
	    case Spectre: str = "Spectre";
	    case Darkside: str = "Darkside";
	    case Shadow: str = "Shadow";
	    case Meat_Wagon: str = "Meat Wagon";
	    case Vermin: str = "Vermin";
	    case Warthog_TM3: str = "Warthog TM3";
	    case ManSalughter: str = "Man Salughter";
	    case Hammerhead: str = "Hammerhead";
	    case Sweet_Tooth: str = "Sweet Tooth";
	}
	return str;
}

stock GetTwistedMetalColour(modelid, shift = 1)  // SetPlayerColor(playerid, color);
{
    new color = 0xFFFFFFAA;
	switch(modelid)
	{//death warrant = niceblue, crimson fury FF85FF,
	    case Junkyard_Dog: color = 0x82FFDAAA;
	    case Brimstone: color = 0xFCE1FCAA;
	    case Outlaw: color = 0xFFFFFFAA;
	    case Reaper: color = 0xFF0000AA;
	    case Roadkill: color = 0x00FF00AA;
	    case Thumper: color = 0xBB00FFAA;
	    case Spectre: color = 0x42BDFFAA;
	    case Darkside: color = 0x70CDFFAA;
	    case Shadow: color = 0xCE47FFAA;
	    case Meat_Wagon: color = 0xFF6969AA;
	    case Vermin: color = 0xFFE014AA;
	    case Warthog_TM3: color = 0xFFFF30AA;
	    case ManSalughter: color = 0xFFFFFFAA;
	    case Hammerhead: color = 0x145FFFAA;
	    case Sweet_Tooth: color = 0xFF00FFAA;
	}
	if(shift == 1)
	{
		return ShiftRGBAToARGB(color);
	}
	return color;
}

// 1 per player (dynamic)
new PlayerText:Subtitle[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW,...}; // Holds the current player's subtitle textdraw.
                                                         // SubtitleTimer PVar holds the timer ID.
stock ShowSubtitle(playerid, text[], time = 5000, override = 1, Float:x = 375.0, Float:y = 360.0)
{
    if(time < 1 || !IsPlayerConnected(playerid)) return 0;
    if(Subtitle[playerid] != INVALID_PLAYER_TEXT_DRAW)
    {
      	if(!override) return 0;
        else HideSubtitle(playerid); // Hide the current one.
    }
    new string[256];
    format(string, sizeof(string), "~w~%s", text);
  	Subtitle[playerid] = CreatePlayerTextDraw(playerid, x, y, string);
    PlayerTextDrawAlignment(playerid, Subtitle[playerid], 2);
    PlayerTextDrawBackgroundColor(playerid, Subtitle[playerid], 255);
    PlayerTextDrawFont(playerid, Subtitle[playerid], 1);
    PlayerTextDrawLetterSize(playerid, Subtitle[playerid], 0.480, 2.20);
    PlayerTextDrawColor(playerid, Subtitle[playerid], -1);
    PlayerTextDrawSetOutline(playerid, Subtitle[playerid], 0);
    PlayerTextDrawSetProportional(playerid, Subtitle[playerid], 1);
    PlayerTextDrawSetShadow(playerid, Subtitle[playerid], 2);
    PlayerTextDrawUseBox(playerid, Subtitle[playerid], 1);
    PlayerTextDrawBoxColor(playerid, Subtitle[playerid], 572661504);
    PlayerTextDrawTextSize(playerid, Subtitle[playerid], 0.0, 438.000000);

    PlayerTextDrawShow(playerid, Subtitle[playerid]);

    SetPVarInt(playerid, "SubtitleTimer", SetTimerEx("HideSubtitle", time, 0, "i", playerid));

    if(Subtitle[playerid] == INVALID_PLAYER_TEXT_DRAW) return 0;
    return 1;
}

forward HideSubtitle(playerid);
public HideSubtitle(playerid)
{
	if(Subtitle[playerid] == INVALID_PLAYER_TEXT_DRAW) return 1;
    PlayerTextDrawHide(playerid, Subtitle[playerid]);
    PlayerTextDrawDestroy(playerid, Subtitle[playerid]);
    Subtitle[playerid] = INVALID_PLAYER_TEXT_DRAW;
	new tid = GetPVarInt(playerid, "SubtitleTimer");
    KillTimer(tid);
    DeletePVar(playerid, "SubtitleTimer");
    return 1;
}
CMD:subtitle(playerid, params[])
{
	new text[32], time = 5000, override = 1;
	if(!sscanf(params, "s[32]D(5000)D(1)", text, time, override))
	{
	    ShowSubtitle(playerid, text, time, override);
	}
	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if(!IsPlayerAdmin(playerid)) return 1;
    SetPlayerPosFindZ(playerid, fX, fY, fZ);
    return 1;
}

new RandomMSG[11][103] =
{
    "I am Calypso and I thank you for playing Twisted Metal...",
    "I am Calypso and I am the creator of Twisted Metal...",
    "I attempted to bring wife and daughter back..but.. I wasn't powerful enough...",
    "The Twisted Metal contests began since 1995",
    "I'll serve this same foul humiliation back to that crooked, collapsed, cortex, criminally handicapped,",
    "This is ridiculous, really; Twisted Metal is my tournament, it's my brainchild, it's mine!",
    "Their emptiness makes me whole. Their weakness gives me strength. Their destruction is my creation.",
    "Before I created this contest.. I was just a regular man with a wife and daughter..",
    "I got into A car crash into A brick wall that killed my wife and daughter..",
    "Noone knows my real name, all I know that my surname is 'Sparks'",
    "When you win my contest.. you win one free wish.."
};

public SendRandomMsg()
{
	new RandMsg = random(sizeof(RandomMSG)), rmstr[128];
	format(rmstr, sizeof(rmstr), "{0694AC}Calypso: "#cWhite"%s", RandomMSG[RandMsg]);
	foreach(Player, i)
	{
		SendClientMessage(i, 0xFFFFFFFF, rmstr);
		if(RandMsg == 4) SendClientMessage(i, 0xFFFFFFFF, "{0694AC}Calypso: "#cWhite"overly-made up clown!");
		if(RandMsg == 5) SendClientMessage(i, 0xFFFFFFFF, "{0694AC}Calypso: "#cWhite"This will be proven soon enough");
	}
	return 1;
}

stock GetTwistedSpecialTimeUpdate(modelid)
{
	new time = 25;
	switch(modelid)
	{
	    case Junkyard_Dog: time = 30;
	    case Brimstone: time = 25;
	    case Outlaw: time = 30;
	    case Reaper: time = 20;
	    case Roadkill: time = 40;
	    case Thumper: time = 28;
	    case Spectre: time = 25;
	    case Darkside: time = 32;
	    case Shadow: time = 35;
	    case Meat_Wagon: time = 30;
	    case Vermin: time = 25;
	    case Warthog_TM3: time = 32;
	    case ManSalughter: time = 25;
	    case Hammerhead: time = 25;
	    case Sweet_Tooth: time = 32;
	}
	return time;
}

stock GetTwistedMaxSpecials()
{
	return 3;
}

enum rankingEnum
{
    player_Score,
    player_ID
}

stock GetPlayerHighestScores(array[][rankingEnum], left, right)
{
    new
        tempLeft = left,
        tempRight = right,
        pivot = array[(left + right) / 2][player_Score],
        tempVar
    ;
    while(tempLeft <= tempRight)
    {
        while(array[tempLeft][player_Score] > pivot) tempLeft++;
        while(array[tempRight][player_Score] < pivot) tempRight--;

        if(tempLeft <= tempRight)
        {
            tempVar = array[tempLeft][player_Score], array[tempLeft][player_Score] = array[tempRight][player_Score], array[tempRight][player_Score] = tempVar;
            tempVar = array[tempLeft][player_ID], array[tempLeft][player_ID] = array[tempRight][player_ID], array[tempRight][player_ID] = tempVar;
            tempLeft++, tempRight--;
        }
    }
    if(left < tempRight) GetPlayerHighestScores(array, left, tempRight);
    if(tempLeft < right) GetPlayerHighestScores(array, tempLeft, right);
}

stock AssignRandomTeamHuntedPlayer(teamid)
{
    new randomplayer[MAX_PLAYERS], count = 0;
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
	    if(PlayerInfo[i][gTeam] != teamid) continue;
	    if(PlayerInfo[i][pSpawned] != 1) continue;
	    randomplayer[count] = i;
	    ++count;
	}
	if(count == 0) return 1;
	gHunted_Player[teamid] = randomplayer[random(count)];
    new engine, lights, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(Current_Vehicle[gHunted_Player[teamid]], engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(Current_Vehicle[gHunted_Player[teamid]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
	return 1;
}

forward SpawnPlayerEx(playerid);
public SpawnPlayerEx(playerid) return SpawnPlayer(playerid);

public OnGameBegin(gameid)
{
    foreach(Player, i)
	{
	    if(IsLogged[i] == 0) continue;
	    if(GetPVarInt(i, "pSpawn_On_Request") >= 1) continue;
	    if(GetPVarInt(i, "pGarage") >= 1) continue;
	    if(PlayerInfo[i][pSpawned] == 1) continue;
		switch(gGameData[gameid][g_Gamemode])
		{
		    case TEAM_DEATHMATCH, TEAM_HUNTED, TEAM_LAST_MAN_STANDING:
		    {
			    if(PlayerInfo[i][gTeam] == INVALID_GAME_TEAM)
			    {
			        PlayerInfo[i][gTeam] = random(MAX_TEAMS);
			        if(PlayerInfo[i][gTeam] == TEAM_DOLLS)
			        {
			            PlayerInfo[i][gRival_Team] = TEAM_CLOWNS;
			        }
			        else PlayerInfo[i][gRival_Team] = TEAM_DOLLS;
			        SendClientMessage(i, -1, "You Have Been Placed In A Random Team!");
		            AddPlayerToGameTeam(i);
			    }
			}
	    }
	    SpawnPlayer(i);
	    CallLocalFunction("OnPlayerRequestSpawn", "i", i);
	}
	switch(gGameData[gameid][g_Gamemode])
	{
 		case HUNTED:
		{
		    if(Iter_Count(Player) > 0)
		    {
	  			gHunted_Player[0] = Iter_Random(Player);
	  			if(PlayerInfo[gHunted_Player[0]][pSpawned] == 1)
	  			{
	  			    new engine, lights, alarm, doors, bonnet, boot, objective;
					GetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
	  			}
  			}
		}
  		case TEAM_HUNTED:
        {
		    for(new teamid = 0; teamid < MAX_TEAMS; teamid++)
		    {
		    	AssignRandomTeamHuntedPlayer(teamid);
		    }
        }
	}
	return 1;
}

new LastSpecialUpdateTick[MAX_PLAYERS];
forward Overlay();
public Overlay()
{
	for(new gameid = 0; gameid < MAX_GAME_LOBBIES; gameid++)
	{
	    if(gGameData[gameid][g_Gamemode_Time] == 0 && gGameData[gameid][g_Voting_Time] == 0)
		{
			OnMapFinish(gameid, gGameData[gameid][g_Gamemode], gGameData[gameid][g_Map_id]);
		}
		if(gGameData[gameid][g_Gamemode_Countdown_Time] == 0)
		{
			new result[12], minutes;
			minutes = (gGameData[gameid][g_Gamemode_Time] / 60);
			format(result, 12, "%02d:%02d", minutes, gGameData[gameid][g_Gamemode_Time] - (minutes * 60));
			TextDrawSetString(gGameData[gameid][g_Gamemode_Time_Text], result);
			TextDrawSetString(gGameData[gameid][g_Lobby_Time], result);
			gGameData[gameid][g_Gamemode_Time]--;
		}
		else
		{
		    new result[64], minutes;
		    minutes = (gGameData[gameid][g_Gamemode_Countdown_Time] / 60);
			format(result, 12, "%02d:%02d", minutes, gGameData[gameid][g_Gamemode_Countdown_Time] - (minutes * 60));
			TextDrawSetString(gGameData[gameid][g_Gamemode_Time_Text], result);
			TextDrawSetString(gGameData[gameid][g_Lobby_Time], result);

		    gGameData[gameid][g_Gamemode_Countdown_Time]--;
		    if(gGameData[gameid][g_Gamemode_Countdown_Time] == 0)
		    {
		        TextDrawSetString(gGameData[gameid][g_Lobby_gState], "IN GAME");
		        format(result, sizeof(result), "BEGIN!~n~%s", s_Gamemodes[gGameData[gameid][g_Gamemode]][GM_Name]);
		        foreach(Player, i)
				{
				    if(IsLogged[i] == 0) continue;
				    if(GetPVarInt(i, "pSpawn_On_Request") >= 1) continue;
				    if(GetPVarInt(i, "pGarage") >= 1) continue;
		        	TimeTextForPlayer( TIMETEXT_MIDDLE_SUPER_LARGE, i, result, 3000 );
		        	TogglePlayerControllable(i, true);
		        	PlayerPlaySoundEx(i, 44602);
		        }
		        OnGameBegin(gameid);
		    }
		}
		switch(gGameData[gameid][g_Gamemode])
		{
		    case RACE:
			{
			    if(gGameData[gameid][g_Map_id] != (MAX_MAPS + 1))
				{
					Race_Loop();
				}
				foreach(Player, playerid)
				{
				    if(PlayerInfo[playerid][pSpawned] == 0) continue;
				    new rpos = (Race_Position[playerid] >= 4) ? 4 : Race_Position[playerid],
						boxc, ocount = 0;
			        if(rpos > 4)
					{
						rpos = 4;
					}
					if(rpos <= 3)
					{
					    for(new opos = (rpos - 1); opos < 3; opos++)
						{
						    if(opos < 0) continue;
						    if(Race_Top3_Positions[opos] == playerid) continue;
						    if(Race_Top3_Positions[opos] != INVALID_PLAYER_ID)
						    {
						        ++ocount;
						    }
						}
						boxc += rpos;
						boxc += ocount;
					}
			        SetPositionalBox(playerid, boxc);
					new id;
					for(new pos = 0; pos < 3; pos++)
					{
					    id = Race_Top3_Positions[pos];
					    if(id == playerid)
					    {
						    for(new opos = 0; opos < 3; opos++)
							{
							    if(pos == opos) continue;
							    if(Race_Top3_Positions[opos] == playerid)
							    {
							        PlayerTextDrawHide(playerid, Race_Box_Text[playerid][opos]);
							        Race_Top3_Positions[opos] = INVALID_PLAYER_ID;
							    }
							}
						}
					    if(id == INVALID_PLAYER_ID)
						{
						    PlayerTextDrawHide(playerid, Race_Box_Text[playerid][pos]);
							continue;
						}
					    if(!IsPlayerConnected(id))
						{
	                    	PlayerTextDrawHide(playerid, Race_Box_Text[playerid][pos]);
				   	 		Race_Top3_Positions[pos] = INVALID_PLAYER_ID;
							continue;
						}
						if(playerid == id) PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], 0x00FF00FF);
						else PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], -1);
						format(GlobalString, sizeof(GlobalString), "%d   %s", Race_Position[id], Playername(id));
						PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][pos], GlobalString);
						PlayerTextDrawShow(playerid, Race_Box_Text[playerid][pos]);
					}
				}
			}
			case TEAM_DEATHMATCH, TEAM_HUNTED:
			{
			    foreach(Player, i)
			    {
			    	AdjustTeamColoursForPlayer(i);
			    }
			}
			case DEATHMATCH, HUNTED, LAST_MAN_STANDING:
			{
			    for(new opos = 0; opos < 3; opos++)
				{
				    if(Race_Top3_Positions[opos] != INVALID_PLAYER_ID)
				    {
				        Race_Top3_Positions[opos] = INVALID_PLAYER_ID;
				    }
				}
		    	new playerScores[MAX_PLAYERS][rankingEnum], index, id;
	            foreach(Player, i)
	            {
	                if(GetPVarInt(i, "pMultiplayer") != 1) continue;
	                playerScores[index][player_Score] = GetPlayerGamePoints(i);
	                playerScores[index++][player_ID] = i;
	            }
	            GetPlayerHighestScores(playerScores, 0, index);
	            for(new i = 0; i < index; ++i)
	            {
	                id = playerScores[i][player_ID];
	                p_Old_Position[id] = p_Position[id];
	                p_Position[id] = i + 1;
	                if(1 <= p_Position[id] <= 3)
					{
					    Race_Top3_Positions[p_Position[id] - 1] = id;
					}
				}
				foreach(Player, playerid)
				{
				    if(PlayerInfo[playerid][pSpawned] == 0) continue;
				    new rpos = (p_Position[playerid] >= 4) ? 4 : p_Position[playerid],
						boxc, ocount = 0;
			        if(rpos > 4)
					{
						rpos = 4;
					}
					if(rpos <= 3)
					{
					    for(new opos = (rpos - 1); opos < 3; opos++)
						{
						    if(opos < 0) continue;
						    if(Race_Top3_Positions[opos] == playerid) continue;
						    if(Race_Top3_Positions[opos] != INVALID_PLAYER_ID)
						    {
						        ++ocount;
						    }
						}
						boxc += rpos;
						boxc += ocount;
					}
			        SetPositionalBox(playerid, boxc);
					for(new pos = 0; pos < 3; pos++)
					{
					    id = Race_Top3_Positions[pos];
					    if(id == playerid)
					    {
						    for(new opos = 0; opos < 3; opos++)
							{
							    if(pos == opos) continue;
							    if(Race_Top3_Positions[opos] == playerid)
							    {
							        PlayerTextDrawHide(playerid, Race_Box_Text[playerid][opos]);
							        Race_Top3_Positions[opos] = INVALID_PLAYER_ID;
							    }
							}
						}
					    if(id == INVALID_PLAYER_ID)
						{
						    PlayerTextDrawHide(playerid, Race_Box_Text[playerid][pos]);
							continue;
						}
					    if(!IsPlayerConnected(id))
						{
	                    	PlayerTextDrawHide(playerid, Race_Box_Text[playerid][pos]);
				   	 		Race_Top3_Positions[pos] = INVALID_PLAYER_ID;
							continue;
						}
						if(playerid == id) PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], 0x00FF00FF);
						else PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], -1);
						format(GlobalString, sizeof(GlobalString), "%d   %s   ~r~~h~%d", p_Position[id], Playername(id), GetPlayerGamePoints(id));
						PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][pos], GlobalString);
						PlayerTextDrawShow(playerid, Race_Box_Text[playerid][pos]);
					}
				}
				/*
	                if(index > 3)
	                {
	                	SetPositionalBox(id, 3);
	                }
	                else SetPositionalBox(id, index);
	                if(i < 3)
	                {
	                    if(strlen(Playername(playerScores[i][player_ID])) >= 19)
	                    {
	                    	format(score_Text, sizeof(score_Text), "%d   %s ~r~~h~%d", i + 1, Playername(playerScores[i][player_ID]), playerScores[i][player_Score]);
						}
						else format(score_Text, sizeof(score_Text), "%d   %s   ~r~~h~%d", i + 1, Playername(playerScores[i][player_ID]), playerScores[i][player_Score]);
						foreach(Player, playerid)
						{
						    if(PlayerInfo[playerid][pSpawned] == 0) continue;
						    if(playerid == id)
						    {
						        PlayerTextDrawColor(playerid, Race_Box_Text[playerid][i], 0x00FF00FF);
						    }
						    else PlayerTextDrawColor(playerid, Race_Box_Text[playerid][i], -1);
	                    	PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][i], score_Text);
							PlayerTextDrawShow(playerid, Race_Box_Text[playerid][i]);
						}
	                }
	                if(p_Position[id] != p_Old_Position[id])
	                {
		                if(p_Old_Position[id] <= 3
			 				&& p_Position[id] >= 4 || p_Position[id] >= 4)
		                {
		                    format(GlobalString, sizeof(GlobalString), "~g~~h~~h~%d   ~r~~h~%d", p_Position[id], Playername(id), GetPlayerGamePoints(id));
							PlayerTextDrawSetString(id, Race_Box_Text[id][3], GlobalString);
							PlayerTextDrawShow(id, Race_Box_Text[id][3]);
							SetPositionalBox(id, 4);
		                }
		                if(p_Old_Position[id] >= 4
			 				&& p_Position[id] <= 3)
		                {
		                    PlayerTextDrawHide(id, Race_Box_Text[id][3]);
		                    SetPositionalBox(id, p_Position[id]);
		                }
					}*/
			}
		}
	}
	new tick = GetTickCount(), vehicleid, Float:x, Float:y, Float:z, Float:health,
		Found_Vehicle = INVALID_VEHICLE_ID, model;
	foreach(Player, i)
	{
	    if( PlayerInfo[i][pSpawned] == 0 ) continue;
	    vehicleid = GetPlayerVehicleID(i);
	    if(vehicleid == 0) continue;
	    if((1 <= vehicleid <= 2000))
		{
		    model = GetVehicleModel(vehicleid);
		    if(PlayerInfo[i][pEnergy] < floatround(GetTwistedMetalMaxEnergy(model)))
		    {
		        PlayerInfo[i][pEnergy] ++;
		        SetPlayerProgressBarValue(i, pTextInfo[i][pEnergyBar], float(PlayerInfo[i][pEnergy]));
				UpdatePlayerProgressBar(i, pTextInfo[i][pEnergyBar]);
			}
	        GetVehiclePos(vehicleid, x, y, z);
	        if(z < GetMapZ(gGameData[PlayerInfo[i][gGameID]][g_Map_id]) && s_Maps[gGameData[PlayerInfo[i][gGameID]][g_Map_id]][m_CheckLowestZ] == 1)
	        {
	            new Float:newhealth;
				T_GetVehicleHealth(vehicleid, health);
				newhealth = (health - GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid)));
				T_SetVehicleHealth(vehicleid, newhealth);
				if( newhealth <= 0.0 && health > 0.0)
			    {
			   		CallLocalFunction( "OnPlayerTwistedDeath", "ddddddi", i, vehicleid, i, vehicleid, Missile_Fall, GetVehicleModel(vehicleid), GetVehicleModel(vehicleid));
				}
	            continue;
	        }
		}
		if(EMPTime[i] > 0)
		{
		    EMPTime[i] --;
		    SetVehicleAngularVelocity(vehicleid, 0.005, 0.005, 0.0);
		    if(EMPTime[i] == 0)
		    {
		        TogglePlayerControllable(i, true);
				AddEXPMessage(i, "~y~~h~Unfrozen!");
		    }
		    //else SetVehicleAngularVelocity(vehicleid, 0.0, 0.0, 0.0);
		}
		if(PlayerUpdate{i} < 2)
   		{
            PlayerUpdate{i}++;
		}
        else
        {
            if(Paused[i] != 1)
			{
				CallRemoteFunction("OnPlayerPause", "i", i);
                Paused[i] = 1;
            }
        }
	    foreach(Vehicles, v)
	    {
	        if(v == vehicleid) continue;
	        if(!IsVehicleStreamedIn(v, i)) continue;
	        if(!GetVehiclePos(v, x, y, z)) continue;
	        if(!IsPlayerAimingAt(i, x, y, z, 35.0)) continue;
	        Found_Vehicle = v;
	        break;
	    }
	    if(Found_Vehicle == INVALID_VEHICLE_ID)
	    {
	        HidePlayerProgressBar(i, pTextInfo[i][pAiming_Health_Bar]);
			PlayerTextDrawHide(i, pTextInfo[i][AimingPlayer]);
	    }
	    else
	    {
		    T_GetVehicleHealth(Found_Vehicle, health);
	    	PlayerTextDrawSetString(i, pTextInfo[i][AimingPlayer], GetTwistedMetalName(GetVehicleModel(Found_Vehicle)));
	    	SetPlayerProgressBarValue(i, pTextInfo[i][pAiming_Health_Bar], health / GetTwistedMetalMaxHealth(GetVehicleModel(Found_Vehicle)) * 100.0);
			ShowPlayerProgressBar(i, pTextInfo[i][pAiming_Health_Bar]);
			PlayerTextDrawShow(i, pTextInfo[i][AimingPlayer]);
			Found_Vehicle = INVALID_VEHICLE_ID;
		}
		Found_Vehicle = GetVehicleModel(vehicleid);
		if(( tick - LastSpecialUpdateTick[i]) > GetTwistedSpecialTimeUpdate(Found_Vehicle) * 1000)
		{
		    if(PlayerInfo[i][pMissiles][Missile_Special] >= GetTwistedMaxSpecials())
		    {
		        continue;
		    }
		    PlayerInfo[i][pMissiles][Missile_Special]++;
		    new c;
		    for(new m = (Missile_Special + 1); m < (MAX_MISSILEID); m++)
			{
		    	if(PlayerInfo[i][pMissiles][m] != 0)
				{
				    c = m;
					continue;
				}
			}
			if(!c)
			{
		    	pMissileid[i] = Missile_Special;
		    }
		    UpdatePlayerHUD(i);
		    LastSpecialUpdateTick[i] = tick;
		}
		Found_Vehicle = INVALID_VEHICLE_ID;
	}
   	return 1;
}

enum Class_Selection_Info
{
	CS_VehicleModelID,
	CS_TwistedName[24],
	CS_SkinID,
	CS_Colour1,
	CS_Colour2
};
#define MAX_TWISTED_VEHICLES 14
new Class_Selection_IDS[MAX_TWISTED_VEHICLES + 1][Class_Selection_Info] =
{
	{400, "Dummy", 0, 0, 0},
	{Junkyard_Dog, "Junkyard Dog", 200, 3, 6},
	{Brimstone, "~w~Brimstone", 147, 1, 1},
	{Outlaw, "~b~~h~Out~r~~h~law", 266, 0, 1},
	{Reaper, "Mr.Grimm / Reaper", 28, 0, 3},
	{Roadkill, "~g~Roadkill", 162, 44, 44},
	{Thumper, "~p~Thumper", 0, 149, 1},
	{Spectre, "~b~~h~Spectre", 233, 7, 1},
	{Darkside, "Darkside", 251, 0, 0},
	{Shadow, "~p~Shadow", 0, 1, 1},
	{Meat_Wagon, "~r~~h~Meat Wagon", 219, 1, 3},//275 skin
	{Vermin, "~y~Vermin", 262, 6, 113},
	{Warthog_TM3, "~y~~h~Warthog_TM3", 28, 1, 1},
	//{ManSalughter, "~w~ManSalughter", 27, 1, 1},
	{Hammerhead, "~b~~h~~h~Hammerhead", 73, 79, 79},
	{Sweet_Tooth, "~p~~h~Sweet Tooth", 264, 1, 126}
};
#define C_S_IDS Class_Selection_IDS

#define SAMP_03e (true)

//new CarsUse[212];
//new PlayerCopyBegins[MAX_PLAYERS char];

//3790

#define HidePlayerDialog(%1) ShowPlayerDialog(%1,-1,0,"","","","")

new TD_gPHTD;

#define PI 3.14159265

stock stringContainsIP(const szStr[])
{
    new iDots, i;
    while(szStr[i] != EOS)
    {
        if('0' <= szStr[i] <= '9')
        {
            do
            {
                if(szStr[i] == '.') iDots++;
                i++;
            }
            while(('0' <= szStr[i] <= '9') || szStr[i] == '.' || szStr[i] == ':');
        }
        if(iDots > 2) return 1;
        else iDots = 0;
        i++;
    }
    return 0;
}

#define USE_SPEED_UPDATE    (false)

#if USE_SPEED_UPDATE == (true)

// The speed will be multiplied by this value
#define SPEED_MULTIPLIER 1.018

// The speed will only be increased if velocity is larger than this value
#define SPEED_THRESHOLD  0.4

new
	g_SpeedUpTimer = -1,
    Float:g_SpeedThreshold
;

new const
          KEY_VEHICLE_FORWARD  = 0b001000,
          KEY_VEHICLE_BACKWARD = 0b100000
;
#endif

main() {}
//LD_TATT:9gun - minigun td

//LD_TATT:12bndit - dolls td
//LD_TATT:6clown - clowns td

new
    Iterator:pSlots_In_Use[MAX_PLAYERS]<MAX_COMPLETE_SLOTS>;

#define PLAYER_MISSILE_SLOT_ADD 0
#define PLAYER_MISSILE_SLOT_REMOVE 1
#define PLAYER_MISSILE_SLOT_CLEAR 2

stock EditPlayerSlot(playerid, slot = 0, pstype = PLAYER_MISSILE_SLOT_ADD)
{
	switch(pstype)
	{
	    case PLAYER_MISSILE_SLOT_ADD:
	    {
		    if(!Iter_Contains(pSlots_In_Use[playerid], slot))
			{
				Iter_Add(pSlots_In_Use[playerid], slot);
			}
		}
		case PLAYER_MISSILE_SLOT_REMOVE:
		{
		    if(Iter_Contains(pSlots_In_Use[playerid], slot))
			{
			    new next;
				Iter_SafeRemove(pSlots_In_Use[playerid], slot, next);
				return next;
			}
		}
		case PLAYER_MISSILE_SLOT_CLEAR: Iter_Clear(pSlots_In_Use[playerid]);
	}
	return -1;
}

public OnPlayerPause(playerid)
{
	printf("[System] - %s(%d) Has Paused", Playername(playerid), playerid);
	new Float:px, Float:py, Float:pz;
	GetPlayerPos(playerid, px, py, pz);
	PausedText[playerid] = Create3DTextLabel("PAUSED", -1, px, py, pz + 1.0, 25.0, GetPlayerVirtualWorld(playerid));
    Attach3DTextLabelToPlayer(PausedText[playerid], playerid, 0, 0, 0.4);
	if(!IsPlayerAdmin(playerid) && PlayerInfo[playerid][AdminLevel] == 0)
	{
		PauseTime[playerid] = gettime() + 180;
	}
    return 1;
}
forward KickPausedPlayer(playerid);
public KickPausedPlayer(playerid)
{
	if(!IsPlayerConnected(playerid)) return 1;
	format(GlobalString, sizeof(GlobalString), "SERVER KICK: %s(%d) Has Been Kicked From The Server - Reason: Paused/ AFK.", Playername(playerid),playerid);
	SendClientMessageToAll(PINK, GlobalString);
	Delete3DTextLabel(PausedText[playerid]);
	PausedText[playerid] = Text3D:INVALID_3DTEXT_ID;
	PauseTime[playerid] = 0;
	SafeKick(playerid, "Being Paused To Long");
	return 1;
}
public OnPlayerUnPause(playerid)
{
    Delete3DTextLabel(PausedText[playerid]);
    PausedText[playerid] = Text3D:INVALID_3DTEXT_ID;
    PauseTime[playerid] = 0;
    printf("[System] - %s(%d) Has Unpaused", Playername(playerid), playerid);
    if(Selecting_Textdraw[playerid] != -1)
    {
        SelectTextdraw(playerid, Selecting_Textdraw[playerid]);
    }
    return 1;
}
public IsPlayerPaused(playerid) return Paused[playerid];

#define CAMERA_MODE_NONE    	0
#define CAMERA_MODE_FREE_LOOK	1

stock RGBA(red, green, blue, alpha)
{
	return (red * 16777216) + (green * 65536) + (blue * 256) + alpha;
}

enum e_mod_colours
{
	mod_name[24],
	mod_R,
	mod_G,
	mod_B
};
#define MAX_MOD_SHOP_COLOURS 10 // 126
new mod_colours[126][e_mod_colours] = // RBG
{
	{"Black", 0, 0, 0},
	{"White", 0, 0, 0},
	{"Police car blue", 42, 119, 161},
	{"Cherry red", 132, 4, 16},
	{"Midnight blue", 38, 55, 57},
	{"Temple curtain purple", 134, 68, 110},
	{"Taxi yellow", 215, 142, 16},
	{"Striking blue", 76, 117, 183},
	{"Light blue grey", 189, 190, 198},
	{"Hoods", 94, 112, 114}
};
#pragma unused mod_colours

public OnGameModeInit()
{
    printf("[Heapspace - OnGameModeInit] - heapspace(): %i - Heapspace: %i kilobytes", heapspace(), heapspace() / 1024);
    Iter_Init(pSlots_In_Use);
    Iter_Init(Map_Selection);
	new str[32];
	str = "123.456.789.0:7777";
	printf("ip: %s - contains: %d", str, stringContainsIP(str));

	//SendRconCommand("loadfs Twisted_Pic");
	SendRconCommand("hostname Twisted Metal: SA-MP v"#Server_Version"");
	SendRconCommand("gamemodetext Vehicular Combat");
	SendRconCommand("weburl "#Server_Website"");
    new StartTick = GetTickCount();
	SetWorldTime(3);
	ManualVehicleEngineAndLights();
	EnableStuntBonusForAll(false);
	DisableInteriorEnterExits();

	for(new i = 0; i < MAX_MAPS; i++)
	{
		s_Maps[i][m_ID] = -1;
	}
    SetTimer("MissileUpdate", 65, true);
	SetTimer("Overlay", 997, true);
	SetTimer("SendRandomMsg", 255001, true);
	SetTimer("Pickup_Update", 175, true);

	#if USE_SPEED_UPDATE == (true)
	//g_SpeedUpTimer = SetTimer("SpeedUp", 220, true);

    // Cache this value for speed
    // This can not be done during compilation because of a limitation with float values
    g_SpeedThreshold = SPEED_THRESHOLD * SPEED_THRESHOLD;
    #endif

	TD_gPHTD = funcidx("Hidetd") != -1;

	#if USE_MYSQL == (true)
	mysql_debug(true);
	McHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
	#endif

	gBotID[0] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_1_NICKNAME, BOT_1_REALNAME, BOT_1_USERNAME);
	IRC_SetIntData(gBotID[0], E_IRC_CONNECT_DELAY, 1);

	gGroupID = IRC_CreateGroup();

	new mapid;

	mapid = CreateMap("Skyscraper (S.F Skyline)", MAP_TYPE_NORMAL);
	SetMapData(mapid, MD_TYPE_LowestZ, ""#MAP_SKYSCRAPER_Z"", .valuetype = MD_Float);

	AddMapObject(MAP_SKYSCRAPERS, 10139, -2003.59997559, 357.29998779, 81.69999695, 0.0, 4.00244141, 180.13970947, 0.0);  //object(road47_sfe) (1)
	AddMapObject(MAP_SKYSCRAPERS, 10136, -1961.40002441, 435.39999390, 113.09999847, 0.0, 0.0, 2.0, 0.0); //object(road44_sfe) (1)
	AddMapObject(MAP_SKYSCRAPERS, 10136, -1969.19995117, 498.79998779, 130.30000305, 0.0, 0.0, 90.0, 0.0);
	AddMapObject(MAP_SKYSCRAPERS, 10113, -2018.69995117, 499.70001221, 126.52999878, 0.0, 0.0, 268.0, 0.0); //object(road19_sfe) (1)

    AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HEALTH, -2159.6465, 372.8101, 59.1739);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HEALTH, -2446.8884, 346.8462, 89.0868);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HEALTH, -2213.4688, 550.8536, 81.9552);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HEALTH, -2086.4734, 471.7954, 115.5671);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_MACHINE_GUN_UPGRADE, -2423.5906, 380.8875, 77.0862);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_MACHINE_GUN_UPGRADE, -2162.5259, 471.8792, 74.2109);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HOMING_MISSILE, -2156.2849, 221.3587, 51.6483);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HOMING_MISSILE, -2441.2153, 426.6300, 73.4463);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HOMING_MISSILE, -2159.9363, 550.6191, 81.9550);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_HOMING_MISSILE, -2017.9677, 446.5648, 139.3671);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_FIRE_MISSILE, -2198.8689, 253.1347, 56.4977);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_FIRE_MISSILE, -2234.4026, 168.8765, 57.8941);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_FIRE_MISSILE, -2125.8760, 549.8195, 78.7939);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_FIRE_MISSILE, -2100.7634, 342.6689, 66.7942);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_FIRE_MISSILE, -1899.1156, 509.5067, 108.0175);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_POWER_MISSILE, -2197.7632, 332.9297, 61.5851);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_POWER_MISSILE, -2215.2439, 154.3444, 59.0953);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_POWER_MISSILE, -1900.0160, 466.0663, 108.0185);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_NAPALM_MISSILE, -2463.5718, 310.6233, 77.0843);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_NAPALM_MISSILE, -2174.5227, 156.7459, 61.7345);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_NAPALM_MISSILE, -2124.5469, 517.3336, 78.7940);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_NAPALM_MISSILE, -1855.4224, 508.2366, 108.0182);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_NAPALM_MISSILE, -2110.4946, 398.6523, 91.7654);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_STALKER_MISSILE, -2171.8086, 461.8672, 74.2108);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_STALKER_MISSILE, -1856.0737, 465.6059, 108.0183);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_RICOCHETS_MISSILE, -2242.4951, 251.7877, 55.9924);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_RICOCHETS_MISSILE, -2144.4011, -10.7885, 51.5073);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_RICOCHETS_MISSILE, -2326.6936, 419.1492, 73.4372);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_RICOCHETS_MISSILE, -2028.2504, 533.4715, 78.7942);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_RICOCHETS_MISSILE, -2106.4756,449.4692, 91.7671);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_REMOTEBOMBS, -2465.2190, 449.8807, 73.4315);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_REMOTEBOMBS, -2137.9377, 73.9072, 50.1256);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_REMOTEBOMBS, -2071.3875,438.9512, 139.3672);
	AddMapPickup(MAP_SKYSCRAPERS, PICKUPTYPE_LIGHTNING, -1877.7018,487.1498, 115.9443);

	mapid = CreateMap("Downtown", MAP_TYPE_NORMAL);
	SetMapData(mapid, MD_TYPE_LowestZ, ""#MAP_DOWNTOWN_Z"", .valuetype = MD_Float);
	SetMapData(mapid, MD_TYPE_CheckLowestZ, "0", .valuetype = MD_Integer);
	SetMapData(mapid, MD_TYPE_IP_Index, "4", .valuetype = MD_Integer);
	SetMapData(mapid, MD_TYPE_EN_Name, "Lightning", .valuetype = MD_String);
	SetMapData(MAP_DOWNTOWN, MD_TYPE_WB_max_X, "-1867.2859", MD_Float);
	SetMapData(MAP_DOWNTOWN, MD_TYPE_WB_min_X, "-2164.8445", MD_Float);
	SetMapData(MAP_DOWNTOWN, MD_TYPE_WB_max_Y, "-709.1476", MD_Float);
	SetMapData(MAP_DOWNTOWN, MD_TYPE_WB_min_Y, "-1087.1028", MD_Float);

	AddMapObject(MAP_DOWNTOWN, 8151, -2124.69995117, -740.70001221, 35.59999847, 0.0, 0.0, 90.0, 0.0); //object(vgsselecfence05) (1)
	AddMapObject(MAP_DOWNTOWN, 8150, -2022.69995117, -708.79998779, 34.20000076, 0.0, 0.0, 0.0, 0.0); //object(vgsselecfence04) (1)
	AddMapObject(MAP_DOWNTOWN, 8150, -1931.69995117, -708.79998779, 34.29999924, 0.0, 0.0, 0.0, 0.0); //object(vgsselecfence04) (2)
	AddMapObject(MAP_DOWNTOWN, 8150, -1868.80004883, -771.29998779, 34.09999847, 0.0, 0.0, 90.0, 0.0); //object(vgsselecfence04) (3)
	AddMapObject(MAP_DOWNTOWN, 8150, -1868.40002441, -895.90002441, 34.00000000, 0.0, 0.0, 90.0, 0.0); //object(vgsselecfence04) (4)
	AddMapObject(MAP_DOWNTOWN, 8150, -1936.30004883, -1079.00000000, 34.20000076, 0.0,0.0, 270.0, 0.0); //object(vgsselecfence04) (5)
	AddMapObject(MAP_DOWNTOWN, 8151, -1901.59997559, -996.50000000, 33.79999924, 0.0, 180.0, 178.0, 0.0); //object(vgsselecfence05) (2)
	AddMapObject(MAP_DOWNTOWN, 980, -1931.00000000, -1034.80004883, 33.79999924, 0.0, 0.0, 358.0, 0.0); //object(airportgate) (1)
	AddMapObject(MAP_DOWNTOWN, 8150, -2164.69995117, -832.70001221, 33.79999924, 0.0, 0.0, 270.0, 0.0); //object(vgsselecfence04) (6)
	AddMapObject(MAP_DOWNTOWN, 8150, -2164.60009766, -958.29998779, 33.79999924, 0.0, 0.0, 270.0, 0.0); //object(vgsselecfence04) (7)
	AddMapObject(MAP_DOWNTOWN, 8262, -2089.80004883, -1017.40002441, 34.20000076, 0.0, 0.0, 90.0, 0.0); //object(vgsselecfence13) (1)
	AddMapObject(MAP_DOWNTOWN, 8262, -2087.89990234, -1017.50000000, 41.00000000, 0.0, 0.0, 90.0, 0.0); //object(vgsselecfence13) (2)
	AddMapObject(MAP_DOWNTOWN, 6959, -2019.80004883, -782.70001221, 30.26000023, 0.0, 0.0, 0.0, 0.0); 	//object(vegasnbball1) (2)
	AddMapObject(MAP_DOWNTOWN, 6959, -2022.80004883, -822.59997559, 30.26000023, 0.0, 0.0, 0.0, 0.0); 	//object(vegasnbball1) (3)
	AddMapObject(MAP_DOWNTOWN, 6959, -2021.69995117, -862.29998779, 30.26000023, 0.0, 0.0, 0.0, 0.0); 	//object(vegasnbball1) (4)
	AddMapObject(MAP_DOWNTOWN, 6959, -2022.30004883, -901.40002441, 30.26000023, 0.0, 0.0, 0.0, 0.0); 	//object(vegasnbball1) (5)
	AddMapObject(MAP_DOWNTOWN, 6959, -2021.59997559, -941.29998779, 30.26000023, 0.0, 0.0, 270.0, 0.0); //object(vegasnbball1) (6)

	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HEALTH, -1968.6166, -795.9158, 32.0306);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HEALTH, -1954.5425, -989.5878, 35.5157);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HEALTH, -1954.8473, -978.8585, 41.8281);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HEALTH, -1959.1565, -1041.5227, 52.8903);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HEALTH, -2063.0967, -1039.1526, 58.8897);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HEALTH, -2081.6472, -858.5424, 66.8750);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_TURBO, -1939.7659, -925.4441, 32.0302);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_MACHINE_GUN_UPGRADE, -1875.137, -714.065, 31.650);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HOMING_MISSILE, -1941.0214, -1085.2242, 30.5805);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HOMING_MISSILE, -1892.0339, -859.2641, 31.8302);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HOMING_MISSILE, -1961.3849, -846.6412, 35.5146);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_HOMING_MISSILE, -2081.6160, -886.9053, 71.6587);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_FIRE_MISSILE, -1969.0414, -786.6783, 32.0303);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_FIRE_MISSILE, -1892.2778, -807.2610, 31.8271);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_FIRE_MISSILE, -1949.2175, -875.0110, 35.5129);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_FIRE_MISSILE, -2129.5322, -809.9766, 31.6483);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_FIRE_MISSILE, -2081.6638, -835.0388, 68.9314);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_FIRE_MISSILE, -1954.7003, -737.4468, 41.2548);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_POWER_MISSILE, -1949.5277, -1085.4576, 30.5784);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_POWER_MISSILE, -1892.6548, -909.2054, 31.8283);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_POWER_MISSILE, -1954.9137, -941.7766, 35.5156);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_POWER_MISSILE, -2022.1172, -806.3328, 30.8782);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_POWER_MISSILE, -2070.8479, -859.7825, 66.4998);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_POWER_MISSILE, -1940.6736, -1020.4677, 52.8897);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_NAPALM_MISSILE, -2023.7727, -911.5933, 30.8783);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_NAPALM_MISSILE, -2079.8171, -870.7611, 66.4997);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_ENVIRONMENTALS, -1955.0471, -729.1618, 35.516);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_STALKER_MISSILE, -2128.9412, -911.6611, 31.6482);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_STALKER_MISSILE, -1885.635, -1017.077, 32.1);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_STALKER_MISSILE, -1954.7145, -858.9112, 41.4475);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_STALKER_MISSILE, -2092.9849, -860.0109, 66.4998);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_RICOCHETS_MISSILE, -2084.0837, -849.1871, 66.4989);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_RICOCHETS_MISSILE, -2055.614, -911.293, 31.797);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_REMOTEBOMBS, -1941.2844, -793.4117, 32.0289);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_REMOTEBOMBS, -2097.9424, -809.0001, 65.1329);
	AddMapPickup(MAP_DOWNTOWN, PICKUPTYPE_REMOTEBOMBS, -2010.2809, -1028.3591, 58.8906);

	mapid = CreateMap("Hanger 18", MAP_TYPE_NORMAL);
	SetMapData(mapid, MD_TYPE_LowestZ, ""#MAP_NORMAL_Z"", .valuetype = MD_Float);

	AddMapObject(MAP_HANGER18, 8051, -1185.19995117, 0.69999999,	 33.29999924, 0.0, 268.0, 315.0, 0.0);  //object(vegassedge13) (1)
	AddMapObject(MAP_HANGER18, 8824, -1172.90002441, 280.89999390, 33.09999847, 0.0, 90.0, 134.70010376, 0.0); //object(vgseedge05) (1)
    AddMapObject(MAP_HANGER18, 8824, -1188.00000000, 63.0,		 33.20000076, 0.0, 270.00000000, 44.69793701, 0.0); //object(vgseedge05) (2)
    AddMapObject(MAP_HANGER18, 8824, -1160.09997559, -88.5, 33.29999924, 0.0, 267.99499512, 42.69787598, 0.0); //object(vgseedge05) (3)
    AddMapObject(MAP_HANGER18, 8051, -1201.09997559, 195.0,	 31.29999924, 0.0, 267.99493408, 44.99450684, 0.0); //object(vegassedge13) (7)
    AddMapObject(MAP_HANGER18, 8824, -1187.00000000, 176.60000610, 32.70000076, 0.0,88.0, 134.69781494, 0.0); //object(vgseedge05) (4)
    AddMapObject(MAP_HANGER18, 8824, -1074.50000000, 378.20001221, 32.90000153, 0.0,90.0, 134.69787598, 0.0); //object(vgseedge05) (5)
    AddMapObject(MAP_HANGER18, 8824, -1076.69995117, 419.20001221, 33.0, 0.0, 90.0, 224.69787598, 0.0); //object(vgseedge05) (6)
    AddMapObject(MAP_HANGER18, 8824, -1136.59997559, 395.50000000, 33.50000000,0.00000000,269.00000000,134.89791870, 0.0); //object(vgseedge05) (7)
    AddMapObject(MAP_HANGER18, 8824, -1235.76000977, 297.39999390, 33.50000000,0.00000000,271.00000000,135.10003662, 0.0); //object(vgseedge05) (8)
    AddMapObject(MAP_HANGER18, 8824, -1334.09997559, 199.60000610, 33.20000076,0.00000000,272.99902344,135.09887695, 0.0); //object(vgseedge05) (9)
    AddMapObject(MAP_HANGER18, 8824, -1432.80004883, 100.59999847, 33.29999924,0.00000000,272.99377441,135.09341431, 0.0); //object(vgseedge05) (10)
    AddMapObject(MAP_HANGER18, 8824, -1531.00000000, 2.09999990, 33.00000000,0.00000000,272.99377441,135.09341431, 0.0); //object(vgseedge05) (11)
    AddMapObject(MAP_HANGER18, 8824, -1629.09997559, -97.09999847, 32.29999924,0.00000000,272.99377441,135.09341431, 0.0); //object(vgseedge05) (12)
    AddMapObject(MAP_HANGER18, 8824, -1701.19995117, -211.19999695, 32.09999847,0.00000000,272.99377441,165.09344482, 0.0); //object(vgseedge05) (13)
    AddMapObject(MAP_HANGER18, 8824, -1726.79992676, -347.50000000, 32.29999924,0.00000000,272.98828125,175.09155273, 0.0); //object(vgseedge05) (14)
    AddMapObject(MAP_HANGER18, 8824, -1734.69995117, -487.0,		32.00000000,0.00000000,272.98278809,179.08911133, 0.0); //object(vgseedge05) (15)
    AddMapObject(MAP_HANGER18, 8824, -1733.00000000, -624.0,		32.50000000,0.00000000,272.97729492,183.08813477, 0.0); //object(vgseedge05) (17)
    AddMapObject(MAP_HANGER18, 8824, -1686.30004883, -647.50,		32.70000076,0.00000000,270.97180176,233.08715820, 0.0); //object(vgseedge05) (18)
    AddMapObject(MAP_HANGER18, 8824, -1562.40002441, -694.29998779, 32.50000000,0.00000000,268.97167969,270.08593750, 0.0); //object(vgseedge05) (19)
    AddMapObject(MAP_HANGER18, 8824, -1422.59997559, -694.0,		32.20000076,0.00000000,268.96728516,270.08239746, 0.0); //object(vgseedge05) (20)
    AddMapObject(MAP_HANGER18, 8824, -1284.40002441, -693.90002441, 32.20000076,0.00000000,268.96728516,270.08239746, 0.0); //object(vgseedge05) (21)
    AddMapObject(MAP_HANGER18, 8824, -1107.40002441, -175.39999390, 32.00000000,0.00000000,267.99499512,26.69287109, 0.0); //object(vgseedge05) (22)
    AddMapObject(MAP_HANGER18, 8824, -1061.90002441, -207.60000610, 33.09999847,0.00000000,90.00000000,114.69140625, 0.0); //object(vgseedge05) (23)
    AddMapObject(MAP_HANGER18, 8824, -1228.30004883, -634.20001221, 32.00000000,0.00000000,268.96728516,0.08239746, 0.0); //object(vgseedge05) (24)
    AddMapObject(MAP_HANGER18, 8824, -1175.59997559, -494.10000610, 32.79999924,0.00000000,90.00000000,138.68630981, 0.0); //object(vgseedge05) (25)
    AddMapObject(MAP_HANGER18, 8824, -1122.69995117, -386.50,		32.79999924,0.00000000,90.00000000,162.68591309, 0.0); //object(vgseedge05) (27)
    AddMapObject(MAP_HANGER18, 8824, -1125.80004883, -321.60000610, 32.79999924,0.00000000,267.99499512,6.69128418, 0.0); //object(vgseedge05) (28)

	//
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HEALTH, -1333.1632,-690.2609,13.7736);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HEALTH, -1627.2253,-497.9879,22.3220);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HEALTH, -1380.0986,-264.9716,28.9736);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_TURBO, -1395.6112,-690.7286,13.7734);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_TURBO, -1082.6086,411.2628,13.7735);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_MACHINE_GUN_UPGRADE, -1397.4900,-662.4650,26.9484);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HOMING_MISSILE, -1701.9808,-615.5155,13.8581);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HOMING_MISSILE, -1672.5557,-450.0131,13.7702);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HOMING_MISSILE, -1272.7809,-662.2274,26.9496);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HOMING_MISSILE, -1533.7335,-536.3138,13.7732);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HOMING_MISSILE, -1322.6210,-572.7213,13.7734);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_HOMING_MISSILE, -1135.9952,388.3161,14.1424);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_FIRE_MISSILE, -1335.5183,-662.7516,26.9517);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_FIRE_MISSILE, -1616.4437,-681.6674,13.7688);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_FIRE_MISSILE, -1681.0417,-626.2104,20.2786);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_FIRE_MISSILE, -1333.1929,-272.9081,13.7734);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_FIRE_MISSILE, -1656.6677,-164.1126,13.7738);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_POWER_MISSILE, -1127.1443,-150.6824,13.7691);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_POWER_MISSILE, -1459.9198,-661.7783,26.9502);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_POWER_MISSILE, -1605.6865,-476.8925,22.2773);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_NAPALM_MISSILE, -1502.9771,-676.9957,41.7210);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_NAPALM_MISSILE, -1389.4724,-216.4485,13.7734);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_NAPALM_MISSILE, -1378.5898,-370.5057,25.0624);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_NAPALM_MISSILE, -1223.3116,177.0148,13.7732);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_STALKER_MISSILE, -1238.3367,-657.4380,13.7733);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_STALKER_MISSILE, -1725.0079,-364.2274,15.3995);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_STALKER_MISSILE, -1302.3929,-440.1608,13.7735);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_RICOCHETS_MISSILE, -1566.9156,-559.8745,13.7735);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_RICOCHETS_MISSILE, -1505.3624,-523.9119,13.7685);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_RICOCHETS_MISSILE, -1104.4197,357.2081,14.1130);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_REMOTEBOMBS, -1138.8975,-160.2062,13.7736);
	AddMapPickup(MAP_HANGER18, PICKUPTYPE_REMOTEBOMBS, -1714.9625,-547.1940,13.7735);

	mapid = CreateMap("Suburbs", MAP_TYPE_NORMAL);
	SetMapData(mapid, MD_TYPE_LowestZ, ""#MAP_SUBURBS_Z"", .valuetype = MD_Float);
	SetMapData(MAP_SUBURBS, MD_TYPE_WB_max_X, "-2203.2310", MD_Float);
	SetMapData(MAP_SUBURBS, MD_TYPE_WB_min_X, "-2878.3123", MD_Float);
	SetMapData(MAP_SUBURBS, MD_TYPE_WB_max_Y, "2808.5183", MD_Float);
	SetMapData(MAP_SUBURBS, MD_TYPE_WB_min_Y, "2176.3350", MD_Float);

	//
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HEALTH, -2501.7786,2310.6724,15.2365);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HEALTH, -2374.1606,2215.5779,4.6091);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HEALTH, -2619.1931, 2238.7034, 4.6); // broken
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HEALTH, -2502.8582,2514.0364,18.8111);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HEALTH, -2234.6465,2402.9248,2.1161);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HEALTH, -2228.1140,2326.5317,7.1717);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_TURBO, -2636.8086,2255.1628,13.1351);//broken
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_TURBO, -2413.7476,2354.4380,4.6181);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_TURBO, -2458.8289,2232.2397,4.4687);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_MACHINE_GUN_UPGRADE, -2638.4211,2305.4961,8.2864);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_MACHINE_GUN_UPGRADE, -2441.1377,2301.2236,4.6095);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HOMING_MISSILE, -2627.7756,2249.7329,7.8198);//broken
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HOMING_MISSILE, -2366.4685,2444.9915,8.8757);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HOMING_MISSILE, -2285.2356,2312.0244,10.1152);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HOMING_MISSILE, -2653.3352,2352.6968,10.0534);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HOMING_MISSILE, -2459.4658,2459.8899,16.1824);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2615.1428,2331.0686,7.7448);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2445.3015,2313.6418,15.6857);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2582.9697,2397.2100,12.6432);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2297.3643,2311.5159,10.7558);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2506.3699,2534.2495,18.7925);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2454.1182,2414.6577,14.9903);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2493.0579,2291.7168,4.6095);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_POWER_MISSILE, -2636.4934,2328.5942,8.0112);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_POWER_MISSILE, -2528.8994,2309.8860,13.1484);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_POWER_MISSILE, -2444.7368,2275.8816,15.0052);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_POWER_MISSILE, -2277.8059,2574.6318,23.1222);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_POWER_MISSILE, -2250.7061,2418.8352,2.1204);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_NAPALM_MISSILE, -2547.6838,2432.1133,18.5541);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_NAPALM_MISSILE, -2291.6990,2310.8506,15.1821);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_NAPALM_MISSILE, -2390.1692,2556.9177,23.5941);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_NAPALM_MISSILE, -2601.0322,2250.4084,7.8256);//broken
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_NAPALM_MISSILE, -2399.6670,2383.6025,7.1457);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_STALKER_MISSILE, -2512.3347,2284.8108,14.6717);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_STALKER_MISSILE, -2538.3215,2223.4648,4.5246);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_STALKER_MISSILE, -2333.1855,2450.1653,4.4957);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_RICOCHETS_MISSILE, -2575.9463,2273.1890,5.7061);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_RICOCHETS_MISSILE, -2626.3787,2448.3960,16.7685);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_RICOCHETS_MISSILE, -2256.1775,2561.8293,4.3339);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_RICOCHETS_MISSILE, -2357.0403,2389.0664,5.9492);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_REMOTEBOMBS, -2629.9985,2403.0474,11.1136);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_REMOTEBOMBS, -2630.0449,2268.9019,7.7205);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_REMOTEBOMBS, -2261.6213,2286.4539,4.4454);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_LIGHTNING, -2488.2761,2281.0830,18.7584);

	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_TURBO, -2509.0105,2646.0840,64.5916);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_HOMING_MISSILE, -2726.1399,2278.8198,61.9628);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_FIRE_MISSILE, -2812.9373,2286.6565,90.6382);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_POWER_MISSILE, -2741.0505,2199.9109,68.1439);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_NAPALM_MISSILE, -2293.4316,2227.9836,5.1689);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_STALKER_MISSILE, -2756.7944,2382.9399,83.6944);
	AddMapPickup(MAP_SUBURBS, PICKUPTYPE_RICOCHETS_MISSILE, -2654.9351,2629.3584,83.8687);

	mapid = CreateMap("Diablo Pass", MAP_TYPE_RACE);
	SetMapData(mapid, MD_TYPE_LowestZ, ""#MAP_DIABLO_PASS_Z"", .valuetype = MD_Float);
	SetMapData(mapid, MD_TYPE_Weatherid, "666", .valuetype = MD_Integer);

	LoadMapData(MAP_ALL_DATA, mapid = MAX_MAPS);

	//new Query[256];
	//for(new maxmap = 0; maxmap < ; maxmap++)
	//{
	//    format(Query, sizeof(Query), "");
	//	mysql_function_query(McHandle, Query, false, "NoReturnThread", "i", -1);
	//}

	MapAndreas_Init(MAP_ANDREAS_MODE_MINIMAL);

    #if ENABLE_NPC == (true)
	//ConnectNPC("[BOT]Calypso", "npcidle");
	#endif

    //ConnectNPC("[BOT]RacerTest", "npcidle");
    #if defined RNPC_INCLUDED
    ConnectRNPCS();
    #endif

	new v = 1, p = 0, ms = 0, go = 0, objectid = 0;
	do
	{
	    Vehicle_Missile_Currentslotid[v] = 0;
	    Vehicle_Using_Environmental[v] = 0;
	    Vehicle_Machine_Gun_Currentid[v] = 0;
        Vehicle_Machine_Gun_CurrentSlot[v] = 0;
        VehicleOffsetX[v] = 0.0;
 		VehicleOffsetY[v] = 0.0;
 		VehicleOffsetZ[v] = 0.0;
 		WasDamaged[v] = 0;
	 	Vehicle_Machine_Gunid[v] = 0;
	 	Machine_Gun_Firing_Timer[v] = -1;
	 	pLastAttacked[v] = 0;
	 	pLastAttackedTime[v] = 0;
		pLastAttackedMissile[v] = -1;
		pCurrentlyAttackingMissile[v] = -1;
		Vehicle_Missile_Reset_Fire_Time[v] = 0;
		Vehicle_Missile_Reset_Fire_Slot[v] = -1;
	 	for(ms = 0; ms < MAX_MISSILE_SLOTS; ms++)
	 	{
		 	Vehicle_Smoke[v][ms] = INVALID_OBJECT_ID;
		 	Vehicle_Missile[v][ms] = INVALID_OBJECT_ID;
		 	Vehicle_Missile_Following[v][ms] = INVALID_VEHICLE_ID;
		 	for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
	 		{
		 		Vehicle_Missile_Lights[v][L] = INVALID_OBJECT_ID;
		 		Vehicle_Missile_Lights_Attached[v][L] = -1;
		 	}

	 	}
	 	for(ms = 0; ms < MAX_DAMAGEABLE_MISSILES; ms++)
	 	{
	 	    pCurrentlyAttackingDamage[v][ms] = 0.0;
		}
	 	for(ms = 0; ms < MAX_MACHINE_GUN_SLOTS; ms++)
	 	{
	 		Vehicle_Machine_Gun[v][ms] = INVALID_OBJECT_ID;
	 		Vehicle_Machine_Mega_Gun[v][ms] = INVALID_OBJECT_ID;
	 	}
	 	for(go = 0; go < 2; go++)
	 	{
	 		Vehicle_Machine_Gun_Object[v][go] = INVALID_OBJECT_ID;
	 		Vehicle_Machine_Gun_Flash[v][go] = INVALID_OBJECT_ID;
	 	}
	    ++v;
	}
	while (v < MAX_VEHICLES);
	do
	{
		Object_Owner[objectid] = INVALID_VEHICLE_ID;
		Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
		++objectid;
	}
	while (objectid < MAX_OBJECTS);
	do
	{
	    pMissileid[p] = 0;
	    pFiring_Missile[p] = 0;
		Mine_Timer[p] = -1;
		Nitro_Bike_Object[p] = INVALID_OBJECT_ID;
		for(new ro = 0; ro < MAX_PRELOADED_OBJECTS; ro++)
    	{
           	Preloading_Objects[p][ro] = INVALID_OBJECT_ID;
    	}
    	Objects_Preloaded[p] = 0;
   		pFirstTimeViewingMap[p] = 1;
   		PlayerInfo[p][pMissile_Charged] = -1;
   		PlayerInfo[p][gTeam] = INVALID_GAME_TEAM;
   		PlayerInfo[p][gRival_Team] = INVALID_GAME_TEAM;
	    EditPlayerSlot(p, _, PLAYER_MISSILE_SLOT_CLEAR);
		++p;
	}
	while (p < MAX_PLAYERS);

	new tutobject;
	tutobject = CreateObject(19478, 2694.757568, -2264.6299, 40.479072, 0.0, 0.0, 0.0, 300.0);
	SetObjectMaterialText(tutobject, ""#cBlue"Twisted Metal: "#cWhite"SA-MP", 0, OBJECT_MATERIAL_SIZE_64x32,\
	"Courier New", 120, 0, 0xFFFFFFFF, 0xFF000000, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);

	gFerrisWheel = CreateObject( FERRIS_WHEEL_ID, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2],
	  							 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, FERRIS_DRAW_DISTANCE );

    gFerrisBase = CreateObject( FERRIS_BASE_ID, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2],
	  							 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, FERRIS_DRAW_DISTANCE );

	new x = 0;
	while(x != NUM_FERRIS_CAGES) {
        gFerrisCages[x] = CreateObject( FERRIS_CAGE_ID, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2],
	  							 0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, FERRIS_DRAW_DISTANCE );

        AttachObjectToObject( gFerrisCages[x], gFerrisWheel,
							  gFerrisCageOffsets[x][0],
							  gFerrisCageOffsets[x][1],
	  						  gFerrisCageOffsets[x][2],
							  0.0, 0.0, FERRIS_WHEEL_Z_ANGLE, 0 );
		x++;
	}

	iSpawn_Text = TextDrawCreate(320.0, 380.0, "Continue - I Have Learnt Enough"); // Text is txdfile:texture
	TextDrawUseBox(iSpawn_Text, 1);
	TextDrawBoxColor(iSpawn_Text, 0x00000044);
	TextDrawFont(iSpawn_Text, 3);
	TextDrawSetShadow(iSpawn_Text, 0); // no shadow
	TextDrawSetOutline(iSpawn_Text, 2); // thickness 1
	TextDrawBackgroundColor(iSpawn_Text, 0x000000AA);
	TextDrawColor(iSpawn_Text, 0xFFFFFFFF);
	TextDrawAlignment(iSpawn_Text, 2); // centered
	TextDrawLetterSize(iSpawn_Text, 0.5, 1.5);
	TextDrawTextSize(iSpawn_Text, 32.0, 200.0); // reverse width and height for rockstar (only for centered td's)
	TextDrawSetSelectable(iSpawn_Text, 1);

	for(new ti = 0; ti < sizeof(Team_Info); ti++)
	{
	    if(strlen(Team_Info[ti][TI_Textdraw_S]) == 0) continue;
	    Team_Info[ti][TI_Textdraw] = TextDrawCreate((ti == 0) ? 364.000 : 173.500, 161.500, Team_Info[ti][TI_Textdraw_S]);
		TextDrawFont(Team_Info[ti][TI_Textdraw], 4);
		TextDrawTextSize(Team_Info[ti][TI_Textdraw], 86.500, 77.500);
		TextDrawColor(Team_Info[ti][TI_Textdraw], -1);
		TextDrawSetSelectable(Team_Info[ti][TI_Textdraw], 1);

		Team_Info[ti][TI_Textdraw_N] = TextDrawCreate((ti == 0) ? (364.000 + 43.25) : (173.000 + 43.256), 140.000, Team_Info[ti][TI_Team_Name]);
        TextDrawAlignment(Team_Info[ti][TI_Textdraw_N], 2);
		TextDrawFont(Team_Info[ti][TI_Textdraw_N], 0);
		TextDrawLetterSize(Team_Info[ti][TI_Textdraw_N], 0.5, 1.0);
		TextDrawColor(Team_Info[ti][TI_Textdraw_N], -1);
		TextDrawSetOutline(Team_Info[ti][TI_Textdraw_N], 0);
		TextDrawSetProportional(Team_Info[ti][TI_Textdraw_N], 1);
		TextDrawSetShadow(Team_Info[ti][TI_Textdraw_N], 0);
		TextDrawTextSize(Team_Info[ti][TI_Textdraw_N], 30.0, 50.0);
		TextDrawSetSelectable(Team_Info[ti][TI_Textdraw_N], 1);
	}
	new Float:indexadder = 40.0;
	for(new gameid = 0; gameid < MAX_GAME_LOBBIES; gameid++)
	{
	    gGameData[gameid][g_Gamemode] = random(MAX_GAMEMODES);
	    gGameData[gameid][g_Map_id] = INVALID_MAP_ID;

		gGameData[gameid][g_Gamemode_Time_Text] = TextDrawCreate(607.0, 123.0, "00:00");
		TextDrawAlignment(gGameData[gameid][g_Gamemode_Time_Text], 3);
		TextDrawFont(gGameData[gameid][g_Gamemode_Time_Text], 2);
		TextDrawLetterSize(gGameData[gameid][g_Gamemode_Time_Text], 0.459999, 1.899999);
		TextDrawSetOutline(gGameData[gameid][g_Gamemode_Time_Text], 1);

		gGameData[gameid][g_Lobby_Box] = TextDrawCreate(168.000000, 212.0 + (indexadder * gameid), "_");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Box], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Box], 0.000000, 1.899999);
		TextDrawColor(gGameData[gameid][g_Lobby_Box], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Box], 0);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawUseBox(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawBoxColor(gGameData[gameid][g_Lobby_Box], -741092353);
		TextDrawTextSize(gGameData[gameid][g_Lobby_Box], 562.000000, 22.000000);
		TextDrawSetSelectable(gGameData[gameid][g_Lobby_Box], 1);

		gGameData[gameid][g_Lobby_Name] = TextDrawCreate(166.000, 210.0 + (indexadder * gameid), "Calypso's Terror"); // Calypso's Terror
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Name], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Name], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Name], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Name], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Name], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Name], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Name], 1);
		switch(gameid)
		{
		    case 0: format(gGameData[gameid][g_Lobby_gName], 32, "Sweet Tooth's Carnage");
		    case 1: format(gGameData[gameid][g_Lobby_gName], 32, "Mr. Grimm's Dark Lobby");
		    case 2: format(gGameData[gameid][g_Lobby_gName], 32, "Dollface Madness");
		}
		UpdateLobbyTD(gGameData[gameid][g_Lobby_Name], gGameData[gameid][g_Lobby_gName]);
		gGameData[gameid][g_Lobby_Type] = TextDrawCreate(261.000000, 210.0 + (indexadder * gameid), "Deathmatch"); // Last Man~n~Standing
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Type], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Type], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Type], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Type], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Type], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Type], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Type], 1);

		gGameData[gameid][g_Lobby_Map] = TextDrawCreate(338.000000, 210.0 + (indexadder * gameid), "Downtown"); // Suburbs
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Map], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Map], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Map], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Map], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Map], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Map], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Map], 1);

		gGameData[gameid][g_Lobby_gState] = TextDrawCreate(416.000000, 210.0 + (indexadder * gameid), "IN GAME"); //IN GAME 423
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_gState], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_gState], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_gState], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_gState], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_gState], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_gState], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_gState], 1);

		gGameData[gameid][g_Lobby_Players] = TextDrawCreate(492.000000, 210.0 + (indexadder * gameid), "0/32");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Players], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Players], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Players], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Players], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Players], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Players], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Players], 1);

		gGameData[gameid][g_Lobby_Time] = TextDrawCreate(535.000000, 210.0 + (indexadder * gameid), "10:00");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Time], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Time], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Time], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Time], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Time], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Time], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Time], 1);

		switch(gGameData[gameid][g_Gamemode])
		{
		    case RACE: OnMapBegin(gameid, gGameData[gameid][g_Gamemode], Iter_Random(Race_Maps));
		    default: OnMapBegin(gameid, gGameData[gameid][g_Gamemode], Iter_Random(Maps));
		}
	}
	Players_Online_Textdraw = TextDrawCreate(41.000000, 316.000000, "01");
	TextDrawBackgroundColor(Players_Online_Textdraw, 255);
	TextDrawFont(Players_Online_Textdraw, 1);
	TextDrawLetterSize(Players_Online_Textdraw, 0.330000, 1.500000);
	TextDrawColor(Players_Online_Textdraw, -1);
	TextDrawSetOutline(Players_Online_Textdraw, 1);
	TextDrawSetProportional(Players_Online_Textdraw, 1);
	TextDrawSetShadow(Players_Online_Textdraw, 0);
	TextDrawUseBox(Players_Online_Textdraw, 1);
	TextDrawBoxColor(Players_Online_Textdraw, 150);
	TextDrawTextSize(Players_Online_Textdraw, 56.000000, 0.000000);

	pHud_Box = TextDrawCreate(627.000000, 346.000000, "   ");
	TextDrawBackgroundColor(pHud_Box, 255);
	TextDrawFont(pHud_Box, 0);
	TextDrawLetterSize(pHud_Box, 0.000000, 3.700000);
	TextDrawColor(pHud_Box, -1);
	TextDrawSetOutline(pHud_Box, 0);
	TextDrawSetProportional(pHud_Box, 1);
	TextDrawSetShadow(pHud_Box, 1);
	TextDrawUseBox(pHud_Box, 1);
	TextDrawBoxColor(pHud_Box, 100);
	TextDrawTextSize(pHud_Box, 509.000000, 1.000000);

	pHud_UpArrow = TextDrawCreate(610.000000 - 15, 325.000000 - 15, "ld_beat:up");
	TextDrawFont(pHud_UpArrow, 4);
    TextDrawColor(pHud_UpArrow, 0x0097FCFF);
    TextDrawTextSize(pHud_UpArrow, 16.0, 16.0);

    pHud_LeftArrow = TextDrawCreate(610.000000 - 30, 325.000000, "ld_beat:left");
	TextDrawFont(pHud_LeftArrow, 4);
    TextDrawColor(pHud_LeftArrow, 0x0097FCFF);
    TextDrawTextSize(pHud_LeftArrow, 16.0, 16.0);

	pHud_RightArrow = TextDrawCreate(610.000000, 325.000000, "ld_beat:right");
	TextDrawFont(pHud_RightArrow, 4);
    TextDrawColor(pHud_RightArrow, 0x0097FCFF);
    TextDrawTextSize(pHud_RightArrow, 16.0, 16.0);

    TextDrawSetSelectable(pHud_RightArrow, 1);
	TextDrawSetSelectable(pHud_LeftArrow, 1);
	TextDrawSetSelectable(pHud_UpArrow, 1);

	pHud_HealthSign = TextDrawCreate(607.800000, 347.000000, "+");
	TextDrawBackgroundColor(pHud_HealthSign, 255);
	TextDrawFont(pHud_HealthSign, 1);
	TextDrawLetterSize(pHud_HealthSign, 0.500000, 1.700000);
	TextDrawColor(pHud_HealthSign, -1);
	TextDrawSetOutline(pHud_HealthSign, 0);
	TextDrawSetProportional(pHud_HealthSign, 1);
	TextDrawSetShadow(pHud_HealthSign, 1);

	pHud_BoxSeparater = TextDrawCreate(516.000000, 418.000000, "   ");
	TextDrawBackgroundColor(pHud_BoxSeparater, 255);
	TextDrawFont(pHud_BoxSeparater, 1);
	TextDrawLetterSize(pHud_BoxSeparater, 0.000000, 0.000000);
	TextDrawColor(pHud_BoxSeparater, -1);
	TextDrawSetOutline(pHud_BoxSeparater, 0);
	TextDrawSetProportional(pHud_BoxSeparater, 1);
	TextDrawSetShadow(pHud_BoxSeparater, 1);
	TextDrawUseBox(pHud_BoxSeparater, 1);
	TextDrawBoxColor(pHud_BoxSeparater, 421075400);
	TextDrawTextSize(pHud_BoxSeparater, 621.000000, 1.000000);

	pHud_SecondBox = TextDrawCreate(628.000000, 420.000000, "  ");
	TextDrawBackgroundColor(pHud_SecondBox, 255);
	TextDrawFont(pHud_SecondBox, 1);
	TextDrawLetterSize(pHud_SecondBox, 0.479999, 1.700000);
	TextDrawColor(pHud_SecondBox, -1);
	TextDrawSetOutline(pHud_SecondBox, 0);
	TextDrawSetProportional(pHud_SecondBox, 1);
	TextDrawSetShadow(pHud_SecondBox, 1);
	TextDrawUseBox(pHud_SecondBox, 1);
	TextDrawBoxColor(pHud_SecondBox, 150);
	TextDrawTextSize(pHud_SecondBox, 509.0, 0.0);

	pHud_EnergySign = TextDrawCreate(515.000000, 417.000000, "E");
	TextDrawBackgroundColor(pHud_EnergySign, 255);
	TextDrawFont(pHud_EnergySign, 1);
	TextDrawLetterSize(pHud_EnergySign, 0.500000, 1.05);
	TextDrawColor(pHud_EnergySign, -1);
	TextDrawSetOutline(pHud_EnergySign, 0);
	TextDrawSetProportional(pHud_EnergySign, 1);
	TextDrawSetShadow(pHud_EnergySign, 1);
	TextDrawSetSelectable(pHud_EnergySign, 1);

	pHud_TurboSign = TextDrawCreate(515.000000, 427.000000, "T");
	TextDrawBackgroundColor(pHud_TurboSign, 255);
	TextDrawFont(pHud_TurboSign, 1);
	TextDrawLetterSize(pHud_TurboSign, 0.500000, 1.0);
	TextDrawColor(pHud_TurboSign, -1);
	TextDrawSetOutline(pHud_TurboSign, 0);
	TextDrawSetProportional(pHud_TurboSign, 1);
	TextDrawSetShadow(pHud_TurboSign, 1);

	Navigation_S[0] = TextDrawCreate(34.000000, 203.000000, "Multi-Player");
	TextDrawBackgroundColor(Navigation_S[0], 255);
	TextDrawFont(Navigation_S[0], 2);
	TextDrawLetterSize(Navigation_S[0], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[0], -1);
	TextDrawSetOutline(Navigation_S[0], 0);
	TextDrawSetProportional(Navigation_S[0], 1);
	TextDrawSetShadow(Navigation_S[0], 1);
	TextDrawUseBox(Navigation_S[0], 1);
	TextDrawBoxColor(Navigation_S[0], 0);
	TextDrawTextSize(Navigation_S[0], 205.000000, 25.000000);
	TextDrawSetSelectable(Navigation_S[0], 1);

	Navigation_S[1] = TextDrawCreate(34.000000, 230.000000, "Garage");
	TextDrawBackgroundColor(Navigation_S[1], 255);
	TextDrawFont(Navigation_S[1], 2);
	TextDrawLetterSize(Navigation_S[1], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[1], -1);
	TextDrawSetOutline(Navigation_S[1], 0);
	TextDrawSetProportional(Navigation_S[1], 1);
	TextDrawSetShadow(Navigation_S[1], 1);
	TextDrawUseBox(Navigation_S[1], 1);
	TextDrawBoxColor(Navigation_S[1], 0);
	TextDrawTextSize(Navigation_S[1], 132.000000, 25.000000);
	TextDrawSetSelectable(Navigation_S[1], 1);

	Navigation_S[2] = TextDrawCreate(34.000000, 257.000000, "Options");
	TextDrawBackgroundColor(Navigation_S[2], 255);
	TextDrawFont(Navigation_S[2], 2);
	TextDrawLetterSize(Navigation_S[2], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[2], -1);
	TextDrawSetOutline(Navigation_S[2], 0);
	TextDrawSetProportional(Navigation_S[2], 1);
	TextDrawSetShadow(Navigation_S[2], 1);
	TextDrawUseBox(Navigation_S[2], 1);
	TextDrawBoxColor(Navigation_S[2], 0);
	TextDrawTextSize(Navigation_S[2], 140.000000, 25.000000);
	TextDrawSetSelectable(Navigation_S[2], 1);

	Navigation_S[3] = TextDrawCreate(34.000000, 284.000000, "Help");
	TextDrawBackgroundColor(Navigation_S[3], 255);
	TextDrawFont(Navigation_S[3], 2);
	TextDrawLetterSize(Navigation_S[3], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[3], -1);
	TextDrawSetOutline(Navigation_S[3], 0);
	TextDrawSetProportional(Navigation_S[3], 1);
	TextDrawSetShadow(Navigation_S[3], 1);
	TextDrawUseBox(Navigation_S[3], 1);
	TextDrawBoxColor(Navigation_S[3], 0);
	TextDrawTextSize(Navigation_S[3], 140.000000, 25.000000);
	TextDrawSetSelectable(Navigation_S[3], 1);

	Navigation_S[4] = TextDrawCreate(36.000000, 119.000000, ".");
	TextDrawBackgroundColor(Navigation_S[4], 0);
	TextDrawFont(Navigation_S[4], 3);
	TextDrawLetterSize(Navigation_S[4], 5.879998, 2.799998);
	TextDrawColor(Navigation_S[4], -1);
	TextDrawSetOutline(Navigation_S[4], 1);
	TextDrawSetProportional(Navigation_S[4], 1);

	Navigation_S[5] = TextDrawCreate(89.000000, 119.000000, ".");
	TextDrawBackgroundColor(Navigation_S[5], 0);
	TextDrawFont(Navigation_S[5], 3);
	TextDrawLetterSize(Navigation_S[5], 8.789999, 2.799998);
	TextDrawColor(Navigation_S[5], -1);
	TextDrawSetOutline(Navigation_S[5], 1);
	TextDrawSetProportional(Navigation_S[5], 1);

	Navigation_S[6] = TextDrawCreate(82.000000, 137.000000, ".");
	TextDrawBackgroundColor(Navigation_S[6], 0);
	TextDrawFont(Navigation_S[6], 3);
	TextDrawLetterSize(Navigation_S[6], 7.689995, 2.799998);
	TextDrawColor(Navigation_S[6], -1);
	TextDrawSetOutline(Navigation_S[6], 1);
	TextDrawSetProportional(Navigation_S[6], 1);

	Navigation_S[7] = TextDrawCreate(34.000000, 131.000000, "TwisTed");
	TextDrawBackgroundColor(Navigation_S[7], 0);
	TextDrawFont(Navigation_S[7], 1);
	TextDrawLetterSize(Navigation_S[7], 1.000000, 2.999999);
	TextDrawColor(Navigation_S[7], -1);
	TextDrawSetOutline(Navigation_S[7], 1);
	TextDrawSetProportional(Navigation_S[7], 1);

	Navigation_S[8] = TextDrawCreate(52.000000, 149.000000, "MeTal");
	TextDrawBackgroundColor(Navigation_S[8], 0);
	TextDrawFont(Navigation_S[8], 1);
	TextDrawLetterSize(Navigation_S[8], 1.000000, 2.999999);
	TextDrawColor(Navigation_S[8], -1);
	TextDrawSetOutline(Navigation_S[8], 1);
	TextDrawSetProportional(Navigation_S[8], 1);

	Navigation_Game_S[0] = TextDrawCreate(34.000000, 203.000000, "LOBBIES");
	TextDrawBackgroundColor(Navigation_Game_S[0], 255);
	TextDrawFont(Navigation_Game_S[0], 2);
	TextDrawLetterSize(Navigation_Game_S[0], 0.600000, 2.200001);
	TextDrawColor(Navigation_Game_S[0], -1);
	TextDrawSetOutline(Navigation_Game_S[0], 0);
	TextDrawSetProportional(Navigation_Game_S[0], 1);
	TextDrawSetShadow(Navigation_Game_S[0], 1);

	Navigation_Game_S[1] = TextDrawCreate(234.000000, 140.000000, "Please Select A Lobby Below To Join");
	TextDrawBackgroundColor(Navigation_Game_S[1], 255);
	TextDrawFont(Navigation_Game_S[1], 1);
	TextDrawLetterSize(Navigation_Game_S[1], 0.429999, 1.899999);
	TextDrawColor(Navigation_Game_S[1], -16776961);
	TextDrawSetOutline(Navigation_Game_S[1], 1);
	TextDrawSetProportional(Navigation_Game_S[1], 1);

	Navigation_Game_S[2] = TextDrawCreate(165.000000, 197.000000, "GAME NAME");
	TextDrawBackgroundColor(Navigation_Game_S[2], 255);
	TextDrawFont(Navigation_Game_S[2], 1);
	TextDrawLetterSize(Navigation_Game_S[2], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[2], -1);
	TextDrawSetOutline(Navigation_Game_S[2], 0);
	TextDrawSetProportional(Navigation_Game_S[2], 1);
	TextDrawSetShadow(Navigation_Game_S[2], 1);

	Navigation_Game_S[3] = TextDrawCreate(262.000000, 197.000000, "TYPE");
	TextDrawBackgroundColor(Navigation_Game_S[3], 255);
	TextDrawFont(Navigation_Game_S[3], 1);
	TextDrawLetterSize(Navigation_Game_S[3], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[3], -1);
	TextDrawSetOutline(Navigation_Game_S[3], 0);
	TextDrawSetProportional(Navigation_Game_S[3], 1);
	TextDrawSetShadow(Navigation_Game_S[3], 1);

	Navigation_Game_S[4] = TextDrawCreate(337.000000, 197.000000, "MAP");
	TextDrawBackgroundColor(Navigation_Game_S[4], 255);
	TextDrawFont(Navigation_Game_S[4], 1);
	TextDrawLetterSize(Navigation_Game_S[4], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[4], -1);
	TextDrawSetOutline(Navigation_Game_S[4], 0);
	TextDrawSetProportional(Navigation_Game_S[4], 1);
	TextDrawSetShadow(Navigation_Game_S[4], 1);

	Navigation_Game_S[5] = TextDrawCreate(416.000000, 197.000000, "GAME STATE");
	TextDrawBackgroundColor(Navigation_Game_S[5], 255);
	TextDrawFont(Navigation_Game_S[5], 1);
	TextDrawLetterSize(Navigation_Game_S[5], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[5], -1);
	TextDrawSetOutline(Navigation_Game_S[5], 0);
	TextDrawSetProportional(Navigation_Game_S[5], 1);
	TextDrawSetShadow(Navigation_Game_S[5], 1);

	Navigation_Game_S[6] = TextDrawCreate(489.000000, 197.000000, "PLAYERS");
	TextDrawBackgroundColor(Navigation_Game_S[6], 255);
	TextDrawFont(Navigation_Game_S[6], 1);
	TextDrawLetterSize(Navigation_Game_S[6], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[6], -1);
	TextDrawSetOutline(Navigation_Game_S[6], 0);
	TextDrawSetProportional(Navigation_Game_S[6], 1);
	TextDrawSetShadow(Navigation_Game_S[6], 1);

	Navigation_Game_S[7] = TextDrawCreate(539.000000, 197.000000, "TIME");
	TextDrawBackgroundColor(Navigation_Game_S[7], 255);
	TextDrawFont(Navigation_Game_S[7], 1);
	TextDrawLetterSize(Navigation_Game_S[7], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[7], -1);
	TextDrawSetOutline(Navigation_Game_S[7], 0);
	TextDrawSetProportional(Navigation_Game_S[7], 1);
	TextDrawSetShadow(Navigation_Game_S[7], 1);

    Tutorial_Arrows[0] = TextDrawCreate(73.000, 287.000, "LD_BEAT:down");
    TextDrawFont(Tutorial_Arrows[0], 4);
    TextDrawTextSize(Tutorial_Arrows[0], 28.500, 26.000);
    TextDrawColor(Tutorial_Arrows[0], 0xFF0000FF);

    Tutorial_Arrows[1] = TextDrawCreate(139.000, 344.500, "LD_BEAT:downl");
    TextDrawFont(Tutorial_Arrows[1], 4);
    TextDrawTextSize(Tutorial_Arrows[1], 28.500, 26.000);
    TextDrawColor(Tutorial_Arrows[1], 0xFF0000FF);

    Tutorial_Arrows[2] = TextDrawCreate(143.500, 400.000, "LD_BEAT:downl");
    TextDrawFont(Tutorial_Arrows[2], 4);
    TextDrawTextSize(Tutorial_Arrows[2], 28.500, 26.000);
    TextDrawColor(Tutorial_Arrows[2], 0xFF0000FF);

    Tutorial_Arrows[3] = TextDrawCreate(431.500, 397.000, "LD_BEAT:downr");
    TextDrawFont(Tutorial_Arrows[3], 4);
    TextDrawTextSize(Tutorial_Arrows[3], 28.500, 26.000);
    TextDrawColor(Tutorial_Arrows[3], 0xFF0000FF);

    Tutorial_Arrows[4] = TextDrawCreate(298.000, 397.000, "LD_BEAT:down");
    TextDrawFont(Tutorial_Arrows[4], 4);
    TextDrawTextSize(Tutorial_Arrows[4], 28.500, 26.000);
    TextDrawColor(Tutorial_Arrows[4], 0xFF0000FF);

    Tutorial_Arrows[5] = TextDrawCreate(494.500, 415.000, "LD_BEAT:right");
    TextDrawFont(Tutorial_Arrows[5], 4);
    TextDrawTextSize(Tutorial_Arrows[5], 17.500, 13.000);
    TextDrawColor(Tutorial_Arrows[5], 0xFF0000FF);

    Tutorial_Arrows[6] = TextDrawCreate(494.500, 427.000, "LD_BEAT:right");
    TextDrawFont(Tutorial_Arrows[6], 4);
    TextDrawTextSize(Tutorial_Arrows[6], 17.500, 13.000);
    TextDrawColor(Tutorial_Arrows[6], 0xFF0000FF);

    Tutorial_Arrows[7] = TextDrawCreate(494.500, 344.500, "LD_BEAT:right");
    TextDrawFont(Tutorial_Arrows[7], 4);
    TextDrawTextSize(Tutorial_Arrows[7], 17.500, 13.000);
    TextDrawColor(Tutorial_Arrows[7], 0xFF0000FF);

    Tutorial_Arrows[8] = TextDrawCreate(625.000, 349.000, "LD_BEAT:left");
    TextDrawFont(Tutorial_Arrows[8], 4);
    TextDrawTextSize(Tutorial_Arrows[8], 14.500, 13.000);
    TextDrawColor(Tutorial_Arrows[8], 0xFF0000FF);

    Tutorial_Arrows[9] = TextDrawCreate(527.500, 131.500 - 3.0, "LD_BEAT:right");
    TextDrawFont(Tutorial_Arrows[9], 4);
    TextDrawTextSize(Tutorial_Arrows[9], 19.000, 14.500);
    TextDrawColor(Tutorial_Arrows[9], 0xFF0000FF);

    Tutorial_Numbers[0] = TextDrawCreate(81.000000, 278.000000, "1");
	TextDrawBackgroundColor(Tutorial_Numbers[0], 255);
	TextDrawFont(Tutorial_Numbers[0], 1);
	TextDrawLetterSize(Tutorial_Numbers[0], 0.500000, 1.000000);
	TextDrawColor(Tutorial_Numbers[0], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[0], 0);
	TextDrawSetProportional(Tutorial_Numbers[0], 1);
	TextDrawSetShadow(Tutorial_Numbers[0], 1);

	Tutorial_Numbers[1] = TextDrawCreate(162.000000, 344.000000, "2");
	TextDrawBackgroundColor(Tutorial_Numbers[1], 255);
	TextDrawFont(Tutorial_Numbers[1], 1);
	TextDrawLetterSize(Tutorial_Numbers[1], 0.500000, 1.100000);
	TextDrawColor(Tutorial_Numbers[1], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[1], 0);
	TextDrawSetProportional(Tutorial_Numbers[1], 1);
	TextDrawSetShadow(Tutorial_Numbers[1], 1);

	Tutorial_Numbers[2] = TextDrawCreate(164.500000, 397.500000, "3");
	TextDrawBackgroundColor(Tutorial_Numbers[2], 255);
	TextDrawFont(Tutorial_Numbers[2], 1);
	TextDrawLetterSize(Tutorial_Numbers[2], 0.500000, 1.100000);
	TextDrawColor(Tutorial_Numbers[2], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[2], 0);
	TextDrawSetProportional(Tutorial_Numbers[2], 1);
	TextDrawSetShadow(Tutorial_Numbers[2], 1);

	Tutorial_Numbers[3] = TextDrawCreate(307.000000, 386.000000, "4");
	TextDrawBackgroundColor(Tutorial_Numbers[3], 255);
	TextDrawFont(Tutorial_Numbers[3], 1);
	TextDrawLetterSize(Tutorial_Numbers[3], 0.500000, 1.100000);
	TextDrawColor(Tutorial_Numbers[3], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[3], 0);
	TextDrawSetProportional(Tutorial_Numbers[3], 1);
	TextDrawSetShadow(Tutorial_Numbers[3], 1);

	Tutorial_Numbers[4] = TextDrawCreate(428.000000, 393.000000, "5");
	TextDrawBackgroundColor(Tutorial_Numbers[4], 255);
	TextDrawFont(Tutorial_Numbers[4], 1);
	TextDrawLetterSize(Tutorial_Numbers[4], 0.500000, 1.100000);
	TextDrawColor(Tutorial_Numbers[4], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[4], 0);
	TextDrawSetProportional(Tutorial_Numbers[4], 1);
	TextDrawSetShadow(Tutorial_Numbers[4], 1);

	Tutorial_Numbers[5] = TextDrawCreate(483.000000, 427.000000, "6");
	TextDrawBackgroundColor(Tutorial_Numbers[5], 255);
	TextDrawFont(Tutorial_Numbers[5], 1);
	TextDrawLetterSize(Tutorial_Numbers[5], 0.449999, 1.200000);
	TextDrawColor(Tutorial_Numbers[5], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[5], 0);
	TextDrawSetProportional(Tutorial_Numbers[5], 1);
	TextDrawSetShadow(Tutorial_Numbers[5], 1);

	Tutorial_Numbers[6] = TextDrawCreate(483.000000, 416.000000, "7");
	TextDrawBackgroundColor(Tutorial_Numbers[6], 255);
	TextDrawFont(Tutorial_Numbers[6], 1);
	TextDrawLetterSize(Tutorial_Numbers[6], 0.449999, 1.200000);
	TextDrawColor(Tutorial_Numbers[6], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[6], 0);
	TextDrawSetProportional(Tutorial_Numbers[6], 1);
	TextDrawSetShadow(Tutorial_Numbers[6], 1);

	Tutorial_Numbers[7] = TextDrawCreate(483.000000, 345.000000, "8");
	TextDrawBackgroundColor(Tutorial_Numbers[7], 255);
	TextDrawFont(Tutorial_Numbers[7], 1);
	TextDrawLetterSize(Tutorial_Numbers[7], 0.430000, 1.200000);
	TextDrawColor(Tutorial_Numbers[7], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[7], 0);
	TextDrawSetProportional(Tutorial_Numbers[7], 1);
	TextDrawSetShadow(Tutorial_Numbers[7], 1);

	Tutorial_Numbers[8] = TextDrawCreate(628.000000, 360.000000, "9");
	TextDrawBackgroundColor(Tutorial_Numbers[8], 255);
	TextDrawFont(Tutorial_Numbers[8], 1);
	TextDrawLetterSize(Tutorial_Numbers[8], 0.430000, 1.200000);
	TextDrawColor(Tutorial_Numbers[8], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[8], 0);
	TextDrawSetProportional(Tutorial_Numbers[8], 1);
	TextDrawSetShadow(Tutorial_Numbers[8], 1);

	Tutorial_Numbers[9] = TextDrawCreate(510.000000, 133.000000 - 3.0, "10");
	TextDrawBackgroundColor(Tutorial_Numbers[9], 255);
	TextDrawFont(Tutorial_Numbers[9], 1);
	TextDrawLetterSize(Tutorial_Numbers[9], 0.430000, 1.200000);
	TextDrawColor(Tutorial_Numbers[9], 0xFF0000FF);
	TextDrawSetOutline(Tutorial_Numbers[9], 0);
	TextDrawSetProportional(Tutorial_Numbers[9], 1);
	TextDrawSetShadow(Tutorial_Numbers[9], 1);

	for(new tm = 0; tm != MAX_TWISTED_VEHICLES; tm++)
	{
		new id = AddStaticVehicle(C_S_IDS[tm][CS_VehicleModelID], 0.0 + x, 0.0 + x, 0.0 + x, 0.0, 0, 0);
		DestroyVehicle(id);
		AddPlayerClass(C_S_IDS[tm][CS_SkinID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE, 0, 0, 0, 0, 0, 0);
	}
	printf("[System] Gamemode Loaded In: %d ms - Tickcount: %d", (GetTickCount() - StartTick), tickcount());
	return 1;
}

public OnGameModeExit()
{
    #if USE_MYSQL == (true)
	mysql_close();
	#endif
	printf("[Heapspace - OnGameModeExit] - heapspace(): %i - Heapspace: %i kilobytes", heapspace(), heapspace() / 1024);
    MapAndreas_Unload();
	Iter_Clear(Vehicles);
	#if USE_SPEED_UPDATE == (true)
	KillTimer(g_SpeedUpTimer);
	#endif
	for(new ta = 0, tas = sizeof(Tutorial_Arrows); ta < tas; ta++)
	{
		TextDrawHideForAll(Tutorial_Arrows[ta]);
    	TextDrawDestroy(Tutorial_Arrows[ta]);
    	TextDrawHideForAll(Tutorial_Numbers[ta]);
    	TextDrawDestroy(Tutorial_Numbers[ta]);
    }
	TextDrawHideForAll(pHud_Box);
	TextDrawHideForAll(pHud_UpArrow);
	TextDrawHideForAll(pHud_LeftArrow);
	TextDrawHideForAll(pHud_RightArrow);
	TextDrawHideForAll(pHud_HealthSign);
	TextDrawHideForAll(pHud_BoxSeparater);
	TextDrawHideForAll(pHud_SecondBox);
	TextDrawHideForAll(pHud_EnergySign);
	TextDrawHideForAll(pHud_TurboSign);
	TextDrawDestroy(pHud_Box);
	TextDrawDestroy(pHud_UpArrow);
	TextDrawDestroy(pHud_LeftArrow);
    TextDrawDestroy(pHud_RightArrow);
	TextDrawDestroy(pHud_HealthSign);
	TextDrawDestroy(pHud_BoxSeparater);
	TextDrawDestroy(pHud_SecondBox);
	TextDrawDestroy(pHud_EnergySign);
	TextDrawDestroy(pHud_TurboSign);
	for(new gameid = 0; gameid < MAX_GAME_LOBBIES; gameid++)
	{
		TextDrawHideForAll(gGameData[gameid][g_Gamemode_Time_Text]);
		TextDrawDestroy(gGameData[gameid][g_Gamemode_Time_Text]);
	}
	TextDrawHideForAll(Players_Online_Textdraw);
	TextDrawDestroy(Players_Online_Textdraw);
	IRC_Quit(gBotID[0], "Gamemode Exiting - Goodbye!");
	IRC_DestroyGroup(gGroupID);
	for(new p = 0, sp = sizeof(PickupInfo); p < sp; p++)
	{
 		if(PickupInfo[p][Pickupid] == -1) continue;
		DestroyPickupEx(p);
	}
    DestroyObject(gFerrisWheel);
    DestroyObject(gFerrisBase);
    new x = 0;
	while(x != NUM_FERRIS_CAGES) {
	    DestroyObject(gFerrisCages[x]);
		x++;
	}
	new o = 0, extra;
	do
	{
	    extra = o;
	    if(IsValidObject(extra))
	    {
	    	DestroyObject(extra);
	    }
	    o++;
	}
	while (o < MAX_OBJECTS);
	new t = 0;
	do
	{
	    extra = t;
	    KillTimer(extra);
	    t++;
	}
	while (t != 1000);
	foreach(Player, i)
	{
	    if(i >= MAX_PLAYERS) break;
		for(new st = 0; st < sizeof(StatusTextPositions); st++)
	    {
			KillTimer(pStatusInfo[i][StatusTextTimer][st]);
		}
		PlayerTextDrawDestroy(i, pTextInfo[i][pHealthBar]);
		for(new m = 0; m < (MAX_MISSILEID); m++) {
		    PlayerTextDrawHide(i, pTextInfo[i][pMissileSign][m]);
			PlayerTextDrawDestroy(i, pTextInfo[i][pMissileSign][m]);
		}
		PlayerTextDrawDestroy(i, pTextInfo[i][pLevelText]);
		PlayerTextDrawDestroy(i, pTextInfo[i][pEXPText]);
		DestroyPlayerProgressBar(i, pTextInfo[i][pTurboBar]);
		DestroyPlayerProgressBar(i, pTextInfo[i][pEnergyBar]);
		DestroyPlayerProgressBar(i, pTextInfo[i][pChargeBar]);
		DestroyPlayerProgressBar(i, pTextInfo[i][pExprienceBar]);
		DestroyPlayerProgressBar(i, pTextInfo[i][pAiming_Health_Bar]);
		//for(new t = 0; t != 15; t++)
		//{
		//	TextDrawDestroy(pTextInfo[i][TDSpeedClock][t]);
		//}
	 	i ++;
	}
	//SendRconCommand("unloadfs Twisted_Pic");
	printf("[System] - Twisted Metal: SA-MP Exited Succesfully");
	return 1;
}
#if USE_SPEED_UPDATE == (true)
forward SpeedUp();
public SpeedUp() {
    new
        vehicleid,
        keys,
        lr,
        Float:vx,
        Float:vy,
        Float:vz
    ;
    // Loop all players
    foreach(Player, playerid)
	{
        // Store the value from GetPlayerVehicleID and continue if it's not 0
        if ((vehicleid = GetPlayerVehicleID(playerid)))
		{
            // Get the player keys (vx is used here because we don't need updown/leftright)
            GetPlayerKeys(playerid, keys, _:vx, lr);

            // If KEY_VEHICLE_FORWARD is pressed, but not KEY_VEHICLE_BACKWARD or KEY_HANDBRAKE.
            if ((keys & (KEY_VEHICLE_FORWARD | KEY_VEHICLE_BACKWARD | KEY_HANDBRAKE)) == KEY_VEHICLE_FORWARD)
			{
                // Get the velocity
                GetVehicleVelocity(vehicleid, vx, vy, vz);

                // Don't do anything if the vehicle is going slowly
                if (vx * vx + vy * vy < g_SpeedThreshold) continue;

                // Increase the X and Y velocity
                vx *= SPEED_MULTIPLIER;
                vy *= SPEED_MULTIPLIER;

                // Increase the Z velocity to make up for lost gravity, if needed.
                if (vz > 0.04 || vz < -0.04)
                    vz -= 0.015;

                // Now set it
                SetVehicleVelocity(vehicleid, vx, vy, vz);
            }
            /*if (lr != 0 && (keys & (KEY_VEHICLE_FORWARD | KEY_VEHICLE_BACKWARD | KEY_HANDBRAKE) != KEY_VEHICLE_BACKWARD))
            {
                GetVehicleVelocity(vehicleid, vx, vy, vz);
                SendClientMessageFormatted(playerid, -1,
				"vx: %0.2f - vx after: %0.2f - lr: %d", vx, (vx * 0.08), lr);
                vx *= 0.08;
                SetVehicleAngularVelocity(vehicleid, 0.0, 0.0, (lr == 128) ? vx : -vx);
            }*/
        }
    }
}
#endif

stock TemporaryRaceQuitList(playerid = INVALID_PLAYER_ID, action = 0)
{ // INSERT INTO `Race_Temp_Quit_List`(`Username`, `Checkpoint_Index`) VALUES ('Kar', 2)
	switch(action)
	{
	    case 0: // TRQL_ACTION_INSERT
	    {
			format(GlobalQuery, sizeof(GlobalQuery), "INSERT INTO `Race_Temp_Quit_List`(`Username`, `Checkpoint_Index`) VALUES ('%s', %d)", Playername(playerid), CP_Progress[playerid] - 1);
			mysql_function_query(McHandle, GlobalQuery, false, "Thread_NoReturnThread", "i", playerid);
		}
		case 1: // TRQL_ACTION_SELECT_AND_DELETE
	    {
	        format(GlobalQuery, sizeof(GlobalQuery), "SELECT `Checkpoint_Index` FROM `Race_Temp_Quit_List` WHERE `Username` = '%s' LIMIT 0,1", Playername(playerid));
			mysql_function_query(McHandle, GlobalQuery, true, "Thread_LoadTempRaceQuitList", "i", playerid);
		}
		case 2: // TRQL_ACTION_CLEAR
	    {
			mysql_function_query(McHandle, "DELETE FROM `Race_Temp_Quit_List`", false, "Thread_NoReturnThread", "i", playerid);
		}
	}
	return 1;
}
THREAD:LoadTempRaceQuitList(playerid)
{
	new rows, fields, data[12];
	cache_get_data(rows, fields, McHandle);
	if(rows > 0)
	{
	    cache_get_field_content(0, "Checkpoint_Index", data, McHandle);
	    CP_Progress[playerid] = strval(data);
	    format(GlobalQuery, sizeof(GlobalQuery), "DELETE FROM `Race_Temp_Quit_List` WHERE `Username` = '%s' LIMIT 1", Playername(playerid));
		mysql_function_query(McHandle, GlobalQuery, false, "Thread_NoReturnThread", "i", playerid);
	}
	return 1;
}

stock SavePlayerAccount(playerid)
{
    if(IsLogged[playerid] == 0) return 1;
	new Query[512];//, Escape[MAX_PLAYER_NAME];
	format(Query, sizeof(Query), "UPDATE `Accounts` SET `Money`=%d",
		PlayerInfo[playerid][Money]
	);

	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ADMIN)) {
		format(Query, sizeof(Query), "%s,`AdminLevel`=%d", Query, PlayerInfo[playerid][AdminLevel]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ADMIN);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLS)) {
		format(Query, sizeof(Query), "%s,`Kills`=%d", Query, PlayerInfo[playerid][Kills]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_DEATHS)) {
		format(Query, sizeof(Query), "%s,`Deaths`=%d", Query, PlayerInfo[playerid][Deaths]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_DEATHS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ASSISTS)) {
		format(Query, sizeof(Query), "%s,`Assists`=%d", Query, PlayerInfo[playerid][Assists]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ASSISTS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLSTREAKS)) {
		format(Query, sizeof(Query), "%s,`pKillStreaks`=%d", Query, PlayerInfo[playerid][pKillStreaks]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLSTREAKS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_EXPRIENCE)) {
		format(Query, sizeof(Query), "%s,`pExprience`=%d", Query, PlayerInfo[playerid][pExprience]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_EXPRIENCE);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LAST_EXPRIENCE)) {
		format(Query, sizeof(Query), "%s,`pLast_Exp_Gained`=%d", Query, PlayerInfo[playerid][pLast_Exp_Gained]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LAST_EXPRIENCE);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LEVEL)) {
		format(Query, sizeof(Query), "%s,`pLevel`=%d,`pTier_Points`=%d", Query, PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pTier_Points]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LEVEL);
	}
	format(Query, sizeof(Query), "%s WHERE `Username` = '%s' LIMIT 1", Query, Playername(playerid));
	mysql_function_query(McHandle, Query, false, "Thread_NoReturnThread", "i", playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(playerid >= MAX_PLAYERS) return 0;
	#if defined RNPC_INCLUDED
	if(IsRNPC[playerid] != -1)
	{
	    new npcid = IsRNPC[playerid];
	    Twisted_NPCS[npcid][t_NPCID] = INVALID_PLAYER_ID;
	    if(IsValidVehicle(Twisted_NPCS[npcid][t_NPCVehicle]))
	    {
	        DestroyVehicle(Twisted_NPCS[npcid][t_NPCVehicle]);
	    }
	    Twisted_NPCS[npcid][t_NPCVehicle] = 0;
	    KillTimer(Twisted_NPCS[npcid][t_NPCTimer]);
	    Twisted_NPCS[npcid][t_NPCTimer] = 0;
	    Twisted_NPC_Names_Used[npcid] = 0;
	    IsRNPC[playerid] = -1;
	}
	#endif
    SavePlayerAccount(playerid);
    UpdatePlayerDate(playerid);
    if(PlayerInfo[playerid][gGameID] != INVALID_GAME_ID)
    {
        gGameData[PlayerInfo[playerid][gGameID]][g_Players]--;
        TextDrawHideForPlayer(playerid, gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Time_Text]);
	    switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	    {
	        case RACE:
	        {
	            if((0 <= gGameData[PlayerInfo[playerid][gGameID]][g_Map_id] <= (MAX_MAPS - 1)))
				{
			    	CP_Progress[playerid] = s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Max_Grids];
			    }
			    if(1 <= Race_Position[playerid] <= 3)
			    {
			        foreach(Player, i)
					{
			        	PlayerTextDrawHide(i, Race_Box_Text[i][Race_Position[playerid] - 1]);
			        }
			    }
			    TemporaryRaceQuitList(playerid, .action = 0);
			}
			case DEATHMATCH, HUNTED:
			{
			    if(1 <= p_Position[playerid] <= 3)
			    {
			        foreach(Player, i)
					{
			        	PlayerTextDrawHide(i, Race_Box_Text[i][p_Position[playerid] - 1]);
			        }
			    }
			    if(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode] == HUNTED)
			    {
			        if(gHunted_Player[0] == playerid)
			        {
			            if(Iter_Count(Player) > 0)
			            {
				            gHunted_Player[0] = Iter_Random(Player);
				            if(IsPlayerConnected(gHunted_Player[0]))
				            {
					  			if(PlayerInfo[gHunted_Player[0]][pSpawned] == 1)
					  			{
					  			    new engine, lights, alarm, doors, bonnet, boot, objective;
									GetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, objective);
									SetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
					  			}
				  			}
			  			}
			        }
			    }
			}
			case LAST_MAN_STANDING:
			{
				new count = 0;
			    foreach(Player, i)
			    {
			        if(i == playerid) continue;
			        if(PlayerInfo[i][pSpawned] == 1) continue;
			        count++;
			    }
			    if(count == 1)
			    {
			        OnMapFinish(PlayerInfo[playerid][gGameID], gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode], gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]);
			    }
			}
			case TEAM_LAST_MAN_STANDING:
			{
			    if(PlayerInfo[playerid][gTeam] != INVALID_GAME_TEAM)
				{
					gTeam_Player_Count[PlayerInfo[playerid][gTeam]]--;
				}
				foreach(Player, i)
				{
					if(i == playerid) continue;
				    UpdatePlayerLMSTeamInfo(playerid);
				}
			}
		}
	}
	ResetPlayerVars(playerid);
    //ModelPlayerDisconnect(playerid);
    new vehicleid = Current_Vehicle[playerid];
    KillTimer(Mine_Timer[playerid]);
	for(new s = 0; s < MAX_MISSILE_SLOTS; s++)
	{
        if(Vehicle_Missile_Following[vehicleid][s] != INVALID_VEHICLE_ID) Vehicle_Missile_Following[vehicleid][s] = INVALID_VEHICLE_ID;
        if(IsValidObject(Vehicle_Missile[vehicleid][s]))
		{
		    Object_Owner[Vehicle_Missile[vehicleid][s]] = INVALID_VEHICLE_ID;
	      	Object_OwnerEx[Vehicle_Missile[vehicleid][s]] = INVALID_PLAYER_ID;
	      	Object_Type[Vehicle_Missile[vehicleid][s]] = -1;
	      	Object_Slot[Vehicle_Missile[vehicleid][s]] = -1;
			DestroyObject(Vehicle_Missile[vehicleid][s]);
			Vehicle_Missile[vehicleid][s] = INVALID_OBJECT_ID;
		}
		if(IsValidObject(Vehicle_Smoke[vehicleid][s]))
		{
			DestroyObject(Vehicle_Smoke[vehicleid][s]);
			Vehicle_Smoke[vehicleid][s] = INVALID_OBJECT_ID;
		}
    }
    Vehicle_Missile_Reset_Fire_Time[vehicleid] = 0;
    Vehicle_Missile_Reset_Fire_Slot[vehicleid] = -1;
    ResetTwistedVars(playerid);
    for(new st = 0; st < sizeof(StatusTextPositions); st++)
    {
		KillTimer(pStatusInfo[playerid][StatusTextTimer][st]);
	}
	for(new xp = 0; xp < MAX_XP_STATUSES; xp++)
	{
		PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pEXPStatus][xp]);
	}
	TextDrawHideForPlayer(playerid, Players_Online_Textdraw);
    DestroyVehicle(Current_Vehicle[playerid]);
    Current_Vehicle[playerid] = 0;
    DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pAiming_Health_Bar]);
	for(new sp = 0; sp < MAX_SPECIAL_OBJECTS; sp++)
	{
	    if(IsValidObject(PlayerInfo[playerid][pSpecialObjects][sp]))
		{
			DestroyObject(PlayerInfo[playerid][pSpecialObjects][sp]);
			PlayerInfo[playerid][pSpecialObjects][sp] = INVALID_OBJECT_ID;
		}
	}
	if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
    {
        DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
        PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
    }
    new string[90];
    switch(reason)
    {
        case 0: format(string, sizeof(string), "%s(%d) Has Left The Server - (Timeout / Crash)", Playername(playerid), playerid);
        case 1: format(string, sizeof(string), "%s(%d) Has Left The Server - (Leaving / Quit)", Playername(playerid), playerid);
        case 2: format(string, sizeof(string), "%s(%d) Has Left The Server - (Kicked / Banned)", Playername(playerid), playerid);
    }
    if(!IsPlayerNPC(playerid))
	{
		SendClientMessageToAll(system, string);
	}
    pName[playerid] = " - ";
	return 1;
}

stock RemoveDowntownMisc(playerid)
{
    RemoveBuildingForPlayer(playerid, 10937, -1904.0547, -855.6172, 38.0625, 0.25);
	RemoveBuildingForPlayer(playerid, 11067, -1904.0547, -855.6172, 38.0625, 0.25);
	RemoveBuildingForPlayer(playerid, 11134, -1904.0078, -1093.6875, 35.7422, 0.25);
	RemoveBuildingForPlayer(playerid, 11278, -1904.0078, -1093.6875, 35.7422, 0.25);
	RemoveBuildingForPlayer(playerid, 3818, -1904.0547, -817.2500, 49.9531, 0.25);
	RemoveBuildingForPlayer(playerid, 705, -2053.6172, -726.0938, 31.4453, 0.25);
	RemoveBuildingForPlayer(playerid, 703, -2196.5703, -945.7422, 36.3516, 0.25);
	RemoveBuildingForPlayer(playerid, 703, -2181.4063, -941.1875, 36.3516, 0.25);
	RemoveBuildingForPlayer(playerid, 672, -2144.4141, -984.7969, 31.8750, 0.25);
	RemoveBuildingForPlayer(playerid, 672, -2138.0234, -993.5781, 31.8750, 0.25);
	RemoveBuildingForPlayer(playerid, 671, -2060.5859, -995.3125, 31.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 703, -2054.0391, -992.7109, 31.0547, 0.25);
	RemoveBuildingForPlayer(playerid, 671, -2047.4531, -983.6797, 31.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 671, -2045.1484, -992.1797, 31.2578, 0.25);
	RemoveBuildingForPlayer(playerid, 669, -2011.3203, -988.3438, 31.4375, 0.25);
	RemoveBuildingForPlayer(playerid, 703, -2034.8516, -738.1797, 31.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 669, -2000.8516, -990.1250, 31.4375, 0.25);
	RemoveBuildingForPlayer(playerid, 703, -2023.7344, -728.7734, 31.1563, 0.25);
	RemoveBuildingForPlayer(playerid, 1290, -1987.8438, -941.1719, 36.9375, 275.0);
	RemoveBuildingForPlayer(playerid, 673, -1987.7500, -951.3047, 31.0156, 275.0);
	return 1;
}

#if !defined MAX_JOIN_LOGS
        #define MAX_JOIN_LOGS (35)
#endif

enum e_JoinLog {
        e_iIP,
        e_iTimeStamp
};

static stock
        g_eaJoinLog[MAX_JOIN_LOGS][e_JoinLog]
;

forward OnPlayerFloodControl(playerid, iCount, iTimeSpan);
public OnPlayerFloodControl(playerid, iCount, iTimeSpan) {
    if(iCount > 2 && iTimeSpan < 10000)
	{
        MessageToAdmins(COLOR_ADMIN, "[Flood Control] %s(%d) Banned - Count: %d - Time: %d", Playername(playerid), playerid, iCount, iTimeSpan);
        printf("[Flood Control] %s(%d) Banned - Count: %d - Time: %d", Playername(playerid), playerid, iCount, iTimeSpan);
		Ban(playerid);
    }
    return 1;
}

stock Flood_Control(playerid)
{
    static s_iJoinSeq;
    new szIP[16] ;
    GetPlayerIp(playerid, szIP, sizeof(szIP));

    g_eaJoinLog[s_iJoinSeq][e_iIP] = szIP[0] = IpToInt(szIP);
    g_eaJoinLog[s_iJoinSeq][e_iTimeStamp] = GetTickCount();

    s_iJoinSeq = ++s_iJoinSeq % MAX_JOIN_LOGS;

    szIP[1] = szIP[2] = 0;
    szIP[3] = -1;

    for(new i = 0; i < MAX_JOIN_LOGS; ++i) {
        if(g_eaJoinLog[i][e_iIP] != szIP[0]) {
                continue;
        }
        szIP[1]++;

        if(szIP[3] != -1) {
                szIP[2] += floatround(floatabs(g_eaJoinLog[i][e_iTimeStamp] - g_eaJoinLog[szIP[3]][e_iTimeStamp]));
        }
        szIP[3] = i;
    }
    CallRemoteFunction("OnPlayerFloodControl", "iii", playerid, szIP[1], szIP[2]);
	return 1;
}

static stock IpToInt(const szIP[]) {
    new aiBytes[4 char], iPos = 0 ;
    aiBytes{0} = strval(szIP[iPos]);
    while(szIP[iPos] != EOS && szIP[iPos++] != '.') {}
    aiBytes{1} = strval(szIP[iPos]);
    while(szIP[iPos] != EOS && szIP[iPos++] != '.') {}
    aiBytes{2} = strval(szIP[iPos]);
    while(szIP[iPos] != EOS && szIP[iPos++] != '.') {}
    aiBytes{3} = strval(szIP[iPos]);
    return aiBytes[0];
}

public OnPlayerConnect(playerid)
{
    GetPlayerName(playerid, pName[playerid], MAX_PLAYER_NAME);
    if(IsPlayerNPC(playerid))
	{
	    new ip[17], sip[17];
	    GetPlayerIp(playerid, ip, sizeof(ip));
		GetServerVarAsString("bind", sip, sizeof(sip));
		if(sip[0] == 0)
		{
		    sip = "127.0.0.1";
		}
	    if(strcmp(ip, sip, false) != 0)
	    {
		    printf("[System: NPC] - Illegal NPC Connecting From %s", ip);
		    //Kick(playerid);
	    }
	    #if defined RNPC_INCLUDED
	    for(new i = 0; i < sizeof(Twisted_NPCS); i++)
		{
		    if(strcmp(pName[playerid], Twisted_NPC_Names[i], false) == 0)
		    {
		        Twisted_NPCS[i][t_NPCID] = playerid;
				IsRNPC[Twisted_NPCS[i][t_NPCID]] = i;
			    strmid(Twisted_NPCS[i][t_Name], pName[playerid], false, strlen(pName[playerid]), MAX_PLAYER_NAME);
			    if(Twisted_NPCS[i][t_NPCVehicle] == 0)
				{
				    Twisted_NPCS[i][t_NPCVehicle] = CreateVehicle(Roadkill, 0.0, 0.0, 3.0, 0.0, -1, -1, 0);
				}
				printf("[RNPC: OnPlayerConnect] - %s(%d)", Playername(playerid), playerid);
				break;
		    }
		}
		#endif
	    return 1;
	}
	Flood_Control(playerid);
	SetPlayerColor(playerid, 0xFFFFFFFF);
    SendClientMessage(playerid, ANNOUNCEMENT, "{FF0000}Warning: {a9c4e4}The concept in this server and GTA in general may be considered Explicit Material.");
    SendClientMessage(playerid, ANNOUNCEMENT, "{FF0000}Concept: {a9c4e4}Twisted Metal: SA-MP is a demolition derby that permits the usage of ballistic projectiles.");
    SendClientMessage(playerid, ANNOUNCEMENT, "{FF0000}Note: {a9c4e4}This Server uses A mix of Title Case And Sentence case.");
    SendClientMessage(playerid, ANNOUNCEMENT, "{FF0000}Website: {a9c4e4}tm.lvcnr.net.");
	new str[64];
	format(str, sizeof(str), "%s(%d) Has Joined The Server.", Playername(playerid), playerid);
	SendClientMessageToAll(LIGHTGREY, str);
	format(str, sizeof(str), "%02d", Iter_Count(Player));
	TextDrawSetString(Players_Online_Textdraw, str);

	Muted[playerid] = 0;
	IsLogged[playerid] = 0;
	PlayerInfo[playerid][gGameID] = INVALID_GAME_ID;
	//DeActiveSpeedometer{playerid} = 0;
	PlayerInfo[playerid][pSpawned] = 0;
	ResetPlayerVars(playerid);
	ResetTwistedVars(playerid);
	new i = playerid;

	pTextInfo[i][pTextWrapper] = CreatePlayerTextDraw(playerid, 0.0, 0.0, "Wrapper");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[i][pTextWrapper], 0x00);
	PlayerTextDrawColor(playerid, pTextInfo[i][pTextWrapper], 0x00);

   	pTextInfo[i][AimingPlayer] = CreatePlayerTextDraw(playerid, 102.000000, 314.000000, "Roadkill");
	PlayerTextDrawAlignment(playerid, pTextInfo[i][AimingPlayer], 2);
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[i][AimingPlayer], 255);
	PlayerTextDrawFont(playerid, pTextInfo[i][AimingPlayer], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[i][AimingPlayer], 0.310000, 1.000000);
	PlayerTextDrawColor(playerid, pTextInfo[i][AimingPlayer], -1);
	PlayerTextDrawSetOutline(playerid, pTextInfo[i][AimingPlayer], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[i][AimingPlayer], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[i][AimingPlayer], 1);

	pTextInfo[i][AimingBox] = CreatePlayerTextDraw(playerid, 152.000000, 316.000000, "_");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[i][AimingBox], 255);
	PlayerTextDrawFont(playerid, pTextInfo[i][AimingBox], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[i][AimingBox], 1.130000, 1.500000);
	PlayerTextDrawColor(playerid, pTextInfo[i][AimingBox], -1);
	PlayerTextDrawSetOutline(playerid, pTextInfo[i][AimingBox], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[i][AimingBox], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[i][AimingBox], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[i][AimingBox], 1);
	PlayerTextDrawBoxColor(playerid, pTextInfo[i][AimingBox], 150);
	PlayerTextDrawTextSize(playerid, pTextInfo[i][AimingBox], 56.000000, 1.000000);

	pTextInfo[i][pHealthBar] = CreatePlayerTextDraw(playerid, 627.000000, 418.000000, "  ");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[i][pHealthBar], 65535);
	PlayerTextDrawFont(playerid, pTextInfo[i][pHealthBar], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[i][pHealthBar], 0.0, -8.60);
	PlayerTextDrawColor(playerid, pTextInfo[i][pHealthBar], 16711935);
	PlayerTextDrawSetOutline(playerid, pTextInfo[i][pHealthBar], 1);
	PlayerTextDrawSetProportional(playerid, pTextInfo[i][pHealthBar], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[i][pHealthBar], 1);
	PlayerTextDrawBoxColor(playerid, pTextInfo[i][pHealthBar], 0x00F000FF);
	PlayerTextDrawTextSize(playerid, pTextInfo[i][pHealthBar], 598.000000, 0.000000);

	pTextInfo[playerid][pLevelText] = CreatePlayerTextDraw(playerid, 115.000000, 426.000000, "Level: 1");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pLevelText], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pLevelText], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pLevelText], 0.360, 1.0);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pLevelText], 0xB3B3B3FF);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pLevelText], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pLevelText], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pLevelText], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pLevelText], 0);

	pTextInfo[playerid][pEXPText] = CreatePlayerTextDraw(playerid, 448.000000, 425.000000, "XP: 0");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pEXPText], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pEXPText], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pEXPText], 0.30, 0.899999);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pEXPText], 0xB3B3B3FF);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pEXPText], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pEXPText], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pEXPText], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pEXPText], 0);

	pTextInfo[playerid][pKillStreakText] = CreatePlayerTextDraw(playerid, 119.000000, 296.000000, "KillStreak: 1");
	PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pKillStreakText], 3);
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pKillStreakText], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pKillStreakText], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pKillStreakText], 0.399998, 1.899999);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pKillStreakText], 0xD11111FF);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pKillStreakText], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pKillStreakText], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pKillStreakText], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pKillStreakText], 0);

	Race_Box_Outline[playerid] = CreatePlayerTextDraw(playerid, 481.000000, 166.000000 + 90.0, "raceboxoutline");
	PlayerTextDrawBackgroundColor(playerid, Race_Box_Outline[playerid], 255);
	PlayerTextDrawFont(playerid, Race_Box_Outline[playerid], 1);
	PlayerTextDrawLetterSize(playerid, Race_Box_Outline[playerid], 0.000000, 4.499998);
	PlayerTextDrawColor(playerid, Race_Box_Outline[playerid], -1);
	PlayerTextDrawSetOutline(playerid, Race_Box_Outline[playerid], 0);
	PlayerTextDrawSetProportional(playerid, Race_Box_Outline[playerid], 1);
	PlayerTextDrawSetShadow(playerid, Race_Box_Outline[playerid], 1);
	PlayerTextDrawUseBox(playerid, Race_Box_Outline[playerid], 1);
	PlayerTextDrawBoxColor(playerid, Race_Box_Outline[playerid], 0xFF0000FF);
	PlayerTextDrawTextSize(playerid, Race_Box_Outline[playerid], 616.000000, 0.000000);

	Race_Box[playerid] = CreatePlayerTextDraw(playerid, 484.000000, 168.000000 + 90.0, "racebox");
	PlayerTextDrawBackgroundColor(playerid, Race_Box[playerid], 255);
	PlayerTextDrawFont(playerid, Race_Box[playerid], 1);
	PlayerTextDrawLetterSize(playerid, Race_Box[playerid], 0.000000, 4.099998);
	PlayerTextDrawColor(playerid, Race_Box[playerid], -1);
	PlayerTextDrawSetOutline(playerid, Race_Box[playerid], 1);
	PlayerTextDrawSetProportional(playerid, Race_Box[playerid], 1);
	PlayerTextDrawUseBox(playerid, Race_Box[playerid], 1);
	PlayerTextDrawBoxColor(playerid, Race_Box[playerid], 255);
	PlayerTextDrawTextSize(playerid, Race_Box[playerid], 613.000000, 0.000000);

	pTextInfo[playerid][Mega_Gun_IDX] = CreatePlayerTextDraw(playerid, 527.000000, 315.000000, "150");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][Mega_Gun_IDX], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][Mega_Gun_IDX], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][Mega_Gun_IDX], 0.360000, 1.100000);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][Mega_Gun_IDX], -1);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][Mega_Gun_IDX], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][Mega_Gun_IDX], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][Mega_Gun_IDX], 1);

	pTextInfo[playerid][Mega_Gun_Sprite] = CreatePlayerTextDraw(playerid, 536.500, 326.500, "LD_TATT:9gun");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][Mega_Gun_Sprite], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][Mega_Gun_Sprite], 4);
	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][Mega_Gun_Sprite], 16.000, 13.000);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][Mega_Gun_Sprite], -256);

	pTextInfo[playerid][pGarage_Go_Back] = CreatePlayerTextDraw(playerid, 100.0, 407.0, "Click here to return to the main menu");
	PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pGarage_Go_Back], 2);
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pGarage_Go_Back], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pGarage_Go_Back], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pGarage_Go_Back], 0.480, 2.20);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pGarage_Go_Back], -1);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pGarage_Go_Back], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pGarage_Go_Back], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pGarage_Go_Back], 2);
	PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pGarage_Go_Back], 0);
	PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pGarage_Go_Back], 572661504);
	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pGarage_Go_Back], 60.0, 160.0);
	PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pGarage_Go_Back], 1);

    for(new rb = 0; rb < 4; rb++)
	{
		Race_Box_Text[playerid][rb] = CreatePlayerTextDraw(playerid, 483.000000, 166.000000 + 90.0 + (rb * 9.5), "1   My Name is 24 Characters");
		PlayerTextDrawBackgroundColor(playerid, Race_Box_Text[playerid][rb], 255);
		PlayerTextDrawFont(playerid, Race_Box_Text[playerid][rb], 1);
		PlayerTextDrawLetterSize(playerid, Race_Box_Text[playerid][rb], 0.260000, 1.100000);
		PlayerTextDrawColor(playerid, Race_Box_Text[playerid][rb], -1);
		PlayerTextDrawSetOutline(playerid, Race_Box_Text[playerid][rb], 0);
		PlayerTextDrawSetProportional(playerid, Race_Box_Text[playerid][rb], 1);
		PlayerTextDrawSetShadow(playerid, Race_Box_Text[playerid][rb], 1);
	}
	for(new xp = 0; xp < MAX_XP_STATUSES; xp++)
	{
		pTextInfo[playerid][pEXPStatus][xp] = CreatePlayerTextDraw(playerid, 119.0, 285.0 - (xp * 10.0), "Killstreak 25 xp");
        PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pEXPStatus][xp], 3);
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pEXPStatus][xp], 255);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pEXPStatus][xp], 1);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pEXPStatus][xp], 0.300000, 1.100000);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pEXPStatus][xp], 0xD11111FF);
		PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pEXPStatus][xp], 0);
		PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pEXPStatus][xp], 1);
		PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pEXPStatus][xp], 1);
	}
	for(new st = 0; st < sizeof(StatusTextPositions); st++)
	{
		pStatusInfo[i][StatusText][st] = CreatePlayerTextDraw(playerid, StatusTextPositions[st][0], StatusTextPositions[st][1], "INCOMING");
		PlayerTextDrawAlignment(playerid, pStatusInfo[i][StatusText][st], 2);
		PlayerTextDrawBackgroundColor(playerid, pStatusInfo[i][StatusText][st], 0xFF);
		PlayerTextDrawFont(playerid, pStatusInfo[i][StatusText][st], 1);
		PlayerTextDrawLetterSize(playerid, pStatusInfo[i][StatusText][st], StatusTextLetterSize[st][0], StatusTextLetterSize[st][1]);
		PlayerTextDrawColor(playerid, pStatusInfo[i][StatusText][st], StatusTextColors[st]);
		PlayerTextDrawSetOutline(playerid, pStatusInfo[i][StatusText][st], 1);
		PlayerTextDrawSetProportional(playerid, pStatusInfo[i][StatusText][st], 1);
		PlayerTextDrawSetShadow(playerid, pStatusInfo[i][StatusText][st], 0);
	}
    for(new m = 0; m < (MAX_MISSILEID); m++) {
    	pTextInfo[i][pMissileSign][m] = CreatePlayerTextDraw(playerid, 516.000000, 345.000000 + (m != 0 ? (m + (13 * m) / 2) : 0), "Missiles");
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pMissileSign][m], 255);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pMissileSign][m], 1);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pMissileSign][m], 0.260000, 0.879998);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][m], 100); // 16711935
		PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pMissileSign][m], 0);
		PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pMissileSign][m], 1);
		PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pMissileSign][m], 1);

		format(str, 32, "%d %s", PlayerInfo[playerid][pMissiles][m], GetTwistedMissileName(m, m));
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pMissileSign][m], str);
	}
	pTextInfo[playerid][pTurboBar] = CreatePlayerProgressBar(playerid, 532.00, 430.00, 87.50, 3.20, -5046017, MAX_TURBO); //922812415
	pTextInfo[playerid][pEnergyBar] = CreatePlayerProgressBar(playerid, 532.00, 420.00, 87.50, 3.20, ENERGY_COLOUR, 100.0);
    pTextInfo[playerid][pAiming_Health_Bar] = CreatePlayerProgressBar(playerid, 75.00, 325.00, 53.50, 2.50, 16711850, 100.0);
    pTextInfo[playerid][pExprienceBar] = CreatePlayerProgressBar(playerid, 187.00, 430.00, 252.50, 1.40, EXPRIENCE_COLOUR, 1000.0, 0x000000FF, 0x4D4D4DFF); // 0xFF0000FF
    pTextInfo[playerid][pChargeBar] = CreatePlayerProgressBar(playerid, 320.00, 240.00, 50.0, 2.0, 0xFFA500FF, 20.0); //, 0xFFFFFFFF, 0xFFFFFFFF

	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], MAX_TURBO);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], 100.0);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pAiming_Health_Bar], 0.0);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pExprienceBar], 0.0);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], DEFAULT_CHARGE_INDEX);

	PlayerInfo[playerid][pTurbo] = floatround(MAX_TURBO);
	PlayerInfo[playerid][pEnergy] = 100;
	PlayerInfo[playerid][g_pExprience] = 0;
	PlayerInfo[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
	RemoveDowntownMisc(playerid);
	PreloadAnimLib(playerid, "BOMBER"); PreloadAnimLib(playerid, "RAPPING");
   	PreloadAnimLib(playerid, "SHOP"); PreloadAnimLib(playerid, "BEACH");
   	PreloadAnimLib(playerid, "SMOKING"); PreloadAnimLib(playerid, "FOOD");
   	PreloadAnimLib(playerid, "ON_LOOKERS"); PreloadAnimLib(playerid, "DEALER");
	PreloadAnimLib(playerid, "CRACK"); PreloadAnimLib(playerid, "CARRY");
	PreloadAnimLib(playerid, "COP_AMBIENT"); PreloadAnimLib(playerid, "PARK");
	PreloadAnimLib(playerid, "INT_HOUSE"); PreloadAnimLib(playerid, "PED");
	PreloadAnimLib(playerid, "MISC"); PreloadAnimLib(playerid, "OTB");
	PreloadAnimLib(playerid, "BD_Fire"); PreloadAnimLib(playerid, "BENCHPRESS");
	PreloadAnimLib(playerid, "KISSING"); PreloadAnimLib(playerid, "BSKTBALL");
	PreloadAnimLib(playerid, "MEDIC"); PreloadAnimLib(playerid, "SWORD");
	PreloadAnimLib(playerid, "POLICE"); PreloadAnimLib(playerid, "SUNBATHE");
	PreloadAnimLib(playerid, "FAT"); PreloadAnimLib(playerid, "WUZI");
	PreloadAnimLib(playerid, "SWEET"); PreloadAnimLib(playerid, "ROB_BANK");
	PreloadAnimLib(playerid, "GANGS"); PreloadAnimLib(playerid, "RIOT");
	PreloadAnimLib(playerid, "GYMNASIUM"); PreloadAnimLib(playerid, "CAR");
	PreloadAnimLib(playerid, "CAR_CHAT"); PreloadAnimLib(playerid, "GRAVEYARD");
	PreloadAnimLib(playerid, "POOL");
	StopAudioStreamForPlayer(playerid);
	HidePlayerDialog(playerid);
	switch(random(2))
	{
	    case 0: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/tm2-menu-screen.mp3");
	    case 1: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal - Main Theme Song.mp3");
	}
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	//SelectTextDraw(playerid, 0xFFFFFFFF);
	#if USE_MYSQL == (false)
	if(IsLogged[playerid] == 1)
	{
	    SendClientMessageFormatted(playerid, -1, ""#cNiceBlue"Welcome "#cWhite"%s", Playername(playerid));
        for(new i = 0; i < sizeof(Navigation_S); i++)
        {
            TextDrawShowForPlayer(playerid, Navigation_S[i]);
        }
        SetTimerEx("SpawnPlayerEx", 100, false, "i", playerid);
	}
    #else
    if(IsLogged[playerid] == 0)
	{
	    new Query[128];
	    format(Query, sizeof(Query), "SELECT `Username` FROM `Accounts` WHERE `Username` = '%s' LIMIT 0,1", Playername(playerid));
    	mysql_function_query(McHandle, Query, true, "Thread_DoesAccountExists", "i", playerid);
	}
	#endif
	return 1;
}
THREAD:DoesAccountExists(playerid)
{
    //printf("[Thread: DoesAccountExists] - %s(%d)", Playername(playerid), playerid);
	new rows, fields, Query[138];
	cache_get_data(rows, fields, McHandle);
	if(rows > 0)
	{
	    format(Query, sizeof(Query), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP\n\n{FAF87F}Account: "#cWhite"%s\n\nPlease Enter Your Password Below:", Playername(playerid));
		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Login To Twisted Metal: SA-MP", Query, "Login", "Cancel");
        SetPVarInt(playerid, "pSpawn_On_Request", 2);
	}
	else
	{
	    format(Query, sizeof(Query), ""#cWhite"Welcome To "#cBlue"Twisted Metal: SA-MP: "#cWhite"%s\n\nPlease Enter A Password Below To Register:", Playername(playerid));
		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT, ""#cSAMPRed"Register On Twisted Metal: SA-MP", Query, "Register", "");
      	SetPVarInt(playerid, "pSpawn_On_Request", 1);
	}
	return 1;
}
stock ClearPreChat(playerid)
{
	for(new i = 0; i < 9; i++)
	{
	    SendClientMessage(playerid, -1, "");
	}
	return 1;
}
forward StartPreloading(playerid);
public StartPreloading(playerid)
{
	if(Objects_Preloaded[playerid] >= 1) return 1;
	Objects_Preloaded[playerid] = 1;
    for(new i = 0; i < MAX_PRELOADED_OBJECTS; i++)
    {
        if(IsValidPlayerObject(playerid, Preloading_Objects[playerid][i]))
        {
            DestroyPlayerObject(playerid, Preloading_Objects[playerid][i]);
            Preloading_Objects[playerid][i] = INVALID_OBJECT_ID;
        }
    }
    Preloading_Objects[playerid][0] = CreatePlayerObject(playerid, Machine_Gun, 			TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
    Preloading_Objects[playerid][1] = CreatePlayerObject(playerid, Missile_Default_Object, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
    Preloading_Objects[playerid][2] = CreatePlayerObject(playerid, Missile_Napalm_Object, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
    Preloading_Objects[playerid][3] = CreatePlayerObject(playerid, Missile_RemoteBomb_Object, TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][4] = CreatePlayerObject(playerid, Missile_Smoke_Object, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][5] = CreatePlayerObject(playerid, 18681, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // explosions
    Preloading_Objects[playerid][6] = CreatePlayerObject(playerid, 18685, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // explosions
	Preloading_Objects[playerid][7] = CreatePlayerObject(playerid, 18686, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // explosions
    Preloading_Objects[playerid][8] = CreatePlayerObject(playerid, 18647, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // red neon
	Preloading_Objects[playerid][9] = CreatePlayerObject(playerid, 18650, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // yellow neon
	Preloading_Objects[playerid][10] = CreatePlayerObject(playerid, 19284, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // ricochet
	Preloading_Objects[playerid][11] = CreatePlayerObject(playerid, 1654, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // ricochet
	Preloading_Objects[playerid][12] = CreatePlayerObject(playerid, 1083, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // ricochet
	Preloading_Objects[playerid][13] = CreatePlayerObject(playerid, 3092, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0); // dead body
	SetTimerEx("FinishPreloading", 2500, false, "i", playerid);
	return 1;
}
forward FinishPreloading(playerid);
public FinishPreloading(playerid)
{
    for(new i = 0; i < MAX_PRELOADED_OBJECTS; i++)
    {
        if(IsValidPlayerObject(playerid, Preloading_Objects[playerid][i]))
        {
            DestroyPlayerObject(playerid, Preloading_Objects[playerid][i]);
            Preloading_Objects[playerid][i] = INVALID_OBJECT_ID;
        }
    }
    Objects_Preloaded[playerid] = 2;
	return 1;
}
PreloadAnimLib(playerid, animlib[])
{
	ApplyAnimation(playerid,animlib,"null",0.0,0,0,0,0,0,1);
}
stock CanPlayerUseTwistedMetalVehicle(playerid, model)
{
    if(0 <= PlayerInfo[playerid][pLevel] <= 20)
 	{
 	    if(0 <= PlayerInfo[playerid][pLevel] <= 10)
	    {
	 	    switch(model)
		    {
		        case Roadkill, Meat_Wagon, Hammerhead:
				{
				    return 0;
				}
		    }
	    }
        switch(model)
	    {
	        case Sweet_Tooth, Darkside, Reaper, Shadow:
			{
			    return 0;
			}
	    }
 	}
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid))
	{
	    SpawnPlayer(playerid);
	    #if defined RNPC_INCLUDED
	    if(IsRNPC[playerid] != -1)
	    {
	    	printf("[RNPC: OnPlayerRequestClass] - %s(%d)", Playername(playerid), playerid);
	    }
	    #endif
		return 1;
	}
	if(GetPVarInt(playerid, "pSpawn_On_Request") >= 1)
	{
	    SpawnPlayer(playerid);
	    //printf("[System - OnPlayerRequestClass] - pSpawn_On_Request: %d", GetPVarInt(playerid, "pSpawn_On_Request"));
	    return 1;
	}
	if(IsLogged[playerid] == 0) return 1;
	if(pSpectate_Random_Teammate[playerid] == 1)
	{
	    SpawnPlayer(playerid);
	    return 1;
	}
	if(PlayerInfo[playerid][gGameID] == INVALID_GAME_ID)
	{
	    PlayerInfo[playerid][gGameID] = 0;
	}
	SetPlayerVirtualWorld(playerid, playerid + 1);
	if(1 <= Current_Vehicle[playerid] <= 2000)
  	{
	  	DestroyVehicle(Current_Vehicle[playerid]);
	  	Current_Vehicle[playerid] = 0;
	}
	classid++;
	Current_Car_Index[playerid] = classid;
	startr:
	switch(Current_Car_Index[playerid])
	{
	    case 1..14:
		{
			Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
			C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
			GameTextForPlayerFormatted(playerid, "~n~~n~~n~~n~~n~~n~~n~%s", 15000, 3, C_S_IDS[Current_Car_Index[playerid]][CS_TwistedName]);
		}
		default:
        {
			Current_Car_Index[playerid] = 1;
			goto startr;
		}
	}
	SetVehicleVirtualWorld(Current_Vehicle[playerid], playerid + 1);
	PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
	SetCameraBehindPlayer(playerid);
	Add_Vehicle_Offsets_And_Objects(Current_Vehicle[playerid], Missile_Machine_Gun);
	AttachSpecialObjects(playerid, C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID]);

	PlayerInfo[playerid][pSkin] = C_S_IDS[Current_Car_Index[playerid]][CS_SkinID];

 	InterpolateCameraPos(playerid, -2407.893066, -590.872802, 134.399978, TM_SELECTION_CAMERA_X, TM_SELECTION_CAMERA_Y, TM_SELECTION_CAMERA_Z, 3000, CAMERA_MOVE);
 	InterpolateCameraLookAt(playerid, -2405.759521, -595.313354, 133.546020, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z, 4000, CAMERA_MOVE);
	if(GetPVarInt(playerid, "pGarage") == 0)
	{
	    if(Objects_Preloaded[playerid] == 0)
	    {
	    	StartPreloading(playerid);
	    }
	    if(!CanPlayerUseTwistedMetalVehicle(playerid, C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID]))
		{
		    ShowSubtitle(playerid, "Locked", .time = 15000, .override = 1);
		}
		else HideSubtitle(playerid);
		if(gGameData[PlayerInfo[playerid][gGameID]][g_Voting_Time] == 0)
		{
			switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
		    {
			    case TEAM_DEATHMATCH, TEAM_HUNTED, TEAM_LAST_MAN_STANDING:
				{
				    if(PlayerInfo[playerid][gTeam] == INVALID_GAME_TEAM)
				    {
			            SelectTeams(playerid);
					}
				}
				default: SetPlayerColor(playerid, GetTwistedMetalColour(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], .shift = 0));
			}
			if(Selecting_Textdraw[playerid] == -1)
			{
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pGarage_Go_Back]);
				SelectTextDraw(playerid, NAVIGATION_COLOUR);
			}
		}
	}
	else
	{
	    new text[96];
	    switch(IsPlayerInAnyVehicle(playerid))
	    {
	    	case 1: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
			default: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
		}
		ShowSubtitle(playerid, text, (60 * 1000), 1, 320.0);
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
    if(IsLogged[playerid] == 0) return 1;
    if(GetPVarInt(playerid, "pSpawn_On_Request") >= 1)
	{
	    SpawnPlayer(playerid);
	    return 0;
	}
	if(Current_Car_Index[playerid] == 0)
	{
		GameTextForPlayer(playerid, "~r~Please Select A Vehicle!", 3000, 3);
		CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
		return 0;
	}
	if(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id] == INVALID_MAP_ID ||
		gGameData[PlayerInfo[playerid][gGameID]][g_Voting_Time] == 1)
	{
	    GameTextForPlayer(playerid, "~w~The Map Is Currently Changing!~n~~r~~h~Please Wait!", 3000, 3);
        TextDrawShowForPlayer(playerid, gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Time_Text]);
		return 0;
	}
	if(GetPVarInt(playerid, "pSelecting_Team") == 1)
	{
	    GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~Please Select A Team!", 3000, 3);
		return 0;
	}
	if(GetPVarInt(playerid, "pGarage") == 1)
	{
	    if(1 <= Current_Vehicle[playerid] <= 2000)
	  	{
		  	DestroyVehicle(Current_Vehicle[playerid]);
		  	Current_Vehicle[playerid] = 0;
		}
        Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], 2492.3181, -1668.0062, 13.9273 + 0.7, 70.1542, C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
	    SetVehicleNumberPlate(Current_Vehicle[playerid], GetTwistedMetalName(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID]));
	    GameTextForPlayer(playerid, " ", 5, 3);
	    for(new i = 0; i < sizeof(Navigation_S); i++)
        {
            TextDrawHideForPlayer(playerid, Navigation_S[i]);
        }
        CancelSelectTextDraw(playerid);
	    TogglePlayerSpectating(playerid, true);
	    new text[96];
	    switch(IsPlayerInAnyVehicle(playerid))
	    {
	    	case 1: format(text, sizeof(text), "Now Customizing %s - ~w~Type ~y~/back ~w~To Go Back", C_S_IDS[Current_Car_Index[playerid]][CS_TwistedName]); // Press ~y~~h~~k~~VEHICLE_ACCELERATE~
			default: format(text, sizeof(text), "Now Customizing %s - ~w~Type ~w~/back ~w~To Go Back", C_S_IDS[Current_Car_Index[playerid]][CS_TwistedName]); // ~y~~h~~k~~PED_SPRINT~~n~
		}
		ShowSubtitle(playerid, text, (60 * 2000), 1, 320.0);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pGarage_Go_Back]);
		SetPVarInt(playerid, "pGarage", 2);
		SpawnPlayer(playerid);
	    return 0;
	}
	else
	{
		if(!CanPlayerUseTwistedMetalVehicle(playerid, C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID]))
		{
		    ShowSubtitle(playerid, "Locked", .time = 15000, .override = 1);
		    return 0;
		}
		else HideSubtitle(playerid);
	}
	if(GetPVarInt(playerid, "Requesting_Spawn") == 1)
	{
	    if(GetPVarInt(playerid, "Requesting_Spawn_Time") >= gettime())
	    {
	    	return 0;
	    }
	}
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	SetPVarInt(playerid, "Requesting_Spawn", 1);
	SetPVarInt(playerid, "Requesting_Spawn_Time", gettime() + 3);
	if(1 <= Current_Vehicle[playerid] <= 2000)
  	{
	  	DestroyVehicle(Current_Vehicle[playerid]);
	  	Current_Vehicle[playerid] = 0;
	}
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pGarage_Go_Back]);
	CancelSelectTextDraw(playerid);
	SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, playerid, "READ /controls!", 3000 );
	return 1;
}

UpdatePlayerLMSTeamInfo(playerid)
{
	if(PlayerInfo[playerid][gTeam] != INVALID_GAME_TEAM &&
	    PlayerInfo[playerid][gRival_Team] != INVALID_GAME_TEAM)
 	{
	    new team_text[32], rival_text[32];
	    format(team_text, sizeof(team_text), "Teammates: %d~n~Team Lives: %d", gTeam_Player_Count[PlayerInfo[playerid][gTeam]], gTeam_Lives[PlayerInfo[playerid][gTeam]]);
	   	format(rival_text, sizeof(rival_text), "Enemies: %d~n~Enemy Lives: %d", gTeam_Player_Count[PlayerInfo[playerid][gRival_Team]], gTeam_Lives[PlayerInfo[playerid][gRival_Team]]);
	    PlayerTextDrawSetString(playerid, pTextInfo[playerid][pTeam_Score], team_text);
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pRival_Team_Score], rival_text);
	}
	return 1;
}

CreateTeamsTextdraws(playerid)
{
	new team_text[32], rival_text[32];
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
	    case TEAM_LAST_MAN_STANDING:
	    {
	        format(team_text, sizeof(team_text), "Teammates: %d~n~Team Lives: %d", gTeam_Player_Count[PlayerInfo[playerid][gTeam]], gTeam_Lives[PlayerInfo[playerid][gTeam]]);
         	format(rival_text, sizeof(rival_text), "Enemies: %d~n~Enemy Lives: %d", gTeam_Player_Count[PlayerInfo[playerid][gRival_Team]], gTeam_Lives[PlayerInfo[playerid][gRival_Team]]);
	        pTextInfo[playerid][pTeam_Score] = CreatePlayerTextDraw(playerid, 83.000, (151.000 - 5.0), team_text);
			pTextInfo[playerid][pRival_Team_Score] = CreatePlayerTextDraw(playerid, 83.000, (205.000 - 5.0), rival_text);
	    }
	    default:
	    {
	        pTextInfo[playerid][pTeam_Score] = CreatePlayerTextDraw(playerid, 83.000, 151.000, "0");
			pTextInfo[playerid][pRival_Team_Score] = CreatePlayerTextDraw(playerid, 83.000, 205.000, "0");
	    }
	}
	switch(PlayerInfo[playerid][gTeam])
	{
	    case TEAM_CLOWNS:
	    {
	        pTextInfo[playerid][pTeam_Sprite] = CreatePlayerTextDraw(playerid, 38.500, 140.500, "LD_TATT:6clown");
	        pTextInfo[playerid][pRival_Team_Sprite] = CreatePlayerTextDraw(playerid, 38.500, 194.500, "LD_TATT:12bndit");
     	}
	    case TEAM_DOLLS:
	    {
	        pTextInfo[playerid][pTeam_Sprite] = CreatePlayerTextDraw(playerid, 38.500, 140.500, "LD_TATT:12bndit");
	        pTextInfo[playerid][pRival_Team_Sprite] = CreatePlayerTextDraw(playerid, 38.500, 194.500, "LD_TATT:6clown");
     	}
	}
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pTeam_Sprite], 4);
 	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pTeam_Sprite], 40.000, 32.500);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pTeam_Sprite], PLAYER_TEAM_COLOUR);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pRival_Team_Sprite], 4);
 	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pRival_Team_Sprite], 40.000, 32.500);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pRival_Team_Sprite], RIVAL_TEAM_COLOUR);

	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pTeam_Score], 0xAA);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pTeam_Score], 2);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pTeam_Score], 0.300, 0.999998);
 	PlayerTextDrawColor(playerid, pTextInfo[playerid][pTeam_Score], PLAYER_TEAM_COLOUR);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pTeam_Score], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pTeam_Score], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pTeam_Score], 1);

	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pRival_Team_Score], 0xAA);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pRival_Team_Score], 2);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pRival_Team_Score], 0.300, 0.999998);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pRival_Team_Score], RIVAL_TEAM_COLOUR);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pRival_Team_Score], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pRival_Team_Score], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pRival_Team_Score], 1);

	PlayerTextDrawShow(playerid, pTextInfo[playerid][pTeam_Sprite]);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pRival_Team_Sprite]);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pTeam_Score]);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pRival_Team_Score]);
}

stock AddPlayerToGameTeam(playerid)
{
    gTeam_Player_Count[PlayerInfo[playerid][gTeam]]++;
    SendClientMessageFormatted(playerid, -1, "Your Team Is Now "#cLime"%s", Team_Info[PlayerInfo[playerid][gTeam]][TI_Team_Name]);
    CreateTeamsTextdraws(playerid);
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
	    case TEAM_LAST_MAN_STANDING:
	    {
			foreach(Player, i)
			{
				if(i == playerid) continue;
			    UpdatePlayerLMSTeamInfo(playerid);
			}
		}
	}
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_CLOWNS][TI_Textdraw]);
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_CLOWNS][TI_Textdraw_N]);
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_DOLLS][TI_Textdraw]);
    TextDrawHideForPlayer(playerid, Team_Info[TEAM_DOLLS][TI_Textdraw_N]);
    CancelSelectTextDraw(playerid);
    DeletePVar(playerid, "pSelecting_Team");
    AdjustTeamColoursForPlayer(playerid);
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(playertextid == INVALID_PLAYER_TEXT_DRAW)
    {
		if(Selecting_Textdraw[playerid] != -1)
	    {
	        SelectTextdraw(playerid, Selecting_Textdraw[playerid]);
	    }
	    return 1;
    }
    if(playertextid == pTextInfo[playerid][pGarage_Go_Back])
    {
        GameTextForPlayer(playerid, " ", 5, 3);
        HideSubtitle(playerid);
        HideAllTeams(playerid, false);
        for(new rb = 0; rb < 4; rb++)
		{
		    PlayerTextDrawHide(playerid, Race_Box_Text[playerid][rb]);
		}
		PlayerTextDrawHide(playerid, Race_Box_Outline[playerid]);
		PlayerTextDrawHide(playerid, Race_Box[playerid]);
        DeletePVar(playerid, "pGarage");
        DeletePVar(playerid, "pMultiplayer");
        SetPVarInt(playerid, "pSpawn_On_Request", 2);
        SpawnPlayer(playerid);
        for(new i = 0; i < sizeof(Navigation_S); i++)
        {
            TextDrawShowForPlayer(playerid, Navigation_S[i]);
        }
        PlayerTextDrawHide(playerid, pTextInfo[playerid][pGarage_Go_Back]);
        if(PlayerInfo[playerid][gGameID] != INVALID_GAME_ID)
        {
        	gGameData[PlayerInfo[playerid][gGameID]][g_Players]--;
        	format(GlobalString, sizeof(GlobalString), "%d/"#MAX_PLAYERS_PER_LOBBY"", gGameData[PlayerInfo[playerid][gGameID]][g_Players]);
	        TextDrawSetString(gGameData[PlayerInfo[playerid][gGameID]][g_Lobby_Players], GlobalString);
        	TextDrawHideForPlayer(playerid, gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Time_Text]);
            PlayerInfo[playerid][gGameID] = INVALID_GAME_ID;
            if(PlayerInfo[playerid][gTeam] != INVALID_GAME_TEAM)
			{
				gTeam_Player_Count[PlayerInfo[playerid][gTeam]]--;
				PlayerInfo[playerid][gTeam] = INVALID_GAME_TEAM;
			}

		}
	}
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == INVALID_TEXT_DRAW)
    {
		if(Selecting_Textdraw[playerid] != -1)
	    {
	        SelectTextdraw(playerid, Selecting_Textdraw[playerid]);
	    }
	    return 1;
    }
    if(clickedid == Navigation_S[NAVIGATION_INDEX_MULTIPLAYER])
    {
        for(new i = 0; i <= NAVIGATION_INDEX_HELP; i++)
        {
            TextDrawHideForPlayer(playerid, Navigation_S[i]);
        }
        SendClientMessage(playerid, -1, "Please Select A Game Lobby To Join");
        for(new i = 0; i < sizeof(Navigation_Game_S); i++)
        {
            TextDrawShowForPlayer(playerid, Navigation_Game_S[i]);
        }
        for(new gameid = 0; gameid < sizeof(gGameData); gameid++)
		{
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Box]);
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Name]);
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Type]);
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Map]);
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_gState]);
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Players]);
            TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Time]);
        }
        SelectTextDraw(playerid, NAVIGATION_COLOUR); // EXPRIENCE_COLOUR
        return 1;
    }
    if(clickedid == Navigation_S[NAVIGATION_INDEX_GARAGE]) // Pick a vehicle to start customizing
    {
        for(new i = 0; i < sizeof(Navigation_S); i++)
        {
            TextDrawHideForPlayer(playerid, Navigation_S[i]);
        }
        CancelSelectTextDraw(playerid);
    	ForceClassSelection(playerid);
    	TogglePlayerSpectating(playerid, true);
    	TogglePlayerSpectating(playerid, false);
    	CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
    	new text[96];
	    switch(IsPlayerInAnyVehicle(playerid))
	    {
	    	case 1: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
			default: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
		}
		ShowSubtitle(playerid, text, (60 * 1000), 1, 320.0);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pGarage_Go_Back]);
		SelectTextDraw(playerid, NAVIGATION_COLOUR);
        DeletePVar(playerid, "pSpawn_On_Request");
        SetPVarInt(playerid, "pGarage", 1);
		return 1;
    }
    if(clickedid == Navigation_S[NAVIGATION_INDEX_OPTIONS])
    {
        GameTextForPlayer(playerid, "~r~~h~Not Finished", 5000, 3);
        return 1;
    }
    if(clickedid == Navigation_S[NAVIGATION_INDEX_HELP])
    {
        cmd_tutorial(playerid, "");
        return 1;
    }
	if(clickedid == iSpawn_Text)
	{
	    CancelSelectTextDraw(playerid);
	    TextDrawHideForPlayer(playerid, iSpawn_Text);
	    DeletePVar(playerid, "pRegistration_Tutorial");
	    DeletePVar(playerid, "pSpawn_On_Request");
	    ForceClassSelection(playerid);
	    TogglePlayerSpectating(playerid, true);
    	TogglePlayerSpectating(playerid, false);
	    PlayerInfo[playerid][pSpawned] = 0;
	    CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
	    return 1;
	}
	new bool:changed = false;
	if(clickedid == Team_Info[TEAM_CLOWNS][TI_Textdraw]
		|| clickedid == Team_Info[TEAM_CLOWNS][TI_Textdraw_N])
	{
	    PlayerInfo[playerid][gTeam] = TEAM_CLOWNS;
	    PlayerInfo[playerid][gRival_Team] = TEAM_DOLLS;
	    changed = true;
	}
	if(clickedid == Team_Info[TEAM_DOLLS][TI_Textdraw]
		|| clickedid == Team_Info[TEAM_DOLLS][TI_Textdraw_N])
	{
	    PlayerInfo[playerid][gTeam] = TEAM_DOLLS;
	    PlayerInfo[playerid][gRival_Team] = TEAM_CLOWNS;
	    changed = true;
	}
	if(changed == true && GetPVarInt(playerid, "pSelecting_Team") == 1)
	{
	    AddPlayerToGameTeam(playerid);
	    ForceClassSelection(playerid);
	    return 1;
	}
	for(new gameid = 0; gameid < sizeof(gGameData); gameid++)
	{
	    if(clickedid == gGameData[gameid][g_Lobby_Box])
	    {
	        for(new i = 0; i < sizeof(Navigation_Game_S); i++)
	        {
	            TextDrawHideForPlayer(playerid, Navigation_Game_S[i]);
	        }
	        for(new g = 0; g < sizeof(gGameData); g++)
			{
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_Box]);
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_Name]);
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_Type]);
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_Map]);
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_gState]);
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_Players]);
	            TextDrawHideForPlayer(playerid, gGameData[g][g_Lobby_Time]);
	        }
	        PlayerInfo[playerid][gGameID] = gameid;
	        ForceClassSelection(playerid);
	    	TogglePlayerSpectating(playerid, true);
	    	TogglePlayerSpectating(playerid, false);
	        TemporaryRaceQuitList(playerid, .action = 1);
	        DeletePVar(playerid, "pSpawn_On_Request");
	        CancelSelectTextDraw(playerid);
	        CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
	        PlayerTextDrawShow(playerid, pTextInfo[playerid][pGarage_Go_Back]);
			SelectTextDraw(playerid, NAVIGATION_COLOUR);
			SetPVarInt(playerid, "pMultiplayer", 1);
			SendClientMessage(playerid, -1, ""#cNiceBlue"Now Joining Multi-Player Action");
			gGameData[gameid][g_Players]++;
	        format(GlobalString, sizeof(GlobalString), "%d/"#MAX_PLAYERS_PER_LOBBY"", gGameData[gameid][g_Players]);
	        TextDrawSetString(gGameData[gameid][g_Lobby_Players], GlobalString);
	        for(new i = NAVIGATION_INDEX_HELP; i < sizeof(Navigation_S); i++)
	        {
	            TextDrawHideForPlayer(playerid, Navigation_S[i]);
	        }
	        if(gGameData[PlayerInfo[playerid][gGameID]][g_Voting_Time] == 0)
	    	{
	    	    SendClientMessageFormatted(playerid, -1, ""#cGold"[%s] "#cWhite"- Mode: "#cGold"%s "#cWhite"- Map: "#cGold"%s", gGameData[PlayerInfo[playerid][gGameID]][g_Lobby_gName], s_Gamemodes[gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode]][GM_Name], s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Name]);
	    	}
	    	else SendClientMessageFormatted(playerid, -1, ""#cRed"[%s] "#cWhite"- A new Gamemode and Map is being voted for.", gGameData[PlayerInfo[playerid][gGameID]][g_Lobby_gName]);
			break;
	    }
	}
	return 1;
}
stock AdjustTeamColoursForPlayer(playerid)
{
    foreach(Player, i)
    {
        if(PlayerInfo[i][gTeam] == PlayerInfo[playerid][gTeam])
        {
    		SetPlayerMarkerForPlayer(i, playerid, PLAYER_TEAM_COLOUR);
    		SetPlayerMarkerForPlayer(playerid, i, PLAYER_TEAM_COLOUR);
		}
		else if(PlayerInfo[i][gTeam] != PlayerInfo[playerid][gTeam])
		{
		    SetPlayerMarkerForPlayer(i, playerid, RIVAL_TEAM_COLOUR);
    		SetPlayerMarkerForPlayer(playerid, i, RIVAL_TEAM_COLOUR);
		}
    }
	return 1;
}
CMD:adjust(playerid, params[]) return AdjustTeamColoursForPlayer(playerid);

CMD:back(playerid, params[])
{
    if(GetPVarInt(playerid, "pGarage") == 2)
    {
        SetPVarInt(playerid, "pGarage", 1);
        CancelSelectTextDraw(playerid);
    	ForceClassSelection(playerid);
    	TogglePlayerSpectating(playerid, true);
    	TogglePlayerSpectating(playerid, false);
    	CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
    	new text[96];
	    switch(IsPlayerInAnyVehicle(playerid))
	    {
	    	case 1: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
			default: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
		}
		ShowSubtitle(playerid, text, (60 * 1000), 1, 320.0);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pGarage_Go_Back]);
		SelectTextDraw(playerid, NAVIGATION_COLOUR);
    }
    return 1;
}

CMD:tutorial(playerid, params[])
{
    ShowPlayerDialog(playerid, DIALOG_TUTORIAL, DIALOG_STYLE_LIST,
	""cSAMP"Twisted Metal SA-MP - Tutorial", "HUD\nThe Gamemodes\nThe Weapons\nHow To Spawn\n", "Proceed", "Finish");
	PlayerPlaySound(playerid, 4804, 0.0, 0.0, 0.0);
	return 1;
}
CMD:clicktd(playerid, params[])
{
    SelectTextDraw(playerid, 0x9999BBBB);
	return 1;
}
CMD:canceltd(playerid, params[])
{
    CancelSelectTextDraw(playerid);
	return 1;
}

CMD:hidenav(playerid, params[])
{
    for(new i = 0; i < sizeof(Navigation_S); i++)
    {
        TextDrawHideForPlayer(playerid, Navigation_S[i]);
    }
	return 1;
}

CMD:shownav(playerid, params[])
{
	new start = strval(params);
    for(new i = start; i < sizeof(Navigation_S); i++)
    {
        TextDrawShowForPlayer(playerid, Navigation_S[i]);
    }
	return 1;
}

stock numLen(iNum)
{
    new szNum[11];
    valstr(szNum, iNum);
    return strlen(szNum);
}
stock roundNum(iNum, iDig)
{
    if(iDig)
    {
        new iMod;
        iDig = floatround(floatpower(0xA, iDig));
        iMod = iNum % iDig;
        return (iMod < (iDig >>> 1)) ? (iNum - iMod) : (iNum - iMod + iDig);
    }
    return iNum;
}
CMD:gainxp(playerid, params[])
{
    GainExprience(playerid, 200);
    AddEXPMessage(playerid, "Test EXP 200");
	return 1;
}
new Global_KSXPString[32];
stock ShowKillStreak(playerid, text[32])
{
	PlayerTextDrawSetString(playerid, pTextInfo[playerid][pKillStreakText], text);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pKillStreakText]);
	return 1;
}
forward HideKillStreak(playerid);
public HideKillStreak(playerid)
{
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pKillStreakText]);
	return 1;
}
#define EXP_STATUS_SHOW_TIME 8
forward AddEXPMessage(playerid, text[32]);
public AddEXPMessage(playerid, text[32])
{
    new i = 0, lowest = EXP_STATUS_SHOW_TIME, lowest_i;
	for(; i < (MAX_XP_STATUSES - 1); i++)
	{
	    if(i >= MAX_XP_STATUSES)
	    {
	        i = 0;
	        for(; i < MAX_XP_STATUSES; i++)
			{
			    if(pEXPTextStatusChanged[playerid][i] == 1) continue;
		        if(pEXPTextStatus[playerid][i] < lowest)
		        {
		            lowest = pEXPTextStatus[playerid][i];
		            lowest_i = i;
		        }
	        }
	        strmid(pEXPTextStatusText[playerid][lowest_i], text, false, strlen(text));
	        pEXPTextStatusChanged[playerid][lowest_i] = 1;
	        break;
	    }
	    if(pEXPTextStatus[playerid][i] == 0) break;
 	}
    PlayerTextDrawSetString(playerid, pTextInfo[playerid][pEXPStatus][i], text);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pEXPStatus][i]);
	strmid(pEXPTextStatusText[playerid][i], text, false, strlen(text));
	pEXPTextStatus[playerid][i] = EXP_STATUS_SHOW_TIME;
	pEXPTextStatusChanged[playerid][i] = 0;
	KillTimer(pEXPTextStatusTimer[playerid][i]);
	pEXPTextStatusTimer[playerid][i] = SetTimerEx("FadeXPMessage", 8 * 1000, false, "ii", playerid, i);
	return 1;
}
forward FadeXPMessage(playerid, index);
public FadeXPMessage(playerid, index)
{
    FadeTextdraw(playerid, _:pTextInfo[playerid][pEXPStatus][index], 0xFF0000FF, 0xFF, 2000, 50);
    SetTimerEx("HideXPMessage", 2000, false, "ii", playerid, index);
	return 1;
}
forward HideXPMessage(playerid, index);
public HideXPMessage(playerid, index)
{
    PlayerTextDrawHide(playerid, pTextInfo[playerid][pEXPStatus][index]);
    PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pEXPStatus][index], 255);
 	PlayerTextDrawColor(playerid, pTextInfo[playerid][pEXPStatus][index], 0xD11111FF);
    KillTimer(pEXPTextStatusTimer[playerid][index]);
    pEXPTextStatus[playerid][index] = 0;
	pEXPTextStatusTimer[playerid][index] = 0;
	if(pEXPTextStatusChanged[playerid][index] == 1)
	{
	    pEXPTextStatusChanged[playerid][index] = 0;
	    strmid(pEXPTextStatusText[playerid][index], "", false, 1);
	    AddEXPMessage(playerid, pEXPTextStatusText[playerid][index]);
	    return 1;
	}
	strmid(pEXPTextStatusText[playerid][index], "", false, 1);
	return 1;
}
//-- game xp
//Damage Bonus 25 xp
//Kills 25 xp
//Assists 5 xp
//Battering RAM Kill 25 xp
//Revenge Kill 25 XP
//Streaker Kill 25 xp
//-- game points
//Poach Kill 25 xp (steal kill)
//Soft Kill 50 xp
//Kill 75 xp
//Soft Assist 25 xp
//Assist 50 xp & 5 assists gamexp
//Strong assist 75 xp
//-- Killstreak bonus (KS Bonus: %s)
//weapons

stock GainExprience(playerid, exprience)
{
	if(!IsPlayerConnected(playerid)) return 1;
	new string[16], leveltimes = 1000;
	PlayerInfo[playerid][g_pExprience] += exprience;
	PlayerInfo[playerid][pExprience] += exprience;
	ToggleAccountSavingVar(playerid, ACCOUNT_UPDATE_EXPRIENCE);
    leveltimes = 1000;
    if(PlayerInfo[playerid][pExprience] >= (PlayerInfo[playerid][pLevel] * leveltimes))
    {
    	PlayerInfo[playerid][pLevel] += 1;
    	format(string, sizeof(string), "Level: %d", PlayerInfo[playerid][pLevel]);
    	PlayerTextDrawSetString(playerid, pTextInfo[playerid][pLevelText], string);
    	PlayerTextDrawShow(playerid, pTextInfo[playerid][pLevelText]);
    	PlayerInfo[playerid][pTier_Points] += 1;
    	ToggleAccountSavingVar(playerid, ACCOUNT_UPDATE_LEVEL);
    	AddEXPMessage(playerid, "LEVELED UP!");
    }
    format(string, sizeof(string), "XP: %d", PlayerInfo[playerid][pExprience]);
    PlayerTextDrawSetString(playerid, pTextInfo[playerid][pEXPText], string);
    SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pExprienceBar], float((PlayerInfo[playerid][pExprience] - ((PlayerInfo[playerid][pLevel] - 1) * leveltimes))));
    ShowPlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	return 1;
}

stock GainPoints(playerid, points)
{
    PlayerInfo[playerid][g_pPoints] += points;
	return 1;
}

stock ResetPlayerGamePoints(playerid)
{
	return (PlayerInfo[playerid][g_pPoints] = 0);
}

stock GetPlayerGamePoints(playerid)
{
	return PlayerInfo[playerid][g_pPoints];
}

CMD:sound(playerid, params[])
{
    new sound, id = playerid, str[8];
    format(str, sizeof(str), "dU(%d)", playerid);
	if(sscanf(params, str, sound, id)) return SendClientMessage(playerid, -1, "Usage: /sound [id] Optional: [nick / id]");
	new Float:x, Float:y, Float:z;
	GetPlayerPos(id, x, y, z);
 	PlayerPlaySound(id, sound, x, y, z);
 	SendClientMessageFormatted(id, -1, "Playing Soundid '%d'.", sound);
 	return 1;
}

CMD:soundex(playerid, params[])
{
	if(isnull(params)) return SendClientMessage(playerid, -1, "Error: /soundex [id]");
 	PlayerPlaySound(playerid, strval(params), 0.0, 0.0, 0.0);
	SendClientMessageFormatted(playerid, -1, "Playing Soundid '%d'.", strval(params));
 	return 1;
}

CMD:name(playerid, params[])
{
	new name[24];
	if(sscanf(params, "s[24]", name)) return 1;
   	SetPlayerName(playerid, name);
	return 1;
}

CMD:time(playerid, params[])
{
	new time;
	if(sscanf(params, "d", time)) return 1;
   	SetWorldTime(time);
	return 1;
}

CMD:attachmarker(playerid, params[])
{
	new vehicleid, color;
	if(sscanf(params, "dx", vehicleid, color)) return 1;
    CreateMarkerForPlayer(vehicleid, color);
	return 1;
}

stock CreateMarkerForPlayer(vehicleid, color)
{
	new Text3D:vehicle3Dtext[6];
    vehicle3Dtext[0] = Create3DTextLabel(" \\IIIIIIIIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
    vehicle3Dtext[1] = Create3DTextLabel("  \\IIIIIIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
    vehicle3Dtext[2] = Create3DTextLabel("   \\IIIIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
    vehicle3Dtext[3] = Create3DTextLabel("    \\IIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
    vehicle3Dtext[4] = Create3DTextLabel("     \\II/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
    vehicle3Dtext[5] = Create3DTextLabel("     \\/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
    for(new i = 0; i < 6; i++) {
		Attach3DTextLabelToVehicle( vehicle3Dtext[i], vehicleid, 0.0, 0.0, (2.0 - floatdiv(i, 8.5)) );
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPVarInt(playerid, "Requesting_Spawn", 0);
    if(IsPlayerNPC(playerid))
  	{
  	    #if defined RNPC_INCLUDED
  	    if(IsRNPC[playerid] != -1)
  	    {
  	        new npcid = IsRNPC[playerid];
  	    	InitializeRNPCVehicle(Twisted_NPCS[npcid][t_NPCID], Twisted_NPCS[npcid][t_NPCVehicle]);
	    	printf("[RNPC: OnPlayerSpawn] - %s(%d)", Playername(playerid), playerid);
	    }
	    #endif
	    /*for(new i = 0; i != MAX_PLAYERS; i++)
	    {
	        if(i == playerid) continue;
	        SetPlayerMarkerForPlayer( i, playerid, 0xFFFFFF00 );
	    }*/
	    /*if(strcmp(Playername(playerid), "[BOT]Calypso", false) == 0)
	    {
			Current_Car_Index[playerid] = random(14) + 1;
			Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
			C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
            new Float:x, Float:y, Float:z, Float:angle;
    		GetMapComponents(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
    		SetVehiclePos(Current_Vehicle[playerid], x, y, z);
			PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
			SetCameraBehindPlayer(playerid);
			SetPlayerVirtualWorld(playerid, 0);
	    }
	    if(strfind(Playername(playerid), "[BOT]RacerTest", false) != -1)
	    {
			Current_Car_Index[playerid] = random(14) + 1;
			Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
			C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
            new Float:x, Float:y, Float:z, Float:angle;
    		GetMapComponents(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
    		SetVehiclePos(Current_Vehicle[playerid], x, y, z);
			PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
			SetCameraBehindPlayer(playerid);
			SetPlayerVirtualWorld(playerid, 0);
	    }*/
		return 1;
	}
	if(pSpectate_Random_Teammate[playerid] == 1)
	{
	    TogglePlayerSpectating(playerid, true);
	    new randomplayer[MAX_PLAYERS], count = 0, target;
		for(new i = 0; i < MAX_PLAYERS; i++)
		{
		    if(PlayerInfo[i][gTeam] != PlayerInfo[i][gTeam]) continue;
		    if(PlayerInfo[i][pSpawned] != 1) continue;
		    randomplayer[count] = i;
		    ++count;
		}
		if(count == 0)
		{
		    pSpectate_Random_Teammate[playerid] = 0;
			SetPlayerHealth(playerid, -1);
		    return 1;
		}
		target = randomplayer[random(count)];
		PlayerSpectateVehicle(playerid, Current_Vehicle[target], SPECTATE_MODE_NORMAL);
	    return 1;
	}
	switch(GetPVarInt(playerid, "pSpawn_On_Request"))
	{
		case 1:
		{
		    SetCameraBehindPlayerNoHUD(playerid);
		    for(new i = 0; i < 5; i++)
			{
				SetPlayerCameraPos(playerid, 2695.057568, -2352.101562, 40.479072);
				SetPlayerCameraLookAt(playerid, 2694.728027, -2347.103027, 40.359199, CAMERA_CUT);
			}
		    return 1;
		}
		case 2:
		{
		    SetCameraBehindPlayerNoHUD(playerid);
  			SelectTextDraw(playerid, NAVIGATION_COLOUR);
  			TogglePlayerSpectating(playerid, true);
            InterpolateCameraPos(playerid, 1545.918945, -1351.678344, 365.233612, 378.247344, -1987.221313, 29.519388, 120000);
			InterpolateCameraLookAt(playerid, 1545.924316, -1352.195800, 360.260467, 378.325256, -1991.985717, 28.004817, 120000);
			return 1;
		}
	}
	switch(GetPVarInt(playerid, "pGarage"))
	{
	    case 2:
	    {
	        PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
			SetCameraBehindPlayerNoHUD(playerid);
			SetPlayerVirtualWorld(playerid, 0);
			SetPlayerInterior(playerid, 0);
			SetPlayerCameraPos(playerid, 2481.926269, -1670.402465, 15.355634);
			SetPlayerCameraLookAt(playerid, 2486.694091, -1668.989501, 14.834477, CAMERA_MOVE);
			return 1;
	    }
	}
	if(TD_gPHTD)
	{
		CallRemoteFunction("Hidetd", "i", playerid);
	}
	if(2001 <= PlayerInfo[playerid][pSpecial_Missile_Vehicle] <= 4000)
	{
		PlayerInfo[playerid][pSpecial_Missile_Vehicle] -= 2000;
	    CallLocalFunction("OnPlayerVehicleHealthChange", "iiff", playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2400.0, 2500.0);
	    SetTimerEx("Reset_SMV", 100, false, "i", playerid);
	    return 1;
	}
	TwistedSpawnPlayer(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(GetPVarInt(playerid, "Vermin_Special") == 1 && PlayerInfo[playerid][pSpecial_Missile_Vehicle] != 0)
	{
	    PlayerInfo[playerid][pSpecial_Missile_Vehicle] += 2000;
	    DeletePVar(playerid, "Vermin_Special");
	    return 1;
	}
	PlayerInfo[playerid][pSpawned] = 0;
	//printf("[SAMP: OnPlayerDeath] - playerid: %d - killerid: %d - reason: %d", playerid, killerid, reason);
	ClearAnimations(playerid);
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	ForceClassSelection(playerid);
	/*new bool:gender = true;
	switch(GetVehicleModel(Current_Vehicle[playerid]))
	{
 		case Junkyard_Dog: gender = true;
	    case Brimstone: gender = true;
	    case Outlaw: gender = true;
	    case Reaper: gender = true;
	    case Roadkill: gender = true;
	    case Thumper: gender = true;
	    case Spectre: gender = false;
	    case Darkside: gender = false;
	    case Shadow: gender = false;
	    case Meat_Wagon: gender = false;
	    case Vermin: gender = true;
	    case ManSalughter: gender = true;
	    case Sweet_Tooth: gender = true;
	}
	new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
	SetPlayerPos(playerid, x, y, z + 10);
    foreach(Player, i)
    {
        if(!IsPlayerInRangeOfPoint(i, 30.0, x, y, z)) continue;
 		PlayAudioStreamForPlayer(playerid, gender == false ? ("http://www.lvcnr.net/tmtwisted_metal/DEATH_AI_F.wav")
 		: ("http://www.lvcnr.net/tmtwisted_metal/DEATH_AI_M.wav"), x, y, z, 30.0, 1);
	}*/
	new vehicleid = Current_Vehicle[playerid], model = GetVehicleModel(Current_Vehicle[playerid]);
	RemovePlayerAttachedObject(playerid, 0);
	RemovePlayerFromVehicle(playerid);
	Vehicle_Using_Environmental[Current_Vehicle[playerid]] = 0;
	switch(model)
	{
	    case Junkyard_Dog:
	    {
	        if(GetVehicleModel(PlayerInfo[playerid][pSpecial_Missile_Vehicle]) != 0)
	        {
	        	DestroyVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	        }
	        if(GetPVarInt(playerid, "Junkyard_Dog_Attach"))
		    {
		        DeletePVar(playerid, "Junkyard_Dog_Attach");
		    }
	    }
	    case Outlaw, Thumper:
	    {
	        if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
            {
                DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
                PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
            }
	    }
	}
	PlayerVehicleRacePosition(playerid, PVRP_Destroy, "");
	DestroySpecialObjects(playerid, model);
	if(GetVehicleComponentInSlot(Current_Vehicle[playerid], CARMODTYPE_NITRO))
	{
		RemoveVehicleComponent(Current_Vehicle[playerid], GetVehicleComponentInSlot(Current_Vehicle[playerid], CARMODTYPE_NITRO));
	}
	DestroyVehicle(Current_Vehicle[playerid]);
	Current_Vehicle[playerid] = 0;
	EMPTime[playerid] = 0;
 	TogglePlayerControllable(playerid, true);
	for(new go; go < 2; go++)
	{
		if(IsValidObject(Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][go]))
		{
			DestroyObject(Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][go]);
			Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][go] = INVALID_OBJECT_ID;
		}
		if(IsValidObject(Vehicle_Machine_Gun_Flash[Current_Vehicle[playerid]][go]))
		{
			DestroyObject(Vehicle_Machine_Gun_Flash[Current_Vehicle[playerid]][go]);
			Vehicle_Machine_Gun_Flash[Current_Vehicle[playerid]][go] = INVALID_OBJECT_ID;
		}
	}
	for(new s = 0; s < MAX_MISSILE_SLOTS; s++)
	{
	    EditPlayerSlot(playerid, s, PLAYER_MISSILE_SLOT_REMOVE);
        if(IsValidObject(Vehicle_Missile[vehicleid][s]))
		{
		    Object_Owner[Vehicle_Missile[vehicleid][s]] = INVALID_VEHICLE_ID;
	      	Object_OwnerEx[Vehicle_Missile[vehicleid][s]] = INVALID_PLAYER_ID;
	      	Object_Type[Vehicle_Missile[vehicleid][s]] = -1;
	      	Object_Slot[Vehicle_Missile[vehicleid][s]] = -1;
			DestroyObject(Vehicle_Missile[vehicleid][s]);
		}
		if(Vehicle_Missile[vehicleid][s] != INVALID_OBJECT_ID)
		{
		    Vehicle_Missile[vehicleid][s] = INVALID_OBJECT_ID;
		}
        for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
 		{
		 	if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
	  		{
			  	DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
			  	Vehicle_Missile_Lights_Attached[vehicleid][L] = -1;
			}
	 	}
       	if(IsValidObject(Vehicle_Smoke[vehicleid][s]))
   		{
		   DestroyObject(Vehicle_Smoke[vehicleid][s]);
		}
		if(Vehicle_Missile_Following[vehicleid][s] != INVALID_VEHICLE_ID) Vehicle_Missile_Following[vehicleid][s] = INVALID_VEHICLE_ID;
    }
   	KillTimer(Special_Missile_Timer[playerid]);
   	SetPVarInt(playerid, "Hammerhead_Special_Attacking", INVALID_PLAYER_ID);
	SetPVarInt(playerid, "Hammerhead_Special_Hit", INVALID_PLAYER_ID);
	ResetTwistedVars(playerid);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][AimingBox]);
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
	TextDrawHideForPlayer(playerid, Players_Online_Textdraw);
	PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthBar], 0x00F000FF);
	new msg[128], reasonMsg[32];
    switch(reason)
	{
        case 0: reasonMsg = "Fist";
        case 1: reasonMsg = "Brass Knuckles";
        case 2: reasonMsg = "Golf Club";
        case 3: reasonMsg = "Night Stick";
        case 4: reasonMsg = "Knife";
        case 5: reasonMsg = "Baseball Bat";
        case 6: reasonMsg = "Shovel";
        case 7: reasonMsg = "Pool Cue";
        case 8: reasonMsg = "Katana";
        case 9: reasonMsg = "Chainsaw";
        case 10: reasonMsg = "Long Purple Dildo";
        case 11: reasonMsg = "Short Tan Dildo";
        case 12: reasonMsg = "Small Vibrator";
        case 13: reasonMsg = "Vibrator";
        case 14: reasonMsg = "Flowers";
        case 15: reasonMsg = "Cane";
        case 16: reasonMsg = "Grenade";
        case 17: reasonMsg = "Tear Gas";
		case 18: reasonMsg = "Molotov";
		case 19: reasonMsg = "Rocket";
        case 22: reasonMsg = "Pistol";
        case 23: reasonMsg = "Silenced Pistol";
        case 24: reasonMsg = "Desert Eagle";
        case 25: reasonMsg = "Shotgun";
        case 26: reasonMsg = "Sawn-off Shotgun";
        case 27: reasonMsg = "Combat Shotgun";
        case 28: reasonMsg = "MAC-10";
        case 29: reasonMsg = "MP5";
        case 30: reasonMsg = "AK-47";
        case 31:
        {
            if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) {
                switch (GetVehicleModel(GetPlayerVehicleID(killerid))) {
                    case 447: reasonMsg = "Sea Sparrow Machine Gun";
                    default: reasonMsg = "M4";
                }
            }
            else reasonMsg = "M4";
        }
        case 32: reasonMsg = "TEC-9";
        case 33: reasonMsg = "Rifle";
        case 34: reasonMsg = "Sniper Rifle";
        case 35: reasonMsg = "Rocket Launcher";
		case 36: reasonMsg = "Heat-Seeking RPG";
        case 38:
        {
            if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) {
                switch (GetVehicleModel(GetPlayerVehicleID(killerid))) {
                    case 425:reasonMsg = "Hunter Machine Gun";
                    default: reasonMsg = "Minigun";
                }
            }
            else reasonMsg = "Minigun";
        }
        case 41: reasonMsg = "Spraycan";
        case 42: reasonMsg = "Fire Extinguisher";
        case 43: reasonMsg = "Camera";
        case 44: reasonMsg = "Night-Vision Goggles";
        case 46: reasonMsg = "Parachute";
        case 49: reasonMsg = "Vehicle Collision";
        case 50:
        {
            if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) {
                switch (GetVehicleModel(GetPlayerVehicleID(killerid))) {
                    case 417, 425, 447, 465, 469, 487, 488, 497, 501, 548, 563: reasonMsg = "Helicopter Blades";
                    default: reasonMsg = "Vehicle Collision";
                }
            }
            else reasonMsg = "Vehicle Collision";
        }
        case 51:
        {
            if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) {
                switch (GetVehicleModel(GetPlayerVehicleID(killerid))) {
                    case 425: reasonMsg = "Hunter Rockets";
                    case 432: reasonMsg = "Rhino Turret";
                    case 520: reasonMsg = "Hydra Rockets";
                    default: reasonMsg = "Explosion";
                }
            }
            else reasonMsg = "Explosion";
        }
        case 52, 37: reasonMsg = "Fire / Burnt To Death";
        case 53: reasonMsg = "Drowned";
        case 54: reasonMsg = "Fell To Death (Collision)";
        case 58: reasonMsg = "Flare";
        default: reasonMsg = "Unknown";
    }
    if (killerid != INVALID_PLAYER_ID)
	{
        format(msg, sizeof(msg), "04Death: 01%s(%d) Killed %s(%d) - Reason: %s", Playername(killerid), killerid, Playername(playerid), playerid, reasonMsg);
        SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "%s(%d) Died - Killed By: %s(%d) - %s", Playername(playerid), playerid, Playername(killerid), killerid, reasonMsg);
	}
    else {
        format(msg, sizeof(msg), "04Death: 01%s(%d) Died - Reason: %s", Playername(playerid), playerid, reasonMsg);
        SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "%s(%d) Died - %s", Playername(playerid), playerid, reasonMsg);
    }
	return 1;
}

stock ResetPlayerVars(playerid)
{
    iCurrentState[playerid] = PLAYER_STATE_NONE;
    PlayerInfo[playerid][pDonaterRank] = 0;
    PlayerInfo[playerid][Money] = 0;
    PlayerInfo[playerid][Score] = 0;
    PlayerInfo[playerid][Kills] = 0;
    PlayerInfo[playerid][Deaths] = 0;
    PlayerInfo[playerid][Assists] = 0;
    PlayerInfo[playerid][pKillStreaks] = 0;
    PlayerInfo[playerid][pExprience] = 0;
	PlayerInfo[playerid][pLast_Exp_Gained] = 0;
	PlayerInfo[playerid][pLevel] = 1;
	PlayerInfo[playerid][pTier_Points] = 0;
	PlayerInfo[playerid][pTravelled_Distance] = 0.0;
	PlayerInfo[playerid][pFavourite_Vehicle] = 0;
	PlayerInfo[playerid][pFavourite_Map] = -1;
	PlayerInfo[playerid][LoggedSeconds] = 0;
	PlayerInfo[playerid][LoggedMinutes] = 0;
	PlayerInfo[playerid][LoggedHours] = 0;
	PlayerInfo[playerid][LoggedDays] = 0;
    PlayerInfo[playerid][AdminLevel] = 0;
    PlayerInfo[playerid][pRegular] = 0;
    PlayerInfo[playerid][gTeam] = INVALID_GAME_TEAM;
    pSpectate_Random_Teammate[playerid] = 0;
    Objects_Preloaded[playerid] = 0;
    if(PlayerInfo[playerid][gGameID] != INVALID_GAME_ID)
    {
	    if((0 <= gGameData[PlayerInfo[playerid][gGameID]][g_Map_id] <= (MAX_MAPS - 1)))
		{
	    	CP_Progress[playerid] = s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Max_Grids];
	    }
    }
    Race_Current_Lap[playerid] = 1;
	Race_Position[playerid] = 0;
	Race_Old_Position[playerid] = 0;
	p_Position[playerid] = 0;
	p_Old_Position[playerid] = 0;
    Paused[playerid] = 0;
 	Delete3DTextLabel(PausedText[playerid]);
 	PausedText[playerid] = Text3D:INVALID_3DTEXT_ID;
 	PlayerInfo[playerid][Camera_Mode] = CAMERA_MODE_NONE;
 	PlayerInfo[playerid][Camera_Object] = INVALID_OBJECT_ID;
 	Selecting_Textdraw[playerid] = -1;
 	ResetPlayerGamePoints(playerid);
 	if(IsValidObject(Race_Object[playerid]))
    {
        DestroyObject(Race_Object[playerid]);
        Race_Object[playerid] = INVALID_OBJECT_ID;
    }
	return 1;
}

stock ResetTwistedVars(playerid)
{
    DisablePlayerCheckpoint(playerid);
	DisablePlayerRaceCheckpoint(playerid);
	new pm = 0;
	while(pm < 9)
	{
 		PlayerInfo[playerid][pMissiles][pm] = 0;
 		PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][pm]);
 		++pm;
 	}
 	EditPlayerSlot(playerid, _, PLAYER_MISSILE_SLOT_CLEAR);
 	Current_Car_Index[playerid] = 0;
 	pFiring_Missile[playerid] = 0;
 	pHUDStatus[playerid] = HUD_MISSILES;
    PlayerInfo[playerid][pTurbo] = 0;
    PlayerInfo[playerid][pEnergy] = 0;
    PlayerInfo[playerid][pSpawned] = 0;
    PlayerInfo[playerid][Turbo_Tick] = 0;
   	PlayerInfo[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
    PlayerInfo[playerid][pBurnout] = 0;
    PlayerInfo[playerid][pGender] = true;
    PlayerInfo[playerid][pLastVeh] = INVALID_VEHICLE_ID;
    PlayerInfo[playerid][pSpecial_Using_Alt] = 0;
    PlayerInfo[playerid][pMissile_Special_Time] = 0;
    PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
    PlayerInfo[playerid][pMissile_Charged] = -1;
    PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 0;
    PlayerInfo[playerid][CanExitVeh] = 0;
    PlayerInfo[playerid][pKillStreaking] = -1;
    if(2001 <= PlayerInfo[playerid][pSpecial_Missile_Vehicle] <= 4000)
	{
		PlayerInfo[playerid][pSpecial_Missile_Vehicle] -= 2000;
		DestroyVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	}
	if(4001 <= PlayerInfo[playerid][pSpecial_Missile_Vehicle] <= 6000)
	{
		PlayerInfo[playerid][pSpecial_Missile_Vehicle] -= 4000;
		DestroyVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	}
	if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	{
    	DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
    }
    for(new sp = 0; sp < MAX_SPECIAL_OBJECTS; sp++)
	{
	    if(IsValidObject(PlayerInfo[playerid][pSpecialObjects][sp]))
		{
			DestroyObject(PlayerInfo[playerid][pSpecialObjects][sp]);
		}
	}
    PlayerInfo[playerid][pSpecial_Missile_Vehicle] = 0;
    PlayerInfo[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
    KillTimer(Mine_Timer[playerid]);
    KillTimer(Special_Missile_Timer[playerid]);
    KillTimer(PlayerInfo[playerid][Turbo_Timer]);
    KillTimer(Machine_Gun_Firing_Timer[playerid]);
    KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
    KillTimer(PlayerInfo[playerid][pCharge_Timer]);
    new tid = GetPVarInt(playerid, "Flash_Roadkill_Timer");
	KillTimer(tid);
	KillTimer(PlayerInfo[playerid][EnvironmentalCycle_Timer]);
    if(IsValidObject(Nitro_Bike_Object[playerid]))
	{
		DestroyObject(Nitro_Bike_Object[playerid]);
	}
	return 1;
}

forward OnPlayerTwistedDeath(killerid, killer_vehicleid, deathid, death_vehicleid, missileid, killerid_modelid, deathid_modelid);
public OnPlayerTwistedDeath(killerid, killer_vehicleid, deathid, death_vehicleid, missileid, killerid_modelid, deathid_modelid)
{//// Kill an enemy vehicle.
    if(IsPlayerConnected(killerid) && killerid != deathid)
	{
	    PlayerInfo[killerid][pKillStreaking]++;
	    if(PlayerInfo[killerid][pKillStreaking] >= 1)
	    {
	        GainExprience(killerid, 25); // Go on a killstreak.
	        PlayerInfo[killerid][pKillStreaks]++;
	        ToggleAccountSavingVar(killerid, ACCOUNT_UPDATE_KILLSTREAKS);
	        format(Global_KSXPString, sizeof(Global_KSXPString), "KillStreak: %d", PlayerInfo[killerid][pKillStreaking]);
	        ShowKillStreak(killerid, Global_KSXPString);
	        if(PlayerInfo[killerid][pKillStreaking] == 2)
	        {
	            AddEXPMessage(killerid, "KS Bonus: Turbo & Energy Refill");
	            new model = killerid_modelid;
				PlayerInfo[killerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
				PlayerInfo[killerid][pEnergy] = floatround(GetTwistedMetalMaxEnergy(model));

				SetPlayerProgressBarValue(killerid, pTextInfo[killerid][pEnergyBar], float(PlayerInfo[killerid][pEnergy]));
				SetPlayerProgressBarValue(killerid, pTextInfo[killerid][pTurboBar], float(PlayerInfo[killerid][pTurbo]));
				UpdatePlayerProgressBar(killerid, pTextInfo[killerid][pEnergyBar]);
				UpdatePlayerProgressBar(killerid, pTextInfo[killerid][pTurboBar]);
	        }
	        if(PlayerInfo[killerid][pKillStreaking] == 3)
	        {
	            PlayerInfo[killerid][pMissiles][Missile_Machine_Gun_Upgrade] += 150;
		    	if(PlayerInfo[killerid][pMissiles][Missile_Machine_Gun_Upgrade] > 300)
		    	{
		    	    PlayerInfo[killerid][pMissiles][Missile_Machine_Gun_Upgrade] = 300;
		    	}
		    	AddEXPMessage(killerid, "KS Bonus: Mega Guns 150 Rounds");
		    	new idx[4];
				valstr(idx, PlayerInfo[killerid][pMissiles][Missile_Machine_Gun_Upgrade], false);
				PlayerTextDrawSetString(killerid, pTextInfo[killerid][Mega_Gun_IDX], idx);
		    	PlayerTextDrawShow(killerid, pTextInfo[killerid][Mega_Gun_IDX]);
				PlayerTextDrawShow(killerid, pTextInfo[killerid][Mega_Gun_Sprite]);
	        }
	        if(PlayerInfo[killerid][pKillStreaking] == 4) // only if tier 2
	        {
	            AddEXPMessage(killerid, "KS Bonus: Weapon Ammo Doubled");
	            for(new pm = 0; pm < MAX_MISSILEID; pm++)
	            {
	                if(PlayerInfo[killerid][pMissiles][pm] == 0) continue;
	                PlayerInfo[killerid][pMissiles][pm] *= 2;
	            }
	        }
	    }
	}
	if(IsPlayerConnected(deathid) && killerid != deathid)
	{
	    PlayerInfo[killerid][Kills]++;
	    PlayerInfo[deathid][Deaths]++;
	    ToggleAccountSavingVar(killerid, ACCOUNT_UPDATE_KILLS);
	    ToggleAccountSavingVar(deathid, ACCOUNT_UPDATE_DEATHS);
	    PlayerTextDrawBoxColor(deathid, pTextInfo[deathid][pHealthBar], 0x00F000FF);
	    new reason = 51;
	    switch(missileid)
	    {
	        case Missile_Special:
			{
			    switch(killerid_modelid)
				{
					case Thumper:
					{
						reason = 37;
						SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FF00FF, "%s Killed by %s", Playername(deathid), Playername(killerid));
					}
				}
			}
	        case Missile_Ram:
			{
				reason = 49;
				SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FF00FF, "%s Rammed To Death by %s", Playername(deathid), Playername(killerid));
			}
	        case Energy_Mines:
			{
				reason = 40;
				SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FF00FF, "%s Killed by %s", Playername(deathid), Playername(killerid));
			}
	        default:
			{
				SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FF00FF, "%s Killed by %s", Playername(deathid), Playername(killerid));
			}
	    }
	    SendDeathMessage(killerid, deathid, reason);
	    new Float:x, Float:y, Float:z, Float:maxhealth, Float:damagepercent,
			team_score[4], teamthatlostapoint = INVALID_GAME_TEAM, team_text[32], rival_text[32];
		GetPlayerPos(deathid, x, y, z);
		SetPlayerPos(deathid, x, y, z + 10);
		if(PlayerInfo[deathid][pKillStreaking] >= 1)
		{
		    GainExprience(killerid, 25); // Kill an enemy that's on a killstreak.
		    AddEXPMessage(killerid, "Streaker Kill 25 XP");
	        HideKillStreak(deathid);
		}
		PlayerInfo[deathid][pKillStreaking] = -1;
		switch(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode])
	    {
			case HUNTED:
			{
			    if(killerid == gHunted_Player[0])
			    {
			        GainPoints(killerid, 1);
			    }
			    if(deathid == gHunted_Player[0])
			    {
			        GainPoints(killerid, 1);
			        T_SetVehicleHealth(Current_Vehicle[gHunted_Player[0]], GetTwistedMetalMaxHealth(GetVehicleModel(Current_Vehicle[gHunted_Player[0]])));
			        gHunted_Player[0] = killerid;
		            new engine, lights, alarm, doors, bonnet, boot, objective;
					GetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
			    	TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, "You Killed The Hunted!", 3000 );
			    	SetPVarInt(killerid, "Killed_Hunted", 1);
			    }
			}
	        case TEAM_DEATHMATCH:
	        {
				Team_Info[PlayerInfo[killerid][gTeam]][TI_Score] += 1;
				valstr(team_score, Team_Info[PlayerInfo[killerid][gTeam]][TI_Score], false);
			}
			case TEAM_HUNTED:
			{
			    if(killerid == gHunted_Player[PlayerInfo[killerid][gTeam]]
		        && deathid == gHunted_Player[PlayerInfo[killerid][gRival_Team]]) // hunted killed hunted
		        {
		            Team_Info[PlayerInfo[killerid][gTeam]][TI_Score] += 2;
		            AssignRandomTeamHuntedPlayer(PlayerInfo[killerid][gRival_Team]);
		            TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, "You Killed The Hunted!", 3000 );
			    	SetPVarInt(killerid, "Killed_Hunted", 1);
		        }
		        else if(killerid == gHunted_Player[PlayerInfo[killerid][gTeam]]
					&& deathid != gHunted_Player[PlayerInfo[killerid][gRival_Team]]) // hunted killed normal player
		        {
		            Team_Info[PlayerInfo[killerid][gTeam]][TI_Score] += 1;
		            AssignRandomTeamHuntedPlayer(PlayerInfo[killerid][gRival_Team]);
		        }
			    else if(killerid != gHunted_Player[PlayerInfo[killerid][gTeam]] &&
					deathid == gHunted_Player[PlayerInfo[killerid][gRival_Team]]) // normal player killed hunted
			    {
			        Team_Info[PlayerInfo[killerid][gTeam]][TI_Score] += 1;
			        gHunted_Player[PlayerInfo[killerid][gRival_Team]] = INVALID_PLAYER_ID;
			        AssignRandomTeamHuntedPlayer(PlayerInfo[killerid][gRival_Team]);
			        TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, "You Killed The Hunted!", 3000 );
			    	SetPVarInt(killerid, "Killed_Hunted", 1);
			    }
			}
			case LAST_MAN_STANDING:
			{
			    new count = 0;
			    foreach(Player, i)
			    {
			        if(i == deathid) continue;
			        if(GetPlayerState(i) == PLAYER_STATE_SPECTATING) continue;
			        if(PlayerInfo[i][pSpawned] == 1) continue;
			        count++;
			    }
			    if(count == 1)
			    {
			        OnMapFinish(PlayerInfo[deathid][gGameID], gGameData[PlayerInfo[deathid][gGameID]][g_Gamemode], gGameData[PlayerInfo[deathid][gGameID]][g_Map_id]);
			    }
			    else pSpectate_Random_Teammate[deathid] = 1;
			}
			case TEAM_LAST_MAN_STANDING:
			{
			    if(gTeam_Lives[PlayerInfo[deathid][gTeam]] == 0)
			    {
			        gTeam_Player_Count[PlayerInfo[deathid][gTeam]]--;
			        if(gTeam_Player_Count[PlayerInfo[deathid][gTeam]] == 0)
			        {
			            Team_Info[PlayerInfo[deathid][gTeam]][TI_Score] = 0;
			            Team_Info[PlayerInfo[killerid][gTeam]][TI_Score] = 1;
						OnMapFinish(PlayerInfo[killerid][gGameID], gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode], gGameData[PlayerInfo[killerid][gGameID]][g_Map_id]);
						return 1;
			        }
			        pSpectate_Random_Teammate[deathid] = 1;
			    }
			    else gTeam_Lives[PlayerInfo[deathid][gTeam]]--;
			    teamthatlostapoint = PlayerInfo[deathid][gTeam];
			}
		}
		format(Global_KSXPString, sizeof(Global_KSXPString), "~y~~h~%s Killed By %s", Playername(deathid), Playername(killerid));
		AddEXPMessage(killerid, Global_KSXPString);
	    foreach(Player, i)
	    {
	        switch(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode])
		    {
		        case TEAM_DEATHMATCH, TEAM_HUNTED:
		        {
			        if(PlayerInfo[killerid][gTeam] == PlayerInfo[i][gTeam])
			        {
			            PlayerTextDrawSetString(i, pTextInfo[i][pTeam_Score], team_score);
			        }
			        else if(PlayerInfo[killerid][gTeam] != PlayerInfo[i][gTeam])
			        {
			            PlayerTextDrawSetString(i, pTextInfo[i][pRival_Team_Score], team_score);
			        }
				}
				case TEAM_LAST_MAN_STANDING:
				{
                    if(PlayerInfo[killerid][gTeam] == PlayerInfo[i][gTeam])
			        {
                        format(team_text, sizeof(team_text), "Teammates: %d~n~Team Lives: %d", gTeam_Player_Count[PlayerInfo[i][gTeam]], gTeam_Lives[PlayerInfo[i][gTeam]]);
                        PlayerTextDrawSetString(i, pTextInfo[i][pTeam_Score], team_text);
			        }
			        else if(PlayerInfo[killerid][gTeam] != PlayerInfo[i][gTeam])
			        {
			            format(rival_text, sizeof(rival_text), "Enemies: %d~n~Enemy Lives: %d", gTeam_Player_Count[PlayerInfo[i][gTeam]], gTeam_Lives[PlayerInfo[i][gTeam]]);
			            PlayerTextDrawSetString(i, pTextInfo[i][pRival_Team_Score], rival_text);
			        }
			        if(teamthatlostapoint == PlayerInfo[i][gTeam])
			        {
			            format(Global_KSXPString, sizeof(Global_KSXPString), "Your Team Has %d Lives Left", gTeam_Lives[PlayerInfo[i][gTeam]]);
			            AddEXPMessage(i, Global_KSXPString);
			        }
				}
	        }
	        if(i == killerid)
			{
			    if(GetPVarInt(killerid, "Killed_Hunted") == 0)
			    {
				    format(Global_KSXPString, sizeof(Global_KSXPString), "You Killed %s", Playername(deathid));
				    TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, Global_KSXPString, 3000 );
			    }
			    else DeletePVar(killerid, "Killed_Hunted");
			    maxhealth = GetTwistedMetalMaxHealth(deathid_modelid);
				damagepercent = PlayerInfo[i][pDamageToPlayer][deathid] / maxhealth * 100;
			    if(0 <= damagepercent < 14)
				{
				    if(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode] != HUNTED)
			    	{
				    	GainPoints(killerid, 25); // Poach Kill
				    }
				    GainExprience(killerid, 25);
				    TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Poach Kill, 25 Points!", 3000 );
				    AddEXPMessage(killerid, "Damage Bonus 25 XP");
				}
				else if(15 <= damagepercent < 39)
				{
				    if(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode] != HUNTED)
			    	{
				    	GainPoints(killerid, 50); // Soft Kill
				    }
				    GainExprience(killerid, 25);
				    TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Soft Kill, 50 Points!", 3000 );
				    AddEXPMessage(killerid, "Damage Bonus 25 XP");
				}
				else if(40 <= damagepercent < 74)
				{
				    if(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode] != HUNTED)
			    	{
				    	GainPoints(killerid, 75); // Kill
				    }
				    GainExprience(killerid, 25);
				    TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Kill, 75 Points!", 3000 );
				    AddEXPMessage(killerid, "Damage Bonus 25 XP");
				}
				else if(75 <= damagepercent < 94)
				{
				    if(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode] != HUNTED)
			    	{
				    	GainPoints(killerid, 100); // Strong Kill
				    }
				    GainExprience(killerid, 25);
				    TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Strong Kill, 100 Points!", 3000 );
				    AddEXPMessage(killerid, "Damage Bonus 25 XP");
				}
				else
				{
				    if(gGameData[PlayerInfo[killerid][gGameID]][g_Gamemode] != HUNTED)
			    	{
				    	GainPoints(killerid, 125); // Super Kill
				    }
				    GainExprience(killerid, 25);
				    TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Super Kill, 125 Points!", 3000 );
				    AddEXPMessage(killerid, "Damage Bonus 25 XP");
				}
			    PlayerInfo[i][pDamageToPlayer][deathid] = 0.0;
				continue;
			}
	        if(!(PlayerInfo[i][pDamageToPlayer][deathid] > 0.0) && i != killerid) continue;
			maxhealth = GetTwistedMetalMaxHealth(deathid_modelid);
			damagepercent = PlayerInfo[i][pDamageToPlayer][deathid] / maxhealth * 100;
			if(0 <= damagepercent < 24)
			{
			    if(gGameData[PlayerInfo[i][gGameID]][g_Gamemode] != HUNTED)
			    {
	    			GainPoints(i, 25); // Soft Assist
				}
			    PlayerInfo[i][Assists]++;
			    ToggleAccountSavingVar(i, ACCOUNT_UPDATE_ASSISTS);
			    GainExprience(i, 2);
			    TimeTextForPlayer( TIMETEXT_MIDDLE, killerid, "Soft Assist, 25 Points!", 3000 );
			    AddEXPMessage(i, "Soft Assist 2 XP");
			}
			else if(25 <= damagepercent < 74)
			{
			    if(gGameData[PlayerInfo[i][gGameID]][g_Gamemode] != HUNTED)
			    {
			    	GainPoints(i, 50); // Assist
				}
			    PlayerInfo[i][Assists]++;
			    ToggleAccountSavingVar(i, ACCOUNT_UPDATE_ASSISTS);
			    GainExprience(i, 5);
			    TimeTextForPlayer( TIMETEXT_MIDDLE, killerid, "Assist, 50 Points!", 3000 );
				AddEXPMessage(i, "Assist 5 XP");
			}
			else
			{
			    if(gGameData[PlayerInfo[i][gGameID]][g_Gamemode] != HUNTED)
			    {
			    	GainPoints(i, 75); // Strong Assist
			    }
			    PlayerInfo[i][Assists]++;
			    ToggleAccountSavingVar(i, ACCOUNT_UPDATE_ASSISTS);
			    GainExprience(i, 5);
			    TimeTextForPlayer( TIMETEXT_MIDDLE, killerid, "Strong Assist, 75 Points!", 3000 );
			    AddEXPMessage(i, "Strong Assist 10 XP");
			}
	        PlayerInfo[i][pDamageToPlayer][deathid] = 0.0;
		}
	}
    new Float:P[3], ht = random(EFFECT_RANDOM), xang = random(EFFECT_RANDOM)-EFFECT_FIX_DEFAULT,
		yang = random(EFFECT_RANDOM)-EFFECT_FIX_DEFAULT, zang = random(EFFECT_RANDOM) ;
    GetVehiclePos(death_vehicleid, P[0], P[1], P[2]);
    CreateExplosion(P[0], P[1], P[2] + EFFECT_EXPLOSIONOFFSET, EFFECT_EXPLOSIONTYPE, EFFECT_EXPLOSIONRADIUS);
    SetVehicleAngularVelocity(death_vehicleid, xang * EFFECT_MULTIPLIER, yang * EFFECT_MULTIPLIER, zang * EFFECT_FIX_Z);
    GetVehicleVelocity(death_vehicleid, P[0], P[1], P[2]);
    SetVehicleVelocity(death_vehicleid, P[0], P[1], P[2] + (ht * EFFECT_FIX_Z) );
	new reason;
	switch(missileid)
	{
		case Missile_Special:
		{
		    switch(killerid_modelid)
			{
				case Junkyard_Dog: reason = 0;
				case Brimstone: reason = 1;
				case Outlaw: reason = 2;
				case Reaper: reason = 3;
				case Roadkill: reason = 4;
				case Thumper: reason = 5;
				case Spectre: reason = 6;
				case Darkside: reason = 7;
				case Shadow: reason = 8;
				case Meat_Wagon: reason = 9;
				case Vermin: reason = 10;
				case Warthog_TM3: reason = 11;
				case ManSalughter: reason = 12;
				case Hammerhead: reason = 13;
				case Sweet_Tooth: reason = 14;
			}
		}
		case Missile_Fall: reason = 15;
		case Missile_Ram: reason = 16;
		default: reason = (16 + missileid);
	}
	if(deathid == INVALID_PLAYER_ID)
	{
		deathid = (MAX_PLAYERS - 1);
	}
	else
	{
	    new Float:health;
	    GetPlayerHealth(deathid, health);
	    if(health > 0.0)
	    {
	        SetPlayerHealth(deathid, -1);
	    }
	}
	printf("[System: OnPlayerTwistedDeath] - killer: %s(%d), %d, deathid: %s(%d), %d, %d(%s), killer: %s(%d), death: %s(%d)", Playername(killerid), killerid, killer_vehicleid, Playername(deathid), deathid, death_vehicleid, missileid, TwistedDeathArray[reason], GetTwistedMetalName(killerid_modelid), killerid_modelid, GetTwistedMetalName(deathid_modelid), deathid_modelid);
	return 1;
}

forward Reset_Invisibility(vehicleid);
public Reset_Invisibility(vehicleid)
{
    LinkVehicleToInterior(vehicleid, 0);
	return 1;
}

CMD:emp(playerid, params[])
{
    //18699 18702 18729 18728 18740 18724
	return 1;
}

CMD:jump(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    new cur_j_index = GetPVarInt(playerid, "Jumped_Index");
    switch(cur_j_index)
	{
	    case 0: {}
	    case 1:
	    {
	        if(GetPVarInt(playerid, "Jumped_Recently") <= gettime())
	    	{
	    		SetPVarInt(playerid, "Jumped_Index", 0);
	    		cur_j_index = 0;
	    	}
	    }
	    default:
	    {
	        if(GetPVarInt(playerid, "Jumped_Recently") > gettime()) return 1;
	    	SetPVarInt(playerid, "Jumped_Index", 0);
	    	cur_j_index = 0;
	    }
	}
	new Float:x, Float:y, Float:z, vehicleid = GetPlayerVehicleID(playerid),
		Float:offset = 0.3, timetoadd = 3;
	if(cur_j_index == 1)
	{
	    offset = 0.25;
	    timetoadd = 2;
	}
	GetVehicleVelocity(vehicleid, x, y, z);
	SetVehicleVelocity(vehicleid, x, y, (z + offset));
	SetPVarInt(playerid, "Jumped_Recently", gettime() + timetoadd);
	SetPVarInt(playerid, "Jumped_Index", cur_j_index + 1);
	return 1;
}

CMD:ainvisibility(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return SendClientMessage(playerid, RED, "Error: you are already in Invisibility mode");
	LinkVehicleToInterior(GetPlayerVehicleID(playerid), INVISIBILITY_INDEX);
	return 1;
}

CMD:resetinvisibility(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(GetVehicleInterior(GetPlayerVehicleID(playerid)) != INVISIBILITY_INDEX) return SendClientMessage(playerid, RED, "Error: you are not in Invisibility mode");
    Reset_Invisibility(GetPlayerVehicleID(playerid));
	return 1;
}

CMD:invisibility(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(PlayerInfo[playerid][pEnergy] < 25) return SendClientMessageFormatted(playerid, RED, "Error: "#cWhite"You don't have enough energy to activate invisibility "#cYellow"- Energy Left: %d", PlayerInfo[playerid][pEnergy]);
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return SendClientMessage(playerid, RED, "Error: You are already in Invisibility Mode");
	PlayerInfo[playerid][pEnergy] -= 25;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(PlayerInfo[playerid][pEnergy]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	LinkVehicleToInterior(GetPlayerVehicleID(playerid), INVISIBILITY_INDEX);
	SetTimerEx("Reset_Invisibility", 7000, false, "i", GetPlayerVehicleID(playerid));
	return 1;
}

CMD:shield(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(PlayerInfo[playerid][pEnergy] < 35) return SendClientMessageFormatted(playerid, RED, "Error: "#cWhite"You don't have enough energy to activate your shield "#cYellow"- Energy Left: %d", PlayerInfo[playerid][pEnergy]);
    PlayerInfo[playerid][pEnergy] -= 35;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(PlayerInfo[playerid][pEnergy]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	return 1;
}

CMD:mine(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(PlayerInfo[playerid][pEnergy] < 25) return SendClientMessageFormatted(playerid, RED, "Error: "#cWhite"You don't have enough energy to plant a mine "#cYellow"- Energy Left: %d", PlayerInfo[playerid][pEnergy]);
	if(strcmp(params, "alt_fire", true) != 0)
	{

	}
	PlayerPlaySound(playerid, 25800, 0.0, 0.0, 0.0);
	new id = GetPlayerVehicleID(playerid), Float:x, Float:y, Float:z, Float:a,
		slot = GetFreeMissileSlot(id), Float:sX, Float:sY, Float:sZ;
	if(IsValidObject(Vehicle_Missile[id][slot]))
	{
	    Object_Owner[Vehicle_Missile[id][slot]] = INVALID_VEHICLE_ID;
      	Object_OwnerEx[Vehicle_Missile[id][slot]] = INVALID_PLAYER_ID;
      	Object_Type[Vehicle_Missile[id][slot]] = -1;
      	Object_Slot[Vehicle_Missile[id][slot]] = -1;
		DestroyObject(Vehicle_Missile[id][slot]);
		EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_REMOVE);
	}
	GetVehicleModelInfo(GetVehicleModel(id), VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
  	GetVehiclePos(id, x, y, z);
   	GetVehicleZAngle(id, a);
    a += 180.0;
	sY /= 1.7;
	y += ( sY * floatcos( -a, degrees ) );
    z -= 0.3;
	Vehicle_Missile[id][slot] = CreateObject(1654, x, y, z, 0, 90.0, (a + 180), 300.0);
	Vehicle_Smoke[id][slot] = CreateObject(19282, x, y, z + 0.05, 0, 0.0, 0.0, 300.0); //red small light
	Object_Owner[Vehicle_Missile[id][slot]] = id;
  	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
  	Object_Type[Vehicle_Missile[id][slot]] = Energy_Mines;
  	Object_Slot[Vehicle_Missile[id][slot]] = slot;
  	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
	Mine_Timer[playerid] = SetTimerEx("Explode_Missile", 10000, false, "iiii", playerid, id, slot, Energy_Mines);
    PlayerInfo[playerid][pEnergy] -= 25;
    SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(PlayerInfo[playerid][pEnergy]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	return 1;
}

public OnUnoccupiedVehicleUpdate(vehicleid, playerid, passenger_seat)
{
	new Float: fVehicle[3], myid = GetPlayerVehicleID(playerid), Float:speed,
		Float:vX, Float:vY, Float:vZ, Float:mx, Float:my, Float:mz;
	GetVehiclePos(myid, mx, my, mz);
	GetVehiclePos(vehicleid, fVehicle[0], fVehicle[1], fVehicle[2]);
	if(1 <= myid <= 2000)
	{
        ConfigureVehicleRAMPos(myid, mx, my);
		if(GetVehicleDistanceFromPoint(myid, fVehicle[0], fVehicle[1], fVehicle[2]) < TwistedRAMRadius(GetVehicleModel(myid)))
		{
      		GetVehicleVelocity(myid, vX, vY, vZ);
      		speed = GetVehicleSpeed(myid, false);
			CallLocalFunction("OnVehicleHitUnoccupiedVehicle", "iiif", playerid, myid, vehicleid, speed);
		}
	}
	if(!IsPlayerInRangeOfPoint(playerid, 10, fVehicle[0], fVehicle[1], fVehicle[2]))
	{
	    return;
	}
}

forward OnVehicleHitUnoccupiedVehicle(playerid, myvehicleid, vehicleid, Float:speed);
forward OnVehicleHitVehicle(playerid, myvehicleid, hitplayerid, vehicleid, Float:speed);

public OnVehicleHitUnoccupiedVehicle(playerid, myvehicleid, vehicleid, Float:speed)
{
	if(speed > 0.0 && WasDamaged[vehicleid] == 0)
	{
	    WasDamaged[vehicleid] = 1;
	    SetTimerEx("ResetCollision", 750, false, "i", vehicleid);
    	CallLocalFunction("OnVehicleHitVehicle", "iiiif", playerid, myvehicleid, INVALID_PLAYER_ID, vehicleid, speed);
    }
	return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
	//printf("[System: OnVehicleDamageStatusUpdate] - vehicleid: %d - playerid: %d", vehicleid, playerid);
	new panels, doors, lights, tires;
    GetVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	if(tires)
	{
	    new Float:x, Float:y, Float:z;
	    GetPlayerPos(playerid, x, y, z);
		PlayerPlaySound(playerid, 6402, x, y, z);
		tires = encode_tires(0, 0, 0, 0); // fix all tires
    	UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	}
	if(lights)
	{
	    new Float:x, Float:y, Float:z;
	    GetPlayerPos(playerid, x, y, z);
		PlayerPlaySound(playerid, 6402, x, y, z);
    	lights = encode_lights(0, 0, 0, 0); // fix all lights
    	UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	}
    return 1;
}

encode_tires(tire1, tire2, tire3, tire4) return tire1 | (tire2 << 1) | (tire3 << 2) | (tire4 << 3);
encode_panels(flp, frp, rlp, rrp, windshield, front_bumper, rear_bumper)
{
    return flp | (frp << 4) | (rlp << 8) | (rrp << 12) | (windshield << 16) | (front_bumper << 20) | (rear_bumper << 24);
}
encode_doors(bonnet, boot, driver_door, passenger_door, behind_driver_door, behind_passenger_door)
{
    #pragma unused behind_driver_door
    #pragma unused behind_passenger_door
    return bonnet | (boot << 8) | (driver_door << 16) | (passenger_door << 24);
}
#pragma unused encode_panels
#pragma unused encode_doors
encode_lights(light1, light2, light3, light4)
{
    return light1 | (light2 << 1) | (light3 << 2) | (light4 << 3);
}

forward ResetCollision(vehicleid);
public ResetCollision(vehicleid){ WasDamaged[vehicleid] = 0; return 1; }

new Float:oldVehicleHealth[MAX_VEHICLES], Float:newVehicleHealth[MAX_VEHICLES]; // change MAX_VEHICLES to your own vehicle amount.

#define MAX_VEHICLE_MAX 2500.0

ConfigureVehicleRAMPos(vehicleid, &Float:x, &Float:y)
{
	switch(GetVehicleModel(vehicleid))
	{
	    case Darkside:
	    {
	        new Float:angle;
	        GetVehicleZAngle(vehicleid, angle);
     		x += (3.0 * floatsin(-angle, degrees));
        	y += (3.0 * floatcos(-angle, degrees));
	    }
	    case Hammerhead:
	    {
	        new Float:angle;
	        GetVehicleZAngle(vehicleid, angle);
     		x += (1.5 * floatsin(-angle, degrees));
        	y += (1.5 * floatcos(-angle, degrees));
	    }
	    case ManSalughter:
	    {
	        new Float:angle;
	        GetVehicleZAngle(vehicleid, angle);
     		x += (1.0 * floatsin(-angle, degrees));
        	y += (1.0 * floatcos(-angle, degrees));
	    }
	}
	return 1;
}

forward OnPlayerVehicleHealthChange(playerid, vehicleid, Float:newhealth, Float:oldhealth);
public OnPlayerVehicleHealthChange(playerid, vehicleid, Float:newhealth, Float:oldhealth)
{
	if(!(1 <= vehicleid <= MAX_VEHICLES)) return 1;
	if(WasDamaged[vehicleid] == 0 && newhealth < oldhealth)
	{
		WasDamaged[vehicleid] = 1;
		new Float:x, Float:y, Float:z, Float:mx, Float:my, Float:mz,
			rammer = INVALID_VEHICLE_ID, Float:ramspeed = 0.0,
			beingrammed = INVALID_VEHICLE_ID;
		GetVehiclePos(vehicleid, mx, my, mz);
	    foreach(Vehicles, id)
	    {//compare both veloocites and do damage based off them
	        if(id >= MAX_VEHICLES) break;
	        if(vehicleid == id) continue;
	        if(WasDamaged[id] == 1)
	        {
	            new Float:yX, Float:yY, Float:yZ, Float:oyX, Float:oyY, Float:oyZ, Float:speed[2];
	            GetVehicleVelocity(id, yX, yY, yZ);
	            GetVehicleVelocity(vehicleid, oyX, oyY, oyZ);
	            speed[0] = (yX * yX + yY * yY);
	            speed[1] = (oyX * oyX + oyY * oyY);
	            //SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "id: %d (%0.2f) - oid: %d (%0.2f) - dis: %0.2f", id, speed[0], vehicleid, speed[1], GetVehicleDistanceFromPoint(vehicleid, x, y, z));
	            if(speed[0] > speed[1])
				{
				    speed[0] = GetVehicleSpeed(id, false);
				    rammer = id;
	      			ramspeed = speed[0];
	      			beingrammed = vehicleid;
				}
				else if(speed[1] > speed[0])
				{
				    speed[1] = GetVehicleSpeed(vehicleid, false);
				    rammer = vehicleid;
				    ramspeed = speed[1];
				    beingrammed = id;
	      		}
				else if(speed[1] == speed[0])
				{
				    speed[0] = GetVehicleSpeed(id, false);
				    speed[1] = GetVehicleSpeed(vehicleid, false);
				    rammer = id;
                    ramspeed = speed[0];
                    beingrammed = vehicleid;
	      			CallLocalFunction("OnVehicleHitVehicle", "iiiif", MPGetVehicleDriver(beingrammed), beingrammed, MPGetVehicleDriver(rammer), rammer, speed[1]);
				}
				GetVehiclePos(rammer, x, y, z);
	            ConfigureVehicleRAMPos(rammer, mx, my);
	            if(TwistedRAMRadius(GetVehicleModel(rammer)) <= GetVehicleDistanceFromPoint(beingrammed, x, y, z)) continue;

				CallLocalFunction("OnVehicleHitVehicle", "iiiif", MPGetVehicleDriver(rammer), rammer, MPGetVehicleDriver(beingrammed), beingrammed, ramspeed);
				rammer = INVALID_VEHICLE_ID;
				beingrammed = INVALID_VEHICLE_ID;
				ramspeed = 0.0;
	        }
	    }
	    SetTimerEx("ResetCollision", 750, false, "i", vehicleid);
	}
	if(vehicleid == PlayerInfo[playerid][pSpecial_Missile_Vehicle] && newhealth < oldhealth)
	{
	    new Float:x, Float:y, Float:z, Float:distaway = 1.0; //slot = SPECIAL_MISSILE_SLOT
		new id = GetClosestVehicleEx(playerid, 9.0, distaway);
        if(id != INVALID_VEHICLE_ID)
        {
            new Float:damage, distance_type = d_type_none;
            switch(GetVehicleModel(Current_Vehicle[playerid]))
	        {
				case Junkyard_Dog:
				{
				    return 1;
				}
	            case Vermin:
	            {
	                switch(floatround(distaway))
			        {
			            case 5..9: damage = 20.0, distance_type = d_type_close;
			            case 0..4: damage = GetMissileDamage(Missile_Special, Current_Vehicle[playerid], 1);
			        }
			        printf("distaway: %0.2f - distance_type: %d", distaway, distance_type);
	            }
	            case Meat_Wagon:
	            {
			        switch(floatround(distaway))
			        {
			            case 8..9: damage = 10.0, distance_type = d_type_far;
			            case 4..7: damage = 20.0, distance_type = d_type_close;
			            case 0..3: damage = GetMissileDamage(Missile_Special, Current_Vehicle[playerid], 1);
			        }
		        }
	        }
	        DamagePlayer(playerid, Current_Vehicle[playerid], MPGetVehicleDriver(id), id, damage, Missile_Special, 1, distance_type);
        }
        GetObjectPos(PlayerInfo[playerid][pSpecial_Missile_Object], x, y, z);
	    CreateMissileExplosion(vehicleid, Missile_Special, x, y, z, 1);
	    DestroyVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
	    new Float:health;
		GetPlayerHealth(playerid, health);
	    if(!(health == 0.0))
		{
			PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
			PlayerInfo[playerid][pSpecial_Missile_Vehicle] = 0;
		}
        pFiring_Missile[playerid] = 0;
        KillTimer(Special_Missile_Timer[playerid]);
  	}
  	if(-1.7 <= MPGetVehicleUpsideDown(vehicleid) <= -0.3)
	{
	    //1.0 = car placed on level ground
		//0.0 = car is 90 degrees on side
		//-1.0 would be totally upside down
	    new Float:Angle, Float:x, Float:y, Float:z;
	    GetVehicleVelocity(vehicleid, x, y, z);
 		GetVehicleZAngle(vehicleid, Angle);
 		SetVehicleZAngle(vehicleid, Angle);
 		SetVehicleVelocity(vehicleid, x, y, z);
	}
  	if(newhealth < (MAX_VEHICLE_MAX - 100.0))
	{
	    SetVehicleHealth(vehicleid, MAX_VEHICLE_MAX);
	}
	return 1;
}

stock CreateMissileExplosion(vehicleid, missileid, Float:x, Float:y, Float:z, alt_special = 0)
{
	new e_Objectid = INVALID_OBJECT_ID;
	switch(missileid)
	{
	    case Missile_Special:
	    {
	        switch(GetVehicleModel(vehicleid))
	        {
	            case Spectre, Junkyard_Dog:
				{
				    CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
				    e_Objectid = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
				}
				case Reaper:
				{
				    switch(alt_special)
					{
					    case 1:
					    {
					        CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
				    		e_Objectid = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
	                   	}
	                   	default: e_Objectid = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
					}
				}
				case Roadkill, Sweet_Tooth, Warthog_TM3:
				{
				    e_Objectid = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
				}
	            case Vermin, Meat_Wagon:
				{
				    switch(alt_special)
					{
					    case 1:
					    {
					        CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
		    				e_Objectid = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
		    			}
		    			default:
		    			{
	        				e_Objectid = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
		    			}
					}
				}
			}
		}
		case Missile_Power:
		{
		    e_Objectid = CreateObject(18681, x, y, z, 0.0, 0.0, 0.0, 300.0);
		}
		case Missile_Napalm:
		{
		    e_Objectid = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
		    CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
  		}
		case Missile_Fire, Missile_Homing, Missile_Ricochet, Missile_Stalker:
		{
		    e_Objectid = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
		}
		case Energy_Mines:
		{
		    CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
		}
	}
	if(IsValidObject(e_Objectid))
	{
		SetTimerEx("Destroy_Explosion", 200, false, "i", e_Objectid);
	}
	return 1;
}

forward Destroy_Explosion(objectid);
public Destroy_Explosion(objectid)
{
	DestroyObject(objectid);
	return 1;
}

forward Reset_SMV(playerid);
public Reset_SMV(playerid)
{
    PlayerInfo[playerid][pSpecial_Missile_Vehicle] = 0;
	return 1;
}
forward Float:TwistedRAMRadius(twistedid);
stock Float:TwistedRAMRadius(twistedid)
{
	switch(twistedid)
	{
		case Junkyard_Dog, Brimstone, Outlaw, Roadkill, Thumper, Spectre,
			Shadow, Meat_Wagon, Vermin, Sweet_Tooth: return 12.0;
		case Reaper: return 9.0;
		case Darkside, Hammerhead: return 16.0;
		case ManSalughter: return 14.0;
	}
	return 12.0;
}
forward Float:TwistedMass(twistedid);
stock Float:TwistedMass(twistedid)
{
	switch(twistedid)
	{
		case Junkyard_Dog: return 3500.0;
		case Brimstone: return 1.2;
		case Outlaw: return 1.1;
		case Reaper: return 800.0;
		case Roadkill: return 1200.0;
		case Thumper: return 1500.0;
		case Spectre: return 1700.0;
		case Darkside: return 5000.0;
		case Shadow: return 0.9;
		case Meat_Wagon: return 0.9;
		case Vermin: return 0.8;
		case Warthog_TM3: return 5000.0;
		case ManSalughter: return 0.8;
		case Hammerhead: return 0.8;
		case Sweet_Tooth: return 0.7;
	}
	return 1.0;
}
new Float:Twisted_Custom_Health[MAX_VEHICLES];

public OnVehicleHitVehicle(playerid, myvehicleid, hitplayerid, vehicleid, Float:speed)
{
	if(playerid == INVALID_PLAYER_ID || myvehicleid == vehicleid || speed < 20.0) return 1;
	if(PlayerInfo[playerid][pSpecial_Missile_Vehicle] == myvehicleid) return 1;
    //SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "Vehicleid: %d Collided With Vehicleid: %d", myvehicleid, vehicleid);
    new Float:Health, str[32], Float:total, style = TIMETEXT_TOP, model = GetVehicleModel(myvehicleid),
		Float:size_x, Float:size_y, Float:size_z, Float:volume, omodel = GetVehicleModel(vehicleid);
	GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, size_x, size_y, size_z);
	volume = (size_x + size_y + size_z) / 2;
	total = (speed + volume);
	GetVehicleModelInfo(omodel, VEHICLE_MODEL_INFO_SIZE, size_x, size_y, size_z);
	volume = (size_x + size_y + size_z);
	total -= volume;
	if(GetPVarInt(playerid, "InTightTurn"))
	{
	    total *= 1.2;
	}
	switch(omodel)
	{
	    case Junkyard_Taxi:
	    {
	        if(PlayerInfo[playerid][pSpecial_Missile_Vehicle] == vehicleid) return 1;
	        foreach(Player, i)
	        {
	            if(PlayerInfo[i][pSpecial_Missile_Vehicle] != vehicleid) continue;
				DamagePlayer(i, Current_Vehicle[i], playerid, myvehicleid, GetMissileDamage(Missile_Special, Current_Vehicle[i], 0), Missile_Special, 0, d_type_none);
				GetVehiclePos(vehicleid, size_x, size_y, size_z);
				CreateMissileExplosion(Current_Vehicle[i], Missile_Special, size_x, size_y, size_z, 0); //, GetFreeMissileSlot(Current_Vehicle[i])
				DestroyVehicle(vehicleid);
				PlayerInfo[i][pSpecial_Missile_Vehicle] = INVALID_VEHICLE_ID;
				DeletePVar(i, "Junkyard_Dog_Attach");
				break;
			}
	    }
	}
	start:
	switch( floatround(total) )
	{
	    case 0..49:
	    {
	        format(str, sizeof(str), "Ram Damage Hit %d damage", floatround(total));
	    }
	    case 50..74:
		{
		    format(str, sizeof(str), "SUPER RAM %d damage", floatround(total));
		    style = TIMETEXT_MIDDLE;
	    }
	    default:
	    {
	        if(total < 0)
			{
				total = 1;
				goto start;
			}
	        format(str, sizeof(str), "MASSIVE RAM %d damage", floatround(total));
	        style = TIMETEXT_MIDDLE;
	    }
	}
	if(PlayerInfo[playerid][pMissile_Charged] == Missile_Special)
	{
	    switch(model)
	    {
			case Darkside:
			{
			    total *= 1.1;
			    format(str, sizeof(str), "DARKSIDE SLAM! %d damage", floatround(total));
			    style = TIMETEXT_MIDDLE;
			}
			case Hammerhead:
			{
			    total *= 0.7;
			    format(str, sizeof(str), "RAM ATTACK! %d damage", floatround(total));
			    style = TIMETEXT_MIDDLE;
    			KillTimer(Special_Missile_Timer[playerid]);
    			PlayerInfo[playerid][pMissile_Charged] = -1;
   				SetPVarInt(playerid, "Hammerhead_Special_Hit", hitplayerid);
   				new engine, lights, alarm, doors, bonnet, boot, objective;
				GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
				SetVehicleParamsEx(vehicleid, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);
			}
		}
	}
	T_GetVehicleHealth(vehicleid, Health);
	T_SetVehicleHealth(vehicleid, floatsub(Health, total));
	if(Health < 0.0)
	{
		CallLocalFunction( "OnPlayerTwistedDeath", "ddddddi", playerid, myvehicleid, hitplayerid, vehicleid, Missile_Ram, model, omodel);
		if(!IsPlayerConnected(MPGetVehicleDriver(vehicleid)))
	   	{
		   	DestroyVehicle(vehicleid);
		}
	}
	TimeTextForPlayer( style, playerid, str, 3000);
	return 1;
}

/*new model = Thumper;
    new Float:size_x, Float:size_y, Float:size_z, Float:volume, Float:force, Float:speed = 86.0;
	GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, size_x, size_y, size_z);
	volume = (size_x * size_y * size_z);
	printf("x: %f - y: %f - z: %f", size_x, size_y, size_z);
	printf("volume: %f", volume);
	force = ((volume * TwistedMass(model)) / 3500) + (speed / 2);
	printf("force: %f", force);*/

forward OnEthicalHealthChange(vehicleid, playerid, Float:newhealth, Float:oldhealth);
public OnEthicalHealthChange(vehicleid, playerid, Float:newhealth, Float:oldhealth)
{
	if(PlayerInfo[playerid][pSpawned] == 0) return 1;
	new Float:health, Float:maxhealth = GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid));
   	health = (newhealth) / maxhealth * 100.0;
	if(health <= 0.0) health = -1;
	SetPlayerHealth(playerid, health);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pHealthBar], 0.0, (health * -0.086) - ((health > 50.0) ? 0.1 : 0.66));
	health = (maxhealth / 2.0);
	maxhealth = (health / 2.0);
	//printf("newhealth: %0.2f - health2: %0.2f - health4: %0.2f", newhealth, health, maxhealth);
	if(newhealth < health)
	{
	    if(newhealth < maxhealth)
		{
		    PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthBar], 0xF00000FF);
		}
		else PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthBar], 0xFFEA00FF);
	}
	else
	{
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthBar], 0x00F000FF);
	}
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthBar]);
	return 1;
}

stock T_SetVehicleHealth(vehicleid, Float:health)
{
	new Float:oldhealth = Twisted_Custom_Health[vehicleid], playerid = MPGetVehicleDriver(vehicleid);
	Twisted_Custom_Health[vehicleid] = health;
	if(playerid != INVALID_PLAYER_ID)
	{
		CallLocalFunction("OnEthicalHealthChange", "iiff", vehicleid, playerid, Twisted_Custom_Health[vehicleid], oldhealth);
	}
	return 1;
}

stock T_GetVehicleHealth(vehicleid, &Float:health)
{
	if(!GetVehicleHealth(vehicleid, health)) return 0;
	if(health)
	{
 		health = Twisted_Custom_Health[vehicleid];
	}
	else return floatround(Twisted_Custom_Health[vehicleid]);
 	return 1;
}

CMD:health(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid), Float:health;
    T_GetVehicleHealth(vehicleid, health);
    SendClientMessageFormatted(playerid, -1, "Health: %0.2f", health);
	return 1;
}

CMD:sethealth(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);
	if(sscanf(params, "d", vehicleid)) return 1;
    T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid)));
    SendClientMessage(playerid, -1, "Health Set");
	return 1;
}

CMD:setvhealth(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid), Float:health;
	if(sscanf(params, "dF(1000.0)", vehicleid, health)) return 1;
    SetVehicleHealth(vehicleid, health);
    SendClientMessage(playerid, -1, "Health Set");
	return 1;
}

//new Float:speedometer_alpha;
/*
CMD:alpha(playerid, params[])
{
	if(isnull(params)) return SendClientMessage(playerid, -1, "Usage: /alpha [27 - 360]");
	if(!isNumeric(params)) return SendClientMessage(playerid, -1, "Usage: /alpha [27 - 360] - Use A Numerical Value!");
	if(speedometer_alpha < 42) speedometer_alpha = 42;
	speedometer_alpha = floatstr(params);
    SendClientMessageFormatted(playerid, -1, "New Alpha: %0.2f", speedometer_alpha);
	return 1;
}*/

new bool:debugkeys;
CMD:debugkeys(playerid, params[])
{
	debugkeys = !debugkeys;
	return 1;
}

new gAttached[MAX_PLAYERS];

forward OnTrailerAttach(playerid, vehicleid, trailerid);
forward OnTrailerDetach(playerid, vehicleid, trailerid);
public OnTrailerAttach(playerid, vehicleid, trailerid)
{
	return 1;
}

public OnTrailerDetach(playerid, vehicleid, trailerid)
{
	if(GetPVarInt(playerid, "Junkyard_Dog_Attach") == trailerid)
	{
    	GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~b~~h~Reattaching Taxi", 4500, 3);
    	AttachTrailerToVehicle(trailerid, vehicleid);
    }
	return 1;
}

public OnPlayerUpdate(playerid)
{
	//if(IsPlayerNPC(playerid))
	//{
	    //printf("NPC ID: %d - Animation: %d", playerid, GetPlayerAnimationIndex(playerid));
	//}
	if(PlayerInfo[playerid][pSpawned] == 1)
	{
	    if(PlayerUpdate{playerid} >= 2)
		{
		    Paused[playerid] = 0;
			CallRemoteFunction("OnPlayerUnPause", "i", playerid);
		}
	    PlayerUpdate{playerid} = 0;
	    new vehicleid = GetPlayerVehicleID(playerid);
	    if(vehicleid != 0)
		{
		    new Float:health;
	  		GetVehicleHealth(vehicleid, health);
		    newVehicleHealth[vehicleid] = health;
		    if(newVehicleHealth[vehicleid] != oldVehicleHealth[vehicleid])
		    {
		        CallLocalFunction("OnPlayerVehicleHealthChange", "iiff", playerid, vehicleid, newVehicleHealth[vehicleid], oldVehicleHealth[vehicleid]);
		      	oldVehicleHealth[vehicleid] = newVehicleHealth[vehicleid];
		    }
		    if(( 1 <= PlayerInfo[playerid][pSpecial_Missile_Vehicle] <= 2000 ))
		    {
		        new trailerid = GetVehicleTrailer(vehicleid);
		        if (gAttached[playerid] != trailerid)
		        {
		            if (trailerid == 0 || trailerid == INVALID_VEHICLE_ID)
		            {
		                CallLocalFunction("OnTrailerDetach", "iii", playerid, vehicleid, gAttached[playerid]);
		            }
		            else if (trailerid)
		            {
		                CallLocalFunction("OnTrailerAttach", "iii", playerid, vehicleid, trailerid);
		            }
		            gAttached[playerid] = trailerid;
		        }
		        vehicleid = PlayerInfo[playerid][pSpecial_Missile_Vehicle];
		        GetVehicleHealth(vehicleid, health);
			    newVehicleHealth[vehicleid] = health;
			    if(newVehicleHealth[vehicleid] != oldVehicleHealth[vehicleid])
			    {
			        CallLocalFunction("OnPlayerVehicleHealthChange", "iiff", playerid, vehicleid, newVehicleHealth[vehicleid], oldVehicleHealth[vehicleid]);
			      	oldVehicleHealth[vehicleid] = newVehicleHealth[vehicleid];
			    }
		    }
			new ud, lr, keys;
            GetPlayerKeys(playerid, keys, ud, lr);
            if(debugkeys && keys != 0)
            {
                printf("keys: %d - ud: %d - lr: %d", keys, ud, lr);
            }
            if (lr != 0 && gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Countdown_Time] == 0)
            {
                if(keys == 0)
                {
		            new Float:vx, Float:vy, Float:vz;
					GetVehicleVelocity(vehicleid, vx, vy, vz);
					if((vx * vx + vy * vy + vz * vz) < 0.003)
					{
		            	vx = 0.045;
		            	SetVehicleAngularVelocity(vehicleid, 0.0, (lr == 128) ? 0.01 : -0.01, (lr == 128) ? -vx : vx);
		            	SetVehicleVelocity(vehicleid, 0.0, 0.0, vz);
		            }
				}
    			if((keys & KEY_HANDBRAKE) && GetPVarInt(playerid, "InTightTurn") == 0)
	            {
	                new Float:vx, Float:vy, Float:vz;
					GetVehicleVelocity(vehicleid, vx, vy, vz);
					if((vx * vx + vy * vy + vz * vz) >= 0.003)
					{
		                //printf("OnPlayerStartTightTurn");
		                SetPVarInt(playerid, "InTightTurn", 1);
		                SetPVarInt(playerid, "InTightTurnTime", GetTickCount());
	                }
	            }
            }
			if(GetPVarInt(playerid, "InTightTurn") == 1 && !(keys == KEY_HANDBRAKE))
			{
			    //printf("OnPlayerFinishTightTurn");
			    new time = GetTickCount() - GetPVarInt(playerid, "InTightTurnTime");
			    SetPVarInt(playerid, "InTightTurn", 0);
			    SetPVarInt(playerid, "InTightTurnTime", 0);
			    if(time > 150)
			    {
				    new Float:currspeed[3], Float:direction[3], Float:total;
					GetVehicleVelocity(vehicleid, currspeed[0], currspeed[1], currspeed[2]);
					total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
					total += 0.18;
					new Float:invector[3] = {0.0, -1.0, 0.0};
					RotatePointVehicleRotation(vehicleid, invector, direction[0], direction[1], direction[2]);
					SetVehicleVelocity(vehicleid, direction[0] * total, direction[1] * total, direction[2] * total);
					/*//jump
					new Float:Zangle, Float:Xv, Float:Yv, Float:Zv;
			        GetVehicleZAngle(vehicleid, Zangle);
			        GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
			        Xv = (0.6 * floatsin(Zangle, degrees));
			        Yv = (0.6 * floatcos(Zangle, degrees));
			        SetVehicleAngularVelocity(vehicleid, Yv, Xv, 0);*/
		        }
			}
            if(pFiring_Missile[playerid] == Reaper && PlayerInfo[playerid][pSpecial_Using_Alt] == 0)
            {
                new Float:heading, Float:attitude, Float:bank;
                GetVehicleRotation(vehicleid, heading, attitude, bank);
                if( 30.0 <= bank <= 90.0 )
                {
                	GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~Flame Saw Activated!", 4000, 3);
                	PlayerInfo[playerid][pSpecial_Using_Alt] = 1;
                	SetPlayerAttachedObject(playerid, Reaper_Chainsaw_Flame_Index, 18688, Reaper_Chainsaw_Bone, 0.8, 0.4, -1.9, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0);
                	ApplyAnimation(playerid, "ped", "DAM_armL_frmFT", 4.0, 0, 0, 0, 0, 0, 1);
				}
			}
			/*if(!DeActiveSpeedometer{playerid})
			{
				new pstate = GetPlayerState(playerid);
			  	if(pstate == PLAYER_STATE_DRIVER)
			 	{
			 	    static Float:x, Float:y, Float:z, Float:Pos[8][2], Float:Speed;
			    	GetVehicleVelocity(vehicleid, x, y, z);
					Speed = floatmul(floatsqroot(floatadd(floatadd(floatpower(x, 2), floatpower(y, 2)),  floatpower(z, 2))), 200.0);
					new Float:alpha = 333.0 - floatdiv(Speed, 1.609344); //if(alpha > 333.0) alpha = 333.0;
					for(new i = 0; i < Speedometer_Needle_Index; i++)
			  		{
			         	TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
			          	TextDrawDestroy(pTextInfo[playerid][SpeedoMeterNeedle][i]);
			           	GetDotXY((531.0 - 152.0), (280.0 + 135.0), Pos[i][0], Pos[i][1], alpha, (i + 1) * 4);
			            pTextInfo[playerid][SpeedoMeterNeedle][i] = TextDrawCreate(Pos[i][0], Pos[i][1], "~b~.");
			            TextDrawLetterSize(pTextInfo[playerid][SpeedoMeterNeedle][i], 0.63, -2.60 );// 0.73, -2.60
			            TextDrawSetOutline(pTextInfo[playerid][SpeedoMeterNeedle][i], 0);
			            TextDrawSetShadow(pTextInfo[playerid][SpeedoMeterNeedle][i], 1);
			            TextDrawShowForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
			    	}
				}
			}*/
		}
	}
  	return 1;
}

stock GetDotXY(Float:StartPosX, Float:StartPosY, &Float:NewX, &Float:NewY, Float:alpha, Float:dist)
{
   	NewX = StartPosX + (dist * floatsin(alpha, degrees));
  	NewY = StartPosY + (dist * floatcos(alpha, degrees));
}

stock PlayerPlaySoundEx(playerid, soundid)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
 	PlayerPlaySound(playerid, soundid, x, y, z);
}

stock PlaySoundForAll(soundid, Float:x, Float:y, Float:z)
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
	    if(IsPlayerConnected(i))
	    {
		    PlayerPlaySound(i, soundid, x, y, z);
	    }
	}
}

stock PlaySoundForPlayersInRange(soundid, Float:range, Float:x, Float:y, Float:z)
{
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
	    if(IsPlayerConnected(i) && IsPlayerInRangeOfPoint(i, range, x, y, z))
	    {
		    PlayerPlaySound(i, soundid, x, y, z);
	    }
	}
}


/*forward Push(playerid);
public Push(playerid)
{
	Switched_Vehicle_Rec{playerid} = 0;
	return 1;
}*/

#define pb_percent2(%1,%2,%3,%4) ((%1 + 6.0) - ((((%1 - 6.0 + %2 - 2.0) - %1) / %3) * %4))
//pb_percent(x, width, max, value)
public UpdatePlayerHUD(playerid)
{
    new m, m_i, str[32], start = 0, end = MAX_MISSILEID;
    switch(pHUDStatus[playerid])
    {
        case HUD_MISSILES:
		{
		    start = 0;
			end = MAX_MISSILEID;
		}
        case HUD_ENERGY:
		{
			start = ENERGY_WEAPONS_INDEX;
			end = TOTAL_WEAPONS;
		}
    }
	for( m_i = start; m_i < end; m_i++ )
	{
	    m = m_i;
		if(PlayerInfo[playerid][pMissiles][m_i] > 0)
		{
		    switch(pHUDStatus[playerid])
		    {
		        case HUD_ENERGY:
				{
				    format(str, 32, "%s", GetTwistedMissileName(m, m));
					m -= ENERGY_WEAPONS_INDEX;
				}
		        default: format(str, 32, "%d %s", PlayerInfo[playerid][pMissiles][m], GetTwistedMissileName(m, m));
		    }
		    PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][m], (pMissileid[playerid] == m_i) ? 0x00FF00FF : 100);
	 		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pMissileSign][m], str);
            PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileSign][m]);
		}
		else PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][m]);
	}
	return 1;
}

stock ConvertNonNormaQuatToEuler(Float: qw, Float: qx, Float:qy, Float:qz, &Float:heading, &Float:attitude, &Float:bank) // Credits DANGER1979
{
    new Float: sqw = qw*qw;
    new Float: sqx = qx*qx;
    new Float: sqy = qy*qy;
    new Float: sqz = qz*qz;
    new Float: unit = sqx + sqy + sqz + sqw; // if normalised is one, otherwise is correction factor
    //åñëè normalised, - îäèí, â ïðîòèâíîì ñëó÷àå - ïîêàçàòåëü êîððåêöèè
    new Float: test = qx*qy + qz*qw;
    if (test > 0.499*unit)
    { // singularity at north pole - îñîáåííîñòü íà ñåâåðíîì ïîëþñå
        heading = 2*atan2(qx,qw);
        attitude = 3.141592653/2;
        bank = 0;
        return 1;
    }
    if (test < -0.499*unit)
    { // singularity at south pole - îñîáåííîñòü íà þæíîì ïîëþñå
        heading = -2*atan2(qx,qw);
        attitude = -3.141592653/2;
        bank = 0;
        return 1;
    }
    heading = -atan2(2*qy*qw - 2*qx*qz, sqx - sqy - sqz + sqw); // minus added to fit the gta-sa angle
    attitude = asin(2*test/unit);
    bank = -atan2(2*qx*qw - 2*qy*qz, -sqx + sqy - sqz + sqw); // moved minus here
    return 1;
}

stock GetVehicleRotation(vehicleid, &Float:heading, &Float:attitude, &Float:bank) // Credits DANGER1979
{
    new Float:quat_w, Float:quat_x, Float:quat_y, Float:quat_z;
    GetVehicleRotationQuat(vehicleid, quat_w, quat_x, quat_y, quat_z);
    ConvertNonNormaQuatToEuler(quat_w, quat_x, quat_z, quat_y, heading, attitude, bank);
    return 1;
}

stock QuaternionToYawPitchRoll(vehicleid, &Float:x, &Float:y, &Float:z) {
    new Float:quat_w, Float:quat_x, Float:quat_y, Float:quat_z;
    GetVehicleRotationQuat(vehicleid, quat_w, quat_x, quat_y, quat_z);
	x = atan2(2*((quat_x*quat_y)+(quat_w+quat_z)),(quat_w*quat_w)+(quat_x*quat_x)-(quat_y*quat_y)-(quat_z*quat_z));
	y = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)),(quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
	z = asin(-2*((quat_x*quat_z)+(quat_w*quat_y)));
	return 1;
}
stock QuaternionGetYaw(Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z,&Float:yaw) {
	yaw = asin(-2*((quat_x*quat_z)+(quat_w*quat_y)));
	return 1;
}
stock QuaternionGetPitch(Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z,&Float:pitch) {
	pitch = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)),(quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
	return 1;
}
stock QuaternionGetRoll(Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z,&Float:roll) {
	roll = atan2(2*((quat_x*quat_y)+(quat_w+quat_z)),(quat_w*quat_w)+(quat_x*quat_x)-(quat_y*quat_y)-(quat_z*quat_z));
	return 1;
}

forward FireALTSpecial(playerid, missileid);
public FireALTSpecial(playerid, missileid)
{
    new id = GetPlayerVehicleID(playerid), slot;
	switch(missileid)
	{
	    case Missile_Special:
	   	{
	   	    switch(GetVehicleModel(id))
	        {
	            case Reaper:
	            {
	                PlayerInfo[playerid][pSpecial_Using_Alt] = 2;
	                GivePlayerWeapon(playerid, REAPER_RPG_WEAPON, 1);
	                PutPlayerInVehicle(playerid, id, 1);
	                TimeTextForPlayer( TIMETEXT_TOP, playerid, "~k~~VEHICLE_HORN~ To Activate RPG (Shoot The Rifle To Fire An RPG Missile)", 3000);
	                return 1;
	            }
	            case Meat_Wagon:
	            {
	                if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	                {
	                    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
	                }
	                new Float:vx, Float:vy, Float:vz, Float:distance, Float:angle,
						Float:x, Float:y, Float:z;
	                GetVehicleZAngle(id, angle);
	                GetVehicleVelocity(id, vx, vy, vz);
	                GetVehiclePos(id, x, y, z);
	                distance = floatsqroot(vx*vx + vy*vy + vz*vz); // floatabs() * 0.5

				    if(distance < 0.35) //gurney too slow
					{
	                    vx = floatsin(-angle, degrees) * 0.4;
					    vy = floatcos(-angle, degrees) * 0.4;
					    vz = 0.1;
	                }
	                distance += 8.0;

					x += (distance * floatsin(-angle, degrees));
					y += (distance * floatcos(-angle, degrees));
	                z += 0.1;

	                PlayerInfo[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(457, x, y, z, angle, 0, 0, -1);
	                SetVehicleVelocity(PlayerInfo[playerid][pSpecial_Missile_Vehicle], vx, vy, vz);
	                LinkVehicleToInterior(PlayerInfo[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
	                SetVehicleHealth(PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2500.0);
	                pFiring_Missile[playerid] = 1;
	                PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(2146, x, y, (z + 0.5), 0, 0, angle, 300.0);
	                AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				   	PutPlayerInVehicle(playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0);
				   	Special_Missile_Timer[playerid] = SetTimerEx("GurneySpeedUpdate", 150, true, "ii", playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	            }
	            case Vermin: // Rat Rocket
	            {
	                if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	                {
	                    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
	                }
	                new Float:x, Float:y, Float:z, Float:angle;
	                GetVehiclePos(id, x, y, z);
	                GetVehicleZAngle(id, angle);
	                z += 3.0;
	                PlayerInfo[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(464, x, y, z, angle, 0, 0, -1);
	                LinkVehicleToInterior(PlayerInfo[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
	                SetVehicleHealth(PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2500.0);
	                pFiring_Missile[playerid] = 1;
	                PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(Missile_Default_Object, x, y, (z + 0.5), 0, 0, angle, 300.0);
	                AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 270.0);
				   	PutPlayerInVehicle(playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0);
					KillTimer(Special_Missile_Timer[playerid]);
					Special_Missile_Timer[playerid] = SetTimerEx("RocketSpeedUpdate", 150, true, "ii", playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	               	SetPVarInt(playerid, "Vermin_Special", 1);
			  	}
			}
			if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
			{
				Object_Owner[PlayerInfo[playerid][pSpecial_Missile_Object]] = id;
				Object_OwnerEx[PlayerInfo[playerid][pSpecial_Missile_Object]] = playerid;
				Object_Type[PlayerInfo[playerid][pSpecial_Missile_Object]] = Missile_Special;
				Object_Slot[PlayerInfo[playerid][pSpecial_Missile_Object]] = slot;
				EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
			}
	   	}
	}
	return 1;
}

new Float:axoff = 2.0, Float:ayoff = -0.01, Float:azoff = -1.0;

CMD:gfoffset(playerid, params[])
{
	sscanf(params, "fff", axoff, ayoff, azoff);
    SendClientMessageFormatted(playerid, -1, "axoff: %0.2f - ayoff: %0.2f - azoff: %0.2f", axoff, ayoff, azoff);
	return 1;
}

stock AttachGunFlashToMachineGun(playerid, vehicleid, Float:angle, modelid = 0)
{
	if(modelid == 0)
	{
		modelid = GetVehicleModel(vehicleid);
	}
	for(new go; go < 2; go++)
	{
		if(IsValidObject(Vehicle_Machine_Gun_Flash[vehicleid][go]))
		{
			DestroyObject(Vehicle_Machine_Gun_Flash[vehicleid][go]);
		}
	}
	Vehicle_Machine_Gun_Flash[vehicleid][0] = CreateObject(18695, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 300.0);
	AttachObjectToObject(Vehicle_Machine_Gun_Flash[vehicleid][0], Vehicle_Machine_Gun_Object[vehicleid][0], axoff, ayoff, azoff, 0.0, 0.0, angle, 0);
	switch(modelid)
	{
	    case Junkyard_Dog, Darkside, Shadow, Meat_Wagon, ManSalughter, Sweet_Tooth, Hammerhead, Warthog_TM3:
		{
            Vehicle_Machine_Gun_Flash[vehicleid][1] = CreateObject(18695, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 300.0);
			AttachObjectToObject(Vehicle_Machine_Gun_Flash[vehicleid][1], Vehicle_Machine_Gun_Object[vehicleid][1], axoff, ayoff, azoff, 0.0, 0.0, angle, 0);
		}
	}
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
 	PlayerPlaySound(playerid, 1135, x, y, z);
	return 1;
}

CMD:checkmissiles(playerid, params[])
{
	for(new slot = 0; slot < MAX_MISSILE_SLOTS; slot++)
	{
	    if(Vehicle_Missile[Current_Vehicle[playerid]][slot] != INVALID_OBJECT_ID)
	    {
	        SendClientMessageFormatted(playerid, -1, "Slot: %d - ID: %d", slot, Vehicle_Missile[Current_Vehicle[playerid]][slot]);
	    }
	}
	return 1;
}

#define MISSILE_D_DIVIDER 5.7
#define MISSILE_D_MULTIPLIER 0.3

forward FireMissile(playerid, id, missileid);
public FireMissile(playerid, id, missileid)
{
	if(PlayerInfo[playerid][pSpawned] == 0) return 1;
    new slot = -1;
	switch(missileid)
	{
	    case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
	   	{
	   	    if(IsValidObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]])) DestroyObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]);
	   	    if(IsValidObject(Vehicle_Machine_Mega_Gun[id][Vehicle_Machine_Gun_Currentid[id]])) DestroyObject(Vehicle_Machine_Mega_Gun[id][Vehicle_Machine_Gun_Currentid[id]]);

			new Float:x, Float:y, Float:z, Float:a, model = GetVehicleModel(id);
			GetVehiclePos(id, x, y, z);
			GetVehicleZAngle(id, a);
			AttachGunFlashToMachineGun(playerid, id, a, model);
     		switch(model)
			{
				case Reaper: // Reaper (Freeway)
				{
				    a += 90.0;
					x += (-0.3 * floatsin(-a, degrees));
					y += (-0.3 * floatcos(-a, degrees));
					z += 0.40;
					Vehicle_Machine_Gun_CurrentSlot[id] = 0;
					a -= 90.0;
				}
				case Brimstone: // Brimstone - Preacher
				{
      				a += 90.0;
              		x += (-1.2 * floatsin(-a, degrees));
                	y += (-1.2 * floatcos(-a, degrees));
                	z += 0.70;
                	Vehicle_Machine_Gun_CurrentSlot[id] = 0;
                	a -= 90.0;
				}
				case Outlaw: // Outlaw (Rancher)
				{
				    a += 90.0;
              		x += (-0.40 * floatsin(-a, degrees));
                	y += (-0.60 * floatcos(-a, degrees));
                	//z += VehicleOffsetZ[id];
                	Vehicle_Machine_Gun_CurrentSlot[id] = 0;
                	a -= 90.0;
				}
				case Roadkill, Thumper: // Roadkill (Bullet) / Crazy 8
				{
           			a += 270.0;
              		x += (0.6 * floatsin(-a, degrees));
					y += (0.6 * floatcos(-a, degrees));
                	z += 0.67;
                	a -= 270.0;
                	Vehicle_Machine_Gun_CurrentSlot[id] = 1;
				}
				case Spectre:
				{
     				a += 270.0;
					x += (0.9 * floatsin(-a, degrees));
					y += (1.1 * floatcos(-a, degrees));
     				z += 0.53;
     				Vehicle_Machine_Gun_CurrentSlot[id] = 1;
     				a -= 270.0;
				}
				case Meat_Wagon:
				{
				    a += 90.0;
					x += (VehicleOffsetX[id] * floatsin(-a, degrees));
					y += (VehicleOffsetX[id] * floatcos(-a, degrees));
     				z += VehicleOffsetZ[id];
     				a -= 90.0;
     				Vehicle_Machine_Gun_CurrentSlot[id] = 0;
				}
				case Vermin:
				{
				    a += 270.0;
					x += (VehicleOffsetX[id] * floatsin(-a, degrees));
					y += (VehicleOffsetX[id] * floatcos(-a, degrees));
     				z += VehicleOffsetZ[id];
     				Vehicle_Machine_Gun_CurrentSlot[id] = 1;
     				a -= 270.0;
				}
   				case Junkyard_Dog, Darkside, Shadow, ManSalughter, Sweet_Tooth, Warthog_TM3, Hammerhead:
			    {
			        a += (Vehicle_Machine_Gun_CurrentSlot[id] == 0) ? 90.0 : 270.0;
                    z += VehicleOffsetZ[id];
                    x += (VehicleOffsetX[id] * floatsin(-a, degrees));
                    y += (VehicleOffsetX[id] * floatcos(-a, degrees));
                    a -= (Vehicle_Machine_Gun_CurrentSlot[id] == 0) ? 90.0 : 270.0;
			    }
			    default:
				{
					a += 90.0;
					x += (VehicleOffsetX[id] * floatsin(-a, degrees));
					y += (VehicleOffsetX[id] * floatcos(-a, degrees));
     				z += VehicleOffsetZ[id];
     				a -= 90.0;
     				Vehicle_Machine_Gun_CurrentSlot[id] = 0;
				}
 			}
 			Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]] = CreateObject(/*1240*/Machine_Gun, x, y, z, 0, 0, a, 300.0);

			if(missileid == Missile_Machine_Gun_Upgrade)
  			{ //combing 2 red + green to make yellow light
                Vehicle_Machine_Mega_Gun[id][Vehicle_Machine_Gun_Currentid[id]] = CreateObject(19282, x, y, z, 0, 0, a, 300.0); // green 19283
				AttachObjectToObject(Vehicle_Machine_Mega_Gun[id][Vehicle_Machine_Gun_Currentid[id]], Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0);
                PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] --;
				new idx[4];
				valstr(idx, PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade], false);
				PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], idx);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
                if( PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] == 0 )
                {
                    KillTimer(Machine_Gun_Firing_Timer[playerid]);
                	new update_index = 285;
	  				Machine_Gun_Firing_Timer[playerid] = SetTimerEx("FireMissile", update_index, true, "iii", playerid, id, Missile_Machine_Gun);
	  				PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
	  				PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
                }
			}
			//x += (120.0 * floatsin(-a, degrees));
   			//y += (120.0 * floatcos(-a, degrees));

   			new Float:bank;
			CalculateElevation(playerid, id, x, y, z, bank);

      		MoveObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]], x, y, z, MISSILE_SPEED);

			Object_Owner[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = id;
  			Object_OwnerEx[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = playerid;
            Object_Type[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = missileid;
            Object_Slot[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = Vehicle_Machine_Gun_Currentid[id];
            EditPlayerSlot(playerid, Vehicle_Machine_Gun_Currentid[id], PLAYER_MISSILE_SLOT_ADD);
			Vehicle_Machine_Gun_Currentid[id] ++;
  			Vehicle_Machine_Gun_CurrentSlot[id] ++;

			if(Vehicle_Machine_Gun_Currentid[id] >= MAX_MACHINE_GUN_SLOTS) Vehicle_Machine_Gun_Currentid[id] = 0;
  			if(Vehicle_Machine_Gun_CurrentSlot[id] > 1) Vehicle_Machine_Gun_CurrentSlot[id] = 0;
  			CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, Vehicle_Machine_Gun_Currentid[id], missileid, Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]);
			return 1;
		}
		case Missile_Special:
		{
		    switch(GetVehicleModel(id))
		    {
		        case Warthog_TM3:
      	        {
					slot = GetFreeMissileSlot(id);
					PlayerInfo[playerid][pSpecial_Missile_Update]++;
					new Float:x, Float:y, Float:z, Float:a, light_slot = GetFreeMissileLightSlot(id), Float:distance;
					if(light_slot == -1) return 1;

					GetVehicleZAngle(id, a);
  					GetVehiclePos(id, x, y, z);
                  	CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

	              	new Float:x2, Float:y2, Float:z2, Float:bank;
					CalculateElevation(playerid, id, x2, y2, z2, bank);

                	Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, bank, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Missile_Lights[id][light_slot] = CreateObject(18651, x, y, z, 0, 0, (0.0), 300.0);//purple neonlight
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);

	              	AttachObjectToObject(Vehicle_Missile_Lights[id][light_slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, a, 0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);

	              	FindMissileTarget(playerid, id, slot);
                    Vehicle_Missile_Lights_Attached[id][light_slot] = slot;
					CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, Missile_Special, Vehicle_Missile[id][slot]);
				}
		        case Reaper:
		        {
		            slot = GetFreeMissileSlot(id);
		            pFiring_Missile[playerid] = 1;
				    new Float:x, Float:y, Float:z, Float:a, Float:distance;

					GetVehicleZAngle(id, a);
					GetVehiclePos(id, x, y, z);
		          	CalculateMissile(id, distance, a, x, y, z, 0.0, 0.0, 1.0, GetPlayerPing(playerid));

		           	new Float:x2, Float:y2, Float:z2, Float:bank;
					CalculateElevation(playerid, id, x2, y2, z2, bank);

		        	Vehicle_Missile[id][slot] = CreateObject(Reaper_Chainsaw, x, y, z, 0.0, bank, 90.0, 300.0);
                    MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);
					if(PlayerInfo[playerid][pSpecial_Missile_Update] == 1)
					{
					    Vehicle_Smoke[id][slot] = CreateObject(18690, x, y, z - 1.3, 0, 0, 0, 300.0);
						AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 270.0, 0);
					}
					ApplyAnimation(playerid, "GRENADE", "WEAPON_throw", 4.0, 0, 0, 0, 0, 0, 1);
					FindMissileTarget(playerid, id, slot);
		          	CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, Missile_Special, Vehicle_Missile[id][slot]);
		        }
		        case Roadkill:
		        {
		            PlayerInfo[playerid][pSpecial_Missile_Update]++;
					slot = GetFreeMissileSlot(id);
					new Float:x, Float:y, Float:z, Float:a, Float:distance;

					GetVehicleZAngle(id, a);
					GetVehiclePos(id, x, y, z);

		            new Float:offsetx = 0.70;
		            switch(PlayerInfo[playerid][pSpecial_Missile_Update])//offsetx -= (0.30 * PlayerInfo[playerid][pSpecial_Missile_Update]);
		            {
		                case 2: offsetx = 0.40;
		                case 3: offsetx = 0.10;
		                case 4: offsetx = -0.20;
		                case 5: offsetx = -0.50;
		                case 6: offsetx = -0.70;
		                default: offsetx = 0.70;
		            }
		          	CalculateMissile(id, distance, a, x, y, z, offsetx, VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

		           	new Float:x2, Float:y2, Float:z2, Float:bank;
					CalculateElevation(playerid, id, x2, y2, z2, bank);

		        	Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, bank, (a - 90.0),  300.0);
                    SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, (z - 1.3), 0, 0, 0, 300.0);
		          	AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

		            FindMissileTarget(playerid, id, slot);
					CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, Missile_Special, Vehicle_Missile[id][slot]);
		        }
		        case Sweet_Tooth:
		        {
					slot = GetFreeMissileSlot(id);
					PlayerInfo[playerid][pSpecial_Missile_Update]++;
					SetPVarInt(playerid, "Firing_Sweet_Tooth_Special", GetPVarInt(playerid, "Firing_Sweet_Tooth_Special") + 1);

					new Float:x, Float:y, Float:z, Float:a, Float:distance;
					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);

					GetVehicleZAngle(id, a);
					GetVehiclePos(id, x, y, z);
             		CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

		           	new Float:x2, Float:y2, Float:z2, Float:bank;
					CalculateElevation(playerid, id, x2, y2, z2, bank);

		        	Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, bank, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

		            FindMissileTarget(playerid, id, slot);
                    CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, Missile_Special, Vehicle_Missile[id][slot]);
				}
			}
		}
		case Energy_Shield: return GameTextForPlayer(playerid, "~r~~h~Defective", 2000, 3);
		case Energy_Mines: return cmd_mine(playerid, "");
		case Energy_Invisibility: return cmd_invisibility(playerid, "");
		case Energy_EMP, Missile_Fire, Missile_Homing, Missile_Power, Missile_Stalker,
			Missile_Stalker, Missile_RemoteBomb, Missile_Ricochet:
        {
            switch(missileid)
            {
                case Energy_EMP:
                {
		            if(GetPVarInt(playerid, "pShot_EMP_Recently") > gettime())
		            {
		                AddEXPMessage(playerid, "~p~EMP Is Overheated!");
		                return 1;
		            }
	            }
	            case Missile_Stalker:
				{
				    if(PlayerInfo[playerid][pMissiles][Missile_Stalker] == 0) return 1;
					PlayerInfo[playerid][pMissiles][Missile_Stalker] --;
					PlayerInfo[playerid][pMissile_Charged] = missileid;
					pFiring_Missile[playerid] = 1;
                   	PlayerInfo[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
                   	KillTimer(PlayerInfo[playerid][pCharge_Timer]);
                   	PlayerInfo[playerid][pCharge_Timer] = SetTimerEx("Charge_Missile", 195, true, "iii", playerid, id, missileid);
				}
            }
            if(PlayerInfo[playerid][pMissiles][missileid] == 0) return 1;
			PlayerInfo[playerid][pMissiles][missileid] --;
			slot = GetFreeMissileSlot(id);
			pFiring_Missile[playerid] = 1;

			new keys, ud, lr, Float:x, Float:y, Float:z, Float:a, Float:distance,
				Float:x2, Float:y2, Float:z2, Float:bank, light_slots[2];

            GetPlayerKeys(playerid, keys, ud, lr);
			GetVehicleZAngle(id, a);
			if(keys & 320)
            {
                a += 180.0;
            }
			GetVehiclePos(id, x, y, z);
          	CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));
			CalculateElevation(playerid, id, x2, y2, z2, bank);

        	switch(missileid)
            {
                case Missile_RemoteBomb:
                {
                    Vehicle_Missile[id][slot] = CreateObject(Missile_RemoteBomb_Object, x, y, z, 0.0, bank, (a - 90.0), 300.0);
                }
                case Missile_Ricochet:
                {
                    Vehicle_Missile[id][slot] = CreateObject(19284, x, y, z, 0.0, 90.0, a, 300.0);
                }
                default:
                {
                    Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, bank, (a - 90.0), 300.0);
                }
			}
			//printf("x: %0.2f - y: %0.2f - z: %0.2f - x2: %0.2f - y2: %0.2f", x, y, z, x2, y2);
			switch(missileid)
            {
                case Energy_EMP:
                {
                    FindMissileTarget(playerid, id, slot);
					Vehicle_Smoke[id][slot] = CreateObject(18728, x, y, z - 0.7, 0, 0, 0, 300.0);
		          	AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1);
		          	SetPVarInt(playerid, "pShot_EMP_Recently", gettime() + 7);
				}
				case Missile_Fire:
				{
				    FindMissileTarget(playerid, id, slot);
				    SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
		            for(new L = 0, LS = sizeof(light_slots); L < LS; L++)
					{//red + yellow = orange
					    light_slots[L] = GetFreeMissileLightSlot(id);
					    switch(L)
					    {
					    	case 0: Vehicle_Missile_Lights[id][light_slots[L]] = CreateObject(18647, x, y, z, 0, bank, (a - 90.0), 300.0);
					    	default: Vehicle_Missile_Lights[id][light_slots[L]] = CreateObject(18650, x, y, z, 0, bank, (a - 90.0), 300.0);
						}
						Vehicle_Missile_Lights_Attached[id][light_slots[L]] = slot;
						AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[L]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (a - 90.0) - a, 1);
					}
				}
				case Missile_Homing:
      	        {
      	            FindMissileTarget(playerid, id, slot);
      	            light_slots[0] = GetFreeMissileLightSlot(id);
                	SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
					Vehicle_Missile_Lights[id][light_slots[0]] = CreateObject(18651, x, y, z, 0, bank, (a - 90.0), 300.0); //purple neonlight
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[0]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (a - 90.0) - a, 1);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
	              	Vehicle_Missile_Lights_Attached[id][light_slots[0]] = slot;
	            }
      	      	case Missile_Power:
      	        {
      	            light_slots[0] = GetFreeMissileLightSlot(id);
                	SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
					Vehicle_Missile_Lights[id][light_slots[0]] = CreateObject(18647, x, y, z, 0, bank, (a - 90.0), 300.0); //red neonlight
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[0]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (a - 90.0) - a, 1);
				  	AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
					Vehicle_Missile_Lights_Attached[id][light_slots[0]] = slot;
                }
                case Missile_Ricochet:
      	        {
                	SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
					for(new L = 0, LS = 2; L < LS; L++)
					{
					    light_slots[L] = GetFreeMissileLightSlot(id); //wheel + dynamite object
					    switch(L)
					    {
					    	case 0: Vehicle_Missile_Lights[id][light_slots[L]] = CreateObject(1083, x, y, z, 0, 0, a, 300.0);
					    	default: Vehicle_Missile_Lights[id][light_slots[L]] = CreateObject(1654, x, y, z, 0, 0, a, 300.0);
						}
						Vehicle_Missile_Lights_Attached[id][light_slots[L]] = slot;
						AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[L]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.3, 0.0, 0.0, a, 0);
					}
                	SetPVarInt(playerid, "Ricochet_Missile_Timer", SetTimerEx("Explode_Missile", 6000, false, "iiii", playerid, id, slot, Missile_Ricochet));
	            }
                case Missile_RemoteBomb:
                {
                    SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
					Vehicle_Smoke[id][slot] = CreateObject(19283, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0);
					FindMissileTarget(playerid, id, slot);
                }
				case Missile_Stalker:
				{
				    FindMissileTarget(playerid, id, slot);
				    SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, ReturnMissileColor(missileid));
				    Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
					PlayerInfo[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
            		SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], DEFAULT_CHARGE_INDEX);
                    if(PlayerInfo[playerid][pMissiles][Missile_Stalker] >= 1)
					{
				        ShowPlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
					}
					else HidePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
				}
			}
			MoveObject(Vehicle_Missile[id][slot], x2, y2, z, MISSILE_SPEED);
			//printf("tick: %d - missile %s - time object should take: %d", end, GetTwistedMissileName(missileid), move);
            CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, missileid, Vehicle_Missile[id][slot]);
		}
	}
	if(Vehicle_Missile[id][slot] != INVALID_OBJECT_ID)
	{
		Object_Owner[Vehicle_Missile[id][slot]] = id;
	  	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
	  	Object_Type[Vehicle_Missile[id][slot]] = missileid;
	  	Object_Slot[Vehicle_Missile[id][slot]] = slot;
	  	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
  	}
	return 1;
}

stock Add_Vehicle_Offsets_And_Objects(vehicleid, Missileid)
{
   	new Float:x, Float:y, Float:z;
   	if(GetVehiclePos(vehicleid, x, y, z))
  	{
  	    switch(Missileid)
		{
		    case Missile_Machine_Gun:
			{
			    Vehicle_Machine_Gunid[vehicleid] = Missile_Machine_Gun;
			    new Float:ry = 0.0, model = GetVehicleModel(vehicleid);
	           	if(IsValidObject(Vehicle_Machine_Gun_Object[vehicleid][0]))
   				{
				   	DestroyObject(Vehicle_Machine_Gun_Object[vehicleid][0]);
				}
	           	if(IsValidObject(Vehicle_Machine_Gun_Object[vehicleid][1]))
	   			{
				   	DestroyObject(Vehicle_Machine_Gun_Object[vehicleid][1]);
				}
	           	Vehicle_Machine_Gun_Object[vehicleid][0] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
 				switch(model)
				{
				    case Junkyard_Dog: // Junkyard Dog / Tow Truck
					{
					    VehicleOffsetX[vehicleid] = 1.0;
					    VehicleOffsetY[vehicleid] = 2.5;
	           			VehicleOffsetZ[vehicleid] = 0.53;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
	           			AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.0, 2.5, 0.53, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.85, 2.5, 0.53, 0.0, 30.0, 95.0);
                        VehicleOffsetY[vehicleid] = 2.6;
			   			VehicleOffsetZ[vehicleid] = 1.0;
	           			return 1;
					}
					case Brimstone:
					{
					    VehicleOffsetX[vehicleid] = 1.2;
					    VehicleOffsetY[vehicleid] = -1.0;
	           			VehicleOffsetZ[vehicleid] = 0.53;
	           			ry = 30.0;
					}
					case Outlaw:
					{
					    VehicleOffsetX[vehicleid] = 0.40;
					    VehicleOffsetY[vehicleid] = 2.30;
	           			VehicleOffsetZ[vehicleid] = 0.0;
	           			ry = 30.0;
					}
					case Reaper://1085 tire
					{
					    VehicleOffsetX[vehicleid] = 0.07;
					    VehicleOffsetY[vehicleid] = 0.50;
	           			VehicleOffsetZ[vehicleid] = 0.80;
	           			ry = 30.0;
					}
					case Roadkill:
					{
					    VehicleOffsetX[vehicleid] = 0.70;
					    VehicleOffsetY[vehicleid] = 0.60;
	           			VehicleOffsetZ[vehicleid] = 0.60;
	           			ry = 30.0;
					}
					case Thumper:
					{
					    VehicleOffsetX[vehicleid] = 0.70;
					    VehicleOffsetY[vehicleid] = 0.60;
	           			VehicleOffsetZ[vehicleid] = 0.60;
	           			ry = 30.0;
					}
					case Spectre:
					{
					    VehicleOffsetX[vehicleid] = 1.04;
					    VehicleOffsetY[vehicleid] = -0.7;
	           			VehicleOffsetZ[vehicleid] = 0.6;
	           			ry = 30.0;
					}
					case Darkside:
					{
					    VehicleOffsetX[vehicleid] = 1.2;
					    VehicleOffsetY[vehicleid] = 3.3;
	           			VehicleOffsetZ[vehicleid] = 0.4;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.2, 3.3, 0.4, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 3.3, 0.4, 0.0, 30.0, 95.0);
						VehicleOffsetX[vehicleid] = 1.4;
						return 1;
					}
					case Shadow:
					{
					    VehicleOffsetX[vehicleid] = 1.1;
					    VehicleOffsetY[vehicleid] = 1.0;
	           			VehicleOffsetZ[vehicleid] = 0.5;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.1, 1.0, 0.5, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.97, 1.0, 0.5, 0.0, 30.0, 95.0);
                        VehicleOffsetX[vehicleid] = 1.2;
						VehicleOffsetY[vehicleid] = 1.60;
						return 1;
					}
					case Meat_Wagon:
					{
					    VehicleOffsetX[vehicleid] = -0.97;
					    VehicleOffsetY[vehicleid] = 1.0;
	           			VehicleOffsetZ[vehicleid] = 0.5;
	           			ry = 30.0;
					}
					case Vermin:
					{
					    VehicleOffsetX[vehicleid] = 1.1;
					    VehicleOffsetY[vehicleid] = 1.0;
	           			VehicleOffsetZ[vehicleid] = 0.5;
					    ry = 30.0;
					}
					case Warthog_TM3:
					{
					    VehicleOffsetX[vehicleid] = 0.8;
					    VehicleOffsetY[vehicleid] = 0.8;
	           			VehicleOffsetZ[vehicleid] = 0.8;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 0.9, 0.8, 0.8, 0.0, 30.0, 95.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.8, 0.8, 0.8, 0.0, 30.0, 95.0);
					    VehicleOffsetY[vehicleid] = 1.6;
					    return 1;
					}
					case ManSalughter:
					{
					    VehicleOffsetX[vehicleid] = 1.3;
					    VehicleOffsetY[vehicleid] = 3.0;
	           			VehicleOffsetZ[vehicleid] = 0.5;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.3, 3.0, 0.5, 0.0, 30.0, 95.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 3.0, 0.5, 0.0, 30.0, 95.0);
						return 1;
					}
					case Hammerhead:
					{
					    VehicleOffsetX[vehicleid] = 1.3;
					    VehicleOffsetY[vehicleid] = 2.8;
	           			VehicleOffsetZ[vehicleid] = 0.5;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.3, 2.8, 0.5, 0.0, 30.0, 95.0);
					    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 2.8, 0.5, 0.0, 30.0, 95.0);
					    VehicleOffsetX[vehicleid] = 1.4;
					    VehicleOffsetY[vehicleid] = 3.6;
					    return 1;
					}
					case Sweet_Tooth:
					{
					    VehicleOffsetX[vehicleid] = 1.2;
					    VehicleOffsetY[vehicleid] = 1.7;
	           			VehicleOffsetZ[vehicleid] = 0.5;
	           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.2, 1.7, 0.5, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.05, 1.7, 0.5, 0.0, 30.0, 95.0);
						VehicleOffsetX[vehicleid] = 1.3;
					    VehicleOffsetY[vehicleid] = 2.5;
	           			VehicleOffsetZ[vehicleid] = 0.55;
						return 1;
					}
					default: AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, -VehicleOffsetX[vehicleid], VehicleOffsetY[vehicleid], VehicleOffsetZ[vehicleid], 0.0, ry, 95.0);
				}
				AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, VehicleOffsetX[vehicleid], VehicleOffsetY[vehicleid], VehicleOffsetZ[vehicleid], 0.0, ry, 95.0);
				switch(model) // set REAL OFFSETS FOR SHOOTING
				{
					case Brimstone:
					{
					    VehicleOffsetX[vehicleid] = 1.25;
					    VehicleOffsetY[vehicleid] = 0.7;
	           			VehicleOffsetZ[vehicleid] = 0.53;
					}
					case Outlaw:
					{
					    VehicleOffsetX[vehicleid] = 0.40;
					    VehicleOffsetY[vehicleid] = 2.90;
	           			VehicleOffsetZ[vehicleid] = 0.70;
					}
					case Reaper: //1085 tyre
					{
					    VehicleOffsetY[vehicleid] = 0.60;
					}
					case Roadkill:
					{
					    VehicleOffsetX[vehicleid] = 0.80;
					    VehicleOffsetY[vehicleid] = 1.0;
	           			VehicleOffsetZ[vehicleid] = 0.65;
					}
					case Thumper:
					{
					    VehicleOffsetX[vehicleid] = 0.75;
					    VehicleOffsetY[vehicleid] = 1.40;
	           			VehicleOffsetZ[vehicleid] = 0.80;
					}
					case Spectre:
					{
					    VehicleOffsetX[vehicleid] = 1.05;
					    VehicleOffsetY[vehicleid] = 1.0;
	           			VehicleOffsetZ[vehicleid] = 0.70;
					}
					case Meat_Wagon:
					{
					    VehicleOffsetX[vehicleid] = -0.97;
					    VehicleOffsetY[vehicleid] = 1.60;
					}
					case Vermin:
					{
					    VehicleOffsetX[vehicleid] = 1.15;
					    VehicleOffsetY[vehicleid] = 1.80;
	           			VehicleOffsetZ[vehicleid] = 0.5;
					}
				}
			}
		    case Missile_Machine_Gun_Upgrade: Vehicle_Machine_Gunid[vehicleid] = Missile_Machine_Gun_Upgrade;
		    //3786
		    /*case Missile_Napalm:
		    {
				if(IsValidObject(Vehicle_Missile[vehicleid][0])) DestroyObject(Vehicle_Missile[vehicleid][0]);
		        Vehicle_Missile[vehicleid][0] = CreateObject(3046, x, y, z, 0, 0, 0, 300.0);
      			switch(GetVehicleModel(vehicleid))
				{
				    case 525: AttachObjectToVehicle(Vehicle_Missile[vehicleid][0], vehicleid, 0.00, -3.65, 0.53, 0.0, 0.0, 90.0);
				    case 576: AttachObjectToVehicle(Vehicle_Missile[vehicleid][0], vehicleid, -1.65, -1.7, 0.53, 0.0, 0.0, 90.0);
					case 599: AttachObjectToVehicle(Vehicle_Missile[vehicleid][0], vehicleid, 0.10, -2.90, 0.53, 0.0, 0.0, 90.0);
					case 463: AttachObjectToVehicle(Vehicle_Missile[vehicleid][0], vehicleid, -0.8, -0.80, 0.05, 0.0, 0.0, 90.0);
					case 541:// Roadkill
					{
					    new engine,lights,alarm,doors,bonnet,boot,objective;
						GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
						SetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,VEHICLE_PARAMS_ON,objective);
						AttachObjectToVehicle(Vehicle_Missile[vehicleid][0],vehicleid, 0.07, -1.70, 0.56, 0.0, 0.0, 90.0);
					}
					case 474: AttachObjectToVehicle(Vehicle_Missile[vehicleid][0], vehicleid, 0.07, -1.70, 0.56, 0.0, 0.0, 90.0);
					case 475: AttachObjectToVehicle(Vehicle_Missile[vehicleid][0], vehicleid, 0.07, -1.70, 0.56, 0.0, 0.0, 90.0);
				}
         		pMissileid[playerid] = Missileid;
		        return 1;
		    }*/
		}
  	}
	return 0;
}

stock HidePlayerHUD(playerid)
{
    TextDrawHideForPlayer(playerid, pHud_Box);
	TextDrawHideForPlayer(playerid, pHud_UpArrow);
	TextDrawHideForPlayer(playerid, pHud_LeftArrow);
	TextDrawHideForPlayer(playerid, pHud_RightArrow);
	TextDrawHideForPlayer(playerid, pHud_HealthSign);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pHealthBar]);
	TextDrawHideForPlayer(playerid, pHud_BoxSeparater);
	TextDrawHideForPlayer(playerid, pHud_SecondBox);
	TextDrawHideForPlayer(playerid, pHud_EnergySign);
	TextDrawHideForPlayer(playerid, pHud_TurboSign);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pLevelText]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pEXPText]);
	for(new m = 0; m < (MAX_MISSILEID); m++)
	{
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][m]);
	}
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	//for(new i; i < Speedometer_Needle_Index; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
	//for(new i; i != 15; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    iCurrentState[playerid] = newstate;
	switch(newstate)
	{
	    case PLAYER_STATE_DRIVER, PLAYER_STATE_PASSENGER:
	    {
	        PlayerInfo[playerid][pLastVeh] = GetPlayerVehicleID(playerid);
			TextDrawShowForPlayer(playerid, pHud_Box);
			TextDrawShowForPlayer(playerid, pHud_UpArrow);
			TextDrawShowForPlayer(playerid, pHud_LeftArrow);
			TextDrawShowForPlayer(playerid, pHud_RightArrow);
			TextDrawShowForPlayer(playerid, pHud_HealthSign);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthBar]);
			TextDrawShowForPlayer(playerid, pHud_BoxSeparater);
			TextDrawShowForPlayer(playerid, pHud_SecondBox);
			TextDrawShowForPlayer(playerid, pHud_EnergySign);
			TextDrawShowForPlayer(playerid, pHud_TurboSign);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pLevelText]);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pEXPText]);
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
			UpdatePlayerHUD(playerid);
			/*if(!DeActiveSpeedometer{playerid})
	        {
	          	for(new i; i != 15; i++) TextDrawShowForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
	          	for(new i; i < Speedometer_Needle_Index; i++) TextDrawShowForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
	        }
	        else
	        {
	        	for(new i; i < Speedometer_Needle_Index; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
	         	for(new i; i != 15; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
	        }*/
	        SetPVarInt(playerid, "Jumped_Index", 0);
			SetPVarInt(playerid, "Jumped_Recently", 0);
	    }
	    case PLAYER_STATE_ONFOOT, PLAYER_STATE_EXIT_VEHICLE:
	    {
            if(!PlayerInfo[playerid][CanExitVeh])
			{
				PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0); // PlayerInfo[playerid][pLastVeh]
			}
	    }
	    case PLAYER_STATE_WASTED:
	    {
            HidePlayerHUD(playerid);
	    }
	}
	if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
	{
	    HidePlayerHUD(playerid);
	}
	return 1;
}

CMD:exitveh(playerid, params[])
{
    PlayerInfo[playerid][CanExitVeh] = !PlayerInfo[playerid][CanExitVeh];
	return 1;
}

stock IsPlayerFacingVehicleEx(playerid, vehicleid, Float:offset = 5.0)
{
	if(playerid == INVALID_PLAYER_ID) return 0;
    new Float:pX, Float:pY, Float:pZ, Float:pA, Float:x, Float:y, Float:z, Float:ang;
	GetVehiclePos(vehicleid, X, Y, Z);
	GetPlayerPos(playerid, pX, pY, pZ);
	GetPlayerFacingAngle(playerid, pA);

	if( Y > pY ) ang = (-acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);
	else if( Y < pY && X < pX ) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 450.0);
	else if( Y < pY ) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);
	if(AngleInRangeOfAngle(-ang, pA, offset)) return true;
   	else return false;
}

stock AngleInRangeOfAngle(Float:a1, Float:a2, Float:range)
{
	a1 -= a2;
	if((a1 < range) && (a1 > -range)) return true;
	return false;
}

forward ReturnDarksidesSpeed(playerid, vehicleid, Float:VelocityX, Float:VelocityY, Float:VelocityZ);
public ReturnDarksidesSpeed(playerid, vehicleid, Float:VelocityX, Float:VelocityY, Float:VelocityZ)
{
	SetVehicleVelocity(vehicleid, VelocityX, VelocityY, VelocityZ);
	pFiring_Missile[playerid] = 0;
	PlayerInfo[playerid][pMissile_Charged] = -1;
	return 1;
}

stock GetClosestVehicleEx(playerid, Float:dis = 6000.0, &Float:distaway)
{
    new vehicle = INVALID_VEHICLE_ID;
    foreach(Vehicles, v)
    {
	    new Float:dis2 = GetPlayerDistanceToVehicle(playerid, v);
	    if(dis2 < dis && !IsPlayerInVehicle(playerid, v))
	    {
		    dis = dis2;
		    vehicle = v;
	    }
    }
    distaway = dis;
    return vehicle;
}

stock GetClosestVehicle(playerid, Float:dis = 6000.0)
{
    new vehicle = INVALID_VEHICLE_ID;
    foreach(Vehicles, v)
    {
	    new Float:dis2 = GetPlayerDistanceToVehicle(playerid, v);
	    if(dis2 < dis && !IsPlayerInVehicle(playerid, v))
	    {
		    dis = dis2;
		    vehicle = v;
	    }
    }
    return vehicle;
}

forward Outlaw_Special(playerid, vehicleid);
public Outlaw_Special(playerid, vehicleid)//18712 - gunshell attach to minigun head
{
	if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	{
	    PlayerInfo[playerid][pMissile_Special_Time] += 100;
	    if(PlayerInfo[playerid][pMissile_Special_Time] > 5000)
		{
		    pFiring_Missile[playerid] = 0;
		    KillTimer(Special_Missile_Timer[playerid]);
		    PlayerInfo[playerid][pMissile_Special_Time] = 0;
		    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
			PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
		}
		else
		{
		    if(PlayerInfo[playerid][pMissile_Special_Time] >= 2500)
		    {
		    	if(pFiring_Missile[playerid] == 1)
		    	{
                    pFiring_Missile[playerid] = 0;
		    	}
		    }
		    new Float:x, Float:y, Float:z, Float:DestX, Float:DestY, Float:Angle, Float:damage,
				closestvehicle = GetClosestVehicle(playerid, 25.0), Float:fAZ;
          	if(closestvehicle == INVALID_VEHICLE_ID || !(1 <= closestvehicle <= 2000))
  			{
			  	Angle = 95.0;
			}
			else
			{
			    GetVehiclePos(vehicleid, x, y, z);
          		GetVehiclePos(closestvehicle, DestX, DestY, z);
          		GetVehicleZAngle(vehicleid, fAZ);
			    //Angle = (95.0 + 360.0) - atan2( x - x2, y - y2 );
			    //Angle = 95.0 - atan2(x - x2, y - y2);
			    //Angle = atan2(y - y2, x - x2) - 90.0 + 95.0;
			    //Angle = atan2(y - y2, x - x2) - 90.0;
			    //Angle = atan2(DestY - y, DestX - x) + 270.0;
			    //Angle = PointAngle(vehicleid, x, y, DestX, DestY) - 180.0;
			    Angle = atan2(y - DestY, x - DestX) - fAZ - 180.0;
				MPClamp360(Angle);
			    damage = GetMissileDamage(Missile_Special, vehicleid);
				DamagePlayer(playerid, vehicleid, MPGetVehicleDriver(closestvehicle), closestvehicle, damage, Missile_Special);
				GetVehicleModelInfo(GetVehicleModel(closestvehicle), VEHICLE_MODEL_INFO_SIZE, z, z, z);
 				z -= 0.7;
				StartHitBarProcess(playerid, floatround(damage), 0.0, 0.0, z, closestvehicle);
		 	}
          	//SendClientMessageFormatted(playerid, -1, "[System] - playerid: %d - closestvehicleid: %d - Angle: %f - Angle2D - 95.0: %f", playerid, closestvehicle, Angle, (Angle - 95.0));
           	AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], vehicleid, 0.1, -0.5, 1.5, 0.0, 30.0, Angle);
		}
	}
	else
	{
     	pFiring_Missile[playerid] = 0;
	    KillTimer(Special_Missile_Timer[playerid]);
	    PlayerInfo[playerid][pMissile_Special_Time] = 0;
	}
	return 1;
}

stock StartHitBarProcess(playerid, amount, Float:x, Float:y, Float:z, attachedvehicleid = INVALID_VEHICLE_ID)
{
    new string[3], PlayerText3D:hitbar;
 	format(string, sizeof string, "%d", amount);
 	hitbar = CreatePlayer3DTextLabel(playerid, string, RED, x, y, z + 0.6, 50.0, INVALID_PLAYER_ID, attachedvehicleid, 0);
	SetTimerEx("UpdateHitBar", 66, false, "iiiifffii", playerid, attachedvehicleid, _:hitbar, amount, x, y, z + 0.8, 16, RED);
	return 1;
}

forward UpdateHitBar(playerid, attachedvehicle, PlayerText3D:hitbar, hp, Float:x, Float:y, Float:z, update_no, color);
public UpdateHitBar(playerid, attachedvehicle, PlayerText3D:hitbar, hp, Float:x, Float:y, Float:z, update_no, color)
{
    DeletePlayer3DTextLabel(playerid, hitbar);
    update_no--;
    if(!update_no) return;
    new string[3];
    z += 0.05;
    color -= 12;
    format(string, sizeof string, "%d", hp);
    hitbar = CreatePlayer3DTextLabel(playerid, string, color, x, y, z, 50.0, INVALID_PLAYER_ID, attachedvehicle, 0);
    SetTimerEx("UpdateHitBar", 66, false, "iiiifffii", playerid, attachedvehicle, _:hitbar, hp, x, y, z, update_no, color);
}

forward Thumper_Special(playerid, vehicleid);
public Thumper_Special(playerid, vehicleid)
{
	if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	{
	    PlayerInfo[playerid][pMissile_Special_Time] += 100;
	    if(PlayerInfo[playerid][pMissile_Special_Time] > 5000)
		{
		    pFiring_Missile[playerid] = 0;
		    KillTimer(Special_Missile_Timer[playerid]);
		    PlayerInfo[playerid][pMissile_Special_Time] = 0;
		    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
			PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
		}
		else
		{
		    if(PlayerInfo[playerid][pMissile_Special_Time] >= 2500)
		    {
		    	if(pFiring_Missile[playerid] == 1)
		    	{
                    pFiring_Missile[playerid] = 0;
		    	}
		    }
		    new cv = GetClosestVehicle(playerid, 8.0);
	      	if(cv == INVALID_VEHICLE_ID) return 1;
	      	new Float:x, Float:y, Float:z, Float:damage;
	      	GetVehiclePos(vehicleid, x, y, z);
	      	GetXYInFrontOfVehicle(vehicleid, x, y, 4.0);
	      	if(GetVehicleDistanceFromPoint(cv, x, y, z) < 4.0)
	      	{
	      	    damage = GetMissileDamage(Missile_Special, vehicleid);
		      	DamagePlayer(playerid, vehicleid, MPGetVehicleDriver(cv), cv, damage, Missile_Special);
			 	GetVehicleModelInfo(GetVehicleModel(cv), VEHICLE_MODEL_INFO_SIZE, z, z, z);
			 	z -= 0.7;
        		StartHitBarProcess(playerid, floatround(damage), 0.0, 0.0, z, cv);
	      	}
		}
	}
	else
	{
	    pFiring_Missile[playerid] = 0;
	    KillTimer(Special_Missile_Timer[playerid]);
	    PlayerInfo[playerid][pMissile_Special_Time] = 0;
	}
	return 1;
}

forward FlashRoadkillForPlayer(playerid, times);
public FlashRoadkillForPlayer(playerid, times)
{
	if(times == 0)
	{
 		Roadkill_Special(playerid, 2);
	    return 1;
	}
	GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |~n~~p~Click ~k~~VEHICLE_FIREWEAPON_ALT~ To Fire!", 300, 3);
	SetTimerEx("FlashRoadkillForPlayer", 500, false, "ii", playerid, (times - 1));
	return 1;
}

forward Roadkill_Special(playerid, countdown);
public Roadkill_Special(playerid, countdown)
{
	if(countdown == 1)
	{
	    PlayerInfo[playerid][pMissile_Special_Time]++;
	    switch(PlayerInfo[playerid][pMissile_Special_Time])
	    {
	        case 1: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~|", 915, 3);
	        case 2: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| |", 915, 3);
	        case 3: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | |", 915, 3);
	        case 4: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | |", 915, 3);
	        case 5: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | | |", 915, 3);
	        case 6: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |", 915, 3);
	        default: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |", 915, 3);
	    }
	    PlayerPlaySound(playerid, 1056, 0.0, 0.0, 0.0);
	    if(PlayerInfo[playerid][pMissile_Special_Time] >= 7)
	    {
	        SetPVarInt(playerid, "Flash_Roadkill_Timer", SetTimerEx("FlashRoadkillForPlayer", 500, false, "ii", playerid, 5));
        	KillTimer(Special_Missile_Timer[playerid]);
	        PlayerInfo[playerid][pMissile_Special_Time] = 0;
	        PlayerInfo[playerid][pMissile_Charged] = Missile_Special;
		}
	}
	else if(countdown == 2)
	{
	    pFiring_Missile[playerid] = 0;
    	KillTimer(Special_Missile_Timer[playerid]);
	    PlayerInfo[playerid][pMissile_Special_Time] = 0;
	    PlayerInfo[playerid][pMissile_Charged] = -1;
	    new tid = GetPVarInt(playerid, "Flash_Roadkill_Timer");
		KillTimer(tid);
		DeletePVar(playerid, "Flash_Roadkill_Timer");
	    GameTextForPlayer(playerid, " ", 1, 3);
	    GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |~n~~r~~h~Special Over", 300, 3);
	}
	return 1;
}

stock GetPlayerMissileCount(playerid)
{
    new i, count;
    for(i = MIN_MISSILEID; i < MAX_MISSILEID; i++) //find total number of missiles
	{
	    if(PlayerInfo[playerid][pMissiles][i] != 0) count++;
	}
	return count;
}
stock GetNextHUDSlot(playerid)
{
	new i, m, imax, imin;
	switch(pHUDStatus[playerid])
	{
	    case HUD_MISSILES:
	    {
	        imin = MIN_MISSILEID;
			imax = MAX_MISSILEID;
		}
		case HUD_ENERGY:
		{
			imin = ENERGY_WEAPONS_INDEX;
			imax = TOTAL_WEAPONS;
		}
	}
	for(i = (imax - 1); i != imin; i--) //find the highest slot used
	{
	    if(PlayerInfo[playerid][pMissiles][i] != 0) break;
	    continue;
	}
	for(m = (pMissileid[playerid] + 1); m != (imax + 1); m++)
	{
	    if(m > i || m >= imax)
	    {
	        for(m = imin; m != pMissileid[playerid]; m++)
			{
			    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
			    pMissileid[playerid] = m;
			    break;
			}
			break;
	    }
	    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
	    pMissileid[playerid] = m;
	    break;
	}
	return pMissileid[playerid];
}

stock GetPreviousHUDSlot(playerid)
{
	new i, m, imax, imin;
	switch(pHUDStatus[playerid])
	{
	    case HUD_MISSILES:
	    {
	        imin = MIN_MISSILEID;
			imax = MAX_MISSILEID;
		}
		case HUD_ENERGY:
		{
			imin = ENERGY_WEAPONS_INDEX;
			imax = TOTAL_WEAPONS;
		}
	}
	for(i = imin; i < imax; i++) //find the lowest slot used
	{
	    if(PlayerInfo[playerid][pMissiles][i] != 0) break;
	    continue;
	}
	for(m = pMissileid[playerid] - 1; m != (imin - 2); m--)
	{
	    if(m < imin)
	    {
	        for(m = (imax - 1); m != imin; m--)
			{
			    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
			    pMissileid[playerid] = m;
			    break;
			}
			break;
	    }
	    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
	    pMissileid[playerid] = m;
	    break;
	}
	return pMissileid[playerid];
}

stock RemovePlayerFromVehicleEx ( playerid )
{
    if ( !IsPlayerInAnyVehicle(playerid) ) return 0;
    new vid = GetPlayerVehicleID(playerid);
    if ( vid == INVALID_VEHICLE_ID ) return 0;
    new Float: pos[4], Float: sideAngle;
    GetVehiclePos ( vid, pos[0], pos[1], pos[2] );
    GetVehicleZAngle( vid, pos[3] );
    switch ( GetPlayerVehicleSeat(playerid) )
    {
        case 0,2 : sideAngle = pos[3] - 180.0;
        default  : sideAngle = pos[3];
    }
    SetPlayerPos( playerid, pos[0] + 2.0 * floatcos( sideAngle, degrees ),
	pos[1] + 2.0 * floatsin( sideAngle, degrees ),pos[2] + 0.3 );
    SetPlayerFacingAngle( playerid, pos[3] );
    SetCameraBehindPlayer(playerid);
    return 1;
}

stock InterpolateCameraPosNoHUD(playerid, Float:FromX, Float:FromY, Float:FromZ, Float:ToX, Float:ToY, Float:ToZ, time, cut = CAMERA_CUT)
{
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);
	return InterpolateCameraPos(playerid, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut);
}

stock SetCameraBehindPlayerNoHUD(playerid)
{
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);
	return SetCameraBehindPlayer(playerid);
}

CMD:resetmapcam(playerid, params[])
{
    pFirstTimeViewingMap[playerid] = 1;
	return 1;
}

GetMapInterpolationIndex(gameid, start)
{
    new index = 0;
    if((0 <= gGameData[gameid][g_Map_id] <= (MAX_MAPS - 1)))
    {
		switch(start)
		{
		    case 0: // end
		    {
	        	index = s_Maps[gGameData[gameid][g_Map_id]][m_Interpolation_Index];
		    }
		    //case 1: {} // start
		}
	}
	return index;
}

enum e_Map_Viewing
{
	mv_Map,
	Float:mv_cPosX,
	Float:mv_cPosY,
	Float:mv_cPosZ,
	Float:mv_cLPosX,
	Float:mv_cLPosY,
	Float:mv_cLPosZ,
	mv_MoveTime
}
new mv_Interpolation[5][e_Map_Viewing] =
{
	{MAP_DOWNTOWN, -2018.4077, -860.7560, 96.3775, -2018.3990, -861.7546, 96.0425, 3000},
	{MAP_DOWNTOWN, -1876.4188, -967.0780, 104.4019, -1877.3862, -967.3249, 103.8269, 3000},
	{MAP_DOWNTOWN, -1876.5049, -714.2787, 96.9035, -1877.4073, -714.7056, 96.4084, 4000},
	{MAP_DOWNTOWN, -2174.1772, -673.5807, 106.1909, -2173.6741, -674.4426, 105.7958, 3000},
	{MAP_DOWNTOWN, -2027.1857, -799.0085, 419.7032, -2027.1840, -800.0073, 413.3235, 0}
};

forward ContinueInterpolation(playerid, index, end);
public ContinueInterpolation(playerid, index, end)
{
	if(index == end)
	{
	    pFirstTimeViewingMap[playerid] = 0;
	    if(GetPlayerVirtualWorld(playerid) != (playerid + 1))
		{
	    	SetTimerEx("TwistedSpawnPlayer", mv_Interpolation[index - 1][mv_MoveTime] - 700, false, "i", playerid);
		}
		GameTextForPlayerFormatted(playerid, "~w~Welcome To ~b~~h~%s", mv_Interpolation[index - 1][mv_MoveTime] + 200, 4, s_Maps[mv_Interpolation[index - 1][mv_Map]][m_Name]);
	    return 1;
	}
	else
	{
	    if(GetPlayerVirtualWorld(playerid) != (playerid + 1))
		{
			SetTimerEx("ContinueInterpolation", mv_Interpolation[index][mv_MoveTime] - 100, false, "iii", playerid, (index + 1), end);
		}
		else SetCameraBehindPlayer(playerid);
	}
	InterpolateCameraPos(playerid, mv_Interpolation[index][mv_cPosX],
	mv_Interpolation[index][mv_cPosY], mv_Interpolation[index][mv_cPosZ],
	mv_Interpolation[index + 1][mv_cPosX], mv_Interpolation[index + 1][mv_cPosY],
	mv_Interpolation[index + 1][mv_cPosZ], mv_Interpolation[index][mv_MoveTime], CAMERA_MOVE);
	InterpolateCameraLookAt(playerid, mv_Interpolation[index][mv_cLPosX],
	mv_Interpolation[index][mv_cLPosY], mv_Interpolation[index][mv_cLPosZ],
	mv_Interpolation[index + 1][mv_cLPosX], mv_Interpolation[index + 1][mv_cLPosY],
	mv_Interpolation[index + 1][mv_cLPosZ], mv_Interpolation[index][mv_MoveTime], CAMERA_MOVE);
	return 1;
}

forward TwistedSpawnPlayer(playerid);
public TwistedSpawnPlayer(playerid)
{
    if(1 <= Current_Vehicle[playerid] <= 2000)
  	{
	  	DestroyVehicle(Current_Vehicle[playerid]);
	  	Current_Vehicle[playerid] = 0;
	}
	SetPlayerVirtualWorld(playerid, 0);
	if(pFirstTimeViewingMap[playerid] == 1)
	{
	    SendClientMessage(playerid, -1, "Type {2DFA45}/controls "#cWhite"To See The Server Controls - Type {2DFA45}/tutorial "#cWhite"for a tutorial");
	    new start = GetMapInterpolationIndex(PlayerInfo[playerid][gGameID], true), end = GetMapInterpolationIndex(PlayerInfo[playerid][gGameID], false);
	    for(new mv_Index = start; mv_Index <= end; mv_Index++)
	    {
	        if(mv_Interpolation[mv_Index][mv_Map] != gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]) continue;
	        SetPlayerPos(playerid, 56.6482, -53.1604, 0.3160);
	        SetPlayerFacingAngle(playerid, 206.6024);
	        pFirstTimeViewingMap[playerid] = 0;
	        GameTextForPlayer(playerid, " ", 5, 3);
	        SetPlayerCameraPos(playerid, mv_Interpolation[mv_Index][mv_cPosX],
			mv_Interpolation[mv_Index][mv_cPosY], mv_Interpolation[mv_Index][mv_cPosZ]);
			SetPlayerCameraLookAt(playerid, mv_Interpolation[mv_Index][mv_cLPosX],
			mv_Interpolation[mv_Index][mv_cLPosY], mv_Interpolation[mv_Index][mv_cLPosZ]);
			SetTimerEx("ContinueInterpolation", 100, false, "iii", playerid, mv_Index, end);
			return 1;
	    }
		pFirstTimeViewingMap[playerid] = 0;
	}
    GameTextForPlayer(playerid, " ", 5, 3);
    StopAudioStreamForPlayer(playerid);
	switch(random(5))
	{
	    case 0: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/tm2-title-screen.mp3");
	    case 1: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/tm2-new-york.mp3");
	    case 2: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal OST - Deathwish.mp3");
        case 3: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal OST - Roadkill.mp3");
        case 4: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal OST - Shotgunner.mp3");
	}
    new Float:x, Float:y, Float:z, Float:angle;
    GetMapComponents(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
	//printf("pGameID: %d - pMapid: %d - pGamemode: %d", PlayerInfo[playerid][gGameID], gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode]);
	SetPlayerPos(playerid, x, y, z);
	SetPlayerInterior(playerid, 0);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);

	PlayerTextDrawShow(playerid, pTextInfo[playerid][AimingBox]);
	TextDrawShowForPlayer(playerid, Players_Online_Textdraw);
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
	    case DEATHMATCH:
	    {
	        PlayerTextDrawShow(playerid, Race_Box_Outline[playerid]);
			PlayerTextDrawShow(playerid, Race_Box[playerid]);
	    }
	    case RACE:
	    {
	        if((s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Max_Grids] + 1) <= CP_Progress[playerid] < Total_Race_Checkpoints)
	        {
	            CP_Progress[playerid]--;
		        SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
	            PlayerTextDrawShow(playerid, Race_Box_Outline[playerid]);
				PlayerTextDrawShow(playerid, Race_Box[playerid]);
				x = Race_Checkpoints[CP_Progress[playerid]][0];
		 		y = Race_Checkpoints[CP_Progress[playerid]][1];
		 		z = Race_Checkpoints[CP_Progress[playerid]][2] + 3.0;

		 		angle = Angle2D(Race_Checkpoints[CP_Progress[playerid]][0],
									Race_Checkpoints[CP_Progress[playerid]][1],
			 					Race_Checkpoints[CP_Progress[playerid] + 1][0],
							 	Race_Checkpoints[CP_Progress[playerid] + 1][1] );
	    		MPClamp360(angle);
			}
			else if(CP_Progress[playerid] < Total_Race_Checkpoints)
			{
		        SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
	            PlayerTextDrawShow(playerid, Race_Box_Outline[playerid]);
				PlayerTextDrawShow(playerid, Race_Box[playerid]);
			}
		}
	}
	PlayerInfo[playerid][pSpawned] = 1;
	Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], x, y, z + 0.7, angle, C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
    SetVehicleNumberPlate(Current_Vehicle[playerid], GetTwistedMetalName(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID]));
	PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
	SetTimerEx("Complete_Twisted_Spawn", 125, false, "iffff", playerid, x, y, z, angle);
	return 1;
}

new Float:Downtown_Spawns[11][4] =
{
	{-1987.6123,-1006.0413,32.4640,359.4698},
	{-2159.5183,-988.0478,32.4197,0.1144},
	{-2141.6816,-1005.2360,32.4375,270.4423},
	{-2144.4934,-714.6802,32.4239,270.2378},
	{-2159.4753,-729.0433,32.4129,180.0636},
	{-1987.4827,-715.3997,32.4641,180.8086},
	{-1922.7969,-731.0041,32.4200,180.9581},
	{-1937.9205,-714.5966,32.4282,90.2995},
	{-1988.4668,-858.7548,32.4602,271.0332},
	{-1935.1844,-1005.2726,32.4287,90.1289},
	{-1922.7192,-989.6423,32.4165,0.6842}
};


new Float:Skyscraper_Spawns[9][4] =
{
	{-2294.051, 476.350, 73.351, 226.0},
	{-2189.6624, 397.0610, 60.1914, 43.3923},
	{-2066.5410,483.5458,139.3674,177.2467},
	{-2030.0596,444.3904,139.3674,86.9886},
	{-2294.2964,423.0440,73.3671,347.6301},
	{-2357.9277,390.9946,72.8832,2.9862},
	{-2444.3015,445.5710,72.8828,294.4821},
	{-2162.0969,336.5743,57.7409,41.5695},
	{-2237.8096,335.9155,54.5704,319.8129}
};

new Float:Hanger18_Spawns[34][4] =
{
	{-1656.4219,-541.5161,10.9823,312.7561},
	{-1729.6597,-579.9389,15.9611,269.3188},
	{-1680.9089,-513.2444,13.7733,305.9908},
	{-1613.5013,-556.0402,13.7688,80.2743},
	{-1643.1727,-431.8990,13.7730,326.5934},
	{-1609.6106,-397.1441,13.6175,341.6703},
	{-1572.3168,-454.9272,13.6244,222.5986},
	{-1514.7030,-494.4241,13.6135,106.8789},
	{-1396.8541,-340.4178,13.6245,25.3159},
	{-1560.7693,-445.7268,5.6267,314.7088},
	{-1507.1617,-391.7778,6.7032,133.0445},
	{-1586.2411,-370.0423,11.6248,171.9191},
	{-1504.1965,-290.0568,11.6248,274.1419},
	{-1404.9904,-389.3194,11.6250,351.0293},
	{-1486.5664,-471.1100,11.6249,98.0407},
	{-1512.9012,-275.4865,5.6250,13.3662},
	{-1385.7329,-398.7112,5.6249,257.9461},
	{-1612.1335,-491.8345,21.7127,46.5732},
	{-1693.1304,-388.7632,13.7730,358.4928},
	{-1622.0405,-316.1133,13.7731,313.8858},
	{-1466.1172,-182.9698,13.7735,347.0826},
	{-1538.1409,-45.3629,13.7730,314.3130},
	{-1280.1423,212.1583,13.7692,314.1291},
	{-1115.1012,377.5732,13.7716,134.2760},
	{-1267.2278,115.2770,13.7734,135.6364},
	{-1185.5377,26.3374,13.7735,135.2504},
	{-1306.0122,-190.4102,13.7735,135.5382},
	{-1358.0900,-242.5534,13.7695,315.6682},
	{-1274.9916,-307.2718,13.7738,289.8127},
	{-1153.1241,-136.5296,13.7688,134.5390},
	{-1144.4663,-410.1067,13.7735,177.5875},
	{-1263.8223,-567.0160,13.7698,94.3018},
	{-1480.8177,-559.8555,13.7730,179.4896},
	{-1623.4120,-654.5112,13.7723,292.8566}
};

new Float:Suburbs_Spawns[10][4] =
{
	{-2285.3977,2676.2571,55.4253,93.6407},
	{-2286.7290,2639.3779,55.0550,92.9251},
	{-2676.9854,2197.8809,55.0501,7.8180},
	{-2696.3701,2202.3540,54.9167,20.1082},
	{-2752.7505,2351.6926,72.9861,279.0209},
	{-2723.6121,2357.2429,71.4108,101.0704},
	{-2606.7898,2331.1489,7.7406,270.5275},
	{-2551.1499,2402.0447,14.3448,225.5588},
	{-2511.8142,2432.4368,16.3830,43.8924},
	{-2498.4285,2410.6379,16.1203,208.3412}
};
#define IsOdd(%1) ((%1) & 1)

stock GetMapComponents(mapid, &Float:x, &Float:y, &Float:z, &Float:angle, playerid = INVALID_PLAYER_ID)
{
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
    {
		case RACE: // MAP_DIABLO_PASS
		{
		    if(playerid == INVALID_PLAYER_ID)
		    {
		        r_Index = random(s_Maps[mapid][m_Max_Grids]);
		    }
		    else
		    {
		    	if(IsOdd(playerid)) r_Index = random(s_Maps[mapid][m_Max_Grids] - 1);
				else r_Index = random(s_Maps[mapid][m_Max_Grids]);
			}
		    if(PlayersCount[r_Index] == 1)
		    {
				RaceVehCoords[r_Index][0] -= (6 * floatsin(-RaceVehCoords[r_Index][3], degrees));
		 		RaceVehCoords[r_Index][1] -= (6 * floatcos(-RaceVehCoords[r_Index][3], degrees));
		 		x = RaceVehCoords[r_Index][0];
		 		y = RaceVehCoords[r_Index][1];
		 		z = RaceVehCoords[r_Index][2];
		 		angle = RaceVehCoords[r_Index][3];
			}
			else
			{
			    x = RaceVehCoords[r_Index][0];
		 		y = RaceVehCoords[r_Index][1];
		 		z = RaceVehCoords[r_Index][2];
		 		angle = RaceVehCoords[r_Index][3];
			    PlayersCount[r_Index] = 1;
			}
		}
		default:
		{
		    switch(mapid)
		    {
		        case MAP_SKYSCRAPERS:
		        {
		            new RandomArray = random(sizeof(Skyscraper_Spawns));
		            x = Skyscraper_Spawns[RandomArray][0];
					y = Skyscraper_Spawns[RandomArray][1];
					z = Skyscraper_Spawns[RandomArray][2];
					angle = Skyscraper_Spawns[RandomArray][3];
		        }
		        case MAP_DOWNTOWN:
		        {
				    new RandomArray = random(sizeof(Downtown_Spawns));
					x = Downtown_Spawns[RandomArray][0];
					y = Downtown_Spawns[RandomArray][1];
					z = Downtown_Spawns[RandomArray][2];
					angle = Downtown_Spawns[RandomArray][3];
				}
				case MAP_HANGER18:
		        {
				    new RandomArray = random(sizeof(Hanger18_Spawns));
					x = Hanger18_Spawns[RandomArray][0];
					y = Hanger18_Spawns[RandomArray][1];
					z = Hanger18_Spawns[RandomArray][2];
					angle = Hanger18_Spawns[RandomArray][3];
				}
				case MAP_SUBURBS:
		        {
				    new RandomArray = random(sizeof(Suburbs_Spawns));
					x = Suburbs_Spawns[RandomArray][0];
					y = Suburbs_Spawns[RandomArray][1];
					z = Suburbs_Spawns[RandomArray][2];
					angle = Suburbs_Spawns[RandomArray][3];
				}
			}
		}
	}
	return 1;
}

forward Complete_Twisted_Spawn(playerid, Float:x, Float:y, Float:z, Float:angle);
public Complete_Twisted_Spawn(playerid, Float:x, Float:y, Float:z, Float:angle)
{
	AttachSpecialObjects(playerid, C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID]);
	Add_Vehicle_Offsets_And_Objects(Current_Vehicle[playerid], Missile_Machine_Gun);
    pHUDStatus[playerid] = HUD_MISSILES;
	pMissileid[playerid] = Missile_Special;
	LastSpecialUpdateTick[playerid] = GetTickCount();
 	new pm = 0;
	while(pm < TOTAL_WEAPONS)
	{
		switch(pm)
		{
		    case Missile_Special, Missile_Ricochet: PlayerInfo[playerid][pMissiles][pm] = 1;
			case Missile_Fire, Missile_Homing: PlayerInfo[playerid][pMissiles][pm] = 2;
			case Energy_Mines, Energy_EMP, Energy_Shield, Energy_Invisibility:
			{
			    PlayerInfo[playerid][pMissiles][pm] = 999;
			}
			default:
			{
			    PlayerInfo[playerid][pMissiles][pm] = 0;
			    if(pm < MAX_MISSILEID)
			    {
					PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][pm]);
				}
			}
		}
 		++pm;
 	}
	UpdatePlayerHUD(playerid);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pHealthBar], 0.000000, -8.600000);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthBar]);
	TextDrawShowForPlayer(playerid, gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Time_Text]);

	new model = GetVehicleModel(Current_Vehicle[playerid]);
	PlayerInfo[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
	PlayerInfo[playerid][pEnergy] = floatround(GetTwistedMetalMaxEnergy(model));

	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(PlayerInfo[playerid][pEnergy]));
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], float(PlayerInfo[playerid][pTurbo]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	if(!IsPlayerInVehicle(playerid, Current_Vehicle[playerid]))
	{
	    PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
	}
	switch(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode])
	{
		case RACE:
		{
		    switch(Race_Position[playerid])
		    {
				case 0: PlayerVehicleRacePosition(playerid, PVRP_Create, "*");
				default:
				{
				    new text[4];
			    	format(text, sizeof(text), "%d", Race_Position[playerid]);
				    PlayerVehicleRacePosition(playerid, PVRP_Create, text);
				}
			}
		}
		case HUNTED:
		{
		    if(gHunted_Player[0] == INVALID_PLAYER_ID)
	        {
	            gHunted_Player[0] = Iter_Random(Player);
	  			if(PlayerInfo[gHunted_Player[0]][pSpawned] == 1)
	  			{
	  			    new engine, lights, alarm, doors, bonnet, boot, objective;
					GetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
	  			}
			}
		    else if(gHunted_Player[0] == playerid)
		    {
		        new engine, lights, alarm, doors, bonnet, boot, objective;
				GetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, objective);
				SetVehicleParamsEx(Current_Vehicle[gHunted_Player[0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
		    }
		}
		case TEAM_DEATHMATCH, TEAM_LAST_MAN_STANDING:
	    {
	        foreach(Player, i)
	        {
	        	AdjustTeamColoursForPlayer(i);
	        }
	        AdjustTeamColoursForPlayer(playerid);
	    }
		case TEAM_HUNTED:
		{
		    foreach(Player, i)
	        {
	        	AdjustTeamColoursForPlayer(i);
	        }
	        if(PlayerInfo[playerid][gTeam] == INVALID_GAME_TEAM)
	        {
	            PlayerInfo[playerid][gTeam] = random(MAX_TEAMS);
		        if(PlayerInfo[playerid][gTeam] == TEAM_DOLLS)
		        {
		            PlayerInfo[playerid][gRival_Team] = TEAM_CLOWNS;
		        }
		        else PlayerInfo[playerid][gRival_Team] = TEAM_DOLLS;
		        SendClientMessage(playerid, -1, "You Have Been Placed In A Random Team!");
	            AddPlayerToGameTeam(playerid);
	        }
		    if(gHunted_Player[PlayerInfo[playerid][gTeam]] == INVALID_PLAYER_ID)
			{
			    AssignRandomTeamHuntedPlayer(PlayerInfo[playerid][gTeam]);
			}
			AdjustTeamColoursForPlayer(playerid);
		}
	}
	if(gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Countdown_Time] > 0)
	{
	    TogglePlayerControllable(playerid, false);
	}
	else TogglePlayerControllable(playerid, true);
	SetTimerEx("SetPlayerMapWorldBounds", 1500, false, "i", playerid);
	return 1;
}

forward SetPlayerMapWorldBounds(playerid);
public SetPlayerMapWorldBounds(playerid)
{
    if(!IsPlayerInVehicle(playerid, Current_Vehicle[playerid]))
	{
	    PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
	}
	return (gGameData[PlayerInfo[playerid][gGameID]][g_Map_id] >= MAX_MAPS) ? -1 : SetPlayerWorldBounds(playerid, s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_max_X], s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_min_X],
			s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_max_Y], s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_min_Y]);
}

stock AttachSpecialObjects(playerid, model)
{
    for(new sp = 0; sp < MAX_SPECIAL_OBJECTS; sp++)
	{
	    if(IsValidObject(PlayerInfo[playerid][pSpecialObjects][sp]))
		{
			DestroyObject(PlayerInfo[playerid][pSpecialObjects][sp]);
		}
	}
	switch(model)
	{
	    case Sweet_Tooth:
		{
			PlayerInfo[playerid][pSpecialObjects][0] = CreateObject(18691, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][0], Current_Vehicle[playerid], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			//spike 1593
			PlayerInfo[playerid][pSpecialObjects][1] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][1], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][1], Current_Vehicle[playerid], 0.0, 2.4, -0.2, 0.0, 90.0, 90.0);

			PlayerInfo[playerid][pSpecialObjects][2] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][2], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][2], Current_Vehicle[playerid], 0.0, 2.4, -0.4, 0.0, 90.0, 90.0);

			PlayerInfo[playerid][pSpecialObjects][3] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][3], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][3], Current_Vehicle[playerid], 0.0, 2.5, -0.4, 0.0, 90.0, 90.0);

			PlayerInfo[playerid][pSpecialObjects][4] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][4], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][4], Current_Vehicle[playerid], 0.0, 2.5, -0.5, 0.0, 90.0, 90.0);

			PlayerInfo[playerid][pSpecialObjects][5] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][5], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][5], Current_Vehicle[playerid], 0.0, 2.5, -0.7, 0.0, 90.0, 90.0);
		}
		case Vermin:
		{
		    PlayerInfo[playerid][pSpecialObjects][0] = CreateObject(3797, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][0], Current_Vehicle[playerid], 0.0, -0.4, 1.6, 0.0, 180.0, 90.0);
		}
		case Darkside:
		{
		    SetPlayerAttachedObject(playerid, Darkside_Mask, 19036, 2, 0.1, 0.04, 0.0, 90.0, 90.0, 0.0, 1.0, 1.0, 1.0);
		}
	}
	new id = MAX_SPECIAL_OBJECTS - 1, Float:sX, Float:sY, Float:sZ;
	PlayerInfo[playerid][pSpecialObjects][id] = CreateObject(19198, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0); //19198, "EnExMarkers", "enexmarker1"
	//SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][id], 0, 19198, "none", "none", GetTwistedMetalColour(model, .shift = 1));
    //SetObjectMaterial(PlayerInfo[playerid][pSpecialObjects][id], 1, 19198, "none", "none", GetTwistedMetalColour(model, .shift = 1));
	GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
	AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObjects][id], Current_Vehicle[playerid], 0.0, 0.0, (sZ * 1.7), 0.0, 0.0, 0.0);
	return 1;
}
//18646, "matcolours", "white"
/*
Model: enexmarker3

Tex: EnEx
Alp: EnExa

Texture: EnExMarkers

TXD Textures: enexmarker1 enexmarker1-2 enex
*/

stock DestroySpecialObjects(playerid, model = 0)
{
    for(new sp = 0; sp < MAX_SPECIAL_OBJECTS; sp++)
	{
	    if(IsValidObject(PlayerInfo[playerid][pSpecialObjects][sp]))
		{
			DestroyObject(PlayerInfo[playerid][pSpecialObjects][sp]);
		}
	}
	switch(model)
	{
	    case Darkside: RemovePlayerAttachedObject(playerid, Darkside_Mask);
	}
	return 1;
}

/*
//Snow: 3942, bistro, mp_snow
Ground under the lava: 18752, Volcano, redgravel
Lava: 18752, Volcano, lavalake
*/

forward GurneySpeedUpdate(playerid, vehicleid);
public GurneySpeedUpdate(playerid, vehicleid)
{
	new Float:currspeed[3], Float:direction[3], Float:total, Float:invector[3] = {0.0, -1.0, 0.0};
	GetVehicleVelocity(vehicleid, currspeed[0], currspeed[1], currspeed[2]);
	total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
	RotatePointVehicleRotation(vehicleid, invector, direction[0], direction[1], direction[2]);
    if(total < 0.49)
    {
		total += 0.1;
	}
	else
	{
	    total -= 0.3;
	}
	SetVehicleVelocity(vehicleid, direction[0] * total, direction[1] * total, 0.0);
	return 1;
}

forward RocketSpeedUpdate(playerid, vehicleid);
public RocketSpeedUpdate(playerid, vehicleid)
{
	new Float:vx, Float:vy, Float:vz;
	GetVehicleVelocity(vehicleid, vx, vy, vz);
	new Float:vlength = floatsqroot(vx*vx + vy*vy + vz*vz);

    if(vlength < 0.35) //plane isn't flying fast yet
	{
	    new Float:va;
	    GetVehicleZAngle(vehicleid, va);

	    vx = floatsin(-va, degrees) * 0.4;
	    vy = floatcos(-va, degrees) * 0.4;
	    vz = 0.1;
	}
	else //plane is flying full speed
	{
		vx /= vlength;
		vy /= vlength;
		vz /= vlength;
	}
	new Float:cx, Float:cy, Float:cz;
	GetPlayerCameraFrontVector(playerid, cx, cy, cz);
	cz += 0.08;

	new Float:anglecos;
	anglecos = floatabs(vx*cx + vy*cy + vz*cz); //This value is the cosine of the angle between camera- and vehicle-vector.

	new Float:rx, Float:ry, Float:rz;
	rx = vx + cx*0.4*anglecos + cx * 0.2; //Camera vector * the angle = more effect on small corners, less to zero effect on 90°
	ry = vy + cy*0.4*anglecos + cy * 0.2; //Added another 0.2 so that there still is Some effect at 90°
	rz = vz + cz*0.4*anglecos + cz * 0.2; //Sum of 0.4 + 0.2 = 0.6 = total amount of how much the camera vector gets addded.

	SetVehicleVelocity(vehicleid, rx * 0.5, ry * 0.5, rz * 0.5); //1.3 = speed multiplier
	return 1;
}

#define BURNOUT_INDEX 0.015

#define VEHICLE_ACCELERATE 8

forward BurnoutFunc(playerid, vehicleid);
public BurnoutFunc(playerid, vehicleid)
{
	PlayerInfo[playerid][pBurnout]++;
	new keys, ud, lr;
 	GetPlayerKeys(playerid, keys, ud, lr);
	if(PlayerInfo[playerid][pBurnout] > 10
		&& ( keys == VEHICLE_ACCELERATE )) // VEHICLE_ACCELERATE (8) // for nitro
	{
	    if(!(keys & KEY_FIRE))
	    {
			if(PlayerInfo[playerid][pBurnout] > 28) PlayerInfo[playerid][pBurnout] = 28;
		}
		else if(PlayerInfo[playerid][pBurnout] > 33) PlayerInfo[playerid][pBurnout] = 33;
        new Float:speed[2];
        GetXYInFrontOfVehicle(vehicleid, speed[0], speed[1], BURNOUT_INDEX * PlayerInfo[playerid][pBurnout]);
		AccelerateTowardsAPoint(vehicleid, speed[0], speed[1]);
        PlayerInfo[playerid][pBurnout] = 0;
        KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
        new Float:Xv, Float:Yv, Float:Zv, Float:absV;
		GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
		absV = floatsqroot((Xv * Xv) + (Yv * Yv) + (Zv * Zv));
		if(absV < 0.04)
		{
	        new Float:Zangle;
	        GetVehicleZAngle(vehicleid, Zangle);
	        GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
	        Xv = (0.10 * floatsin(Zangle, degrees));
	        Yv = (0.10 * floatcos(Zangle, degrees));
	        SetVehicleAngularVelocity(vehicleid, Yv, Xv, 0);
		}
    }
    if(keys != ( KEY_SPRINT | KEY_JUMP ) && keys != VEHICLE_ACCELERATE)
	{
		PlayerInfo[playerid][pBurnout] = 0;
		KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
	}
	return 1;
}

CMD:controls(playerid, params[])
{
    SendClientMessage(playerid, -1, "~k~~VEHICLE_FIREWEAPON_ALT~ To Fire A Missile");
    SendClientMessage(playerid, -1, "~k~~VEHICLE_HORN~ To Fire Machine Gun");
    SendClientMessage(playerid, -1, "Press ~k~~TOGGLE_SUBMISSIONS~ And ~k~~VEHICLE_FIREWEAPON_ALT~ To Fire Your ALT Special Weapon");
    SendClientMessage(playerid, -1, "Double Tap And Hold ~k~~VEHICLE_FIREWEAPON~ To Use Turbo");
    SendClientMessage(playerid, -1, "~k~~VEHICLE_TURRETUP~ To Scroll Through Next Weapon (Alternately DEL)");
    SendClientMessage(playerid, -1, "~k~~VEHICLE_TURRETDOWN~ To Scroll Through Previous Weapon (Alternately END)");
    SendClientMessage(playerid, -1, "Press ~k~~CONVERSATION_NO~ To Toggle Missile And Energy Selection");
	SendClientMessage(playerid, -1, "Press ~k~~CONVERSATION_YES~ To Jump");
    SendClientMessage(playerid, -1, "Hold ~k~~VEHICLE_ACCELERATE~ And ~k~~VEHICLE_BRAKE~ To Burnout");
	return 1;
}

CMD:ctest(playerid, params[])
{
    SendClientMessage(playerid, -1, "~k~~SNEAK_ABOUT~ Walk In Vehicle");
    SendClientMessage(playerid, -1, "~k~~PED_LOCK_TARGET~ Aim In Vehicle");
	return 1;
}

#define TARGET_CIRCLE_ATTACHING 1
stock TargetCircle(type = 0, toobjectid, objectslot, vehicleid, Float:attachz = -1.0, Float:x = 0.0, Float:y = 0.0, Float:z = 0.0)
{
	new light_slot, Float:rZ, Float:aX, Float:aY, odd;
	for(light_slot = 0; light_slot < MAX_MISSILE_LIGHTS; light_slot++)
	{
	    if(!IsValidObject(Vehicle_Missile_Lights[vehicleid][light_slot])) continue;
	    rZ += 90.0;
    	switch(odd)
	    {
	        case 0: rZ = 0.0;
			case 1: aX = 0.0, aY = 3.0;
			case 2: aX = 3.0, aY = 0.0;
			case 3: aX = 0.0, aY = -3.0;
			case 4: aX = -3.0, aY = 0.0;
			case 5: break;
	    }
	    ++odd;
	    switch(type)
		{
		    case 0:
		    {
		        light_slot = GetFreeMissileLightSlot(vehicleid);
		        if(light_slot == -1) return;
    			Vehicle_Missile_Lights[vehicleid][light_slot] = CreateObject(18647, x, y, z, 0, 90.0, 270.0, 300.0); //red neonlight
    			Vehicle_Missile_Lights_Attached[vehicleid][light_slot] = objectslot;
			}
		}
		AttachObjectToObject(Vehicle_Missile_Lights[vehicleid][light_slot], toobjectid, aX, aY, attachz, 0.0, 0.0, rZ, 1);
	}
}

new missileobjectex = INVALID_OBJECT_ID;

stock CalculateMissile(vehicleid, &Float:distance, &Float:angle, &Float:x, &Float:y, &Float:z, Float:xCal, Float:yCal, Float:zCal, ping = 120)
{
    z += zCal;

	x += (yCal * floatsin(-angle, degrees));
	y += (yCal * floatcos(-angle, degrees));

	angle += 270.0;
	x += (xCal * floatsin(-angle, degrees));
	y += (xCal * floatcos(-angle, degrees));
	angle -= 270.0;

	new Float:vx, Float:vy, Float:vz;
	GetVehicleVelocity(vehicleid, vx, vy, vz);
	vz = (vx + vy);
	if(vz < 0.0)
	{
	    vz *= -1;
	}
	distance = vz * ping * 0.140;
	printf("(vx + vy): %0.2f - ping: %d - distance: %0.2f", vz, ping, distance);
	x += (distance * floatsin(-angle, degrees));
  	y += (distance * floatcos(-angle, degrees));
  	if(IsValidObject(missileobjectex))
  	{
  	    DestroyObject(missileobjectex);
  	}
	missileobjectex = CreateObject(19282, x, y, z, 0.0, 0.0, (angle - 90.0));
}
////SetObjectRot(object, asin(z_vector), 0.0, 360 - atan2(x_vector, y_vetor));
stock CalculateElevation(playerid, vehicleid, &Float:x, &Float:y, &Float:z, &Float:bank, &Float:distance = 120.0)
{
    switch(PlayerInfo[playerid][Camera_Mode])
	{
		case CAMERA_MODE_FREE_LOOK:
		{
		    new Float:CP[3], Float:FV[3], Float:elevation;
		    GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);
		    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);
			GetVehicleRotation(vehicleid, x, y, bank);
			GetXYZOfVehicle(vehicleid, x, y, z, bank, distance);
			FV[2] += GetTwistedMetalCameraOffset(GetVehicleModel(vehicleid));
			elevation = FV[2] * distance; // + CP[2]
			if(elevation < 0.0)
			{
			    elevation = 0.0;
			}
			z += elevation;
			//SendClientMessageFormatted(playerid, -1, "Z Vector: %0.2f - elevation: %0.2f", FV[2], elevation);
		}
		default:
	    {
			GetVehicleRotation(vehicleid, x, y, bank);
			GetXYZOfVehicle(vehicleid, x, y, z, bank, distance);
		}
	}
	return 1;
}

stock FindMissileTarget(playerid, vehicleid, slot, rear = 0)
{
	new Float:x, Float:y, Float:z, Float:angle, Float:tx, Float:ty, Float:tz,
		Float:anglebetween, Float:anglediff, target;
	GetVehiclePos(vehicleid, x, y, z);
	GetVehicleZAngle(vehicleid, angle);
    foreach(Vehicles, v)
	{
	    if(v == vehicleid) continue;
	    if(IsPlayerInVehicle(playerid, v)) continue;
	    if(!IsVehicleStreamedIn(v, playerid)) continue;
	    if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
	    target = GetVehicleDriver(v);
	    if(target != INVALID_PLAYER_ID)
		{
	    	if(PlayerInfo[playerid][gTeam] == PlayerInfo[target][gTeam]) continue;
	    }
     	GetVehiclePos(v, tx, ty, tz);
     	if(IsPlayerAimingAt(playerid, tx, ty, tz, 30.0))
		{
		    anglebetween = Angle2D( x, y, tx, ty );
			MPClamp360(anglebetween);
			anglediff = (angle - anglebetween);
			MPClamp360(anglediff);
			//SendClientMessageFormatted(playerid, -1, "angle: %0.2f - Anglediff: %0.2f - diff: %0.2f", angle, anglebetween, anglediff);
			switch(rear)
			{
			    case 0: if(90.0 <= anglediff <= 270.0) continue;
				case 1: if(270.0 <= anglediff <= 360.0 || 0.0 <= anglediff <= 90.0) continue;
			}
		    Vehicle_Missile_Following[vehicleid][slot] = v;
		    break;
		}
  	}
}

forward Hammerhead_Special(playerid, id, Float:startdis, Float:toX, Float:toY, Float:toZ, Float:vsX, Float:vsY);
public Hammerhead_Special(playerid, id, Float:startdis, Float:toX, Float:toY, Float:toZ, Float:vsX, Float:vsY)
{
    SendClientMessageFormatted(playerid, RED,
		"Hit: %d - Distance: %0.2f | startdis: %0.2f - Time: %d",
		GetPVarInt(playerid, "Hammerhead_Special_Hit"),
		GetVehicleDistanceFromPoint(id, toX, toY, toZ), startdis,
		GetPVarInt(playerid, "Hammerhead_Special_Time"));
    if(GetPVarInt(playerid, "Hammerhead_Special_Hit") != INVALID_PLAYER_ID
	|| GetVehicleDistanceFromPoint(id, toX, toY, toZ) > startdis
	|| GetPVarInt(playerid, "Hammerhead_Special_Time") <= gettime())
    {
    	new engine, lights, alarm, doors, bonnet, boot, objective,
			target = (GetPVarInt(playerid, "Hammerhead_Special_Hit") == INVALID_VEHICLE_ID) ? GetPVarInt(playerid, "Hammerhead_Special_Attacking") : GetPVarInt(playerid, "Hammerhead_Special_Hit");
		if( 1 <= target <= MAX_VEHICLES )
		{
			GetVehicleParamsEx(Current_Vehicle[target], engine, lights, alarm, doors, bonnet, boot, objective);
			SetVehicleParamsEx(Current_Vehicle[target], VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);
		}
    	KillTimer(Special_Missile_Timer[playerid]);
    	PlayerInfo[playerid][pMissile_Charged] = -1;
    	SetPVarInt(playerid, "Hammerhead_Special_Attacking", INVALID_PLAYER_ID);
    	SetPVarInt(playerid, "Hammerhead_Special_Hit", INVALID_PLAYER_ID);
    }
    return 1;
}

#define TURBO_DEDUCT_INDEX 135

forward Float:GetTwistedMetalCameraOffset(modelid);
stock Float:GetTwistedMetalCameraOffset(modelid)
{
	new Float:offset;
    switch(modelid)
	{
	    case Brimstone: offset = 0.01;
		case Thumper: offset = 0.0;
		case Spectre: offset = 0.01;
	    case Reaper: offset = 0.03;
	    case Crimson_Fury: offset = 0.0;
		case Roadkill: offset = 0.0;
		case Vermin: offset = 0.01;
		case Meat_Wagon: offset = 0.01;
		case Shadow: offset = 0.01;
		case Outlaw: offset = 0.02;
		case Sweet_Tooth: offset = 0.04;
		case Hammerhead: offset = 0.04;
		case Junkyard_Dog: offset = 0.04;
		case Warthog_TM3: offset = 0.02;
		case ManSalughter: offset = 0.04;
		case Darkside: offset = 0.10;
		default: offset = 0.02;
	}
	return offset;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys == 320)
	{
 		switch(PlayerInfo[playerid][Camera_Mode])
 		{
 		    case CAMERA_MODE_NONE:
 		    {
 		        new Float:sX, Float:sY, Float:sZ, model = GetVehicleModel(Current_Vehicle[playerid]);
 		        GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
                if(IsValidObject(PlayerInfo[playerid][Camera_Object]))
 		        {
 		            DestroyObject(PlayerInfo[playerid][Camera_Object]);
 		        }
 		        PlayerInfo[playerid][Camera_Object] = CreatePlayerObject(playerid, 19300, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				AttachPlayerObjectToVehicle(playerid, PlayerInfo[playerid][Camera_Object], Current_Vehicle[playerid],
				0.0, -sY, sZ, 0.0, 0.0, 0.0);
				AttachCameraToPlayerObject(playerid, PlayerInfo[playerid][Camera_Object]);
				PlayerInfo[playerid][Camera_Mode] = CAMERA_MODE_FREE_LOOK;
				SendClientMessage(playerid, -1, "Free Camera Mode Activiated");
		 	}
 		    case CAMERA_MODE_FREE_LOOK:
 		    {
 		        if(IsValidPlayerObject(playerid, PlayerInfo[playerid][Camera_Object]))
 		        {
 		            DestroyPlayerObject(playerid, PlayerInfo[playerid][Camera_Object]);
 		            PlayerInfo[playerid][Camera_Object] = INVALID_OBJECT_ID;
 		        }
 		        PlayerInfo[playerid][Camera_Mode] = CAMERA_MODE_NONE;
 		        SetCameraBehindPlayer(playerid);
 		        SendClientMessage(playerid, -1, "Free Camera Mode Deactiviated");
 		    }
 		}
    }
    if(newkeys & KEY_YES)
   	{
   	    if(PlayerInfo[playerid][pSpawned] == 1)
   	    {
   	    	cmd_jump(playerid, "");
   	    }
   	}
   	if(newkeys & KEY_NO)
   	{   //SelectTextDraw(playerid, ENERGY_COLOUR);
   	    if(PlayerInfo[playerid][pSpawned] == 1)
   	    {
   	        new oldmissile = pMissileid[playerid];
	   		pHUDStatus[playerid] = !pHUDStatus[playerid];
	   	    switch(pHUDStatus[playerid])
	   	    {
	   	    	case HUD_MISSILES:
	   	    	{
	   	    	    pMissileid[playerid] = Missile_Special;
	   	    	    AddEXPMessage(playerid, "HUD:: Missiles");
	   	    	}
				case HUD_ENERGY:
				{
				    pMissileid[playerid] = ENERGY_WEAPONS_INDEX;
					AddEXPMessage(playerid, "HUD:: Energy Abilities");
				}
	   	    }
	   	    CallLocalFunction("OnVehicleMissileChange", "iiii", Current_Vehicle[playerid], oldmissile, pMissileid[playerid], playerid);
	   	    for( new m = 0; m < MAX_MISSILEID; m++ )
			{
			    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
				PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][m]);
			}
			UpdatePlayerHUD(playerid);
   	    }
   	}
    if ((newkeys & KEY_SPRINT) && (newkeys & KEY_JUMP))// || newkeys & (KEY_SPRINT | KEY_JUMP | KEY_FIRE)))
    {
        if(IsPlayerInAnyVehicle(playerid) && gGameData[PlayerInfo[playerid][gGameID]][g_Gamemode_Countdown_Time] == 0)
		{
		    KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
		    PlayerInfo[playerid][pBurnout]++;
		    PlayerInfo[playerid][pBurnoutTimer] = SetTimerEx("BurnoutFunc", 100, true, "ii", playerid, Current_Vehicle[playerid]);
		}
	}
    if (RELEASED( KEY_SPRINT | KEY_JUMP ) && !(newkeys & 8))
    {
        if (IsPlayerInAnyVehicle(playerid) && PlayerInfo[playerid][pBurnout] > 0)
        {
            PlayerInfo[playerid][pBurnout] = 0;
            KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
        }
    }
    if(newkeys & KEY_SPRINT)
	{
	    if(GetPVarInt(playerid, "pGarage") == 2)
	    {
	        SetPVarInt(playerid, "pGarage", 1);
	        CancelSelectTextDraw(playerid);
	    	ForceClassSelection(playerid);
	    	TogglePlayerSpectating(playerid, true);
	    	TogglePlayerSpectating(playerid, false);
	    	CallLocalFunction("OnPlayerRequestClass", "ii", playerid, 0);
	    	new text[96];
		    switch(IsPlayerInAnyVehicle(playerid))
		    {
		    	case 1: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
				default: format(text, sizeof(text), "Select A Vehicle To Start Customizing");
			}
			ShowSubtitle(playerid, text, (60 * 1000), 1, 320.0);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pGarage_Go_Back]);
			SelectTextDraw(playerid, NAVIGATION_COLOUR);
	    }
	}
    /*if(newkeys & KEY_ANALOG_LEFT)
    {
        if(GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) return SendClientMessage(playerid, COLOR_WHITE, "ERROR: You can't use this as a passenger!");
        new Float:vel[3], Float:angle;
        GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
        GetVehicleVelocity(GetPlayerVehicleID(playerid), vel[0], vel[1], vel[2]);
        SetVehicleVelocity(GetPlayerVehicleID(playerid), vel[0], vel[1], vel[2] + 0.25);
        SetVehicleAngularVelocity(GetPlayerVehicleID(playerid), floatsin(-angle - 180.0, degrees)/1.0, floatcos(-angle - 180.0, degrees)/1.0, 0.0);
    }
    if(newkeys & KEY_ANALOG_RIGHT)
    {
        if(GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) return SendClientMessage(playerid, COLOR_WHITE, "ERROR: You can't use this as a passenger!");
        new Float:vel[3], Float:angle;
        GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
        GetVehicleVelocity(GetPlayerVehicleID(playerid), vel[0], vel[1], vel[2]);
        SetVehicleVelocity(GetPlayerVehicleID(playerid), vel[0], vel[1], vel[2] + 0.25);
        SetVehicleAngularVelocity(GetPlayerVehicleID(playerid), floatsin(-angle - 360.0, degrees)/1.0, floatcos(-angle - 360.0, degrees)/1.0, 0.0);
    }*/
	if((newkeys & KEY_FIRE) == KEY_FIRE)
	{
	    new vehicleid = GetPlayerVehicleID(playerid);
	    new model = GetVehicleModel(vehicleid);
	    if(model == Reaper && PlayerInfo[playerid][pSpecial_Using_Alt] == 2)
		{//REAPER_RPG_WEAPON
			new slot = GetFreeMissileSlot(vehicleid), Float:x, Float:y, Float:z, Float:a, light_slots[2], Float:distance;
			pFiring_Missile[playerid] = 1;

			GetPlayerFacingAngle(playerid, a);
			GetPlayerPos(playerid, x, y, z);
          	CalculateMissile(vehicleid, distance, a, x, y, z, VehicleOffsetX[vehicleid], VehicleOffsetY[vehicleid], VehicleOffsetZ[vehicleid], GetPlayerPing(playerid));

          	new Float:x2, Float:y2, Float:z2, Float:bank;
			CalculateElevation(playerid, vehicleid, x2, y2, z2, bank);

			Vehicle_Missile[vehicleid][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, bank, (a - 90.0), 300.0);
            MoveObject(Vehicle_Missile[vehicleid][slot], x2, y2, z2, MISSILE_SPEED);

			Vehicle_Smoke[vehicleid][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
			AttachObjectToObject(Vehicle_Smoke[vehicleid][slot], Vehicle_Missile[vehicleid][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
            for(new L = 0, LS = sizeof(light_slots); L < LS; L++)
			{//red + yellow = orange
			    light_slots[L] = GetFreeMissileLightSlot(vehicleid);
			    switch(L)
			    {
			    	case 0: Vehicle_Missile_Lights[vehicleid][light_slots[L]] = CreateObject(18647, x, y, z, 0, 0, a, 300.0);
			    	default: Vehicle_Missile_Lights[vehicleid][light_slots[L]] = CreateObject(18650, x, y, z, 0, 0, a, 300.0);
				}
				Vehicle_Missile_Lights_Attached[vehicleid][light_slots[L]] = slot;
				AttachObjectToObject(Vehicle_Missile_Lights[vehicleid][light_slots[L]], Vehicle_Missile[vehicleid][slot], 0.0, 0.0, 0.0, 0.0, 0.0, a, 0);
			}
			FindMissileTarget(playerid, vehicleid, slot);
			CallLocalFunction("OnVehicleFire", "iiiii", playerid, vehicleid, slot, Missile_Special, Vehicle_Missile[vehicleid][slot]);
			Object_Owner[Vehicle_Missile[vehicleid][slot]] = vehicleid;
	      	Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = playerid;
	      	Object_Type[Vehicle_Missile[vehicleid][slot]] = Missile_Special;
	      	Object_Slot[Vehicle_Missile[vehicleid][slot]] = slot;
	      	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
	      	PutPlayerInVehicle(playerid, vehicleid, 0);
	      	PlaySoundForPlayersInRange(44239, 35.0, x, y, z); // "RPG! RPG!"
		    return 1;
		}
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && !IsPlayerInvalidNosExcludeBikes(playerid))
  		{
  		    if(PlayerInfo[playerid][pTurbo] <= 0) return 1;
  		    if(PlayerInfo[playerid][Turbo_Tick] == 0)
			{
				PlayerInfo[playerid][Turbo_Tick] = GetTickCount();
			}
			else
			{
				if(GetTickCount() - PlayerInfo[playerid][Turbo_Tick] < 500)
				{
					switch(model)
					{
						case 463:
						{
						    if(IsValidObject(Nitro_Bike_Object[playerid]))
							{
								DestroyObject(Nitro_Bike_Object[playerid]);
							}
						    new Float:x, Float:y, Float:z;
						    GetPlayerPos(playerid, x, y, z);
						    Nitro_Bike_Object[playerid] = CreateObject(18693, x, y, z + 10, 0.0, 0.0, 0.0, 125.0);
							AttachObjectToVehicle(Nitro_Bike_Object[playerid], vehicleid, 0.164999, 0.909999, -0.379999, 86.429962, 3.645001, 0.000000);
						}
						default: AddVehicleComponent(vehicleid, 1010);
					}
		 			KillTimer(PlayerInfo[playerid][Turbo_Timer]);
		 			PlayerInfo[playerid][Turbo_Timer] = SetTimerEx("Turbo_Deduct", TURBO_DEDUCT_INDEX, true, "ii", playerid, vehicleid); //12
				}
				PlayerInfo[playerid][Turbo_Tick] = GetTickCount();
			}
		}
	}
	if(RELEASED(KEY_FIRE) || oldkeys & KEY_FIRE && !(newkeys & KEY_FIRE))
	{
	    if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && !IsPlayerInvalidNosExcludeBikes(playerid))
  		{
 			RemoveVehicleComponent(Current_Vehicle[playerid], 1010);
 			KillTimer(PlayerInfo[playerid][Turbo_Timer]);
 			if(IsValidObject(Nitro_Bike_Object[playerid]))
 			{
			 	DestroyObject(Nitro_Bike_Object[playerid]);
			}
  		}
	}
   	if(RELEASED(MACHINE_GUN_KEY))
 	{
	   KillTimer(Machine_Gun_Firing_Timer[playerid]);
	}
	if(newkeys & (MACHINE_GUN_KEY))
   	{
   	    new id = GetPlayerVehicleID(playerid);
  		if(id != INVALID_VEHICLE_ID && Vehicle_Machine_Gunid[id] == Missile_Machine_Gun)
		{
  			KillTimer(Machine_Gun_Firing_Timer[playerid]);
			new update_index = 285, missileid = Missile_Machine_Gun;
  			if(PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] > 0)
  			{
  			    update_index = 185;
  			    missileid = Missile_Machine_Gun_Upgrade;
  			}
  			FireMissile(playerid, id, missileid);
  			Machine_Gun_Firing_Timer[playerid] = SetTimerEx("FireMissile", update_index, true, "iii", playerid, id, missileid);
		}
	}
	if((newkeys & KEY_SUBMISSION) && (newkeys & MISSILE_FIRE_KEY))
	{
	    if(PlayerInfo[playerid][pMissiles][Missile_Special] == 0) return 1;
     	PlayerInfo[playerid][pMissiles][Missile_Special] --;
		CallLocalFunction("FireALTSpecial", "ii", playerid, Missile_Special);
		if(PlayerInfo[playerid][pMissiles][Missile_Special] == 0)
        {
            pMissileid[playerid] = GetNextHUDSlot(playerid);
        }
        UpdatePlayerHUD(playerid);
		return 1;
	}
	if(newkeys & KEY_SUBMISSION)
	{
	    switch(GetVehicleModel(Current_Vehicle[playerid]))
	    {
	        case Junkyard_Dog:
	        {
	            if(PlayerInfo[playerid][pSpecial_Missile_Vehicle] != INVALID_VEHICLE_ID
					&& IsTrailerAttachedToVehicle(Current_Vehicle[playerid]))
	            {
	                DeletePVar(playerid, "Junkyard_Dog_Attach");
	            	DetachTrailerFromVehicle(Current_Vehicle[playerid]);
	            	GameTextForPlayer(playerid, "~w~Taxi Bomb Dropped", 3000, 3);
     			}
     		}
     	}
	}
	if(newkeys & MISSILE_FIRE_KEY)
   	{
   	    new id = GetPlayerVehicleID(playerid);
   	    switch(PlayerInfo[playerid][pMissile_Charged])
   	    {
	 		case Missile_Special:
	 		{
	 			switch(GetVehicleModel(id))
	      	    {
	      	        case Roadkill:
	      	        {
	      	            pFiring_Missile[playerid] = 1;
			            for(new i = 1; i != 7; i++)
						{
						    FireMissile(playerid, id, Missile_Special);
						}
						PlayerInfo[playerid][pMissile_Special_Time] = 0;
		    			PlayerInfo[playerid][pMissile_Charged] = -1;
		    			new tid = GetPVarInt(playerid, "Flash_Roadkill_Timer");
		    			KillTimer(tid);
		    			DeletePVar(playerid, "Flash_Roadkill_Timer");
		    			GameTextForPlayer(playerid, " ", 1, 3);
					}
				}
			}
			case Missile_Stalker:
			{
			    FireMissile(playerid, id, PlayerInfo[playerid][pMissile_Charged]);
				PlayerInfo[playerid][pMissile_Charged] = -1;
				SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], 0.0);
				KillTimer(PlayerInfo[playerid][pCharge_Timer]);
			}
		}
		if(IsValidObject(Vehicle_Missile[id][5]) && pFiring_Missile[playerid] == 1 && pMissileid[playerid] == Missile_Napalm)
		{
		    new slot = 5, Float:x, Float:y, Float:z, axis, object = Vehicle_Missile[id][slot];
		   	GetObjectPos(object, x, y, z);
		   	DestroyObject(Vehicle_Missile[id][slot]);
		   	Object_Owner[object] = INVALID_VEHICLE_ID;
		  	Object_OwnerEx[object] = INVALID_PLAYER_ID;
		  	Object_Type[object] = -1;
		  	Object_Slot[object] = -1;
		  	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_REMOVE);
			SetPVarInt(playerid, "Dont_Destroy_Napalm", 1);
			Vehicle_Missile[id][slot] = CreateObject(Missile_Napalm_Object, x, y, z, 0, 0, 0.0, 150.0);
			z = GetMapLowestZ(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], x, y, z, axis);
		    MoveObject(Vehicle_Missile[id][slot], x, y, z + 0.2, (MISSILE_SPEED - 38));
			Object_Owner[Vehicle_Missile[id][slot]] = id;
			Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
			Object_Type[Vehicle_Missile[id][slot]] = Missile_Napalm;
			Object_Slot[Vehicle_Missile[id][slot]] = slot;
			EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
			DestroyObject(Vehicle_Smoke[id][slot]);
			SetPVarInt(playerid, "Dont_Destroy_Napalm", 1);
			GameTextForPlayer(playerid, " ", 1, 3); //SendClientMessageFormatted(playerid, -1, "z: %0.2f", z);
	    	return 1;
		}
		new slot, missileid = pMissileid[playerid];
		if(pFiring_Missile[playerid] == Reaper)
		{
		    RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Index);
		    if(PlayerInfo[playerid][pSpecial_Using_Alt] == 1)
		    {
		    	RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Flame_Index);
			}
			GameTextForPlayer(playerid, " ", 1, 3);
		    FireMissile(playerid, id, Missile_Special);
		}
 		if(!pFiring_Missile[playerid])
    	{
         	if(id != INVALID_VEHICLE_ID)
			{
          	    switch(missileid)
          	    {
          	        case Energy_EMP, Energy_Mines, Energy_Shield, Energy_Invisibility,
					  	Missile_Fire, Missile_Homing, Missile_Power,
	  					Missile_Stalker, Missile_RemoteBomb, Missile_Ricochet:
					{
	  					FireMissile(playerid, id, pMissileid[playerid]);
					}
          	        case Missile_Special:
          	        {
          	            if(PlayerInfo[playerid][pMissiles][Missile_Special] == 0) return 1;
          	            PlayerInfo[playerid][pMissiles][Missile_Special] --;
				      	if(PlayerInfo[playerid][pMissiles][Missile_Special] == 0)
				        {
				            pMissileid[playerid] = GetNextHUDSlot(playerid);
				        }
				        UpdatePlayerHUD(playerid);
          	            switch(GetVehicleModel(id))
          	            {
          	                case Hammerhead:
          	                {
          	                    new v = GetClosestVehicle(playerid, 30.0), Float:x, Float:y, Float:z,
								  	Float:sX, Float:sY, Float:sZ, Float:vX, Float:vY, Float:vZ;
          	                    if(v == INVALID_VEHICLE_ID) return 1;
          	                    PlayerInfo[playerid][pMissile_Charged] = Missile_Special;
          	                    GetVehicleVelocity(v, vX, vY, vZ);
          	                    SetVehicleVelocity(v, 0.0, 0.0, 0.0);
          	                    GetVehiclePos(v, x, y, z);
          	                    SetVehiclePos(v, x, y, z + 2.0);
          	                    GetVehicleModelInfo(v, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
          	                    z += sZ + 1.0;
          	                    ShootVehicleToDirection(id, x, y, z, 1.0);
          	                    new vowner = MPGetVehicleDriver(v);
          	                    if(vowner != INVALID_PLAYER_ID)
          	                    {
          	                        new engine, lights, alarm, doors, bonnet, boot, objective;
									GetVehicleParamsEx(v, engine, lights, alarm, doors, bonnet, boot, objective);
									SetVehicleParamsEx(v, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective);
									SetPVarInt(playerid, "Hammerhead_Special_Attacking", vowner);
									SetPVarInt(playerid, "Hammerhead_Special_Hit", INVALID_PLAYER_ID);
									SetPVarInt(playerid, "Hammerhead_Special_Time", gettime() + 5000);
									Special_Missile_Timer[playerid] = SetTimerEx("Hammerhead_Special", 200, true, "iiffffff", playerid, id, GetVehicleDistanceFromPoint(id, x, y, z) + 1.0, x, y, z, sX, sY);
								}
          	                    return 1;
          	                }
          	                case Junkyard_Dog:
	  						{
	  						    //SendClientMessage(playerid, -1, "Special Incomplete");
								if(PlayerInfo[playerid][pSpecial_Missile_Vehicle] != INVALID_VEHICLE_ID)
								{
									DestroyVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
								}
							  	new Float:x, Float:y, Float:z, Float:angle;
				                GetVehiclePos(id, x, y, z);
				                GetVehicleZAngle(id, angle);
				                PlayerInfo[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(Junkyard_Taxi, x, y, z + 10, angle, 0, 0, -1);
								SetVehicleHealth(PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2500.0);
				                SetPVarInt(playerid, "Junkyard_Dog_Attach", PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
				                SendClientMessage(playerid, -1, "Hit Players With The Taxi By T-Sliding");
				                SendClientMessage(playerid, -1, "Press ~k~~TOGGLE_SUBMISSIONS~ To Unhook The Taxi And Drop It As A Bomb");
				                return 1;
							}
							case Shadow:
	  						{
	  						    slot = SPECIAL_MISSILE_SLOT;
          	                    new Float:x, Float:y, Float:z, Float:a, Float:distance;
		 						pFiring_Missile[playerid] = 1;

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

				              	new Float:x2, Float:y2, Float:z2, Float:bank;
								CalculateElevation(playerid, id, x2, y2, z2, bank);

		                    	Vehicle_Missile[id][slot] = CreateObject(Shadow_Coffin, x, y, (z + 1.4), 0.0, bank, (a - 90.0), 300.0);
                                MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED, 0.0, 0.0, 360.0);

								Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
								AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
							}
							case ManSalughter:
	  						{
	  						    SendClientMessage(playerid, -1, "Special Incomplete");
							  	return 1;
							}
							case Reaper:
							{
							    PlayerInfo[playerid][pSpecial_Using_Alt] = 0;
							    PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
							    pFiring_Missile[playerid] = Reaper;
							    GameTextForPlayer(playerid, "~n~~n~~n~~n~~p~Click ~k~~VEHICLE_FIREWEAPON_ALT~ To Fire The ~y~~h~Chainsaw!~n~~w~Do A Wheelie To Create A~n~~r~~h~Flame Saw!", 4000, 3);
							    SetPlayerAttachedObject(playerid, Reaper_Chainsaw_Index, Reaper_Chainsaw, Reaper_Chainsaw_Bone, 0.0, 0.0, 0.0, 80.0, 40.0, -10.0, 1.0, 1.0, 1.0);
								return 1;
			    			}
          	                case Sweet_Tooth:
          	                {
          	                    pFiring_Missile[playerid] = 1;
          	                    PlayerInfo[playerid][pSpecial_Using_Alt] = 0;
          	                    PlayerInfo[playerid][pMissile_Special_Time] = 0;
          	                    PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
          	                    SetPVarInt(playerid, "Firing_Sweet_Tooth_Special", 0);
          	                    FireMissile(playerid, id, Missile_Special);
          	                    for(new i = 1; i != 20; i++)
								{
								    SetTimerEx("FireMissile", (i * 225), false, "iii", playerid, id, Missile_Special);
								}
								return 1;
          	                }
          	                case Warthog_TM3:
							{
                                pFiring_Missile[playerid] = 1;
          	                    PlayerInfo[playerid][pSpecial_Using_Alt] = 0;
          	                    PlayerInfo[playerid][pMissile_Special_Time] = 0;
          	                    PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
          	                    FireMissile(playerid, id, Missile_Special);
          	                    for(new i = 1; i != 3; i++)
								{
								    SetTimerEx("FireMissile", (i * 220), false, "iii", playerid, id, Missile_Special);
								}
								return 1;
							}
          	                case Roadkill:
          	                {
          	                    pFiring_Missile[playerid] = 1;
								KillTimer(Special_Missile_Timer[playerid]);
								PlayerInfo[playerid][pMissile_Special_Time] = 0;
								PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
								PlayerInfo[playerid][pMissile_Charged] = -1;
                                Special_Missile_Timer[playerid] = SetTimerEx("Roadkill_Special", 600, true, "ii", playerid, 1);
                                return 1;
          	                }
          	                case Thumper:
							{
							    if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
          	                    {
          	                        DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
          	                        PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
          	                    }
          	                    pFiring_Missile[playerid] = 1;
							    PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(18694, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
								AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], id, 0.0, 2.0, -1.7, 0.0, 0.0, 0.0);
							    PlayerInfo[playerid][pMissile_Special_Time] = 0;
								KillTimer(Special_Missile_Timer[playerid]);
                                Special_Missile_Timer[playerid] = SetTimerEx("Thumper_Special", 100, true, "ii", playerid, id);
                                return 1;
							}
							case Darkside:
          	                {
          	                    pFiring_Missile[playerid] = 1;
          	                    PlayerInfo[playerid][pMissile_Charged] = Missile_Special;
          	                    new Float:currspeed[3], Float:direction[3], Float:total;
								GetVehicleVelocity(id, currspeed[0], currspeed[1], currspeed[2]);
								total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
								total += 1.1;
								new Float:invector[3] = {0.0, -1.0, 0.0};
								RotatePointVehicleRotation(id, invector, direction[0], direction[1], direction[2]);
								SetVehicleVelocity(id, direction[0] * total, direction[1] * total, direction[2] * total);
								SetTimerEx("ReturnDarksidesSpeed", 1100, false, "iifff", playerid, id, currspeed[0], currspeed[1], currspeed[2]);
                                CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, Missile_Special, INVALID_OBJECT_ID);
								return 1;
          	                }
          	                case Outlaw: //2985 0.0 -0.5 0.4 0.0 0.0 90.0//mounted minigun
          	                {
          	                    if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
          	                    {
          	                        DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
          	                        PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
          	                    }
          	                    pFiring_Missile[playerid] = 1;
          	                    KillTimer(Special_Missile_Timer[playerid]);
          	                    PlayerInfo[playerid][pMissile_Special_Time] = 0;
								//362 0.1 -0.5 1.5 0.0 30.0 95.0//minigun model id
								PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(362, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
								AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], id, 0.1, -0.5, 1.5, 0.0, 30.0, 95.0);
								Special_Missile_Timer[playerid] = SetTimerEx("Outlaw_Special", 200, true, "ii", playerid, id);
								return 1;
							}
							case Meat_Wagon:
          	                {
          	                    pFiring_Missile[playerid] = 1;
          	                    slot = SPECIAL_MISSILE_SLOT;
          	                    new Float:x, Float:y, Float:z, Float:a, Float:distance;

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

				              	new Float:x2, Float:y2, Float:z2, Float:bank;
								CalculateElevation(playerid, id, x2, y2, z2, bank); // 2146 gurney

		                    	Vehicle_Missile[id][slot] = CreateObject(2146, x, y, z, 0.0, bank, (a - 90.0), 300.0);
                                MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

								Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
		          				AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

                                FindMissileTarget(playerid, id, slot);
          	                }
          	                case Vermin:
          	                {
          	                    pFiring_Missile[playerid] = 1;
          	                    slot = SPECIAL_MISSILE_SLOT;
          	                    new Float:x, Float:y, Float:z, Float:a, Float:distance;

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

				              	new Float:x2, Float:y2, Float:z2, Float:bank;
								CalculateElevation(playerid, id, x2, y2, z2, bank);

		                    	Vehicle_Missile[id][slot] = CreateObject(19079, x, y, z, 0.0, bank, (a - 90.0), 300.0);
								MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

								Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
		          				AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

                                FindMissileTarget(playerid, id, slot);
						  	}
          	                case Brimstone: //3092 - dead body
          	                {
          	                    slot = GetFreeMissileSlot(id);
		 						pFiring_Missile[playerid] = 1;

								new Float:x, Float:y, Float:z, Float:a, Float:distance;

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);
		                      	CalculateMissile(id, distance, a, x, y, z, 0.0, 2.0, 1.3, GetPlayerPing(playerid));

				              	new Float:x2, Float:y2, Float:z2, Float:bank;
								CalculateElevation(playerid, id, x2, y2, z2, bank);

		                    	Vehicle_Missile[id][slot] = CreateObject(3092, x, y, z, 0, 0, 95.0, 300.0);
								MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);
							}
          	                case Spectre:
          	                {
          	                    slot = GetFreeMissileSlot(id);
          	                    pFiring_Missile[playerid] = 1;

          	                    new Float:x, Float:y, Float:z, Float:a, Float:distance;

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);
		                      	CalculateMissile(id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

				               	new Float:x2, Float:y2, Float:z2, Float:bank;
								CalculateElevation(playerid, id, x2, y2, z2, bank);

		                    	Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, bank, (a - 90.0), 300.0);
                                MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

								Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
		          				AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

                                FindMissileTarget(playerid, id, slot);
							}
          	            }
          	            if(Vehicle_Missile[id][slot] != INVALID_OBJECT_ID)
          	            {
          	                CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, missileid, Vehicle_Missile[id][slot]);
	          	            Object_Owner[Vehicle_Missile[id][slot]] = id;
					      	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
					      	Object_Type[Vehicle_Missile[id][slot]] = missileid;
					      	Object_Slot[Vehicle_Missile[id][slot]] = slot;
					      	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
				      	}
          	        }
          	        case Missile_Napalm:
          	        {
          	            if(PlayerInfo[playerid][pMissiles][Missile_Napalm] == 0) return 1;
          	            PlayerInfo[playerid][pMissiles][Missile_Napalm]--;
          	            slot = 5;
          	        	new Float:x, Float:y, Float:z, Float:a;
						pFiring_Missile[playerid] = 1;


						GetVehiclePos(id, x, y, z);
    					GetVehicleZAngle(id, a);

						a += 90.0;
		               	z += VehicleOffsetZ[id];

		               	x += (VehicleOffsetX[id] * floatsin(-a, degrees));
		               	y += (VehicleOffsetX[id] * floatcos(-a, degrees));

		               	z += 1.5;

		               	Vehicle_Missile[id][slot] = CreateObject(Missile_Napalm_Object, x, y, z, 0.0, 0.0, a + 180, 150.0);
		               	Vehicle_Smoke[id][slot] = CreateObject(18690, x, y, z - 1.3, 0, 0, 0, 150.0);

                       	a += 270.0;
		               	x += (65.0 * floatsin(-a, degrees));
		               	y += (65.0 * floatcos(-a, degrees));

		               	MoveObject(Vehicle_Missile[id][slot], x, y, z + 4.5, MISSILE_SPEED - 20);
		               	AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);

						TargetCircle(_, Vehicle_Missile[id][slot], slot, id, _, x, y, z);
                    }
					case Missile_Environmentals:
          	        {
          	            switch(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id])
          	            {
          	                case MAP_DOWNTOWN:
          	                {
		          	            if(Vehicle_Using_Environmental[id] == 1) return 1;
		          	            if(PlayerInfo[playerid][pMissiles][Missile_Environmentals] == 0) return 1;
		          	            PlayerInfo[playerid][pMissiles][Missile_Environmentals]--;
		          	            StartEnvironmentalEvent(playerid);
		          	            if(PlayerInfo[playerid][pMissiles][Missile_Environmentals] == 0)
		          	            {
		          	                pMissileid[playerid] = GetNextHUDSlot(playerid);
		          	            }
					  			UpdatePlayerHUD(playerid);
				  			}
			  			}
			  			CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, missileid, INVALID_OBJECT_ID);
          	            return 1;
					}
	         	}
	         	if(Vehicle_Missile[id][slot] != INVALID_OBJECT_ID)
	         	{
	         	    CallLocalFunction("OnVehicleFire", "iiiii", playerid, id, slot, missileid, Vehicle_Missile[id][slot]);
		         	Object_Owner[Vehicle_Missile[id][slot]] = id;
			      	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
			      	Object_Type[Vehicle_Missile[id][slot]] = missileid;
			      	Object_Slot[Vehicle_Missile[id][slot]] = slot;
			      	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
		      	}
			}
     	}
  	}
	if(PRESSED(KEY_ANALOG_DOWN) || HOLDING(KEY_ANALOG_DOWN))
   	{
   	    new id = GetPlayerVehicleID(playerid), oldmissile = pMissileid[playerid];
        pMissileid[playerid] = GetNextHUDSlot(playerid);
   	    CallLocalFunction("OnVehicleMissileChange", "iiii", id, oldmissile, pMissileid[playerid], playerid);
   	}
   	if(PRESSED(KEY_ANALOG_UP) || HOLDING(KEY_ANALOG_UP))
   	{
   	    new id = GetPlayerVehicleID(playerid), oldmissile = pMissileid[playerid];
   	    pMissileid[playerid] = GetPreviousHUDSlot(playerid);
   	    CallLocalFunction("OnVehicleMissileChange", "iiii", id, oldmissile, pMissileid[playerid], playerid);
   	}
	return 1;
}

stock StartEnvironmentalEvent(playerid)
{
    new vehicleid = GetPlayerVehicleID(playerid);
    Vehicle_Using_Environmental[vehicleid] = 1;
    SetPVarInt(playerid, "EnvironmentalCycle", 0);
    PlayerInfo[playerid][EnvironmentalCycle_Timer] = SetTimerEx("StartEnvironmentalCycle", 600, true, "dd", playerid, vehicleid);
	return 1;
}

forward StartEnvironmentalCycle(playerid, vehicleid);
public StartEnvironmentalCycle(playerid, vehicleid)
{
    SetPVarInt(playerid, "EnvironmentalCycle", GetPVarInt(playerid, "EnvironmentalCycle") + 1);
    new Float:x, Float:y, Float:z, Float:vx, Float:vy, Float:vz;
    GetObjectPos(HelicopterAttack, x, y, z);
	foreach(Vehicles, v)
	{
	    if(v == vehicleid) continue;
	    if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
     	GetVehiclePos(v, vx, vy, vz);
     	if(MPFDistance(x, y, z, vx, vy, vz) < 80.0)
		{
		    new Float:a, slot = GetFreeMissileSlot(vehicleid);

		    if(IsValidObject(Vehicle_Missile[vehicleid][slot])) DestroyObject(Vehicle_Missile[vehicleid][slot]);
			if(IsValidObject(Vehicle_Smoke[vehicleid][slot])) DestroyObject(Vehicle_Smoke[vehicleid][slot]);

		    GetObjectRot(HelicopterAttack, a, a, a);

		    Vehicle_Missile[vehicleid][slot] = CreateObject(Missile_Default_Object, x, y, (z - 0.3), 0, 0, (a - 90.0), 300.0);
		   	Vehicle_Smoke[vehicleid][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);

			MoveObject(Vehicle_Missile[vehicleid][slot], vx, vy, z, MISSILE_SPEED);

			AttachObjectToObject(Vehicle_Smoke[vehicleid][slot], Vehicle_Missile[vehicleid][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

		    SetObjectFaceCoords3D(HelicopterAttack, vx, vy, vz, 0.0, 180.0, 90.0);//22.0, 11.0, 180.0
		    Vehicle_Missile_Following[vehicleid][slot] = v;

			CallLocalFunction("OnVehicleFire", "iiiii", INVALID_PLAYER_ID, vehicleid, slot, Missile_Environmentals, Vehicle_Missile[vehicleid][slot]);

			Object_Owner[Vehicle_Missile[vehicleid][slot]] = vehicleid;
	      	Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = playerid;
	      	Object_Type[Vehicle_Missile[vehicleid][slot]] = Missile_Environmentals;
	      	Object_Slot[Vehicle_Missile[vehicleid][slot]] = slot;
	      	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
			break;
		}
  	}
	if(GetPVarInt(playerid, "EnvironmentalCycle") > 12)
	{
	    DeletePVar(playerid, "EnvironmentalCycle");
	    Vehicle_Using_Environmental[vehicleid] = 0;
	    KillTimer(PlayerInfo[playerid][EnvironmentalCycle_Timer]);
	}
	return 1;
}

stock SetObjectFaceCoords3D(iObject, Float: fX, Float: fY, Float: fZ, Float: fRollOffset = 0.0, Float: fPitchOffset = 0.0, Float: fYawOffset = 0.0)
{
    new Float: fOX, Float: fOY, Float: fOZ, Float: fPitch;
    GetObjectPos(iObject, fOX, fOY, fOZ);

    fPitch = floatsqroot(floatpower(fX - fOX, 2.0) + floatpower(fY - fOY, 2.0));
    fPitch = floatabs(atan2(fPitch, fZ - fOZ));

    fZ = atan2(fY - fOY, fX - fOX) - 90.0; // Yaw

    SetObjectRot(iObject, fRollOffset, fPitch + fPitchOffset, fZ + fYawOffset);
}

forward Float:GetMissileDamage(missileid, vehicleid = 0, alt_weapon = 0, mapid = -1);
stock Float:GetMissileDamage(missileid, vehicleid = 0, alt_weapon = 0, mapid = -1)
{
	new Float:damage;
	switch(missileid)
	{
	    case Missile_Special:
		{
		    if(vehicleid)
		    {
			    switch(GetVehicleModel(vehicleid))
			    {
					case Junkyard_Dog: damage = 35.0;
					case Brimstone: damage = 45.0;
					case Outlaw: damage = 1.0;
					case Reaper:
					{
						switch(alt_weapon)
						{
						    case 1: damage = 150.0;
						   	default: damage = 65.0;
						}
					}
					case Roadkill: damage = 15.0;
					case Thumper: damage = 1.5;
					case Spectre: damage = 45.0;
					case Darkside: damage = 0.0;
					case Shadow:
					{
					    switch(alt_weapon)
					    {
					        case 1: damage = 120.0;
							default: damage = 30.0;
						}
					}
					case Meat_Wagon:
					{
					    switch(alt_weapon)
					    {
					        case 1: damage = 90.0;
							default: damage = 40.0;
						}
					}
					case Vermin:
					{
						switch(alt_weapon)
					    {
					        case 1: damage = 100.0;
					        case 2: damage = 50.0;
							default: damage = 30.0;
						}
					}
					case Warthog_TM3:
					{
					    switch(alt_weapon)
					    {
					        case 1: damage = 25.0;
							default: damage = 25.0;
						}
					}
					case ManSalughter: damage = 10.0;
					case Sweet_Tooth: damage = 5.0;
					case Hammerhead: damage = 1.0;
					default: damage = 0.0;
			    }
		    }
		}
	    case Missile_Fire: damage = 16.0;
	    case Missile_Homing: damage = 12.0;
	    case Missile_Environmentals:
	    {
	        switch(mapid)
	        {
	            case MAP_DOWNTOWN:
	            {
	                damage = 12.0;
	            }
	            case MAP_SUBURBS:
				{
				    damage = 1.0;
				}
	        }
	    }
	    case Missile_Power: damage = 75.0;
	    case Missile_Napalm: damage = 35.0;
	    case Missile_Ricochet: damage = 16.0;
	    case Missile_Stalker: damage = 45.0;
	    case Missile_RemoteBomb: damage = 50.0;
	    case Missile_Machine_Gun: damage = 1.0;
	    case Missile_Machine_Gun_Upgrade: damage = 1.0;
	    case Energy_Mines: damage = 10.0;
	    case Energy_EMP: damage = 5.0;
	    default: damage = 10.0;
	}
	return damage;
}

forward Float:GetMissileExplosionRadius(missileid);
stock Float:GetMissileExplosionRadius(missileid)
{
	#pragma unused missileid
	return 1.0;
}

stock Float:GetTwistedMetalMissileAccuracy(playerid = INVALID_PLAYER_ID, missileid, model = 0, alt_special = 0)
{//lower accuracy = better homing
    new Float:accuracy = 1.0;
    switch(missileid)
	{
	    case Missile_Special:
	    {
	        switch(model)
	        {
	            case Warthog_TM3: accuracy = 3.0;
	            case Roadkill, Spectre: accuracy = 4.0;
	            case Reaper:
	            {
	                switch(alt_special)
				    {
				        case 2:
				        {
				            accuracy = 4.0;
				        }
					}
	            }
	            case Sweet_Tooth: accuracy = 4.5;
	            case Meat_Wagon: accuracy = 2.0;
				case Vermin: accuracy = 2.0;
	        }
	    }
	    case Missile_Fire: accuracy = 5.0;
	    case Missile_Homing: accuracy = 3.0;
	    case Missile_Stalker:
		{
			accuracy = PlayerInfo[playerid][pCharge_Index];
		}
		case Missile_RemoteBomb: accuracy = 4.0;
		case Missile_Environmentals: accuracy = 1.0;
		case Energy_EMP: accuracy = 2.0;
	}
	return accuracy;
}

forward OnBrimstoneFollowerHitVehicle(playerid, vehicleid, vehicle, FollowerObject, slot, Float:x, Float:y, Float:z);
public OnBrimstoneFollowerHitVehicle(playerid, vehicleid, vehicle, FollowerObject, slot, Float:x, Float:y, Float:z)
{
	//SendClientMessageFormatted(playerid, -1, "[System: OnBrimstoneFollowerHitVehicle] - vehicle hit: %d - objectid: %d", vehicle, FollowerObject);
    FollowerObject = CreateObject(3092, x, y, z, 0.0, 0.0, 95.0, 250.0);
    AttachObjectToVehicle(FollowerObject, vehicle, 0.0, 0.0, 0.7, 0.0, 0.0, 95.0);
    SetTimerEx("FinishBrimstoneHit", 2500, false, "iiiii", playerid, vehicleid, vehicle, FollowerObject, slot);
	pFiring_Missile[playerid] = 0;
 	return 1;
}

forward FinishBrimstoneHit(playerid, myvid, vehicle, objectid, slot);
public FinishBrimstoneHit(playerid, myvid, vehicle, objectid, slot)
{
    //SendClientMessageFormatted(playerid, -1, "[System: FinishBrimstoneHit] - vehicle hit: %d - objectid: %d", vehicle, objectid);
    new Float:x, Float:y, Float:z;
    Object_Owner[objectid] = INVALID_VEHICLE_ID;
  	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
  	Object_Type[objectid] = -1;
  	Object_Slot[objectid] = -1;
  	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_REMOVE);
	DestroyObject(objectid);//GetObjectPos(objectid, x, y, z);
	DamagePlayer(playerid, myvid, MPGetVehicleDriver(vehicle), vehicle, GetMissileDamage(Missile_Special, myvid), Missile_Special);
	GetVehiclePos(objectid, x, y, z);
	z += 0.8;
    Vehicle_Smoke[myvid][slot] = CreateObject(18683, x, y, z, 0.0, 0.0, 0.0, 300.0);
    SetTimerEx("Destroy_Object", 200, false, "i", Vehicle_Smoke[myvid][slot]);
	return 1;
}

stock PullVehicleIntoDirection(vehicleid, Float:x, Float:y, Float:z, Float:speed)
{
    new Float:distance, Float:vehicle_pos[3];

    GetVehiclePos(vehicleid, vehicle_pos[0], vehicle_pos[1], vehicle_pos[2]);
    SetVehicleZAngle(vehicleid, atan2VehicleZ(vehicle_pos[0], vehicle_pos[1], x, y));
    x -= vehicle_pos[0];
    y -= vehicle_pos[1];
    z -= vehicle_pos[2];
    distance = floatsqroot((x * x) + (y * y) + (z * z));
    x = (speed * x) / distance;
    y = (speed * y) / distance;
    z = (speed * z) / distance;
    SetVehicleVelocity(vehicleid, x, y, z);
}

#define USE_SMOOTH_TURNS

stock ShootVehicleToDirection(vehicleid, Float:x, Float:y, Float:z, Float:speed) // Gamer_Z & Mickey
{
	new Float:distance, Float:vehicle_pos[3];
    GetVehiclePos(vehicleid, vehicle_pos[0], vehicle_pos[1], vehicle_pos[2]);
	#if defined USE_SMOOTH_TURNS
	new Float: oz = atan2VehicleZ(vehicle_pos[0], vehicle_pos[1], x, y), Float:vz;
	GetVehicleZAngle(vehicleid, vz);
	if(oz < (vz - 180)) oz = oz + 360;
	if(vz < (oz - 180)) vz = vz + 360;
	new Float: cz = floatabs(vz - oz);
	#else
	SetVehicleZAngle(vehicleid, atan2VehicleZ(vehicle_pos[0], vehicle_pos[1], x, y));
	#endif
    x -= vehicle_pos[0];
    y -= vehicle_pos[1];
    z -= vehicle_pos[2];

    z += 0.1;
    distance = floatsqroot((x * x) + (y * y) + (z * z));
    x = (speed * x) / distance;
    y = (speed * y) / distance;
    z = (speed * z) / distance;

	#if defined USE_SMOOTH_TURNS
	if(cz > 0)
 	{
		new Float: fz = cz * 0.0015;
		SetVehicleAngularVelocity(vehicleid, 0.0, 0.0, (vz < oz) ? fz : -fz);
	}
	#endif
    SetVehicleVelocity(vehicleid, x, y, z);
}

forward Float:atan2VehicleZ(Float:Xb, Float:Yb, Float:Xe, Float:Ye);// Dunno how to name it...
stock Float:atan2VehicleZ(Float:Xb, Float:Yb, Float:Xe, Float:Ye)
{
	new Float:a = floatabs(360.0 - atan2( Xe - Xb, Ye - Yb));
	if(360 > a > 180) return a;
	return a - 360.0;
}

forward MoveDownLift(liftid);
public MoveDownLift(liftid)
{
    MovingLiftStatus[liftid] = 0;
    new Float:x, Float:y, Float:z;
 	GetObjectPos(MovingLifts[liftid], x, y, z);
	MoveObject(MovingLifts[liftid], x, y, z - MovingLiftArray[liftid][L_Move_Z_Index], MovingLiftArray[liftid][L_Move_Speed]);
	return 1;
}

UpdateWheelTarget()
{
    gCurrentTargetYAngle += 36.0; // There are 10 carts, so 360 / 10
    if(gCurrentTargetYAngle >= 360.0) {
		gCurrentTargetYAngle = 0.0;
    }
	if(gWheelTransAlternate) gWheelTransAlternate = 0;
	else gWheelTransAlternate = 1;
}

//-------------------------------------------------

public RotateWheel()
{
    UpdateWheelTarget();

    new Float:fModifyWheelZPos = 0.0;
    if(gWheelTransAlternate) fModifyWheelZPos = 0.05;

    MoveObject( gFerrisWheel, gFerrisOrigin[0], gFerrisOrigin[1], gFerrisOrigin[2]+fModifyWheelZPos,
				FERRIS_WHEEL_SPEED, 0.0, gCurrentTargetYAngle, FERRIS_WHEEL_Z_ANGLE );
}


public OnObjectMoved(objectid)
{
	/*if(Move_ObjectX[objectid] != 0.0 && Move_ObjectY[objectid] != 0.0)
	{
	    new Float:opos[2], Float:G_Z;
 		GetObjectPos(objectid, opos[0], opos[1], G_Z);
 		GetPointZPos(opos[0], opos[1], G_Z);
	    MoveObject(objectid, Move_ObjectX[objectid], Move_ObjectY[objectid], G_Z + 0.9, MISSILE_SPEED);
	}*/
	//printf("[System: OnObjectMoved] - objectid: %d - missile: %s - vowner: %d - powner: %d - slot: %d", objectid, GetTwistedMissileName(Object_Type[objectid], objectid), Object_Owner[objectid], Object_OwnerEx[objectid], Object_Slot[objectid]);
    if(Object_Type[objectid] == -1)
	{
	 	if(objectid == gFerrisWheel)
		{
	    	SetTimer("RotateWheel", 3 * 1000, false);
	    	return 1;
		}
		for(new i = 0; i < sizeof(MovingLifts); i++)
		{
		    if(objectid == MovingLifts[i])
		    {
				switch(MovingLiftStatus[i])
				{
					case 1:
				    {
				        SetTimerEx("MoveDownLift", 5000, false, "i", i);
					}
					case 0:
					{
						DestroyPickup(MovingLiftPickup[i]);
			        	MovingLiftPickup[i] = CreatePickup(1247, 14, MovingLiftArray[i][L_X], MovingLiftArray[i][L_Y], MovingLiftArray[i][L_Z] - 0.6);
					}
				}
				return 1;
			}
		}
		return 1;
	}
	new vehicleid = Object_Owner[objectid], playerid = Object_OwnerEx[objectid], missileid = Object_Type[objectid], slot = Object_Slot[objectid];
	new Float:x, Float:y, Float:z;
    if(vehicleid != INVALID_VEHICLE_ID)
	{
	    switch(missileid)
	    {
	        case Missile_Napalm:
	        {
	            new destroynapalm = GetPVarInt(Object_OwnerEx[objectid], "Dont_Destroy_Napalm");
				if(destroynapalm == 1)
				{
		            GetObjectPos(objectid, x, y, z);
			        slot = 5;
			        CreateMissileExplosion(vehicleid, Missile_Napalm, x, y, z, _);
					RadiusDamage(playerid, vehicleid, x, y, z, GetMissileDamage(missileid), missileid, 15.0);
			        pFiring_Missile[playerid] = 0;
			        Vehicle_Missile_Following[vehicleid][slot] = INVALID_VEHICLE_ID;
                    SetPVarInt(Object_OwnerEx[objectid], "Dont_Destroy_Napalm", 0);
					Object_Owner[Vehicle_Missile[vehicleid][slot]] = INVALID_VEHICLE_ID;
				  	Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = INVALID_PLAYER_ID;
				  	Object_Type[Vehicle_Missile[vehicleid][slot]] = -1;
				  	Object_Slot[Vehicle_Missile[vehicleid][slot]] = -1;
				  	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_REMOVE);
				  	DestroyObject(Vehicle_Missile[vehicleid][slot]);
				 	for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
					{
					    if(Vehicle_Missile_Lights_Attached[vehicleid][L] != slot) continue;
					 	if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
				  		{
						  	DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
						}
				 	}
				 	if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
			 		{
					 	DestroyObject(Vehicle_Smoke[vehicleid][slot]);
					}
				 	return 1;
			 	}
	        }
	        default:
	        {
	            CallLocalFunction("UpdateMissile", "iiiiii", playerid, vehicleid, objectid, missileid, slot, Vehicle_Missile_Following[vehicleid][slot]);
			}
        }
	}
	switch(Object_Type[objectid])
	{
	    case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
	    {
	        if(Object_Slot[objectid] != -1)
	        {
	            DestroyObject(Vehicle_Machine_Gun[vehicleid][Object_Slot[objectid]]);
	        	if(Object_Type[objectid] == Missile_Machine_Gun_Upgrade)
	        	{
	        	    if(IsValidObject(Vehicle_Machine_Mega_Gun[vehicleid][Object_Slot[objectid]]))
	        	    {
		        		DestroyObject(Vehicle_Machine_Mega_Gun[vehicleid][Object_Slot[objectid]]);
		        	}
	        	}
	        }
	    }
	    case Missile_Ricochet: return 1;
	    default:
		{
		    CallLocalFunction("Explode_Missile", "iiii", playerid, vehicleid, slot, missileid);
		}
	}
	EditPlayerSlot(playerid, Object_Slot[objectid], PLAYER_MISSILE_SLOT_REMOVE);
	Object_Owner[objectid] = INVALID_VEHICLE_ID;
 	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
 	Object_Type[objectid] = Object_Slot[objectid] = -1;
	return 1;
}

CMD:rd(playerid, params[])
{
    DamagePlayer(playerid, Current_Vehicle[playerid], MPGetVehicleDriver(Current_Vehicle[playerid]), Current_Vehicle[playerid], 15.0, Missile_Special);
	return 1;
}

stock RadiusDamage(playerid, vehicleid, Float:x, Float:y, Float:z, Float:maxdamage, missileid, Float:radius)
{
	new Float:pdist, Float:damage;
    foreach(Vehicles, v)
    {
		pdist = GetVehicleDistanceFromPoint(v, x, y, z);
        pdist *= 0.8;
        if(pdist > radius) continue;
        damage = (1 - (pdist / radius)) * maxdamage;
        DamagePlayer(playerid, vehicleid, MPGetVehicleDriver(v), v, damage, missileid);
        //printf("[System: RadiusDamage] - damage: %0.2f - pdist: %0.2f - radius: %0.2f", damage, pdist, radius);
	}
	return 1;
}

stock DamagePlayer(playerid, id, damagedid = INVALID_PLAYER_ID, vehicleid, Float:damount, missileid, alt_special = 0, distance_type = d_type_none)
{
	new Float:amount = damount, Float:health, bool:use2text = false, Float:newhealth,
		Float:oldhealth, str[32 + 4];
	T_GetVehicleHealth(vehicleid, health);
	oldhealth = health;
	newhealth = (health - amount);
	if(newhealth <= 0.0)
	{
	    damount -= oldhealth;
	    if(damount < 0.0) damount *= -1;
	}
	T_SetVehicleHealth(vehicleid, newhealth);
	pCurrentlyAttacking[id] = vehicleid;
	pCurrentlyAttackingMissile[id] = missileid;
	PlayerInfo[playerid][pDamageDone] += damount;
	if(damagedid != INVALID_PLAYER_ID)
	{
	    PlayerInfo[damagedid][pDamageTaken] += damount;
		PlayerInfo[playerid][pDamageToPlayer][damagedid] += damount;
	}
	switch(missileid)
    {
        case Missile_Special, Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
        {
            pCurrentlyAttackingDamage[id][missileid] += damount;
		}
    }
	if((GetTickCount() - pLastAttackedTime[id]) < 1500)
	{
	    if(pLastAttackedMissile[id] == pCurrentlyAttackingMissile[id])
	    {
	        switch(missileid)
	        {
	            case Missile_Special, Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
	            {
	                amount += pCurrentlyAttackingDamage[id][missileid];
	                use2text = true;
				}
	        }
	    }
	}
	else
	{
	    pLastAttackedMissile[id] = -1;
	    pCurrentlyAttackingDamage[id][missileid] = 0;
	}
	if(playerid != INVALID_PLAYER_ID)
	{
		switch(missileid)
		{
		    case Missile_Special:
		    {
	     		format(str, sizeof(str), "%s %d damage", GetTwistedMissileName(missileid, id, true, alt_special, distance_type), floatround(amount));
		    }
		    case Missile_Fire..Missile_Napalm, Missile_Ricochet..Missile_RemoteBomb:
		    {
				format(str, sizeof(str), "%s Missile hit %d damage", GetTwistedMissileName(missileid, id), floatround(amount));
			}
			case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
			{
				format(str, sizeof(str), "%s %d damage", GetTwistedMissileName(missileid, id), floatround(amount));
			}
		}
		TimeTextForPlayer( TIMETEXT_TOP, playerid, str, 3000, _, use2text);
	}
	//printf("DamagePlayer(id: %d, vid: %d, d: %0.2f, m: %d, hleft: %0.2f)", id, vehicleid, amount, missileid, newhealth);
	if( newhealth <= 0.0 && health > 0.0)
    {
   		CallLocalFunction( "OnPlayerTwistedDeath", "ddddddd", playerid, id, damagedid, vehicleid, missileid, GetVehicleModel(id), GetVehicleModel(vehicleid));
		if(!IsPlayerConnected(MPGetVehicleDriver(vehicleid)))
	   	{
		   	DestroyVehicle(vehicleid);
		}
	}
	pLastAttacked[id] = vehicleid;
	pLastAttackedMissile[id] = missileid;
	pLastAttackedTime[id] = GetTickCount();
	return 1;
}

CMD:groundz(playerid, params[])
{
	new Float:pl_pos[3], Float:x, Float:y;
    GetPlayerPos(playerid, pl_pos[0], pl_pos[1], pl_pos[2]);
	x = 5.0 * floatround(pl_pos[0] / 5.0);
	y = 5.0 * floatround(pl_pos[1] / 5.0);
	SendClientMessageFormatted(playerid, -1, "floatround(x): %d - floatround(y): %d - z: %0.2f", floatround(x), floatround(y), pl_pos[2]);
	return 1;
}

stock IsPointInPolygon(Float: point_X, Float: point_Y, { Float, _ }: ...)
{
    #define MAX_POINTS (32)

    new args_Total = numargs(), polygon_Sides = (args_Total - 2) / 2 ;
    if((args_Total - 2) & 0b1 || MAX_POINTS <= polygon_Sides || polygon_Sides < 3)
	{
	    printf("[System: IsPointInPolygon] - Fail - polygon_Sides: %d", polygon_Sides);
		return 0;
	}
    new Float: polygon_Data[2][MAX_POINTS], cross_Total ;
    #undef MAX_POINTS

    for(new i = 2, j; i < args_Total; i += 2, ++j)
    {
        polygon_Data[0][j] = Float: getarg(i);
        polygon_Data[1][j] = Float: getarg(i + 1);
    }
    for(new i, j = polygon_Sides - 1; i < polygon_Sides; j = i, ++i)
    {
        if(polygon_Data[1][i] < point_Y && polygon_Data[1][j] >= point_Y || polygon_Data[1][j] < point_Y && polygon_Data[1][i] >= point_Y)
        {
            if(polygon_Data[0][i] + (point_Y - polygon_Data[1][i]) / (polygon_Data[1][j] - polygon_Data[1][i]) * (polygon_Data[0][j] - polygon_Data[0][i]) < point_X)
            {
                cross_Total++;
            }
        }
    }
    return cross_Total & 0b1;
}

stock IsPointInArea(Float:x, Float:y, Float:minx, Float:maxx, Float:miny, Float:maxy)
{
    if (x > minx && x < maxx && y > miny && y < maxy) return 1;
    return 0;
}

static const stock Float:Hanger18_Points[20][2] =
{
	{-1732.9351, -611.5394}, // a
	{-1621.8508, -694.9910}, // b
	{-1227.5701, -694.4587}, // c
	{-1228.2415, -554.5089},
	{-1145.5831, -459.9896},
	{-1118.8612, -374.2502},
	{-1134.6113, -241.7159},
	{-1084.8250, -218.3002},
	{-1139.4792, -109.4554},
	{-1213.7091, -28.8316},
	{-1155.9581, 31.0298},
	{-1244.1909, 120.4091},
	{-1184.6167, 179.4770},
	{-1229.6351, 224.2526},
	{-1054.9166, 397.1960},
	{-1094.8671, 437.9679},
	{-1684.9160, -154.5242},
	{-1720.9116, -288.4950},
	{-1732.5011, -427.1551},
	{-1735.3436, -566.6928}
};

forward Float:GetMapLowestZ(mapid, Float:x, Float:y, Float:cZ, &whichaxis = 0);
stock Float:GetMapLowestZ(mapid, Float:x, Float:y, Float:cZ, &whichaxis = 0)
{
	new Float:z = 0.0;
	switch(mapid)
	{
	    case MAP_HANGER18:
	    {
	        new point = IsPointInPolygon(x, y,
						-1732.9351, -611.5394, // a
						-1621.8508, -694.9910, // b
						-1227.5701, -694.4587, // c
						-1228.2415, -554.5089,
						-1145.5831, -459.9896,
						-1118.8612, -374.2502,
						-1134.6113, -241.7159,
						-1084.8250, -218.3002,
						-1139.4792, -109.4554,
						-1213.7091, -28.8316,
						-1155.9581, 31.0298,
						-1244.1909, 120.4091,
						-1184.6167, 179.4770,
						-1229.6351, 224.2526,
						-1054.9166, 397.1960,
						-1094.8671, 437.9679,
						-1684.9160, -154.5242,
						-1720.9116, -288.4950,
						-1732.5011, -427.1551,
						-1735.3436, -566.6928);
	        if(!point)
	        {
	            z = cZ + 5.0; //printf("x: %0.2f - y: %0.2f - points: %d", x, y, point);
	        }
	        else
	        {
             	MapAndreas_FindZ_For2DCoord(x, y, z);
             	if( z > cZ )
             	{
             	    if(IsPointInPolygon(x, y,
				 	-1489.8970,-465.9743,
					-1420.2805,-421.4152,
				 	-1411.3307,-387.3859,
				 	-1395.1316,-387.4485,
				 	-1372.1550,-397.2090,
				 	-1372.1550,-405.7532,
				 	-1397.1353,-401.3542,
                    -1406.9679,-427.8992,
                    -1423.7266,-450.9918,
                    -1446.8057,-468.6593,
                    -1474.4912,-478.8586,
					-1488.5732,-481.0092))
					{
					    z = 5.50;
					}
					else if(IsPointInPolygon(x, y, -1461.7700,-215.3291,
					-1433.9153,-122.7020,
					-1376.2902,-144.7513,
					-1415.0918,-231.4165,
					-1425.9885,-227.3817,
					-1409.6709,-182.2987,
					-1433.5980,-173.5414,
					-1450.2328,-218.3726))
					{
					    z = 14.14;
					}
					else if(IsPointInPolygon(x, y, -1394.7711,-373.6178,
					-1396.8937,-358.8463,
					-1400.7649,-345.1499,
					-1406.5449,-332.7275,
					-1413.1406,-321.4689,
					-1437.8079,-297.7291,
					-1460.9878,-285.6641,
					-1488.3525,-279.7889,
					-1487.3295,-264.2761,
					-1455.9193,-271.1209,
					-1426.3719,-286.7276,
					-1401.9177,-311.2426,
					-1386.7657,-340.1027,
					-1379.5203,-371.9048))
					{
					    z = 6.0;
					}
             	}
	        }
		}
	    case MAP_DOWNTOWN:
		{
		    new Float:DowntownCantGoOutOfZAreas[1][6] = //MinX, MaxX, MinY, MaxY, MinZ, MaxZ
			{
			    {-2163.8215, -1869.5753, -1036.5284, -709.5605}
			};
		    for(new a = 0, da = sizeof(DowntownCantGoOutOfZAreas); a < da; a++)
		    {
			    if(!(x >= DowntownCantGoOutOfZAreas[a][0] && x <= DowntownCantGoOutOfZAreas[a][1]))
				{
	               	z = 50.0;
					if(x < DowntownCantGoOutOfZAreas[a][0])
	   			    {
	   			    	whichaxis = 2;
					}
					else if(x > DowntownCantGoOutOfZAreas[a][1])
					{
						whichaxis = 1;
					}
	               	break;
	   			}
	   			if(!(y >= DowntownCantGoOutOfZAreas[a][2] && y <= DowntownCantGoOutOfZAreas[a][3]))
	   			{
	   			    z = 50.0;
	   			    if(y < DowntownCantGoOutOfZAreas[a][2])
	   			    {
	   			    	whichaxis = 4;
					}
					else if(y > DowntownCantGoOutOfZAreas[a][3])
					{
						whichaxis = 3;
					}
	               	break;
	   			}
   			}
		    new Float:DowntownExcludingZAreas[5][6] = //MinX, MaxX, MinY, MaxY, MinZ, MaxZ
			{
			    {-1927.9543, -1885.1970, -1035.0299, -709.5599, 31.0, 43.0},
			    {-1983.9663, -1935.7401, -867.9561, -849.6713, 31.2188, 40.9494},
			    {-1964.5488, -1945.1086, -990.6176, -727.0721, 35.4, 40.9494},
			    {-1954.1730, -1937.0645, -1087.1028, -1016.8768, 31.2188, 40.9494},
			    {-1997.2842, -1978.7244, -1087.1028, -1016.8768, 31.2188, 40.9494}
			};
		    for(new a = 0, da = sizeof(DowntownExcludingZAreas); a < da; a++)
		    {
			    if(x >= DowntownExcludingZAreas[a][0] && x <= DowntownExcludingZAreas[a][1]
				&& y >= DowntownExcludingZAreas[a][2] && y <= DowntownExcludingZAreas[a][3]
				&& cZ >= DowntownExcludingZAreas[a][4] && cZ <= DowntownExcludingZAreas[a][5])
				{
	               	z = DowntownExcludingZAreas[a][4];
	               	break;
	   			}
   			}
   			if(z == 0.0)
   			{
   			    whichaxis = 3;
				MapAndreas_FindZ_For2DCoord(x, y, z);
				if(z == 0.0)
				{
				    z = GetMapZ(mapid);
				}
   			}
		}
		default: MapAndreas_FindZ_For2DCoord(x, y, z);
	}
	return z;
}

forward Float:MissileYSize();
stock Float:MissileYSize()
{
	return (1.40 + 0.05);
}

new debugmissiles = 0;

CMD:debugmissiles(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    debugmissiles = !debugmissiles;
	return 1;
}

new mu_id,
 	mu_objectid,
 	mu_vehicleid;
 	//mu_slot;

public MissileUpdate()
{
	foreach(Player, i)
	{
	    if(PlayerInfo[i][pSpawned] == 0) continue;
	    mu_id = GetPlayerVehicleID(i);
	    //for(mu_slot = 0; mu_slot < MAX_COMPLETE_SLOTS; mu_slot++)
	    foreach(pSlots_In_Use[i], mu_slot)
	    {
	        if(debugmissiles == 1)
	        {
	        	printf("%s mu_slot: %d", Playername(i), mu_slot);
	        }
		    mu_objectid = Vehicle_Missile[mu_id][mu_slot];
		    if(IsValidObject(mu_objectid))
		    {
		        if(Object_Type[mu_objectid] == -1)
				{
				    DestroyObject(Vehicle_Missile[mu_id][mu_slot]);
				    ResetMissile(Current_Vehicle[i], mu_slot);
				    //CallLocalFunction("Explode_Missile", "iiii", i, mu_id, mu_slot, missileid);
					continue;
				}
			    mu_vehicleid = Vehicle_Missile_Following[mu_id][mu_slot];
			    if(mu_vehicleid != INVALID_VEHICLE_ID)
			    {
				    if(GetVehicleModel(mu_vehicleid) == 0)
				    {
				        printf("vehicle %d is not valid anymore - resetting", mu_vehicleid);
				        Vehicle_Missile_Following[mu_id][mu_slot] = INVALID_VEHICLE_ID;
				    }
			    }
			    if( Object_OwnerEx[mu_objectid] != i ) // patch for: some sort of bug that causes the playerid owner to change
			    {
			        printf("[System Error: MissileUpdate] - Objectid: %d - Missileid: %d - pOwner: %d - vOwner: %d - slot: %d - i: %d - iv: %d", mu_objectid, Object_Type[mu_objectid], Object_OwnerEx[mu_objectid], Object_Owner[mu_objectid], mu_slot, i, Current_Vehicle[i]);
			        Object_OwnerEx[mu_objectid] = i;
			    }
			    CallLocalFunction("UpdateMissile", "iiiiii", Object_OwnerEx[mu_objectid], mu_id, mu_objectid, Object_Type[mu_objectid], mu_slot, mu_vehicleid);
			    switch(Object_Type[mu_objectid])
			    {
			        case Missile_Fire, Missile_Homing, Missile_Power, Missile_Stalker,
						Missile_RemoteBomb:
			        {
			            if(Vehicle_Missile_Reset_Fire_Time[mu_id] == 80 && mu_slot == Vehicle_Missile_Reset_Fire_Slot[mu_id])
						{
						    Vehicle_Missile_Reset_Fire_Time[mu_id] = 0;
						    pFiring_Missile[i] = 0;
						}
			            else Vehicle_Missile_Reset_Fire_Time[mu_id] -= 80;
			        }
			    }
			}
		    mu_objectid = Vehicle_Machine_Gun[mu_id][mu_slot];
		    if(IsValidObject(mu_objectid))
		    {
			    if( Object_OwnerEx[mu_objectid] != i ) // patch for: some sort of bug that causes the playerid owner to change
			    {
			        printf("[System Error: MissileUpdate] - Objectid: %d - Missileid: %d - pOwner: %d - vOwner: %d - slot: %d - i: %d - iv: %d", mu_objectid, Object_Type[mu_objectid], Object_OwnerEx[mu_objectid], Object_Owner[mu_objectid], mu_slot, i, Current_Vehicle[i]);
			        Object_OwnerEx[mu_objectid] = i;
			    }
			    CallLocalFunction("UpdateMissile", "iiiiii", Object_OwnerEx[mu_objectid], mu_id, mu_objectid, Object_Type[mu_objectid], mu_slot, INVALID_VEHICLE_ID);
			}
			if(!IsValidObject(Vehicle_Missile[mu_id][mu_slot]) && !IsValidObject(Vehicle_Machine_Gun[mu_id][mu_slot]))
			{
				mu_slot = EditPlayerSlot(i, mu_slot, PLAYER_MISSILE_SLOT_REMOVE);
			}
		}
	}
	return 1;
}

new missileobject = INVALID_OBJECT_ID,
	missileattachedobject = INVALID_OBJECT_ID;

CMD:testmissile(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
	if(IsValidObject(missileobject))
	{
	    DestroyObject(missileobject);
	}
	if(IsValidObject(missileattachedobject))
	{
	    DestroyObject(missileattachedobject);
	}
	new Float:oX, Float:oY, Float:oZ,
		Float:vX, Float:vY, Float:vZ,
		Float:angle, vehicleid, Float:oangle;
    vehicleid = GetPlayerVehicleID(vehicleid);
	GetVehiclePos(vehicleid, vX, vY, vZ);
	GetVehicleZAngle(vehicleid, angle);

	oX = vX;
	oY = vY;
	oZ = vZ;

	oX += ( 7.0 * floatsin( -angle, degrees ) );
	oY += ( 7.0 * floatcos( -angle, degrees ) );

	missileobject = CreateObject(Missile_Default_Object, oX, oY, oZ, 0.0, 0.0, (angle - 90.0));

	vX += ( 14.0 * floatsin( -angle, degrees ) );
	vY += ( 14.0 * floatcos( -angle, degrees ) );

    oangle = Angle2D( oX, oY, vX, vY );
    printf("oangle: %0.2f - angle: %0.2f", oangle, angle);
    oX += ( MissileYSize() * floatsin( -angle, degrees ) );
	oY += ( MissileYSize() * floatcos( -angle, degrees ) );

	missileattachedobject = CreateObject(19282, oX, oY, oZ, 0.0, 0.0, (angle - 90.0));
	return 1;
}

public UpdateMissile(playerid, id, objectid, missileid, slot, vehicleid)
{
	if(slot < 0 || slot >= MAX_MISSILE_SLOTS)
	{
	    printf("[System: UpdateMissile - Slot Error (Out Of Bounds)] - Slot: %d", slot);
	    return 1;
	}
	if(!IsValidObject(objectid))
	{
		SendClientMessageFormatted(playerid, -1, "objectid: %d - Invalid", objectid);
		return 1;
	}
	if(playerid < 0 || playerid >= MAX_PLAYERS || playerid == INVALID_VEHICLE_ID)
	{
	    printf("[System: UpdateMissile - playerid Error (Out Of Bounds)] - playerid: %d - missileid: %s(%d)", playerid, GetTwistedMissileName(missileid, missileid), missileid);
	    return 1;
	}
	if(missileid < 0 || missileid >= MAX_DAMAGEABLE_MISSILES)
	{
	    Object_Owner[objectid] = INVALID_VEHICLE_ID;
	  	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
	  	Object_Type[objectid] = Object_Slot[objectid] = -1;
	  	EditPlayerSlot(playerid, Object_Slot[objectid], PLAYER_MISSILE_SLOT_REMOVE);
	    DestroyObject(objectid);
	    printf("[System: UpdateMissile - missileid Error (Out Of Bounds)] - missileid: %s(%d)", GetTwistedMissileName(missileid, missileid), missileid);
	    return 1;
	}
	if(id < 0 || id > MAX_VEHICLES || id == INVALID_VEHICLE_ID)
	{
	    printf("[System: UpdateMissile - id Error (Out Of Bounds)] - id: %d - missileid: %s(%d)", id, GetTwistedMissileName(missileid, missileid), missileid);
	    return 1;
	}
	//if(missileid == Missile_Homing) printf("[System: UpdateMissile] - (%d, %d, %d, %s, %d, %d)", playerid, id, objectid, GetTwistedMissileName(missileid, missileid), slot, vehicleid);
  	//SendClientMessageFormatted(INVALID_PLAYER_ID, RED, "[System] - Playerid: %d - Objectid: %d - Missileid: %d", playerid, objectid, missileid);
	new Float:x, Float:y, Float:z, Float:mZ, axis, Float:s_oX, Float:s_oY, Float:s_oZ,
		Float:vX, Float:vY, Float:vZ, Float:oX, Float:oY, Float:oZ,
		Float:sX, Float:sY, Float:sZ,model, Float:tindex, Float:abetweenobjectandvehicle,
		player;
	switch(missileid)
	{
	    case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade: GetObjectPos(Vehicle_Machine_Gun[id][slot], s_oX, s_oY, s_oZ);
		case Energy_Mines:
		{
		    GetObjectPos(Vehicle_Missile[id][slot], s_oX, s_oY, s_oZ);
		    s_oZ += 0.75;
		}
		default: GetObjectPos(Vehicle_Missile[id][slot], s_oX, s_oY, s_oZ);
	}
	oX = s_oX;
    oY = s_oY;
    oZ = s_oZ;
	mZ = GetMapLowestZ(gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], oX, oY, oZ, axis);
	if(mZ > oZ)
	{
	    switch(missileid)
	    {
	        case Missile_Ricochet:
	        {
	            new Float:angle, Float:rangle;
       			GetObjectRot(objectid, angle, angle, angle);
          		switch(axis)
                {
                    case 1, 2: rangle = (360.0 - angle - 10.0);
                    case 3, 4: rangle = (360.0 - angle - 180.0);
                }
                MPClamp360(rangle);
				oX += (150.0 * floatsin(-rangle, degrees));
              	oY += (150.0 * floatcos(-rangle, degrees));
              	StopObject(objectid);
              	MoveObject(objectid, oX, oY, oZ, MISSILE_SPEED);
            }
            case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
            {
                if(IsValidObject(Vehicle_Machine_Gun[id][slot]))
                {
	                Object_Owner[Vehicle_Machine_Gun[id][slot]] = INVALID_VEHICLE_ID;
		  			Object_OwnerEx[Vehicle_Machine_Gun[id][slot]] = INVALID_PLAYER_ID;
		  			Object_Type[Vehicle_Machine_Gun[id][slot]] = Object_Slot[Vehicle_Machine_Gun[id][slot]] = -1;
                    DestroyObject(Vehicle_Machine_Gun[id][slot]);
				}
                if(IsValidObject(Vehicle_Machine_Mega_Gun[id][slot])) DestroyObject(Vehicle_Machine_Mega_Gun[id][slot]);
            	return 1;
            }
	        default:
	        {
	 		    CallLocalFunction("Explode_Missile", "iiii", playerid, id, slot, missileid);
 		    }
	    }
	    return 1;
	}
	foreach(Vehicles, v)
	{
	    if(v > MAX_VEHICLES)
	    {
	        continue;
	    }
	    if(id == v) continue;
	    model = GetVehicleModel(v);
	    if(!model) continue;
	    if(!GetVehiclePos(v, vX, vY, vZ)) continue;
	    player = MPGetVehicleDriver(v);
        if(player != INVALID_VEHICLE_ID)
        {
	        switch(gGameData[PlayerInfo[player][gGameID]][g_Gamemode])
	        {
	            case TEAM_DEATHMATCH, TEAM_HUNTED, TEAM_LAST_MAN_STANDING:
	            {
					if(PlayerInfo[playerid][gTeam] == PlayerInfo[player][gTeam]) continue;
				}
			}
		}
	    switch(missileid)
	    {
	        case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
	        {
	            oX = s_oX;
			    oY = s_oY;
			    oZ = s_oZ;
			    abetweenobjectandvehicle = Angle2D( oX, oY, vX, vY );
		 	    oX += ( 0.10 * floatsin( -abetweenobjectandvehicle, degrees ) );
				oY += ( 0.10 * floatcos( -abetweenobjectandvehicle, degrees ) );
				oX -= vX;
				oY -= vY;
				oZ -= vZ;
				GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, vX, vY, vZ); //vX *= 0.8; //vY *= 0.8;
			 	vZ *= 0.8;
			 	tindex = ((oX * oX) + (oY * oY) + (oZ * oZ));
				if((-vX < oX < vX) && (-vY < oY < vY) && (-vZ < oZ < vZ) || tindex < (4.0))
				{
	        		Object_Owner[Vehicle_Machine_Gun[id][slot]] = INVALID_VEHICLE_ID;
		  			Object_OwnerEx[Vehicle_Machine_Gun[id][slot]] = INVALID_PLAYER_ID;
		  			Object_Type[Vehicle_Machine_Gun[id][slot]] = Object_Slot[Vehicle_Machine_Gun[id][slot]] = -1;
                    DestroyObject(Vehicle_Machine_Gun[id][slot]);
					DamagePlayer(playerid, id, MPGetVehicleDriver(v), v, GetMissileDamage(missileid), missileid);
	        		if(IsValidObject(Vehicle_Machine_Mega_Gun[id][slot])) DestroyObject(Vehicle_Machine_Mega_Gun[id][slot]);
	            	return 1;
	 			}
	 			else continue;
	        }
	        case Energy_Mines:
	        {
	            oX = s_oX;
			    oY = s_oY;
			    oZ = s_oZ;
				oX -= vX;
				oY -= vY;
				oZ -= vZ;
				GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ); //vX *= 0.8; //vY *= 0.8;
				sZ *= 0.8;
			 	tindex = ((oX * oX) + (oY * oY) + (oZ * oZ));
				if((-sX < oX < sX) && (-sY < oY < sY) || tindex < (4.0))
				{
				    if((oZ > (sZ / 2.0) + 0.3))
					{
					    continue;
					}
				    CreateMissileExplosion(id, missileid, x, y, z, _);
	        		Object_Owner[Vehicle_Missile[id][slot]] = INVALID_VEHICLE_ID;
		  			Object_OwnerEx[Vehicle_Missile[id][slot]] = INVALID_PLAYER_ID;
		  			Object_Type[Vehicle_Missile[id][slot]] = Object_Slot[Vehicle_Missile[id][slot]] = -1;
                    DestroyObject(Vehicle_Missile[id][slot]);
					DamagePlayer(playerid, id, MPGetVehicleDriver(v), v, GetMissileDamage(missileid), missileid);
	        		if(IsValidObject(Vehicle_Smoke[id][slot]))
					{
					 	DestroyObject(Vehicle_Smoke[id][slot]);
					}
	            	return 1;
	 			}
	 			else continue;
	        }
	        default:
	        {
	            oX = s_oX;
			    oY = s_oY;
			    oZ = s_oZ;
		 	    abetweenobjectandvehicle = Angle2D( oX, oY, vX, vY );
		 	    oX += ( MissileYSize() * floatsin( -abetweenobjectandvehicle, degrees ) );
	   			oY += ( MissileYSize() * floatcos( -abetweenobjectandvehicle, degrees ) );
	   			x = oX;
		 	    y = oY;
		 	    z = oZ;
				oX -= vX;
				oY -= vY;
				oZ -= vZ;
				GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, vX, vY, vZ); //vX *= 0.8; //vY *= 0.8;
			 	vZ *= 0.7;
			 	tindex = ((oX * oX) + (oY * oY) + (oZ * oZ));
				if((-vX < oX < vX) && (-vY < oY < vY) && (-vZ < oZ < vZ) || tindex < (4.0))
				{
				    if(IsValidObject(Vehicle_Missile[id][slot]))
					{
					    //SendClientMessageFormatted(playerid, -1, "UpdateMissile: %d", Vehicle_Missile[id][slot]);
					    Object_Owner[Vehicle_Missile[id][slot]] = INVALID_VEHICLE_ID;
		  				Object_OwnerEx[Vehicle_Missile[id][slot]] = INVALID_PLAYER_ID;
		  				Object_Type[Vehicle_Missile[id][slot]] = Object_Slot[Vehicle_Missile[id][slot]] = -1;
						DestroyObject(Vehicle_Missile[id][slot]);
	   				}
					switch(missileid)
			  		{
			  		    case Energy_EMP:
			  		    {
			  		        new frozen = player;
			  		        if(frozen != INVALID_VEHICLE_ID)
			  		        {
				  		        format(Global_KSXPString, sizeof(Global_KSXPString), "~g~~h~Frozen By %s", Playername(playerid));
								AddEXPMessage(frozen, Global_KSXPString);
								format(Global_KSXPString, sizeof(Global_KSXPString), "~y~~h~Froze %s", Playername(frozen));
								AddEXPMessage(playerid, Global_KSXPString);
								SetVehicleVelocity(v, 0.0, 0.0, 0.0);
								SetVehicleAngularVelocity(v, 0.005, 0.005, 0.0);
								TogglePlayerControllable(frozen, false);
								EMPTime[frozen] = 4;
							}
			  		    }
			  		    case Missile_Ricochet:
			  		    {
			  		        new tid = GetPVarInt(playerid, "Ricochet_Missile_Timer");
			  		        KillTimer(tid);
			  		    }
						case Missile_RemoteBomb:
			  		    {
			  		       	CallRemoteFunction("OnRemoteBombHitVehicle", "iiiiiffffff", playerid, id, v, objectid, slot, x, y, z, s_oX, s_oY, s_oZ);
		    				return 1;
			  		    }
						case Missile_Special:
						{
						    switch(GetVehicleModel(id))
						    {
								case Reaper:
								{
								    CreateMissileExplosion(id, missileid, x, y, z, PlayerInfo[playerid][pSpecial_Using_Alt]);
									DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid, id, PlayerInfo[playerid][pSpecial_Using_Alt]), missileid, PlayerInfo[playerid][pSpecial_Using_Alt]);
						            pFiring_Missile[playerid] = 0;
						            Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
								    if(PlayerInfo[playerid][pSpecial_Using_Alt] == 2)
								    {
									    for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
										{
										    if(Vehicle_Missile_Lights_Attached[id][L] != slot) continue;
										 	if(IsValidObject(Vehicle_Missile_Lights[id][L]))
									  		{
											  	DestroyObject(Vehicle_Missile_Lights[id][L]);
											}
									 	}
								 	}
								 	PlayerInfo[playerid][pSpecial_Using_Alt] = 0;
								    return 1;
								}
								case Brimstone:
								{
								    CallRemoteFunction("OnBrimstoneFollowerHitVehicle", "iiiiifff", playerid, id, v, objectid, slot, x, y, z);
								    return 1;
								}
								case Sweet_Tooth:
								{
								    CreateMissileExplosion(id, missileid, x, y, z, _);
									DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid, id), missileid);
						            Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
									new left = GetPVarInt(playerid, "Firing_Sweet_Tooth_Special") - 1;
						            SetPVarInt(playerid, "Firing_Sweet_Tooth_Special", left);
						            if(left == 0)
						            {
						                pFiring_Missile[playerid] = 0;
						            }
									return 1;
								}
							}
						}
						case Missile_Napalm:
						{
						    z -= 1.95;
						}
					}
					CreateMissileExplosion(id, missileid, x, y, z, _);
					DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid, id), missileid, gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]);
                    pFiring_Missile[playerid] = 0;
		            Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
		            if(IsValidObject(Vehicle_Smoke[id][slot]))
					{
					 	DestroyObject(Vehicle_Smoke[id][slot]);
					}
		            for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
					{
					    if(Vehicle_Missile_Lights_Attached[id][L] != slot) continue;
					 	if(IsValidObject(Vehicle_Missile_Lights[id][L]))
				  		{
						  	DestroyObject(Vehicle_Missile_Lights[id][L]);
						}
				 	}
				 	return 1;
				}
	        }
	    }
	}
	switch(missileid)
	{
	    case Missile_Napalm:
		{
		    new Float:attachz;
		    attachz = -(s_oZ - mZ) + 0.7;
		    TargetCircle(TARGET_CIRCLE_ATTACHING, Vehicle_Missile[id][slot], slot, id, attachz, s_oX, s_oY, s_oZ);
		}
	}
	if(vehicleid != INVALID_VEHICLE_ID)
	{
		/*
		new Float:distance, Float:tolerancex, Float:tolerancey, Float:tz;
		distance = MPFDistance(x, y, z, ompos[0], ompos[1], ompos[2]);
		if(distance > 8.0)
		{
			tz = floatdiv(distance, 2.0);
			tolerancex = floatsub( floatrand(0.0, tz ), floatdiv(tz, 2.0) );
			tolerancey = floatsub( floatrand(0.0, tz ), floatdiv(tz, 2.0) );
		 	x += tolerancex;
	 		y += tolerancey;
		 	SendClientMessageFormatted(playerid, -1, "tolerancex: %0.2f - tolerancey: %0.2f", tolerancex, tolerancey);
		}
		*/
		//printf("%s(%d)'s %s missile being homed to vehicleid: %d", Playername(playerid), playerid, GetTwistedMissileName(missileid, missileid), vehicleid);
		new Float:ompos[3], Float:Old_Missile_Angle, Float:newangle, Float:difference;
	    GetVehiclePos(vehicleid, x, y, z);
		GetObjectPos(objectid, ompos[0], ompos[1], ompos[2]);
		GetObjectRot(objectid, Old_Missile_Angle, Old_Missile_Angle, Old_Missile_Angle);

		newangle = Angle2D( ompos[0], ompos[1], x, y ) - 90;
		difference = (newangle - Old_Missile_Angle);
		//if(difference < 0.0) difference *= -1;
		//printf("%s difference: %0.2f", GetTwistedMissileName(missileid), difference);
		if(difference < GetTwistedMetalMissileAccuracy(playerid, missileid, GetVehicleModel(id), PlayerInfo[playerid][pSpecial_Using_Alt]))
		{
			SetObjectRot(objectid, 0.0, 0.0, newangle);
			MoveObject(objectid, x, y, z, MISSILE_SPEED, 0.0, 0.0, newangle);
			switch(missileid)
			{
			    case Missile_Fire, Missile_Homing:
			    {
			        for(new light_slot = 0; light_slot < MAX_MISSILE_LIGHTS; light_slot ++)
		            {
		                if(Vehicle_Missile_Lights_Attached[id][light_slot] == slot)
		                {
		                    AttachObjectToObject(Vehicle_Missile_Lights[id][light_slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (newangle - 90.0) - newangle, 1);
		                }
		            }
			    }
			}
		}
		else Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
	}
	return 1;
}

forward OnRemoteBombHitVehicle(playerid, vehicleid, vehicle, Bomb, Float:x, Float:y, Float:z, Float:objectX, Float:objectY, Float:objectZ);
public OnRemoteBombHitVehicle(playerid, vehicleid, vehicle, Bomb, Float:x, Float:y, Float:z, Float:objectX, Float:objectY, Float:objectZ)
{
	Bomb = CreateObject(Missile_Napalm_Object, x, y, z, 0.0, 0.0, 95.0, 250.0);
	x -= objectX;
	y -= objectY;
	z -= objectZ;
    AttachObjectToVehicle(Bomb, vehicle, x, y, z, 0.0, 0.0, 95.0);
    SetTimerEx("ExplodeRemoteBomb", 2500, false, "iiiifff", playerid, vehicleid, vehicle, Bomb, x, y, z);
	pFiring_Missile[playerid] = 0;
 	return 1;
}

forward ExplodeRemoteBomb(playerid, myvid, vehicle, objectid, Float:offsetX, Float:offsetY, Float:offsetZ);
public ExplodeRemoteBomb(playerid, myvid, vehicle, objectid, Float:offsetX, Float:offsetY, Float:offsetZ)
{
    new Float:x, Float:y, Float:z;
	GetVehiclePos(objectid, x, y, z);
	x += (offsetX * floatsin(-95.0, degrees));
	y += (offsetY * floatsin(-95.0, degrees));
	z += offsetZ;
    CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(Missile_RemoteBomb));
    DamagePlayer(playerid, myvid, MPGetVehicleDriver(vehicle), vehicle, GetMissileDamage(Missile_RemoteBomb, myvid), Missile_RemoteBomb);
    Object_Owner[objectid] = INVALID_VEHICLE_ID;
	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
	Object_Type[objectid] = Object_Slot[objectid] = -1;
	EditPlayerSlot(playerid, Object_Slot[objectid], PLAYER_MISSILE_SLOT_REMOVE);
	DestroyObject(objectid);
	return 1;
}

//1654 - dynamite
//2036 - fake sniper
//2469 2470 2510 2511 - fake planes
stock SetObjectRotEx(iObjID, Float: fRX, Float: fRY, Float: fRZ, Float: fSpeed)
{
    new Float: fX, Float: fY, Float: fZ ;
    if(GetObjectPos(iObjID, fX, fY, fZ))
    {
        return MoveObject(iObjID, fX, fY, fZ + 0.001, fSpeed, fRX, fRY, fRZ);
    }
    return 0;
}

stock PointInRangeOfPoint(Float:x, Float:y, Float:z, Float:x2, Float:y2, Float:z2, Float:range)
{
    x2 -= x; y2 -= y; z2 -= z;
    return ((x2 * x2) + (y2 * y2) + (z2 * z2)) < (range * range);
}

CMD:resetworldbounds(playerid, params[])
{
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	return 1;
}

CMD:attachv(playerid, params[])
{
	new vehicleid;
	if(sscanf(params, "i", vehicleid)) return 1;
	AttachTrailerToVehicle(vehicleid, Current_Vehicle[playerid]);
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
    T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid)));
    SetVehicleHealth(vehicleid, MAX_VEHICLE_MAX);
	if(!Iter_Contains(Vehicles, vehicleid))
	{
		Iter_Add(Vehicles, vehicleid);
	}
	SetVehicleParamsEx(vehicleid, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF);
	return 1;
}

//forward Sync_Vehicle_Spawning(vehicleid); public Sync_Vehicle_Spawning(vehicleid){ return 1; }

public OnVehicleDeath(vehicleid, killerid)
{
	if(Iter_Contains(Vehicles, vehicleid))
	{
	    new next;
		Iter_SafeRemove(Vehicles, vehicleid, next);
	}
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
    if(GetPVarInt(forplayerid, "Junkyard_Dog_Attach") == PlayerInfo[forplayerid][pSpecial_Missile_Vehicle])
    {
        AttachTrailerToVehicle(PlayerInfo[forplayerid][pSpecial_Missile_Vehicle], GetPlayerVehicleID(forplayerid));
    }
    if(Current_Vehicle[forplayerid] == vehicleid)
	{
		if(!IsPlayerInVehicle(forplayerid, Current_Vehicle[forplayerid]))
	 	{
	 	    if(PlayerInfo[forplayerid][CanExitVeh] == 0)
	 	    {
				if(GetPlayerState(forplayerid) == PLAYER_STATE_ONFOOT)
				{
			    	PutPlayerInVehicle(forplayerid, Current_Vehicle[forplayerid], 0);
			    	SetCameraBehindPlayer(forplayerid);
			    }
		    }
		}
	}
    return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
    return 1;
}

new legalmods[48][22] = {
    {400, 1024,1021,1020,1019,1018,1013,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {401, 1145,1144,1143,1142,1020,1019,1017,1013,1007,1006,1005,1004,1003,1001,0000,0000,0000,0000},
    {404, 1021,1020,1019,1017,1016,1013,1007,1002,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {405, 1023,1021,1020,1019,1018,1014,1001,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {410, 1024,1023,1021,1020,1019,1017,1013,1007,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000},
    {415, 1023,1019,1018,1017,1007,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {418, 1021,1020,1016,1006,1002,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {420, 1021,1019,1005,1004,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {421, 1023,1021,1020,1019,1018,1016,1014,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {422, 1021,1020,1019,1017,1013,1007,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {426, 1021,1019,1006,1005,1004,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {436, 1022,1021,1020,1019,1017,1013,1007,1006,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000},
    {439, 1145,1144,1143,1142,1023,1017,1013,1007,1003,1001,0000,0000,0000,0000,0000,0000,0000,0000},
    {477, 1021,1020,1019,1018,1017,1007,1006,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {478, 1024,1022,1021,1020,1013,1012,1005,1004,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {489, 1024,1020,1019,1018,1016,1013,1006,1005,1004,1002,1000,0000,0000,0000,0000,0000,0000,0000},
    {491, 1145,1144,1143,1142,1023,1021,1020,1019,1018,1017,1014,1007,1003,0000,0000,0000,0000,0000},
    {492, 1016,1006,1005,1004,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {496, 1143,1142,1023,1020,1019,1017,1011,1007,1006,1003,1002,1001,0000,0000,0000,0000,0000,0000},
    {500, 1024,1021,1020,1019,1013,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {516, 1021,1020,1019,1018,1017,1016,1015,1007,1004,1002,1000,0000,0000,0000,0000,0000,0000,0000},
    {517, 1145,1144,1143,1142,1023,1020,1019,1018,1017,1016,1007,1003,1002,0000,0000,0000,0000,0000},
    {518, 1145,1144,1143,1142,1023,1020,1018,1017,1013,1007,1006,1005,1003,1001,0000,0000,0000,0000},
    {527, 1021,1020,1018,1017,1015,1014,1007,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {529, 1023,1020,1019,1018,1017,1012,1011,1007,1006,1003,1001,0000,0000,0000,0000,0000,0000,0000},
    {534, 1185,1180,1179,1178,1127,1126,1125,1124,1123,1122,1106,1101,1100,0000,0000,0000,0000,0000},
    {535, 1121,1120,1119,1118,1117,1116,1115,1114,1113,1110,1109,0000,0000,0000,0000,0000,0000,0000},
    {536, 1184,1183,1182,1181,1128,1108,1107,1105,1104,1103,0000,0000,0000,0000,0000,0000,0000,0000},
    {540, 1145,1144,1143,1142,1024,1023,1020,1019,1018,1017,1007,1006,1004,1001,0000,0000,0000,0000},
    {542, 1145,1144,1021,1020,1019,1018,1015,1014,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {546, 1145,1144,1143,1142,1024,1023,1019,1018,1017,1007,1006,1004,1002,1001,0000,0000,0000,0000},
    {547, 1143,1142,1021,1020,1019,1018,1016,1003,1000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {549, 1145,1144,1143,1142,1023,1020,1019,1018,1017,1012,1011,1007,1003,1001,0000,0000,0000,0000},
    {550, 1145,1144,1143,1142,1023,1020,1019,1018,1006,1005,1004,1003,1001,0000,0000,0000,0000,0000},
    {551, 1023,1021,1020,1019,1018,1016,1006,1005,1003,1002,0000,0000,0000,0000,0000,0000,0000,0000},
    {558, 1168,1167,1166,1165,1164,1163,1095,1094,1093,1092,1091,1090,1089,1088,0000,0000,0000,0000},
    {559, 1173,1162,1161,1160,1159,1158,1072,1071,1070,1069,1068,1067,1066,1065,0000,0000,0000,0000},
    {560, 1170,1169,1141,1140,1139,1138,1033,1032,1031,1030,1029,1028,1027,1026,0000,0000,0000,0000},
    {561, 1157,1156,1155,1154,1064,1063,1062,1061,1060,1059,1058,1057,1056,1055,1031,1030,1027,1026},
    {562, 1172,1171,1149,1148,1147,1146,1041,1040,1039,1038,1037,1036,1035,1034,0000,0000,0000,0000},
    {565, 1153,1152,1151,1150,1054,1053,1052,1051,1050,1049,1048,1047,1046,1045,0000,0000,0000,0000},
    {567, 1189,1188,1187,1186,1133,1132,1131,1130,1129,1102,0000,0000,0000,0000,0000,0000,0000,0000},
    {575, 1177,1176,1175,1174,1099,1044,1043,1042,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {576, 1193,1192,1191,1190,1137,1136,1135,1134,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {580, 1023,1020,1018,1017,1007,1006,1001,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {589, 1145,1144,1024,1020,1018,1017,1016,1013,1007,1006,1005,1004,1000,0000,0000,0000,0000,0000},
    {600, 1022,1020,1018,1017,1013,1007,1006,1005,1004,0000,0000,0000,0000,0000,0000,0000,0000,0000},
    {603, 1145,1144,1143,1142,1024,1023,1020,1019,1018,1017,1007,1006,1001,0000,0000,0000,0000,0000}
};

iswheelmodel(modelid) {
    new wheelmodels[17] = {1025,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1096,1097,1098};
    for(new wm; wm < sizeof(wheelmodels); wm++) {
        if (modelid == wheelmodels[wm])
            return true;
    }
    return false;
}

IllegalCarNitroIde(carmodel) {
    new illegalvehs[29] = { 581, 523, 462, 521, 463, 522, 461, 448, 468, 586, 509, 481, 510, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454, 590, 569, 537, 538, 570, 449 };
    for(new iv; iv < sizeof(illegalvehs); iv++) {
        if (carmodel == illegalvehs[iv])
            return true;
    }
    return false;
}

stock islegalcarmod(vehicleide, componentid) {
    new modok = false;
    if ( (iswheelmodel(componentid)) || (componentid == 1086) || (componentid == 1087) || ((componentid >= 1008) && (componentid <= 1010))) {
        new nosblocker = IllegalCarNitroIde(vehicleide);
        if (!nosblocker)
            modok = true;
    } else {
        for(new lm; lm < sizeof(legalmods); lm++) {
            if (legalmods[lm][0] == vehicleide) {
                for(new J = 1; J < 22; J++) {
                    if (legalmods[lm][J] == componentid)
                        modok = true;
                }
            }
        }
    }
    return modok;
}

public OnVehicleMod(playerid, vehicleid, componentid) {
    new vehicleide = GetVehicleModel(vehicleid);
    new mod_ok = islegalcarmod(vehicleide, componentid);
    if (!mod_ok) {
    	printf("[System: OnVehicleMod - Warning] Name: %s(%d) - Vehicleid: %d - Model: %d - Componentid: %d", Playername(playerid), playerid, vehicleid, vehicleide, componentid);
    	MessageToAdmins(COLOR_ADMIN, "[System: invalid mod] %s(%d) - v: %d(%d) - c: %d", pName[playerid], playerid, vehicleid, vehicleide, componentid);
		//strins(string, "10", 0, sizeof(string));
		//IRC_GroupSay(gGroupID, ADMIN_IRC_CHANNEL, string);
        RemoveVehicleComponent(vehicleid, componentid);
        if(!GetPVarInt(playerid, "c_Invalid_Mods_Time"))
        {
            SetPVarInt(playerid, "c_Invalid_Mods_Time", GetTickCount());
        }
        SetPVarInt(playerid, "c_Invalid_Mods", GetPVarInt(playerid, "c_Invalid_Mods") + 1);
    	if(GetPVarInt(playerid, "c_Invalid_Mods") > 3 && (GetTickCount() - GetPVarInt(playerid, "c_Invalid_Mods_Time")) > 250)
     	{
     	    DeletePVar(playerid, "c_Invalid_Mods_Time");
     	    format(GlobalString, sizeof(GlobalString), "SERVER BAN: %s(%d) Has Been Banned From The Server - Reason: Vehicle Mods Hack.", Playername(playerid), playerid);
			SendClientMessageToAll(PINK, GlobalString);
			//IRC_GroupSay(gGroupID, ECHO_IRC_CHANNEL, GlobalString);
			//IRC_GroupSay(gGroupID, ADMIN_IRC_CHANNEL, GlobalString);
			SendClientMessage(playerid, -1, "You Have Been Banned For Attempting To Hack Vehicle Modifications");
			BanEx(playerid, "Vehicle Mods Hack");
     	}
		return 0;
	}
    return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    PlayerInfo[playerid][pLastVeh] = vehicleid;
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(!PlayerInfo[playerid][CanExitVeh])
	{
		SetTimerEx("PutPlayerBackInVehicle", 50, false, "ii", playerid, vehicleid);
		print("[System: OnPlayerExitVehicle] - Putting back in vehicle");
	}
	printf("[System: OnPlayerExitVehicle] - playerid: %d - vehicleid: %d", playerid, vehicleid);
	return 1;
}
forward PutPlayerBackInVehicle(playerid, vehicleid);
public PutPlayerBackInVehicle(playerid, vehicleid)
{
    PutPlayerInVehicle(playerid, vehicleid, 0);
    UpdatePlayerHUD(playerid);
	return 1;
}

public OnVehicleFire(playerid, vehicleid, slot, missileid, objectid)
{
    //SendClientMessageFormatted(playerid, -1, "OnVehicleFire: %d (objectid: %d) - slot: %d", Vehicle_Missile[vehicleid][slot], objectid, slot);
	//printf("[System: OnVehicleFire] - Vehicleid: %d - Slot: %d - Missile: %s", vehicleid, slot, GetTwistedMissileName(missileid));
    //PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Missile_Sound.mp3");
	new connected = IsPlayerConnected(playerid);
	if(missileid < MAX_MISSILEID && connected)
	{
		switch(missileid)
	    {
	        case Missile_Fire, Missile_Homing, Missile_Power, Missile_Stalker,
				Missile_RemoteBomb:
	        {
	            pFiring_Missile[playerid] = 1;
	            Vehicle_Missile_Reset_Fire_Time[vehicleid] = 640;
	            Vehicle_Missile_Reset_Fire_Slot[vehicleid] = slot;
	        }
			case Missile_Napalm:
			{
			    GameTextForPlayer(playerid, "~n~~n~~w~Click ~p~~k~~VEHICLE_FIREWEAPON_ALT~ ~w~To Bring Down The Gas Can", 2000, 3);
			}
			case Missile_Special:
        	{
        	    switch(GetVehicleModel(vehicleid))
			    {
			        case Warthog_TM3:
			        {
					    if(PlayerInfo[playerid][pSpecial_Missile_Update] == 3)
						{
							PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
						}
						return 1;
			    	}
			        case Roadkill:
			        {
					    if(PlayerInfo[playerid][pSpecial_Missile_Update] == 6)
						{
							PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
						}
						return 1;
			    	}
			        case Sweet_Tooth:
			        {
					    if(PlayerInfo[playerid][pSpecial_Missile_Update] == 20)
						{
							PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
						}
						return 1;
					}
				}
			}
		}
		if(PlayerInfo[playerid][pMissiles][missileid] <= 0)
		{
            pMissileid[playerid] = GetNextHUDSlot(playerid);
		}
		UpdatePlayerHUD(playerid);
	}
	return 1;
}
forward Charge_Missile(playerid, id, missileid);
public Charge_Missile(playerid, id, missileid)
{
	if(PlayerInfo[playerid][pCharge_Index] <= 0.0)
	{
	    KillTimer(PlayerInfo[playerid][pCharge_Timer]);
	    return 1;
	}
    PlayerInfo[playerid][pCharge_Index] -= 1.0;
    SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], PlayerInfo[playerid][pCharge_Index]);
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
	return 1;
}

forward OnVehicleMissileChange(vehicleid, oldmissile, newmissile, playerid);
public OnVehicleMissileChange(vehicleid, oldmissile, newmissile, playerid)
{
    if(PlayerInfo[playerid][pMissiles][newmissile] > 0)
    {
		switch(pHUDStatus[playerid])
		{
		    case HUD_ENERGY: newmissile -= ENERGY_WEAPONS_INDEX;
		}
		if(oldmissile >= ENERGY_WEAPONS_INDEX)
		{
			oldmissile -= ENERGY_WEAPONS_INDEX;
		}
        PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][newmissile], 0x00FF00FF);
        PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileSign][newmissile]);
        PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][oldmissile], 100);
        switch(newmissile)
        {
            case Missile_Stalker:
            {
                SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], DEFAULT_CHARGE_INDEX);
                ShowPlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
            }
        }
        switch(oldmissile)
        {
            case Missile_Stalker:
            {
			    HidePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
			    SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], DEFAULT_CHARGE_INDEX);
			}
        }
    }
    if(PlayerInfo[playerid][pMissile_Charged] == oldmissile)
 	{
 	    pFiring_Missile[playerid] = 0;
 	    PlayerInfo[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
 	    KillTimer(PlayerInfo[playerid][pCharge_Timer]);
 	}
    UpdatePlayerHUD(playerid);
    //SendClientMessageFormatted(playerid, -1, "New Missile: %s - Ammo: %d - Missileid: %d - Old Missile: %s", GetTwistedMissileName(newmissile, newmissile), PlayerInfo[playerid][pMissiles][newmissile], newmissile, GetTwistedMissileName(oldmissile, oldmissile));
	if(PlayerInfo[playerid][pMissile_Charged] != -1 || PlayerInfo[playerid][pMissile_Special_Time] != 0)
	{
		PlayerInfo[playerid][pMissile_Special_Time] = 0;
		PlayerInfo[playerid][pMissile_Charged] = -1;
	}
	if(pFiring_Missile[playerid] == Reaper)
	{
	    pFiring_Missile[playerid] = 0;
	    RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Index);
	    if(PlayerInfo[playerid][pSpecial_Using_Alt] == 1)
	    {
	    	RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Flame_Index);
	    	PlayerInfo[playerid][pSpecial_Using_Alt] = 0;
		}
		GameTextForPlayer(playerid, " ", 1, 3);
	}
	return 1;
}

stock ResetMissile(vehicleid, slot)
{
    if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
	{
		DestroyObject(Vehicle_Smoke[vehicleid][slot]);
	}
	for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
	{
	    if(Vehicle_Missile_Lights_Attached[vehicleid][L] != slot) continue;
	 	if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
  		{
		  	DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
		}
 	}
	Vehicle_Missile_Reset_Fire_Time[vehicleid] = 0;
	Vehicle_Missile_Reset_Fire_Slot[vehicleid] = -1;
	if(Vehicle_Missile_Following[vehicleid][slot] != INVALID_VEHICLE_ID)
	{
		Vehicle_Missile_Following[vehicleid][slot] = INVALID_VEHICLE_ID;
	}
	return 1;
}

public Explode_Missile(playerid, vehicleid, slot, missileid)
{
    //printf("[System: Explode_Missile] - playerid: %d - vehicleid: %d - slot: %d - missileid: %s", playerid, vehicleid, slot, GetTwistedMissileName(missileid));
    switch(missileid)
    {
        case Missile_Special:
        {
		    switch(GetVehicleModel(vehicleid))
		    {
		        case Sweet_Tooth:
		        {
		            new left = GetPVarInt(playerid, "Firing_Sweet_Tooth_Special") - 1;
		            SetPVarInt(playerid, "Firing_Sweet_Tooth_Special", left);
		            if(left == 0)
		            {
		                pFiring_Missile[playerid] = 0;
		            }
		        }
		        default: pFiring_Missile[playerid] = 0;
		    }
    	}
    	default: pFiring_Missile[playerid] = 0;
    }
   	if(vehicleid == INVALID_VEHICLE_ID) return 1;
	new Float:x, Float:y, Float:z;
	if(IsValidObject(Vehicle_Missile[vehicleid][slot]))
	{
	    GetObjectPos(Vehicle_Missile[vehicleid][slot], x, y, z);
	    z -= 1.8;
	    //SendClientMessageFormatted(playerid, -1, "Explode_Missile: %d - slot: %d", Vehicle_Missile[vehicleid][slot], slot);
	    Object_Owner[Vehicle_Missile[vehicleid][slot]] = INVALID_VEHICLE_ID;
		Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = INVALID_PLAYER_ID;
		Object_Type[Vehicle_Missile[vehicleid][slot]] = Object_Slot[Vehicle_Missile[vehicleid][slot]] = -1;
		DestroyObject(Vehicle_Missile[vehicleid][slot]);
	}
	if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
	{
		DestroyObject(Vehicle_Smoke[vehicleid][slot]);
	}
	for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
	{
	    if(Vehicle_Missile_Lights_Attached[vehicleid][L] != slot) continue;
	 	if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
  		{
		  	DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
		}
 	}
 	Vehicle_Missile_Reset_Fire_Time[vehicleid] = 0;
 	Vehicle_Missile_Reset_Fire_Slot[vehicleid] = -1;
	if(Vehicle_Missile_Following[vehicleid][slot] != INVALID_VEHICLE_ID)
	{
		Vehicle_Missile_Following[vehicleid][slot] = INVALID_VEHICLE_ID;
	}
 	CreateMissileExplosion(vehicleid, missileid, x, y, z, _);
 	PlayerPlaySound(playerid, 1159, x, y, z);
 	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return 1;
	//printf("[System: OnPlayerPickUpPickup] - Pickupid: %d", pickupid);
	if(gGameData[PlayerInfo[playerid][gGameID]][g_Has_Moving_Lift] == true)
	{
		for(new i = 0; i < sizeof(MovingLiftPickup); i++)
		{
		    if(pickupid == MovingLiftPickup[i] && MovingLiftStatus[i] == 0)
		    {
		        MovingLiftStatus[i] = 1;
		        new Float:x, Float:y, Float:z;
		        GetObjectPos(MovingLifts[i], x, y, z);
		        MoveObject(MovingLifts[i], x, y, z + MovingLiftArray[i][L_Move_Z_Index], MovingLiftArray[i][L_Move_Speed]);
		        return 1;
		    }
		}
	}
	new spickupid = -1, ipickup, bool:iterpickup = false, syncweapon;
	for(; ipickup < sizeof(PickupSlots); ipickup++)
	{
	    if(PickupSlots[ipickup] != 1) continue;
	    if(PickupInfo[ipickup][Pickupid] != pickupid) continue;
        spickupid = ipickup;
	    break;
	}
	if(spickupid == -1 || PickupInfo[spickupid][Created] == false) return 1;
	if(GetPlayerMissileCount(playerid) == 0)
 	{
		++syncweapon;
 	}
	switch(PickupInfo[spickupid][Pickuptype])
	{
	    case PICKUPTYPE_HEALTH:
	    {
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "30 Percent Health Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "30% Health Pickup", 5000);
	    	new Float:health, vehicleid = GetPlayerVehicleID(playerid), Float:maxhealth;
	    	maxhealth = GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid));
	    	T_GetVehicleHealth(vehicleid, health);
	    	if(health >= maxhealth)
			{
			    DestroyPickup(pickupid);
			    PickupInfo[spickupid][Created] = false;
	    		SetTimerEx("RespawnPickup", 2000, false, "ii", spickupid, PickupInfo[spickupid][Pickuptype]);
                TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Health Bay Full", 4000);
                return 1;
			}
			health *= 1.3;
			health = (health > maxhealth) ? maxhealth : health;
	    	T_SetVehicleHealth(vehicleid, health);
	    }
	    case PICKUPTYPE_TURBO:
	    {
	        new model = GetVehicleModel(Current_Vehicle[playerid]);
	        if(PlayerInfo[playerid][pTurbo] >= floatround(GetTwistedMetalMaxTurbo(model)))
			{
			    DestroyPickup(pickupid);
			    PickupInfo[spickupid][Created] = false;
	    		SetTimerEx("RespawnPickup", 2000, false, "ii", spickupid, PickupInfo[spickupid][Pickuptype]);
				TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Turbo Bay Full", 4000);
				return 1;
			}
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Turbo Picked Up");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Turbo Recharge", 5000);
	    	PlayerInfo[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
	    	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], GetTwistedMetalMaxTurbo(model));
	    	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	    }
	    case PICKUPTYPE_MACHINE_GUN_UPGRADE:
	    {
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Machine Gun Upgrade Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Machine Gun Upgrade", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] += 150;
	    	if(PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] > 300)
	    	{
	    	    PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 300;
	    	}
	    	new idx[4];
			valstr(idx, PlayerInfo[playerid][pMissiles][Missile_Machine_Gun_Upgrade], false);
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], idx);
	    	PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
		}
	    case PICKUPTYPE_HOMING_MISSILE:
	    {
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Homing Missiles Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Homing Missiles Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Homing] += 2;
		}
		case PICKUPTYPE_FIRE_MISSILE:
	    {
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Fire Missiles Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Fire Missiles Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Fire] += 2;
		}
		case PICKUPTYPE_POWER_MISSILE:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Power Missiles Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Power Missiles Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Power]++;
		}
		case PICKUPTYPE_NAPALM_MISSILE:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Napalm Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Napalm Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Napalm] += 2;
		}
		case PICKUPTYPE_STALKER_MISSILE:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Stalker Missile Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Stalker Missile Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Stalker]++;
		}
		case PICKUPTYPE_RICOCHETS_MISSILE:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Ricochet Missiles Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Ricochet Missiles Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Ricochet] += 2;
		}
		case PICKUPTYPE_REMOTEBOMBS:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Remote Bomb Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Remote Bomb Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_RemoteBomb]++;
		}
		case PICKUPTYPE_ENVIRONMENTALS:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Environment Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Environment Pickup", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Environmentals]++;
		}
		case PICKUPTYPE_LIGHTNING:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Lightning Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Lightning Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Lightning]++;
		}
	}
	if(iterpickup == true)
	{
	    DestroyPickup(pickupid);
		PickupInfo[spickupid][Created] = false;
    	SetTimerEx("RespawnPickup", 25000, false, "ii", spickupid, PickupInfo[spickupid][Pickuptype]);
    	if(syncweapon)
	    {
	        pMissileid[playerid] = GetNextHUDSlot(playerid);
	    }
	    UpdatePlayerHUD(playerid);
	}
	if(GetPVarInt(playerid, "Pickup_Deletion_Mode") == 1)
	{
	    SendClientMessageFormatted(playerid, -1, ""#cSAMPRed"Pickup Deleted: "#cWhite"Map: %s(%d) - %d - x: %0.4f - y: %0.4f - z: %0.4f", s_Maps[gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]][m_Name], gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], PickupInfo[spickupid][Pickuptype], PickupInfo[spickupid][PickupX], PickupInfo[spickupid][PickupY], PickupInfo[spickupid][PickupZ]);
	    DestroyPickupEx(spickupid);
		format(GlobalQuery, sizeof(GlobalQuery), "DELETE FROM `Maps_Pickups` WHERE `Mapid` = %d AND `Pickup_Type` = %d AND `x` = 0.4f AND `y` = 0.4f AND `z` = 0.4f LIMIT 1", gGameData[PlayerInfo[playerid][gGameID]][g_Map_id], PickupInfo[spickupid][Pickuptype], PickupInfo[spickupid][PickupX], PickupInfo[spickupid][PickupY], PickupInfo[spickupid][PickupZ]);
		mysql_function_query(McHandle, GlobalQuery, true, "Thread_NoReturnThread", "i", gGameData[PlayerInfo[playerid][gGameID]][g_Map_id]);
	}
	return 1;
}

//sweet tooth fire /hold 18688 2 0.22 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
public Destroy_Object(objectid)
{
    new rdo = objectid;
	if(IsValidObject(objectid))
	{
		rdo = DestroyObject(objectid);
		objectid = INVALID_OBJECT_ID;
	}
	//printf("Objectid %d Destroyed", objectid);
	//SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "Objectid %d Destroyed", objectid);
	return rdo;
}

public OnPlayerText(playerid, text[])
{
	if(Muted[playerid] == 1)
	{
    	SendClientMessage(playerid, RED, "You Are Muted - You Cannot Talk!");
		return 0;
	}
	if (text[0] == '@' || text[0] == '!')
	{
        if (PlayerInfo[playerid][AdminLevel] > 0)
		{
	        new string[128];
	        format(string, sizeof(string),"(Admin Chat) %s(%d): %s",Playername(playerid),playerid,text[1]);
	        MessageToAdmins(COLOR_ADMIN, string);
	        return 0;
		}
    }
    if (text[0] == '#')
	{
        if (PlayerInfo[playerid][pDonaterRank] < 1) return 1;
        foreach(Player, i)
        {
            if(PlayerInfo[i][pDonaterRank] > 0)
            {
            	SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FFFFFF, "(Donor Chat) %s(%d): %s", Playername(playerid), playerid, text[1]);
			}
			else continue;
        }
        return 0;
    }
 	new to_others[MAX_CHATBUBBLE_LENGTH + 1];
	format(to_others, MAX_CHATBUBBLE_LENGTH, "%s(%d) Says: %s", Playername(playerid), playerid, text);
	SetPlayerChatBubble(playerid, to_others, ROYALBLUE, 35.0, 7000);
	SetPVarInt(playerid,"textspam", GetPVarInt(playerid, "textspam") + 1);
	SetTimerEx("clearspam", 4000, false, "d", playerid);
	if(GetPVarInt(playerid, "textspam") == 5)
	{
		SendClientMessageFormatted(INVALID_PLAYER_ID, PINK, "Auto Kick: %s(%d) has been kicked from the server - Reason: Excess Flood (Text Spam)", Playername(playerid), playerid);
		SafeKick(playerid, "Excess Flood (Text Spam)");
	}
	else if(GetPVarInt(playerid, "textspam") == 4)
	{
		SendClientMessage(playerid, RED, "Stop Spamming Or You Will Be Kicked - (You Must Now Wait 4 Seconds To Type Again)");
		return 0;
	}
	return 1;
}

forward clearspam(playerid);
public clearspam(playerid)
{
	SetPVarInt(playerid, "textspam", 0);
	return 1;
}

CMD:applyanimation(playerid, params[])
{
	new animlib[32], animname[32];
	if(sscanf(params, "s[32]s[32]", animlib, animname)) return SendClientMessage(playerid, -1, "Usage: /Applyanimation [Animlib] [Animname]");
	ApplyAnimation(playerid, animlib, animname, 4.0, 0, 0, 0, 0, 0, 1);
	return 1;
}
CMD:animation(playerid,params[])
{
	if(GetPlayerAnimationIndex(playerid))
    {
        new animlib[32],animname[32],msg[128];
        GetAnimationName(GetPlayerAnimationIndex(playerid),animlib, 32, animname, 32);
        format(msg, sizeof(msg), "Running anim: %s - %s - %d", animlib, animname, GetPlayerAnimationIndex(playerid));
        SendClientMessage(playerid, 0xFFFFFFFF, msg);
        printf("%s(%d) Animation: %s - %s", Playername(playerid),playerid,animlib, animname);
    }
	return 1;
}

CMD:testexlol(playerid, params[])
{//explosion behind of vehicle - trunk
	new Float: Pos[7], vehicleid = GetPlayerVehicleID(playerid);
	GetVehicleZAngle(vehicleid, Pos[6]);
	GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, Pos[3], Pos[4], Pos[5]);
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	Pos[0] += (floatsin(Pos[6], degrees) * 0.8 * Pos[4]);
	Pos[1] -= (floatcos(Pos[6], degrees) * 0.8 * Pos[4]);

	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.7 * Pos[5], 12, 1.0);
	return 1;
}

CMD:testex(playerid, params[])
{//explosion area
	new Float: Pos[6], Float:a, vehicleid = GetPlayerVehicleID(playerid);
	GetVehicleZAngle(vehicleid, a);
	GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, Pos[3], Pos[4], Pos[5]);
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find front right

	Pos[0] += (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] += (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270.0;
  	Pos[0] += (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] += (Pos[3] * 0.42 * floatcos(-a, degrees));

	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);
	//
	GetVehicleZAngle(vehicleid, a); //a -= 270
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find front left

	Pos[0] -= (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] += (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270.0;
  	Pos[0] -= (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] += (Pos[3] * 0.42 * floatcos(-a, degrees));

  	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);

  	//
	GetVehicleZAngle(vehicleid, a); //a -= 270
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find back right

	Pos[0] += (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] -= (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270.0;
  	Pos[0] += (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] -= (Pos[3] * 0.42 * floatcos(-a, degrees));

  	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);

  	//
	GetVehicleZAngle(vehicleid, a); //a -= 270
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find back left

	Pos[0] -= (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] -= (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270.0;
  	Pos[0] -= (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] -= (Pos[3] * 0.42 * floatcos(-a, degrees));

	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);

	T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid)));
	return 1;
}

CMD:connect(playerid, params[])
{
    ConnectNPC("[BOT]RacerTest", "npcidle");
    return 1;
}
CMD:connectheli(playerid, params[])
{
    ConnectNPC("[BOT]HelicopterAttack", "HelicopterAttack");
    return 1;
}
CMD:velocity(playerid, params[])
{
	new Float:x, Float:y, Float:z, id;
	if(sscanf(params, "fffD(%d)", x, y, z, id, playerid)) return SendClientMessage(playerid, 0xFFFFFFFF, "Usage: /velocity [x, y, z] [playerid]");
	SetPlayerVelocity(id, x, y, z);
	return 1;
}
/*CMD:speedo(playerid, params[])
{
	new strOptionInfo[2][37] =
	{
    	"You have turned on your speedometer",
    	"You have turned off your speedometer"
 	};
 	DeActiveSpeedometer{playerid} = !DeActiveSpeedometer{playerid};
 	SendClientMessage(playerid, 0x00AA00FF, strOptionInfo[DeActiveSpeedometer{playerid}]);
 	if(!DeActiveSpeedometer{playerid})
 	{
 		for(new i; i != 15; i++) TextDrawShowForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
		for(new i; i < Speedometer_Needle_Index; i++) TextDrawShowForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
  	}
  	else
  	{
 		for(new i; i < Speedometer_Needle_Index; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
 		for(new i; i != 15; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
   	}
  	return 1;
}*/
CMD:damagestatus(playerid, params[])
{
	#pragma unused params
	if(GetPlayerVehicleID(playerid) == INVALID_VEHICLE_ID) return 1;
    new panels, doors, lights, tires;
	GetVehicleDamageStatus(GetPlayerVehicleID(playerid), panels, doors, lights, tires);
	SendClientMessageFormatted(playerid, TEAL, "Vehicle Status: Panels: %d - Doors: %d - Lights: %d - Tires: %d", panels, doors, lights, tires);
	return 1;
}
CMD:trunk(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);
    if(vehicleid == INVALID_VEHICLE_ID || vehicleid == 0) return SendClientMessage(playerid, RED, "Error: You Cannot Use This Command While Onfoot");
    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	if(boot == VEHICLE_PARAMS_UNSET || boot == VEHICLE_PARAMS_OFF)
	{
 		SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, VEHICLE_PARAMS_ON, objective);
	}
    else
    {
 		SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, VEHICLE_PARAMS_OFF, objective);
	}
    return 1;
}
CMD:doors(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);
    if(vehicleid == INVALID_VEHICLE_ID || vehicleid == 0) return SendClientMessage(playerid, RED, "Error: You Cannot Use This Command While Onfoot");
    new engine,lights,alarm,doors,bonnet,boot,objective;
    GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
 	if(doors == VEHICLE_PARAMS_UNSET || doors == VEHICLE_PARAMS_OFF) SetVehicleParamsEx(vehicleid,engine,lights,alarm,VEHICLE_PARAMS_ON,bonnet,boot,objective);
 	else SetVehicleParamsEx(vehicleid,engine,lights,alarm,VEHICLE_PARAMS_OFF,bonnet,boot,objective);
    return 1;
}

CMD:hold(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new oid, bid, Float:a[9], colour[2];
	a[6] = a[7] = a[8] = 1.0;
	if(sscanf(params, "ddF(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(1.0)F(1.0)F(1.0)H(0)H(0)", oid, bid, a[0], a[1], a[2], a[3], a[4], a[5],a[6], a[7], a[8], colour[0], colour[1]))
	{
    	SendClientMessage(playerid, WHITE, "Usage: /hold [Objectid] [Boneid 1-18] [fOffSetX] [fOffSetY] [fOffSetZ] [fRotX] [fRotY] [fRotZ] [fScaleX] [fScaleY] [fScaleZ] [Colour1] [Colour2]"),
		SendClientMessage(playerid, WHITE, "1: Spine | 2: Head | 3: Left Upper Arm | 4: Right Upper Arm | 5: Left Hand | 6: Right Hand"),
		SendClientMessage(playerid, WHITE, "7: Left thigh | 8: Right thigh | 9: Left foot | 10: Right foot | 11: Right calf | 12: Left calf"),
		SendClientMessage(playerid, WHITE, "13: Left forearm | 14: Right forearm | 15: Left clavicle | 16: Right clavicle | 17: Neck | 18: Jaw");
		return 1;
	}
    SetPlayerAttachedObject(playerid, 0, oid, bid, a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], colour[0], colour[1]);
	return 1;
}

CMD:btest(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new Float:a[6], index, id, str[7], Float:angle;
    if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
        SendClientMessage(playerid,RED,"{1E90FF}/btest [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n"#cWhite"Position and index are optional.");
		return 1;
	}
    GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
	//angle += 90;
	format(str, sizeof(str), "obb-%d", index);
	new Float:x, Float:y, Float:z;
	if(GetPVarInt(playerid, str) != 0)
	{
	    new o = GetPVarInt(playerid, str);
		DestroyObject(o);
		GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    	SetPVarInt(playerid, str, CreateObject(id, x + (a[0] * floatsin(-angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2], a[3], a[4], angle + 90 + a[5], 100.0));
		//printf("btest - xsin: %f - x+sin: %f - x: %f - y: %f - z: %f", floatsin(-angle, degrees), (a[0] * floatsin(angle, degrees)), x + (a[0] * floatsin(angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2]);
	}
	else
	{
	    new o = GetPVarInt(playerid, str);
		DestroyObject(o);
		GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    	SetPVarInt(playerid, str, CreateObject(id, x + (a[0] * floatsin(-angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2], a[3], a[4], angle + a[5], 100.0));
	}
    return 1;
}

CMD:holdvex(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new Float:a[6],index,id,str[8];
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
        SendClientMessage(playerid,RED,"{1E90FF}/holdvex [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n"#cWhite"Position and index are optional.");
		return 1;
	}
	if(IsValidObject(id))
	{
        SendClientMessage(playerid,RED,"{E31919}The specified object is not valid.");
		return 1;
	}
	format(str, sizeof(str), "obex-%d", index);
	new Float:x, Float:y, Float:z;
	if(GetPVarInt(playerid, str) != 0)
	{
		new o = GetPVarInt(playerid, str);
		DestroyObject(o);
		GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    	SetPVarInt(playerid, str, CreateObject(id, x + a[0], y + a[1], z + a[2], a[3], a[4], a[5], 100.0));
	}
	else
	{
	    new o = GetPVarInt(playerid, str);
		DestroyObject(o);
		GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    	SetPVarInt(playerid, str, CreateObject(id, x + a[0], y + a[1], z + a[2], a[3], a[4], a[5], 100.0));
	}
	return 1;
}

CMD:holdv(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new Float:a[6],index,id,str[6];
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
        SendClientMessage(playerid,RED,"{1E90FF}/holdv [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n"#cWhite"Position and index are optional.");
		return 1;
	}
	if(IsValidObject(id))
	{
        SendClientMessage(playerid,RED,"{E31919}The specified object is not valid.");
		return 1;
	}
	format(str, sizeof(str), "ob-%d", index);
	if(GetPVarInt(playerid, str) != 0)
	{
		new o = GetPVarInt(playerid, str);
		DestroyObject(o);
    	SetPVarInt(playerid, str, CreateObject(id, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0));
		AttachObjectToVehicle(GetPVarInt(playerid, str), GetPlayerVehicleID(playerid), a[0], a[1], a[2], a[3], a[4], a[5]);
	}
	else
	{
	    new o = GetPVarInt(playerid, str);
		DestroyObject(o);
    	SetPVarInt(playerid, str, CreateObject(id, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0));
		AttachObjectToVehicle(GetPVarInt(playerid, str), GetPlayerVehicleID(playerid), a[0], a[1], a[2], a[3], a[4], a[5]);
	}
	SendClientMessageFormatted(playerid, -1, "[System] - Holdv - Objectid %d", GetPVarInt(playerid, str));
	return 1;
}

CMD:attach(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new oid,Float:a[6],str[6],index;
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", oid, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
        SendClientMessage(playerid,RED,"{1E90FF}/attach [objectid] [index] [OffSetX] [OffSetY] [OffSetZ] [rX] [rY] [rZ]");
		return 1;
	}
	if(IsValidObject(oid))
	{
        SendClientMessage(playerid,RED,"{E31919}The specified object is not valid.");
		return 1;
	}
	format(str, sizeof(str), "ob-%d", index);
	if(GetPVarInt(playerid, str) != 0)
	{
		new o = GetPVarInt(playerid, str);
		DestroyObject(o);
		SetPVarInt(playerid, str, CreateObject(oid,0.0,0.0,0.0,0.0,0.0,0.0,200.0));
		AttachObjectToPlayer(GetPVarInt(playerid, str),playerid,a[0],a[1],a[2],a[3],a[4],a[5]);
	}
	else
	{
	    new o = GetPVarInt(playerid, str);
		DestroyObject(o);
	    SetPVarInt(playerid, str, CreateObject(oid,0.0,0.0,0.0,0.0,0.0,0.0,200.0));
		AttachObjectToPlayer(GetPVarInt(playerid, str),playerid,a[0],a[1],a[2],a[3],a[4],a[5]);
	}
	return 1;
}

CMD:reset(playerid, params[])
{
	pFiring_Missile[playerid] = 0;
	return 1;
}
CMD:machine(playerid, params[])
{
    Add_Vehicle_Offsets_And_Objects(GetPlayerVehicleID(playerid), Missile_Machine_Gun);
    SendClientMessage(playerid, 0xFFFFFFFF, "Machine Gun Added");
	return 1;
}
CMD:special(playerid, params[])
{
	new Specials;
	if(sscanf(params, "D(2)", Specials)) return SendClientMessage(playerid, RED, "/Special [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Special Missile Added");
	PlayerInfo[playerid][pMissiles][Missile_Special] += Specials;
	return 1;
}
CMD:fire(playerid, params[])
{
	new Fires;
	if(sscanf(params, "D(2)", Fires)) return SendClientMessage(playerid, RED, "/Fire [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Fire Missile Added");
	PlayerInfo[playerid][pMissiles][Missile_Fire] += Fires;
	return 1;
}
CMD:homing(playerid, params[])
{
	new Homings;
	if(sscanf(params, "D(2)", Homings)) return SendClientMessage(playerid, RED, "/Homing [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Homing Missile Added");
	PlayerInfo[playerid][pMissiles][Missile_Homing] += Homings;
	return 1;
}
CMD:power(playerid, params[])
{
	new Powers;
	if(sscanf(params, "D(2)", Powers)) return SendClientMessage(playerid, RED, "/Power [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Power Missile Added");
	PlayerInfo[playerid][pMissiles][Missile_Power] += Powers;
	return 1;
}
CMD:napalm(playerid, params[])
{
	new Napalms;
	if(sscanf(params, "D(1)", Napalms)) return SendClientMessage(playerid, RED, "/Gas [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Gas Can Missile(s) Added");
    PlayerInfo[playerid][pMissiles][Missile_Napalm] += Napalms;
	return 1;
}
CMD:stalker(playerid, params[])
{
	new stalkers;
	if(sscanf(params, "D(2)", stalkers)) return SendClientMessage(playerid, RED, "/stalker [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Stalker Missile(s) Added");
	PlayerInfo[playerid][pMissiles][Missile_Stalker] += stalkers;
	return 1;
}
CMD:ricochet(playerid, params[])
{
	new Ricochets;
	if(sscanf(params, "D(2)", Ricochets)) return SendClientMessage(playerid, RED, "/Ricochet [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Ricochet Missile Added");
	PlayerInfo[playerid][pMissiles][Missile_Ricochet] += Ricochets;
	return 1;
}
CMD:remotebomb(playerid, params[])
{
	new remotebombs;
	if(sscanf(params, "D(2)", remotebombs)) return SendClientMessage(playerid, RED, "/Remotebomb [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Remote Bomb Missile Added");
	PlayerInfo[playerid][pMissiles][Missile_RemoteBomb] += remotebombs;
	return 1;
}
CMD:addcomponent(playerid, params[])
{
    new componentid;
	if(sscanf(params, "d", componentid)) return SendClientMessage(playerid, RED, "/addcomponent [componentid]");
    SendClientMessageFormatted(playerid, 0xFFFFFFFF, "componentid %d Added", componentid);
    AddVehicleComponent(GetPlayerVehicleID(playerid), componentid);
	return 1;
}
CMD:environmentals(playerid, params[])
{
	new Environmentals;
	if(sscanf(params, "D(1)", Environmentals)) return SendClientMessage(playerid, RED, "/Environmentals [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Environmental Missile(s) Added");
    PlayerInfo[playerid][pMissiles][Missile_Environmentals] += Environmentals;
	return 1;
}
CMD:turbo(playerid, params[])
{
	new model = GetVehicleModel(Current_Vehicle[playerid]);
	PlayerInfo[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], floatround(GetTwistedMetalMaxTurbo(model)));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	return 1;
}
CMD:energy(playerid, params[])
{
	PlayerInfo[playerid][pEnergy] = 100;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], 100.0);
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	return 1;
}
CMD:camera(playerid, params[])
{
	SetCameraBehindPlayer(playerid);
	return 1;
}
CMD:setskin(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id, skin;
	if(sscanf(params, "ui", id, skin)) return SendClientMessage(playerid, WHITE, "Usage: /setskin [nick/id] [Skinid]");
 	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");
	SetPlayerSkin(id, skin);
	PlayerInfo[playerid][pSkinid] = skin;
	return 1;
}
CMD:vremove(playerid, params[])
{
	if(GetPlayerVehicleID(playerid)) RemovePlayerFromVehicle(playerid);
	return 1;
}
CMD:giveweapon(playerid, params[]) return cmd_givegun(playerid,params);
CMD:giveweap(playerid, params[]) return cmd_givegun(playerid,params);
CMD:givegun(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
 	{
		new weaponid, ammo, string[128], gun[30], playa;
		if(sscanf(params, "uii", playa, weaponid, ammo)) return SendClientMessage(playerid, WHITE, "Usage: /giveweapon [playerID] [weaponID] [Ammo]");
		if(weaponid > 46 || weaponid < 1) return SendClientMessage(playerid,RED,"Invalid Weapon ID [1-46]!");
		if(playa != INVALID_PLAYER_ID)
		{
			GetWeaponName(weaponid,gun,30);
		    if(playa != playerid)
		    {
				format(string,sizeof(string),"You gave %s a %s with %d rounds of ammunition!", Playername(playa),gun, ammo); SendClientMessage(playerid,WHITE,string);
				format(string,sizeof(string),"You have recieved a %s with %d round of ammunition from Administrator %s",gun, ammo, Playername(playerid)); SendClientMessage(playa, GREEN, string);
				format(string,sizeof(string),"Admin Message: %s gave %s a %s with %d rounds of ammunition",Playername(playerid),Playername(playa),gun, ammo); MessageToAdmins(WHITE, string);
				return GivePlayerWeapon(playa, weaponid, ammo);
			} else {
			    format(string,sizeof(string),"You gave yourself a %s with %d rounds of ammunition!", gun, ammo); SendClientMessage(playerid,WHITE,string);
				format(string,sizeof(string),"Admin Message: %s gave himself a %s with %d rounds of ammunition",Playername(playerid),gun, ammo); MessageToAdmins(WHITE, string);
				return GivePlayerWeapon(playa, weaponid, ammo);
			}
		} else return SendClientMessage(playerid, RED,"Invalid Nick/id!");
	} else return 0;
}
CMD:goto(playerid,params[])
{
    if(IsPlayerAdmin(playerid))
	{
	    new id,string[128];
		if(sscanf(params,"u",id)) return SendClientMessage(playerid, LIGHTBLUE2, "Usage: /Goto [Goto id/Playername]") &&
		SendClientMessage(playerid, ORANGE, "Function: Will Go To specified player");
		if(!IsPlayerConnected(id)) return SendClientMessage(playerid,RED,"That Player Is Not Connected.");
        if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid,RED,"Invalid Nick/id.");
	 	if(id != playerid)
	 	{
			new Float:x, Float:y, Float:z; GetPlayerPos(id, x, y, z);
			SetPlayerInterior(playerid, GetPlayerInterior(id));
			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
			if(GetPlayerState(playerid) == 2)
			{
				SetVehiclePos(GetPlayerVehicleID(playerid),x+3,y,z+0.3);
				LinkVehicleToInterior(GetPlayerVehicleID(playerid),GetPlayerInterior(id));
				SetVehicleVirtualWorld(GetPlayerVehicleID(playerid),GetPlayerVirtualWorld(id));
			}
			else SetPlayerPos(playerid,x+2,y,z+0.4);
			format(string,sizeof(string),"|- You Have Teleported To \"%s\" -|", Playername(id));
			return SendClientMessage(playerid,BlueMsg,string);
		}
	}
	return 0;
}
CMD:gxttest(playerid, params[])
{
	new achar = 'b';
	if(sscanf(params, "c", achar)) return SendClientMessage(playerid, -1, "Usage: /gxttest [char]");
	new str[64];
	format(str, sizeof(str), "~%c~Hello Moto", achar);
	GameTextForPlayer(playerid, str, 5000, 3);
	return 1;
}
CMD:test(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
    if(IsPlayerInAnyVehicle(playerid)){
		SetVehiclePos(GetPlayerVehicleID(playerid), 1389.0594,1526.7904,10.3527);
		SetPlayerInterior(playerid, 0);
  		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(playerid));
  		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(playerid));
  		new Float:Angle;GetPlayerFacingAngle(playerid,Angle);
		SetVehicleZAngle(GetPlayerVehicleID(playerid),Angle);
	}
	else
	SetPlayerPos(playerid, 1389.0594,1526.7904,10.3527);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}
stock CalculatePointsBetweenPoints(Float:x, Float:y, Float:x2, Float:y2, Points = 1)
{
    new Float:DistX = x2[1] - x[0];// 2900-2500 = 400
	new Float:DistY = y2[1] - y[0];// 2400-2600 = -200
	new Float:StepX = DistX / (Points + 1);// 400 / 4 = 100
	new Float:StepY = DistY / (Points + 1);// -200 / 4 = -50
	for (new Steps = 0; Steps < Points + 1;Steps++)
	{
	    new Float:X = x[0] + Steps * StepX;
	    new Float:Y = y[0] + Steps * StepY;
	    new string[64];
	    format(string, sizeof(string),"Pointx: %f - Pointy: %f", X, Y);
	    SendClientMessageToAll(0xffffffff, string);
	}
	return 1;
}
CMD:top5(playerid, params[])
{
    new
        players_Data[MAX_PLAYERS][2],
        tempString[128],
        tempVar,
        i,
        j,
        k
    ;
    foreachex(Player, i)
    {
        players_Data[tempVar][0] = GetPlayerScore(i);
        players_Data[tempVar++][1] = i;
    }
    for(i = 0, j = 0; i < tempVar; ++i)
    {
        j = players_Data[i][0];

        for(k = i - 1; k > -1; --k)
        {
            if(j > players_Data[k][0])
            {
                players_Data[k][0] ^= players_Data[k + 1][0], players_Data[k + 1][0] ^= players_Data[k][0], players_Data[k][0] ^= players_Data[k + 1][0];
                players_Data[k][1] ^= players_Data[k + 1][1], players_Data[k + 1][1] ^= players_Data[k][1], players_Data[k][1] ^= players_Data[k + 1][1];
            }
        }
    }

    SendClientMessage(playerid, 0xFF0000FF, "» Top 5 players:");
    for(i = 0; i < 5; ++i)
    {
        if(tempVar < i) break;

        GetPlayerName(players_Data[i][1], tempString, 20);

        format(tempString, sizeof(tempString), "» %d. Player: %s [%d] - Score: %d", i, tempString, players_Data[i][1], players_Data[i][0]);
        SendClientMessage(playerid, 0xFFFFFFFF, tempString);
    }
    return 1;
}
new aVehicleNames[212][] = {	// Vehicle Names - Betamaster
	{"Landstalker"},{"Bravura"},{"Buffalo"},{"Linerunner"},{"Perrenial"},
	{"Sentinel"},{"Dumper"},{"Firetruck"},{"Trashmaster"},{"Stretch"},
	{"Manana"},{"Infernus"},{"Voodoo"},{"Pony"},{"Mule"},{"Cheetah"},
	{"Ambulance"},{"Leviathan"},{"Moonbeam"},{"Esperanto"},{"Taxi"},
	{"Washington"},{"Bobcat"},{"Mr Whoopee"},{"BF Injection"},{"Hunter"},
	{"Premier"},{"Enforcer"},{"Securicar"},{"Banshee"},{"Predator"},{"Bus"},
	{"Rhino"},{"Barracks"},{"Hotknife"},{"Trailer 1"}, /*artict*/{"Previon"},
	{"Coach"},{"Cabbie"},{"Stallion"},{"Rumpo"},{"RC Bandit"},{"Romero"},
	{"Packer"},{"Monster"},{"Admiral"},{"Squalo"},{"Seasparrow"},{"Pizzaboy"},
	{"Tram"},{"Trailer 2"}, /*artict2*/{"Turismo"},{"Speeder"},{"Reefer"},
	{"Tropic"},{"Flatbed"},{"Yankee"},{"Caddy"},{"Solair"},{"Berkley's RC Van"},
	{"Skimmer"},{"PCJ-600"},{"Faggio"},{"Freeway"},{"RC Baron"},{"RC Raider"},
	{"Glendale"},{"Oceanic"},{"Sanchez"},{"Sparrow"},{"Patriot"},{"Quad"},
	{"Coastguard"},{"Dinghy"},{"Hermes"},{"Sabre"},{"Rustler"},{"ZR-350"},
	{"Walton"},{"Regina"},{"Comet"},{"BMX"},{"Burrito"},{"Camper"},
	{"Marquis"},{"Baggage"},{"Dozer"},{"Maverick"},{"News Chopper"},{"Rancher"},
	{"FBI Rancher"},{"Virgo"},{"Greenwood"},{"Jetmax"},{"Hotring"},{"Sandking"},
	{"Blista Compact"},{"Police Maverick"},{"Boxville"},{"Benson"},{"Mesa"},
	{"RC Goblin"},{"Hotring Racer A"},/*hotrina*/{"Hotring Racer B"},/*hotrinb*/
	{"Bloodring Banger"},{"Rancher"},{"Super GT"},{"Elegant"},{"Journey"},
	{"Bike"},{"Mountain Bike"},{"Beagle"},{"Cropduster"},{"Stunt"},
	{"Tanker"}, /*petro*/{"Roadtrain"},{"Nebula"},{"Majestic"},{"Buccaneer"},
	{"Shamal"},{"Hydra"},{"FCR-900"},{"NRG-500"},{"HPV1000"},{"Cement Truck"},
	{"Tow Truck"},{"Fortune"},{"Cadrona"},{"FBI Truck"},{"Willard"},{"Forklift"},
	{"Tractor"},{"Combine"},{"Feltzer"},{"Remington"},{"Slamvan"},{"Blade"},
	{"Freight"},{"Streak"},{"Vortex"},{"Vincent"},{"Bullet"},{"Clover"},{"Sadler"},
	{"Firetruck LA"},/*firela*/{"Hustler"},{"Intruder"},{"Primo"},{"Cargobob"},
	{"Tampa"},{"Sunrise"},{"Merit"},{"Utility"},{"Nevada"},{"Yosemite"},
	{"Windsor"},{"Monster A"}, /*monstera*/{"Monster B"}, /*monsterb*/
	{"Uranus"},{"Jester"},{"Sultan"},{"Stratum"},{"Elegy"},
	{"Raindance"},{"RC Tiger"},{"Flash"},{"Tahoma"},{"Savanna"},{"Bandito"},
	{"Freight Flat"}, /*freiflat*/{"Streak Carriage"}, /*streakc*/{"Kart"},
	{"Mower"},{"Duneride"},{"Sweeper"},{"Broadway"},{"Tornado"},{"AT-400"},
	{"DFT-30"},{"Huntley"},{"Stafford"},{"BF-400"},{"Newsvan"},{"Tug"},
	{"Trailer 3"}, /*petrotr*/{"Emperor"},{"Wayfarer"},{"Euros"},{"Hotdog"},
	{"Club"},{"Freight Carriage"}, /*freibox*/{"Trailer 3"}, /*artict3*/
	{"Andromada"},{"Dodo"},{"RC Cam"},{"Launch"},{"Police Car (LSPD)"},
	{"Police Car (SFPD)"},{"Police Car (LVPD)"},{"Police Ranger"},{"Picador"},
	{"S.W.A.T. Van"},{"Alpha"},{"Phoenix"},{"Glendale"},{"Sadler"},
	{"Luggage Trailer A"}, /*bagboxa*/{"Luggage Trailer B"}, /*bagboxb*/
	{"Stair Trailer"}, /*tugstair*/{"Boxville"},{"Farm Plow"}, /*farmtr1*/
	{"Utility Trailer"}/*utiltr1*/
};
new aveh[MAX_PLAYERS];
CMD:v(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new vname[24], changecurrentcar;
 	if(sscanf(params, "s[24]D(0)", vname, changecurrentcar)) return SendClientMessage(playerid, RED, "Usage: /v [twisted name/ vehiclename / modelid - changecurrentcar = 0 / 1]");
	if(aveh[playerid] != 0) DestroyVehicle(aveh[playerid]);
	new Float:x, Float:y, Float:z, Float:Angle;
 	GetPlayerPos(playerid, x, y, z);
 	GetPlayerFacingAngle(playerid, Angle);
 	x += (2.0 * floatsin(-Angle, degrees));
 	y += (2.0 * floatcos(-Angle, degrees));
 	if(isNumeric(vname))
  	{
		if(!IsValidVehicleModel(strval(vname))) return SendClientMessage(playerid, RED, "Error: Invalid Vehicleid");
		aveh[playerid] = CreateVehicle(strval(vname), x, y, z, Angle, -1, -1, -1);
		T_SetVehicleHealth(aveh[playerid], GetTwistedMetalMaxHealth(GetVehicleModel(aveh[playerid])));
  	}
	else if(!isNumeric(vname))
	{
	    new bool:index = false, model = GetTwistedMetalVehicleID(vname);
	    if(model == INVALID_VEHICLE_ID)
	    {
	        model = ReturnVehicleID(vname);
	    }
	    else index = true;
		if(!IsValidVehicleModel(model)) return SendClientMessage(playerid, RED, "Error: Invalid Name");
		aveh[playerid] = CreateVehicle(model, x, y, z, Angle, -1, -1, -1);
		if(index == true)
		{
		    Add_Vehicle_Offsets_And_Objects(aveh[playerid], Missile_Machine_Gun);
		}
		T_SetVehicleHealth(aveh[playerid], GetTwistedMetalMaxHealth(GetVehicleModel(aveh[playerid])));
  	}
  	else return SendClientMessage(playerid, RED, "Usage: /v [twisted name/ vehiclename / modelid - changecurrentcar = 0 / 1]");
   	PutPlayerInVehicle(playerid, aveh[playerid], 0);
   	AddVehicleComponent(aveh[playerid], 1010);
   	LinkVehicleToInterior(aveh[playerid], GetPlayerInterior(playerid));
   	SetVehicleVirtualWorld(aveh[playerid], GetPlayerVirtualWorld(playerid));
   	if(changecurrentcar)
   	{
   	    Current_Vehicle[playerid] = aveh[playerid];
   	    aveh[playerid] = 0;
   	    pFiring_Missile[playerid] = 0;
   	    pMissileid[playerid] = Missile_Special;
	 	new pm = 0;
		while(pm < 9)
		{
			switch(pm)
			{
			    case Missile_Special, Missile_Ricochet: PlayerInfo[playerid][pMissiles][pm] = 1;
				case Missile_Fire, Missile_Homing: PlayerInfo[playerid][pMissiles][pm] = 2;
				default: PlayerInfo[playerid][pMissiles][pm] = 0;
			}
	 		++pm;
	 	}
	 	UpdatePlayerHUD(playerid);
   	}
	return 1;
}
CMD:gotoobject(playerid, params[])
{
	new objectid, Float:x, Float:y, Float:z;
	if(sscanf(params, "i", objectid)) return SendClientMessage(playerid, -1, "Syntax: /gotoobject [objectid]");
	if(!IsValidObject(objectid)) return SendClientMessage(playerid, -1, "Error: Invalid Object");
	GetObjectPos(objectid, x, y, z);
	SetVehiclePos(Current_Vehicle[playerid], x, y, z);
	SendClientMessageFormatted(playerid, -1, "objectid: %d - x: %0.2f - y: %0.2f - z: %0.2f", objectid, x, y, z);
	return 1;
}
CMD:getobjectpos(playerid, params[])
{
    new objectid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;
	if(sscanf(params, "d", objectid)) return SendClientMessage(playerid, -1, "Usage: /GetObjectPos [objectid]");
    if(!IsValidObject(objectid)) return SendClientMessage(playerid, -1, "Error: Invalid Object");
	GetObjectPos(objectid, x, y, z);
	GetObjectRot(objectid, rx, ry, rz);
	SendClientMessageFormatted(playerid, -1 , "Object Position id: %d - x: %0.2f - y: %0.2f - z: %0.2f - Angle: %0.4f", objectid, x, y, z, rz);
	return 1;
}
CMD:getpos(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new Float:x, Float:y, Float:z, Float:a;
	if(IsPlayerInAnyVehicle(playerid))
	{	GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
		GetVehicleZAngle(GetPlayerVehicleID(playerid), a);}
	else
	{
	    GetPlayerPos(playerid, x, y, z);
		GetPlayerFacingAngle(playerid, a);
	}
	SendClientMessageFormatted(playerid, -1, "Vehicle/Player Position - x: %0.4f - y: %0.4f - z: %0.4f - Angle: %0.4f", x, y, z, a);
	return 1;
}
CMD:setzangle(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    if(!GetPlayerVehicleID(playerid)) return SendClientMessage(playerid,0xFFFFFFFF,"Error: Get In A Vehicle");
	new Float:a, id = GetPlayerVehicleID(playerid);
	if(sscanf(params,"f", a)) return SendClientMessage(playerid,0xFFFFFFFF,"Usage: /setzangle [a]");
	SetVehicleZAngle(id, a);
	return 1;
}
CMD:gotopos(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new Float:x, Float:y, Float:z;
	if(sscanf(params,"fff", x, y, z)) return SendClientMessage(playerid,0xFFFFFFFF,"Usage: /gotopos [x, y, z]");
	SetPlayerPos(playerid, x, y, z);
	return 1;
}
CMD:akill(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new id, reason[40];
    if(sscanf(params, "uS(No Reason)[40]", id, reason)) return SendClientMessage(playerid, WHITE, "Usage: /akill [id] [reason]");
   	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");

	new string[128];
	format(string, 128, "Administrator %s(%d) Has AKilled %s(%d) - Reason: %s", Playername(playerid), playerid, Playername(id), id, reason);
	MessageToAdmins(WHITE, string);
	new Float:x, Float:y, Float:z;
	GetPlayerPos(id, x, y, z);
	SetPlayerPos(id, x, y, z + 10);
	SetPlayerHealth(id, -1);
	ForceClassSelection(playerid);
	return 1;
}
CMD:getall(playerid,params[])
{
    #pragma unused params
	if(!IsPlayerAdmin(playerid)) return 0;
	new Float:x, Float:y, Float:z, interior = GetPlayerInterior(playerid);
	GetPlayerPos(playerid, x, y, z);
 	foreach(Player, i)
	{
		if(i == playerid) continue;
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerPos(i, x + (playerid/4) + 1, y + (playerid/4), z);
		SetPlayerInterior(i, interior);
	}
	return SendClientMessageFormatted(INVALID_PLAYER_ID, BlueMsg, "|- Administrator \"%s\" Has Teleported All Players To His Position -|", Playername(playerid));
}
CMD:get(playerid, params[])
{
    #pragma unused params
    if(!IsPlayerAdmin(playerid)) return 0;
    new id,string[128];
	if(sscanf(params,"u",id)) return SendClientMessage(playerid, LIGHTBLUE2, "Usage: /Get [id/nick]") &&
	SendClientMessage(playerid, ORANGE, "Function: Will Bring To you the specified player");
	if(!IsPlayerConnected(id) || id == INVALID_PLAYER_ID || id == playerid) return SendClientMessage(playerid,RED,"Error: Player is not connected or is yourself");
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	SetPlayerInterior(id, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(id, GetPlayerVirtualWorld(playerid));
	if(GetPlayerState(id) == 2)
	{
		SetVehiclePos(GetPlayerVehicleID(id),x+3,y,z);
		LinkVehicleToInterior(GetPlayerVehicleID(id),GetPlayerInterior(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(id),GetPlayerVirtualWorld(playerid));
	}
	else SetPlayerPos(id,x+2,y,z);
	format(string,sizeof(string),"|- You Have Been Teleported To Administrator \"%s(%d)'s\" Position! -|", Playername(playerid),playerid);
	SendClientMessage(id,BlueMsg,string);
	format(string,sizeof(string),"|- You Have Teleported \"%s(%d)\" To Your Position -|", Playername(id),id);
	return SendClientMessage(playerid,BlueMsg,string);
}
stock GetPlayerSpeed(playerid, bool:kmh)
{
	new Float:Speed, Float:X, Float:Y, Float:Z;
    if(IsPlayerInAnyVehicle(playerid)) GetVehicleVelocity(GetPlayerVehicleID(playerid), X, Y, Z);
    else GetPlayerVelocity(playerid, X, Y, Z);
	Speed = floatmul(floatsqroot(floatadd(floatadd(floatpower(X, 2), floatpower(Y, 2)),  floatpower(Z, 2))), 200.0); //100.0
  	return kmh == true ? floatround(Speed, floatround_floor) : floatround(floatdiv(Speed, 1.609344), floatround_floor);
}
stock GetVehicleSpeed(vehicleid, bool:kmh)
{
	new Float:Speed, Float:X, Float:Y, Float:Z;
	GetVehicleVelocity(vehicleid, X, Y, Z);
	Speed = floatmul(floatsqroot(floatadd(floatadd(floatpower(X, 2), floatpower(Y, 2)),  floatpower(Z, 2))), 200.0); //100.0
  	return kmh == true ? floatround(Speed, floatround_floor) : floatround(floatdiv(Speed, 1.609344), floatround_floor);
}
stock IncreaseVehicleSpeed(vehicleid, Float:howmuch)
{
    static Float:Velocity[3];
	GetVehicleVelocity(vehicleid, Velocity[0], Velocity[1], Velocity[2]);
    return SetVehicleVelocity(vehicleid, Velocity[0] * howmuch , Velocity[1] * howmuch , Velocity[2]);
}
stock DecreaseVehicleSpeed(vehicleid, Float:howmuch)
{
    static Float:Velocity[3];
	GetVehicleVelocity(vehicleid, Velocity[0], Velocity[1], Velocity[2]);
    return SetVehicleVelocity(vehicleid, Velocity[0] / howmuch , Velocity[1] / howmuch , Velocity[2]);
}
stock IsValidVehicleModel(vehicleid)
{
	if(vehicleid < 400 || vehicleid > 611) return false;
	    else return true;
}
ReturnVehicleID(vName[])
{
	for(new x = 0; x != 211; x++)
	{
	    if(strfind(aVehicleNames[x], vName, true) != -1)
		return x + 400;
	}
	return INVALID_VEHICLE_ID;
}
GetTwistedMetalVehicleID(vName[24])
{
	for(new x = 0; x != MAX_TWISTED_VEHICLES; x++)
	{
	    if(strfind(C_S_IDS[x][CS_TwistedName], vName, true) != -1) return C_S_IDS[x][CS_VehicleModelID];
	}
	return INVALID_VEHICLE_ID;
}
stock RotatePoint(& Float: X, & Float: Y, & Float: Z, Float: pitch, Float: yaw, Float: distance) {
    X -= (distance * floatcos(pitch, degrees) * floatsin(yaw, degrees));
    Y += (distance * floatcos(pitch, degrees) * floatcos(yaw, degrees));
    Z += (distance * floatsin(pitch, degrees));
}

stock GetXYZOfVehicle(vehicleid, & Float: X, & Float: Y, & Float: Z, Float: pitch, Float: distance) {
    new Float: yaw, Float:vZ;
    if(GetVehicleZAngle(vehicleid, yaw)) {
        GetVehiclePos(vehicleid, X, Y, Z);
        vZ = Z;
        RotatePoint(X, Y, Z, pitch, yaw, distance);
        if(Z < vZ) Z += 0.5;
        return true;
    }
    return false;
}
stock GetMiddlePos(Float:x_1, Float:y_1, Float:x_2, Float:y_2, &Float:x_mid, &Float:y_mid)
{
    x_mid = (x_1 + x_2) / 2;    // Arithmetic mean value is all you need
    y_mid = (y_1 + y_2) / 2;
}
stock GetXYInFrontOfPoint( &Float: x, &Float: y, Float: angle, Float: distance ) {

   x += ( distance * floatsin( -angle, degrees ) );
   y += ( distance * floatcos( -angle, degrees ) );
}
stock GetXYInLeftOfPoint( &Float: x, &Float: y, Float: angle, Float: distance ) {

   	angle += 90.0;
   	x += floatmul(floatsin(-angle, degrees), distance);
   	y += floatmul(floatcos(-angle, degrees), distance);
}
stock GetXYInRightOfPoint( &Float: x, &Float: y, Float: angle, Float: distance ) {

   	Angle -= 90.0;
   	x += floatmul(floatsin(-angle, degrees), distance);
	y += floatmul(floatcos(-angle, degrees), distance);
}
stock GetXYLeftOfPlayer(playerid, Float:distance, &Float:X, &Float:Y)
{
    new Float:Angle;
    GetPlayerFacingAngle(playerid, Angle); Angle += 90.0;
    X += floatmul(floatsin(-Angle, degrees), distance);
    Y += floatmul(floatcos(-Angle, degrees), distance);
}
stock GetXYRightOfPlayer(playerid, Float:distance, &Float:X, &Float:Y)
{
    new Float:Angle;
    GetPlayerFacingAngle(playerid, Angle); Angle -= 90.0;
    X += floatmul(floatsin(-Angle, degrees), distance);
    Y += floatmul(floatcos(-Angle, degrees), distance);
}
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
    new Float:a;
    GetPlayerPos(playerid, x, y, a);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID(playerid)) {
        GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
    }
    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));
}
stock GetXYBehindPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);
	if (GetPlayerVehicleID(playerid)){
	    GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	}
	a +=180;
	x -= (distance * floatsin(-a, degrees));
	y -= (distance * floatcos(-a, degrees));
}
stock GetXYRightOfVehicle(vehicleid, Float:distance, &Float:x, &Float:y)
{
    new Float:Angle;
    GetVehicleZAngle(vehicleid, Angle); Angle += 90.0;
    x += floatmul(floatsin(-Angle, degrees), distance);
    y += floatmul(floatcos(-Angle, degrees), distance);
}
stock GetXYLeftOfVehicle(vehicleid, Float:distance, &Float:x, &Float:y)
{
    new Float:Angle;
    GetVehicleZAngle(vehicleid, Angle); Angle -= 90.0;
    x += floatmul(floatsin(-Angle, degrees), distance);
    y += floatmul(floatcos(-Angle, degrees), distance);
}
stock GetXYInFrontOfVehicle(vehicleid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetVehiclePos(vehicleid, x, y, a);
	GetVehicleZAngle(vehicleid, a);
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}
stock GetXYBehindOfVehicle(vehicleid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetVehiclePos(vehicleid, x, y, a);
	GetVehicleZAngle(vehicleid, a);
	a += 180;
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}
stock GetZBelowOfObject(objectid, &Float:z, Float:distance)
{
    new Float:rz;
    GetObjectPos(objectid, rz, rz, z);
    GetObjectRot(objectid, rz, rz, rz);
    z -= (distance * floatsin(-rz, degrees));
}
stock GetZOnTopOfObject(objectid, &Float:z, Float:distance)
{
    new Float:rz;
    GetObjectPos(objectid, rz, rz, z);
    GetObjectRot(objectid, rz, rz, rz);
    z += (distance * floatsin(-rz, degrees));
}
stock GetXYInFrontOfObject(objectid, &Float:x, &Float:y, Float:distance)
{
    new Float:rz;
    GetObjectPos(objectid, x, y, rz);
    GetObjectRot(objectid, rz, rz, rz);
    x += (distance * floatsin(-rz, degrees));
    y += (distance * floatcos(-rz, degrees));
}
stock GetXYBehindObject(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float:rz;
    GetObjectPos(objectid, x, y, rz);
    GetObjectRot(objectid, rx, ry, rz);
    rz += 180;
    x += (distance * floatsin(-rz, degrees));
    y += (distance * floatcos(-rz, degrees));
}

stock IsObjectInRangeOfVehicle(objectid, vehicleid, Float:range)
{
	new Float:pos[3], Float:x, Float:y, Float:z;
	GetObjectPos(objectid, pos[0], pos[1], pos[2]);
	GetVehiclePos(vehicleid, x, y, z);
	pos[0] -= x; pos[1] -= y; pos[2] -= z;
	return ((pos[0] * pos[0]) + (pos[1] * pos[1]) + (pos[2] * pos[2])) < (range * range);
}
stock IsPlayerAimingAt(playerid, Float:x, Float:y, Float:z, Float:radius)
{
    new Float:cx,Float:cy,Float:cz,Float:fx,Float:fy,Float:fz;
    GetPlayerCameraPos(playerid, cx, cy, cz);
    GetPlayerCameraFrontVector(playerid, fx, fy, fz);
    return (radius >= MPDistanceCameraToLocation(cx, cy, cz, x, y, z, fx, fy, fz));
}
stock IsPlayerInInvalidNosVehicle(playerid)
{
	new vehicleid = GetPlayerVehicleID(playerid);
	#define MAX_INVALID_NOS_VEHICLES 52
	new InvalidNosVehicles[MAX_INVALID_NOS_VEHICLES] =
	{
		581,523,462,521,463,522,461,448,468,586,417,425,469,487,512,520,563,593,
		509,481,510,472,473,493,520,595,484,430,453,432,476,497,513,533,577,
		452,446,447,454,590,569,537,538,570,449,519,460,488,511,519,548,592
	};
 	if(IsPlayerInAnyVehicle(playerid))
  	{
   		for(new i = 0; i < MAX_INVALID_NOS_VEHICLES; i++)
     	{
      		if(GetVehicleModel(vehicleid) == InvalidNosVehicles[i]) return true;
       	}
   	}
   	return false;
}
stock IsPlayerInvalidNosExcludeBikes(playerid)
{
	new vehicleid = GetPlayerVehicleID(playerid);
	#define MAX_INVALID_NOS_VEHICLE 52
	new InvalidNosVehicles[MAX_INVALID_NOS_VEHICLE] =
	{
		581,523,462,521,522,461,448,468,586,417,425,469,487,512,520,563,593,
		473,493,520,595,484,430,453,432,476,497,513,533,577,481,472,548,
		452,446,447,454,590,569,537,538,570,449,519,460,488,511,519
	};
 	if(IsPlayerInAnyVehicle(playerid))
  	{
   		for(new i = 0; i < MAX_INVALID_NOS_VEHICLE; i++)
     	{
      		if(GetVehicleModel(vehicleid) == InvalidNosVehicles[i]) return true;
       	}
   	}
   	return false;
}

stock GetAlpha(color) return (color & 0xFF);

CMD:timetext(playerid, params[])
{
	new text[64], style = TIMETEXT_TOP, time = 5000;
	if(!sscanf(params, "D("#TIMETEXT_TOP")D(5000)s[64]", style, time, text))
	{
	    TimeTextForPlayer( style, playerid, text, time, _);
	}
	return 1;
}

#define TIMETEXT_INTERVAL 20

forward UpdateTimeTextSize(playerid, style, duration, Float:letterx, Float:lettery);
public UpdateTimeTextSize(playerid, style, duration, Float:letterx, Float:lettery)
{
    if( letterx < StatusTextLetterSize[style][0] )
	{
		letterx += StatusTextLetterSize[style][0] / 20.0;
	}
    if( lettery < StatusTextLetterSize[style][1] )
	{
		lettery += StatusTextLetterSize[style][1] / 20.0;
	}
    PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], letterx, lettery);
    PlayerTextDrawShow( playerid, pStatusInfo[playerid][StatusText][style] );
    if( letterx >= StatusTextLetterSize[style][0] )
    {
        PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], StatusTextLetterSize[style][0], StatusTextLetterSize[style][1]);
        PlayerTextDrawShow( playerid, pStatusInfo[playerid][StatusText][style] );
        return 1;
    }
    SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, duration, letterx, lettery);
    return 1;
}

stock TimeTextForPlayer( style, playerid, text[], time = 5000, color = -1, bool:use2text = false, stop2text = 0 )
{
	if(color == -1)
	{
		color = StatusTextColors[style];
	}
    switch( style )
    {
        case TIMETEXT_POINTS:
        {
            FadeTextdraw(playerid, _:pStatusInfo[playerid][StatusText][style], StatusTextColors[style], 0xFF, time, 400);
        }
        case TIMETEXT_MIDDLE:
        {
            new Float:letterx, Float:lettery;
            PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], 0.0, 0.0);
            SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, time, letterx, lettery);
			FadeTextdraw(playerid, _:pStatusInfo[playerid][StatusText][style], color, 0xFF, time, 400);
	    }
	    case TIMETEXT_MIDDLE_LARGE:
        {
            new Float:letterx, Float:lettery;
            PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], 0.0, 0.0);
            SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, time, letterx, lettery);
			FadeTextdraw(playerid, _:pStatusInfo[playerid][StatusText][style], color, 0xFF, time, 400);
	    }
	    case TIMETEXT_MIDDLE_SUPER_LARGE:
	    {
            new Float:letterx, Float:lettery;
            PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], 0.0, 0.0);
            SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, time, letterx, lettery);
			FadeTextdraw(playerid, _:pStatusInfo[playerid][StatusText][style], color, 0xFF, time, 400);
	    }
	    case TIMETEXT_BOTTOM:
	    {
     		new Float:letterx, Float:lettery;
     		letterx = StatusTextLetterSize[style][0] / 2.0;
		 	lettery = StatusTextLetterSize[style][1] / 2.0;
            PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], letterx, lettery);
	        SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, time, letterx, lettery);
	        FadeTextdraw(playerid, _:pStatusInfo[playerid][StatusText][style], color, 0xFF, time, 500);
	    }
		case TIMETEXT_TOP_2:
	    {
	        new Float:letterx, Float:lettery;
            PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], 0.0, 0.0);
            SetTimerEx("UpdateTimeTextSize", 10, false, "dddff", playerid, style, time, letterx, lettery);
	    }
	    case TIMETEXT_TOP:
	    {
	        ++pStatusInfo[playerid][StatusIndex];
	        switch(pStatusInfo[playerid][StatusIndex])
	        {
	            case 1:
	            {
	                pStatusInfo[playerid][StatusTime] = GetTickCount();
	                new Float:letterx, Float:lettery;
		            PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], 0.0, 0.0);
		            SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, time, letterx, lettery);
				}
				default:
				{
				    new timeleft = (GetTickCount() - pStatusInfo[playerid][StatusTime]);
					if(timeleft > 0)
					{
				    	timeleft += 1000;
				    	if(use2text == false)
	        			{
	        			    pStatusInfo[playerid][StatusIndex] = 0;
	        			    TimeTextForPlayer( TIMETEXT_TOP_2, playerid, Status_Text[playerid][TIMETEXT_TOP], timeleft, _, use2text );
	        			}
	        			else
						{
						    if(stop2text) return 1;
						    stop2text = 1;
						    pStatusInfo[playerid][StatusIndex] = 1;
							TimeTextForPlayer( TIMETEXT_TOP, playerid, text, timeleft, _, use2text, stop2text );
						}
						PlayerTextDrawSetString( playerid, pStatusInfo[playerid][StatusText][style], text );
		    			PlayerTextDrawShow( playerid, pStatusInfo[playerid][StatusText][style] );
				    	strmid(Status_Text[playerid][style], text, false, strlen(text), MAX_STATUS_TEXT_LENGTH);
					    KillTimer( pStatusInfo[playerid][StatusTextTimer][style] );
					    pStatusInfo[playerid][StatusTextTimer][style] = SetTimerEx( "HideTextTimer", time, false, "iii", style, playerid, _:pStatusInfo[playerid][StatusText][style]);
						return 1;
				    }
				}
	        }
	    }
    }
    //PlayerTextDrawColor( pStatusInfo[playerid][StatusText][style], StatusTextColors[st] );
    PlayerTextDrawSetString( playerid, pStatusInfo[playerid][StatusText][style], text );
    PlayerTextDrawShow( playerid, pStatusInfo[playerid][StatusText][style] );
    strmid(Status_Text[playerid][style], text, false, strlen(text), MAX_STATUS_TEXT_LENGTH);
    KillTimer( pStatusInfo[playerid][StatusTextTimer][style] );
    pStatusInfo[playerid][StatusTextTimer][style] = SetTimerEx( "HideTextTimer", time, false, "iii", style, playerid, _:pStatusInfo[playerid][StatusText][style]);
    return 1;
}

forward HideTextTimer( style, playerid, textdrawid );
public HideTextTimer( style, playerid, textdrawid )
{
    PlayerTextDrawHide(playerid, PlayerText:textdrawid);
    PlayerTextDrawColor( playerid, PlayerText:textdrawid, StatusTextColors[style] );
    KillTimer(pStatusInfo[playerid][StatusTextTimer][style]);
    switch(style)
    {
        case TIMETEXT_POINTS, TIMETEXT_MIDDLE, TIMETEXT_MIDDLE_LARGE, TIMETEXT_MIDDLE_SUPER_LARGE, TIMETEXT_BOTTOM:
	    {
	        StopFadingTextdraw(playerid, textdrawid);
	    }
    }
    strmid(Status_Text[playerid][style], "\0", false, strlen("\0"), 4);
    return 1;
}

#if !defined TIMEDRAW_FADE_STAGE_TIME
        #define TIMEDRAW_FADE_STAGE_TIME (50)
#endif

forward TextdrawFader(playerid, textdrawid, color, alpha, time, stage);
public TextdrawFader(playerid, textdrawid, color, alpha, time, stage)
{
    static sTimer[32];
    if(playerid == INVALID_PLAYER_ID)
    {
        format(sTimer, sizeof (sTimer), "k_fading_%d", textdrawid);
    }
    else
    {
    	format(sTimer, sizeof (sTimer), "k_fading_p_%d", textdrawid);
	}
    stage = (stage + 1) % (time);
    if (stage >= time)
    {
        if(playerid == INVALID_PLAYER_ID)
        {
    		TextDrawShowForAll(Text:textdrawid);
    	}
    	else
    	{
            PlayerTextDrawShow(playerid, PlayerText:textdrawid);
    	}
    	stage = GetPVarInt(playerid, sTimer);
    	KillTimer(stage);
        return;
    }
    else
    {
        alpha -= 8;
        if(alpha < 0)
		{
			alpha = 0;
			if(playerid == INVALID_PLAYER_ID)
        	{
				TextDrawColor(Text:textdrawid, (color & 0xFFFFFF00) | alpha);
				TextDrawBackgroundColor(Text:textdrawid, alpha);
				TextDrawShowForAll(Text:textdrawid);
			}
			else
			{
			    PlayerTextDrawColor(playerid, PlayerText:textdrawid, (color & 0xFFFFFF00) | alpha);
				PlayerTextDrawBackgroundColor(playerid, PlayerText:textdrawid, alpha);
				PlayerTextDrawShow(playerid, PlayerText:textdrawid);
			}
			StopFadingTextdraw(playerid, textdrawid);
			return;
		}
		if(playerid == INVALID_PLAYER_ID)
 		{
		    TextDrawColor(Text:textdrawid, (color & 0xFFFFFF00) | alpha);
			TextDrawBackgroundColor(Text:textdrawid, alpha);
			TextDrawShowForAll(Text:textdrawid);
        }
		else
		{
		    PlayerTextDrawColor(playerid, PlayerText:textdrawid, (color & 0xFFFFFF00) | alpha);
			PlayerTextDrawBackgroundColor(playerid, PlayerText:textdrawid, alpha);
			PlayerTextDrawShow(playerid, PlayerText:textdrawid);
		}
		SetPVarInt(playerid, sTimer, SetTimerEx("TextdrawFader", TIMEDRAW_FADE_STAGE_TIME, false, "iiiiii", playerid, textdrawid, color, alpha, time, stage));
    }
    return;
}

stock FadeTextdraw(playerid = INVALID_PLAYER_ID, textdrawid, color, alpha = 0xFF, time, delay = TIMEDRAW_FADE_STAGE_TIME)
{
    static sTimer[32], tid;
    if(playerid == INVALID_PLAYER_ID)
    {
        format(sTimer, sizeof (sTimer), "k_fading_%d", textdrawid);
	    TextDrawColor(Text:textdrawid, color);
	    TextDrawBackgroundColor(Text:textdrawid, alpha);
	    TextDrawShowForAll(Text:textdrawid);
    }
    else
    {
        format(sTimer, sizeof (sTimer), "k_fading_p_%d", textdrawid);
	    PlayerTextDrawColor(playerid, PlayerText:textdrawid, color);
	    PlayerTextDrawBackgroundColor(playerid, PlayerText:textdrawid, alpha);
	    PlayerTextDrawShow(playerid, PlayerText:textdrawid);
    }
    tid = GetPVarInt(playerid, sTimer);
    KillTimer(tid);
    SetPVarInt(playerid, sTimer, SetTimerEx("TextdrawFader", delay, false, "iiiiii", playerid, textdrawid, color, alpha, time / TIMEDRAW_FADE_STAGE_TIME / 2, 0));
    return 1;
}

stock StopFadingTextdraw(playerid, textdrawid)
{
    static sTimer[32], tid;
    if(playerid == INVALID_PLAYER_ID)
    {
        format(sTimer, sizeof (sTimer), "k_fading_%d", textdrawid);
    }
    else
    {
    	format(sTimer, sizeof (sTimer), "k_fading_p_%d", textdrawid);
	}
    tid = GetPVarInt(playerid, sTimer);
    KillTimer(tid);
    return 1;
}

CMD:testpoint(playerid, params[])
{
	new ispoint, Float:x, Float:y, Float:z, vehicleid;
	if(sscanf(params, "d", vehicleid)) return SendClientMessage(playerid, -1, "Usage: /testpoint vehicleid");
	GetVehiclePos(vehicleid, x, y, z);
    ispoint = IsPointInPlayerScreen(playerid, x, y, z);
    SendClientMessageFormatted(playerid, -1, "IsPointInPlayerScreen: %d", ispoint);
	return 1;
}

stock IsPointInPlayerScreen(playerid, Float:x, Float:y, Float:z)
{
    new Float:P[3], Float:Dist;
    GetPlayerPos(playerid, P[0], P[1], P[2]);
    if(z - P[2] > 15.0 || P[2] - z > 15.0) return 0;
    Dist = floatsqroot(floatpower((P[0]-x), 2) + floatpower((P[1]-y), 2) + floatpower((P[2]-z), 2));
    if(Dist > 100.0) return 0;
    new Float:cV[3], Float:cP[3], Float:T[3], Float:Ar;
    GetPlayerCameraPos(playerid, cP[0], cP[1], cP[2]);
    GetPlayerCameraFrontVector(playerid, cV[0], cV[1], cV[2]);
    T[0] = cV[0] * Dist + cP[0];
    T[1] = cV[1] * Dist + cP[1];
    T[2] = cV[2] * Dist + cP[2];
    if(z - T[2] > 10.5 || T[2] - z > 10.5) return 0;
    if(Dist < 7.0) return 1;
    Ar = atan2((P[1] - T[1]), (P[0] - T[0]));
    if(Ar - 45.0 < (atan2((P[1] - y), (P[0] - x))) < Ar + 45.0) return 1;
    return 0;
}

stock MatrixTransformVector(Float:vector[3], Float:m[4][4], &Float:resx, &Float:resy, &Float:resz) {
	resz = vector[2] * m[0][0] + vector[1] * m[0][1] + vector[0] * m[0][2] + m[0][3];
 	resy = vector[2] * m[1][0] + vector[1] * m[1][1] + vector[0] * m[1][2] + m[1][3];
  	resx = -(vector[2] * m[2][0] + vector[1] * m[2][1] + vector[0] * m[2][2] + m[2][3]); // don't ask why -x was needed, i don't know either.
}
stock RotatePointVehicleRotation(vehid, Float:Invector[3], &Float:resx, &Float:resy, &Float:resz, worldspace=0)
{
	new Float:Quaternion[4];
 	new Float:transformationmatrix[4][4];
	GetVehicleRotationQuat(vehid, Quaternion[0], Quaternion[1], Quaternion[2], Quaternion[3]);
 	// build a transformation matrix out of the quaternion
  	new Float:xx = Quaternion[0] * Quaternion[0];
   	new Float:xy = Quaternion[0] * Quaternion[1];
    new Float:xz = Quaternion[0] * Quaternion[2];
    new Float:xw = Quaternion[0] * Quaternion[3];
    new Float:yy = Quaternion[1] * Quaternion[1];
    new Float:yz = Quaternion[1] * Quaternion[2];
    new Float:yw = Quaternion[1] * Quaternion[3];
    new Float:zz = Quaternion[2] * Quaternion[2];
    new Float:zw = Quaternion[2] * Quaternion[3];

	transformationmatrix[0][0] = 1 - 2 * ( yy + zz );
 	transformationmatrix[0][1] =     2 * ( xy - zw );
  	transformationmatrix[0][2] =     2 * ( xz + yw );
   	transformationmatrix[0][3] = 0.0;

	transformationmatrix[1][0] =     2 * ( xy + zw );
	transformationmatrix[1][1] = 1 - 2 * ( xx + zz );
 	transformationmatrix[1][2] =     2 * ( yz - xw );
  	transformationmatrix[1][3] = 0.0;

	transformationmatrix[2][0] =     2 * ( xz - yw );
 	transformationmatrix[2][1] =     2 * ( yz + xw );
  	transformationmatrix[2][2] = 1 - 2 * ( xx + yy );
   	transformationmatrix[2][3] = 0;

	transformationmatrix[3][0] = 0;
 	transformationmatrix[3][1] = 0;
  	transformationmatrix[3][2] = 0;
   	transformationmatrix[3][3] = 1;
    // transform the point thru car's rotation
    MatrixTransformVector(Invector, transformationmatrix, resx, resy, resz);
    // if worldspace is set it'll return the coords in global space - useful to check tire coords against tire spike proximity directly, etc..
    if (worldspace == 1) {
    	new Float:fX, Float:fY, Float:fZ;
     	GetVehiclePos(vehid, fX, fY, fZ);
      	resx += fX,resy += fY,resz += fZ;
    }
}
stock AccelerateTowardsAPoint(vehicleid, Float:x, Float:y)
{
    new Float:pos[6];
    GetVehicleVelocity(vehicleid, pos[4], pos[5], pos[2]);
    GetVehiclePos(vehicleid, pos[0], pos[1], pos[3]);
    if(GivesSpeed(pos[4], pos[5], pos[2], x-pos[0], y-pos[1], pos[2]))
	{
		SetVehicleVelocity(vehicleid, x-pos[0], y-pos[1], pos[2]);
	}
}

stock GivesSpeed(Float:x, Float:y, Float:z, Float:newx, Float:newy, Float:newz) // Checks if one velocity is bigger than another.
{
    if(floatsqroot(floatpower(floatabs(x),2)+floatpower(floatabs(y),2)+floatpower(floatabs(z),2))<floatsqroot(floatpower(floatabs(newx),2)+floatpower(floatabs(newy),2)+floatpower(floatabs(newz),2))) return true;
    return false;
}

CMD:av(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
	new vehicleid = GetPlayerVehicleID(playerid), Float:vX, Float:vY, Float:vZ, Float:aX, Float:aY, Float:aZ;
	if(sscanf(params, "F(0.0)F(0.0)F(0.0)", aX, aY, aZ)) return SendClientMessage(playerid, -1, "Usage: /av Optional: angular velocity [x] [y] [z]");
    GetVehicleVelocity(vehicleid, vX, vY, vZ);
    SetVehicleVelocity(vehicleid, vX, vY, vZ);
	if(vX == 0 && vY == 0 && vZ == 0)
    {
 		SetVehicleVelocity(vehicleid, vX, vY, vZ + 0.01); //If X, Y and Z is 0, a velocity won't work
    }
	SetVehicleAngularVelocity(vehicleid, aX, aY, aZ);
	return 1;
}
stock ModifyVehicleAngularVelocity(vehicleid, Float:modifier = 0.0, positive = 0)
{
	new Float:Zangle, Float:Xv, Float:Yv, Float:Zv;
    GetVehicleZAngle(vehicleid, Zangle);
    GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
    switch(positive)
    {
        case 1: Zangle = -Zangle;
    }
    Xv = (modifier * floatsin(Zangle, degrees));
    Yv = (modifier * floatcos(Zangle, degrees));
    SetVehicleAngularVelocity(vehicleid, Yv, Xv, 0);
	return 1;
}
CMD:testm(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
	new Float:modifier, positive;
	if(sscanf(params, "F(0.0)D(0)", modifier, positive)) return SendClientMessage(playerid, -1, "Usage: /testm Optional: [modifier] [positive]");
	ModifyVehicleAngularVelocity(GetPlayerVehicleID(playerid), modifier, positive);
	printf("modifier: %0.2f", modifier);
	return 1;
}
CMD:js(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
 	new vehicleid = GetPlayerVehicleID(playerid), Float:Xv, Float:Yv, Float:Zv, Float:absV;
	GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
	absV = floatsqroot((Xv * Xv) + (Yv * Yv) + (Zv * Zv));
	if(absV < 0.04)
	{
        new Float:Zangle;
        GetVehicleZAngle(vehicleid, Zangle);
        GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
        Xv = (0.11 * floatsin(Zangle, degrees));
        Yv = (0.11 * floatcos(Zangle, degrees));
        SetVehicleAngularVelocity(vehicleid, Yv, Xv, 0);
	}
	printf("absV: %0.2f", absV);
	return 1;
}
CMD:spin(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
 	SetVehicleAngularVelocity(GetPlayerVehicleID(playerid), 0.0, 0.0, 1.0);
	return 1;
}
CMD:fflip(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
    SetVehicleVelocity(GetPlayerVehicleID(playerid), 0.0, 0.0, 0.2);
    SetVehicleAngularVelocity(GetPlayerVehicleID(playerid), 0.2, 0.0, 0.0);
	return 1;
}
CMD:speedboost(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
    new Float:currspeed[3], Float:direction[3], Float:total, vehicleid = GetPlayerVehicleID(playerid);
	GetVehicleVelocity(vehicleid, currspeed[0], currspeed[1], currspeed[2]);
	total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
	total += 0.7;
	new Float:invector[3] = {0.0, -1.0, 0.0};
	RotatePointVehicleRotation(vehicleid, invector, direction[0], direction[1], direction[2]);
	SetVehicleVelocity(vehicleid, direction[0] * total, direction[1] * total, direction[2] * total);
	return 1;
}

forward Turbo_Deduct(playerid, vehicleid);
public Turbo_Deduct(playerid, vehicleid)
{
    new ud, lr, keys;
    GetPlayerKeys(playerid, keys, ud, lr);
    if(!(keys & 8) && !(ud < 0))
    {
        return 1;
    }//(keys & (KEY_VEHICLE_FORWARD | KEY_VEHICLE_BACKWARD | KEY_HANDBRAKE)) == KEY_VEHICLE_FORWARD
	PlayerInfo[playerid][pTurbo]--;
	if(GetVehicleModel(vehicleid) == Reaper)
	{
	    IncreaseVehicleSpeed(vehicleid, 1.015);
	}
	/*else
	{
		switch(random(8))
		{
		    case 3: IncreaseVehicleSpeed(vehicleid, 1.07);
		}
	}*/
 	if(PlayerInfo[playerid][pTurbo] <= 0)
 	{
  		PlayerInfo[playerid][pTurbo] = 0;
  		SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], 0.0);
  		RemoveVehicleComponent(vehicleid, 1010);
  		KillTimer(PlayerInfo[playerid][Turbo_Timer]);
  		if(GetVehicleModel(vehicleid) == Reaper)
  		{
		  	DestroyObject(Nitro_Bike_Object[playerid]);
		}
 	}
 	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], float(PlayerInfo[playerid][pTurbo]));
 	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
 	return 1;
}

forward GetVehicleDriver(vehicle);
public GetVehicleDriver(vehicle)
{
	//new driverid = INVALID_PLAYER_ID;
	//foreach(Player, i)
	//{
 	//	if(GetPlayerState(i) == PLAYER_STATE_DRIVER)
   	//	{
   	//  	if(GetPlayerVehicleID(i) == vehicle)
	//		{
	//		 	driverid = i;
	//		 	break;
	//		}
	//	}
	//}
	return MPGetVehicleDriver(vehicle);
}

forward RespawnPickup(spickupid, type);
public RespawnPickup(spickupid, type)
{
	new pid = CreatePickup(PickupInfo[spickupid][Modelid], PickupInfo[spickupid][Type], PickupInfo[spickupid][PickupX], PickupInfo[spickupid][PickupY], PickupInfo[spickupid][PickupZ], PickupInfo[spickupid][VirtualWorld]);
    PickupInfo[spickupid][Created] = true;
	PickupInfo[spickupid][Pickupid] = pid;
    PickupInfo[spickupid][Pickuptype] = type;
	return 1;
}

stock FindFreePickupSlot()
{
    new pickup = 0, pickupsize = sizeof(PickupSlots);
	for(; pickup < pickupsize; pickup++)
	{
	    if(PickupSlots[pickup] == 0) break;
	}
	return pickup;
}
stock FreePickupSlot(slot)
{
	PickupSlots[slot] = 0;
	return 1;
}

stock CreatePickupEx(type, Float:x, Float:y, Float:z, virtualworld = 0, pickuptype = -1)
{
	new pickupid = FindFreePickupSlot(), cpickupid, model, text3D[33];
	if(pickupid < 0 || pickupid >= MAX_MAP_PICKUPS)
	{
	    printf("No Free Pickup Slots Left - pickupid: %d - type: %d", pickupid, pickuptype);
		return 0;
	}
	PickupSlots[pickupid] = 1;
	switch(pickuptype)
    {
        case PICKUPTYPE_HEALTH: model = 1240;
        case PICKUPTYPE_TURBO: model = 1010;
        case PICKUPTYPE_MACHINE_GUN_UPGRADE: model = 362;
        case PICKUPTYPE_NAPALM_MISSILE: model = Missile_Napalm_Object;
        case PICKUPTYPE_REMOTEBOMBS: model = Missile_RemoteBomb_Object;
        case PICKUPTYPE_HOMING_MISSILE, PICKUPTYPE_FIRE_MISSILE,
			PICKUPTYPE_POWER_MISSILE, PICKUPTYPE_ENVIRONMENTALS,
			PICKUPTYPE_RICOCHETS_MISSILE, PICKUPTYPE_STALKER_MISSILE,
			PICKUPTYPE_LIGHTNING: model = 3790; //3786
		default: model = 3786;
    }
    cpickupid = CreatePickup(model, type, x, y, z, virtualworld);
	//printf("Creating Map pickupid: %d | %d - x: %0.2f - y: %0.2f - z: %0.2f - world: %d", pickupid, cpickupid, x, y, z, virtualworld);
    PickupInfo[pickupid][Pickupid] = cpickupid;
    PickupInfo[pickupid][Modelid] = model;
    PickupInfo[pickupid][Type] = type;
    PickupInfo[pickupid][PickupX] = x;
    PickupInfo[pickupid][PickupY] = y;
    PickupInfo[pickupid][PickupZ] = z;
    PickupInfo[pickupid][VirtualWorld] = virtualworld;
    PickupInfo[pickupid][Pickuptype] = pickuptype;
    PickupInfo[pickupid][Created] = true;
    switch(pickuptype)
    {
        case PICKUPTYPE_HEALTH: text3D = "{FF0000}Health";
        case PICKUPTYPE_TURBO: text3D = "{09FF00}Turbo";
        case PICKUPTYPE_MACHINE_GUN_UPGRADE: text3D = "{C3FAC8}Machine Gun Upgrade";
        case PICKUPTYPE_HOMING_MISSILE: text3D = "{B51BE0}Homing Missile";
        case PICKUPTYPE_FIRE_MISSILE: text3D = "{FF9500}Fire Missile";
        case PICKUPTYPE_POWER_MISSILE: text3D = "{FF0000}Power Missile";
        case PICKUPTYPE_NAPALM_MISSILE: text3D = "{FEBF10}Napalm Pickup";
        case PICKUPTYPE_STALKER_MISSILE: text3D = "{DD1FFF}Stalker Missile";
        case PICKUPTYPE_RICOCHETS_MISSILE: text3D = "{0000FF}Ricochet "#cWhite"Missile";
        case PICKUPTYPE_REMOTEBOMBS: text3D = "{09FF00}Remote Bomb";
        case PICKUPTYPE_ENVIRONMENTALS: text3D = "{FAA2E5}Environmental";
        case PICKUPTYPE_LIGHTNING: text3D = "{FFDD00}Lightning";
        default: text3D = "{000000}Unknown Pickup";
    }
    PickupInfo[pickupid][Pickuptext] = Create3DTextLabel(text3D, 0xFFFFFFFF, x, y, z + 0.3, 50.0, virtualworld);
	return pickupid;
}

stock DestroyPickupEx(pickupid)
{
	if(pickupid < 0 || pickupid >= sizeof(PickupInfo)) return 0;
	if(PickupInfo[pickupid][Pickupid] == -1) return 0;
	DestroyPickup(PickupInfo[pickupid][Pickupid]);
	FreePickupSlot(pickupid);
	PickupInfo[pickupid][Pickupid] = -1;
	PickupInfo[pickupid][Modelid] = -1;
    PickupInfo[pickupid][Type] = -1;
    PickupInfo[pickupid][PickupX] = 0.0;
    PickupInfo[pickupid][PickupY] = 0.0;
    PickupInfo[pickupid][PickupZ] = 0.0;
    PickupInfo[pickupid][Created] = false;
    PickupInfo[pickupid][VirtualWorld] = 0;
    PickupInfo[pickupid][Pickuptype] = -1;
    Delete3DTextLabel(PickupInfo[pickupid][Pickuptext]);
	return 1;
}

stock GetPlayerIDFromBot(const name[])
{
    foreach(Bot, i)
    {
		if(!strcmp(Playername(i), name, true)) return i;
    }
    return INVALID_PLAYER_ID;
}

#define va_args<%0> {Float,File,Bit,PlayerText3D,Text,Text3D,Menu,DB,DBResult,Style,XML,Bintree,Group,_}:...
#define va_start<%0> (va_:(%0))

stock va_format(out[], size, fmat[], va_:STATIC_ARGS)
{
        new num_args, arg_start, arg_end;
        // Get the pointer to the number of arguments to the last function.
        #emit LOAD.S.pri   0
        #emit ADD.C        8
        #emit MOVE.alt
        // Get the number of arguments.
        #emit LOAD.I
        #emit STOR.S.pri   num_args
        // Get the variable arguments (end).
        #emit ADD
        #emit STOR.S.pri   arg_end
        // Get the variable arguments (start).
        #emit LOAD.S.pri   STATIC_ARGS
        #emit SMUL.C       4
        #emit ADD
        #emit STOR.S.pri   arg_start
        // Using an assembly loop here screwed the code up as the labels added some
        // odd stack/frame manipulation code...
        while (arg_end != arg_start)
        {
                #emit MOVE.pri
                #emit LOAD.I
                #emit PUSH.pri
                #emit CONST.pri    4
                #emit SUB.alt
                #emit STOR.S.pri   arg_end
        }
        // Push the additional parameters.
        #emit PUSH.S       fmat
        #emit PUSH.S       size
        #emit PUSH.S       out
        // Push the argument count.
        #emit LOAD.S.pri   num_args
        #emit ADD.C        12
        #emit LOAD.S.alt   STATIC_ARGS
        #emit XCHG
        #emit SMUL.C       4
        #emit SUB.alt
        #emit PUSH.pri
        #emit MOVE.alt
        // This gets confused if you have a local variable of the same name as it
        // seems to factor in them first, so you get the offset of the local
        // variable instead of the index of the native.
        #emit SYSREQ.C     format
        // Clear the stack.
        #emit CONST.pri    4
        #emit ADD
        #emit MOVE.alt
        // The three lines above get the total stack data size, now remove it.
        #emit LCTRL        4
        #emit ADD
        #emit SCTRL        4
        // Now do the real return.
}

new g_FORMAT_out[144];
new g_IRCFORMAT_out[256];

SendClientMessageFormatted(playerid, colour, format[], va_args<>)
{
    va_format(g_FORMAT_out, sizeof(g_FORMAT_out), format, va_start<3>);
    if(playerid == INVALID_PLAYER_ID)
	{
		return SendClientMessageToAll(colour, g_FORMAT_out);
	}
    else
    {
    	return SendClientMessage(playerid, colour, g_FORMAT_out);
	}
}
MessageToAdmins(color, format[], va_args<>)
{
    va_format(g_FORMAT_out, sizeof(g_FORMAT_out), format, va_start<2>);
	foreach(Player, i)
	{
    	if(IsPlayerAdmin(i) || PlayerInfo[i][AdminLevel] > 0)
		{
			SendClientMessage(i, color, g_FORMAT_out);
		}
	}
	return 1;
}
GameTextForPlayerFormatted(playerid, format[], time, style, va_args<>)
{
    va_format(g_FORMAT_out, sizeof(g_FORMAT_out), format, va_start<4>);
    if(playerid == INVALID_PLAYER_ID)
	{
		return GameTextForAll(g_FORMAT_out, time, style);
	}
    else
    {
    	return GameTextForPlayer(playerid, g_FORMAT_out, time, style);
	}
}
stock IRC_GroupSayFormatted(groupid, const target[], format[], {Float, _}:...)
{
    va_format(g_IRCFORMAT_out, sizeof(g_IRCFORMAT_out), format, va_start<3>);
    return IRC_GroupSay(groupid, target, g_IRCFORMAT_out);
}

CMD:glvl(playerid, params[])
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	new msg[64];
	format(msg, 64,"Your position is: x: %f y: %f z: %f", x, y, z);
	SendClientMessage(playerid,0xFFFFFFFF, msg);

	GetPointZPos(x, y, z);
	format(msg, 32, "PointZPos: Ground level: %f", z);
	SendClientMessage(playerid, 0xFFFFFFFF, msg);
	MapAndreas_FindZ_For2DCoord(x, y, z);
	format(msg, 32, "MapAndreas: Ground level: %f", z);
	SendClientMessage(playerid, 0xFFFFFFFF, msg);
	return 1;
}

stock IsValidObjectModel(model)
{
	static
		valid_model[] = //credits to Slice
		{
			0b11111111111011111110110111111110, 0b00000000001111111111111111111111,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b11111111111111111111111110000000,
			0b11100001001111111111111111111111, 0b11110111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b00000001111000000111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111100011111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111011111, 0b11111111111111111111111101111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111100000000000001111111111,
			0b11111111111111111111111111111111, 0b11111111111010111101111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111001111111111111,
			0b11111111111111111111111111111111, 0b10000000000011111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111011111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111101011101111111111, 0b11111111111111111111111111110111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111110011,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111100111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111011110111101111,
			0b10000000000000000000000000000000, 0b00000010000010000000010011111111,
			0b00000000001000000100000000000000, 0b11111111101101100101111000000000,
			0b01110000111111111111111111111011, 0b00000000001111111111111111000000,
			0b10011111110000000000001111001100, 0b11111111101111001100000000011110,
			0b00001110110111111100111111111111, 0b11111111111111111111111111001110,
			0b11111000000011111111111111111111, 0b11111111111111111110111101101011,
			0b01000000000000000111111101110111, 0b11010111111111111111000001111100,
			0b11110011111111111111111001111111, 0b01011111111111111111111111111111,
			0b01111110100001111011111010101011, 0b10001001010101100100001000010000,
			0b10100000000000000001010000101010, 0b00001000001111101010111100100000,
			0b11111111111111111111111010100001, 0b00000000011111111111110101111111,
			0b00001111111111111111110000111100, 0b11011110111111001111011011111011,
			0b11111111111001111111110011001110, 0b11111111111111111111111111111111,
			0b01111111111111111111111110111111, 0b01111000111111111111110111111111,
			0b00011100000000010000000000000111, 0b00001111111100001000000000000000,
			0b10101111001001110111110011111000, 0b01010101010101010110100000101011,
			0b01110111110101011111110100101001, 0b01111111111100101110111011111011,
			0b11111111111111111100101111001000, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b00000000011111111111111111111111, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b11111111000000000000000000000000, 0b00010100101000001111111111111111,
			0b11111111101111011111111111000000, 0b00111111111111111111111100000001,
			0b11110000000000000000000000000000, 0b00000101010101010111111111111111,
			0b11110010110111000011111010000000, 0b11111110111110000111110111010000,
			0b00000000000000011111111111111111, 0b00000000000000000000000000000000,
			0b11111111111111111111111111000000, 0b11111111111111111111111111111111,
			0b11011111111111111111111111111111, 0b00000000000000000000000000000111,
			0b00000000000000000000000000000000, 0b11010111111000000000000000000000,
			0b10110011001000101111111111111111, 0b00011000010111010101011111010111,
			0b11011111111111111111010101111111, 0b11111111111111100000000000000011,
			0b11111111111111111111111111111111, 0b11111111111111111100000101111111,
			0b00000000000000000000000111111111, 0b00011000000001111000000000000000,
			0b11111111111111100111100000000100, 0b11110100011011111111110000000000,
			0b11111110001001111111110000000111, 0b11111111110110000100101010101000,
			0b11111111111111111100000000000000, 0b11111111111111111111111111111111,
			0b11101011111011110011111111111111, 0b11111111111111111111111111111111,
			0b00010001000001111100001111111111, 0b00100000000000000000000000000000,
			0b00000000000000000000000000000000, 0b11111101000000000000000000000000,
			0b11110001110101000001111111111111, 0b00000000000001101111010000010010,
			0b11111111111111111111111110000000, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11100001111100000111100000000000, 0b11100110011111111101011111111011,
			0b00000000000000000000000100111001, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000100110000101100111111001100,
			0b11111111111110000000000000000000, 0b00000000000001111111111111111111,
			0b11000001111111011100000110000000, 0b00000111111101111111111111111111,
			0b00000000001000011110000111010010, 0b00111000100111110011110000000000,
			0b00111111111110101000001001111110, 0b00000000000000100001111100000000,
			0b11111111111111111111111100000000, 0b01111111111111111111111111111111,
			0b01011100001111111110101111110111, 0b11100010111111100000000000111111,
			0b11011000011000110011100011111001, 0b01100110000011110001100000010000,
			0b00000111100000000000000000000100, 0b00010111111101100011100001101010,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b11111111101111111000000000000000, 0b01111000000111100000000111111111,
			0b00000000011111110111111110111111, 0b11111111111111111111111111111111,
			0b00000000101001101111111111111111, 0b11111111111111111111111111111110,
			0b10100001000000111111111111111111, 0b11111111111111111111111111111011,
			0b00000000000000000000000000000011, 0b00000000000000100000000000000000,
			0b01110001111111010000000000010000, 0b11111101111101100011011111111111,
			0b10000000011111111111110101010111, 0b11011111100000010011001010110111,
			0b11010011101011111111111111111111, 0b10101010000010010000001111111000,
			0b11111000101111100000111110010110, 0b11111111100000000000000000000001,
			0b11111111111111111111111111111111, 0b01111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111101111111111,
			0b11111111111111111111111111111111, 0b00000000000001111111111111111111,
			0b00111000000000010001000000000010, 0b00000000000011100000000000000000,
			0b00000000000000000000100000000000, 0b00000000000000000000000000000000,
			0b11110101000000000000000000000000, 0b00011111111000000101001000000111,
			0b11110000011110100011011101000000, 0b01111110111111111111111111111111,
			0b10101000000111110100101111011100, 0b11111111111111111111110000111010,
			0b00000000000000000000011111111111, 0b11111111111111111111111111111110,
			0b00001000111111111111111111111111, 0b00000000000000000000000000000000,
			0b00001111111110000000001111111101, 0b00111110000001111111101110100000,
			0b00001111111101111100011111000100, 0b11101010111101010011000111110000,
			0b11101010000000000000000111010001, 0b10001110110101100101000001110101,
			0b11000011111010101011111111111111, 0b11010110101111110000000000111111,
			0b00011111111111111111111111010100, 0b11111111111111111111111111111111,
			0b00111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b10000000001111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b00000000000000111111111111111111,
			0b00000000000000000000000001000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00011111000000000000000000000000,
			0b00011111111111100111111111111111, 0b00000011111111111111111111111110,
			0b00000000000000000000000000000000, 0b00101100000110000000000000010000,
			0b11100000111110000000001000000000, 0b11111000000000011111111100000000,
			0b11010000111111101011111111111111, 0b11001101010100011100011101000011,
			0b11111111111101010011110011100111, 0b01000000000111111001101111111111,
			0b00000000111010111111110010000111, 0b11111111111000000000001111111111,
			0b11111111111111111111111111111111, 0b11111111111011110111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b00000000000001100000001111111111, 0b00000000000000000000000000000000,
			0b11100000000000000000000000000000, 0b00000000000000000000000000000001,
			0b11111111111111111111110000010000, 0b00000111111111111111111111111111,
			0b11111111111111111110100000000000, 0b11111111111111111111111110111111,
			0b00000011100001111111111111111111, 0b00000000001100000000000000000000,
			0b01100110001011010000000000000000, 0b11111111111111111111111111111111,
			0b00000111111111111111111111111111, 0b00000000000000000000000011111110,
			0b11111111110100000000000000000000, 0b00000000000000000111111111101011,
			0b01100000000000000000000110011100, 0b11111111111111111111111111101010,
			0b11111100000000000111111111111111, 0b00000000000000000000000001111111,
			0b11101111000000000000000000000000, 0b11111110111111111111111111111111,
			0b11111111111111111111011111111111, 0b11000000001000000000000011011001,
			0b11011111111111111111111111111111, 0b11100000011000000000011111111110,
			0b00000000001111100011111111111111, 0b00011110111111000000000000000000,
			0b11001111111100001001011111110100, 0b00110001110001111000011101011110,
			0b00000000000000000000000001110110, 0b11111111111111111100000000000000,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b00111111111111111111111111111111,
			0b00000000000000000000000000000000, 0b11000000000000000000000000000000,
			0b00000000000000011111111111111111, 0b11101111111111110100001000000000,
			0b00001010000000001111111111111111, 0b00001100000110011000000000000000,
			0b01010011111111111111111111000000, 0b11000001111111111100000000000100,
			0b11111111111111111111111111111111, 0b11001111110000000000111111111111,
			0b11111111111111111111111111111111, 0b00001111111111111111111111011111,
			0b00000011100000000000111000100000, 0b11111111111111111110000000100000,
			0b11111111111001111111111111111111, 0b11111111111111111111111111111111,
			0b00000000000000000000000011111111, 0b10000000000000000000000000000000,
			0b11111111111111111111111111111111, 0b11111111111111111111111111001111,
			0b00000000000000000111111000001111, 0b00000000000000000000000000000000,
			0b11110111100000000000000000000000, 0b00111111111100001011111111111111,
			0b10110111101010010000000000000000, 0b11010000111111110001011011101010,
			0b10000011100000101101001011010000, 0b11111111111110000100000010111101,
			0b11110011011111110100001100011111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b00000000000110011111111111111111,
			0b00001111100000000000000000000000, 0b10000000000000001011111010000000,
			0b11100100000001111000000000000000, 0b00000000000000000000000000000011,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111011,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b00001110001111111101111001011011,
			0b00011110011000011100011000111100, 0b11000000001011111111111110010001,
			0b01111111111111111101101111111111, 0b00111111111111111010100001110010,
			0b01111111111000000100000001011000, 0b00000000001110000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000111000000000000000,
			0b01000001000100000011101000000001, 0b11001111100110110000000000111010,
			0b00000000000000000000000000000000, 0b11111000000000000100000000000000,
			0b01000000001000000001111110111111, 0b11111111111011100111000000000000,
			0b11111111111111111111111111111111, 0b00001111111111111111111111111111,
			0b11111111110000000000000000000000, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111100001111,
			0b11111111111111111111111111111111, 0b01111111101111011111111111111111,
			0b00100001000000000000000000000010, 0b10110111011001100111011000001000,
			0b00000000001000000000000010000111, 0b10000100000000011000001111100000,
			0b00000000000000000000000000000100, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b11111111111111111000000000000000,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11010111111111111111111111111101, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111100000011111111111111111111,
			0b11111111111111111111111111110011, 0b11111111111111111111100011111111,
			0b11111111111111111000000111111111, 0b11111111111111000011111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111110111111111, 0b00000000111101111111111111101111,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b11111111111111100000000000000000,
			0b00000001111111111111111111111111, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111000000011111110111111111, 0b11111111111111111111111111111111,
			0b11111111111111101111111111111111, 0b00000111111111111111111111111111,
			0b00001111111111111111111111111111, 0b01110100111101000100000111110000,
			0b10101000000000000000000000000001, 0b00000000111101000000000000000011,
			0b00000000111111000000000000000000, 0b00001001000111000000000000000000,
			0b00100010100000100000000000000000, 0b11111111111110001100000000100100,
			0b11111111111111111111111111111111, 0b01110000011101100011111001111010,
			0b11111000000000000000000000011110, 0b11000001111101100000111111111111,
			0b00000000011111111111111111101110, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b11111111111111111111111100000000,
			0b11111110001111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b01010111111111111111111111111111,
			0b01010101010101010101010101010101, 0b01010101000101010101010101010101,
			0b01010101010101010101010101010101, 0b10101010101010000101010101010101,
			0b01111010111111111111111111111010, 0b00000000111010101101100000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b10000000000000111100000000000000,
			0b11110000000000000000000000000101, 0b11111111111111111111111011111111,
			0b11111111111111111111111111111111, 0b11111101101101101100111111100001,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b00000000000000000000000000011111,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000101011000000000000, 0b01111011000000100000000000100000,
			0b11000011111111010000111111011000, 0b11111011100011110110111001111001,
			0b11001101111111110110000111100111, 0b00000101011110110000000001111110,
			0b11111111111111110000000000000000, 0b11111111110111111111111111111111,
			0b11111111111111111111111111111111, 0b00100011011111111111111111111111,
			0b00000000000000000000000000000001, 0b00000000000000000000000000000000,
			0b11111111000000000000000000000000, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b00000111111111111111111111111111, 0b00000000000000000000000000000000,
			0b11111111111111111111111111111111, 0b00000000001111111111111111111111,
			0b00000000010000000000000000000001, 0b00000011100000000000000000000000,
			0b00000000000000000000001111101010, 0b11111111111111110000000000000000,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b10111111111111111111111111111111, 0b11111111111111111100111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b01111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111110011111111111, 0b11101111111111111111000111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11111111111111111111111111111111, 0b11111111111111111111111111111111,
			0b11110000000001111111111111111111, 0b00001111111111111111111111111111,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00000000000000000000000000000000,
			0b00000000000000000000000000000000, 0b00100000000000000000000000000000
		};
	if (model > 19901)
	{
		return 0;
	}
	model -= 320;
	if (model < 0)
	{
		return 0;
	}
	return (valid_model[model >> 5] & (1 << (model & 0x1F)));
}

/*        Old Versions

	***: Version 1.0 Beta

	Missile Firing System
	Missile Accuracy / Missile Missing feature
	Missile Locking / Homing feature
	Missile / Energy switching feature
	Missile Damage Stacking System
	Missile Hitbar System
	Map System along witha  Map Previewing System
	Twisted Metal Audio System
	Race Temporary Quit Progress system

	15/07/2012 - 25/08/2012: v0.5

	Added multiple gaming lobbies
	You can join different games, each game can hold up to 32 players
	Each game has randomized gamemodes and mapping
	All vehicles now have close-to-perfect missile shooting offsets
	Energy now regenerates over time after consumption
	Finished the completely Dynamic Map System
	Fixed napalm radius damage
	Fixed missile light rotations
	Fixed random speed boosting
	Fixed team last man standing team textdraws
	Fixed missile hitting and targeting team players
	Fixed the score box for deathmatch, hunted & last man standing
	Fixed spawning for high pingers
	Fixed EMP not unfreezing players
	Fixed interpolation issues
	Fixed most mmisile offset issues

	07/07/2012 - 15/07/2012: v0.4

	Added current game info at join
	Missile accuracy feature - All missiles now move smoothly and have accuracy
	Missiles can now 'miss' vehicles because of not having great accuracy
	Temporary race quit progress system - If you leave / crash / lose connection while race mode is on, your
	progress is saved and will be reloaded on relog (only if the same race mode is happening)
	Stopped vehicle turning added
	Free camera mode added
	Burnout jump re-enabled
	Burnout while having turbo on added
	You cannot shoot vehicles that are behind of you
	Finished Stalker missile, the more you power it up, the more accuracy it has (even more accuracy than a homing misile if charged fully).
	Updated /tutorial - added gamemodes and weapons
	Slowered missiles

	28/03/2012 - 04/07/2012: v0.3

	Account system added
	Added XP and Ranks
	Added Sweet Tooth's spikes infront
	Fixed Hammerhead's Special
	Fixed textdraw fading
	Added the position box, shows positions 1st - 3rd and your position
	Added the Race Gamemode (A.K.A Deathrace, but a replica of TM PS3 race mode)
	Added machine gun sprite and how much machine guns you have left above the sprite
	Race positioning and box working perfectly now
	Added The first Environmental Weapon (Suburbs Ferris Wheel)
	More efficient & accurate missile checks
	Fixed a bug with the new missile checking whereas missiles wouldn't damage a vehicle
	Hacker Protection: Added Anti vehicle mod hacks
	Added Killstreak bonuses!
	Added Energy attacks! Click N to switch your HUD to energy and N to switch back to missiles!
	(EMP [Freeze], Invisiblity, [Absorbtion] Shield, [Super] Mines)
	Added Assists
	Made the information list work on cache
	Enabled Registration System
	Added information at registration for players to learn about Twisted Metal: SA-MP
	Fixed some player crashing issues, players shouldn't crash as often anymore
	Added Team Deathmatch Gamemode! You can select teams using the Mouse Textdraw Clicking Feature!
	The team with the most score at the end of a match wins!
	Your team will show at GREEN, and the rival's team will show as RED!
	Added Hunted, Team Hunted, Last Man Standing, Team Last Man Standing!

	09/10/2011 - 27/03/2012: v0.2

	Environmental missiles finished for downtown
	Fixed object sync
	Fixed delay between missile firing
	Fixed the class selecting spawn bug
	Fixed all the missile bugs
	Fixed the missile explosion bug
	Fixed machine guns for most vehicles
	Alot of bug fixes and optimizations
	Fixed missile shooting recoil (more accurate calculations and offsets)
	Fixed all pickups
	Fixed colours
	Fixed missile shooting
	Fixed Environmental missiles
	Fixed death arrays
	Gascan renamed to Napalm
	Redesigned audio system, removed Incognito's Audio Plugin, the server now uses audio streams
	Redesigned Textdraws, textdraws made to match Twisted Metal PS3's & Black's design combined, which is much simplier
	Twisted Metal PS3's textdraw system
	Added Burnout system
	Added Mega Guns (Upgraded Machine Guns)
	Mr. Grimm renamed to Repear to match Twisted Metal PS3
	Added Repear's Flame Saw (Do a wheelie to activate it)
	Added Ricochet missiles
	Added Remote Bombs
	Added Shadow's Death Coffin
	Fixed Spectre's special not having a homing ability
	Added a new class selection
	Added hitbars to outlaw's and thumpers special
	Added missile damage stacking.
	Added damage close and damage far for certain specials
	Added Reaper's RPG Alternative Special
	Fixed missiles bugging after awhile
	Fixed missile damage stacking due to it stacking when a different missile type hit
	Added 3 Maps, Skyscrapers (SF Rooftops) - Suburbs (Bayside) - Hanger 18 (SF Airport)
	Fixed a bug that caused people not able to shoot
	Added cinematic viewing of maps for the first time before spawning
	Finished Junkyard Dog's special (Taxi bomb and diversion)
	Added Vermin's rat rocket ontop of it's roof
	Tweaked Missile Firing - Missiles has a VERY slight chance of colliding with vehicles now!
	Fixed the car trading bug
	Fixed some issues with outlaw's machine gun not aiming correctly
	Fixed health bar not returning green on respawn
	Added Hammerhead
	Added Hammerhead's Special (RAM Attack - This is deadly and cannot be avoided)
	Hammerhead's special is weaker than Darkside's RAM

    05/06/2011 - 27/08/2011: v0.1

	Holding The Machine Gun Fire Key, Will Now Make Automatic Rapid Machine Gun Fire, Instead Of Clicking it Every Time.
	Crazy 8 / No Face - has been removed due to samp limitations.
	Thumper - has been added, from twisted metal 4!
	Thumper's Special Has Been Added.
	Looking to adding sweet tooth's special now, because fire missiles now have their slight homing ability that sweet tooth's 20 missiles have.
	Gave Fire Missiles Their "Slight" Homing Ability
	Invisility Ability Added, it takes 25% of your energy! (/invisibility)
	Missiles now won't hit invisible vehicles.
	Energy Bar is now fully functional.
	Updated Spectre's Special
	Fixed Health Pickups
	Reduced Lag.
	Random chat messages have been implemented
    Updated Colours based on vehicle selected
	Reduced Lag on vehicle selection
	Fixed Vehicle selections screen
	Fixed some Exploits
	Added Automatic Flip.
	Sweet Tooth's special finally added! he shoots a burst of 20 missiles, you don't want to get in his way!
	Energy ("perks") removed from keyboard hitting, you now use commands
	/jump - obvious
	/freeze - shoot a freeze missle
	/invisibility - obvious
	/mine - plant a mine on the ground, if you hit it, it exploits or can be detonated again by retyping the command
	I was over using char arrays to the max, I got so addicted to them I over using them causing alot of bugs.
	ALOT of timer and objectid bugs fixed.
	Beginning the Map changing/loading system
	Fixed a turbo bug
	Attempted to fix Sweet Tooth's special and applied it to all vehicles (meaning the fix)
	You can now scroll through the missile list correctly! if your at your last missile and click down it will go back to the first and etc!
	Roadkill special added!
	New designed audio system, users with the audio plugin may have it just like the real thing!
	Re-wrote the timer system, fixed sweet tooth's missiles and other missiles that were not working properly/going through vehicles.
	Re-wrote Roadkill's special
	Increased the overall speed of certain things
	Vehicles lights are now automatically turned on
	Napalm finally complete, use LCTRL to fire and bring it down!
	Fixed the floating fires in the air
	New administration system! registration and login is here!
	Map system coming soon

	22/05/2011:
	Server Put On Hold - Got Exams until 16th June.

	21/05/2011:
	Brimstone Special Made.
	Mr. Grimm's Special In Progress.

	19/05/2011:
	Fixed Outlaw's Special a bit more
	Updated Spectre's Ghost Missile.

	18/05/2011:
	Changed machine gun's object
	Third Special Added: Spectre's Ghost missile! flys through anything to hit it's target

	17/05/2011:
	Fixed Missile firing, it now does not crash the server.
	Most crashes fixed.
	Sometimes missiles would past right through some vehicles, this has been improved a bit.
	Machine gun crashing the server has been fixed
	Added the first special ig! - Darkside's ramming special... coming up next iss... Outlaw!
	Second special added: Outlaw's gun turrent of death! coming up next... who knows?

	15/05/2011:
	Been working hard, thanks for the traffic. got a alot of bugs outta the way.
	new way of calculating missile launching. better offsets - better firing
	Weapon switching system! click analog up to scroll up and analog down to scroll down to cycle through missiles/weapons! then simply L Ctrl to fire!

	13/05/2011:
	Fixed Some Object & Pickup Exploits
*/

	/*for(new t = 0; t < Speedometer_Needle_Index; t++)
	{
		pTextInfo[playerid][SpeedoMeterNeedle][t] = TextDrawCreate(531.0 - 152, 280.0 + 135, "~b~.");
	}
 	pTextInfo[playerid][TDSpeedClock][0] = TextDrawCreate(524.000000 - 152, 299.000000 + 135, "MPH");
  	pTextInfo[playerid][TDSpeedClock][1] = TextDrawCreate(509.000000 - 152, 301.000000 + 135, "0");
   	pTextInfo[playerid][TDSpeedClock][2] = TextDrawCreate(491.000000 - 152, 294.000000 + 135, "20");
    pTextInfo[playerid][TDSpeedClock][3] = TextDrawCreate(484.000000 - 152, 280.000000 + 135, "40");
    pTextInfo[playerid][TDSpeedClock][4] = TextDrawCreate(481.000000 - 152, 266.000000 + 135, "60");
    pTextInfo[playerid][TDSpeedClock][5] = TextDrawCreate(483.000000 - 152, 252.000000 + 135, "80");
    pTextInfo[playerid][TDSpeedClock][6] = TextDrawCreate(488.000000 - 152, 238.000000 + 135, "100");
    pTextInfo[playerid][TDSpeedClock][7] = TextDrawCreate(503.000000 - 152, 224.000000 + 135, "120");
    pTextInfo[playerid][TDSpeedClock][8] = TextDrawCreate(526.000000 - 152, 215.000000 + 135, "140");
    pTextInfo[playerid][TDSpeedClock][9] = TextDrawCreate(550.000000 - 152, 224.000000 + 135, "160");
    pTextInfo[playerid][TDSpeedClock][10] = TextDrawCreate(565.000000 - 152, 238.000000 + 135, "180");
    pTextInfo[playerid][TDSpeedClock][11] = TextDrawCreate(571.000000 - 152, 252.000000 + 135, "200");
    pTextInfo[playerid][TDSpeedClock][12] = TextDrawCreate(574.000000 - 152, 266.000000 + 135, "220");
    pTextInfo[playerid][TDSpeedClock][13] = TextDrawCreate(569.000000 - 152, 280.000000 + 135, "240");
    pTextInfo[playerid][TDSpeedClock][14] = TextDrawCreate(563.000000 - 152, 294.000000 + 135, "260");
    pTextInfo[playerid][TDSpeedClock][15] = TextDrawCreate(531.000000 - 152, 270.000000 + 135, ".");
    TextDrawLetterSize(pTextInfo[playerid][TDSpeedClock][15], 0.63, -2.60);
    for(new td = 0; td != 15; td++)
    {
    	TextDrawLetterSize(pTextInfo[playerid][TDSpeedClock][td], 0.320000, 1.200000);
    }*/

stock SafeKick(playerid, reason[])
{
    printf("[System: Kick] - %s(%d) Has Been Kicked For %s", Playername(playerid), playerid, reason);
    GameTextForPlayer(playerid, "~r~Kicked", 5000, 3);
 	SetPlayerInterior(playerid, playerid);
 	SetPlayerVirtualWorld(playerid, 1);
	SetCameraBehindPlayer(playerid);
    Kick(playerid);
	return 1;
}

CMD:reply(playerid, params[])
{
	new id = GetPVarInt(playerid, "LastMessage");
	if(isnull(params)) return SendClientMessage(playerid, RED, "{FF0000}Usage: "#cWhite"/reply (message)");
	if(strlen(params) > 120) return SendClientMessage(playerid, RED, "{FF0000}Error: "#cWhite"Invalid PM Lenght - Your PM Must Be Between 1-120 Characters.");
	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, RED, "Invalid Player!");
	//if(PlayerInfo[id][PMDisabled] == 1) return SendClientMessageFormatted(playerid, RED, ""#cYellow"%s(%d) "#cWhite"Is {FF0000}Not "#cWhite"Accepting His PMs At The Moment.", Playername(id), id);
    //if(IsIgnored[id][playerid] == 1) return SendClientMessage(playerid, RED, "Error: "#cWhite"That Player Is Ignoring You");
	SendClientMessageFormatted(playerid, YELLOW, "PM Sent To %s(%d): %s", Playername(id), id, params);
	SendClientMessageFormatted(id, YELLOW, "PM From %s(%d): %s", Playername(playerid), playerid, params);
	SetPVarInt(id, "LastMessage", playerid);
	//new ircstr[156 + 12];
    //format(ircstr, sizeof(ircstr), "%s(%d) PM To %s(%d): %s", Playername(playerid), playerid, Playername(id), id, params);
	//IRC_GroupSay(gGroupID, ADMIN_IRC_CHANNEL, ircstr);
	return 1;
}
CMD:r(playerid, params[]) return cmd_reply(playerid, params);
CMD:pm(playerid, params[])
{
    new id, message[128];
    if(sscanf(params, "us[128]", id, message)) return SendClientMessage(playerid, RED, "Usage: /pm [Nick / id] [Message]");
    if(id == INVALID_PLAYER_ID) return SendClientMessageFormatted(playerid, RED, "%s Is Not A Valid Player",params);
    if(id == playerid) return SendClientMessage(playerid, RED, "Error: "#cWhite"You Cannot PM Yourself");
	//if(PlayerInfo[id][PMDisabled] == 1) return SendClientMessage(playerid, RED, "Error: "#cWhite"That Player's Private Message Is Currently Disabled.");
    //if(IsIgnored[id][playerid] == 1) return SendClientMessage(playerid, RED, "Error: "#cWhite"That Player Is Ignoring You");

	SendClientMessageFormatted(id, YELLOW, "From %s(%d): %s", Playername(playerid), playerid, message);
    SendClientMessageFormatted(playerid, YELLOW, "To %s(%d): %s", Playername(id), id, message);
    printf("System: Private Message] - %s(%d) PM'ED %s(%d): %s", Playername(playerid), playerid, Playername(id), id, message);
    //new ircstr[156 + 12];
    //format(ircstr, sizeof(ircstr), "%s(%d) PM To %s(%d): %s", Playername(playerid), playerid, Playername(id), id, message);
	//IRC_GroupSay(gGroupID, ADMIN_IRC_CHANNEL, ircstr);
	if(GetPVarInt(playerid, "LastMessage") == INVALID_PLAYER_ID) SendClientMessage(id, 0x00983BFF, ""#cWhite"Use {30AEFC}/reply (/r) "#cWhite"To Quick Reply And {30AEFC}/nopm "#cWhite"To {FF0000}Disable "#cWhite"PMs.");
    if(GetPVarInt(playerid, "LastMessage") != INVALID_PLAYER_ID && GetPVarInt(playerid, "LastMessage") != id) SendClientMessage(id, 0x00983BFF, ""#cWhite"Use {30AEFC}/reply (/r) "#cWhite"To Quick Reply And {30AEFC}/nopm "#cWhite"To {FF0000}Disable "#cWhite"PMs.");
	SetPVarInt(id, "LastMessage", playerid);
	if(IsPlayerNPC(id))
	{
	    new RandomResponse[4][] = {
			"Go away I am sleeping!",
			"Why bother PMing me I'm a bot idiot.",
			"I totally agree.",
			"I'm having my period right now, please hold."
		};
		new RandomRes = random(sizeof(RandomResponse));
    	SendClientMessage(id, YELLOW, RandomResponse[RandomRes]);
	}
	#if defined SAMP_03d
	new Text:txtThumbup;
    txtThumbup = TextDrawCreate(430.0, 300.0, "ld_chat:thumbup"); // Text is txdfile:texture
    TextDrawFont(txtThumbup, 4); // Font ID 4 is the sprite draw font
    TextDrawColor(txtThumbup, 0xFFFFFFFF);
    TextDrawTextSize(txtThumbup, 32.0, 32.0); // Text size is the Width:Height
    TextDrawShowForPlayer(playerid, txtThumbup);
	SetTimerEx("DestroyTextdraw", 5000, false, "i", _:txtThumbup);
	#endif
    return true;
}

CMD:setlevel(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id, level, AdmRank[32];
    if(sscanf(params, "ud", id, level)) return SendClientMessage(playerid, WHITE, "Usage: /setlevel [nick / id] [Level]");
	if(IsLogged[playerid] == 0) return SendClientMessage(playerid, RED, "Error: "#cWhite"You Are Not Logged In Please Log In Using /Login [password]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: "#cWhite"Invalid Nick / id");
    if(level > 10) return SendClientMessage(playerid, RED, "Error: "#cWhite"Max adminlevel is 10!");
	switch(level)
	{
		case 0: AdmRank = "None";
		case 1: AdmRank = "Trial Administrator";
		case 2..9: AdmRank = "Administrator";
		case 10: AdmRank = "Developer";
	}
	PlayerInfo[id][AdminLevel] = level;
	format(GlobalQuery, sizeof(GlobalQuery), "UPDATE `Accounts` SET `AdminLevel` = %d WHERE `Username` = '%s' LIMIT 1", PlayerInfo[id][AdminLevel], Playername(id));
	mysql_function_query(McHandle, GlobalQuery, false, "Thread_NoReturnThread", "i", playerid);
	SendClientMessageFormatted(id, BLUE, "*Admin: Administrator %s Has Set Your Admin Level To %s", Playername(playerid), AdmRank);
	SendClientMessageFormatted(playerid, YELLOW, "*Admin: You have set %s's admin level To %d / %s", Playername(id), level, AdmRank);
	return 1;
}

CMD:tadmins(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
 	new string[64];
	SendClientMessage(playerid, BLUE, "|-__________Admins Online__________-|");
	new AdminCount = 0, AdmRank[32];
	foreach(Player, i)
	{
 		if(IsLogged[i])
 		{
			if(PlayerInfo[i][AdminLevel] >= 1 && PlayerInfo[i][AdminLevel] <= 10 && !IsPlayerAdmin(i))
			{
				AdminCount++;
				switch(PlayerInfo[i][AdminLevel])
				{
					case 0: AdmRank = "None";
					case 1: AdmRank = "Trial Administrator";
					case 2..9: AdmRank = "Administrator";
					case 10: AdmRank = "Developer";
				}
				format(string, 128, "%s(%d) Level: %s",Playername(i) ,i,AdmRank);
				SendClientMessage(playerid, LIME, string);
			}
	 	 	else if(IsPlayerAdmin(i))
			{
   				AdminCount++;
				format(string, 128, "%s(%d) Level: Sexy",Playername(i) ,i);
				SendClientMessage(playerid, LIME, string);
			}
		}
	}
	if (AdminCount == 0) SendClientMessage(playerid, ROYALBLUE, "Sorry No Admins Are Currently Online");
	SendClientMessage(playerid, BLUE, "[__________________________________]");
	return 1;
}
CMD:admins(playerid, params[])
{
	SendClientMessage(playerid, ROYALBLUE, "Sorry But, We Do Not List Our Administrators In Game.");
	return 1;
}
CMD:freeze(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, WHITE, "Usage: /Freeze [playerid / part of name]");
 	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");
 	if(IsLogged[playerid] == 0) return SendClientMessage(playerid, RED,"Error: You Are Not Logged In Please Log In Using /Login [password]");

	TogglePlayerControllable(id, false);
	SendClientMessageFormatted(id, BLUE, "Admin: An Administrator Has Frozen You", Playername(playerid),playerid);
	SendClientMessageFormatted(playerid, YELLOW, "Admin: You Have Frozen %s(%d)", Playername(id),id);
	return 1;
}
CMD:unfreeze(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
	new id, str[128];
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, WHITE, "Usage: /Unfreeze [playerid / part of name]");
 	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");
 	if(IsLogged[playerid] == 0) return SendClientMessage(playerid, RED,"Error: You Are Not Logged In Please Log In Using /Login [password]");

	TogglePlayerControllable(id, true);
	SetCameraBehindPlayer(playerid);
	SendClientMessage(id, BLUE, "An Administrator Has Unfrozen You");
	format(str, sizeof(str), "Admin: You Have Unfrozen %s(%d)", Playername(id),id);
	SendClientMessage(playerid, YELLOW, str);
	return 1;
}
CMD:setscore(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id, score;
	if(sscanf(params, "ui", id, score)) return SendClientMessage(playerid, WHITE, "Usage: /Setscore [playerid / part of name] [Score]");
 	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xFF00AAFF, "Error: Player is not connected!");
  	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");
  	if(score > 1000000) return SendClientMessage(playerid, RED, "Error: Invalid Score! (0-1000000)");
	if(IsLogged[playerid] == 0) return SendClientMessage(playerid, RED,"Error: You Are Not Logged In Please Log In Using /Login [password]");

	SetPlayerScore(id, score);
	SendClientMessageFormatted(id, BLUE, "*ADMIN: Administrator %s(%d) Has set your Score To %d", Playername(playerid),playerid, score);
	SendClientMessageFormatted(playerid, YELLOW, "*ADMIN: You have set %s(%d)'s Score To %i", Playername(id),id, score);
	return 1;
}
CMD:setmoney(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id, money;
	if(sscanf(params, "ui", id, money)) return SendClientMessage(playerid, WHITE, "Usage: /setmoney [Nick/id] [Money]");
 	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid nick/id");
	//if(IsLogged[playerid] == 0) return SendClientMessage(playerid, RED,"Error: You Are Not Logged In Please Log In Using /Login [password]");
	PlayerInfo[id][Money] = money;
	SendClientMessageFormatted(id, BLUE, "Admin: Administrator %s(%d) Has Set Your Money To {19E03D}$%i", Playername(playerid), playerid, money);
	SendClientMessageFormatted(playerid, YELLOW, "Admin: You Have Set %s(%d)'s Money To {19E03D}$%d", Playername(id), id, money);
	return 1;
}
CMD:setinterior(playerid, params[])
{
   	if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
   	new id;
   	if(sscanf(params, "i", id)) return SendClientMessage(playerid, WHITE, "Usage: /setinterior [interiorid]");
 	SetPlayerInterior(playerid, id);
	return 1;
}
CMD:setworld(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
   	new id;
   	if(sscanf(params, "i", id)) return SendClientMessage(playerid, WHITE, "Usage: /setworld [worldid]");
 	SetPlayerVirtualWorld(playerid, id);
	return 1;
}
CMD:world(playerid, params[])
{
	new str[60];
	format(str, sizeof(str), "Current Virtual World: %d", GetPlayerVirtualWorld(playerid));
	return SendClientMessage(playerid, ANNOUNCEMENT, str);
}
CMD:setweather(playerid, params[])
{
	if(PlayerInfo[playerid][AdminLevel] >= 1 || IsPlayerAdmin(playerid))
	{
	    new weather;
		if(sscanf(params, "i", weather)) return SendClientMessage(playerid, White, "Usage: /SetWeather [weatherid]");
		SetWeather(weather);
		SendClientMessageToAll(COLOR_GREY, "The Weather Has Been Changed!");
	}
	return 1;
}
CMD:amuteall(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
 		if(i != playerid) Muted[i] = 1;
   		SendClientMessage(playerid, PINK, "All Players Have Been Muted By An Administrator.");
	}
	return 1;
}
CMD:aunmuteall(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
 		Muted[i] = 0;
   		SendClientMessage(playerid, PINK, "All Players Have Been Unmuted By An Administrator.");
	}
	return 1;
}
CMD:mute(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
	new id, reason[50];
 	if(sscanf(params, "uS(No Reason)[50]", id, reason)) return SendClientMessage(playerid, COLOR_WHITE, "Usage: /mute [id] [reason]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid Nick/id");
	if(Muted[id] == 1) return SendClientMessageFormatted(playerid,RED,"Error: %s(%d) Is Already Muted",Playername(id),id);
	SendClientMessageFormatted(INVALID_PLAYER_ID, YELLOW, "Admin Mute: An Administrator Has Muted %s(%d) - (Reason: %s)", Playername(id), id, reason);
 	Muted[id] = 1;
	return 1;
}
CMD:unmute(playerid, params[])
{
    if(PlayerInfo[playerid][AdminLevel] == 0 && !IsPlayerAdmin(playerid)) return 0;
	new id;
 	if(sscanf(params, "u", id)) return SendClientMessage(playerid, COLOR_WHITE, "Usage: /Unmute [id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "Error: Invalid Nick/id");
	if(Muted[id] == 0) return SendClientMessageFormatted(playerid,RED,"Error: %s(%d) Is Not Muted",Playername(id),id);
	SendClientMessageFormatted(INVALID_PLAYER_ID, YELLOW, "Admin Unmute: An Administrator Has Unmuted %s(%d)", Playername(id), id);
 	Muted[id] = 0;
	return 1;
}

public IRC_OnConnect(botid, ip[], port)
{
	new string[96];
	printf("[IRC] - IRC_OnConnect: Bot id: %d Has Connected To %s: %d", botid, ip, port);
	IRC_AddToGroup(gGroupID, botid);
	format(string, sizeof(string), "ghost %s "#IRC_BOT_PASSWORD"", gBotNames[botid - 1]);
	IRC_SendRaw(botid, string);
	//IRC_SendRaw(botid, ":PRIVMSG NickServ REGISTER "#IRC_BOT_PASSWORD" admin@lvcnr.net");
	IRC_SendRaw(botid, ":PRIVMSG NickServ IDENTIFY "#IRC_BOT_PASSWORD"");
	IRC_JoinChannel(botid, IRC_CHANNEL);
	IRC_JoinChannel(botid, ECHO_IRC_CHANNEL);
	IRC_JoinChannel(botid, ADMIN_IRC_CHANNEL, IRC_BOT_ADMIN_CHAN_KEY);
	return 1;
}
public IRC_OnDisconnect(botid, ip[], port, reason[])
{
	//printf("IRC_OnDisconnect: Bot id: %d Has Disconnected From %s: %d (%s)", botid, ip, port, reason);
	IRC_RemoveFromGroup(gGroupID, botid);
	return 1;
}
public IRC_OnConnectAttempt(botid, ip[], port)
{
	//printf("IRC_OnConnectAttempt: Bot id: %d Attempting To Connect To %s: %d...", botid, ip, port);
	return 1;
}
public IRC_OnConnectAttemptFail(botid, ip[], port, reason[])
{
	if(strfind(reason, "No connection could be made because the target machine actively refused it", true, 0) != -1) return 1;
	//printf("[IRC] - IRC_OnConnectAttemptFail: Bot id: %d Failed To Connect To %s: %d (%s)", botid, ip, port, reason);
	return 1;
}
public IRC_OnJoinChannel(botid, channel[])
{
	printf("[IRC] - IRC_OnJoinChannel: Bot id: %d Has Joined Channel %s", botid, channel);
	return 1;
}
public IRC_OnLeaveChannel(botid, channel[], message[])
{
	printf("[IRC] - IRC_OnLeaveChannel: Bot id: %d Has Left The Channel %s (%s)!", botid, channel, message);
	return 1;
}
public IRC_OnKickedFromChannel(botid, channel[], oppeduser[], oppedhost[], message[])
{
	printf("[IRC] - IRC_OnKickedFromChannel: Bot id: %d Kicked By %s (%s) From Channel %s (%s)", botid, oppeduser, oppedhost, channel, message);
    IRC_JoinChannel(botid, channel);
	return 1;
}
public IRC_OnUserDisconnect(botid, user[], host[], message[])
{
	printf("[IRC] - IRC_OnUserDisconnect: User: %s Has Disconnected! (%s)" , user, message);
	return 1;
}
new iLast_Nick_Change[32],
	iLast_User_Join[32];
public IRC_OnUserJoinChannel(botid, channel[], user[], host[])
{
	if(strcmp(iLast_User_Join, user, false) == 0) return 1;
	printf("[IRC] - IRC_OnUserJoinChannel Bot id: %d User %s Has Joined The Channel!", botid, user);
	if(strcmp(channel, IRC_CHANNEL) == 0)
	{
		format(GlobalString, sizeof(GlobalString), "Welcome To Twisted Metal: SA-MP IRC %s!", user);
		IRC_GroupSay(botid, channel, GlobalString);
	    format(GlobalString, sizeof(GlobalString), "%s Has Joined Twisted Metal: SA-MP IRC!", user);
	    SendClientMessageToAll(BLUE, GlobalString);
    }
    else if(strcmp(channel, ECHO_IRC_CHANNEL) == 0)
	{
		format(GlobalString, sizeof(GlobalString), "Welcome To Twisted Metal: SA-MP Echo IRC Channel %s!", user);
		IRC_GroupSay(botid, channel, GlobalString);
	    format(GlobalString, sizeof(GlobalString), "%s Has Joined Twisted Metal: SA-MP Echo IRC Channel!", user);
	    SendClientMessageToAll(BLUE, GlobalString);
    }
    else if(strcmp(channel, ADMIN_IRC_CHANNEL) == 0)
    {
        format(GlobalString, sizeof(GlobalString), "[IRC] - %s Has Joined Twisted Metal: SA-MP Admin IRC Channel! (Host: %s)", user, host);
        foreach(Player, i)
        {
            if(PlayerInfo[i][AdminLevel] == 0 || !IsPlayerAdmin(i)) continue;
        	SendClientMessage(i, COLOR_ADMIN, GlobalString);
		}
	}
    format(iLast_User_Join, sizeof(iLast_User_Join), "%s", user);
	return 1;
}
public IRC_OnUserLeaveChannel(botid, channel[], user[], host[], message[])
{
	printf("User: %s Has Left Twisted Metal: SA-MP IRC Reason: %s.", user, message);
	format(GlobalString, sizeof(GlobalString), "%s Has Left Twisted Metal: SA-MP IRC!", user);
    SendClientMessageToAll(BLUE, GlobalString);
	return 1;
}
public IRC_OnUserKickedFromChannel(botid, channel[], kickeduser[], oppeduser[], oppedhost[], message[])
{
	printf("[IRC] - IRC_OnUserKickedFromChannel Bot id: %d - User %s Kicked By %s (%s) From Channel %s (%s)", botid, kickeduser, oppeduser, oppedhost, channel, message);
	return 1;
}

public IRC_OnUserNickChange(botid, oldnick[], newnick[], host[])
{
	if(strcmp(iLast_Nick_Change, newnick, false) == 0) return 1;
    printf("[IRC] - IRC_OnUserNickChange (Bot ID %d): User %s Changed Has Nick To %s!", botid, oldnick, newnick);
	format(GlobalString, sizeof(GlobalString), "[IRC] - %s Has Changed His Nick To %s (Host: %s)", oldnick, newnick, host);
    foreach(Player, i)
    {
        if(PlayerInfo[i][AdminLevel] == 0 && !IsPlayerAdmin(i)) continue;
    	SendClientMessage(i, COLOR_ADMIN, GlobalString);
	}
	format(iLast_Nick_Change, sizeof(iLast_Nick_Change), "%s", newnick);
	//if(strcmp(newnick, "Kar", false) == 0 || strcmp(newnick, "Lvcnr", false) == 0)
	//{
    //    IRC_KickUser(botid, "#lvcnr.echo", newnick, "Impersonation");
	//}
	return 1;
}
public IRC_OnUserSetChannelMode(botid, channel[], user[], host[], mode[])
{
	printf("[IRC] - IRC_OnUserSetChannelMode: User: %s on %s Set The Irc Mode To: %s!", user, channel, mode);
	return 1;
}
public IRC_OnUserSetChannelTopic(botid, channel[], user[], host[], topic[])
{
	printf("User %s on %s Set The Topic To: %s!", user, channel, topic);
	return 1;
}
public IRC_OnUserSay(botid, recipient[], user[], host[], message[])
{// Admin Chat
 	if(IRC_IsUserOnChannel(botid, ADMIN_IRC_CHANNEL, user))
	{
		if (message[0] == '@')
		{
  			if(!IRC_IsVoice(botid, ADMIN_IRC_CHANNEL, user)) return 1;
	        format(GlobalString, sizeof(GlobalString), "(IRC Admin Chat) %s: %s", user, message[1]);
	        //MessageToAdmins(COLOR_ADMIN, GlobalString);
	        format(GlobalString, sizeof(GlobalString), "03(Admin Chat)01 %s: %s", user, message[1]);
	        IRC_GroupSay(gGroupID, ADMIN_IRC_CHANNEL, GlobalString);
        }
        return 0;
    }
	printf("IRC_OnUserSay (Bot ID %d): User %s Sent A Message To %s: %s", botid, user, recipient, message);
	return 1;
}
public IRC_OnUserNotice(botid, recipient[], user[], host[], message[])
{
	printf("[IRC] - IRC_OnUserNotice (Bot ID %d): User %s (%s) Sent A Notice To %s: %s", botid, user,host, recipient, message);
	if (!strcmp(message, BOT_1_NICKNAME)) IRC_Notice(botid, user, "You sent me a notice!");
	return 1;
}
#define IRC_PLUGIN_VERSION "1.4.2"
public IRC_OnUserRequestCTCP(botid, user[], host[], message[])
{
	printf("[IRC] - IRC_OnUserRequestCTCP Botid: %d - User %s (%s) Sent A CTCP Request: %s", botid, user, host, message);
	if(strcmp(message, "VERSION") == 0) // Someone sent a CTCP VERSION request
	{
		IRC_ReplyCTCP(botid, user, "VERSION SA-MP IRC Plugin v"#IRC_PLUGIN_VERSION"");
	}
	return 1;
}
public IRC_OnUserReplyCTCP(botid, user[], host[], message[])
{
	printf("[IRC] - IRC_OnUserReplyCTCP Botid: %d - User %s (%s) Sent A CTCP Reply: %s", botid, user, host, message);
	return 1;
}
public IRC_OnReceiveRaw(botid, message[])
{
	new File:file;
	if (!fexist("irc_log.txt")) file = fopen("irc_log.txt", io_write);
	else file = fopen("irc_log.txt", io_append);
	if (file)
	{
		fwrite(file, message);
		fwrite(file, "\r\n");
		fclose(file);
	}
	return 1;
}

/*get map 3x3

new Float: posi[2][3] =
{
    { 3528.0, -4674.0, 0.0 },
    { 3567.0, -4647.0, 0.0 }
};
new Float: ppos[3];

COMMAND:test(playerid, params[])
{
	for(new i = 0; i < 3; i++) ppos[i] = posi[0][i];
	SetPlayerPos(playerid, ppos[0], ppos[1], ppos[2]);
	SetTimerEx("CheckHeight", 200, true, "d", playerid);
	SetPlayerFacingAngle(playerid, 0);
	return 1;
}

forward CheckHeight(playerid);
public CheckHeight(playerid)
{
	TogglePlayerControllable(playerid, 0);
	SetPlayerFacingAngle(playerid, 0);
	if(ppos[0] > posi[1][0]) return 1;
	if(GetPlayerAnimationIndex(playerid))
    {
        new
			animlib[32],
        	animname[32],
			string[50];

        GetAnimationName(GetPlayerAnimationIndex(playerid), animlib, 32, animname, 32);
		if(strcmp(animname, "IDLE_STANCE", true) == 0)
		{
		    format(string, sizeof(string), "%f, %f, %f", ppos[0], ppos[1], ppos[2]);
			SendCustomMessage(playerid, string);
			if(ppos[1] == posi[1][1] || ppos[1] == 10) ppos[1] = posi[0][1], ppos[0] += 3;
			else ppos[1] += 3;
			ppos[2] = 0;
		}
		else ppos[2] += 0.1;
	}
	SetPlayerPos(playerid, ppos[0], ppos[1], ppos[2]);
	return 1;
} */

/*IGN Guide

Weapons and Special Moves

Twisted Metal: SA-MP is all about driving your car to the best of your ability under harsh conditions, and knowing your weapons inside and out. Make no mistake about it, mastering your vehicle and deploying the right weapon at the right time is key to winning Calypso's tournament, and that's why we have this handy-dandy little guide.

The basic weapons:

Machine Gun
The machine gun is your default, built-in weapon.
There is no limit to its ammo - so you never run out of machine gun bullets.
But, the guns do overheat, so pay attention to your Machine Gun Light;
when it turns red, quit shooting for about 10-20 seconds, and let it cool down.
Then you can start up again.
Use the machine gun to terrorize opponents from behind, or to whittle away at their health.
It's not terribly useful, but if you're out of everything, and your opponent is on the run, it's handy.
The machine guns can be upgraded by picking up a Box-like icon.
Like any pick-up, this upgrade is limited. Just for the record, this upgrade kicks butt.
Your guns seem about five times more powerful than before.

Homing
A great tracking weapon, but only useful in bunches.
To effectively use the homing weapon, which is the best tracking weapon of all, fire off one, and then quickly follow up with a second and a third.
It's not terribly powerful with just one shot.

Fire
As the middle child of the projectiles, the fire weapon doesn't track as well as the Homing, and it's not as powerful as the Power, but it strikes an excellent balance in between.
A good weapon for all purposes and one of my favorites.

Power
Incredibly powerful, but without any tracking abilities, Power is a straight, lethal shot.
Theoretically, Power can devastate a small building.
But you'd better have your enemies square in your sights for it to work.

Napalm
A superb weapon that can be shot out in front of the car or dropped behind it - and probably my favorite of all the weapons.
What's so great about the Gas Can is its pure power - and the wonderful collateral damage it causes.
Throw a Gas Can into a crowded deathmatch and everybody takes it up the rump. It never fails.
To use this weapon most effectively, deploy it and then when it's directly over the enemy's head press the same button you used to fire it and the Gas Can comes zooming down directly over the enemy's head.
To drop from behind, press down, up, down, on the d-pad or the left analog. To manually control the blast press L2 again to explode it.

Rico
Rico is short for ricochet.
Ricochet should be considered a skill-based weapon, rather than a basic one, because in order for Rico to achieve maximum damage it must bounce off at least one wall to work correctly.
Rico does a good amount of damage as a straight-forward weapon - it shoots straight forward with no tracking abilities - too.
But it works much better as a rebound weapon.
The more times it rebounds before hitting an opponent, the more damage it does.
Definitely an acquired taste.

Environment
The Environment pick-up doesn't work in all levels, but in the ones where it does work, it performs magnificently.
Essentially, Env works with environmental conditions.
Like for instance, in Zorko Brothers Scrap and Salvage, it works, in Prison Passage it works, in Snowy Roads it works, and essentially whenever there is an Env. Pick-up around, you can use it.
In Scrap and Salvage, press Env at the right time, when a plane is in the air, a bomber will deploy numerous bombs onto your enemies' heads.
It's like magic, it doesn't hurt you, and you don't have to be close for it to damage an enemy on the opposite side of the level. This weapon works in several levels, but not all.

Special
What is so special about this weapon is that it's different for each character/vehicle.
For Roadkill it's a single, or when used correctly, a multiple missile launch.
For Sweet Tooth, the Special is a vehicle transformation and then a 20-rocket flurry that pummels the closest targeted enemy.
Each is unique and powerful. For more on each character/vehicle's special, check the their character.

Misc. pick-ups

Health
Health is health, it's quite plain.
Pick one up to increase your Health bar to stay alive.
Health, however, won't repair the physical performance or look or your car.

Turbo
With a Nitro canister in place, your speed increases about 20%-30%.
You can outrun some enemies and bad situations, and it's crucial to have it again bosses.
Check your lower horizontal bar to see how much you have left.
To use it hit the Square button twice, or if you're using the analog buttons, press R4 (right analog) down and hold.

Black Cubes
Ah, the wonderful secret black cubes.
These little objects unlock, when located and touched, either a new level, or new characters.
Collect all of them to unlock the whole crew of Twisted Metal characters, and to unlock both multiplayer levels.

Helicopters
Should we really thank Calypso? At least for the helicopters, we should.
The helicopters deliver needed goods to the contestants in the contest.
Whether it's weapons or health, the helicopters bring them down with tow lines.
Once you have collected an item from a helicopter, it will bring down another one in about 10-20 seconds.


Energy Attacks

Useful at any time, but especially key in human-to-human deathmatches, the energy attacks are great ways to ruin your enemy's hopes.
You should notice two horizontal bars on your HUD.
The top one, which constantly recharges, measures energy, and when you've used up all of your energy,
you can't attack with one of these.

Freeze (Up, Down, Up)
Probably the most useful and easy on your energy supply, the Freeze projectile is a tracking one,
which temporarily stops your opponent cold.
During that time you can attack him or her unremittingly, without response.
The free lasts about four seconds. To break a freeze, quickly push any controller button.
To avoid receiving a Cheap Shot warning, don't fire a Freeze attack at an already frozen opponent.
If you do, then you'll receive the freeze from your own shot.

Mine (Right, Left, Down)
A weapon that drops from behind your car. It explodes on impact.
Good for narrow passages and enemies that tail gate too closely.

Charge up Mine (Right, Left, Down, hold down for a second)
A land mine that causes more damage. Good for narrow passages and enemies that tail gate too closely.

Invisibility (Left, Left, Down, Down)
Just like it sounds -- you disappear, temporarily. You disappear from sight and radar.
An excellent way to sneak up and pummel an opponent.

Shield (Right, Right, Down, Down)
This energy attack is actually a defensive measure:
it creates a temporary shield around your vehicles that cannot be disrupted for a short amount of time.
It uses a lot of energy.

Jump (Cycle weapons plus cycle weapons, or L1 plus R1)
A great defensive move to avoid being hit by an opponent's low flying attack
(i.e. the Rico, or Phantom's special, for instance).

Rear-fire weapon (does not require energy to attack) (Left, Right, Down, plus Fire Weapon button)
Select any weapon and use these moves to rear-fire that weapon.
Very useful when being tracked at low energy. Very useful. Learn this one, kids.

float CWorldSA::FindGroundZFor3DPosition(CVector * vecPosition)
{
    DEBUG_TRACE("FLOAT CWorldSA::FindGroundZFor3DPosition(CVector * vecPosition)");
    DWORD dwFunc = FUNC_FindGroundZFor3DCoord;
    FLOAT fReturn = 0;
    FLOAT fX = vecPosition->fX;
    FLOAT fY = vecPosition->fY;
    FLOAT fZ = vecPosition->fZ;
    _asm
    {
        push    0
        push    0
        push    fZ
        push    fY
        push    fX
        call    dwFunc
        fstp    fReturn
        add     esp, 0x14
    }
    return fReturn;
}

#define FUNC_FindGroundZFor3DCoord                          0x5696C0 // ##SA##

CREATE TABLE IF NOT EXISTS `Maps` (
  `Map_Name` varchar(32) NOT NULL,
  `Map_Type` int(11) NOT NULL,
  `Mapid` int(11) NOT NULL,
  `Lowest_Z` float NOT NULL default '0',
  PRIMARY KEY ( account_id ),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

*/

/*
					© Karim "Kar" K. F. Cambridge 2010 - 2018
								All Rights Reserved

							   	Twisted Metal: SA-MP

	Unauthorized copying or distribution of this file via any medium is strictly prohibited
	
							Proprietary and confidential
*/

/*
	 * List of authors:
	 *
	 *		Karim K. F. Cambridge (Kar)		-		Founder, Owner & Lead Developer.
	 *
	 * http://www.lvcnr.net
	 * http://wiki.lvcnr.net
	 * https://forum.lvcnr.net
*/