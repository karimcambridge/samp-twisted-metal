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

//todo
//junkyard dog taxi slam
//shadow death coffin
//meat wagon

#include <a_samp>
#if defined MAX_PLAYERS
	#undef MAX_PLAYERS
	#define MAX_PLAYERS 32
#endif
#if defined MAX_VEHICLES
	#undef MAX_VEHICLES
	#define MAX_VEHICLES 32
#endif
#define MAX_PROGRESS_BARS_PER_PLAYER (MAX_PLAYERS * 3)
//#define TIMER_FIX_DEBUG  true
//#include <TimerFix>
#include <sscanf2>
#include <a_mysql>
#include <foreach>
#include <zcmd>
#include <gl_common>
#include <progress>

#define MAP_ANDREAS_MODE_NONE			0
#define MAP_ANDREAS_MODE_MINIMAL		1
#define MAP_ANDREAS_MODE_MEDIUM			2	// currently unused
#define MAP_ANDREAS_MODE_FULL			3
#define MAP_ANDREAS_MODE_NOBUFFER		4

native MapAndreas_Init(mode);
native MapAndreas_FindZ_For2DCoord(Float:X, Float:Y, &Float:Z);
native MapAndreas_FindAverageZ(Float:X, Float:Y, &Float:Z);
native MapAndreas_Unload();

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

#define KEY_AIM                   (128)

enum E_FIXES_WORLDBOUND_DATA
{
	// "Previous".
	Float:E_FIXES_WORLDBOUND_DATA_PX,
 	Float:E_FIXES_WORLDBOUND_DATA_PY,
 	Float:E_FIXES_WORLDBOUND_DATA_PZ,
 	// "Lower".
 	Float:E_FIXES_WORLDBOUND_DATA_LX,
 	Float:E_FIXES_WORLDBOUND_DATA_LY,
 	// "Upper".
 	Float:E_FIXES_WORLDBOUND_DATA_UX,
 	Float:E_FIXES_WORLDBOUND_DATA_UY
}

new FIXES_gsWorldbounds[MAX_PLAYERS][E_FIXES_WORLDBOUND_DATA];

stock FIXES_SetPlayerWorldBounds(playerid, Float:x_max, Float:x_min, Float:y_max, Float:y_min)
{
    // This code could do with a way to mostly remove the checks.  Maybe
    // when setting everything to FIXES_INFINITY (with default parameters).
    new Float:tmp;
    if (x_max < x_min)
    {
        tmp = x_min;
        x_min = x_max;
        x_max = tmp;
    }
    if (y_max < y_min)
    {
        tmp = y_min;
        y_min = y_max;
        y_max = tmp;
    }
    // Give a little leway so this fix isn't noticed if you're not trying to
    // break through the world bounds.  Leway removed in favour of keys.
    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_LX] = x_min;
    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_UX] = x_max;

    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_LY] = y_min;
    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_UY] = y_max;

    GetPlayerPos(playerid, tmp, tmp, tmp);
    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PX] = (x_max - x_min) / 2 + x_min;
    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PY] = (y_max - y_min) / 2 + y_min;
    FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PZ] = tmp;
    return SetPlayerWorldBounds(playerid, x_max, x_min, y_max, y_min);
}

#define SetPlayerWorldBounds FIXES_SetPlayerWorldBounds

/*stock FIXES_CreateObject(modelid, Float:X, Float:Y, Float:Z, Float:rX, Float:rY, Float:rZ, Float:DrawDistance = 0.0)
{
    printf("[System: CreateObject] - %d, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f", modelid, X, Y, Z, rX, rY, rZ, DrawDistance);
    return CreateObject(modelid, X, Y, Z, rX, rY, rZ, DrawDistance);
}
#define CreateObject FIXES_CreateObject
*/
stock FIXES_DestroyObject(objectid)
{
    //printf("[System: DestroyObject] - %d", objectid);
    new rdo = DestroyObject(objectid);
    objectid = INVALID_OBJECT_ID;
    return rdo;
}
#define DestroyObject FIXES_DestroyObject

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
#define Server_Version 	"v1.0"
#define Server_Website 	"lvcnr.net"

#define IRC_Echo_Channel_Password 	"Karim_TMB"

#undef INVALID_TEXT_DRAW
#define INVALID_TEXT_DRAW       Text:0xFFFF

#define HOLDING(%0) \
	((newkeys & (%0)) == (%0))
#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define RELEASED(%0) \
	(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))

main() {}

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

#define cRed "{FF0000}"
#define cTeal "{00F5FF}"
#define cLime "{19E03D}"
#define cWhite "{FFFFFF}"
#define cPurple "{A82FED}"
#define cNiceBlue "{30AEFC}"

#define RegDialog 33
#define LoginDialog 34

#define MISSILE_DETONATE_TIME 2500 //milliseconds
#define MISSILE_SPEED 65.0
#define MISSILE_FIRE_KEY KEY_ACTION
#define MACHINE_GUN_KEY KEY_CROUCH
#define Missile_Update_Index 15

//18728	smoke_flare - Roadkill's special
//19270 MapMarker_Fire - Roadkill's Special

#define Crazy8 474
#define Crimson_Fury 420
#define Junkyard_Dog 525
#define Brimstone 576
#define Outlaw 599
#define Reaper 463
#define Mr.Grimm Reaper
#define Roadkill 541
#define Thumper 474
#define Spectre 475
#define Darkside 514
#define Shadow 442
#define Meat_Wagon 479
#define Vermin 482
#define ManSalughter 455
#define Sweet_Tooth 423

#define Machine_Gun 3002 /*pool ball*//*19718 custom bullet*//*18633 - Wrench*/
#define Missile_Default_Object 3790
#define Missile_Napalm_Object 1222

#define INVALID_MISSILE_ID -1

#define Missile_Special 0
#define Missile_Fire 1
#define Missile_Homing 2
#define Missile_Power 3
#define Missile_Napalm 4
#define Missile_Environmentals 5
#define Missile_Ricochet 6
#define Missile_Stalker 7
#define Missile_Zoomys 8
#define MIN_MISSILEID 0
#define MAX_MISSILEID 9
#define Missile_Machine_Gun 9
#define Missile_Machine_Gun_Upgrade 10
#define Missile_RemoteBomb 11
#define Missile_EMP 12

#define MAX_MISSILE_SLOTS 23
#define ENERGY_MISSILE_SLOT 20
#define ENVIRONMENTAL_START_SLOT 16
#define MAX_MACHINE_GUN_SLOTS 25

/*Junkyard dog
Fire the taxi at enemies or drop it in traffic for a hidden surprise.
Use your Special Weapon to ready up a taxi behind your truck, then throw it at your opponents.
Use alt Special Weapon to drop Health Taxi to nearby teammates. This is only for team games.
The Health Taxi will only give health to your teammates, not you.
While in a non-team game, alt Special Weapon switches your taxi to a Death Taxi.
Outlaw
Special Weapon auto targets enemies. Tapping the R2 button while firing adds grenades into the mix.
Outlaw's Special Weapon allows you to toggle the targeted enemy using the R3 button.
At any time during your Special Weapon, press the DOWN button to fire in reverse. Press DOWN button again to return to normal.
Rear fire your Special Weapon to automatically target opponents behind you.
Reaper
The Chainsaw Special Weapon may not track enemies very well but will do a lot of damage if it connects.
Do a wheelie to set fire to the chainsaw for extra damage.
Drag the Chainsaw Special Weapon on the ground by doing a wheelie. Once it is heated up you will do even more damage if you can line up the shot.
Perform a wheelie by pulling back on the Left Stick.
Use the alt Special Weapon to manually target opponents with an RPG
After firing your RPG, waiting until stage 2 to detonate will increase the damage and range.
Roadkill
Charge Special Weapon by holding the Fire button until the charge bar is full, then release the Fire button to fire a stream of bullets.
Charge up the alt Special Weapon by holding the Fire button. When the charge meter gets into the red, release and quickly hold the fire button again. Repeat to fully charge. Beware of overcharging.
Rear fire the Special Weapon to drop mines.
Your alt Special Weapon is harder to use but causes a lot more damage.
Darkside
Rear fire your special weapon to drop mines behind you.
Hold fire on your Special Weapon to perform a deadly turbo ram.
Enable your alt Special Weapon and hold the fire button to unleash minigun fury on your enemies.
When using the minigun click the R3 button to change the targeted enemy.
Shadow
The farther the coffin travels the larger the explosion. This inflicts more damage in a bigger radius.
Manually detonate the coffin by pressing the Fire button.
Use your alt Special Weapon to manually target opponents with your coffin.
The longer your coffin Special Weapon travels the more damage it does.
*/

new TwistedDeathArray[24][42] =
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
	{"Man Salughter's Boulder Throw"},
	{"Sweet Tooth's Missile Rack"}, // 2012 Laughing Ghost maybe ALT it?
	{"Fire Missile"},
	{"Homing Missile"},
	{"Power Missile"},
	{"Napalm Missile"},
	{"Environmentals"},
	{"Ricochet Missile"},
	{"Stalker Missile"},
	{"Zoomy Missile"},
	{"Machine Gun"},
	{"Upgraded Machine Gun"},
	{"Remote Bomb"}
};

forward OnPlayerTwistedDeath(killerid, killer_vehicleid, deathid, death_vehicleid, missileid, killerid_modelid);
public OnPlayerTwistedDeath(killerid, killer_vehicleid, deathid, death_vehicleid, missileid, killerid_modelid)
{
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
				case ManSalughter: reason = 11;
				case Sweet_Tooth: reason = 12;
			}
		}
		default: reason = 12 + missileid;
	}
	printf("[System: OnPlayerTwistedDeath] - (%d, %d, %d, %d, %d (%s), killer: %s(%d))", killerid, killer_vehicleid, deathid, death_vehicleid, missileid, TwistedDeathArray[reason], GetTwistedMetalName(killerid_modelid), killerid_modelid);
	return 1;
}
forward Float:GetTwistedMetalMaxHealth(vehicleid);
stock Float:GetTwistedMetalMaxHealth(vehicleid)
{
	new Float:health;
    switch(GetVehicleModel(vehicleid))
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
		case Junkyard_Dog: health = 260.0;
		case ManSalughter: health = 270.0;
		case Darkside: health = 280.0;
		default: health = 150.0;
	}
	return health;
}
/*
Reaper --- 90 Health
Crimson Fury -- 110 Health
Talon --- 120 Health
Kamikaze --- 150 Health
Roadkill --- 160 Health
Axel --- 170 Health
Death Warrant --- 180 Health
Vermin --- 205 Health
Road Boat --- 210 Health
Meat Wagon --- 210 Health
Shadow --- 230 Health
Outlaw --- 240 Health
Sweet Tooth --- 250 Health
Junkyard Dog --- 260 Health
Darkside --- 280 Health
Juggernaut --- 400 Health*/

#define INVISIBILITY_INDEX 100

new Float:VehicleOffsetX[MAX_VEHICLES],
 	Float:VehicleOffsetY[MAX_VEHICLES],
 	Float:VehicleOffsetZ[MAX_VEHICLES];
 	
new Nitro_Bike_Object[MAX_PLAYERS] = {INVALID_OBJECT_ID, ...};

new WasDamaged[MAX_VEHICLES],
 	Napalm_Timer[MAX_PLAYERS],
 	Vehicle_Napalm[MAX_VEHICLES],
 	Vehicle_Smoke[MAX_VEHICLES][MAX_MISSILE_SLOTS],
 	Vehicle_Missile[MAX_VEHICLES][MAX_MISSILE_SLOTS],
 	Vehicle_Missile_Light[MAX_VEHICLES][MAX_MISSILE_SLOTS],
 	Vehicle_Missileid[MAX_VEHICLES],
 	Vehicle_Machine_Gun[MAX_VEHICLES][MAX_MACHINE_GUN_SLOTS],
 	Vehicle_Machine_Gunid[MAX_VEHICLES],
 	Vehicle_Firing_Missile[MAX_VEHICLES],
 	Vehicle_Using_Environmental[MAX_VEHICLES],
 	Vehicle_Environmental_Slot[MAX_VEHICLES],
 	Machine_Gun_Firing_Timer[MAX_PLAYERS],
 	Vehicle_Machine_Gun_Object[MAX_VEHICLES][2],
 	Vehicle_Machine_Gun_Currentid[MAX_VEHICLES],
 	Vehicle_Machine_Gun_CurrentSlot[MAX_VEHICLES],
 	Vehicle_Missile_Special_Slot[MAX_VEHICLES]
;
 	
new
    Object_Slot[MAX_OBJECTS] = {0, ...},
	Object_Type[MAX_OBJECTS] = {0, ...},
	Object_Owner[MAX_OBJECTS] = {INVALID_VEHICLE_ID, ...},
	Object_OwnerEx[MAX_OBJECTS] = {INVALID_PLAYER_ID, ...}
;

forward UpdateMissile(playerid, id, objectid, missileid, slot, vehicleid);
forward Explode_Missile(vehicleid, slot, missileid);
forward OnVehicleFire(playerid, vehicleid, slot, missileid);
forward OnVehicleMissileExploded(vehicleid, slot, missileid);
forward Destroy_Object(objectid, playerid);
forward SendRandomMsg();
forward UpdatePlayerMissileStatus(playerid);
//forward ChangeMap();

new Text3D:BotName[1];
//new MovingLifts[2];
new HelicopterAttack = INVALID_OBJECT_ID;

#define MAP_DOWNTOWN 4

new iMap = MAP_DOWNTOWN;

forward OnMapBegin();
public OnMapBegin()
{
	switch(iMap)
	{
	    case MAP_DOWNTOWN:
	    {
	        if(IsValidObject(HelicopterAttack)) DestroyObject(HelicopterAttack);
	        //if(IsValidObject(MovingLifts[0])) DestroyObject(MovingLifts[0]);
	        //if(IsValidObject(MovingLifts[1])) DestroyObject(MovingLifts[1]);
	        Delete3DTextLabel(BotName[0]);
	    	HelicopterAttack = CreateObject(10757, -2025, -860, 50.0, 22, 11, 180, 150.0);//x, y, z, rx, ry, rz
			//MovingLifts[0] = CreateObject(1241, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			//MovingLifts[1] = CreateObject(1241, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			BotName[0] = Create3DTextLabel("[BOT]HelicopterAttack", 0xFFFFFFFF, 3484.7271, 284.1839, 23.0870, 70.0, 0);
		}
	}
	return 1;
}

enum Downtown_Enum
{
	D_modelid,
	Float:D_X,
	Float:D_Y,
 	Float:D_Z,
 	Float:DR_X,
	Float:DR_Y,
 	Float:DR_Z,
 	Float:DR_DrawDistance
};
new a_Downtown_Positions[17][Downtown_Enum] =
{
	{8151, -2124.69995117, -740.70001221, 35.59999847, 0.0, 0.0, 90.0, 0.0}, //object(vgsselecfence05) (1)
	{8150, -2022.69995117, -708.79998779, 34.20000076, 0.0, 0.0, 0.0, 0.0}, //object(vgsselecfence04) (1)
	{8150,-1931.69995117, -708.79998779, 34.29999924, 0.0, 0.0, 0.0, 0.0}, //object(vgsselecfence04) (2)
	{8150, -1868.80004883, -771.29998779, 34.09999847, 0.0, 0.0, 90.0, 0.0}, //object(vgsselecfence04) (3)
	{8150, -1868.40002441, -895.90002441, 34.00000000, 0.0, 0.0, 90.0, 0.0}, //object(vgsselecfence04) (4)
	{8150, -1936.30004883, -1079.00000000, 34.20000076, 0.0,0.0, 270.0, 0.0}, //object(vgsselecfence04) (5)
	{8151, -1901.59997559, -996.50000000, 33.79999924, 0.0, 180.0, 178.0, 0.0}, //object(vgsselecfence05) (2)
	{980, -1931.00000000, -1034.80004883, 33.79999924, 0.0, 0.0, 358.0, 0.0}, //object(airportgate) (1)
	{8150, -2164.69995117, -832.70001221, 33.79999924, 0.0, 0.0, 270.0, 0.0}, //object(vgsselecfence04) (6)
	{8150, -2164.60009766, -958.29998779, 33.79999924, 0.0, 0.0, 270.0, 0.0}, //object(vgsselecfence04) (7)
	{8262, -2089.80004883, -1017.40002441, 34.20000076, 0.0, 0.0, 90.0, 0.0}, //object(vgsselecfence13) (1)
	{8262, -2087.89990234, -1017.50000000, 41.00000000, 0.0, 0.0, 90.0, 0.0}, //object(vgsselecfence13) (2)
	{6959, -2019.80004883, -782.70001221, 30.26000023, 0.0, 0.0, 0.0, 0.0}, 	//object(vegasnbball1) (2)
	{6959, -2022.80004883, -822.59997559, 30.26000023, 0.0, 0.0, 0.0, 0.0}, 	//object(vegasnbball1) (3)
	{6959, -2021.69995117, -862.29998779, 30.26000023, 0.0, 0.0, 0.0, 0.0}, 	//object(vegasnbball1) (4)
	{6959, -2022.30004883, -901.40002441, 30.26000023, 0.0, 0.0, 0.0, 0.0}, 	//object(vegasnbball1) (5)
	{6959, -2021.59997559, -941.29998779, 30.26000023, 0.0, 0.0, 270.0, 0.0} //object(vegasnbball1) (6)
};
new a_Downtown_Objects[sizeof(a_Downtown_Positions)];

new Update_Remote_Bomb_Timer[MAX_PLAYERS];
new Update_Missile_Timer[MAX_PLAYERS][MAX_MISSILE_SLOTS];
new Update_Machine_Gun_Timer[MAX_PLAYERS][MAX_MACHINE_GUN_SLOTS];

stock GetTwistedMissileName(missileid, &vehicleid, bool:checkspecial = false)
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
						case Outlaw: str = "Gun Turret";
						case Reaper: str = "Mr. Grimms Chainsaw";
						case Roadkill: str = "Series Missiles";
						case Thumper: str = "Jet Stream Of Fire";
						case Spectre: str = "Screaming Fiery Missile";
						case Darkside: str = "Darkside Slam";
						case Shadow: str = "Death Coffin";
						case Meat_Wagon: str = "Gurney Bomb";
						case Vermin: str = "Rat Rocket";
						case ManSalughter: str = "Boulder Throw";
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
	    case Missile_Environmentals: str = "Environmental";
	    case Missile_Zoomys: str = "Zoomy";
	    case Missile_Machine_Gun: str = "Machine Gun";
	    case Missile_Machine_Gun_Upgrade: str = "Upgraded Machine Gun";
	    case Missile_RemoteBomb: str = "Remote Bomb";
	    case Missile_EMP: str = "EMP";
	    default: str = "Unknown";
	}
	return str;
}

#define MAX_TIMETEXTS 4

#define TIMETEXT_TOP 1
#define TIMETEXT_TOP_2 0
#define TIMETEXT_MIDDLE 2
#define TIMETEXT_BOTTOM 3

#define TM_STATUS_COLOUR1 0xF5E000FF
#define TM_STATUS_COLOUR2 0xFFFFFFFF

new Float:StatusTextPositions[MAX_TIMETEXTS][2] =
{
    {320.0, 140.0},
    {320.0, 150.0},
    {320.0, 165.0},
    {320.0, 330.0}
};

new Float:StatusTextLetterSize[MAX_TIMETEXTS][2] =
{
    {0.45, 1.8},
    {0.50, 2.0},
    {0.58, 2.2},
    {0.58, 2.2}
};

enum pStatusinfo
{
    StatusIndex,
    StatusTime,
	StatusTextTimer[MAX_TIMETEXTS],
	Text:StatusText[MAX_TIMETEXTS]
}
new pStatusInfo[MAX_PLAYERS][pStatusinfo];

new Status_Text[MAX_PLAYERS][MAX_TIMETEXTS][32];

enum pTextinfo
{
	Text:AimingPlayer,
	Text:AimingBox,
	Text:pBox,
	Text:pUpArrow,
	Text:pLeftArrow,
	Text:pRightArrow,
	Text:pUpArrowKey,
	Text:pLeftArrowKey,
	Text:pRightArrowKey,
	Text:pHealthSign,
	Text:pHealthBar,
	Text:pBoxSeparater,
	Text:pSecondBox,
	Text:pEnergySign,
	Text:pTurboSign,
	Text:pMissileSign[9],
	Text:TDSpeedClock[16],
	//Text:SpeedoMeterNeedle[8],
	Bar:pAiming_Health_Bar,
	Bar:pEnergyBar,
	Bar:pTurboBar
};
//#define Speedometer_Needle_Index 8
new pTextInfo[MAX_PLAYERS][pTextinfo];

new Text:Players_Online_Textdraw = INVALID_TEXT_DRAW;

#define MAX_TURBO 200.0

enum pInfo
{
    CanExitVeh,
    pSkinid,
    pSkin,
    pTurbo,
	pEnergy,
	pSpawned,
	pLastVeh,
	pCarModel,
    pSelection,
    Turbo_Tick,
    Turbo_Timer,
    pSpecialObject,
    pMissiles[9],/*0 - Special, 1 - Fires, 2 - Homing, 3 - Napalms, 4 - Powers, 5 - Environments,
    6 - Ricochets, 7- Stalkers, 8 - Zoomys*/
    pMissile_Special_Time,
    pSpecial_Missile_Update,
    pSpecial_Missile_Vehicle,
    pSpecial_Missile_Object,
    bool:pMissile_Special_Charged,
    pUsername,
    pPassword,
    pIP,
    pDonaterRank,
    Money,
    Score,
	Kills,
	Deaths,
	AdminLevel,
	pRegular,
	bool:pGender,
	EnvironmentalCycle_Timer,
	pBurnout,
	pBurnoutTimer,
};

//new DeActiveSpeedometer[MAX_PLAYERS char];
new PlayerInfo[MAX_PLAYERS][pInfo];
new IsLogged[MAX_PLAYERS];
new LoggedTimer[MAX_PLAYERS];
new Muted[MAX_PLAYERS];

new Current_Vehicle[MAX_PLAYERS];
new Current_Car_Index[MAX_PLAYERS];
new Switched_Vehicle_Rec[MAX_PLAYERS char];

#define TM_SELECTION_X -986.4280
#define TM_SELECTION_Y 1289.2329
#define TM_SELECTION_Z 40.0344
#define TM_SELECTION_ANGLE 220.5888

#define TM_SELECTION_CAMERA_X -985.1891
#define TM_SELECTION_CAMERA_Y 1274.9076
#define TM_SELECTION_CAMERA_Z 44.7193

#define TM_SELECTION_LOOKAT_X -986.4280
#define TM_SELECTION_LOOKAT_Y 1289.2329
#define TM_SELECTION_LOOKAT_Z 41.5344

new Text:SpawnTD = INVALID_TEXT_DRAW;

Playername(playerid)
{
    new pName[24] = " - ";
    if(playerid != INVALID_PLAYER_ID && playerid != -1) GetPlayerName(playerid, pName, 24);
    return pName;
}

new Float:HealthPickupCoords[3][3] = {
    {-1968.6166,-795.9158,32.0306},
    {-1954.5425,-989.5878,35.5157},
    {-1954.8473,-978.8585,41.8281}
};
new HealthPickups[sizeof(HealthPickupCoords)];

new Float:TurboPickupCoords[1][3] = {
	{-1939.7659,-925.4441,32.0302}
};
new TurboPickups[sizeof(TurboPickupCoords)];

new Float:MachineGunUpgradePickupCoords[1][3] = {
	{0.0, 0.0, 10.0}
};
new MachineGunUpgradePickups[sizeof(MachineGunUpgradePickupCoords)];

new Float:HomingPickupCoords[4][3] = {
	{-1941.0214,-1085.2242,30.5805},
	{-1892.0339,-859.2641,31.8302},
	{-1961.3849,-846.6412,35.5146},
	{-2081.6160,-886.9053,71.6587}
};
new HomingPickups[sizeof(HomingPickupCoords)];

new Float:FirePickupCoords[6][3] = {
	{-1969.0414,-786.6783,32.0303},
	{-1892.2778,-807.2610,31.8271},
	{-1949.2175,-875.0110,35.5129},
	{-2129.5322,-809.9766,31.6483},
	{-2081.6638,-835.0388,68.9314},
	{-1954.7003,-737.4468,41.2548}
};
new FirePickups[sizeof(FirePickupCoords)];

new Float:PowerPickupCoords[5][3] = {
	{-1949.5277,-1085.4576,30.5784},
	{-1892.6548,-909.2054,31.8283},
	{-1954.9137,-941.7766,35.5156},
	{-2022.1172,-806.3328,30.8782},
	{-2070.8479,-859.7825,66.4998}
};
new PowerPickups[sizeof(PowerPickupCoords)];

new Float:NapalmPickupCoords[2][3] = {
	{-2023.7727,-911.5933,30.8783},
	{-2079.8171,-870.7611,66.4997}
};
new NapalmPickups[sizeof(NapalmPickupCoords)];

new Float:StalkerPickupCoords[4][3] = {
	{-2128.9412,-911.6611,31.6482},
	{-1885.635, -1017.077, 32.1},
	{-1954.7145,-858.9112,41.4475},
	{-2092.9849,-860.0109,66.4998}
};
new StalkerPickups[sizeof(StalkerPickupCoords)];

new Float:RicochetPickupCoords[2][3] = {
	{-2084.0837,-849.1871,66.4989},
	{-2055.614, -911.293, 31.797}
};
new RicochetPickups[sizeof(RicochetPickupCoords)];

new Float:ZoomyPickupCoords[2][3] = {
	{-1941.2844,-793.4117,32.0289},
	{-2097.9424,-809.0001,65.1329}
};
new ZoomyPickups[sizeof(PowerPickupCoords)];

new Float:EnvironmentalPickupCoords[1][3] = {
	{-1955.0471,-729.1618,35.516}
};
new EnvironmentalPickups[sizeof(PowerPickupCoords)];

new Float:LightningPickupCoords[1][3] = {
	{-2081.6472,-858.5424,66.8750}
};
new LightningPickups[sizeof(LightningPickupCoords)];

#define PICKUPTYPE_HEALTH 0
#define PICKUPTYPE_TURBO 1
#define PICKUPTYPE_SPECIAL_MISSILE 2
#define PICKUPTYPE_HOMING_MISSILE 3
#define PICKUPTYPE_FIRE_MISSILE 4
#define PICKUPTYPE_POWER_MISSILE 5
#define PICKUPTYPE_NAPALM_MISSILE 6
#define PICKUPTYPE_ENVIRONMENTALS 7
#define PICKUPTYPE_RICOCHETS_MISSILE 8
#define PICKUPTYPE_STALKERS_MISSILE 9
#define PICKUPTYPE_ZOOMY_MISSILE 10
#define PICKUPTYPE_LIGHTNING 11
#define PICKUPTYPE_MACHINE_GUN_UPGRADE 12

#define strcpy(%0,%1,%2) \
    strcat((%0[0] = '\0', %0), %1, %2)//strcpy(dest, src, sizeof (dest));

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
new PickupInfo[MAX_PICKUPS][Pickups_data];
new TotalPickups = 0;

#define MYSQL_HOST ""
#define MYSQL_USER ""
#define MYSQL_PASS ""
#define MYSQL_DB   ""

#define BYTES_PER_CELL 4

stock minrand(min, max) return random(max-min)+min; //By Alex "Y_Less" Cole
stock Float:floatrand(Float:min, Float:max) //By Alex "Y_Less" Cole
{
	new imin = floatround(min);
	return floatdiv(float(random((floatround(max)-imin)*100)+(imin*100)),100.0);
}

//new IteratorArray:Streamed_Vehicles[MAX_PLAYERS]<MAX_VEHICLES>;
new Iterator:Vehicles<MAX_VEHICLES>;
new Vehicle_Interior[MAX_VEHICLES];

stock CreateVehicleEx(vehicletype, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay)
{
	new id = CreateVehicle(vehicletype, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay);
    if(!Iter_Contains(Vehicles, id))
	{
		Iter_Add(Vehicles, id);
	}
    Vehicle_Interior[id] = 0;
    Vehicle_Missileid[id] = 0;
    Vehicle_Firing_Missile[id] = 0;
    Vehicle_Using_Environmental[id] = 0;
    Vehicle_Environmental_Slot[id] = 0;
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
		Iter_Remove(Vehicles, vehicleid);
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

stock Float:PointAngle(playerid, Float:xa, Float:ya, Float:xb, Float:yb)
{
	new Float:carangle,Float:xc, Float:yc,Float:angle;
	xc = floatabs(floatsub(xa,xb));
	yc = floatabs(floatsub(ya,yb));
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
		angle = atan(xc/yc);
		if(xb > xa && yb <= ya) angle += 90.0;
		else if(xb <= xa && yb < ya) angle = floatsub(90.0, angle);
		else if(xb < xa && yb >= ya) angle -= 90.0;
		else if(xb >= xa && yb > ya) angle = floatsub(270.0, angle);
	}
	if(IsPlayerInAnyVehicle(playerid)) GetVehicleZAngle(GetPlayerVehicleID(playerid), carangle);
	else GetPlayerFacingAngle(playerid, carangle);
	return floatadd(angle, -carangle);
}

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

stock Float:GetPlayerDistanceToVehicle(playerid, vehicleid)
{
    new Float:vpos[3];
    GetVehiclePos(vehicleid, vpos[0], vpos[1], vpos[2]);
    return GetPlayerDistanceFromPoint(playerid, vpos[0], vpos[1], vpos[2]);
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
	    case ManSalughter: str = "Man Salughter";
	    case Sweet_Tooth: str = "Sweet Tooth";
	}
	return str;
}

// 1 per player (dynamic)
new Text:Subtitle[MAX_PLAYERS] = {Text:INVALID_TEXT_DRAW,...}; // Holds the current player's subtitle textdraw.
                                                         // SubtitleTimer PVar holds the timer ID.
stock ShowSubtitle(playerid, text[], time = 5000, override = 1)
{
    if(time < 1 || !IsPlayerConnected(playerid)) return 0;

    if(Subtitle[playerid] != Text:INVALID_TEXT_DRAW)
    {
      	if(!override) return 0;
        else HideSubtitle(playerid); // Hide the current one.
    }

    new string[256];
    format(string, sizeof(string), "~w~%s", text);
  	Subtitle[playerid] = TextDrawCreate(375.000000, 360.000000, string);
    TextDrawAlignment(Subtitle[playerid], 2);
    TextDrawBackgroundColor(Subtitle[playerid], 255);
    TextDrawFont(Subtitle[playerid], 1);
    TextDrawLetterSize(Subtitle[playerid], 0.480000, 2.400000);
    TextDrawColor(Subtitle[playerid], -1);
    TextDrawSetOutline(Subtitle[playerid], 0);
    TextDrawSetProportional(Subtitle[playerid], 1);
    TextDrawSetShadow(Subtitle[playerid], 2);
    TextDrawUseBox(Subtitle[playerid], 1);
    TextDrawBoxColor(Subtitle[playerid], 572661504);
    TextDrawTextSize(Subtitle[playerid], 0.000000, 438.000000);

    TextDrawShowForPlayer(playerid, Subtitle[playerid]);

    SetPVarInt(playerid, "SubtitleTimer", SetTimerEx("HideSubtitle", time, 0, "i", playerid));

    if(Subtitle[playerid] != Text:INVALID_TEXT_DRAW) return 1;
    else return 0;
}

forward HideSubtitle(playerid);
public HideSubtitle(playerid)
{
    TextDrawHideForPlayer(playerid, Subtitle[playerid]);
    TextDrawDestroy(Subtitle[playerid]);
    Subtitle[playerid] = Text:INVALID_TEXT_DRAW;

    KillTimer(GetPVarInt(playerid, "SubtitleTimer"));
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

#if SAMP_03d == (true)

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if(!IsPlayerAdmin(playerid)) return 1;
    SetPlayerPosFindZ(playerid, fX, fY, fZ);
    return 1;
}

#endif

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
	format(rmstr, sizeof(rmstr), "{0694AC}Calypso: {FFFFFF}%s", RandomMSG[RandMsg]);
	SendClientMessageToAll(0xFFFFFFFF, rmstr);
	if(RandMsg == 4) SendClientMessageToAll(0xFFFFFFFF, "{0694AC}Calypso: {FFFFFF}overly-made up clown!");
	if(RandMsg == 5) SendClientMessageToAll(0xFFFFFFFF, "{0694AC}Calypso: {FFFFFF}This will be proven soon enough");
	return 1;
}

