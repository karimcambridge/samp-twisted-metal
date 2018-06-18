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

/* todo

	Make exprience show at end of game (textdraw)

	Profiles

	Find some way to make a lightning attack

	Make the new GUI (make them interchangeable)

*/

/* Testers:

	wHoOpEr
	AndreT
	Nicolas.
	King_Hual
	Niko_boy
	Lorenc_
	Tenshi
	Saurik
	Pghpunkid
	Anthony_Vernon
	Rac3r (AdrenalineX Owner)

*/

/* Credits:

	//29:03:2013 Lorenc_'s reg date
	Nero_3D (missile Y angle help),
	Backwardsman97 (basic missile firing help),
	[NoV]Austin (ricochet reflection),
	Hiddos (Hit bar base),
	King_Hual (Class selection idea),
	wHoOpEr (ideas, major testing),
	RyDeR` (Polygon function), cueball (Trajectory functions)

*/

#if __Pawn >= 0x30A
	#pragma warning push
	#pragma warning disable 207
	#pragma disablerecursion
	#pragma warning pop
#endif

#include <a_samp>

#if defined MAX_PLAYERS
	#undef MAX_PLAYERS
	#define MAX_PLAYERS 96
#endif
#if defined MAX_VEHICLES
	#undef MAX_VEHICLES
	#define MAX_VEHICLES MAX_PLAYERS
#endif

#include <sscanf2>
#include <a_mysql>
#include <irc>
#include <foreach>
#include <zcmd>
#include <model_sizes>
//#include <evi>
//#include <rnpc>

native WP_Hash(buffer[], len, const str[]);

#define WP_HASH_LEN 		(129)

#if defined MAX_PLAYER_NAME
	#undef MAX_PLAYER_NAME
	#define MAX_PLAYER_NAME 21
#endif

#define MAX_PLAYER_IP		17

#define HidePlayerDialog(%1) ShowPlayerDialog(%1,-1,0,"","","","")

#define VEHICLE_ACCELERATE 	(8)
#define KEY_AIM				(128)

#define isValueOdd(%0)  ((%0)&1)
#define isValueEven(%0) (!isValueOdd(%0)

#define MAP_ANDREAS_MODE_NONE			0
#define MAP_ANDREAS_MODE_MINIMAL		1
#define MAP_ANDREAS_MODE_MEDIUM			2	// currently unused
#define MAP_ANDREAS_MODE_FULL			3
#define MAP_ANDREAS_MODE_NOBUFFER		4

#define MAP_ANDREAS_ERROR_SUCCESS		0
#define MAP_ANDREAS_ERROR_FAILURE		1
#define MAP_ANDREAS_ERROR_MEMORY		2
#define MAP_ANDREAS_ERROR_DATA_FILES	3
#define MAP_ANDREAS_ERROR_INVALID_AREA	4

native MapAndreas_Init(mode, name[]="", len=sizeof(name));
native MapAndreas_FindZ_For2DCoord(Float:X, Float:Y, &Float:Z);
native MapAndreas_FindAverageZ(Float:X, Float:Y, &Float:Z);
native MapAndreas_Unload();
native MapAndreas_SetZ_For2DCoord(Float:X, Float:Y, Float:Z);
native MapAndreas_SaveCurrentHMap(name[]);
native MapAndreas_GetAddress(); //only for plugins

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
native Float:MPDistancePointLine(Float:PointX, Float:PointY, Float:PointZ, Float:LineSx, Float:LineSy, Float:LineSz, Float:LineEx, Float:LineEy, Float:LineEz); // [url]http://paulbourke.net/geometry/pointline/[/url] returns super huge number 10000000 if outside of range of specified the line segment.
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

new Selecting_Textdraw[MAX_PLAYERS] = {0, ...};
stock tm_SelectTextdraw(playerid, hovercolor)
{
	Selecting_Textdraw[playerid] = hovercolor;
	return SelectTextDraw(playerid, hovercolor);
}
#if defined _ALS_SelectTextdraw
	#undef SelectTextdraw
#else
	#define _ALS_SelectTextdraw
#endif
#define SelectTextdraw tm_SelectTextdraw

stock tm_CancelSelectTextdraw(playerid)
{
	Selecting_Textdraw[playerid] = 0;
	return CancelSelectTextDraw(playerid);
}
#if defined _ALS_CancelSelectTextdraw
	#undef CancelSelectTextdraw
#else
	#define _ALS_CancelSelectTextdraw
#endif
#define CancelSelectTextdraw tm_CancelSelectTextdraw

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
	new retTimerID = KillTimer(timerid);
	timerid = 0;
	return retTimerID;
}
#define KillTimer FIXES_KillTimer

#define SERVER_MODE_NORMAL 0
#define SERVER_MODE_TESTING 1

#define SAMP_03d 			(true)
#define SAMP_04 			(false)
#define SERVER_VERSION 		"0.65"
#define SERVER_WEBSITE 		"lvcnr.net"
#define SERVER_NAME 		"Twisted Metal: SA-MP"
#define SERVER_NAME_SHORT 	"TM SA-MP"
#define SERVER_IP           "tm.lvcnr.net"
#define SERVER_IP_ADDRESS	"" // 188.226.222.239

#define THREAD:%1(%2)			\
			forward Thread_%1(%2);	\
			public Thread_%1(%2)

#define MYSQL_HOST			""
#define MYSQL_USER			""
#define MYSQL_DB  			""
#define MYSQL_PASS			""

#define mySQL_Accounts_Table		"`p_accounts`"
#define mySQL_Customization_Table	"`p_customization`"
#define mySQL_Maps_Table			"`s_maps`"
#define mySQL_Maps_Objects_Table	"`s_map_objects`"
#define mySQL_Maps_Pickups_Table	"`s_map_pickups`"
#define mySQL_Maps_Spawns_Table		"`s_map_spawns`"
#define mySQL_Race_Quit_List_Table	"`s_temp_race_quit_list`"

#define ENABLE_NPC 				(false)

#define IRC_SERVER 				"irc.tl"
#define IRC_PORT 				(6667)
#define IRC_CHANNEL 			"#tm"
#define ECHO_IRC_CHANNEL 		"#tm.echo"
#define ADMIN_CHAT_IRC_CHANNEL 	"#tm.admin"

#define IRC_BOT_PASSWORD		""
#define IRC_BOT_ADMIN_CHAN_KEY	""

#define MAX_IRC_BOTS (2)

#define IRC_BOT_GAME_QUIT_REASON "Gamemode Exit"
#define IRC_BOT_QUIT_REASON "Forced Quit"

new gBotID[MAX_IRC_BOTS], gIRCGroupChatID;

new gBotNames[MAX_IRC_BOTS][12] =
{
	{"Calypso"},
	{"Sweet_Tooth"}
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
	
#define MAX_LOGIN_ATTEMPTS 3

#define MAX_PLAYER_BARS				7
#define INVALID_PLAYER_BAR_VALUE	(Float:0xFFFFFFFF)
#define INVALID_PLAYER_BAR_ID		(PlayerBar:-1)
#define pb_percent(%1,%2,%3,%4)	((%1 - 6.0) + ((((%1 + 6.0 + %2 - 2.0) - %1) / %3) * %4)) //pb_percent(x, width, max, value)

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
	if(!pBars[playerid][_:barid][pb_created]) return 0;
	value = (value < 0.0) ? (0.0) : (value > pBars[playerid][_:barid][pb_m]) ? (pBars[playerid][_:barid][pb_m]) : (value);
	PlayerTextDrawUseBox(playerid, pBars[playerid][_:barid][pb_t3], value > 0.0);
	pBars[playerid][_:barid][pb_v] = value;
	PlayerTextDrawTextSize(playerid, pBars[playerid][_:barid][pb_t3], pb_percent(pBars[playerid][_:barid][pb_x], pBars[playerid][_:barid][pb_w], pBars[playerid][_:barid][pb_m], value), 0.0);
	return 1;
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

stock UpdatePlayerProgressBar(playerid, PlayerBar:barid) return ShowPlayerProgressBar(playerid, barid);

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
#define cBot "{0694AC}"
#define cBotEx 0x0694ACFF
#define cGrey "{D3D3D3}"
#define cTeal "{02D9F5}"
#define cLime "{19E03D}"
#define cGold "{FFD700}"
#define cGreen "{33FF33}"
#define cWhite "{FFFFFF}"
#define cPurple "{A82FED}"
#define cYellow "{FFEF00}"
#define cNiceBlue "{30AEFC}"
#define cNiceBlueEx 0x30AEFCFF
#define cLightBlue "{33CCFF}"
#define cOrange "{FFBB00}"
#define cOrangeRed "{FF6600}"
#define cOrangeRedEx 0xFF6600FF

#define GOLD 0xFFD700FF
#define COLOR_RED 0xFF0000FF
#define BLUE 0x4242FFFF
#define LIME 0x00FF00FF
#define TEAL 0x00F5FF99
#define PINK 0xE100E1AA
#define GREEN 0x33FF33AA
#define White 0xFFFFFFF
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
#define GREY_MENU      0x00000066

#define DIALOG_REGISTRATION 6500
#define DIALOG_LOGIN 6501

#define MISSILE_SPEED 60.0
#define MISSILE_FIRE_KEY KEY_ACTION
#define MACHINE_GUN_KEY KEY_CROUCH

#define Reaper_Chainsaw 341
#define Reaper_Chainsaw_Bone 5
#define REAPER_RPG_WEAPON 33
#define Shadow_Coffin 2896

#define ATTACHED_INDEX_SHIELD 2
#define Reaper_Chainsaw_Index 3
#define Reaper_Chainsaw_Flame_Index 4
#define Darkside_Mask 6

//18728	smoke_flare - Roadkill's special
//19270 MapMarker_Fire - Roadkill's Special

#define TMC_CRAZY8 				474
#define TMC_CRIMSON_FURY 		473
#define TMC_JUNKYARD_DOG_TAXI 	420
#define TMC_JUNKYARD_DOG 		525
#define TMC_BRIMSTONE 			576
#define TMC_OUTLAW 				599
#define TMC_REAPER 				463
#define TMC_MRGRIMM 			TMC_REAPER
#define TMC_ROADKILL 			541
#define TMC_THUMPER 			412
#define TMC_SPECTRE 			475
#define TMC_DARKSIDE 			514
#define TMC_SHADOW 				442
#define TMC_MEATWAGON 			479
#define TMC_VERMIN 				482
#define TMC_3_WARTHOG 			470
#define TMC_MANSLAUGHTER 		455 // deprecated, should return later
#define TMC_HAMMERHEAD 			444
#define TMC_SWEETTOOTH 			423

#define Machine_Gun 3002 /*pool ball*/
#define Machine_Gun_Default_Object 362
#define Missile_Default_Object 3790 //345 //
#define Missile_Napalm_Object 1222
#define Missile_Ricochet_Object 19284
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

#define MAX_MACHINE_GUN_SLOTS 			26
#define MAX_MISSILE_SLOTS 				26

#define MAX_ROADKILL_MISSILES 6
#define MAX_SWEETTOOTH_MISSILES 20
#define MAX_WARTHOG_MISSILES 3

#define MAX_TWISTED_VEHICLES 14

#define MAX_TEAMS 2

#define TEAM_CLOWNS 0
#define TEAM_DOLLS 1

#define INVALID_GAME_TEAM (-1)

#define PLAYER_TEAM_COLOUR 0x00FF00FF
#define RIVAL_TEAM_COLOUR 0xFF0000FF

#define EFFECT_RANDOM           20
#define EFFECT_FIX_DEFAULT      10
#define EFFECT_FIX_Z            0.008
#define EFFECT_MULTIPLIER               0.05
#define EFFECT_HELI_VEL                 0.1
#define EFFECT_EXPLOSIONTYPE    1
#define EFFECT_EXPLOSIONOFFSET  -1.2
#define EFFECT_EXPLOSIONRADIUS  2.5

#define MAX_GAME_LOBBIES 3
#define MAX_FREEROAM_GAMES 1
#define FREEROAM_GAME 3
#define MAX_PLAYERS_PER_LOBBY 32
#define INVALID_GAME_ID (-1)
#define MAX_MAP_SELECTION 8

#define MAX_MISSILE_LIGHTS 10

#define TARGET_CIRCLE_CREATING 0
#define TARGET_CIRCLE_ATTACHING 1

#define Missile_Texture "missiles_sfs"
#define Missile_Texture_Name "white"

#define MAX_TWISTED_HEALTH 280.0

#define MAX_TURBO 300.0

#define MAX_ENERGY 100.0

#define INVISIBILITY_INDEX 100

#define MAX_PRELOADED_OBJECTS 14

#define PLAYER_MISSILE_SLOT_ADD 0
#define PLAYER_MISSILE_SLOT_REMOVE 1
#define PLAYER_MISSILE_SLOT_CLEAR 2

#define MAX_MAPS 64

#define INVALID_MAP_ID MAX_MAPS

#define MAP_SKYSCRAPERS	1
#define	MAP_DOWNTOWN 	2
#define	MAP_HANGER18	3
#define	MAP_SUBURBS 	4
#define	MAP_DIABLO_PASS	5
#define	MAP_FREEWAY		6

#define MAP_NORMAL_Z 0.0
#define MAP_SKYSCRAPER_Z 43.0
#define MAP_DOWNTOWN_Z 31.0
#define MAP_SUBURBS_Z 0.4
#define MAP_DIABLO_PASS_Z 0.0

#define MAX_MAP_TYPES 2

#define MAP_TYPE_NORMAL 0
#define MAP_TYPE_RACE 1

#define MAX_MAP_OBJECTS (MAX_OBJECTS / 2)

#define MAX_DESTROYABLE_OBJECTS 10

#define MAP_OBJECT_SPAWN_FIND_NEW_INDEX -1

#define MAX_MAP_SPAWNS MAX_PLAYERS_PER_LOBBY * MAX_MAPS

#define MAX_MAP_PICKUPS 	72 // ((MAX_PICKUPS / 64))

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

#define MAX_MAPS_PICKUPS 500

#define MAP_ALL_DATA 0
#define MAP_DATA_OBJECTS 1
#define MAP_DATA_PICKUPS 2
#define MAP_DATA_SPAWNS 3

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
#define MD_TYPE_MaxZ 13

#define MD_Integer 0
#define MD_String 1
#define MD_Float 2

#define MAX_PASSWORD_LEN 20
#define MIN_PASSWORD_LEN 3
#define MAX_REGISTRATION_DATE_LEN  13

#define BitFlag_Get(%0,%1)            ((%0) & (%1))   // Returns zero (false) if the flag isn't set.
#define BitFlag_On(%0,%1)             ((%0) |= (%1))  // Turn on a flag.
#define BitFlag_Off(%0,%1)            ((%0) &= ~(%1)) // Turn off a flag.
#define BitFlag_Toggle(%0,%1)         ((%0) ^= (%1))  // Toggle a flag (swap true/false).

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

#define MAX_SPECIAL_OBJECTS 7

#define DEFAULT_CHARGE_INDEX 20.0

#define MAX_MODELS_PER_VEHICLE 5
#define MAX_STATUS_TEXT_LENGTH 32 + 4

#define MAX_XP_STATUSES 6

#define ENERGY_COLOUR 0x0097FCFF
#define EXPRIENCE_COLOUR 0xC20000FF

#define MAX_COLOUR_BOXES 2
#define MAX_C_OBJECTS_LIST 6

#define MAX_T_POINTS 10

#define d_type_none 0
#define d_type_close 1
#define d_type_far 2

#define MAX_GAMEMODES 7

#define GM_DEATHMATCH 0
#define GM_TEAM_DEATHMATCH 1
#define GM_HUNTED 2
#define GM_TEAM_HUNTED 3
#define GM_LAST_MAN_STANDING 4
#define GM_TEAM_LAST_MAN_STANDING 5
#define GM_RACE 6
#define GM_FREEROAM 7

#define MAX_LIFTS 2 * MAX_GAME_LOBBIES
#define MAX_LIFT_OBJECTS 2

#define TURBO_DEDUCT_INDEX 135

#define ADMIN_LEVEL_TRIAL 1
#define ADMIN_LEVEL_ADMINISTRATOR 2
#define ADMIN_LEVEL_LEAD_ADMIN 3
#define ADMIN_LEVEL_DEVELOPER 4

#define EXP_STATUS_SHOW_TIME 8
#define GAME_EXP_PER_LEVEL 1000

#define TUTORIAL_WORLD 100

#define CAMERA_MODE_NONE    	0
#define CAMERA_MODE_FREE_LOOK	1

#define SPAWN_REQUEST_NONE 0
#define SPAWN_REQUEST_Authentication 1
#define SPAWN_REQUEST_REGISTRATION 2
#define SPAWN_REQUEST_GARAGE 3
#define SPAWN_REQUEST_GARAGE_EDITING 4

new
	Text:iSpawn_Text,

	iGamemode_MaxTime = (10 * 60),
	iGamemode_CountDownMaxTime = 45,

	pLogged_Status[MAX_PLAYERS],
	pSpectate_Random_Teammate[MAX_PLAYERS],
	
	pFirstTimeViewingMap[MAX_PLAYERS] = {1, ...},
	
	pLastSavedStatisticsTime[MAX_PLAYERS],

	mysqlConnHandle = 0,
	gQuery[640],
	gString[320],
	
	General_Vars:bPlayerGameSettings[MAX_PLAYERS],
	
	Global_KSXPString[32],
	
	aveh[MAX_PLAYERS],
	
	pSpawn_Request[MAX_PLAYERS],

	EMPTime[MAX_PLAYERS] = {0, ...},

	pPlayerUpdate[MAX_PLAYERS] = {0, ...},
	bool:pPaused[MAX_PLAYERS] = {false, ...},
	pPausedTimestamp[MAX_PLAYERS] = {0, ...},
	Text3D:pPausedText[MAX_PLAYERS],

	iCurrentState[MAX_PLAYERS],
	Float:VehicleOffsetX[MAX_VEHICLES],
	Float:VehicleOffsetY[MAX_VEHICLES],
	Float:VehicleOffsetZ[MAX_VEHICLES],
	
	Nitro_Bike_Object[MAX_PLAYERS] = {INVALID_OBJECT_ID, ...},

	pMissileID[MAX_PLAYERS],
	Mine_Timer[MAX_PLAYERS],
	pFiring_Missile[MAX_PLAYERS],
	WasDamaged[MAX_VEHICLES],
	Vehicle_Using_Environmental[MAX_VEHICLES],
	Vehicle_Smoke[MAX_VEHICLES][MAX_MISSILE_SLOTS],
	Vehicle_Missile[MAX_VEHICLES][MAX_MISSILE_SLOTS],
	Vehicle_Missile_CurrentslotID[MAX_VEHICLES],
	Vehicle_Missile_Lights[MAX_VEHICLES][MAX_MISSILE_LIGHTS],
	Vehicle_Missile_Lights_Attached[MAX_VEHICLES][MAX_MISSILE_LIGHTS],
	Vehicle_Missile_Following[MAX_VEHICLES][MAX_MISSILE_SLOTS],
	Float:Vehicle_Missile_Final_Angle[MAX_VEHICLES][MAX_MISSILE_SLOTS],
	Vehicle_Missile_Reset_Fire_Time[MAX_VEHICLES],
	Vehicle_Missile_Reset_Fire_Slot[MAX_VEHICLES],
	tNapalm_Slot[MAX_PLAYERS],

	Vehicle_Machine_Gun[MAX_VEHICLES][MAX_MACHINE_GUN_SLOTS],
	Vehicle_Machine_Mega_Gun[MAX_VEHICLES][MAX_MACHINE_GUN_SLOTS],
	Vehicle_Machine_Gunid[MAX_VEHICLES],
	Vehicle_Machine_Gun_Flash[MAX_VEHICLES][2],
	Vehicle_Machine_Gun_Object[MAX_VEHICLES][2],
	Vehicle_Machine_Gun_CurrentID[MAX_VEHICLES],
	Vehicle_Machine_Gun_CurrentSlot[MAX_VEHICLES] = {0, ...},
	Machine_Gun_Firing_Timer[MAX_PLAYERS],
	Special_Missile_Timer[MAX_PLAYERS],

	pLastAttacked[MAX_VEHICLES],
	pLastAttackedMissile[MAX_VEHICLES],
	pLastAttackedTime[MAX_VEHICLES],
	pCurrentlyAttacking[MAX_VEHICLES],
	pCurrentlyAttackingMissile[MAX_VEHICLES],
	Float:pCurrentlyAttackingDamage[MAX_VEHICLES][MAX_DAMAGEABLE_MISSILES],

	Object_Slot[MAX_OBJECTS] = {-1, ...},
	Object_Type[MAX_OBJECTS] = {-1, ...},
	Object_Owner[MAX_OBJECTS] = {INVALID_VEHICLE_ID, ...},
	Object_OwnerEx[MAX_OBJECTS] = {INVALID_PLAYER_ID, ...},
	
	Iterator:iPlayersInGame[MAX_GAME_LOBBIES]<MAX_PLAYERS>,
	
	Iterator:Vehicles<MAX_VEHICLES>,
	Vehicle_Interior[MAX_VEHICLES],
	
	Preloading_Objects[MAX_PLAYERS][MAX_PRELOADED_OBJECTS],
	Objects_Preloaded[MAX_PLAYERS],
	
	Iterator:pSlots_In_Use[MAX_PLAYERS]<MAX_MISSILE_SLOTS>,
	
	LastSpecialUpdateTick[MAX_PLAYERS],

	HelicopterAttack = INVALID_OBJECT_ID,
	
	pName[MAX_PLAYERS][MAX_PLAYER_NAME],
	pNameNone[MAX_PLAYER_NAME] = " - ",

	gAttached[MAX_PLAYERS],

	bool:debugkeys,
	
	Missile_Material_Index = 0,

	server_mode = SERVER_MODE_NORMAL,
	server_ip_addr[17],
	server_port
	//sql_pool_size = 0,
	//server_max_players = MAX_PLAYERS,
;

forward SendRandomMsg();
forward UpdateMissile(playerid, id, objectid, missileid, slot, vehicleid);
forward OnMissileUpdate();
forward explodeMissile(playerid, vehicleid, slot, missileid);
forward OnMissileFire(playerid, vehicleid, slot, missileid, objectid);
forward Destroy_Object(objectid);
forward updateServerPickups();
forward Float:GetTwistedMetalMaxEnergy(modelid);
forward Float:GetTwistedMetalMaxHealth(modelid);
forward Float:GetTwistedMetalMaxTurbo(modelid);
forward Float:getMapLowestZ(Mapid);
forward Float:getMapHighestZ(Mapid);
forward Float:getMapLowestZEx(mapid, Float:x, Float:y, Float:cZ, &whichaxis = 0);
forward OnMapBegin(gameid, gamemode, mapid);
forward OnMapFinish(gameid, gamemode, mapid);
forward OnGameBegin(gameid);
forward OnGameJoin(gameid, mapid, playerid);
forward OnGameLeave(gameid, playerid);
forward OnPlayerPause(playerid);
forward OnPlayerUnPause(playerid);
forward IsPlayerPaused(playerid);
forward Float:MissileYSize();
forward EndVotingTime(voteid, gameid);
forward StartVoting(gameid);
forward SetCP(playerid, PrevCP, NextCP, MaxCP, rType);
forward Race_Loop(gameid);
forward Float:Angle2D(Float:PointAx, Float:PointAy, Float:PointBx, Float:PointBy);
forward Float:GetPlayerDistanceToVehicle(playerid, vehicleid);
forward HideSubtitle(playerid);
forward SpawnPlayerEx(playerid);
forward Overlay();
forward OnPlayerFloodControl(playerid, iCount, iTimeSpan);
forward FinishPlayerPreloading(playerid);
forward OnPlayerRequestClassEx(playerid, classid);
forward OnPlayerTwistedDeath(killerid, killer_vehicleid, deathid, death_vehicleid, missileid, killerid_modelid, deathid_modelid);
forward playerResetGameInvisibility(vehicleid);
forward playerResetGameShield(playerid);
forward OnVehicleHitUnoccupiedVehicle(playerid, myvehicleid, vehicleid, Float:speed);
forward OnVehicleHitVehicle(playerid, myvehicleid, hitplayerid, vehicleid, Float:speed);
forward ResetCollision(vehicleid);
forward OnPlayerVehicleHealthChange(playerid, vehicleid, Float:newhealth, Float:oldhealth);
forward Destroy_Explosion(objectid);
forward Reset_SMV(playerid);
forward Float:TwistedRAMRadius(twistedid);
forward Float:getTwistedMetalCameraOffset(modelid);
forward Float:atan2VehicleZ(Float:Xb, Float:Yb, Float:Xe, Float:Ye); 
forward Float:GetRequiredAngle(Float:range, Float:velocity, Float:gravity = 9.8);
forward Float:GetVelocityXY(Float:x, Float:y);
forward Float:GetFlightMaxTime(Float:base, Float:velocity, Float:angle, Float:gravity = 9.8); // To avoid reparse errors.
forward Float:GetMissileDamage(missileid, vehicleid = 0, alt_weapon = 0, mapid = -1);
forward Float:GetMissileExplosionRadius(missileid);
forward Float:GetTwistedMetalMissileAccuracy(playerid = INVALID_PLAYER_ID, missileid, model = 0, alt_special = 0, justfired = 0);


enum General_Vars:(<<= 1)
{
	gMuted
};

enum FLIGHT_DATA {
	Float:FLIGHT_DISTANCE,
	Float:FLIGHT_HEIGHT,
	Float:FLIGHT_VELOCITY[2]
};

new
	pShadow_Count[MAX_PLAYERS],
	Float:pShadow_Angle[MAX_PLAYERS],
	sData[MAX_T_POINTS][FLIGHT_DATA] // pShadow_Data[MAX_PLAYERS],
;

enum Class_Selection_Info
{
	CS_VehicleModelID,
	CS_TwistedName[24],
	CS_SkinID,
	CS_Colour1,
	CS_Colour2
};

new Class_Selection_IDS[MAX_TWISTED_VEHICLES + 1][Class_Selection_Info] =
{
	{400, "Dummy", 0, 0, 0},
	{TMC_JUNKYARD_DOG, "Junkyard Dog", 200, 3, 6},
	{TMC_BRIMSTONE, "~w~Brimstone", 147, 1, 1},
	{TMC_OUTLAW, "~b~~h~Out~r~~h~law", 266, 0, 1},
	{TMC_REAPER, "~r~~h~~h~~h~Reaper", 28, 0, 3},
	{TMC_ROADKILL, "~g~Roadkill", 162, 44, 44},
	{TMC_THUMPER, "~p~Thumper", 0, 136, 1},
	{TMC_SPECTRE, "~b~~h~Spectre", 233, 7, 1},
	{TMC_DARKSIDE, "Darkside", 251, 0, 0},
	{TMC_SHADOW, "~p~Shadow", 0, 1, 1},
	{TMC_MEATWAGON, "~r~~h~Meat Wagon", 219, 1, 3}, //275 skin
	{TMC_VERMIN, "~y~Vermin", 262, 6, 113},
	{TMC_3_WARTHOG, "~y~~h~Warthog_TM3", 28, 1, 1},
	//{TMC_MANSLAUGHTER, "~w~ManSalughter", 27, 1, 1},
	{TMC_HAMMERHEAD, "~b~~h~~h~Hammerhead", 73, 79, 79},
	{TMC_SWEETTOOTH, "~p~~h~Sweet Tooth", 264, 1, 126}
},
	pVehicleID[MAX_PLAYERS] = {0, ...},
	pTwistedIndex[MAX_PLAYERS],
	Vehicle_Driver[MAX_PLAYERS * 2] = {INVALID_PLAYER_ID, ...};
	
#define C_S_IDS Class_Selection_IDS

enum e_TeamInfo
{
	TI_Team_Name[16],
	TI_Skin_ID,
	TI_Score
};
new Team_Info[MAX_TEAMS][e_TeamInfo] =
{
	{"The Clowns", 264, 0}, //{"The Skulls", 66}, //{"The Holy Men", 142,}
	{"The Dolls", 193, 0}
};
new gTeam_Player_Count[MAX_GAME_LOBBIES][MAX_TEAMS],
	gTeam_Lives[MAX_GAME_LOBBIES][MAX_TEAMS],
	gHunted_Player[MAX_GAME_LOBBIES][MAX_TEAMS];

new twistedDeathReasons[29][42] =
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
Crimson Fury -- 110 Health
Talon --- 120 Health
Kamikaze --- 150 Health
Axel --- 170 Health
Death Warrant --- 180 
Road Boat --- 210 Health
Juggernaut --- 400 Health*/

stock FIXES_DestroyObject(&objectid)
{
	//printf("[System: DestroyObject] - %d", objectid);
	//SetObjectMaterial(objectid, 0, 19341, "invalid", "invalid", 0);
	new rdo = DestroyObject(objectid);
	objectid = INVALID_OBJECT_ID;
	return rdo;
}
#define DestroyObject FIXES_DestroyObject

enum e_Games
{
	g_Map_id,
	g_Gamemode,
	g_Gamemode_Time,
	g_Gamemode_Countdown_Time,
	Text:g_Gamemode_Time_Text,
	g_Voting_Time,
	bool:g_Has_Moving_Lift,
	g_Players,
	g_Lobby_gName[32],
	Text:g_Lobby_Box_Outline,
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
new gGameData[MAX_GAME_LOBBIES + MAX_FREEROAM_GAMES][e_Games]; // + 1 = freeroam

enum e_s_Maps
{
	m_Name[32],
	m_Type,
	m_ID,
	Float:m_LowestZ,
	Float:m_MaxZ,
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
	Float:m_DrawDistance,
	m_Destroyable
};
new m_Map_Positions[MAX_MAP_OBJECTS][Map_Enum],
	Map_Objects[MAX_GAME_LOBBIES][100];
new Iterator:m_Destroyables[MAX_GAME_LOBBIES]<MAX_DESTROYABLE_OBJECTS>;
new Iterator:m_Map_Objects[MAX_GAME_LOBBIES]<MAX_MAP_OBJECTS / 4>;

enum e_mSpawns
{
	s_Mapid,
	Float:s_X,
	Float:s_Y,
	Float:s_Z,
	Float:s_Angle
};
new m_Map_Spawns[MAX_MAP_SPAWNS][e_mSpawns];

enum e_m_Pickup_data
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
new m_Pickup_Data[MAX_GAME_LOBBIES][MAX_MAP_PICKUPS][e_m_Pickup_data],
	Iterator:m_Map_Pickups[MAX_GAME_LOBBIES]<MAX_MAP_PICKUPS>;

enum e_Maps_Pickup_Data
{
	PI_Mapid,
	PI_Pickuptype,
	Float:PI_pX,
	Float:PI_pY,
	Float:PI_pZ
}
new Maps_m_Pickup_Data[MAX_MAPS_PICKUPS][e_Maps_Pickup_Data];

enum s_GameModes
{
	GM_Name[32 + 12]
};
new s_Gamemodes[MAX_GAMEMODES + MAX_FREEROAM_GAMES][s_GameModes] =
{
	{"Deathmatch"},
	{"Team Deathmatch"},
	{"Hunted"},
	{"Team Hunted"},
	{"Last Man Standing"},
	{"Team Last Man Standing"},
	{"Race"},
	{"Freeroam"}
};
new gmVotes[MAX_GAME_LOBBIES][MAX_GAMEMODES];

new MovingLifts[MAX_LIFTS],
	MovingLiftPickup[MAX_LIFTS] = {-1, ...},
	MovingLiftStatus[MAX_LIFTS],
	MovingLiftGameID[MAX_LIFTS];

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
new MovingLiftData[MAX_LIFT_OBJECTS][e_MovingLifts] =
{
	{MAP_DOWNTOWN, 16773, -2084.7964, -984.2720, 31.2, 90.0, 90.0, 90.0, 33.2, 6.0},
	{MAP_DOWNTOWN, 16773, -2083.0549, -781.6403, 31.2, 90.0, 90.0, 90.0, 33.2, 6.0}
};

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
	{MAP_DOWNTOWN, -2027.1857, -799.0085, 419.7032, -2027.1840, -800.0073, 413.3235, 5000}
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

new Status_Text[MAX_PLAYERS][MAX_TIMETEXTS][MAX_STATUS_TEXT_LENGTH];
//#define Speedometer_Needle_Index 8

enum pTextinfo
{
	PlayerText:pTextWrapper,
	PlayerText:AimingPlayer,
	PlayerText:pHealthVerticalBar,
	PlayerText:pMissileSign[MAX_MISSILEID],
	PlayerText:pMissileImages[MAX_MISSILEID],
	PlayerText:pLevelText,
	PlayerText:pEXPText,
	PlayerText:pEXPStatus[MAX_XP_STATUSES],
	PlayerText:pKillStreakText,
	PlayerText:Mega_Gun_IDX,
	PlayerText:Mega_Gun_Sprite,
	//Text:TDSpeedClock[16],
	//Text:SpeedoMeterNeedle[8],
	PlayerBar:pHealthBar,
	PlayerBar:pAiming_Health_Bar,
	PlayerBar:pEnergyBar,
	PlayerBar:pTurboBar,
	PlayerBar:pExprienceBar,
	PlayerBar:pChargeBar,
	PlayerText:pTeam_Sprite,
	PlayerText:pTeam_Score,
	PlayerText:pRival_Team_Sprite,
	PlayerText:pRival_Team_Score,
	PlayerText:pC_ColorBoxLeft[MAX_COLOUR_BOXES],
	PlayerText:pC_ColorBoxOutline[MAX_COLOUR_BOXES],
	PlayerText:pC_ColorBoxM[MAX_COLOUR_BOXES],
	PlayerText:pC_ColorBoxRight[MAX_COLOUR_BOXES],
	PlayerText:pC_Wheel_Name,
	PlayerText:pC_oNames[MAX_C_OBJECTS_LIST],
	PlayerText:pC_oModels[MAX_C_OBJECTS_LIST],
	PlayerText:pC_Select_Header_Text
};
enum e_Wheel_Data
{
	w_ID,
	w_Name[10]
};

new pTextInfo[MAX_PLAYERS][pTextinfo],
	pEXPTextStatus[MAX_PLAYERS][MAX_XP_STATUSES],
	pEXPTextStatusTimer[MAX_PLAYERS][MAX_XP_STATUSES],
	pEXPTextStatusText[MAX_PLAYERS][MAX_XP_STATUSES][32],
	pEXPTextStatusChanged[MAX_PLAYERS][MAX_XP_STATUSES],
	pGarageModelIDData[MAX_PLAYERS][MAX_C_OBJECTS_LIST],
	c_ColorIndex[ MAX_PLAYERS ][2],
	c_WheelIndex[ MAX_PLAYERS ] = {0, ...},
	Wheel_Data[18][e_Wheel_Data] = {
		{0, "None"},
		{1025, "Offroad"},
		{1073, "Shadow"}, // 1073
		{1074, "Mega"},
		{1075, "Rimshine"},
		{1076, "Wires"},
		{1077, "Classic"},
		{1078, "Twist"},
		{1079, "Cutter"},
		{1080, "Switch"},
		{1081, "Grove"},
		{1082, "Import"},
		{1083, "Dollar"},
		{1084, "Trance"},
		{1085, "Atomic"}, // 1085
		{1096, "Ahab"},
		{1097, "Virtual"},
		{1098, "Access"}
	},
	c_ModelIndex[ MAX_PLAYERS ] = {0, ...},
	p_c_Model[ MAX_PLAYERS ][MAX_MODELS_PER_VEHICLE],
	p_c_Model_Edited[ MAX_PLAYERS ][MAX_MODELS_PER_VEHICLE],
	Float:p_c_Model_Data[ MAX_PLAYERS ][MAX_MODELS_PER_VEHICLE][6],
	p_c_Objects[ MAX_PLAYERS ][MAX_MODELS_PER_VEHICLE];

new Text:Players_Online_Textdraw = INVALID_TEXT_DRAW;

#define GARAGE_MODEL_EDIT_ATTACH 0
#define GARAGE_MODEL_EDIT_DATA 1
#define GARAGE_MODEL_EDIT_DELETE 2

//Model: 12938 Texture: sw_apartments Txd: sw_policeline

enum pInfo
{
	CanExitVeh,
	pSkinid,
	pSkin,
	pTurbo,
	pEnergy,
	pSpawned_Status,
	Turbo_Tick,
	Turbo_Timer,
	Float:pCharge_Index,
	pCharge_Timer,
	pSpecialObjects[MAX_SPECIAL_OBJECTS],
	pMissiles[TOTAL_WEAPONS],/*0 - Special, 1 - Fires, 2 - Homing, 3 - Napalms, 4 - Powers, 5 - Environments,
	6 - Ricochets, 7- Stalkers, 8 - Remote Bombs*/
	pMissile_Special_Time,
	pMissileSpecialUpdate,
	pSpecial_Missile_Vehicle,
	pSpecial_Missile_Object,
	pSpecial_Using_Alt,
	pMissile_Charged,
	Float:pDamageToPlayer[MAX_PLAYERS],
	Float:pDamageDone,
	Float:pDamageTaken,
	pLast_Killed_By,
	g_pExprience,
	g_pPoints,
	gTeam,
	gRival_Team,
	gGameID,
	pKillStreaking,
	pConnect_Time,
	pAccount_ID,
	//pPassword[16],
	pIPv4[17],
	pRegistered_Date[MAX_REGISTRATION_DATE_LEN],
	pTime_Played,
	pLastVisit,
	pAdminLevel,
	pDonaterRank,
	pMoney,
	pKills,
	pDeaths,
	pKillAssists,
	pKillStreaks,
	pExprience,
	pLast_Exp_Gained,
	pLevel,
	pTier_Points,
	Float:pTravelled_Distance,
	pFavourite_Vehicle,
	pFavourite_Map,
	pRegular,
	bool:pGender,
	EnvironmentalCycle_Timer,
	pBurnout,
	Camera_Mode,
	Camera_Object,
	pLast_Chat_Tick
};

new playerData[MAX_PLAYERS][pInfo];
	
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

#define TM_SELECTION_X		-2404.533447
#define TM_SELECTION_Y		-598.653503
#define TM_SELECTION_Z 		132.648437
#define TM_SELECTION_ANGLE 	189.156631

#define TM_PRELOAD_X 		-2375.568
#define TM_PRELOAD_Y 		-581.391
#define TM_PRELOAD_Z 		132.111

#define TM_SELECTION_CAMERA_X -2404.533447 + (15 * floatsin(-(294.587921 - 180.0), degrees))
#define TM_SELECTION_CAMERA_Y -598.653503 + (15 * floatcos(-(294.587921 - 180.0), degrees))
#define TM_SELECTION_CAMERA_Z 135.648437

#define TM_SELECTION_LOOKAT_X -2404.533447
#define TM_SELECTION_LOOKAT_Y -598.653503
#define TM_SELECTION_LOOKAT_Z 132.648437

#define HUD_MISSILES 0
#define HUD_ENERGY 1

#define HUD_TYPE_TMBLACK 0
#define HUD_TYPE_TMPS3 1

#define INVALID_CLASS -1

new pHUDStatus[MAX_PLAYERS] = {HUD_MISSILES, ...},
	pHUDType[MAX_PLAYERS] = {HUD_TYPE_TMPS3, ...},
	
	Text:gClass_Spawn = INVALID_TEXT_DRAW,
	Text:gClass_Box = INVALID_TEXT_DRAW,
	PlayerText:gClass_Name[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...},
	Text:gClass_Left_Arrow = INVALID_TEXT_DRAW,
	Text:gClass_Right_Arrow = INVALID_TEXT_DRAW,
	Text:gClass_Info_Model = INVALID_TEXT_DRAW,
	Text:gClass_T_Box = INVALID_TEXT_DRAW,
	Text:gClass_T_Left = INVALID_TEXT_DRAW,
	Text:gClass_T_Right = INVALID_TEXT_DRAW,
	PlayerText:gClass_Team_Name[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...},
	PlayerText:gClass_Team_Model[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...},

	//Text:Tutorial_Arrows[10] = {INVALID_TEXT_DRAW, ...},
	//Text:Tutorial_Numbers[10] = {INVALID_TEXT_DRAW, ...},
	Text:pHud_Box = INVALID_TEXT_DRAW,
	Text:pHud_UpArrow = INVALID_TEXT_DRAW,
	Text:pHud_LeftArrow = INVALID_TEXT_DRAW,
	Text:pHud_RightArrow = INVALID_TEXT_DRAW,
	Text:pHud_HealthSign = INVALID_TEXT_DRAW,
	Text:pHud_BoxSeparater = INVALID_TEXT_DRAW,
	Text:pHud_SecondBox = INVALID_TEXT_DRAW,
	Text:pHud_EnergySign = INVALID_TEXT_DRAW,
	Text:pHud_TurboSign = INVALID_TEXT_DRAW,
	Text:gGarage_Go_Back = INVALID_TEXT_DRAW,
	Text:txdTMLogo[11] = {INVALID_TEXT_DRAW, ...},
	Text:Navigation_S[4] = {INVALID_TEXT_DRAW, ...},
	Text:Navigation_Game_S[9] = {INVALID_TEXT_DRAW, ...},
	Text:pC_Box_Outline = INVALID_TEXT_DRAW,
	Text:pC_Box = INVALID_TEXT_DRAW,
	Text:pC_cColor1 = INVALID_TEXT_DRAW,
	Text:pC_cColor2 = INVALID_TEXT_DRAW,
	Text:pC_Wheel_Type = INVALID_TEXT_DRAW,
	Text:pC_Save = INVALID_TEXT_DRAW,
	Text:pC_fLine = INVALID_TEXT_DRAW,
	Text:pC_lLine = INVALID_TEXT_DRAW,
	Text:pC_ColorLeftArrow[2] = INVALID_TEXT_DRAW,
	Text:pC_ColorRightArrow[2] = INVALID_TEXT_DRAW,
	Text:pC_WheelLeftArrow = INVALID_TEXT_DRAW,
	Text:pC_WheelRightArrow = INVALID_TEXT_DRAW,
	Text:pC_Default = INVALID_TEXT_DRAW,
	Text:pC_Back = INVALID_TEXT_DRAW,
	Text:pC_Select_Box = INVALID_TEXT_DRAW,
	Text:pC_Select_Line = INVALID_TEXT_DRAW,
	Text:pC_Models_Up_Arrow = INVALID_TEXT_DRAW,
	Text:pC_Models_Down_Arrow = INVALID_TEXT_DRAW;

#define NAVIGATION_COLOUR 0xFA1919AA

#define NAVIGATION_INDEX_MULTIPLAYER 0
#define NAVIGATION_INDEX_GARAGE 1
#define NAVIGATION_INDEX_OPTIONS 2
#define NAVIGATION_INDEX_HELP 3

#define NAVIGATION_INDEX_LOBBY 0
#define NAVIGATION_INDEX_MAIN_MENU 8

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
	Game_Top3_Positions[MAX_GAME_LOBBIES][3];
	
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

enum e_RACE
{
	Float:E_RACE_TOGO,
	//E_RACE_POS
}

new PlayerText:Race_Box[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...},
	PlayerText:Race_Box_Outline[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW, ...},
	PlayerText:Race_Box_Text[MAX_PLAYERS][4];

public Race_Loop(gameid)
{
	for(new opos = 0; opos < 3; opos++)
	{
		if(Game_Top3_Positions[gameid][opos] != INVALID_PLAYER_ID)
		{
			Game_Top3_Positions[gameid][opos] = INVALID_PLAYER_ID;
		}
	}
	new racePos[MAX_PLAYERS][e_RACE], pos = 1, cp, lap, Float:togo, text[4];
	foreach(iPlayersInGame[gameid], playerid)
	{
		if(playerData[playerid][pSpawned_Status] == 0) continue;
		pos = 1,
		cp = CP_Progress[playerid],
		lap = Race_Current_Lap[playerid];
		if(CP_Progress[playerid] == Total_Race_Checkpoints)
		{
			++pos;
			continue;
		}
		static
			Float:x,
			Float:y,
			Float:z
		;
		GetPlayerPos(playerid, x, y, z);
		x -= Race_Checkpoints[cp][0];
		y -= Race_Checkpoints[cp][1];
		z -= Race_Checkpoints[cp][2];
		togo = ((x * x) + (y * y) + (z * z));
		racePos[playerid][E_RACE_TOGO] = togo;
		foreach (iPlayersInGame[gameid], p)
		{
			if(CP_Progress[p] == Total_Race_Checkpoints)
			{
				++pos;
				continue;
			}
			if(p == playerid) break;
			if(Race_Current_Lap[p] > lap ||
				(Race_Current_Lap[p] == lap &&
					(CP_Progress[p] > cp || (CP_Progress[p] == cp && racePos[p][E_RACE_TOGO] < togo))))
			{
				++pos;
			}
			//else ++racePos[p][E_RACE_POS];
		}
		//racePos[playerid][E_RACE_POS] = pos;
		Race_Old_Position[playerid] = Race_Position[playerid];
		Race_Position[playerid] = pos;
		if(Race_Position[playerid] != Race_Old_Position[playerid])
		{
			SendClientMessageFormatted(playerid, -1, "Your new Position: %d", Race_Position[playerid]);
			format(text, sizeof(text), "%d", Race_Position[playerid]);
			PlayerVehicleRacePosition(playerid, PVRP_Update, text);
		}
		if(1 <= Race_Position[playerid] <= 3)
		{
			Game_Top3_Positions[gameid][Race_Position[playerid] - 1] = playerid;
		}
		if(Race_Position[playerid] >= 4)
		{
			format(gString, sizeof(gString), "%d   %s", Race_Position[playerid], playerName(playerid));
			PlayerTextDrawColor(playerid, Race_Box_Text[playerid][3], 0x00FF00FF);
			PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][3], gString);
			PlayerTextDrawShow(playerid, Race_Box_Text[playerid][3]);
		}
		else PlayerTextDrawHide(playerid, Race_Box_Text[playerid][3]);
	}
}

PlayerVehicleRacePosition(playerid, type, text[4])
{
	new vehicleid = pVehicleID[playerid], Float:x, Float:y, Float:z;
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

SetPositionalBox(playerid, count)
{
	if(count > 4) count = 4;
	new Float:extra = (count > 2) ? 0.2 : 0.0;
	--count;
	PlayerTextDrawLetterSize(playerid, Race_Box_Outline[playerid], 0.0, 1.1299995 + ( 1.0 * count ) + extra);
	PlayerTextDrawLetterSize(playerid, Race_Box[playerid], 0.0, 0.70 + ( 1.0 * count ) + extra);
	PlayerTextDrawShow(playerid, Race_Box_Outline[playerid]);
	PlayerTextDrawShow(playerid, Race_Box[playerid]);
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	//printf("[System: OnPlayerEnterRaceCheckpoint] - Playerid: %d", playerid);
	PlayerPlaySound(playerid, 1137, 0.0, 0.0, 0.0);
	if(CP_Progress[playerid] == Total_Race_Checkpoints - 1 && Race_Current_Lap[playerid] < Total_Race_Laps)
	{
		CP_Progress[playerid] = s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Max_Grids];
		++Race_Current_Lap[playerid];
		SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
	}
	else if(CP_Progress[playerid] == Total_Race_Checkpoints - 1 && Race_Current_Lap[playerid] == Total_Race_Laps)
	{
		new Position = Race_Position[playerid];
		DisablePlayerRaceCheckpoint(playerid);
		CP_Progress[playerid] = Total_Race_Checkpoints;
		SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "Race: %s(%d) Finished The Race In %d%s Position", playerName(playerid), playerid, Position, returnOrdinal(Position));
	}
	else
	{
		++CP_Progress[playerid];
		SetCP(playerid, CP_Progress[playerid], (CP_Progress[playerid] + 1), Total_Race_Checkpoints, RaceType);
	}
	return 1;
}

returnOrdinal(number)
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

public updateServerPickups()
{
	new pid = -1, Float:distance, Float:maxdist = 25.0, gameid;
	for(gameid = 0; gameid < MAX_GAME_LOBBIES; ++gameid)
	{
		if(gGameData[gameid][g_Gamemode_Countdown_Time] > 0 || gGameData[gameid][g_Voting_Time] > 0) continue;
		foreach(iPlayersInGame[gameid], playerid)
		{
			if(playerData[playerid][pSpawned_Status] == 0) continue;
			foreach(m_Map_Pickups[gameid], iter)
			{
				if(m_Pickup_Data[gameid][iter][Created] == false) continue;
				distance = GetPlayerDistanceFromPoint(playerid, m_Pickup_Data[gameid][iter][PickupX],
					m_Pickup_Data[gameid][iter][PickupY], m_Pickup_Data[gameid][iter][PickupZ]);
				if(distance < maxdist)
				{
					pid = iter;
					maxdist = distance;
				}
			}
			if(pid != -1)
			{
				SetPlayerCheckpoint(playerid, m_Pickup_Data[gameid][pid][PickupX], m_Pickup_Data[gameid][pid][PickupY],
					m_Pickup_Data[gameid][pid][PickupZ], 1.0);
				SetPVarInt(playerid, "pClosest_Pickup", pid);
			}
			else if(GetPVarType(playerid, "pClosest_Pickup"))
			{
				DeletePVar(playerid, "pClosest_Pickup");
				DisablePlayerCheckpoint(playerid);
			}
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	if(GetPVarType(playerid, "pClosest_Pickup"))
	{
		new iter_pickup = GetPVarInt(playerid, "pClosest_Pickup");
		if(m_Pickup_Data[playerData[playerid][gGameID]][iter_pickup][Created] == true)
		{
			//SendClientMessageFormatted(playerid, -1, "OnPlayerEnterCheckpoint - [Created]: %d", m_Pickup_Data[playerData[playerid][gGameID]][iter_pickup][Created]);
			DisablePlayerCheckpoint(playerid);
			OnPlayerPickUpPickup(playerid, m_Pickup_Data[playerData[playerid][gGameID]][iter_pickup][Pickupid]);
		}
	}
	return 1;
}

hidePlayerTeamTextDraws(playerid, bool:cancel = true)
{
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pTeam_Sprite]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pRival_Team_Sprite]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pTeam_Score]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pRival_Team_Score]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pTeam_Sprite]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pRival_Team_Sprite]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pTeam_Score]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pRival_Team_Score]);
	pTextInfo[playerid][pTeam_Sprite] = INVALID_PLAYER_TEXT_DRAW;
	pTextInfo[playerid][pRival_Team_Sprite] = INVALID_PLAYER_TEXT_DRAW;
	pTextInfo[playerid][pTeam_Score] = INVALID_PLAYER_TEXT_DRAW;
	pTextInfo[playerid][pRival_Team_Score] = INVALID_PLAYER_TEXT_DRAW;
	if(cancel == true) {
		tm_CancelSelectTextdraw(playerid);
	}
	return 1;
}

public OnMapBegin(gameid, gamemode, mapid)
{
	gGameData[gameid][g_Map_id] = mapid;
	gGameData[gameid][g_Gamemode_Countdown_Time] = iGamemode_CountDownMaxTime;
	LoadMapData(MAP_DATA_OBJECTS, mapid, gameid);
	LoadMapData(MAP_DATA_PICKUPS, mapid, gameid);
	LoadMapData(MAP_DATA_SPAWNS, mapid);
	printf("[System: OnMapBegin] - GameID: %d. Gamemode: %s(%d). Map: %s(%d)", gameid, s_Gamemodes[gamemode][GM_Name], gamemode, s_Maps[mapid][m_Name], mapid);
	switch(gamemode)
	{
		case GM_TEAM_LAST_MAN_STANDING: gGameData[gameid][g_Gamemode_Time] = iGamemode_MaxTime + (2 * 60);
		default: gGameData[gameid][g_Gamemode_Time] = iGamemode_MaxTime;
	}
	switch(gamemode)
	{
		//case GM_DEATHMATCH, GM_HUNTED, GM_LAST_MAN_STANDING: {}
		case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
		{
			for(new i = 0; i < MAX_TEAMS; ++i)
			{
				gTeam_Player_Count[gameid][i] = 0;
				gTeam_Lives[gameid][i] = 6;
			}
			foreach(Player, i)
			{
				if(playerData[i][gGameID] != gameid) continue;
				playerData[i][gTeam] = TEAM_CLOWNS;
				playerData[i][gRival_Team] = TEAM_DOLLS;
			}
		}
	}
	switch(gamemode)
	{
		case GM_RACE:
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
			for(new g = 0; g < MAX_STARTING_GRIDS; g++)
			{
				RaceVehCoords[g][0] = Race_Checkpoints[g][0];
				RaceVehCoords[g][1] = Race_Checkpoints[g][1];
				RaceVehCoords[g][2] = Race_Checkpoints[g][2];
			}
			RaceVehCoords[0][3] = Angle2D(Race_Checkpoints[s_Maps[mapid][m_Max_Grids]][0],
									Race_Checkpoints[s_Maps[mapid][m_Max_Grids]][1],
								Race_Checkpoints[s_Maps[mapid][m_Max_Grids] + 1][0],
								Race_Checkpoints[s_Maps[mapid][m_Max_Grids] + 1][1] );
			MPClamp360(RaceVehCoords[0][3]);
			RaceVehCoords[1][3] = RaceVehCoords[0][3];
			RaceVehCoords[2][3] = RaceVehCoords[0][3];

			foreach(iPlayersInGame[gameid], i)
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
				if(Game_Top3_Positions[gameid][opos] != INVALID_PLAYER_ID)
				{
					Game_Top3_Positions[gameid][opos] = INVALID_PLAYER_ID;
				}
			}
			Race_Loop(gameid);
			// deathmatch surprise, "GM_RACE BATTLE" kill all opponents to win
		}
		case GM_DEATHMATCH,
		GM_TEAM_DEATHMATCH,
		GM_HUNTED,
		GM_TEAM_HUNTED,
		GM_LAST_MAN_STANDING,
		GM_TEAM_LAST_MAN_STANDING:
		{
			for(new m = 0, mp = sizeof(m_Map_Positions); m < mp; m++)
			{
				if( m_Map_Positions[m][m_Mapid] != mapid ) continue;
				SpawnMapObject(gameid, MAP_OBJECT_SPAWN_FIND_NEW_INDEX, m, m_Map_Positions[m][m_Model], m_Map_Positions[m][m_X], m_Map_Positions[m][m_Y], m_Map_Positions[m][m_Z], m_Map_Positions[m][m_rX], m_Map_Positions[m][m_rY], m_Map_Positions[m][m_rZ], m_Map_Positions[m][m_DrawDistance]);
			}
			for(new p = 0, mp = sizeof(Maps_m_Pickup_Data); p < mp; p++)
			{
				if( Maps_m_Pickup_Data[p][PI_Mapid] != mapid ) continue;
				createPickupEx(gameid, 14, Maps_m_Pickup_Data[p][PI_pX], Maps_m_Pickup_Data[p][PI_pY], Maps_m_Pickup_Data[p][PI_pZ], gameid, Maps_m_Pickup_Data[p][PI_Pickuptype]);
			}
			for(new i = 0; i < sizeof(MovingLiftData); ++i)
			{
				if( MovingLiftData[i][L_Mapid] != mapid ) continue;
				if(IsValidObject(MovingLifts[i]))
				{
					DestroyObject(MovingLifts[i]);
					MovingLifts[i] = INVALID_OBJECT_ID;
				}
				MovingLifts[i] = CreateObject(MovingLiftData[i][L_Objectid], MovingLiftData[i][L_X], MovingLiftData[i][L_Y], MovingLiftData[i][L_Z], MovingLiftData[i][L_RX], MovingLiftData[i][L_RY], MovingLiftData[i][L_RZ]);
				MovingLiftPickup[i] = CreatePickup(1247, 14, MovingLiftData[i][L_X], MovingLiftData[i][L_Y], MovingLiftData[i][L_Z] - 0.6, gameid);
				MovingLiftStatus[i] = 0;
				MovingLiftGameID[i] = gameid;
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
	foreach(iPlayersInGame[gameid], playerid)
	{
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], "0");
		PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
		HideKillStreak(playerid);
		playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 0;
		playerData[playerid][pKillStreaking] = -1;
		pFirstTimeViewingMap[playerid] = 1;
	}
	//new str[64];
	//format(str, sizeof(str), "map %s", s_Maps[mapid][m_Name]);
	//SendRconCommand(str);
	TextDrawSetString(gGameData[gameid][g_Lobby_gState], "COUNTDOWN");
	switch(gamemode)
	{
		case GM_LAST_MAN_STANDING: format(gString, sizeof(gString), "Last Man~n~Standing");
		case GM_TEAM_DEATHMATCH: format(gString, sizeof(gString), "Team~n~Deathmatch");
		//case GM_TEAM_LAST_MAN_STANDING: format(gString, sizeof(gString), "Team Last~n~Man Standing");
		default: format(gString, sizeof(gString), "%s", s_Gamemodes[gamemode][GM_Name]);
	}
	UpdateLobbyTD(gGameData[gameid][g_Lobby_Type], gString);
	UpdateLobbyTD(gGameData[gameid][g_Lobby_Map], s_Maps[mapid]);
	return 1;
}
#define MAP_GAMEMODE_DIALOG 3200
#define MAP_VOTE_DIALOG 3201
#define VOTE_ID_GAMEMODE 0
#define VOTE_ID_MAP 1

public OnMapFinish(gameid, gamemode, mapid)
{
	printf("[System: OnMapFinish] - Gameid: %d. Gamemode: %s(%d). Map: %s(%d)", gameid, s_Gamemodes[gamemode][GM_Name], gamemode, s_Maps[mapid][m_Name], mapid);
	switch(gamemode)
	{
		case GM_DEATHMATCH, GM_HUNTED:
		{
			new winnerid = INVALID_PLAYER_ID, winnerscore = 0, score = 0, bool:drawn = false;
			foreach(iPlayersInGame[gameid], playerid)
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
					PlayerPlaySound(winnerid, 5448, 0.0, 0.0, 0.0); // "You Win!"
					foreach(iPlayersInGame[gameid], i)
					{
						if(playerData[i][gGameID] != gameid) continue;
						SendClientMessageFormatted(i, GOLD, "%s(%d) "#cWhite"Has Won The Deathmatch Game", playerName(winnerid), winnerid);
						if(winnerid == i) continue;
						PlayerPlaySound(i, 7023, 0.0, 0.0, 0.0); // "Loser!"
					}
				}
				else
				{
					foreach(iPlayersInGame[gameid], i)
					{
						if(playerData[i][gGameID] != gameid) continue;
						PlayerPlaySound(i, 7023, 0.0, 0.0, 0.0); // "Loser!"
						SendClientMessage(i, GOLD, "The Game Has Been Drawn With No Winners");
					}
				}
			}
			else
			{
				foreach(iPlayersInGame[gameid], i)
				{
					if(playerData[i][gGameID] != gameid) continue;
					PlayerPlaySound(i, 7023, 0.0, 0.0, 0.0); // "Loser!"
					SendClientMessage(i, GOLD, "The Game Has Been Drawn With No Winners");
				}
			}
			gHunted_Player[gameid][0] = INVALID_PLAYER_ID;
		}
		case GM_LAST_MAN_STANDING:
		{
			new g_Winnerid = INVALID_PLAYER_ID, drawn = 0;
			foreach(iPlayersInGame[gameid], i)
			{
				if(playerData[i][pSpawned_Status] == 0) continue;
				g_Winnerid = i;
			}
			if(g_Winnerid == INVALID_PLAYER_ID)
			{
				drawn = 1;
			}
			if(g_Winnerid == INVALID_PLAYER_ID || drawn == 1) // drawn
			{
				foreach(iPlayersInGame[gameid], i)
				{
					if(playerData[i][gGameID] != gameid) continue;
					SendClientMessage(i, GOLD, "The Game Has Ended With No Winner");
					PlayerPlaySound(i, 7023, 0.0, 0.0, 0.0); // "Loser!"
				}
			}
			else
			{
				PlayerPlaySound(g_Winnerid, 5448, 0.0, 0.0, 0.0); // "You Win!"
				foreach(iPlayersInGame[gameid], i)
				{
					if(playerData[i][gGameID] != gameid) continue;
					SendClientMessageFormatted(i, GOLD, "%s(%d) "#cWhite"Has Won The Last Man Standing Game", playerName(g_Winnerid), g_Winnerid);
					if(g_Winnerid == i) continue;
					PlayerPlaySound(i, 7023, 0.0, 0.0, 0.0); // "Loser!"
				}
			}
		}
		case GM_RACE:
		{
			TemporaryRaceQuitList(.playerid = INVALID_PLAYER_ID, .action = 2);
			if(Game_Top3_Positions[gameid][0] != INVALID_PLAYER_ID)
			{
				PlayerPlaySound(Game_Top3_Positions[gameid][0], 5448, 0.0, 0.0, 0.0); // "You win!"
				foreach(Player, i)
				{
					if(playerData[i][gGameID] != gameid) continue;
					SendClientMessageFormatted(i, GOLD, "%s(%d) "#cWhite"Has Won The Race", playerName(Game_Top3_Positions[gameid][0]), Game_Top3_Positions[gameid][0]);
				}
			}
		}
		case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
		{
			new winnerteamid = -1, winnerscore = 0, bool:drawn = false, loserteamid;
			for(new ti = 0; ti < sizeof(Team_Info); ++ti)
			{
				if(gGameData[gameid][g_Gamemode] == GM_TEAM_LAST_MAN_STANDING)
				{
					Team_Info[ti][TI_Score] = gTeam_Lives[gameid][ti];
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
				foreach(iPlayersInGame[gameid], i)
				{
					SendClientMessage(i, GOLD, "The Game Has Drawn!");
				}
			}
			else
			{
				if(gGameData[gameid][g_Gamemode] == GM_TEAM_LAST_MAN_STANDING)
				{
					format(gString, sizeof(gString), "Your Team Loses!");
				}
				else format(gString, sizeof(gString), "Your Team Loses! (%d To %d)", Team_Info[winnerteamid][TI_Score], Team_Info[loserteamid][TI_Score]);
				foreach(iPlayersInGame[gameid], i)
				{
					if(playerData[i][gTeam] == winnerteamid)
					{
						TimeTextForPlayer( TIMETEXT_MIDDLE_SUPER_LARGE, i, "Your Team Wins!", 3000, PLAYER_TEAM_COLOUR );
					}
					else TimeTextForPlayer( TIMETEXT_MIDDLE_SUPER_LARGE, i, gString, 3000, RIVAL_TEAM_COLOUR );
				}
				SendClientMessageFormatted(INVALID_PLAYER_ID, GOLD, "[%s] - %s "#cWhite"Has Won!", gGameData[gameid][g_Lobby_gName], Team_Info[winnerteamid][TI_Team_Name]);
			}
		}
	}
	foreach(iPlayersInGame[gameid], i)
	{
		if(GetPVarType(i, "pRegistration_Tutorial")) continue;
		DeletePVar(i, "pSpectating");
		//TogglePlayerSpectating(i, false);
		playerData[i][pLast_Exp_Gained] = playerData[i][g_pExprience];
		toggleAccountSave(i, ACCOUNT_UPDATE_LAST_EXPRIENCE);
		playerData[i][g_pExprience] = 0;
		SendClientMessageFormatted(i, -1, ""#cTeal"Exprience Gained: "#cWhite"%d", playerData[i][pLast_Exp_Gained]);
		SendClientMessageFormatted(i, -1, ""#cTeal"New Exprience: "#cWhite"%d", playerData[i][pExprience]);
		ResetPlayerGamePoints(i);
		hidePlayerTeamTextDraws(i);
		HideKillStreak(i);
		playerData[i][gTeam] = INVALID_GAME_TEAM;
		playerData[i][gRival_Team] = INVALID_GAME_TEAM;
		for(new rb = 0; rb < 4; rb++)
		{
			PlayerTextDrawHide(i, Race_Box_Text[i][rb]);
		}
		PlayerTextDrawHide(i, Race_Box_Outline[i]);
		PlayerTextDrawHide(i, Race_Box[i]);
		PlayerTextDrawHide(i, pTextInfo[i][AimingPlayer]);
		PlayerTextDrawHide(i, pTextInfo[i][Mega_Gun_IDX]);
		PlayerTextDrawHide(i, pTextInfo[i][Mega_Gun_Sprite]);
		pSpectate_Random_Teammate[i] = 0;
		KillTimer(playerData[i][Turbo_Timer]);
		KillTimer(Special_Missile_Timer[i]);
		playerData[i][pMissile_Special_Time] = 0;
		playerData[i][pMissile_Charged] = INVALID_MISSILE_ID;
		if(IsValidObject(Race_Object[i]))
		{
			DestroyObject(Race_Object[i]);
			Race_Object[i] = INVALID_OBJECT_ID;
		}
		playerData[i][pLast_Killed_By] = INVALID_PLAYER_ID;
		if(playerData[i][pSpawned_Status] == 0) continue;
		SetPlayerHealth(i, -1);
		//setupClassSelectionForPlayer(i, pTwistedIndex[i]);
	}
	foreach(m_Map_Objects[gameid], m)
	{
		if(IsValidObject(Map_Objects[gameid][m]))
		{
			DestroyObject(Map_Objects[gameid][m]);
			Map_Objects[gameid][m] = INVALID_OBJECT_ID;
		}
		if(Iter_Contains(m_Destroyables[gameid], m))
		{
			Iter_Remove(m_Destroyables[gameid], m);
		}
		new next;
		Iter_SafeRemove(m_Map_Objects[gameid], m, next);
		m = next;
	}
	gGameData[gameid][g_Has_Moving_Lift] = false;
	for(new i = 0; i < MAX_LIFTS; ++i)
	{
		if(MovingLiftGameID[i] != gameid) continue;
		if(IsValidObject(MovingLifts[i]))
		{
			DestroyObject(MovingLifts[i]);
			MovingLifts[i] = INVALID_OBJECT_ID;
		}
		MovingLiftStatus[i] = 0;
		MovingLiftGameID[i] = -1;
	}
	foreach(m_Map_Pickups[gameid], p)
	{
		new next;
		Iter_SafeRemove(m_Map_Pickups[gameid], p, next);
		DestroyPickupEx(gameid, p);
		p = next;
	}
	Iter_Clear(m_Map_Pickups[gameid]);
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

public StartVoting(gameid)
{
	gString = "\0";
	for(new g = 0, gm = MAX_GAMEMODES; g < gm; g++)
	{
		strcat(gString, s_Gamemodes[g][GM_Name]);
		strcat(gString, "\n");
	}
	foreach(Player, playerid)
	{
		if(playerData[playerid][gGameID] != gameid) continue;
		SendClientMessage(playerid, -1, "Gamemode Voting Has Began! Cast Your Votes.");
		ShowPlayerDialog(playerid, MAP_GAMEMODE_DIALOG, DIALOG_STYLE_LIST, ""#cWhite"Vote For The Next "#cYellow"Gamemode", gString, "Proceed", "");
	}
	SetTimerEx("EndVotingTime", 20000, false, "ii", VOTE_ID_GAMEMODE, gameid);
	gGameData[gameid][g_Gamemode_Time] = 18;
	TextDrawSetString(gGameData[gameid][g_Lobby_gState], "MODE VOTING");
	return 1;
}

public EndVotingTime(voteid, gameid)
{
	if(gameid == INVALID_GAME_ID) return printf("[System Error: EndVotingTime] - voteid: %d - gameid: %d", voteid, gameid);
	switch(voteid)
	{
		case VOTE_ID_GAMEMODE:
		{
			new highest = -1, highestex = 0, VoteListIndex;
			for(new g = 0, gm = MAX_GAMEMODES; g < gm; g++)
			{
				if(gmVotes[gameid][g] > highestex)
				{
					highestex = gmVotes[gameid][g];
					highest = g;
				}
				gmVotes[gameid][g] = 0;
			}
			if(highest == -1) {
				highest = random(MAX_GAMEMODES);
			}
			gGameData[gameid][g_Gamemode] = highest;
			TextDrawSetString(gGameData[gameid][g_Lobby_Type], s_Gamemodes[gGameData[gameid][g_Gamemode]][GM_Name]);
			gString = "\0";
			for(new m = 0, gm = sizeof(s_Maps); m < gm; m++)
			{
				if(-1 <= s_Maps[m][m_ID] <= 0) continue;
				if(Iter_Count(Map_Selection[gameid]) >= MAX_MAP_SELECTION
					|| VoteListIndex >= MAX_MAP_SELECTION) continue;
				switch(gGameData[gameid][g_Gamemode])
				{
					case GM_RACE: if(s_Maps[m][m_Type] != MAP_TYPE_RACE) continue;
					default: if(s_Maps[m][m_Type] == MAP_TYPE_RACE) continue;
				}
				gGameData[gameid][VoteList][VoteListIndex] = m;
				strcat(gString, s_Maps[m][m_Name]);
				strcat(gString, "\n");
				++VoteListIndex;
				if(!Iter_Contains(Map_Selection[gameid], m))
				{
					Iter_Add(Map_Selection[gameid], m);
				}
				if((m + 1) < gm)
				{
					if(strlen(gString) + strlen(s_Maps[m + 1][m_Name]) > sizeof(gString)) break;
				}
			}
			gGameData[gameid][g_Voting_Time] = 2;
			foreach(Player, playerid)
			{
				if(playerData[playerid][gGameID] != gameid) continue;
				SendClientMessage(playerid, -1, "Gamemode Voting Time Has "#cSAMP"Expired!");
				SendClientMessage(playerid, -1, "Beginning Map Vote. Cast your Vote for the Best Map!");
				SendClientMessageFormatted(playerid, -1, "The next mode will be "#cYellow"%s"#cWhite".", s_Gamemodes[gGameData[gameid][g_Gamemode]][GM_Name]);
				ShowPlayerDialog(playerid, MAP_VOTE_DIALOG, DIALOG_STYLE_LIST, ""#cWhite"Vote For The Next "#cBlue"Map", gString, "Proceed", "");
			}
			SetTimerEx("EndVotingTime", 15000, false, "ii", VOTE_ID_MAP, gameid);
			gGameData[gameid][g_Gamemode_Time] = 14;
			gGameData[gameid][g_Gamemode_Countdown_Time] = -1;
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
					if(playerData[playerid][gGameID] != gameid) continue;
					SendClientMessage(playerid, -1, "Noone Voted. Random Map Assigned.");
				}
			}
			gGameData[gameid][g_Map_id] = newmap;
			gGameData[gameid][g_Gamemode_Time] = 2;
			foreach(iPlayersInGame[gameid], playerid)
			{
				HidePlayerDialog(playerid);
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

#define DIALOG_TUTORIAL 500
//#define DIALOG_TUTORIAL_HUD 501
#define DIALOG_TUTORIAL_GAMEMODES 501
#define DIALOG_TUTORIAL_WEAPONS 502
#define DIALOG_TUTORIAL_SPAWN 503
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_TUTORIAL:
		{
			switch(response)
			{
				case 0: return 1;
				default:
				{
					new tutorial[1024 + 256];
					++listitem;
					switch(listitem)
					{
						/*case 1:
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
							""cSAMP""#SERVER_NAME" - Tutorial | HUD",
							tutorial, "Go Back", "");
						}*/
						case 1:
						{
							strcat(tutorial, ""#cBlue"Deathmatch \t\t- "#cWhite"Players must fight each other in the level and score points with enemy kills.\n");
							strcat(tutorial, ""#cBlue"Team Deathmatch \t- "#cWhite"Players must destroy as many players on the opposing team as possible before time runs out.\n");
							strcat(tutorial, ""#cBlue"Hunted \t\t- "#cWhite"One player is the \"Hunted\" which means that he/she will be targeted by everyone.\n\t\t\t  If a player kills the \"Hunted\", he/she gets a point but will become the \"Hunted\".\n\t\t\t  Killing another player while being the \"Hunted\" is also awarded a point.\n");
							strcat(tutorial, ""#cBlue"Team Hunted \t\t- "#cWhite"One player on each team is the \"Hunted\" which means that he/she will be targeted by\n\t\t\t  everyone on the opposing team.\n");
							strcat(tutorial, ""#cBlue"Last Man Standing \t- "#cWhite"Each player has a specific number of lives and the player will not respawn if\n\t\t\t  he/she runs out of lives and is killed.\n");
							strcat(tutorial, ""#cBlue"Team Last Man Standing - "#cWhite"Each team has a specific number of lives. The team lives are shared to everyone\n\t\t\t  in the team. If a team runs out of lives, a player of that team will not respawn if he/she is killed.\n");
							strcat(tutorial, ""#cBlue"Race \t\t\t- "#cWhite"Players must get to checkpoints and destroy anyone in their path.\n");
							ShowPlayerDialog(playerid, DIALOG_TUTORIAL_GAMEMODES, DIALOG_STYLE_MSGBOX,
							""cSAMP""#SERVER_NAME" - Tutorial | The Gamemodes Explained",
							tutorial, "Go Back", "");
						}
						case 2:
						{
							strcat(tutorial, ""#cBlue"Fire Missile\t\t - "#cWhite"Slight homing ability and the most common weapon - 16 pts damage\n");
							strcat(tutorial, ""#cBlue"Homing Missile\t - "#cWhite"Strong homing ability - 12 pts damage\n");
							strcat(tutorial, ""#cBlue"Power Missile\t\t - "#cWhite"No homing ability but very powerful - 75 pts damage\n");
							strcat(tutorial, ""#cBlue"Stalker Missile\t - "#cWhite"Homing + Power combo missile; able to be charged for more homing capabilities - 45 pts damage\n");
							strcat(tutorial, ""#cBlue"Napalm\t\t - "#cWhite"Fire once to launch, fire again to drop; land a direct hit to inflict extra damage and ignite an\n\t\t\tenemy on fire - 35 pts Bullseye damage, 20 Medium, 10 Far\n");
							strcat(tutorial, ""#cBlue"Remote Bomb \t - "#cWhite"Bonus damage longer you allow to sit. (Stage 1: 35 pts- Stage 2: 50 Cooked Bomb pts)\n");
							strcat(tutorial, ""#cBlue"Ricochet\t\t - "#cWhite"Able to be charged up, launched, and detonated much like Napalm.\n\t\t\t(25 pts dmg) Bonus damage inflicted when richoched off a wall. (35 pts Bounce Bonus)\n");
							strcat(tutorial, ""#cBlue"Mega Guns\t\t - "#cWhite"Increased damage and fire rate to mounted guns. One pickup loads 150 shots.\n");
							ShowPlayerDialog(playerid, DIALOG_TUTORIAL_WEAPONS, DIALOG_STYLE_MSGBOX,
							""cSAMP""#SERVER_NAME" - Tutorial | The Weapons Explained",
							tutorial, "Go Back", "");
						}
						case 3:
						{
							strcat(tutorial, ""#cWhite"Follow These Instructions To Begin Playing\n\n");
							strcat(tutorial, "\t"#cWhite"Step 1:\t"#cBlue"Click Multi-Player\n");
							strcat(tutorial, "\t"#cWhite"Step 2:\t"#cBlue"Choose A Vehicle\n");
							strcat(tutorial, "\t"#cWhite"Step 3:\t"#cBlue"Click The Pink Car\n");
							strcat(tutorial, "\n"#cWhite"Type "#cBlue"/controls "#cWhite"to view the server controls\t\t\t");
							ShowPlayerDialog(playerid, DIALOG_TUTORIAL_SPAWN, DIALOG_STYLE_MSGBOX,
							""cSAMP""#SERVER_NAME_SHORT" - Tutorial | How To Start Playing",
							tutorial, "Go Back", "");
						}
					}
				}
			}
		}
		/*case DIALOG_TUTORIAL_HUD:
		{
			for(new ta = 0, tas = sizeof(Tutorial_Arrows); ta < tas; ta++)
			{
				TextDrawHideForPlayer(playerid, Tutorial_Arrows[ta]);
				TextDrawHideForPlayer(playerid, Tutorial_Numbers[ta]);
			}
			return cmd_tutorial(playerid, "");
		}*/
		case DIALOG_TUTORIAL_GAMEMODES, DIALOG_TUTORIAL_WEAPONS, DIALOG_TUTORIAL_SPAWN: return cmd_tutorial(playerid, "");
		case MAP_GAMEMODE_DIALOG:
		{
			if(gGameData[playerData[playerid][gGameID]][g_Voting_Time] != 1) return SendClientMessage(playerid, -1, "You have attempted to voted too late, gamemode voting time has already expired.");
			if(strfind(s_Gamemodes[listitem][GM_Name], "Last Man Standing") != -1) // and Team LMS
			{
				if(Iter_Count(iPlayersInGame[playerData[playerid][gGameID]]) < 3) return SendClientMessage(playerid, -1, "This gamemode requires 3(+) players to play.");
			}
			SendClientMessageFormatted(playerid, -1, "You have voted for gamemode "#cGreen"%s(%d)"#cWhite".", s_Gamemodes[listitem][GM_Name], listitem);
			++gmVotes[playerData[playerid][gGameID]][listitem];
			if(playerData[playerid][pSpawned_Status] == 0)
			{
				TextDrawShowForPlayer(playerid, gGameData[playerData[playerid][gGameID]][g_Gamemode_Time_Text]);
			}
		}
		case MAP_VOTE_DIALOG:
		{
			if(gGameData[playerData[playerid][gGameID]][g_Voting_Time] != 2) return SendClientMessage(playerid, -1, "You Have Voted Too Late, Map Voting Time Has Already Expired");
			SendClientMessageFormatted(playerid, -1, "You have voted for map "#cGreen"%s(%d)"#cWhite".", s_Maps[gGameData[playerData[playerid][gGameID]][VoteList][listitem]][m_Name], gGameData[playerData[playerid][gGameID]][VoteList][listitem]);
			++gGameData[playerData[playerid][gGameID]][mVotes][gGameData[playerData[playerid][gGameID]][VoteList][listitem]];
		}
	}
	if(dialogid == DIALOG_REGISTRATION)
	{
		if(!response || isnull(inputtext))
		{
			format(gString, sizeof(gString), ""#cSAMP"Welcome To "#SERVER_NAME": "#cWhite"%s\n\nSelect \"continue\" to play without registering or\n\nplease enter a password below to register:", playerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_REGISTRATION, DIALOG_STYLE_INPUT, ""#cSAMPRed"Account Registration", gString, "Register", "Cancel");
			return 1;
		}
		if(strlen(inputtext) < MIN_PASSWORD_LEN || strlen(inputtext) >= MAX_PASSWORD_LEN)
		{
			format(gString, sizeof(gString), ""#cSAMP"Welcome To "#SERVER_NAME": "#cWhite"%s\n\n"#cRed"ERROR:\n\n"#cWhite"Your password must contain "#cOrangeRed"%s "#cWhite"characters.\nPlease enter an eligible password:", playerName(playerid), (strlen(inputtext) < 6) ? ("atleast "#MIN_PASSWORD_LEN"") : ("atmost "#MAX_PASSWORD_LEN""));
			ShowPlayerDialog(playerid, DIALOG_REGISTRATION, DIALOG_STYLE_INPUT, ""#cSAMPRed"Account Registration", gString, "Register", "Cancel");
			return 1;
		}
		if(strfind(inputtext, "~", true) != -1 || strfind(inputtext, "%", true) != -1)
		{
			format(gString, sizeof(gString), ""#cSAMP"Welcome To "#SERVER_NAME": "#cWhite"%s\n\n"#cRed"ERROR:\n\nTidle's (~) "#cWhite"And "#cRed"Percent Signs (\%) "#cWhite"cannot be used\n\n",playerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_REGISTRATION, DIALOG_STYLE_INPUT, ""#cSAMPRed"Account Registration", gString, "Register", "Cancel");
			return 1;
		}
		if(pLogged_Status[playerid] == 1) return SendClientMessage(playerid, COLOR_RED, "You are already logged in.");
		format(gQuery, sizeof(gQuery), "SELECT `Username` FROM "#mySQL_Accounts_Table" WHERE `Username` = '%s' LIMIT 0,1", playerName(playerid));
		mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnUserRegister", "is", playerid, inputtext);
	}
	if(dialogid == DIALOG_LOGIN)
	{
		if(!response || isnull(inputtext))
		{
			format(gString, sizeof(gString), ""#cWhite"Welcome To "#cBlue""#SERVER_NAME"\n\n{FAF87F}Account: "#cWhite"%s\n\n{FF0000}Please Enter Your Password Below:", playerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, ""#cSAMPRed"Account Authentication", gString, "Login", "Cancel");
			return 1;
		}
		if(strlen(inputtext) >= MAX_PASSWORD_LEN)
		{
			format(gString, sizeof(gString), ""#cWhite"Welcome To "#cBlue""#SERVER_NAME"\n\n{FAF87F}Account: "#cWhite"%s\n\n{FF0000}Your Password Must Be Less Than "#MAX_PASSWORD_LEN" characters!", playerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, ""#cSAMPRed"Account Authentication", gString, "Login", "Cancel");
			return 1;
		}
		if(strfind(inputtext, "~", true) != -1 || strfind(inputtext, "%", true) != -1)
		{
			format(gString, sizeof(gString), ""#cRed"Tidle's (~) And Percent Signs \%) Cannot Be Used In Your Password\n\n"#cWhite"Welcome To "#cBlue""#SERVER_NAME"\n\n{FAF87F}Account: "#cWhite"%s\n\n{FF0000}Please Enter Your Password Below:", playerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, ""#cSAMPRed"Account Authentication", gString, "Login", "Cancel");
			return 1;
		}
		new hashed_password[WP_HASH_LEN];
		WP_Hash(hashed_password, sizeof(hashed_password), inputtext);
		format(gQuery, sizeof(gQuery), "SELECT * FROM "#mySQL_Accounts_Table" WHERE `Username` = '%s' AND `Password` = '%s' LIMIT 0,1", playerName(playerid), hashed_password);
		mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnUserLogin", "i", playerid);
	}
	return 1;
}

THREAD:OnUserLogin(playerid)
{
	new rows = cache_get_row_count(mysqlConnHandle), result[32];
	if(rows == 1)
	{
		pLogged_Status[playerid] = 1;
		playerData[playerid][pConnect_Time] = gettime();
		SetPVarInt(playerid, "pCanTalk", 1);
		
		playerData[playerid][pAccount_ID] = cache_get_row_int(0, 1, mysqlConnHandle); //cache_get_row(0, 2, playerData[playerid][pPassword]);
		cache_get_row(0, 3, playerData[playerid][pIPv4], mysqlConnHandle, 17);
		cache_get_row(0, 4, playerData[playerid][pRegistered_Date], mysqlConnHandle, MAX_REGISTRATION_DATE_LEN);
		playerData[playerid][pTime_Played] = cache_get_row_int(0, 5, mysqlConnHandle);
		playerData[playerid][pLastVisit] = cache_get_row_int(0, 6, mysqlConnHandle);
		playerData[playerid][pAdminLevel] = cache_get_row_int(0, 7, mysqlConnHandle);
		playerData[playerid][pDonaterRank] = cache_get_row_int(0, 8, mysqlConnHandle);
		
		playerData[playerid][pMoney] = cache_get_field_content_int(0, "pMoney", mysqlConnHandle);
		playerData[playerid][pKills] = cache_get_field_content_int(0, "pKills", mysqlConnHandle);
		playerData[playerid][pDeaths] = cache_get_field_content_int(0, "pDeaths", mysqlConnHandle);
		
		playerData[playerid][pKillAssists] = cache_get_field_content_int(0, "pKillAssists", mysqlConnHandle);
		playerData[playerid][pKillStreaks] = cache_get_field_content_int(0, "pKillStreaks", mysqlConnHandle);
		
		playerData[playerid][pExprience] = cache_get_field_content_int(0, "pExprience", mysqlConnHandle);
		playerData[playerid][pLast_Exp_Gained] = cache_get_field_content_int(0, "pLast_Exp_Gained", mysqlConnHandle);
		playerData[playerid][pLevel] = cache_get_field_content_int(0, "pLevel", mysqlConnHandle);
		
		playerData[playerid][pTier_Points] = cache_get_field_content_int(0, "pTier_Points", mysqlConnHandle);
		SetPlayerScore(playerid, playerData[playerid][pLevel]);
		
		playerData[playerid][pTravelled_Distance] = cache_get_field_content_float(0, "pTravelled_Distance", mysqlConnHandle);
		
		playerData[playerid][pFavourite_Vehicle] = cache_get_field_content_int(0, "pFavourite_Vehicle", mysqlConnHandle);
		playerData[playerid][pFavourite_Map] = cache_get_field_content_int(0, "pFavourite_Map", mysqlConnHandle);
		
		format(result, sizeof(result), "Level: %d", playerData[playerid][pLevel]);
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pLevelText], result);
		format(result, sizeof(result), "XP: %d", playerData[playerid][pExprience]);
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pEXPText], result);
		
		SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pExprienceBar], 1000);
		SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pExprienceBar], float((playerData[playerid][pExprience] - ((playerData[playerid][pLevel] - 1) * 1000))));
		UpdatePlayerDate(playerid);
		processPlayerGameplay(playerid);
	}
	else if(rows > 1)
	{
		SendClientMessage(playerid, COLOR_RED, "Error: Multiple Accounts Found - Please Report This At "#SERVER_WEBSITE" In The Server Bugs Section.");
		safeKickPlayer(playerid, "Multiple Accounts Found.");
	}
	else
	{
		SendClientMessage(playerid, COLOR_RED, "You have entered an Invalid Password. Please enter your correct password to continue!");
		format(gString, sizeof(gString), ""#cWhite"Welcome To "#cBlue""#SERVER_NAME"\n\n{FAF87F}Account: "#cWhite"%s\n\n"#cRed"INVALID PASSWORD\n\nIf This Is Not Your Account Please Quit Immediately\n\nIf You Have Forgotten Your Password Please Visit "#SERVER_WEBSITE"\n\nEnter Your Correct Password:", playerName(playerid));
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, ""#cSAMPRed"Login To "#SERVER_NAME"", gString, "Login", "Cancel");
		SetPVarInt(playerid, "pLogin_Failed", GetPVarInt(playerid, "pLogin_Failed") + 1);
		if(GetPVarInt(playerid, "pLogin_Failed") == MAX_LOGIN_ATTEMPTS)
		{
			SetPVarInt(playerid, "pLogin_Failed", 0);
			SendClientMessage(playerid, COLOR_RED, "Maximum incorrect passwords entered. You have been kicked.");
			safeKickPlayer(playerid, "Failing To Login");
		}
	}
	return 1;
}

THREAD:OnUserRegister(playerid, inputtext[])
{
	printf("[Thread: OnUserRegister] - %s(%d)", playerName(playerid), playerid);
	if(cache_get_row_count() > 0) {
		SendClientMessage(playerid, COLOR_RED, "Error: This Account Already Exists!");
		return 1;
	} else {
		clearPlayerCurrentChatLines(playerid);
		SetPVarInt(playerid, "pCanTalk", 1);
		SetPVarInt(playerid, "pFirst_Gameplay", 1);
		
		new y, m, d, hashed_password[WP_HASH_LEN];
		
		WP_Hash(hashed_password, sizeof(hashed_password), inputtext);

		getdate(y, m, d);
		format(playerData[playerid][pRegistered_Date], MAX_REGISTRATION_DATE_LEN, "%02d:%02d:%04d", d, m, y);
		
		playerData[playerid][pLastVisit] = gettime();
		
		format(gQuery, sizeof(gQuery), "INSERT INTO "#mySQL_Accounts_Table" (`Username`,`Password`,`pIPv4`,`pRegistered_Date`,`pLastVisit`) VALUES ('%s', '%s', '%s', '%s', UNIX_TIMESTAMP())", playerName(playerid), hashed_password, playerData[playerid][pIPv4], playerData[playerid][pRegistered_Date]);
		mysql_tquery(mysqlConnHandle, gQuery);
		
		SendClientMessageFormatted(playerid, -1, "Welcome To "#cSAMPRed""#SERVER_NAME" "#cBlue"%s"#cWhite". You Have Successfully Registered On. Enjoy Your Stay.", playerName(playerid));
		SendClientMessage(playerid, -1, "Type "#cNiceBlue"/tutorial "#cWhite"To Learn More About The Server");
		
		//IRC_GroupSayFormatted(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, "05%s(%d) Has Registered (%s)", pName[playerid], playerid, playerData[playerid][pIPv4]);
		
		format(gQuery, sizeof(gQuery), ""#cWhite"Welcome To "#cBlue""#SERVER_NAME"\n\n{FAF87F}Account: "#cWhite"%s\n\nPlease Re-Enter Your Password Confirm The Registration Process:", playerName(playerid));
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, ""#cSAMPRed"Re-Authenticate To "#SERVER_NAME"", gQuery, "Login", "Cancel");

		printf("%s(%d) Has Successfully Registered", playerName(playerid), playerid);
	}
	return 1;
}

UpdatePlayerDate(playerid)
{
	if(pLogged_Status[playerid] == 0) return 1;
	playerData[playerid][pLastVisit] = gettime();
	format(gQuery, sizeof(gQuery), "UPDATE "#mySQL_Accounts_Table" SET `pLastVisit` = UNIX_TIMESTAMP() WHERE `Username` = '%s' LIMIT 1", playerName(playerid));
	mysql_tquery(mysqlConnHandle, gQuery);
	return 1;
}

playerChangePasswordFromUser(username[MAX_PLAYER_NAME], password[MAX_PASSWORD_LEN])
{
	new passwordHashed[WP_HASH_LEN];
	WP_Hash(passwordHashed, sizeof(passwordHashed), password);
	format(gQuery, sizeof(gQuery), "UPDATE "#mySQL_Accounts_Table" SET `Password` = '%s' WHERE `Username` = '%s' LIMIT 1", passwordHashed, username);
	mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnPasswordChangedNick", "ss", username, password);
	return 1;
}

THREAD:OnPasswordChangedNick(username[MAX_PLAYER_NAME], password[MAX_PASSWORD_LEN])
{
	printf("[SYSTEM: OnPasswordChanged]: %s.", username);
	return 1;
}

togglePlayerNavigationTXD(playerid, bool:toggle, bool:tmLogo = true, bool:navigationTxd = true)
{
	if(toggle == true) {
		if(navigationTxd) {
			for(new i = 0; i < sizeof(Navigation_S); ++i) {
				TextDrawShowForPlayer(playerid, Navigation_S[i]);
			}
		}
		if(tmLogo) {
			for(new i = 0; i < sizeof(txdTMLogo); ++i) {
				TextDrawShowForPlayer(playerid, txdTMLogo[i]);
			}
		}
	} else {
		if(navigationTxd) {
			for(new i = 0; i < sizeof(Navigation_S); ++i) {
				TextDrawHideForPlayer(playerid, Navigation_S[i]);
			}
		}
		if(tmLogo) {
			for(new i = 0; i < sizeof(txdTMLogo); ++i) {
				TextDrawHideForPlayer(playerid, txdTMLogo[i]);
			}
		}
	}
}

togglePlayerLobbyGameTXD(playerid, gameid, bool:toggle = true)
{
	if(toggle == true) {
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Box_Outline]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Box]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Name]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Type]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Map]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_gState]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Players]);
		TextDrawShowForPlayer(playerid, gGameData[gameid][g_Lobby_Time]);
	} else {
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Box_Outline]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Box]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Name]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Type]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Map]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_gState]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Players]);
		TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Time]);
	}
}

processPlayerGameplay(playerid)
{
	//pSpawn_Request[playerid] = SPAWN_REQUEST_NONE;
	CreateHUD(playerid, pHUDType[playerid]);
	if(GetPVarInt(playerid, "pFirst_Gameplay") == 0)
	{
		TogglePlayerSpectating(playerid, true);
		tm_SelectTextdraw(playerid, NAVIGATION_COLOUR);
		SendClientMessageFormatted(playerid, -1, "Welcome Back, "#cNiceBlue"%s"#cWhite".", playerName(playerid));
		togglePlayerNavigationTXD(playerid, true);
		SetTimerEx("SpawnPlayerEx", 50, false, "i", playerid);
	} else {
		TogglePlayerSpectating(playerid, true);
		tm_SelectTextdraw(playerid, 0xFFD700FF);
		SetPVarInt(playerid, "pRegistration_Tutorial", 1);
		SetTimerEx("Registration_Tutorial", 1000, false, "i", playerid);
		OnDialogResponse(playerid, DIALOG_TUTORIAL, 1, 2, "");
		TextDrawShowForPlayer(playerid, iSpawn_Text);
		InterpolateCameraPos(playerid, 2694.757568, -2352.101562, 40.479072, -2172.573242, 2056.373779, 79.361602, 90000);
		InterpolateCameraLookAt(playerid, 2694.728027, -2347.103027, 40.359199, -2175.464355, 2060.436767, 78.995948, 45000);
	}
	SetSpawnInfo(playerid, NO_TEAM, 0, TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE, 0, 0, 0, 0, 0, 0);
	return;
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
	Vehicle_Missile_CurrentslotID[id] = 0;
	Vehicle_Using_Environmental[id] = 0;
	Vehicle_Machine_Gun_CurrentID[id] = 0;
	Vehicle_Machine_Gun_CurrentSlot[id] = 0;
	CallRemoteFunction("OnVehicleSpawn", "i", id);
	return id;
}

stock DestroyVehicleEx(vehicleid)
{
	if(Iter_Contains(Vehicles, vehicleid)) {
		new next;
		Iter_SafeRemove(Vehicles, vehicleid, next);
	}
	Vehicle_Interior[vehicleid] = 0;
	Vehicle_Driver[vehicleid] = INVALID_PLAYER_ID;
	return DestroyVehicle(vehicleid);
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

Float:Angle2D(Float:PointAx, Float:PointAy, Float:PointBx, Float:PointBy)
{
	new Float:Angle;
	Angle = -atan2(PointBx - PointAx, PointBy - PointAy);
	return Angle;
}

/*Float:GetDistanceBetweenPoints(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
	x1 -= x2,y1 -= y2,z1 -= z2;
	return floatsqroot((x1 * x1) + (y1 * y1) + (z1 * z1));
}*/

Float:GetPlayerDistanceToVehicle(playerid, vehicleid)
{
	new Float:vpos[3];
	GetVehiclePos(vehicleid, vpos[0], vpos[1], vpos[2]);
	return GetPlayerDistanceFromPoint(playerid, vpos[0], vpos[1], vpos[2]);
}

GetTwistedMetalName(modelid)
{
	new str[14] = "Unknown";
	switch(modelid)
	{
		case TMC_JUNKYARD_DOG: str = "Junkyard Dog";
		case TMC_BRIMSTONE: str = "Brimstone";
		case TMC_OUTLAW: str = "Outlaw";
		case TMC_REAPER: str = "Reaper";
		case TMC_ROADKILL: str = "Roadkill";
		case TMC_THUMPER: str = "Thumper";
		case TMC_SPECTRE: str = "Spectre";
		case TMC_DARKSIDE: str = "Darkside";
		case TMC_SHADOW: str = "Shadow";
		case TMC_MEATWAGON: str = "Meat Wagon";
		case TMC_VERMIN: str = "Vermin";
		case TMC_3_WARTHOG: str = "Warthog TM3";
		case TMC_MANSLAUGHTER: str = "Man Salughter";
		case TMC_HAMMERHEAD: str = "Hammerhead";
		case TMC_SWEETTOOTH: str = "Sweet Tooth";
	}
	return str;
}

GetTwistedMetalColour(modelid, shift = 1)  // SetPlayerColor(playerid, color);
{
	new color = 0xFFFFFFAA;
	switch(modelid)
	{//death warrant = niceblue, crimson fury FF85FF,
		case TMC_JUNKYARD_DOG: color = 0x82FFDAAA;
		case TMC_BRIMSTONE: color = 0xFCE1FCAA;
		case TMC_OUTLAW: color = 0xFFFFFFAA;
		case TMC_REAPER: color = 0xFF0000AA;
		case TMC_ROADKILL: color = 0x00FF00AA;
		case TMC_THUMPER: color = 0xBB00FFAA;
		case TMC_SPECTRE: color = 0x42BDFFAA;
		case TMC_DARKSIDE: color = 0x70CDFFAA;
		case TMC_SHADOW: color = 0xCE47FFAA;
		case TMC_MEATWAGON: color = 0xFF6969AA;
		case TMC_VERMIN: color = 0xFFE014AA;
		case TMC_3_WARTHOG: color = 0xFFFF30AA;
		case TMC_MANSLAUGHTER: color = 0xFFFFFFAA;
		case TMC_HAMMERHEAD: color = 0x145FFFAA;
		case TMC_SWEETTOOTH: color = 0xFF00FFAA;
	}
	if(shift == 1) return ShiftRGBAToARGB(color);
	return color;
}

// 1 per player (dynamic)
new PlayerText:Subtitle[MAX_PLAYERS] = {INVALID_PLAYER_TEXT_DRAW,...}; // Holds the current player's subtitle textdraw.
														 // SubtitleTimer PVar holds the timer ID.
ShowSubtitle(playerid, text[], time = 5000, override = 1, Float:x = 375.0, Float:y = 360.0)
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

	SetPVarInt(playerid, "SubtitleTimer", SetTimerEx("HideSubtitle", time, false, "i", playerid));

	if(Subtitle[playerid] == INVALID_PLAYER_TEXT_DRAW) return 0;
	return 1;
}

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

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if(!isServerAdmin(playerid)) return 1;
	SetPlayerPosFindZ(playerid, fX, fY, fZ);
	return 1;
}

public SendRandomMsg()
{
	new RandomMSG[12][103] =
	{
		"I am Calypso and I thank you for playing Twisted Metal...",
		"I am Calypso and I am the creator of Twisted Metal...",
		"I attempted to bring wife and daughter back..but.. I wasn't powerful enough...",
		"The Twisted Metal contests began since 1995.",
		"I'll serve this same foul humiliation back to that crooked, collapsed, cortex, criminally handicapped,",
		"This is ridiculous, really; Twisted Metal is my tournament, it's my brainchild, it's mine!",
		"Their emptiness makes me whole. Their weakness gives me strength. Their destruction is my creation.",
		"Before I created this contest.. I was just a regular man with a wife and daughter..",
		"I got into A car crash into A brick wall that killed my wife and daughter..",
		"Noone knows my real name, all I know that my surname is Sparks.",
		"When you win my contest.. you win one free wish..",
		"Follow Us On Twitter! "#cGrey"@TMSAMP_dev"
	}, randMsgID, msg[144];

	randMsgID = random(sizeof(RandomMSG));
	format(msg, sizeof(msg), "Calypso: "#cWhite"%s", RandomMSG[randMsgID]);
	foreach(Player, i)
	{
		SendClientMessage(i, cBotEx, msg);
		switch(randMsgID)
		{
			case 4: SendClientMessage(i, cBotEx, "Calypso: "#cWhite"overly-made up clown!");
			case 5: SendClientMessage(i, cBotEx, "Calypso: "#cWhite"This will be proven soon enough");
		}
	}
	return 1;
}

GetTwistedSpecialTimeUpdate(modelid)
{
	new time = 25;
	switch(modelid)
	{
		case TMC_JUNKYARD_DOG: time = 30;
		case TMC_BRIMSTONE: time = 25;
		case TMC_OUTLAW: time = 30;
		case TMC_REAPER: time = 20;
		case TMC_ROADKILL: time = 40;
		case TMC_THUMPER: time = 28;
		case TMC_SPECTRE: time = 25;
		case TMC_DARKSIDE: time = 32;
		case TMC_SHADOW: time = 35;
		case TMC_MEATWAGON: time = 30;
		case TMC_VERMIN: time = 25;
		case TMC_3_WARTHOG: time = 32;
		case TMC_MANSLAUGHTER: time = 25;
		case TMC_HAMMERHEAD: time = 25;
		case TMC_SWEETTOOTH: time = 32;
	}
	return time;
}

GetTwistedMaxSpecials() return 3;

enum rankingEnum
{
	player_Score,
	player_ID
}

GetPlayerHighestScores(array[][rankingEnum], left, right)
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

AssignRandomTeamHuntedPlayer(gameid, teamid)
{
	new randomplayer[MAX_PLAYERS], count = 0;
	foreach(Player, i)
	{
		if(playerData[i][gTeam] != teamid || playerData[i][gGameID] != gameid
			|| playerData[i][pSpawned_Status] == 0) continue;
		randomplayer[count] = i;
		++count;
	}
	if(count == 0) return 1;
	gHunted_Player[gameid][teamid] = randomplayer[random(count)];
	new engine, lights, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(pVehicleID[gHunted_Player[gameid][teamid]], engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(pVehicleID[gHunted_Player[gameid][teamid]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
	return 1;
}

public SpawnPlayerEx(playerid) return SpawnPlayer(playerid);

public OnGameBegin(gameid)
{
	foreach(iPlayersInGame[gameid], i)
	{
		if(pLogged_Status[i] == 0 || playerData[i][pSpawned_Status] == 1
			|| GetPVarInt(i, "pGarage") != 0) continue;
		if(!CanPlayerUseTwistedMetalVehicle(i, C_S_IDS[pTwistedIndex[i]][CS_VehicleModelID])) continue;
		switch(gGameData[gameid][g_Gamemode])
		{
			case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
			{
				if(playerData[i][gTeam] == INVALID_GAME_TEAM)
				{
					playerData[i][gTeam] = random(MAX_TEAMS);
					if(playerData[i][gTeam] == TEAM_DOLLS)
					{
						playerData[i][gRival_Team] = TEAM_CLOWNS;
					}
					else playerData[i][gRival_Team] = TEAM_DOLLS;
					SendClientMessage(i, -1, "You Have Been Placed In A Random Team!");
					AddPlayerToGameTeam(i);
				}
			}
		}
	}
	switch(gGameData[gameid][g_Gamemode])
	{
		case GM_HUNTED:
		{
			if(Iter_Count(iPlayersInGame[gameid]) > 0)
			{
				gHunted_Player[gameid][0] = Iter_Random(iPlayersInGame[gameid]);
				if(playerData[gHunted_Player[gameid][0]][pSpawned_Status] == 1)
				{
					new engine, lights, alarm, doors, bonnet, boot, objective;
					GetVehicleParamsEx(pVehicleID[gHunted_Player[gameid][0]], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(pVehicleID[gHunted_Player[gameid][0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
				}
			}
		}
		case GM_TEAM_HUNTED:
		{
			for(new teamid = 0; teamid < MAX_TEAMS; teamid++)
			{
				AssignRandomTeamHuntedPlayer(gameid, teamid);
			}
		}
	}
	return 1;
}

public OnGameJoin(gameid, mapid, playerid)
{
	printf("[System: OnGameJoin] - gameid: %d - mapid: %d(%s) - playerid: %d(%s)", gameid, mapid, s_Maps[mapid][m_Name], playerid, playerName(playerid));
	if(!Iter_Contains(iPlayersInGame[gameid], playerid)) {
		Iter_Add(iPlayersInGame[gameid], playerid);
	}
	switch(gGameData[gameid][g_Gamemode])
	{
		case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
		{
			playerData[playerid][gTeam] = TEAM_CLOWNS;
			playerData[playerid][gRival_Team] = TEAM_DOLLS;
		}
		case GM_RACE:
		{
			CP_Progress[playerid] = s_Maps[mapid][m_Max_Grids];
			Race_Current_Lap[playerid] = 1;
			Race_Position[playerid] = 0;
			Race_Old_Position[playerid] = 0;
			p_Position[playerid] = 0;
			p_Old_Position[playerid] = 0;
			SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
		}
	}
	HideKillStreak(playerid);
	PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], "0");
	PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
	playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 0;
	playerData[playerid][pKillStreaking] = -1;
	pFirstTimeViewingMap[playerid] = 1;
	playerData[playerid][pLast_Killed_By] = INVALID_PLAYER_ID;
	playerData[playerid][pDamageDone] = 0;
	playerData[playerid][pDamageTaken] = 0;
	foreach(iPlayersInGame[gameid], i)
	{
		if(playerData[playerid][pDamageToPlayer][i] == 0.0) continue;
		playerData[playerid][pDamageToPlayer][i] = 0.0;
	}
	return 1;
}

public OnGameLeave(gameid, playerid)
{
	--gGameData[gameid][g_Players];
	format(gString, sizeof(gString), "%d/"#MAX_PLAYERS_PER_LOBBY"", gGameData[gameid][g_Players]);
	TextDrawSetString(gGameData[gameid][g_Lobby_Players], gString);
	TextDrawHideForPlayer(playerid, gGameData[gameid][g_Lobby_Players]);
	TextDrawHideForPlayer(playerid, gGameData[gameid][g_Gamemode_Time_Text]);
	SendClientMessage(playerid, COLOR_RED, "Now leaving Multi-Player action.");
	if(gameid != FREEROAM_GAME) {
		hidePlayerTeamTextDraws(playerid, false);
		if(Iter_Contains(iPlayersInGame[gameid], playerid)) {
			Iter_Remove(iPlayersInGame[gameid], playerid);
		}
		for(new rb = 0; rb < 4; rb++) {
			PlayerTextDrawHide(playerid, Race_Box_Text[playerid][rb]);
		}
		PlayerTextDrawHide(playerid, Race_Box_Outline[playerid]);
		PlayerTextDrawHide(playerid, Race_Box[playerid]);
		switch(gGameData[gameid][g_Gamemode])
		{
			case GM_RACE:
			{
				if((0 <= gGameData[gameid][g_Map_id] <= (MAX_MAPS - 1))) {
					CP_Progress[playerid] = s_Maps[gGameData[gameid][g_Map_id]][m_Max_Grids];
				}
				if(1 <= Race_Position[playerid] <= 3) {
					foreach(iPlayersInGame[gameid], i)
					{
						PlayerTextDrawHide(i, Race_Box_Text[i][Race_Position[playerid] - 1]);
					}
				}
				TemporaryRaceQuitList(playerid, .action = 0);
			}
			case GM_DEATHMATCH, GM_HUNTED:
			{
				if(1 <= p_Position[playerid] <= 3) {
					foreach(iPlayersInGame[gameid], i)
					{
						PlayerTextDrawHide(i, Race_Box_Text[i][p_Position[playerid] - 1]);
					}
				}
				if(gGameData[gameid][g_Gamemode] == GM_HUNTED)
				{
					if(gHunted_Player[gameid][0] == playerid)
					{
						if(Iter_Count(iPlayersInGame[gameid]) > 0)
						{
							gHunted_Player[gameid][0] = Iter_Random(iPlayersInGame[gameid]);
							if(IsPlayerConnected(gHunted_Player[gameid][0]))
							{
								if(playerData[gHunted_Player[gameid][0]][pSpawned_Status] == 1)
								{
									new engine, lights, alarm, doors, bonnet, boot, objective;
									GetVehicleParamsEx(pVehicleID[gHunted_Player[gameid][0]], engine, lights, alarm, doors, bonnet, boot, objective);
									SetVehicleParamsEx(pVehicleID[gHunted_Player[gameid][0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
								}
							}
						}
					}
				}
			}
			case GM_TEAM_HUNTED:
			{
				if(gHunted_Player[gameid][playerData[playerid][gTeam]] == playerid)
				{
					new engine, lights, alarm, doors, bonnet, boot, objective;
					gHunted_Player[gameid][playerData[playerid][gTeam]] = INVALID_PLAYER_ID;
					GetVehicleParamsEx(pVehicleID[playerid], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(pVehicleID[playerid], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_OFF);
					AssignRandomTeamHuntedPlayer(gameid, playerData[playerid][gTeam]);
				}
			}
			case GM_LAST_MAN_STANDING:
			{
				new count = 0;
				foreach(iPlayersInGame[gameid], i)
				{
					if(i == playerid || playerData[i][pSpawned_Status] == 0) continue;
					++count;
				}
				if(count == 1) {
					OnMapFinish(gameid, gGameData[gameid][g_Gamemode], gGameData[gameid][g_Map_id]);
				}
			}
			case GM_TEAM_LAST_MAN_STANDING:
			{
				foreach(iPlayersInGame[gameid], i)
				{
					if(i == playerid) continue;
					UpdatePlayerLMSTeamInfo(i);
				}
			}
		}
		if(playerData[playerid][gTeam] != INVALID_GAME_TEAM) {
			--gTeam_Player_Count[gameid][playerData[playerid][gTeam]];
			playerData[playerid][gTeam] = INVALID_GAME_TEAM;
		}
		if(playerData[playerid][gRival_Team] != INVALID_GAME_TEAM) {
			playerData[playerid][gRival_Team] = INVALID_GAME_TEAM;
		}
	}
	playerData[playerid][gGameID] = INVALID_GAME_ID;
	DeletePVar(playerid, "pMultiplayer");
	return 1;
}

public Overlay()
{
	new result[64], minutes;
	for(new gameid = 0; gameid < MAX_GAME_LOBBIES; gameid++)
	{
		if(gGameData[gameid][g_Voting_Time] != 0) continue;
		if(gGameData[gameid][g_Gamemode_Time] == 0)
		{
			OnMapFinish(gameid, gGameData[gameid][g_Gamemode], gGameData[gameid][g_Map_id]);
			continue;
		}
		if(gGameData[gameid][g_Gamemode_Countdown_Time] == 0)
		{
			TextDrawSetString(gGameData[gameid][g_Lobby_gState], "IN GAME");
			format(result, sizeof(result), "BEGIN!~n~%s", s_Gamemodes[gGameData[gameid][g_Gamemode]][GM_Name]);
			foreach(iPlayersInGame[gameid], i)
			{
				if(GetPVarInt(i, "pClassSelection")) continue;
				TimeTextForPlayer( TIMETEXT_MIDDLE_SUPER_LARGE, i, result, 3000 );
				TogglePlayerControllable(i, true);
				PlayerPlaySound(i, 44602, 0.0, 0.0, 0.0);
			}
			OnGameBegin(gameid);
		}
		if(gGameData[gameid][g_Gamemode_Countdown_Time] < 0)
		{
			minutes = (gGameData[gameid][g_Gamemode_Time] / 60);
			format(result, 12, "%02d:%02d", minutes, gGameData[gameid][g_Gamemode_Time] - (minutes * 60));
			TextDrawSetString(gGameData[gameid][g_Gamemode_Time_Text], result);
			TextDrawSetString(gGameData[gameid][g_Lobby_Time], result);
			--gGameData[gameid][g_Gamemode_Time];
		} else {
			minutes = (gGameData[gameid][g_Gamemode_Countdown_Time] / 60);
			format(result, 12, "%02d:%02d", minutes, gGameData[gameid][g_Gamemode_Countdown_Time] - (minutes * 60));
			TextDrawSetString(gGameData[gameid][g_Gamemode_Time_Text], result);
			TextDrawSetString(gGameData[gameid][g_Lobby_Time], result);
			--gGameData[gameid][g_Gamemode_Countdown_Time];
		}
		switch(gGameData[gameid][g_Gamemode])
		{
			case GM_RACE:
			{
				if(gGameData[gameid][g_Map_id] != (MAX_MAPS + 1)) {
					Race_Loop(gameid);
				}
				foreach(Player, playerid)
				{
					if(playerData[playerid][pSpawned_Status] == 0) continue;
					if(playerData[playerid][gGameID] != gameid) continue;
					new rpos = (Race_Position[playerid] >= 4) ? 4 : Race_Position[playerid],
						boxc, ocount = 0, id;

					if(rpos > 4) {
						rpos = 4;
					}
					if(rpos <= 3) {
						for(new opos = (rpos - 1); opos < 3; ++opos) {
							if(opos < 0) continue;
							if(Game_Top3_Positions[gameid][opos] == playerid) continue;
							if(Game_Top3_Positions[gameid][opos] != INVALID_PLAYER_ID) {
								++ocount;
							}
						}
						boxc += rpos;
						boxc += ocount;
					}
					SetPositionalBox(playerid, boxc);
					for(new pos = 0; pos < 3; pos++)
					{
						id = Game_Top3_Positions[gameid][pos];
						if(id == playerid) {
							for(new opos = 0; opos < 3; opos++)
							{
								if(pos == opos) continue;
								if(Game_Top3_Positions[gameid][opos] == playerid)
								{
									PlayerTextDrawHide(playerid, Race_Box_Text[playerid][opos]);
									Game_Top3_Positions[gameid][opos] = INVALID_PLAYER_ID;
								}
							}
						}
						if(id == INVALID_PLAYER_ID) {
							PlayerTextDrawHide(playerid, Race_Box_Text[playerid][pos]);
							continue;
						}
						if(!IsPlayerConnected(id)) {
							PlayerTextDrawHide(playerid, Race_Box_Text[playerid][pos]);
							Game_Top3_Positions[gameid][pos] = INVALID_PLAYER_ID;
							continue;
						}
						if(playerid == id) 
							PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], 0x00FF00FF);
						else 
							PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], -1);

						format(gString, sizeof(gString), "%d   %s", Race_Position[id], playerName(id));
						PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][pos], gString);
						PlayerTextDrawShow(playerid, Race_Box_Text[playerid][pos]);
					}
				}
			}
			case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED:
			{
				foreach(iPlayersInGame[gameid], i)
				{
					AdjustTeamColoursForPlayer(i);
				}
			}
			case GM_DEATHMATCH, GM_HUNTED, GM_LAST_MAN_STANDING:
			{
				for(new opos = 0; opos < 3; opos++)
				{
					if(Game_Top3_Positions[gameid][opos] != INVALID_PLAYER_ID)
					{
						Game_Top3_Positions[gameid][opos] = INVALID_PLAYER_ID;
					}
				}
				new playerScores[MAX_PLAYERS][rankingEnum], index, id;
				foreach(iPlayersInGame[gameid], i)
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
						Game_Top3_Positions[gameid][p_Position[id] - 1] = id;
					}
				}
				foreach(iPlayersInGame[gameid], playerid)
				{
					if(playerData[playerid][pSpawned_Status] == 0) continue;
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
							if(Game_Top3_Positions[gameid][opos] == playerid) continue;
							if(Game_Top3_Positions[gameid][opos] != INVALID_PLAYER_ID)
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
						id = Game_Top3_Positions[gameid][pos];
						if(id == playerid)
						{
							for(new opos = 0; opos < 3; opos++)
							{
								if(pos == opos) continue;
								if(Game_Top3_Positions[gameid][opos] == playerid)
								{
									PlayerTextDrawHide(playerid, Race_Box_Text[playerid][opos]);
									Game_Top3_Positions[gameid][opos] = INVALID_PLAYER_ID;
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
							Game_Top3_Positions[gameid][pos] = INVALID_PLAYER_ID;
							continue;
						}
						if(playerid == id) PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], 0x00FF00FF);
						else PlayerTextDrawColor(playerid, Race_Box_Text[playerid][pos], -1);
						format(gString, sizeof(gString), "%d   %s   ~r~~h~%d", p_Position[id], playerName(id), GetPlayerGamePoints(id));
						PlayerTextDrawSetString(playerid, Race_Box_Text[playerid][pos], gString);
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
						if(strlen(playerName(playerScores[i][player_ID])) >= 19)
						{
							format(score_Text, sizeof(score_Text), "%d   %s ~r~~h~%d", i + 1, playerName(playerScores[i][player_ID]), playerScores[i][player_Score]);
						}
						else format(score_Text, sizeof(score_Text), "%d   %s   ~r~~h~%d", i + 1, playerName(playerScores[i][player_ID]), playerScores[i][player_Score]);
						foreach(Player, playerid)
						{
							if(playerData[playerid][pSpawned_Status] == 0) continue;
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
							format(gString, sizeof(gString), "~g~~h~~h~%d   ~r~~h~%d", p_Position[id], playerName(id), GetPlayerGamePoints(id));
							PlayerTextDrawSetString(id, Race_Box_Text[id][3], gString);
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
	new vehicleid, Float:x, Float:y, Float:z, Float:groundZ, 
		Float:health, model, time = gettime(),
		Found_Vehicle = INVALID_VEHICLE_ID,
		checklowest = 0;

	foreach(Player, i)
	{
		if(playerData[i][pSpawned_Status] == 0) continue;
		vehicleid = GetPlayerVehicleID(i);
		if(vehicleid == 0) continue;
		if((1 <= vehicleid <= 2000)) {
			model = GetVehicleModel(vehicleid);

			if(playerData[i][pEnergy] < floatround(GetTwistedMetalMaxEnergy(model))) {
				++playerData[i][pEnergy];
				SetPlayerProgressBarValue(i, pTextInfo[i][pEnergyBar], float(playerData[i][pEnergy]));
				UpdatePlayerProgressBar(i, pTextInfo[i][pEnergyBar]);
			}

			GetVehiclePos(vehicleid, x, y, z);

			if(GetPVarInt(i, "pJump_GroundCheck") == 1 && GetPVarInt(i, "pJump_Index") > 0) {
				MapAndreas_FindZ_For2DCoord(x, y, groundZ);
				//SendClientMessageFormatted(i, -1, "dis to ground: %0.2f.", (z - groundZ));
				if((z - groundZ) < 1.0) {
					resetPlayerJumpData(i);
				}
			}

			if(playerData[i][gGameID] == FREEROAM_GAME) {
				checklowest = 1;
			}
			else if(gGameData[playerData[i][gGameID]][g_Map_id] != INVALID_MAP_ID) {
				checklowest = s_Maps[gGameData[playerData[i][gGameID]][g_Map_id]][m_CheckLowestZ];
			} else {
				checklowest = 0;
			}

			if(z < getMapLowestZ(gGameData[playerData[i][gGameID]][g_Map_id]) && checklowest == 1) {
				new Float:newhealth;
				T_GetVehicleHealth(vehicleid, health);
				newhealth = (health - GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid)));
				T_SetVehicleHealth(vehicleid, newhealth);
				if( newhealth <= 0.0 && health > 0.0) {
					CallLocalFunction( "OnPlayerTwistedDeath", "ddddddi", i, vehicleid, i, vehicleid, Missile_Fall, GetVehicleModel(vehicleid), GetVehicleModel(vehicleid));
				}
				continue;
			}

			if(getMapHighestZ(gGameData[playerData[i][gGameID]][g_Map_id]) != 0.0) {
				if(z >= getMapHighestZ(gGameData[playerData[i][gGameID]][g_Map_id])) {
					new Float:vX, Float:vY, Float:vZ;
					GetVehicleVelocity(vehicleid, vX, vY, vZ);
					SetVehicleVelocity(vehicleid, vX, vY, (vZ / 2));
				}
			}
			if(EMPTime[i] > 0) {
				--EMPTime[i];
				SetVehicleAngularVelocity(vehicleid, 0.015, 0.015, 0.0);
				if(EMPTime[i] == 0) {
					TogglePlayerControllable(i, true);
					AddEXPMessage(i, "~y~~h~Unfrozen!");
				}
				//else SetVehicleAngularVelocity(vehicleid, 0.0, 0.0, 0.0);
			}
			foreach(Vehicles, v)
			{
				if(v == vehicleid || !IsVehicleStreamedIn(v, i)) continue;
				if(!GetVehiclePos(v, x, y, z)) continue;
				if(!IsPlayerAimingAt(i, x, y, z, 40.0)) continue;
				Found_Vehicle = v;
				break;
			}
			if(Found_Vehicle == INVALID_VEHICLE_ID) {
				HidePlayerProgressBar(i, pTextInfo[i][pAiming_Health_Bar]);
				PlayerTextDrawHide(i, pTextInfo[i][AimingPlayer]);
			} else {
				T_GetVehicleHealth(Found_Vehicle, health);
				PlayerTextDrawSetString(i, pTextInfo[i][AimingPlayer], GetTwistedMetalName(GetVehicleModel(Found_Vehicle)));
				SetPlayerProgressBarValue(i, pTextInfo[i][pAiming_Health_Bar], health / GetTwistedMetalMaxHealth(GetVehicleModel(Found_Vehicle)) * 100.0);
				ShowPlayerProgressBar(i, pTextInfo[i][pAiming_Health_Bar]);
				PlayerTextDrawShow(i, pTextInfo[i][AimingPlayer]);
				Found_Vehicle = INVALID_VEHICLE_ID;
			}
			Found_Vehicle = GetVehicleModel(vehicleid);
			if((time - LastSpecialUpdateTick[i]) > GetTwistedSpecialTimeUpdate(Found_Vehicle)) {
				if(playerData[i][pMissiles][Missile_Special] >= GetTwistedMaxSpecials()) continue;
				++playerData[i][pMissiles][Missile_Special];
				new c;
				for(new m = (Missile_Special + 1); m < (MAX_MISSILEID); m++)
				{
					if(playerData[i][pMissiles][m] != 0) {
						c = m;
						continue;
					}
				}
				if(!c) {
					pMissileID[i] = Missile_Special;
				}
				updatePlayerHUD(i);
				LastSpecialUpdateTick[i] = time;
			}
			Found_Vehicle = INVALID_VEHICLE_ID;
			checklowest = 0;
		}
		if(pPlayerUpdate[i] >= 2 && !isPlayerPaused(i)) {
			pPaused[i] = true;
			CallRemoteFunction("OnPlayerPause", "i", i);
		} else {
			pPlayerUpdate[i]++;
		}
	}
	return 1;
}

/*new const
		  KEY_VEHICLE_FORWARD  = 0b001000,
		  KEY_VEHICLE_BACKWARD = 0b100000
;*/

//LD_TATT:9gun - minigun td

//LD_TATT:12bndit - dolls td
//LD_TATT:6clown - clowns td

new VehicleColoursTableRGBA[256] = {
	// The existing colours from San Andreas
	0x000000FF, 0xF5F5F5FF, 0x2A77A1FF, 0x840410FF, 0x263739FF, 0x86446EFF, 0xD78E10FF, 0x4C75B7FF, 0xBDBEC6FF, 0x5E7072FF,
	0x46597AFF, 0x656A79FF, 0x5D7E8DFF, 0x58595AFF, 0xD6DAD6FF, 0x9CA1A3FF, 0x335F3FFF, 0x730E1AFF, 0x7B0A2AFF, 0x9F9D94FF,
	0x3B4E78FF, 0x732E3EFF, 0x691E3BFF, 0x96918CFF, 0x515459FF, 0x3F3E45FF, 0xA5A9A7FF, 0x635C5AFF, 0x3D4A68FF, 0x979592FF,
	0x421F21FF, 0x5F272BFF, 0x8494ABFF, 0x767B7CFF, 0x646464FF, 0x5A5752FF, 0x252527FF, 0x2D3A35FF, 0x93A396FF, 0x6D7A88FF,
	0x221918FF, 0x6F675FFF, 0x7C1C2AFF, 0x5F0A15FF, 0x193826FF, 0x5D1B20FF, 0x9D9872FF, 0x7A7560FF, 0x989586FF, 0xADB0B0FF,
	0x848988FF, 0x304F45FF, 0x4D6268FF, 0x162248FF, 0x272F4BFF, 0x7D6256FF, 0x9EA4ABFF, 0x9C8D71FF, 0x6D1822FF, 0x4E6881FF,
	0x9C9C98FF, 0x917347FF, 0x661C26FF, 0x949D9FFF, 0xA4A7A5FF, 0x8E8C46FF, 0x341A1EFF, 0x6A7A8CFF, 0xAAAD8EFF, 0xAB988FFF,
	0x851F2EFF, 0x6F8297FF, 0x585853FF, 0x9AA790FF, 0x601A23FF, 0x20202CFF, 0xA4A096FF, 0xAA9D84FF, 0x78222BFF, 0x0E316DFF,
	0x722A3FFF, 0x7B715EFF, 0x741D28FF, 0x1E2E32FF, 0x4D322FFF, 0x7C1B44FF, 0x2E5B20FF, 0x395A83FF, 0x6D2837FF, 0xA7A28FFF,
	0xAFB1B1FF, 0x364155FF, 0x6D6C6EFF, 0x0F6A89FF, 0x204B6BFF, 0x2B3E57FF, 0x9B9F9DFF, 0x6C8495FF, 0x4D8495FF, 0xAE9B7FFF,
	0x406C8FFF, 0x1F253BFF, 0xAB9276FF, 0x134573FF, 0x96816CFF, 0x64686AFF, 0x105082FF, 0xA19983FF, 0x385694FF, 0x525661FF,
	0x7F6956FF, 0x8C929AFF, 0x596E87FF, 0x473532FF, 0x44624FFF, 0x730A27FF, 0x223457FF, 0x640D1BFF, 0xA3ADC6FF, 0x695853FF,
	0x9B8B80FF, 0x620B1CFF, 0x5B5D5EFF, 0x624428FF, 0x731827FF, 0x1B376DFF, 0xEC6AAEFF, 0x000000FF,
	// SA-MP extended colours (0.3x)
	0x177517FF, 0x210606FF, 0x125478FF, 0x452A0DFF, 0x571E1EFF, 0x010701FF, 0x25225AFF, 0x2C89AAFF, 0x8A4DBDFF, 0x35963AFF,
	0xB7B7B7FF, 0x464C8DFF, 0x84888CFF, 0x817867FF, 0x817A26FF, 0x6A506FFF, 0x583E6FFF, 0x8CB972FF, 0x824F78FF, 0x6D276AFF,
	0x1E1D13FF, 0x1E1306FF, 0x1F2518FF, 0x2C4531FF, 0x1E4C99FF, 0x2E5F43FF, 0x1E9948FF, 0x1E9999FF, 0x999976FF, 0x7C8499FF,
	0x992E1EFF, 0x2C1E08FF, 0x142407FF, 0x993E4DFF, 0x1E4C99FF, 0x198181FF, 0x1A292AFF, 0x16616FFF, 0x1B6687FF, 0x6C3F99FF,
	0x481A0EFF, 0x7A7399FF, 0x746D99FF, 0x53387EFF, 0x222407FF, 0x3E190CFF, 0x46210EFF, 0x991E1EFF, 0x8D4C8DFF, 0x805B80FF,
	0x7B3E7EFF, 0x3C1737FF, 0x733517FF, 0x781818FF, 0x83341AFF, 0x8E2F1CFF, 0x7E3E53FF, 0x7C6D7CFF, 0x020C02FF, 0x072407FF,
	0x163012FF, 0x16301BFF, 0x642B4FFF, 0x368452FF, 0x999590FF, 0x818D96FF, 0x99991EFF, 0x7F994CFF, 0x839292FF, 0x788222FF,
	0x2B3C99FF, 0x3A3A0BFF, 0x8A794EFF, 0x0E1F49FF, 0x15371CFF, 0x15273AFF, 0x375775FF, 0x060820FF, 0x071326FF, 0x20394BFF,
	0x2C5089FF, 0x15426CFF, 0x103250FF, 0x241663FF, 0x692015FF, 0x8C8D94FF, 0x516013FF, 0x090F02FF, 0x8C573AFF, 0x52888EFF,
	0x995C52FF, 0x99581EFF, 0x993A63FF, 0x998F4EFF, 0x99311EFF, 0x0D1842FF, 0x521E1EFF, 0x42420DFF, 0x4C991EFF, 0x082A1DFF,
	0x96821DFF, 0x197F19FF, 0x3B141FFF, 0x745217FF, 0x893F8DFF, 0x7E1A6CFF, 0x0B370BFF, 0x27450DFF, 0x071F24FF, 0x784573FF,
	0x8A653AFF, 0x732617FF, 0x319490FF, 0x56941DFF, 0x59163DFF, 0x1B8A2FFF, 0x38160BFF, 0x041804FF, 0x355D8EFF, 0x2E3F5BFF,
	0x561A28FF, 0x4E0E27FF, 0x706C67FF, 0x3B3E42FF, 0x2E2D33FF, 0x7B7E7DFF, 0x4A4442FF, 0x28344EFF
};

main() {}

public OnGameModeInit()
{
	//printf("Launch Angle: %0.2f", GetRequiredAngle(5.0, 10.0));
	//new Float:y2 = 2637.27, Float:y = 2640.60, Float:x2 = -2319.87, Float:xx = -2290.19,
	//	Float:Old_Missile_Angle = 92.96, Float:newangle, Float:difference;
	//newangle = Angle2D( xx, y, x2, y2 ) - 90.0;
	//difference = (newangle - Old_Missile_Angle);
	//printf("Normal difference: %0.2f", difference);
	//if(difference < 0.0) difference *= -1;
	//printf("y2: %0.2f - y: %0.2f - x2: %0.2f - xx: %0.2f - newangle: %0.2f - Old_Missile_Angle: %0.2f -", y2, y, x2, xx, newangle, Old_Missile_Angle);
	//printf("After Negative Check difference: %0.2f", difference);
	//if(difference != 0.0) return 1;
	//[18:52:29] y2: 2637.27 - y: 2640.60 - x2: -2319.87 - x: -2290.19 - newangle: -173.58 - Old_Missile_Angle: 92.96 -
	//[18:52:29] [Fire] Homing difference: 266.55
	//[18:52:30] Homing difference: 4.03
	
	printf("[Heapspace - OnGameModeInit] - heapspace(): %i - Heapspace: %i kilobytes", heapspace(), heapspace() / 1024);
	Iter_Init(pSlots_In_Use);
	Iter_Init(Map_Selection);
	Iter_Init(m_Destroyables);
	Iter_Init(m_Map_Objects);
	Iter_Init(m_Map_Pickups);
	Iter_Init(iPlayersInGame);

	//SendRconCommand("loadfs Twisted_Pic");
	SendRconCommand("hostname "#SERVER_NAME" v"#SERVER_VERSION"");
	SendRconCommand("gamemodetext Vehicular Combat|Race|DD|DM");
	SendRconCommand("weburl "#SERVER_WEBSITE"");
	SendRconCommand("mapname Twisted San Andreas");
	
	new StartTick = GetTickCount();
	
	SetWorldTime(3);
	ManualVehicleEngineAndLights();
	EnableStuntBonusForAll(false);
	DisableInteriorEnterExits();
	
	MapAndreas_Init(MAP_ANDREAS_MODE_MINIMAL);
	
	for(new i = 0; i < MAX_MAPS; ++i) {
		s_Maps[i][m_ID] = -1;
	}
	SetTimer("OnMissileUpdate", 65, true);
	SetTimer("Overlay", 997, true);
	SetTimer("SendRandomMsg", 255001, true);

	initializeMySQL();
	
	if(server_mode == SERVER_MODE_NORMAL) {
		connectIRCBots(.serverStart = 1);
	}
	
	new mapid;
	
	mapid = CreateMap("Skyscraper (S.F Skyline)", MAP_TYPE_NORMAL);
	SetMapData(mapid, MD_TYPE_LowestZ, ""#MAP_SKYSCRAPER_Z"", .valuetype = MD_Float);
	
	AddMapSpawn(MAP_SKYSCRAPERS, -2294.051, 476.350, 73.351, 226.0);
	AddMapSpawn(MAP_SKYSCRAPERS, -2189.6624, 397.0610, 60.1914, 43.3923);
	AddMapSpawn(MAP_SKYSCRAPERS, -2066.5410,483.5458,139.3674,177.2467);
	AddMapSpawn(MAP_SKYSCRAPERS, -2030.0596,444.3904,139.3674,86.9886);
	AddMapSpawn(MAP_SKYSCRAPERS, -2294.2964,423.0440,73.3671,347.6301);
	AddMapSpawn(MAP_SKYSCRAPERS, -2357.9277,390.9946,72.8832,2.9862);
	AddMapSpawn(MAP_SKYSCRAPERS, -2444.3015,445.5710,72.8828,294.4821);
	AddMapSpawn(MAP_SKYSCRAPERS, -2162.0969,336.5743,57.7409,41.5695);
	AddMapSpawn(MAP_SKYSCRAPERS, -2237.8096,335.9155,54.5704,319.8129);
	
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
	
	AddMapSpawn(MAP_DOWNTOWN, -1987.6123,-1006.0413,32.4640,359.4698);
	AddMapSpawn(MAP_DOWNTOWN, -2159.5183,-988.0478,32.4197,0.1144);
	AddMapSpawn(MAP_DOWNTOWN, -2141.6816,-1005.2360,32.4375,270.4423);
	AddMapSpawn(MAP_DOWNTOWN, -2144.4934,-714.6802,32.4239,270.2378);
	AddMapSpawn(MAP_DOWNTOWN, -2159.4753,-729.0433,32.4129,180.0636);
	AddMapSpawn(MAP_DOWNTOWN, -1987.4827,-715.3997,32.4641,180.8086);
	AddMapSpawn(MAP_DOWNTOWN, -1922.7969,-731.0041,32.4200,180.9581);
	AddMapSpawn(MAP_DOWNTOWN, -1937.9205,-714.5966,32.4282,90.2995);
	AddMapSpawn(MAP_DOWNTOWN, -1988.4668,-858.7548,32.4602,271.0332);
	AddMapSpawn(MAP_DOWNTOWN, -1935.1844,-1005.2726,32.4287,90.1289);
	AddMapSpawn(MAP_DOWNTOWN, -1922.7192,-989.6423,32.4165,0.6842);
	
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
	AddMapObject(MAP_HANGER18, 8824, -1136.59997559, 395.50000000, 33.50000000,0.0,269.00000000,134.89791870, 0.0); //object(vgseedge05) (7)
	AddMapObject(MAP_HANGER18, 8824, -1235.76000977, 297.39999390, 33.50000000,0.0,271.00000000,135.10003662, 0.0); //object(vgseedge05) (8)
	AddMapObject(MAP_HANGER18, 8824, -1334.09997559, 199.60000610, 33.20000076,0.0,272.99902344,135.09887695, 0.0); //object(vgseedge05) (9)
	AddMapObject(MAP_HANGER18, 8824, -1432.80004883, 100.59999847, 33.29999924,0.0,272.99377441,135.09341431, 0.0); //object(vgseedge05) (10)
	AddMapObject(MAP_HANGER18, 8824, -1531.00000000, 2.09999990, 33.00000000,0.0,272.99377441,135.09341431, 0.0); //object(vgseedge05) (11)
	AddMapObject(MAP_HANGER18, 8824, -1629.09997559, -97.09999847, 32.29999924,0.0,272.99377441,135.09341431, 0.0); //object(vgseedge05) (12)
	AddMapObject(MAP_HANGER18, 8824, -1701.19995117, -211.19999695, 32.09999847,0.0,272.99377441,165.09344482, 0.0); //object(vgseedge05) (13)
	AddMapObject(MAP_HANGER18, 8824, -1726.79992676, -347.50000000, 32.29999924,0.0,272.98828125,175.09155273, 0.0); //object(vgseedge05) (14)
	AddMapObject(MAP_HANGER18, 8824, -1734.69995117, -487.0,		32.00000000,0.0,272.98278809,179.08911133, 0.0); //object(vgseedge05) (15)
	AddMapObject(MAP_HANGER18, 8824, -1733.00000000, -624.0,		32.50000000,0.0,272.97729492,183.08813477, 0.0); //object(vgseedge05) (17)
	AddMapObject(MAP_HANGER18, 8824, -1686.30004883, -647.50,		32.70000076,0.0,270.97180176,233.08715820, 0.0); //object(vgseedge05) (18)
	AddMapObject(MAP_HANGER18, 8824, -1562.40002441, -694.29998779, 32.50000000,0.0,268.97167969,270.08593750, 0.0); //object(vgseedge05) (19)
	AddMapObject(MAP_HANGER18, 8824, -1422.59997559, -694.0,		32.20000076,0.0,268.96728516,270.08239746, 0.0); //object(vgseedge05) (20)
	AddMapObject(MAP_HANGER18, 8824, -1284.40002441, -693.90002441, 32.20000076,0.0,268.96728516,270.08239746, 0.0); //object(vgseedge05) (21)
	AddMapObject(MAP_HANGER18, 8824, -1107.40002441, -175.39999390, 32.00000000,0.0,267.99499512,26.69287109, 0.0); //object(vgseedge05) (22)
	AddMapObject(MAP_HANGER18, 8824, -1061.90002441, -207.60000610, 33.09999847,0.0,90.00000000,114.69140625, 0.0); //object(vgseedge05) (23)
	AddMapObject(MAP_HANGER18, 8824, -1228.30004883, -634.20001221, 32.00000000,0.0,268.96728516,0.08239746, 0.0); //object(vgseedge05) (24)
	AddMapObject(MAP_HANGER18, 8824, -1175.59997559, -494.10000610, 32.79999924,0.0,90.0,138.68630981, 0.0); //object(vgseedge05) (25)
	AddMapObject(MAP_HANGER18, 8824, -1122.69995117, -386.50,		32.79999924,0.0,90.0,162.68591309, 0.0); //object(vgseedge05) (27)
	AddMapObject(MAP_HANGER18, 8824, -1125.80004883, -321.60000610, 32.79999924,0.0,267.99499512,6.69128418, 0.0); //object(vgseedge05) (28)
	AddMapObject(MAP_HANGER18, 8824, -1148.39, 		36.45, 			17.18,   	90.00, 90.00, 135.49, 0.0); //object(vgseedge05) (28)
	AddMapObject(MAP_HANGER18, 8824, -1148.39, 		36.45, 			17.18,   	90.00, 90.00, 135.49, 0.0); //object(vgseedge05) (28)
	AddMapObject(MAP_HANGER18, 3881, -1229.3281, 53.3281, 14.9844, 356.8584, 0.0000, 224.3960, 0.0, .destroyable = 1); // boot at parking end
	AddMapObject(MAP_HANGER18, 10810, -1687.4141, -623.0234, 18.1484, 0.0, 0.0, 0.0, 0.0, .destroyable = 1); 
	AddMapObject(MAP_HANGER18, 3881,  -1542.46, -443.40, 6.85, 0.00, 0.00, 316.00, 0.0, .destroyable = 1); // boot at entrance

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
	
	mapid = CreateMap("Freeway", MAP_TYPE_NORMAL);
	SetMapData(mapid, MD_TYPE_MaxZ, "71.0", .valuetype = MD_Float);
	
	AddMapPickup(MAP_FREEWAY, PICKUPTYPE_MACHINE_GUN_UPGRADE, 2050.6685, 318.4796, 28.3892);

	AddMapObject(MAP_FREEWAY, 8051,1592.7998047,4.7998047,39.7999992,0.0000000,90.0000000,103.9965820); //object(vegassedge13) (3)
	AddMapObject(MAP_FREEWAY, 8051,1608.8000488,19.7000008,40.0000000,0.0000000,90.0000000,21.9965820); //object(vegassedge13) (4)
	AddMapObject(MAP_FREEWAY, 8051,1600.0999756,9.1000004,53.5000000,0.0000000,90.0000000,103.9965820); //object(vegassedge13) (5)
	AddMapObject(MAP_FREEWAY, 8051,1589.8000488,86.8000031,52.2999992,0.0000000,90.0000000,9.9946289); //object(vegassedge13) (6)
	AddMapObject(MAP_FREEWAY, 8051,1595.5000000,112.9000015,48.2999992,0.0000000,90.0000000,347.9920654); //object(vegassedge13) (8)
	AddMapObject(MAP_FREEWAY, 8051,1613.8000488,185.8999939,50.2999992,0.0000000,90.0000000,343.9919434); //object(vegassedge13) (9)
	AddMapObject(MAP_FREEWAY, 8051,1718.9000244,4.9000001,41.2000008,0.0000000,90.0000000,99.9993896); //object(vegassedge13) (10)
	AddMapObject(MAP_FREEWAY, 8051,1796.7998047,0.7998047,38.5989990,0.0000000,90.0000000,73.9929199); //object(vegassedge13) (11)
	AddMapObject(MAP_FREEWAY, 16114,1771.5999756,2.5000000,21.6000004,0.0000000,0.0000000,105.9960938); //object(des_rockgp2_) (1)
	AddMapObject(MAP_FREEWAY, 8051,1872.6999512,-21.2000008,38.5999985,0.0000000,90.0000000,73.9929199); //object(vegassedge13) (12)
	AddMapObject(MAP_FREEWAY, 16120,1835.5996094,-17.0000000,19.5000000,0.0000000,0.0000000,41.9952393); //object(des_rockgp2_07) (1)
	AddMapObject(MAP_FREEWAY, 8051,1872.9000244,-21.2000008,74.3000031,0.0000000,90.0000000,73.9929199); //object(vegassedge13) (13)
	AddMapObject(MAP_FREEWAY, 8051,1797.3000488,0.3000000,74.1999969,0.0000000,90.0000000,73.9929199); //object(vegassedge13) (14)
	AddMapObject(MAP_FREEWAY, 8051,1719.5000000,4.1999998,75.6999969,0.0000000,90.0000000,99.9975586); //object(vegassedge13) (15)
	AddMapObject(MAP_FREEWAY, 8051,1673.6992188,1.1992188,75.6999969,0.0000000,90.0000000,69.9938965); //object(vegassedge13) (16)
	AddMapObject(MAP_FREEWAY, 8051,1608.3000488,21.7999992,79.0000000,0.0000000,90.0000000,21.9946289); //object(vegassedge13) (17)
	AddMapObject(MAP_FREEWAY, 8051,1899.5999756,-9.3999996,50.5999985,0.0000000,90.0000000,163.9879150); //object(vegassedge13) (18)
	AddMapObject(MAP_FREEWAY, 8051,1951.3000488,30.7999992,50.5000000,0.0000000,90.0000000,91.9830322); //object(vegassedge13) (19)
	AddMapObject(MAP_FREEWAY, 8051,2030.0000000,33.5999985,44.9000015,0.0000000,90.0000000,91.9720459); //object(vegassedge13) (20)
	AddMapObject(MAP_FREEWAY, 8051,2079.1000977,73.0000000,44.7999992,0.0000000,90.0000000,165.9809570); //object(vegassedge13) (21)
	AddMapObject(MAP_FREEWAY, 8051,2096.3000488,148.8000031,37.0000000,0.0000000,90.0000000,167.9809570); //object(vegassedge13) (22)
	AddMapObject(MAP_FREEWAY, 8051,2103.6999512,183.3000031,14.6999998,0.0000000,90.0000000,167.9809570); //object(vegassedge13) (23)
	AddMapObject(MAP_FREEWAY, 8051,2112.3000488,223.3999939,35.2999992,0.0000000,90.0000000,167.9809570); //object(vegassedge13) (24)
	AddMapObject(MAP_FREEWAY, 8051,2066.6000977,310.7000122,43.0000000,0.0000000,90.0000000,187.9809570); //object(vegassedge13) (25)
	AddMapObject(MAP_FREEWAY, 8051,2112.0000000,263.2999878,35.4000015,0.0000000,90.0000000,259.9809570); //object(vegassedge13) (26)
	AddMapObject(MAP_FREEWAY, 8051,2112.6999512,263.1000061,68.0000000,0.0000000,90.0000000,259.9804688); //object(vegassedge13) (27)
	AddMapObject(MAP_FREEWAY, 8051,2066.5996094,310.5996094,81.0999985,0.0000000,90.0000000,187.9705811); //object(vegassedge13) (28)
	AddMapObject(MAP_FREEWAY, 8051,2022.5999756,355.2000122,45.2999992,0.0000000,90.0000000,261.9760742); //object(vegassedge13) (29)
	AddMapObject(MAP_FREEWAY, 8051,1944.9000244,366.1000061,38.0000000,0.0000000,90.0000000,261.9744873); //object(vegassedge13) (30)
	AddMapObject(MAP_FREEWAY, 8051,1867.3000488,377.1000061,38.2999992,0.0000000,90.0000000,261.9744873); //object(vegassedge13) (31)
	AddMapObject(MAP_FREEWAY, 8051,1788.5000000,389.7000122,38.0999985,0.0000000,90.0000000,259.9744873); //object(vegassedge13) (32)
	AddMapObject(MAP_FREEWAY, 8051,1710.6999512,403.5000000,38.0000000,0.0000000,90.0000000,259.9694824); //object(vegassedge13) (33)
	AddMapObject(MAP_FREEWAY, 8051,1674.6999512,393.5000000,38.2999992,0.0000000,90.0000000,345.9694824); //object(vegassedge13) (35)
	AddMapObject(MAP_FREEWAY, 8051,1641.6999512,387.6000061,38.5000000,0.0000000,90.0000000,213.9649658); //object(vegassedge13) (37)
	AddMapObject(MAP_FREEWAY, 8051,1613.9000244,384.8999939,38.2999992,0.0000000,90.0000000,255.9642334); //object(vegassedge13) (38)
	AddMapObject(MAP_FREEWAY, 8051,1590.9000244,368.7000122,38.4000015,0.0000000,90.0000000,299.9594727); //object(vegassedge13) (39)
	AddMapObject(MAP_FREEWAY, 8051,1578.4000244,338.3999939,37.2999992,0.0000000,90.0000000,331.9542236); //object(vegassedge13) (40)
	AddMapObject(MAP_FREEWAY, 8051,1551.6999512,268.2000122,34.5999985,0.0000000,90.0000000,345.9484863); //object(vegassedge13) (41)
	AddMapObject(MAP_FREEWAY, 8051,1558.5000000,236.1000061,43.0000000,0.0000000,90.0000000,25.9484863); //object(vegassedge13) (42)
	AddMapObject(MAP_FREEWAY, 8051,1572.4000244,222.3000031,39.7999992,0.0000000,90.0000000,67.9394531); //object(vegassedge13) (43)
	AddMapObject(MAP_FREEWAY, 8051,1586.5000000,209.6999969,46.2999992,0.0000000,90.0000000,111.9394531); //object(vegassedge13) (44)
	AddMapObject(MAP_FREEWAY, 8051,1600.5000000,7.3000002,86.4000015,0.0000000,90.0000000,103.9965820); //object(vegassedge13) (45)
	AddMapObject(MAP_FREEWAY, 8051,1900.9000244,-9.6999998,89.3000031,0.0000000,90.0000000,161.9879150); //object(vegassedge13) (49)
	AddMapObject(MAP_FREEWAY, 8051,1953.4000244,30.5000000,88.5000000,0.0000000,90.0000000,91.9830322); //object(vegassedge13) (50)
	AddMapObject(MAP_FREEWAY, 8051,2031.5000000,33.5000000,81.5999985,0.0000000,90.0000000,91.9830322); //object(vegassedge13) (51)
	AddMapObject(MAP_FREEWAY, 8051,2079.6000977,71.1999969,82.8000031,0.0000000,90.0000000,167.9809570); //object(vegassedge13) (52)
	AddMapObject(MAP_FREEWAY, 8051,2096.6999512,147.6000061,76.0000000,0.0000000,90.0000000,167.9809570); //object(vegassedge13) (53)
	AddMapObject(MAP_FREEWAY, 8051,2112.8000488,222.1000061,72.4000015,0.0000000,90.0000000,167.9809570); //object(vegassedge13) (54)
	AddMapObject(MAP_FREEWAY, 8051,1671.3000488,1.5000000,41.0000000,0.0000000,90.0000000,69.9938965); //object(vegassedge13) (16)
	AddMapObject(MAP_FREEWAY, 9246,1812.8000488,-2.7000000,22.6450005,0.0000000,0.0000000,0.0000000); //object(cock_sfn09) (1)

	LoadMapData(MAP_ALL_DATA, mapid = MAX_MAPS);
	
	//new Query[256];
	//for(new maxmap = 0; maxmap < ; maxmap++)
	//{
	//    format(Query, sizeof(Query), "");
	//	mysql_tquery(mysqlConnHandle, Query, "", "");
	//}

	#if ENABLE_NPC == (true)
	ConnectNPC("[BOT]Calypso", "npcidle");
	#endif
	
	#if defined RNPC_INCLUDED
	ConnectRNPCS();
	#endif
	
	new v = 1, p = 0, ms = 0, go = 0, objectid = 0;
	do
	{
		Vehicle_Missile_CurrentslotID[v] = 0;
		Vehicle_Using_Environmental[v] = 0;
		Vehicle_Machine_Gun_CurrentID[v] = 0;
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
			Vehicle_Missile_Final_Angle[v][ms] = 0.0;
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
		pMissileID[p] = 0;
		pFiring_Missile[p] = 0;
		Mine_Timer[p] = -1;
		Nitro_Bike_Object[p] = INVALID_OBJECT_ID;
		for(new ro = 0; ro < MAX_PRELOADED_OBJECTS; ro++)
		{
			Preloading_Objects[p][ro] = INVALID_OBJECT_ID;
		}
		Objects_Preloaded[p] = 0;
		pFirstTimeViewingMap[p] = 1;
		playerData[p][pMissile_Charged] = INVALID_MISSILE_ID;
		playerData[p][gTeam] = INVALID_GAME_TEAM;
		playerData[p][gRival_Team] = INVALID_GAME_TEAM;
		EditPlayerSlot(p, _, PLAYER_MISSILE_SLOT_CLEAR);
		++p;
	}
	while (p < MAX_PLAYERS);

	for(new g = 0; g < MAX_GAME_LOBBIES; g++) {
		for(new pickupID = 0; pickupID < MAX_MAP_PICKUPS; pickupID++) {
			m_Pickup_Data[g][pickupID][Pickupid] = -1;
		}
	}

	new tutobject;
	tutobject = CreateObject(19478, 2694.757568, -2264.6299, 40.479072, 0.0, 0.0, 0.0, 300.0);
	SetObjectMaterialText(tutobject, ""#cBlue"Twisted Metal: "#cWhite"SA-MP", 0, OBJECT_MATERIAL_SIZE_64x32,
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
		++x;
	}
	iSpawn_Text = TextDrawCreate(320.0, 380.0, "Continue & Begin Vehicle Tutorial"); // Text is txdfile:texture
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

	new Float:fLobbyDiff = 40.0, map_id = INVALID_MAP_ID;
	for(new gameid = 0; gameid < (MAX_GAME_LOBBIES + MAX_FREEROAM_GAMES); gameid++)
	{
		switch(gameid)
		{
			case FREEROAM_GAME: gGameData[gameid][g_Gamemode] = GM_FREEROAM;
			default: gGameData[gameid][g_Gamemode] = random(MAX_GAMEMODES);
		}
		gGameData[gameid][g_Map_id] = INVALID_MAP_ID;
		
		gGameData[gameid][g_Gamemode_Time_Text] = TextDrawCreate(607.0, 123.0, "00:00");
		TextDrawAlignment(gGameData[gameid][g_Gamemode_Time_Text], 3);
		TextDrawFont(gGameData[gameid][g_Gamemode_Time_Text], 2);
		TextDrawLetterSize(gGameData[gameid][g_Gamemode_Time_Text], 0.459999, 1.899999);
		TextDrawSetOutline(gGameData[gameid][g_Gamemode_Time_Text], 1);

		gGameData[gameid][g_Lobby_Box_Outline] = TextDrawCreate(165.000000, 210.000000 + (fLobbyDiff * gameid), "_");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Box_Outline], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Box_Outline], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Box_Outline], 0.000000, 2.199999);
		TextDrawColor(gGameData[gameid][g_Lobby_Box_Outline], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Box_Outline], 0);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Box_Outline], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Box_Outline], 1);
		TextDrawUseBox(gGameData[gameid][g_Lobby_Box_Outline], 1);
		TextDrawBoxColor(gGameData[gameid][g_Lobby_Box_Outline], 255);
		TextDrawTextSize(gGameData[gameid][g_Lobby_Box_Outline], 564.000000, 0.000000);
		TextDrawSetSelectable(gGameData[gameid][g_Lobby_Box_Outline], 0);

		gGameData[gameid][g_Lobby_Box] = TextDrawCreate(166.000000, 212.0 + (fLobbyDiff * gameid), "_");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Box], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Box], 0.000000, 1.80);
		TextDrawColor(gGameData[gameid][g_Lobby_Box], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Box], 0);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawUseBox(gGameData[gameid][g_Lobby_Box], 1);
		TextDrawBoxColor(gGameData[gameid][g_Lobby_Box], -741092353);
		TextDrawTextSize(gGameData[gameid][g_Lobby_Box], 563.000000, 22.000000);
		TextDrawSetSelectable(gGameData[gameid][g_Lobby_Box], 1);
		
		gGameData[gameid][g_Lobby_Name] = TextDrawCreate(166.000, 210.0 + (fLobbyDiff * gameid), "Calypso's Terror"); // Calypso's Terror
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
			case 3: format(gGameData[gameid][g_Lobby_gName], 32, "Freeroam");
		}
		UpdateLobbyTD(gGameData[gameid][g_Lobby_Name], gGameData[gameid][g_Lobby_gName]);

		gGameData[gameid][g_Lobby_Type] = TextDrawCreate(261.000000, 210.0 + (fLobbyDiff * gameid), "Deathmatch"); // Last Man~n~Standing
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Type], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Type], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Type], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Type], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Type], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Type], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Type], 1);

		gGameData[gameid][g_Lobby_Map] = TextDrawCreate(338.000000, 210.0 + (fLobbyDiff * gameid), "Downtown"); // Suburbs
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Map], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Map], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Map], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Map], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Map], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Map], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Map], 1);

		gGameData[gameid][g_Lobby_gState] = TextDrawCreate(416.000000, 210.0 + (fLobbyDiff * gameid), "IN GAME"); //IN GAME 423
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_gState], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_gState], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_gState], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_gState], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_gState], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_gState], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_gState], 1);

		gGameData[gameid][g_Lobby_Players] = TextDrawCreate(492.000000, 210.0 + (fLobbyDiff * gameid), "0/32");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Players], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Players], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Players], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Players], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Players], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Players], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Players], 1);

		gGameData[gameid][g_Lobby_Time] = TextDrawCreate(535.000000, 210.0 + (fLobbyDiff * gameid), "10:00");
		TextDrawBackgroundColor(gGameData[gameid][g_Lobby_Time], 255);
		TextDrawFont(gGameData[gameid][g_Lobby_Time], 1);
		TextDrawLetterSize(gGameData[gameid][g_Lobby_Time], 0.280000, 1.000000);
		TextDrawColor(gGameData[gameid][g_Lobby_Time], -1);
		TextDrawSetOutline(gGameData[gameid][g_Lobby_Time], 1);
		TextDrawSetProportional(gGameData[gameid][g_Lobby_Time], 1);
		TextDrawSetShadow(gGameData[gameid][g_Lobby_Time], 1);
		if(gameid < MAX_GAME_LOBBIES)
		{
			for(new o = 0; o < sizeof(Map_Objects[]); ++o)
			{
				Map_Objects[gameid][o] = INVALID_OBJECT_ID;
			}
			for(new t = 0; t < MAX_TEAMS; ++t)
			{
				gTeam_Lives[gameid][t] = 6;
				gHunted_Player[gameid][t] = INVALID_PLAYER_ID;
			}
			for(new r = 0; r < 3; r++)
			{
				Game_Top3_Positions[gameid][r] = INVALID_PLAYER_ID;
			}
			switch(gGameData[gameid][g_Gamemode])
			{
				case GM_RACE: map_id = Iter_Random(Race_Maps);
				default: map_id = Iter_Random(Maps);
			}
			if(gameid > 0)
			{
				for(new ex = 0; ex < gameid; ex++)
				{
					if(gGameData[ex][g_Gamemode] == GM_RACE) continue;
					if(gGameData[ex][g_Map_id] == map_id) map_id = Iter_Random(Maps);
				}
			}
			OnMapBegin(gameid, gGameData[gameid][g_Gamemode], map_id);
		}
		else if(gameid == FREEROAM_GAME)
		{
			UpdateLobbyTD(gGameData[gameid][g_Lobby_Map], "Freeroam");
			TextDrawSetString(gGameData[gameid][g_Lobby_Time], "N/A");
		}
	}
	
	gGarage_Go_Back = TextDrawCreate(100.0, 407.0, "Click here to return~n~to the main menu");
	TextDrawAlignment(gGarage_Go_Back, 2);
	TextDrawBackgroundColor(gGarage_Go_Back, 255);
	TextDrawFont(gGarage_Go_Back, 1);
	TextDrawLetterSize(gGarage_Go_Back, 0.480, 2.20);
	TextDrawColor(gGarage_Go_Back, -1);
	TextDrawSetOutline(gGarage_Go_Back, 0);
	TextDrawSetProportional(gGarage_Go_Back, 1);
	TextDrawSetShadow(gGarage_Go_Back, 2);
	TextDrawUseBox(gGarage_Go_Back, 0);
	TextDrawBoxColor(gGarage_Go_Back, 572661504);
	TextDrawTextSize(gGarage_Go_Back, 60.0, 160.0);
	TextDrawSetSelectable(gGarage_Go_Back, 1);

	Navigation_S[0] = TextDrawCreate(34.000000, 203.000000, "Multi-Player");
	TextDrawBackgroundColor(Navigation_S[0], 255);
	TextDrawFont(Navigation_S[0], 2);
	TextDrawLetterSize(Navigation_S[0], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[0], -1);
	TextDrawSetOutline(Navigation_S[0], 1);
	TextDrawSetProportional(Navigation_S[0], 1);
	TextDrawUseBox(Navigation_S[0], 1);
	TextDrawBoxColor(Navigation_S[0], 0);
	TextDrawTextSize(Navigation_S[0], 205.0, 15.0);
	TextDrawSetSelectable(Navigation_S[0], 1);

	Navigation_S[1] = TextDrawCreate(34.000000, 230.000000, "Garage");
	TextDrawBackgroundColor(Navigation_S[1], 255);
	TextDrawFont(Navigation_S[1], 2);
	TextDrawLetterSize(Navigation_S[1], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[1], -1);
	TextDrawSetOutline(Navigation_S[1], 1);
	TextDrawSetProportional(Navigation_S[1], 1);
	TextDrawUseBox(Navigation_S[1], 1);
	TextDrawBoxColor(Navigation_S[1], 0);
	TextDrawTextSize(Navigation_S[1], 132.0, 15.0);
	TextDrawSetSelectable(Navigation_S[1], 1);

	Navigation_S[2] = TextDrawCreate(34.000000, 257.000000, "Options");
	TextDrawBackgroundColor(Navigation_S[2], 255);
	TextDrawFont(Navigation_S[2], 2);
	TextDrawLetterSize(Navigation_S[2], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[2], -1);
	TextDrawSetOutline(Navigation_S[2], 1);
	TextDrawSetProportional(Navigation_S[2], 1);
	TextDrawUseBox(Navigation_S[2], 1);
	TextDrawBoxColor(Navigation_S[2], 0);
	TextDrawTextSize(Navigation_S[2], 140.0, 15.0);
	TextDrawSetSelectable(Navigation_S[2], 1);

	Navigation_S[3] = TextDrawCreate(34.0, 284.0, "Help");
	TextDrawBackgroundColor(Navigation_S[3], 255);
	TextDrawFont(Navigation_S[3], 2);
	TextDrawLetterSize(Navigation_S[3], 0.600000, 2.200001);
	TextDrawColor(Navigation_S[3], -1);
	TextDrawSetOutline(Navigation_S[3], 1);
	TextDrawSetProportional(Navigation_S[3], 1);
	TextDrawSetShadow(Navigation_S[3], 1);
	TextDrawUseBox(Navigation_S[3], 1);
	TextDrawBoxColor(Navigation_S[3], 0);
	TextDrawTextSize(Navigation_S[3], 120.0, 15.0);
	TextDrawSetSelectable(Navigation_S[3], 1);

	txdTMLogo[0] = TextDrawCreate(25.000000, 122.000000, "T");
	TextDrawBackgroundColor(txdTMLogo[0], 255);
	TextDrawFont(txdTMLogo[0], 2);
	TextDrawLetterSize(txdTMLogo[0], 1.000000, 4.099997);
	TextDrawColor(txdTMLogo[0], -1);
	TextDrawSetOutline(txdTMLogo[0], 1);
	TextDrawSetProportional(txdTMLogo[0], 1);
	TextDrawSetSelectable(txdTMLogo[0], 0);

	txdTMLogo[1] = TextDrawCreate(80.000000, 122.000000, "T");
	TextDrawBackgroundColor(txdTMLogo[1], 255);
	TextDrawFont(txdTMLogo[1], 2);
	TextDrawLetterSize(txdTMLogo[1], 1.000000, 4.099997);
	TextDrawColor(txdTMLogo[1], -1);
	TextDrawSetOutline(txdTMLogo[1], 1);
	TextDrawSetProportional(txdTMLogo[1], 1);
	TextDrawSetSelectable(txdTMLogo[1], 0);

	txdTMLogo[2] = TextDrawCreate(45.000000, 132.000000, "wis");
	TextDrawBackgroundColor(txdTMLogo[2], 255);
	TextDrawFont(txdTMLogo[2], 2);
	TextDrawLetterSize(txdTMLogo[2], 0.580000, 2.700000);
	TextDrawColor(txdTMLogo[2], -1);
	TextDrawSetOutline(txdTMLogo[2], 1);
	TextDrawSetProportional(txdTMLogo[2], 1);
	TextDrawSetSelectable(txdTMLogo[2], 0);

	txdTMLogo[3] = TextDrawCreate(100.000000, 132.000000, "ed");
	TextDrawBackgroundColor(txdTMLogo[3], 255);
	TextDrawFont(txdTMLogo[3], 2);
	TextDrawLetterSize(txdTMLogo[3], 0.580000, 2.700000);
	TextDrawColor(txdTMLogo[3], -1);
	TextDrawSetOutline(txdTMLogo[3], 1);
	TextDrawSetProportional(txdTMLogo[3], 1);
	TextDrawSetSelectable(txdTMLogo[3], 0);

	txdTMLogo[4] = TextDrawCreate(33.000000, 145.000000, "M");
	TextDrawBackgroundColor(txdTMLogo[4], 255);
	TextDrawFont(txdTMLogo[4], 2);
	TextDrawLetterSize(txdTMLogo[4], 1.000000, 4.099997);
	TextDrawColor(txdTMLogo[4], -1);
	TextDrawSetOutline(txdTMLogo[4], 1);
	TextDrawSetProportional(txdTMLogo[4], 1);
	TextDrawSetSelectable(txdTMLogo[4], 0);

	txdTMLogo[5] = TextDrawCreate(65.000000, 155.000000, "E");
	TextDrawBackgroundColor(txdTMLogo[5], 255);
	TextDrawFont(txdTMLogo[5], 2);
	TextDrawLetterSize(txdTMLogo[5], 0.580000, 2.700000);
	TextDrawColor(txdTMLogo[5], -1);
	TextDrawSetOutline(txdTMLogo[5], 1);
	TextDrawSetProportional(txdTMLogo[5], 1);
	TextDrawSetSelectable(txdTMLogo[5], 0);

	txdTMLogo[6] = TextDrawCreate(73.000000, 145.000000, "T");
	TextDrawBackgroundColor(txdTMLogo[6], 255);
	TextDrawFont(txdTMLogo[6], 2);
	TextDrawLetterSize(txdTMLogo[6], 1.000000, 4.099997);
	TextDrawColor(txdTMLogo[6], -1);
	TextDrawSetOutline(txdTMLogo[6], 1);
	TextDrawSetProportional(txdTMLogo[6], 1);
	TextDrawSetSelectable(txdTMLogo[6], 0);

	txdTMLogo[7] = TextDrawCreate(91.000000, 156.000000, "al");
	TextDrawBackgroundColor(txdTMLogo[7], 255);
	TextDrawFont(txdTMLogo[7], 2);
	TextDrawLetterSize(txdTMLogo[7], 0.580000, 2.700000);
	TextDrawColor(txdTMLogo[7], -1);
	TextDrawSetOutline(txdTMLogo[7], 1);
	TextDrawSetProportional(txdTMLogo[7], 1);
	TextDrawSetSelectable(txdTMLogo[7], 0);

	txdTMLogo[8] = TextDrawCreate(29.000000, 116.000000, "-");
	TextDrawBackgroundColor(txdTMLogo[8], 255);
	TextDrawFont(txdTMLogo[8], 2);
	TextDrawLetterSize(txdTMLogo[8], 9.370003, 3.700000);
	TextDrawColor(txdTMLogo[8], -1);
	TextDrawSetOutline(txdTMLogo[8], 1);
	TextDrawSetProportional(txdTMLogo[8], 1);
	TextDrawSetSelectable(txdTMLogo[8], 0);

	txdTMLogo[9] = TextDrawCreate(89.000000, 122.000000, "-");
	TextDrawBackgroundColor(txdTMLogo[9], 255);
	TextDrawFont(txdTMLogo[9], 2);
	TextDrawLetterSize(txdTMLogo[9], 0.600000, 2.900000);
	TextDrawColor(txdTMLogo[9], -1);
	TextDrawSetOutline(txdTMLogo[9], 0);
	TextDrawSetProportional(txdTMLogo[9], 1);
	TextDrawSetShadow(txdTMLogo[9], 0);
	TextDrawSetSelectable(txdTMLogo[9], 0);

	txdTMLogo[10] = TextDrawCreate(31.500000, 127.500000, "-");
	TextDrawBackgroundColor(txdTMLogo[10], -1);
	TextDrawFont(txdTMLogo[10], 2);
	TextDrawLetterSize(txdTMLogo[10], 2.070000, 1.400000);
	TextDrawColor(txdTMLogo[10], -1);
	TextDrawSetOutline(txdTMLogo[10], 1);
	TextDrawSetProportional(txdTMLogo[10], 1);
	TextDrawSetSelectable(txdTMLogo[10], 0);

	/*
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
	TextDrawBackgroundColor(Navigation_S[7], 255);
	TextDrawFont(Navigation_S[7], 1);
	TextDrawLetterSize(Navigation_S[7], 1.000000, 2.999999);
	TextDrawColor(Navigation_S[7], -1);
	TextDrawSetOutline(Navigation_S[7], 1);
	TextDrawSetProportional(Navigation_S[7], 1);

	Navigation_S[8] = TextDrawCreate(52.000000, 149.000000, "MeTal");
	TextDrawBackgroundColor(Navigation_S[8], 255);
	TextDrawFont(Navigation_S[8], 1);
	TextDrawLetterSize(Navigation_S[8], 1.000000, 2.999999);
	TextDrawColor(Navigation_S[8], -1);
	TextDrawSetOutline(Navigation_S[8], 1);
	TextDrawSetProportional(Navigation_S[8], 1);
	*/
	Navigation_Game_S[0] = TextDrawCreate(34.000000, 203.000000, "LOBBIES");
	TextDrawBackgroundColor(Navigation_Game_S[0], 255);
	TextDrawFont(Navigation_Game_S[0], 2);
	TextDrawLetterSize(Navigation_Game_S[0], 0.600000, 2.200001);
	TextDrawColor(Navigation_Game_S[0], -1);
	TextDrawSetOutline(Navigation_Game_S[0], 1);
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
	TextDrawSetOutline(Navigation_Game_S[2], 1);
	TextDrawSetProportional(Navigation_Game_S[2], 1);
	TextDrawSetShadow(Navigation_Game_S[2], 1);

	Navigation_Game_S[3] = TextDrawCreate(262.000000, 197.000000, "TYPE");
	TextDrawBackgroundColor(Navigation_Game_S[3], 255);
	TextDrawFont(Navigation_Game_S[3], 1);
	TextDrawLetterSize(Navigation_Game_S[3], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[3], -1);
	TextDrawSetOutline(Navigation_Game_S[3], 1);
	TextDrawSetProportional(Navigation_Game_S[3], 1);
	TextDrawSetShadow(Navigation_Game_S[3], 1);

	Navigation_Game_S[4] = TextDrawCreate(337.000000, 197.000000, "MAP");
	TextDrawBackgroundColor(Navigation_Game_S[4], 255);
	TextDrawFont(Navigation_Game_S[4], 1);
	TextDrawLetterSize(Navigation_Game_S[4], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[4], -1);
	TextDrawSetOutline(Navigation_Game_S[4], 1);
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
	TextDrawSetOutline(Navigation_Game_S[6], 1);
	TextDrawSetProportional(Navigation_Game_S[6], 1);
	TextDrawSetShadow(Navigation_Game_S[6], 1);

	Navigation_Game_S[7] = TextDrawCreate(539.000000, 197.000000, "TIME");
	TextDrawBackgroundColor(Navigation_Game_S[7], 255);
	TextDrawFont(Navigation_Game_S[7], 1);
	TextDrawLetterSize(Navigation_Game_S[7], 0.280000, 1.000000);
	TextDrawColor(Navigation_Game_S[7], -1);
	TextDrawSetOutline(Navigation_Game_S[7], 1);
	TextDrawSetProportional(Navigation_Game_S[7], 1);
	TextDrawSetShadow(Navigation_Game_S[7], 1);

	Navigation_Game_S[NAVIGATION_INDEX_MAIN_MENU] = TextDrawCreate(34.000000, 230.000000, "Main Menu");
	TextDrawBackgroundColor(Navigation_Game_S[8], 255);
	TextDrawFont(Navigation_Game_S[8], 2);
	TextDrawLetterSize(Navigation_Game_S[8], 0.6, 2.2);
	TextDrawColor(Navigation_Game_S[8], -1);
	TextDrawSetOutline(Navigation_Game_S[8], 1);
	TextDrawSetProportional(Navigation_Game_S[8], 1);
	TextDrawSetShadow(Navigation_Game_S[8], 1);
	TextDrawUseBox(Navigation_Game_S[8], 1);
	TextDrawBoxColor(Navigation_Game_S[8], 0);
	TextDrawTextSize(Navigation_Game_S[8], 150.000000, 30.000000);
	TextDrawSetSelectable(Navigation_Game_S[8], 1);

	gClass_Spawn = TextDrawCreate(300.000000, 410.000000, "hud:skipicon");
	TextDrawBackgroundColor(gClass_Spawn, 0);
	TextDrawFont(gClass_Spawn, 4);
	TextDrawLetterSize(gClass_Spawn, 0.500000, 1.000000);
	TextDrawColor(gClass_Spawn, -16711681);
	TextDrawSetOutline(gClass_Spawn, 0);
	TextDrawSetProportional(gClass_Spawn, 1);
	TextDrawSetShadow(gClass_Spawn, 1);
	TextDrawUseBox(gClass_Spawn, 1);
	TextDrawBoxColor(gClass_Spawn, 255);
	TextDrawTextSize(gClass_Spawn, 40.000000, 40.000000);
	TextDrawSetSelectable(gClass_Spawn, 1);
	
	gClass_Box = TextDrawCreate(413.000000, 271.000000, "ld_otb2:butna");
	TextDrawBackgroundColor(gClass_Box, 0);
	TextDrawFont(gClass_Box, 4);
	TextDrawLetterSize(gClass_Box, 0.000000, 0.000000);
	TextDrawColor(gClass_Box, -1040187222);
	TextDrawSetOutline(gClass_Box, 0);
	TextDrawSetProportional(gClass_Box, 1);
	TextDrawSetShadow(gClass_Box, 1);
	TextDrawUseBox(gClass_Box, 1);
	TextDrawBoxColor(gClass_Box, -1040187137);
	TextDrawTextSize(gClass_Box, 215.000000, 35.000000);
	TextDrawSetSelectable(gClass_Box, 0);

	gClass_Info_Model = TextDrawCreate(515.000000, 415.000000, "infomodel");
	TextDrawBackgroundColor(gClass_Info_Model, -256);
	TextDrawFont(gClass_Info_Model, 5);
	TextDrawLetterSize(gClass_Info_Model, 0.509998, 2.099997);
	TextDrawColor(gClass_Info_Model, 16711935);
	TextDrawSetOutline(gClass_Info_Model, 0);
	TextDrawSetProportional(gClass_Info_Model, 1);
	TextDrawSetShadow(gClass_Info_Model, 1);
	TextDrawUseBox(gClass_Info_Model, 1);
	TextDrawBoxColor(gClass_Info_Model, -256);
	TextDrawTextSize(gClass_Info_Model, 30.000000, 30.000000);
	TextDrawSetPreviewModel(gClass_Info_Model, 1239);
	TextDrawSetPreviewRot(gClass_Info_Model, 0.000000, 0.000000, 0.000000, 0.800000);
	TextDrawSetSelectable(gClass_Info_Model, 1);

	gClass_Left_Arrow = TextDrawCreate(417.000000, 275.000000, "ld_beat:left");
	TextDrawBackgroundColor(gClass_Left_Arrow, 0);
	TextDrawFont(gClass_Left_Arrow, 4);
	TextDrawLetterSize(gClass_Left_Arrow, 0.000000, 0.000000);
	TextDrawColor(gClass_Left_Arrow, -1);
	TextDrawSetOutline(gClass_Left_Arrow, 0);
	TextDrawSetProportional(gClass_Left_Arrow, 1);
	TextDrawSetShadow(gClass_Left_Arrow, 1);
	TextDrawUseBox(gClass_Left_Arrow, 1);
	TextDrawBoxColor(gClass_Left_Arrow, 255);
	TextDrawTextSize(gClass_Left_Arrow, 20.000000, 20.000000);
	TextDrawSetSelectable(gClass_Left_Arrow, 1);

	gClass_Right_Arrow = TextDrawCreate(605.000000, 275.000000, "ld_beat:right");
	TextDrawBackgroundColor(gClass_Right_Arrow, 0);
	TextDrawFont(gClass_Right_Arrow, 4);
	TextDrawLetterSize(gClass_Right_Arrow, 0.000000, 0.000000);
	TextDrawColor(gClass_Right_Arrow, -1);
	TextDrawSetOutline(gClass_Right_Arrow, 0);
	TextDrawSetProportional(gClass_Right_Arrow, 1);
	TextDrawSetShadow(gClass_Right_Arrow, 1);
	TextDrawUseBox(gClass_Right_Arrow, 1);
	TextDrawBoxColor(gClass_Right_Arrow, 255);
	TextDrawTextSize(gClass_Right_Arrow, 20.000000, 20.000000);
	TextDrawSetSelectable(gClass_Right_Arrow, 1);
	
	gClass_T_Box = TextDrawCreate(434.000000, 299.000000, "ld_otb2:butna");
	TextDrawBackgroundColor(gClass_T_Box, 0);
	TextDrawFont(gClass_T_Box, 4);
	TextDrawLetterSize(gClass_T_Box, 0.000000, 0.000000);
	TextDrawColor(gClass_T_Box, -1040187222);
	TextDrawSetOutline(gClass_T_Box, 0);
	TextDrawSetProportional(gClass_T_Box, 1);
	TextDrawSetShadow(gClass_T_Box, 1);
	TextDrawUseBox(gClass_T_Box, 1);
	TextDrawBoxColor(gClass_T_Box, -1040187137);
	TextDrawTextSize(gClass_T_Box, 193.000000, 30.000000);
	TextDrawSetSelectable(gClass_T_Box, 0);

	gClass_T_Left = TextDrawCreate(437.000000, 302.000000, "ld_beat:left");
	TextDrawBackgroundColor(gClass_T_Left, 0);
	TextDrawFont(gClass_T_Left, 4);
	TextDrawLetterSize(gClass_T_Left, 0.000000, 0.000000);
	TextDrawColor(gClass_T_Left, -1);
	TextDrawSetOutline(gClass_T_Left, 0);
	TextDrawSetProportional(gClass_T_Left, 1);
	TextDrawSetShadow(gClass_T_Left, 1);
	TextDrawUseBox(gClass_T_Left, 1);
	TextDrawBoxColor(gClass_T_Left, 255);
	TextDrawTextSize(gClass_T_Left, 17.000000, 17.000000);
	TextDrawSetSelectable(gClass_T_Left, 1);

	gClass_T_Right = TextDrawCreate(606.000000, 302.000000, "ld_beat:right");
	TextDrawBackgroundColor(gClass_T_Right, 0);
	TextDrawFont(gClass_T_Right, 4);
	TextDrawLetterSize(gClass_T_Right, 0.000000, 0.000000);
	TextDrawColor(gClass_T_Right, -1);
	TextDrawSetOutline(gClass_T_Right, 0);
	TextDrawSetProportional(gClass_T_Right, 1);
	TextDrawSetShadow(gClass_T_Right, 1);
	TextDrawUseBox(gClass_T_Right, 1);
	TextDrawBoxColor(gClass_T_Right, 255);
	TextDrawTextSize(gClass_T_Right, 17.000000, 17.000000);
	TextDrawSetSelectable(gClass_T_Right, 1);
	
	Players_Online_Textdraw = TextDrawCreate(41.000000, 316.000000, "01");
	TextDrawBackgroundColor(Players_Online_Textdraw, 0); // 225
	TextDrawFont(Players_Online_Textdraw, 1);
	TextDrawLetterSize(Players_Online_Textdraw, 0.330000, 1.500000);
	TextDrawColor(Players_Online_Textdraw, -1);
	TextDrawSetOutline(Players_Online_Textdraw, 1);
	TextDrawSetProportional(Players_Online_Textdraw, 1);
	TextDrawSetShadow(Players_Online_Textdraw, 0);
	TextDrawUseBox(Players_Online_Textdraw, 1);
	TextDrawBoxColor(Players_Online_Textdraw, 150);
	TextDrawTextSize(Players_Online_Textdraw, 56.000000, 0.0);

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

	pHud_TurboSign = TextDrawCreate(515.000000, 427.000000, "T");
	TextDrawBackgroundColor(pHud_TurboSign, 255);
	TextDrawFont(pHud_TurboSign, 1);
	TextDrawLetterSize(pHud_TurboSign, 0.500000, 1.0);
	TextDrawColor(pHud_TurboSign, -1);
	TextDrawSetOutline(pHud_TurboSign, 0);
	TextDrawSetProportional(pHud_TurboSign, 1);
	TextDrawSetShadow(pHud_TurboSign, 1);
	
	pC_Box_Outline = TextDrawCreate(630.000000, 340.000000, "_");
	TextDrawLetterSize(pC_Box_Outline, 0.500000, 6.999998);
	TextDrawUseBox(pC_Box_Outline, 1);
	TextDrawBoxColor(pC_Box_Outline, 65535);
	TextDrawTextSize(pC_Box_Outline, 454.000000, 0.000000);

	pC_Box = TextDrawCreate(629.000000, 341.000000, "_");
	TextDrawLetterSize(pC_Box, 0.500000, 6.799997);
	TextDrawUseBox(pC_Box, 1);
	TextDrawBoxColor(pC_Box, 255);
	TextDrawTextSize(pC_Box, 455.000000, 0.000000);

	for(new i = 0; i < sizeof(c_ColorIndex[]); ++i)
	{
		pC_ColorLeftArrow[i] = TextDrawCreate(515.500, (340.000 + (i * 16.0)), "LD_BEAT:left");
		TextDrawFont(pC_ColorLeftArrow[i], 4);
		TextDrawTextSize(pC_ColorLeftArrow[i], 17.500, 14.500);
		TextDrawColor(pC_ColorLeftArrow[i], -1);
		TextDrawSetSelectable(pC_ColorLeftArrow[i], 1);

		pC_ColorRightArrow[i] = TextDrawCreate(605.500, (340.000 + (i * 16.0)), "LD_BEAT:right");
		TextDrawFont(pC_ColorRightArrow[i], 4);
		TextDrawTextSize(pC_ColorRightArrow[i], 17.500, 14.500);
		TextDrawColor(pC_ColorRightArrow[i], -1);
		TextDrawSetSelectable(pC_ColorRightArrow[i], 1);
	}
	pC_WheelLeftArrow = TextDrawCreate(515.500, (340.000  + 31.0), "LD_BEAT:left");
	TextDrawFont(pC_WheelLeftArrow, 4);
	TextDrawTextSize(pC_WheelLeftArrow, 17.500, 14.500);
	TextDrawColor(pC_WheelLeftArrow, -1);
	TextDrawSetSelectable(pC_WheelLeftArrow, 1);

	pC_WheelRightArrow = TextDrawCreate(605.500, (340.000 + 31.0), "LD_BEAT:right");
	TextDrawFont(pC_WheelRightArrow, 4);
	TextDrawTextSize(pC_WheelRightArrow, 17.500, 14.500);
	TextDrawColor(pC_WheelRightArrow, -1);
	TextDrawSetSelectable(pC_WheelRightArrow, 1);

	pC_cColor1 = TextDrawCreate(465.000000, 341.000000, "CAR COLOR 1");
	TextDrawFont(pC_cColor1, 2);
	TextDrawLetterSize(pC_cColor1, 0.194998, 1.100000);
	TextDrawColor(pC_cColor1, -1);

	pC_cColor2 = TextDrawCreate(465.000000, 357.000000, "CAR COLOR 2");
	TextDrawFont(pC_cColor2, 2);
	TextDrawLetterSize(pC_cColor2, 0.189998, 1.100000);
	TextDrawColor(pC_cColor2, -1);

	pC_Wheel_Type = TextDrawCreate(465.000000, 372.000000, "WHEEL TYPE");
	TextDrawFont(pC_Wheel_Type, 2);
	TextDrawLetterSize(pC_Wheel_Type, 0.189998, 1.100000);
	TextDrawColor(pC_Wheel_Type, -1);
	TextDrawSetSelectable(pC_Wheel_Type, 0);
	
	pC_fLine = TextDrawCreate(628.000000, 357.000000, "_");
	TextDrawFont(pC_fLine, 3);
	TextDrawLetterSize(pC_fLine, 0.0, -0.56);
	TextDrawUseBox(pC_fLine, 1);
	TextDrawBoxColor(pC_fLine, -144);
	TextDrawTextSize(pC_fLine, 456.0, 0.0);

	pC_lLine = TextDrawCreate(628.000000, 373.000000, "_");
	TextDrawFont(pC_lLine, 3);
	TextDrawLetterSize(pC_lLine, 0.0, -0.56);
	TextDrawUseBox(pC_lLine, 1);
	TextDrawBoxColor(pC_lLine, -144);
	TextDrawTextSize(pC_lLine, 456.0, 0.0);
	
	pC_Save = TextDrawCreate(543.000000, 391.000000, "SAVE");
	TextDrawAlignment(pC_Save, 2);
	TextDrawFont(pC_Save, 2);
	TextDrawLetterSize(pC_Save, 0.189998, 1.100000);
	TextDrawColor(pC_Save, -1);
	TextDrawTextSize(pC_Save, 15.0, 30.0); // inverted due to Alignment
	TextDrawSetSelectable(pC_Save, 1);
	
	pC_Default = TextDrawCreate(500.000000, 391.000000, "DEFAULT");
	TextDrawAlignment(pC_Default, 2);
	TextDrawFont(pC_Default, 2);
	TextDrawLetterSize(pC_Default, 0.189998, 1.100000);
	TextDrawColor(pC_Default, -1);
	TextDrawTextSize(pC_Default, 15.0, 30.0); // inverted due to Alignment
	TextDrawSetSelectable(pC_Default, 1);
	
	pC_Back = TextDrawCreate(586.000000, 391.000000, "BACK");
	TextDrawAlignment(pC_Back, 2);
	TextDrawFont(pC_Back, 2);
	TextDrawLetterSize(pC_Back, 0.189998, 1.100000);
	TextDrawColor(pC_Back, -1);
	TextDrawTextSize(pC_Back, 15.0, 30.0); // inverted due to Alignment
	TextDrawSetSelectable(pC_Back, 1);
	
	pC_Models_Up_Arrow = TextDrawCreate(607.000, 217.000, "LD_BEAT:up");
	TextDrawFont(pC_Models_Up_Arrow, 4);
	TextDrawTextSize(pC_Models_Up_Arrow, 17.500, 14.500);
	TextDrawColor(pC_Models_Up_Arrow, 340197350);
	TextDrawSetSelectable(pC_Models_Up_Arrow, 1);
	
	pC_Models_Down_Arrow = TextDrawCreate(607.000, 319.000, "LD_BEAT:down");
	TextDrawFont(pC_Models_Down_Arrow, 4);
	TextDrawTextSize(pC_Models_Down_Arrow, 17.500, 14.500);
	TextDrawColor(pC_Models_Down_Arrow, 340197350);
	TextDrawSetSelectable(pC_Models_Down_Arrow, 1);

	pC_Select_Box = TextDrawCreate(630.000000, 188.000000, "_");
	TextDrawBackgroundColor(pC_Select_Box, 255);
	TextDrawFont(pC_Select_Box, 1);
	TextDrawLetterSize(pC_Select_Box, 0.000000, 16.200000);
	TextDrawColor(pC_Select_Box, -1);
	TextDrawUseBox(pC_Select_Box, 1);
	TextDrawBoxColor(pC_Select_Box, 55);
	TextDrawTextSize(pC_Select_Box, 454.0, 0.0);
	TextDrawSetSelectable(pC_Select_Box, 0);

	pC_Select_Line = TextDrawCreate(630.000000, 216.000000, "_");
	TextDrawBackgroundColor(pC_Select_Line, 255);
	TextDrawFont(pC_Select_Line, 3);
	TextDrawLetterSize(pC_Select_Line, 0.000000, -0.600000);
	TextDrawColor(pC_Select_Line, -1);
	TextDrawUseBox(pC_Select_Line, 1);
	TextDrawBoxColor(pC_Select_Line, 65535);
	TextDrawTextSize(pC_Select_Line, 454.000000, 0.000000);
	TextDrawSetSelectable(pC_Select_Line, 0);

	/*Tutorial_Arrows[0] = TextDrawCreate(73.000, 287.000, "LD_BEAT:down");
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
	TextDrawSetShadow(Tutorial_Numbers[9], 1);*/
	
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
	printf("[Heapspace - OnGameModeExit] - heapspace(): %i - Heapspace: %i kilobytes", heapspace(), heapspace() / 1024);
	Iter_Clear(Vehicles);
	/*for(new ta = 0, tas = sizeof(Tutorial_Arrows); ta < tas; ta++)
	{
		TextDrawHideForAll(Tutorial_Arrows[ta]);
		TextDrawDestroy(Tutorial_Arrows[ta]);
		TextDrawHideForAll(Tutorial_Numbers[ta]);
		TextDrawDestroy(Tutorial_Numbers[ta]);
	}*/
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
	//for(new p = 0, sp = sizeof(m_Pickup_Data); p < sp; p++)
	//{
	//	if(m_Pickup_Data[p][Pickupid] == -1) continue;
	//	DestroyPickupEx(p);
	//}
	DestroyObject(gFerrisWheel);
	DestroyObject(gFerrisBase);
	new x = 0;
	while(x != NUM_FERRIS_CAGES) {
		DestroyObject(gFerrisCages[x]);
		++x;
	}
	new o = 0, extra;
	do
	{
		extra = o;
		if(IsValidObject(extra)) {
			DestroyObject(extra);
		}
		++o;
	}
	while (o < MAX_OBJECTS);
	new t = 0;
	do
	{
		extra = t;
		KillTimer(extra);
		++t;
	}
	while (t != 1000);
	foreach(Player, i)
	{
		if(i >= MAX_PLAYERS) break;
		for(new st = 0; st < sizeof(StatusTextPositions); st++)
		{
			KillTimer(pStatusInfo[i][StatusTextTimer][st]);
			pStatusInfo[i][StatusTextTimer][st] = -1;
		}
		DestroyHUD(i);
		//for(new t = 0; t != 15; t++)
		//{
		//	TextDrawDestroy(pTextInfo[i][TDSpeedClock][t]);
		//}
		++i;
	}
	quitIRCBots(true);
	MapAndreas_Unload();
	if(mysqlConnHandle > 0) {
		mysql_close(mysqlConnHandle);
	}
	//SendRconCommand("unloadfs Twisted_Pic");
	printf("[System] - "#SERVER_NAME" Exited Succesfully");
	return 1;
}

initializeMySQL()
{
	GetConsoleVarAsString("bind", server_ip_addr, sizeof(server_ip_addr));

	if(isnull(server_ip_addr)) {
		server_ip_addr = "127.0.0.1";
	}

	server_port = GetConsoleVarAsInt("port");
	printf("IP: "#SERVER_IP_ADDRESS". Bind IP: %s:%d.", server_ip_addr, server_port);

	if(strcmp(""#SERVER_IP_ADDRESS"", server_ip_addr, true) != 0 || isnull(server_ip_addr)
		|| (strcmp(""#SERVER_IP_ADDRESS"", server_ip_addr, true) == 0 && server_port != 8000)) {
		printf("[SYSTEM WARNING]: TESTING MODE ACTIVATED.");
	}
	mysql_log(LOG_ERROR | LOG_WARNING); // | LOG_DEBUG
	new startTick = GetTickCount();
	mysqlConnHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS, .pool_size = 0);
	if(mysql_errno() != 0) {
		printf("[MySQL Connection:: tick: %d (%s)]: FAILED: Please check the mysql_connect or the database! mysqlConnHandle: %d.", (GetTickCount() - startTick), MYSQL_HOST, mysqlConnHandle);
		mysqlConnHandle = 0;
	} else {
		printf("[MySQL Connection:: tick: %d (%s)]: PASSED: mysqlConnHandle: %d.", (GetTickCount() - startTick), MYSQL_HOST, mysqlConnHandle);
	}
	if(mysqlConnHandle > 0) {
		mysql_option(DUPLICATE_CONNECTIONS, false);
		mysql_option(LOG_TRUNCATE_DATA, false);
		//playerChangePasswordFromUser("Lorenc", "lorenc");
	}
}

TemporaryRaceQuitList(playerid = INVALID_PLAYER_ID, action = 0)
{ // INSERT INTO "#mySQL_Race_Quit_List_Table" (`Username`, `checkpointIndex`) VALUES ('Kar', 2)
	switch(action)
	{
		case 0: // TRQL_ACTION_INSERT
		{
			format(gQuery, sizeof(gQuery), "INSERT INTO "#mySQL_Race_Quit_List_Table" (`Username`, `checkpointIndex`) VALUES ('%s', %d)", playerName(playerid), CP_Progress[playerid] - 1);
			mysql_tquery(mysqlConnHandle, gQuery);
		}
		case 1: // TRQL_ACTION_SELECT_AND_DELETE
		{
			format(gQuery, sizeof(gQuery), "SELECT `checkpointIndex` FROM "#mySQL_Race_Quit_List_Table" WHERE `Username` = '%s' LIMIT 0,1", playerName(playerid));
			mysql_tquery(mysqlConnHandle, gQuery, "Thread_LoadTempRaceQuitList", "i", playerid);
		}
		case 2: // TRQL_ACTION_CLEAR
		{
			mysql_tquery(mysqlConnHandle, "DELETE FROM "#mySQL_Race_Quit_List_Table"");
		}
	}
	return 1;
}
THREAD:LoadTempRaceQuitList(playerid)
{
	new rows = cache_get_row_count(mysqlConnHandle);
	if(rows > 0)
	{
		CP_Progress[playerid] = cache_get_field_content_int(0, "checkpointIndex", mysqlConnHandle);
		format(gQuery, sizeof(gQuery), "DELETE FROM "#mySQL_Race_Quit_List_Table" WHERE `Username` = '%s' LIMIT 1", playerName(playerid));
		mysql_tquery(mysqlConnHandle, gQuery);
	}
	return 1;
}

quitIRCBots(bool:gamemodeExiting = false)
{
	if(gamemodeExiting) {
		for(new i = 0; i < MAX_IRC_BOTS; ++i)
			IRC_Quit(gBotID[i], IRC_BOT_GAME_QUIT_REASON);

		IRC_DestroyGroup(gIRCGroupChatID);
	}
	else {
		for(new i = 0; i < MAX_IRC_BOTS; ++i)
			IRC_Quit(gBotID[i], IRC_BOT_QUIT_REASON);
	}
}

connectIRCBots(serverStart = 0)
{
	if(!serverStart)
		quitIRCBots();
	else
		gIRCGroupChatID = IRC_CreateGroup();

	for(new i = 0; i < MAX_IRC_BOTS; ++i) {
		gBotID[i] = IRC_Connect(IRC_SERVER, IRC_PORT, gBotNames[i], gBotNames[i], gBotNames[i]);
		IRC_SetIntData(gBotID[i], E_IRC_CONNECT_DELAY, i + 1);
	}
}


public OnPlayerDisconnect(playerid, reason)
{
	if(playerid >= MAX_PLAYERS) return 0;
	#if defined RNPC_INCLUDED
	if(IsRNPC[playerid] != -1)
	{
		new npcid = IsRNPC[playerid];
		Twisted_NPCS[npcid][t_NPCID] = INVALID_PLAYER_ID;
		if(IsValidVehicle(Twisted_NPCS[npcid][t_NPCVehicle])) {
			DestroyVehicle(Twisted_NPCS[npcid][t_NPCVehicle]);
		}
		Twisted_NPCS[npcid][t_NPCVehicle] = 0;
		KillTimer(Twisted_NPCS[npcid][t_NPCTimer]);
		Twisted_NPC_Names_Used[npcid] = 0;
		IsRNPC[playerid] = -1;
	}
	#endif
	savePlayerAccount(playerid, .disconnecting = 1);
	if(playerData[playerid][gGameID] != INVALID_GAME_ID) {
		OnGameLeave(playerData[playerid][gGameID], playerid);
	}
	//ModelPlayerDisconnect(playerid);
	destroyAllTwistedMetalData(playerid);
	new string[90];
	switch(reason)
	{
		case 0: format(string, sizeof(string), "%s(%d) Has Left The Server - (Timeout / Crash)", playerName(playerid), playerid);
		case 1: format(string, sizeof(string), "%s(%d) Has Left The Server - (Leaving / Quit)", playerName(playerid), playerid);
		case 2: format(string, sizeof(string), "%s(%d) Has Left The Server - (Kicked / Banned)", playerName(playerid), playerid);
	}
	if(!IsPlayerNPC(playerid))
	{
		SendClientMessageToAll(system, string);
	}
	strins(string, "04", 0, sizeof(string));
	IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, string);
	IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, string);
	pName[playerid] = " - ";
	resetPlayerConnectionVariables(playerid);
	return 1;
}

removeDowntownBuildings(playerid)
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
	//hanger 18
	RemoveBuildingForPlayer(playerid, 1278, -1596.7891, -589.3281, 25.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -1525.3906, -619.7656, 25.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -1246.6953, -289.4609, 25.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 1278, -1405.3125, -132.1250, 25.3359, 0.25);
	RemoveBuildingForPlayer(playerid, 3881, -1229.3281, 53.3281, 14.9844, 0.25);
	RemoveBuildingForPlayer(playerid, 3881, -1542.4609, -443.3984, 6.8516, 0.25); // boot at entrance
	RemoveBuildingForPlayer(playerid, 3852, -1686.8828, -163.1484, 14.5078, 0.25); // drive over thing
	RemoveBuildingForPlayer(playerid, 10813, -1687.4141, -623.0234, 18.1484, 0.25); // lod
	RemoveBuildingForPlayer(playerid, 10810, -1687.4141, -623.0234, 18.1484, 0.25); //
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


public OnPlayerFloodControl(playerid, iCount, iTimeSpan) {
	if(iCount > 2 && iTimeSpan < 10000)
	{
		messageAdmins(COLOR_ADMIN, "[Flood Control] %s(%d) Banned - Count: %d - Time: %d", playerName(playerid), playerid, iCount, iTimeSpan);
		printf("[Flood Control] %s(%d) Banned - Count: %d - Time: %d", playerName(playerid), playerid, iCount, iTimeSpan);
		Ban(playerid);
	}
	return 1;
}

Flood_Control(playerid)
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
	SetPlayerColor(playerid, 0xFFFFFFFF);
	GetPlayerName(playerid, pName[playerid], MAX_PLAYER_NAME);
	GetPlayerIp(playerid, playerData[playerid][pIPv4], MAX_PLAYER_IP);
	if(IsPlayerNPC(playerid))
	{
		resetPlayerConnectionVariables(playerid);
		if(strcmp(playerData[playerid][pIPv4], "127.0.0.1", true) != 0 && strcmp(playerData[playerid][pIPv4], server_ip_addr, true) != 0) {
			printf("[SYSTEM: NPC]: Got a remote NPC connecting from %s and I'm kicking it.", playerData[playerid][pIPv4]);
			BanEx(playerid, "Remote NPC");
			return 0;
		}
		printf("[SYSTEM: OnPlayerConnect]: NPC Connection [%s] - %s(%d).", playerData[playerid][pIPv4], pName[playerid], playerid);
		SendClientMessageFormatted(MAX_PLAYERS, 0xD3D3D3FF, "[NPC]: %s(%d) has joined "#SERVER_NAME_SHORT".", playerName(playerid), playerid);
		#if defined RNPC_INCLUDED
		for(new i = 0; i < sizeof(Twisted_NPCS); ++i)
		{
			if(strcmp(pName[playerid], Twisted_NPC_Names[i], false) == 0)
			{
				Twisted_NPCS[i][t_NPCID] = playerid;
				IsRNPC[Twisted_NPCS[i][t_NPCID]] = i;
				strmid(Twisted_NPCS[i][t_Name], pName[playerid], false, strlen(pName[playerid]), MAX_PLAYER_NAME);
				if(Twisted_NPCS[i][t_NPCVehicle] == 0)
				{
					Twisted_NPCS[i][t_NPCVehicle] = CreateVehicle(TMC_ROADKILL, 0.0, 0.0, 3.0, 0.0, -1, -1, 0);
				}
				printf("[RNPC: OnPlayerConnect] - %s(%d)", playerName(playerid), playerid);
				break;
			}
		}
		#endif
		return 1;
	}
	Flood_Control(playerid);
	SendClientMessage(playerid, COLOR_RED, "WARNING: "#cSAMP"The concept in this server and GTA in general may be considered Explicit Material.");
	SendClientMessage(playerid, COLOR_RED, "CONCEPT: "#cSAMP""#SERVER_NAME" is a demolition derby that permits the usage of ballistic projectiles.");
	SendClientMessage(playerid, COLOR_RED, "WEBSITE: "#cSAMP""#SERVER_WEBSITE".");
	
	new str[96];
	format(str, sizeof(str), "%s(%d) has joined "#SERVER_NAME".", playerName(playerid), playerid);
	SendClientMessageToAll(LIGHTGREY, str);
	format(str, sizeof(str), "14%s(%d) has joined "#SERVER_NAME" Version: v%s.", playerName(playerid), playerid, SERVER_VERSION);
	IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, str);
	format(str, sizeof(str), "14%s(%d) has joined "#SERVER_NAME" Version: v%s (IP: %s).", playerName(playerid), playerid, SERVER_VERSION, playerData[playerid][pIPv4]);
	IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, str);
	format(str, sizeof(str), "%02d", Iter_Count(Player));
	TextDrawSetString(Players_Online_Textdraw, str);

	resetPlayerConnectionVariables(playerid);
	
	createPlayerTextdraws(playerid);
	
	removeDowntownBuildings(playerid);
	StopAudioStreamForPlayer(playerid);
	HidePlayerDialog(playerid);
	/*switch(random(2))
	{
		case 0: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/tm2-menu-screen.mp3");
		case 1: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal - Main Theme Song.mp3");
	}*/
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	//tm_SelectTextdraw(playerid, 0xFFFFFFAA);
	if(mysqlConnHandle == 0 && server_mode == SERVER_MODE_TESTING) {
		pLogged_Status[playerid] = 1;
		processPlayerGameplay(playerid);
	}
	if(pLogged_Status[playerid] == 0) {
		format(gQuery, sizeof(gQuery), "SELECT `Username` FROM "#mySQL_Accounts_Table" WHERE `Username` = '%s' LIMIT 0,1", playerName(playerid));
		mysql_tquery(mysqlConnHandle, gQuery, "Thread_DoesAccountExists", "i", playerid);
	}
	return 1;
}

THREAD:DoesAccountExists(playerid)
{
	//printf("[Thread: DoesAccountExists] - %s(%d)", playerName(playerid), playerid);
	new rows = cache_get_row_count(mysqlConnHandle);
	if(rows > 0)
	{
		format(gQuery, sizeof(gQuery), ""#cWhite"Welcome To "#cBlue""#SERVER_NAME"\n\n{FAF87F}Account: "#cWhite"%s\n\nPlease Enter Your Password Below:", playerName(playerid));
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""#cSAMPRed""#SERVER_NAME"", gQuery, "Login", "Cancel"); // Authentication - too long
		pSpawn_Request[playerid] = SPAWN_REQUEST_Authentication;
	} else {
		format(gQuery, sizeof(gQuery), ""#cWhite"Welcome To "#cBlue""#SERVER_NAME": "#cWhite"%s\n\nPlease Enter A Password Below To Register:", playerName(playerid));
		ShowPlayerDialog(playerid, DIALOG_REGISTRATION, DIALOG_STYLE_INPUT, ""#cSAMPRed""#SERVER_NAME" Registration", gQuery, "Register", "");
		pSpawn_Request[playerid] = SPAWN_REQUEST_REGISTRATION;
	}
	return 1;
}

public OnPlayerRequestClassEx(playerid, classid)
{
	if(classid <= 0 || classid > MAX_TWISTED_VEHICLES)
		pTwistedIndex[playerid] = 1;
	else
		pTwistedIndex[playerid] = classid;
	
	pVehicleID[playerid] = CreateVehicle(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE, C_S_IDS[pTwistedIndex[playerid]][CS_Colour1], C_S_IDS[pTwistedIndex[playerid]][CS_Colour2], 0);
	
	SetVehicleVirtualWorld(pVehicleID[playerid], playerid + 1);
	setupTwistedVehicle(playerid, pVehicleID[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]);
	
	PlayerTextDrawSetString(playerid, gClass_Name[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_TwistedName]);
	PlayerTextDrawShow(playerid, gClass_Name[playerid]);
	
	//InterpolateCameraPos(playerid, -2407.893066, -590.872802, 134.399978, TM_SELECTION_CAMERA_X, TM_SELECTION_CAMERA_Y, TM_SELECTION_CAMERA_Z, 3000, CAMERA_MOVE);
	//InterpolateCameraLookAt(playerid, -2405.759521, -595.313354, 133.546020, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z, 4000, CAMERA_MOVE);
	//InterpolateCameraPos(playerid, -2414.954345, -613.888793, 137.119247, -2414.954345, -613.888793, 137.119247, 1000, CAMERA_MOVE);
	//InterpolateCameraLookAt(playerid, -2411.009521, -610.853576, 136.644607, -2411.009521, -610.853576, 136.644607, 1000, CAMERA_MOVE);
	if(GetPVarInt(playerid, "pClassSelection"))
	{
		if(Objects_Preloaded[playerid] == 0) {
			beginPlayerPreloading(playerid);
		}
		if(!CanPlayerUseTwistedMetalVehicle(playerid, C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]))
		{
			ChangeVehicleColor(pVehicleID[playerid], 0, 0);
			for(new sp = 0; sp < MAX_SPECIAL_OBJECTS; sp++)
			{
				if(IsValidObject(playerData[playerid][pSpecialObjects][sp]))
				{
					SetObjectMaterial(playerData[playerid][pSpecialObjects][sp], 0, 18837, "mickytextures", "ws_gayflag1", 0x000000FF);
				}// SetObjectMaterial(Snowtest, 0, 3942, "bistro", "mp_snow", 0);
				if(sp < 2)
				{
					if(IsValidObject(Vehicle_Machine_Gun_Object[pVehicleID[playerid]][sp]))
					{// muzzle_texture4 minigun_2 minigunicon bulletbelt
						SetObjectMaterial(Vehicle_Machine_Gun_Object[pVehicleID[playerid]][sp], 2, 0, "none", "none", 0x000000FF);
						SetObjectMaterial(Vehicle_Machine_Gun_Object[pVehicleID[playerid]][sp], 1, 0, "none", "none", 0x000000FF);
					}
				}
			}
			ShowSubtitle(playerid, "Locked", 15000, 1);
		} else {
			HideSubtitle(playerid);
		}
		if(playerData[playerid][gGameID] != INVALID_GAME_ID)
		{
			if(gGameData[playerData[playerid][gGameID]][g_Voting_Time] == 0)
			{
				switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
				{
					case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
					{
						playerData[playerid][pSkin] = Team_Info[playerData[playerid][gTeam]][TI_Skin_ID];
					}
					default:
					{
						SetPlayerColor(playerid, GetTwistedMetalColour(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], .shift = 0));
						playerData[playerid][pSkin] = C_S_IDS[pTwistedIndex[playerid]][CS_SkinID];
					}
				}
				//SetPlayerSkin(playerid, playerData[playerid][pSkin]);
			}
		}
	} else {
		playerData[playerid][pSkin] = C_S_IDS[pTwistedIndex[playerid]][CS_SkinID];
		//SetPlayerSkin(playerid, playerData[playerid][pSkin]);
	}
	PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);

	SetPlayerCameraPos(playerid, -2414.954345, -613.888793, 137.119247);
	SetPlayerCameraLookAt(playerid, -2411.009521, -610.853576, 136.644607, CAMERA_CUT);
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid))
	{
		SpawnPlayer(playerid);
		#if defined RNPC_INCLUDED
		if(IsRNPC[playerid] != -1)
			printf("[RNPC: OnPlayerRequestClass] - %s(%d)", playerName(playerid), playerid);
		#endif
		return 1;
	}
	if(pSpawn_Request[playerid] != SPAWN_REQUEST_NONE)
	{
		SpawnPlayer(playerid);
		return 1;
	}
	if(pLogged_Status[playerid] == 0) return 1;
	if(pSpectate_Random_Teammate[playerid] == 1)
	{
		SpawnPlayer(playerid);
		return 1;
	}
	return 1;
}
#define GARAGE_POSITIONS 2481.926269, -1670.402465, 15.355634
#define GARAGE_V_POSITIONS 2492.3181, -1668.0062, 13.9273
#define GARAGE_LOOKAT_POSITIONS 2486.694091, -1668.989501, 14.834477

public OnPlayerRequestSpawn(playerid)
{
	if(pLogged_Status[playerid] == 0) return 0;
	if(pSpawn_Request[playerid] != SPAWN_REQUEST_NONE)
	{
		SpawnPlayer(playerid);
		return 0;
	}
	if(pTwistedIndex[playerid] == 0)
	{
		GameTextForPlayer(playerid, "~r~Please Select A Vehicle!", 3000, 3);
		setupClassSelectionForPlayer(playerid, pTwistedIndex[playerid]);
		return 0;
	}
	if(GetPVarInt(playerid, "Requesting_Spawn") == 1)
	{
		if(GetPVarInt(playerid, "Requesting_Spawn_Time") >= gettime()) return 0;
	}
	SetPVarInt(playerid, "Requesting_Spawn", 1);
	SetPVarInt(playerid, "Requesting_Spawn_Time", gettime() + 3);
	return 1;
}

UpdatePlayerLMSTeamInfo(playerid)
{
	if(playerData[playerid][gTeam] != INVALID_GAME_TEAM &&
		playerData[playerid][gRival_Team] != INVALID_GAME_TEAM)
	{
		new team_text[32], rival_text[32];
		format(team_text, sizeof(team_text), "Teammates: %d~n~Team Lives: %d", gTeam_Player_Count[playerData[playerid][gGameID]][playerData[playerid][gTeam]], gTeam_Lives[playerData[playerid][gGameID]][playerData[playerid][gTeam]]);
		format(rival_text, sizeof(rival_text), "Enemies: %d~n~Enemy Lives: %d", gTeam_Player_Count[playerData[playerid][gGameID]][playerData[playerid][gRival_Team]], gTeam_Lives[playerData[playerid][gGameID]][playerData[playerid][gRival_Team]]);
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pTeam_Score], team_text);
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pRival_Team_Score], rival_text);
	}
	return 1;
}

CreateTeamsTextdraws(playerid)
{
	new team_text[32], rival_text[32];
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_TEAM_LAST_MAN_STANDING:
		{
			format(team_text, sizeof(team_text), "Teammates: %d~n~Team Lives: %d", gTeam_Player_Count[playerData[playerid][gGameID]][playerData[playerid][gTeam]], gTeam_Lives[playerData[playerid][gGameID]][playerData[playerid][gTeam]]);
			format(rival_text, sizeof(rival_text), "Enemies: %d~n~Enemy Lives: %d", gTeam_Player_Count[playerData[playerid][gGameID]][playerData[playerid][gRival_Team]], gTeam_Lives[playerData[playerid][gGameID]][playerData[playerid][gRival_Team]]);
			pTextInfo[playerid][pTeam_Score] = CreatePlayerTextDraw(playerid, 83.000, (151.000 - 5.0), team_text);
			pTextInfo[playerid][pRival_Team_Score] = CreatePlayerTextDraw(playerid, 83.000, (205.000 - 5.0), rival_text);
		}
		default:
		{
			pTextInfo[playerid][pTeam_Score] = CreatePlayerTextDraw(playerid, 83.000, 151.000, "0");
			pTextInfo[playerid][pRival_Team_Score] = CreatePlayerTextDraw(playerid, 83.000, 205.000, "0");
		}
	}
	switch(playerData[playerid][gTeam])
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

AddPlayerToGameTeam(playerid)
{
	if(playerData[playerid][gGameID] == INVALID_GAME_TEAM) return 0;
	++gTeam_Player_Count[playerData[playerid][gGameID]][playerData[playerid][gTeam]];
	SendClientMessageFormatted(playerid, -1, "Your team is now "#cLime"%s"#cWhite".", Team_Info[playerData[playerid][gTeam]][TI_Team_Name]);
	CreateTeamsTextdraws(playerid);
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_TEAM_LAST_MAN_STANDING:
		{
			foreach(Player, i)
			{
				if(i == playerid || playerData[i][gGameID] != playerData[playerid][gGameID]) continue;
				UpdatePlayerLMSTeamInfo(i);
			}
		}
	}
	AdjustTeamColoursForPlayer(playerid);
	return 1;
}

#define MAX_CUSTOM_OBJECTS 19
enum e_C_Models
{
	c_Model,
	c_Name[20],
};
new cModels[MAX_CUSTOM_OBJECTS][e_C_Models] =
{
	{19308,	"taxi01"},
	{19309,	"taxi02"},
	{19310,	"taxi03"},
	{19311,	"taxi04"},
	{19314,	"Bull Horns"},
	{1851, "Dice"},
	{2103, "Boom Box 1"},
	{2226, "Boom Box 2"},
	//{1211, "Fire Hydrant"},
	{1000, "Car Spoiler"},
	{1001, "Car Spoiler 2"},
	{1002, "Car Spoiler 3"},
	{1003, "Car Spoiler 4"},
	{1004, "Car Hood Scoop 1"},
	{1005, "Car Hood Scoop 2"},
	{1006, "Car Hood Scoop 3"},
	{1013, "Headlights"},
	{1018, "Exhaust Pipe"},
	{1019, "Exhaust Pipe 2"},
	{1020, "Exhaust Pipe 3"}
};

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	if(playertextid == INVALID_PLAYER_TEXT_DRAW)
	{
		if(Selecting_Textdraw[playerid] != 0) {
			tm_SelectTextdraw(playerid, Selecting_Textdraw[playerid]);
		}
		return 1;
	}
	if(pSpawn_Request[playerid] == SPAWN_REQUEST_GARAGE)
	{
		for(new i = 0; i < MAX_C_OBJECTS_LIST; ++i)
		{
			if(playertextid == pTextInfo[playerid][pC_oNames][i] || playertextid == pTextInfo[playerid][pC_oModels][i])
			{
				new id = 0, cID = -1;
				switch(GetPVarInt(playerid, "pGarageEditingModelMode"))
				{
					case GARAGE_MODEL_EDIT_ATTACH:
					{
						new Float:x, Float:y, Float:z, Float:angle,
							Float:sX, Float:sY, Float:sZ,
							model = pGarageModelIDData[playerid][i]
						;
						for(id = 0; id < MAX_MODELS_PER_VEHICLE; ++id)
						{
							if(p_c_Model[playerid][id] != 0) continue;
							p_c_Model[playerid][id] = model;
							SetPVarInt(playerid, "pGarageEditingModelIndex", id);
							break;
						}
						if(id == MAX_MODELS_PER_VEHICLE) return SendClientMessage(playerid, 0xFFFFFFFF, "You have too many objects placed on this vehicle already!");
						tm_CancelSelectTextdraw(playerid);
						GetVehiclePos(pVehicleID[playerid], x, y, z);
						GetVehicleZAngle(pVehicleID[playerid], angle);
						GetVehicleModelInfo(GetVehicleModel(pVehicleID[playerid]), VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
						x += (sX * 0.5) * floatsin(-angle, degrees);
						y += (sY * 0.25) * floatcos(-angle, degrees);
						z += (sZ * 0.25);
						
						p_c_Model_Edited[playerid][id] = 2;
						p_c_Objects[playerid][id] = CreatePlayerObject(playerid, model, x, y, z, 0.0, 0.0, 0.0, 50.0);

						cID = getCustomizationIDFromModel(p_c_Model[playerid][id]);
						if(cID != -1)
								SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) attached & being edited.", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);

						SendClientMessage(playerid, 0xFFFFFFFF, "Hint: Use "#cYellow"~k~~PED_SPRINT~ "#cWhite"to look around - Press "#cYellow"ESC "#cWhite"to cancel.");
					}
					case GARAGE_MODEL_EDIT_DATA:
					{
						for(id = 0; id < MAX_MODELS_PER_VEHICLE; ++id)
						{
							if(id != pGarageModelIDData[playerid][i]) continue;
							SetPVarInt(playerid, "pGarageEditingModelIndex", id);
							break;
						}
						cID = getCustomizationIDFromModel(p_c_Model[playerid][id]);

						if(IsValidObject(p_c_Objects[playerid][id]))
						{
							SetPVarInt(playerid, "pCancelObjectCancel", 1);
							DestroyObject(p_c_Objects[playerid][id]);
							new Float:x, Float:y, Float:z, Float:rX, Float:rY, Float:rZ;

							x = p_c_Model_Data[playerid][id][0];
							y =	p_c_Model_Data[playerid][id][1];
							z =	p_c_Model_Data[playerid][id][2];
							rX =	p_c_Model_Data[playerid][id][3];
							rY =	p_c_Model_Data[playerid][id][4];
							rZ =	p_c_Model_Data[playerid][id][5];
							p_c_Model_Edited[playerid][id] = 0;
							
							//OffsetFromVehiclePosition(pVehicleID[playerid], x, y, z, rX, rY, rZ);
							//PositionFromVehicleOffset(pVehicleID[playerid], rX, rY, rZ, x, y, z);
							GetVehiclePosEx(pVehicleID[playerid], x, y, z, rX, rY, rZ);

							p_c_Objects[playerid][id] = CreatePlayerObject(playerid, p_c_Model[playerid][id], x, y, z, rX, rY, rZ, 50.0);
							//AttachObjectToVehicle(p_c_Objects[playerid][id], vehicleid, p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5]);
							if(cID != -1)
								SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) being edited.", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);
						}
						else if(cID != -1)
								SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) could not be edited.", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);
					}
					case GARAGE_MODEL_EDIT_DELETE:
					{
						for(id = 0; id < MAX_MODELS_PER_VEHICLE; ++id)
						{
							if(id != pGarageModelIDData[playerid][i]) continue;
							format(gQuery, sizeof gQuery, "DELETE FROM "#mySQL_Customization_Table" WHERE `Username` = '%s' AND `vmodel` = %d AND `ID` = %d AND `objectmodel` = %d LIMIT 1", pName[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], id, p_c_Model[playerid][id]);
							mysql_tquery(mysqlConnHandle, gQuery);
							
							cID = getCustomizationIDFromModel(p_c_Model[playerid][id]);

							if(cID != -1)
								SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) deleted from your Customization List.", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);

							p_c_Model[playerid][id] = 0;
							p_c_Model_Edited[playerid][id] = 0;
							p_c_Model_Data[playerid][id][0] = 0.0;
							p_c_Model_Data[playerid][id][1] = 0.0;
							p_c_Model_Data[playerid][id][2] = 0.0;
							p_c_Model_Data[playerid][id][3] = 0.0;
							p_c_Model_Data[playerid][id][4] = 0.0;
							p_c_Model_Data[playerid][id][5] = 0.0;

							DestroyObject(p_c_Objects[playerid][id]);
							togglePlayerGarageModelSelMode(playerid, .updateOnly = 1);
							return 1;
						}
					}
				}
				//EditObject(playerid, p_c_Objects[playerid][GetPVarInt(playerid, "pGarageEditingModelIndex")]);
				pSpawn_Request[playerid] = SPAWN_REQUEST_GARAGE_EDITING;
				TogglePlayerSpectating(playerid, false);
				return 1;
			}
		}
	}
	return 0;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(clickedid == INVALID_TEXT_DRAW)
	{
		if(Selecting_Textdraw[playerid] != 0) {
			tm_SelectTextdraw(playerid, Selecting_Textdraw[playerid]);
		}
		return 1;
	}
	if(clickedid == gClass_Info_Model) {
		SendClientMessage(playerid, -1, "This feature is not yet complete.");
		return 1;
	}
	if(clickedid == gClass_Spawn)
	{
		if(playerData[playerid][gGameID] == INVALID_GAME_TEAM)
		{
			if(GetPVarInt(playerid, "pGarage") == 1) {
				togglePlayerNavigationTXD(playerid, false);
				playerBeginCustomization(playerid);
				return 1;
			} else {
				SendClientMessage(playerid, -1, "Please Go Back And Select A Game!");
			}
		}
		if(!GetPVarType(playerid, "pRegistration_Tutorial") && playerData[playerid][gGameID] != FREEROAM_GAME)
		{
			if(gGameData[playerData[playerid][gGameID]][g_Map_id] == INVALID_MAP_ID ||
			gGameData[playerData[playerid][gGameID]][g_Voting_Time] >= 1)
			{
				GameTextForPlayer(playerid, "~w~The Map Is Currently Changing!~n~~r~~h~Please Wait!", 3000, 3);
				TextDrawShowForPlayer(playerid, gGameData[playerData[playerid][gGameID]][g_Gamemode_Time_Text]);
				return 0;
			}
		}
		if(!CanPlayerUseTwistedMetalVehicle(playerid, C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])) {
			ShowSubtitle(playerid, "Locked", .time = 15000, .override = 1);
			return 0;
		} else {
			HideSubtitle(playerid);
		}
		TogglePlayerSpectating(playerid, false);
		endPlayerClassSelection(playerid);
		TextDrawHideForPlayer(playerid, gGarage_Go_Back);
		SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
		if(playerData[playerid][gGameID] == FREEROAM_GAME)
			return OnTwistedSpawn(playerid, 3);

		switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
		{
			case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING: {
				AddPlayerToGameTeam(playerid);
			}
		}
		//TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, playerid, "READ /controls!", 3000 );
		
		SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pHealthBar], floatround(GetTwistedMetalMaxHealth(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])));
		SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pTurboBar], floatround(GetTwistedMetalMaxTurbo(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])));
		SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pEnergyBar], floatround(GetTwistedMetalMaxEnergy(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])));

		OnTwistedSpawn(playerid, 1);
		return 1;
	}
	if(clickedid == gClass_Left_Arrow || clickedid == gClass_Right_Arrow)
	{
		if(clickedid == gClass_Left_Arrow)
			--pTwistedIndex[playerid];
		else
			++pTwistedIndex[playerid];
		if(pTwistedIndex[playerid] > MAX_TWISTED_VEHICLES) pTwistedIndex[playerid] = 1;
		if(pTwistedIndex[playerid] < 1) pTwistedIndex[playerid] = MAX_TWISTED_VEHICLES;
		setupClassSelectionForPlayer(playerid, pTwistedIndex[playerid]);
		return 1;
	}
	if(clickedid == gClass_T_Left || clickedid == gClass_T_Right)
	{
		if(clickedid == gClass_T_Left)
			--playerData[playerid][gTeam];
		else
			++playerData[playerid][gTeam];
		if(playerData[playerid][gTeam] >= MAX_TEAMS) playerData[playerid][gTeam] = TEAM_CLOWNS;
		if(playerData[playerid][gTeam] < 0) playerData[playerid][gTeam] = MAX_TEAMS - 1;
		PlayerTextDrawSetString(playerid, gClass_Team_Name[playerid], Team_Info[playerData[playerid][gTeam]][TI_Team_Name]);
		PlayerTextDrawSetPreviewModel(playerid, gClass_Team_Model[playerid], Team_Info[playerData[playerid][gTeam]][TI_Skin_ID]);
		PlayerTextDrawShow(playerid, gClass_Team_Model[playerid]);
		return 1;
	}
	if(clickedid == gGarage_Go_Back || clickedid == Navigation_Game_S[NAVIGATION_INDEX_MAIN_MENU])
	{
		if(playerData[playerid][gGameID] != INVALID_GAME_ID) {
			OnGameLeave(playerData[playerid][gGameID], playerid);
		} else {
			DeletePVar(playerid, "pGarage");
		}
		if(clickedid == gGarage_Go_Back) {
			TextDrawHideForPlayer(playerid, gGarage_Go_Back);
			pSpawn_Request[playerid] = SPAWN_REQUEST_Authentication;
			SpawnPlayer(playerid);
		} else {
			for(new i = 0; i < sizeof(Navigation_Game_S); ++i) {
				TextDrawHideForPlayer(playerid, Navigation_Game_S[i]);
			}
			for(new gameid = 0; gameid < sizeof(gGameData); ++gameid) {
				togglePlayerLobbyGameTXD(playerid, gameid, false);
			}
		}
		pTwistedIndex[playerid] = 0;
		togglePlayerNavigationTXD(playerid, true);
		endPlayerClassSelection(playerid, 0);
		return 1;
	}
	if(clickedid == Navigation_S[NAVIGATION_INDEX_MULTIPLAYER])
	{
		togglePlayerNavigationTXD(playerid, false, false);
		SendClientMessage(playerid, -1, "Please Select A Game Lobby To Join.");
		for(new i = 0; i < sizeof(Navigation_Game_S); ++i) {
			TextDrawShowForPlayer(playerid, Navigation_Game_S[i]);
		}
		for(new gameid = 0; gameid < sizeof(gGameData); gameid++) {
			togglePlayerLobbyGameTXD(playerid, gameid, true);
		}
		tm_SelectTextdraw(playerid, NAVIGATION_COLOUR); // EXPRIENCE_COLOUR
		return 1;
	}
	if(clickedid == Navigation_S[NAVIGATION_INDEX_GARAGE]) // Pick a vehicle to start customizing
	{
		playerData[playerid][gGameID] = INVALID_GAME_ID;
		togglePlayerNavigationTXD(playerid, false);
		setupClassSelectionForPlayer(playerid, 0, .garage = 1, .firstTime = 1);
		return 1;
	}
	if(clickedid == Navigation_S[NAVIGATION_INDEX_OPTIONS])
	{
		if(IsPlayerAdmin(playerid)) {
			togglePlayerNavigationTXD(playerid, false, false);
			pSpawn_Request[playerid] = SPAWN_REQUEST_NONE;
			//SpawnPlayer(playerid);
			TogglePlayerSpectating(playerid, false);
			tm_CancelSelectTextdraw(playerid);
			
			GameTextForPlayer(playerid, "~b~~h~Test Mode", 5000, 3);
		} else {
			GameTextForPlayer(playerid, "~r~~h~Not Finished", 5000, 3);
		}
		return 1;
	}
	if(clickedid == Navigation_S[NAVIGATION_INDEX_HELP])
	{
		cmd_tutorial(playerid, "");
		return 1;
	}
	if(clickedid == iSpawn_Text)
	{
		tm_CancelSelectTextdraw(playerid);
		TextDrawHideForPlayer(playerid, iSpawn_Text);
		pSpawn_Request[playerid] = SPAWN_REQUEST_NONE;
		SetPVarInt(playerid, "pRegistration_Tutorial", 2);
		SetPVarInt(playerid, "pMultiplayer", 1);
		TogglePlayerSpectating(playerid, false);
		playerData[playerid][gGameID] = FREEROAM_GAME;
		return OnTwistedSpawn(playerid, 3);
	}
	if(pSpawn_Request[playerid] == SPAWN_REQUEST_GARAGE)
	{
		if(clickedid == pC_Default)
		{
			setPlayerDefaultCustomization(playerid);
			return 1;
		}
		if(clickedid == pC_Back) return cmd_back(playerid, "");
		if(clickedid == pC_Save)
		{
			new editions = 0;
			for(new i = 0; i < MAX_MODELS_PER_VEHICLE; ++i)
			{
				if(p_c_Model_Edited[playerid][i] == 0) continue;

				format(gQuery, sizeof gQuery, "UPDATE "#mySQL_Customization_Table" SET `offsetx` = %0.2f, `offsety` = %0.2f, `offsetz` = %0.2f, `offsetrx` = %0.2f, `offsetry` = %0.2f, `offsetrz` = %0.2f WHERE `Username` = '%s' AND `vmodel` = %d AND `ID` = %d AND `objectmodel` = %d LIMIT 1",
					p_c_Model_Data[playerid][i][0], p_c_Model_Data[playerid][i][1], p_c_Model_Data[playerid][i][2], p_c_Model_Data[playerid][i][3], p_c_Model_Data[playerid][i][4], p_c_Model_Data[playerid][i][5], pName[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], i, p_c_Model[playerid][i]);

				mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnModelSaveComplete", "ii", playerid, i);
				p_c_Model_Edited[playerid][i] = 0;
				++editions;
			}
			SendClientMessageFormatted(playerid, -1, "%d Editions being saved.", editions);
			return 1;
		}
		if(clickedid == pC_Models_Up_Arrow || clickedid == pC_Models_Down_Arrow)
		{
			if(clickedid == pC_Models_Up_Arrow)
			{
				if(--c_ModelIndex[playerid] < -MAX_C_OBJECTS_LIST)
					c_ModelIndex[playerid] = sizeof(cModels) - 1;
			}
			if(clickedid == pC_Models_Down_Arrow)
			{
				if(++c_ModelIndex[playerid] >= sizeof(cModels))
					 c_ModelIndex[playerid] = 0;
			}
			new model = c_ModelIndex[playerid], modelArrSize = sizeof(cModels);
			for(new i = 0; i < MAX_C_OBJECTS_LIST; ++i)
			{
				model = c_ModelIndex[playerid] + i;
				if(model < 0)
					model += modelArrSize;
				else if(model >= modelArrSize)
					model -= modelArrSize;
					
				PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_oNames][i], cModels[model][c_Name]);
				PlayerTextDrawSetPreviewModel(playerid, pTextInfo[playerid][pC_oModels][i], cModels[model][c_Model]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oNames][i]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oModels][i]);
				pGarageModelIDData[playerid][i] = cModels[model][c_Model];
			}
		}
		if(clickedid == pC_WheelLeftArrow || clickedid == pC_WheelRightArrow)
		{
			switch(GetVehicleModel(pVehicleID[playerid]))
			{
				case TMC_HAMMERHEAD: return PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Wheel_Name], "Incompatible");
			}
			if(clickedid == pC_WheelLeftArrow)
			{
				if(--c_WheelIndex[playerid] < 0)
					c_WheelIndex[playerid] = sizeof(Wheel_Data) - 1;
			}
			if(clickedid == pC_WheelRightArrow)
			{
				if(++c_WheelIndex[playerid] >= sizeof(Wheel_Data))
					 c_WheelIndex[playerid] = 0;
			}
			if(GetVehicleComponentInSlot(pVehicleID[playerid], CARMODTYPE_WHEELS))
				RemoveVehicleComponent(pVehicleID[playerid], GetVehicleComponentInSlot(pVehicleID[playerid], CARMODTYPE_WHEELS));

			if(Wheel_Data[c_WheelIndex[playerid]][w_ID] != 0)
				AddVehicleComponent(pVehicleID[playerid], Wheel_Data[c_WheelIndex[playerid]][w_ID]);
				
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Wheel_Name], Wheel_Data[c_WheelIndex[playerid]][w_Name]);
			return 1;
		}
		for(new i = 0; i < sizeof(c_ColorIndex[]); ++i)
		{
			if(clickedid == pC_ColorLeftArrow[i] || clickedid == pC_ColorRightArrow[i])
			{
				if(clickedid == pC_ColorRightArrow[i])
				{
					if(++c_ColorIndex[playerid][i] >= 256)
						c_ColorIndex[playerid][i] = 0;
				}
				else if(clickedid == pC_ColorLeftArrow[i])
				{
					if(--c_ColorIndex[playerid][i] <= -1)
						c_ColorIndex[playerid][i] = 255;
				}
				new left, right;
				if(c_ColorIndex[playerid][i] == 0)
					left = 255;
				else
					left = c_ColorIndex[playerid][i] - 1;
					
				if(c_ColorIndex[playerid][i] == 255)
					right = 0;
				else
					right = c_ColorIndex[playerid][i] + 1;
					
				PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], VehicleColoursTableRGBA[left]);
				PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxM][i], VehicleColoursTableRGBA[c_ColorIndex[playerid][i]]);
				PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], VehicleColoursTableRGBA[right]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxM][i]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxRight][i]);
				ChangeVehicleColor(pVehicleID[playerid], c_ColorIndex[playerid][0], c_ColorIndex[playerid][1]);
				return 1;
			}
		}
		return 1;
	}
	for(new gameid = 0; gameid < sizeof(gGameData); gameid++)
	{
		if(clickedid == gGameData[gameid][g_Lobby_Box])
		{
			for(new i = 0; i < sizeof(Navigation_Game_S); i++) {
				TextDrawHideForPlayer(playerid, Navigation_Game_S[i]);
			}
			togglePlayerNavigationTXD(playerid, false, true, false);
			for(new gameIDEx = 0; gameIDEx < sizeof(gGameData); gameIDEx++) {
				togglePlayerLobbyGameTXD(playerid, gameIDEx, false);
			}
			SetPVarInt(playerid, "pMultiplayer", 1);
			SendClientMessage(playerid, cNiceBlueEx, "Now joining Multi-Player action.");

			++gGameData[gameid][g_Players];
			format(gString, sizeof(gString), "%d/"#MAX_PLAYERS_PER_LOBBY"", gGameData[gameid][g_Players]);
			TextDrawSetString(gGameData[gameid][g_Lobby_Players], gString);
			playerData[playerid][gGameID] = gameid;
			if(gameid != FREEROAM_GAME) {
				OnGameJoin(gameid, gGameData[gameid][g_Map_id], playerid);
				TemporaryRaceQuitList(playerid, .action = 1);
				if(gGameData[playerData[playerid][gGameID]][g_Voting_Time] == 0) {
					SendClientMessageFormatted(playerid, -1, ""#cGold"[%s]"#cWhite": Mode: "#cGold"%s "#cWhite" Map: "#cGold"%s "#cWhite" Players: "#cGold"%d"#cWhite".", gGameData[playerData[playerid][gGameID]][g_Lobby_gName], s_Gamemodes[gGameData[playerData[playerid][gGameID]][g_Gamemode]][GM_Name], s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Name], gGameData[playerData[playerid][gGameID]][g_Players]);
				} else {
					SendClientMessageFormatted(playerid, -1, ""#cRed"[%s]"#cWhite": A new Gamemode and Map is currently being voted for.", gGameData[playerData[playerid][gGameID]][g_Lobby_gName]);
				}
			} else {
				SendClientMessageFormatted(playerid, -1, ""#cGold"[%s]"#cWhite": Welcome & Enjoy. Do Whatever You Feel Like!", gGameData[playerData[playerid][gGameID]][g_Lobby_gName]);
			}
			// new class selection
			setupClassSelectionForPlayer(playerid, 0, .firstTime = 1);
			break;
		}
	}
	return 0;
}

public OnPlayerEditObject(playerid, playerobject, objectid, response, Float:fX, Float:fY, Float:fZ, Float:fRotX, Float:fRotY, Float:fRotZ)
{
	if(!playerobject)
	{
		if(!IsValidObject(objectid)) return 1;
		MoveObject(objectid, fX, fY, fZ, 10.0, fRotX, fRotY, fRotZ);
	}
	if(playerobject)
	{
		switch(response)
		{
			case EDIT_RESPONSE_FINAL:
			{
				new Float:fPos[3], Float:offsets[3], id = GetPVarInt(playerid, "pGarageEditingModelIndex"),
					Float:sX, Float:sY, Float:sZ, cID = getCustomizationIDFromModel(p_c_Model[playerid][id]);
				GetVehiclePos(pVehicleID[playerid], fPos[0], fPos[1], fPos[2]);
				GetVehicleModelInfo(GetVehicleModel(pVehicleID[playerid]), VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
				
				offsets[0] = fX - fPos[0];
				offsets[1] = fY - fPos[1];
				offsets[2] = fZ - fPos[2] + 1.6;// + (sZ * 0.25);

				p_c_Model_Data[playerid][id][0] = offsets[0];
				p_c_Model_Data[playerid][id][1] = offsets[1];
				p_c_Model_Data[playerid][id][2] = offsets[2];
				p_c_Model_Data[playerid][id][3] = fRotX;
				p_c_Model_Data[playerid][id][4] = fRotY;
				p_c_Model_Data[playerid][id][5] = fRotZ;
				
				DestroyPlayerObject(playerid, objectid);

				p_c_Objects[playerid][id] = CreateObject(p_c_Model[playerid][id], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0);
				AttachObjectToVehicle(p_c_Objects[playerid][id], pVehicleID[playerid], p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5]);

				if(p_c_Model_Edited[playerid][id] == 2) {
					format(gQuery, sizeof gQuery, "INSERT INTO "#mySQL_Customization_Table" (`Account_ID`, `Username`, `vmodel`, `ID`, `objectmodel`, `offsetx`, `offsety`, `offsetz`, `offsetrx`, `offsetry`, `offsetrz`) VALUES (%d, '%s', %d, %d, %d, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f)",
						playerData[playerid][pAccount_ID], pName[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], id, p_c_Model[playerid][id], p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5]);
					mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnModelSaveComplete", "ii", playerid, id);
					p_c_Model_Edited[playerid][id] = 0;
					if(cID != -1) {
						SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) edited and saved.", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);
					}
				} else {
					p_c_Model_Edited[playerid][id] = 1;
					if(cID != -1) {
						SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) edited (Click SAVE to save new positions).", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);
					}
				}
				CancelEdit(playerid);
				tm_SelectTextdraw(playerid, COLOR_RED);
				
				pSpawn_Request[playerid] = SPAWN_REQUEST_GARAGE;
				TogglePlayerSpectating(playerid, true);
				SpawnPlayer(playerid);
			}
			case EDIT_RESPONSE_CANCEL:
			{
				if(GetPVarType(playerid, "pCancelObjectCancel"))
				{
					DeletePVar(playerid, "pCancelObjectCancel");
					return 0;
				}
				new id = GetPVarInt(playerid, "pGarageEditingModelIndex");
				
				DestroyPlayerObject(playerid, objectid);
				
				if(p_c_Model_Edited[playerid][id] != 2) {
					p_c_Objects[playerid][id] = CreateObject(p_c_Model[playerid][id], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0);
					AttachObjectToVehicle(p_c_Objects[playerid][id], pVehicleID[playerid], p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5]);
				}
				p_c_Model_Edited[playerid][id] = 0;
				
				CancelEdit(playerid);
				tm_SelectTextdraw(playerid, COLOR_RED);
				
				new cID = getCustomizationIDFromModel(p_c_Model[playerid][id]);
				if(cID != -1)
						SendClientMessageFormatted(playerid, -1, "[%s]: %s(%d) editing Cancelled.", GetTwistedMetalName(GetVehicleModel(pVehicleID[playerid])), cModels[cID][c_Name], id);

				pSpawn_Request[playerid] = SPAWN_REQUEST_GARAGE;
				TogglePlayerSpectating(playerid, true);
				SpawnPlayer(playerid);
			}
		}
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(playerData[playerid][pSpawned_Status] == 1) return 1;
	SetPVarInt(playerid, "Requesting_Spawn", 0);
	if(IsPlayerNPC(playerid))
	{
		#if defined RNPC_INCLUDED
		if(IsRNPC[playerid] != -1)
		{
			new npcid = IsRNPC[playerid];
			InitializeRNPCVehicle(Twisted_NPCS[npcid][t_NPCID], Twisted_NPCS[npcid][t_NPCVehicle]);
			printf("[RNPC: OnPlayerSpawn] - %s(%d)", playerName(playerid), playerid);
		}
		#endif
		/*for(new i = 0; i != MAX_PLAYERS; ++i)
		{
			if(i == playerid) continue;
			SetPlayerMarkerForPlayer( i, playerid, 0xFFFFFF00 );
		}*/
		/*if(strcmp(playerName(playerid), "[BOT]Calypso", false) == 0)
		{
			pTwistedIndex[playerid] = random(14) + 1;
			pVehicleID[playerid] = CreateVehicle(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
			C_S_IDS[pTwistedIndex[playerid]][CS_Colour1], C_S_IDS[pTwistedIndex[playerid]][CS_Colour2], 0);
			new Float:x, Float:y, Float:z, Float:angle;
			GetMapSpawnData(gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
			SetVehiclePos(pVehicleID[playerid], x, y, z);
			PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			SetCameraBehindPlayer(playerid);
			SetPlayerVirtualWorld(playerid, 0);
		}
		if(strfind(playerName(playerid), "[BOT]RacerTest", false) != -1)
		{
			pTwistedIndex[playerid] = random(14) + 1;
			pVehicleID[playerid] = CreateVehicle(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
			C_S_IDS[pTwistedIndex[playerid]][CS_Colour1], C_S_IDS[pTwistedIndex[playerid]][CS_Colour2], 0);
			new Float:x, Float:y, Float:z, Float:angle;
			GetMapSpawnData(gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
			SetVehiclePos(pVehicleID[playerid], x, y, z);
			PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			SetCameraBehindPlayer(playerid);
			SetPlayerVirtualWorld(playerid, 0);
		}*/
		return 1;
	}
	if(pSpectate_Random_Teammate[playerid] == 1)
	{
		new randomplayer[MAX_PLAYERS], count = 0, target;
		foreach(Player, i)
		{
			if(playerData[playerid][gGameID] != playerData[i][gGameID] || playerData[playerid][gTeam] != playerData[i][gTeam] || playerData[i][pSpawned_Status] == 0) continue;
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
		TogglePlayerSpectating(playerid, true);
		PlayerSpectateVehicle(playerid, pVehicleID[target], SPECTATE_MODE_NORMAL);
		SetPVarInt(playerid, "pSpectating", target);
		return 1;
	}
	switch(pSpawn_Request[playerid])
	{
		case SPAWN_REQUEST_NONE: 
		{
			if(IsPlayerAdmin(playerid)) {
				SetPlayerPos(playerid, 0, 0, 3);
			}
			return 1;
		}
		case SPAWN_REQUEST_REGISTRATION:
		{
			for(new i = 0; i < 3; ++i)
			{
				SetPlayerCameraPos(playerid, 2695.057568, -2352.101562, 40.479072);
				SetPlayerCameraLookAt(playerid, 2694.728027, -2347.103027, 40.359199, CAMERA_CUT);
			}
			return 1;
		}
		case SPAWN_REQUEST_Authentication:
		{
			if(!GetPVarInt(playerid, "pMultiplayer"))
			{
				TogglePlayerSpectating(playerid, true);
				for(new i = 0; i < 3; ++i)
				{
					SetPlayerCameraPos(playerid, 1545.918945, -1351.678344, 365.233612);
					SetPlayerCameraLookAt(playerid, 1545.924316, -1352.195800, 360.260467, CAMERA_CUT);
				}
				InterpolateCameraPos(playerid, 1545.918945, -1351.678344, 365.233612, 378.247344, -1987.221313, 29.519388, 120000);
				InterpolateCameraLookAt(playerid, 1545.924316, -1352.195800, 360.260467, 378.325256, -1991.985717, 28.004817, 120000);
				tm_SelectTextdraw(playerid, NAVIGATION_COLOUR);
				return 1;
			}
		}
		case SPAWN_REQUEST_GARAGE, SPAWN_REQUEST_GARAGE_EDITING:
		{
			setupGarageForPlayer(playerid);
			return 1;
		}
	}
	if(2001 <= playerData[playerid][pSpecial_Missile_Vehicle] <= 4000)
	{
		playerData[playerid][pSpecial_Missile_Vehicle] -= 2000;
		CallLocalFunction("OnPlayerVehicleHealthChange", "iiff", playerid, playerData[playerid][pSpecial_Missile_Vehicle], 2400.0, 2500.0);
		SetTimerEx("Reset_SMV", 100, false, "i", playerid);
		return 1;
	}
	setupClassSelectionForPlayer(playerid, pTwistedIndex[playerid], .firstTime = 1);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{//printf("[SAMP: OnPlayerDeath] - playerid: %d - killerid: %d - reason: %d", playerid, killerid, reason);
	if(GetPVarInt(playerid, "Vermin_Special") == 1 && playerData[playerid][pSpecial_Missile_Vehicle] != 0)
	{
		playerData[playerid][pSpecial_Missile_Vehicle] += 2000;
		DeletePVar(playerid, "Vermin_Special");
		return 1;
	}
	playerData[playerid][pSpawned_Status] = 0;
	ClearAnimations(playerid);
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	/*new bool:gender = true;
	switch(GetVehicleModel(pVehicleID[playerid]))
	{
		case TMC_JUNKYARD_DOG: gender = true;
		case TMC_BRIMSTONE: gender = true;
		case TMC_OUTLAW: gender = true;
		case TMC_REAPER: gender = true;
		case TMC_ROADKILL: gender = true;
		case TMC_THUMPER: gender = true;
		case TMC_SPECTRE: gender = false;
		case TMC_DARKSIDE: gender = false;
		case TMC_SHADOW: gender = false;
		case TMC_MEATWAGON: gender = false;
		case TMC_VERMIN: gender = true;
		case TMC_MANSLAUGHTER: gender = true;
		case TMC_SWEETTOOTH: gender = true;
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
	new vehicleid = pVehicleID[playerid], model = GetVehicleModel(pVehicleID[playerid]);
	RemovePlayerAttachedObject(playerid, 0);
	RemovePlayerFromVehicle(playerid);
	Vehicle_Using_Environmental[pVehicleID[playerid]] = 0;
	switch(model)
	{
		case TMC_JUNKYARD_DOG:
		{
			if(GetVehicleModel(playerData[playerid][pSpecial_Missile_Vehicle]) != 0) {
				DestroyVehicle(playerData[playerid][pSpecial_Missile_Vehicle]);
			}
			if(GetPVarInt(playerid, "Junkyard_Dog_Attach")) {
				DeletePVar(playerid, "Junkyard_Dog_Attach");
			}
		}
		case TMC_OUTLAW, TMC_THUMPER:
		{
			if(IsValidObject(playerData[playerid][pSpecial_Missile_Object])) {
				DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
				playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
			}
		}
	}
	PlayerVehicleRacePosition(playerid, PVRP_Destroy, "");
	if(GetVehicleComponentInSlot(pVehicleID[playerid], CARMODTYPE_NITRO)) {
		RemoveVehicleComponent(pVehicleID[playerid], GetVehicleComponentInSlot(pVehicleID[playerid], CARMODTYPE_NITRO));
	}
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_HUNTED, GM_TEAM_HUNTED:
		{
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(pVehicleID[playerid], engine, lights, alarm, doors, bonnet, boot, objective);
			SetVehicleParamsEx(pVehicleID[playerid], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_OFF);
		}
	}
	destroyTwistedVehicle(playerid, pVehicleID[playerid]);
	TogglePlayerControllable(playerid, true);
	for(new go; go < 2; go++)
	{
		if(IsValidObject(Vehicle_Machine_Gun_Object[pVehicleID[playerid]][go]))
		{
			DestroyObject(Vehicle_Machine_Gun_Object[pVehicleID[playerid]][go]);
			Vehicle_Machine_Gun_Object[pVehicleID[playerid]][go] = INVALID_OBJECT_ID;
		}
		if(IsValidObject(Vehicle_Machine_Gun_Flash[pVehicleID[playerid]][go]))
		{
			DestroyObject(Vehicle_Machine_Gun_Flash[pVehicleID[playerid]][go]);
			Vehicle_Machine_Gun_Flash[pVehicleID[playerid]][go] = INVALID_OBJECT_ID;
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
			Vehicle_Missile[vehicleid][s] = INVALID_OBJECT_ID;
		}
		Vehicle_Missile[vehicleid][s] = INVALID_OBJECT_ID;
		for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
		{
			if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
			{
				DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
				Vehicle_Missile_Lights[vehicleid][L] = INVALID_OBJECT_ID;
				Vehicle_Missile_Lights_Attached[vehicleid][L] = -1;
			}
		}
		if(IsValidObject(Vehicle_Smoke[vehicleid][s]))
		{
		   DestroyObject(Vehicle_Smoke[vehicleid][s]);
		   Vehicle_Smoke[vehicleid][s] = INVALID_OBJECT_ID;
		}
		Vehicle_Smoke[vehicleid][s] = INVALID_OBJECT_ID;
		if(Vehicle_Missile_Following[vehicleid][s] != INVALID_VEHICLE_ID)
		{
			Vehicle_Missile_Following[vehicleid][s] = INVALID_VEHICLE_ID;
			Vehicle_Missile_Final_Angle[vehicleid][s] = 0.0;
		}
	}
	SetPVarInt(playerid, "Hammerhead_Special_Attacking", INVALID_PLAYER_ID);
	SetPVarInt(playerid, "Hammerhead_Special_Hit", INVALID_PLAYER_ID);

	if(pHUDType[playerid] == HUD_TYPE_TMBLACK) {
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 0x00F000FF);
	}
	SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "%s(%d) Died.", playerName(playerid), playerid);
	resetPlayerGameVariables(playerid);
	return 1;
}

public OnPlayerTwistedDeath(killerid, killer_vehicleid, deathid, death_vehicleid, missileid, killerid_modelid, deathid_modelid)
{//// Kill an enemy vehicle.
	if(killerid != INVALID_PLAYER_ID)
	{
		++playerData[killerid][pKillStreaking];
		if(playerData[killerid][pKillStreaking] >= 1)
		{
			GainExprience(killerid, 25); // Go on a killstreak.
			++playerData[killerid][pKillStreaks];
			toggleAccountSave(killerid, ACCOUNT_UPDATE_KILLSTREAKS);
			format(Global_KSXPString, sizeof(Global_KSXPString), "KillStreak: %d", playerData[killerid][pKillStreaking]);
			ShowKillStreak(killerid, Global_KSXPString);
			if(playerData[killerid][pKillStreaking] == 2)
			{
				AddEXPMessage(killerid, "KS Bonus: Turbo & Energy Refill");
				new model = killerid_modelid;
				playerData[killerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
				playerData[killerid][pEnergy] = floatround(GetTwistedMetalMaxEnergy(model));

				SetPlayerProgressBarValue(killerid, pTextInfo[killerid][pEnergyBar], float(playerData[killerid][pEnergy]));
				SetPlayerProgressBarValue(killerid, pTextInfo[killerid][pTurboBar], float(playerData[killerid][pTurbo]));
				UpdatePlayerProgressBar(killerid, pTextInfo[killerid][pEnergyBar]);
				UpdatePlayerProgressBar(killerid, pTextInfo[killerid][pTurboBar]);
			}
			if(playerData[killerid][pKillStreaking] == 3)
			{
				playerData[killerid][pMissiles][Missile_Machine_Gun_Upgrade] += 150;
				if(playerData[killerid][pMissiles][Missile_Machine_Gun_Upgrade] > 300) {
					playerData[killerid][pMissiles][Missile_Machine_Gun_Upgrade] = 300;
				}
				AddEXPMessage(killerid, "KS Bonus: Mega Guns 150 Rounds");
				new idx[4];
				valstr(idx, playerData[killerid][pMissiles][Missile_Machine_Gun_Upgrade], false);
				PlayerTextDrawSetString(killerid, pTextInfo[killerid][Mega_Gun_IDX], idx);
				PlayerTextDrawShow(killerid, pTextInfo[killerid][Mega_Gun_IDX]);
				PlayerTextDrawShow(killerid, pTextInfo[killerid][Mega_Gun_Sprite]);
			}
			if(playerData[killerid][pKillStreaking] == 4) // only if tier 2
			{
				AddEXPMessage(killerid, "KS Bonus: Weapon Ammo Doubled");
				for(new pm = 0; pm < MAX_MISSILEID; pm++)
				{
					if(playerData[killerid][pMissiles][pm] > 0)
						playerData[killerid][pMissiles][pm] *= 2;
				}
			}
		}
	}
	if(IsPlayerConnected(deathid) && killerid != deathid)
	{
		++playerData[killerid][pKills];
		++playerData[deathid][pDeaths];
		toggleAccountSave(killerid, ACCOUNT_UPDATE_KILLS);
		toggleAccountSave(deathid, ACCOUNT_UPDATE_DEATHS);
		if(pHUDType[deathid] == HUD_TYPE_TMBLACK) {
			PlayerTextDrawBoxColor(deathid, pTextInfo[deathid][pHealthVerticalBar], 0x00F000FF);
		}
		new reason = 51;
		switch(missileid)
		{
			case Missile_Special:
			{
				switch(killerid_modelid)
				{
					case TMC_THUMPER: reason = 37;
				}
			}
			case Missile_Ram: reason = 49;
			case Energy_Mines: reason = 40;
		}
		switch(reason)
		{
			case 49: SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FF00FF, "%s Rammed To Death by %s", playerName(deathid), playerName(killerid));
			default: SendClientMessageFormatted(INVALID_PLAYER_ID, 0x00FF00FF, "%s Killed by %s", playerName(deathid), playerName(killerid));
		}
		SendDeathMessage(killerid, deathid, reason);
		new Float:x, Float:y, Float:z, Float:maxhealth = GetTwistedMetalMaxHealth(deathid_modelid),
			Float:damagepercent, team_score[4], teamthatlostapoint = INVALID_GAME_TEAM,
			team_text[32], rival_text[32];
		GetPlayerPos(deathid, x, y, z);
		SetPlayerPos(deathid, x, y, z + 10.0);
		if(playerData[deathid][pKillStreaking] >= 1) {
			GainExprience(killerid, 25); // Kill an enemy that's on a killstreak.
			AddEXPMessage(killerid, "Streaker Kill 25 XP");
			HideKillStreak(deathid);
		}
		playerData[deathid][pKillStreaking] = -1;
		if(deathid == playerData[killerid][pLast_Killed_By]) {
			GainExprience(killerid, 25); // Kill an enemy that last killed you
			AddEXPMessage(killerid, "Revenge Kill 25 XP");
			HideKillStreak(deathid);
			playerData[killerid][pLast_Killed_By] = INVALID_PLAYER_ID;
		}
		switch(gGameData[playerData[killerid][gGameID]][g_Gamemode])
		{
			case GM_HUNTED:
			{
				if(killerid == gHunted_Player[playerData[killerid][gGameID]][0]) {
					GainPoints(killerid, 1);
				}
				new engine, lights, alarm, doors, bonnet, boot, objective;
				if(deathid == gHunted_Player[playerData[deathid][gGameID]][0]) {
					GetVehicleParamsEx(pVehicleID[deathid], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(pVehicleID[deathid], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_OFF);
					GainPoints(killerid, 1);
					T_SetVehicleHealth(pVehicleID[gHunted_Player[playerData[deathid][gGameID]][0]], GetTwistedMetalMaxHealth(GetVehicleModel(pVehicleID[gHunted_Player[playerData[deathid][gGameID]][0]])));
					gHunted_Player[playerData[deathid][gGameID]][0] = killerid;
					GetVehicleParamsEx(pVehicleID[gHunted_Player[playerData[deathid][gGameID]][0]], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(pVehicleID[gHunted_Player[playerData[deathid][gGameID]][0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
					TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, "You Killed The Hunted!", 3000 );
					SetPVarInt(killerid, "Killed_Hunted", 1);
				} else {
					GetVehicleParamsEx(pVehicleID[killerid], engine, lights, alarm, doors, bonnet, boot, objective);
					if(objective != VEHICLE_PARAMS_ON)
					{
						SetVehicleParamsEx(pVehicleID[killerid], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_OFF);
					}
				}
			}
			case GM_TEAM_DEATHMATCH:
			{
				++Team_Info[playerData[killerid][gTeam]][TI_Score];
				format(team_score, sizeof(team_score), "%d", Team_Info[playerData[killerid][gTeam]][TI_Score]);
			}
			case GM_TEAM_HUNTED:
			{
				new engine, lights, alarm, doors, bonnet, boot, objective;
				if(killerid == gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gTeam]]
				&& deathid == gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gRival_Team]]) // hunted killed hunted
				{
					Team_Info[playerData[killerid][gTeam]][TI_Score] += 2;
					gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gRival_Team]] = INVALID_PLAYER_ID;
					AssignRandomTeamHuntedPlayer(playerData[killerid][gGameID], playerData[killerid][gRival_Team]);
					TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, "You Killed The Hunted!", 3000 );
					SetPVarInt(killerid, "Killed_Hunted", 1);
					GetVehicleParamsEx(pVehicleID[deathid], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(pVehicleID[deathid], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_OFF);
				}
				else if(killerid == gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gTeam]]
					&& deathid != gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gRival_Team]]) // hunted killed normal player
				{
					++Team_Info[playerData[killerid][gTeam]][TI_Score];
					AssignRandomTeamHuntedPlayer(playerData[killerid][gGameID], playerData[killerid][gRival_Team]);
				}
				else if(killerid != gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gTeam]] &&
					deathid == gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gRival_Team]]) // normal player killed hunted
				{
					++Team_Info[playerData[killerid][gTeam]][TI_Score];
					gHunted_Player[playerData[killerid][gGameID]][playerData[killerid][gRival_Team]] = INVALID_PLAYER_ID;
					AssignRandomTeamHuntedPlayer(playerData[killerid][gGameID], playerData[killerid][gRival_Team]);
					TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, "You Killed The Hunted!", 3000 );
					SetPVarInt(killerid, "Killed_Hunted", 1);
					GetVehicleParamsEx(pVehicleID[deathid], engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(pVehicleID[deathid], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_OFF);
				}
			}
			case GM_LAST_MAN_STANDING:
			{
				new count = 0;
				foreach(Player, i)
				{
					if(playerData[i][gGameID] != playerData[deathid][gGameID]) continue;
					if(i == deathid || playerData[i][pSpawned_Status] == 0 || GetPlayerState(i) == PLAYER_STATE_SPECTATING) continue;
					++count;
				}
				if(count == 1) {
					OnMapFinish(playerData[deathid][gGameID], gGameData[playerData[deathid][gGameID]][g_Gamemode], gGameData[playerData[deathid][gGameID]][g_Map_id]);
				}
				else pSpectate_Random_Teammate[deathid] = 1;
			}
			case GM_TEAM_LAST_MAN_STANDING:
			{
				if(gTeam_Lives[playerData[deathid][gGameID]][playerData[deathid][gTeam]] == 0)
				{
					--gTeam_Player_Count[playerData[deathid][gGameID]][playerData[deathid][gTeam]];
					if(gTeam_Player_Count[playerData[deathid][gGameID]][playerData[deathid][gTeam]] <= 0)
					{
						Team_Info[playerData[deathid][gTeam]][TI_Score] = 0;
						Team_Info[playerData[killerid][gTeam]][TI_Score] = 1;
						OnMapFinish(playerData[killerid][gGameID], gGameData[playerData[killerid][gGameID]][g_Gamemode], gGameData[playerData[killerid][gGameID]][g_Map_id]);
						return 1;
					}
					pSpectate_Random_Teammate[deathid] = 1;
				}
				else --gTeam_Lives[playerData[deathid][gGameID]][playerData[deathid][gTeam]];
				teamthatlostapoint = playerData[deathid][gTeam];
			}
		}
		format(Global_KSXPString, sizeof(Global_KSXPString), "~y~~h~%s Killed By %s", playerName(deathid), playerName(killerid));
		AddEXPMessage(INVALID_PLAYER_ID, Global_KSXPString); // Global
		if(GetPVarInt(killerid, "Killed_Hunted") == 0) {
			format(Global_KSXPString, sizeof(Global_KSXPString), "You Killed %s", playerName(deathid));
			TimeTextForPlayer( TIMETEXT_MIDDLE_LARGE, killerid, Global_KSXPString, 3000 );
		} else {
			DeletePVar(killerid, "Killed_Hunted");
		}
		damagepercent = playerData[killerid][pDamageToPlayer][deathid] / maxhealth * 100;
		if(0 <= damagepercent <= 14)
		{
			if(gGameData[playerData[killerid][gGameID]][g_Gamemode] != GM_HUNTED) {
				GainPoints(killerid, 25); // Poach Kill
			}
			TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Poach Kill, 25 Points!", 3000 );
		}
		else if(15 <= damagepercent <= 39)
		{
			if(gGameData[playerData[killerid][gGameID]][g_Gamemode] != GM_HUNTED) {
				GainPoints(killerid, 50); // Soft Kill
			}
			TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Soft Kill, 50 Points!", 3000 );
		}
		else if(40 <= damagepercent <= 74)
		{
			if(gGameData[playerData[killerid][gGameID]][g_Gamemode] != GM_HUNTED) {
				GainPoints(killerid, 75); // Kill
			}
			TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Kill, 75 Points!", 3000 );
		}
		else if(75 <= damagepercent <= 94)
		{
			if(gGameData[playerData[killerid][gGameID]][g_Gamemode] != GM_HUNTED) {
				GainPoints(killerid, 100); // Strong Kill
			}
			TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Strong Kill, 100 Points!", 3000 );
		}
		else
		{
			if(gGameData[playerData[killerid][gGameID]][g_Gamemode] != GM_HUNTED) {
				GainPoints(killerid, 125); // Super Kill
			}
			TimeTextForPlayer( TIMETEXT_POINTS, killerid, "Super Kill, 125 Points!", 3000 );
		}
		GainExprience(killerid, 25);
		AddEXPMessage(killerid, "Damage Bonus 25 XP");
		playerData[killerid][pDamageToPlayer][deathid] = 0.0;
		foreach(Player, i)
		{
			if(playerData[i][gGameID] != playerData[killerid][gGameID]) continue;
			switch(gGameData[playerData[killerid][gGameID]][g_Gamemode])
			{
				case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED:
				{
					if(playerData[killerid][gTeam] == playerData[i][gTeam]) {
						PlayerTextDrawSetString(i, pTextInfo[i][pTeam_Score], team_score);
					} else {
						PlayerTextDrawSetString(i, pTextInfo[i][pRival_Team_Score], team_score);
					}
				}
				case GM_TEAM_LAST_MAN_STANDING:
				{
					if(playerData[killerid][gTeam] == playerData[i][gTeam]) {
						format(team_text, sizeof(team_text), "Teammates: %d~n~Team Lives: %d", gTeam_Player_Count[playerData[i][gGameID]][playerData[i][gTeam]], gTeam_Lives[playerData[i][gGameID]][playerData[i][gTeam]]);
						PlayerTextDrawSetString(i, pTextInfo[i][pTeam_Score], team_text);
					}
					else if(playerData[killerid][gTeam] != playerData[i][gTeam]) {
						format(rival_text, sizeof(rival_text), "Enemies: %d~n~Enemy Lives: %d", gTeam_Player_Count[playerData[i][gGameID]][playerData[i][gTeam]], gTeam_Lives[playerData[i][gGameID]][playerData[i][gTeam]]);
						PlayerTextDrawSetString(i, pTextInfo[i][pRival_Team_Score], rival_text);
					}
					if(teamthatlostapoint == playerData[i][gTeam]) {
						format(Global_KSXPString, sizeof(Global_KSXPString), "Your Team Has %d Lives Left", gTeam_Lives[playerData[i][gGameID]][playerData[i][gTeam]]);
						AddEXPMessage(i, Global_KSXPString);
					}
				}
			}
			if(playerData[i][pDamageToPlayer][deathid] <= 0.0 || i == killerid) continue;
			maxhealth = GetTwistedMetalMaxHealth(deathid_modelid);
			damagepercent = playerData[i][pDamageToPlayer][deathid] / maxhealth * 100;
			if(0 <= damagepercent <= 24)
			{
				if(gGameData[playerData[i][gGameID]][g_Gamemode] != GM_HUNTED) {
					GainPoints(i, 25); // Soft Assist
				}
				++playerData[i][pKillAssists];
				toggleAccountSave(i, ACCOUNT_UPDATE_ASSISTS);
				TimeTextForPlayer( TIMETEXT_MIDDLE, killerid, "Soft Assist, 25 Points!", 3000 );
				GainExprience(i, 2);
				AddEXPMessage(i, "Soft Assist 2 XP");
			}
			else if(25 <= damagepercent <= 74)
			{
				if(gGameData[playerData[i][gGameID]][g_Gamemode] != GM_HUNTED) {
					GainPoints(i, 50); // Assist
				}
				++playerData[i][pKillAssists];
				toggleAccountSave(i, ACCOUNT_UPDATE_ASSISTS);
				TimeTextForPlayer( TIMETEXT_MIDDLE, killerid, "Assist, 50 Points!", 3000 );
				GainExprience(i, 5);
				AddEXPMessage(i, "Assist 5 XP");
			}
			else
			{
				if(gGameData[playerData[i][gGameID]][g_Gamemode] != GM_HUNTED) {
					GainPoints(i, 75); // Strong Assist
				}
				++playerData[i][pKillAssists];
				toggleAccountSave(i, ACCOUNT_UPDATE_ASSISTS);
				TimeTextForPlayer( TIMETEXT_MIDDLE, killerid, "Strong Assist, 75 Points!", 3000 );
				GainExprience(i, 10);
				AddEXPMessage(i, "Strong Assist 10 XP");
			}
			playerData[i][pDamageToPlayer][deathid] = 0.0;
		}
		playerData[deathid][pLast_Killed_By] = killerid;
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
				case TMC_JUNKYARD_DOG: reason = 0;
				case TMC_BRIMSTONE: reason = 1;
				case TMC_OUTLAW: reason = 2;
				case TMC_REAPER: reason = 3;
				case TMC_ROADKILL: reason = 4;
				case TMC_THUMPER: reason = 5;
				case TMC_SPECTRE: reason = 6;
				case TMC_DARKSIDE: reason = 7;
				case TMC_SHADOW: reason = 8;
				case TMC_MEATWAGON: reason = 9;
				case TMC_VERMIN: reason = 10;
				case TMC_3_WARTHOG: reason = 11;
				case TMC_MANSLAUGHTER: reason = 12;
				case TMC_HAMMERHEAD: reason = 13;
				case TMC_SWEETTOOTH: reason = 14;
			}
		}
		case Missile_Fall: reason = 15;
		case Missile_Ram: reason = 16;
		default: reason = (16 + missileid);
	}
	if(deathid != INVALID_PLAYER_ID)
	{
		new Float:health;
		GetPlayerHealth(deathid, health);
		if(health > 0.0) {
			SetPlayerHealth(deathid, -1);
		}
	}
	else deathid = (MAX_PLAYERS - 1);
	printf("[System: OnPlayerTwistedDeath] - killer: %s(%d), %d, deathid: %s(%d), %d, %d(%s), killer: %s(%d), death: %s(%d)", playerName(killerid), killerid, killer_vehicleid, playerName(deathid), deathid, death_vehicleid, missileid, twistedDeathReasons[reason], GetTwistedMetalName(killerid_modelid), killerid_modelid, GetTwistedMetalName(deathid_modelid), deathid_modelid);
	return 1;
}

public playerResetGameInvisibility(vehicleid)
{
	LinkVehicleToInterior(vehicleid, 0);
	return 1;
}

public playerResetGameShield(playerid)
{
	if(GetPVarType(playerid, "Absorption_Shield")) {
		DeletePVar(playerid, "Absorption_Shield");
	}
	if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACHED_INDEX_SHIELD)) {
		RemovePlayerAttachedObject(playerid, ATTACHED_INDEX_SHIELD);
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
	if(!IsPlayerInRangeOfPoint(playerid, 10.0, fVehicle[0], fVehicle[1], fVehicle[2]))
	{
		return;
	}
}
 // fix these, make use of both damagestatusupdate and health lost
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
		PlayerPlaySound(playerid, 6402, 0.0, 0.0, 0.0);
		tires = encode_tires(0, 0, 0, 0); // fix all tires
		UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	}
	if(lights)
	{
		new Float:x, Float:y, Float:z;
		GetPlayerPos(playerid, x, y, z);
		PlayerPlaySound(playerid, 6402, 0.0, 0.0, 0.0);
		lights = encode_lights(0, 0, 0, 0); // fix all lights
		UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	}
	return 1;
}

public ResetCollision(vehicleid){ WasDamaged[vehicleid] = 0; return 1; }

new Float:oldVehicleHealth[MAX_VEHICLES], Float:newVehicleHealth[MAX_VEHICLES]; // change MAX_VEHICLES to your own vehicle amount.

#define MAX_VEHICLE_HEALTH 2500.0

ConfigureVehicleRAMPos(vehicleid, &Float:x, &Float:y)
{
	switch(GetVehicleModel(vehicleid))
	{
		case TMC_DARKSIDE:
		{
			new Float:angle;
			GetVehicleZAngle(vehicleid, angle);
			x += (3.0 * floatsin(-angle, degrees));
			y += (3.0 * floatcos(-angle, degrees));
		}
		case TMC_HAMMERHEAD:
		{
			new Float:angle;
			GetVehicleZAngle(vehicleid, angle);
			x += (1.5 * floatsin(-angle, degrees));
			y += (1.5 * floatcos(-angle, degrees));
		}
		case TMC_MANSLAUGHTER:
		{
			new Float:angle;
			GetVehicleZAngle(vehicleid, angle);
			x += (1.0 * floatsin(-angle, degrees));
			y += (1.0 * floatcos(-angle, degrees));
		}
	}
	return 1;
}

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
			if(WasDamaged[id] == 0) continue;
			if(GetVehicleDistanceFromPoint(id, mx, my, mz) < 25.0)
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
					CallLocalFunction("OnVehicleHitVehicle", "iiiif", Vehicle_Driver[beingrammed], beingrammed, Vehicle_Driver[rammer], rammer, speed[1]);
				}
				GetVehiclePos(rammer, x, y, z);
				ConfigureVehicleRAMPos(rammer, mx, my);
				if(TwistedRAMRadius(GetVehicleModel(rammer)) <= GetVehicleDistanceFromPoint(beingrammed, x, y, z)) continue;

				CallLocalFunction("OnVehicleHitVehicle", "iiiif", Vehicle_Driver[rammer], rammer, Vehicle_Driver[beingrammed], beingrammed, ramspeed);
				rammer = INVALID_VEHICLE_ID;
				beingrammed = INVALID_VEHICLE_ID;
				ramspeed = 0.0;
				break;
			}
		}
		SetTimerEx("ResetCollision", 750, false, "i", vehicleid);
	}
	if(vehicleid == playerData[playerid][pSpecial_Missile_Vehicle] && newhealth < oldhealth)
	{
		new Float:x, Float:y, Float:z, Float:distaway = 1.0, id;
		id = GetClosestVehicleEx(playerid, 9.0, distaway);
		if(id != INVALID_VEHICLE_ID)
		{
			new Float:damage, distance_type = d_type_none;
			switch(GetVehicleModel(pVehicleID[playerid]))
			{
				case TMC_JUNKYARD_DOG:
				{
					return 1;
				}
				case TMC_VERMIN:
				{
					switch(floatround(distaway))
					{
						case 5..9: damage = 20.0, distance_type = d_type_close;
						case 0..4: damage = GetMissileDamage(Missile_Special, pVehicleID[playerid], 1);
					}
					printf("distaway: %0.2f - distance_type: %d", distaway, distance_type);
				}
				case TMC_MEATWAGON:
				{
					switch(floatround(distaway))
					{
						case 8..9: damage = 10.0, distance_type = d_type_far;
						case 4..7: damage = 20.0, distance_type = d_type_close;
						case 0..3: damage = GetMissileDamage(Missile_Special, pVehicleID[playerid], 1);
					}
				}
			}
			DamagePlayer(playerid, pVehicleID[playerid], Vehicle_Driver[id], id, damage, Missile_Special, 1, distance_type);
		}
		GetObjectPos(playerData[playerid][pSpecial_Missile_Object], x, y, z);
		CreateMissileExplosion(vehicleid, Missile_Special, x, y, z, 1);
		DestroyVehicle(playerData[playerid][pSpecial_Missile_Vehicle]);
		DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
		new Float:health;
		GetPlayerHealth(playerid, health);
		if(!(health == 0.0))
		{
			PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			playerData[playerid][pSpecial_Missile_Vehicle] = 0;
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
	if(newhealth < (MAX_VEHICLE_HEALTH - 100.0))
	{
		SetVehicleHealth(vehicleid, MAX_VEHICLE_HEALTH);
	}
	return 1;
}

CreateMissileExplosion(vehicleid, missileid, Float:x, Float:y, Float:z, alt_special = 0)
{
	new e_Objectid = INVALID_OBJECT_ID;
	switch(missileid)
	{
		case Missile_Special:
		{
			switch(GetVehicleModel(vehicleid))
			{
				case TMC_SPECTRE, TMC_JUNKYARD_DOG:
				{
					CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
					e_Objectid = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
				}
				case TMC_REAPER:
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
				case TMC_ROADKILL, TMC_SWEETTOOTH, TMC_3_WARTHOG: e_Objectid = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
				case TMC_VERMIN, TMC_MEATWAGON:
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
			}
		}
		case Missile_Power: e_Objectid = CreateObject(18681, x, y, z, 0.0, 0.0, 0.0, 300.0);
		case Missile_Napalm:
		{
			e_Objectid = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
			CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));
		}
		case Missile_Fire, Missile_Homing, Missile_Ricochet, Missile_Stalker: e_Objectid = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
		case Energy_Mines: CreateExplosion(x, y, z, 1, GetMissileExplosionRadius(missileid));

	}
	if(IsValidObject(e_Objectid))
	{
		SetTimerEx("Destroy_Explosion", 200, false, "i", e_Objectid);
	}
	return 1;
}

public Destroy_Explosion(objectid)
{
	DestroyObject(objectid);
	return 1;
}

public Reset_SMV(playerid)
{
	playerData[playerid][pSpecial_Missile_Vehicle] = 0;
	return 1;
}

/*Float:ph_Velocity(Float:distance, timetaken)
		return(distance/timetaken); // Meters per Second (m/s)
Float:ph_Acceleration(Float:velocitychange, timetaken) // (vfinal - vinitial) / (tfinal - tinitial)
		return(velocitychange/timetaken); // Meters per Second Squared (m/s^2)
Float:ph_Force(Float:mass, Float:acceleration)
		return(mass*acceleration); // Newtons (N)
Float:ph_Momentum(Float:mass, Float:velocity)
		return(mass*velocity); // Kilograms per Meter per Second (kgm/s)
Float:ph_ImpactForce(Float:momentum, timetaken)
		return(momentum/timetaken); // Newtons (N)*/

Float:TwistedRAMRadius(twistedid)
{
	switch(twistedid)
	{
		case TMC_JUNKYARD_DOG, TMC_BRIMSTONE, TMC_OUTLAW, TMC_ROADKILL, TMC_THUMPER, TMC_SPECTRE,
			TMC_SHADOW, TMC_MEATWAGON, TMC_VERMIN, TMC_SWEETTOOTH: return 12.0;
		case TMC_REAPER: return 9.0;
		case TMC_DARKSIDE, TMC_HAMMERHEAD: return 16.0;
		case TMC_MANSLAUGHTER: return 14.0;
	}
	return 12.0;
}

stock PrintMass()
{
	new Float:vehicle_weight;
	printf("TMC_JUNKYARD_DOG weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_JUNKYARD_DOG, "fMass"));
	printf("Brimstone weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_BRIMSTONE, "fMass"));
	printf("Outlaw weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_OUTLAW, "fMass"));
	printf("Reaper weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_REAPER, "fMass"));
	printf("Roadkill weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_ROADKILL, "fMass"));
	printf("Spectre weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_SPECTRE, "fMass"));
	printf("Darkside weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_DARKSIDE, "fMass"));
	printf("Shadow weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_SHADOW, "fMass"));
	printf("Meat_Wagon weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_MEATWAGON, "fMass"));
	printf("Vermin weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_VERMIN, "fMass"));
	printf("Warthog_TM3 weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_3_WARTHOG, "fMass"));
	printf("ManSalughter weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_MANSLAUGHTER, "fMass"));
	printf("Hammerhead weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_HAMMERHEAD, "fMass"));
	printf("Sweet_Tooth weighs %f Newtons", GetVehicleModelInfoAsFloat(TMC_SWEETTOOTH, "fMass"));
	return 1;
}

forward Float:TwistedMass(twistedmodel_id);
stock Float:TwistedMass(twistedmodel_id)
{
	switch(twistedmodel_id)
	{
		case TMC_JUNKYARD_DOG: return 3500.0;
		case TMC_BRIMSTONE: return 1700;
		case TMC_OUTLAW: return 2500.0;
		case TMC_REAPER: return 800.0;
		case TMC_ROADKILL: return 1200.0;
		case TMC_THUMPER: return 1500.0;
		case TMC_SPECTRE: return 1700.0;
		case TMC_DARKSIDE: return 3800.0;
		case TMC_SHADOW: return 2500.0;
		case TMC_MEATWAGON: return 1500.0;
		case TMC_VERMIN: return 1900.0;
		case TMC_3_WARTHOG: return 2500.0;
		case TMC_MANSLAUGHTER: return 8500.0;
		case TMC_HAMMERHEAD: return 5000.0;
		case TMC_SWEETTOOTH: return 1700.0;
	}
	return 1500.0;
}
new Float:Twisted_Custom_Health[MAX_VEHICLES];

public OnVehicleHitVehicle(playerid, myvehicleid, hitplayerid, vehicleid, Float:speed)
{
	if(playerid == INVALID_PLAYER_ID || myvehicleid == vehicleid || speed < 20.0) return 1;
	if(playerData[playerid][pSpecial_Missile_Vehicle] == myvehicleid) return 1;
	//SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "Vehicleid: %d Collided With Vehicleid: %d", myvehicleid, vehicleid);
	new Float:Health, str[32], Float:total, style = TIMETEXT_TOP, model = GetVehicleModel(myvehicleid),
		Float:size_x, Float:size_y, Float:size_z, Float:volume, omodel = GetVehicleModel(vehicleid);
	speed *= 0.44704; // mph to m/s
	//new Float:momentum = ph_Momentum(TwistedMass(model), speed); // Float:mass, Float:velocity
	//ph_ImpactForce(Float:momentum, timetaken) // Float:momentum, timetaken
	GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, size_x, size_y, size_z);
	volume = (size_x + size_y + size_z) / 2.0;
	total = (speed + volume);
	GetVehicleModelInfo(omodel, VEHICLE_MODEL_INFO_SIZE, size_x, size_y, size_z);
	volume = (size_x + size_y + size_z) / 2.0;
	total -= volume;
	if(GetPVarInt(playerid, "InTightTurn"))
	{
		total *= 1.2;
	}
	//ph_Momentum(Float:mass, Float:velocity)
	switch(omodel)
	{
		case TMC_JUNKYARD_DOG_TAXI:
		{
			if(playerData[playerid][pSpecial_Missile_Vehicle] == vehicleid) return 1;
			foreach(Player, i)
			{
				if(playerData[i][pSpecial_Missile_Vehicle] != vehicleid) continue;
				DamagePlayer(i, pVehicleID[i], playerid, myvehicleid, GetMissileDamage(Missile_Special, pVehicleID[i], 0), Missile_Special, 0, d_type_none);
				GetVehiclePos(vehicleid, size_x, size_y, size_z);
				CreateMissileExplosion(pVehicleID[i], Missile_Special, size_x, size_y, size_z, 0); //, GetFreeMissileSlot(pVehicleID[i])
				DestroyVehicle(vehicleid);
				playerData[i][pSpecial_Missile_Vehicle] = INVALID_VEHICLE_ID;
				DeletePVar(i, "Junkyard_Dog_Attach");
				break;
			}
		}
	}
	start:
	switch( floatround(total) )
	{
		case 0..49: format(str, sizeof(str), "Ram Damage Hit %d damage", floatround(total));
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
	if(playerData[playerid][pMissile_Charged] == Missile_Special)
	{
		switch(model)
		{
			case TMC_DARKSIDE:
			{
				total *= 1.1;
				format(str, sizeof(str), "DARKSIDE SLAM! %d damage", floatround(total));
				style = TIMETEXT_MIDDLE;
			}
			case TMC_HAMMERHEAD:
			{
				total *= 0.7;
				format(str, sizeof(str), "RAM ATTACK! %d damage", floatround(total));
				style = TIMETEXT_MIDDLE;
				KillTimer(Special_Missile_Timer[playerid]);
				playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
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
	if(playerData[playerid][pSpawned_Status] == 0) return 1;
	new Float:health, Float:maxhealth = GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid));
	health = (newhealth / maxhealth) * 100.0;
	if(health <= 0.0) health = -1;
	SetPlayerHealth(playerid, health);
	switch(pHUDType[playerid])
	{
		case HUD_TYPE_TMPS3:
		{
			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pHealthBar], newhealth);
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pHealthBar]);
		}
		default:
		{
			PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pHealthVerticalBar], 0.0, (health * -0.086) - ((health > 50.0) ? 0.1 : 0.66));
			health = (maxhealth / 2.0);
			maxhealth = (health / 2.0);
			//printf("newhealth: %0.2f - health2: %0.2f - health4: %0.2f", newhealth, health, maxhealth);
			if(newhealth < health)
			{
				if(newhealth < maxhealth)
				{
					PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 0xF00000FF);
				}
				else PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 0xFFEA00FF);
			}
			else PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 0x00F000FF);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthVerticalBar]);
		}
	}
	return 1;
}

T_SetVehicleHealth(vehicleid, Float:health)
{
	new Float:oldhealth = Twisted_Custom_Health[vehicleid], playerid = MPGetVehicleDriver(vehicleid);
	Twisted_Custom_Health[vehicleid] = health;
	if(playerid != INVALID_PLAYER_ID)
	{
		CallLocalFunction("OnEthicalHealthChange", "iiff", vehicleid, playerid, Twisted_Custom_Health[vehicleid], oldhealth);
	}
	return 1;
}

T_GetVehicleHealth(vehicleid, &Float:health)
{
	if(!GetVehicleHealth(vehicleid, health)) return 0;
	if(health)
	{
		health = Twisted_Custom_Health[vehicleid];
	}
	else return floatround(Twisted_Custom_Health[vehicleid]);
	return 1;
}

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
	if(playerData[playerid][pSpawned_Status] == 1)
	{
		if(pPlayerUpdate[playerid] >= 2 && isPlayerPaused(playerid)) {
			pPaused[playerid] = false;
			CallRemoteFunction("OnPlayerUnPause", "i", playerid);
		}
		pPlayerUpdate[playerid] = 0;
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
			if(( 1 <= playerData[playerid][pSpecial_Missile_Vehicle] <= 2000 ))
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
				vehicleid = playerData[playerid][pSpecial_Missile_Vehicle];
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
			if (lr != 0 && gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] <= 0)
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
			if(pFiring_Missile[playerid] == TMC_REAPER && playerData[playerid][pSpecial_Using_Alt] == 0)
			{
				new Float:heading, Float:altitude, Float:pitch;
				GetVehicleRotation(vehicleid, heading, altitude, pitch);
				if(30.0 <= pitch <= 90.0)
				{
					GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~Flame Saw Activated!", 4000, 3);
					playerData[playerid][pSpecial_Using_Alt] = 1;
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
					for(new i = 0; i < Speedometer_Needle_Index; ++i)
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
	/*else
	{
		if(GetPVarInt(playerid, "pClassSelection") == 1)
		{
			new ud, lr, keys;
			GetPlayerKeys(playerid, keys, ud, lr);
			if(lr == KEY_LEFT)
			{
				--pTwistedIndex[playerid];
			}
			else if(lr == KEY_RIGHT) ++pTwistedIndex[playerid];
			if(pTwistedIndex[playerid] > MAX_TWISTED_VEHICLES) pTwistedIndex[playerid] = 1;
			if(pTwistedIndex[playerid] < 1) pTwistedIndex[playerid] = MAX_TWISTED_VEHICLES;
			setupClassSelectionForPlayer(playerid, pTwistedIndex[playerid]);
		}
	}*/
	return 1;
}

new Float:s_velocity = 35.0, Float:s_maxrange = 25.0;

CMD:changes(playerid, params[])
{
	if(sscanf(params, "ff", s_maxrange, s_velocity)) return 0;
	SendClientMessageFormatted(playerid, -1, "s_maxrange: %0.2f - s_velocity: %0.2f", s_maxrange, s_velocity);
	return 1;
}

fireTwistedALTSpecial(playerid)
{
	new id = GetPlayerVehicleID(playerid), slot, missileid = Missile_Special;
	if(promptMissileFire(playerid, Missile_Special) == 0) return 0;
	switch(missileid)
	{
		case Missile_Special:
		{
			switch(GetVehicleModel(id))
			{
				case TMC_SHADOW:
				{
					new Float:x, Float:y, Float:z, Float:angle;

					slot = GetFreeMissileSlot(playerid, id);
					
					GetVehiclePos(id, x, y, z);
					GetVehicleZAngle(id, pShadow_Angle[playerid]);
					
					pShadow_Count[playerid] = 0;
					//90.0
					angle = GetRequiredAngle(s_maxrange, s_velocity);
					
					GetFlightData(0.0, s_velocity, angle, sData);
					
					SendClientMessageFormatted(playerid, -1, "s_maxrange: %0.2f - s_velocity: %0.2f - angle: %0.2f", s_maxrange, s_velocity, angle);
					
					++pShadow_Count[playerid]; // 19283
					
					Vehicle_Missile[id][slot] = CreateObject(362, x, y, z, 0.0, 0.0, pShadow_Angle[playerid], 300.0);
					
					GetXYInFrontOfPoint( x, y, pShadow_Angle[playerid], sData[pShadow_Count[playerid]][FLIGHT_DISTANCE] );

					MoveObject(Vehicle_Missile[id][slot], x, y, z + sData[pShadow_Count[playerid]][FLIGHT_DISTANCE], 15.0);
					
					Object_Owner[Vehicle_Missile[id][slot]] = id;
					Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
					Object_Type[Vehicle_Missile[id][slot]] = Missile_Special;
					Object_Slot[Vehicle_Missile[id][slot]] = slot; 
				}
				case TMC_REAPER:
				{
					playerData[playerid][pSpecial_Using_Alt] = 2;
					GivePlayerWeapon(playerid, REAPER_RPG_WEAPON, 1);
					PutPlayerInVehicle(playerid, id, 1);
					TimeTextForPlayer( TIMETEXT_TOP, playerid, "~k~~VEHICLE_HORN~ To Activate RPG (Shoot The Rifle To Fire An RPG Missile)", 3000);
					return 1;
				}
				case TMC_MEATWAGON:
				{
					if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
					{
						DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
						playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
					}
					new Float:vx, Float:vy, Float:vz, Float:distance, Float:angle,
						Float:x, Float:y, Float:z;
					pFiring_Missile[playerid] = 1;
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

					playerData[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(457, x, y, z, angle, 0, 0, -1);
					SetVehicleVelocity(playerData[playerid][pSpecial_Missile_Vehicle], vx, vy, vz);
					LinkVehicleToInterior(playerData[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
					SetVehicleHealth(playerData[playerid][pSpecial_Missile_Vehicle], 2500.0);
					
					playerData[playerid][pSpecial_Missile_Object] = CreateObject(2146, x, y, (z + 0.5), 0, 0, angle, 300.0);
					AttachObjectToVehicle(playerData[playerid][pSpecial_Missile_Object], playerData[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
					PutPlayerInVehicle(playerid, playerData[playerid][pSpecial_Missile_Vehicle], 0);
					Special_Missile_Timer[playerid] = SetTimerEx("GurneySpeedUpdate", 150, true, "ii", playerid, playerData[playerid][pSpecial_Missile_Vehicle]);
				}
				case TMC_VERMIN: // Rat Rocket
				{
					if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
					{
						DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
						playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
					}
					new Float:x, Float:y, Float:z, Float:angle;
					pFiring_Missile[playerid] = 1;
					GetVehiclePos(id, x, y, z);
					GetVehicleZAngle(id, angle);
					z += 3.0;
					playerData[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(464, x, y, z, angle, 0, 0, -1);
					LinkVehicleToInterior(playerData[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
					SetVehicleHealth(playerData[playerid][pSpecial_Missile_Vehicle], 2500.0);
					playerData[playerid][pSpecial_Missile_Object] = CreateObject(Missile_Default_Object, x, y, (z + 0.5), 0, 0, angle, 300.0);
					AttachObjectToVehicle(playerData[playerid][pSpecial_Missile_Object], playerData[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 270.0);
					PutPlayerInVehicle(playerid, playerData[playerid][pSpecial_Missile_Vehicle], 0);
					KillTimer(Special_Missile_Timer[playerid]);
					Special_Missile_Timer[playerid] = SetTimerEx("RocketSpeedUpdate", 150, true, "ii", playerid, playerData[playerid][pSpecial_Missile_Vehicle]);
					SetPVarInt(playerid, "Vermin_Special", 1);
				}
			}
			CallLocalFunction("OnMissileFire", "iiiii", playerid, id, slot, Missile_Special, playerData[playerid][pSpecial_Missile_Object]);
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

CMD:checkmissiles(playerid, params[])
{
	for(new slot = 0; slot < MAX_MISSILE_SLOTS; slot++)
	{
		if(Vehicle_Missile[pVehicleID[playerid]][slot] != INVALID_OBJECT_ID)
		{
			SendClientMessageFormatted(playerid, -1, "Slot: %d - ID: %d", slot, Vehicle_Missile[pVehicleID[playerid]][slot]);
		}
	}
	return 1;
}

CMD:hudtype(playerid, params[])
{
	DestroyHUD(playerid);
	CreateHUD(playerid, strval(params));
	return 1;
}

DestroyHUD(playerid)
{
	TextDrawHideForPlayer(playerid, pHud_Box);
	TextDrawHideForPlayer(playerid, pHud_UpArrow);
	TextDrawHideForPlayer(playerid, pHud_LeftArrow);
	TextDrawHideForPlayer(playerid, pHud_RightArrow);
	TextDrawHideForPlayer(playerid, pHud_HealthSign);
	TextDrawHideForPlayer(playerid, pHud_BoxSeparater);
	TextDrawHideForPlayer(playerid, pHud_SecondBox);
	TextDrawHideForPlayer(playerid, pHud_EnergySign);
	TextDrawHideForPlayer(playerid, pHud_TurboSign);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pHealthVerticalBar]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pLevelText]);
	PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pEXPText]);
	for(new m = 0; m < (MAX_MISSILEID); m++)
	{
		PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pMissileSign][m]);
	}
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pHealthBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	DestroyPlayerProgressBar(playerid, pTextInfo[playerid][pAiming_Health_Bar]);
	return 1;
}

CreateHUD(playerid, hudtype)
{
	new str[32], Float:x, Float:y;
	switch(hudtype)
	{
		case HUD_TYPE_TMPS3:
		{
			for(new m = 0; m < (MAX_MISSILEID); m++) {
				x = 195.0 + (m * 25.0), y = 388.0;
				pTextInfo[playerid][pMissileSign][m] = CreatePlayerTextDraw(playerid, x, y, "999");
				PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pMissileSign][m], 255);
				PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pMissileSign][m], 2);
				PlayerTextDrawFont(playerid, pTextInfo[playerid][pMissileSign][m], 1);
				PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pMissileSign][m], 0.260000, 0.88);
				PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][m], 100); // 16711935
				PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pMissileSign][m], 1);
				PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pMissileSign][m], 1);
				PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pMissileSign][m], 1);

				format(str, 32, "%d", playerData[playerid][pMissiles][m]);
				PlayerTextDrawSetString(playerid, pTextInfo[playerid][pMissileSign][m], str);

				x = 183.0 + (m * 25.0), y = 395.0; // end at x 420
				switch(m)
				{//3790, 3786
					case Missile_Special:
					{
						pTextInfo[playerid][pMissileImages][m] = CreatePlayerTextDraw(playerid, x, y, "S");
						PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pMissileImages][m], 255);
						//PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pMissileImages][m], 2);
						PlayerTextDrawFont(playerid, pTextInfo[playerid][pMissileImages][m], 1);
						PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pMissileImages][m], 1.25, 3.5);
						PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileImages][m], 100);
						PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pMissileImages][m], 1);
					}
					case Missile_Environmentals: // Missile_Lightning
					{
						pTextInfo[playerid][pMissileImages][m] = CreatePlayerTextDraw(playerid, x, y, "E");
						PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pMissileImages][m], 255);
						//PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pMissileImages][m], 2);
						PlayerTextDrawFont(playerid, pTextInfo[playerid][pMissileImages][m], 1);
						PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pMissileImages][m], 1.25, 3.5);
						PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileImages][m], 100);
						PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pMissileImages][m], 1);
					}
					default:
					{
						x = 175.0 + (m * 25.0), y = 395.0; // end at x 420
						pTextInfo[playerid][pMissileImages][m] = CreatePlayerTextDraw(playerid, x, y, "_");
						PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pMissileImages][m], 0);
						//PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pMissileImages][m], 2);
						PlayerTextDrawFont(playerid, pTextInfo[playerid][pMissileImages][m], 5);
						PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pMissileImages][m], 0.500000, 1.000000);
						PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][m], 100);
						PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pMissileImages][m], 1);
						PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pMissileImages][m], 1);
						PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pMissileImages][m], 1);
						PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pMissileImages][m], 0xFFFFFF00);
						PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pMissileImages][m], 40.000000, 32.000000);
						PlayerTextDrawSetPreviewModel(playerid, pTextInfo[playerid][pMissileImages][m], ReturnMissileModel(m));
						switch(m)
						{
							case Missile_Napalm, Missile_RemoteBomb: PlayerTextDrawSetPreviewRot(playerid, pTextInfo[playerid][pMissileImages][m], 0.0, 0.0, 0.0, 1.0);
							case Missile_Ricochet: PlayerTextDrawSetPreviewRot(playerid, pTextInfo[playerid][pMissileImages][m], 270.0, 0.0, 180.0, 0.3);
							default: PlayerTextDrawSetPreviewRot(playerid, pTextInfo[playerid][pMissileImages][m], 90.0, 90.0, 270.0, 1.0);
						}
					}
				}
				//pTextInfo[playerid][pMissileImages][m] = CreatePlayerTextDraw(playerid, 516.000000, 345.000000 + (m != 0 ? (m + (13 * m) / 2) : 0), "Missiles");
			}
			new Float:maxhealth = MAX_TWISTED_HEALTH;
			if(IsPlayerInAnyVehicle(playerid))
			{
				maxhealth = GetTwistedMetalMaxHealth(GetVehicleModel(GetPlayerVehicleID(playerid)));
			}
			//PlayerBar:CreatePlayerProgressBar(playerid, Float:x, Float:y, Float:width, Float:height, color, Float:max = 100.0, color2 = -1, color1 = -1);
			pTextInfo[playerid][pHealthBar] = CreatePlayerProgressBar(playerid, 532.00, 430.00, 75.0, 5.0, 0x38FF53FF, maxhealth);
			pTextInfo[playerid][pTurboBar] = CreatePlayerProgressBar(playerid, 532.00, 440.00, 75.0, 3.20, -5046017, MAX_TURBO); //922812415
			pTextInfo[playerid][pEnergyBar] = CreatePlayerProgressBar(playerid, 20.00, 440.00, 40.0, 3.20, ENERGY_COLOUR, MAX_ENERGY);

			pTextInfo[playerid][Mega_Gun_IDX] = CreatePlayerTextDraw(playerid, 105.000, 315.000, "150");
			pTextInfo[playerid][Mega_Gun_Sprite] = CreatePlayerTextDraw(playerid, 100.000, 323.000, "LD_TATT:9gun"); // LD_TATT:9gun
			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pHealthBar], maxhealth);
		}
		default:
		{
			for(new m = 0; m < (MAX_MISSILEID); m++) {
				pTextInfo[playerid][pMissileSign][m] = CreatePlayerTextDraw(playerid, 516.000000, 345.000000 + (m != 0 ? (m + (13 * m) / 2) : 0), "Missiles");
				PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pMissileSign][m], 255);
				PlayerTextDrawFont(playerid, pTextInfo[playerid][pMissileSign][m], 1);
				PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pMissileSign][m], 0.260000, 0.88);
				PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][m], 100); // 16711935
				PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pMissileSign][m], 0);
				PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pMissileSign][m], 1);
				PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pMissileSign][m], 1);

				format(str, 32, "%d %s", playerData[playerid][pMissiles][m], GetTwistedMissileName(m));
				PlayerTextDrawSetString(playerid, pTextInfo[playerid][pMissileSign][m], str);
			}
			pTextInfo[playerid][pTurboBar] = CreatePlayerProgressBar(playerid, 532.00, 430.00, 87.50, 3.20, -5046017, MAX_TURBO); //922812415
			pTextInfo[playerid][pEnergyBar] = CreatePlayerProgressBar(playerid, 532.00, 420.00, 87.50, 3.20, ENERGY_COLOUR, 100.0);
			
			pTextInfo[playerid][Mega_Gun_IDX] = CreatePlayerTextDraw(playerid, 527.000000, 315.000000, "150");
			pTextInfo[playerid][Mega_Gun_Sprite] = CreatePlayerTextDraw(playerid, 527.000, 323.000, "LD_TATT:9gun"); // LD_TATT:9gun
		}
	}
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][Mega_Gun_IDX], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][Mega_Gun_IDX], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][Mega_Gun_IDX], 0.360000, 1.100000);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][Mega_Gun_IDX], -1);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][Mega_Gun_IDX], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][Mega_Gun_IDX], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][Mega_Gun_IDX], 1);

	PlayerTextDrawFont(playerid, pTextInfo[playerid][Mega_Gun_Sprite], 4);
	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][Mega_Gun_Sprite], 22.000, 13.000);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][Mega_Gun_Sprite], -1);
	
	playerData[playerid][pTurbo] = floatround(MAX_TURBO);
	playerData[playerid][pEnergy] = 100;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], float(playerData[playerid][pTurbo]));
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));

	pTextInfo[playerid][pExprienceBar] = CreatePlayerProgressBar(playerid, 187.00, 435.00, 252.50, 1.40, EXPRIENCE_COLOUR, 1000.0, 0x000000FF, 0x4D4D4DFF); // 0xFF0000FF
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pExprienceBar], 0.0);
	
	pTextInfo[playerid][pChargeBar] = CreatePlayerProgressBar(playerid, 320.00, 240.00, 50.0, 2.0, 0xFFA500FF, 20.0); //, 0xFFFFFFFF, 0xFFFFFFFF
	playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], DEFAULT_CHARGE_INDEX);
	
	pTextInfo[playerid][pAiming_Health_Bar] = CreatePlayerProgressBar(playerid, 75.00, 325.00, 53.50, 2.50, 16711850, 100.0);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pAiming_Health_Bar], 0.0);
	return 1;
}

CMD:showhud(playerid, params[])
{
	showPlayerHUD(playerid);
	return 1;
}

CMD:hidehud(playerid, params[])
{
	hidePlayerHUD(playerid);
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	iCurrentState[playerid] = newstate;
	switch(newstate)
	{
		case PLAYER_STATE_DRIVER, PLAYER_STATE_PASSENGER:
		{
			if(GetPVarInt(playerid, "pGarage") || GetPVarInt(playerid, "pClassSelection")) return 1;
			Vehicle_Driver[GetPlayerVehicleID(playerid)] = playerid;
			showPlayerHUD(playerid);
			resetPlayerJumpData(playerid);
			/*if(!DeActiveSpeedometer{playerid})
			{
				for(new i; i != 15; ++i) TextDrawShowForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
				for(new i; i < Speedometer_Needle_Index; ++i) TextDrawShowForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
			}
			else
			{
				for(new i; i < Speedometer_Needle_Index; ++i) TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
				for(new i; i != 15; ++i) TextDrawHideForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
			}*/
		}
		case PLAYER_STATE_ONFOOT, PLAYER_STATE_EXIT_VEHICLE:
		{
			if(GetPVarInt(playerid, "pGarage") || GetPVarInt(playerid, "pClassSelection")) return 1;
			switch(oldstate)
			{
				case PLAYER_STATE_DRIVER:
				{
					if(!playerData[playerid][CanExitVeh] && playerData[playerid][pSpawned_Status] == 1)
						PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
				}
			}
		}
		case PLAYER_STATE_WASTED: hidePlayerHUD(playerid);
	}
	switch(oldstate)
	{
		case PLAYER_STATE_DRIVER, PLAYER_STATE_PASSENGER:
		{
			if(GetPVarInt(playerid, "pGarage") || GetPVarInt(playerid, "pClassSelection")) return 1;
			hidePlayerHUD(playerid);
		}
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_SUBMISSION) && (newkeys & MISSILE_FIRE_KEY))
	{
		SendClientMessageFormatted(playerid, -1, "Alt Fire: %d", pMissileID[playerid]);
		if(!pFiring_Missile[playerid])
		{
			switch(pMissileID[playerid])
			{
				case Energy_Shield: return cmd_shield(playerid, "Absorption_Shield");
				case Energy_Mines: return cmd_mine(playerid, "alt_fire");
				case Missile_Special:
				{
					fireTwistedALTSpecial(playerid);
					return 1;
				}
			}
		}
	}
	if(newkeys & MISSILE_FIRE_KEY && !(newkeys & KEY_SUBMISSION))
	{
		if(!fireChargedMissile(playerid, newkeys))
		{
			new id = GetPlayerVehicleID(playerid);
			if(tNapalm_Slot[playerid] != -1)
			{
				if(IsValidObject(Vehicle_Missile[id][tNapalm_Slot[playerid]]) && pFiring_Missile[playerid] == 1 && pMissileID[playerid] == Missile_Napalm)
				{
					new slot = tNapalm_Slot[playerid], Float:x, Float:y, Float:z, axis, object = Vehicle_Missile[id][slot];
					GetObjectPos(object, x, y, z);
					DestroyObject(Vehicle_Missile[id][slot]);
					Object_Owner[object] = INVALID_VEHICLE_ID;
					Object_OwnerEx[object] = INVALID_PLAYER_ID;
					Object_Type[object] = Object_Slot[object] = -1;
					EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_REMOVE);
					Vehicle_Missile[id][slot] = CreateObject(Missile_Napalm_Object, x, y, z, 0, 0, 0.0, 150.0);
					z = getMapLowestZEx(gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, axis);
					MoveObject(Vehicle_Missile[id][slot], x, y, z + 0.2, (MISSILE_SPEED - 38));
					Object_Owner[Vehicle_Missile[id][slot]] = id;
					Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
					Object_Type[Vehicle_Missile[id][slot]] = Missile_Napalm;
					Object_Slot[Vehicle_Missile[id][slot]] = slot;
					EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
					DestroyObject(Vehicle_Smoke[id][slot]);
					Vehicle_Smoke[id][slot] = INVALID_OBJECT_ID;
					SetPVarInt(playerid, "Dont_Destroy_Napalm", 1);
					GameTextForPlayer(playerid, " ", 1, 3); //SendClientMessageFormatted(playerid, -1, "z: %0.2f", z);
					return 1;
				}
			}
			if(pFiring_Missile[playerid] == TMC_REAPER)
			{
				RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Index);
				if(playerData[playerid][pSpecial_Using_Alt] == 1)
				{
					RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Flame_Index);
				}
				GameTextForPlayer(playerid, " ", 1, 3);
				fireMissile(playerid, id, Missile_Special, newkeys);
				return 1;
			}
			if(!pFiring_Missile[playerid])
			{
				if(id != INVALID_VEHICLE_ID)
				{
					switch(pMissileID[playerid])
					{
						case Missile_Special: startTwistedSpecial(playerid, id, newkeys);
						case Missile_Environmentals:
						{
							switch(gGameData[playerData[playerid][gGameID]][g_Map_id])
							{
								case MAP_DOWNTOWN:
								{
									if(Vehicle_Using_Environmental[id] == 1) return 1;
									if(playerData[playerid][pMissiles][Missile_Environmentals] == 0) return 1;
									--playerData[playerid][pMissiles][Missile_Environmentals];
									StartEnvironmentalEvent(playerid);
									if(playerData[playerid][pMissiles][Missile_Environmentals] == 0)
									{
										pMissileID[playerid] = getNextHUDSlot(playerid);
									}
									else updatePlayerHUD(playerid, Missile_Environmentals);
								}
							}
						}
						default: fireMissile(playerid, id, pMissileID[playerid], newkeys);
					}
				}
			}
		}
	}
	if(newkeys == 320)
	{
		switch(playerData[playerid][Camera_Mode])
		{
			case CAMERA_MODE_NONE:
			{
				new Float:sX, Float:sY, Float:sZ, model = GetVehicleModel(pVehicleID[playerid]);
				GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
				if(IsValidObject(playerData[playerid][Camera_Object]))
				{
					DestroyObject(playerData[playerid][Camera_Object]);
					playerData[playerid][Camera_Object] = INVALID_OBJECT_ID;
				}
				playerData[playerid][Camera_Object] = CreatePlayerObject(playerid, 19300, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				AttachPlayerObjectToVehicle(playerid, playerData[playerid][Camera_Object], pVehicleID[playerid],
				0.0, -sY, sZ, 0.0, 0.0, 0.0);
				AttachCameraToPlayerObject(playerid, playerData[playerid][Camera_Object]);
				playerData[playerid][Camera_Mode] = CAMERA_MODE_FREE_LOOK;
				SendClientMessage(playerid, -1, "Free Camera Mode Activiated");
			}
			case CAMERA_MODE_FREE_LOOK:
			{
				if(IsValidPlayerObject(playerid, playerData[playerid][Camera_Object]))
				{
					DestroyPlayerObject(playerid, playerData[playerid][Camera_Object]);
					playerData[playerid][Camera_Object] = INVALID_OBJECT_ID;
				}
				playerData[playerid][Camera_Mode] = CAMERA_MODE_NONE;
				SetCameraBehindPlayer(playerid);
				SendClientMessage(playerid, -1, "Free Camera Mode Deactiviated");
			}
		}
	}
	if(newkeys & KEY_YES)
	{
		if(playerData[playerid][pSpawned_Status] == 1)
		{
			cmd_jump(playerid, "");
		}
	}
	if(newkeys & KEY_NO)
	{   //tm_SelectTextdraw(playerid, ENERGY_COLOUR);
		if(playerData[playerid][pSpawned_Status] == 1)
		{
			pHUDStatus[playerid] = !pHUDStatus[playerid];
			switch(pHUDStatus[playerid])
			{
				case HUD_MISSILES:
				{
					pMissileID[playerid] = Missile_Special;
					AddEXPMessage(playerid, "HUD:: Missiles");
				}
				case HUD_ENERGY:
				{
					pMissileID[playerid] = ENERGY_WEAPONS_INDEX;
					AddEXPMessage(playerid, "HUD:: Energy Abilities");
				}
			}
			//CallLocalFunction("OnVehicleMissileChange", "iiii", pVehicleID[playerid], oldmissile, pMissileID[playerid], playerid);
		}
	}
	if(playerData[playerid][gGameID] != INVALID_GAME_TEAM)
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] <= 0)
		{
			if((newkeys & KEY_SPRINT) && (newkeys & KEY_JUMP)) // || newkeys & (KEY_SPRINT | KEY_JUMP | KEY_FIRE)))
			{
				playerData[playerid][pBurnout] = GetTickCount();
			}
			if((newkeys & 8 || newkeys == VEHICLE_ACCELERATE) && oldkeys & 32 && !(newkeys & 32))
			{
				new Float:speed[2], Float:Xv, Float:Yv, Float:Zv, Float:absV,
					Float:mp = floatdiv(GetTickCount() - playerData[playerid][pBurnout], 3000.0),
					vehicleid = GetPlayerVehicleID(playerid), Float:Zangle;
				if(mp > 1.70) {
					mp = 1.70;
				}
				if(mp < 0.20) return 1;
				if(newkeys & KEY_FIRE) { // nitro
					mp *= 1.10;
				}
				if(GetVehicleSpeed(vehicleid, true) < 20.0) {
					GetXYInFrontOfVehicle(vehicleid, speed[0], speed[1], float(playerData[playerid][pBurnout]) * 1.50);
					AccelerateTowardsAPoint(vehicleid, speed[0], speed[1]);
				}
				GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
				absV = floatsqroot((Xv * Xv) + (Yv * Yv) + (Zv * Zv));
				if(absV < 0.04)
				{
					GetVehicleZAngle(vehicleid, Zangle);
					GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
					//Xv = (0.10 * floatsin(Zangle, degrees));
					//Yv = (0.10 * floatcos(Zangle, degrees));
					Xv = (0.07 * floatsin(Zangle, degrees) * mp);
					Yv = (0.07 * floatcos(Zangle, degrees) * mp);
					SetVehicleAngularVelocity(vehicleid, Yv, Xv, 0);
					Xv = (0.23 * floatcos(Zangle, degrees) * mp);
					Yv = (-0.23 * floatsin(Zangle, degrees) * mp);
					SetVehicleVelocity(vehicleid, Yv, Xv, 0);
				}
				playerData[playerid][pBurnout] = 0;
			}
			if((RELEASED( KEY_SPRINT | KEY_JUMP ) || newkeys != ( KEY_SPRINT | KEY_JUMP )) && !(newkeys & 8 || newkeys == VEHICLE_ACCELERATE))
			{
				if (playerData[playerid][pBurnout] > 0) {
					playerData[playerid][pBurnout] = 0;
				}
			}
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
	if(newkeys == KEY_ANALOG_RIGHT)
	{
		if(GetPVarType(playerid, "pSpectating"))
		{
			new i = GetPVarInt(playerid, "pSpectating") + 1;
			if(i >= MAX_PLAYERS) i = 0;
			for(; i < MAX_PLAYERS; ++i)
			{
				if(playerData[i][gGameID] != playerData[playerid][gGameID]) continue;
				if(playerData[i][gTeam] != playerData[playerid][gTeam]) continue;
				if(!IsPlayerInAnyVehicle(i))  continue;
				PlayerSpectateVehicle(playerid, GetPlayerVehicleID(i));
				SetPVarInt(playerid, "pSpectating", i);
				break;
			}
		}
	}
	if((newkeys & KEY_FIRE) == KEY_FIRE)
	{
		new vehicleid = GetPlayerVehicleID(playerid), model;
		model = GetVehicleModel(vehicleid);
		if(model == TMC_REAPER && playerData[playerid][pSpecial_Using_Alt] == 2)
		{ // REAPER_RPG_WEAPON
			new slot = GetFreeMissileSlot(playerid, vehicleid), Float:x, Float:y, Float:z, Float:a,
			light_slots[2], Float:distance, Float:x2, Float:y2, Float:z2, Float:pitch;
			pFiring_Missile[playerid] = 1;
			
			GetPlayerFacingAngle(playerid, a);
			GetPlayerPos(playerid, x, y, z);
			
			calcMissileOffsets(playerid, vehicleid, distance, a, x, y, z, VehicleOffsetX[vehicleid], VehicleOffsetY[vehicleid], VehicleOffsetZ[vehicleid], GetPlayerPing(playerid));
			calcMissileElevation(playerid, vehicleid, x2, y2, z2, pitch);

			Vehicle_Missile[vehicleid][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
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
			findPlayerMissileTarget(playerid, vehicleid, slot);
			CallLocalFunction("OnMissileFire", "iiiii", playerid, vehicleid, slot, Missile_Special, Vehicle_Missile[vehicleid][slot]);
			PutPlayerInVehicle(playerid, vehicleid, 0);
			PlaySoundForPlayersInRange(44239, 35.0, x, y, z); // "RPG! RPG!"
			return 1;
		}
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && !IsPlayerInvalidNosExcludeBikes(playerid))
		{
			if(playerData[playerid][pTurbo] <= 0) return 1;
			if(playerData[playerid][Turbo_Tick] != 0)
			{
				if(GetTickCount() - playerData[playerid][Turbo_Tick] < 500)
				{
					switch(model)
					{
						case 463:
						{
							if(IsValidObject(Nitro_Bike_Object[playerid]))
							{
								DestroyObject(Nitro_Bike_Object[playerid]);
								Nitro_Bike_Object[playerid] = INVALID_OBJECT_ID;
							}
							new Float:x, Float:y, Float:z;
							GetPlayerPos(playerid, x, y, z);
							Nitro_Bike_Object[playerid] = CreateObject(18693, x, y, z + 10, 0.0, 0.0, 0.0, 125.0);
							AttachObjectToVehicle(Nitro_Bike_Object[playerid], vehicleid, 0.164999, 0.909999, -0.379999, 86.429962, 3.645001, 0.000000);
						}
						default: AddVehicleComponent(vehicleid, 1010);
					}
					KillTimer(playerData[playerid][Turbo_Timer]);
					playerData[playerid][Turbo_Timer] = SetTimerEx("Turbo_Deduct", TURBO_DEDUCT_INDEX, true, "ii", playerid, vehicleid); //12
				}
				playerData[playerid][Turbo_Tick] = GetTickCount();
			}
			else playerData[playerid][Turbo_Tick] = GetTickCount();
		}
	}
	if(RELEASED(KEY_FIRE) || oldkeys & KEY_FIRE && !(newkeys & KEY_FIRE))
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && !IsPlayerInvalidNosExcludeBikes(playerid))
		{
			RemoveVehicleComponent(pVehicleID[playerid], 1010);
			KillTimer(playerData[playerid][Turbo_Timer]);
			if(IsValidObject(Nitro_Bike_Object[playerid]))
			{
				DestroyObject(Nitro_Bike_Object[playerid]);
				Nitro_Bike_Object[playerid] = INVALID_OBJECT_ID;
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
			if(playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] > 0) {
				update_index = 185;
				missileid = Missile_Machine_Gun_Upgrade;
			}
			fireMissile(playerid, id, missileid, newkeys);
			Machine_Gun_Firing_Timer[playerid] = SetTimerEx("fireMissile", update_index, true, "iii", playerid, id, missileid);
		}
	}
	if(newkeys & KEY_SUBMISSION)
	{
		switch(GetVehicleModel(pVehicleID[playerid]))
		{
			case TMC_JUNKYARD_DOG:
			{
				if(playerData[playerid][pSpecial_Missile_Vehicle] != INVALID_VEHICLE_ID
					&& IsTrailerAttachedToVehicle(pVehicleID[playerid]))
				{
					DeletePVar(playerid, "Junkyard_Dog_Attach");
					DetachTrailerFromVehicle(pVehicleID[playerid]);
					GameTextForPlayer(playerid, "~w~Taxi Bomb Dropped", 3000, 3);
				}
			}
		}
	}
	if(PRESSED(KEY_ANALOG_UP) || HOLDING(KEY_ANALOG_UP))
	{
		if(pHUDStatus[playerid] == HUD_MISSILES)
		{
			new id = GetPlayerVehicleID(playerid), oldmissile = pMissileID[playerid];
			pMissileID[playerid] = getNextHUDSlot(playerid);
			CallLocalFunction("OnVehicleMissileChange", "iiii", id, oldmissile, pMissileID[playerid], playerid);
		}
		return 1;
	}
	if(PRESSED(KEY_ANALOG_DOWN) || HOLDING(KEY_ANALOG_DOWN))
	{
		if(pHUDStatus[playerid] == HUD_MISSILES)
		{
			new id = GetPlayerVehicleID(playerid), oldmissile = pMissileID[playerid];
			pMissileID[playerid] = getPreviousHUDSlot(playerid);
			CallLocalFunction("OnVehicleMissileChange", "iiii", id, oldmissile, pMissileID[playerid], playerid);
		}
		return 1;
	}
	return 1;
}
//case Energy_EMP, Energy_Mines, Energy_Shield, Energy_Invisibility,
//Missile_Fire, Missile_Homing, Missile_Power, Missile_Stalker, Missile_RemoteBomb, Missile_Ricochet: {}
StartEnvironmentalEvent(playerid)
{
	new vehicleid = GetPlayerVehicleID(playerid);
	Vehicle_Using_Environmental[vehicleid] = 1;
	SetPVarInt(playerid, "EnvironmentalCycle", 0);
	playerData[playerid][EnvironmentalCycle_Timer] = SetTimerEx("StartEnvironmentalCycle", 600, true, "dd", playerid, vehicleid);
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
			new Float:a, slot = GetFreeMissileSlot(playerid, vehicleid);

			GetObjectRot(HelicopterAttack, a, a, a);

			Vehicle_Missile[vehicleid][slot] = CreateObject(Missile_Default_Object, x, y, (z - 0.3), 0, 0, (a - 90.0), 300.0);
			Vehicle_Smoke[vehicleid][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);

			MoveObject(Vehicle_Missile[vehicleid][slot], vx, vy, z, MISSILE_SPEED);

			AttachObjectToObject(Vehicle_Smoke[vehicleid][slot], Vehicle_Missile[vehicleid][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

			SetObjectFaceCoords3D(HelicopterAttack, vx, vy, vz, 0.0, 180.0, 90.0);//22.0, 11.0, 180.0
			Vehicle_Missile_Following[vehicleid][slot] = v;

			CallLocalFunction("OnMissileFire", "iiiii", INVALID_PLAYER_ID, vehicleid, slot, Missile_Environmentals, Vehicle_Missile[vehicleid][slot]);
			break;
		}
	}
	if(GetPVarInt(playerid, "EnvironmentalCycle") > 12)
	{
		DeletePVar(playerid, "EnvironmentalCycle");
		Vehicle_Using_Environmental[vehicleid] = 0;
		KillTimer(playerData[playerid][EnvironmentalCycle_Timer]);
	}
	return 1;
}

SetObjectFaceCoords3D(iObject, Float: fX, Float: fY, Float: fZ, Float: fRollOffset = 0.0, Float: fPitchOffset = 0.0, Float: fYawOffset = 0.0)
{
	new Float: fOX, Float: fOY, Float: fOZ, Float: fPitch;
	GetObjectPos(iObject, fOX, fOY, fOZ);

	fPitch = floatsqroot(floatpower(fX - fOX, 2.0) + floatpower(fY - fOY, 2.0));
	fPitch = floatabs(atan2(fPitch, fZ - fOZ));

	fZ = atan2(fY - fOY, fX - fOX) - 90.0; // Yaw

	SetObjectRot(iObject, fRollOffset, fPitch + fPitchOffset, fZ + fYawOffset);
}

Float:GetMissileDamage(missileid, vehicleid = 0, alt_weapon = 0, mapid = -1)
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
					case TMC_JUNKYARD_DOG: damage = 35.0;
					case TMC_BRIMSTONE: damage = 45.0;
					case TMC_OUTLAW: damage = 1.0;
					case TMC_REAPER:
					{
						switch(alt_weapon)
						{
							case 1: damage = 150.0;
							default: damage = 65.0;
						}
					}
					case TMC_ROADKILL: damage = 15.0;
					case TMC_THUMPER: damage = 1.5;
					case TMC_SPECTRE: damage = 45.0;
					case TMC_DARKSIDE: damage = 0.0;
					case TMC_SHADOW:
					{
						switch(alt_weapon)
						{
							case 1: damage = 120.0;
							default: damage = 30.0;
						}
					}
					case TMC_MEATWAGON:
					{
						switch(alt_weapon)
						{
							case 1: damage = 90.0;
							default: damage = 40.0;
						}
					}
					case TMC_VERMIN:
					{
						switch(alt_weapon)
						{
							case 1: damage = 100.0;
							case 2: damage = 50.0;
							default: damage = 30.0;
						}
					}
					case TMC_3_WARTHOG:
					{
						switch(alt_weapon)
						{
							case 1: damage = 25.0;
							default: damage = 25.0;
						}
					}
					case TMC_MANSLAUGHTER: damage = 10.0;
					case TMC_SWEETTOOTH: damage = 5.0;
					case TMC_HAMMERHEAD: damage = 1.0;
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

Float:GetMissileExplosionRadius(missileid)
{
	#pragma unused missileid
	return 1.0;
}

Float:GetTwistedMetalMissileAccuracy(playerid = INVALID_PLAYER_ID, missileid, model = 0, alt_special = 0, justfired = 0)
{//higher accuracy = better homing
	new Float:accuracy = 1.0;
	switch(missileid)
	{
		case Missile_Special:
		{
			switch(model)
			{
				case TMC_3_WARTHOG: accuracy = 3.0;
				case TMC_ROADKILL, TMC_SPECTRE: accuracy = 4.0;
				case TMC_REAPER:
				{
					switch(alt_special)
					{
						case 2: accuracy = 4.0;
					}
				}
				case TMC_SWEETTOOTH: accuracy = 4.5;
				case TMC_MEATWAGON: accuracy = 2.0;
				case TMC_VERMIN: accuracy = 2.0;
			}
		}
		case Missile_Fire: accuracy = 5.0;
		case Missile_Homing: accuracy = 15.0;
		case Missile_Stalker: accuracy = playerData[playerid][pCharge_Index];
		case Missile_RemoteBomb: accuracy = 4.0;
		case Missile_Environmentals: accuracy = 15.0;
		case Energy_EMP: accuracy = 2.0;
	}
	if(justfired == 1) accuracy *= 6.0;
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

#define USE_SMOOTH_TURNS
PushVehicleToPosition(vehicleid, Float:x, Float:y, Float:z, Float:speed) // Gamer_Z & Mickey
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

Float:atan2VehicleZ(Float:Xb, Float:Yb, Float:Xe, Float:Ye)
{
	new Float:a = floatabs(360.0 - atan2( Xe - Xb, Ye - Yb ));
	return (360.0 > a > 180.0) ? a : (a - 360.0);
}

forward MoveDownLift(liftid);
public MoveDownLift(liftid)
{
	MovingLiftStatus[liftid] = 0;
	new Float:x, Float:y, Float:z;
	GetObjectPos(MovingLifts[liftid], x, y, z);
	MoveObject(MovingLifts[liftid], x, y, z - MovingLiftData[liftid][L_Move_Z_Index], MovingLiftData[liftid][L_Move_Speed]);
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
		for(new i = 0; i < sizeof(MovingLifts); ++i)
		{
			if(objectid == MovingLifts[i])
			{
				switch(MovingLiftStatus[i])
				{
					case 0:
					{
						DestroyPickup(MovingLiftPickup[i]);
						MovingLiftPickup[i] = CreatePickup(1247, 14, MovingLiftData[i][L_X], MovingLiftData[i][L_Y], MovingLiftData[i][L_Z] - 0.6, MovingLiftGameID[i]);
					}
					default: SetTimerEx("MoveDownLift", 5000, false, "i", i);
				}
				return 1;
			}
		}
		return 1;
	}
	new vehicleid = Object_Owner[objectid], playerid = Object_OwnerEx[objectid],
		missileid = Object_Type[objectid], slot = Object_Slot[objectid],
		Float:x, Float:y, Float:z;
	if(vehicleid != INVALID_VEHICLE_ID)
	{
		switch(missileid)
		{
			case Missile_Special:
			{
				if(pShadow_Count[playerid] != 0)
				{
					GetObjectPos(objectid, x, y, z);
					if(pShadow_Count[playerid] == sizeof(sData))
					{
						CreateExplosion(x, y, z, 1, 20.0);
						Object_Owner[Vehicle_Missile[vehicleid][slot]] = INVALID_VEHICLE_ID;
						Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = INVALID_PLAYER_ID;
						Object_Type[Vehicle_Missile[vehicleid][slot]] = -1;
						Object_Slot[Vehicle_Missile[vehicleid][slot]] = -1;
						DestroyObject(Vehicle_Missile[vehicleid][slot]);
						Vehicle_Missile[vehicleid][slot] = INVALID_OBJECT_ID;
						pShadow_Angle[playerid] = 0.0;
						pShadow_Count[playerid] = 0;
						return 1;
					}
					GetXYInFrontOfPoint( x, y, pShadow_Angle[playerid], sData[pShadow_Count[playerid]][FLIGHT_DISTANCE] );

					MoveObject(Vehicle_Missile[vehicleid][slot], x, y, z - sData[pShadow_Count[playerid] - 1][FLIGHT_HEIGHT] + sData[pShadow_Count[playerid]][FLIGHT_HEIGHT], GetVelocityXY(sData[pShadow_Count[playerid]][FLIGHT_VELOCITY][0], sData[pShadow_Count[playerid]][FLIGHT_VELOCITY][1]));
					++pShadow_Count[playerid];
					return 1;
				}
			}
			case Missile_Napalm:
			{
				new destroynapalm = GetPVarInt(Object_OwnerEx[objectid], "Dont_Destroy_Napalm");
				if(destroynapalm == 1)
				{
					GetObjectPos(objectid, x, y, z);
					slot = tNapalm_Slot[playerid];
					tNapalm_Slot[playerid] = -1;
					CreateMissileExplosion(vehicleid, Missile_Napalm, x, y, z, _);
					RadiusDamage(playerid, vehicleid, x, y, z, GetMissileDamage(missileid), missileid, 15.0);
					pFiring_Missile[playerid] = 0;
					Vehicle_Missile_Following[vehicleid][slot] = INVALID_VEHICLE_ID;
					Vehicle_Missile_Final_Angle[vehicleid][slot] = 0.0;
					DeletePVar(Object_OwnerEx[objectid], "Dont_Destroy_Napalm");
					Object_Owner[Vehicle_Missile[vehicleid][slot]] = INVALID_VEHICLE_ID;
					Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = INVALID_PLAYER_ID;
					Object_Type[Vehicle_Missile[vehicleid][slot]] = Object_Slot[Vehicle_Missile[vehicleid][slot]] = -1;
					EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_REMOVE);
					DestroyObject(Vehicle_Missile[vehicleid][slot]);
					Vehicle_Missile[vehicleid][slot] = INVALID_OBJECT_ID;
					for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
					{
						if(Vehicle_Missile_Lights_Attached[vehicleid][L] != slot) continue;
						if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
						{
							DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
							Vehicle_Missile_Lights[vehicleid][L] = INVALID_OBJECT_ID;
						}
					}
					if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
					{
						DestroyObject(Vehicle_Smoke[vehicleid][slot]);
						Vehicle_Smoke[vehicleid][slot] = INVALID_OBJECT_ID;
					}
					if(playerData[playerid][pMissiles][missileid] <= 0)
					{
						pMissileID[playerid] = getNextHUDSlot(playerid);
					}
					return 1;
				}
			}
			default: CallLocalFunction("UpdateMissile", "iiiiii", playerid, vehicleid, objectid, missileid, slot, Vehicle_Missile_Following[vehicleid][slot]);
		}
	}
	switch(Object_Type[objectid])
	{
		case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
		{
			if(Object_Slot[objectid] != -1)
			{
				DestroyObject(Vehicle_Machine_Gun[vehicleid][Object_Slot[objectid]]);
				Vehicle_Machine_Gun[vehicleid][Object_Slot[objectid]] = INVALID_OBJECT_ID;
				if(Object_Type[objectid] == Missile_Machine_Gun_Upgrade)
				{
					if(IsValidObject(Vehicle_Machine_Mega_Gun[vehicleid][Object_Slot[objectid]]))
					{
						DestroyObject(Vehicle_Machine_Mega_Gun[vehicleid][Object_Slot[objectid]]);
						Vehicle_Machine_Mega_Gun[vehicleid][Object_Slot[objectid]] = INVALID_OBJECT_ID;
					}
				}
			}
		}
		case Missile_Ricochet: return 1;
		default: CallLocalFunction("explodeMissile", "iiii", playerid, vehicleid, slot, missileid);
	}
	EditPlayerSlot(playerid, Object_Slot[objectid], PLAYER_MISSILE_SLOT_REMOVE);
	Object_Owner[objectid] = INVALID_VEHICLE_ID;
	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
	Object_Type[objectid] = Object_Slot[objectid] = -1;
	return 1;
}

Float:getMapLowestZEx(mapid, Float:x, Float:y, Float:cZ, &whichaxis = 0)
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
						-1145.5831, -459.9896, -1118.8612, -374.2502,
						-1134.6113, -241.7159, -1084.8250, -218.3002,
						-1139.4792, -109.4554, -1213.7091, -28.8316,
						-1155.9581, 31.0298, -1244.1909, 120.4091,
						-1184.6167, 179.4770, -1229.6351, 224.2526,
						-1054.9166, 397.1960, -1094.8671, 437.9679,
						-1684.9160, -154.5242, -1720.9116, -288.4950,
						-1732.5011, -427.1551, -1735.3436, -566.6928);
			if(point)
			{
				MapAndreas_FindZ_For2DCoord(x, y, z);
				if( z > cZ )
				{
					if(IsPointInPolygon(x, y,
					-1489.8970,-465.9743, -1420.2805,-421.4152,
					-1411.3307,-387.3859, -1395.1316,-387.4485,
					-1372.1550,-397.2090, -1372.1550,-405.7532,
					-1397.1353,-401.3542, -1406.9679,-427.8992,
					-1423.7266,-450.9918, -1446.8057,-468.6593,
					-1474.4912,-478.8586, -1488.5732,-481.0092))
					{
						z = 5.50;
					}
					else if(IsPointInPolygon(x, y, -1461.7700,-215.3291,
					-1433.9153,-122.7020, -1376.2902,-144.7513,
					-1415.0918,-231.4165, -1425.9885,-227.3817,
					-1409.6709,-182.2987, -1433.5980,-173.5414, -1450.2328,-218.3726)
					|| IsPointInPolygon(x, y, -1330.6299,-344.9863,
					-1333.9620,-334.7762, -1288.8632,-318.1987,
					-1297.1212,-294.7146, -1342.5748,-310.9069,
					-1347.7300,-299.9476, -1259.8358,-260.7970, -1238.5035,-319.4509))
					{
						z = 14.14;
					}
					else if(IsPointInPolygon(x, y, -1394.7711,-373.6178,
					-1396.8937,-358.8463, -1400.7649,-345.1499,
					-1406.5449,-332.7275, -1413.1406,-321.4689,
					-1437.8079,-297.7291, -1460.9878,-285.6641,
					-1488.3525,-279.7889, -1487.3295,-264.2761,
					-1455.9193,-271.1209, -1426.3719,-286.7276,
					-1401.9177,-311.2426, -1386.7657,-340.1027, -1379.5203,-371.9048))
					{
						z = 6.0;
					}
					else if(IsPointInPolygon(x, y, -1674.1277,-623.3311, -1684.9785,-619.0835,
					-1689.0922,-614.4486, -1693.9746,-614.4214, -1697.5449,-616.5976,
					-1698.0687,-624.9882, -1694.6058,-628.3465, -1678.1333,-634.1520))
					{
						z = 14.14;
					}
				}
			}
			else z = cZ + 5.0; //printf("x: %0.2f - y: %0.2f - points: %d", x, y, point);
		}
		case MAP_DOWNTOWN:
		{
			new Float:DowntownCantGoOutOfZAreas[1][4] = //MinX, MaxX, MinY, MaxY, MinZ, MaxZ
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
				{-1927.9543, -1885.1970, -1035.0299, -709.5599, 31.0000, 43.0},
				{-1983.9663, -1935.7401, -867.9561,  -849.6713, 31.2188, 40.9494},
				{-1964.5488, -1945.1086, -990.6176,  -727.0721, 35.4000, 40.9494},
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
					z = getMapLowestZ(mapid);
				}
			}
		}
		default: MapAndreas_FindZ_For2DCoord(x, y, z);
	}
	return z;
}

Float:MissileYSize()
{
	return 1.45;
}

new missileobject = INVALID_OBJECT_ID,
	missileattachedobject = INVALID_OBJECT_ID;

CMD:testmissile(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	if(IsValidObject(missileobject))
	{
		DestroyObject(missileobject);
		missileobject = INVALID_OBJECT_ID;
	}
	if(IsValidObject(missileattachedobject))
	{
		DestroyObject(missileattachedobject);
		missileattachedobject = INVALID_OBJECT_ID;
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

new debugmissiles = 0;

CMD:debugmissiles(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	debugmissiles = !debugmissiles;
	return 1;
}

new mu_id,
	mu_objectid,
	mu_vehicleid,
	pickup_update
;
	//mu_slot;
	
public OnMissileUpdate()
{
	//new starttick = GetTickCount(), endtick;
	foreach(Player, i)
	{
		if(playerData[i][pSpawned_Status] == 0 || playerData[i][gGameID] == INVALID_GAME_ID || pVehicleID[i] == 0) continue;
		mu_id = GetPlayerVehicleID(i);
		//for(mu_slot = 0; mu_slot < MAX_MISSILE_SLOTS; mu_slot++)
		foreach(pSlots_In_Use[i], mu_slot)
		{
			if(debugmissiles == 1)
			{
				printf("%s mu_slot: %d", playerName(i), mu_slot);
			}
			if(!IsValidObject(Vehicle_Missile[mu_id][mu_slot]) && !IsValidObject(Vehicle_Machine_Gun[mu_id][mu_slot]))
			{
				mu_slot = EditPlayerSlot(i, mu_slot, PLAYER_MISSILE_SLOT_REMOVE);
				continue;
			}
			mu_objectid = Vehicle_Missile[mu_id][mu_slot];
			if(IsValidObject(mu_objectid))
			{
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
					case -1:
					{
						DestroyObject(Vehicle_Missile[mu_id][mu_slot]);
						Vehicle_Missile[mu_id][mu_slot] = INVALID_OBJECT_ID;
						ResetMissile(pVehicleID[i], mu_slot);
						//CallLocalFunction("explodeMissile", "iiii", i, mu_id, mu_slot, missileid);
						continue;
					}
				}
				mu_vehicleid = Vehicle_Missile_Following[mu_id][mu_slot];
				if(mu_vehicleid != INVALID_VEHICLE_ID)
				{
					if(GetVehicleModel(mu_vehicleid) == 0)
					{
						printf("vehicle %d is not valid anymore - resetting", mu_vehicleid);
						Vehicle_Missile_Following[mu_id][mu_slot] = INVALID_VEHICLE_ID;
						Vehicle_Missile_Final_Angle[mu_id][mu_slot] = 0.0;
					}
				}
				if(Object_OwnerEx[mu_objectid] != i) // patch for: some sort of bug that causes the playerid owner to change
				{
					printf("[System Error: OnMissileUpdate] - Objectid: %d - Missileid: %d - pOwner: %d - vOwner: %d - slot: %d - i: %d - iv: %d", mu_objectid, Object_Type[mu_objectid], Object_OwnerEx[mu_objectid], Object_Owner[mu_objectid], mu_slot, i, pVehicleID[i]);
					Object_OwnerEx[mu_objectid] = i;
				}
				CallLocalFunction("UpdateMissile", "iiiiii", Object_OwnerEx[mu_objectid], mu_id, mu_objectid, Object_Type[mu_objectid], mu_slot, mu_vehicleid);
			}
			mu_objectid = Vehicle_Machine_Gun[mu_id][mu_slot];
			if(IsValidObject(mu_objectid))
			{
				if( Object_OwnerEx[mu_objectid] != i ) // patch for: some sort of bug that causes the playerid owner to change
				{
					printf("[System Error: OnMissileUpdate] - Objectid: %d - Missileid: %d - pOwner: %d - vOwner: %d - slot: %d - i: %d - iv: %d", mu_objectid, Object_Type[mu_objectid], Object_OwnerEx[mu_objectid], Object_Owner[mu_objectid], mu_slot, i, pVehicleID[i]);
					Object_OwnerEx[mu_objectid] = i;
				}
				CallLocalFunction("UpdateMissile", "iiiiii", Object_OwnerEx[mu_objectid], mu_id, mu_objectid, Object_Type[mu_objectid], mu_slot, INVALID_VEHICLE_ID);
			}
		}
	}
	if(++pickup_update == 2)
	{
		updateServerPickups();
		pickup_update = 0;
	}
	//endtick = GetTickCount() - starttick;
	//if(endtick > 1)
		//printf("OnMissileUpdate Tick: %d", endtick);
	return 1;
}

public UpdateMissile(playerid, id, objectid, missileid, slot, vehicleid)
{
	if(slot < 0 || slot >= MAX_MISSILE_SLOTS)
	{
		printf("[System: UpdateMissile - Slot Error (Out Of Bounds)] - Slot: %d", slot);
		return 1;
	}
	//if(!IsValidObject(objectid))
	//{
	//	SendClientMessageFormatted(playerid, -1, "objectid: %d - Invalid", objectid);
	//	return 1;
	//}
	//if(playerid < 0 || playerid >= MAX_PLAYERS)
	//{
	//    printf("[System: UpdateMissile - playerid Error (Out Of Bounds)] - playerid: %d - missileid: %s(%d)", playerid, GetTwistedMissileName(missileid), missileid);
	//    return 1;
	//}
	if(missileid < 0 || missileid >= MAX_DAMAGEABLE_MISSILES)
	{
		Object_Owner[objectid] = INVALID_VEHICLE_ID;
		Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
		Object_Type[objectid] = Object_Slot[objectid] = -1;
		EditPlayerSlot(playerid, Object_Slot[objectid], PLAYER_MISSILE_SLOT_REMOVE);
		DestroyObject(objectid);
		printf("[System: UpdateMissile - missileid Error (Out Of Bounds)] - missileid: %s(%d)", GetTwistedMissileName(missileid), missileid);
		return 1;
	}
	if(id < 0 || id > MAX_VEHICLES)
	{
		printf("[System: UpdateMissile - id Error (Out Of Bounds)] - id: %d - missileid: %s(%d)", id, GetTwistedMissileName(missileid), missileid);
		return 1;
	}
	//SendClientMessageFormatted(INVALID_PLAYER_ID, COLOR_RED, "[System] - Playerid: %d - Objectid: %d - Missileid: %d", playerid, objectid, missileid);
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
	mZ = getMapLowestZEx(gGameData[playerData[playerid][gGameID]][g_Map_id], oX, oY, oZ, axis);
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
					Vehicle_Machine_Gun[id][slot] = INVALID_OBJECT_ID;
				}
				if(IsValidObject(Vehicle_Machine_Mega_Gun[id][slot])) {
					DestroyObject(Vehicle_Machine_Mega_Gun[id][slot]);
					Vehicle_Machine_Mega_Gun[id][slot] = INVALID_OBJECT_ID;
				}
				return 1;
			}
			default: CallLocalFunction("explodeMissile", "iiii", playerid, id, slot, missileid);
		}
		return 1;
	}
	switch(missileid)
	{
		case Missile_Fire:
		{
			if(playerData[playerid][gGameID] != FREEROAM_GAME)
			{
				foreach(m_Destroyables[playerData[playerid][gGameID]], d)
				{
					new Float:m_oX, Float:m_oY, Float:m_oZ;
					GetObjectPos(Map_Objects[playerData[playerid][gGameID]][d], m_oX, m_oY, m_oZ);
					printf("[System: UpdateMissile] - m_Destroyables: %d - objectid: %d - radius: %0.2f - dis to obj: %0.4f", d, Map_Objects[playerData[playerid][gGameID]][d], GetColSphereRadius(m_Map_Positions[d][m_Model]), MPFDistance(oX, oY, oZ, m_oX, m_oY, m_oZ));
					if(MPFDistance(oX, oY, oZ, m_oX, m_oY, m_oZ) < GetColSphereRadius(m_Map_Positions[d][m_Model]))
					{
						DestroyObject(Map_Objects[playerData[playerid][gGameID]][d]);
						Map_Objects[playerData[playerid][gGameID]][d] = INVALID_OBJECT_ID;
						CreateMissileExplosion(id, missileid, x, y, z, _);
					}
				}
			}
		}
	}
	foreach(Vehicles, v)
	{
		if(v > MAX_VEHICLES || id == v) continue;
		model = GetVehicleModel(v);
		if(!model || !GetVehiclePos(v, vX, vY, vZ)) continue;
		player = Vehicle_Driver[v];
		if(debugmissiles == 1)
		{
			printf("%s slot: %d {checking vehicleid: %d} - player: %d - missileid: %d(%s)", playerName(playerid), slot, v, player, missileid, GetTwistedMissileName(missileid));
		}
		if(player != INVALID_VEHICLE_ID)
		{
			if(debugmissiles == 1)
			{
				printf("%s slot: %d {player gameid: %d - playerid gameid: %d}", playerName(playerid), slot, playerData[player][gGameID], playerData[playerid][gGameID]);
			}
			if(playerData[player][gGameID] != playerData[playerid][gGameID]) continue;
			switch(gGameData[playerData[player][gGameID]][g_Gamemode])
			{
				case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
				{
					if(playerData[player][gTeam] == playerData[playerid][gTeam]) continue;
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
					Vehicle_Machine_Gun[id][slot] = INVALID_OBJECT_ID;
					DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid), missileid);
					if(IsValidObject(Vehicle_Machine_Mega_Gun[id][slot]))
					{
						DestroyObject(Vehicle_Machine_Mega_Gun[id][slot]);
						Vehicle_Machine_Mega_Gun[id][slot] = INVALID_OBJECT_ID;
					}
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
				//sZ *= 0.8;
				tindex = ((oX * oX) + (oY * oY) + (oZ * oZ));
				if((-sX < oX < sX) && (-sY < oY < sY) || tindex < (4.0))
				{
					if((oZ > (sZ / 1.8) + 0.3)) continue;
					CreateMissileExplosion(id, missileid, x, y, z, _);
					Object_Owner[Vehicle_Missile[id][slot]] = INVALID_VEHICLE_ID;
					Object_OwnerEx[Vehicle_Missile[id][slot]] = INVALID_PLAYER_ID;
					Object_Type[Vehicle_Missile[id][slot]] = Object_Slot[Vehicle_Missile[id][slot]] = -1;
					DestroyObject(Vehicle_Missile[id][slot]);
					Vehicle_Missile[id][slot] = INVALID_OBJECT_ID;
					DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid), missileid);
					if(IsValidObject(Vehicle_Smoke[id][slot]))
					{
						DestroyObject(Vehicle_Smoke[id][slot]);
						Vehicle_Smoke[id][slot] = INVALID_OBJECT_ID;
					}
					return 1;
				}
				else continue;
			}
			default:
			{
				if(debugmissiles == 1)
				{
					printf("%s slot: %d {checking for collision}", playerName(playerid), slot);
				}
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
					if(debugmissiles == 1)
					{
						printf("%s slot: %d {collided}", playerName(playerid), slot);
					}
					if(IsValidObject(Vehicle_Missile[id][slot]))
					{
						Object_Owner[Vehicle_Missile[id][slot]] = INVALID_VEHICLE_ID;
						Object_OwnerEx[Vehicle_Missile[id][slot]] = INVALID_PLAYER_ID;
						Object_Type[Vehicle_Missile[id][slot]] = Object_Slot[Vehicle_Missile[id][slot]] = -1;
						DestroyObject(Vehicle_Missile[id][slot]);
						Vehicle_Missile[id][slot] = INVALID_OBJECT_ID;
					}
					Vehicle_Missile[id][slot] = INVALID_OBJECT_ID;
					switch(missileid)
					{
						case Energy_EMP:
						{
							new frozen = player;
							if(frozen != INVALID_VEHICLE_ID)
							{
								format(Global_KSXPString, sizeof(Global_KSXPString), "~g~~h~Frozen By %s", playerName(playerid));
								AddEXPMessage(frozen, Global_KSXPString);
								format(Global_KSXPString, sizeof(Global_KSXPString), "~y~~h~Froze %s", playerName(frozen));
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
								case TMC_REAPER:
								{
									CreateMissileExplosion(id, missileid, x, y, z, playerData[playerid][pSpecial_Using_Alt]);
									DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid, id, playerData[playerid][pSpecial_Using_Alt]), missileid, playerData[playerid][pSpecial_Using_Alt]);
									pFiring_Missile[playerid] = 0;
									Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
									Vehicle_Missile_Final_Angle[id][slot] = 0.0;
									if(playerData[playerid][pSpecial_Using_Alt] == 2)
									{
										for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
										{
											if(Vehicle_Missile_Lights_Attached[id][L] != slot) continue;
											if(IsValidObject(Vehicle_Missile_Lights[id][L]))
											{
												DestroyObject(Vehicle_Missile_Lights[id][L]);
												Vehicle_Missile_Lights[id][L] = INVALID_OBJECT_ID;
											}
										}
									}
									playerData[playerid][pSpecial_Using_Alt] = 0;
									return 1;
								}
								case TMC_BRIMSTONE:
								{
									CallRemoteFunction("OnBrimstoneFollowerHitVehicle", "iiiiifff", playerid, id, v, objectid, slot, x, y, z);
									return 1;
								}
								case TMC_SWEETTOOTH:
								{
									CreateMissileExplosion(id, missileid, x, y, z, _);
									DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid, id), missileid);
									Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
									Vehicle_Missile_Final_Angle[id][slot] = 0.0;
									if(playerData[playerid][pMissileSpecialUpdate] == MAX_SWEETTOOTH_MISSILES)
										pFiring_Missile[playerid] = 0;
									return 1;
								}
							}
						}
						case Missile_Napalm: z -= 1.95;
					}
					CreateMissileExplosion(id, missileid, x, y, z, _);
					DamagePlayer(playerid, id, player, v, GetMissileDamage(missileid, id), missileid, gGameData[playerData[playerid][gGameID]][g_Map_id]);
					pFiring_Missile[playerid] = 0;
					Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
					Vehicle_Missile_Final_Angle[id][slot] = 0.0;
					if(IsValidObject(Vehicle_Smoke[id][slot]))
					{
						DestroyObject(Vehicle_Smoke[id][slot]);
						Vehicle_Smoke[id][slot] = INVALID_OBJECT_ID;
					}
					for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
					{
						if(Vehicle_Missile_Lights_Attached[id][L] != slot) continue;
						if(IsValidObject(Vehicle_Missile_Lights[id][L]))
						{
							DestroyObject(Vehicle_Missile_Lights[id][L]);
							Vehicle_Missile_Lights[id][L] = INVALID_OBJECT_ID;
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
			attachMissileTargetCircle(TARGET_CIRCLE_ATTACHING, Vehicle_Missile[id][slot], slot, id, attachz, s_oX, s_oY, s_oZ);
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
		//printf("%s(%d)'s %s missile being homed to vehicleid: %d", playerName(playerid), playerid, GetTwistedMissileName(missileid), vehicleid);
		new Float:ompos[3], Float:Old_Missile_Angle, Float:newangle, Float:difference;
		GetVehiclePos(vehicleid, x, y, z);
		GetObjectPos(objectid, ompos[0], ompos[1], ompos[2]);
		GetObjectRot(objectid, Old_Missile_Angle, Old_Missile_Angle, Old_Missile_Angle);

		newangle = Angle2D( ompos[0], ompos[1], x, y ) - 90.0;
		MPClamp360(newangle);
		difference = (newangle - Old_Missile_Angle);
		if(difference == 0) return 1;
		if(debugmissiles == 1)
		{
			printf("%s slot: %d {checking for accuracy}", playerName(playerid), slot);
		}
		//printf("%s difference: %0.2f", GetTwistedMissileName(missileid), difference);
		if( !((newangle - 45.0) <= Vehicle_Missile_Final_Angle[vehicleid][slot] <= (newangle + 45.0)))
		{
			if(difference < GetTwistedMetalMissileAccuracy(playerid, missileid, GetVehicleModel(id), playerData[playerid][pSpecial_Using_Alt]))
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
				Vehicle_Missile_Final_Angle[vehicleid][slot] = newangle;
			}
			else
			{
				Vehicle_Missile_Following[id][slot] = INVALID_VEHICLE_ID;
				Vehicle_Missile_Final_Angle[vehicleid][slot] = 0.0;
			}
		}
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

CMD:resetworldbounds(playerid, params[])
{
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	return 1;
}

CMD:debugworldbounds(playerid, params[])
{
	SendClientMessageFormatted(playerid, -1, "%0.2f, %0.2f, %0.2f, %0.2f", s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_max_X], s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_min_X],
	s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_max_Y], s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_min_Y]);
	return 1;
}

CMD:attachv(playerid, params[])
{
	new vehicleid;
	if(sscanf(params, "i", vehicleid)) return 1;
	AttachTrailerToVehicle(vehicleid, pVehicleID[playerid]);
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid)));
	SetVehicleHealth(vehicleid, MAX_VEHICLE_HEALTH);
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
	Vehicle_Driver[vehicleid] = INVALID_PLAYER_ID;
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	if(GetPVarInt(forplayerid, "Junkyard_Dog_Attach") == playerData[forplayerid][pSpecial_Missile_Vehicle])
		AttachTrailerToVehicle(playerData[forplayerid][pSpecial_Missile_Vehicle], GetPlayerVehicleID(forplayerid));

	if(pVehicleID[forplayerid] == vehicleid)
	{
		if(!IsPlayerInVehicle(forplayerid, pVehicleID[forplayerid]))
		{
			if(playerData[forplayerid][CanExitVeh] == 0 && playerData[forplayerid][pSpawned_Status] == 1)
			{
				if(GetPlayerState(forplayerid) == PLAYER_STATE_ONFOOT)
				{
					PutPlayerInVehicle(forplayerid, pVehicleID[forplayerid], 0);
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

islegalcarmod(vehicleide, componentid) {
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
		printf("[System: OnVehicleMod - Warning] Name: %s(%d) - Vehicleid: %d - Model: %d - Componentid: %d", playerName(playerid), playerid, vehicleid, vehicleide, componentid);
		messageAdmins(COLOR_ADMIN, "[System: invalid mod] %s(%d) - v: %d(%d) - c: %d", pName[playerid], playerid, vehicleid, vehicleide, componentid);
		//strins(string, "10", 0, sizeof(string));
		//IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, string);
		RemoveVehicleComponent(vehicleid, componentid);
		if(!GetPVarInt(playerid, "c_Invalid_Mods_Time"))
		{
			SetPVarInt(playerid, "c_Invalid_Mods_Time", GetTickCount());
		}
		SetPVarInt(playerid, "c_Invalid_Mods", GetPVarInt(playerid, "c_Invalid_Mods") + 1);
		if(GetPVarInt(playerid, "c_Invalid_Mods") > 3 && (GetTickCount() - GetPVarInt(playerid, "c_Invalid_Mods_Time")) > 250)
		{
			DeletePVar(playerid, "c_Invalid_Mods_Time");
			format(gString, sizeof(gString), "SERVER BAN: %s(%d) Has Been Banned From The Server - Reason: Vehicle Mods Hack.", playerName(playerid), playerid);
			SendClientMessageToAll(PINK, gString);
			//IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, gString);
			//IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, gString);
			SendClientMessage(playerid, -1, "You Have Been Banned For Attempting To Hack Vehicle Modifications");
			BanEx(playerid, "Vehicle Mods Hack");
		}
		return 0;
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(!playerData[playerid][CanExitVeh])
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
	return 1;
}

promptMissileFire(playerid, missileid)
{
	if(missileid == Missile_Machine_Gun) return 1;
	if(playerData[playerid][pMissiles][missileid] == 0) return 0;
	if(pFiring_Missile[playerid] == 1) return 1;
	if(--playerData[playerid][pMissiles][missileid] == 0 && missileid != Missile_Napalm) {
		pMissileID[playerid] = getNextHUDSlot(playerid);
	} else {
		updatePlayerHUD(playerid, missileid);
	}
	return 1;
}

public OnMissileFire(playerid, vehicleid, slot, missileid, objectid)
{
	//SendClientMessageFormatted(playerid, -1, "OnMissileFire: %d (objectid: %d) - slot: %d", Vehicle_Missile[vehicleid][slot], objectid, slot);
	//printf("[System: OnMissileFire] - Vehicleid: %d - Slot: %d - Missile: %s", vehicleid, slot, GetTwistedMissileName(missileid));
	//PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Missile_Sound.mp3");
	if(objectid != INVALID_OBJECT_ID)
	{
		Object_Owner[objectid] = vehicleid;
		Object_OwnerEx[objectid] = playerid;
		Object_Type[objectid] = missileid;
		Object_Slot[objectid] = slot;
		EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
	}
	if(missileid < MAX_MISSILEID)
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
				return 1;
			}
			case Missile_Special:
			{
				switch(GetVehicleModel(vehicleid))
				{
					case TMC_3_WARTHOG:
					{
						if(playerData[playerid][pMissileSpecialUpdate] == MAX_WARTHOG_MISSILES)
						{
							playerData[playerid][pMissileSpecialUpdate] = 0;
						}
						else return 1;
					}
					case TMC_SWEETTOOTH:
					{
						if(playerData[playerid][pMissileSpecialUpdate] == MAX_SWEETTOOTH_MISSILES)
						{
							playerData[playerid][pMissileSpecialUpdate] = 0;
						}
						else return 1;
					}
				}
			}
		}
	}
	else
	{
		if(missileid == Missile_Machine_Gun_Upgrade)
		{
			if( --playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] == 0) // && newkeys & (MACHINE_GUN_KEY)
			{
				KillTimer(Machine_Gun_Firing_Timer[playerid]);
				new update_index = 285;
				Machine_Gun_Firing_Timer[playerid] = SetTimerEx("fireMissile", update_index, true, "iii", playerid, vehicleid, Missile_Machine_Gun);
				PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
				PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
			}
			else
			{
				new idx[4];
				valstr(idx, playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade], false);
				PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], idx);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
			}
		}
	}
	return 1;
}

public explodeMissile(playerid, vehicleid, slot, missileid)
{
	//printf("[System: explodeMissile] - playerid: %d - vehicleid: %d - slot: %d - missileid: %s", playerid, vehicleid, slot, GetTwistedMissileName(missileid));
	switch(missileid)
	{
		case Missile_Special:
		{
			switch(GetVehicleModel(vehicleid))
			{
				case TMC_SWEETTOOTH:
				{
					if(playerData[playerid][pMissileSpecialUpdate] == MAX_SWEETTOOTH_MISSILES)
						pFiring_Missile[playerid] = 0;
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
		//SendClientMessageFormatted(playerid, -1, "explodeMissile: %d - slot: %d", Vehicle_Missile[vehicleid][slot], slot);
		Object_Owner[Vehicle_Missile[vehicleid][slot]] = INVALID_VEHICLE_ID;
		Object_OwnerEx[Vehicle_Missile[vehicleid][slot]] = INVALID_PLAYER_ID;
		Object_Type[Vehicle_Missile[vehicleid][slot]] = Object_Slot[Vehicle_Missile[vehicleid][slot]] = -1;
		DestroyObject(Vehicle_Missile[vehicleid][slot]);
		Vehicle_Missile[vehicleid][slot] = INVALID_OBJECT_ID;
	}
	if(Vehicle_Missile[vehicleid][slot] != INVALID_OBJECT_ID)
	{
		Vehicle_Missile[vehicleid][slot] = INVALID_OBJECT_ID;
	}
	if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
	{
		DestroyObject(Vehicle_Smoke[vehicleid][slot]);
		Vehicle_Smoke[vehicleid][slot] = INVALID_OBJECT_ID;
	}
	for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
	{
		if(Vehicle_Missile_Lights_Attached[vehicleid][L] != slot) continue;
		if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
		{
			DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
			Vehicle_Missile_Lights[vehicleid][L] = INVALID_OBJECT_ID;
		}
	}
	Vehicle_Missile_Reset_Fire_Time[vehicleid] = 0;
	Vehicle_Missile_Reset_Fire_Slot[vehicleid] = -1;
	if(Vehicle_Missile_Following[vehicleid][slot] != INVALID_VEHICLE_ID)
	{
		Vehicle_Missile_Following[vehicleid][slot] = INVALID_VEHICLE_ID;
		Vehicle_Missile_Final_Angle[vehicleid][slot] = 0.0;
	}
	CreateMissileExplosion(vehicleid, missileid, x, y, z, _);
	PlayerPlaySound(playerid, 1159, x, y, z);
	return 1;
}


forward Charge_Missile(playerid, id, missileid);
public Charge_Missile(playerid, id, missileid)
{
	if(playerData[playerid][pCharge_Index] <= 0.0)
	{
		KillTimer(playerData[playerid][pCharge_Timer]);
		pFiring_Missile[playerid] = 0;
		playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
		playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
		SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], playerData[playerid][pCharge_Index]);
		HidePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
		GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~Stalker Overheated", 1500, 3);
		return 1;
	}
	playerData[playerid][pCharge_Index] -= 1.0;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], playerData[playerid][pCharge_Index]);
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
	return 1;
}

forward OnVehicleMissileChange(vehicleid, oldmissile, newmissile, playerid);
public OnVehicleMissileChange(vehicleid, oldmissile, newmissile, playerid)
{
	if(playerData[playerid][pMissiles][oldmissile] > 0)
	{
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][oldmissile], 100);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileSign][oldmissile]);
		if(pHUDType[playerid] == HUD_TYPE_TMPS3)
		{
			PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileImages][oldmissile], 100);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileImages][oldmissile]);
		}
	}
	if(playerData[playerid][pMissiles][newmissile] > 0)
	{
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][newmissile], 0x00FF00FF);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileSign][newmissile]);
		if(pHUDType[playerid] == HUD_TYPE_TMPS3)
		{
			PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileImages][newmissile], getMissileColour(newmissile));
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileImages][newmissile]);
		}
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
	if(playerData[playerid][pMissile_Charged] == oldmissile)
	{
		pFiring_Missile[playerid] = 0;
		playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
		KillTimer(playerData[playerid][pCharge_Timer]);
	}
	//SendClientMessageFormatted(playerid, -1, "New Missile: %s - Ammo: %d - Missileid: %d - Old Missile: %s", GetTwistedMissileName(newmissile, newmissile), playerData[playerid][pMissiles][newmissile], newmissile, GetTwistedMissileName(oldmissile, oldmissile));
	if(playerData[playerid][pMissile_Charged] != INVALID_MISSILE_ID
		|| playerData[playerid][pMissile_Special_Time] != 0)
	{
		playerData[playerid][pMissile_Special_Time] = 0;
		playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
	}
	if(pFiring_Missile[playerid] == TMC_REAPER)
	{
		pFiring_Missile[playerid] = 0;
		RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Index);
		if(playerData[playerid][pSpecial_Using_Alt] == 1)
		{
			RemovePlayerAttachedObject(playerid, Reaper_Chainsaw_Flame_Index);
			playerData[playerid][pSpecial_Using_Alt] = 0;
		}
		GameTextForPlayer(playerid, " ", 1, 3);
	}
	return 1;
}

ResetMissile(vehicleid, slot)
{
	if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
	{
		DestroyObject(Vehicle_Smoke[vehicleid][slot]);
		Vehicle_Smoke[vehicleid][slot] = INVALID_OBJECT_ID;
	}
	for(new L = 0; L < MAX_MISSILE_LIGHTS; L++)
	{
		if(Vehicle_Missile_Lights_Attached[vehicleid][L] != slot) continue;
		if(IsValidObject(Vehicle_Missile_Lights[vehicleid][L]))
		{
			DestroyObject(Vehicle_Missile_Lights[vehicleid][L]);
			Vehicle_Missile_Lights[vehicleid][L] = INVALID_OBJECT_ID;
		}
	}
	Vehicle_Missile_Reset_Fire_Time[vehicleid] = 0;
	Vehicle_Missile_Reset_Fire_Slot[vehicleid] = -1;
	if(Vehicle_Missile_Following[vehicleid][slot] != INVALID_VEHICLE_ID)
	{
		Vehicle_Missile_Following[vehicleid][slot] = INVALID_VEHICLE_ID;
		Vehicle_Missile_Final_Angle[vehicleid][slot] = 0.0;
	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return 0;
	//printf("[System: OnPlayerPickUpPickup] - Pickupid: %d", pickupid);
	new gameid = playerData[playerid][gGameID];
	if(gameid == INVALID_GAME_TEAM) return 0;
	if(gGameData[gameid][g_Has_Moving_Lift] == true)
	{
		for(new i = 0; i < sizeof(MovingLiftPickup); ++i)
		{
			if(pickupid == MovingLiftPickup[i] && MovingLiftStatus[i] == 0)
			{
				MovingLiftStatus[i] = 1;
				new Float:x, Float:y, Float:z;
				GetObjectPos(MovingLifts[i], x, y, z);
				MoveObject(MovingLifts[i], x, y, z + MovingLiftData[i][L_Move_Z_Index], MovingLiftData[i][L_Move_Speed]);
				return 1;
			}
		}
	}
	new spickupid = -1, bool:iterpickup = false, syncweapon;
	foreach(m_Map_Pickups[gameid], ipickup)
	{
		if(m_Pickup_Data[gameid][ipickup][Pickupid] != pickupid) continue;
		spickupid = ipickup;
		break;
	}
	if(spickupid == -1 || m_Pickup_Data[gameid][spickupid][Created] == false) return 1;
	if(GetPlayerMissileCount(playerid) == 0)
	{
		++syncweapon;
	}
	switch(m_Pickup_Data[gameid][spickupid][Pickuptype])
	{
		case PICKUPTYPE_HEALTH:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "30 Percent Health Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "30% Health Pickup", 5000);
			new Float:health, vehicleid = GetPlayerVehicleID(playerid), Float:maxhealth, Float:plushealth;
			maxhealth = GetTwistedMetalMaxHealth(GetVehicleModel(vehicleid));
			T_GetVehicleHealth(vehicleid, health);
			if(health >= maxhealth)
			{
				DestroyPickup(pickupid);
				m_Pickup_Data[gameid][spickupid][Created] = false;
				SetTimerEx("respawnServerPickup", 2000, false, "iii", gameid, spickupid, m_Pickup_Data[gameid][spickupid][Pickuptype]);
				TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Health Bay Full", 4000);
				return 1;
			}
			plushealth = (30 * maxhealth) / 100;
			health += plushealth;
			health = (health > maxhealth) ? maxhealth : health;
			T_SetVehicleHealth(vehicleid, health);
		}
		case PICKUPTYPE_TURBO:
		{
			new model = GetVehicleModel(pVehicleID[playerid]);
			if(playerData[playerid][pTurbo] >= floatround(GetTwistedMetalMaxTurbo(model)))
			{
				DestroyPickup(pickupid);
				m_Pickup_Data[gameid][spickupid][Created] = false;
				SetTimerEx("respawnServerPickup", 2000, false, "iii", gameid, spickupid, m_Pickup_Data[gameid][spickupid][Pickuptype]);
				TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Turbo Bay Full", 4000);
				return 1;
			}
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Turbo Picked Up");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Turbo Recharge", 5000);
			playerData[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], GetTwistedMetalMaxTurbo(model));
			UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
		}
		case PICKUPTYPE_MACHINE_GUN_UPGRADE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Machine Gun Upgrade Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Machine Gun Upgrade", 5000);
			playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] += 150;
			if(playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] > 300)
			{
				playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 300;
			}
			new idx[4];
			valstr(idx, playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade], false);
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][Mega_Gun_IDX], idx);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
		}
		case PICKUPTYPE_HOMING_MISSILE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Homing Missiles Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Homing Missiles Picked Up", 5000);
			playerData[playerid][pMissiles][Missile_Homing] += 2;
		}
		case PICKUPTYPE_FIRE_MISSILE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Fire Missiles Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Fire Missiles Picked Up", 5000);
			playerData[playerid][pMissiles][Missile_Fire] += 2;
		}
		case PICKUPTYPE_POWER_MISSILE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Power Missiles Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Power Missiles Picked Up", 5000);
			++playerData[playerid][pMissiles][Missile_Power];
		}
		case PICKUPTYPE_NAPALM_MISSILE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Napalm Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Napalm Picked Up", 5000);
			playerData[playerid][pMissiles][Missile_Napalm] += 2;
		}
		case PICKUPTYPE_STALKER_MISSILE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Stalker Missile Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Stalker Missile Picked Up", 5000);
			++playerData[playerid][pMissiles][Missile_Stalker];
		}
		case PICKUPTYPE_RICOCHETS_MISSILE:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Ricochet Missiles Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Ricochet Missiles Picked Up", 5000);
			playerData[playerid][pMissiles][Missile_Ricochet] += 2;
		}
		case PICKUPTYPE_REMOTEBOMBS:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Remote Bomb Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Remote Bomb Picked Up", 5000);
			++playerData[playerid][pMissiles][Missile_RemoteBomb];
		}
		case PICKUPTYPE_ENVIRONMENTALS:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Environment Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Environment Pickup", 5000);
			++playerData[playerid][pMissiles][Missile_Environmentals];
		}
		case PICKUPTYPE_LIGHTNING:
		{
			iterpickup = true;
			SendClientMessage(playerid, GetPlayerColor(playerid), "Lightning Pickup");
			TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Lightning Picked Up", 5000);
			++playerData[playerid][pMissiles][Missile_Lightning];
		}
	}
	if(iterpickup == true)
	{
		DestroyPickup(pickupid);
		DisablePlayerCheckpoint(playerid);
		m_Pickup_Data[gameid][spickupid][Created] = false;
		SetTimerEx("respawnServerPickup", 25000, false, "iii", gameid, spickupid, m_Pickup_Data[gameid][spickupid][Pickuptype]);
		if(syncweapon)
		{
			pMissileID[playerid] = getNextHUDSlot(playerid);
		}
		else updatePlayerHUD(playerid);
	}
	if(GetPVarInt(playerid, "Pickup_Deletion_Mode") == 1)
	{
		SendClientMessageFormatted(playerid, -1, ""#cSAMPRed"Pickup Deleted: "#cWhite"Map: %s(%d) - %d - x: %0.4f - y: %0.4f - z: %0.4f", s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Name], gGameData[playerData[playerid][gGameID]][g_Map_id], m_Pickup_Data[gameid][spickupid][Pickuptype], m_Pickup_Data[gameid][spickupid][PickupX], m_Pickup_Data[gameid][spickupid][PickupY], m_Pickup_Data[gameid][spickupid][PickupZ]);
		format(gQuery, sizeof(gQuery), "DELETE FROM "#mySQL_Maps_Pickups_Table" WHERE `Mapid` = %d AND `Pickup_Type` = %d AND `x` = %0.4f AND `y` = %0.4f AND `z` = %0.4f LIMIT 1", gGameData[playerData[playerid][gGameID]][g_Map_id], m_Pickup_Data[gameid][spickupid][Pickuptype], m_Pickup_Data[gameid][spickupid][PickupX], m_Pickup_Data[gameid][spickupid][PickupY], m_Pickup_Data[gameid][spickupid][PickupZ]);
		mysql_tquery(mysqlConnHandle, gQuery);
		DestroyPickupEx(gameid, spickupid);
	}
	return 1;
}

CMD:changegunsize(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new Float:sx, Float:sy;
	if(sscanf(params, "F(17.0)F(17.0)", sx, sy)) return SendClientMessage(playerid, -1, "/changegunsize sx sy");
	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][Mega_Gun_Sprite], sx, sy); // 16.000, 13.000
	PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
	SendClientMessageFormatted(playerid, -1, "sx: %0.1f - sy: %0.1f", sx, sy);
	return 1;
}

CMD:changegunrot(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new Float:rx, Float:ry, Float:rz;
	if(sscanf(params, "F(345.0)F(30.0)F(45.0)", rx, ry, rz)) return SendClientMessage(playerid, -1, "/changegunrot rx ry rz");
	PlayerTextDrawSetPreviewRot(playerid, pTextInfo[playerid][Mega_Gun_Sprite], rx, ry, rz);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
	SendClientMessageFormatted(playerid, -1, "rx: %0.1f - ry: %0.1f - rz: %0.1f", rx, ry, rz);
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
	if(!canPlayerChat(playerid)) return 0;
	new pText[144];
	format(pText, sizeof(pText), "%s", text);
	if (text[0] == '@' || text[0] == '!')
	{
		if(isServerAdmin(playerid))
		{
			messageAdmins(_, "(Admin Chat) %s(%d): "#cWhite"%s", playerName(playerid), playerid, pText[1]);
			format(gString, sizeof(gString), "03(Admin Chat)01 %s(%d): %s", playerName(playerid), playerid, pText[1]);
			IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, gString);
			return 0;
		}
	}
	if (text[0] == '#')
	{
		if(playerData[playerid][pDonaterRank])
		{
			foreach(Player, i)
			{
				if(playerData[i][pDonaterRank] > 0)
					SendClientMessageFormatted(i, 0x00FFFFFF, "(Donor Chat) %s(%d): %s", playerName(playerid), playerid, pText[1]);
			}
			IRC_GroupSayFormatted(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, "11(Donor Chat)01 %s(%d): %s", playerName(playerid), playerid, pText[1]);
			return 0;
		}
	}
	new chat[144 + 24];
	format(chat, sizeof(chat), "%s(%d): %s", playerName(playerid), playerid, pText);
	IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, chat);
	IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, chat);
	
	new to_others[MAX_CHATBUBBLE_LENGTH + 1];
	format(to_others, MAX_CHATBUBBLE_LENGTH, "%s(%d) Says: %s", playerName(playerid), playerid, pText);
	SetPlayerChatBubble(playerid, to_others, ROYALBLUE, 35.0, 7000);
	return 1;
}

canPlayerChat(playerid)
{
	if(!isServerAdmin(playerid)) {
		new tick_count = GetTickCount();
		if((tick_count - playerData[playerid][pLast_Chat_Tick]) < 550) {
			SendClientMessage(playerid, COLOR_RED, "[WARNING: Anti-Spam]: Please Wait Before Attempting To Chat Again.");
			return 0;
		}
		playerData[playerid][pLast_Chat_Tick] = tick_count;
	}
	if(mysqlConnHandle > 0 && !GetPVarInt(playerid, "pCanTalk") && IsPlayerAdmin(playerid) == 0) {
		SendClientMessage(playerid, COLOR_RED, "Please Login Before Trying to Speak.");
		return 0;
	}
	if(bPlayerGameSettings[playerid] & gMuted) { //  && !pMenu_Status[playerid]
		SendClientMessage(playerid, COLOR_RED, "You Are Muted - You Cannot Talk!");
		return 0;
	}
	return 1;
}

CMD:applyanimation(playerid, params[])
{
	new animlib[32], animname[32];
	if(sscanf(params, "s[32]s[32]", animlib, animname)) return SendClientMessage(playerid, -1, "Syntax: /Applyanimation [Animlib] [Animname]");
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
		printf("%s(%d) Animation: %s - %s", playerName(playerid),playerid,animlib, animname);
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

CMD:velocity(playerid, params[])
{
	new Float:x, Float:y, Float:z, id;
	if(sscanf(params, "fffD(%d)", x, y, z, id, playerid)) return SendClientMessage(playerid, 0xFFFFFFFF, "Syntax: /velocity [x, y, z] [playerid]");
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
		for(new i; i != 15; ++i) TextDrawShowForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
		for(new i; i < Speedometer_Needle_Index; ++i) TextDrawShowForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
	}
	else
	{
		for(new i; i < Speedometer_Needle_Index; ++i) TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
		for(new i; i != 15; ++i) TextDrawHideForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
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
	if(vehicleid == INVALID_VEHICLE_ID || vehicleid == 0) return SendClientMessage(playerid, COLOR_RED, "Error: You Cannot Use This Command While Onfoot");
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
	if(vehicleid == INVALID_VEHICLE_ID || vehicleid == 0) return SendClientMessage(playerid, COLOR_RED, "Error: You Cannot Use This Command While Onfoot");
	new engine,lights,alarm,doors,bonnet,boot,objective;
	GetVehicleParamsEx(vehicleid,engine,lights,alarm,doors,bonnet,boot,objective);
	if(doors == VEHICLE_PARAMS_UNSET || doors == VEHICLE_PARAMS_OFF) SetVehicleParamsEx(vehicleid,engine,lights,alarm,VEHICLE_PARAMS_ON,bonnet,boot,objective);
	else SetVehicleParamsEx(vehicleid,engine,lights,alarm,VEHICLE_PARAMS_OFF,bonnet,boot,objective);
	return 1;
}

CMD:hold(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new oid, bid, Float:a[9], colour[2];
	a[6] = a[7] = a[8] = 1.0;
	if(sscanf(params, "ddF(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(1.0)F(1.0)F(1.0)H(0)H(0)", oid, bid, a[0], a[1], a[2], a[3], a[4], a[5],a[6], a[7], a[8], colour[0], colour[1]))
	{
		SendClientMessage(playerid, COLOR_WHITE, "Syntax: /hold [Objectid] [Boneid 1-18] [fOffSetX] [fOffSetY] [fOffSetZ] [fRotX] [fRotY] [fRotZ] [fScaleX] [fScaleY] [fScaleZ] [Colour1] [Colour2]"),
		SendClientMessage(playerid, COLOR_WHITE, "1: Spine | 2: Head | 3: Left Upper Arm | 4: Right Upper Arm | 5: Left Hand | 6: Right Hand"),
		SendClientMessage(playerid, COLOR_WHITE, "7: Left thigh | 8: Right thigh | 9: Left foot | 10: Right foot | 11: Right calf | 12: Left calf"),
		SendClientMessage(playerid, COLOR_WHITE, "13: Left forearm | 14: Right forearm | 15: Left clavicle | 16: Right clavicle | 17: Neck | 18: Jaw");
		return 1;
	}
	SetPlayerAttachedObject(playerid, 0, oid, bid, a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], colour[0], colour[1]);
	return 1;
}

CMD:btest(playerid,params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new Float:a[6], index, id, str[7], Float:angle;
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
		SendClientMessage(playerid, COLOR_RED, "{1E90FF}/btest [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n"#cWhite"Position and index are optional.");
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
		//printf("btest - xsin: %f - x+sin: %f - x: %f - y: %f - z: %f", floatsin(-angle, degrees), (a[0] * floatsin(angle, degrees)), x + (a[0] * floatsin(angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2]);
	}
	GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
	SetPVarInt(playerid, str, CreateObject(id, x + (a[0] * floatsin(-angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2], a[3], a[4], angle + a[5], 100.0));
	return 1;
}

CMD:holdvex(playerid,params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new Float:a[6],index,id,str[8];
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
		SendClientMessage(playerid, COLOR_RED, "{1E90FF}/holdvex [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n"#cWhite"Position and index are optional.");
		return 1;
	}
	format(str, sizeof(str), "obvex-%d", index);
	new Float:x, Float:y, Float:z;
	if(GetPVarInt(playerid, str) != 0)
	{
		new o = GetPVarInt(playerid, str);
		DestroyObject(o);
	}
	GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
	SetPVarInt(playerid, str, CreateObject(id, x + a[0], y + a[1], z + a[2], a[3], a[4], a[5], 100.0));
	return 1;
}

CMD:holdv(playerid,params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new Float:a[6],index,id,str[6];
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
		SendClientMessage(playerid, COLOR_RED, "{1E90FF}/holdv [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n"#cWhite"Position and index are optional.");
		return 1;
	}
	format(str, sizeof(str), "obv-%d", index);
	if(GetPVarInt(playerid, str) != 0)
	{
		new o = GetPVarInt(playerid, str);
		DestroyObject(o);
	}
	SetPVarInt(playerid, str, CreateObject(id, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0));
	AttachObjectToVehicle(GetPVarInt(playerid, str), GetPlayerVehicleID(playerid), a[0], a[1], a[2], a[3], a[4], a[5]);
	SendClientMessageFormatted(playerid, -1, "[System] - Holdv - Objectid %d", GetPVarInt(playerid, str));
	return 1;
}

CMD:attach(playerid,params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new oid,Float:a[6],str[6],index;
	if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", oid, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
		SendClientMessage(playerid, COLOR_RED, "{1E90FF}/attach [objectid] [index] [OffSetX] [OffSetY] [OffSetZ] [rX] [rY] [rZ]");
		return 1;
	}
	format(str, sizeof(str), "ob-%d", index);
	if(GetPVarInt(playerid, str) != 0)
	{
		new o = GetPVarInt(playerid, str);
		DestroyObject(o);
	}
	SetPVarInt(playerid, str, CreateObject(oid,0.0,0.0,0.0,0.0,0.0,0.0,200.0));
	AttachObjectToPlayer(GetPVarInt(playerid, str),playerid,a[0],a[1],a[2],a[3],a[4],a[5]);
	return 1;
}

CMD:reset(playerid, params[])
{
	pFiring_Missile[playerid] = 0;
	return 1;
}
CMD:machine(playerid, params[])
{
	attachVehicleMachineGuns(GetPlayerVehicleID(playerid), Missile_Machine_Gun);
	SendClientMessage(playerid, 0xFFFFFFFF, "Machine Gun Added");
	return 1;
}
CMD:special(playerid, params[])
{
	new Specials = 1;
	if(sscanf(params, "D(1)", Specials)) return SendClientMessage(playerid, COLOR_RED, "/Special [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Special Missile Added");
	playerData[playerid][pMissiles][Missile_Special] += Specials;
	return 1;
}
CMD:fire(playerid, params[])
{
	new Fires;
	if(sscanf(params, "D(2)", Fires)) return SendClientMessage(playerid, COLOR_RED, "/Fire [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Fire Missile Added");
	playerData[playerid][pMissiles][Missile_Fire] += Fires;
	return 1;
}
CMD:homing(playerid, params[])
{
	new Homings;
	if(sscanf(params, "D(2)", Homings)) return SendClientMessage(playerid, COLOR_RED, "/Homing [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Homing Missile Added");
	playerData[playerid][pMissiles][Missile_Homing] += Homings;
	return 1;
}
CMD:power(playerid, params[])
{
	new Powers;
	if(sscanf(params, "D(2)", Powers)) return SendClientMessage(playerid, COLOR_RED, "/Power [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Power Missile Added");
	playerData[playerid][pMissiles][Missile_Power] += Powers;
	return 1;
}
CMD:napalm(playerid, params[])
{
	new Napalms;
	if(sscanf(params, "D(1)", Napalms)) return SendClientMessage(playerid, COLOR_RED, "/Gas [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Gas Can Missile(s) Added");
	playerData[playerid][pMissiles][Missile_Napalm] += Napalms;
	return 1;
}
CMD:stalker(playerid, params[])
{
	new stalkers;
	if(sscanf(params, "D(2)", stalkers)) return SendClientMessage(playerid, COLOR_RED, "/stalker [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Stalker Missile(s) Added");
	playerData[playerid][pMissiles][Missile_Stalker] += stalkers;
	return 1;
}
CMD:ricochet(playerid, params[])
{
	new Ricochets;
	if(sscanf(params, "D(2)", Ricochets)) return SendClientMessage(playerid, COLOR_RED, "/Ricochet [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Ricochet Missile Added");
	playerData[playerid][pMissiles][Missile_Ricochet] += Ricochets;
	return 1;
}
CMD:remotebomb(playerid, params[])
{
	new remotebombs;
	if(sscanf(params, "D(2)", remotebombs)) return SendClientMessage(playerid, COLOR_RED, "/Remotebomb [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Remote Bomb Missile Added");
	playerData[playerid][pMissiles][Missile_RemoteBomb] += remotebombs;
	return 1;
}
CMD:addcomponent(playerid, params[])
{
	new componentid;
	if(sscanf(params, "d", componentid)) return SendClientMessage(playerid, COLOR_RED, "/addcomponent [componentid]");
	SendClientMessageFormatted(playerid, 0xFFFFFFFF, "componentid %d Added", componentid);
	AddVehicleComponent(GetPlayerVehicleID(playerid), componentid);
	return 1;
}
CMD:environmentals(playerid, params[])
{
	new Environmentals;
	if(sscanf(params, "D(1)", Environmentals)) return SendClientMessage(playerid, COLOR_RED, "/Environmentals [Amount]");
	SendClientMessage(playerid, 0xFFFFFFFF, "Environmental Missile(s) Added");
	playerData[playerid][pMissiles][Missile_Environmentals] += Environmentals;
	return 1;
}
CMD:turbo(playerid, params[])
{
	new model = GetVehicleModel(pVehicleID[playerid]);
	playerData[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], floatround(GetTwistedMetalMaxTurbo(model)));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
	return 1;
}
CMD:energy(playerid, params[])
{
	playerData[playerid][pEnergy] = 100;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], 100.0);
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	return 1;
}
CMD:camera(playerid, params[])
{
	SetCameraBehindPlayer(playerid);
	return 1;
}
CMD:vremove(playerid, params[])
{
	if(GetPlayerVehicleID(playerid)) RemovePlayerFromVehicle(playerid);
	return 1;
}
CMD:setskin(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id, skin;
	if(sscanf(params, "ui", id, skin)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setskin [nick/id] [Skinid]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid nick/id");
	SetPlayerSkin(id, skin);
	playerData[playerid][pSkinid] = skin;
	return 1;
}

CMD:goto(playerid,params[])
{
	if(IsPlayerAdmin(playerid))
	{
		new id,string[128];
		if(sscanf(params,"u",id)) return SendClientMessage(playerid, LIGHTBLUE2, "Syntax: /Goto [Goto id/playerName]") &&
		SendClientMessage(playerid, ORANGE, "Function: Will Go To specified player");
		if(!IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_RED, "That Player Is Not Connected.");
		if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Invalid Nick/id.");
		if(id != playerid)
		{
			new Float:x, Float:y, Float:z; GetPlayerPos(id, x, y, z);
			SetPlayerInterior(playerid, GetPlayerInterior(id));
			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
			if(GetPlayerState(playerid) == 2)
			{
				SetVehiclePos(GetPlayerVehicleID(playerid),x+3,y,z+0.3);
				LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(id));
				SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(id));
			}
			else SetPlayerPos(playerid,x+2,y,z+0.4);
			format(string,sizeof(string),"|- You Have Teleported To \"%s\" -|", playerName(id));
			return SendClientMessage(playerid,BlueMsg,string);
		}
	}
	return 0;
}

CMD:gxttest(playerid, params[])
{
	new achar = 'b';
	if(sscanf(params, "c", achar)) return SendClientMessage(playerid, -1, "Syntax: /gxttest [char]");
	new str[64];
	format(str, sizeof(str), "~%c~Hello Moto", achar);
	GameTextForPlayer(playerid, str, 5000, 3);
	return 1;
}

CMD:top5(playerid, params[])
{
	new players_Data[MAX_PLAYERS][2], tempString[128], tempVar, i, j, k;
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
	SendClientMessage(playerid, 0xFF0000FF, "Top 5 players:");
	for(i = 0; i < 5; ++i)
	{
		if(tempVar < i) break;

		GetPlayerName(players_Data[i][1], tempString, 20);

		format(tempString, sizeof(tempString), "%d. Player: %s [%d] - Score: %d", i, tempString, players_Data[i][1], players_Data[i][0]);
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

CMD:v(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new vname[24], changecurrentcar;
	if(sscanf(params, "s[24]D(0)", vname, changecurrentcar)) return SendClientMessage(playerid, COLOR_RED, "Syntax: /v [twisted name/ vehiclename / modelid - changecurrentcar = 0 / 1]");
	if(aveh[playerid] != 0) DestroyVehicle(aveh[playerid]);
	new Float:x, Float:y, Float:z, Float:Angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, Angle);
	x += (2.0 * floatsin(-Angle, degrees));
	y += (2.0 * floatcos(-Angle, degrees));
	if(isNumeric(vname))
	{
		if(!IsValidVehicleModel(strval(vname))) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid Vehicleid");
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
		if(!IsValidVehicleModel(model)) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid Name");
		aveh[playerid] = CreateVehicle(model, x, y, z, Angle, -1, -1, -1);
		if(index == true)
		{
			attachVehicleMachineGuns(aveh[playerid], Missile_Machine_Gun);
		}
		T_SetVehicleHealth(aveh[playerid], GetTwistedMetalMaxHealth(GetVehicleModel(aveh[playerid])));
	}
	else return SendClientMessage(playerid, COLOR_RED, "Syntax: /v [twisted name/ vehiclename / modelid - changecurrentcar = 0 / 1]");
	PutPlayerInVehicle(playerid, aveh[playerid], 0);
	AddVehicleComponent(aveh[playerid], 1010);
	LinkVehicleToInterior(aveh[playerid], GetPlayerInterior(playerid));
	SetVehicleVirtualWorld(aveh[playerid], GetPlayerVirtualWorld(playerid));
	if(changecurrentcar)
	{
		pVehicleID[playerid] = aveh[playerid];
		aveh[playerid] = 0;
		pFiring_Missile[playerid] = 0;
		pMissileID[playerid] = Missile_Special;
		new pm = 0;
		while(pm < 9)
		{
			switch(pm)
			{
				case Missile_Special, Missile_Ricochet: playerData[playerid][pMissiles][pm] = 1;
				case Missile_Fire, Missile_Homing: playerData[playerid][pMissiles][pm] = 2;
				default: playerData[playerid][pMissiles][pm] = 0;
			}
			++pm;
		}
		updatePlayerHUD(playerid);
	}
	return 1;
}
CMD:gotoobject(playerid, params[])
{
	new objectid, Float:x, Float:y, Float:z;
	if(sscanf(params, "i", objectid)) return SendClientMessage(playerid, -1, "Syntax: /gotoobject [objectid]");
	if(!IsValidObject(objectid)) return SendClientMessage(playerid, -1, "Error: Invalid Object");
	GetObjectPos(objectid, x, y, z);
	SetVehiclePos(pVehicleID[playerid], x, y, z);
	SendClientMessageFormatted(playerid, -1, "objectid: %d - x: %0.2f - y: %0.2f - z: %0.2f", objectid, x, y, z);
	return 1;
}
CMD:getobjectpos(playerid, params[])
{
	new objectid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;
	if(sscanf(params, "d", objectid)) return SendClientMessage(playerid, -1, "Syntax: /GetObjectPos [objectid]");
	if(!IsValidObject(objectid)) return SendClientMessage(playerid, -1, "Error: Invalid Object");
	GetObjectPos(objectid, x, y, z);
	GetObjectRot(objectid, rx, ry, rz);
	SendClientMessageFormatted(playerid, -1 , "Object Position id: %d - x: %0.2f - y: %0.2f - z: %0.2f - Angle: %0.4f", objectid, x, y, z, rz);
	return 1;
}
CMD:getpos(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
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
	if(!isServerAdmin(playerid)) return 0;
	if(!GetPlayerVehicleID(playerid)) return SendClientMessage(playerid,0xFFFFFFFF,"Error: Get In A Vehicle");
	new Float:a, id = GetPlayerVehicleID(playerid);
	if(sscanf(params,"f", a)) return SendClientMessage(playerid,0xFFFFFFFF,"Syntax: /setzangle [a]");
	SetVehicleZAngle(id, a);
	return 1;
}
CMD:gotopos(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new Float:x, Float:y, Float:z;
	if(strfind(params, ",", true) != -1)
	{
		if(sscanf(params, "p<,>fff", x, y, z)) return SendClientMessage(playerid, -1, "Syntax: /gotopos [x, y, z]");
	}
	else if(sscanf(params, "fff", x, y, z)) return SendClientMessage(playerid, -1, "Syntax: /gotopos [x y z]");
	SetPlayerPos(playerid, x, y, z);
	SendClientMessageFormatted(playerid, -1, "Teleporting to position: %0.4f %0.4f %0.4f", x, y, z);
	return 1;
}
CMD:akill(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id, reason[40];
	if(sscanf(params, "uS(No Reason)[40]", id, reason)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /akill [id] [reason]");
	if(id == INVALID_PLAYER_ID || !IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid nick/id");

	messageAdmins(COLOR_WHITE, "Administrator %s(%d) Has AKilled %s(%d) - Reason: %s", playerName(playerid), playerid, playerName(id), id, reason);
	new Float:x, Float:y, Float:z;
	GetPlayerPos(id, x, y, z);
	SetPlayerPos(id, x, y, z + 10);
	SetPlayerHealth(id, -1);
	return 1;
}
CMD:getall(playerid,params[])
{
	#pragma unused params
	if(!isServerAdmin(playerid)) return 0;
	new Float:x, Float:y, Float:z, interior = GetPlayerInterior(playerid);
	GetPlayerPos(playerid, x, y, z);
	foreach(Player, i)
	{
		if(i == playerid) continue;
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerPos(i, x + (playerid/4) + 1, y + (playerid/4), z);
		SetPlayerInterior(i, interior);
	}
	return SendClientMessageFormatted(INVALID_PLAYER_ID, BlueMsg, "|- Administrator \"%s\" Has Teleported All Players To His Position -|", playerName(playerid));
}
CMD:get(playerid, params[])
{
	#pragma unused params
	if(!isServerAdmin(playerid)) return 0;
	new id, string[128];
	if(sscanf(params,"u", id)) return SendClientMessage(playerid, LIGHTBLUE2, "Syntax: /Get [id/nick]") &&
	SendClientMessage(playerid, ORANGE, "Function: Will Bring To you the specified player");
	if(!IsPlayerConnected(id) || id == INVALID_PLAYER_ID || id == playerid) return SendClientMessage(playerid, COLOR_RED, "Error: Player is not connected or is yourself");
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	SetPlayerInterior(id, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(id, GetPlayerVirtualWorld(playerid));
	if(GetPlayerState(id) == PLAYER_STATE_DRIVER)
	{
		SetVehiclePos(GetPlayerVehicleID(id),x+3,y,z);
		LinkVehicleToInterior(GetPlayerVehicleID(id),GetPlayerInterior(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(id),GetPlayerVirtualWorld(playerid));
	}
	else SetPlayerPos(id,x + 2,y,z);
	format(string, sizeof(string),"|- You Have Been Teleported To Administrator \"%s(%d)'s\" Position! -|", playerName(playerid),playerid);
	SendClientMessage(id,BlueMsg,string);
	format(string, sizeof(string),"|- You Have Teleported \"%s(%d)\" To Your Position -|", playerName(id),id);
	return SendClientMessage(playerid,BlueMsg,string);
}

GetVehicleSpeed(vehicleid, bool:kmh)
{
	new Float:Speed, Float:X, Float:Y, Float:Z;
	GetVehicleVelocity(vehicleid, X, Y, Z);
	Speed = floatmul(floatsqroot(floatadd(floatadd(floatpower(X, 2), floatpower(Y, 2)),  floatpower(Z, 2))), 200.0); //100.0
	return kmh == true ? floatround(Speed, floatround_floor) : floatround(floatdiv(Speed, 1.609344), floatround_floor);
}

IncreaseVehicleSpeed(vehicleid, Float:howmuch)
{
	static Float:Velocity[3];
	GetVehicleVelocity(vehicleid, Velocity[0], Velocity[1], Velocity[2]);
	return SetVehicleVelocity(vehicleid, Velocity[0] * howmuch , Velocity[1] * howmuch , Velocity[2]);
}

/*DecreaseVehicleSpeed(vehicleid, Float:howmuch)
{
	static Float:Velocity[3];
	GetVehicleVelocity(vehicleid, Velocity[0], Velocity[1], Velocity[2]);
	return SetVehicleVelocity(vehicleid, Velocity[0] / howmuch , Velocity[1] / howmuch , Velocity[2]);
}*/

IsValidVehicleModel(vehicleid)
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

GetXYInFrontOfPoint( &Float: x, &Float: y, Float: angle, Float: distance )
{
   x += ( distance * floatsin( -angle, degrees ) );
   y += ( distance * floatcos( -angle, degrees ) );
}

GetXYInFrontOfVehicle(vehicleid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetVehiclePos(vehicleid, x, y, a);
	GetVehicleZAngle(vehicleid, a);
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

IsPlayerAimingAt(playerid, Float:x, Float:y, Float:z, Float:radius)
{
	new Float:cx, Float:cy, Float:cz, Float:fx, Float:fy, Float:fz;
	GetPlayerCameraPos(playerid, cx, cy, cz);
	GetPlayerCameraFrontVector(playerid, fx, fy, fz);
	return (radius >= MPDistanceCameraToLocation(cx, cy, cz, x, y, z, fx, fy, fz));
}

CMD:testaim(playerid, params[])
{
	new ispoint, Float:x, Float:y, Float:z, vehicleid, Float:radius;
	if(sscanf(params, "df", vehicleid, radius)) return SendClientMessage(playerid, -1, "Syntax: /testaim vehicleid radius");
	GetVehiclePos(vehicleid, x, y, z);
	ispoint = IsPlayerAimingAt(playerid, x, y, z, radius);
	SendClientMessageFormatted(playerid, -1, "IsPlayerAimingAt: %d.", ispoint);
	return 1;
}

IsPlayerInvalidNosExcludeBikes(playerid)
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
		for(new i = 0; i < MAX_INVALID_NOS_VEHICLE; ++i)
		{
			if(GetVehicleModel(vehicleid) == InvalidNosVehicles[i]) return true;
		}
	}
	return false;
}

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

TimeTextForPlayer( style, playerid, text[], time = 5000, color = -1, bool:dontuse2text = false, stop2text = 0 )
{
	if(color == -1)
	{
		color = StatusTextColors[style];
	}
	switch( style )
	{
		case TIMETEXT_POINTS: FadeTextdraw(playerid, _:pStatusInfo[playerid][StatusText][style], StatusTextColors[style], 0xFF, time, 400);
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
					switch(dontuse2text)
					{
						case true: PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], StatusTextLetterSize[style][0], StatusTextLetterSize[style][1]);
						default:
						{
							if(Status_Text[playerid][TIMETEXT_TOP_2][0] != '\0')
							{
								PlayerTextDrawSetString( playerid, pStatusInfo[playerid][StatusText][TIMETEXT_TOP_2], Status_Text[playerid][TIMETEXT_TOP] );
								PlayerTextDrawShow( playerid, pStatusInfo[playerid][StatusText][TIMETEXT_TOP_2] );
								format(Status_Text[playerid][TIMETEXT_TOP_2], MAX_STATUS_TEXT_LENGTH, Status_Text[playerid][TIMETEXT_TOP]);
							}
							new Float:letterx, Float:lettery;
							PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][style], 0.0, 0.0);
							SetTimerEx("UpdateTimeTextSize", TIMETEXT_INTERVAL, false, "dddff", playerid, style, time, letterx, lettery);
						}
					}
				}
				default:
				{
					new timeleft = (GetTickCount() - pStatusInfo[playerid][StatusTime]);
					if(timeleft > 0)
					{
						timeleft += 1000;
						if(dontuse2text == false)
						{
							pStatusInfo[playerid][StatusIndex] = 0;
							TimeTextForPlayer( TIMETEXT_TOP_2, playerid, Status_Text[playerid][TIMETEXT_TOP], timeleft, _, dontuse2text );
						}
						else
						{
							if(stop2text) return 1;
							stop2text = 1;
							pStatusInfo[playerid][StatusIndex] = 1;
							TimeTextForPlayer( TIMETEXT_TOP, playerid, text, timeleft, _, dontuse2text, stop2text );
						}
					}
				}
			}
		}
	}
	//PlayerTextDrawColor( pStatusInfo[playerid][StatusText][style], StatusTextColors[st] );
	PlayerTextDrawSetString( playerid, pStatusInfo[playerid][StatusText][style], text );
	PlayerTextDrawShow( playerid, pStatusInfo[playerid][StatusText][style] );
	strmid(Status_Text[playerid][style], text, false, strlen(text), MAX_STATUS_TEXT_LENGTH);
	KillTimer(pStatusInfo[playerid][StatusTextTimer][style]);
	pStatusInfo[playerid][StatusTextTimer][style] = SetTimerEx( "HideTextTimer", time, false, "iii", style, playerid, _:pStatusInfo[playerid][StatusText][style]);
	return 1;
}

forward HideTextTimer( style, playerid, textdrawid );
public HideTextTimer( style, playerid, textdrawid )
{
	PlayerTextDrawHide(playerid, PlayerText:textdrawid);
	PlayerTextDrawColor( playerid, PlayerText:textdrawid, StatusTextColors[style] );
	KillTimer(pStatusInfo[playerid][StatusTextTimer][style]);
	pStatusInfo[playerid][StatusTextTimer][style] = -1;
	switch(style)
	{
		case TIMETEXT_POINTS, TIMETEXT_MIDDLE, TIMETEXT_MIDDLE_LARGE, TIMETEXT_MIDDLE_SUPER_LARGE, TIMETEXT_BOTTOM:
		{
			StopFadingTextdraw(playerid, textdrawid);
		}
	}
	format(Status_Text[playerid][style], MAX_STATUS_TEXT_LENGTH, "\0");
	Status_Text[playerid][style][0] = EOS;
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
	else format(sTimer, sizeof (sTimer), "k_fading_p_%d", textdrawid);
	stage = (stage + 1) % (time);
	if (stage >= time)
	{
		if(playerid == INVALID_PLAYER_ID) {
			TextDrawShowForAll(Text:textdrawid);
		} else {
			PlayerTextDrawShow(playerid, PlayerText:textdrawid);
		}
		stage = GetPVarInt(playerid, sTimer);
		KillTimer(stage);
		return;
	} else {
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

FadeTextdraw(playerid = INVALID_PLAYER_ID, textdrawid, color, alpha = 0xFF, time, delay = TIMEDRAW_FADE_STAGE_TIME)
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

StopFadingTextdraw(playerid, textdrawid)
{
	static sTimer[32], tid;
	if(playerid == INVALID_PLAYER_ID)
	{
		format(sTimer, sizeof (sTimer), "k_fading_%d", textdrawid);
	} else {
		format(sTimer, sizeof (sTimer), "k_fading_p_%d", textdrawid);
	}
	tid = GetPVarInt(playerid, sTimer);
	KillTimer(tid);
	return 1;
}

CMD:testpoint(playerid, params[])
{
	new ispoint, Float:x, Float:y, Float:z, vehicleid;
	if(sscanf(params, "d", vehicleid)) return SendClientMessage(playerid, -1, "Syntax: /testpoint vehicleid");
	GetVehiclePos(vehicleid, x, y, z);
	ispoint = IsPointInPlayerScreen(playerid, x, y, z);
	SendClientMessageFormatted(playerid, -1, "IsPointInPlayerScreen: %d", ispoint);
	return 1;
}

IsPointInPlayerScreen(playerid, Float:x, Float:y, Float:z)
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

MatrixTransformVector(Float:vector[3], Float:m[4][4], &Float:resx, &Float:resy, &Float:resz) {
	resz = vector[2] * m[0][0] + vector[1] * m[0][1] + vector[0] * m[0][2] + m[0][3];
	resy = vector[2] * m[1][0] + vector[1] * m[1][1] + vector[0] * m[1][2] + m[1][3];
	resx = -(vector[2] * m[2][0] + vector[1] * m[2][1] + vector[0] * m[2][2] + m[2][3]); // don't ask why -x was needed, i don't know either.
}

RotatePointVehicleRotation(vehid, Float:Invector[3], &Float:resx, &Float:resy, &Float:resz, worldspace=0)
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
		resx += fX, resy += fY, resz += fZ;
	}
}

AccelerateTowardsAPoint(vehicleid, Float:x, Float:y)
{
	new Float:pos[6];
	GetVehicleVelocity(vehicleid, pos[4], pos[5], pos[2]);
	GetVehiclePos(vehicleid, pos[0], pos[1], pos[3]);
	if(GivesSpeed(pos[4], pos[5], pos[2], x-pos[0], y-pos[1], pos[2])) {
		SetVehicleVelocity(vehicleid, x-pos[0], y-pos[1], pos[2]);
	}
}

GivesSpeed(Float:x, Float:y, Float:z, Float:newx, Float:newy, Float:newz) // Checks if one velocity is bigger than another.
{
	if(floatsqroot(floatpower(floatabs(x),2)+floatpower(floatabs(y),2)+floatpower(floatabs(z),2))<floatsqroot(floatpower(floatabs(newx),2)+floatpower(floatabs(newy),2)+floatpower(floatabs(newz),2))) return true;
	return false;
}

CMD:av(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not In A Vehicle");
	new vehicleid = GetPlayerVehicleID(playerid), Float:vX, Float:vY, Float:vZ, Float:aX, Float:aY, Float:aZ;
	if(sscanf(params, "F(0.0)F(0.0)F(0.0)", aX, aY, aZ)) return SendClientMessage(playerid, -1, "Syntax: /av Optional: angular velocity [x] [y] [z]");
	GetVehicleVelocity(vehicleid, vX, vY, vZ);
	SetVehicleVelocity(vehicleid, vX, vY, vZ);
	if(vX == 0 && vY == 0 && vZ == 0)
	{
		SetVehicleVelocity(vehicleid, vX, vY, vZ + 0.01); //If X, Y and Z is 0, a velocity won't work
	}
	SetVehicleAngularVelocity(vehicleid, aX, aY, aZ);
	return 1;
}

ModifyVehicleAngularVelocity(vehicleid, Float:modifier = 0.0, positive = 0)
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
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not In A Vehicle");
	new Float:modifier, positive;
	if(sscanf(params, "F(0.0)D(0)", modifier, positive)) return SendClientMessage(playerid, -1, "Syntax: /testm Optional: [modifier] [positive]");
	ModifyVehicleAngularVelocity(GetPlayerVehicleID(playerid), modifier, positive);
	printf("modifier: %0.2f", modifier);
	return 1;
}
CMD:js(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not In A Vehicle");
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
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not In A Vehicle");
	SetVehicleAngularVelocity(GetPlayerVehicleID(playerid), 0.0, 0.0, 1.0);
	return 1;
}
CMD:fflip(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not In A Vehicle");
	SetVehicleVelocity(GetPlayerVehicleID(playerid), 0.0, 0.0, 0.2);
	SetVehicleAngularVelocity(GetPlayerVehicleID(playerid), 0.175, 0.0, 0.0);
	return 1;
}
CMD:speedboost(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not In A Vehicle");
	new Float:currspeed[3], Float:direction[3], Float:total, vehicleid = GetPlayerVehicleID(playerid);
	GetVehicleVelocity(vehicleid, currspeed[0], currspeed[1], currspeed[2]);
	total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
	total += 0.7;
	new Float:invector[3] = {0.0, -1.0, 0.0};
	RotatePointVehicleRotation(vehicleid, invector, direction[0], direction[1], direction[2]);
	SetVehicleVelocity(vehicleid, direction[0] * total, direction[1] * total, direction[2] * total);
	return 1;
}

CMD:reply(playerid, params[])
{
	new id = GetPVarInt(playerid, "LastMessage");
	if(isnull(params)) return SendClientMessage(playerid, COLOR_RED, "{FF0000}Usage: "#cWhite"/reply (message)");
	if(strlen(params) > 120) return SendClientMessage(playerid, COLOR_RED, "{FF0000}Error: "#cWhite"Invalid PM Lenght - Your PM Must Be Between 1-120 Characters.");
	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_RED, "Invalid Player!");
	//if(playerData[id][PMDisabled] == 1) return SendClientMessageFormatted(playerid, COLOR_RED, ""#cYellow"%s(%d) "#cWhite"Is {FF0000}Not "#cWhite"Accepting His PMs At The Moment.", playerName(id), id);
	//if(IsIgnored[id][playerid] == 1) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"That Player Is Ignoring You");
	SendClientMessageFormatted(playerid, YELLOW, "PM Sent To %s(%d): %s", playerName(id), id, params);
	SendClientMessageFormatted(id, YELLOW, "PM From %s(%d): %s", playerName(playerid), playerid, params);
	SetPVarInt(id, "LastMessage", playerid);
	//new ircstr[156 + 12];
	//format(ircstr, sizeof(ircstr), "%s(%d) PM To %s(%d): %s", playerName(playerid), playerid, playerName(id), id, params);
	//IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, ircstr);
	return 1;
}
CMD:r(playerid, params[]) return cmd_reply(playerid, params);
CMD:pm(playerid, params[])
{
	new id, message[128];
	if(sscanf(params, "us[128]", id, message)) return SendClientMessage(playerid, COLOR_RED, "Syntax: /pm [Nick / id] [Message]");
	if(id == INVALID_PLAYER_ID) return SendClientMessageFormatted(playerid, COLOR_RED, "%s Is Not A Valid Player",params);
	if(id == playerid) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"You Cannot PM Yourself");
	//if(playerData[id][PMDisabled] == 1) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"That Player's Private Message Is Currently Disabled.");
	//if(IsIgnored[id][playerid] == 1) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"That Player Is Ignoring You");

	SendClientMessageFormatted(id, YELLOW, "From %s(%d): %s", playerName(playerid), playerid, message);
	SendClientMessageFormatted(playerid, YELLOW, "To %s(%d): %s", playerName(id), id, message);
	printf("System: Private Message] - %s(%d) PM'ED %s(%d): %s", playerName(playerid), playerid, playerName(id), id, message);
	//new ircstr[156 + 12];
	//format(ircstr, sizeof(ircstr), "%s(%d) PM To %s(%d): %s", playerName(playerid), playerid, playerName(id), id, message);
	//IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, ircstr);
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
	if(!isServerAdmin(playerid)) return 0;
	new id, level, AdmRank[32];
	if(sscanf(params, "ud", id, level)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setlevel [nick / id] [Level]");
	if(pLogged_Status[playerid] == 0) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"You Are Not Logged In Please Log In Using /Login [password]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"Invalid Nick / id");
	if(level > 10) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"Max adminlevel is 10!");
	switch(level)
	{
		case 0: AdmRank = "None";
		case ADMIN_LEVEL_TRIAL: AdmRank = "Trial Administrator";
		case ADMIN_LEVEL_ADMINISTRATOR: AdmRank = "Administrator";
		case ADMIN_LEVEL_LEAD_ADMIN: AdmRank = "Lead Administrator";
		case ADMIN_LEVEL_DEVELOPER: AdmRank = "Developer";
	}
	playerData[id][pAdminLevel] = level;
	format(gQuery, sizeof(gQuery), "UPDATE "#mySQL_Accounts_Table" SET `AdminLevel` = %d WHERE `Username` = '%s' LIMIT 1", playerData[id][pAdminLevel], playerName(id));
	mysql_tquery(mysqlConnHandle, gQuery);
	SendClientMessageFormatted(id, BLUE, "*Admin: Administrator %s Has Set Your Admin Level To %s", playerName(playerid), AdmRank);
	SendClientMessageFormatted(playerid, YELLOW, "*Admin: You have set %s's admin level To %d / %s", playerName(id), level, AdmRank);
	return 1;
}

CMD:freeze(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /Freeze [playerid / part of name]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid nick/id");
	if(pLogged_Status[playerid] == 0) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not Logged In Please Log In Using /Login [password]");

	TogglePlayerControllable(id, false);
	SendClientMessageFormatted(id, BLUE, "Admin: An Administrator Has Frozen You", playerName(playerid),playerid);
	SendClientMessageFormatted(playerid, YELLOW, "Admin: You Have Frozen %s(%d)", playerName(id),id);
	return 1;
}
CMD:unfreeze(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id, str[128];
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /Unfreeze [playerid / part of name]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid nick/id");
	if(pLogged_Status[playerid] == 0) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not Logged In Please Log In Using /Login [password]");

	TogglePlayerControllable(id, true);
	SetCameraBehindPlayer(playerid);
	SendClientMessage(id, BLUE, "An Administrator Has Unfrozen You");
	format(str, sizeof(str), "Admin: You Have Unfrozen %s(%d)", playerName(id),id);
	SendClientMessage(playerid, YELLOW, str);
	return 1;
}
CMD:setscore(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id, score;
	if(sscanf(params, "ui", id, score)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setscore [playerid / part of name] [Score]");
	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xFF00AAFF, "Error: Player is not connected!");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid nick/id");
	if(score > 1000000) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid Score! (0-1000000)");
	if(pLogged_Status[playerid] == 0) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not Logged In Please Log In Using /Login [password]");

	SetPlayerScore(id, score);
	SendClientMessageFormatted(id, BLUE, "*ADMIN: Administrator %s(%d) Has set your Score To %d", playerName(playerid),playerid, score);
	SendClientMessageFormatted(playerid, YELLOW, "*ADMIN: You have set %s(%d)'s Score To %i", playerName(id),id, score);
	return 1;
}
CMD:setmoney(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id, money;
	if(sscanf(params, "ui", id, money)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setmoney [Nick/id] [pMoney]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid nick/id");
	//if(pLogged_Status[playerid] == 0) return SendClientMessage(playerid, COLOR_RED, "Error: You Are Not Logged In Please Log In Using /Login [password]");
	playerData[id][pMoney] = money;
	SendClientMessageFormatted(id, BLUE, "Admin: Administrator %s(%d) Has Set Your Money To {19E03D}$%i", playerName(playerid), playerid, money);
	SendClientMessageFormatted(playerid, YELLOW, "Admin: You Have Set %s(%d)'s Money To {19E03D}$%d", playerName(id), id, money);
	return 1;
}
CMD:setinterior(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setinterior [interiorid]");
	SetPlayerInterior(playerid, id);
	return 1;
}
CMD:setworld(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setworld [worldid]");
	SetPlayerVirtualWorld(playerid, id);
	return 1;
}
CMD:world(playerid, params[])
{
	new str[64];
	format(str, sizeof(str), "Current Virtual World: %d", GetPlayerVirtualWorld(playerid));
	return SendClientMessage(playerid, ANNOUNCEMENT, str);
}
CMD:setweather(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	{
		new weather;
		if(sscanf(params, "i", weather)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /setweather [weatherid]");
		SetWeather(weather);
		SendClientMessageToAll(COLOR_GREY, "The Weather Has Been Changed!");
	}
	return 1;
}
CMD:amuteall(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	for(new i = 0; i < MAX_PLAYERS; ++i)
	{
		if(IsPlayerNPC(i) || i == playerid) continue;
		BitFlag_On(bPlayerGameSettings[i], gMuted);
	}
	SendClientMessage(playerid, PINK, "All Players Have Been Muted By An Administrator.");
	//IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, "11All Players Have Been Muted By An Administrator.");
	//IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, "11All Players Have Been Muted By An Administrator.");
	return 1;
}
CMD:aunmuteall(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	for(new i = 0; i < MAX_PLAYERS; ++i)
	{
		if(IsPlayerNPC(i)) continue;
		BitFlag_Off(bPlayerGameSettings[i], gMuted);
	}
	SendClientMessage(playerid, PINK, "All Players Have Been Unmuted By An Administrator.");
	//IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, "11All Players Have Been Unmuted By An Administrator.");
	//IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, "11All Players Have Been Unmuted By An Administrator.");
	return 1;
}
CMD:mute(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id, reason[50];
	if(sscanf(params, "uS(No Reason)[50]", id, reason)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /mute [id] [reason]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid Nick/id");
	if(bPlayerGameSettings[id] & gMuted) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: %s(%d) Is Already Muted", playerName(id),id);
	SendClientMessageFormatted(INVALID_PLAYER_ID, YELLOW, "Admin Mute: An Administrator Has Muted %s(%d) - (Reason: %s)", playerName(id), id, reason);
	BitFlag_Off(bPlayerGameSettings[id], gMuted);
	return 1;
}
CMD:unmute(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, COLOR_WHITE, "Syntax: /Unmute [id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "Error: Invalid Nick/id");
	if(!(bPlayerGameSettings[id] & gMuted)) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: %s(%d) Is Not Muted", playerName(id),id);
	SendClientMessageFormatted(INVALID_PLAYER_ID, YELLOW, "Admin Unmute: An Administrator Has Unmuted %s(%d)", playerName(id), id);
	BitFlag_On(bPlayerGameSettings[id], gMuted);
	return 1;
}

public IRC_OnConnect(botid, ip[], port)
{
	printf("[IRC] - IRC_OnConnect: Bot id: %d Has Connected To %s: %d", botid, ip, port);
	IRC_AddToGroup(gIRCGroupChatID, botid);
	ircBotIdentify(botid);
	
	IRC_JoinChannel(botid, IRC_CHANNEL);
	IRC_JoinChannel(botid, ECHO_IRC_CHANNEL);
	SetTimerEx("IRC_OnConnectComplete", 250, 0, "i", botid);
	return 1;
}

ircBotIdentify(botid)
{//IRC_SendRaw(botid, ":PRIVMSG NickServ REGISTER "#IRC_BOT_PASSWORD" admin@lvcnr.net");
	if(botid > 1)
		IRC_SayFormatted(botid, "NickServ", "IDENTIFY %s "#IRC_BOT_PASSWORD"", gBotNames[0]);
	else
		IRC_Say(botid, "NickServ", "IDENTIFY "#IRC_BOT_PASSWORD"");
}

forward IRC_OnConnectComplete(botid);
public IRC_OnConnectComplete(botid)
{
	IRC_JoinChannel(botid, ADMIN_CHAT_IRC_CHANNEL, IRC_BOT_ADMIN_CHAN_KEY);
	return 1;
}

public IRC_OnDisconnect(botid, ip[], port, reason[])
{
	//printf("IRC_OnDisconnect: Bot id: %d Has Disconnected From %s: %d (%s)", botid, ip, port, reason);
	IRC_RemoveFromGroup(gIRCGroupChatID, botid);
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
public IRC_OnInvitedToChannel(botid, channel[], invitinguser[], invitinghost[])
{
	printf("*** IRC_OnInvitedToChannel: Bot ID %d invited to channel %s by %s (%s)", botid, channel, invitinguser, invitinghost);
	if(strfind(channel, "tm", true) != -1)
	{
		IRC_JoinChannel(botid, channel);
	}
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
		format(gString, sizeof(gString), "Welcome To "#SERVER_NAME" IRC %s!", user);
		IRC_GroupSay(botid, channel, gString);
		format(gString, sizeof(gString), "%s Has Joined "#SERVER_NAME" IRC!", user);
		SendClientMessageToAll(BLUE, gString);
	}
	else if(strcmp(channel, ECHO_IRC_CHANNEL) == 0)
	{
		format(gString, sizeof(gString), "Welcome To "#SERVER_NAME" Echo IRC Channel %s!", user);
		IRC_GroupSay(botid, channel, gString);
		format(gString, sizeof(gString), "%s Has Joined "#SERVER_NAME" Echo IRC Channel!", user);
		SendClientMessageToAll(BLUE, gString);
	}
	else if(strcmp(channel, ADMIN_CHAT_IRC_CHANNEL) == 0)
	{
		format(gString, sizeof(gString), "[IRC] - %s Has Joined "#SERVER_NAME" Admin IRC Channel! (Host: %s)", user, host);
		foreach(Player, i)
		{
			if(!isServerAdmin(i)) continue;
			SendClientMessage(i, COLOR_ADMIN, gString);
		}
	}
	format(iLast_User_Join, sizeof(iLast_User_Join), "%s", user);
	return 1;
}
public IRC_OnUserLeaveChannel(botid, channel[], user[], host[], message[])
{
	printf("User: %s Has Left "#SERVER_NAME" IRC Reason: %s.", user, message);
	format(gString, sizeof(gString), "%s Has Left "#SERVER_NAME" IRC!", user);
	SendClientMessageToAll(BLUE, gString);
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
	format(gString, sizeof(gString), "[IRC] - %s Has Changed His Nick To %s (Host: %s)", oldnick, newnick, host);
	foreach(Player, i)
	{
		if(!isServerAdmin(i)) continue;
		SendClientMessage(i, COLOR_ADMIN, gString);
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
	if(IRC_IsUserOnChannel(botid, ADMIN_CHAT_IRC_CHANNEL, user))
	{
		if (message[0] == '@')
		{
			if(!IRC_IsVoice(botid, ADMIN_CHAT_IRC_CHANNEL, user)) return 1;
			format(gString, sizeof(gString), "(IRC Admin Chat) %s: %s", user, message[1]);
			//messageAdmins(COLOR_ADMIN, gString);
			format(gString, sizeof(gString), "03(Admin Chat)01 %s: %s", user, message[1]);
			IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, gString);
		}
		return 0;
	}
	printf("IRC_OnUserSay (Bot ID %d): User %s Sent A Message To %s: %s", botid, user, recipient, message);
	return 1;
}
public IRC_OnUserNotice(botid, recipient[], user[], host[], message[])
{
	if (!strcmp(host, "No hostname", true)) return 1;
	printf("[IRC] - IRC_OnUserNotice (Bot ID %d): User %s (%s) Sent A Notice To %s: %s", botid, user,host, recipient, message);
	if(strfind(message, "has been ghosted") != -1) {
		new newName[20];
		format(newName, 20, "%s", gBotNames[botid - 1]);
		IRC_ChangeNick(botid, newName);
		ircBotIdentify(botid);
	}
	return 1;
}

public IRC_OnReceiveNumeric(botid, numeric, message[])
{
	// Check if the numeric is an error defined by RFC 1459/2812
	if (numeric >= 400 && numeric <= 599)
	{
		if (numeric == 433) // const ERR_NICKNAMEINUSE = 433;
		{
			// Check if the nickname is already in use
			new newName[20];
			format(newName, 20, "%s`", gBotNames[botid - 1]);
			IRC_ChangeNick(botid, newName);
			IRC_SayFormatted(botid, "NickServ", "GHOST %s "#IRC_BOT_PASSWORD"", gBotNames[botid - 1]);
		}
		else if(numeric == 477) // You need to be identified to a registered account to join this channel
		{
			ircBotIdentify(botid);
		}
		printf("*** IRC_OnReceiveNumeric (Bot ID %d): %d (%s)", botid, numeric, message);
	}
	return 1;
}

public OnQueryError(errorid, error[], callback[], query[], connectionHandle)
{
	printf("[OnQueryError (%d, %s, %s)]: Query: %s", errorid, error, callback, query);
	switch(errorid)
	{
		case CR_COMMAND_OUT_OF_SYNC: {
			printf("[MySQL: Error - Callback: %s] - Commands Out Of Sync For - Query: %s", callback, query);
		}
		case ER_UNKNOWN_TABLE: printf("[MySQL: Error - Callback: %s] - Unknown table '%s' in %s - Query: %s", callback, error, query);
		case ER_SYNTAX_ERROR: printf("[MySQL: Error - Callback: %s] - Something is wrong in your syntax - Query: %s", callback, query);
		case CR_SERVER_GONE_ERROR, CR_SERVER_LOST, CR_SERVER_LOST_EXTENDED: mysql_reconnect();
	}
	return 1;
}

public OnPlayerPause(playerid)
{
	printf("[SYSTEM]: %s(%d) has Paused.", playerName(playerid), playerid);

	new Float:px, Float:py, Float:pz;
	GetPlayerPos(playerid, px, py, pz);
	pPausedText[playerid] = Create3DTextLabel("PAUSED", -1, px, py, pz + 1.0, 25.0, GetPlayerVirtualWorld(playerid));
	Attach3DTextLabelToPlayer(pPausedText[playerid], playerid, 0, 0, 0.4);
	new time = gettime();
	pPausedTimestamp[playerid] = time;
	return 1;
}

public OnPlayerUnPause(playerid)
{
	printf("[SYSTEM]: %s(%d) has Unpaused.", playerName(playerid), playerid);
	pPausedTimestamp[playerid] = 0;
	Delete3DTextLabel(pPausedText[playerid]);
	pPausedText[playerid] = Text3D:INVALID_3DTEXT_ID;
	if(Selecting_Textdraw[playerid] != 0) {
		tm_SelectTextdraw(playerid, Selecting_Textdraw[playerid]);
	}
	return 1;
}

isPlayerPaused(playerid) return _:pPaused[playerid];

// [MODULE] Commands

CMD:subtitle(playerid, params[])
{
	new text[32], time = 5000, override = 1;
	if(!sscanf(params, "s[32]D(5000)D(1)", text, time, override)) {
		ShowSubtitle(playerid, text, time, override);
	}
	return 1;
}

CMD:mysqlreconnect(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 1;
	mysql_reconnect(); //mysqlConnHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
	SendClientMessage(playerid, -1, "MySQL Connect Attempted");
	return 1;
}

IRCCMD:mysqlreconnect(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsAdmin(botid, channel, user)) return 1;
	mysql_reconnect(); //mysqlConnHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
	IRC_Notice(gIRCGroupChatID, user, "MySQL Connect Attempted");
	return 1;
}

CMD:savestats(playerid, params[])
{
	if(pLastSavedStatisticsTime[playerid] >= gettime()) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"Please Wait Before Saving Your Statistics Again!");
	pLastSavedStatisticsTime[playerid] = gettime() + 35;
	savePlayerAccount(playerid, .automated = 0);
	return 1;
}

IRCCMD:saveallstats(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsAdmin(botid, channel, user)) return 0;
	new time = gettime();
	foreach(Player, i)
	{
		if(playerData[i][pSpawned_Status] == 0) continue;
		pLastSavedStatisticsTime[i] = time + 10;
		savePlayerAccount(i, .automated = 0);
	}
	//IRC_GroupSay(gIRCGroupChatID, channel, "13All Player Data Saved Successfully");
	//if(strcmp(channel, ECHO_IRC_CHANNEL, false) == 0) {
	//    IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, "13All Player Data Saved Successfully");
	//}
	return 1;
}
IRCCMD:msg(botid, channel[], user[], host[], params[]) return irccmd_say(botid, channel, user, host, params);
IRCCMD:say(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsVoice(botid, channel, user)) return 1;
	if(isnull(params)) return IRC_Notice(gIRCGroupChatID, user, "04Error: 01You cannot send empty (null) messages to the SERVER!");
	//if(params[130]) return IRC_Notice(gIRCGroupChatID, user, "04Error: 01The message you attempted to send is too long. Please shorten it");
	format(gString, sizeof(gString), "02*** %s on IRC: %s", user, params);
	IRC_GroupSay(gIRCGroupChatID, channel, gString);
	if(strcmp(channel, IRC_CHANNEL, false) == 0)
	{
		format(gString, sizeof(gString), "02*** %s on Echo IRC: %s", user, params);
		IRC_GroupSay(gIRCGroupChatID, ECHO_IRC_CHANNEL, gString);
		format(gString, sizeof(gString), "02*** %s on Echo IRC: %s", user, params);
		IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, gString);
	}
	else if(strcmp(channel, ECHO_IRC_CHANNEL, false) == 0)
	{
		format(gString, sizeof(gString), "02*** %s on Echo IRC: %s", user, params);
		IRC_GroupSay(gIRCGroupChatID, IRC_CHANNEL, gString);
		format(gString, sizeof(gString), "02*** %s on Echo IRC: %s", user, params);
		IRC_GroupSay(gIRCGroupChatID, ADMIN_CHAT_IRC_CHANNEL, gString);
	}
	format(gString, sizeof(gString), "*** %s on IRC: %s", user, params);
	SendClientMessageToAll(0xFF00EEFF, gString);
	return 1;
}

CMD:exitveh(playerid, params[])
{
	playerData[playerid][CanExitVeh] = !playerData[playerid][CanExitVeh];
	return 1;
}

CMD:curmodel(playerid, params[])
{
	SendClientMessageFormatted(playerid, -1, "Current Vehicle Model: "#cBlue"%d", C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]);
	return 1;
}
CMD:curid(playerid, params[])
{
	new Float:x, Float:y, Float:z;
	GetVehiclePos(pVehicleID[playerid], x, y, z);
	SendClientMessageFormatted(playerid, -1, "Current Vehicle Model: "#cBlue"%d - (%0.2f, %0.2f, %0.2f)", pVehicleID[playerid], x, y, z);
	return 1;
}
CMD:getcurid(playerid, params[])
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	SetVehiclePos(pVehicleID[playerid], x, y, z);
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

CMD:setsave(playerid, params[])
{
	new Float:width, Float:height;
	if(sscanf(params, "ff", width, height)) return SendClientMessage(playerid, COLOR_RED, "Error In Syntax");
	TextDrawTextSize(pC_Save, width, height);
	return 1;
}

CMD:top3(playerid, params[])
{
	for(new opos = 0; opos < 3; opos++)
	{
		if(Game_Top3_Positions[playerData[playerid][gGameID]][opos] != INVALID_PLAYER_ID)
		{
			SendClientMessageFormatted(playerid, -1, "%s - Position: %d", playerName(Game_Top3_Positions[playerData[playerid][gGameID]][opos]), opos + 1);
		}
	}
	return 1;
}

CMD:position(playerid, params[])
{
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_RACE: SendClientMessageFormatted(playerid, -1, "Position: %d - Old Position: %d - cp: %d", Race_Position[playerid], Race_Old_Position[playerid], CP_Progress[playerid]);
		default: SendClientMessageFormatted(playerid, -1, "Position: %d - Old Position: %d - xp: %d", p_Position[playerid], p_Old_Position[playerid], GetPlayerGamePoints(playerid));
	}
	return 1;
}

CMD:setcpprogress(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_RACE:
		{
			CP_Progress[playerid] = strval(params);
			SendClientMessageFormatted(playerid, -1, "CP Progress Changed To %d", CP_Progress[playerid]);
		}
		default: SendClientMessage(playerid, -1, "This gamemode does not support this command - Please use in the GM_RACE Gamemode");
	}
	return 1;
}

CMD:hunted(playerid, params[])
{
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_HUNTED:
		{
			if(gHunted_Player[playerData[playerid][gGameID]][0] == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "There is no current hunted player");
			SendClientMessageFormatted(playerid, -1, "The Current Hunted Player Is: %s(%d)", playerName(gHunted_Player[playerData[playerid][gGameID]][0]), gHunted_Player[playerData[playerid][gGameID]][0]);
		}
		default: SendClientMessage(playerid, -1, "This gamemode does not support this command. Please use in the Hunted Gamemode");
	}
	return 1;
}

CMD:addspawn(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new vehicleid = GetPlayerVehicleID(playerid), Float:x, Float:y, Float:z, Float:angle;
	switch(vehicleid)
	{
		case 0: SendClientMessage(playerid, -1, "Syntax: /addspawn :- Please add spawns in vehicle!");
		default:
		{
			GetVehiclePos(vehicleid, x, y, z);
			GetVehicleZAngle(vehicleid, angle);
		}
	}
	AddMapSpawn(gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, angle);
	SendClientMessageFormatted(playerid, -1, ""#cSAMPRed"Spawn Added: "#cNiceBlue"%0.4f, %0.4f, %0.4f, %0.2f "#cWhite"- To Map %s(%d)", x, y, z, angle, s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Name], gGameData[playerData[playerid][gGameID]][g_Map_id]);
	format(gQuery, sizeof(gQuery), "INSERT INTO "#mySQL_Maps_Spawns_Table" (`mapName`, `mapID`, `x`, `y`, `z`, `angle`) VALUES ('%s', %d, %0.4f, %0.4f, %0.4f, %0.2f)", s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Name], gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, angle);
	mysql_tquery(mysqlConnHandle, gQuery);
	return 1;
}

CMD:addpickup(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new pickuptype[32], pickuptypei = -1, vehicleid = GetPlayerVehicleID(playerid), Float:x, Float:y, Float:z;
	if(sscanf(params, "s[32]", pickuptype)) {
		SendClientMessage(playerid, -1, "Syntax: /addpickup [pickup type]");
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
		default: GetVehiclePos(vehicleid, x, y, z);
	}
	AddMapPickup(gGameData[playerData[playerid][gGameID]][g_Map_id], pickuptypei, x, y, z);
	createPickupEx(playerData[playerid][gGameID], 14, x, y, z, GetPlayerVirtualWorld(playerid), pickuptypei);
	SendClientMessageFormatted(playerid, -1, ""#cSAMPRed"Pickup Added: "#cNiceBlue"%s "#cWhite"Placed at your position", pickuptype);
	format(gQuery, sizeof(gQuery), "INSERT INTO "#mySQL_Maps_Pickups_Table" (`mapName`, `mapID`, `pickupType`, `x`, `y`, `z`) VALUES ('%s', %d, %d, %0.4f, %0.4f, %0.4f)", s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Name], gGameData[playerData[playerid][gGameID]][g_Map_id], pickuptypei, x, y, z);
	mysql_tquery(mysqlConnHandle, gQuery);
	return 1;
}

CMD:deletepickup(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	new mode;
	if(sscanf(params, "D(0)", mode)) return SendClientMessage(playerid, -1, "Syntax: /deletepickup [mode off / on (0 / 1)]");
	SetPVarInt(playerid, "Pickup_Deletion_Mode", mode);
	SendClientMessageFormatted(playerid, -1, "Pickup Deletion Mode: %s", (mode == 0) ? (""#cRed"OFF") : (""#cLime"ON"));
	if(mode == 1)
	{
		SendClientMessage(playerid, -1, "Pickup Deletion Mode Activated, Enter the pickup you want to delete.");
	}
	return 1;
}

CMD:setgtime(playerid, params[])
{
	new time;
	if(sscanf(params, "d", time)) return 1;
	gGameData[playerData[playerid][gGameID]][g_Gamemode_Time] = time;
	return 1;
}
CMD:setgctime(playerid, params[])
{
	new time;
	if(sscanf(params, "d", time)) return 1;
	gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] = time;
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
	if(isnull(params)) return SendClientMessage(playerid, -1, "Syntax: /alpha [27 - 360]");
	if(!isNumeric(params)) return SendClientMessage(playerid, -1, "Syntax: /alpha [27 - 360] - Use A Numerical Value!");
	if(speedometer_alpha < 42) speedometer_alpha = 42;
	speedometer_alpha = floatstr(params);
	SendClientMessageFormatted(playerid, -1, "New Alpha: %0.2f", speedometer_alpha);
	return 1;
}*/

CMD:debugkeys(playerid, params[])
{
	debugkeys = !debugkeys;
	return 1;
}

CMD:adjust(playerid, params[]) return AdjustTeamColoursForPlayer(playerid);

//CMD:beginc(playerid, params[]) return playerBeginCustomization(playerid);
//CMD:endc(playerid, params[]) return playerEndCustomization(playerid);

CMD:back(playerid, params[])
{
	if(pSpawn_Request[playerid] == SPAWN_REQUEST_GARAGE)
	{
		playerEndCustomization(playerid);
		setupClassSelectionForPlayer(playerid, 0, .garage = 1, .firstTime = 1);
	}
	return 1;
}

CMD:tutorial(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_TUTORIAL, DIALOG_STYLE_LIST, ""cSAMP""#SERVER_NAME" - Tutorial", "The Gamemodes\nThe Weapons\nHow To Spawn\n", "Proceed", "Finish");
	PlayerPlaySound(playerid, 4804, 0.0, 0.0, 0.0); // "Yow pay attention and you might learn something"
	return 1;
}
CMD:clicktd(playerid, params[])
{
	tm_SelectTextdraw(playerid, 0x9999BBBB);
	return 1;
}
CMD:canceltd(playerid, params[])
{
	tm_CancelSelectTextdraw(playerid);
	return 1;
}
CMD:canceledit(playerid, params[])
{
	CancelEdit(playerid);
	return 1;
}
CMD:selectobject(playerid, params[])
{
	SelectObject(playerid);
	return 1;
}

CMD:hidenav(playerid, params[])
{
	togglePlayerNavigationTXD(playerid, false);
	return 1;
}

CMD:shownav(playerid, params[])
{
	togglePlayerNavigationTXD(playerid, true);
	return 1;
}

CMD:sound(playerid, params[])
{
	new sound, id = playerid, str[8];
	format(str, sizeof(str), "dU(%d)", playerid);
	if(sscanf(params, str, sound, id)) return SendClientMessage(playerid, -1, "Syntax: /sound [id] Optional: [nick / id]");
	PlayerPlaySound(id, sound, 0.0, 0.0, 0.0);
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
	new name[MAX_PLAYER_NAME];
	if(sscanf(params, "s[MAX_PLAYER_NAME]", name)) return 1;
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

CMD:jump(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
	if(playerData[playerid][gGameID] != INVALID_GAME_ID) {
		if(gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] > 0) return 1;
	}
	if(GetPVarInt(playerid, "pJump_GroundCheck") == 1) {
		//SendClientMessageFormatted(playerid, -1, "time distance: %d. index: %d.", (gettime() - GetPVarInt(playerid, "pJump_GroundTime")), GetPVarInt(playerid, "pJump_Index"));
		if(GetPVarInt(playerid, "pJump_GroundTime") < gettime()) {
			resetPlayerJumpData(playerid);
		}
	}
	new curJumpIndex = GetPVarInt(playerid, "pJump_Index"),
		Float:x, Float:y, Float:z, vehicleid = GetPlayerVehicleID(playerid),
		Float:offset = 0.3;

	if(curJumpIndex >= 2) return 1;

	switch(curJumpIndex)
	{
		case 0:
		{
			SetPVarInt(playerid, "pJump_GroundCheck", 1);
			SetPVarInt(playerid, "pJump_GroundTime", gettime() + 7);
		}
		case 1: offset = 0.25;
	}
	SetPVarInt(playerid, "pJump_Index", curJumpIndex + 1);
	GetVehicleVelocity(vehicleid, x, y, z);
	SetVehicleVelocity(vehicleid, x, y, (z + offset));
	return 1;
}

resetPlayerJumpData(playerid)
{
	SetPVarInt(playerid, "pJump_Index", 0);
	SetPVarInt(playerid, "pJump_GroundCheck", 0);
	SetPVarInt(playerid, "pJump_GroundTime", 0);
}

CMD:ainvisibility(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return SendClientMessage(playerid, COLOR_RED, "Error: you are already in Invisibility mode");
	LinkVehicleToInterior(GetPlayerVehicleID(playerid), INVISIBILITY_INDEX);
	return 1;
}

CMD:resetinvisibility(playerid, params[])
{
	if(!isServerAdmin(playerid)) return 0;
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) != INVISIBILITY_INDEX) return SendClientMessage(playerid, COLOR_RED, "Error: you are not in Invisibility mode");
	playerResetGameInvisibility(GetPlayerVehicleID(playerid));
	return 1;
}

CMD:fakefreeze(playerid, params[])
{
	return (EMPTime[playerid] = 5);
}

CMD:invisibility(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
	if(playerData[playerid][pEnergy] < 25) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: "#cWhite"You don't have enough energy to activate invisibility "#cYellow"- Energy Left: %d", playerData[playerid][pEnergy]);
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return SendClientMessage(playerid, COLOR_RED, "Error: "#cWhite"You are already in Invisibility Mode");
	playerData[playerid][pEnergy] -= 25;
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	LinkVehicleToInterior(GetPlayerVehicleID(playerid), INVISIBILITY_INDEX);
	SetTimerEx("playerResetGameInvisibility", 7000, false, "i", GetPlayerVehicleID(playerid));
	return 1;
}

CMD:shield(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
	if(strcmp(params, "Absorption_Shield", false) == 0 && !isnull(params))
	{
		if(playerData[playerid][pEnergy] < 45) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: "#cWhite"You don't have enough energy to activate your absorption shield "#cYellow"- Energy Left: %d", playerData[playerid][pEnergy]);
		playerData[playerid][pEnergy] -= 45;
	}
	else
	{
		if(playerData[playerid][pEnergy] < 35) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: "#cWhite"You don't have enough energy to activate your shield "#cYellow"- Energy Left: %d", playerData[playerid][pEnergy]);
		playerData[playerid][pEnergy] -= 35;
	}
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	new Float:sX, Float:sY, Float:sZ, color = 0xFFFF0011, time = 2500; // red
	GetVehicleModelInfo(GetVehicleModel(pVehicleID[playerid]), VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
	if(strcmp(params, "Absorption_Shield", false) == 0 && !isnull(params))
	{
		color = 0xFF000011; // blue
		time = 2100;
		SetPVarInt(playerid, "Absorption_Shield", 1);
	}
	sX *= 0.8;
	sY *= 0.7;
	sZ *= 0.7;
	SetPlayerAttachedObject(playerid, ATTACHED_INDEX_SHIELD, 18887, 1, 0.0, 0.1, -0.42, 0.0, 0.0, 18.0, sX, sY, sZ, color); // spectre 1.0 3.7 1.3
	SetTimerEx("playerResetGameShield", time, false, "i", playerid);
	return 1;
}

CMD:mine(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
	if(strcmp(params, "alt_fire", true) == 0)
	{
		if(playerData[playerid][pEnergy] < 35) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: "#cWhite"You don't have enough energy to plant a super mine. "#cYellow"Energy Left: %d", playerData[playerid][pEnergy]);
		playerData[playerid][pEnergy] -= 35;
	}
	else
	{
		if(playerData[playerid][pEnergy] < 25) return SendClientMessageFormatted(playerid, COLOR_RED, "Error: "#cWhite"You don't have enough energy to plant a mine. "#cYellow"Energy Left: %d", playerData[playerid][pEnergy]);
		playerData[playerid][pEnergy] -= 25;
	}
	PlayerPlaySound(playerid, 25800, 0.0, 0.0, 0.0);
	new id = GetPlayerVehicleID(playerid), Float:x, Float:y, Float:z, Float:a,
		slot = GetFreeMissileSlot(playerid, id), Float:sX, Float:sY, Float:sZ;
	GetVehicleModelInfo(GetVehicleModel(id), VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
	GetVehiclePos(id, x, y, z);
	GetVehicleZAngle(id, a);
	a += 180.0;
	sY /= 1.7;
	y += ( sY * floatcos( -a, degrees ) );
	z -= 0.3;//1213
	Vehicle_Missile[id][slot] = CreateObject(1654, x, y, z, 0, 90.0, (a + 180), 300.0);
	Vehicle_Smoke[id][slot] = CreateObject(19282, x, y, z + 0.05, 0, 0.0, 0.0, 300.0); // red small light
	Object_Owner[Vehicle_Missile[id][slot]] = id;
	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
	Object_Type[Vehicle_Missile[id][slot]] = Energy_Mines;
	Object_Slot[Vehicle_Missile[id][slot]] = slot;
	EditPlayerSlot(playerid, slot, PLAYER_MISSILE_SLOT_ADD);
	Mine_Timer[playerid] = SetTimerEx("explodeMissile", 10000, false, "iiii", playerid, id, slot, Energy_Mines);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));
	UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
	return 1;
}

// [MODULE] Stocks and functions
/*
intabs(intNum) {
	return (intNum < 0) ? -intNum : intNum;
}

Distance1Dint(fPos1, fPos2) {

	if(fPos1 > fPos2)
		return intabs(fPos1 - fPos2);
	return intabs(fPos2 - fPos1);
}

GetTimeDistance(a, b) {
	// a pawn cell is signed 32-bit integer. (-2147483648 to 2147483647)
	// handle invalid time. If any time is invalid (zero) then it returns infinite time (2147483647)
	if((a == 0) || (b == 0)) {
		return 2147483647;
	}
	if((a < 0) && (b > 0)) {
		new dist = Distance1Dint(a, b);
		if (dist > 2147483647)
			return Distance1Dint(a - 2147483647, b - 2147483647);
		else
			return dist;
	} else {
		return Distance1Dint(a, b);
	}
}
*/
setupGarageForPlayer(playerid)
{
	SetPlayerPos(playerid, GARAGE_POSITIONS);
	SetPlayerVirtualWorld(playerid, 0);
	switch(pSpawn_Request[playerid])
	{
		case SPAWN_REQUEST_GARAGE:
		{
			//PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			InterpolateCameraPos(playerid, 2501.935058, -1672.158813, 14.968697, 2484.361572, -1662.390502, 15.966423, 2000);
			InterpolateCameraLookAt(playerid, 2497.711669, -1669.485473, 15.094894, 2487.824218, -1665.972900, 15.546255, 2500);
		}
		case SPAWN_REQUEST_GARAGE_EDITING:
		{
			SetPlayerCameraPos(playerid, 2484.361572, -1662.390502, 15.966423);
			SetPlayerCameraLookAt(playerid, 2487.824218, -1665.972900, 15.546255);
			EditPlayerObject(playerid, p_c_Objects[playerid][GetPVarInt(playerid, "pGarageEditingModelIndex")]);
		}
	}
}

playerBeginCustomization(playerid)
{
	if(pVehicleID[playerid]) {
		destroyTwistedVehicle(playerid, pVehicleID[playerid]);
	}
	SetPlayerPos(playerid, GARAGE_POSITIONS);
	pVehicleID[playerid] = CreateVehicle(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], GARAGE_V_POSITIONS + 0.7, 0.0, C_S_IDS[pTwistedIndex[playerid]][CS_Colour1], C_S_IDS[pTwistedIndex[playerid]][CS_Colour2], 0);
	SetVehicleNumberPlate(pVehicleID[playerid], GetTwistedMetalName(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]));
	format(gString, sizeof(gString), "Customizing %s~n~~w~Type ~b~/back ~w~to go back", C_S_IDS[pTwistedIndex[playerid]][CS_TwistedName]); // Press ~y~~h~~k~~VEHICLE_ACCELERATE~
	ShowSubtitle(playerid, gString, (20 * 1000), 1, 335.0);
	hideClassHUDForPlayer(playerid);
	TextDrawHideForPlayer(playerid, gGarage_Go_Back);
	pSpawn_Request[playerid] = SPAWN_REQUEST_GARAGE;
	tm_SelectTextdraw(playerid, COLOR_RED);
	TextDrawShowForPlayer(playerid, pC_Box_Outline);
	TextDrawShowForPlayer(playerid, pC_Box);
	TextDrawShowForPlayer(playerid, pC_cColor1);
	TextDrawShowForPlayer(playerid, pC_cColor2);
	TextDrawShowForPlayer(playerid, pC_Wheel_Type);
	TextDrawShowForPlayer(playerid, pC_Save);
	TextDrawShowForPlayer(playerid, pC_fLine);
	TextDrawShowForPlayer(playerid, pC_lLine);
	TextDrawShowForPlayer(playerid, pC_WheelLeftArrow);
	TextDrawShowForPlayer(playerid, pC_WheelRightArrow);
	TextDrawShowForPlayer(playerid, pC_Default);
	TextDrawShowForPlayer(playerid, pC_Back);
	setPlayerDefaultCustomization(playerid, .firstStart = 1);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_Select_Header_Text]);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_Wheel_Name]);
	TextDrawShowForPlayer(playerid, pC_Select_Box);
	TextDrawShowForPlayer(playerid, pC_Select_Line);
	TextDrawShowForPlayer(playerid, pC_Models_Up_Arrow);
	TextDrawShowForPlayer(playerid, pC_Models_Down_Arrow);
	SpawnPlayer(playerid);
	return 1;
}

playerEndCustomization(playerid)
{
	tm_CancelSelectTextdraw(playerid);
	for(new i = 0; i < sizeof(c_ColorIndex[]); ++i)
	{
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_ColorBoxM][i]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_ColorBoxRight][i]);
		TextDrawHideForPlayer(playerid, pC_ColorLeftArrow[i]);
		TextDrawHideForPlayer(playerid, pC_ColorRightArrow[i]);
		c_ColorIndex[ playerid ][i] = 0;
	}
	TextDrawHideForPlayer(playerid, pC_Box_Outline);
	TextDrawHideForPlayer(playerid, pC_Box);
	TextDrawHideForPlayer(playerid, pC_cColor1);
	TextDrawHideForPlayer(playerid, pC_cColor2);
	TextDrawHideForPlayer(playerid, pC_Wheel_Type);
	TextDrawHideForPlayer(playerid, pC_Save);
	TextDrawHideForPlayer(playerid, pC_fLine);
	TextDrawHideForPlayer(playerid, pC_lLine);
	TextDrawHideForPlayer(playerid, pC_WheelLeftArrow);
	TextDrawHideForPlayer(playerid, pC_WheelRightArrow);
	TextDrawHideForPlayer(playerid, pC_Default);
	TextDrawHideForPlayer(playerid, pC_Back);
	TextDrawHideForPlayer(playerid, pC_Select_Box);
	TextDrawHideForPlayer(playerid, pC_Select_Line);
	TextDrawHideForPlayer(playerid, pC_Models_Up_Arrow);
	TextDrawHideForPlayer(playerid, pC_Models_Down_Arrow);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_Select_Header_Text]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_Wheel_Name]);
	for(new i = 0; i < MAX_C_OBJECTS_LIST; ++i)
	{
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_oNames][i]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_oModels][i]);
	}
	c_WheelIndex[ playerid ] = 0;
	unloadPlayerCustomizationModels(playerid);
	DeletePVar(playerid, "pGarageEditingModelMode");
	return 1;
}

setPlayerDefaultCustomization(playerid, firstStart = 0)
{
	c_ColorIndex[ playerid ][0] = C_S_IDS[pTwistedIndex[playerid]][CS_Colour1];
	c_ColorIndex[ playerid ][1] = C_S_IDS[pTwistedIndex[playerid]][CS_Colour2];
	new left, i;
	for(i = 0; i < sizeof(c_ColorIndex[]); ++i)
	{
		if(c_ColorIndex[playerid][i] == 0)
			left = 255;
		else
			left = c_ColorIndex[playerid][i] - 1;
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], VehicleColoursTableRGBA[left]);
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxM][i], VehicleColoursTableRGBA[c_ColorIndex[playerid][i]]);
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], VehicleColoursTableRGBA[c_ColorIndex[playerid][i] + 1]);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i]);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i]);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxM][i]);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_ColorBoxRight][i]);
		TextDrawShowForPlayer(playerid, pC_ColorLeftArrow[i]);
		TextDrawShowForPlayer(playerid, pC_ColorRightArrow[i]);
		ChangeVehicleColor(pVehicleID[playerid], c_ColorIndex[playerid][0], c_ColorIndex[playerid][1]);
	}
	c_WheelIndex[ playerid ] = 0;
	switch(GetVehicleModel(pVehicleID[playerid]))
	{
		case TMC_HAMMERHEAD: PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Wheel_Name], "Incompatible");
		default:
		{
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Wheel_Name], Wheel_Data[0][w_Name]);
			if(GetVehicleComponentInSlot(pVehicleID[playerid], CARMODTYPE_WHEELS))
				RemoveVehicleComponent(pVehicleID[playerid], GetVehicleComponentInSlot(pVehicleID[playerid], CARMODTYPE_WHEELS));
		}
	}
	c_ModelIndex[playerid] = 0;
	for(i = 0; i < MAX_C_OBJECTS_LIST; ++i)
	{
		pGarageModelIDData[playerid][i] = cModels[i][c_Model];
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_oNames][i], cModels[i][c_Name]);
		PlayerTextDrawSetPreviewModel(playerid, pTextInfo[playerid][pC_oModels][i], cModels[i][c_Model]);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oNames][i]);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oModels][i]);
	}
	if(firstStart) {
		togglePlayerGarageModelSelMode(playerid, .updateOnly = 1, .modeOverride = GARAGE_MODEL_EDIT_ATTACH);
		loadPlayerCustomizationModels(playerid, pVehicleID[playerid]);
	} else {
		attachPlayerCustomizationModels(playerid);
	}
	return;
}

CMD:gedit(playerid, params[])
{
	togglePlayerGarageModelSelMode(playerid);
	return 1;
}

togglePlayerGarageModelSelMode(playerid, updateOnly = 0, modeOverride = -1)
{
	CancelEdit(playerid);
	if(modeOverride != -1)
		SetPVarInt(playerid, "pGarageEditingModelMode", modeOverride);
		
	new curEditingMode = GetPVarInt(playerid, "pGarageEditingModelMode");
	if(!updateOnly) {
		if(++curEditingMode > GARAGE_MODEL_EDIT_DELETE)
			curEditingMode = GARAGE_MODEL_EDIT_ATTACH;

		if(modeOverride == -1)
			SetPVarInt(playerid, "pGarageEditingModelMode", curEditingMode);
	}
	for(new i = 0; i < MAX_C_OBJECTS_LIST; ++i)
	{
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_oNames][i]);
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pC_oModels][i]);
	}
	switch(curEditingMode)
	{
		case GARAGE_MODEL_EDIT_ATTACH:
		{
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Select_Header_Text], "SELECT AN OBJECT TO ATTACH~n~TO YOUR VEHICLE");
			for(new i = 0; i < MAX_C_OBJECTS_LIST; ++i)
			{
				pGarageModelIDData[playerid][i] = cModels[i][c_Model];
				PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_oNames][i], cModels[i][c_Name]);
				PlayerTextDrawSetPreviewModel(playerid, pTextInfo[playerid][pC_oModels][i], cModels[i][c_Model]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oNames][i]);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oModels][i]);
			}
		}
		case GARAGE_MODEL_EDIT_DATA:
		{
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Select_Header_Text], "SELECT AN OBJECT TO EDIT~n~ON YOUR VEHICLE");
			loadPlayerCustomizationModels(playerid, pVehicleID[playerid], .showGarageEditing = 1);
		}
		case GARAGE_MODEL_EDIT_DELETE:
		{
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_Select_Header_Text], "SELECT AN OBJECT TO DELETE~n~FROM YOUR VEHICLE");
			loadPlayerCustomizationModels(playerid, pVehicleID[playerid], .showGarageEditing = 1);
		}
	}
}

loadPlayerCustomizationModels(playerid, vehicleid, showGarageEditing = 0)
{
	unloadPlayerCustomizationModels(playerid);
	format(gQuery, sizeof gQuery, "SELECT * FROM "#mySQL_Customization_Table" WHERE `Username` = '%s' AND `vmodel` = %d LIMIT 0,%d", playerName(playerid), C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], MAX_MODELS_PER_VEHICLE);
	mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnPlayerModelsLoad", "iii", playerid, vehicleid, showGarageEditing);
}

THREAD:OnPlayerModelsLoad(playerid, vehicleid, showGarageEditing)
{
	new rows = cache_get_row_count(mysqlConnHandle), data[16], row, id, cID, iCustomMenuIndex = 0;
	if(rows)
	{
		for(row = 0; row < rows; ++row)
		{
			cache_get_row(row, 3, data, mysqlConnHandle); // ID
			id = strval(data);
			cache_get_row(row, 4, data, mysqlConnHandle); // objectmodel
			p_c_Model[playerid][id] = strval(data);
			cache_get_row(row, 5, data, mysqlConnHandle); // offsetx
			p_c_Model_Data[playerid][id][0] = floatstr(data);
			cache_get_row(row, 6, data, mysqlConnHandle); // offsety
			p_c_Model_Data[playerid][id][1] = floatstr(data);
			cache_get_row(row, 7, data, mysqlConnHandle); // offsetz
			p_c_Model_Data[playerid][id][2] = floatstr(data);
			cache_get_row(row, 8, data, mysqlConnHandle); // offsetrx
			p_c_Model_Data[playerid][id][3] = floatstr(data);
			cache_get_row(row, 9, data, mysqlConnHandle); // offsetry
			p_c_Model_Data[playerid][id][4] = floatstr(data);
			cache_get_row(row, 10, data, mysqlConnHandle); // offsetrz
			p_c_Model_Data[playerid][id][5] = floatstr(data);
			p_c_Objects[playerid][id] = CreateObject(p_c_Model[playerid][id], p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5], 50.0);
			AttachObjectToVehicle(p_c_Objects[playerid][id], vehicleid, p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5]);
			//SendClientMessageFormatted(playerid, -1, "%d loaded (rows %d)", id, rows);

			if(showGarageEditing) {
				cID = getCustomizationIDFromModel(p_c_Model[playerid][id]);
				
				if(cID != -1) {
					pGarageModelIDData[playerid][iCustomMenuIndex] = id;

					PlayerTextDrawSetString(playerid, pTextInfo[playerid][pC_oNames][iCustomMenuIndex], cModels[cID][c_Name]);
					PlayerTextDrawSetPreviewModel(playerid, pTextInfo[playerid][pC_oModels][iCustomMenuIndex], cModels[cID][c_Model]);
					PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oNames][iCustomMenuIndex]);
					PlayerTextDrawShow(playerid, pTextInfo[playerid][pC_oModels][iCustomMenuIndex]);
					++iCustomMenuIndex;
				}
				else
					printf("[SYSTEM: Thread_OnPlayerModelsLoad ERROR] - Loading model Index from Model %d (Database Indexed: %d) FAILED!", p_c_Model[playerid][id], id);
			}
		}
	}
	else {
		if(showGarageEditing) {
			togglePlayerGarageModelSelMode(playerid, .updateOnly = 1, .modeOverride = GARAGE_MODEL_EDIT_ATTACH);
			SendClientMessage(playerid, -1, "There are no customization models left to edit / delete.");
		}
	}
	return 1;
}

attachPlayerCustomizationModels(playerid)
{
	for(new id = 0; id < MAX_MODELS_PER_VEHICLE; ++id)
	{
		if(IsValidPlayerObject(playerid, p_c_Objects[playerid][id]))
			DestroyPlayerObject(playerid, p_c_Objects[playerid][id]);
			
		if(IsValidObject(p_c_Objects[playerid][id]))
			DestroyObject(p_c_Objects[playerid][id]);

		p_c_Objects[playerid][id] = CreateObject(p_c_Model[playerid][id], p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5], 50.0);
		AttachObjectToVehicle(p_c_Objects[playerid][id], pVehicleID[playerid], p_c_Model_Data[playerid][id][0], p_c_Model_Data[playerid][id][1], p_c_Model_Data[playerid][id][2], p_c_Model_Data[playerid][id][3], p_c_Model_Data[playerid][id][4], p_c_Model_Data[playerid][id][5]);
	}
}

getCustomizationIDFromModel(modelID)
{
	for(new i = 0; i < MAX_CUSTOM_OBJECTS; ++i)
	{
		if(modelID == cModels[i][c_Model]) return i;
	}
	return -1;
}

unloadPlayerCustomizationModels(playerid)
{
	for(new i = 0; i < MAX_MODELS_PER_VEHICLE; ++i)
	{
		if(IsValidObject(p_c_Objects[playerid][i]))
		{
			DestroyObject(p_c_Objects[playerid][i]);
			p_c_Model[playerid][i] = 0;
			p_c_Model_Edited[playerid][i] = 0;
			for(new f = 0; f < 6; f++)
				p_c_Model_Data[playerid][i][f] = 0.0;
			//SendClientMessageFormatted(playerid, -1, "%d unloaded", i);
		}
	}
}

setupClassSelectionForPlayer(playerid, classid, garage = 0, firstTime = 0)
{
	new showHUD = 0;
	if(garage) {
		SetPVarInt(playerid, "pGarage", 1), showHUD = 1;
		ShowSubtitle(playerid, "Select a vehicle to start customizing", (60 * 1000 * 2), 1, 345.0);
	} else {
		if(!GetPVarInt(playerid, "pClassSelection") && !GetPVarInt(playerid, "pGarage"))
		{
			SetPVarInt(playerid, "pClassSelection", 1);
			showHUD = 1;
		}
	}
	if(showHUD) {
		showClassHUDForPlayer(playerid);
	}
	if(firstTime) {
		tm_SelectTextdraw(playerid, NAVIGATION_COLOUR);
		SetPlayerVirtualWorld(playerid, playerid + 1);
	}
	if(pVehicleID[playerid]) {
		destroyTwistedVehicle(playerid, pVehicleID[playerid]);
	}
	CallLocalFunction("OnPlayerRequestClassEx", "ii", playerid, classid);
}

endPlayerClassSelection(playerid, cancelTD = 1)
{
	DeletePVar(playerid, "pClassSelection");
	hideClassHUDForPlayer(playerid);
	HideSubtitle(playerid);
	if(cancelTD) {
		tm_CancelSelectTextdraw(playerid);
	}
	SetPlayerVirtualWorld(playerid, 0);
	destroyTwistedVehicle(playerid, pVehicleID[playerid]);
}

showClassHUDForPlayer(playerid)
{
	TextDrawShowForPlayer(playerid, gGarage_Go_Back);
	TextDrawShowForPlayer(playerid, gClass_Spawn);
	TextDrawShowForPlayer(playerid, gClass_Box);
	PlayerTextDrawShow(playerid, gClass_Name[playerid]);
	TextDrawShowForPlayer(playerid, gClass_Left_Arrow);
	TextDrawShowForPlayer(playerid, gClass_Right_Arrow);
	TextDrawShowForPlayer(playerid, gClass_Info_Model);
	if(playerData[playerid][gGameID] != INVALID_GAME_TEAM)
	{
		switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
		{
			case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
			{
				playerData[playerid][gTeam] = TEAM_CLOWNS;
				TextDrawShowForPlayer(playerid, gClass_T_Box);
				TextDrawShowForPlayer(playerid, gClass_T_Left);
				TextDrawShowForPlayer(playerid, gClass_T_Right);
				PlayerTextDrawSetString(playerid, gClass_Team_Name[playerid], Team_Info[playerData[playerid][gTeam]][TI_Team_Name]);
				PlayerTextDrawSetPreviewModel(playerid, gClass_Team_Model[playerid], Team_Info[playerData[playerid][gTeam]][TI_Skin_ID]);
				PlayerTextDrawShow(playerid, gClass_Team_Name[playerid]);
				PlayerTextDrawShow(playerid, gClass_Team_Model[playerid]);
			}
		}
	}
}

hideClassHUDForPlayer(playerid)
{
	TextDrawHideForPlayer(playerid, gClass_Spawn);
	TextDrawHideForPlayer(playerid, gClass_Box);
	PlayerTextDrawHide(playerid, gClass_Name[playerid]);
	TextDrawHideForPlayer(playerid, gClass_Left_Arrow);
	TextDrawHideForPlayer(playerid, gClass_Right_Arrow);
	TextDrawHideForPlayer(playerid, gClass_Info_Model);
	TextDrawHideForPlayer(playerid, gClass_T_Box);
	TextDrawHideForPlayer(playerid, gClass_T_Left);
	TextDrawHideForPlayer(playerid, gClass_T_Right);
	PlayerTextDrawHide(playerid, gClass_Team_Name[playerid]);
	PlayerTextDrawHide(playerid, gClass_Team_Model[playerid]);
	return 1;
}

hidePlayerHUD(playerid)
{
	switch(pHUDType[playerid])
	{
		case HUD_TYPE_TMPS3:
		{
			HidePlayerProgressBar(playerid, pTextInfo[playerid][pHealthBar]);
			HidePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
			HidePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
			for(new m = 0; m < MAX_MISSILEID; m++)
			{
				PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][m]);
				PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileImages][m]);
			}
		}
		default:
		{
			TextDrawHideForPlayer(playerid, pHud_Box);
			TextDrawHideForPlayer(playerid, pHud_HealthSign);
			TextDrawHideForPlayer(playerid, pHud_BoxSeparater);
			TextDrawHideForPlayer(playerid, pHud_SecondBox);
			TextDrawHideForPlayer(playerid, pHud_EnergySign);
			TextDrawHideForPlayer(playerid, pHud_TurboSign);
			PlayerTextDrawHide(playerid, pTextInfo[playerid][pHealthVerticalBar]);
			for(new m = 0; m < MAX_MISSILEID; m++)
			{
				PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][m]);
			}
		}
	}
	TextDrawHideForPlayer(playerid, pHud_UpArrow);
	TextDrawHideForPlayer(playerid, pHud_LeftArrow);
	TextDrawHideForPlayer(playerid, pHud_RightArrow);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pLevelText]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pEXPText]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_IDX]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][Mega_Gun_Sprite]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pLevelText]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][pEXPText]);
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
	HidePlayerProgressBar(playerid, pTextInfo[playerid][pAiming_Health_Bar]);
	PlayerTextDrawHide(playerid, pTextInfo[playerid][AimingPlayer]);
	for(new rb = 0; rb < 4; rb++)
	{
		PlayerTextDrawHide(playerid, Race_Box_Text[playerid][rb]);
	}
	PlayerTextDrawHide(playerid, Race_Box_Outline[playerid]);
	PlayerTextDrawHide(playerid, Race_Box[playerid]);
	TextDrawHideForPlayer(playerid, Players_Online_Textdraw);
	TextDrawHideForPlayer(playerid, gGameData[playerData[playerid][gGameID]][g_Gamemode_Time_Text]);
	return 1;
}

showPlayerHUD(playerid)
{
	TextDrawShowForPlayer(playerid, gGameData[playerData[playerid][gGameID]][g_Gamemode_Time_Text]);
	TextDrawShowForPlayer(playerid, pHud_UpArrow);
	TextDrawShowForPlayer(playerid, pHud_LeftArrow);
	TextDrawShowForPlayer(playerid, pHud_RightArrow);
	switch(pHUDType[playerid])
	{
		case HUD_TYPE_TMPS3:
		{
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pHealthBar]);
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
			ShowPlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
			if(pHUDType[playerid] == HUD_TYPE_TMBLACK) {
				PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pHealthVerticalBar], 0.000000, -8.600000);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthVerticalBar]);
			}
		}
		default:
		{
			TextDrawShowForPlayer(playerid, pHud_Box);
			TextDrawShowForPlayer(playerid, pHud_HealthSign);
			TextDrawShowForPlayer(playerid, pHud_BoxSeparater);
			TextDrawShowForPlayer(playerid, pHud_SecondBox);
			TextDrawShowForPlayer(playerid, pHud_EnergySign);
			TextDrawShowForPlayer(playerid, pHud_TurboSign);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthVerticalBar]);
		}
	}
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pLevelText]);
	PlayerTextDrawShow(playerid, pTextInfo[playerid][pEXPText]);
	ShowPlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	updatePlayerHUD(playerid);
	return 1;
}

CanPlayerUseTwistedMetalVehicle(playerid, model)
{
	switch(model)
	{
		case TMC_ROADKILL, TMC_MEATWAGON, TMC_HAMMERHEAD:
		{
			if(0 <= playerData[playerid][pLevel] <= 10) return 0;
		}
		case TMC_SWEETTOOTH, TMC_DARKSIDE, TMC_REAPER, TMC_SHADOW:
		{
			if(0 <= playerData[playerid][pLevel] <= 20) return 0;
		}
	}
	return 1;
}

beginPlayerPreloading(playerid)
{
	if(Objects_Preloaded[playerid] != 0) return 1;
	Objects_Preloaded[playerid] = 1;
	for(new i = 0; i < MAX_PRELOADED_OBJECTS; ++i)
	{
		if(IsValidPlayerObject(playerid, Preloading_Objects[playerid][i]))
		{
			DestroyPlayerObject(playerid, Preloading_Objects[playerid][i]);
			Preloading_Objects[playerid][i] = INVALID_OBJECT_ID;
		}
	}
	Preloading_Objects[playerid][0] = CreatePlayerObject(playerid, Machine_Gun, 			TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][1] = CreatePlayerObject(playerid, Missile_Default_Object, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][2] = CreatePlayerObject(playerid, Missile_Napalm_Object, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][3] = CreatePlayerObject(playerid, Missile_RemoteBomb_Object, TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][4] = CreatePlayerObject(playerid, Missile_Smoke_Object, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0);
	Preloading_Objects[playerid][5] = CreatePlayerObject(playerid, 18681, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // explosions
	Preloading_Objects[playerid][6] = CreatePlayerObject(playerid, 18685, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // explosions
	Preloading_Objects[playerid][7] = CreatePlayerObject(playerid, 18686, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // explosions
	Preloading_Objects[playerid][8] = CreatePlayerObject(playerid, 18647, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // red neon
	Preloading_Objects[playerid][9] = CreatePlayerObject(playerid, 18650, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // yellow neon
	Preloading_Objects[playerid][10] = CreatePlayerObject(playerid, Missile_Ricochet_Object, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // ricochet
	Preloading_Objects[playerid][11] = CreatePlayerObject(playerid, 1654, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // ricochet
	Preloading_Objects[playerid][12] = CreatePlayerObject(playerid, 1083, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // ricochet
	Preloading_Objects[playerid][13] = CreatePlayerObject(playerid, 3092, 	TM_PRELOAD_X, TM_PRELOAD_Y + 5, TM_PRELOAD_Z, 0.0, 0.0, 0.0, 300.0); // dead body
	SetTimerEx("FinishPlayerPreloading", 2500, false, "i", playerid);
	return 1;
}

public FinishPlayerPreloading(playerid)
{
	for(new i = 0; i < MAX_PRELOADED_OBJECTS; ++i)
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

forward ReturnDarksidesSpeed(playerid, vehicleid, Float:VelocityX, Float:VelocityY, Float:VelocityZ);
public ReturnDarksidesSpeed(playerid, vehicleid, Float:VelocityX, Float:VelocityY, Float:VelocityZ)
{
	SetVehicleVelocity(vehicleid, VelocityX, VelocityY, VelocityZ);
	pFiring_Missile[playerid] = 0;
	playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
	return 1;
}

GetClosestVehicleEx(playerid, Float:dis = 6000.0, &Float:distaway)
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

GetClosestVehicle(playerid, Float:dis = 6000.0)
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
	if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
	{
		playerData[playerid][pMissile_Special_Time] += 100;
		if(playerData[playerid][pMissile_Special_Time] > 5000)
		{
			pFiring_Missile[playerid] = 0;
			KillTimer(Special_Missile_Timer[playerid]);
			playerData[playerid][pMissile_Special_Time] = 0;
			DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
			playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
		} else {
			if(playerData[playerid][pMissile_Special_Time] >= 2500)
			{
				if(pFiring_Missile[playerid] == 1)
				{
					pFiring_Missile[playerid] = 0;
				}
			}
			new Float:x, Float:y, Float:z, Float:DestX, Float:DestY, Float:Angle, Float:damage,
				closestvehicle = GetClosestVehicle(playerid, 25.0), Float:fAZ;
			if((closestvehicle != INVALID_VEHICLE_ID || (1 <= closestvehicle <= 2000))
			  && playerData[Vehicle_Driver[closestvehicle]][gTeam] != playerData[playerid][gTeam])
			{
				GetVehiclePos(vehicleid, x, y, z);
				GetVehiclePos(closestvehicle, DestX, DestY, z);
				GetVehicleZAngle(vehicleid, fAZ);
				Angle = atan2(y - DestY, x - DestX) - fAZ - 180.0;
				MPClamp360(Angle);
				damage = GetMissileDamage(Missile_Special, vehicleid);
				DamagePlayer(playerid, vehicleid, MPGetVehicleDriver(closestvehicle), closestvehicle, damage, Missile_Special);
				GetVehicleModelInfo(GetVehicleModel(closestvehicle), VEHICLE_MODEL_INFO_SIZE, z, z, z);
				z -= 0.7;
				StartHitBarProcess(playerid, floatround(damage), 0.0, 0.0, z, closestvehicle);
			}
			else Angle = 95.0;
			//SendClientMessageFormatted(playerid, -1, "[System] - playerid: %d - closestvehicleid: %d - Angle: %f - Angle2D - 95.0: %f", playerid, closestvehicle, Angle, (Angle - 95.0));
			AttachObjectToVehicle(playerData[playerid][pSpecial_Missile_Object], vehicleid, 0.1, -0.5, 1.5, 0.0, 30.0, Angle);
		}
	} else {
		pFiring_Missile[playerid] = 0;
		KillTimer(Special_Missile_Timer[playerid]);
		playerData[playerid][pMissile_Special_Time] = 0;
	}
	return 1;
}

StartHitBarProcess(playerid, amount, Float:x, Float:y, Float:z, attachedvehicleid = INVALID_VEHICLE_ID)
{
	new string[3], PlayerText3D:hitbar;
	format(string, sizeof string, "%d", amount);
	hitbar = CreatePlayer3DTextLabel(playerid, string, COLOR_RED, x, y, z + 0.6, 50.0, INVALID_PLAYER_ID, attachedvehicleid, 0);
	SetTimerEx("UpdateHitBar", 66, false, "iiiifffii", playerid, attachedvehicleid, _:hitbar, amount, x, y, z + 0.8, 16, COLOR_RED);
	return 1;
}

forward UpdateHitBar(playerid, attachedvehicle, PlayerText3D:hitbar, hp, Float:x, Float:y, Float:z, update_no, color);
public UpdateHitBar(playerid, attachedvehicle, PlayerText3D:hitbar, hp, Float:x, Float:y, Float:z, update_no, color)
{
	DeletePlayer3DTextLabel(playerid, hitbar);
	--update_no;
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
	if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
	{
		playerData[playerid][pMissile_Special_Time] += 100;
		if(playerData[playerid][pMissile_Special_Time] > 5000)
		{
			pFiring_Missile[playerid] = 0;
			KillTimer(Special_Missile_Timer[playerid]);
			playerData[playerid][pMissile_Special_Time] = 0;
			DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
			playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
		} else {
			if(playerData[playerid][pMissile_Special_Time] >= 2500)
			{
				if(pFiring_Missile[playerid] == 1)
				{
					pFiring_Missile[playerid] = 0;
				}
			}
			new cv = GetClosestVehicle(playerid, 8.0);
			if(cv == INVALID_VEHICLE_ID || playerData[Vehicle_Driver[cv]][gTeam] == playerData[playerid][gTeam]) return 1;
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
	} else {
		pFiring_Missile[playerid] = 0;
		KillTimer(Special_Missile_Timer[playerid]);
		playerData[playerid][pMissile_Special_Time] = 0;
	}
	return 1;
}

forward FlashRoadkillForPlayer(playerid, times);
public FlashRoadkillForPlayer(playerid, times)
{
	if(playerData[playerid][pMissile_Charged] == INVALID_MISSILE_ID) return 1;
	if(times == 0)
	{
		Roadkill_Special(playerid, 2);
		return 1;
	}
	GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |~n~~w~Click ~p~~k~~VEHICLE_FIREWEAPON_ALT~ ~w~To Fire!", 300, 3);
	SetTimerEx("FlashRoadkillForPlayer", 500, false, "ii", playerid, (times - 1));
	return 1;
}

forward Roadkill_Special(playerid, countdown);
public Roadkill_Special(playerid, countdown)
{
	if(countdown == 1)
	{
		PlayerPlaySound(playerid, 1056, 0.0, 0.0, 0.0);
		if(++playerData[playerid][pMissile_Special_Time] >= MAX_ROADKILL_MISSILES)
		{
			playerData[playerid][pMissile_Special_Time] = MAX_ROADKILL_MISSILES;
			KillTimer(Special_Missile_Timer[playerid]);
			Special_Missile_Timer[playerid] = SetTimerEx("FlashRoadkillForPlayer", 500, false, "ii", playerid, 5);
		}
		switch(playerData[playerid][pMissile_Special_Time])
		{
			case 1: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~|", 915, 3);
			case 2: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| |", 915, 3);
			case 3: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| | |", 915, 3);
			case 4: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| | | |", 915, 3);
			case 5: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| | | | |", 915, 3);
			case 6: GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |", 915, 3);
		}
	}
	else if(countdown == 2)
	{
		pFiring_Missile[playerid] = 0;
		KillTimer(Special_Missile_Timer[playerid]);
		playerData[playerid][pMissile_Special_Time] = 0;
		playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
		GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |~n~~r~~h~Special Overheated", 2500, 3);
	}
	return 1;
}

forward GurneySpeedUpdate(playerid, vehicleid);
public GurneySpeedUpdate(playerid, vehicleid)
{
	new Float:currspeed[3], Float:direction[3], Float:total, Float:invector[3] = {0.0, -1.0, 0.0};
	GetVehicleVelocity(vehicleid, currspeed[0], currspeed[1], currspeed[2]);
	total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
	RotatePointVehicleRotation(vehicleid, invector, direction[0], direction[1], direction[2]);
	if(total < 0.49) {
		total += 0.1;
	} else {
		total -= 0.3;
	}
	SetVehicleVelocity(vehicleid, direction[0] * total, direction[1] * total, 0.0);
	return 1;
}

forward RocketSpeedUpdate(playerid, vehicleid);
public RocketSpeedUpdate(playerid, vehicleid)
{
	new Float:vx, Float:vy, Float:vz, Float:vlength, Float:cx, Float:cy, Float:cz,
		Float:rx, Float:ry, Float:rz, Float:anglecos, Float:va;
	GetVehicleVelocity(vehicleid, vx, vy, vz);
	vlength = floatsqroot(vx*vx + vy*vy + vz*vz);

	if(vlength < 0.35) { // plane isn't flying fast yet
		GetVehicleZAngle(vehicleid, va);
		vx = floatsin(-va, degrees) * 0.4;
		vy = floatcos(-va, degrees) * 0.4;
		vz = 0.1;
	} else { // plane is flying full speed so slow it down
		vx /= vlength;
		vy /= vlength;
		vz /= vlength;
	}
	GetPlayerCameraFrontVector(playerid, cx, cy, cz);
	cz += 0.08;
	anglecos = floatabs(vx*cx + vy*cy + vz*cz); // This value is the cosine of the angle between camera- and vehicle-vector.

	rx = vx + cx * 0.4 * anglecos + cx * 0.2; // Camera vector * the angle = more effect on small corners, less to zero effect on 90
	ry = vy + cy * 0.4 * anglecos + cy * 0.2; // Added another 0.2 so that there still is some effect at 90
	rz = vz + cz * 0.4 * anglecos + cz * 0.2;

	SetVehicleVelocity(vehicleid, rx * 0.5, ry * 0.5, rz * 0.5); // speed multiplier
	return 1;
}

forward OnTwistedSpawn(playerid, step);
public OnTwistedSpawn(playerid, step)
{
	switch(step)
	{
		case 3:
		{
			new tutorial = GetPVarType(playerid, "pRegistration_Tutorial");
			if(tutorial) {
				pTwistedIndex[playerid] = 5; // Roadkill
				//show tds and shit
			}
			playerData[playerid][pSpawned_Status] = 1;
			new Float:x, Float:y, Float:z, Float:angle;
			x = 1073.5100, y = -956.8530, z = 42.2946, angle = 278.6549;
			pVehicleID[playerid] = CreateVehicle(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], x, y, z + 0.7, angle, C_S_IDS[pTwistedIndex[playerid]][CS_Colour1], C_S_IDS[pTwistedIndex[playerid]][CS_Colour2], -1);
			SetVehicleVirtualWorld(pVehicleID[playerid], TUTORIAL_WORLD);
			setupTwistedVehicle(playerid, pVehicleID[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]);

			SetPlayerVirtualWorld(playerid, TUTORIAL_WORLD);
			SetPlayerInterior(playerid, 0);
			SetPlayerPos(playerid, x, y, z);
			PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			SetCameraBehindPlayer(playerid);

			TextDrawShowForPlayer(playerid, Players_Online_Textdraw);

			pHUDStatus[playerid] = HUD_MISSILES;
			pMissileID[playerid] = Missile_Special;
			new pm = 0;
			while(pm < TOTAL_WEAPONS)
			{
				playerData[playerid][pMissiles][pm] = 999; // debug hud
				++pm;
			}
			updatePlayerHUD(playerid);
			if(pHUDType[playerid] == HUD_TYPE_TMBLACK) {
				PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pHealthVerticalBar], 0.000000, -8.600000);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pHealthVerticalBar]);
			}
			playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;

			playerData[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]));
			playerData[playerid][pEnergy] = floatround(GetTwistedMetalMaxEnergy(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]));

			SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pHealthBar], floatround(GetTwistedMetalMaxHealth(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])));
			SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pTurboBar], floatround(GetTwistedMetalMaxTurbo(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])));
			SetPlayerProgressBarMaxValue(playerid, pTextInfo[playerid][pEnergyBar], floatround(GetTwistedMetalMaxEnergy(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID])));

			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));
			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], float(playerData[playerid][pTurbo]));
			UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
			UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
			SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
		}
		case 1:
		{
			playerData[playerid][pSpawned_Status] = 1;
			new Float:x, Float:y, Float:z, Float:angle;
			switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
			{
				case GM_RACE:
				{
					if((s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Max_Grids] + 1) <= CP_Progress[playerid] < Total_Race_Checkpoints)
					{
						--CP_Progress[playerid];
						SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
						x = Race_Checkpoints[CP_Progress[playerid]][0];
						y = Race_Checkpoints[CP_Progress[playerid]][1];
						z = Race_Checkpoints[CP_Progress[playerid]][2] + 3.0;
						angle = Angle2D(Race_Checkpoints[CP_Progress[playerid]][0], Race_Checkpoints[CP_Progress[playerid]][1], Race_Checkpoints[CP_Progress[playerid] + 1][0], Race_Checkpoints[CP_Progress[playerid] + 1][1] );
						MPClamp360(angle);
					}
					else if(CP_Progress[playerid] < Total_Race_Checkpoints)
					{
						SetCP(playerid, CP_Progress[playerid], CP_Progress[playerid] + 1, Total_Race_Checkpoints, RaceType);
					}
				}
				default: GetMapSpawnData(gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
			}
			SetPlayerSkin(playerid, playerData[playerid][pSkin]);
			pVehicleID[playerid] = CreateVehicle(C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], x, y, z + 0.7, angle, C_S_IDS[pTwistedIndex[playerid]][CS_Colour1], C_S_IDS[pTwistedIndex[playerid]][CS_Colour2], -1);
			SetVehicleVirtualWorld(pVehicleID[playerid], playerData[playerid][gGameID]);
			setupTwistedVehicle(playerid, pVehicleID[playerid], C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]);
			
			SetPlayerVirtualWorld(playerid, playerData[playerid][gGameID]);
			SetPlayerInterior(playerid, 0);
			SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
			SetPlayerPos(playerid, x, y, z);
			PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			SetCameraBehindPlayer(playerid);

			TextDrawShowForPlayer(playerid, Players_Online_Textdraw);

			StopAudioStreamForPlayer(playerid);
			/*switch(random(5)) {
				case 0: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/tm2-title-screen.mp3");
				case 1: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/tm2-new-york.mp3");
				case 2: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal OST - Deathwish.mp3");
				case 3: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal OST - Roadkill.mp3");
				case 4: PlayAudioStreamForPlayer(playerid, "http://www.lvcnr.net/tm/twisted_metal/Twisted Metal OST - Shotgunner.mp3");
			}*/
			OnTwistedSpawn(playerid, 2);
		}
		case 2:
		{
			if(pFirstTimeViewingMap[playerid] == 1)
			{
				SendClientMessage(playerid, -1, "Type "#cBlue"/controls "#cWhite"To See The Server Controls. Type "#cBlue"/tutorial "#cWhite"for a tutorial.");
				new end = GetMapInterpolationIndex(playerData[playerid][gGameID], false);
				if(end)
				{
					new start = GetMapInterpolationIndex(playerData[playerid][gGameID], true);
					for(new mv_Index = start; mv_Index <= end; mv_Index++)
					{
						if(mv_Interpolation[mv_Index][mv_Map] != gGameData[playerData[playerid][gGameID]][g_Map_id]) continue;
						LinkVehicleToInterior(pVehicleID[playerid], 1);
						SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
						SetPlayerPos(playerid, 56.6482, -53.1604, 0.3160);
						SetPlayerFacingAngle(playerid, 206.6024);
						GameTextForPlayer(playerid, " ", 5, 3);
						SetPlayerCameraPos(playerid, mv_Interpolation[mv_Index][mv_cPosX],
							mv_Interpolation[mv_Index][mv_cPosY], mv_Interpolation[mv_Index][mv_cPosZ]);
						SetPlayerCameraLookAt(playerid, mv_Interpolation[mv_Index][mv_cLPosX],
							mv_Interpolation[mv_Index][mv_cLPosY], mv_Interpolation[mv_Index][mv_cLPosZ]);
						SetTimerEx("ContinueInterpolation", 100, false, "iii", playerid, mv_Index, end);
						return 1;
					}
				}
				
			}
			else if(pFirstTimeViewingMap[playerid] == 2) {
				pFirstTimeViewingMap[playerid] = 0;
				LinkVehicleToInterior(pVehicleID[playerid], 0);
			}
			//PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
			//SetCameraBehindPlayer(playerid);
			pHUDStatus[playerid] = HUD_MISSILES;
			pMissileID[playerid] = Missile_Special;
			LastSpecialUpdateTick[playerid] = gettime();
			new pm = 0;
			while(pm < TOTAL_WEAPONS)
			{
				switch(pm)
				{
					case Missile_Special, Missile_Ricochet: playerData[playerid][pMissiles][pm] = 1;
					case Missile_Fire, Missile_Homing: playerData[playerid][pMissiles][pm] = 2;
					case Energy_Mines, Energy_EMP, Energy_Shield,
						Energy_Invisibility: playerData[playerid][pMissiles][pm] = 999;
					default:
					{
						playerData[playerid][pMissiles][pm] = 0;
						if(pm < MAX_MISSILEID)
						{
							PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][pm]);
						}
					}
				}
				++pm;
			}
			updatePlayerHUD(playerid);
			
			new model = GetVehicleModel(pVehicleID[playerid]);
			playerData[playerid][pTurbo] = floatround(GetTwistedMetalMaxTurbo(model));
			playerData[playerid][pEnergy] = floatround(GetTwistedMetalMaxEnergy(model));

			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));
			SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], float(playerData[playerid][pTurbo]));
			UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
			UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pTurboBar]);
			if(GetVehicleModel(pVehicleID[playerid]) != 0)
			{
				if(!IsPlayerInVehicle(playerid, pVehicleID[playerid]))
				{
					new Float:x, Float:y, Float:z, Float:angle;
					GetMapSpawnData(gGameData[playerData[playerid][gGameID]][g_Map_id], x, y, z, angle, playerid);
					SetVehiclePos(pVehicleID[playerid], x, y, z);
					SetVehicleZAngle(pVehicleID[playerid], angle);
					//SendClientMessageFormatted(playerid, -1, "You Took Long To Enter Your Vehicle (Model - ID: "#cBlue"%d - %d)", C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID], pVehicleID[playerid]);
					PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
				}
			}
			switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
			{
				case GM_RACE:
				{
					switch(Race_Position[playerid])
					{
						case 0: PlayerVehicleRacePosition(playerid, PVRP_Create, "*");
						default:
						{
							new text[4];
							valstr(text, Race_Position[playerid]);
							PlayerVehicleRacePosition(playerid, PVRP_Create, text);
						}
					}
				}
				case GM_HUNTED:
				{
					if(gHunted_Player[playerData[playerid][gGameID]][0] == INVALID_PLAYER_ID)
					{
						gHunted_Player[playerData[playerid][gGameID]][0] = Iter_Random(Player);
						if(playerData[gHunted_Player[playerData[playerid][gGameID]][0]][pSpawned_Status] == 1)
						{
							new engine, lights, alarm, doors, bonnet, boot, objective;
							GetVehicleParamsEx(pVehicleID[gHunted_Player[playerData[playerid][gGameID]][0]], engine, lights, alarm, doors, bonnet, boot, objective);
							SetVehicleParamsEx(pVehicleID[gHunted_Player[playerData[playerid][gGameID]][0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
						}
					}
					else if(gHunted_Player[playerData[playerid][gGameID]][0] == playerid)
					{
						new engine, lights, alarm, doors, bonnet, boot, objective;
						GetVehicleParamsEx(pVehicleID[gHunted_Player[playerData[playerid][gGameID]][0]], engine, lights, alarm, doors, bonnet, boot, objective);
						SetVehicleParamsEx(pVehicleID[gHunted_Player[playerData[playerid][gGameID]][0]], engine, lights, alarm, doors, bonnet, boot, VEHICLE_PARAMS_ON);
					}
				}
				case GM_TEAM_DEATHMATCH, GM_TEAM_LAST_MAN_STANDING:
				{
					foreach(iPlayersInGame[playerData[playerid][gGameID]], i)
					{
						AdjustTeamColoursForPlayer(i);
					}
					if(playerData[playerid][gTeam] == INVALID_GAME_TEAM)
					{
						playerData[playerid][gTeam] = random(MAX_TEAMS);
						if(playerData[playerid][gTeam] == TEAM_DOLLS)
						{
							playerData[playerid][gRival_Team] = TEAM_CLOWNS;
						}
						else playerData[playerid][gRival_Team] = TEAM_DOLLS;
						SendClientMessage(playerid, -1, "You Have Been Placed In A Random Team!");
						AddPlayerToGameTeam(playerid);
					}
					if(gGameData[playerData[playerid][gGameID]][g_Gamemode] == GM_TEAM_HUNTED)
					{
						if(gHunted_Player[playerData[playerid][gGameID]][playerData[playerid][gTeam]] == INVALID_PLAYER_ID)
						{
							AssignRandomTeamHuntedPlayer(playerData[playerid][gGameID], playerData[playerid][gTeam]);
						}
					}
				}
			}
			if(gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] > 0) {
				TogglePlayerControllable(playerid, false);
			} else {
				TogglePlayerControllable(playerid, true);
			}
			SetTimerEx("SetPlayerMapWorldBounds", 1500, false, "i", playerid);
			if(gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] > 1)
			{
				new sCount = 0;
				foreach(iPlayersInGame[playerData[playerid][gGameID]], i)
				{
					if(playerData[i][pSpawned_Status] == 0) continue;
					++sCount;
				}
				if(gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] > 10 && sCount == Iter_Count(iPlayersInGame[playerData[playerid][gGameID]])) {
					gGameData[playerData[playerid][gGameID]][g_Gamemode_Countdown_Time] = 10;
				}
			}
		}
	}
	return 1;
}

forward SetPlayerMapWorldBounds(playerid);
public SetPlayerMapWorldBounds(playerid)
{
	if(!IsPlayerInVehicle(playerid, pVehicleID[playerid]))
	{
		PutPlayerInVehicle(playerid, pVehicleID[playerid], 0);
	}
	return (gGameData[playerData[playerid][gGameID]][g_Map_id] >= MAX_MAPS) ? -1 : SetPlayerWorldBounds(playerid, s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_max_X], s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_min_X],
			s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_max_Y], s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_min_Y]);
}

attachMissileTargetCircle(type = TARGET_CIRCLE_CREATING, toobjectid, objectslot, vehicleid, Float:attachz = -1.0, Float:x = 0.0, Float:y = 0.0, Float:z = 0.0)
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
				if(light_slot != -1)
				{
					Vehicle_Missile_Lights[vehicleid][light_slot] = CreateObject(18647, x, y, z, 0, 90.0, 270.0, 300.0); //red neonlight
					Vehicle_Missile_Lights_Attached[vehicleid][light_slot] = objectslot;
				}
			}
		}
		AttachObjectToObject(Vehicle_Missile_Lights[vehicleid][light_slot], toobjectid, aX, aY, attachz, 0.0, 0.0, rZ, 1);
	}
}

//new missileobjectex = INVALID_OBJECT_ID;

calcMissileOffsets(playerid, vehicleid, &Float:distance, &Float:angle, &Float:x, &Float:y, &Float:z, Float:xCal, Float:yCal, Float:zCal, ping = -1, side = 0)
{
	z += zCal;

	x += (yCal * floatsin(-angle, degrees));
	y += (yCal * floatcos(-angle, degrees));

	angle += (side == 0) ? 270.0 : 90.0;
	x += (xCal * floatsin(-angle, degrees));
	y += (xCal * floatcos(-angle, degrees));
	angle -= (side == 0) ? 270.0 : 90.0;

	new Float:vx, Float:vy, Float:vz;
	GetVehicleVelocity(vehicleid, vx, vy, vz);
	vz = (vx + vy);
	if(vz < 0.0)
		vz *= -1;
	if(ping == -1)
		ping = GetPlayerPing(playerid);
	distance = vz * ping * 0.140; // ((vz < 0.0) ? -vz : vz)
	//printf("(vx + vy): %0.2f - ping: %d - distance: %0.2f", vz, ping, distance);
	x += (distance * floatsin(-angle, degrees));
	y += (distance * floatcos(-angle, degrees));
	/*if(IsValidObject(missileobjectex))
	{
		DestroyObject(missileobjectex);
	}
	missileobjectex = CreateObject(19282, x, y, z, 0.0, 0.0, (angle - 90.0));*/
}

////SetObjectRot(object, asin(z_vector), 0.0, 360 - atan2(x_vector, y_vetor));
calcMissileElevation(playerid, vehicleid, &Float:x, &Float:y, &Float:z, &Float:pitch, &Float:distance = 120.0)
{
	switch(playerData[playerid][Camera_Mode])
	{
		case CAMERA_MODE_FREE_LOOK:
		{
			new Float:CP[3], Float:FV[3], Float:elevation;
			GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);
			GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);
			FV[2] += 0.08;
			GetVehicleRotation(vehicleid, x, y, pitch);
			GetXYZOfVehicle(vehicleid, x, y, z, pitch, distance);
			FV[2] += getTwistedMetalCameraOffset(GetVehicleModel(vehicleid));
			elevation = FV[2] * distance; // + CP[2]
			if(elevation < 0.0) {
				elevation = 0.0;
			}
			z += elevation;
			//SendClientMessageFormatted(playerid, -1, "Z Vector: %0.2f - elevation: %0.2f", FV[2], elevation);
		}
		default:
		{
			new Float:yaw, Float:roll;
			GetVehicleRotation(vehicleid, yaw, roll, pitch);
			GetXYZOfVehicle(vehicleid, x, y, z, pitch, distance);
		}
	}
	return 1;
}

GetVehicleRotation(vehicleid, &Float:heading, &Float:altitude, &Float:pitch) // Credits DANGER1979
{
	new Float:quat_w, Float:quat_x, Float:quat_y, Float:quat_z;
	GetVehicleRotationQuat(vehicleid, quat_w, quat_x, quat_y, quat_z);
	ConvertNonNormaQuatToEuler(quat_w, quat_x, quat_z, quat_y, heading, altitude, pitch);
	return 1;
}

RotatePoint(&Float:X, &Float:Y, &Float:Z, Float: pitch, Float: yaw, Float: distance) {
	X -= (distance * floatcos(pitch, degrees) * floatsin(yaw, degrees));
	Y += (distance * floatcos(pitch, degrees) * floatcos(yaw, degrees));
	Z += (distance * floatsin(pitch, degrees));
}

GetXYZOfVehicle(vehicleid, &Float:X, &Float:Y, &Float:Z, Float: pitch, Float: distance) {
	new Float:yaw, Float:vZ;
	if(GetVehicleZAngle(vehicleid, yaw)) {
		GetVehiclePos(vehicleid, X, Y, Z);
		vZ = Z;
		RotatePoint(X, Y, Z, pitch, yaw, distance);
		if(Z < vZ) Z += 0.5;
	}
	return 1;
}

ConvertNonNormaQuatToEuler(Float: qw, Float: qx, Float:qy, Float:qz, &Float:heading, &Float:altitude, &Float:pitch) // Credits DANGER1979
{
	new Float: sqw = qw*qw;
	new Float: sqx = qx*qx;
	new Float: sqy = qy*qy;
	new Float: sqz = qz*qz;
	new Float: unit = sqx + sqy + sqz + sqw; // if normalised is one, otherwise is correction factor
	//normalised
	new Float: test = qx*qy + qz*qw;
	if (test > 0.499*unit)
	{ // singularity at north pole
		heading = 2*atan2(qx,qw);
		altitude = 3.141592653/2;
		pitch = 0;
		return 1;
	}
	if (test < -0.499*unit)
	{ // singularity at south pole
		heading = -2*atan2(qx,qw);
		altitude = -3.141592653/2;
		pitch = 0;
		return 1;
	}
	heading = -atan2(2*qy*qw - 2*qx*qz, sqx - sqy - sqz + sqw); // minus added to fit the gta-sa angle
	altitude = asin(2*test/unit);
	pitch = -atan2(2*qx*qw - 2*qy*qz, -sqx + sqy - sqz + sqw); // moved minus here
	return 1;
}

/*QuaternionToYawPitchRoll(vehicleid, &Float:x, &Float:y, &Float:z) {
	new Float:quat_w, Float:quat_x, Float:quat_y, Float:quat_z;
	GetVehicleRotationQuat(vehicleid, quat_w, quat_x, quat_y, quat_z);
	x = atan2(2*((quat_x*quat_y)+(quat_w+quat_z)),(quat_w*quat_w)+(quat_x*quat_x)-(quat_y*quat_y)-(quat_z*quat_z));
	y = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)),(quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
	z = asin(-2*((quat_x*quat_z)+(quat_w*quat_y)));
	return 1;
}

QuaternionGetYaw(Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z,&Float:yaw) {
	yaw = asin(-2*((quat_x*quat_z)+(quat_w*quat_y)));
	return 1;
}

QuaternionGetPitch(Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z,&Float:pitch) {
	pitch = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)),(quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
	return 1;
}

QuaternionGetRoll(Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z,&Float:roll) {
	roll = atan2(2*((quat_x*quat_y)+(quat_w+quat_z)),(quat_w*quat_w)+(quat_x*quat_x)-(quat_y*quat_y)-(quat_z*quat_z));
	return 1;
}*/
/*
CalcSlopeAtPoint(Float:x, Float:y, &Float:RXAngle, &Float:RYAngle)
{
	new Float:North[3], Float:South[3], Float:East[3], Float:West[3], Float:opposite, Float:hypotenuse;

	// Set slope positions
	North[0] = x;
	North[1] = y + 1;

	South[0] = x;
	South[1] = y - 1;

	East[0] = x + 1;
	East[1] = y;

	West[0] = x - 1;
	West[1] = y;

	// Use map andreas to get Z Values
	MapAndreas_FindZ_For2DCoord(North[0], North[1], North[2]);
	MapAndreas_FindZ_For2DCoord(South[0], South[1], South[2]);
	MapAndreas_FindZ_For2DCoord(East[0], East[1], East[2]);
	MapAndreas_FindZ_For2DCoord(West[0], West[1], West[2]);

	// Calculate Slope angles
	// North South RX
	hypotenuse = getdist3d(North[0], North[1], North[2], South[0], South[1], South[2]);
	opposite = getdist3d(North[0], North[1], North[2], North[0], North[1], South[2]);

	RXAngle = asin(floatdiv(opposite, hypotenuse));
	if(South[2] > North[2]) RXAngle *= -1;

	// West East RY
	hypotenuse = getdist3d(West[0], West[1], West[2], East[0], East[1], East[2]);
	opposite = getdist3d(West[0], West[1], West[2], West[0], West[1], East[2]);

	RYAngle = asin(floatdiv(opposite, hypotenuse));
	if(East[2] > West[2]) RYAngle *= -1;

	return 1;
}*/

findPlayerMissileTarget(playerid, vehicleid, slot, rear = 0)
{
	new Float:x, Float:y, Float:z, Float:angle, Float:tx, Float:ty, Float:tz,
		Float:anglebetween, Float:anglediff, target;
	GetVehiclePos(vehicleid, x, y, z);
	GetVehicleZAngle(vehicleid, angle);
	foreach(Vehicles, v)
	{
		if(v == vehicleid) continue;
		if(IsPlayerInVehicle(playerid, v) || !IsVehicleStreamedIn(v, playerid)
		|| GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
		target = Vehicle_Driver[v];
		if(target != INVALID_PLAYER_ID)
		{
			if(playerData[playerid][gTeam] == playerData[target][gTeam]) continue;
			switch(gGameData[playerData[target][gGameID]][g_Gamemode])
			{
				case GM_TEAM_DEATHMATCH, GM_TEAM_HUNTED, GM_TEAM_LAST_MAN_STANDING:
				{
					if(playerData[target][gTeam] == playerData[playerid][gTeam]) continue;
				}
			}
		}
		GetVehiclePos(v, tx, ty, tz);
		if(IsPlayerAimingAt(playerid, tx, ty, tz, 50.0))
		{
			anglebetween = Angle2D( x, y, tx, ty );
			MPClamp360(anglebetween);
			anglediff = (angle - anglebetween);
			MPClamp360(anglediff);
			//SendClientMessageFormatted(playerid, -1, "angle: %0.2f - Anglediff: %0.2f - diff: %0.2f", angle, anglebetween, anglediff);
			switch(rear)
			{
				case 0: if(90.0 <= anglediff <= 270.0) continue; // normal front fire
				case 1: if(270.0 <= anglediff <= 360.0 || 0.0 <= anglediff <= 90.0) continue; // rear fire
			}
			Vehicle_Missile_Following[vehicleid][slot] = v;
			break;
		}
	}
}

forward Hammerhead_Special(playerid, id, Float:startdis, Float:toX, Float:toY, Float:toZ, Float:vsX, Float:vsY);
public Hammerhead_Special(playerid, id, Float:startdis, Float:toX, Float:toY, Float:toZ, Float:vsX, Float:vsY)
{
	SendClientMessageFormatted(playerid, COLOR_RED,
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
			GetVehicleParamsEx(pVehicleID[target], engine, lights, alarm, doors, bonnet, boot, objective);
			SetVehicleParamsEx(pVehicleID[target], VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);
		}
		KillTimer(Special_Missile_Timer[playerid]);
		playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
		SetPVarInt(playerid, "Hammerhead_Special_Attacking", INVALID_PLAYER_ID);
		SetPVarInt(playerid, "Hammerhead_Special_Hit", INVALID_PLAYER_ID);
	}
	return 1;
}

Float:getTwistedMetalCameraOffset(modelid)
{
	new Float:offset;
	switch(modelid)
	{
		case TMC_BRIMSTONE: offset = 0.01;
		case TMC_THUMPER: offset = 0.0;
		case TMC_SPECTRE: offset = 0.01;
		case TMC_REAPER: offset = 0.03;
		case TMC_CRIMSON_FURY: offset = 0.0;
		case TMC_ROADKILL: offset = 0.0;
		case TMC_VERMIN: offset = 0.01;
		case TMC_MEATWAGON: offset = 0.01;
		case TMC_SHADOW: offset = 0.01;
		case TMC_OUTLAW: offset = 0.02;
		case TMC_SWEETTOOTH: offset = 0.04;
		case TMC_HAMMERHEAD: offset = 0.04;
		case TMC_JUNKYARD_DOG: offset = 0.04;
		case TMC_3_WARTHOG: offset = 0.02;
		case TMC_MANSLAUGHTER: offset = 0.04;
		case TMC_DARKSIDE: offset = 0.10;
		default: offset = 0.02;
	}
	return offset;
}

attachMinigunFlashToVehicle(playerid, vehicleid, Float:angle, modelid = 0)
{
	if(modelid == 0) {
		modelid = GetVehicleModel(vehicleid);
	}
	for(new go; go < 2; go++)
	{
		if(IsValidObject(Vehicle_Machine_Gun_Flash[vehicleid][go]))
		{
			DestroyObject(Vehicle_Machine_Gun_Flash[vehicleid][go]);
			Vehicle_Machine_Gun_Flash[vehicleid][go] = INVALID_OBJECT_ID;
		}
	}
	Vehicle_Machine_Gun_Flash[vehicleid][0] = CreateObject(18695, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 300.0);
	AttachObjectToObject(Vehicle_Machine_Gun_Flash[vehicleid][0], Vehicle_Machine_Gun_Object[vehicleid][0], axoff, ayoff, azoff, 0.0, 0.0, angle, 0);
	switch(modelid)
	{
		case TMC_JUNKYARD_DOG, TMC_DARKSIDE, TMC_SHADOW, TMC_MEATWAGON, TMC_MANSLAUGHTER, TMC_SWEETTOOTH, TMC_HAMMERHEAD, TMC_3_WARTHOG:
		{
			Vehicle_Machine_Gun_Flash[vehicleid][1] = CreateObject(18695, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 300.0);
			AttachObjectToObject(Vehicle_Machine_Gun_Flash[vehicleid][1], Vehicle_Machine_Gun_Object[vehicleid][1], axoff, ayoff, azoff, 0.0, 0.0, angle, 0);
		}
	}
	PlayerPlaySound(playerid, 1135, 0.0, 0.0, 0.0);
	return 1;
}

startTwistedSpecial(playerid, id, newkeys)
{
	if(playerData[playerid][pSpawned_Status] == 0
		|| promptMissileFire(playerid, Missile_Special) == 0) return 0;
	switch(GetVehicleModel(id))
	{
		case TMC_HAMMERHEAD:
		{
			new v = GetClosestVehicle(playerid, 30.0), Float:x, Float:y, Float:z,
				Float:sX, Float:sY, Float:sZ, Float:vX, Float:vY, Float:vZ;
			if(v == INVALID_VEHICLE_ID) return 1;
			playerData[playerid][pMissile_Charged] = Missile_Special;
			GetVehicleVelocity(v, vX, vY, vZ);
			SetVehicleVelocity(v, 0.0, 0.0, 0.0);
			GetVehiclePos(v, x, y, z);
			SetVehiclePos(v, x, y, z + 2.0);
			GetVehicleModelInfo(v, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
			z += sZ + 1.0;
			PushVehicleToPosition(id, x, y, z, 1.0);
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
		}
		case TMC_JUNKYARD_DOG:
		{
			if(playerData[playerid][pSpecial_Missile_Vehicle] != INVALID_VEHICLE_ID) {
				DestroyVehicle(playerData[playerid][pSpecial_Missile_Vehicle]);
			}
			new Float:x, Float:y, Float:z, Float:angle;
			GetVehiclePos(id, x, y, z);
			GetVehicleZAngle(id, angle);
			playerData[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(TMC_JUNKYARD_DOG_TAXI, x, y, z + 10, angle, 0, 0, -1);
			SetVehicleVirtualWorld(playerData[playerid][pSpecial_Missile_Vehicle], GetPlayerVirtualWorld(playerid));
			SetVehicleHealth(playerData[playerid][pSpecial_Missile_Vehicle], 2500.0);
			SetPVarInt(playerid, "Junkyard_Dog_Attach", playerData[playerid][pSpecial_Missile_Vehicle]);
			SendClientMessage(playerid, -1, "Hit Players With The Taxi By T-Sliding");
			SendClientMessage(playerid, -1, "Press ~k~~TOGGLE_SUBMISSIONS~ To Unhook The Taxi And Drop It As A Bomb");
		}
		case TMC_MANSLAUGHTER: SendClientMessage(playerid, -1, "Special Incomplete");
		case TMC_REAPER:
		{
			playerData[playerid][pSpecial_Using_Alt] = 0;
			playerData[playerid][pMissileSpecialUpdate] = 0;
			pFiring_Missile[playerid] = TMC_REAPER;
			SetPlayerAttachedObject(playerid, Reaper_Chainsaw_Index, Reaper_Chainsaw, Reaper_Chainsaw_Bone, 0.0, 0.0, 0.0, 80.0, 40.0, -10.0, 1.0, 1.0, 1.0);
			GameTextForPlayer(playerid, "~n~~n~~n~~n~~p~Click ~w~~k~~VEHICLE_FIREWEAPON_ALT~ ~w~To Fire The ~y~~h~Chainsaw!~n~~w~Do A Wheelie To Create A~n~~r~~h~Flame Saw!", 4000, 3);
		}
		case TMC_ROADKILL:
		{
			pFiring_Missile[playerid] = 1;
			playerData[playerid][pMissile_Special_Time] = 0;
			playerData[playerid][pMissileSpecialUpdate] = 0;
			playerData[playerid][pMissile_Charged] = Missile_Special;
			KillTimer(Special_Missile_Timer[playerid]);
			Special_Missile_Timer[playerid] = SetTimerEx("Roadkill_Special", 600, true, "ii", playerid, 1);
		}
		case TMC_SWEETTOOTH:
		{
			pFiring_Missile[playerid] = 1;
			playerData[playerid][pSpecial_Using_Alt] = 0;
			playerData[playerid][pMissile_Special_Time] = 0;
			playerData[playerid][pMissileSpecialUpdate] = 0;
			for(new i = 0; i != MAX_SWEETTOOTH_MISSILES; ++i)
			{
				SetTimerEx("fireMissile", (i * 225), false, "iiii", playerid, id, Missile_Special, newkeys);
			}
		}
		case TMC_3_WARTHOG:
		{
			pFiring_Missile[playerid] = 1;
			playerData[playerid][pSpecial_Using_Alt] = 0;
			playerData[playerid][pMissile_Special_Time] = 0;
			playerData[playerid][pMissileSpecialUpdate] = 0;
			for(new i = 0; i != MAX_WARTHOG_MISSILES; ++i)
			{
				SetTimerEx("fireMissile", (i * 220), false, "iiii", playerid, id, Missile_Special, newkeys);
			}
		}
		case TMC_THUMPER:
		{
			if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
			{
				DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
				playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
			}
			pFiring_Missile[playerid] = 1;
			playerData[playerid][pSpecial_Missile_Object] = CreateObject(18694, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(playerData[playerid][pSpecial_Missile_Object], id, 0.0, 2.0, -1.7, 0.0, 0.0, 0.0);
			playerData[playerid][pMissile_Special_Time] = 0;
			KillTimer(Special_Missile_Timer[playerid]);
			Special_Missile_Timer[playerid] = SetTimerEx("Thumper_Special", 100, true, "ii", playerid, id);
		}
		case TMC_DARKSIDE:
		{
			pFiring_Missile[playerid] = 1;
			playerData[playerid][pMissile_Charged] = Missile_Special;
			new Float:currspeed[3], Float:direction[3], Float:total;
			GetVehicleVelocity(id, currspeed[0], currspeed[1], currspeed[2]);
			total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
			total += 1.1;
			new Float:invector[3] = {0.0, -1.0, 0.0};
			RotatePointVehicleRotation(id, invector, direction[0], direction[1], direction[2]);
			SetVehicleVelocity(id, direction[0] * total, direction[1] * total, direction[2] * total);
			SetTimerEx("ReturnDarksidesSpeed", 1100, false, "iifff", playerid, id, currspeed[0], currspeed[1], currspeed[2]);
		}
		case TMC_OUTLAW: //2985 0.0 -0.5 0.4 0.0 0.0 90.0//mounted minigun
		{
			if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
			{
				DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
				playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
			}
			pFiring_Missile[playerid] = 1;
			KillTimer(Special_Missile_Timer[playerid]);
			playerData[playerid][pMissile_Special_Time] = 0;
			//362 0.1 -0.5 1.5 0.0 30.0 95.0//minigun model id
			playerData[playerid][pSpecial_Missile_Object] = CreateObject(Machine_Gun_Default_Object, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(playerData[playerid][pSpecial_Missile_Object], id, 0.1, -0.5, 1.5, 0.0, 30.0, 95.0);
			Special_Missile_Timer[playerid] = SetTimerEx("Outlaw_Special", 200, true, "ii", playerid, id);
		}
		case TMC_VERMIN, TMC_BRIMSTONE, TMC_SPECTRE, TMC_SHADOW, TMC_MEATWAGON:
		{
			fireMissile(playerid, id, Missile_Special, newkeys);
		}
	}
	return 1;
}

forward fireMissile(playerid, id, missileid, keys);
public fireMissile(playerid, id, missileid, keys)
{
	if(playerData[playerid][pSpawned_Status] == 0
		|| promptMissileFire(playerid, missileid) == 0) return 0;
	new slot = GetFreeMissileSlot(playerid, id), model = GetVehicleModel(id), Float:x, Float:y, Float:z, Float:a, Float:distance,
		Float:x2, Float:y2, Float:z2, Float:pitch, rear = 0;

	GetVehiclePos(id, x, y, z);
	GetVehicleZAngle(id, a);

	calcMissileElevation(playerid, id, x2, y2, z2, pitch);

	switch(missileid)
	{
		case Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
		{
			attachMinigunFlashToVehicle(playerid, id, a, model);
			slot = Vehicle_Machine_Gun_CurrentID[id];
			switch(model)
			{
				case TMC_JUNKYARD_DOG, TMC_DARKSIDE, TMC_SHADOW, TMC_MANSLAUGHTER, TMC_SWEETTOOTH, TMC_3_WARTHOG, TMC_HAMMERHEAD: {}
				case TMC_MEATWAGON: Vehicle_Machine_Gun_CurrentSlot[id] = 0;
				default: Vehicle_Machine_Gun_CurrentSlot[id] = 0;
			}
			calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid) / 2, Vehicle_Machine_Gun_CurrentSlot[id]);

			Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_CurrentID[id]] = CreateObject(/*1240*/Machine_Gun, x, y, z, 0, 0, a, 300.0);

			if(missileid == Missile_Machine_Gun_Upgrade)
			{ // combining 2 red + green to make yellow light
				Vehicle_Machine_Mega_Gun[id][Vehicle_Machine_Gun_CurrentID[id]] = CreateObject(19282, x, y, z, 0, 0, a, 300.0); // green 19283
				AttachObjectToObject(Vehicle_Machine_Mega_Gun[id][Vehicle_Machine_Gun_CurrentID[id]], Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_CurrentID[id]], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0);
			}

			MoveObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_CurrentID[id]], x2, y2, z2, MISSILE_SPEED);

			CallLocalFunction("OnMissileFire", "iiiii", playerid, id, Vehicle_Machine_Gun_CurrentID[id], missileid, Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_CurrentID[id]]);
			++Vehicle_Machine_Gun_CurrentID[id];
			if(IsValidObject(Vehicle_Machine_Gun_Object[id][1])) {
				++Vehicle_Machine_Gun_CurrentSlot[id];
				if(Vehicle_Machine_Gun_CurrentSlot[id] > 1) {
					Vehicle_Machine_Gun_CurrentSlot[id] = 0;
				}
			}
			if(Vehicle_Machine_Gun_CurrentID[id] >= MAX_MACHINE_GUN_SLOTS) Vehicle_Machine_Gun_CurrentID[id] = 0;
			return 1;
		}
		case Missile_Special:
		{
			SendClientMessage(playerid, -1, "Firing special");
			switch(GetVehicleModel(id))
			{
				case TMC_3_WARTHOG:
				{
					++playerData[playerid][pMissileSpecialUpdate];

					calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);

					new light_slot = GetFreeMissileLightSlot(id);
					if(light_slot != -1)
					{
						Vehicle_Missile_Lights[id][light_slot] = CreateObject(18651, x, y, z, 0.0, 0.0, 0.0, 300.0); // purple neonlight
						AttachObjectToObject(Vehicle_Missile_Lights[id][light_slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, a, 0);
						Vehicle_Missile_Lights_Attached[id][light_slot] = slot;
					}
					findPlayerMissileTarget(playerid, id, slot);
				}
				case TMC_REAPER:
				{
					pFiring_Missile[playerid] = 1;

					calcMissileOffsets(playerid, id, distance, a, x, y, z, 0.0, 0.0, 1.0, GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(Reaper_Chainsaw, x, y, z, 0.0, pitch, 90.0, 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);
					if(playerData[playerid][pMissileSpecialUpdate] == 1)
					{
						Vehicle_Smoke[id][slot] = CreateObject(18690, x, y, z - 1.3, 0, 0, 0, 300.0);
						AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 270.0, 0);
					}
					ApplyAnimation(playerid, "GRENADE", "WEAPON_throw", 4.0, 0, 0, 0, 0, 0, 1);
					findPlayerMissileTarget(playerid, id, slot);
					CallLocalFunction("OnMissileFire", "iiiii", playerid, id, -1, Missile_Special, INVALID_OBJECT_ID);
				}
				case TMC_ROADKILL:
				{
					new Float:offsetx;
					++playerData[playerid][pMissileSpecialUpdate];

					offsetx = 0.70;
					switch(playerData[playerid][pMissileSpecialUpdate])//offsetx -= (0.30 * (playerData[playerid][pMissileSpecialUpdate] - 1));
					{
						case 2: offsetx = 0.40;
						case 3: offsetx = 0.10;
						case 4: offsetx = -0.20;
						case 5: offsetx = -0.50;
						case 6: offsetx = -0.70;
						default: offsetx = 0.70;
					}
					calcMissileOffsets(playerid, id, distance, a, x, y, z, offsetx, VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, pitch, (a - 90.0),  300.0);
					SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, (z - 1.3), 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

					findPlayerMissileTarget(playerid, id, slot);
				}
				case TMC_SWEETTOOTH:
				{
					++playerData[playerid][pMissileSpecialUpdate];

					calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					findPlayerMissileTarget(playerid, id, slot);
				}
				case TMC_VERMIN:
				{
					pFiring_Missile[playerid] = 1;

					calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(19079, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

					findPlayerMissileTarget(playerid, id, slot);
				}
				case TMC_BRIMSTONE: //3092 - dead body
				{
					pFiring_Missile[playerid] = 1;

					calcMissileOffsets(playerid, id, distance, a, x, y, z, 0.0, 2.0, 1.3, GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(3092, x, y, z, 0, 0, 95.0, 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);
				}
				case TMC_SPECTRE:
				{
					pFiring_Missile[playerid] = 1;

					calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

					findPlayerMissileTarget(playerid, id, slot);
				}
				case TMC_SHADOW:
				{
					pFiring_Missile[playerid] = 1;

					calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(Shadow_Coffin, x, y, (z + 1.4), 0.0, pitch, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED, 0.0, 0.0, 360.0);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
				}
				case TMC_MEATWAGON:
				{
					pFiring_Missile[playerid] = 1;

					calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

					Vehicle_Missile[id][slot] = CreateObject(2146, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);

					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);

					findPlayerMissileTarget(playerid, id, slot);
				}
			}
		}
		case Energy_Shield: return cmd_shield(playerid, "");
		case Energy_Mines: return cmd_mine(playerid, "");
		case Energy_Invisibility: return cmd_invisibility(playerid, "");
		case Missile_Napalm:
		{
			tNapalm_Slot[playerid] = slot;

			pFiring_Missile[playerid] = 1;

			calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

			Vehicle_Missile[id][slot] = CreateObject(Missile_Napalm_Object, x, y, z, 0.0, 0.0, a + 180, 150.0);
			Vehicle_Smoke[id][slot] = CreateObject(18690, x, y, z - 1.3, 0, 0, 0, 150.0);
			AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);

			x += (65.0 * floatsin(-a, degrees));
			y += (65.0 * floatcos(-a, degrees));

			MoveObject(Vehicle_Missile[id][slot], x, y, z + 4.5, MISSILE_SPEED - 20);

			attachMissileTargetCircle(TARGET_CIRCLE_CREATING, Vehicle_Missile[id][slot], slot, id, _, x, y, z);
			return 1;
		}
		case Energy_EMP, Missile_Fire, Missile_Homing, Missile_Power, Missile_Stalker,
			Missile_RemoteBomb, Missile_Ricochet:
		{
			switch(missileid)
			{
				case Energy_EMP:
				{
					if(GetPVarInt(playerid, "pShot_EMP_Recently") > gettime())
					{
						AddEXPMessage(playerid, "~p~EMP Overheated!");
						return 1;
					}
				}
				case Missile_Stalker:
				{
					if(playerData[playerid][pMissile_Charged] == INVALID_MISSILE_ID)
					{
						playerData[playerid][pMissile_Charged] = missileid;
						pFiring_Missile[playerid] = 1;
						playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
						KillTimer(playerData[playerid][pCharge_Timer]);
						playerData[playerid][pCharge_Timer] = SetTimerEx("Charge_Missile", 195, true, "iii", playerid, id, missileid);
						return 1;
					}
				}
			}
			pFiring_Missile[playerid] = 1;
			if(320 <= keys <= 321 || keys == 329 || keys == 353)
			{
				a += 180.0;
				rear = 1;
			}
			new light_slots[2];

			calcMissileOffsets(playerid, id, distance, a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id], GetPlayerPing(playerid));

			switch(missileid)
			{
				case Missile_RemoteBomb: Vehicle_Missile[id][slot] = CreateObject(Missile_RemoteBomb_Object, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
				case Missile_Ricochet: Vehicle_Missile[id][slot] = CreateObject(Missile_Ricochet_Object, x, y, z, 0.0, 90.0, a, 300.0);
				default: Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, z, 0.0, pitch, (a - 90.0), 300.0);
			}
			//printf("x: %0.2f - y: %0.2f - z: %0.2f - x2: %0.2f - y2: %0.2f", x, y, z, x2, y2);
			switch(missileid)
			{
				case Energy_EMP:
				{
					findPlayerMissileTarget(playerid, id, slot, rear);
					Vehicle_Smoke[id][slot] = CreateObject(18728, x, y, z - 0.7, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1);
					SetPVarInt(playerid, "pShot_EMP_Recently", gettime() + 7);
					playerData[playerid][pEnergy] -= 15;
					SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pEnergyBar], float(playerData[playerid][pEnergy]));
					UpdatePlayerProgressBar(playerid, pTextInfo[playerid][pEnergyBar]);
				}
				case Missile_Fire:
				{
					findPlayerMissileTarget(playerid, id, slot, rear);
					//SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
					for(new L = 0, LS = sizeof(light_slots); L < LS; L++)
					{//red + yellow = orange
						light_slots[L] = GetFreeMissileLightSlot(id);
						switch(L)
						{
							case 0: Vehicle_Missile_Lights[id][light_slots[L]] = CreateObject(18647, x, y, z, 0, pitch, (a - 90.0), 300.0);
							default: Vehicle_Missile_Lights[id][light_slots[L]] = CreateObject(18650, x, y, z, 0, pitch, (a - 90.0), 300.0);
						}
						Vehicle_Missile_Lights_Attached[id][light_slots[L]] = slot;
						AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[L]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (a - 90.0) - a, 1);
					}
				}
				case Missile_Homing:
				{
					findPlayerMissileTarget(playerid, id, slot, rear);
					light_slots[0] = GetFreeMissileLightSlot(id);
					SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
					Vehicle_Missile_Lights[id][light_slots[0]] = CreateObject(18651, x, y, z, 0, pitch, (a - 90.0), 300.0); //purple neonlight
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[0]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (a - 90.0) - a, 1);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
					Vehicle_Missile_Lights_Attached[id][light_slots[0]] = slot;
				}
				case Missile_Power:
				{
					light_slots[0] = GetFreeMissileLightSlot(id);
					SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
					Vehicle_Missile_Lights[id][light_slots[0]] = CreateObject(18647, x, y, z, 0, pitch, (a - 90.0), 300.0); //red neonlight
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Missile_Lights[id][light_slots[0]], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (a - 90.0) - a, 1);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
					Vehicle_Missile_Lights_Attached[id][light_slots[0]] = slot;
				}
				case Missile_Ricochet:
				{
					//SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
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
					SetPVarInt(playerid, "Ricochet_Missile_Timer", SetTimerEx("explodeMissile", 3000, false, "iiii", playerid, id, slot, Missile_Ricochet));
				}
				case Missile_RemoteBomb:
				{
					findPlayerMissileTarget(playerid, id, slot, rear);
					SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
					Vehicle_Smoke[id][slot] = CreateObject(19283, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0);
				}
				case Missile_Stalker:
				{
					findPlayerMissileTarget(playerid, id, slot, rear);
					SetObjectMaterial(Vehicle_Missile[id][slot], Missile_Material_Index, Missile_Default_Object, Missile_Texture, Missile_Texture_Name, getMissileColour(missileid, .shift = 1));
					Vehicle_Smoke[id][slot] = CreateObject(Missile_Smoke_Object, x, y, z - 1.3, 0, 0, 0, 300.0);
					AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 1);
					playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
					KillTimer(playerData[playerid][pCharge_Timer]);
					SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pChargeBar], DEFAULT_CHARGE_INDEX);
					if(playerData[playerid][pMissiles][Missile_Stalker] > 0) {
						ShowPlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
					} else {
						HidePlayerProgressBar(playerid, pTextInfo[playerid][pChargeBar]);
					}
				}
			}
			MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED);
			if(Vehicle_Missile_Following[id][slot] != INVALID_VEHICLE_ID)
			{
				new vehicleid = Vehicle_Missile_Following[id][slot],
					Float:Old_Missile_Angle = a, Float:newangle, Float:difference;
				GetVehiclePos(vehicleid, x2, y2, z2);

				newangle = Angle2D( x, y, x2, y2 );
				MPClamp360(newangle);
				difference = (newangle - Old_Missile_Angle);
				MPClamp360(difference);
				//printf("y2: %0.2f - y: %0.2f - x2: %0.2f - x: %0.2f - newangle: %0.2f - Old_Missile_Angle: %0.2f -", y2, y, x2, x, newangle, Old_Missile_Angle);
				//printf("[fireMissile] %s difference: %0.2f", GetTwistedMissileName(missileid), difference);
				if(difference < GetTwistedMetalMissileAccuracy(playerid, missileid, GetVehicleModel(id), playerData[playerid][pSpecial_Using_Alt], 1))
				{
					Vehicle_Missile_Final_Angle[vehicleid][slot] = newangle;
					//SetObjectRot(Vehicle_Missile[id][slot], 0.0, 0.0, newangle);
					MoveObject(Vehicle_Missile[id][slot], x2, y2, z2, MISSILE_SPEED, 0.0, 0.0, newangle);
				}
			}
			//printf("tick: %d - missile %s - time object should take: %d", end, GetTwistedMissileName(missileid), move);
		}
	}
	CallLocalFunction("OnMissileFire", "iiiii", playerid, id, slot, missileid, Vehicle_Missile[id][slot]);
	return 1;
}

fireChargedMissile(playerid, newkeys)
{
	if(playerData[playerid][pMissile_Charged] == INVALID_MISSILE_ID || pFiring_Missile[playerid] == 0) return 0;
	new id = GetPlayerVehicleID(playerid);
	switch(playerData[playerid][pMissile_Charged])
	{
		case Missile_Special:
		{
			switch(GetVehicleModel(id))
			{
				case TMC_ROADKILL:
				{
					if(playerData[playerid][pMissile_Special_Time] == 0) return 1;
					GameTextForPlayer(playerid, " ", 1, 3);
					for(new i = 0; i < playerData[playerid][pMissile_Special_Time]; ++i)
					{
						fireMissile(playerid, id, playerData[playerid][pMissile_Charged], newkeys);
					}
					playerData[playerid][pMissile_Special_Time] = 0;
					playerData[playerid][pMissileSpecialUpdate] = 0;
					KillTimer(Special_Missile_Timer[playerid]); // FlashRoadkillForPlayer, Roadkill_Special
				}
			}
		}
		case Missile_Stalker: fireMissile(playerid, id, playerData[playerid][pMissile_Charged], newkeys);
	}
	playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
	return 1;
}

setupTwistedVehicle(playerid, vehicleid, model = -1)
{
	attachVehicleMachineGuns(vehicleid, Missile_Machine_Gun);
	attachTwistedObjectsToVehicle(playerid, vehicleid, model);
	loadPlayerCustomizationModels(playerid, vehicleid);
	SetVehicleNumberPlate(vehicleid, GetTwistedMetalName(model));
}

attachVehicleMachineGuns(vehicleid, missileid)
{
	new Float:x, Float:y, Float:z;
	if(GetVehiclePos(vehicleid, x, y, z))
	{
		destroyVehicleMachineGuns(vehicleid);
		switch(missileid)
		{
			case Missile_Machine_Gun:
			{
				Vehicle_Machine_Gunid[vehicleid] = Missile_Machine_Gun;
				new Float:ry = 0.0, model = GetVehicleModel(vehicleid);
				Vehicle_Machine_Gun_Object[vehicleid][0] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0.0, 0.0, 0.0, 300.0);
				switch(model)
				{
					case TMC_JUNKYARD_DOG: // Junkyard Dog / Tow Truck
					{
						VehicleOffsetX[vehicleid] = 1.0;
						VehicleOffsetY[vehicleid] = 2.5;
						VehicleOffsetZ[vehicleid] = 0.53;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0.0, 0.0, 0.0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.0, 2.5, 0.53, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.85, 2.5, 0.53, 0.0, 30.0, 95.0);
						VehicleOffsetY[vehicleid] = 2.6;
						VehicleOffsetZ[vehicleid] = 1.0;
						return 1;
					}
					case TMC_BRIMSTONE:
					{
						VehicleOffsetX[vehicleid] = 1.2;
						VehicleOffsetY[vehicleid] = -1.0;
						VehicleOffsetZ[vehicleid] = 0.53;
						ry = 30.0;
					}
					case TMC_OUTLAW:
					{
						VehicleOffsetX[vehicleid] = 0.40;
						VehicleOffsetY[vehicleid] = 2.30;
						VehicleOffsetZ[vehicleid] = 0.0;
						ry = 30.0;
					}
					case TMC_REAPER://1085 tire
					{
						VehicleOffsetX[vehicleid] = 0.07;
						VehicleOffsetY[vehicleid] = 0.50;
						VehicleOffsetZ[vehicleid] = 0.80;
						ry = 30.0;
					}
					case TMC_ROADKILL:
					{
						VehicleOffsetX[vehicleid] = 0.71;
						VehicleOffsetY[vehicleid] = 0.62;
						VehicleOffsetZ[vehicleid] = 0.61;
						ry = 30.0;
					}
					case TMC_THUMPER:
					{
						VehicleOffsetX[vehicleid] = 0.70;
						VehicleOffsetY[vehicleid] = 0.60;
						VehicleOffsetZ[vehicleid] = 0.60;
						ry = 30.0;
					}
					case TMC_SPECTRE:
					{
						VehicleOffsetX[vehicleid] = 1.04;
						VehicleOffsetY[vehicleid] = -0.7;
						VehicleOffsetZ[vehicleid] = 0.6;
						ry = 30.0;
					}
					case TMC_DARKSIDE:
					{
						VehicleOffsetX[vehicleid] = 1.2;
						VehicleOffsetY[vehicleid] = 3.3;
						VehicleOffsetZ[vehicleid] = 0.4;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.2, 3.3, 0.4, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 3.3, 0.4, 0.0, 30.0, 95.0);
						VehicleOffsetX[vehicleid] = 1.4;
						return 1;
					}
					case TMC_SHADOW:
					{
						VehicleOffsetX[vehicleid] = 1.1;
						VehicleOffsetY[vehicleid] = 1.0;
						VehicleOffsetZ[vehicleid] = 0.5;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.1, 1.0, 0.5, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.97, 1.0, 0.5, 0.0, 30.0, 95.0);
						VehicleOffsetX[vehicleid] = 1.2;
						VehicleOffsetY[vehicleid] = 1.60;
						return 1;
					}
					case TMC_MEATWAGON:
					{
						VehicleOffsetX[vehicleid] = -0.97;
						VehicleOffsetY[vehicleid] = 1.0;
						VehicleOffsetZ[vehicleid] = 0.5;
						ry = 30.0;
					}
					case TMC_VERMIN:
					{
						VehicleOffsetX[vehicleid] = 1.1;
						VehicleOffsetY[vehicleid] = 1.0;
						VehicleOffsetZ[vehicleid] = 0.5;
						ry = 30.0;
					}
					case TMC_3_WARTHOG:
					{
						VehicleOffsetX[vehicleid] = 0.8;
						VehicleOffsetY[vehicleid] = 0.8;
						VehicleOffsetZ[vehicleid] = 0.8;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 0.9, 0.8, 0.8, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.8, 0.8, 0.8, 0.0, 30.0, 95.0);
						VehicleOffsetY[vehicleid] = 1.6;
						return 1;
					}
					case TMC_MANSLAUGHTER:
					{
						VehicleOffsetX[vehicleid] = 1.3;
						VehicleOffsetY[vehicleid] = 3.0;
						VehicleOffsetZ[vehicleid] = 0.5;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.3, 3.0, 0.5, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 3.0, 0.5, 0.0, 30.0, 95.0);
						return 1;
					}
					case TMC_HAMMERHEAD:
					{
						VehicleOffsetX[vehicleid] = 1.3;
						VehicleOffsetY[vehicleid] = 2.8;
						VehicleOffsetZ[vehicleid] = 0.5;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0, 0, 0, 300.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.3, 2.8, 0.5, 0.0, 30.0, 95.0);
						AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 2.8, 0.5, 0.0, 30.0, 95.0);
						VehicleOffsetX[vehicleid] = 1.4;
						VehicleOffsetY[vehicleid] = 3.6;
						return 1;
					}
					case TMC_SWEETTOOTH:
					{
						VehicleOffsetX[vehicleid] = 1.2;
						VehicleOffsetY[vehicleid] = 1.7;
						VehicleOffsetZ[vehicleid] = 0.5;
						Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(Machine_Gun_Default_Object, x, y, z, 0, 0, 0, 300.0);
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
					case TMC_BRIMSTONE:
					{
						VehicleOffsetX[vehicleid] = 1.25;
						VehicleOffsetY[vehicleid] = 0.7;
						VehicleOffsetZ[vehicleid] = 0.53;
					}
					case TMC_OUTLAW:
					{
						VehicleOffsetX[vehicleid] = 0.40;
						VehicleOffsetY[vehicleid] = 2.90;
						VehicleOffsetZ[vehicleid] = 0.70;
					}
					case TMC_REAPER: //1085 tyre
					{
						VehicleOffsetY[vehicleid] = 0.60;
					}
					case TMC_ROADKILL:
					{
						VehicleOffsetX[vehicleid] = 0.80;
						VehicleOffsetY[vehicleid] = 1.0;
						VehicleOffsetZ[vehicleid] = 0.65;
					}
					case TMC_THUMPER:
					{
						VehicleOffsetX[vehicleid] = 0.75;
						VehicleOffsetY[vehicleid] = 1.40;
						VehicleOffsetZ[vehicleid] = 0.80;
					}
					case TMC_SPECTRE:
					{
						VehicleOffsetX[vehicleid] = 1.05;
						VehicleOffsetY[vehicleid] = 1.0;
						VehicleOffsetZ[vehicleid] = 0.70;
					}
					case TMC_MEATWAGON:
					{
						VehicleOffsetX[vehicleid] = -0.97;
						VehicleOffsetY[vehicleid] = 1.60;
					}
					case TMC_VERMIN:
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
				pMissileID[playerid] = missileid;
				return 1;
			}*/
		}
	}
	return 0;
}

destroyVehicleMachineGuns(vehicleid)
{
	if(vehicleid < 0 || vehicleid >= MAX_VEHICLES) return ;
	for(new i = 0; i < 2; ++i)
	{
		if(IsValidObject(Vehicle_Machine_Gun_Object[vehicleid][i])) {
			DestroyObject(Vehicle_Machine_Gun_Object[vehicleid][i]);
			Vehicle_Machine_Gun_Object[vehicleid][i] = INVALID_OBJECT_ID;
		}
	}
}

GetPlayerMissileCount(playerid)
{
	new i, count;
	for(i = MIN_MISSILEID; i < MAX_MISSILEID; ++i) //find total number of missiles
	{
		if(playerData[playerid][pMissiles][i] != 0) ++count;
	}
	return count;
}

updatePlayerHUD(playerid, missileid = -1)
{
	if(pHUDStatus[playerid] == HUD_ENERGY) {
		if(missileid != -1) {
			missileid = -1;
		}
	}
	if(missileid != -1 && missileid < MAX_MISSILEID)
	{
		if(playerData[playerid][pMissiles][missileid])
		{
			new str[32];
			switch(pHUDType[playerid])
			{
				case HUD_TYPE_TMPS3: format(str, 32, "%d", playerData[playerid][pMissiles][missileid]);
				default: format(str, 32, "%d %s", playerData[playerid][pMissiles][missileid], GetTwistedMissileName(missileid));
			}
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pMissileSign][missileid], str);
			PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][missileid], (pMissileID[playerid] == missileid) ? 0x00FF00FF : 100);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileSign][missileid]);
			if(pHUDType[playerid] == HUD_TYPE_TMPS3)
			{
				PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileImages][missileid], (pMissileID[playerid] == missileid) ? getMissileColour(missileid) : 100);
				PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileImages][missileid]);
			}
		}
		else
		{
			PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][missileid]);
			if(pHUDType[playerid] == HUD_TYPE_TMPS3)
				PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileImages][missileid]);
		}
		return ;
	}
	new i, mName[32];
	for( i = 0; i < MAX_MISSILEID; ++i )
	{
		if(playerData[playerid][pMissiles][i] > 0)
		{
			switch(pHUDType[playerid])
			{
				case HUD_TYPE_TMPS3:
				{
					format(mName, sizeof(mName), "%d", playerData[playerid][pMissiles][i]);
					PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileImages][i], (pMissileID[playerid] == i) ? getMissileColour(i) : 100);
					PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileImages][i]);
				}
				default: format(mName, sizeof(mName), "%d %s", playerData[playerid][pMissiles][i], GetTwistedMissileName(i));
			}
			PlayerTextDrawColor(playerid, pTextInfo[playerid][pMissileSign][i], (pMissileID[playerid] == i) ? 0x00FF00FF : 100);
			PlayerTextDrawSetString(playerid, pTextInfo[playerid][pMissileSign][i], mName);
			PlayerTextDrawShow(playerid, pTextInfo[playerid][pMissileSign][i]);
		}
		else
		{
			PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileSign][i]);
			if(pHUDType[playerid] == HUD_TYPE_TMPS3) {
				PlayerTextDrawHide(playerid, pTextInfo[playerid][pMissileImages][i]);
			}
		}
	}
	return ;
}

getNextHUDSlot(playerid, bool:update_hud = true)
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
	if(update_hud == true)
	{
		updatePlayerHUD(playerid, pMissileID[playerid]);
	}
	for(i = (imax - 1); i != imin; i--) // find the highest slot used
	{
		if(playerData[playerid][pMissiles][i] != 0) break;
		continue;
	}
	for(m = (pMissileID[playerid] + 1); m != (imax + 1); m++)
	{
		if(m > i || m >= imax)
		{
			for(m = imin; m != pMissileID[playerid]; m++)
			{
				if(playerData[playerid][pMissiles][m] == 0) continue;
				pMissileID[playerid] = m;
				break;
			}
			break;
		}
		if(playerData[playerid][pMissiles][m] == 0) continue;
		pMissileID[playerid] = m;
		break;
	}
	if(update_hud == true)
	{
		updatePlayerHUD(playerid, pMissileID[playerid]);
	}
	return pMissileID[playerid];
}

getPreviousHUDSlot(playerid, bool:update_hud = true)
{
	new m, imax, imin;
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
	if(update_hud == true)
	{
		updatePlayerHUD(playerid, pMissileID[playerid]);
	}
	for(m = pMissileID[playerid] - 1; m != (imin - 2); m--)
	{
		if(m < imin)
		{
			for(m = (imax - 1); m != imin; m--)
			{
				if(playerData[playerid][pMissiles][m] == 0) continue;
				pMissileID[playerid] = m;
				break;
			}
			break;
		}
		if(playerData[playerid][pMissiles][m] == 0) continue;
		pMissileID[playerid] = m;
		break;
	}
	if(update_hud == true)
	{
		updatePlayerHUD(playerid, pMissileID[playerid]);
	}
	return pMissileID[playerid];
}

/*GetDotXY(Float:StartPosX, Float:StartPosY, &Float:NewX, &Float:NewY, Float:alpha, Float:dist)
{
	NewX = StartPosX + (dist * floatsin(alpha, degrees));
	NewY = StartPosY + (dist * floatcos(alpha, degrees));
}*/

PlaySoundForPlayersInRange(soundid, Float:range, Float:x, Float:y, Float:z)
{
	foreach(Player, i)
	{
		if(!IsPlayerInRangeOfPoint(i, range, x, y, z)) continue;
		PlayerPlaySound(i, soundid, x, y, z);
	}
}

GetMapInterpolationIndex(gameid, start)
{
	new index = 0;
	if((0 <= gGameData[gameid][g_Map_id] <= (MAX_MAPS - 1)))
	{
		switch(start)
		{
			case 0: index = s_Maps[gGameData[gameid][g_Map_id]][m_Interpolation_Index]; // end
			//case 1: {} // start
		}
	}
	return index;
}

forward ContinueInterpolation(playerid, index, end);
public ContinueInterpolation(playerid, index, end)
{
	if(index == end)
	{
		pFirstTimeViewingMap[playerid] = 2;
		SetTimerEx("OnTwistedSpawn", mv_Interpolation[index - 1][mv_MoveTime] - 700, false, "ii", playerid, 2);
		GameTextForPlayerFormatted(playerid, "~n~~n~~w~Welcome To ~b~~h~%s", mv_Interpolation[index - 1][mv_MoveTime] + 300, 4, s_Maps[mv_Interpolation[index - 1][mv_Map]][m_Name]);
		return 1;
	}
	else SetTimerEx("ContinueInterpolation", mv_Interpolation[index][mv_MoveTime] - 100, false, "iii", playerid, (index + 1), end);
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

attachTwistedObjectsToVehicle(playerid, vehicleid, model = -1)
{
	if(model == -1) {
		model = GetVehicleModel(vehicleid);
	}
	destroyTwistedAttributes(playerid, model);
	switch(model)
	{
		case TMC_SWEETTOOTH:
		{
			playerData[playerid][pSpecialObjects][0] = CreateObject(18691, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][0], pVehicleID[playerid], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			//spike 1593
			playerData[playerid][pSpecialObjects][1] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(playerData[playerid][pSpecialObjects][1], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][1], pVehicleID[playerid], 0.0, 2.4, -0.2, 0.0, 90.0, 90.0);

			playerData[playerid][pSpecialObjects][2] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(playerData[playerid][pSpecialObjects][2], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][2], pVehicleID[playerid], 0.0, 2.4, -0.4, 0.0, 90.0, 90.0);

			playerData[playerid][pSpecialObjects][3] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(playerData[playerid][pSpecialObjects][3], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][3], pVehicleID[playerid], 0.0, 2.5, -0.4, 0.0, 90.0, 90.0);

			playerData[playerid][pSpecialObjects][4] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(playerData[playerid][pSpecialObjects][4], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][4], pVehicleID[playerid], 0.0, 2.5, -0.5, 0.0, 90.0, 90.0);

			playerData[playerid][pSpecialObjects][5] = CreateObject(1593, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			SetObjectMaterial(playerData[playerid][pSpecialObjects][5], 0, 18837, "mickytextures", "ws_gayflag1", 0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][5], pVehicleID[playerid], 0.0, 2.5, -0.7, 0.0, 90.0, 90.0);
		}
		case TMC_VERMIN:
		{
			playerData[playerid][pSpecialObjects][0] = CreateObject(3797, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(playerData[playerid][pSpecialObjects][0], pVehicleID[playerid], 0.0, -0.4, 1.6, 0.0, 180.0, 90.0);
		}
		case TMC_DARKSIDE: SetPlayerAttachedObject(playerid, Darkside_Mask, 19036, 2, 0.1, 0.04, 0.0, 90.0, 90.0, 0.0, 1.0, 1.0, 1.0);
	}
	new id = MAX_SPECIAL_OBJECTS - 1, Float:sX, Float:sY, Float:sZ;
	playerData[playerid][pSpecialObjects][id] = CreateObject(19198, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0); //19198, "EnExMarkers", "enexmarker1"
	//SetObjectMaterial(playerData[playerid][pSpecialObjects][id], 0, 19198, "none", "none", GetTwistedMetalColour(model, .shift = 1));
	//SetObjectMaterial(playerData[playerid][pSpecialObjects][id], 1, 19198, "none", "none", GetTwistedMetalColour(model, .shift = 1));
	GetVehicleModelInfo(model, VEHICLE_MODEL_INFO_SIZE, sX, sY, sZ);
	AttachObjectToVehicle(playerData[playerid][pSpecialObjects][id], pVehicleID[playerid], 0.0, 0.0, (sZ * 1.7), 0.0, 0.0, 0.0);
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

destroyTwistedAttributes(playerid, model = 0)
{
	for(new sp = 0; sp < MAX_SPECIAL_OBJECTS; sp++)
	{
		if(IsValidObject(playerData[playerid][pSpecialObjects][sp]))
		{
			DestroyObject(playerData[playerid][pSpecialObjects][sp]);
			playerData[playerid][pSpecialObjects][sp] = INVALID_OBJECT_ID;
		}
	}
	switch(model)
	{
		case TMC_DARKSIDE: RemovePlayerAttachedObject(playerid, Darkside_Mask);
	}
	return 1;
}

destroyTwistedVehicle(playerid, &vehicleid)
{
	if(vehicleid >= 1 && vehicleid <= MAX_VEHICLES)
	{
		destroyVehicleMachineGuns(vehicleid);
		destroyTwistedAttributes(playerid, C_S_IDS[pTwistedIndex[playerid]][CS_VehicleModelID]);
		unloadPlayerCustomizationModels(playerid);
		new ret = DestroyVehicle(vehicleid);
		vehicleid = 0;
		return ret;
	}
	return 0;
}

destroyAllTwistedMetalData(playerid) 
{
	new vehicleid = pVehicleID[playerid];
	KillTimer(Mine_Timer[playerid]);
	for(new s = 0; s < MAX_MISSILE_SLOTS; s++)
	{
		if(Vehicle_Missile_Following[vehicleid][s] != INVALID_VEHICLE_ID)
		{
			Vehicle_Missile_Following[vehicleid][s] = INVALID_VEHICLE_ID;
			Vehicle_Missile_Final_Angle[vehicleid][s] = 0.0;
		}
		if(IsValidObject(Vehicle_Missile[vehicleid][s]))
		{
			Object_Owner[Vehicle_Missile[vehicleid][s]] = INVALID_VEHICLE_ID;
			Object_OwnerEx[Vehicle_Missile[vehicleid][s]] = INVALID_PLAYER_ID;
			Object_Type[Vehicle_Missile[vehicleid][s]] = -1;
			Object_Slot[Vehicle_Missile[vehicleid][s]] = -1;
			DestroyObject(Vehicle_Missile[vehicleid][s]);
			Vehicle_Missile[vehicleid][s] = INVALID_OBJECT_ID;
		}
		Vehicle_Missile[vehicleid][s] = INVALID_OBJECT_ID;
		if(IsValidObject(Vehicle_Smoke[vehicleid][s]))
		{
			DestroyObject(Vehicle_Smoke[vehicleid][s]);
			Vehicle_Smoke[vehicleid][s] = INVALID_OBJECT_ID;
		}
		Vehicle_Smoke[vehicleid][s] = INVALID_OBJECT_ID;
	}
	Vehicle_Missile_Reset_Fire_Time[vehicleid] = 0;
	Vehicle_Missile_Reset_Fire_Slot[vehicleid] = -1;
	
	for(new st = 0; st < sizeof(StatusTextPositions); st++) {
		KillTimer(pStatusInfo[playerid][StatusTextTimer][st]);
		pStatusInfo[playerid][StatusTextTimer][st] = -1;
	}
	for(new xp = 0; xp < MAX_XP_STATUSES; xp++) {
		PlayerTextDrawHide(playerid, pTextInfo[playerid][pEXPStatus][xp]);
		PlayerTextDrawDestroy(playerid, pTextInfo[playerid][pEXPStatus][xp]);
	}
	TextDrawHideForPlayer(playerid, Players_Online_Textdraw);
	DestroyHUD(playerid);
	destroyTwistedVehicle(playerid, pVehicleID[playerid]);
	if(IsValidObject(playerData[playerid][pSpecial_Missile_Object])) {
		DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
		playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
	}
}

/*
//Snow: 3942, bistro, mp_snow
Ground under the lava: 18752, Volcano, redgravel
Lava: 18752, Volcano, lavalake
*/

GetMapSpawnData(mapid, &Float:x, &Float:y, &Float:z, &Float:angle, playerid = INVALID_PLAYER_ID)
{
	switch(gGameData[playerData[playerid][gGameID]][g_Gamemode])
	{
		case GM_RACE: // MAP_DIABLO_PASS
		{
			if(playerid != INVALID_PLAYER_ID)
			{
				if(isValueOdd(playerid)) r_Index = random(s_Maps[mapid][m_Max_Grids] - 1);
				else r_Index = random(s_Maps[mapid][m_Max_Grids]);
			}
			else r_Index = random(s_Maps[mapid][m_Max_Grids]);
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
				default:
				{
					new idx = -1, s, si, count[MAX_MAP_SPAWNS];
					for( ; si < sizeof(m_Map_Spawns); si++ )
					{
						if( m_Map_Spawns[si][s_Mapid] != mapid ) continue;
						count[s++] = si;
					}
					if(s == 0)
					{
						z = 15.0;
						return printf("[System: GetMapSpawnData] - Spawn Index Error [1]");
					}
					idx = count[random(s)];
					x = m_Map_Spawns[idx][s_X];
					y = m_Map_Spawns[idx][s_Y];
					z = m_Map_Spawns[idx][s_Z];
					angle = m_Map_Spawns[idx][s_Angle];
				}
			}
		}
	}
	return 1;
}

THREAD:OnModelSaveComplete(playerid, i)
{
	GameTextForPlayer(playerid, "~b~Saving Complete", 3000, 3);
	return 1;
}

isServerAdmin(playerid, level = ADMIN_LEVEL_TRIAL) return playerData[playerid][pAdminLevel] >= level || IsPlayerAdmin(playerid);

toggleAccountSave(playerid, Account_Flags:var)
{
	if(!BitFlag_Get(Account_Saving_Update[playerid], var))
		BitFlag_On(Account_Saving_Update[playerid], var);
}

savePlayerAccount(playerid, automated = 1, disconnecting = 0)
{
	if(IsPlayerNPC(playerid) || pLogged_Status[playerid] == 0) return 0;
	new Query[512], timebetween, gtime = gettime();
	timebetween = gtime - playerData[playerid][pConnect_Time];
	playerData[playerid][pTime_Played] += timebetween;
	format(Query, sizeof(Query), "UPDATE "#mySQL_Accounts_Table" SET `pTime_Played`=%d, `pMoney`=%d",
		playerData[playerid][pTime_Played], playerData[playerid][pMoney]
	);
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ADMIN)) {
		format(Query, sizeof(Query), "%s,`pAdminLevel`=%d", Query, playerData[playerid][pAdminLevel]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ADMIN);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLS)) {
		format(Query, sizeof(Query), "%s,`pKills`=%d", Query, playerData[playerid][pKills]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_DEATHS)) {
		format(Query, sizeof(Query), "%s,`pDeaths`=%d", Query, playerData[playerid][pDeaths]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_DEATHS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ASSISTS)) {
		format(Query, sizeof(Query), "%s,`pKillAssists`=%d", Query, playerData[playerid][pKillAssists]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_ASSISTS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLSTREAKS)) {
		format(Query, sizeof(Query), "%s,`pKillStreaks`=%d", Query, playerData[playerid][pKillStreaks]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_KILLSTREAKS);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_EXPRIENCE)) {
		format(Query, sizeof(Query), "%s,`pExprience`=%d", Query, playerData[playerid][pExprience]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_EXPRIENCE);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LAST_EXPRIENCE)) {
		format(Query, sizeof(Query), "%s,`pLast_Exp_Gained`=%d", Query, playerData[playerid][pLast_Exp_Gained]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LAST_EXPRIENCE);
	}
	if(BitFlag_Get(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LEVEL)) {
		format(Query, sizeof(Query), "%s,`pLevel`=%d,`pTier_Points`=%d", Query, playerData[playerid][pLevel], playerData[playerid][pTier_Points]);
		BitFlag_Off(Account_Saving_Update[playerid], ACCOUNT_UPDATE_LEVEL);
	}
	format(Query, sizeof(Query), "%s WHERE `Username` = '%s' LIMIT 1", Query, playerName(playerid));
	mysql_tquery(mysqlConnHandle, Query, "Thread_OnPlayerDataSaved", "iii", playerid, automated, disconnecting);
	return 1;
}

THREAD:OnPlayerDataSaved(playerid, automated, disconnecting)
{
	if(disconnecting == 0)
	{
		switch(automated)
		{
			case 0: SendClientMessageFormatted(playerid, -1, "Your "#cYellow"Player Data "#cWhite"Has Manually Been "#cGreenYellow"Saved");
			case 1: SendClientMessageFormatted(playerid, -1, "Your "#cYellow"Player Data "#cWhite"Has Automatically Been "#cGreenYellow"Saved");
		}
	}
	return 1;
}

isNumeric(const string[])
{
	new length = strlen(string);
	if(length == 0 || isnull(string)) return false;
	for(new i = 0; i < length; i++)
	{
		if((string[i] > '9' || string[i] < '0' && string[i] != '-' && string[i] != '+') // Not a number,'+' or '-'
			 || (string[i] == '-' && i != 0)											 // A '-' but not at first.
			 || (string[i] == '+' && i != 0)											 // A '+' but not at first.
		 ) return false;
	}
	if(length == 1 && (string[0] == '-' || string[0] == '+')) return false;
	return true;
}

playerName(playerid)
{
	if(playerid < 0 || playerid >= MAX_PLAYERS) return pNameNone;
	return pName[playerid];
}

clearPlayerCurrentChatLines(playerid)
{
	for(new i = 0; i < 10; ++i)
	{
		SendClientMessage(playerid, -1, "");
	}
	return 1;
}

resetPlayerConnectionVariables(playerid)
{
	pLogged_Status[playerid] = 0;
	pSpawn_Request[playerid] = SPAWN_REQUEST_NONE;
	playerData[playerid][gGameID] = INVALID_GAME_ID;
	//DeActiveSpeedometer{playerid} = 0;
	playerData[playerid][pSpawned_Status] = 0;
	bPlayerGameSettings[playerid] = General_Vars:0;
	iCurrentState[playerid] = PLAYER_STATE_NONE;
	playerData[playerid][pConnect_Time] = 0;
	playerData[playerid][pDonaterRank] = 0;
	playerData[playerid][pMoney] = 0;
	playerData[playerid][pKills] = 0;
	playerData[playerid][pDeaths] = 0;
	playerData[playerid][pKillAssists] = 0;
	playerData[playerid][pKillStreaks] = 0;
	playerData[playerid][pExprience] = 0;
	playerData[playerid][pLast_Exp_Gained] = 0;
	playerData[playerid][pLevel] = 1;
	playerData[playerid][pTier_Points] = 0;
	playerData[playerid][pTravelled_Distance] = 0.0;
	playerData[playerid][pFavourite_Vehicle] = 0;
	playerData[playerid][pFavourite_Map] = -1;
	playerData[playerid][pTime_Played] = 0;
	playerData[playerid][pAdminLevel] = 0;
	playerData[playerid][pRegular] = 0;
	playerData[playerid][gTeam] = INVALID_GAME_TEAM;
	playerData[playerid][pLast_Killed_By] = INVALID_PLAYER_ID;
	playerData[playerid][g_pExprience] = 0;
	pSpectate_Random_Teammate[playerid] = 0;
	Objects_Preloaded[playerid] = 0;
	if(playerData[playerid][gGameID] != INVALID_GAME_ID)
	{
		if((0 <= gGameData[playerData[playerid][gGameID]][g_Map_id] <= (MAX_MAPS - 1)))
		{
			CP_Progress[playerid] = s_Maps[gGameData[playerData[playerid][gGameID]][g_Map_id]][m_Max_Grids];
		}
	}
	Race_Current_Lap[playerid] = 1;
	Race_Position[playerid] = 0;
	Race_Old_Position[playerid] = 0;
	p_Position[playerid] = 0;
	p_Old_Position[playerid] = 0;
	pPaused[playerid] = false;
	Delete3DTextLabel(pPausedText[playerid]);
	pPausedText[playerid] = Text3D:INVALID_3DTEXT_ID;
	playerData[playerid][Camera_Mode] = CAMERA_MODE_NONE;
	playerData[playerid][Camera_Object] = INVALID_OBJECT_ID;
	Selecting_Textdraw[playerid] = 0;
	ResetPlayerGamePoints(playerid);
	if(IsValidObject(Race_Object[playerid]))
	{
		DestroyObject(Race_Object[playerid]);
		Race_Object[playerid] = INVALID_OBJECT_ID;
	}
	resetPlayerGameVariables(playerid);
	return 1;
}

resetPlayerGameVariables(playerid)
{
	DisablePlayerCheckpoint(playerid);
	DisablePlayerRaceCheckpoint(playerid);
	new pm = 0;
	while(pm < 9)
	{
		playerData[playerid][pMissiles][pm] = 0;
		++pm;
	}
	playerData[playerid][pMissiles][Missile_Machine_Gun_Upgrade] = 0;
	EditPlayerSlot(playerid, _, PLAYER_MISSILE_SLOT_CLEAR);
	pFiring_Missile[playerid] = 0;
	EMPTime[playerid] = 0;
	pHUDStatus[playerid] = HUD_MISSILES;
	playerData[playerid][pTurbo] = 0;
	playerData[playerid][pEnergy] = 0;
	playerData[playerid][Turbo_Tick] = 0;
	playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
	playerData[playerid][pBurnout] = 0;
	playerData[playerid][pGender] = true;
	playerData[playerid][pSpecial_Using_Alt] = 0;
	playerData[playerid][pMissile_Special_Time] = 0;
	playerData[playerid][pMissileSpecialUpdate] = 0;
	playerData[playerid][pMissile_Charged] = INVALID_MISSILE_ID;
	playerData[playerid][CanExitVeh] = 0;
	playerData[playerid][pKillStreaking] = -1;
	if(2001 <= playerData[playerid][pSpecial_Missile_Vehicle] <= 4000)
	{
		playerData[playerid][pSpecial_Missile_Vehicle] -= 2000;
		DestroyVehicle(playerData[playerid][pSpecial_Missile_Vehicle]);
	}
	if(4001 <= playerData[playerid][pSpecial_Missile_Vehicle] <= 6000)
	{
		playerData[playerid][pSpecial_Missile_Vehicle] -= 4000;
		DestroyVehicle(playerData[playerid][pSpecial_Missile_Vehicle]);
	}
	if(IsValidObject(playerData[playerid][pSpecial_Missile_Object]))
	{
		DestroyObject(playerData[playerid][pSpecial_Missile_Object]);
		playerData[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
	}
	playerData[playerid][pSpecial_Missile_Vehicle] = 0;
	playerData[playerid][pCharge_Index] = DEFAULT_CHARGE_INDEX;
	KillTimer(Mine_Timer[playerid]);
	KillTimer(Special_Missile_Timer[playerid]);
	KillTimer(playerData[playerid][Turbo_Timer]);
	KillTimer(Machine_Gun_Firing_Timer[playerid]);
	KillTimer(playerData[playerid][pCharge_Timer]);
	KillTimer(playerData[playerid][EnvironmentalCycle_Timer]);
	if(IsValidObject(Nitro_Bike_Object[playerid]))
	{
		DestroyObject(Nitro_Bike_Object[playerid]);
		Nitro_Bike_Object[playerid] = INVALID_OBJECT_ID;
	}
	return 1;
}

createPlayerTextdraws(playerid)
{
	pTextInfo[playerid][pTextWrapper] = CreatePlayerTextDraw(playerid, 0.0, 0.0, "Wrapper");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pTextWrapper], 0x00);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pTextWrapper], 0x00);

	gClass_Name[playerid] = CreatePlayerTextDraw(playerid, 520.000000, 275.000000, "Sweet Tooth");
	PlayerTextDrawAlignment(playerid, gClass_Name[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, gClass_Name[playerid], 255);
	PlayerTextDrawFont(playerid, gClass_Name[playerid], 1);
	PlayerTextDrawLetterSize(playerid, gClass_Name[playerid], 0.579999, 1.899999);
	PlayerTextDrawColor(playerid, gClass_Name[playerid], -1);
	PlayerTextDrawSetOutline(playerid, gClass_Name[playerid], 0);
	PlayerTextDrawSetProportional(playerid, gClass_Name[playerid], 1);
	PlayerTextDrawSetShadow(playerid, gClass_Name[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, gClass_Name[playerid], 0);

	gClass_Team_Name[playerid] = CreatePlayerTextDraw(playerid, 548.000000, 301.000000, "The Clowns");
	PlayerTextDrawAlignment(playerid, gClass_Team_Name[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, gClass_Team_Name[playerid], 255);
	PlayerTextDrawFont(playerid, gClass_Team_Name[playerid], 1);
	PlayerTextDrawLetterSize(playerid, gClass_Team_Name[playerid], 0.520000, 1.699998);
	PlayerTextDrawColor(playerid, gClass_Team_Name[playerid], -1);
	PlayerTextDrawSetOutline(playerid, gClass_Team_Name[playerid], 0);
	PlayerTextDrawSetProportional(playerid, gClass_Team_Name[playerid], 1);
	PlayerTextDrawSetShadow(playerid, gClass_Team_Name[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, gClass_Team_Name[playerid], 0);

	gClass_Team_Model[playerid] = CreatePlayerTextDraw(playerid, 458.000000, 288.000000, "teamskin");
	PlayerTextDrawAlignment(playerid, gClass_Team_Model[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, gClass_Team_Model[playerid], 0);
	PlayerTextDrawFont(playerid, gClass_Team_Model[playerid], 5);
	PlayerTextDrawLetterSize(playerid, gClass_Team_Model[playerid], 0.000000, -0.000001);
	PlayerTextDrawColor(playerid, gClass_Team_Model[playerid], -1);
	PlayerTextDrawSetOutline(playerid, gClass_Team_Model[playerid], 0);
	PlayerTextDrawSetProportional(playerid, gClass_Team_Model[playerid], 1);
	PlayerTextDrawSetShadow(playerid, gClass_Team_Model[playerid], 1);
	PlayerTextDrawUseBox(playerid, gClass_Team_Model[playerid], 1);
	PlayerTextDrawBoxColor(playerid, gClass_Team_Model[playerid], 0);
	PlayerTextDrawTextSize(playerid, gClass_Team_Model[playerid], 37.000000, 47.000000);
	PlayerTextDrawSetPreviewModel(playerid, gClass_Team_Model[playerid], 264);
	PlayerTextDrawSetPreviewRot(playerid, gClass_Team_Model[playerid], 0.000000, 90.000000, 0.000000, 0.899999);
	PlayerTextDrawSetSelectable(playerid, gClass_Team_Model[playerid], 0);

	pTextInfo[playerid][AimingPlayer] = CreatePlayerTextDraw(playerid, 102.000000, 314.000000, "Roadkill");
	PlayerTextDrawAlignment(playerid, pTextInfo[playerid][AimingPlayer], 2);
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][AimingPlayer], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][AimingPlayer], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][AimingPlayer], 0.310000, 1.000000);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][AimingPlayer], -1);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][AimingPlayer], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][AimingPlayer], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][AimingPlayer], 1);

	//pTextInfo[playerid][AimingBox] = CreatePlayerTextDraw(playerid, 152.000000, 316.000000, "_");
	//PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][AimingBox], 255);
	//PlayerTextDrawFont(playerid, pTextInfo[playerid][AimingBox], 1);
	//PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][AimingBox], 1.130000, 1.500000);
	//PlayerTextDrawColor(playerid, pTextInfo[playerid][AimingBox], -1);
	//PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][AimingBox], 0);
	//PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][AimingBox], 1);
	//PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][AimingBox], 1);
	//PlayerTextDrawUseBox(playerid, pTextInfo[playerid][AimingBox], 1);
	//PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][AimingBox], 150);
	//PlayerTextDrawTextSize(playerid, pTextInfo[playerid][AimingBox], 56.000000, 1.000000);

	pTextInfo[playerid][pHealthVerticalBar] = CreatePlayerTextDraw(playerid, 627.000000, 418.000000, "  ");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 65535);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pHealthVerticalBar], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pHealthVerticalBar], 0.0, -8.60);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 16711935);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pHealthVerticalBar], 1);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pHealthVerticalBar], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pHealthVerticalBar], 1);
	PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pHealthVerticalBar], 0x00F000FF);
	PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pHealthVerticalBar], 598.000000, 0.000000);

	pTextInfo[playerid][pLevelText] = CreatePlayerTextDraw(playerid, 115.000000, 430.000000, "Level: 1");
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pLevelText], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pLevelText], 1);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pLevelText], 0.360, 1.0);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pLevelText], 0xB3B3B3FF);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pLevelText], 0);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pLevelText], 1);
	PlayerTextDrawSetShadow(playerid, pTextInfo[playerid][pLevelText], 1);
	PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pLevelText], 0);

	pTextInfo[playerid][pEXPText] = CreatePlayerTextDraw(playerid, 448.000000, 430.000000, "XP: 0");
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
	
	pTextInfo[playerid][pC_Select_Header_Text] = CreatePlayerTextDraw(playerid, 543.000000, 188.000000, "SELECT AN OBJECT TO ATTACH~n~TO YOUR VEHICLE");
	PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pC_Select_Header_Text], 2);
	PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_Select_Header_Text], 255);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_Select_Header_Text], 2);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_Select_Header_Text], 0.230000, 1.299999);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_Select_Header_Text], 340197350);
	PlayerTextDrawSetOutline(playerid, pTextInfo[playerid][pC_Select_Header_Text], 1);
	PlayerTextDrawSetProportional(playerid, pTextInfo[playerid][pC_Select_Header_Text], 1);
	PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_Select_Header_Text], 0);

	for(new i = 0; i < sizeof(c_ColorIndex[]); ++i)
	{
		pTextInfo[playerid][pC_ColorBoxLeft][i] = CreatePlayerTextDraw(playerid, 540.0, (344.0 + (i * 16.0)), "_");
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], 255);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], 1);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], 0.500000, 0.499998);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], -1);
		PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], 1);
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], -1);
		PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], 546.0, 0.0);
		PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_ColorBoxLeft][i], 1);

		pTextInfo[playerid][pC_ColorBoxOutline][i] = CreatePlayerTextDraw(playerid, 578.0, (344.0 + (i * 16.0)), "_");
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 255);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 1);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 0.500000, 0.499998);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], -1);
		PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 1);
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 0xFFFFFFFF);
		PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 559.0, 0.0);
		PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_ColorBoxOutline][i], 1);

		pTextInfo[playerid][pC_ColorBoxM][i] = CreatePlayerTextDraw(playerid, 577.0, (344.7 + (i * 16.0)), "_");
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 255);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 1);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 0.500000, 0.30);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_ColorBoxM][i], -1);
		PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 1);
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 0xFF0000DD);
		PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 560.0, 0.0);
		PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_ColorBoxM][i], 1);

		pTextInfo[playerid][pC_ColorBoxRight][i] = CreatePlayerTextDraw(playerid, 604.0, (344.0 + (i * 16.0)), "_");
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], 255);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], 1);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], 0.500000, 0.499998);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], -1);
		PlayerTextDrawUseBox(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], 1);
		PlayerTextDrawBoxColor(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], -1);
		PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], 584.0, 0.0);
		PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_ColorBoxRight][i], 1);
	}
	pTextInfo[playerid][pC_Wheel_Name] = CreatePlayerTextDraw(playerid, 565.000000, 372.000000, "Wheels");
	PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pC_Wheel_Name], 2);
	PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_Wheel_Name], 2);
	PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_Wheel_Name], 0.189998, 1.100000);
	PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_Wheel_Name], -1);
	for(new i = 0; i < MAX_C_OBJECTS_LIST; ++i)
	{
		pTextInfo[playerid][pC_oNames][i] = CreatePlayerTextDraw(playerid, 500.0, (217.0 + (i * 20.0)), "Object Name");
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_oNames][i], 0);
		PlayerTextDrawAlignment(playerid, pTextInfo[playerid][pC_oNames][i], 2);
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_oNames][i], 2);
		PlayerTextDrawLetterSize(playerid, pTextInfo[playerid][pC_oNames][i], 0.219999, 1.0); // 219999
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_oNames][i], -1);
		PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pC_oNames][i], 20.0, 60.0); // inverted due to Alignment
		PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_oNames][i], 1);

		pTextInfo[playerid][pC_oModels][i] = CreatePlayerTextDraw(playerid, 575.000000, (217.0 + (i * 20.0)), "");
		PlayerTextDrawFont(playerid, pTextInfo[playerid][pC_oModels][i], TEXT_DRAW_FONT_MODEL_PREVIEW);
		PlayerTextDrawColor(playerid, pTextInfo[playerid][pC_oModels][i], 0xFFFFFFFF);
		PlayerTextDrawBackgroundColor(playerid, pTextInfo[playerid][pC_oModels][i], 0);
		PlayerTextDrawTextSize(playerid, pTextInfo[playerid][pC_oModels][i], 30.0, 20.0); // Text size is the Width:Height
		PlayerTextDrawSetPreviewModel(playerid, pTextInfo[playerid][pC_oModels][i], 0);
		PlayerTextDrawSetPreviewRot(playerid, pTextInfo[playerid][pC_oModels][i], 0.0, 0.0, 0.0, 0.8); // -15.0, 0.0, -90.0 | -16.0, 0.0, -55.0
		PlayerTextDrawSetSelectable(playerid, pTextInfo[playerid][pC_oModels][i], 1);
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
		pStatusInfo[playerid][StatusText][st] = CreatePlayerTextDraw(playerid, StatusTextPositions[st][0], StatusTextPositions[st][1], "INCOMING");
		PlayerTextDrawAlignment(playerid, pStatusInfo[playerid][StatusText][st], 2);
		PlayerTextDrawBackgroundColor(playerid, pStatusInfo[playerid][StatusText][st], 0xFF);
		PlayerTextDrawFont(playerid, pStatusInfo[playerid][StatusText][st], 1);
		PlayerTextDrawLetterSize(playerid, pStatusInfo[playerid][StatusText][st], StatusTextLetterSize[st][0], StatusTextLetterSize[st][1]);
		PlayerTextDrawColor(playerid, pStatusInfo[playerid][StatusText][st], StatusTextColors[st]);
		PlayerTextDrawSetOutline(playerid, pStatusInfo[playerid][StatusText][st], 1);
		PlayerTextDrawSetProportional(playerid, pStatusInfo[playerid][StatusText][st], 1);
		PlayerTextDrawSetShadow(playerid, pStatusInfo[playerid][StatusText][st], 0);
	}
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
	--playerData[playerid][pTurbo];
	if(GetVehicleModel(vehicleid) == TMC_REAPER)
	{
		IncreaseVehicleSpeed(vehicleid, 1.015);
	}
	if(playerData[playerid][pTurbo] <= 0)
	{
		playerData[playerid][pTurbo] = 0;
		SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], 0.0);
		RemoveVehicleComponent(vehicleid, 1010);
		KillTimer(playerData[playerid][Turbo_Timer]);
		if(GetVehicleModel(vehicleid) == TMC_REAPER) {
			DestroyObject(Nitro_Bike_Object[playerid]);
			Nitro_Bike_Object[playerid] = 0;
		}
	}
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pTurboBar], float(playerData[playerid][pTurbo]));
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

forward respawnServerPickup(gameid, spickupid, type);
public respawnServerPickup(gameid, spickupid, type)
{
	new pid = CreatePickup(m_Pickup_Data[gameid][spickupid][Modelid], m_Pickup_Data[gameid][spickupid][Type], m_Pickup_Data[gameid][spickupid][PickupX], m_Pickup_Data[gameid][spickupid][PickupY], m_Pickup_Data[gameid][spickupid][PickupZ], m_Pickup_Data[gameid][spickupid][VirtualWorld]);
	m_Pickup_Data[gameid][spickupid][Created] = true;
	m_Pickup_Data[gameid][spickupid][Pickupid] = pid;
	m_Pickup_Data[gameid][spickupid][Pickuptype] = type;
	return 1;
}

createPickupEx(gameid, type, Float:x, Float:y, Float:z, virtualworld = 0, pickuptype = -1)
{
	new pickupid = Iter_Free(m_Map_Pickups[gameid]), cpickupid, model, text3D[33];
	if(pickupid < 0 || pickupid >= MAX_MAP_PICKUPS)
	{
		printf("No Free Pickup Slots Left - pickupid: %d - type: %d", pickupid, pickuptype);
		return 0;
	}
	//printf("adding pickup to game: %d - pickupid: %d", gameid, pickupid);
	if(!Iter_Contains(m_Map_Pickups[gameid], pickupid))
	{
		Iter_Add(m_Map_Pickups[gameid], pickupid);
	}
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
	m_Pickup_Data[gameid][pickupid][Pickupid] = cpickupid;
	m_Pickup_Data[gameid][pickupid][Modelid] = model;
	m_Pickup_Data[gameid][pickupid][Type] = type;
	m_Pickup_Data[gameid][pickupid][PickupX] = x;
	m_Pickup_Data[gameid][pickupid][PickupY] = y;
	m_Pickup_Data[gameid][pickupid][PickupZ] = z;
	m_Pickup_Data[gameid][pickupid][VirtualWorld] = virtualworld;
	m_Pickup_Data[gameid][pickupid][Pickuptype] = pickuptype;
	m_Pickup_Data[gameid][pickupid][Created] = true;
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
	m_Pickup_Data[gameid][pickupid][Pickuptext] = Create3DTextLabel(text3D, 0xFFFFFFFF, x, y, z + 0.3, 50.0, virtualworld);
	return pickupid;
}

DestroyPickupEx(gameid, pickupid)
{
	if(pickupid < 0 || pickupid >= sizeof(m_Pickup_Data[])) return 0;
	if(m_Pickup_Data[gameid][pickupid][Pickupid] == -1) return 0;
	DestroyPickup(m_Pickup_Data[gameid][pickupid][Pickupid]);
	if(Iter_Contains(m_Map_Pickups[gameid], pickupid))
	{
		Iter_Remove(m_Map_Pickups[gameid], pickupid);
	}
	m_Pickup_Data[gameid][pickupid][Pickupid] = -1;
	m_Pickup_Data[gameid][pickupid][Modelid] = -1;
	m_Pickup_Data[gameid][pickupid][Type] = -1;
	m_Pickup_Data[gameid][pickupid][PickupX] = 0.0;
	m_Pickup_Data[gameid][pickupid][PickupY] = 0.0;
	m_Pickup_Data[gameid][pickupid][PickupZ] = 0.0;
	m_Pickup_Data[gameid][pickupid][Created] = false;
	m_Pickup_Data[gameid][pickupid][VirtualWorld] = 0;
	m_Pickup_Data[gameid][pickupid][Pickuptype] = -1;
	Delete3DTextLabel(m_Pickup_Data[gameid][pickupid][Pickuptext]);
	return 1;
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

new g_FORMAT_out[144], g_IRCFORMAT_out[256];

SendClientMessageFormatted(playerid, colour, format[], va_args<>)
{
	va_format(g_FORMAT_out, sizeof(g_FORMAT_out), format, va_start<3>);
	if(playerid == INVALID_PLAYER_ID || playerid == MAX_PLAYERS)
		return SendClientMessageToAll(colour, g_FORMAT_out);
	else
		return SendClientMessage(playerid, colour, g_FORMAT_out);
}
messageAdmins(color = COLOR_ADMIN, format[], va_args<>)
{
	va_format(g_FORMAT_out, sizeof(g_FORMAT_out), format, va_start<2>);
	foreach(Player, i)
	{
		if(isServerAdmin(i))
			SendClientMessage(i, color, g_FORMAT_out);
	}
	return 1;
}
GameTextForPlayerFormatted(playerid, format[], time, style, va_args<>)
{
	va_format(g_FORMAT_out, sizeof(g_FORMAT_out), format, va_start<4>);
	if(playerid == MAX_PLAYERS) return GameTextForAll(g_FORMAT_out, time, style);
	else return GameTextForPlayer(playerid, g_FORMAT_out, time, style);
}
IRC_GroupSayFormatted(groupid, const target[], format[], {Float, _}:...)
{
	va_format(g_IRCFORMAT_out, sizeof(g_IRCFORMAT_out), format, va_start<3>);
	return IRC_GroupSay(groupid, target, g_IRCFORMAT_out);
}
IRC_SayFormatted(groupid, const target[], format[], {Float, _}:...)
{
	va_format(g_IRCFORMAT_out, sizeof(g_IRCFORMAT_out), format, va_start<3>);
	return IRC_Say(groupid, target, g_IRCFORMAT_out);
}
/*IRC_NoticeFormatted(groupid, const target[], format[], {Float, _}:...)
{
	va_format(g_IRCFORMAT_out, sizeof(g_IRCFORMAT_out), format, va_start<3>);
	return IRC_Notice(groupid, target, g_IRCFORMAT_out);
}*/
safeKickPlayer(playerid, reason[])
{
	printf("[System: Kick] - %s(%d) Has Been Kicked For %s", playerName(playerid), playerid, reason);
	GameTextForPlayer(playerid, "~r~Kicked", 5000, 3);
	SetPlayerInterior(playerid, playerid);
	SetPlayerVirtualWorld(playerid, 1);
	SetCameraBehindPlayer(playerid);
	Kick(playerid);
	return 1;
}

RadiusDamage(playerid, vehicleid, Float:x, Float:y, Float:z, Float:maxdamage, missileid, Float:radius)
{
	new Float:pdist, Float:damage;
	foreach(Vehicles, v)
	{
		if(vehicleid == v) continue;
		pdist = GetVehicleDistanceFromPoint(v, x, y, z);
		pdist *= 0.8;
		if(pdist > radius) continue;
		damage = (1 - (pdist / radius)) * maxdamage;
		DamagePlayer(playerid, vehicleid, Vehicle_Driver[v], v, damage, missileid);
		//printf("[System: RadiusDamage] - damage: %0.2f - pdist: %0.2f - radius: %0.2f", damage, pdist, radius);
	}
	return 1;
}

DamagePlayer(playerid, id, damagedid = INVALID_PLAYER_ID, vehicleid, Float:damount, missileid, alt_special = 0, distance_type = d_type_none)
{
	new Float:amount = damount, Float:health, bool:dontuse2text = false, Float:newhealth,
		Float:oldhealth, dtext[32 + 4], time = gettime();
	T_GetVehicleHealth(vehicleid, health);
	if(damagedid != INVALID_PLAYER_ID)
	{
		if(IsPlayerAttachedObjectSlotUsed(damagedid, ATTACHED_INDEX_SHIELD))
		{
			switch(GetPVarInt(damagedid, "Absorption_Shield"))
			{
				case 1:
				{
					++playerData[damagedid][pMissiles][missileid];
					updatePlayerHUD(damagedid);
					DeletePVar(damagedid, "Absorption_Shield");
				}
				case 0: amount = damount = 0.0;
			}
		}
	}
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
	playerData[playerid][pDamageDone] += damount;
	if(damagedid != INVALID_PLAYER_ID)
	{
		playerData[damagedid][pDamageTaken] += damount;
		playerData[playerid][pDamageToPlayer][damagedid] += damount;
	}
	switch(missileid)
	{
		case Missile_Special, Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
		{
			pCurrentlyAttackingDamage[id][missileid] += damount;
		}
	}
	if(pLastAttackedTime[id] > time)
	{
		if(pLastAttackedMissile[id] == pCurrentlyAttackingMissile[id])
		{
			switch(missileid)
			{
				case Missile_Special, Missile_Machine_Gun, Missile_Machine_Gun_Upgrade:
				{
					amount += pCurrentlyAttackingDamage[id][missileid];
					dontuse2text = true;
				}
			}
		}
		else
		{
			pLastAttackedTime[id] = 0;
			pCurrentlyAttackingDamage[id][missileid] = 0;
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
			case Missile_Special, Missile_Machine_Gun, Missile_Machine_Gun_Upgrade: format(dtext, sizeof(dtext), "%s %d damage", GetTwistedMissileName(missileid, id, true, alt_special, distance_type), floatround(amount));
			case Missile_Fire..Missile_Napalm, Missile_Ricochet..Missile_RemoteBomb: format(dtext, sizeof(dtext), "%s Missile hit %d damage", GetTwistedMissileName(missileid, id), floatround(amount));
		}
		TimeTextForPlayer( TIMETEXT_TOP, playerid, dtext, 3000, _, dontuse2text, _ );
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
	if(pCurrentlyAttacking[id] != pLastAttacked[id]) {
		pLastAttacked[id] = vehicleid;
		pLastAttackedMissile[id] = missileid;
		pLastAttackedTime[id] = time + 2;
	}
	return 1;
}

IsPointInPolygon(Float: point_X, Float: point_Y, { Float, _ }: ...)
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

GetTwistedMissileName(missileid, vehicleid = 0, bool:checkspecial = false, alt_special = 0, distance_type = d_type_none, mapid = INVALID_MAP_ID)
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
						case TMC_JUNKYARD_DOG: str = "Taxi Slam";
						case TMC_BRIMSTONE: str = "Slave Dynamite";
						case TMC_OUTLAW: str = "SUV Turret";
						case TMC_REAPER:
						{
							switch(alt_special)
							{
								case 2: str = "RPG";
								case 1: str = "Flame Saw";
								default: str = "Mr. Grimms Chainsaw";
							}
						}
						case TMC_ROADKILL: str = "Series Missiles";
						case TMC_THUMPER: str = "Jet Stream Of Fire";
						case TMC_SPECTRE: str = "Screaming Fiery Missile";
						case TMC_DARKSIDE: str = "Darkside Slam";
						case TMC_SHADOW:
						{
							switch(alt_special)
							{
								case 1: str = "Coffin Bomb Blast";
								default: str = "Death Coffin";
							}
						}
						case TMC_MEATWAGON:
						{
							switch(alt_special)
							{
								case 1: str = "Piloted Gurney Bomb";
								default: str = "Gurney Bomb";
							}
						}
						case TMC_VERMIN:
						{
							switch(alt_special)
							{
								case 1: str = "Piloted Rat Rocket";
								default: str = "Rat Rocket";
							}
						}
						case TMC_3_WARTHOG:
						{
							switch(alt_special)
							{
								case 1: str = "Patriot Swarmers";
								default: str = "Patriot Swarmers";
							}
						}
						case TMC_MANSLAUGHTER: str = "Boulder Throw";
						case TMC_HAMMERHEAD: str = "RAM Attack";
						case TMC_SWEETTOOTH: str = "Missile Rack";
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
		case d_type_close: strcat(str, " Close!", _);
		case d_type_far: strcat(str, " Far!", _);
	}
	return str;
}

AdjustTeamColoursForPlayer(playerid)
{
	foreach(Player, i)
	{
		if(playerData[playerid][gGameID] != playerData[i][gGameID]) continue;
		if(playerData[i][gTeam] == playerData[playerid][gTeam])
		{
			SetPlayerMarkerForPlayer(i, playerid, PLAYER_TEAM_COLOUR);
			SetPlayerMarkerForPlayer(playerid, i, PLAYER_TEAM_COLOUR);
		}
		else if(playerData[i][gTeam] != playerData[playerid][gTeam])
		{
			SetPlayerMarkerForPlayer(i, playerid, RIVAL_TEAM_COLOUR);
			SetPlayerMarkerForPlayer(playerid, i, RIVAL_TEAM_COLOUR);
		}
	}
	return 1;
}

ShowKillStreak(playerid, text[32])
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

forward AddEXPMessage(playerid, text[32]);
public AddEXPMessage(playerid, text[32])
{
	if(playerid == INVALID_PLAYER_ID)
	{
		foreach(Player, p)
		{
			AddEXPMessage(p, text);
		}
		return 1;
	}
	new i = 0, lowest = EXP_STATUS_SHOW_TIME, lowest_i;
	for(; i < (MAX_XP_STATUSES - 1); ++i)
	{
		if(i >= MAX_XP_STATUSES)
		{
			i = 0;
			for(; i < MAX_XP_STATUSES; ++i)
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
	pEXPTextStatusTimer[playerid][i] = SetTimerEx("FadeXPMessage", EXP_STATUS_SHOW_TIME * 1000, false, "ii", playerid, i);
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
	KillTimer(pEXPTextStatusTimer[playerid][index]); // pEXPTextStatus[playerid][index] = 0;
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

GainExprience(playerid, exprience)
{
	if(!IsPlayerConnected(playerid)) return 1;
	new string[16];
	playerData[playerid][g_pExprience] += exprience;
	playerData[playerid][pExprience] += exprience;
	toggleAccountSave(playerid, ACCOUNT_UPDATE_EXPRIENCE);
	if(playerData[playerid][pExprience] >= (playerData[playerid][pLevel] * GAME_EXP_PER_LEVEL))
	{
		++playerData[playerid][pLevel];
		format(string, sizeof(string), "Level: %d", playerData[playerid][pLevel]);
		PlayerTextDrawSetString(playerid, pTextInfo[playerid][pLevelText], string);
		PlayerTextDrawShow(playerid, pTextInfo[playerid][pLevelText]);
		++playerData[playerid][pTier_Points];
		toggleAccountSave(playerid, ACCOUNT_UPDATE_LEVEL);
		AddEXPMessage(playerid, "LEVELED UP!");
	}
	format(string, sizeof(string), "XP: %d", playerData[playerid][pExprience]);
	PlayerTextDrawSetString(playerid, pTextInfo[playerid][pEXPText], string);
	SetPlayerProgressBarValue(playerid, pTextInfo[playerid][pExprienceBar], float((playerData[playerid][pExprience] - ((playerData[playerid][pLevel] - 1) * GAME_EXP_PER_LEVEL))));
	ShowPlayerProgressBar(playerid, pTextInfo[playerid][pExprienceBar]);
	return 1;
}

GainPoints(playerid, points)
{
	playerData[playerid][g_pPoints] += points;
	return 1;
}

ResetPlayerGamePoints(playerid) return (playerData[playerid][g_pPoints] = 0);
GetPlayerGamePoints(playerid) return playerData[playerid][g_pPoints];

CreateMarkerForPlayer(vehicleid, color)
{
	new Text3D:vehicle3Dtext[6];
	vehicle3Dtext[0] = Create3DTextLabel(" \\IIIIIIIIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
	vehicle3Dtext[1] = Create3DTextLabel("  \\IIIIIIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
	vehicle3Dtext[2] = Create3DTextLabel("   \\IIIIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
	vehicle3Dtext[3] = Create3DTextLabel("    \\IIII/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
	vehicle3Dtext[4] = Create3DTextLabel("     \\II/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
	vehicle3Dtext[5] = Create3DTextLabel("     \\/", color, 0.0, 0.0, 0.0, 25.0, GetVehicleVirtualWorld(vehicleid));
	for(new i = 0; i < 6; ++i) {
		Attach3DTextLabelToVehicle( vehicle3Dtext[i], vehicleid, 0.0, 0.0, (2.0 - floatdiv(i, 8.5)) );
	}
	return 1;
}

CreateMap(mapname[32], map_type)
{
	new map_id = -1;
	for(new i = 1; i < MAX_MAPS; ++i)
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
	s_Maps[map_id][m_MaxZ] = 1000.0;
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
		case MD_TYPE_MaxZ: s_Maps[mapid][m_MaxZ] = fvalue;
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


Float:getMapLowestZ(Mapid)
{
	if(Mapid < 0 || Mapid >= MAX_MAPS) return 0.0;
	return s_Maps[Mapid][m_LowestZ];
}

Float:getMapHighestZ(Mapid)
{
	if(Mapid < 0 || Mapid >= MAX_MAPS) return 0.0;
	return s_Maps[Mapid][m_MaxZ];
}

AddMapObject(mapid, modelid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, Float:drawdistance = 0.0, destroyable = 0)
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
	if(drawdistance == 0.0) drawdistance = 500.0;
	m_Map_Positions[m][m_DrawDistance] = drawdistance;
	m_Map_Positions[m][m_Destroyable] = destroyable;
	return 1;
}

SpawnMapObject(gameid, index, mi = 0, modelid = -1, Float:x = 0.0, Float:y = 0.0, Float:z = 0.0, Float:rx = 0.0, Float:ry = 0.0, Float:rz = 0.0, Float:drawdistance = 0.0)
{
	if(index == MAP_OBJECT_SPAWN_FIND_NEW_INDEX)
	{
		index = Iter_Free(m_Map_Objects[gameid]);
		Map_Objects[gameid][index] = CreateObject(modelid, x, y, z, rx, ry, rz, drawdistance);
	}
	else Map_Objects[gameid][index] = CreateObject(m_Map_Positions[mi][m_Model], m_Map_Positions[mi][m_X], m_Map_Positions[mi][m_Y], m_Map_Positions[mi][m_Z], m_Map_Positions[mi][m_rX], m_Map_Positions[mi][m_rY], m_Map_Positions[mi][m_rZ], m_Map_Positions[mi][m_DrawDistance]);
	if(!Iter_Contains(m_Map_Objects[gameid], index))
	{
		Iter_Add(m_Map_Objects[gameid], index);
	}
	if(m_Map_Positions[mi][m_Destroyable] != 0)
	{
		if(!Iter_Contains(m_Destroyables[gameid], index))
		{
			Iter_Add(m_Destroyables[gameid], index);
			printf("[System: SpawnMapObject] - adding id to destroyables: %d", index);
		}
	}
}

AddMapSpawn(mapid, Float:x, Float:y, Float:z, Float:angle = 0.0)
{
	new m = -1;
	for(new mp; mp < sizeof(m_Map_Spawns); mp++)
	{
		if( m_Map_Spawns[mp][s_X] != 0.0 ) continue;
		m = mp;
		break;
	}
	if(m == -1) return 0;
	m_Map_Spawns[m][s_Mapid] = mapid;
	m_Map_Spawns[m][s_X] = x;
	m_Map_Spawns[m][s_Y] = y;
	m_Map_Spawns[m][s_Z] = z;
	m_Map_Spawns[m][s_Angle] = angle;
	return 1;
}

AddMapPickup(mapid, pickuptype, Float:x, Float:y, Float:z)
{
	new m = -1;
	for(new mp; mp < sizeof(Maps_m_Pickup_Data); mp++)
	{
		if( Maps_m_Pickup_Data[mp][PI_Mapid] != 0 ) continue;
		m = mp;
		break;
	}
	if(m == -1) return 0;
	Maps_m_Pickup_Data[m][PI_Mapid] = mapid;
	Maps_m_Pickup_Data[m][PI_Pickuptype] = pickuptype;
	Maps_m_Pickup_Data[m][PI_pX] = x;
	Maps_m_Pickup_Data[m][PI_pY] = y;
	Maps_m_Pickup_Data[m][PI_pZ] = z;
	return 1;
}

LoadMapData(dataid, mapid = MAX_MAPS, gameid = -1)
{
	switch(dataid)
	{
		case MAP_ALL_DATA: mysql_tquery(mysqlConnHandle, "SELECT * FROM "#mySQL_Maps_Table"", "Thread_OnMapDataLoad", "i", MAX_MAPS);
		case MAP_DATA_OBJECTS:
		{
			format(gQuery, sizeof(gQuery), "SELECT * FROM "#mySQL_Maps_Objects_Table" WHERE `mapID` = %d LIMIT 0,%d", mapid, MAX_MAP_OBJECTS);
			mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnMapObjectsLoad", "i", gameid);
		}
		case MAP_DATA_PICKUPS:
		{
			format(gQuery, sizeof(gQuery), "SELECT * FROM "#mySQL_Maps_Pickups_Table" WHERE `mapID` = %d LIMIT 0,%d", mapid, MAX_MAP_PICKUPS);
			mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnMapPickupsLoad", "i", gameid);
		}
		case MAP_DATA_SPAWNS:
		{
			format(gQuery, sizeof(gQuery), "SELECT * FROM "#mySQL_Maps_Spawns_Table" WHERE `mapID` = %d LIMIT 0,"#MAX_PLAYERS_PER_LOBBY"", mapid);
			mysql_tquery(mysqlConnHandle, gQuery, "Thread_OnMapSpawnsLoad", "i", MAX_MAPS);
		}
	}
	return;
}

THREAD:OnMapSpawnsLoad(extraid)
{
	new rows = cache_get_row_count(mysqlConnHandle), mapid, Float:x, Float:y, Float:z, Float:angle;
	for(new row = 0; row < rows; row++)
	{
		if(row >= MAX_MAP_SPAWNS)
		{
			printf("[System - OnMapSpawnsLoad: Max Spawns Limit Reached]");
			break;
		}
		//cache_get_row(row, 0, mapname, mysqlConnHandle); // mapName
		mapid = cache_get_row_int(row, 1, mysqlConnHandle); // mapID
		x = cache_get_row_float(row, 2, mysqlConnHandle); // x
		y = cache_get_row_float(row, 3, mysqlConnHandle); // y
		z = cache_get_row_float(row, 4, mysqlConnHandle); // z
		angle = cache_get_row_float(row, 5, mysqlConnHandle); // angle
		AddMapSpawn(mapid, x, y, z, angle);
	}
	return 1;
}

THREAD:OnMapObjectsLoad(gameid)
{
	new rows = cache_get_row_count(mysqlConnHandle), modelid, Float:x, Float:y, Float:z,
		Float:rx, Float:ry, Float:rz, Float:drawdistance;
	for(new row = 0; row < rows; row++)
	{
		if(row >= MAX_MAP_OBJECTS)
		{
			printf("[System - OnMapObjectsLoad: Max Object Limit Reached]");
			break;
		}
		//cache_get_row(row, 0, mapname, mysqlConnHandle); // map name
		//cache_get_row(row, 1, data, mysqlConnHandle); // map id mapid = strval(data);
		modelid = cache_get_row_int(row, 2, mysqlConnHandle); // modelID
		x = cache_get_row_float(row, 3, mysqlConnHandle); // x
		y = cache_get_row_float(row, 4, mysqlConnHandle); // y
		z = cache_get_row_float(row, 5, mysqlConnHandle); // z
		rx = cache_get_row_float(row, 6, mysqlConnHandle); // rX
		ry = cache_get_row_float(row, 7, mysqlConnHandle); // rY
		rz = cache_get_row_float(row, 8, mysqlConnHandle); // rZ
		drawdistance = cache_get_row_float(row, 9, mysqlConnHandle); // drawDistance
		SpawnMapObject(gameid, MAP_OBJECT_SPAWN_FIND_NEW_INDEX, _, modelid, x, y, z, rx, ry, rz, drawdistance);
	}
	return 1;
}

THREAD:OnMapPickupsLoad(gameid)
{
	new rows = cache_get_row_count(mysqlConnHandle), pickuptype, Float:x, Float:y, Float:z;
	for(new row = 0; row < rows; row++)
	{
		if(row >= MAX_MAP_PICKUPS)
		{
			printf("[System - OnMapPickupsLoad: Max Pickups Limit Reached]");
			break;
		}
		//cache_get_row(row, 0, mapname, mysqlConnHandle); // map name
		//cache_get_row(row, 1, data, mysqlConnHandle); // map id
		pickuptype = cache_get_row_int(row, 2, mysqlConnHandle); // pickuptype
		x = cache_get_row_float(row, 3, mysqlConnHandle);
		y = cache_get_row_float(row, 4, mysqlConnHandle);
		z = cache_get_row_float(row, 5, mysqlConnHandle);
		createPickupEx(gameid, 14, x, y, z, gameid, pickuptype);
	}
	return 1;
}

THREAD:OnMapDataLoad(extraid)
{
	new rows = cache_get_row_count(mysqlConnHandle), mapname[32], mapid, maptype, data[12];
	for(new row = 0; row < rows; row++)
	{
		if(row >= MAX_MAPS) break;
		cache_get_row(row, 0, mapname, mysqlConnHandle); // map name
		maptype = cache_get_row_int(row, 1, mysqlConnHandle); // map type
		mapid = CreateMap(mapname, maptype);
		cache_get_row(row, 2, data, mysqlConnHandle); // map id
		SetMapData(mapid, MD_TYPE_ID, data, MD_String);
		cache_get_row(row, 3, data, mysqlConnHandle); // lowest z
		SetMapData(mapid, MD_TYPE_LowestZ, data, MD_Float);
		cache_get_row(row, 4, data, mysqlConnHandle); // check lowest z
		SetMapData(mapid, MD_TYPE_CheckLowestZ, data, MD_Integer);
		cache_get_row(row, 5, data, mysqlConnHandle); // weather id
		SetMapData(mapid, MD_TYPE_Weatherid, data, MD_Integer);
		cache_get_row(row, 6, data, mysqlConnHandle); // Amount of Interpolation views per map
		SetMapData(mapid, MD_TYPE_IP_Index, data, MD_Integer);
		cache_get_row(row, 7, data, mysqlConnHandle); // Environmental Missile name
		SetMapData(mapid, MD_TYPE_EN_Name, data, MD_String);
		cache_get_row(row, 8, data, mysqlConnHandle); // Grid Index / Max Grids Per Map
		SetMapData(mapid, MD_TYPE_Grid_Index, data, MD_Integer);
	}
	return 1;
}

Float:GetTwistedMetalMaxHealth(modelid)
{
	new Float:health;
	switch(modelid)
	{
		case TMC_BRIMSTONE: health = 150.0;
		case TMC_THUMPER: health = 150.0;
		case TMC_SPECTRE: health = 180.0;
		case TMC_REAPER: health = 90.0;
		case TMC_CRIMSON_FURY: health = 110.0;
		case TMC_ROADKILL: health = 160.0;
		case TMC_VERMIN: health = 205.0;
		case TMC_MEATWAGON: health = 210.0;
		case TMC_SHADOW: health = 230.0;
		case TMC_OUTLAW: health = 240.0;
		case TMC_SWEETTOOTH: health = 250.0;
		case TMC_HAMMERHEAD: health = 260.0;
		case TMC_JUNKYARD_DOG: health = 260.0;
		case TMC_3_WARTHOG: health = 270.0;
		case TMC_MANSLAUGHTER: health = 270.0;
		case TMC_DARKSIDE: health = 280.0;
		default: health = 150.0;
	}
	return health;
}

Float:GetTwistedMetalMaxTurbo(modelid)
{
	new Float:turbo;
	switch(modelid)
	{
		case TMC_BRIMSTONE: turbo = MAX_TURBO;
		case TMC_THUMPER: turbo = MAX_TURBO;
		case TMC_SPECTRE: turbo = MAX_TURBO;
		case TMC_REAPER: turbo = MAX_TURBO;
		case TMC_CRIMSON_FURY: turbo = MAX_TURBO;
		case TMC_ROADKILL: turbo = MAX_TURBO;
		case TMC_VERMIN: turbo = MAX_TURBO;
		case TMC_MEATWAGON: turbo = MAX_TURBO;
		case TMC_SHADOW: turbo = MAX_TURBO;
		case TMC_OUTLAW: turbo = MAX_TURBO + 50.0;
		case TMC_SWEETTOOTH: turbo = MAX_TURBO + 100.0;
		case TMC_HAMMERHEAD: turbo = MAX_TURBO;
		case TMC_JUNKYARD_DOG: turbo = MAX_TURBO + 50.0;
		case TMC_3_WARTHOG: turbo = MAX_TURBO;
		case TMC_MANSLAUGHTER: turbo = MAX_TURBO + 100.0;
		case TMC_DARKSIDE: turbo = MAX_TURBO + 150.0;
		default: turbo = MAX_TURBO;
	}
	return turbo;
}

Float:GetTwistedMetalMaxEnergy(modelid)
{
	new Float:energy;
	switch(modelid)
	{
		case TMC_BRIMSTONE: energy = MAX_ENERGY;
		case TMC_THUMPER: energy = MAX_ENERGY;
		case TMC_SPECTRE: energy = MAX_ENERGY;
		case TMC_REAPER: energy = MAX_ENERGY;
		case TMC_CRIMSON_FURY: energy = MAX_ENERGY;
		case TMC_ROADKILL: energy = MAX_ENERGY;
		case TMC_VERMIN: energy = MAX_ENERGY;
		case TMC_MEATWAGON: energy = MAX_ENERGY;
		case TMC_SHADOW: energy = MAX_ENERGY;
		case TMC_OUTLAW: energy = MAX_ENERGY + 10.0;
		case TMC_SWEETTOOTH: energy = MAX_ENERGY + 15.0;
		case TMC_HAMMERHEAD: energy = MAX_ENERGY;
		case TMC_JUNKYARD_DOG: energy = MAX_ENERGY + 10.0;
		case TMC_3_WARTHOG: energy = MAX_ENERGY;
		case TMC_MANSLAUGHTER: energy = MAX_ENERGY + 15.0;
		case TMC_DARKSIDE: energy = MAX_ENERGY + 20.0;
		default: energy = MAX_ENERGY;
	}
	return energy;
}

GetFreeMissileLightSlot(vehicleid)
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

EditPlayerSlot(playerid, slot = 0, pstype = PLAYER_MISSILE_SLOT_ADD)
{
	switch(pstype)
	{
		case PLAYER_MISSILE_SLOT_ADD:
		{
			if(!Iter_Contains(pSlots_In_Use[playerid], slot))
			{
				Iter_Add(pSlots_In_Use[playerid], slot);
			}
			else return -1;
		}
		case PLAYER_MISSILE_SLOT_REMOVE:
		{
			if(Iter_Contains(pSlots_In_Use[playerid], slot))
			{
				new next;
				Iter_SafeRemove(pSlots_In_Use[playerid], slot, next);
				return next;
			}
			else return -1;
		}
		case PLAYER_MISSILE_SLOT_CLEAR: Iter_Clear(pSlots_In_Use[playerid]);
	}
	return slot;
}

GetFreeMissileSlot(playerid, vehicleid)
{
	++Vehicle_Missile_CurrentslotID[vehicleid];
	if(Vehicle_Missile_CurrentslotID[vehicleid] >= MAX_MISSILE_SLOTS)
	{
		Vehicle_Missile_CurrentslotID[vehicleid] = 0;
	}
	if(Iter_Contains(pSlots_In_Use[playerid], Vehicle_Missile_CurrentslotID[vehicleid]))
	{
		Vehicle_Missile_CurrentslotID[vehicleid] = Iter_Free(pSlots_In_Use[playerid]);
	}
	if(IsValidObject(Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]]))
	{
		Object_Owner[Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]]] = INVALID_VEHICLE_ID;
		Object_OwnerEx[Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]]] = INVALID_PLAYER_ID;
		Object_Type[Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]]] = -1;
		Object_Slot[Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]]] = -1;
		DestroyObject(Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]]);
		Vehicle_Missile[vehicleid][Vehicle_Missile_CurrentslotID[vehicleid]] = INVALID_OBJECT_ID;
		EditPlayerSlot(playerid, Vehicle_Missile_CurrentslotID[vehicleid], PLAYER_MISSILE_SLOT_REMOVE);
	}
	return Vehicle_Missile_CurrentslotID[vehicleid];
}

UpdateLobbyTD(Text:TextdrawID, string[])
{
	new index = -1, text[2][16], text2[32], str[64], spacecount = 0;
	format(str, sizeof(str), "%s", string);
	while((index = strfind(string, " ", true, (index + 1))) != -1)
	{
		++spacecount;
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

ReturnMissileModel(missileid)
{
	new model = INVALID_OBJECT_ID;
	switch(missileid)
	{
		case Missile_Special: model = -1;
		case Missile_Homing, Missile_Fire, Missile_Power, Missile_Stalker: model = Missile_Default_Object;
		case Missile_Napalm: model = Missile_Napalm_Object;
		case Missile_Ricochet: model = 441;//Missile_Ricochet_Object;
		case Missile_RemoteBomb: model = Missile_RemoteBomb_Object;
	}
	return model;
}

ShiftRGBAToARGB(rgba) return rgba >>> 8 | rgba << 24;

getMissileColour(missileid, shift = 0)
{
	new color = 0xFFFFFFAA;
	switch(missileid)
	{
		case Missile_Special: color = 0x00FF00AA;
		case Missile_Homing: color = 0xB51BE0AA;
		case Missile_Fire: color = 0xFF9500AA;
		case Missile_Power: color = 0xFF0000AA;
		case Missile_Environmentals: color = 0xFAA2E5AA;
		case Missile_Napalm: color = 0xFEBF10AA;
		case Missile_Stalker: color = 0xFFB5FDAA;
		case Missile_Ricochet: color = 0x0000FFAA;
		case Missile_RemoteBomb: color = 0x09FF00AA;
	}
	return (shift == 1) ? ShiftRGBAToARGB(color) : color;
}

// unused stocks and functions

/*stringContainsIP(const szStr[], bool:fixedSeparation = true, bool:ignoreNegatives = false)
{
	new 
		i = 0, ch, lastCh, len = strlen(szStr), trueIPInts = 0, bool:isNumNegative = false, bool:numIsValid = true, // Invalid numbers are 1-1
		numberFound = -1, numLen = 0, numStr[5], lastSpacingPos = -1, numSpacingDiff, numLastSpacingDiff, numSpacingDiffCount // -225\0 (4 len)
	;
	while(i <= len)
	{
		lastCh = ch;
		ch = szStr[i];
		switch(ch)
		{
			case '0'..'9':
			{
				if(numIsValid) {
					if(lastCh == '-') {
						if(numLen == 0 && ignoreNegatives == false) {
							isNumNegative = true;
						}
						else if(numLen > 0) {
							numIsValid = false;
						}
					}
					if(numLen == (3 + _:isNumNegative)) { // IP Num is valid up to 4 characters.. -255
						for(numLen = 3; numLen > 0; numLen--) {
							numStr[numLen] = EOS;
						}
					}
					else if(lastCh == '-' && ignoreNegatives) {
						i++;
						continue;
					} else {
						if(numLen == 0 && numIsValid == true && isNumNegative == true && lastCh == '-') {
							numStr[numLen++] = lastCh;
						}
						numStr[numLen++] = ch;
					}
				}
			}
			default: // skip non +/-0-255
			{
				if(numLen && numIsValid) {
					numberFound = strval(numStr);
					if(numberFound >= -255 && numberFound <= 255) {
						if(fixedSeparation) {
							if(lastSpacingPos != -1) {
								numLastSpacingDiff = numSpacingDiff;
								numSpacingDiff = i - lastSpacingPos - numLen;
								if(trueIPInts == 1 || numSpacingDiff == numLastSpacingDiff) {
									++numSpacingDiffCount;
								}
							}
							lastSpacingPos = i;
						}
						if(++trueIPInts >= 4) {
							break;
						}
					}
					for(numLen = 3; numLen > 0; numLen--) { // strdel(numStr, 0, 3); // numStr[numLen] = EOS; ... they just won't work d:
						numStr[numLen] = EOS;
					} // numLen goes back to 0!
					isNumNegative = false;
				} else {
					numIsValid = true;
				}
			}
		}
		i++;
	}
	if(fixedSeparation == true && numSpacingDiffCount < 3) {
		return 0;
	}
	return (trueIPInts >= 4);
}

stock Float:MatrixMultiply(Float:mat1[4][4], Float:mat2[4][4])
{
	new Float:matRet[4][4];
	for (new i = 0; i < 4; ++i)
		for (new j = 0; j < 4; j++)
			for (new k = 0; k < 4; k++)
				matRet[i][j] += mat1[i][k] * mat2[k][j];
	return matRet;
}

stock Float:MatrixMultiplyVector(Float:mat[4][4], Float:vec[4])
{
	new Float:vTmp[4];
	for (new i = 0; i < 4; ++i)
		for (new k = 0; k < 4; k++)
			vTmp[i] += vec[k] * mat[k][i];
	return vTmp;
}

stock calcPosInScreen(playerid, nScreenW, nScreenH, Float:fObjectPos[3])
{
	new str[256];

	new Float:matProj[4][4],
		Float:matView[4][4],
		Float:matWorld[4][4],
		Float:matRet[4][4];

	for (new i = 0; i < 4; ++i)
		for (new j = 0; j < 4; j++)
			matProj[i][j] = 0.0;

	for (new i = 0; i < 4; ++i)
		for (new j = 0; j < 4; j++)
			matView[i][j] = 0.0;

	for (new i = 0; i < 4; ++i)
		for (new j = 0; j < 4; j++)
			matWorld[i][j] = 0.0;

	for (new i = 0; i < 4; ++i)
		for (new j = 0; j < 4; j++)
			matRet[i][j] = 0.0;

	new Float:fYScale = 1.0 / floattan(27.0, degrees),
		Float:fZFar = 10.0,
		Float:fZNear = 0.5;

	new bWideScreen = 0;

	matProj[0][0] = fYScale * nScreenH / nScreenW * 1.2;
	matProj[1][1] = fYScale;

	if (bWideScreen)
		matProj[1][1] *= 1.33;

	matProj[2][2] = fZFar / (fZFar - fZNear);
	matProj[3][2] = -fZNear * fZFar / (fZFar - fZNear);
	matProj[2][3] = 1;


	new Float:fCamPos[3],
		Float:fCamLookAt[3];
	GetPlayerCameraPos(playerid, fCamPos[0], fCamPos[1], fCamPos[2]);
	GetPlayerCameraFrontVector(playerid, fCamLookAt[0], fCamLookAt[1], fCamLookAt[2]);

	new Float:fYaw = atan2(fCamLookAt[0], fCamLookAt[1]),
		Float:fPitch = acos(fCamLookAt[2]) + 270.0,
		Float:fRoll = 0.0;

	if (fYaw < 0.0)
		fYaw += 360.0;

	fYaw = 90.0;
	fPitch = 0.0;

	fCamPos[0] = -0.1;
	fCamPos[1] = 0.0;
	fCamPos[2] = fHeight;

	new Float:fSinYaw = floatsin(fYaw, degrees),
		Float:fCosYaw = floatcos(fYaw, degrees),
		Float:fSinPitch = floatsin(fPitch, degrees),
		Float:fCosPitch = floatcos(fPitch, degrees),
		Float:fSinRoll = floatsin(fRoll, degrees),
		Float:fCosRoll = floatcos(fRoll, degrees);

	matView[0][0] = fCosYaw * fCosRoll + fSinYaw * fSinPitch * fSinRoll;
	matView[0][1] = -fCosYaw * fSinRoll + fSinYaw * fSinPitch * fCosRoll;
	matView[0][2] = fSinYaw * fCosPitch;

	matView[1][0] = fSinRoll * fCosPitch;
	matView[1][1] = fCosRoll * fCosPitch;
	matView[1][2] = -fSinPitch;

	matView[2][0] = -fSinYaw * fCosRoll + fCosYaw * fSinPitch * fSinRoll;
	matView[2][1] = fSinRoll * fSinYaw + fCosYaw * fSinPitch * fCosRoll;
	matView[2][2] = fCosYaw * fCosPitch;

	matView[3][3] = 1.0;
	matView[3][0] = -(fCamPos[0] * matView[0][0] + fCamPos[2] * matView[1][0] + fCamPos[1] * matView[2][0]);
	matView[3][1] = -(fCamPos[0] * matView[0][1] + fCamPos[2] * matView[1][1] + fCamPos[1] * matView[2][1]);
	matView[3][2] = -(fCamPos[0] * matView[0][2] + fCamPos[2] * matView[1][2] + fCamPos[1] * matView[2][2]);


	matWorld[0][0] = 1.0;
	matWorld[1][1] = 1.0;
	matWorld[2][2] = 1.0;
	matWorld[3][3] = 1.0;
	//matWorld[3][0] = fObjectPos[0];
	//matWorld[3][1] = fObjectPos[2];
	//matWorld[3][2] = fObjectPos[1];

	matRet = MatrixMultiply(matView, matProj);

	matRet = MatrixMultiply(matWorld, matRet);

	new Float:fNewVec[4];
	fNewVec[0] = fObjectPos[0];
	fNewVec[1] = fObjectPos[2];
	fNewVec[2] = fObjectPos[1];
	fNewVec[3] = 1.0;
	fNewVec = MatrixMultiplyVector(matRet, fNewVec);

	fNewVec[0] /= fNewVec[3];
	fNewVec[1] /= fNewVec[3];
	fNewVec[2] /= fNewVec[3];

	if (fNewVec[0] < -1.0 || fNewVec[0] > 1.0 || fNewVec[1] < -1.0 || fNewVec[1] > 1.0 || fNewVec[2] < fZNear || fNewVec[2] > fZFar)
		format(str, 256, "Object out of screen");
	else
	{
		fNewVec[0] = (fNewVec[0] + 1) * nScreenW / 2;
		fNewVec[1] = nScreenH / 2 - fNewVec[1] * nScreenH / 2;
		format(str, 256, "%0.5f %0.5f %0.5f", fNewVec[0], fNewVec[1], fNewVec[2]);
	}
	SendClientMessage(playerid, -1, str);
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
}*/

GetVehiclePosEx(vid, &Float:px, &Float:py, &Float:pz, Float:offsetx = 0.0, Float:offsety = 0.0, Float:offsetz = 0.0)
{
	new
		Float:rx, Float:ry, Float:rz,
		Float:sx, Float:sy, Float:sz,
		Float:cy, Float:cx, Float:cz;
	GetVehiclePos(vid, px, py, pz);
	GetVehicleRot(vid, rx, ry, rz);
	sx = floatsin(rx, degrees),
	sy = floatsin(ry, degrees),
	sz = floatsin(rz, degrees),
	cx = floatcos(rx, degrees),
	cy = floatcos(ry, degrees),
	cz = floatcos(rz, degrees);
	if (offsetx)
	{
		px = px + offsetx * (cy * cz - sx * sy * sz);
		py = py + offsetx * (cz * sx * sy + cy * sz);
		pz = pz - offsetx * (cx * sy);
	}
	if (offsety)
	{
		px = px - offsety * (cx * sz);
		py = py + offsety * (cx * cz);
		pz = pz + offsety * (sx);
	}
	if (offsetz)
	{
		px = px + offsetz * (cz * sy + cy * sx * sz);
		py = py - offsetz * (cy * cz * sx + sy * sz);
		pz = pz + offsetz * (cx * cy);
	}
	return 1;
}

GetVehicleRot(vehicleid, &Float:rx, &Float:ry, &Float:rz)
{
	new
		Float:qw,
		Float:qx,
		Float:qy,
		Float:qz;
	GetVehicleRotationQuat(vehicleid, qw, qx, qy, qz);
	ConvertQuatToEuler(qw, -qx, -qy, -qz, rx, ry, rz);
	return 1;
}

ConvertQuatToEuler(Float:qw, Float:qx, Float:qy, Float:qz, &Float:rx, &Float:ry, &Float:rz)
{
	new
		Float:sqw = qw * qw,
		Float:sqx = qx * qx,
		Float:sqy = qy * qy,
		Float:sqz = qz * qz;
	rx = asin (2 * (qw * qx + qy * qz) / (sqw + sqx + sqy + sqz));
	ry = atan2(2 * (qw * qy - qx * qz), 1 - 2 * (sqy + sqx));
	rz = atan2(2 * (qw * qz - qx * qy), 1 - 2 * (sqz + sqx));
	return 1;
}

/*enum MatrixParts
{
	mp_PITCH,
	mp_ROLL,
	mp_YAW,
	mp_POS
};

enum MatrixIndicator
{
	Float:mi_X,
	Float:mi_Y,
	Float:mi_Z
};*/

/*
	Get Corresponding GTA {{Internal}} Vehicle Matrix
*/
//aka quaternion to matrix conversion + including position
/*stock GetVehicleMatrix(vehicleid, Mat4x3[MatrixParts][MatrixIndicator])
{
//initial processing step - gathering information
	new
		Float:x,
		Float:y,
		Float:z,
		Float:w,
		Float:Pos[3];

	GetVehicleRotationQuat(vehicleid,w,x,y,z);
	GetVehiclePos(vehicleid,Pos[0],Pos[1],Pos[2]);

//initialized math for quaternion to matrix conversion {for sake of simplicity and efficiency}
	new
		Float:x2 = x * x,
		Float:y2 = y * y,
		Float:z2 = z * z,
		Float:xy = x * y,
		Float:xz = x * z,
		Float:yz = y * z,
		Float:wx = w * x,
		Float:wy = w * y,
		Float:wz = w * z;

//the maths required to convert a quat to a matrix
	Mat4x3[mp_PITCH][mi_X] = 1.0 - 2.0 * (y2 + z2);
	Mat4x3[mp_PITCH][mi_Y] = 2.0 * (xy - wz);
	Mat4x3[mp_PITCH][mi_Z] = 2.0 * (xz + wy);
	Mat4x3[mp_ROLL][mi_X] = 2.0 * (xy + wz);
	Mat4x3[mp_ROLL][mi_Y] = 1.0 - 2.0 * (x2 + z2);
	Mat4x3[mp_ROLL][mi_Z] = 2.0 * (yz - wx);
	Mat4x3[mp_YAW][mi_X] = 2.0 * (xz - wy);
	Mat4x3[mp_YAW][mi_Y] = 2.0 * (yz + wx);
	Mat4x3[mp_YAW][mi_Z] = 1.0 - 2.0 * (x2 + y2);
//the gta vehicle matrix has the position in it, I want it to keep just like GTA does so I put the position in
	Mat4x3[mp_POS][mi_X] = Pos[0];
	Mat4x3[mp_POS][mi_Y] = Pos[1];
	Mat4x3[mp_POS][mi_Z] = Pos[2];
	return 1;
}*/

/*
	Get position offset at position corresponding to the correct vehicle rotation
*/
/*stock PositionFromVehicleOffset(vehicle,Float:offX,Float:offY,Float:offZ,&Float:x,&Float:y,&Float:z)
{
//initial processing step - gather information
	new
		Mat4x3[MatrixParts][MatrixIndicator];

	GetVehicleMatrix(vehicle, Mat4x3);

//offset calculation math
	x = offX * Mat4x3[mp_PITCH][mi_X] + offY * Mat4x3[mp_ROLL][mi_X] + offZ * Mat4x3[mp_YAW][mi_X] + Mat4x3[mp_POS][mi_X];
	y = offX * Mat4x3[mp_PITCH][mi_Y] + offY * Mat4x3[mp_ROLL][mi_Y] + offZ * Mat4x3[mp_YAW][mi_Y] + Mat4x3[mp_POS][mi_Y];
	z = offX * Mat4x3[mp_PITCH][mi_Z] + offY * Mat4x3[mp_ROLL][mi_Z] + offZ * Mat4x3[mp_YAW][mi_Z] + Mat4x3[mp_POS][mi_Z];
	return 1;
}

stock Float: Det3x3({ Float, _ }: mat[][]) {
	return
		(mat[0][0] * mat[1][1] * mat[2][2] + mat[0][1] * mat[1][2] * mat[2][0] + mat[0][2] * mat[1][0] * mat[2][1]) -
		(mat[2][0] * mat[1][1] * mat[0][2] + mat[2][1] * mat[1][2] * mat[0][0] + mat[2][2] * mat[1][0] * mat[0][1])
	;
}

stock OffsetFromVehiclePosition(vehicle, Float: x, Float: y, Float: z, &Float:offX, &Float:offY, &Float:offZ) {
	//initial processing step - gather information
	new
		Mat4x3[MatrixParts][MatrixIndicator]
	;
	GetVehicleMatrix(vehicle, Mat4x3);
	// offset calculation
	x -= Mat4x3[mp_POS][mi_X];
	y -= Mat4x3[mp_POS][mi_Y];
	z -= Mat4x3[mp_POS][mi_Z];
#if 1 // Cramer's rule
	new
		Float: Mat3x3_1[3][3],
		Float: Mat3x3_2[3][3],
		Float: Mat3x3_3[3][3]
	;
	Mat3x3_1[0][0] = Mat4x3[mp_PITCH][mi_X];
	Mat3x3_1[1][0] = Mat4x3[mp_PITCH][mi_Y];
	Mat3x3_1[2][0] = Mat4x3[mp_PITCH][mi_Z];
	Mat3x3_1[0][1] = Mat4x3[mp_ROLL][mi_X];
	Mat3x3_1[1][1] = Mat4x3[mp_ROLL][mi_Y];
	Mat3x3_1[2][1] = Mat4x3[mp_ROLL][mi_Z];
	Mat3x3_1[0][2] = Mat4x3[mp_YAW][mi_X];
	Mat3x3_1[1][2] = Mat4x3[mp_YAW][mi_Y];
	Mat3x3_1[2][2] = Mat4x3[mp_YAW][mi_Z];

	offZ = Det3x3(Mat3x3_1);

	if(offZ != 0.0) {
		Mat3x3_2 = Mat3x3_1;
		Mat3x3_3 = Mat3x3_1;

		Mat3x3_1[0][0] = Mat3x3_2[0][1] = Mat3x3_3[0][2] = x;
		Mat3x3_1[1][0] = Mat3x3_2[1][1] = Mat3x3_3[1][2] = y;
		Mat3x3_1[2][0] = Mat3x3_2[2][1] = Mat3x3_3[2][2] = z;

		offX = Det3x3(Mat3x3_1) / offZ;
		offY = Det3x3(Mat3x3_2) / offZ;
		offZ = Det3x3(Mat3x3_3) / offZ;
	}
#else // Gaussian elimination
	new
		Float: pX = Mat4x3[mp_PITCH][mi_X],
		Float: pY = Mat4x3[mp_PITCH][mi_Y],
		Float: pZ = Mat4x3[mp_PITCH][mi_Z],
		Float: rX = Mat4x3[mp_ROLL][mi_X],
		Float: rY = Mat4x3[mp_ROLL][mi_Y],
		Float: rZ = Mat4x3[mp_ROLL][mi_Z],
		Float: yX = Mat4x3[mp_YAW][mi_X],
		Float: yY = Mat4x3[mp_YAW][mi_Y],
		Float: yZ = Mat4x3[mp_YAW][mi_Z]
	;
	offZ = ((z * pX - pZ * x) * rX - (rZ * pX - pZ * rX) * x) / ((yZ * pX - pZ * yX) * rX - (rZ * pX - pZ * rX) * yX);
	offY = (y * pX - pY * x - offZ * (yY * pX - pY * yX)) / (rY * pX - pY * rX);
	offX = (x - offZ * yX - offY * rX) / pX;
#endif
}*/

/*  Update Log / Old Versions

	***: Version 1.0 Beta

	Twisted Metal Missile & Energy System:

		Missile Firing
		Missile Accuracy
		Missile Locking / Homing
		Missile Damage Stacking
		Missile Hitbars

	Map System along with previewing feature
	Original Twisted Metal Audio
	Race Progress System
	Multiple Gaming Lobbies (3 for gameplay and 1 for freeroam)

	2015

	Improved jumps significantly

	2014

	Added so that the countdown ends quicker if all the players in the game spawned

	05/06/2013 - v0.65

	New better looking, optimized class selection
	Optimized speed between connect - spawn
	New TM PS3 hud, players can switch between the TM Black HUD and the TM PS3 HUD
	Tweaked Roadkill's special, it's now able to shoot the amount of missiles that is already charged
	New gamemode called 'Freeroam', freeroam has it's own game lobby
	New MultiPlayer-Tutorial that is played in the Freeroam lobby, new players must complete this Tutorial
	The tutorial can be re-done at any point while in the Freeroam lobby
	Freeroam is a new feature to Twisted Metal, it has not been seen in the series before.

	17/03/2013 - v0.6

	Added garage customization (car colors, wheel changes)
	Fixed most bugs with multiple gaming lobbies
	Optimized all game updates
	Made games begin at countdown 00:00 instead of 00:01
	Fixed stalker missile charge bar when you have multiple stalker missiles
	Fixed firing the last napalm you have will not update your hud to your next available missile
	Fixed spawning, you will now always spawn properly no matter what
	Optimized missile switching

	15/07/2012 - 25/08/2012; 24/12/2012 - 26/12/2012: v0.5

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
	Fixed missile colliding and targeting team players
	Fixed the score box for deathmatch, hunted & last man standing
	Fixed spawning for high pingers
	Fixed EMP not unfreezing players
	Fixed map interpolation issues
	Fixed most missiles offset issues

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
	Added information at registration for players to learn about "#SERVER_NAME"
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

/*

Deadliest Vehicle / Character - Reaper / Mr.Grimm
Weakest Vehicle / Character - Reaper / Mr.Grimm
Most Defensive Vehicle / Character - Darkside / Dollface
Most Offensive Vehicle / Character - Roadkill / John Doe

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

TMC_VERMIN:

Vermin's Rocket will zoom in on enemies

You will be able to fly the Rat Rocket if the alt Special Weapon is enabled. Use the Arrow Keys
to speed up or slow down. You can even stop in mid air.

Junkyard dog:
Fire the taxi at enemies or drop it in traffic for a hidden surprise.
Use your Special Weapon to ready up a taxi behind your truck, then throw it at your opponents.
Use alt Special Weapon to drop Health Taxi to nearby teammates. This is only for team games.
The Health Taxi will only give health to your teammates, not you.
While in a non-team game, alt Special Weapon switches your taxi to a Death Taxi.

TMC_OUTLAW:
Special Weapon auto targets enemies. Tapping the R2 button while firing adds grenades into the mix.
Outlaw's Special Weapon allows you to toggle the targeted enemy using the R3 button.
At any time during your Special Weapon, press the DOWN button to fire in reverse. Press DOWN button again to return to normal.
Rear fire your Special Weapon to automatically target opponents behind you.

TMC_REAPER:
The Chainsaw Special Weapon may not track enemies very well but will do a lot of damage if it connects.
Do a wheelie to set fire to the chainsaw for extra damage.
Drag the Chainsaw Special Weapon on the ground by doing a wheelie. Once it is heated up you will do even more damage if you can line up the shot.
Perform a wheelie by pulling back on the Left Stick.
Use the alt Special Weapon to manually target opponents with an RPG
After firing your RPG, waiting until stage 2 to detonate will increase the damage and range.

TMC_ROADKILL:
Charge Special Weapon by holding the Fire button until the charge bar is full, then release the Fire button to fire a stream of bullets.
Charge up the alt Special Weapon by holding the Fire button. When the charge meter gets into the red, release and quickly hold the fire button again. Repeat to fully charge. Beware of overcharging.
Rear fire the Special Weapon to drop mines.
Your alt Special Weapon is harder to use but causes a lot more damage.

TMC_DARKSIDE:
Rear fire your special weapon to drop mines behind you.
Hold fire on your Special Weapon to perform a deadly turbo ram.
Enable your alt Special Weapon and hold the fire button to unleash minigun fury on your enemies.
When using the minigun click the R3 button to change the targeted enemy.

TMC_SHADOW:
The farther the coffin travels the larger the explosion. This inflicts more damage in a bigger radius.
Manually detonate the coffin by pressing the Fire button.
Use your alt Special Weapon to manually target opponents with your coffin.
The longer your coffin Special Weapon travels the more damage it does.

*/

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

CREATE TABLE IF NOT EXISTS "#mySQL_Maps_Table" (
  `Map_Name` varchar(32) NOT NULL,
  `Map_Type` int(11) NOT NULL,
  `Mapid` int(11) NOT NULL,
  `Lowest_Z` float NOT NULL default '0',
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

*/

//base: The height of launch in relation to the height of destination. If you want the object to land 10 units above the launch position, use a base height of 10.
//velocity: The total velocity you want to launch with. Remember that launch velocity and launch angle affect all characteristics of flight.
//angle: The angle of launch in relation to the horizontal. Remember that launch velocity and launch angle affect all characteristics of flight.
//gravity: The amount of gravity that you wish to exert on the object as it flies. For realism, use 9.8 (regarded as Earth's normal gravity at sea level), though it is fun to mess around with this

stock GetFlightData(Float:base, Float:velocity, Float:angle, fData[][FLIGHT_DATA], points = sizeof(fData), Float:gravity = 9.8)
{
	for(new i, Float:increment = floatdiv(GetFlightMaxTime(base, velocity, angle, gravity), float(points)), Float:cTime = increment; i < points; i++, cTime += increment)
	{
		GetFlightConditionsAtTime(base, velocity, angle, cTime, fData[i][FLIGHT_DISTANCE], fData[i][FLIGHT_HEIGHT], fData[i][FLIGHT_VELOCITY][0], fData[i][FLIGHT_VELOCITY][1], gravity);
	}
}

GetFlightConditionsAtTime(Float:base, Float:velocity, Float:angle, Float:time, &Float:distance, &Float:height, &Float:x, &Float:y, Float:gravity = 9.8)
{
	distance = floatmul(floatmul(velocity, floatcos(angle, degrees)), time);
	height = floatadd(base, floatsub(floatmul(floatmul(velocity, floatsin(angle, degrees)), time), floatdiv(floatmul(gravity, floatpower(time, 2.0)), 2.0)));
	GetFlightInitialVelocity(velocity, angle, x, y);
	y -= floatmul(gravity, time);
}

GetFlightInitialVelocity(Float:velocity, Float:angle, &Float:x, &Float:y)
{
	x = floatmul(velocity, floatcos(angle, degrees));
	y = floatmul(velocity, floatsin(angle, degrees));
}

Float:GetFlightMaxTime(Float:base, Float:velocity, Float:angle, Float:gravity = 9.8)
{
	new Float:x, Float:y, Float:fTimes[2];
	GetFlightInitialVelocity(velocity, angle, x, y);

	fTimes[0] = floatadd(floatdiv(y, gravity), floatsqroot(floatsub(floatdiv(floatpower(y, 2.0), floatpower(gravity, 2.0)), floatdiv(floatmul(base, 2.0), gravity))));
	fTimes[1] = floatsub(floatdiv(y, gravity), floatsqroot(floatsub(floatdiv(floatpower(y, 2.0), floatpower(gravity, 2.0)), floatdiv(floatmul(base, 2.0), gravity))));

	return (fTimes[0] >= fTimes[1]) ? (fTimes[0]) : (fTimes[1]);
}

Float:GetRequiredAngle(Float:range, Float:velocity, Float:gravity = 9.8)
{
	return floatdiv(asin(floatdiv(floatmul(range, gravity), floatpower(velocity, 2.0))), 2.0);
}

Float:GetVelocityXY(Float:x, Float:y)
{
	return floatsqroot(floatadd(floatpower(x, 2.0), floatpower(y, 2.0)));
}

/*GetXYInDirectionOfPosition(fAngle, x, y, data[count][FLIGHT_DISTANCE]);
//MoveObject(Rocket, x, y, fHeight + data[count][FLIGHT_HEIGHT], speed);
data[10][FLIGHT_DATA],

if(count == sizeof(data))
			{
				CreateExplosion(x, y, z, 3, 20.0);
				DestroyObject(Rocket);
				Rocket = -1;
				return 1;
				}

			GetXYInDirectionOfPosition(fAngle, x, y, data[count][FLIGHT_DISTANCE]);

			MoveObject(Rocket, x, y, z - data[count - 1][FLIGHT_HEIGHT] + data[count][FLIGHT_HEIGHT], GetVelocityXY(data[count][FLIGHT_VELOCITY][0], data[count][FLIGHT_VELOCITY][1]));
			count++;
		}
*/
/*
GetPlayerCameraPos( playerid, cX, cY, cZ );
GetPlayerCameraFrontVector( playerid, vX, vY, vZ );

getAverageZ( averageZ );

g_warshipData[ E_MISSILE ] = CreateObject( 3786, cX, cY, cZ - 1.0, 0, 0, 0 );

for( new i; i < distance; i++ )
{
	cX += i * vX;
	cY += i * vY;
	cZ += i * vZ;
	if( cZ < averageZ ) break;
}

SetObjectFaceCoords3D( g_warshipData[ E_MISSILE ], cX, cY, averageZ, 0, 90, 0 );
MoveObject( g_warshipData[ E_MISSILE ], cX, cY, averageZ, 50.0 );
*/
/*#define ChangeClockwise(%0) (360.0-(%0))
stock bool:IsSphereInVehicleBeam(vehicleid, Float:sphere_x, Float:sphere_y, Float:sphere_z, Float:sphere_radius)
{
	new Float:v_pos[6], Float:beam_vect[3], Float:normal_vect[2][3];
	GetVehiclePos(vehicleid, v_pos[0], v_pos[1], v_pos[2]);
	GetVehicleRotation(vehicleid, v_pos[3], v_pos[4], v_pos[5]);

	// Position to infront of point vector
	beam_vect[0] = floatsin(ChangeClockwise(v_pos[3]), degrees);
	beam_vect[1] = floatcos(ChangeClockwise(v_pos[3]), degrees);
	beam_vect[2] = floatsin(ChangeClockwise(v_pos[4]), degrees);

	// First normalized vector
	normal_vect[0][0] = (beam_vect[1]*(v_pos[2]-sphere_z))-(beam_vect[2]*(v_pos[1]-sphere_y));
	normal_vect[0][1] = (beam_vect[2]*(v_pos[0]-sphere_x))-(beam_vect[0]*(v_pos[2]-sphere_z));
	normal_vect[0][2] = (beam_vect[0]*(v_pos[1]-sphere_y))-(beam_vect[1]*(v_pos[0]-sphere_x));

	// Final normalized vector
	normal_vect[1][0] = (beam_vect[1]*normal_vect[0][2])-(beam_vect[2]*normal_vect[0][1]);
	normal_vect[1][1] = (beam_vect[2]*normal_vect[0][0])-(beam_vect[0]*normal_vect[0][2]);
	normal_vect[1][2] = (beam_vect[0]*normal_vect[0][1])-(beam_vect[1]*normal_vect[0][0]);

	if((((((normal_vect[1][0]*v_pos[1])-(normal_vect[1][1]*v_pos[0]))+(sphere_x*normal_vect[1][1]))-(sphere_y*normal_vect[1][0]))/((normal_vect[1][0]*beam_vect[1])-(normal_vect[1][1]*beam_vect[0]))) < 0.0) return false; // Behind the vehicle
	new Float:my_s = (((v_pos[0]-sphere_x)*beam_vect[1])+((sphere_y-v_pos[1])*beam_vect[0]))/((normal_vect[1][0]*beam_vect[1])-(normal_vect[1][1]*beam_vect[0]));
	if((((normal_vect[1][0]*my_s)*(normal_vect[1][0]*my_s))+((normal_vect[1][1]*my_s)*(normal_vect[1][1]*my_s))+((normal_vect[1][2]*my_s)*(normal_vect[1][2]*my_s))) <= (sphere_radius*sphere_radius)) return true; // Hits
	return false; // Not
}

stock GetVehicleRotationEx(vehicleid, &Float:x, &Float:y, &Float:z)
{
	new Float:quat_w, Float:quat_x, Float:quat_y, Float:quat_z;
	GetVehicleRotationQuat(vehicleid, quat_w, quat_x, quat_y, quat_z);
	x = atan2(2*((quat_x*quat_y)+(quat_w+quat_z)), (quat_w*quat_w)+(quat_x*quat_x)-(quat_y*quat_y)-(quat_z*quat_z));
	y = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)), (quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
	z = asin(-2*((quat_x*quat_z)+(quat_w*quat_y)));
}*/

/*
					© Karim "Kar" K. F. Cambridge 2010 - 2018
								All Rights Reserved

							   	Twisted Metal: SA-MP

	Unauthorized copying or distribution of this file via any medium is strictly prohibited
	
							Proprietary and confidential
*/