new LastAimingSyncTick;
forward Overlay();
public Overlay()
{
	new tick = GetTickCount();
	if(( tick - LastAimingSyncTick) > 450)
	{
		new Float:x, Float:y, Float:z, Float:health, Found_Vehicle = INVALID_VEHICLE_ID;
		foreach(Player, i)
		{
		    if(!IsPlayerInAnyVehicle(i)) continue;
		    foreach(Vehicles, v)
		    {
		        if(v == GetPlayerVehicleID(i)) continue;
		        if(!IsVehicleStreamedIn(v, i)) continue;
		        if(!GetVehiclePos(v, x, y, z)) continue;
		        if(!IsPlayerAimingAt(i, x, y, z, 35.0)) continue;
		        Found_Vehicle = v;
		        break;
		    }
		    if(Found_Vehicle == INVALID_VEHICLE_ID)
		    {
		        HideProgressBarForPlayer(i, pTextInfo[i][pAiming_Health_Bar]);
				TextDrawHideForPlayer(i, pTextInfo[i][AimingPlayer]);
		    }
		    else
		    {
			    T_GetVehicleHealth(Found_Vehicle, health);
		    	TextDrawSetString(pTextInfo[i][AimingPlayer], GetTwistedMetalName(GetVehicleModel(Found_Vehicle)));
		    	SetProgressBarValue(pTextInfo[i][pAiming_Health_Bar], health / GetTwistedMetalMaxHealth(Found_Vehicle) * 100.0);
				ShowProgressBarForPlayer(i, pTextInfo[i][pAiming_Health_Bar]);
				TextDrawShowForPlayer(i, pTextInfo[i][AimingPlayer]);
				Found_Vehicle = INVALID_VEHICLE_ID;
			}
		}
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
#define MAX_TWISTED_VEHICLES 13
new Class_Selection_IDS[14][Class_Selection_Info] =
{
	{400, "Dummy", 0, 0, 0},
	{Junkyard_Dog, "Junkyard Dog", 200, 3, 6},
	{Brimstone, "~w~Brimstone", 147, 1, 1},
	{Outlaw, "~b~~h~Out~r~~h~law", 266, 0, 1},
	{Reaper, "Mr.Grimm / Reaper", 28, 0, 3},
	{Roadkill, "~g~Roadkill", 162, 44, 44},
	{Thumper, "~p~Thumper", 0, 149, 1},
	{Spectre, "~b~~h~Spectre", 233, 7, 1},
	{Darkside, "Darkside", 298, 0, 0},
	{Shadow, "~p~Shadow", 0, 1, 1},
	{Meat_Wagon, "~r~~h~Meat Wagon", 219, 1, 3},//275 skin
	{Vermin, "~y~Vermin", 262, 6, 113},
	{ManSalughter, "~w~ManSalughter", 0, 1, 1},
	{Sweet_Tooth, "~p~~h~Sweet Tooth", 264, 1, 126}
};
#define C_S_IDS Class_Selection_IDS

#define SAMP_03e (false)

//new CarsUse[212];
//new PlayerCopyBegins[MAX_PLAYERS char];

//3790
public OnGameModeInit()
{
	printf("half: %f - full: %f", MPDistance(9.6999998092651, 6.8000001907349, 2.7000000476837, 8.3999996185303, 6.9000000953674, 2.7000000476837), MPDistance(11.10000038147, 6.9000000953674, 2.7000000476837, 8.3999996185303, 6.9000000953674, 2.7000000476837));
	SendRconCommand("loadfs Twisted_Pic");
	SendRconCommand("hostname Twisted Metal: SA-MP "#Server_Version" Alpha Testing");
	SendRconCommand("gamemodetext Vehicular Combat");
	SendRconCommand("weburl "#Server_Website"");
    new StartTick = GetTickCount();
	SetWorldTime(3);
	ManualVehicleEngineAndLights();
	EnableStuntBonusForAll(false);
	AddPlayerClass(0, TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE, 0, 0, 0,0 , 0, 0);

	SetTimer("Overlay", 210, true);
	SetTimer("SendRandomMsg", 175001, true);
	
	MapAndreas_Init(MAP_ANDREAS_MODE_MINIMAL);
	
	//Iter_Init(Streamed_Vehicles);
    OnMapBegin();
	new v = 1, p = 0, ms = 0, go = 0, objectid = 0;
	do
	{
	    Vehicle_Missileid[v] = 0;
	    Vehicle_Firing_Missile[v] = 0;
	    Vehicle_Environmental_Slot[v] = 0;
	    Vehicle_Using_Environmental[v] = 0;
	    Vehicle_Machine_Gun_Currentid[v] = 0;
        Vehicle_Machine_Gun_CurrentSlot[v] = 0;
        VehicleOffsetX[v] = 0.0;
 		VehicleOffsetY[v] = 0.0;
 		VehicleOffsetZ[v] = 0.0;
 		WasDamaged[v] = 0;
	 	Vehicle_Napalm[v] = INVALID_OBJECT_ID;
	 	Vehicle_Machine_Gunid[v] = 0;
	 	Machine_Gun_Firing_Timer[v] = -1;
	 	Vehicle_Missile_Special_Slot[v] = 0;
	 	for(ms = 0; ms < MAX_MISSILE_SLOTS; ms++)
	 	{
		 	Vehicle_Smoke[v][ms] = INVALID_OBJECT_ID;
		 	Vehicle_Missile[v][ms] = INVALID_OBJECT_ID;
		 	Vehicle_Missile_Light[v][ms] = INVALID_OBJECT_ID;
		 	Vehicle_Machine_Gun[v][ms] = INVALID_OBJECT_ID;
	 	}
	 	for(go = 0; go < 2; go++)
	 	{
	 		Vehicle_Machine_Gun_Object[v][go] = INVALID_OBJECT_ID;
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
		Napalm_Timer[p] = -1;
		Nitro_Bike_Object[p] = INVALID_OBJECT_ID;
		++p;
	}
	while (p < MAX_PLAYERS);
	
	//mysql_debug(true);
	//mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
	
	for(new i = 0; i < sizeof(HealthPickups); i++){
    	HealthPickups[i] = CreatePickupEx(1240, 14, HealthPickupCoords[i][0], HealthPickupCoords[i][1], HealthPickupCoords[i][2], -1, PICKUPTYPE_HEALTH, "{FF0000}Health");
	}
	for(new i = 0; i < sizeof(TurboPickups); i++){
    	TurboPickups[i] = CreatePickupEx(1010, 14, TurboPickupCoords[i][0], TurboPickupCoords[i][1], TurboPickupCoords[i][2], -1, PICKUPTYPE_TURBO, "{09FF00}Turbo");
	}
	for(new i = 0; i < sizeof(HomingPickups); i++){
    	HomingPickups[i] = CreatePickupEx(3786, 14, HomingPickupCoords[i][0], HomingPickupCoords[i][1], HomingPickupCoords[i][2], -1, PICKUPTYPE_HOMING_MISSILE, "{B51BE0}Homing Missile");
	}
	for(new i = 0; i < sizeof(FirePickups); i++){
    	FirePickups[i] = CreatePickupEx(3786, 14, FirePickupCoords[i][0], FirePickupCoords[i][1], FirePickupCoords[i][2], -1, PICKUPTYPE_FIRE_MISSILE, "{FF9500}Fire Missile");
	}
	for(new i = 0; i < sizeof(PowerPickups); i++){
    	PowerPickups[i] = CreatePickupEx(3786, 14, PowerPickupCoords[i][0], PowerPickupCoords[i][1], PowerPickupCoords[i][2], -1, PICKUPTYPE_POWER_MISSILE, "{FF0000}Power Missile");
	}
	for(new i = 0; i < sizeof(NapalmPickupCoords); i++){
    	NapalmPickups[i] = CreatePickupEx(3786, 14, NapalmPickupCoords[i][0], NapalmPickupCoords[i][1], NapalmPickupCoords[i][2], -1, PICKUPTYPE_NAPALM_MISSILE, "{FEBF10}Napalm Pickup");
	}
	for(new i = 0; i < sizeof(StalkerPickupCoords); i++){
    	StalkerPickups[i] = CreatePickupEx(3786, 14, StalkerPickupCoords[i][0], StalkerPickupCoords[i][1], StalkerPickupCoords[i][2], -1, PICKUPTYPE_STALKERS_MISSILE, "{0000FF}Stalker {09FF00}Missile");
	}
	for(new i = 0; i < sizeof(RicochetPickupCoords); i++){
    	RicochetPickups[i] = CreatePickupEx(3786, 14, RicochetPickupCoords[i][0], RicochetPickupCoords[i][1], RicochetPickupCoords[i][2], -1, PICKUPTYPE_RICOCHETS_MISSILE, "{0000FF}Ricochet {FFFFFF}Missile");
	}
	for(new i = 0; i < sizeof(ZoomyPickupCoords); i++){
    	ZoomyPickups[i] = CreatePickupEx(3786, 14, ZoomyPickupCoords[i][0], ZoomyPickupCoords[i][1], ZoomyPickupCoords[i][2], -1, PICKUPTYPE_ZOOMY_MISSILE, "{0000FF}Zoomy {FFFFFF}Missile");
	}
	for(new i = 0; i < sizeof(EnvironmentalPickupCoords); i++){
    	EnvironmentalPickups[i] = CreatePickupEx(3786, 14, EnvironmentalPickupCoords[i][0], EnvironmentalPickupCoords[i][1], EnvironmentalPickupCoords[i][2], -1, PICKUPTYPE_ENVIRONMENTALS, "{FAA2E5}Environmental");
	}
	for(new i = 0; i < sizeof(LightningPickupCoords); i++){
    	LightningPickups[i] = CreatePickupEx(3786, 14, LightningPickupCoords[i][0], LightningPickupCoords[i][1], LightningPickupCoords[i][2], -1, PICKUPTYPE_LIGHTNING, "{FFDD00}Lightning");
	}
	for(new i = 0; i < sizeof(MachineGunUpgradePickupCoords); i++){
    	MachineGunUpgradePickups[i] = CreatePickupEx(362, 14, MachineGunUpgradePickupCoords[i][0], MachineGunUpgradePickupCoords[i][1], MachineGunUpgradePickupCoords[i][2], -1, PICKUPTYPE_MACHINE_GUN_UPGRADE, "{C3FAC8}Machine Gun Upgrade");
	}
	for(new d = 0; d < sizeof(a_Downtown_Positions); d++)
	{
	    a_Downtown_Objects[d] = INVALID_OBJECT_ID;
	    a_Downtown_Objects[d] = CreateObject(a_Downtown_Positions[d][D_modelid], a_Downtown_Positions[d][D_X], a_Downtown_Positions[d][D_Y], a_Downtown_Positions[d][D_Z], a_Downtown_Positions[d][DR_X], a_Downtown_Positions[d][DR_Y], a_Downtown_Positions[d][DR_Z], a_Downtown_Positions[d][DR_DrawDistance]);
	}
	Players_Online_Textdraw = TextDrawCreate(41.000000, 316.000000, "01");
	TextDrawBackgroundColor(Players_Online_Textdraw, 255);
	TextDrawFont(Players_Online_Textdraw, 1);
	TextDrawLetterSize(Players_Online_Textdraw, 0.330000, 1.500000);
	TextDrawColor(Players_Online_Textdraw, -1);
	TextDrawSetOutline(Players_Online_Textdraw, 0);
	TextDrawSetProportional(Players_Online_Textdraw, 1);
	TextDrawSetShadow(Players_Online_Textdraw, 0);
	TextDrawUseBox(Players_Online_Textdraw, 1);
	TextDrawBoxColor(Players_Online_Textdraw, 150);
	TextDrawTextSize(Players_Online_Textdraw, 56.000000, 0.000000);

	SpawnTD = TextDrawCreate(237.000000, 360.000000, "Press ~k~~PED_SPRINT~ To Select A Character");
	TextDrawBackgroundColor(SpawnTD, 255);
	TextDrawFont(SpawnTD, 1);
	TextDrawLetterSize(SpawnTD, 0.380000, 1.000000);
	TextDrawColor(SpawnTD, -1);
	TextDrawSetOutline(SpawnTD, 0);
	TextDrawSetProportional(SpawnTD, 1);
	TextDrawSetShadow(SpawnTD, 1);
	
	for(new x = 0; x != MAX_TWISTED_VEHICLES; x++)
	{
		new id = AddStaticVehicle(C_S_IDS[x][CS_VehicleModelID], 0.0 + x, 0.0 + x, 0.0 + x, 0.0, 0, 0);
		DestroyVehicle(id);
	}
	printf("[System] Gamemode Loaded In: %d ms - Tickcount: %d", (GetTickCount() - StartTick), tickcount());
	return 1;
}

public OnGameModeExit()
{
	//mysql_close();
	//ModelSocketClose();
	MapAndreas_Unload();
	SendRconCommand("unloadfs Twisted_Pic");
	//DestroyAllDynamicObjects();
	Iter_Clear(Vehicles);
	foreach(Player, i)//do
	{
	    KillTimer(Napalm_Timer[i]);
	    for(new s = 0; s != MAX_MISSILE_SLOTS; s++) {
	        KillTimer(Update_Missile_Timer[i][s]);
	    }
	    for(new s = 0; s != MAX_MACHINE_GUN_SLOTS; s++) {
	        KillTimer(Update_Machine_Gun_Timer[i][s]);
	    }
		KillTimer(Update_Remote_Bomb_Timer[i]);
    	KillTimer(PlayerInfo[i][Turbo_Timer]);
    	KillTimer(Machine_Gun_Firing_Timer[i]);
		for(new st = 0; st < sizeof(StatusTextPositions); st++)
	    {
			KillTimer(pStatusInfo[i][StatusTextTimer][st]);
		}
		KillTimer(GetPVarInt(i, "Flash_Roadkill_Timer"));
		TextDrawHideForPlayer(i, pTextInfo[i][pBox]);
		TextDrawHideForPlayer(i, pTextInfo[i][pUpArrow]);
		TextDrawHideForPlayer(i, pTextInfo[i][pLeftArrow]);
		TextDrawHideForPlayer(i, pTextInfo[i][pRightArrow]);
		TextDrawHideForPlayer(i, pTextInfo[i][pHealthSign]);
		TextDrawHideForPlayer(i, pTextInfo[i][pHealthBar]);
		TextDrawHideForPlayer(i, pTextInfo[i][pBoxSeparater]);
		TextDrawHideForPlayer(i, pTextInfo[i][pSecondBox]);
		TextDrawHideForPlayer(i, pTextInfo[i][pEnergySign]);
		TextDrawHideForPlayer(i, pTextInfo[i][pTurboSign]);
		TextDrawDestroy(pTextInfo[i][pBox]);
		TextDrawDestroy(pTextInfo[i][pUpArrow]);
		TextDrawDestroy(pTextInfo[i][pLeftArrow]);
        TextDrawDestroy(pTextInfo[i][pRightArrow]);
		TextDrawDestroy(pTextInfo[i][pHealthSign]);
		TextDrawDestroy(pTextInfo[i][pHealthBar]);
		TextDrawDestroy(pTextInfo[i][pBoxSeparater]);
		TextDrawDestroy(pTextInfo[i][pSecondBox]);
		TextDrawDestroy(pTextInfo[i][pEnergySign]);
		TextDrawDestroy(pTextInfo[i][pTurboSign]);
		for(new m = 0; m < (MAX_MISSILEID); m++) {
		    TextDrawHideForPlayer(i, pTextInfo[i][pMissileSign][m]);
			TextDrawDestroy(pTextInfo[i][pMissileSign][m]);
		}
		DestroyProgressBar(pTextInfo[i][pTurboBar]);
		DestroyProgressBar(pTextInfo[i][pEnergyBar]);
		DestroyProgressBar(pTextInfo[i][pEnergyBar]);
		for(new t = 0; t != 15; t++)
		{
			TextDrawDestroy(pTextInfo[i][TDSpeedClock][t]);
		}
	 	i ++;
	}
	TextDrawHideForAll(Players_Online_Textdraw);
	TextDrawDestroy(Players_Online_Textdraw);
	for(new i = 0; i < MAX_PICKUPS; i++)
	{
 		if(PickupInfo[i][PickupX] == 0.0) continue;
		DestroyPickup(PickupInfo[i][Pickupid]);
	}
	new i = 0;
	do
	{
	    KillTimer(i);
	    i++;
	}
	while (i != 1000);
	KillTimer( -1 );
	printf("Twisted Metal Exited Succesfully");
	return 1;
}

/*public OnStartCopyFiles(playerid)
{
	SendClientMessage(playerid, 0xFF0000, "[System] - Begining to Download Twisted metal Cars");
	printf("[System] - OnStartCopyFiles: %d", playerid);
	PlayerCopyBegins{playerid} = 1;
	return 1;
}

public OnFileTransfer(playerid)
{
	if(PlayerCopyBegins{playerid}) SendClientMessage(playerid, 0xFF000000, "[System] - Finished Downloading Twisted Metal Cars");
	printf("[System] - OnFileTransfer: %d", playerid);
	PlayerCopyBegins{playerid} = 0;
	for(new j = 0; j < 212 ; j++)
	{
		if(CarsUse[j])
		{
			PlayerReplaceCar(playerid, (j + 400));
			printf("[System] - Car Replaced: playerid: %d modelid: %d", playerid, (j + 400));
		}
	}
	return 1;
}*/

public OnPlayerDisconnect(playerid, reason)
{
    //ModelPlayerDisconnect(playerid);
    KillTimer(Napalm_Timer[playerid]);
	for(new s = 0; s != MAX_MISSILE_SLOTS; s++) {
        KillTimer(Update_Missile_Timer[playerid][s]);
        if(IsValidObject(Vehicle_Missile[playerid][s])) DestroyObject(Vehicle_Missile[playerid][s]);
		if(IsValidObject(Vehicle_Smoke[playerid][s])) DestroyObject(Vehicle_Smoke[playerid][s]);
    }
    for(new s = 0; s != MAX_MACHINE_GUN_SLOTS; s++) {
        KillTimer(Update_Machine_Gun_Timer[playerid][s]);
    }
    KillTimer(Update_Remote_Bomb_Timer[playerid]);
    KillTimer(LoggedTimer[playerid]);
    KillTimer(PlayerInfo[playerid][Turbo_Timer]);
    KillTimer(Machine_Gun_Firing_Timer[playerid]);
    for(new st = 0; st < sizeof(StatusTextPositions); st++)
    {
		KillTimer(pStatusInfo[playerid][StatusTextTimer][st]);
	}
	KillTimer(GetPVarInt(playerid, "Flash_Roadkill_Timer"));
	KillTimer(PlayerInfo[playerid][EnvironmentalCycle_Timer]);
	PlayerInfo[playerid][pMissile_Special_Charged] = false;
	TextDrawHideForPlayer(playerid, Players_Online_Textdraw);
	Vehicle_Missile_Special_Slot[Current_Vehicle[playerid]] = 0;
    DestroyVehicle(Current_Vehicle[playerid]);
    if(IsValidObject(PlayerInfo[playerid][pSpecialObject])) DestroyObject(PlayerInfo[playerid][pSpecialObject]);
    new string[90];
    switch(reason)
    {
        case 0: format(string, sizeof(string), "%s(%d) Has Left The Server - (Timeout / Crash)", Playername(playerid),playerid);
        case 1: format(string, sizeof(string), "%s(%d) Has Left The Server - (Leaving/Quit)", Playername(playerid),playerid);
        case 2: format(string, sizeof(string), "%s(%d) Has Left The Server - (Kicked/Banned)", Playername(playerid),playerid);
    }
    if(!IsPlayerNPC(playerid)) SendClientMessageToAll(system, string);
	return 1;
}

#if SAMP_03d == (true)
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
#endif

#define MAX_CONNECT_IN_ROW 2
#define MAX_REJOIN_TIME 5000
new ipCheck[17], IPfound, IPtime;

stock Flood_Control(playerid)
{
    new apIP[17];
    GetPlayerIp(playerid, apIP, 17);
    if( strcmp(ipCheck, apIP, false) == 0 && ( GetTickCount() - IPtime ) < MAX_REJOIN_TIME )
    {
        IPfound++;
        if(IPfound > MAX_CONNECT_IN_ROW)
        {
            GameTextForPlayer(playerid, "~HAX#",1000,3);
		    GameTextForPlayer(playerid, "~DIE*** ~HAHA", 1000, 3);
		    GameTextForPlayer(playerid, "SUCKER! ~xD", 1000, 3);
            Kick(playerid);//"Connection Flood"
            IPfound = 0;
        }
    }
    else
    {
        IPfound = 0;
    }
    format(ipCheck, 17, "%s", apIP);
    IPtime = GetTickCount();
    return true;
}

public OnPlayerConnect(playerid)
{
    if(IsPlayerNPC(playerid))
	{
	    new ip[17];
	    GetPlayerIp(playerid, ip, sizeof(ip));
	    printf("[System: NPC] - Illegal NPC Connecting From %s", ip);
	    Kick(playerid);
	    return 1;
	}
	Flood_Control(playerid);
    SendClientMessage(playerid, ANNOUNCEMENT, "{FF0000}Warning: {a9c4e4}The Concept In This Server And GTA In General May Be Considered Explicit Material.");
    SendClientMessage(playerid, ANNOUNCEMENT, "{FF0000}Concept: {a9c4e4}Twisted Metal: SA-MP is a demolition derby that permits the usage of ballistic projectiles..");
	new str[64];
	format(str, sizeof(str), "%s(%d) Has Joined The Server.", Playername(playerid), playerid);
	SendClientMessageToAll(LIGHTGREY, str);
	if(Iter_Count(Player) < 10)
	{
		format(str, sizeof(str), "0%d", Iter_Count(Player));
	}
	else format(str, sizeof(str), "%d", Iter_Count(Player));
	TextDrawSetString(Players_Online_Textdraw, str);
	
	Muted[playerid] = 0;
	IsLogged[playerid] = 0;
	//DeActiveSpeedometer{playerid} = 0;
	PlayerInfo[playerid][pSpawned] = 0;
	ResetPlayerVars(playerid);
	ResetTwistedVars(playerid);
	new i = playerid;
   	pTextInfo[i][AimingPlayer] = TextDrawCreate(102.000000, 314.000000, "Vermin");
	TextDrawAlignment(pTextInfo[i][AimingPlayer], 2);
	TextDrawBackgroundColor(pTextInfo[i][AimingPlayer], 255);
	TextDrawFont(pTextInfo[i][AimingPlayer], 1);
	TextDrawLetterSize(pTextInfo[i][AimingPlayer], 0.310000, 1.000000);
	TextDrawColor(pTextInfo[i][AimingPlayer], -1);
	TextDrawSetOutline(pTextInfo[i][AimingPlayer], 0);
	TextDrawSetProportional(pTextInfo[i][AimingPlayer], 1);
	TextDrawSetShadow(pTextInfo[i][AimingPlayer], 1);

	pTextInfo[i][AimingBox] = TextDrawCreate(153.000000, 316.000000, "_");
	TextDrawBackgroundColor(pTextInfo[i][AimingBox], 255);
	TextDrawFont(pTextInfo[i][AimingBox], 1);
	TextDrawLetterSize(pTextInfo[i][AimingBox], 1.130000, 1.500000);
	TextDrawColor(pTextInfo[i][AimingBox], -1);
	TextDrawSetOutline(pTextInfo[i][AimingBox], 0);
	TextDrawSetProportional(pTextInfo[i][AimingBox], 1);
	TextDrawSetShadow(pTextInfo[i][AimingBox], 1);
	TextDrawUseBox(pTextInfo[i][AimingBox], 1);
	TextDrawBoxColor(pTextInfo[i][AimingBox], 150);
	TextDrawTextSize(pTextInfo[i][AimingBox], 56.000000, 1.000000);
	
	for(new st = 0; st < sizeof(StatusTextPositions); st++)
	{
		pStatusInfo[i][StatusText][st] = TextDrawCreate(StatusTextPositions[st][0], StatusTextPositions[st][1], "INCOMING");
		TextDrawAlignment(pStatusInfo[i][StatusText][st], 2);
		TextDrawBackgroundColor(pStatusInfo[i][StatusText][st], 255);
		TextDrawFont(pStatusInfo[i][StatusText][st], 1);
		TextDrawLetterSize(pStatusInfo[i][StatusText][st], StatusTextLetterSize[st][0], StatusTextLetterSize[st][1]);
		TextDrawColor(pStatusInfo[i][StatusText][st], TM_STATUS_COLOUR1);
		TextDrawSetOutline(pStatusInfo[i][StatusText][st], 1);
		TextDrawSetProportional(pStatusInfo[i][StatusText][st], 1);
	}

	pTextInfo[i][pBox] = TextDrawCreate(627.000000, 346.000000, "   ");
	TextDrawBackgroundColor(pTextInfo[i][pBox], 255);
	TextDrawFont(pTextInfo[i][pBox], 0);
	TextDrawLetterSize(pTextInfo[i][pBox], 0.000000, 3.700000);
	TextDrawColor(pTextInfo[i][pBox], -1);
	TextDrawSetOutline(pTextInfo[i][pBox], 0);
	TextDrawSetProportional(pTextInfo[i][pBox], 1);
	TextDrawSetShadow(pTextInfo[i][pBox], 1);
	TextDrawUseBox(pTextInfo[i][pBox], 1);
	TextDrawBoxColor(pTextInfo[i][pBox], 100);
	TextDrawTextSize(pTextInfo[i][pBox], 509.000000, 1.000000);
	
	pTextInfo[i][pUpArrow] = TextDrawCreate(610.000000 - 15, 325.000000 - 15, "ld_beat:up");
	TextDrawFont(pTextInfo[i][pUpArrow], 4);
    TextDrawColor(pTextInfo[i][pUpArrow], 0x0097FCFF);
    TextDrawTextSize(pTextInfo[i][pUpArrow], 16.0, 16.0);
    
    pTextInfo[i][pLeftArrow] = TextDrawCreate(610.000000 - 30, 325.000000, "ld_beat:left");
	TextDrawFont(pTextInfo[i][pLeftArrow], 4);
    TextDrawColor(pTextInfo[i][pLeftArrow], 0x0097FCFF);
    TextDrawTextSize(pTextInfo[i][pLeftArrow], 16.0, 16.0);

	pTextInfo[i][pRightArrow] = TextDrawCreate(610.000000, 325.000000, "ld_beat:right");
	TextDrawFont(pTextInfo[i][pRightArrow], 4);
    TextDrawColor(pTextInfo[i][pRightArrow], 0x0097FCFF);
    TextDrawTextSize(pTextInfo[i][pRightArrow], 16.0, 16.0);

	pTextInfo[i][pHealthSign] = TextDrawCreate(610.000000, 347.000000, "+");
	TextDrawBackgroundColor(pTextInfo[i][pHealthSign], 255);
	TextDrawFont(pTextInfo[i][pHealthSign], 1);
	TextDrawLetterSize(pTextInfo[i][pHealthSign], 0.500000, 1.700000);
	TextDrawColor(pTextInfo[i][pHealthSign], -1);
	TextDrawSetOutline(pTextInfo[i][pHealthSign], 0);
	TextDrawSetProportional(pTextInfo[i][pHealthSign], 1);
	TextDrawSetShadow(pTextInfo[i][pHealthSign], 1);

	pTextInfo[i][pHealthBar] = TextDrawCreate(627.000000, 418.000000, "  ");
	TextDrawBackgroundColor(pTextInfo[i][pHealthBar], 65535);
	TextDrawFont(pTextInfo[i][pHealthBar], 1);
	TextDrawLetterSize(pTextInfo[i][pHealthBar], 0.000000, -8.600000);
	TextDrawColor(pTextInfo[i][pHealthBar], 16711935);
	TextDrawSetOutline(pTextInfo[i][pHealthBar], 1);
	TextDrawSetProportional(pTextInfo[i][pHealthBar], 1);
	TextDrawUseBox(pTextInfo[i][pHealthBar], 1);
	TextDrawBoxColor(pTextInfo[i][pHealthBar], 16384150);
	TextDrawTextSize(pTextInfo[i][pHealthBar], 598.000000, 0.000000);

	pTextInfo[i][pBoxSeparater] = TextDrawCreate(516.000000, 418.000000, "   ");
	TextDrawBackgroundColor(pTextInfo[i][pBoxSeparater], 255);
	TextDrawFont(pTextInfo[i][pBoxSeparater], 1);
	TextDrawLetterSize(pTextInfo[i][pBoxSeparater], 0.000000, 0.000000);
	TextDrawColor(pTextInfo[i][pBoxSeparater], -1);
	TextDrawSetOutline(pTextInfo[i][pBoxSeparater], 0);
	TextDrawSetProportional(pTextInfo[i][pBoxSeparater], 1);
	TextDrawSetShadow(pTextInfo[i][pBoxSeparater], 1);
	TextDrawUseBox(pTextInfo[i][pBoxSeparater], 1);
	TextDrawBoxColor(pTextInfo[i][pBoxSeparater], 421075400);
	TextDrawTextSize(pTextInfo[i][pBoxSeparater], 621.000000, 1.000000);

	pTextInfo[i][pSecondBox] = TextDrawCreate(628.000000, 420.000000, "  ");
	TextDrawBackgroundColor(pTextInfo[i][pSecondBox], 255);
	TextDrawFont(pTextInfo[i][pSecondBox], 1);
	TextDrawLetterSize(pTextInfo[i][pSecondBox], 0.479999, 1.700000);
	TextDrawColor(pTextInfo[i][pSecondBox], -1);
	TextDrawSetOutline(pTextInfo[i][pSecondBox], 0);
	TextDrawSetProportional(pTextInfo[i][pSecondBox], 1);
	TextDrawSetShadow(pTextInfo[i][pSecondBox], 1);
	TextDrawUseBox(pTextInfo[i][pSecondBox], 1);
	TextDrawBoxColor(pTextInfo[i][pSecondBox], 150);
	TextDrawTextSize(pTextInfo[i][pSecondBox], 509.000000, 0.000000);

	pTextInfo[i][pEnergySign] = TextDrawCreate(515.000000, 418.000000, "E");
	TextDrawBackgroundColor(pTextInfo[i][pEnergySign], 255);
	TextDrawFont(pTextInfo[i][pEnergySign], 1);
	TextDrawLetterSize(pTextInfo[i][pEnergySign], 0.500000, 1.000000);
	TextDrawColor(pTextInfo[i][pEnergySign], -1);
	TextDrawSetOutline(pTextInfo[i][pEnergySign], 0);
	TextDrawSetProportional(pTextInfo[i][pEnergySign], 1);
	TextDrawSetShadow(pTextInfo[i][pEnergySign], 1);

	pTextInfo[playerid][pTurboSign] = TextDrawCreate(515.000000, 427.000000, "T");
	TextDrawBackgroundColor(pTextInfo[playerid][pTurboSign], 255);
	TextDrawFont(pTextInfo[playerid][pTurboSign], 1);
	TextDrawLetterSize(pTextInfo[playerid][pTurboSign], 0.500000, 1.000000);
	TextDrawColor(pTextInfo[playerid][pTurboSign], -1);
	TextDrawSetOutline(pTextInfo[playerid][pTurboSign], 0);
	TextDrawSetProportional(pTextInfo[playerid][pTurboSign], 1);
	TextDrawSetShadow(pTextInfo[playerid][pTurboSign], 1);
    for(new m = 0; m < (MAX_MISSILEID); m++) {
    	pTextInfo[i][pMissileSign][m] = TextDrawCreate(516.000000, 345.000000 + (m != 0 ? (m + (13 * m) / 2) : 0), "Missiles");
		TextDrawBackgroundColor(pTextInfo[playerid][pMissileSign][m], 255);
		TextDrawFont(pTextInfo[playerid][pMissileSign][m], 1);
		TextDrawLetterSize(pTextInfo[playerid][pMissileSign][m], 0.260000, 0.879998);
		TextDrawColor(pTextInfo[playerid][pMissileSign][m], 16711935);
		TextDrawSetOutline(pTextInfo[playerid][pMissileSign][m], 0);
		TextDrawSetProportional(pTextInfo[playerid][pMissileSign][m], 1);
		TextDrawSetShadow(pTextInfo[playerid][pMissileSign][m], 1);

		format(str, 32, "%d %s", PlayerInfo[playerid][pMissiles][m], GetTwistedMissileName(m, m));
		TextDrawSetString(pTextInfo[playerid][pMissileSign][m], str);
	}
	pTextInfo[playerid][pTurboBar] = CreateProgressBar(532.00, 430.00, 87.50, 3.20, -5046017, MAX_TURBO); //922812415
	pTextInfo[playerid][pEnergyBar] = CreateProgressBar(532.00, 420.00, 87.50, 3.20, 0x0097FCFF, 100.0);
    pTextInfo[playerid][pAiming_Health_Bar] = CreateProgressBar(75.00, 325.00, 53.50, 2.50, 16711850, 100.0);

	SetProgressBarValue(pTextInfo[playerid][pTurboBar], MAX_TURBO);
	SetProgressBarValue(pTextInfo[playerid][pEnergyBar], 100.0);
	SetProgressBarValue(pTextInfo[playerid][pAiming_Health_Bar], 0.0);

	PlayerInfo[playerid][pTurbo] = floatround(MAX_TURBO);
	PlayerInfo[playerid][pEnergy] = 100;
	PlayerInfo[playerid][pSelection] = 0;
	#if SAMP_03d == (true)
	RemoveDowntownMisc(playerid);
	#endif
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid)) return 1;
	PlayerInfo[playerid][pSelection] = 0;
	SetTimerEx("SpawnPlayerEx", 75, false, "i", playerid);
	new Preloading[3] = {INVALID_OBJECT_ID,...};//preload objects
    Preloading[0] = CreatePlayerObject(playerid, Machine_Gun, 				TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
    Preloading[1] = CreatePlayerObject(playerid, Missile_Default_Object, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
    Preloading[2] = CreatePlayerObject(playerid, Missile_Napalm_Object, 	TM_SELECTION_X, TM_SELECTION_Y + 5, TM_SELECTION_Z, 0.0, 0.0, 0.0, 300.0);
    SetTimerEx("FinishPreloading", 2000, false, "iiii", playerid, Preloading[0], Preloading[1], Preloading[2]);
	return 1;
}
forward SpawnPlayerEx(playerid);
public SpawnPlayerEx(playerid)
{
    SetSpawnInfo(playerid, 0, 0, TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, 0, 0, 0, 0, 0, 0, 0);
    SpawnPlayer(playerid);
	return 1;
}
forward FinishPreloading(playerid, pobject1, pobject2, pobject3);
public FinishPreloading(playerid, pobject1, pobject2, pobject3)
{
    if(IsValidPlayerObject(playerid, pobject1))
	{
    	DestroyPlayerObject(playerid, pobject1);
    }
    if(IsValidPlayerObject(playerid, pobject2))
	{
    	DestroyPlayerObject(playerid, pobject2);
    }
    if(IsValidPlayerObject(playerid, pobject3))
	{
    	DestroyPlayerObject(playerid, pobject3);
    }
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

public OnPlayerSpawn(playerid)
{
    if(IsPlayerNPC(playerid))
  	{
	    new npcname[MAX_PLAYER_NAME];
	    GetPlayerName(playerid, npcname, sizeof(npcname));
	    /*for(new i = 0; i != MAX_PLAYERS; i++)
	    {
	        if(i == playerid) continue;
	        SetPlayerMarkerForPlayer( i, playerid, 0xFFFFFF00 );
	    }*/
		if(!strcmp(npcname, "[BOT]HelicopterAttack", true))
		{
		    //PutPlayerInVehicle(playerid, HelicopterAttack_Vehicle, 0);
		    SetPlayerVirtualWorld(playerid, 0);
		    SetPlayerInterior(playerid, 0);
		    Attach3DTextLabelToPlayer(BotName[0], playerid, 0.0, 0.0, 0.0);
		    print("[BOT]HelicopterAttack Successfully Spawned");
		}
		return 1;
	}
	if(2001 <= PlayerInfo[playerid][pSpecial_Missile_Vehicle] <= 4000)
	{
		PlayerInfo[playerid][pSpecial_Missile_Vehicle] -= 2000;
	    CallLocalFunction("OnPlayerVehicleHealthChange", "iiff", playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle], 900.0, 1000.0);
	    SetTimerEx("Reset_SMV", 100, false, "i", playerid);
	    return 1;
	}
	if(PlayerInfo[playerid][pSelection] == 0)
	{
	    PlayerInfo[playerid][pSelection] = 1;
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, playerid);
	    new Float:x, Float:y, Float:z, Float:a;
	    GetPlayerPos(playerid, x, y, z);
	    GetPlayerFacingAngle(playerid, a);
	    PlayerInfo[playerid][pCarModel] = 525;
	    Current_Vehicle[playerid] = CreateVehicle(525, TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE, 3, 6, 0);
		GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~<~ Junkyard Dog ~>~", 8500, 3);
		PlayerInfo[playerid][pSkin] = 200;
		SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
		SetVehicleVirtualWorld(Current_Vehicle[playerid], playerid);
		PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
	   	SetPlayerCameraPos(playerid, TM_SELECTION_CAMERA_X, TM_SELECTION_CAMERA_Y, TM_SELECTION_CAMERA_Z);
		SetPlayerCameraLookAt(playerid, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z);
		TogglePlayerControllable(playerid, false);
		TDS(playerid);
		Current_Car_Index[playerid] = 1;
		Vehicle_Missileid[Current_Vehicle[playerid]] = 0;
		PlayerInfo[playerid][pTurbo] = floatround(MAX_TURBO);
		PlayerInfo[playerid][pEnergy] = 100;
		TextDrawShowForPlayer(playerid, pTextInfo[playerid][AimingBox]);
		TextDrawShowForPlayer(playerid, Players_Online_Textdraw);
		return 1;
	}
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
    if(GetPVarInt(playerid, "Add_Vermin") == 1 && PlayerInfo[playerid][pSpecial_Missile_Vehicle] != 0)
	{
	    PlayerInfo[playerid][pSpecial_Missile_Vehicle] += 2000;
	    DeletePVar(playerid, "Add_Vermin");
	    return 1;
	}
	printf("[SAMP: OnPlayerDeath] - playerid: %d - killerid: %d - reason: %d", playerid, killerid, reason);
	ClearAnimations(playerid);
	SetPlayerWorldBounds(playerid, 20000.0, -20000.0, 20000.0, -20000.0);
	SendDeathMessage(killerid, playerid, reason);
    PlayerInfo[playerid][pSpawned] = 0;
    #if SAMP_03d == (true)
	new bool:gender = true;
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
    foreach(Player, i)
    {
        if(!IsPlayerInRangeOfPoint(i, 30.0, x, y, z)) continue;
 		PlayAudioStreamForPlayer(playerid, gender == false ? ("http://lvcnr.net/twisted_metal/DEATH_AI_F.wav")
 		: ("http://lvcnr.net/twisted_metal/DEATH_AI_M.wav"), x, y, z, 30.0, 1);
	}
	#endif
	RemovePlayerAttachedObject(playerid, 0);
	RemovePlayerFromVehicle(playerid);
	Vehicle_Firing_Missile[Current_Vehicle[playerid]] = 0;
	Vehicle_Environmental_Slot[Current_Vehicle[playerid]] = 0;
	Vehicle_Using_Environmental[Current_Vehicle[playerid]] = 0;
	DestroyVehicle(Current_Vehicle[playerid]);
	if(GetVehicleComponentInSlot(Current_Vehicle[playerid], CARMODTYPE_NITRO))
	{
		RemoveVehicleComponent(Current_Vehicle[playerid], GetVehicleComponentInSlot(Current_Vehicle[playerid], CARMODTYPE_NITRO));
	}
	if(IsValidObject(Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][0]))
	{
		DestroyObject(Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][0]);
	}
	if(IsValidObject(Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][1]))
	{
		DestroyObject(Vehicle_Machine_Gun_Object[Current_Vehicle[playerid]][1]);
	}
	ResetTwistedVars(playerid);
	TextDrawHideForPlayer(playerid, pTextInfo[playerid][AimingBox]);
	TextDrawHideForPlayer(playerid, Players_Online_Textdraw);
    /*foreach (Streamed_Vehicles[playerid], i)
	{
	    new last;
	    Iter_SafeRemove(Streamed_Vehicles[playerid], i, last);
	    i = last;
	}*/
	return 1;
}

stock ResetPlayerVars(playerid)
{
    PlayerInfo[playerid][pDonaterRank] = 0;
    PlayerInfo[playerid][Money] = 0;
    PlayerInfo[playerid][Score] = 0;
    PlayerInfo[playerid][Kills] = 0;
    PlayerInfo[playerid][Deaths] = 0;
    PlayerInfo[playerid][AdminLevel] = 0;
    PlayerInfo[playerid][pRegular] = 0;
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
 		++pm;
 	}
    PlayerInfo[playerid][pTurbo] = 0;
    PlayerInfo[playerid][pEnergy] = 0;
    PlayerInfo[playerid][pSpawned] = 0;
    PlayerInfo[playerid][pSelection] = 0;
    PlayerInfo[playerid][Turbo_Tick] = 0;
    PlayerInfo[playerid][pBurnout] = 0;
    PlayerInfo[playerid][pGender] = true;
    PlayerInfo[playerid][pLastVeh] = INVALID_VEHICLE_ID;
    PlayerInfo[playerid][pMissile_Special_Time] = 0;
    PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
    PlayerInfo[playerid][pMissile_Special_Charged] = false;
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
    	PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
    	DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
    }
    if(IsValidObject(PlayerInfo[playerid][pSpecialObject]))
	{
		DestroyObject(PlayerInfo[playerid][pSpecialObject]);
	}
    PlayerInfo[playerid][pSpecial_Missile_Vehicle] = 0;
    KillTimer(PlayerInfo[playerid][Turbo_Timer]);
    KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
    KillTimer(Update_Remote_Bomb_Timer[playerid]);
    KillTimer(Machine_Gun_Firing_Timer[playerid]);
	KillTimer(GetPVarInt(playerid, "Flash_Roadkill_Timer"));
	KillTimer(PlayerInfo[playerid][EnvironmentalCycle_Timer]);
    if(IsValidObject(Nitro_Bike_Object[playerid]))
	{
		DestroyObject(Nitro_Bike_Object[playerid]);
	}
    for(new s = 0; s != MAX_MISSILE_SLOTS; s++) {
        KillTimer(Update_Missile_Timer[playerid][s]);
        if(IsValidObject(Vehicle_Missile[playerid][s])) DestroyObject(Vehicle_Missile[playerid][s]);
        if(IsValidObject(Vehicle_Missile_Light[playerid][s])) DestroyObject(Vehicle_Missile_Light[playerid][s]);
		if(IsValidObject(Vehicle_Smoke[playerid][s])) DestroyObject(Vehicle_Smoke[playerid][s]);
    }
    for(new s = 0; s != MAX_MACHINE_GUN_SLOTS; s++) {
        KillTimer(Update_Machine_Gun_Timer[playerid][s]);
    }
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
    if(GetPVarInt(playerid, "Jumped_Index") >= 2)
    {
    	if(GetPVarInt(playerid, "Jumped_Recently") >= gettime()) return 1;
    	SetPVarInt(playerid, "Jumped_Index", 0);
    }
	new Float:x, Float:y, Float:z;
	GetVehicleVelocity(GetPlayerVehicleID(playerid), x, y, z);
	SetVehicleVelocity(GetPlayerVehicleID(playerid), x, y, z + 0.2);
	SetPVarInt(playerid, "Jumped_Recently", gettime() + 4);
	SetPVarInt(playerid, "Jumped_Index", GetPVarInt(playerid, "Jumped_Index") + 1);
	return 1;
}

CMD:invisibility(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(PlayerInfo[playerid][pEnergy] < 25) return SendClientMessageFormatted(playerid, RED, "Error: 25 Energy or more needed to use this command - Energy Left: %d", PlayerInfo[playerid][pEnergy]);
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return SendClientMessage(playerid, RED, "Error: you are already in Invisibility mode");
	PlayerInfo[playerid][pEnergy] -= 25;
	SetProgressBarValue(pTextInfo[playerid][pEnergyBar], float(PlayerInfo[playerid][pEnergy]));
	UpdateProgressBar(pTextInfo[playerid][pEnergyBar], playerid);
	LinkVehicleToInterior(GetPlayerVehicleID(playerid), INVISIBILITY_INDEX);
	SetTimerEx("Reset_Invisibility", 7000, false, "i", GetPlayerVehicleID(playerid));
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

CMD:remotebomb(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(PlayerInfo[playerid][pEnergy] < 25) return SendClientMessageFormatted(playerid, RED, "Error: you don't have enough energy to use this command - Energy Left: %d", PlayerInfo[playerid][pEnergy]);
	new id = GetPlayerVehicleID(playerid), Float:x, Float:y, Float:z, Float:a;
	if(IsValidObject(Vehicle_Napalm[id]))
	{
	 	DestroyObject(Vehicle_Napalm[id]);
	}
  	GetVehiclePos(id, x, y, z);
   	GetVehicleZAngle(id, a);
   	//GetPointZPos(x, y, z);
   	z -= 0.1;
	Vehicle_Napalm[id] = CreateObject(1222, x, y, z, 0, 90.0, a + 180, 300.0);
	Update_Remote_Bomb_Timer[playerid] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Napalm[id], Missile_RemoteBomb, 0, INVALID_VEHICLE_ID);
	Napalm_Timer[playerid] = SetTimerEx("Explode_Missile", 15000, false, "ddd", id, 0, Missile_RemoteBomb);
	return 1;
}

public OnUnoccupiedVehicleUpdate(vehicleid, playerid, passenger_seat)
{
	new Float: fVehicle[3];
	GetVehiclePos(vehicleid, fVehicle[0], fVehicle[1], fVehicle[2]);
	if(IsPlayerInAnyVehicle(playerid))
	{
		if(GetVehicleDistanceFromPoint(GetPlayerVehicleID(playerid), fVehicle[0], fVehicle[1], fVehicle[2]) < 5.0)
		{
			CallLocalFunction("OnVehicleHitUnoccupiedVehicle", "iii", playerid, GetPlayerVehicleID(playerid), vehicleid);
		}
	}
	else CallLocalFunction("OnPlayerHitUnoccupiedVehicle", "ii", playerid, vehicleid);
	if(!IsPlayerInRangeOfPoint(playerid, 10, fVehicle[0], fVehicle[1], fVehicle[2]))
	{
	    return;
	}
}

forward OnVehicleHitUnoccupiedVehicle(playerid, myvehicleid, vehicleid);
forward OnPlayerHitUnoccupiedVehicle(playerid, vehicleid);
forward OnVehicleHitVehicle(playerid, myvehicleid, vehicleid);

public OnVehicleHitUnoccupiedVehicle(playerid, myvehicleid, vehicleid)
{
    CallLocalFunction("OnVehicleHitVehicle", "ddd", playerid, myvehicleid, vehicleid);
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
	
forward OnPlayerVehicleHealthChange(playerid, vehicleid, Float:newhealth, Float:oldhealth);
public OnPlayerVehicleHealthChange(playerid, vehicleid, Float:newhealth, Float:oldhealth)
{
	if(!(1 <= vehicleid <= MAX_VEHICLES)) return 1;
	if(-1.5 <= MPGetVehicleUpsideDown(vehicleid) <= -0.5)
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
	if(WasDamaged[vehicleid] == 0 && newhealth < oldhealth)
	{
		WasDamaged[vehicleid] = 1;
		new Float:x, Float:y, Float:z;
	    foreach(Vehicles, id)
	    {
	        if(vehicleid == id) continue;
	        if(WasDamaged[id] == 1)
	        {
	            GetVehiclePos(id, x, y, z);
	            if (GetVehicleDistanceFromPoint(vehicleid, x, y, z) > TwistedRAMRadius(GetVehicleModel(id))) continue;
	            new Float:yX, Float:yY, Float:yZ, Float:oyX, Float:oyY, Float:oyZ, Float:speed[2];
	            GetVehicleVelocity(id, yX, yY, yZ);
	            GetVehicleVelocity(vehicleid, oyX, oyY, oyZ);
	            speed[0] = floatsqroot(yX*yX + yX*yX);
	            speed[1] = floatsqroot(oyX*oyX + oyY*oyY);
	            if(speed[0] > speed[1])
				{
	      			CallLocalFunction("OnVehicleHitVehicle", "ddd", MPGetVehicleDriver(id), id, vehicleid);
				}
				else if(speed[1] > speed[0])
				{
	      			CallLocalFunction("OnVehicleHitVehicle", "ddd", MPGetVehicleDriver(vehicleid), vehicleid, id);
				}
	        }
	    }
	    SetTimerEx("ResetCollision", 750, false, "i", vehicleid);
	}
	if(vehicleid == PlayerInfo[playerid][pSpecial_Missile_Vehicle] && newhealth < oldhealth)
	{
	    new slot = 0, Float:x, Float:y, Float:z, Float:distaway;
	    GetVehiclePos(PlayerInfo[playerid][pSpecial_Missile_Vehicle], x, y, z);
        Vehicle_Smoke[vehicleid][slot] = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
        new id = GetClosestVehicle(playerid, 10.0, distaway);
        if(id != INVALID_VEHICLE_ID)
        {
            new Float:damage;
            switch(GetVehicleModel(Current_Vehicle[playerid]))
	        {
	            case Vermin:
	            {
	                switch(floatround(distaway))
			        {
			            case 7..10: damage = 20.0;
			            case 0..6: damage = GetMissileDamage(Missile_Special, Current_Vehicle[playerid], 1);
			            default: return 1;
			        }
	            }
	            case Meat_Wagon:
	            {
			        switch(floatround(distaway))
			        {
			            case 7..10: damage = 10.0;
			            case 4..6: damage = 20.0;
			            case 0..3: damage = GetMissileDamage(Missile_Special, Current_Vehicle[playerid], 1);
			            default: return 1;
			        }
		        }
	        }
	        DamagePlayer(vehicleid, id, damage, Missile_Special);
        }
	    DestroyVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
	    new Float:health;
		GetPlayerHealth(playerid, health);
	    if(!(health == 0.0))
		{
			PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
			PlayerInfo[playerid][pSpecial_Missile_Vehicle] = 0;
		}
        Vehicle_Firing_Missile[vehicleid] = 0;
        KillTimer(Update_Missile_Timer[playerid][slot]);
        SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[vehicleid][slot], playerid);
	}
	if(newhealth < 700.0)
	{
	    SetVehicleHealth(vehicleid, 1000.0);
	}
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
		case Junkyard_Dog, Brimstone, Outlaw, Roadkill, Thumper, Spectre, Shadow, Meat_Wagon, Vermin, Sweet_Tooth: return 12.0;
		case Reaper: return 9.0;
		case Darkside: return 16.0;
		case ManSalughter: return 18.0;
	}
	return 12.0;
}

stock Float:TwistedDamageMultiplier(twistedid)
{
	switch(twistedid)
	{
		case Junkyard_Dog: return 0.7;
		case Brimstone: return 1.1;
		case Outlaw: return 1.1;
		case Reaper: return 1.4;
		case Roadkill: return 1.0;
		case Thumper: return 1.1;
		case Spectre: return 1.0;
		case Darkside: return 0.6;
		case Shadow: return 0.9;
		case Meat_Wagon: return 0.9;
		case Vermin: return 0.8;
		case ManSalughter: return 0.8;
		case Sweet_Tooth: return 0.7;
	}
	return 1.0;
}
new Float:Twisted_Custom_Health[MAX_VEHICLES];

public OnVehicleHitVehicle(playerid, myvehicleid, vehicleid)
{
	if(PlayerInfo[playerid][pSpecial_Missile_Vehicle] == myvehicleid || myvehicleid == vehicleid) return 1;
    SendClientMessageFormatted(INVALID_PLAYER_ID, -1, "Vehicleid: %d Collided With Vehicleid: %d", myvehicleid, vehicleid);
    new Float:Health, Float:size_x, Float:size_y, Float:size_z;
	T_GetVehicleHealth(vehicleid, Health);
	GetVehicleSize(myvehicleid, size_x, size_y, size_z);
	size_z += size_x;
	size_z += size_y;
	new Float:total = GetVehicleSpeed(myvehicleid, true) * 0.6;
	total *= TwistedDamageMultiplier(GetVehicleModel(vehicleid));
	T_SetVehicleHealth(vehicleid, (floatsub(Health, total)));
	new str[32];
	format(str, sizeof(str), "Ram Damage Hit %d damage", floatround(total));
	TimeTextForPlayer( TIMETEXT_TOP, playerid, str, 3000);
	return 1;
}

forward OnEthicalHealthChange(vehicleid, playerid, Float:newhealth, Float:oldhealth);
public OnEthicalHealthChange(vehicleid, playerid, Float:newhealth, Float:oldhealth)
{
	//printf("OnEthicalHealthChange(%d, %d, %f, %f)", vehicleid, playerid, Float:newhealth, Float:oldhealth);
	if(PlayerInfo[playerid][pSpawned] == 0) return 1;
	new Float:health, Float:maxhealth = GetTwistedMetalMaxHealth(vehicleid);
   	health = (newhealth) / maxhealth * 100;
    //printf("health: %0.2f - maxhealth: %0.2f - newhealth: %0.2f", health, maxhealth, newhealth);
	SetPlayerHealth(playerid, health);
	TextDrawLetterSize(pTextInfo[playerid][pHealthBar], 0.000000, (health * -0.086));
	TextDrawShowForPlayer(playerid, pTextInfo[playerid][pHealthBar]);
	new Float:diff = oldhealth - newhealth;
	diff /= oldhealth;
	diff *= maxhealth;
	//printf("diff percent: %0.2f", diff);
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
    T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(vehicleid));
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
#define PUSH_INDEX 320

public OnPlayerUpdate(playerid)
{
    if(PlayerInfo[playerid][pSelection] == 0)
	{
    	if(PlayerInfo[playerid][pSpawned] == 1)
		{
		    new vehicleid = ( 1 <= PlayerInfo[playerid][pSpecial_Missile_Vehicle] <= 2000 ) ? PlayerInfo[playerid][pSpecial_Missile_Vehicle] : Current_Vehicle[playerid];
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
				static Float:x, Float:y, Float:z;
				new ud, lr, keys;
                GetPlayerKeys(playerid, keys, ud, lr);
                if(debugkeys && keys != 0)
                {
                    printf("keys: %d", keys);
                }
                #pragma unused ud, lr
                if (keys & KEY_AIM)
                {
                    GetPlayerPos(playerid, x, y, z);
                    if (FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_LX] < x < FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_UX] && FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_LY] < y < FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_UY])
                    {
                        FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PX] = x;
                        FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PY] = y;
                        FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PZ] = z;
                    }
                    else
                    {
                    	SetPlayerPos(playerid, FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PX], FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PY], FIXES_gsWorldbounds[playerid][E_FIXES_WORLDBOUND_DATA_PZ]);
                    }
                }
			}
		}
	}
	else
	{
	    new keys, ud, lr;
		GetPlayerKeys(playerid, keys, ud, lr);
		if(lr == KEY_RIGHT)
		{
		    if(Switched_Vehicle_Rec{playerid} == 0)
		    {
		        SetPlayerVirtualWorld(playerid, playerid);
				Switched_Vehicle_Rec{playerid} = 1;
				if(1 <= Current_Vehicle[playerid] <= 2000)
			  	{
				  	DestroyVehicle(Current_Vehicle[playerid]);
				}
				SetTimerEx("Push", PUSH_INDEX, false, "i", playerid);
				Current_Car_Index[playerid]++;
				startr:
				switch(Current_Car_Index[playerid])
				{
				    case 1..13:
					{
					    SetPlayerPos(playerid, -989.8796, 1285.7173, 39.8996);
						Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
						C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
						GameTextForPlayerFormatted(playerid, "~n~~n~~n~~n~~n~~n~~n~~<~ %s ~>~", 15000, 3, C_S_IDS[Current_Car_Index[playerid]][CS_TwistedName]);
      					PlayerInfo[playerid][pSkin] = C_S_IDS[Current_Car_Index[playerid]][CS_SkinID];
					}
					default:
			        {
						Current_Car_Index[playerid] = 1;
						goto startr;
					}
				}
				SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
				SetVehicleVirtualWorld(Current_Vehicle[playerid], playerid);
				PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
				//SetPlayerCameraPos(playerid, TM_SELECTION_CAMERA_X, TM_SELECTION_CAMERA_Y, TM_SELECTION_CAMERA_Z);
				#if SAMP_03e == (true)
				SetPlayerCameraLookAt(playerid, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z, CAMERA_MOVE);
				#else
				SetPlayerCameraLookAt(playerid, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z);
				#endif
				PlayerInfo[playerid][pCarModel] = GetVehicleModel(Current_Vehicle[playerid]);
				Add_Vehicle_Offsets_And_Objects(Current_Vehicle[playerid], Missile_Machine_Gun);
			}
		}
		else if(lr == KEY_LEFT)
		{
  			if(Switched_Vehicle_Rec{playerid} == 0)
		    {
		        SetPlayerVirtualWorld(playerid, playerid);
				Switched_Vehicle_Rec{playerid} = 1;
				SetTimerEx("Push", PUSH_INDEX, false, "i", playerid);
				if(1 <= Current_Vehicle[playerid] <= 2000)
			  	{
				  	DestroyVehicle(Current_Vehicle[playerid]);
				}
				if(Current_Car_Index[playerid] < 0)
    			{
					Current_Car_Index[playerid] = (13 - 1);
    			}
    			Current_Car_Index[playerid] --;
    			startl:
				switch(Current_Car_Index[playerid])
				{
			        case 1..13:
					{
					    SetPlayerPos(playerid, -989.8796, 1285.7173, 39.8996);
						Current_Vehicle[playerid] = CreateVehicle(C_S_IDS[Current_Car_Index[playerid]][CS_VehicleModelID], TM_SELECTION_X, TM_SELECTION_Y, TM_SELECTION_Z, TM_SELECTION_ANGLE,
						C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
						GameTextForPlayerFormatted(playerid, "~n~~n~~n~~n~~n~~n~~n~~<~ %s ~>~", 15000, 3, C_S_IDS[Current_Car_Index[playerid]][CS_TwistedName]);
      					PlayerInfo[playerid][pSkin] = C_S_IDS[Current_Car_Index[playerid]][CS_SkinID];
					}
					default:
					{
						Current_Car_Index[playerid] = 13;
						goto startl;
					}
				}
				SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
				SetVehicleVirtualWorld(Current_Vehicle[playerid], playerid);
				PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
				//SetPlayerCameraPos(playerid, TM_SELECTION_CAMERA_X, TM_SELECTION_CAMERA_Y, TM_SELECTION_CAMERA_Z);
				#if SAMP_03e == (true)
				SetPlayerCameraLookAt(playerid, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z, CAMERA_MOVE);
				#else
				SetPlayerCameraLookAt(playerid, TM_SELECTION_LOOKAT_X, TM_SELECTION_LOOKAT_Y, TM_SELECTION_LOOKAT_Z);
				#endif
				PlayerInfo[playerid][pCarModel] = GetVehicleModel(Current_Vehicle[playerid]);
				Add_Vehicle_Offsets_And_Objects(Current_Vehicle[playerid], Missile_Machine_Gun);
			}
		}
	}
  	return 1;
}

stock GetDotXY(Float:StartPosX, Float:StartPosY, &Float:NewX, &Float:NewY, Float:alpha, Float:dist)
{
   	NewX = StartPosX + (dist * floatsin(alpha, degrees));
  	NewY = StartPosY + (dist * floatcos(alpha, degrees));
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


forward Push(playerid);
public Push(playerid)
{
	Switched_Vehicle_Rec{playerid} = 0;
	return 1;
}
#define pb_percent2(%1,%2,%3,%4) ((%1 + 6.0) - ((((%1 - 6.0 + %2 - 2.0) - %1) / %3) * %4))
//pb_percent(x, width, max, value)
public UpdatePlayerMissileStatus(playerid)
{
	new id = GetPlayerVehicleID(playerid);
	for(new m = 0; m < MAX_MISSILEID; m++)
	{
	    if(Vehicle_Missileid[id] == m && PlayerInfo[playerid][pMissiles][m] > 0)
		{
			new str[32];
			format(str, 32, "%d %s", PlayerInfo[playerid][pMissiles][m], GetTwistedMissileName(m, m));
 			TextDrawSetString(pTextInfo[playerid][pMissileSign][m], str);
 			TextDrawColor(pTextInfo[playerid][pMissileSign][m], 0x00FF00FF);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pMissileSign][m]);
			continue;
		}
	    TextDrawColor(pTextInfo[playerid][pMissileSign][m], 100);
		if(PlayerInfo[playerid][pMissiles][m] > 0)
		{
			new str[32];
			format(str, 32, "%d %s", PlayerInfo[playerid][pMissiles][m], GetTwistedMissileName(m, m));
 			TextDrawSetString(pTextInfo[playerid][pMissileSign][m], str);
            TextDrawShowForPlayer(playerid, pTextInfo[playerid][pMissileSign][m]);
		}
		else TextDrawHideForPlayer(playerid, pTextInfo[playerid][pMissileSign][m]);
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
    //если normalised, - один, в противном случае - показатель коррекции
    new Float: test = qx*qy + qz*qw;
    if (test > 0.499*unit)
    { // singularity at north pole - особенность на северном полюсе
        heading = 2*atan2(qx,qw);
        attitude = 3.141592653/2;
        bank = 0;
        return 1;
    }
    if (test < -0.499*unit)
    { // singularity at south pole - особенность на южном полюсе
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
    new Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z;
    GetVehicleRotationQuat(vehicleid,quat_w,quat_x,quat_y,quat_z);
    ConvertNonNormaQuatToEuler(quat_w,quat_x,quat_z,quat_y, heading, attitude, bank);
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
	            case Meat_Wagon:
	            {
	                new Float:vx, Float:vy, Float:vz, Float:distance, Float:angle;
	                GetVehicleZAngle(id, angle);
	                GetVehicleVelocity(id, vx, vy, vz);
	                distance = floatsqroot(vx*vx + vy*vy + vz*vz);

				    if(distance < 0.35) //gurney too slow
					{
	                    vx = floatsin(-angle, degrees) * 0.4;
					    vy = floatcos(-angle, degrees) * 0.4;
					    vz = 0.1;
	                }
	                distance += 6;

	                new Float:x, Float:y, Float:z;
	                GetVehiclePos(id, x, y, z);

					x += (distance * floatsin(-angle, degrees));
					y += (distance * floatcos(-angle, degrees));
	                z += 0.1;

	                PlayerInfo[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(457, x, y, z, angle, 0, 0, -1);
	                SetVehicleVelocity(PlayerInfo[playerid][pSpecial_Missile_Vehicle], vx, vy, vz);
	                LinkVehicleToInterior(PlayerInfo[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
	                SetVehicleHealth(PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2500.0);
	                Vehicle_Firing_Missile[PlayerInfo[playerid][pSpecial_Missile_Vehicle]] = 1;
	                PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(2146, x, y, (z + 0.5), 0, 0, angle, 300.0);
	                AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				   	PutPlayerInVehicle(playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0);
				   	Update_Missile_Timer[playerid][slot] = SetTimerEx("GurneySpeedUpdate", 150, true, "ii", playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	            }
	            case Vermin:
	            {
	                new Float:x, Float:y, Float:z, Float:angle;
	                GetVehiclePos(id, x, y, z);
	                GetVehicleZAngle(id, angle);
	                z += 3;
	                PlayerInfo[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(464, x, y, z, angle, 0, 0, -1);
	                LinkVehicleToInterior(PlayerInfo[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
	                SetVehicleHealth(PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2500.0);
	                Vehicle_Firing_Missile[PlayerInfo[playerid][pSpecial_Missile_Vehicle]] = 1;
	                PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(Missile_Default_Object, x, y, (z + 0.5), 0, 0, angle, 300.0);
	                AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 270.0);
				   	PutPlayerInVehicle(playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0);
	               	Update_Missile_Timer[playerid][slot] = SetTimerEx("RocketSpeedUpdate", 150, true, "ii", playerid, PlayerInfo[playerid][pSpecial_Missile_Vehicle]);
	               	SetPVarInt(playerid, "Add_Vermin", 1);
			  	}
			}
			Object_Owner[PlayerInfo[playerid][pSpecial_Missile_Object]] = id;
			Object_OwnerEx[PlayerInfo[playerid][pSpecial_Missile_Object]] = playerid;
			Object_Type[PlayerInfo[playerid][pSpecial_Missile_Object]] = Missile_Special;
			Object_Slot[PlayerInfo[playerid][pSpecial_Missile_Object]] = slot;
	   	}
	}
	return 1;
}
forward FireMissile(playerid, missileid);
public FireMissile(playerid, missileid)
{
    new id = GetPlayerVehicleID(playerid), slot;
	switch(missileid)
	{
	    case Missile_Machine_Gun:
	   	{
	   	    if(IsValidObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]])) DestroyObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]);
	   	
			CallLocalFunction("OnVehicleFire", "iiii", playerid, id, Vehicle_Machine_Gun_CurrentSlot[id], Missile_Machine_Gun);
			new Float:x, Float:y, Float:z, Float:a;
			GetVehiclePos(id, x, y, z);
			GetVehicleZAngle(id, a);
     		switch(GetVehicleModel(id))
			{
			    case Junkyard_Dog: // Junkyard Dog (Tow Truck)
				{
				    z += 0.53;
				    if(Vehicle_Machine_Gun_CurrentSlot[id] == 0)
       				{
					    a += 90;
	     				x += (0.9 * floatsin(-a, degrees));
	     				y += (1.0 * floatcos(-a, degrees));
                	}
                	else if(Vehicle_Machine_Gun_CurrentSlot[id] == 1)
					{
						a += 270;
						x += (0.9 * floatsin(-a, degrees));
						y += (1.1 * floatcos(-a, degrees));
					}
				}
				case Reaper: // Reaper (Freeway)
				{
				    a += 90;
					x += (-0.3 * floatsin(-a, degrees));
					y += (-0.3 * floatcos(-a, degrees));
				}
				case Brimstone: // Brimstone - Preacher
				{
      				a += 90;
              		x += (-1.2 * floatsin(-a, degrees));
                	y += (-1.2 * floatcos(-a, degrees));
                	z += 0.70;
				}
				case Outlaw: // Outlaw (Rancher)
				{
				    a += 90;
              		x += (-0.40 * floatsin(-a, degrees));
                	if(GetPlayerSpeed(playerid, true) < 45) y += (-0.60 * floatcos(-a, degrees));
                	else y += (0.40 * floatcos(-a, degrees));
                	z += 0.85;
				}
				case Roadkill, 474: // Roadkill (Bullet) / Crazy 8
				{
           			a += 270;
              		x += (0.6 * floatsin(-a, degrees));
					y += (0.6 * floatcos(-a, degrees));
                	z += 0.67;
				}
				case Spectre:
				{
     				a += 270;
					x += (0.9 * floatsin(-a, degrees));
					y += (1.1 * floatcos(-a, degrees));
     				z += 0.53;
				}
   				case Darkside, Shadow, Meat_Wagon, ManSalughter, Sweet_Tooth:
			    {
       				if(Vehicle_Machine_Gun_CurrentSlot[id] == 0) a += 90;
       				else if(Vehicle_Machine_Gun_CurrentSlot[id] == 1) a += 270;
			    }
			    default: { a += 90; }
 			}
      		Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]] = CreateObject(/*1240*/Machine_Gun, x, y, z, 0, 0, a, 300.0);

    		/*x += (90 * floatsin(-a, degrees));
     		y += (90 * floatcos(-a, degrees));*/
     		GetXYInFrontOfVehicle(id, x, y, 120.0);

      		MoveObject(Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]], x, y, z, 65);

			KillTimer(Update_Machine_Gun_Timer[playerid][Vehicle_Machine_Gun_Currentid[id]]);
            Update_Machine_Gun_Timer[playerid][Vehicle_Machine_Gun_Currentid[id]] = SetTimerEx("UpdateMissile", Missile_Update_Index + 10, true, "dddddd", playerid, id, Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]], Missile_Machine_Gun, Vehicle_Machine_Gun_CurrentSlot[id], INVALID_VEHICLE_ID);
            Object_Owner[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = id;
  			Object_OwnerEx[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = playerid;
            Object_Type[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = Missile_Machine_Gun;
            Object_Slot[Vehicle_Machine_Gun[id][Vehicle_Machine_Gun_Currentid[id]]] = Vehicle_Machine_Gun_Currentid[id];
			Vehicle_Machine_Gun_Currentid[id] ++;
  			Vehicle_Machine_Gun_CurrentSlot[id] ++;

			if(Vehicle_Machine_Gun_Currentid[id] > 24) Vehicle_Machine_Gun_Currentid[id] = 0;
  			if(Vehicle_Machine_Gun_CurrentSlot[id] > 1) Vehicle_Machine_Gun_CurrentSlot[id] = 0;
			return 1;
		}
		case Missile_Special:
		{
		    switch(GetVehicleModel(id))
		    {
		        case Roadkill:
		        {
		            Vehicle_Firing_Missile[id] = 1;
					new m = Vehicle_Missile_Special_Slot[id];
					slot = m;
					new v = GetClosestVehicle(playerid), Float:x, Float:y, Float:z, Float:a;

					GetVehicleZAngle(id, a);
					GetVehiclePos(id, x, y, z);
					
		            new Float:offsetx = 0.70;
		            switch(Vehicle_Missile_Special_Slot[id])
		            {
		                case 1: offsetx = 0.70;//offsetx -= (0.30 * Vehicle_Missile_Special_Slot[id]);
		                case 2: offsetx = 0.40;
		                case 3: offsetx = 0.10;
		                case 4: offsetx = -0.20;
		                case 5: offsetx = -0.50;
		                case 6: offsetx = -0.70;
		            } 
		          	CalculateMissile(a, x, y, z, offsetx, VehicleOffsetY[id], VehicleOffsetZ[id]);

		           	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
		          	new Float:y2 = y + (90.0 * floatcos(-a, degrees));
		          	
		        	Vehicle_Missile[id][m] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90),  300.0);
		           	Vehicle_Smoke[id][m] = CreateObject(18731, x, y, (z - 1.3), 0, 0, 0, 300.0);

					MoveObject(Vehicle_Missile[id][m], x2, y2, (z - 0.3), MISSILE_SPEED);
					#if SAMP_03d == (false)
		          	MoveObject(Vehicle_Smoke[id][m], x2, y2, (z - 1.3), MISSILE_SPEED);
		          	#else
		          	AttachObjectToObject(Vehicle_Smoke[id][m], Vehicle_Missile[id][m], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
					#endif
		            KillTimer(Update_Missile_Timer[playerid][m]);
		            Update_Missile_Timer[playerid][m] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, INVALID_VEHICLE_ID);

					GetVehiclePos(v, x, y, z);
		            if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
					{
					    KillTimer(Update_Missile_Timer[playerid][m]);
						Update_Missile_Timer[playerid][m] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, v);
					}
					else
					{
					    foreachex(Vehicles, v)
					    {
					        if(v == id) continue;
					        if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
					        GetVehiclePos(v, x, y, z);
					     	if( IsPlayerAimingAt(playerid, x, y, z, 30.0) || IsPlayerFacingVehicleEx(playerid, v, 15.0) || IsVehicleStreamedIn(v, playerid))
							{
							    KillTimer(Update_Missile_Timer[playerid][m]);
								Update_Missile_Timer[playerid][m] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, v);
							    break;
							}
					    }
					}
					Vehicle_Missile_Special_Slot[id] ++;
                    CallLocalFunction("OnVehicleFire", "iiii", playerid, id, m, Missile_Special);
		        }
		        case Sweet_Tooth:
		        {
					Vehicle_Firing_Missile[id] = 1;
					new m = Vehicle_Missile_Special_Slot[id];
					slot = m;
					new v = GetClosestVehicle(playerid), Float:x, Float:y, Float:z, Float:a;

					GetVehicleZAngle(id, a);
					GetVehiclePos(id, x, y, z);

		          	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

		           	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
		          	new Float:y2 = y + (90.0 * floatcos(-a, degrees));
		          	
		          	new Float:vx, Float:vy, Float:vz, Float:distance;
	                GetVehicleVelocity(id, vx, vy, vz);
	                distance = floatsqroot(vx * vx + vy * vy + vz * vz);
	                distance += distance + VehicleOffsetY[id];
					x += (distance * floatsin(-a, degrees));
                  	y += (distance * floatcos(-a, degrees));

		        	Vehicle_Missile[id][m] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
		           	Vehicle_Smoke[id][m] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

					MoveObject(Vehicle_Missile[id][m], x2, y2, z, MISSILE_SPEED);
					#if SAMP_03d == (false)
		          	MoveObject(Vehicle_Smoke[id][m], x2, y2, z - 1.3, MISSILE_SPEED);
		          	#else
		          	AttachObjectToObject(Vehicle_Smoke[id][m], Vehicle_Missile[id][m], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
					#endif
		            KillTimer(Update_Missile_Timer[playerid][m]);
		            Update_Missile_Timer[playerid][m] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, INVALID_VEHICLE_ID);

					GetVehiclePos(v, x, y, z);
		            if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0))
					{
					    KillTimer(Update_Missile_Timer[playerid][m]);
						Update_Missile_Timer[playerid][m] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, v);
					}
					else
					{
					    foreachex(Vehicles, v)
					    {
					        if(v == id) continue;
					        if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
					        GetVehiclePos(v, x, y, z);
					     	if( IsPlayerAimingAt(playerid, x, y, z, 30.0) || IsPlayerFacingVehicleEx(playerid, v, 15.0))
							{
							    KillTimer(Update_Missile_Timer[playerid][m]);
								Update_Missile_Timer[playerid][m] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, v);
							    break;
							}
					    }
					}
					Vehicle_Missile_Special_Slot[id] ++;
					if(Vehicle_Missile_Special_Slot[id] >= 19)
					{
					    Vehicle_Missile_Special_Slot[id] = 0;
					}
                    CallLocalFunction("OnVehicleFire", "iiii", playerid, id, m, Missile_Special);
				}
			}
		}
		case Missile_EMP:
        {
			Vehicle_Firing_Missile[id] = 1;
			new m = ENERGY_MISSILE_SLOT;
			slot = m;
			new v = GetClosestVehicle(playerid), Float:x, Float:y, Float:z, Float:a;

			GetVehicleZAngle(id, a);
			GetVehiclePos(id, x, y, z);

          	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

           	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
          	new Float:y2 = y + (90.0 * floatcos(-a, degrees));

        	Vehicle_Missile[id][m] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
           	Vehicle_Smoke[id][m] = CreateObject(18728, x, y, z - 0.7, 0, 0, 0, 300.0);

			MoveObject(Vehicle_Missile[id][m], x2, y2, z, MISSILE_SPEED);
			#if SAMP_03d == (false)
          	MoveObject(Vehicle_Smoke[id][m], x2, y2, z - 1.3, MISSILE_SPEED);
          	#else
          	AttachObjectToObject(Vehicle_Smoke[id][m], Vehicle_Missile[id][m], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0);
			#endif
            KillTimer(Update_Missile_Timer[playerid][m]);
            Update_Missile_Timer[playerid][m] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, INVALID_VEHICLE_ID);

			GetVehiclePos(v, x, y, z);
            if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
			{
			    KillTimer(Update_Missile_Timer[playerid][m]);
				Update_Missile_Timer[playerid][m] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, v);
			}
			else
			{
			    foreachex(Vehicles, v)
			    {
			        if(v == id) continue;
			        if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
			        GetVehiclePos(v, x, y, z);
			     	if( IsPlayerAimingAt(playerid, x, y, z, 30.0) || IsPlayerFacingVehicleEx(playerid, v, 15.0) || IsVehicleStreamedIn(v, playerid))
					{
					    KillTimer(Update_Missile_Timer[playerid][m]);
						Update_Missile_Timer[playerid][m] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][m], Missile_Special, m, v);
					    break;
					}
			    }
			}
			Vehicle_Missile_Special_Slot[id] ++;
            CallLocalFunction("OnVehicleFire", "iiii", playerid, id, m, Missile_Special);
		}
	}
	Object_Owner[Vehicle_Missile[id][slot]] = id;
  	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
  	Object_Type[Vehicle_Missile[id][slot]] = missileid;
  	Object_Slot[Vehicle_Missile[id][slot]] = slot;
	return 1;
}

stock Add_Vehicle_Offsets_And_Objects(vehicleid, Missileid)
{
	if(!Vehicle_Firing_Missile[vehicleid])
 	{
       	new Float:x, Float:y, Float:u;
       	if(GetVehiclePos(vehicleid, u, u, u))
      	{
      	    switch(Missileid)
			{
			    case Missile_Machine_Gun:
				{
				    Vehicle_Machine_Gunid[vehicleid] = Missile_Machine_Gun;
				    new Float:ry = 0.0;
		           	if(IsValidObject(Vehicle_Machine_Gun_Object[vehicleid][0])) DestroyObject(Vehicle_Machine_Gun_Object[vehicleid][0]);
		           	if(IsValidObject(Vehicle_Machine_Gun_Object[vehicleid][1])) DestroyObject(Vehicle_Machine_Gun_Object[vehicleid][1]);
		           	Vehicle_Machine_Gun_Object[vehicleid][0] = CreateObject(362, x, y, u, 0, 0, 0, 300.0);
     				switch(GetVehicleModel(vehicleid))
					{
					    case Junkyard_Dog: // Junkyard Dog / Tow Truck
						{
						    VehicleOffsetX[vehicleid] = 1.0;
						    VehicleOffsetY[vehicleid] = 2.5;
		           			VehicleOffsetZ[vehicleid] = 0.53;
		           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, u, 0, 0, 0, 300.0);
		           			AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.0, 2.5, 0.53, 0.0, 30.0, 95.0);
							AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.85, 2.5, 0.53, 0.0, 30.0, 95.0);
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
						case Roadkill, Thumper:
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
		           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, u, 0, 0, 0, 300.0);
						    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.2, 3.3, 0.4, 0.0, 30.0, 95.0);
							AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 3.3, 0.4, 0.0, 30.0, 95.0);
							return 1;
						}
						case Shadow, Meat_Wagon:
						{
						    VehicleOffsetX[vehicleid] = 1.1;
						    VehicleOffsetY[vehicleid] = 1.0;
		           			VehicleOffsetZ[vehicleid] = 0.5;
		           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, u, 0, 0, 0, 300.0);
							AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.1, 1.0, 0.5, 0.0, 30.0, 95.0);
							AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -0.97, 1.0, 0.5, 0.0, 30.0, 95.0);
							return 1;
						}
						case Vermin:
						{
						    VehicleOffsetX[vehicleid] = 1.1;
						    VehicleOffsetY[vehicleid] = 1.0;
		           			VehicleOffsetZ[vehicleid] = 0.5;
						    ry = 30.0;
						}
						case ManSalughter:
						{
						    VehicleOffsetX[vehicleid] = 1.3;
						    VehicleOffsetY[vehicleid] = 3.0;
		           			VehicleOffsetZ[vehicleid] = 0.5;
		           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, u, 0, 0, 0, 300.0);
						    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.3, 3.0, 0.5, 0.0, 30.0, 95.0);
						    AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.2, 3.0, 0.5, 0.0, 30.0, 95.0);
						    return 1;
						}
						case Sweet_Tooth:
						{
						    VehicleOffsetX[vehicleid] = 1.2;
						    VehicleOffsetY[vehicleid] = 1.7;
		           			VehicleOffsetZ[vehicleid] = 0.5;
		           			Vehicle_Machine_Gun_Object[vehicleid][1] = CreateObject(362, x, y, u, 0, 0, 0, 300.0);
							AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, 1.2, 1.7, 0.5, 0.0, 30.0, 95.0);
							AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][1], vehicleid, -1.05, 1.7, 0.5, 0.0, 30.0, 95.0);
							VehicleOffsetX[vehicleid] = 1.3;
						    VehicleOffsetY[vehicleid] = 2.0;
		           			VehicleOffsetZ[vehicleid] = 0.6;
							return 1;
						}
						default: AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, -VehicleOffsetX[vehicleid], VehicleOffsetY[vehicleid], VehicleOffsetZ[vehicleid], 0.0, ry, 95.0);
					}
					AttachObjectToVehicle(Vehicle_Machine_Gun_Object[vehicleid][0], vehicleid, VehicleOffsetX[vehicleid], VehicleOffsetY[vehicleid], VehicleOffsetZ[vehicleid], 0.0, ry, 95.0);
					switch(GetVehicleModel(vehicleid))//set REAL OFFSETS FOR SHOOTING
					{
					    case Junkyard_Dog:
						{
						    VehicleOffsetX[vehicleid] = 1.2;
						    VehicleOffsetY[vehicleid] = 2.7;
		           			VehicleOffsetZ[vehicleid] = 1.3;
						}
						case Brimstone:
						{
						    VehicleOffsetX[vehicleid] = 1.2;
						    VehicleOffsetY[vehicleid] = 0.6;
		           			VehicleOffsetZ[vehicleid] = 0.53;
						}
						case Outlaw:
						{
						    VehicleOffsetX[vehicleid] = 0.40;
						    VehicleOffsetY[vehicleid] = 2.60;
		           			VehicleOffsetZ[vehicleid] = 0.5;
						}
						case Reaper://1085 tire
						{
						    VehicleOffsetX[vehicleid] = 0.07;
						    VehicleOffsetY[vehicleid] = 0.50;
		           			VehicleOffsetZ[vehicleid] = 0.80;
						}
						case Thumper:
						{
						    VehicleOffsetX[vehicleid] = 0.75;
						    VehicleOffsetY[vehicleid] = 1.00;
		           			VehicleOffsetZ[vehicleid] = 0.70;
						}
						case Spectre:
						{
						    VehicleOffsetX[vehicleid] = 1.04;
						    VehicleOffsetY[vehicleid] = 1.0;
		           			VehicleOffsetZ[vehicleid] = 0.70;
						}
						case Vermin:
						{
						    VehicleOffsetX[vehicleid] = 1.1;
						    VehicleOffsetY[vehicleid] = 1.3;
		           			VehicleOffsetZ[vehicleid] = 0.5;
						}
					}
				}
			    case Missile_Machine_Gun_Upgrade: Vehicle_Machine_Gunid[vehicleid] = Missile_Machine_Gun_Upgrade;
			    //3786
			    /*case Missile_Napalm:
			    {
					if(IsValidObject(Vehicle_Missile[vehicleid][0])) DestroyObject(Vehicle_Missile[vehicleid][0]);
			        Vehicle_Missile[vehicleid][0] = CreateObject(3046, x, y, u, 0, 0, 0, 300.0);
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
             		Vehicle_Missileid[vehicleid] = Missileid;
			        return 1;
			    }*/
			}
      	}
  	}
	return 0;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
	{
	    if(PlayerInfo[playerid][pSelection] == 0)
	    {
	        PlayerInfo[playerid][pLastVeh] = GetPlayerVehicleID(playerid);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pBox]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pUpArrow]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pLeftArrow]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pRightArrow]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pHealthSign]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pHealthBar]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pBoxSeparater]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pSecondBox]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pEnergySign]);
			TextDrawShowForPlayer(playerid, pTextInfo[playerid][pTurboSign]);
			for(new m = 0; m < (MAX_MISSILEID); m++)
			{
				TextDrawShowForPlayer(playerid, pTextInfo[playerid][pMissileSign][m]);
			}
			ShowProgressBarForPlayer(playerid, pTextInfo[playerid][pEnergyBar]);
			ShowProgressBarForPlayer(playerid, pTextInfo[playerid][pTurboBar]);
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
        }
	}
	else if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
	{
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pBox]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pUpArrow]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pLeftArrow]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pRightArrow]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pHealthSign]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pHealthBar]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pBoxSeparater]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pSecondBox]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pEnergySign]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pTurboSign]);
		TextDrawHideForPlayer(playerid, pTextInfo[playerid][pMissileSign]);
		for(new m = 0; m < (MAX_MISSILEID); m++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][pMissileSign][m]);
		HideProgressBarForPlayer(playerid, pTextInfo[playerid][pEnergyBar]);
		HideProgressBarForPlayer(playerid, pTextInfo[playerid][pTurboBar]);
		//for(new i; i < Speedometer_Needle_Index; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][SpeedoMeterNeedle][i]);
 		//for(new i; i != 15; i++) TextDrawHideForPlayer(playerid, pTextInfo[playerid][TDSpeedClock][i]);
	}
	if(newstate == PLAYER_STATE_EXIT_VEHICLE && oldstate == PLAYER_STATE_DRIVER)
	{
	    if(!PlayerInfo[playerid][CanExitVeh]) SetTimerEx("PutPlayerBackInVehicle", 70, false, "ii", playerid, GetPlayerVehicleID(playerid));
	}
	if(newstate == PLAYER_STATE_ONFOOT)
	{
	    if(!PlayerInfo[playerid][CanExitVeh])
		{
			PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0); // PlayerInfo[playerid][pLastVeh]
		}
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
    new Float:pX,Float:pY,Float:pZ,Float:pA,Float:X,Float:Y,Float:Z,Float:ang;
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

forward ReturnDarksidesSpeed(vehicleid, Float:VelocityX, Float:VelocityY, Float:VelocityZ);
public ReturnDarksidesSpeed(vehicleid, Float:VelocityX, Float:VelocityY, Float:VelocityZ)
{
	SetVehicleVelocity(vehicleid, VelocityX, VelocityY, VelocityZ);
	Vehicle_Firing_Missile[vehicleid] = 0;
	return 1;
}

stock GetClosestVehicle(playerid, Float:dis = 99999.0, Float:distaway = 0.0)
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
    if(distaway)
    {
        distaway = dis;
    }
    return vehicle;
}

forward Outlaw_Special(playerid, vehicleid);
public Outlaw_Special(playerid, vehicleid)
{
	if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	{
	    PlayerInfo[playerid][pMissile_Special_Time] += 200;
	    if(PlayerInfo[playerid][pMissile_Special_Time] > 10000)
		{
		    Vehicle_Firing_Missile[vehicleid] = 0;
		    KillTimer(Update_Missile_Timer[playerid][0]);
		    PlayerInfo[playerid][pMissile_Special_Time] = 0;
		    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
			PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
		}
		else
		{
		    new Float:x, Float:y, Float:z, Float:x2, Float:y2, Float:Angle, closestvehicle = GetClosestVehicle(playerid, 25.0);
		    GetVehiclePos(vehicleid, x, y, z);
          	GetVehiclePos(closestvehicle, x2, y2, z);
          	Angle = 95.0 + Angle2D(x2, y2, x, y) + 180.0;
			MPClamp360(Angle);
          	if(closestvehicle == INVALID_VEHICLE_ID || !(1 <= closestvehicle <= 2000))
  			{
			  	Angle = 95.0;
			}
			else
			{
				DamagePlayer(vehicleid, closestvehicle, GetMissileDamage(Missile_Special, vehicleid), Missile_Special);
			}
          	SendClientMessageFormatted(playerid, -1, "[System] - playerid: %d - closestvehicleid: %d - Angle: %f - Angle2D - 95.0: %f", playerid, closestvehicle, Angle, (Angle - 95.0));
          	AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], vehicleid, 0.1, -0.5, 1.5, 0.0, 30.0, Angle);
		}
	}
	else
	{
	    Vehicle_Firing_Missile[vehicleid] = 0;
	    KillTimer(Update_Missile_Timer[playerid][0]);
	    PlayerInfo[playerid][pMissile_Special_Time] = 0;
	}
	return 1;
}

forward Thumper_Special(playerid, vehicleid);
public Thumper_Special(playerid, vehicleid)
{
	if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
	{
	    PlayerInfo[playerid][pMissile_Special_Time] += 100;
	    if(PlayerInfo[playerid][pMissile_Special_Time] > 7000)
		{
		    Vehicle_Firing_Missile[vehicleid] = 0;
		    KillTimer(Update_Missile_Timer[playerid][0]);
		    PlayerInfo[playerid][pMissile_Special_Time] = 0;
		    DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
			PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
		}
		else
		{
		    new cv = GetClosestVehicle(playerid, 8.0);
	      	if(cv == INVALID_VEHICLE_ID) return 1;
	      	new Float:x, Float:y, Float:z;
	      	GetVehiclePos(vehicleid, x, y, z);
	      	GetXYInFrontOfVehicle(vehicleid, x, y, 4.0);
	      	if(GetVehicleDistanceFromPoint(cv, x, y, z) < 4.0)
	      	{
		      	DamagePlayer(vehicleid, cv, GetMissileDamage(Missile_Special, vehicleid), Missile_Special);
	      	}
		}
	}
	else
	{
	    Vehicle_Firing_Missile[vehicleid] = 0;
	    KillTimer(Update_Missile_Timer[playerid][0]);
	    PlayerInfo[playerid][pMissile_Special_Time] = 0;
	}
	return 1;
}

forward FlashRoadkillForPlayer(playerid, times);
public FlashRoadkillForPlayer(playerid, times)
{
	if(times == 0) return 1;
	GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~r~~h~~h~| | | | | |~n~~p~Click ~k~~VEHICLE_FIREWEAPON_ALT~ To Fire!", 300, 3);
	SetTimerEx("FlashRoadkillForPlayer", 500, false, "ii", playerid, (times - 1));
	return 1;
}

forward Roadkill_Special(playerid, vehicleid, countdown);
public Roadkill_Special(playerid, vehicleid, countdown)
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
	        SetPVarInt(playerid, "Flash_Roadkill_Timer", SetTimerEx("FlashRoadkillForPlayer", 500, false, "ii", playerid, 6));
	        for(new s = 0; s != 7; s++)
			{
	        	KillTimer(Update_Missile_Timer[playerid][s]);
			}
	        PlayerInfo[playerid][pMissile_Special_Time] = 0;
	        PlayerInfo[playerid][pMissile_Special_Charged] = true;
	        SetTimerEx("Roadkill_Special", 3000, false, "iii", playerid, vehicleid, 2);
		}
	    return 1;
	}
	else if(countdown == 2)
	{
	    Vehicle_Firing_Missile[vehicleid] = 0;
	    for(new s = 0; s != MAX_MISSILE_SLOTS; s++)
		{
	    	KillTimer(Update_Missile_Timer[playerid][s]);
	    }
	    PlayerInfo[playerid][pMissile_Special_Time] = 0;
	    PlayerInfo[playerid][pMissile_Special_Charged] = false;
	    GameTextForPlayer(playerid, " ", 1, 3);
	    return 1;
	}
	return 1;
}

stock GetNextMissileSlot(playerid, vehicleid)
{
	new i;
	for(i = (MAX_MISSILEID - 1); i != MIN_MISSILEID; i--)//find the highest slot used
	{
	    if(PlayerInfo[playerid][pMissiles][i] != 0) break;
	    continue;
	}
	for(new m = (Vehicle_Missileid[vehicleid] + 1); m != (MAX_MISSILEID + 1); m++)
	{
	    if(m > i || m >= MAX_MISSILEID)
	    {
	        for(m = MIN_MISSILEID; m != Vehicle_Missileid[vehicleid]; m++)
			{
			    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
			    Vehicle_Missileid[vehicleid] = m;
			    break;
			}
			break;
	    }
	    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
	    Vehicle_Missileid[vehicleid] = m;
	    break;
	}
	return Vehicle_Missileid[vehicleid];
}

stock GetPreviousMissileSlot(playerid, vehicleid)
{
	new i;
	for(i = MIN_MISSILEID; i < MAX_MISSILEID; i++)//find the lowest slot used
	{
	    if(PlayerInfo[playerid][pMissiles][i] != 0) break;
	    continue;
	}
	for(new m = Vehicle_Missileid[vehicleid] - 1; m != (MIN_MISSILEID - 2); m--)
	{
	    if(m < 0)
	    {
	        for(m = (MAX_MISSILEID - 1); m != MIN_MISSILEID; m--)
			{
			    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
			    Vehicle_Missileid[vehicleid] = m;
			    break;
			}
			break;
	    }
	    if(PlayerInfo[playerid][pMissiles][m] == 0) continue;
	    Vehicle_Missileid[vehicleid] = m;
	    break;
	}
	return Vehicle_Missileid[vehicleid];
}

forward TwistedSpawnPlayer(playerid);
public TwistedSpawnPlayer(playerid)
{
    TDH(playerid);
    PlayerInfo[playerid][pSelection] = 0;
    RemovePlayerFromVehicle(playerid);
    new RandomArray = random(sizeof(Downtown_Spawns));
	SetPlayerPos(playerid, Downtown_Spawns[RandomArray][0], Downtown_Spawns[RandomArray][1], Downtown_Spawns[RandomArray][2]);
    SetPlayerCameraPos(playerid, Downtown_Spawns[RandomArray][0] + (7 * floatsin(-0.917705, degrees)), Downtown_Spawns[RandomArray][1] + (7 * floatcos(-0.917705, degrees)), Downtown_Spawns[RandomArray][2]);
	SetPlayerCameraLookAt(playerid, Downtown_Spawns[RandomArray][0], Downtown_Spawns[RandomArray][1] + 2, Downtown_Spawns[RandomArray][2] + 2);
	SetTimerEx("UnFreeze_AfterSpawn", 400, false, "dd", playerid, RandomArray);
	GameTextForPlayer(playerid, " ", 5, 3);
	SendClientMessage(playerid, -1, "Type /controls To See The Server Controls");
	return 1;
}

forward UnFreeze_AfterSpawn(playerid, RandomArray);
public UnFreeze_AfterSpawn(playerid, RandomArray)
{
    TogglePlayerControllable(playerid, true);
    DestroyVehicle(Current_Vehicle[playerid]);
    SetPlayerWorldBounds(playerid, -2164.8445, -1848.2859, -709.1476, -1087.1028);
	SetPlayerVirtualWorld(playerid, 0);
    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
	new c = PlayerInfo[playerid][pCarModel];
	Current_Vehicle[playerid] = CreateVehicle(c, Downtown_Spawns[RandomArray][0], Downtown_Spawns[RandomArray][1], Downtown_Spawns[RandomArray][2] + 0.7, Downtown_Spawns[RandomArray][3], C_S_IDS[Current_Car_Index[playerid]][CS_Colour1], C_S_IDS[Current_Car_Index[playerid]][CS_Colour2], 0);
    SetVehicleNumberPlate(Current_Vehicle[playerid], GetTwistedMetalName(GetVehicleModel(Current_Vehicle[playerid])));
	PutPlayerInVehicle(playerid, Current_Vehicle[playerid], 0);
	PlayerInfo[playerid][pSpawned] = 1;
	OnPlayerStateChange(playerid, PLAYER_STATE_DRIVER, PLAYER_STATE_SPAWNED);
	AttachSpecialObjects(playerid);
	Add_Vehicle_Offsets_And_Objects(Current_Vehicle[playerid], Missile_Machine_Gun);
	SetProgressBarValue(pTextInfo[playerid][pEnergyBar], float(PlayerInfo[playerid][pEnergy]));
	SetProgressBarValue(pTextInfo[playerid][pTurboBar], float(PlayerInfo[playerid][pTurbo]));
	UpdateProgressBar(pTextInfo[playerid][pEnergyBar], playerid);
	UpdateProgressBar(pTextInfo[playerid][pTurboBar], playerid);
	
	Vehicle_Missileid[Current_Vehicle[playerid]] = Missile_Special;
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
 	TextDrawColor(pTextInfo[playerid][pMissileSign][0], 0x00FF00FF);
  	for(new m = 1; m < 9; m++)
	{
	    TextDrawColor(pTextInfo[playerid][pMissileSign][m], 100);
        TextDrawShowForPlayer(playerid, pTextInfo[playerid][pMissileSign][m]);
	}
	UpdatePlayerMissileStatus(playerid);
	#if SAMP_03d == (true)
	if(GetVehicleModel(Current_Vehicle[playerid]) == Sweet_Tooth)
	{
	    PlayAudioStreamForPlayer(playerid, "http://lvcnr.net/twisted_metal/SWEETTOOTH_L.wav");
	}
	#endif
	TextDrawLetterSize(pTextInfo[playerid][pHealthBar], 0.000000, -8.600000);
	TextDrawShowForPlayer(playerid, pTextInfo[playerid][pHealthBar]);
	return 1;
}

stock AttachSpecialObjects(playerid)
{
	switch(PlayerInfo[playerid][pCarModel])
	{
	    case Sweet_Tooth:
		{
			if(IsValidObject(PlayerInfo[playerid][pSpecialObject]))
			{
				DestroyObject(PlayerInfo[playerid][pSpecialObject]);
			}
			PlayerInfo[playerid][pSpecialObject] = CreateObject(18691, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
			AttachObjectToVehicle(PlayerInfo[playerid][pSpecialObject], Current_Vehicle[playerid], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
		}
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
    if(total < 0.56)
    {
		total += 0.1;
	}
	else total -= 0.1;
	SetVehicleVelocity(vehicleid, direction[0] * total, direction[1] * total, direction[2] * 0.0);
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

	    vx = floatsin(-va, degrees)*0.4;
	    vy = floatcos(-va, degrees)*0.4;
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

	SetVehicleVelocity(vehicleid, rx*0.5, ry*0.5, rz*0.5); //1.3 = speed multiplier
	return 1;
}

#define BURNOUT_INDEX 0.015

forward BurnoutFunc(playerid, vehicleid);
public BurnoutFunc(playerid, vehicleid)
{
	PlayerInfo[playerid][pBurnout]++;
	new keys, ud, lr;
 	GetPlayerKeys(playerid, keys, ud, lr);
	if(PlayerInfo[playerid][pBurnout] > 10 && keys == 8)//VEHICLE_ACCELERATE
	{
		if(PlayerInfo[playerid][pBurnout] > 30) PlayerInfo[playerid][pBurnout] = 30;
        new Float:speed[2];
        GetXYInFrontOfVehicle(vehicleid, speed[0], speed[1], BURNOUT_INDEX * PlayerInfo[playerid][pBurnout]);
		AccelerateTowardsAPoint(vehicleid, speed[0], speed[1]);
        PlayerInfo[playerid][pBurnout] = 0;
        KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
    }
    if(keys == ( KEY_SPRINT | KEY_JUMP )) return 1;
    if(keys != ( KEY_SPRINT | KEY_JUMP ) && keys != 8)
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
    SendClientMessage(playerid, -1, "~k~~VEHICLE_TURRETUP~ To Scroll Through Next Weapon");
    SendClientMessage(playerid, -1, "~k~~VEHICLE_TURRETDOWN~ To Scroll Through Previous Weapon");
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

stock CalculateMissile(&Float:angle, &Float:x, &Float:y, &Float:z, Float:xCal, Float:yCal, Float:zCal)
{
    z += zCal;

	x += (yCal * floatsin(-angle, degrees));
	y += (yCal * floatcos(-angle, degrees));

	angle += 270.0;
	x += (xCal * floatsin(-angle, degrees));
	y += (xCal * floatcos(-angle, degrees));
	
	angle -= 270.0;
}

#define TURBO_DEDUCT_INDEX 135
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_SPRINT) && (newkeys & KEY_JUMP) && IsPlayerInAnyVehicle(playerid))
    {
        PlayerInfo[playerid][pBurnout]++;
        PlayerInfo[playerid][pBurnoutTimer] = SetTimerEx("BurnoutFunc", 100, true, "ii", playerid, Current_Vehicle[playerid]);
    }
    if (RELEASED( KEY_SPRINT | KEY_JUMP ) && !(newkeys & 8))
    {
        if (IsPlayerInAnyVehicle(playerid) && PlayerInfo[playerid][pBurnout] > 0)
        {
            PlayerInfo[playerid][pBurnout] = 0;
            KillTimer(PlayerInfo[playerid][pBurnoutTimer]);
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
		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && !IsPlayerInvalidNosExcludeBikes(playerid))
  		{
  		    if(PlayerInfo[playerid][pTurbo] <= 0) return 1;
  		    if(PlayerInfo[playerid][Turbo_Tick] == 0)
			{
				PlayerInfo[playerid][Turbo_Tick] = GetTickCount();
			}
			else
			{
				if(GetTickCount() - PlayerInfo[playerid][Turbo_Tick] < 400)
				{
				    new vehicleid = GetPlayerVehicleID(playerid);
					new model = GetVehicleModel(vehicleid);
	    			IncreaseVehicleSpeed(vehicleid, 1.05);
	    			if(IsValidObject(Nitro_Bike_Object[playerid]))
					{
						DestroyObject(Nitro_Bike_Object[playerid]);
					}
					switch(model)
					{
						case 463:
						{
						    new Float:x, Float:y, Float:z;
						    GetPlayerPos(playerid, x, y, z);
						    Nitro_Bike_Object[playerid] = CreateObject(18693, x, y, z + 10, 0.0, 0.0, 0.0, 125.0);
							AttachObjectToVehicle(Nitro_Bike_Object[playerid], vehicleid, 0.164999, 0.909999, -0.379999, 86.429962, 3.645001, 0.000000);
						}
						default: AddVehicleComponent(vehicleid, 1010);
					}
		 			KillTimer(PlayerInfo[playerid][Turbo_Timer]);
		 			PlayerInfo[playerid][Turbo_Timer] = SetTimerEx("Turbo_Deduct", TURBO_DEDUCT_INDEX, true, "i", playerid); //12
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
 			if(IsValidObject(Nitro_Bike_Object[playerid])) DestroyObject(Nitro_Bike_Object[playerid]);
  		}
	}
   	if(PRESSED(KEY_YES))
   	{
   	    cmd_jump(playerid, "");
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
  			FireMissile(playerid, Missile_Machine_Gun);
  			KillTimer(Machine_Gun_Firing_Timer[playerid]);
  			Machine_Gun_Firing_Timer[playerid] = SetTimerEx("FireMissile", 305, true, "ii", playerid, Missile_Machine_Gun);
		}
	}
	if((newkeys & KEY_SUBMISSION) && (newkeys & MISSILE_FIRE_KEY))
	{
	    if(PlayerInfo[playerid][pMissiles][Missile_Special] == 0) return 1;
     	PlayerInfo[playerid][pMissiles][Missile_Special] --;
		CallLocalFunction("FireALTSpecial", "ii", playerid, Missile_Special);
		return 1;
	}
	if((newkeys & MISSILE_FIRE_KEY) == (MISSILE_FIRE_KEY))
   	{
 		new id = GetPlayerVehicleID(playerid);
 		if(PlayerInfo[playerid][pMissile_Special_Charged] == true)
 		{
 			switch(GetVehicleModel(id))
      	    {
      	        case Roadkill:
      	        {
      	            Vehicle_Firing_Missile[id] = 1;
		 			Vehicle_Missile_Special_Slot[id] = 1;
		            for(new i = 1; i != 7; i++)
					{
					    FireMissile(playerid, Missile_Special);
					}
					Vehicle_Missile_Special_Slot[id] = 0;
					PlayerInfo[playerid][pMissile_Special_Time] = 0;
	    			PlayerInfo[playerid][pMissile_Special_Charged] = false;
	    			KillTimer(GetPVarInt(playerid, "Flash_Roadkill_Timer"));
	    			DeletePVar(playerid, "Flash_Roadkill_Timer");
				}
			}
		}
		if(IsValidObject(Vehicle_Missile[id][5]) && Vehicle_Firing_Missile[id] == 1 && Vehicle_Missileid[id] == Missile_Napalm)
		{
		    new slot = 5, Float:x, Float:y, Float:z;
		    Object_Type[Vehicle_Missile[id][slot]] = -1;
		   	GetObjectPos(Vehicle_Missile[id][slot], x, y, z);
			DestroyObject(Vehicle_Missile[id][slot]);
			SetPVarInt(playerid, "Dont_Destroy_Napalm", 1);
			Vehicle_Missile[id][slot] = CreateObject(Missile_Napalm_Object, x, y, z, 0, 0, 0.0, 150.0);
			z = GetMapLowestZ(x, y, z);
		    MoveObject(Vehicle_Missile[id][slot], x, y, z + 0.1, MISSILE_SPEED - 45);
		    DestroyObject(Vehicle_Smoke[id][slot]);
			Object_Owner[Vehicle_Missile[id][slot]] = id;
			Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
			Object_Type[Vehicle_Missile[id][slot]] = Missile_Napalm;
			Object_Slot[Vehicle_Missile[id][slot]] = slot;
			SetPVarInt(playerid, "Dont_Destroy_Napalm", 1);
			GameTextForPlayer(playerid, " ", 1, 3);
	    	return 1;
		}
		new slot, missileid = Vehicle_Missileid[id];
 		if(!Vehicle_Firing_Missile[id])
    	{
         	if(id != INVALID_VEHICLE_ID)
			{
          	    switch(missileid)
          	    {
          	        case Missile_Special:
          	        {
          	            if(PlayerInfo[playerid][pMissiles][Missile_Special] == 0) return 1;
          	            PlayerInfo[playerid][pMissiles][Missile_Special] --;
          	            switch(GetVehicleModel(id))
          	            {
          	                case Junkyard_Dog:
	  						{
	  						    SendClientMessage(playerid, -1, "Special Incomplete");
							  	/*new Float:x, Float:y, Float:z, Float:angle;
				                GetVehiclePos(id, x, y, z);
				                GetVehicleZAngle(id, angle);
				                //Vehicle_Firing_Missile[id] = 1;
				                PlayerInfo[playerid][pSpecial_Missile_Vehicle] = CreateVehicle(420, x, y, z + 10, angle, 0, 0, -1);
								//LinkVehicleToInterior(PlayerInfo[playerid][pSpecial_Missile_Vehicle], INVISIBILITY_INDEX);
				                SetVehicleHealth(PlayerInfo[playerid][pSpecial_Missile_Vehicle], 2500.0);
				                Vehicle_Firing_Missile[PlayerInfo[playerid][pSpecial_Missile_Vehicle]] = 1;
				                PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(3594, x, y, (z + 0.5), 0, 0, angle, 300.0);
				                AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], PlayerInfo[playerid][pSpecial_Missile_Vehicle], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				                AttachTrailerToVehicle(PlayerInfo[playerid][pSpecial_Missile_Vehicle], Current_Vehicle[playerid]);
				                */
								return 1;
							}
          	                case Meat_Wagon:
          	                {
          	                    slot = 0;
          	                    new v = GetClosestVehicle(playerid), Float:x, Float:y, Float:z, Float:a;
		 						Vehicle_Firing_Missile[id] = 1;
			  					if(IsValidObject(Vehicle_Missile[id][0])) DestroyObject(Vehicle_Missile[id][0]);
								if(IsValidObject(Vehicle_Smoke[id][0])) DestroyObject(Vehicle_Smoke[id][0]);

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

				               	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
				              	new Float:y2 = y + (90.0 * floatcos(-a, degrees));//2146 gurney

		                    	Vehicle_Missile[id][0] = CreateObject(2146, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
				               	Vehicle_Smoke[id][0] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

								MoveObject(Vehicle_Missile[id][0], x2, y2, z, MISSILE_SPEED);
								#if SAMP_03d == (false)
                                MoveObject(Vehicle_Smoke[id][0], x2, y2, z - 1.3, MISSILE_SPEED);
                                #else
		          				AttachObjectToObject(Vehicle_Smoke[id][0], Vehicle_Missile[id][0], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
								#endif
		                        KillTimer(Update_Missile_Timer[playerid][0]);
		                        Update_Missile_Timer[playerid][0] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, INVALID_VEHICLE_ID);

								GetVehiclePos(v, x, y, z);
                                if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
	  							{
	  							    GetVehiclePos(v, x, y, z);
	  							    KillTimer(Update_Missile_Timer[playerid][0]);
									Update_Missile_Timer[playerid][0] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, v);
	  							}
	  							else
	  							{
	  							    foreachex(Vehicles, v)
	  							    {
	  							        if(v == id) continue;
	  							        if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
	  							        GetVehiclePos(v, x, y, z);
	  							     	if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
	  									{
	  									    KillTimer(Update_Missile_Timer[playerid][0]);
											Update_Missile_Timer[playerid][0] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, v);
	  									    break;
	  									}
	  							    }
								}
								CallLocalFunction("OnVehicleFire", "iiii", playerid, id, 0, Missile_Special);
          	                    return 1;
          	                }
          	                case Vermin:
          	                {
          	                    slot = 0;
          	                    new v = GetClosestVehicle(playerid), Float:x, Float:y, Float:z, Float:a;
		 						Vehicle_Firing_Missile[id] = 1;
			  					if(IsValidObject(Vehicle_Missile[id][0])) DestroyObject(Vehicle_Missile[id][0]);
								if(IsValidObject(Vehicle_Smoke[id][0])) DestroyObject(Vehicle_Smoke[id][0]);

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

				               	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
				              	new Float:y2 = y + (90.0 * floatcos(-a, degrees));//19315 deer

		                    	Vehicle_Missile[id][0] = CreateObject(19079, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
				               	Vehicle_Smoke[id][0] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

								MoveObject(Vehicle_Missile[id][0], x2, y2, z, MISSILE_SPEED);
								#if SAMP_03d == (false)
                                MoveObject(Vehicle_Smoke[id][0], x2, y2, z - 1.3, MISSILE_SPEED);
                                #else
		          				AttachObjectToObject(Vehicle_Smoke[id][0], Vehicle_Missile[id][0], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
								#endif
		                        KillTimer(Update_Missile_Timer[playerid][0]);
		                        Update_Missile_Timer[playerid][0] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, INVALID_VEHICLE_ID);

								GetVehiclePos(v, x, y, z);
                                if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
	  							{
	  							    GetVehiclePos(v, x, y, z);
	  							    KillTimer(Update_Missile_Timer[playerid][0]);
									Update_Missile_Timer[playerid][0] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, v);
	  							}
	  							else
	  							{
	  							    foreachex(Vehicles, v)
	  							    {
	  							        if(v == id) continue;
	  							        if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
	  							        GetVehiclePos(v, x, y, z);
	  							     	if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
	  									{
	  									    KillTimer(Update_Missile_Timer[playerid][0]);
											Update_Missile_Timer[playerid][0] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, v);
	  									    break;
	  									}
	  							    }
								}
								CallLocalFunction("OnVehicleFire", "iiii", playerid, id, 0, Missile_Special);
          	                    return 1;
						  	}
          	                case Sweet_Tooth:
          	                {
          	                    PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
          	                    Vehicle_Missile_Special_Slot[id] = 0;
          	                    FireMissile(playerid, Missile_Special);
          	                    for(new i = 1; i != 20; i++)
								{
								    SetTimerEx("FireMissile", (i * 225), false, "ii", playerid, Missile_Special);
								}
								Vehicle_Missile_Special_Slot[id] = 0;
								return 1;
          	                }
          	                case Roadkill:
          	                {
          	                    Vehicle_Firing_Missile[id] = 1;
          	                    Vehicle_Missile_Special_Slot[id] = 0;
								KillTimer(Update_Missile_Timer[playerid][0]);
								PlayerInfo[playerid][pMissile_Special_Time] = 0;
								PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
								PlayerInfo[playerid][pMissile_Special_Charged] = false;
                                Update_Missile_Timer[playerid][0] = SetTimerEx("Roadkill_Special", 600, true, "iii", playerid, id, 1);
                                return 1;
          	                }
          	                case Thumper:
							{
							    if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
          	                    {
          	                        DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
          	                        PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
          	                    }
          	                    Vehicle_Firing_Missile[id] = 1;
							    PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(18694, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
								AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], id, 0.0, 2.0, -1.7, 0.0, 0.0, 0.0);
							    PlayerInfo[playerid][pMissile_Special_Time] = 0;
								KillTimer(Update_Missile_Timer[playerid][0]);
                                Update_Missile_Timer[playerid][0] = SetTimerEx("Thumper_Special", 100, true, "ii", playerid, id);
                                return 1;
							}
							case Reaper:
							{
							    slot = 0;
							    new Float:x, Float:y, Float:z, Float:a;
		 						Vehicle_Firing_Missile[id] = 1;
			  					
		     					if(IsValidObject(Vehicle_Missile[id][0])) DestroyObject(Vehicle_Missile[id][0]);
								if(IsValidObject(Vehicle_Smoke[id][0])) DestroyObject(Vehicle_Smoke[id][0]);
								Vehicle_Smoke[id][0] = INVALID_OBJECT_ID;

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);
		      					
		                      	CalculateMissile(a, x, y, z, 0.0, 0.0, 1.0);

				               	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
				              	new Float:y2 = y + (90.0 * floatcos(-a, degrees));

		                    	Vehicle_Missile[id][0] = CreateObject(341, x, y, z, 0, 0, 95.0, 300.0);//1736 attach to front
                                Vehicle_Smoke[id][0] = CreateObject(18690, x, y, z - 1.3, 0, 0, 0, 300.0);

								MoveObject(Vehicle_Missile[id][0], x2, y2, z, MISSILE_SPEED);
								#if SAMP_03d == (false)
                                MoveObject(Vehicle_Smoke[id][0], x2, y2, z - 1.3, MISSILE_SPEED);
                                #else
		          				AttachObjectToObject(Vehicle_Smoke[id][0], Vehicle_Missile[id][0], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
								#endif
		                        KillTimer(Update_Missile_Timer[playerid][0]);
				              	Update_Missile_Timer[playerid][0] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, INVALID_VEHICLE_ID);

				              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, 0, Missile_Special);
							}
          	                case Brimstone: //3092 - dead body
          	                {
          	                    slot = 0;
		     					new Float:x, Float:y, Float:z, Float:a;
		 						Vehicle_Firing_Missile[id] = 1;
			  					if(IsValidObject(Vehicle_Missile[id][0])) DestroyObject(Vehicle_Missile[id][0]);

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(a, x, y, z, 0.0, 2.0, 1.3);

				               	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
				              	new Float:y2 = y + (90.0 * floatcos(-a, degrees));

		                    	Vehicle_Missile[id][0] = CreateObject(3092, x, y, z, 0, 0, 95.0, 300.0);

								MoveObject(Vehicle_Missile[id][0], x2, y2, z, MISSILE_SPEED);
								
		                        KillTimer(Update_Missile_Timer[playerid][0]);
				              	Update_Missile_Timer[playerid][0] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, INVALID_VEHICLE_ID);

				              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, 0, Missile_Special);
							}
          	                case Spectre:
          	                {
          	                    slot = 0;
          	                    new v = GetClosestVehicle(playerid), Float:x, Float:y, Float:z, Float:a;
		 						Vehicle_Firing_Missile[id] = 1;
			  					if(IsValidObject(Vehicle_Missile[id][0])) DestroyObject(Vehicle_Missile[id][0]);
								if(IsValidObject(Vehicle_Smoke[id][0])) DestroyObject(Vehicle_Smoke[id][0]);

								GetVehicleZAngle(id, a);
		      					GetVehiclePos(id, x, y, z);

		                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

				               	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
				              	new Float:y2 = y + (90.0 * floatcos(-a, degrees));

		                    	Vehicle_Missile[id][0] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
				               	Vehicle_Smoke[id][0] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

								MoveObject(Vehicle_Missile[id][0], x2, y2, z, MISSILE_SPEED);
								#if SAMP_03d == (false)
                                MoveObject(Vehicle_Smoke[id][0], x2, y2, z - 1.3, MISSILE_SPEED);
                                #else
		          				AttachObjectToObject(Vehicle_Smoke[id][0], Vehicle_Missile[id][0], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
								#endif
		                        KillTimer(Update_Missile_Timer[playerid][0]);
		                        Update_Missile_Timer[playerid][0] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, INVALID_VEHICLE_ID);

								GetVehiclePos(v, x, y, z);
                                if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
	  							{
	  							    GetVehiclePos(v, x, y, z);
	  							    KillTimer(Update_Missile_Timer[playerid][0]);
									Update_Missile_Timer[playerid][0] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, v);
	  							}
	  							else
	  							{
	  							    foreachex(Vehicles, v)
	  							    {
	  							        if(v == id) continue;
	  							        if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
	  							        GetVehiclePos(v, x, y, z);
	  							     	if( IsPlayerAimingAt(playerid, x, y, z, 25.0) || IsPlayerFacingVehicleEx(playerid, v, 10.0) || IsVehicleStreamedIn(v, playerid))
	  									{
	  									    KillTimer(Update_Missile_Timer[playerid][0]);
											Update_Missile_Timer[playerid][0] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][0], Missile_Special, 0, v);
	  									    break;
	  									}
	  							    }
								}
								CallLocalFunction("OnVehicleFire", "iiii", playerid, id, 0, Missile_Special);
							}
          	                case Darkside:
          	                {
          	                    Vehicle_Firing_Missile[id] = 1;
          	                    new Float:currspeed[3], Float:direction[3], Float:total;
								GetVehicleVelocity(id, currspeed[0], currspeed[1], currspeed[2]);
								total = floatsqroot((currspeed[0] * currspeed[0]) + (currspeed[1] * currspeed[1]) + (currspeed[2] * currspeed[2]));
								total += 1.1;
								new Float:invector[3] = {0.0, -1.0, 0.0};
								RotatePointVehicleRotation(id, invector, direction[0], direction[1], direction[2]);
								SetVehicleVelocity(id, direction[0] * total, direction[1] * total, direction[2] * total);
								SetTimerEx("ReturnDarksidesSpeed", 1100, false, "dfff", id, currspeed[0], currspeed[1], currspeed[2]);
								return 1;
          	                }
          	                case Outlaw: //2985 0.0 -0.5 0.4 0.0 0.0 90.0//mounted minigun
          	                {
          	                    slot = 0;
          	                    if(IsValidObject(PlayerInfo[playerid][pSpecial_Missile_Object]))
          	                    {
          	                        DestroyObject(PlayerInfo[playerid][pSpecial_Missile_Object]);
          	                        PlayerInfo[playerid][pSpecial_Missile_Object] = INVALID_OBJECT_ID;
          	                    }
          	                    Vehicle_Firing_Missile[id] = 1;
          	                    KillTimer(Update_Missile_Timer[playerid][0]);
          	                    PlayerInfo[playerid][pMissile_Special_Time] = 0;
								//362 0.1 -0.5 1.5 0.0 30.0 95.0//minigun model id
								PlayerInfo[playerid][pSpecial_Missile_Object] = CreateObject(362, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 125.0);
								AttachObjectToVehicle(PlayerInfo[playerid][pSpecial_Missile_Object], id, 0.1, -0.5, 1.5, 0.0, 30.0, 95.0);
								Update_Missile_Timer[playerid][0] = SetTimerEx("Outlaw_Special", 200, true, "ii", playerid, id);
								return 1;
							}
          	            }
          	        }
          	        case Missile_Fire:
          	        {
						if(PlayerInfo[playerid][pMissiles][Missile_Fire] == 0) return 1;
						PlayerInfo[playerid][pMissiles][Missile_Fire] --;
						slot = 0;
						new Float:x, Float:y, Float:z, Float:a;
 						Vehicle_Firing_Missile[id] = 1;
	  					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);
						if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);

						GetVehicleZAngle(id, a);
      					GetVehiclePos(id, x, y, z);
                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);
                      	
		              	new Float:x2, Float:y2, Float:z2, Float:bank;
						GetVehicleRotation(id, x2, y2, bank);
						GetVehiclePos(id, x2, y2, z2);
						GetXYZOfVehicle(id, x2, y2, z2, bank, 90.0);
						
						new Float:vx, Float:vy, Float:vz, Float:distance;
		                GetVehicleVelocity(id, vx, vy, vz);
		                distance = floatsqroot(vx * vx + vy * vy + vz * vz);
		                distance += distance + VehicleOffsetY[id];
		                if((VehicleOffsetY[id] + 0.5) > distance) distance -= 0.5;
						x += (distance * floatsin(-a, degrees));
                      	y += (distance * floatcos(-a, degrees));
                      	
						Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), bank, 0, (a - 90), 300.0);
						Vehicle_Smoke[id][slot] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

						MoveObject(Vehicle_Missile[id][slot], x2, y2, (z - 1.0), MISSILE_SPEED);
						#if SAMP_03d == (false)
                        MoveObject(Vehicle_Smoke[id][slot], x2, y2, z - 1.3, MISSILE_SPEED);
                        #else
  						AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
						#endif
                        KillTimer(Update_Missile_Timer[playerid][slot]);
                        Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Fire, slot, INVALID_VEHICLE_ID);
						foreach(Vehicles, v)
     					{
     					    if(v == id) continue;
     					    if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
		                 	GetVehiclePos(v, x, y, z);
		                 	if(IsVehicleStreamedIn(v, playerid) && IsPlayerAimingAt(playerid, x, y, z, 30.0))
							{
							    KillTimer(Update_Missile_Timer[playerid][slot]);
								Update_Missile_Timer[playerid][slot] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Fire, slot, v);
								break;
							}
						}
						SendClientMessageFormatted(playerid, -1, "Vehicle_Missile: %d", Vehicle_Missile[id][slot]);
		              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, slot, Missile_Fire);
					}
         			case Missile_Homing:
          	        {
						if(PlayerInfo[playerid][pMissiles][Missile_Homing] == 0) return 1;
						PlayerInfo[playerid][pMissiles][Missile_Homing] --;
						slot = 0;
						new Float:x, Float:y, Float:z, Float:a;
 						Vehicle_Firing_Missile[id] = 1;
	  					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);
						if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
						if(IsValidObject(Vehicle_Missile_Light[id][slot])) DestroyObject(Vehicle_Missile_Light[id][slot]);

						GetVehicleZAngle(id, a);
      					GetVehiclePos(id, x, y, z);
      					
                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

		               	new Float:x2 = x + (90.0 * floatsin(-a, degrees));
		              	new Float:y2 = y + (90.0 * floatcos(-a, degrees));
		              	
		              	new Float:vx, Float:vy, Float:vz, Float:distance;
		                GetVehicleVelocity(id, vx, vy, vz);
		                distance = floatsqroot(vx * vx + vy * vy + vz * vz);
		                distance += distance + VehicleOffsetY[id];
		                if((VehicleOffsetY[id] + 0.5) > distance) distance -= 0.5;
						x += (distance * floatsin(-a, degrees));
                      	y += (distance * floatcos(-a, degrees));

                    	Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
                        Vehicle_Missile_Light[id][slot] = CreateObject(18651, x, y, z, 0, 0, (270.0), 300.0);//purple neonlight
						Vehicle_Smoke[id][slot] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

						MoveObject(Vehicle_Missile[id][slot], x2, y2, (z - 1.0), MISSILE_SPEED);
						#if SAMP_03d == (false)
						MoveObject(Vehicle_Missile_Light[id][slot], x2, y2, z, MISSILE_SPEED + 0.50);
		              	MoveObject(Vehicle_Smoke[id][slot], x2, y2, z - 1.3, MISSILE_SPEED);
		              	#else
		              	AttachObjectToObject(Vehicle_Missile_Light[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (270.0), 1);
  						AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
						#endif
                        KillTimer(Update_Missile_Timer[playerid][slot]);
                        Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Homing, slot, INVALID_VEHICLE_ID);
                        foreach(Vehicles, v)
     					{
     					    if(v == id) continue;
     					    if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
		                 	GetVehiclePos(v, x, y, z);
		                 	if(IsVehicleStreamedIn(v, playerid) && IsPlayerAimingAt(playerid, x, y, z, 25.0) && !IsPlayerInVehicle(playerid, v))
							{
							    KillTimer(Update_Missile_Timer[playerid][slot]);
								Update_Missile_Timer[playerid][slot] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Homing, slot, v);
								break;
							}
		              	}
		              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, slot, Missile_Homing);
					}
          	      	case Missile_Power:
          	        {
						if(PlayerInfo[playerid][pMissiles][Missile_Power] == 0) return 1;
						PlayerInfo[playerid][pMissiles][Missile_Power] --;
						slot = 0;
						new Float:x, Float:y, Float:z, Float:a;
 						Vehicle_Firing_Missile[id] = 1;
 						
	  					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);
                        if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
                        if(IsValidObject(Vehicle_Missile_Light[id][slot])) DestroyObject(Vehicle_Missile_Light[id][slot]);

						GetVehicleZAngle(id, a);
      					GetVehiclePos(id, x, y, z);

                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

		               	new Float:x2, Float:y2, Float:z2, Float:bank;
						GetVehicleRotation(id, x2, y2, bank);
						GetVehiclePos(id, x2, y2, z2);
						GetXYZOfVehicle(id, x2, y2, z2, bank, 90.0);
		              	
		              	new Float:vx, Float:vy, Float:vz, Float:distance;
		                GetVehicleVelocity(id, vx, vy, vz);
		                distance = floatsqroot(vx * vx + vy * vy + vz * vz);
		                distance += distance + VehicleOffsetY[id];
		                if((VehicleOffsetY[id] + 0.5) > distance) distance -= 0.5;
						x += (distance * floatsin(-a, degrees));
                      	y += (distance * floatcos(-a, degrees));

                    	Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
                        Vehicle_Missile_Light[id][slot] = CreateObject(18647, x, y, z, 0, 0, (270.0), 300.0);//red neonlight
						Vehicle_Smoke[id][slot] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

						MoveObject(Vehicle_Missile[id][slot], x2, y2, (z - 1.0), MISSILE_SPEED);
						#if SAMP_03d == (false)
						MoveObject(Vehicle_Missile_Light[id][slot], x2, y2, z, MISSILE_SPEED + 0.50);
		              	MoveObject(Vehicle_Smoke[id][slot], x2, y2, z - 1.3, MISSILE_SPEED);
		              	#else
  						AttachObjectToObject(Vehicle_Missile_Light[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (270.0), 1);
                    	AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
		              	#endif
                        KillTimer(Update_Missile_Timer[playerid][slot]);
                        
		              	Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Power, slot, INVALID_VEHICLE_ID);
		              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, slot, Missile_Power);
					}
					case Missile_Napalm:
          	        {
          	            if(PlayerInfo[playerid][pMissiles][Missile_Napalm] == 0) return 1;
          	            PlayerInfo[playerid][pMissiles][Missile_Napalm]--;
          	            slot = 5;
          	        	new Float:x, Float:y, Float:z, Float:a;
						Vehicle_Firing_Missile[id] = 1;
						
     					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);

						GetVehiclePos(id, x, y, z);
    					GetVehicleZAngle(id, a);

						a += 90;
		               	z += VehicleOffsetZ[id];

		               	x += (VehicleOffsetX[id] * floatsin(-a, degrees));
		               	y += (VehicleOffsetX[id] * floatcos(-a, degrees));

		               	Vehicle_Missile[id][slot] = CreateObject(Missile_Napalm_Object, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, a + 180, 150.0);
		               	Vehicle_Smoke[id][slot] = CreateObject(18690, x, y, z - 1.3, 0, 0, 0, 150.0);
                       	a += 270;
		               	z += (2.5 * floatsin(-a, degrees));

		               	MoveObject(Vehicle_Missile[id][slot], x, y, z, MISSILE_SPEED + 15);

		               	x += (65 * floatsin(-a, degrees));
		               	y += (65 * floatcos(-a, degrees));

		               	MoveObject(Vehicle_Missile[id][slot], x, y, z + 4.5, MISSILE_SPEED - 20);
		               	#if SAMP_03d == (false)
		               	MoveObject(Vehicle_Smoke[id][slot], x, y, z + 4.5 - 1.3, MISSILE_SPEED - 20);
		               	#else
		               	AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
						#endif
                        KillTimer(Update_Missile_Timer[playerid][slot]);
		               	Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Napalm, slot, INVALID_VEHICLE_ID);

		              	new engine, lights, alarm, doors, bonnet, boot, objective;
						GetVehicleParamsEx(id, engine, lights, alarm, doors, bonnet, boot, objective);
						SetVehicleParamsEx(id, engine, lights, alarm, doors, bonnet, VEHICLE_PARAMS_OFF, objective);
                        SendClientMessageFormatted(playerid, -1, "Napalm Vehicle_Missile: %d", Vehicle_Missile[id][slot]);
						CallLocalFunction("OnVehicleFire", "iiii", playerid, id, slot, Missile_Napalm);
					}
					case Missile_Stalker:
          	        {
						if(PlayerInfo[playerid][pMissiles][Missile_Stalker] == 0) return 1;
						PlayerInfo[playerid][pMissiles][Missile_Stalker] --;
						slot = 0;
						new Float:x, Float:y, Float:z, Float:a;
 						Vehicle_Firing_Missile[id] = 1;
 						
	  					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);
						if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);

						GetVehicleZAngle(id, a);
      					GetVehiclePos(id, x, y, z);

                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);
		              	
		              	new Float:vx, Float:vy, Float:vz, Float:distance;
		                GetVehicleVelocity(id, vx, vy, vz);
		                distance = floatsqroot(vx * vx + vy * vy + vz * vz);
		                distance += distance + VehicleOffsetY[id];
		                if((VehicleOffsetY[id] + 0.5) > distance) distance -= 0.5;
						x += (distance * floatsin(-a, degrees));
                      	y += (distance * floatcos(-a, degrees));

		              	new Float:x2, Float:y2, Float:z2, Float:bank;
						GetVehicleRotation(id, x2, y2, bank);
						GetVehiclePos(id, x2, y2, z2);
						GetXYZOfVehicle(id, x2, y2, z2, bank, 90.0);

						Vehicle_Missile[id][slot] = CreateObject(Missile_Default_Object, x, y, (z + GetVehicleMissileZOffset(id)), bank, 0, (a - 90), 300.0);
						Vehicle_Smoke[id][slot] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

						MoveObject(Vehicle_Missile[id][slot], x2, y2, (z - 1.0), MISSILE_SPEED);
						#if SAMP_03d == (false)
                        MoveObject(Vehicle_Smoke[id][slot], x2, y2, z - 1.3, MISSILE_SPEED);
                        #else
  						AttachObjectToObject(Vehicle_Smoke[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
						#endif
                        KillTimer(Update_Missile_Timer[playerid][slot]);
                        Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Stalker, slot, INVALID_VEHICLE_ID);
						foreach(Vehicles, v)
     					{
     					    if(v == id) continue;
     					    if(GetVehicleInterior(v) == INVISIBILITY_INDEX) continue;
		                 	GetVehiclePos(v, x, y, z);
		                 	if(IsVehicleStreamedIn(v, playerid) && IsPlayerAimingAt(playerid, x, y, z, 30.0))
							{
							    KillTimer(Update_Missile_Timer[playerid][slot]);
								Update_Missile_Timer[playerid][slot] =  SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Stalker, slot, v);
								break;
							}
						}
		              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, slot, Missile_Stalker);
					}
					case Missile_Ricochet:
          	        {
						if(PlayerInfo[playerid][pMissiles][Missile_Ricochet] == 0) return 1;
						PlayerInfo[playerid][pMissiles][Missile_Ricochet] --;
						slot = 0;
						new Float:x, Float:y, Float:z, Float:a;
 						
	  					if(IsValidObject(Vehicle_Missile[id][slot])) DestroyObject(Vehicle_Missile[id][slot]);
                        if(IsValidObject(Vehicle_Missile_Light[id][slot])) DestroyObject(Vehicle_Missile_Light[id][slot]);

						GetVehicleZAngle(id, a);
      					GetVehiclePos(id, x, y, z);

                      	CalculateMissile(a, x, y, z, VehicleOffsetX[id], VehicleOffsetY[id], VehicleOffsetZ[id]);

		               	new Float:x2 = x + (150.0 * floatsin(-a, degrees));
		              	new Float:y2 = y + (150.0 * floatcos(-a, degrees));

		              	new Float:vx, Float:vy, Float:vz, Float:distance;
		                GetVehicleVelocity(id, vx, vy, vz);
		                distance = floatsqroot(vx * vx + vy * vy + vz * vz);
		                distance += distance + VehicleOffsetY[id];
		                if((VehicleOffsetY[id] + 0.5) > distance) distance -= 0.5;
						x += (distance * floatsin(-a, degrees));
                      	y += (distance * floatcos(-a, degrees));

                    	Vehicle_Missile[id][slot] = CreateObject(1087, x, y, (z + GetVehicleMissileZOffset(id)), 0, 0, (a - 90), 300.0);
                        Vehicle_Missile_Light[id][slot] = CreateObject(18648, x, y, z, 0, 0, (270.0), 300.0);//blue neonlight

						MoveObject(Vehicle_Missile[id][slot], x2, y2, (z - 1.0), MISSILE_SPEED);
						#if SAMP_03d == (false)
						MoveObject(Vehicle_Missile_Light[id][slot], x2, y2, z, MISSILE_SPEED + 0.50);
		              	#else
  						AttachObjectToObject(Vehicle_Missile_Light[id][slot], Vehicle_Missile[id][slot], 0.0, 0.0, 0.0, 0.0, 0.0, (270.0), 1);
                    	#endif
                        KillTimer(Update_Missile_Timer[playerid][slot]);

		              	Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, id, Vehicle_Missile[id][slot], Missile_Ricochet, slot, INVALID_VEHICLE_ID);
		              	SetPVarInt(playerid, "Ricochet_Missile_Timer", SetTimerEx("Explode_Missile", 10000, false, "ddd", id, slot, Missile_Ricochet));
		              	CallLocalFunction("OnVehicleFire", "iiii", playerid, id, slot, Missile_Ricochet);
					}
					case Missile_Environmentals:
          	        {
          	            if(Vehicle_Using_Environmental[id] == 1) return 1;
          	            if(PlayerInfo[playerid][pMissiles][Missile_Environmentals] == 0) return 1;
          	            PlayerInfo[playerid][pMissiles][Missile_Environmentals]--;
          	            StartEnvironmentalEvent(playerid);
          	            UpdatePlayerMissileStatus(playerid);
          	            return 1;
					}
	         	}
	         	Object_Owner[Vehicle_Missile[id][slot]] = id;
		      	Object_OwnerEx[Vehicle_Missile[id][slot]] = playerid;
		      	Object_Type[Vehicle_Missile[id][slot]] = missileid;
		      	Object_Slot[Vehicle_Missile[id][slot]] = slot;
			}
     	}
  	}
  	if(PRESSED(KEY_SPRINT) && PlayerInfo[playerid][pSelection] == 1)
	{
	    TwistedSpawnPlayer(playerid);
	}
	if(PRESSED(KEY_ANALOG_DOWN) || HOLDING(KEY_ANALOG_DOWN))
   	{
   	    new id = GetPlayerVehicleID(playerid), oldmissile = Vehicle_Missileid[id];
   	    Vehicle_Missileid[id] = GetNextMissileSlot(playerid, id);
   	    CallLocalFunction("OnVehicleMissileChange", "iiii", id, oldmissile, Vehicle_Missileid[id], playerid);
   	}
   	if(PRESSED(KEY_ANALOG_UP) || HOLDING(KEY_ANALOG_UP))
   	{
   	    new id = GetPlayerVehicleID(playerid), oldmissile = Vehicle_Missileid[id];
   	    Vehicle_Missileid[id] = GetPreviousMissileSlot(playerid, id);
   	    CallLocalFunction("OnVehicleMissileChange", "iiii", id, oldmissile, Vehicle_Missileid[id], playerid);
   	}
	return 1;
}

stock StartEnvironmentalEvent(playerid)
{
    new vehicleid = GetPlayerVehicleID(playerid);
    Vehicle_Using_Environmental[vehicleid] = 1;
    Vehicle_Environmental_Slot[vehicleid] = ENVIRONMENTAL_START_SLOT;
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
		    new Float:a, slot = Vehicle_Environmental_Slot[vehicleid];
			
		    if(IsValidObject(Vehicle_Missile[vehicleid][slot])) DestroyObject(Vehicle_Missile[vehicleid][slot]);
			if(IsValidObject(Vehicle_Smoke[vehicleid][slot])) DestroyObject(Vehicle_Smoke[vehicleid][slot]);
			
		    GetObjectRot(HelicopterAttack, a, a, a);

		    Vehicle_Missile[vehicleid][slot] = CreateObject(Missile_Default_Object, x, y, (z + 0.3), 0, 0, (a - 90), 300.0);
		   	Vehicle_Smoke[vehicleid][slot] = CreateObject(18731, x, y, z - 1.3, 0, 0, 0, 300.0);

			MoveObject(Vehicle_Missile[vehicleid][slot], vx, vy, z, MISSILE_SPEED);
		  	#if SAMP_03d == (true)
			AttachObjectToObject(Vehicle_Smoke[vehicleid][slot], Vehicle_Missile[vehicleid][slot], 0.0, 0.0, -1.3, 0.0, 0.0, 0.0, 0);
			#endif
		    SetObjectFaceCoords3D(HelicopterAttack, vx, vy, vz, 0.0, 11.0, 180.0);//22.0, 11.0, 180.0
		    KillTimer(Update_Missile_Timer[playerid][slot]);
			Update_Missile_Timer[playerid][slot] = SetTimerEx("UpdateMissile", Missile_Update_Index, true, "dddddd", playerid, vehicleid, Vehicle_Missile[vehicleid][slot], Missile_Environmentals, slot, v);
            SendClientMessageFormatted(playerid, -1, "Environmental Vehicle_Missile: %d", Vehicle_Missile[vehicleid][slot]);
			CallLocalFunction("OnVehicleFire", "iiii", INVALID_PLAYER_ID, vehicleid, slot, Missile_Environmentals);
			Vehicle_Environmental_Slot[vehicleid] ++;
			if(Vehicle_Environmental_Slot[vehicleid] >= MAX_MISSILE_SLOTS)
			{
			    Vehicle_Environmental_Slot[vehicleid] = ENVIRONMENTAL_START_SLOT;
			}
			break;
		}
  	}
	if(GetPVarInt(playerid, "EnvironmentalCycle") > 12 || Vehicle_Missile_Special_Slot[vehicleid] > 12)
	{
	    DeletePVar(playerid, "EnvironmentalCycle");
	    Vehicle_Using_Environmental[vehicleid] = 0;
	    Vehicle_Environmental_Slot[vehicleid] = 0;
	    KillTimer(PlayerInfo[playerid][EnvironmentalCycle_Timer]);
	}
	return 1;
}

forward Float:GetVehicleMissileZOffset(id);
stock Float:GetVehicleMissileZOffset(id)
{
	new model = GetVehicleModel(id), Float:offset = 0.3;
	switch(model)
	{
	    case Junkyard_Dog: offset = 0.5;
		case Brimstone: offset = 0.3;
		case Outlaw: offset = 0.6;
		case Reaper: offset = 0.1;
		case Roadkill: offset = 0.3;
		case Thumper: offset = 0.3;
		case Spectre: offset = 0.3;
		case Darkside: offset = 0.8;
		case Shadow, Meat_Wagon: offset = 0.4;
		case Vermin: offset = 0.6;
		case ManSalughter: offset = 0.5;
		case Sweet_Tooth: offset = 0.2;
	}
	return offset;
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

forward Float:GetMissileDamage(missileid, &vehicleid, alt_weapon = 0);
stock Float:GetMissileDamage(missileid, &vehicleid, alt_weapon = 0)
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
					case Outlaw: damage = 3.0;
					case Reaper: damage = 65.0;
					case Roadkill: damage = 25.0;
					case Thumper: damage = 2.5;
					case Spectre: damage = 45.0;
					case Darkside: damage = 0.0;
					case Shadow: 
					{
					    switch(alt_weapon)
					    {
					        case 1: damage = 70.0;
							default: damage = 60.0;
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
					case ManSalughter: damage = 10.0;
					case Sweet_Tooth: damage = 5.0;
					default: damage = 0.0;
			    }
		    }
		}
	    case Missile_Fire: damage = 16.0;
	    case Missile_Homing, Missile_Environmentals: damage = 12.0;
	    case Missile_Power: damage = 75.0;
	    case Missile_Napalm: damage = 35.0;
	    case Missile_Stalker: damage = 45.0;
	    case Missile_Machine_Gun: damage = 2.0;
	    case Missile_Machine_Gun_Upgrade: damage = 5.0;
	    case Missile_RemoteBomb: damage = 1.0;
	    case Missile_EMP: damage = 5.0;
	    default: damage = 1.0;
	}
	return damage;
}

forward OnBrimstoneFollowerHitToVehicle(playerid, vehicleid, vehicle, FollowerObject, Float:x, Float:y, Float:z);
public OnBrimstoneFollowerHitToVehicle(playerid, vehicleid, vehicle, FollowerObject, Float:x, Float:y, Float:z)
{
	//SendClientMessageFormatted(playerid, -1, "[System: OnBrimstoneFollowerHitToVehicle] - vehicle hit: %d - objectid: %d", vehicle, FollowerObject);
    FollowerObject = CreateObject(3092, x, y, z, 0.0, 0.0, 95.0, 250.0);
    AttachObjectToVehicle(FollowerObject, vehicle, 0.0, 0.0, 0.7, 0.0, 0.0, 95.0);
    SetTimerEx("FinishBrimstoneHit", 2500, false, "iiii", playerid, vehicleid, vehicle, FollowerObject);
	Vehicle_Firing_Missile[vehicleid] = 0;
 	KillTimer(Update_Missile_Timer[playerid][0]);
 	return 1;
}

forward FinishBrimstoneHit(playerid, myvid, vehicle, objectid);
public FinishBrimstoneHit(playerid, myvid, vehicle, objectid)
{
    SendClientMessageFormatted(playerid, -1, "[System: FinishBrimstoneHit] - vehicle hit: %d - objectid: %d", vehicle, objectid);
    new Float:x, Float:y, Float:z;
	DestroyObject(objectid);//GetObjectPos(objectid, x, y, z);
	DamagePlayer(myvid, vehicle, GetMissileDamage(Missile_Special, myvid), Missile_Special);
	GetVehiclePos(objectid, x, y, z);
	z += 0.8;
    Vehicle_Smoke[myvid][0] = CreateObject(18683, x, y, z, 0.0, 0.0, 0.0, 300.0);
    SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[myvid][0], INVALID_PLAYER_ID);
	return 1;
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
	printf("[System: OnObjectMoved] - objectid: %d - missile: %s - vowner: %d - powner: %d", objectid, GetTwistedMissileName(Object_Type[objectid], objectid), Object_Owner[objectid], Object_OwnerEx[objectid]);
	new vehicleid = Object_Owner[objectid], playerid = Object_OwnerEx[objectid], missileid = Object_Type[objectid], slot = Object_Slot[objectid];
	new Float:x, Float:y, Float:z, Float: vX, Float: vY, Float: vZ, Float: oX, Float: oY, Float: oZ;
    GetObjectPos(objectid, oX, oY, oZ);
	if(vehicleid != INVALID_VEHICLE_ID)
	{
	    switch(Object_Type[objectid])
	    {
	        case Missile_Homing:
	        {
	            foreach(Vehicles, v)
				{
				    if(vehicleid == v) continue;
				    if(!GetVehiclePos(v, vX, vY, vZ)) continue;
					new Float:abetweenobjectandvehicle = Angle2D( oX, oY, vX, vY );
			 	    MPClamp360(abetweenobjectandvehicle);
			 	    oX += ( (MissileYSize() * 2) * floatsin( -abetweenobjectandvehicle, degrees ) );
		   			oY += ( (MissileYSize() * 2) * floatcos( -abetweenobjectandvehicle, degrees ) );
		   			x = oX;
			 	    y = oY;
			 	    z = oZ;
					oX -= vX;
					oY -= vY;
					oZ -= vZ;
					GetVehicleSize(GetVehicleModel(v), vX, vY, vZ);
					vX *= 0.6;
				 	vY *= 0.6;
				 	vZ *= 0.7;
				 	new Float:tindex = ((oX * oX) + (oY * oY) + (oZ * oZ));
					if((-vX < oX < vX) && (-vY < oY < vY) && (-vZ < oZ < vZ) || tindex < (2.0 * 2.0))
					{
						if(IsValidObject(Vehicle_Missile[vehicleid][0]))
						{
							DestroyObject(Vehicle_Missile[vehicleid][0]);
						}
						if(IsValidObject(Vehicle_Missile_Light[vehicleid][0]))
						{
							DestroyObject(Vehicle_Missile_Light[vehicleid][0]);
						}
				        if(IsValidObject(Vehicle_Smoke[vehicleid][0]))
						{
							DestroyObject(Vehicle_Smoke[vehicleid][0]);
						}
						Vehicle_Smoke[vehicleid][0] = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
						DamagePlayer(vehicleid, v, GetMissileDamage(missileid, vehicleid), missileid);
				        Vehicle_Firing_Missile[vehicleid] = 0;
				        KillTimer(Update_Missile_Timer[playerid][0]);
				        SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[vehicleid][0], playerid);
				        break;
					}
				}
			}
			case Missile_Fire, Missile_Power: Vehicle_Firing_Missile[Object_Owner[objectid]] = 0;
	        case Missile_Napalm:
	        {
	            new destroynapalm = GetPVarInt(Object_OwnerEx[objectid], "Dont_Destroy_Napalm");
				if(destroynapalm == 1)
				{
		            GetObjectPos(objectid, x, y, z);
			        slot = 5;
			        Vehicle_Smoke[vehicleid][slot] = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
					RadiusDamage(vehicleid, GetMissileDamage(missileid, vehicleid), missileid, 8.0);
			        Vehicle_Firing_Missile[vehicleid] = 0;
			        KillTimer(Update_Missile_Timer[playerid][slot]);
			        DestroyObject(objectid);
			        SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[vehicleid][slot], playerid);
                    SetPVarInt(Object_OwnerEx[objectid], "Dont_Destroy_Napalm", 0);
					Object_Owner[objectid] = INVALID_VEHICLE_ID;
				 	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
				 	Object_Type[objectid] = -1;
				 	Object_Slot[objectid] = -1;
				 	return 1;
			 	}
	        }
        }
	}
	if(Object_Owner[objectid] != INVALID_VEHICLE_ID)
	{
		switch(Object_Type[objectid])
		{
		    case Missile_Machine_Gun:
		    {
		        if(Object_Slot[objectid] != -1)
		        {
		        	DestroyObject(Vehicle_Machine_Gun[vehicleid][Object_Slot[objectid]]);
		        	KillTimer(Update_Machine_Gun_Timer[playerid][Object_Slot[objectid]]);
		        }
		    }
		    case Missile_Ricochet: {}
		    default: CallLocalFunction("Explode_Missile", "iii", vehicleid, slot, missileid);
		}
    	Vehicle_Firing_Missile[Object_OwnerEx[objectid]] = 0;
	}
	Object_Owner[objectid] = INVALID_VEHICLE_ID;
 	Object_OwnerEx[objectid] = INVALID_PLAYER_ID;
 	Object_Type[objectid] = -1;
 	Object_Slot[objectid] = -1;
	return 1;
}

CMD:rd(playerid, params[])
{
    DamagePlayer(Current_Vehicle[playerid], Current_Vehicle[playerid], 5.0, Missile_Special);
	return 1;
}

stock RadiusDamage(vehicleid, Float:maxdamage, missileid, Float:radius)
{
	new Float:pdist, Float:radiussquare = radius * radius, Float:damage, Float:x, Float:y, Float:z;
    foreach(Vehicles, v)
    {
		pdist = GetVehicleDistanceFromPoint(v, x, y, z);
        if(pdist > radiussquare) continue;
        pdist = floatsqroot(pdist);
        damage = (1 - (pdist / radius)) * maxdamage;
        DamagePlayer(vehicleid, v, damage, missileid);
        printf("[System: RadiusDamage] - damage: %0.2f - pdist: %0.2f - radius: %0.2f", damage, pdist, radius);
	}
	return 1;
}

stock DamagePlayer(id, vehicleid, Float:amount, missileid)
{
	new Float:health;
	T_GetVehicleHealth(vehicleid, health);
	//amount *= TwistedDamageMultiplier(GetVehicleModel(vehicleid));
	new Float:newhealth = (health - amount);
	T_SetVehicleHealth(vehicleid, newhealth);
	new str[32], playerid = MPGetVehicleDriver(id);
	switch(missileid)
	{
	    case Missile_Special:
	    {
     		format(str, sizeof(str), "%s %d damage", GetTwistedMissileName(missileid, id, true), floatround(amount));
	    }
	    case Missile_Fire..Missile_Napalm:
	    {
			format(str, sizeof(str), "%s Missile hit %d damage", GetTwistedMissileName(missileid, id), floatround(amount));
		}
		case Missile_Machine_Gun: format(str, sizeof(str), "%s %d damage", GetTwistedMissileName(missileid, id), floatround(amount));
	}
	if(playerid != INVALID_PLAYER_ID)
	{
		TimeTextForPlayer( TIMETEXT_TOP, playerid, str, 3000);
	}
	//printf("DamagePlayer(id: %d, vid: %d, d: %0.2f, m: %d, hleft: %0.2f)", id, vehicleid, amount, missileid, newhealth);
	if( newhealth <= 0.0 && health > 0.0)
    {
   		CallLocalFunction( "OnPlayerTwistedDeath", "dddddd", MPGetVehicleDriver(id), id, MPGetVehicleDriver(vehicleid), vehicleid, missileid, GetVehicleModel(id));
   		if(MPGetVehicleDriver(vehicleid) == INVALID_PLAYER_ID) DestroyVehicle(vehicleid);
	}
	return 1;
}

CMD:groundz(playerid, params[])
{
	new Float:pl_pos[3], Float:x, Float:y;
    GetPlayerPos(playerid, pl_pos[0], pl_pos[1], pl_pos[2]);
	x = 3.0 * floatround(pl_pos[0] / 3.0);
	y = 3.0 * floatround(pl_pos[1] / 3.0);
	SendClientMessageFormatted(playerid, -1, "floatround(x): %d floatround(y): %d - z: %0.2f", floatround(x), floatround(y), pl_pos[2]);
	return 1;
}

stock IsPointInArea(Float:x, Float:y, Float:minx, Float:maxx, Float:miny, Float:maxy)
{
    if (x > minx && x < maxx && y > miny && y < maxy) return 1;
    return 0;
}
forward Float:GetMapLowestZ(Float:x, Float:y, &Float:eZ);
stock Float:GetMapLowestZ(Float:x, Float:y, &Float:eZ)
{
	new Float:z = 0.0;
	switch(iMap)
	{
	    case MAP_DOWNTOWN:
		{
		    new Float:DowntownExcludingZAreas[4][6] = //MinX, MaxX, MinY, MaxY, MinZ, MaxZ
			{
			    {-1927.9543, -1885.1970, -1035.0299, -709.5599, 30.0, 43.0},
			    {-1983.9663, -1935.7401, -867.9561, -849.6713, 31.2188, 40.9494},
			    {-1964.5488, -1945.1086, -990.6176, -727.0721, 35.4, 40.9494},
			    {-1954.1730, -1937.0645, -1087.1028, -1016.8768, 31.2188, 40.9494}
			};
		    for(new a = 0, da = sizeof(DowntownExcludingZAreas); a < da; a++)
		    {
			    if(x >= DowntownExcludingZAreas[a][0] && x <= DowntownExcludingZAreas[a][1]
				&& y >= DowntownExcludingZAreas[a][2] && y <= DowntownExcludingZAreas[a][3]
				&& eZ >= DowntownExcludingZAreas[a][4] && eZ <= DowntownExcludingZAreas[a][5])
				{
	               	z = 30.0;
	               	break;
	   			}
   			}
   			if(z == 0.0)
   			{
				MapAndreas_FindZ_For2DCoord(x, y, z);
   			}
		}
	}
	return z;
}

forward Float:MissileYSize();
stock Float:MissileYSize()
{
	return 1.40;
}
//1654 - dynamic
//2036 - fake sniper
//2469 2470 2510 2511 - fake planes
public UpdateMissile(playerid, id, objectid, missileid, slot, vehicleid)
{
	//if(missileid == Missile_Homing) printf("[System: UpdateMissile] - (%d, %d, %d, %s, %d, %d)", playerid, id, objectid, GetTwistedMissileName(missileid), slot, vehicleid);
  	//SendClientMessageFormatted(INVALID_PLAYER_ID, RED, "[System] - Playerid: %d - Objectid: %d - Missileid: %d", playerid, objectid, missileid);
	new Float:x, Float:y, Float:z, Float:mZ,
		Float: vX, Float: vY, Float: vZ, Float: oX, Float: oY, Float: oZ;
    switch(missileid)
    {
        case Missile_Fire, Missile_Homing, Missile_Power, Missile_Napalm:
        {
            if(objectid != Vehicle_Missile[id][slot])
            {
                SendClientMessageFormatted(playerid, -1, "objectid: %d - Vehicle_Missile: %d - slot: %d", objectid, Vehicle_Missile[id][slot], slot);
            	objectid = Vehicle_Missile[id][slot];
            }
        }
        case Missile_RemoteBomb:
        {
            objectid = Vehicle_Napalm[playerid];
        }
    }
    GetObjectPos(objectid, oX, oY, oZ);
    if(oX == 0.0)
    {
    	SendClientMessageFormatted(playerid, -1, "objectid: %d - oZ: %0.2f - oX: %0.2f - oY: %0.2f", objectid, oZ, oX, oY);
    }
	foreach(Vehicles, v)
	{
	    if(id == v) continue;
	    if(!GetVehiclePos(v, vX, vY, vZ)) continue;
		if(missileid == Missile_Machine_Gun)
		{
			oX -= vX, oY -= vY, oZ -= vZ;
			GetVehicleSize(GetVehicleModel(v), vX, vY, vZ);
			vX *= 0.8, vY *= 0.8, vZ *= 0.7;
			if((-vX < oX < vX) && (-vY < oY < vY) && (-vZ < oZ < vZ))
			{
			    //StopObject(objectid);
        		DestroyObject(objectid);
        		DamagePlayer(id, v, GetMissileDamage(missileid, id), missileid);
	 	   		KillTimer(Update_Machine_Gun_Timer[playerid][slot]);
 			}
 			else continue;
		}
		else 
	 	{
	 		mZ = GetMapLowestZ(oX, oY, oZ);
	 		if(mZ > oZ)
	 		{
	 		    switch(missileid)
	 		    {
	 		        case Missile_Ricochet:
	 		        {
						new Float:angle, Float:reflection, Float:wallangle = 30.0;
						GetObjectRot(objectid, angle, angle, angle);
						reflection = (angle * 2.0) - wallangle;
						MPClamp360(reflection);
						new Float:x2 = x + (150.0 * floatsin(-reflection, degrees));
		              	new Float:y2 = y + (150.0 * floatcos(-reflection, degrees));
		              	StopObject(objectid);
		              	MoveObject(objectid, x2, y2, oZ, MISSILE_SPEED);
	 		        }
	 		        default:
	 		        {
			 		    SendClientMessageFormatted(playerid, -1, "mZ: %0.2f - oZ: %0.2f - oX: %0.2f - oY: %0.2f - objectid: %d", mZ, oZ, oX, oY, objectid);
			 		    CallLocalFunction("Explode_Missile", "iii", id, slot, missileid);
		 		    }
	 		    }
	 		    break;
	 		}
	 	    new Float:abetweenobjectandvehicle = Angle2D( oX, oY, vX, vY );
	 	    MPClamp360(abetweenobjectandvehicle);
	 	    oX += ( MissileYSize() * floatsin( -abetweenobjectandvehicle, degrees ) );
   			oY += ( MissileYSize() * floatcos( -abetweenobjectandvehicle, degrees ) );
   			x = oX;
	 	    y = oY;
	 	    z = oZ;
			oX -= vX;
			oY -= vY;
			oZ -= vZ;
			GetVehicleSize(GetVehicleModel(v), vX, vY, vZ); //vX *= 0.8; //vY *= 0.8;
		 	vZ *= 0.7;
		 	new Float:tindex = ((oX * oX) + (oY * oY) + (oZ * oZ));
			if((-vX < oX < vX) && (-vY < oY < vY) && (-vZ < oZ < vZ) || tindex < (2.0 * 2.0))
			{
  				//StopObject(objectid);
  				DestroyObject(objectid);
	        	switch(missileid)
		  		{
		  		    case Missile_Ricochet:
		  		    {
		  		        KillTimer(GetPVarInt(playerid, "Ricochet_Missile_Timer"));
		  		    }
		  		    case Missile_RemoteBomb:
		  		    {
		  		        KillTimer(Update_Remote_Bomb_Timer[playerid]);
		  		        CreateExplosion(x, y, z, 8, 0.7);
		  		        if(IsValidObject(Vehicle_Napalm[id]))
						{
						 	DestroyObject(Vehicle_Napalm[id]);
						}
		  		        return 1;
		  		    }
		  		    case Missile_Napalm:
					{
					    if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
					  	CreateExplosion(x, y, z, 13, 0.0);
					  	Vehicle_Smoke[id][slot] = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
					}
					case Missile_Power:
					{
					    if(IsValidObject(Vehicle_Missile_Light[id][slot])) DestroyObject(Vehicle_Missile_Light[id][slot]);
					    if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
					    Vehicle_Smoke[id][slot] = CreateObject(18681, x, y, z, 0.0, 0.0, 0.0, 300.0);
					}
					case Missile_Special:
					{
					    switch(GetVehicleModel(id))
					    {
					        case Spectre:
							{
							    if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
							    Vehicle_Smoke[id][slot] = CreateObject(18685, x, y, z, 0.0, 0.0, 0.0, 300.0);
								DamagePlayer(id, v, GetMissileDamage(missileid, id), missileid);
						 	    KillTimer(Update_Missile_Timer[playerid][slot]);
						 	    Vehicle_Firing_Missile[id] = 0;
								return 1;
							}
							case Reaper:
							{
							    if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
							    Vehicle_Smoke[id][slot] = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
                                DamagePlayer(id, v, GetMissileDamage(missileid, id), missileid);
						 	    KillTimer(Update_Missile_Timer[playerid][slot]);
						 	    Vehicle_Firing_Missile[id] = 0;
					        	SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[id][slot], playerid);
					        	return 1;
							}
							case Brimstone:
							{
							    CallRemoteFunction("OnBrimstoneFollowerHitToVehicle", "iiiifff", playerid, id, v, objectid, x, y, z);
							    return 1;
							}
							case Roadkill:
							{
					        	if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
                                CreateExplosion(x, y, z, 12, 2);
								Vehicle_Smoke[id][slot] = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
								DamagePlayer(id, v, GetMissileDamage(missileid, id), missileid);
						 	    KillTimer(Update_Missile_Timer[playerid][slot]);
						 	    SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[id][slot], playerid);
					        	return 1;
				   			}
							case Sweet_Tooth:
							{
					        	if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
                                CreateExplosion(x, y, z, 12, 2);
								Vehicle_Smoke[id][slot] = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
                                DamagePlayer(id, v, GetMissileDamage(missileid, id), missileid);
						 	    KillTimer(Update_Missile_Timer[playerid][slot]);
						 	    SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[id][slot], playerid);
					        	return 1;
							}
							//default: {}
						}
					}
					default:
					{
					    if(IsValidObject(Vehicle_Missile_Light[id][slot])) DestroyObject(Vehicle_Missile_Light[id][slot]);
					    if(IsValidObject(Vehicle_Smoke[id][slot])) DestroyObject(Vehicle_Smoke[id][slot]);
					    Vehicle_Smoke[id][slot] = CreateObject(18686, x, y, z, 0.0, 0.0, 0.0, 300.0);
					}
				}
				DamagePlayer(id, v, GetMissileDamage(missileid, id), missileid);
	            Vehicle_Firing_Missile[id] = 0;
		 	    KillTimer(Update_Missile_Timer[playerid][slot]);
		 	    SetTimerEx("Destroy_Object", 200, false, "ii", Vehicle_Smoke[id][slot], playerid);
			}
	  	}
	}
	if(vehicleid != INVALID_VEHICLE_ID)
	{
		switch(missileid)
		{
		    case Missile_Fire:
		    {
	   			SetPVarInt(playerid, "Fire_Missile_Update", GetPVarInt(playerid, "Fire_Missile_Update") + 65);
			    if(GetPVarInt(playerid, "Fire_Missile_Update") > 300)
			    {
				    GetVehiclePos(vehicleid, x, y, z);
				    new Float:ompos[3];
					GetObjectPos(objectid, ompos[0], ompos[1], ompos[2]);
					SetObjectRot(objectid, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90);
					MoveObject(objectid, x, y, z, MISSILE_SPEED, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90);
					SetPVarInt(playerid, "Fire_Missile_Update", 0);
				}
		    }
		    case Missile_Homing, Missile_Environmentals:
		    {
			    GetVehiclePos(vehicleid, x, y, z);
			    new Float:ompos[3];
				GetObjectPos(objectid, ompos[0], ompos[1], ompos[2]);
				//SetObjectRotEx(objectid, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90, 5.0);
				MoveObject(objectid, x, y, z, MISSILE_SPEED, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90);
			}
		    case Missile_Special:
		    {
				switch(GetVehicleModel(id))
				{
				    case Roadkill:
				    {
				        PlayerInfo[playerid][pSpecial_Missile_Update] += 35;
					    if(PlayerInfo[playerid][pSpecial_Missile_Update] >= 130) //(35 * 5)
					    {
						    GetVehiclePos(vehicleid, x, y, z);
						    new Float:ompos[3];
							GetObjectPos(objectid, ompos[0], ompos[1], ompos[2]);
							//SetObjectRotEx(objectid, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90, 5.0);
							MoveObject(objectid, x, y, z, MISSILE_SPEED, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90);
							PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
						}
					}
					case Sweet_Tooth:
					{
					    PlayerInfo[playerid][pSpecial_Missile_Update] += 65;
					    if(PlayerInfo[playerid][pSpecial_Missile_Update] >= 195) //(65 * 3)
					    {
						    GetVehiclePos(vehicleid, x, y, z);
						    new Float:ompos[3];
							GetObjectPos(objectid, ompos[0], ompos[1], ompos[2]);
							//SetObjectRotEx(objectid, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90, 5.0);
							MoveObject(objectid, x, y, z, MISSILE_SPEED, 0.0, 0.0, Angle2D( ompos[0], ompos[1], x, y ) - 90);
							PlayerInfo[playerid][pSpecial_Missile_Update] = 0;
						}
					}
				}
			}
		}
	}
    if(!IsValidObject(objectid))
	{
		KillTimer(Update_Missile_Timer[playerid][slot]);
        Update_Missile_Timer[playerid][slot] = -1;
	}
	return 1;
}

stock SetObjectRotEx(iObjID, Float: fRX, Float: fRY, Float: fRZ, Float: fSpeed)
{
    new Float: fX, Float: fY, Float: fZ ;
    if(GetObjectPos(iObjID, fX, fY, fZ))
    {
        return MoveObject(iObjID, fX, fY, fZ + 0.001, fSpeed, fRX, fRY, fRZ);
    }
    return 0;
}

#define SetObjectRot SetObjectRotEx

stock PointInRangeOfPoint(Float:x, Float:y, Float:z, Float:x2, Float:y2, Float:z2, Float:range)
{
    x2 -= x; y2 -= y; z2 -= z;
    return ((x2 * x2) + (y2 * y2) + (z2 * z2)) < (range * range);
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
    T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(vehicleid));
    Vehicle_Missileid[vehicleid] = 0;
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
    Vehicle_Missileid[vehicleid] = 0;
    Vehicle_Firing_Missile[vehicleid] = 0;
	printf("OnVehicleDeath");
	if(Iter_Contains(Vehicles, vehicleid))
	{
		Iter_Remove(Vehicles, vehicleid);
	}
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	/*if(!Iter_Contains(Streamed_Vehicles[forplayerid], vehicleid))
	{
    	Iter_Add(Streamed_Vehicles[forplayerid], vehicleid);
	}*/
    return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	/*if(Iter_Contains(Streamed_Vehicles[forplayerid], vehicleid))
	{
    	Iter_Remove(Streamed_Vehicles[forplayerid], vehicleid);
    }*/
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
		SetTimerEx("PutPlayerBackInVehicle", 70, false, "ii", playerid, vehicleid);
	}
	return 1;
}
forward PutPlayerBackInVehicle(playerid, vehicleid);
public PutPlayerBackInVehicle(playerid, vehicleid)
{
    PutPlayerInVehicle(playerid, vehicleid, 0);
	return 1;
}

public OnVehicleFire(playerid, vehicleid, slot, missileid)
{
	//printf("Vehicleid: %d Fired A Missile From Slot: %d - Missile: %s", vehicleid, slot, GetTwistedMissileName(missileid));
	new connected = IsPlayerConnected(playerid);
	if(missileid < MAX_MISSILEID && connected)
	{
		if(PlayerInfo[playerid][pMissiles][missileid] <= 0)
		{
		    switch(missileid)
		    {
		        case Missile_Special:
	        	{
	        	    switch(GetVehicleModel(vehicleid))
				    {
				        case Roadkill:
				        {
						    if(slot == 6) Vehicle_Missileid[vehicleid] = GetNextMissileSlot(playerid, vehicleid);
				    	}
				        case Sweet_Tooth:
				        {
						    if(slot == 19) Vehicle_Missileid[vehicleid] = GetNextMissileSlot(playerid, vehicleid);
						}
						default: Vehicle_Missileid[vehicleid] = GetNextMissileSlot(playerid, vehicleid);
					}
				}
		        case (MIN_MISSILEID + 1)..(MAX_MISSILEID - 1):
		        {
		             Vehicle_Missileid[vehicleid] = GetNextMissileSlot(playerid, vehicleid);
				}
			}
		}
	}
	if(connected)
	{
		UpdatePlayerMissileStatus(playerid);
		switch(missileid)
	    {
			case Missile_Napalm:
			{
			    GameTextForPlayer(playerid, "~n~~n~~w~Click ~p~~k~~VEHICLE_FIREWEAPON_ALT~ ~w~To Bring Down The Gas Can", 2000, 3);
			}
		}
	}
	return 1;
}

forward OnVehicleMissileChange(vehicleid, oldmissile, newmissile, playerid);
public OnVehicleMissileChange(vehicleid, oldmissile, newmissile, playerid)
{
    if(PlayerInfo[playerid][pMissiles][newmissile] > 0)
    {
        TextDrawColor(pTextInfo[playerid][pMissileSign][newmissile], 0x00FF00FF);
        TextDrawShowForPlayer(playerid, pTextInfo[playerid][pMissileSign][newmissile]);
    }
    UpdatePlayerMissileStatus(playerid);
    SendClientMessageFormatted(playerid, -1, "New Missile: %s - Ammo: %d - Missileid: %d - Old Missile: %s", GetTwistedMissileName(newmissile, newmissile), PlayerInfo[playerid][pMissiles][newmissile], newmissile, GetTwistedMissileName(oldmissile, oldmissile));
	if(PlayerInfo[playerid][pMissile_Special_Charged] != false || PlayerInfo[playerid][pMissile_Special_Time] != 0)
	{
		PlayerInfo[playerid][pMissile_Special_Time] = 0;
		PlayerInfo[playerid][pMissile_Special_Charged] = false;
	}
	return 1;
}

public Explode_Missile(vehicleid, slot, missileid)
{
    //printf("[System: Explode_Missile] - vehicleid: %d - slot: %d - missileid: %s", vehicleid, slot, GetTwistedMissileName(missileid));
    Vehicle_Firing_Missile[vehicleid] = 0;
	new playerid = MPGetVehicleDriver(vehicleid);
    if(playerid != INVALID_PLAYER_ID)
	{
    	KillTimer(Update_Missile_Timer[playerid][slot]);
	}
	new Float:x, Float:y, Float:z;
	if(IsValidObject(Vehicle_Missile[vehicleid][slot]))
	{
	    GetObjectPos(Vehicle_Missile[vehicleid][slot], x, y, z);
		DestroyObject(Vehicle_Missile[vehicleid][slot]);
	}
	if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
	{
		DestroyObject(Vehicle_Smoke[vehicleid][slot]);
	}
	if(IsValidObject(Vehicle_Missile_Light[vehicleid][slot]))
	{
		DestroyObject(Vehicle_Missile_Light[vehicleid][slot]);
	}
 	switch(missileid)
  	{
  	    case Missile_Special:
        {
            switch(GetVehicleModel(vehicleid))
            {
                case Roadkill, Sweet_Tooth: CreateExplosion(x, y, z, 12, 2);
            }
        }
  	    case Missile_Fire, Missile_Homing:
	  	{
	  	    CreateExplosion(x, y, z, 12, 2);
		}
  		case Missile_Power:
	  	{
         	CreateExplosion(x, y, z, 12, 5);
	   	}
        case Missile_Stalker, Missile_Ricochet:
        {
            CreateExplosion(x, y, z, 12, 3);
    	}
	  	case Missile_Napalm:
	  	{
	  	    CreateExplosion(x, y, z, 11, 4);
		}
		case Missile_RemoteBomb:
		{
		    if(IsValidObject(Vehicle_Napalm[vehicleid]))
			{
			    GetObjectPos(Vehicle_Napalm[vehicleid], x, y, z);
			    DestroyObject(Vehicle_Napalm[vehicleid]);
			    CreateExplosion(x, y, z, 11, 4);
			}
		}
  	}
    CallLocalFunction("OnVehicleMissileExploded", "iii", vehicleid, slot, missileid);
 	return 1;
}

public OnVehicleMissileExploded(vehicleid, slot, missileid)
{
    //printf("[System: OnVehicleMissileExploded] - vehicleid: %d - slot: %d - missile: %s", vehicleid, slot, GetTwistedMissileName(missileid));
	if(IsValidObject(Vehicle_Smoke[vehicleid][slot]))
 	{
 	    DestroyObject(Vehicle_Smoke[vehicleid][slot]);
	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	if(GetVehicleInterior(GetPlayerVehicleID(playerid)) == INVISIBILITY_INDEX) return 1;
	//printf("[System: OnPlayerPickUpPickup] - Total Pickups: %d - Pickupid: %d", TotalPickups, pickupid);
	new bool:iterpickup = false;
	switch(PickupInfo[pickupid][Pickuptype])
	{
	    case PICKUPTYPE_HEALTH:
	    {
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "30 Percent Health Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "30% Health Pickup", 5000);
	    	new Float:health, vehicleid = GetPlayerVehicleID(playerid);
	    	new Float:maxhealth = GetTwistedMetalMaxHealth(vehicleid);
	    	T_GetVehicleHealth(vehicleid, health);
			SendClientMessageFormatted(playerid, -1, "old health: %0.2f", health);
			health *= 1.3;
			SendClientMessageFormatted(playerid, -1, "new health: %0.2f", health);
			health = (health > maxhealth) ? maxhealth : health;
	    	T_SetVehicleHealth(vehicleid, health);
	    }
	    case PICKUPTYPE_TURBO:
	    {
	        if(PlayerInfo[playerid][pTurbo] >= floatround(MAX_TURBO))
			{
			    DestroyPickup(pickupid);
			    PickupInfo[pickupid][Created] = false;
	    		SetTimerEx("RespawnPickup", 2000, false, "i", pickupid);
				TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Turbo Bay Full", 4000);
				return 1;
			}
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Turbo Picked Up");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Turbo Recharge", 5000);
	    	PlayerInfo[playerid][pTurbo] = floatround(MAX_TURBO);
	    	SetProgressBarValue(pTextInfo[playerid][pTurboBar], MAX_TURBO);
	    	UpdateProgressBar(pTextInfo[playerid][pTurboBar], playerid);
	    }
	    case PICKUPTYPE_MACHINE_GUN_UPGRADE:
	    {
	        iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Machine Gun Upgrade Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Machine Gun Upgrade", 5000);
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
		case PICKUPTYPE_STALKERS_MISSILE:
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
		case PICKUPTYPE_ZOOMY_MISSILE:
		{
		    iterpickup = true;
	    	SendClientMessage(playerid, GetPlayerColor(playerid), "Zoomy Missiles Pickup");
	    	TimeTextForPlayer( TIMETEXT_BOTTOM, playerid, "Zoomy Missiles Picked Up", 5000);
	    	PlayerInfo[playerid][pMissiles][Missile_Zoomys]++;
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
		}
	}
	if(iterpickup == true)
	{
	    UpdatePlayerMissileStatus(playerid);
	    DestroyPickup(pickupid);
		PickupInfo[pickupid][Created] = false;
    	SetTimerEx("RespawnPickup", 25000, false, "i", pickupid);
	}
 	return 1;
}


//sweet tooth fire /hold 18688 2 0.22 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
public Destroy_Object(objectid, playerid)
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
	        format(string,sizeof(string),"(Admin Chat) %s(%d): %s",Playername(playerid),playerid,text[1]);
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
		SendClientMessageFormatted(INVALID_PLAYER_ID, PINK, "Auto kick: %s(%d) has been kicked from the server - Reason: Excess Flood (Text Spam)", Playername(playerid), playerid);
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

CMD:applyanimation(playerid,params[])
{
	new animlib[32],animname[32];
	if(sscanf(params,"s[32]s[32]", animlib, animname)) return SendClientMessage(playerid, -1, "Usage: /Applyanimation [Animlib] [Animname]");
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
{//explosion behind of vehicle
	new Float: Pos[7], vehicleid = GetPlayerVehicleID(playerid);
	GetVehicleZAngle(vehicleid, Pos[6]);
	GetVehicleSize(GetVehicleModel(vehicleid), Pos[3], Pos[4], Pos[5]);
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
	GetVehicleSize(GetVehicleModel(vehicleid), Pos[3], Pos[4], Pos[5]);
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find front right

	Pos[0] += (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] += (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270;
  	Pos[0] += (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] += (Pos[3] * 0.42 * floatcos(-a, degrees));

	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);
	//
	GetVehicleZAngle(vehicleid, a); //a -= 270
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find front left

	Pos[0] -= (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] += (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270;
  	Pos[0] -= (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] += (Pos[3] * 0.42 * floatcos(-a, degrees));

  	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);

  	//
	GetVehicleZAngle(vehicleid, a); //a -= 270
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find back right

	Pos[0] += (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] -= (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270;
  	Pos[0] += (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] -= (Pos[3] * 0.42 * floatcos(-a, degrees));

  	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);

  	//
	GetVehicleZAngle(vehicleid, a); //a -= 270
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);

	//find back left

	Pos[0] -= (Pos[4] * 0.42 * floatsin(-a, degrees));
 	Pos[1] -= (Pos[4] * 0.42 * floatcos(-a, degrees));

    a += 270;
  	Pos[0] -= (Pos[3] * 0.42 * floatsin(-a, degrees));
  	Pos[1] -= (Pos[3] * 0.42 * floatcos(-a, degrees));

	CreateExplosion(Pos[0], Pos[1], Pos[2] + 0.42 * Pos[5], 12, 1.0);

	T_SetVehicleHealth(vehicleid, GetTwistedMetalMaxHealth(vehicleid));
	return 1;
}

CMD:connect(playerid, params[])
{
    ConnectNPC("[BOT]Tester", "npcidle");
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
    if(GetPlayerVehicleID(playerid) == INVALID_VEHICLE_ID) return SendClientMessage(playerid,RED,"Error: You Cannot Use This Command While Onfoot");
    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(GetPlayerVehicleID(playerid), engine, lights, alarm, doors, bonnet, boot, objective);
	if(GetPVarInt(playerid,"TrunkOn") == 0)
	{
 		SetVehicleParamsEx(GetPlayerVehicleID(playerid), engine, lights, alarm, doors, bonnet, VEHICLE_PARAMS_ON, objective);
        SetPVarInt(playerid,"TrunkOn", 1);
	}
    else if(GetPVarInt(playerid,"TrunkOn") == 1)
    {
 		SetVehicleParamsEx(GetPlayerVehicleID(playerid), engine, lights, alarm, doors, bonnet, VEHICLE_PARAMS_OFF, objective);
        SetPVarInt(playerid,"TrunkOn", 0);
	}
    return 1;
}

CMD:hold(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new oid,bid,Float:a[9];
	if(sscanf(params, "ddF(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(1.0)F(1.0)F(1.0)", oid, bid, a[0], a[1], a[2], a[3], a[4], a[5],a[6], a[7], a[8]))
	{
    	SendClientMessage(playerid, 0xFFFFFFFF, "Usage: /hold [Objectid] [Boneid 1-18] [fOffSetX] [fOffSetY] [fOffSetZ] [fRotX] [fRotY] [fRotZ] [fScaleX] [fScaleY] [fScaleZ]"),
		SendClientMessage(playerid, 0xFFFFFFFF, "1: Spine | 2: Head | 3: Left Upper Arm | 4: Right Upper Arm | 5: Left Hand | 6: Right Hand"),
		SendClientMessage(playerid, 0xFFFFFFFF, "7: Left thigh | 8: Right thigh | 9: Left foot | 10: Right foot | 11: Right calf | 12: Left calf"),
		SendClientMessage(playerid, 0xFFFFFFFF, "13: Left forearm | 14: Right forearm | 15: Left clavicle | 16: Right clavicle | 17: Neck | 18: Jaw");
		return 1;
	}
    SetPlayerAttachedObject(playerid, 0, oid, bid, a[0],a[1],a[2],a[3],a[4],a[5], a[6], a[7], a[8]);
	return 1;
}

CMD:btest(playerid,params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
    new Float:a[6], index, id, str[7], Float:angle;
    if(sscanf(params, "dD(1)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)F(0.0)", id, index, a[0], a[1], a[2], a[3], a[4], a[5]))
	{
        SendClientMessage(playerid,RED,"{1E90FF}/btest [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n{FFFFFF}Position and index are optional.");
		return 1;
	}
    GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
	//angle += 90;
	format(str, sizeof(str), "obb-%d", index);
	new Float:x, Float:y, Float:z;
	if(GetPVarInt(playerid, str) != 0)
	{
		DestroyObject(GetPVarInt(playerid, str));
		GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    	SetPVarInt(playerid, str, CreateObject(id, x + (a[0] * floatsin(-angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2], a[3], a[4], angle + 90 + a[5], 100.0));
		//printf("btest - xsin: %f - x+sin: %f - x: %f - y: %f - z: %f", floatsin(-angle, degrees), (a[0] * floatsin(angle, degrees)), x + (a[0] * floatsin(angle, degrees)), y + (a[1] * floatcos(-angle, degrees)), z + a[2]);
	}
	else
	{
	    DestroyObject(GetPVarInt(playerid, str));
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
        SendClientMessage(playerid,RED,"{1E90FF}/holdvex [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n{FFFFFF}Position and index are optional.");
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
		DestroyObject(GetPVarInt(playerid, str));
		GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    	SetPVarInt(playerid, str, CreateObject(id, x + a[0], y + a[1], z + a[2], a[3], a[4], a[5], 100.0));
	}
	else
	{
	    DestroyObject(GetPVarInt(playerid, str));
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
        SendClientMessage(playerid,RED,"{1E90FF}/holdv [objectid] [index] [X] [Y] [Z] [rX] [rY] [rZ]\n\n{FFFFFF}Position and index are optional.");
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
		DestroyObject(GetPVarInt(playerid, str));
    	SetPVarInt(playerid, str, CreateObject(id, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0));
		AttachObjectToVehicle(GetPVarInt(playerid, str), GetPlayerVehicleID(playerid), a[0], a[1], a[2], a[3], a[4], a[5]);
	}
	else
	{
	    DestroyObject(GetPVarInt(playerid, str));
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
		DestroyObject(GetPVarInt(playerid, str));
		SetPVarInt(playerid, str, CreateObject(oid,0.0,0.0,0.0,0.0,0.0,0.0,200.0));
		AttachObjectToPlayer(GetPVarInt(playerid, str),playerid,a[0],a[1],a[2],a[3],a[4],a[5]);
	}
	else
	{
	    DestroyObject(GetPVarInt(playerid, str));
	    SetPVarInt(playerid, str, CreateObject(oid,0.0,0.0,0.0,0.0,0.0,0.0,200.0));
		AttachObjectToPlayer(GetPVarInt(playerid, str),playerid,a[0],a[1],a[2],a[3],a[4],a[5]);
	}
	return 1;
}

CMD:remove(playerid, params[])
{
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
CMD:gas(playerid, params[])
{
	new Napalms;
	if(sscanf(params, "D(1)", Napalms)) return SendClientMessage(playerid, RED, "/Gas [Amount]");
    SendClientMessage(playerid, 0xFFFFFFFF, "Gas Can Missile(s) Added");
    PlayerInfo[playerid][pMissiles][Missile_Napalm] += Napalms;
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
	PlayerInfo[playerid][pTurbo] = floatround(MAX_TURBO);
	SetProgressBarValue(pTextInfo[playerid][pTurboBar], floatround(MAX_TURBO));
	UpdateProgressBar(pTextInfo[playerid][pTurboBar], playerid);
	return 1;
}
CMD:energy(playerid, params[])
{
	PlayerInfo[playerid][pEnergy] = 100;
	SetProgressBarValue(pTextInfo[playerid][pEnergyBar], 100.0);
	UpdateProgressBar(pTextInfo[playerid][pEnergyBar], playerid);
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
			new Float:x, Float:y, Float:z; GetPlayerPos(id,x,y,z);
			SetPlayerInterior(playerid,GetPlayerInterior(id));
			SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(id));
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
	new vname[25], changecurrentcar;
 	if(sscanf(params, "s[25]D(0)", vname, changecurrentcar)) return SendClientMessage(playerid, RED, "Usage: /v [twisted name/ vehiclename / modelid - changecurrentcar = 0 / 1]");
	if(aveh[playerid] != 0) DestroyVehicle(aveh[playerid]);
	new Float:x, Float:y, Float:z, Float:Angle;
 	GetPlayerPos(playerid, x, y, z);
 	GetPlayerFacingAngle(playerid, Angle);
 	if(isNumeric(vname))
  	{
		if(!IsValidVehicle(strval(vname))) return SendClientMessage(playerid, RED, "Error: Invalid Vehicleid");
		aveh[playerid] = CreateVehicle(strval(vname), x, y, z, Angle, -1, -1, -1);
		T_SetVehicleHealth(aveh[playerid], GetTwistedMetalMaxHealth(aveh[playerid]));
	}
	else if(!isNumeric(vname))
	{
	    new bool:index = false, model = GetTwistedMetalVehicleID(vname);
	    if(model == INVALID_VEHICLE_ID)
	    {
	        model = ReturnVehicleID(vname);
	    }
	    else index = true;
		if(!IsValidVehicle(model)) return SendClientMessage(playerid, RED, "Error: Invalid Name");
		aveh[playerid] = CreateVehicle(model, x, y, z, Angle, -1, -1, -1);
		if(index == true)
		{
		    Add_Vehicle_Offsets_And_Objects(aveh[playerid], Missile_Machine_Gun);
		}
		T_SetVehicleHealth(aveh[playerid], GetTwistedMetalMaxHealth(aveh[playerid]));
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
   	}
	return 1;
}
CMD:getobjectpos(playerid, params[])
{
    new objectid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;
	if(sscanf(params, "d", objectid)) return SendClientMessage(playerid, -1, "Usage: /GetObjectPos [objectid]");
	GetPlayerPos(objectid, x, y, z);
	GetObjectRot(objectid, rx, ry, rz);
	SendClientMessageFormatted(playerid, -1 , "Object Position id: %d - x: %0.4f - y: %0.4f - z: %0.4f - Angle: %0.4f", objectid, x, y, z, rx, ry, rz);
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
	MessageToAdmins(WHITE,string);
	SetPlayerHealth(id, -1);
	ForceClassSelection(playerid);
	return 1;
}
CMD:getall(playerid,params[])
{
    #pragma unused params
	if(!IsPlayerAdmin(playerid)) return 0;
	new Float:x,Float:y,Float:z,interior = GetPlayerInterior(playerid);
	GetPlayerPos(playerid,x,y,z);
 	foreach(Player,i)
	{
		if(i == playerid) continue;
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerPos(i,x+(playerid/4)+1,y+(playerid/4),z);
		SetPlayerInterior(i,interior);
	}
	new string[128];
	format(string,sizeof(string),"|- Administrator \"%s\" Has Teleported All Players To His Position -|", Playername(playerid));
	return SendClientMessageToAll(BlueMsg, string);
}
CMD:get(playerid,params[])
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
stock IsValidVehicle(vehicleid)
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
GetTwistedMetalVehicleID(vName[])
{
	for(new x = 0; x != MAX_TWISTED_VEHICLES; x++)
	{
	    if(strfind(C_S_IDS[x][CS_TwistedName], vName, true) != -1)
		return C_S_IDS[x][CS_VehicleModelID];
	}
	return INVALID_VEHICLE_ID;
}
stock RotatePoint(& Float: X, & Float: Y, & Float: Z, Float: pitch, Float: yaw, Float: distance) {
    X -= (distance * floatcos(pitch, degrees) * floatsin(yaw, degrees));
    Y += (distance * floatcos(pitch, degrees) * floatcos(yaw, degrees));
    Z += (distance * floatsin(pitch, degrees));
}

stock GetXYZOfVehicle(vehicleid, & Float: X, & Float: Y, & Float: Z, Float: pitch, Float: distance) {
    new Float: yaw;
    if(GetVehicleZAngle(vehicleid, yaw)) {
        GetVehiclePos(vehicleid, X, Y, Z);
        RotatePoint(X, Y, Z, pitch, yaw, distance);
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
	//a +=180;
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

Float:DistanceCameraTargetToLocation(Float:CamX, Float:CamY, Float:CamZ, Float:ObjX, Float:ObjY, Float:ObjZ,  Float:FrX, Float:FrY, Float:FrZ)
{
	new Float:TGTDistance;
	TGTDistance = floatsqroot((CamX - ObjX) * (CamX - ObjX) + (CamY - ObjY) * (CamY - ObjY) + (CamZ - ObjZ) * (CamZ - ObjZ));
	new Float:tmpX, Float:tmpY, Float:tmpZ;
	tmpX = FrX * TGTDistance + CamX;
	tmpY = FrY * TGTDistance + CamY;
	tmpZ = FrZ * TGTDistance + CamZ;
	return floatsqroot((tmpX - ObjX) * (tmpX - ObjX) + (tmpY - ObjY) * (tmpY - ObjY) + (tmpZ - ObjZ) * (tmpZ - ObjZ));
}
#pragma unused DistanceCameraTargetToLocation
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

stock GetAlpha(color) return color & 0xFF;

CMD:text(playerid, params[])
{
	new text[64], style = TIMETEXT_TOP, time = 5000;
	if(!sscanf(params, "s[64]D("#TIMETEXT_TOP")D(5000)", text, style, time))
	{
	    TimeTextForPlayer( style, playerid, text, time);
	}
	return 1;
}

stock TimeTextForPlayer( style, playerid, text[], time = 5000 )
{
    KillTimer( pStatusInfo[playerid][StatusTextTimer][style] );
    pStatusInfo[playerid][StatusTextTimer][style] = SetTimerEx( "HideTextTimer", time, false, "iii", style, playerid, _:pStatusInfo[playerid][StatusText][style]);
	switch( style )
    {
        case TIMETEXT_MIDDLE:
        {
			FadeTextdraw(playerid, pStatusInfo[playerid][StatusText][style], TM_STATUS_COLOUR1, 0x00000000, time, 250);
	    }
	    case TIMETEXT_TOP:
	    {
	        ++pStatusInfo[playerid][StatusIndex];
	        switch(pStatusInfo[playerid][StatusIndex])
	        {
	            case 1:
	            {
	                pStatusInfo[playerid][StatusTime] = GetTickCount();
				}
				default:
				{
				    new timeleft = (GetTickCount() - pStatusInfo[playerid][StatusTime]);
					if(timeleft > 0)
					{
				    	timeleft += 1000;
				    	TimeTextForPlayer( TIMETEXT_TOP_2, playerid, Status_Text[playerid][TIMETEXT_TOP], timeleft);
				    	pStatusInfo[playerid][StatusIndex] = 0;
				    }
				}
	        }
	    }
    }
    //TextDrawColor( pStatusInfo[playerid][StatusText][style], TM_STATUS_COLOUR1 );
    TextDrawSetString( pStatusInfo[playerid][StatusText][style], text );
    TextDrawShowForPlayer( playerid, pStatusInfo[playerid][StatusText][style] );
    strmid(Status_Text[playerid][style], text, false, strlen(text), 32);
    return 1;
}

forward HideTextTimer( style, playerid, textdrawid );
public HideTextTimer( style, playerid, textdrawid )
{
    TextDrawHideForPlayer(playerid, Text:textdrawid);
    KillTimer(pStatusInfo[playerid][StatusTextTimer][style]);
    switch(style)
    {
        case TIMETEXT_MIDDLE:
	    {
	        StopFadingTextdraw(playerid, Text:textdrawid);
	    }
    }
    strmid(Status_Text[playerid][style], "\0", false, strlen("\0"), 4);
    return 1;
}

#if !defined ZONE_PULSE_STAGE_TIME
        #define ZONE_PULSE_STAGE_TIME (50)
#endif

forward TextdrawFader(playerid, Text:textdrawid, from, to, time, stage, delay);
public TextdrawFader(playerid, Text:textdrawid, from, to, time, stage, delay)
{
    if (!IsPlayerConnected(playerid))
    {
        return;
    }
    static sTimer[32];
    format(sTimer, sizeof (sTimer), "k_fading_%d", _:textdrawid);
    stage = (stage + 1) % (time);
    if (stage == time)
    {
        TextDrawColor(textdrawid, to);
    	TextDrawShowForPlayer(playerid, textdrawid);
        SetPVarInt(playerid, sTimer, SetTimerEx("TextdrawFader", delay, 0, "iiiiiiiii", playerid, _:textdrawid, from, to, time, stage, delay));
        return;
    }
    if (stage > time)
    {
        TextDrawColor(textdrawid, to);
    	TextDrawShowForPlayer(playerid, textdrawid);
        SetPVarInt(playerid, sTimer, SetTimerEx("TextdrawFader", delay, 0, "iiiiiiiii", playerid, _:textdrawid, from, to, time, stage, delay));
        return;
	}
    else
    {
        // Fade there.
        new
            r = ((to >>> 24) - (from >>> 24)) * stage / time + (from >>> 24),
            g = ((to >>> 16 & 0xFF) - (from >>> 16 & 0xFF)) * stage / time + (from >>> 16 & 0xFF),
            b = ((to >>> 8 & 0xFF) - (from >>> 8 & 0xFF)) * stage / time + (from >>> 8 & 0xFF),
            a = ((to  & 0xFF) - (from  & 0xFF)) * stage / time + (from  & 0xFF);
        //printf("TextdrawFader: %d %d %x %x %x %x", playerid, _:textdrawid, r & 0xFF, g & 0xFF, b & 0xFF, a & 0xFF);
        TextDrawColor(textdrawid, (r << 24) | ((g & 0xFF) << 16) | ((b & 0xFF) << 8) | (a & 0xFF));
    	TextDrawShowForPlayer(playerid, textdrawid);
		SetPVarInt(playerid, sTimer, SetTimerEx("TextdrawFader", ZONE_PULSE_STAGE_TIME, 0, "iiiiiiiii", playerid, _:textdrawid, from, to, time, stage, delay));
    }
    return;
}

stock FadeTextdraw(playerid, Text:textdrawid, from, to, time, delay = ZONE_PULSE_STAGE_TIME)
{
    static sTimer[32];
    format(sTimer, sizeof (sTimer), "k_fading_%d", _:textdrawid);
    KillTimer(GetPVarInt(playerid, sTimer));
    TextDrawColor(textdrawid, from);
    TextDrawShowForPlayer(playerid, textdrawid);
    SetPVarInt(playerid, sTimer, SetTimerEx("TextdrawFader", delay, 0, "iiiiiiiii", playerid, _:textdrawid, from, to, time / ZONE_PULSE_STAGE_TIME, 0, delay));
    return 1;
}

stock StopFadingTextdraw(playerid, Text:textdrawid)
{
    static sTimer[32];
    format(sTimer, sizeof (sTimer), "k_fading_%d", _:textdrawid);
    KillTimer(GetPVarInt(playerid, sTimer));
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
	new modifier, positive;
	if(sscanf(params, "F(0.0)D(0)", modifier, positive)) return SendClientMessage(playerid, -1, "Usage: /testm Optional: [modifier] [positive]");
	ModifyVehicleAngularVelocity(GetPlayerVehicleID(playerid), modifier, positive);
	return 1;
}
CMD:js(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, RED, "Error: You Are Not In A Vehicle");
 	new vehicleid = GetPlayerVehicleID(playerid), Float:Xv, Float:Yv, Float:Zv, Float:absV;
	GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
	absV = floatsqroot(floatpower(floatabs(Xv),2)+floatpower(floatabs(Yv),2)+floatpower(floatabs(Zv),2));
	if(absV < 0.04)
	{
        new Float:Zangle;
        GetVehicleZAngle(vehicleid, Zangle);
        GetVehicleVelocity(vehicleid, Xv, Yv, Zv);
        Xv = (0.11 * absV * floatsin(Zangle, degrees));
        Yv = (0.11 * absV * floatcos(Zangle, degrees));
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

forward Turbo_Deduct(playerid);
public Turbo_Deduct(playerid)
{
    new ud, lr, keys;
    GetPlayerKeys(playerid, keys, ud, lr);
    if(!(keys & 8) && !(ud < 0))
    {
        return 1;
    }
	PlayerInfo[playerid][pTurbo]--;
	if(GetVehicleModel(Current_Vehicle[playerid]) == 463)
	{
	    IncreaseVehicleSpeed(Current_Vehicle[playerid], 1.015);
	}
	else
	{
		switch(random(8))
		{
		    case 3: IncreaseVehicleSpeed(Current_Vehicle[playerid], 1.07);
		}
	}
 	if(PlayerInfo[playerid][pTurbo] <= 0)
 	{
  		PlayerInfo[playerid][pTurbo] = 0;
  		SetProgressBarValue(pTextInfo[playerid][pTurboBar], 0.0);
  		RemoveVehicleComponent(Current_Vehicle[playerid], 1010);
  		KillTimer(PlayerInfo[playerid][Turbo_Timer]);
  		if(GetVehicleModel(Current_Vehicle[playerid]) == 463)
  		{
		  	DestroyObject(Nitro_Bike_Object[playerid]);
		}
 	}
 	SetProgressBarValue(pTextInfo[playerid][pTurboBar], float(PlayerInfo[playerid][pTurbo]));
 	UpdateProgressBar(pTextInfo[playerid][pTurboBar], playerid);
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

forward TDS(playerid);
public TDS(playerid)
{
	TextDrawShowForPlayer(playerid, SpawnTD);
	return 1;
}

forward TDH(playerid);
public TDH(playerid)
{
    TextDrawHideForPlayer(playerid, SpawnTD);
	return 1;
}

forward RespawnPickup(pickupid);
public RespawnPickup(pickupid)
{
    PickupInfo[pickupid][Created] = true;
	PickupInfo[pickupid][Pickupid] = CreatePickup(PickupInfo[pickupid][Modelid], PickupInfo[pickupid][Type], PickupInfo[pickupid][PickupX], PickupInfo[pickupid][PickupY], PickupInfo[pickupid][PickupZ], PickupInfo[pickupid][VirtualWorld]);
    return 1;
}

stock CreatePickupEx(model, type, Float:x, Float:y, Float:z, virtualworld = 0, pickuptype = -1, text3d[])
{
    PickupInfo[TotalPickups][Pickupid] = CreatePickup(model, type, x, y, z, virtualworld);
    PickupInfo[TotalPickups][Modelid] = model;
    PickupInfo[TotalPickups][Type] = type;
    PickupInfo[TotalPickups][PickupX] = x;
    PickupInfo[TotalPickups][PickupY] = y;
    PickupInfo[TotalPickups][PickupZ] = z;
    PickupInfo[TotalPickups][VirtualWorld] = virtualworld;
    PickupInfo[TotalPickups][Created] = true;
    PickupInfo[TotalPickups][Pickuptype] = pickuptype;
    PickupInfo[TotalPickups][Pickuptext] = Create3DTextLabel(text3d, 0xFFFFFFFF, x, y, z + 0.3, 50.0, 0);
    TotalPickups ++;
	return 1;
}

stock DestroyPickupEx(pickupid)
{
	PickupInfo[TotalPickups][Modelid] = -1;
    PickupInfo[TotalPickups][Type] = -1;
    PickupInfo[TotalPickups][PickupX] = 0.0;
    PickupInfo[TotalPickups][PickupY] = 0.0;
    PickupInfo[TotalPickups][PickupZ] = 0.0;
    PickupInfo[TotalPickups][Created] = false;
    PickupInfo[TotalPickups][VirtualWorld] = 0;
    PickupInfo[TotalPickups][Pickuptype] = -1;
    Delete3DTextLabel(PickupInfo[TotalPickups][Pickuptext]);
	DestroyPickup(pickupid);
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

stock MessageToAdmins(color,const string[])
{
	foreach(Player, i)
	{
    	if(IsPlayerAdmin(i)) SendClientMessage(i, color, string);
	}
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

SendClientMessageFormatted(playerid, colour, format[], va_args<>)
{
    new out[144];
    va_format(out, sizeof(out), format, va_start<3>);
    if(playerid == INVALID_PLAYER_ID) return SendClientMessageToAll(colour, out);
    else return SendClientMessage(playerid, colour, out);
}

GameTextForPlayerFormatted(playerid, format[], time, style, va_args<>)
{
    new out[144];
    va_format(out, sizeof(out), format, va_start<4>);
    if(playerid == INVALID_PLAYER_ID) return GameTextForAll(out, time, style);
    else return GameTextForPlayer(playerid, out, time, style);
}

//IRC_GroupSayFormatted(groupid, const target[], format[], {Float, _}:...)
//{
//    new out[144];
//    va_format(out, sizeof(out), format, va_start<3>);
//    return IRC_GroupSay(groupid, target, out);
//}

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

static const Float: sizeData[212][3] =
{
    { 2.32, 5.11, 1.63 }, { 2.56, 5.82, 1.71 }, { 2.41, 5.80, 1.52 }, { 3.15, 9.22, 4.17 },
    { 2.20, 5.80, 1.84 }, { 2.34, 6.00, 1.49 }, { 5.26, 11.59, 4.42 }, { 2.84, 8.96, 2.70 },
    { 3.11, 10.68, 3.91 }, { 2.36, 8.18, 1.52 }, { 2.25, 5.01, 1.79 }, { 2.39, 5.78, 1.37 },
    { 2.45, 7.30, 1.38 }, { 2.27, 5.88, 2.23 }, { 2.51, 7.07, 4.59 }, { 2.31, 5.51, 1.13 },
    { 2.73, 8.01, 3.40 }, { 5.44, 23.27, 6.61 }, { 2.56, 5.67, 2.14 }, { 2.40, 6.21, 1.40 },
    { 2.41, 5.90, 1.76 }, { 2.25, 6.38, 1.37 }, { 2.26, 5.38, 1.54 }, { 2.31, 4.84, 4.90 },
    { 2.46, 3.85, 1.77 }, { 5.15, 18.62, 5.19 }, { 2.41, 5.90, 1.76 }, { 2.64, 8.19, 3.23 },
    { 2.73, 6.28, 3.48 }, { 2.21, 5.17, 1.27 }, { 4.76, 16.89, 5.92 }, { 3.00, 12.21, 4.42 },
    { 4.30, 9.17, 3.88 }, { 3.40, 10.00, 4.86 }, { 2.28, 4.57, 1.72 }, { 3.16, 13.52, 4.76 },
    { 2.27, 5.51, 1.72 }, { 3.03, 11.76, 4.01 }, { 2.41, 5.82, 1.72 }, { 2.22, 5.28, 1.47 },
    { 2.30, 5.55, 2.75 }, { 0.87, 1.40, 1.01 }, { 2.60, 6.67, 1.75 }, { 4.15, 20.04, 4.42 },
    { 3.66, 6.01, 3.28 }, { 2.29, 5.86, 1.75 }, { 4.76, 17.02, 4.30 }, { 2.42, 14.80, 3.15 },
    { 0.70, 2.19, 1.62 }, { 3.02, 9.02, 4.98 }, { 3.06, 13.51, 3.72 }, { 2.31, 5.46, 1.22 },
    { 3.60, 14.56, 3.28 }, { 5.13, 13.77, 9.28 }, { 6.61, 19.04, 13.84 }, { 3.31, 9.69, 3.63 },
    { 3.23, 9.52, 4.98 }, { 1.83, 2.60, 2.72 }, { 2.41, 6.13, 1.47 }, { 2.29, 5.71, 2.23 },
    { 10.85, 13.55, 4.44 }, { 0.69, 2.46, 1.67 }, { 0.70, 2.19, 1.62 }, { 0.69, 2.42, 1.34 },
    { 1.58, 1.54, 1.14 }, { 0.87, 1.40, 1.01 }, { 2.52, 6.17, 1.64 }, { 2.52, 6.36, 1.66 },
    { 0.70, 2.23, 1.41 }, { 2.42, 14.80, 3.15 }, { 2.66, 5.48, 2.09 }, { 1.41, 2.00, 1.71 },
    { 2.67, 9.34, 4.86 }, { 2.90, 5.40, 2.22 }, { 2.43, 6.03, 1.69 }, { 2.45, 5.78, 1.48 },
    { 11.02, 11.28, 3.28 }, { 2.67, 5.92, 1.39 }, { 2.45, 5.57, 1.74 }, { 2.25, 6.15, 1.99 },
    { 2.26, 5.26, 1.41 }, { 0.70, 1.87, 1.32 }, { 2.33, 5.69, 1.87 }, { 2.04, 6.19, 2.10 },
    { 5.34, 26.20, 7.15 }, { 1.97, 4.07, 1.44 }, { 4.34, 7.84, 4.44 }, { 2.32, 15.03, 4.67 },
    { 2.32, 12.60, 4.65 }, { 2.53, 5.69, 2.14 }, { 2.92, 6.92, 2.14 }, { 2.30, 6.32, 1.28 },
    { 2.34, 6.17, 1.78 }, { 4.76, 17.82, 3.84 }, { 2.25, 6.48, 1.50 }, { 2.77, 5.44, 1.99 },
    { 2.27, 4.75, 1.78 }, { 2.32, 15.03, 4.65 }, { 2.90, 6.59, 4.28 }, { 2.64, 7.19, 3.75 },
    { 2.28, 5.01, 1.85 }, { 0.87, 1.40, 1.01 }, { 2.34, 5.96, 1.51 }, { 2.21, 6.13, 1.62 },
    { 2.52, 6.03, 1.64 }, { 2.53, 5.69, 2.14 }, { 2.25, 5.21, 1.16 }, { 2.56, 6.59, 1.62 },
    { 2.96, 8.05, 3.33 }, { 0.70, 1.89, 1.32 }, { 0.72, 1.74, 1.12 }, { 21.21, 21.19, 5.05 },
    { 11.15, 6.15, 2.99 }, { 8.69, 9.00, 2.23 }, { 3.19, 10.06, 3.05 }, { 3.54, 9.94, 3.42 },
    { 2.59, 6.23, 1.71 }, { 2.52, 6.32, 1.64 }, { 2.43, 6.00, 1.57 }, { 20.30, 19.29, 6.94 },
    { 8.75, 14.31, 2.16 }, { 0.69, 2.46, 1.67 }, { 0.69, 2.46, 1.67 }, { 0.69, 2.47, 1.67 },
    { 3.58, 8.84, 3.64 }, { 3.04, 6.46, 3.28 }, { 2.20, 5.40, 1.25 }, { 2.43, 5.71, 1.74 },
    { 2.54, 5.55, 2.14 }, { 2.38, 5.63, 1.86 }, { 1.58, 4.23, 2.68 }, { 1.96, 3.70, 1.66 },
    { 8.61, 11.39, 4.17 }, { 2.38, 5.42, 1.49 }, { 2.18, 6.26, 1.15 }, { 2.67, 5.48, 1.58 },
    { 2.46, 6.42, 1.29 }, { 3.32, 18.43, 5.19 }, { 3.26, 16.59, 4.94 }, { 2.50, 3.86, 2.55 },
    { 2.58, 6.07, 1.50 }, { 2.26, 4.94, 1.24 }, { 2.48, 6.40, 1.70 }, { 2.38, 5.73, 1.86 },
    { 2.80, 12.85, 3.89 }, { 2.19, 4.80, 1.69 }, { 2.56, 5.86, 1.66 }, { 2.49, 5.84, 1.76 },
    { 4.17, 24.42, 4.90 }, { 2.40, 5.53, 1.42 }, { 2.53, 5.88, 1.53 }, { 2.66, 6.71, 1.76 },
    { 2.65, 6.71, 3.55 }, { 28.73, 23.48, 7.38 }, { 2.68, 6.17, 2.08 }, { 2.00, 5.13, 1.41 },
    { 3.66, 6.36, 3.28 }, { 3.66, 6.26, 3.28 }, { 2.23, 5.25, 1.75 }, { 2.27, 5.48, 1.39 },
    { 2.31, 5.40, 1.62 }, { 2.50, 5.80, 1.78 }, { 2.25, 5.30, 1.50 }, { 3.39, 18.62, 4.71 },
    { 0.87, 1.40, 1.01 }, { 2.02, 4.82, 1.50 }, { 2.50, 6.46, 1.65 }, { 2.71, 6.63, 1.58 },
    { 2.71, 4.61, 1.41 }, { 3.25, 18.43, 5.03 }, { 3.47, 21.06, 5.19 }, { 1.57, 2.32, 1.58 },
    { 1.65, 2.34, 2.01 }, { 2.93, 7.38, 3.16 }, { 1.62, 3.84, 2.50 }, { 2.49, 5.82, 1.92 },
    { 2.42, 6.36, 1.85 }, { 62.49, 61.43, 34.95 }, { 3.15, 11.78, 2.77 }, { 2.47, 6.21, 2.55 },
    { 2.66, 5.76, 2.24 }, { 0.69, 2.46, 1.67 }, { 2.44, 7.21, 3.19 }, { 1.66, 3.66, 3.21 },
    { 3.54, 15.90, 3.40 }, { 2.44, 6.53, 2.05 }, { 0.69, 2.79, 1.96 }, { 2.60, 5.76, 1.45 },
    { 3.07, 8.61, 7.53 }, { 2.25, 5.09, 2.11 }, { 3.44, 18.39, 5.03 }, { 3.18, 13.63, 4.65 },
    { 44.45, 57.56, 18.43 }, { 12.59, 13.55, 3.56 }, { 0.50, 0.92, 0.30 }, { 2.84, 13.47, 2.21 },
    { 2.41, 5.90, 1.76 }, { 2.41, 5.90, 1.76 }, { 2.41, 5.78, 1.76 }, { 2.92, 6.15, 2.14 },
    { 2.40, 6.05, 1.55 }, { 3.07, 6.96, 3.82 }, { 2.31, 5.53, 1.28 }, { 2.64, 6.07, 1.42 },
    { 2.52, 6.17, 1.64 }, { 2.38, 5.73, 1.86 }, { 2.93, 3.38, 1.97 }, { 3.01, 3.25, 1.60 },
    { 1.45, 4.65, 6.36 }, { 2.90, 6.59, 4.21 }, { 2.48, 1.42, 1.62 }, { 2.13, 3.16, 1.83 }
} ;

stock GetVehicleSize(modelID, &Float: size_X, &Float: size_Y, &Float: size_Z) // Author: RyDeR`
{
    if(400 <= modelID <= 611)
    {
        size_X = sizeData[modelID - 400][0];
        size_Y = sizeData[modelID - 400][1];
        size_Z = sizeData[modelID - 400][2];
        return 1;
    }
    return 0;
}


stock GetAttachedObjectPos(objectid, Float:offset_x, Float:offset_y, Float:offset_z, &Float:x, &Float:y, &Float:z)
{
    new Float:object_px,
        Float:object_py,
        Float:object_pz,
        Float:object_rx,
        Float:object_ry,
        Float:object_rz;
    GetObjectPos(objectid, object_px, object_py, object_pz);
    GetObjectRot(objectid, object_rx, object_ry, object_rz);
    new Float:cos_x = floatcos(object_rx, degrees),
        Float:cos_y = floatcos(object_ry, degrees),
        Float:cos_z = floatcos(object_rz, degrees),
        Float:sin_x = floatsin(object_rx, degrees),
        Float:sin_y = floatsin(object_ry, degrees),
        Float:sin_z = floatsin(object_rz, degrees);
    x = object_px + offset_x * cos_y * cos_z - offset_x * sin_x * sin_y * sin_z - offset_y * cos_x * sin_z + offset_z * sin_y * cos_z + offset_z * sin_x * cos_y * sin_z;
    y = object_py + offset_x * cos_y * sin_z + offset_x * sin_x * sin_y * cos_z + offset_y * cos_x * cos_z + offset_z * sin_y * sin_z - offset_z * sin_x * cos_y * cos_z;
    z = object_pz - offset_x * cos_x * sin_y + offset_y * sin_x + offset_z * cos_x * cos_y;
}

/*        Old Versions

	09/10/2011 - 20/01/2011: v1.0 Alpha Released
	
	Environmental missiles finished for downtown
	Fixed object sync
	Fixed delay between missile firing
	Fixed the class selecting spawn bug
	Fixed all the missile bugs
	Fixed the missile explosion bug
	Fixed machine guns for most vehicles
	Fixed remote bombs
	Server is now basically stable
	Alot of bug fixes and optimizations
	Redesigned audio system, removed Incognito's Audio Plugin, the server now uses audio streams
	Redesigned Textdraws, textdraws made to match Twisted Metal PS3's & Black's design combined, which is much simplier
	Twisted Metal PS3's textdraw system
	Burnout system added
	Fixed missile shooting recoil
	Fixed all pickups
	Fixed colours
	Fixed missile shooting
	Fixed Environmental missiles
	Gascan renamed to Napalm

	27/08/2011: v0.9 Alpha Released
	
	Vehicles lights are now automatically turned on
	Napalm finally complete, use LCTRL to fire and bring it down!
	Fixed the floating fires in the air
	New administration system! registration and login is here!
	Map system coming soon

    09/08/2011: v0.8 Alpha Released

    Roadkill special added!
	New designed audio system, users with the audio plugin may have it just like the real thing!
	Re-wrote the timer system, fixed sweet tooth's missiles and other missiles that were not working properly/going through vehicles.
	Re-wrote Roadkill's special from v0.8 alpha testing.
	Basically overall another BIG bugfix to the server.
	Increased the overall speed of certain things
	
	07/08/2011: v0.7 Alpha Released
	
	Begginging the Map changing/loading system
	Fixed a turbo bug
	Attempted to fix Sweet Tooth's special and applied it to all vehicles (meaning the fix)
	You can now scroll through the missile list correctly! if your at your last missile and click down it will go back to the first and etc!

    01/07/2011: v0.6 Alpha Released

	Sweet Tooth's special finally added! he shoots a burst of 20 missiles, you don't want to get in his way!
	Energy ("perks") removed from keyboard hitting, you now use commands
	/jump - obvious
	/freeze - shoot a freeze missle
	/invisibility - obvious
	(alpha) /remotebomb - plant a (remote) bomb on the ground, if you hit it, it exploits or can be detonated again by retyping the command
	I was over using char arrays to the max, I got so addicted to them I over using them causing alot of bugs.
	ALOT of timer and objectid bugs fixed.

    22/06/2011: v0.5 Alpha Released

	Added Automatic Flip.
    
    18/06/2011: v0.4 Alpha Released

    Random chat messages have been implemented
    Updated Colours based on vehicle selected
	Reduced Lag on vehicle selection
	Fixed Vehicle selections screen
	Fixed some Exploits

	11/06/2011: v0.3 R2 Alpha Released
	
	Looking to adding sweet tooth's special now, because fire missiles now have their slight homing ability that sweet tooth's 20 missiles have.
	Gave Fire Missiles Their "Slight" Homing Ability
	Invisility Ability Added, it takes 25% of your energy! (/invisibility)
	Missiles now won't hit invisible vehicles.
	Energy Bar is now fully functional.
	Updated Spectre's Special
	Fixed Health Pickups
	Reduced Lag.

	05/06/2011: v0.2 Alpha Released.
	
	Holding The Machine Gun Fire Key, Will Now Make Automatic Rapid Machine Gun Fire, Instead Of Clicking it Every Time.
	Crazy 8 / No Face - has been removed due to samp limitations.
	Thumper - has been added, from twisted metal 4!
	Thumper's Special Has Been Added.

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

new bool:FirstTimeOnServer[MAX_PLAYERS];

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == LoginDialog)
 	{
 	    new a_Query[128 + 12];
  		if(!response)
  		{
      		format(a_Query, sizeof(a_Query),"{a9c4e4}Welcome To Twisted Metal: SA-MP\n\n{FAF87F}Account: {FFFFFF}%s\n\n{FF0000}Please Enter Your Password Below:",Playername(playerid));
  	 		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT,"{E33667}Login To Twisted Metal: SA-MP",a_Query,"Login","Cancel");
  	 		return 1;
  		}
		if(isnull(inputtext))
		{
      		format(a_Query, sizeof(a_Query), "{a9c4e4}Welcome To Twisted Metal: SA-MP\n\n{FAF87F}Account: {FFFFFF}%s\n\n{FF0000}Please Enter Your Password Below!:",Playername(playerid));
  	 		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, "{E33667}Login To Twisted Metal: SA-MP",a_Query,"Login","Cancel");
            return 1;
		}
		if(strlen(inputtext) > 20)
		{
      		format(a_Query, sizeof(a_Query), "{a9c4e4}Welcome To Twisted Metal: SA-MP\n\n{FAF87F}Account: {FFFFFF}%s\n\n{FF0000}Your Password Must Be Less Than 20 characters!:",Playername(playerid));
  	 		ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, "{E33667}Login To Twisted Metal: SA-MP",a_Query,"Login","Cancel");
            return 1;
		}
 		new lEscape[2][MAX_PLAYER_NAME];
		mysql_real_escape_string(Playername(playerid), lEscape[0]);
		mysql_real_escape_string(inputtext, lEscape[1]);
		format(a_Query, 128, "SELECT * FROM `Accounts` WHERE `Username` = '%s' AND `Password` = '%s' LIMIT 0,1", lEscape[0], lEscape[1]);
		//mysql_query(a_Query);
  		mysql_store_result();
		new Rows = mysql_num_rows(), index = playerid;
		if(Rows == 1)
		{
		    IsLogged[index] = 1;
		    printf("%s(%d) Has Logged In", Playername(index), index);
		    printf("FirstTimeOnServer: %d", FirstTimeOnServer[playerid]);
		    if(FirstTimeOnServer[playerid] != true) FirstTimeOnServer[index] = false;
   			mysql_retrieve_row();
			new result[32];
   			mysql_get_field("Username", PlayerInfo[index][pUsername]);
   			mysql_get_field("Password", PlayerInfo[index][pPassword]);
   			mysql_get_field("IP", PlayerInfo[index][pIP]);
   			mysql_get_field("AdminLevel", result);
   			PlayerInfo[index][AdminLevel] = strval(result);
   			mysql_get_field("DonaterRank", result);
   			PlayerInfo[index][pDonaterRank] = strval(result);
   			mysql_get_field("Money", result);
   			PlayerInfo[index][Money] = strval(result);
   			mysql_get_field("Score", result);
   			PlayerInfo[index][Score] = strval(result);
   			SetPlayerScore(index, PlayerInfo[index][Score]);
   			mysql_get_field("Kills", result);
   			PlayerInfo[index][Kills] = strval(result);
   			mysql_get_field("Deaths", result);
   			PlayerInfo[index][Deaths] = strval(result);
		    mysql_free_result();

			//LoadPlayerAchievements(index);

			LoggedTimer[index] = SetTimerEx("TimeIsLogged", 1000, true, "i", index);

			new Prenium_string[9] = "";
			if(PlayerInfo[index][pDonaterRank] == 2) Prenium_string = "Premium ";
			if(PlayerInfo[index][pDonaterRank] == 0 && PlayerInfo[index][AdminLevel] == 0 && PlayerInfo[index][pRegular] == 0) SendClientMessage(index, White, "Logged In As A {30AEFC}Registered {FFFFFF}Player");
	      	else if(PlayerInfo[index][pDonaterRank] != 0 && PlayerInfo[index][AdminLevel] == 0 && PlayerInfo[index][pRegular] == 0) SendClientMessageFormatted(index, White, "Logged In As A {30AEFC}%sDonating {FFFFFF}Player", Prenium_string);
   			else if(PlayerInfo[index][pDonaterRank] != 0 && PlayerInfo[index][AdminLevel] != 0 && PlayerInfo[index][pRegular] == 0) SendClientMessageFormatted(index, White, "Logged In As A {30AEFC}%sDonating Admin", Prenium_string);
   			else if(PlayerInfo[index][pDonaterRank] != 0 && PlayerInfo[index][AdminLevel] != 0 && PlayerInfo[index][pRegular] != 0) SendClientMessageFormatted(index, White, "Logged In As A {30AEFC}%sDonating Regular Admin", Prenium_string);
   			else if(PlayerInfo[index][pDonaterRank] == 0 && PlayerInfo[index][AdminLevel] != 0 && PlayerInfo[index][pRegular] == 0) SendClientMessage(index, White, "Logged In As A {30AEFC}Admin");
   			else if(PlayerInfo[index][pDonaterRank] == 0 && PlayerInfo[index][AdminLevel] != 0 && PlayerInfo[index][pRegular] != 0) SendClientMessage(index, White, "Logged In As A {30AEFC}Regular Admin");
   			else if(PlayerInfo[index][pDonaterRank] == 0 && PlayerInfo[index][AdminLevel] == 0 && PlayerInfo[index][pRegular] != 0) SendClientMessage(index, White, "Logged In As A {30AEFC}Regular {FFFFFF}Player");
	 		else if(PlayerInfo[index][pDonaterRank] != 0 && PlayerInfo[index][AdminLevel] == 0 && PlayerInfo[index][pRegular] != 0) SendClientMessageFormatted(index, White, "Logged In As A {30AEFC}%sDonating Regular {FFFFFF}Player", Prenium_string);
			else SendClientMessage(index, White, "Logged In As A {30AEFC}Registered {FFFFFF}Player");
			printf("%s(%d) Has Successfully Logged In", Playername(index), index);

		    new pip1[17];
			GetPlayerIp(index, pip1, 17);
			format(a_Query, sizeof(a_Query), "UPDATE `Accounts` SET `IP` = '%s' WHERE `Username` = '%s' LIMIT 1", pip1, lEscape[0]);
			//mysql_query(a_Query);
			SetPlayerArmedWeapon(index, 0);
			ResetPlayerWeapons(index);
		}
  		else if(Rows > 1)
		{
		    mysql_free_result();
		    SendClientMessage(index, RED, "Error: Multiple Accounts Found - Please Report This At "#Server_Website" In The Server Bugs Section.");
			SafeKick(index, "Multiple Accounts Found.");
		}
		else
		{
  			SendClientMessage(index, RED, "Incorrect password, please try again!");
			ShowPlayerDialog(index, LoginDialog, DIALOG_STYLE_INPUT, "Login", "{FF0000}This Username Is Registered\n{FFFFFF}Please Enter Your Password Below To Login\nYou Will be Kicked If You Continue To Enter An Invalid Password", "Login", "Cancel");
   			SetPVarInt(index, "WrongPass", GetPVarInt(index, "WrongPass") + 1);
        	if(GetPVarInt(index, "WrongPass") == 3)
         	{
         	    SetPVarInt(index, "WrongPass", 0);
				SendClientMessageFormatted(INVALID_PLAYER_ID, PINK, "**(AUTO KICK)** %s(%d) Has Been Kicked From The Server - Reason: Failed To Login.", Playername(index),index);
          		SendClientMessage(index, 0xF60000AA, "Maximum incorrect passwords entered - you have been kicked.");
          		SafeKick(index, "Failing To Login");
          	}
		}
		return 1;
	}
	if(dialogid == RegDialog)
 	{
        if(isnull(inputtext) || !response) //new a_Query[128 + 12];
        {
      		format(a_Query, sizeof(a_Query), "{a9c4e4}Welcome To Twisted Metal: SA-MP: {FFFFFF}%s\n\n{FF0000}Please Enter A Password Below To Register:",Playername(playerid));
  	 		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT, "{E33667}Register An Account", a_Query, "Register", "Cancel");
            return 1;
		}
        if(strlen(inputtext) <= 3)
        {
      		format(a_Query, sizeof(a_Query),"{a9c4e4}Welcome To Twisted Metal: SA-MP: {FFFFFF}%s\n\n{FF0000}Your Password Cannot Be Less Than 4 Characters\nPlease Enter A Password 4 Or More Characters Higher To Register:",Playername(playerid));
  	 		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT,"{E33667}Register An Account",a_Query,"Register","Cancel");
            return 1;
		}
        if(strlen(inputtext) > 20)
        {
      		format(a_Query, sizeof(a_Query), "{a9c4e4}Welcome To Twisted Metal: SA-MP: {FFFFFF}%s\n\n{FF0000}Your Password Cannot Be More Than 20 Characters\nPlease Enter A Password 20 Or Less Characters Higher To Register:",Playername(playerid));
  	 		ShowPlayerDialog(playerid, RegDialog, DIALOG_STYLE_INPUT,"{E33667}Register An Account",a_Query,"Register","Cancel");
			return 1;
		}
    	if(IsLogged[playerid] == 1) return SendClientMessage(playerid, RED, "You are already logged in.");
		format(a_Query, sizeof(a_Query), "SELECT `Username` FROM `Accounts` WHERE `Username` = '%s' LIMIT 0,1", Playername(playerid));
	   	//mysql_query(a_Query);
	    mysql_store_result();
	    if(mysql_num_rows() != 0)
	 	{
	  		mysql_free_result();
	  		SendClientMessage(playerid, RED, "Error: This Account Already Exists!");
	      	return 1;
	    }
	    else
	    {
		 	new Escape[2][MAX_PLAYER_NAME];
			mysql_real_escape_string(Playername(playerid), Escape[0]); // This function makes sure you don't get MySQL injected. Read about it by searching it on google.
			mysql_real_escape_string(inputtext, Escape[1]);
			new pip[17], y, m, d, regstr[24];
			getdate(y, m, d);
			GetPlayerIp(playerid, pip, sizeof(pip));
			format(regstr,sizeof(regstr), "%02d:%02d:%04d", d, m, y);
			format(a_Query, sizeof(a_Query), "INSERT INTO `Accounts` (`Username`,`Password`,`IP`,`Money`,`Score`,`AdminLevel``Registered`) VALUES ('%s','%s','%s',10000,5,0,'%s')", Escape[0], Escape[1], pip, regstr);
			//mysql_query(a_Query);
			PlayerInfo[playerid][Money] = 15000;
			PlayerInfo[playerid][AdminLevel] = 0;
			PlayerInfo[playerid][pGender] = true;
			SetPlayerScore(playerid, 10);
			/*format(a_Query, sizeof(a_Query), "INSERT INTO `Achievements` (`Username`) VALUES ('%s')", Escape[0]);
			mysql_query(a_Query);*/
			SendClientMessageFormatted(playerid, 0x19E03DFF, "You've Successfully Registered With The Username Of %s With The Password %s.", Playername(playerid), inputtext);
	  		format(regstr, sizeof(regstr), "{a9c4e4}Welcome To Twisted Metal: SA-MP\n\n{FAF87F}Account: {FFFFFF}%s\n\nPlease Enter Your Password Below:",Playername(playerid));
	  	 	ShowPlayerDialog(playerid, LoginDialog, DIALOG_STYLE_INPUT, "{E33667}Login To Twisted Metal: SA-MP", regstr, "Login", "Cancel");
		}
	}
	return 1;
}
stock SafeKick(playerid, reason[])
{
    printf("[System] - %s(%d) Has Been Kicked For %s", Playername(playerid), playerid, reason);
    GameTextForPlayer(playerid, "~r~Kicked", 5000, 3);
 	SetPlayerInterior(playerid, playerid);
 	SetPlayerVirtualWorld(playerid, 1);
	SetCameraBehindPlayer(playerid);
    Kick(playerid);
	return 1;
}

CMD:tadmins(playerid, params[])
{
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
					case 1: AdmRank = "Trail Moderator";
					case 2: AdmRank = "Basic Moderator";
					case 3: AdmRank = "Moderator";
					case 4: AdmRank = "Master Moderator";
					case 5: AdmRank = "Trail Administrator";
					case 6: AdmRank = "Administrator";
					case 7: AdmRank = "Master Administrator";
					case 8: AdmRank = "Head Administrator";
					case 9: AdmRank = "Co-Owner";
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
CMD:world(playerid, params[])
{
	new str[60];
	format(str,sizeof(str),"Current Virtual World: %d",GetPlayerVirtualWorld(playerid));
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

Gas Can
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

Skill-based pick-ups
These weapons are important to master because they are some of the most deadly in the game, when used with um, skill, that is.
They constantly switch color, so you won't always receive the same one twice from the same spot.

SAT
A barrage of missiles spring forth from the skies with this devastating attack.
With SAT, a target appears in front of your vehicle.
It's green, and stays the same distance from your car at all times.
The object is to place the target onto an enemy and then launch the SAT weapons;
and there is a little trick.
The target is initially green, and the longer the missiles are in the sky the more powerful they become.
Each passing second they are in the air, the target turns color, from green to yellow to red.
When you hit an enemy when the target is red, you deliver extensive damage.
Press L2 to launch and then press again when the enemy is in the target.

Zoomy
With Zoomy, 10 missiles are in your hands and can be fired at any enemy.
The trick with Zoomy is that, they don't track enemies.
They fire straight ahead, and enemies can and will avoid them with all of their muster.
So, find an enemy that's traveling in a relatively straight pattern - i.e. in a hallway, passage, or tunnel, and then attack with Zoomy.
If you land all 10 onto the enemy, you're rewarded with a big damage bonus.


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
Very useful when being tracked at low energy. Very useful. Learn this one, kids.*/

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