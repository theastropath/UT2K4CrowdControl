Class UT2k4CCEffects extends Info;

var Mutator baseMutator;

const Success = 0;
const Failed = 1;
const NotAvail = 2;
const TempFail = 3;

const CCType_Test       = 0x00;
const CCType_Start      = 0x01;
const CCType_Stop       = 0x02;
const CCType_PlayerInfo = 0xE0; //Not used for us
const CCType_Login      = 0xF0; //Not used for us
const CCType_KeepAlive  = 0xFF; //Not used for us

var int behindTimer;
const BehindTimerDefault = 15;

var int speedTimer;
const SpeedTimerDefault = 60;
const SlowTimerDefault = 15;
const SingleSlowTimerDefault = 45;

var int meleeTimer;
const MeleeTimerDefault = 60;

var int vampireTimer;
const VampireTimerDefault = 60;

const MaxAddedBots = 10;
var Bot added_bots[10];
var int numAddedBots;

var int forceWeaponTimer;
const ForceWeaponTimerDefault = 60;
var class<Weapon> forcedWeapon;

var int bodyEffectTimer;
const BodyEffectTimerDefault = 60;
const BigHeadScale = 4.0;
const HiddenScale = 0.0;
const FatScale = 2.0;
const SkinnyScale = 0.5;
enum EBodyEffect
{
    BE_None,
    BE_BigHead,
    BE_Headless,
    BE_NoLimbs,
    BE_Fat,
    BE_Skinny
};
var EBodyEffect bodyEffect;

struct ZoneFriction
{
    var name zonename;
    var float friction;
};
var ZoneFriction zone_frictions[32];
const IceFriction = 0.25;
const NormalFriction = 8;
var int iceTimer;
const IceTimerDefault = 60;

struct ZoneGravity
{
    var name zonename;
    var vector gravity;
};
var ZoneGravity zone_gravities[32];
var vector NormalGravity;
var vector MoonGrav;
var int gravityTimer;
const GravityTimerDefault = 60;

struct ZoneWater
{
    var name zonename;
    var bool water;
};
var ZoneWater zone_waters[32];
var int floodTimer;
const FloodTimerDefault = 15;

struct ZoneFog
{
    var name  zonename;
    var bool  hasFog;
    var float fogStart;
    var float fogEnd;
};
var ZoneFog zone_fogs[32];
var int fogTimer;
const FogTimerDefault = 60;
const HeavyFogStart = 4.0;
const HeavyFogEnd   = 800.0;

var int bounceTimer;
const BounceTimerDefault = 60;
var Vector BouncyCastleVelocity;

var int cfgMinPlayers;

var bool bFat,bFast;
var string targetPlayer;

var bool isLocal;

replication
{
    reliable if ( Role == ROLE_Authority )
        behindTimer,speedTimer,meleeTimer,iceTimer,vampireTimer,floodTimer,forceWeaponTimer,bFat,bFast,forcedWeapon,numAddedBots,targetPlayer,GetEffectList,bodyEffectTimer,bodyEffect,gravityTimer,setLimblessScale,SetAllBoneScale,ModifyPlayer,SetPawnBoneScale,SetAllPlayerAnnouncerVoice,fogTimer,bounceTimer;
}

function Init(Mutator baseMut)
{
    local int i;
    local DeathMatch game;

    game = DeathMatch(Level.Game);
    
    baseMutator = baseMut;
    
    NormalGravity=class'PhysicsVolume'.Default.Gravity;
    //FloatGrav=vect(0,0,0.15);
    MoonGrav=vect(0,0,-100);  
    BouncyCastleVelocity=vect(0,0,600);  

    isLocal = Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer;

    for (i=0;i<MaxAddedBots;i++){
        added_bots[i]=None;
    }

    if (game!=None)
    {
        cfgMinPlayers = game.MinPlayers;
    }
    
}

function SendCCMessage(string msg)
{
    local PlayerController p;
    local color c;
    
    c.R=0;
    c.G=255;
    c.B=0;


    foreach AllActors(class'PlayerController',p){
        p.ClearProgressMessages();
        p.SetProgressTime(4);
        p.SetProgressMessage(0,msg,c);
    }

}

function Broadcast(string msg)
{
    Level.Game.Broadcast(self,msg);
    SendCCMessage(msg);
}


simulated function GetEffectList(out string effects[15], out int numEffects)
{
    local int i;

    if (behindTimer > 0) {
        effects[i]="Third-Person: "$behindTimer;
        i++;
    }
    if (speedTimer > 0) {
        if(bFast){
            effects[i]="Gotta Go Fast: "$speedTimer;
        } else {
            effects[i]="Gotta Go Slow";
            if (targetPlayer!=""){
                effects[i]=effects[i]$" ("$targetPlayer$")";
            }
            effects[i]=effects[i]$": "$speedTimer;
        }
        i++;
    }
    if (meleeTimer > 0) {
        effects[i]="Melee-Only: "$meleeTimer;
        i++;
    }
    if (gravityTimer > 0) {
        effects[i]="Low-Grav: "$gravityTimer;
        i++;
    }
    if (iceTimer > 0) {
        effects[i]="Ice Physics: "$iceTimer;
        i++;
    }
    if (floodTimer > 0) {
        effects[i]="Flood: "$floodTimer;
        i++;
    }
    if (fogTimer > 0) {
        effects[i]="Silent Hill: "$fogTimer;
        i++;
    }
    if (bounceTimer > 0) {
        effects[i]="Bouncy Castle: "$bounceTimer;
        i++;
    }
    if (vampireTimer > 0) {
        effects[i]="Vampire: "$vampireTimer;
        i++;
    }
    if (forceWeaponTimer > 0) {
        effects[i]="Forced "$forcedWeapon.default.ItemName$": "$forceWeaponTimer;
        i++;
    }
    if (bodyEffectTimer > 0) {
        if (bodyEffect==BE_BigHead){
            effects[i]="Big Head Mode: ";
        } else if (bodyEffect==BE_NoLimbs){
            effects[i]="Limbless Mode: ";
        }else if (bodyEffect==BE_Fat){
            effects[i]="Full Fat: ";
        }else if (bodyEffect==BE_Skinny){
            effects[i]="Skin and Bones: ";
        }else if (bodyEffect==BE_Headless){
            effects[i]="Headless: ";
        }
        effects[i]=effects[i]$bodyEffectTimer;
        i++;
    }

    if (numAddedBots > 0) {
        effects[i]="Added Bots: "$numAddedBots;
        i++;
    }

    numEffects=i;
}

//One Second timer updates
function PeriodicUpdates()
{
    if (behindTimer > 0) {
        behindTimer--;
        if (behindTimer <= 0) {
            StopCrowdControlEvent("third_person",true);
        } else {
            SetAllPlayersBehindView(True);
        }
    }  

    if (speedTimer > 0) {
        speedTimer--;
        if (speedTimer <= 0) {
            StopCrowdControlEvent("gotta_go_fast",true);
        }
    }  
    if (iceTimer > 0) {
        iceTimer--;
        if (iceTimer <= 0) {
            StopCrowdControlEvent("ice_physics",true);
        }
    } 
    if (meleeTimer > 0) {
        meleeTimer--;
        if (meleeTimer <= 0) {
            StopCrowdControlEvent("melee_only",true);
        }
    }  
    if (floodTimer > 0) {
        floodTimer--;
        if (floodTimer <= 0) {
            StopCrowdControlEvent("flood",true);
        }
    } 
    if (fogTimer > 0) {
        fogTimer--;
        if (fogTimer <= 0) {
            StopCrowdControlEvent("silent_hill",true);
        }
    } 
    if (bounceTimer > 0) {
        bounceTimer--;
        if (bounceTimer <= 0) {
            StopCrowdControlEvent("bouncy_castle",true);
        } else if ((bounceTimer % 2) == 0){
            BounceAllPlayers();
        }
    } 
    if (vampireTimer > 0) {
        vampireTimer--;
        if (vampireTimer <= 0) {
            StopCrowdControlEvent("vampire_mode",true);
        }
    }  
    
    if (forceWeaponTimer > 0) {
        forceWeaponTimer--;
        if (forceWeaponTimer <= 0) {
            StopCrowdControlEvent("force_weapon_use",true);
        }
    }  
    if (bodyEffectTimer > 0) {
        bodyEffectTimer--;
        if (bodyEffectTimer <= 0) {
            StopCrowdControlEvent("big_head",true);
        }
    }  
    if (gravityTimer > 0) {
        gravityTimer--;
        if (gravityTimer <= 0) {
            StopCrowdControlEvent("low_grav",true);
        }
    }  
    

}

//Updates every tenth of a second
function ContinuousUpdates()
{
    local DeathMatch game;
    
    game = DeathMatch(Level.Game);
    
    //Want to force people to melee more frequently than once a second
    if (meleeTimer > 0) {
        ForceAllPawnsToMelee();
    }
    
    if (forceWeaponTimer > 0) {
        TopUpWeaponAmmoAllPawns(forcedWeapon);
        ForceAllPawnsToSpecificWeapon(forcedWeapon);  
    }
    
    if (game!=None){
        if (numAddedBots==0 || Level.Game.bGameEnded){
            game.MinPlayers = cfgMinPlayers;
        } else {
            game.MinPlayers = Max(cfgMinPlayers+numAddedBots, game.NumPlayers + numAddedBots);
        }
    }
}



//Called every time there is a kill
function ScoreKill(Pawn Killer,Pawn Other)
{
    local int i;
    local DeathMatch game;

    game = DeathMatch(Level.Game);

    //Broadcast(Killer.Controller.GetHumanReadableName()$" just killed "$Other.Controller.GetHumanReadableName());
    
    //Check if the killed pawn is a bot that we don't want to respawn
    for (i=0;i<MaxAddedBots;i++){
        if (added_bots[i]!=None && added_bots[i]==Other) {
            added_bots[i]=None;
            numAddedBots--;
            if (game!=None)
            {
                game.MinPlayers = Max(cfgMinPlayers+numAddedBots, game.NumPlayers + game.NumBots - 1);
            }

            //Broadcast("Should be destroying added bot "$Other.Controller.GetHumanReadableName());
            Broadcast("Crowd Control viewer "$Other.Controller.GetHumanReadableName()$" has left the match");
            //Other.SpawnGibbedCarcass();
            Other.Destroy(); //This may cause issues if there are more mutators caring about ScoreKill.  Probably should schedule this deletion for later instead...
            break;
        }
    }    
}

simulated function ModifyPlayer(Pawn Other)
{
    if (bodyEffectTimer>0) {
        if (bodyEffect==BE_BigHead){
            Other.SetHeadScale(BigHeadScale);
        } else if (bodyEffect==BE_Headless){
            Other.SetHeadScale(HiddenScale);
        } else if (bodyEffect==BE_NoLimbs){
            SetLimblessScale(Other);
        } else if (bodyEffect==BE_Fat){
            SetAllBoneScale(Other,FatScale);
        } else if (bodyEffect==BE_Skinny){
            SetAllBoneScale(Other,SkinnyScale);
        }
    }

    if (speedTimer>0){
        if (bFast){
            Other.GroundSpeed = class'Pawn'.Default.GroundSpeed * 3;
        } else {
            Other.GroundSpeed = class'Pawn'.Default.GroundSpeed / 3;
        }
    }
}

simulated function SetPawnBoneScale(Pawn p, int Slot, optional float BoneScale, optional name BoneName)
{
    if (CrowdControl(baseMutator)!=None){
        CrowdControl(baseMutator).SetPawnBoneScale(p,Slot,BoneScale,BoneName);
    } else if (OfflineCrowdControl(baseMutator)!=None){
        OfflineCrowdControl(baseMutator).SetPawnBoneScale(p,Slot,BoneScale,BoneName);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                               CROWD CONTROL UTILITY FUNCTIONS                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

function vector GetDefaultZoneGravity(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_gravities); i++) {
        if( z.name == zone_gravities[i].zonename )
            return zone_gravities[i].gravity;
        if( zone_gravities[i].zonename == '' )
            break;
    }
    return NormalGravity;
}

function SaveDefaultZoneGravity(PhysicsVolume z)
{
    local int i;
    if( z.gravity.X ~= NormalGravity.X && z.gravity.Y ~= NormalGravity.Y && z.gravity.Z ~= NormalGravity.Z ) return;
    for(i=0; i<ArrayCount(zone_gravities); i++) {
        if( z.name == zone_gravities[i].zonename )
            return;
        if( zone_gravities[i].zonename == '' ) {
            zone_gravities[i].zonename = z.name;
            zone_gravities[i].gravity = z.gravity;
            return;
        }
    }
}

function float GetDefaultZoneFriction(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_frictions); i++) {
        if( z.name == zone_frictions[i].zonename )
            return zone_frictions[i].friction;
    }
    return NormalFriction;
}

function SaveDefaultZoneFriction(PhysicsVolume z)
{
    local int i;
    if( z.GroundFriction ~= NormalFriction ) return;
    for(i=0; i<ArrayCount(zone_frictions); i++) {
        if( zone_frictions[i].zonename == '' || z.name == zone_frictions[i].zonename ) {
            zone_frictions[i].zonename = z.name;
            zone_frictions[i].friction = z.GroundFriction;
            return;
        }
    }
}
function bool GetDefaultZoneWater(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_waters); i++) {
        if( z.name == zone_waters[i].zonename )
            return zone_waters[i].water;
    }
    return True;
}

function SaveDefaultZoneWater(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_waters); i++) {
        if( zone_waters[i].zonename == '' || z.name == zone_waters[i].zonename ) {
            zone_waters[i].zonename = z.name;
            zone_waters[i].water = z.bWaterVolume;
            return;
        }
    }
}
function bool GetDefaultZoneFog(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( z.name == zone_fogs[i].zonename )
            return zone_fogs[i].hasFog;
    }
    return class'PhysicsVolume'.Default.bDistanceFog;
}

function float GetDefaultZoneFogStart(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( z.name == zone_fogs[i].zonename )
            return zone_fogs[i].fogStart;
    }
    return class'PhysicsVolume'.Default.DistanceFogStart;
}

function float GetDefaultZoneFogEnd(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( z.name == zone_fogs[i].zonename )
            return zone_fogs[i].fogEnd;
    }
    return class'PhysicsVolume'.Default.DistanceFogEnd;
}

function SaveDefaultZoneFog(PhysicsVolume z)
{
    local int i;
    for(i=0; i<ArrayCount(zone_fogs); i++) {
        if( zone_fogs[i].zonename == '' || z.name == zone_fogs[i].zonename ) {
            zone_fogs[i].zonename = z.name;
            zone_fogs[i].hasFog = z.bDistanceFog;
            zone_fogs[i].fogStart = z.DistanceFogStart;
            zone_fogs[i].fogEnd = z.DistanceFogEnd;
            return;
        }
    }
}
function GiveInventoryToPawn(Class<Inventory> className, Pawn p)
{
    local Inventory inv;
    
    inv = Spawn(className);
    inv.Touch(p);
    inv.Destroy();
}

function SetAllPlayersGroundSpeed(int speed)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        //Broadcast("Speed before: "$p.GroundSpeed$"  Speed After: "$speed);
        p.GroundSpeed = speed;
    }
}

function Swap(Actor a, Actor b)
{
    local vector newloc, oldloc;
    local rotator newrot;
    local Actor abase, bbase;
    local bool AbCollideActors, AbBlockActors, AbBlockPlayers;
    local EPhysics aphysics, bphysics;

    if( a == b ) return;
    
    AbCollideActors = a.bCollideActors;
    AbBlockActors = a.bBlockActors;
    AbBlockPlayers = a.bBlockPlayers;
    a.SetCollision(false, false, false);

    oldloc = a.Location;
    newloc = b.Location;
    
    b.SetLocation(oldloc);
    a.SetCollision(AbCollideActors, AbBlockActors, AbBlockPlayers);
    
    a.SetLocation(newLoc);
    
    newrot = b.Rotation;
    b.SetRotation(a.Rotation);
    a.SetRotation(newrot);

    aphysics = a.Physics;
    bphysics = b.Physics;
    abase = a.Base;
    bbase = b.Base;

    a.SetPhysics(bphysics);
    if(abase != bbase) a.SetBase(bbase);
    b.SetPhysics(aphysics);
    if(abase != bbase) b.SetBase(abase);
}

function Pawn findRandomPawn()
{
    local int num;
    local Pawn p;
    local Pawn pawns[50];
    
    num = 0;
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            pawns[num++] = p;
        }
    }

    if( num == 0 ) return None;
    return pawns[ Rand(num) ];    
}

function RemoveAllAmmoFromPawn(Pawn p)
{
    local Inventory Inv;
    for( Inv=p.Inventory; Inv!=None; Inv=Inv.Inventory ) {
        PlayerController(p.Controller).ClientMessage("Inventory "$Inv);
        if ( Ammunition(Inv) != None ) {
            Ammunition(Inv).AmmoAmount = 0;
        } else if (Weapon(Inv)!=None){
            Weapon(Inv).AmmoCharge[0]=0;
            Weapon(Inv).AmmoCharge[1]=0;
        }
    }      
}

function class<Ammunition> GetAmmoClassByName(String ammoName)
{
    local class<Ammunition> ammoClass;
    
    switch(ammoName){
        case "assaultammo":
            ammoClass = class'AssaultAmmo';
            break;
        case "bioammo":
            ammoClass = class'BioAmmo';
            break;
        case "flakammo":
            ammoClass = class'FlakAmmo';
            break;
        case "linkammo":
            ammoClass = class'LinkAmmo';
            break;
        case "minigunammo":
            ammoClass = class'MinigunAmmo';
            break;
        case "shockammo":
            ammoClass = class'ShockAmmo';
            break;
        case "sniperammo":
            ammoClass = class'SniperAmmo';
            break;
        default:
            break;
    }
    
    return ammoClass;
}

function AddItemToPawnInventory(Pawn p, Inventory item)
{
        item.SetOwner(p);
        item.Inventory = p.Inventory;
        p.Inventory = item;
}

function bool IsWeaponRemovable(Weapon w)
{
    if (w==None){
        return False;
    }
    return w.bCanThrow;
}

function class<Weapon> GetWeaponClassByName(String weaponName)
{
    local class<Weapon> weaponClass;
    
    switch(weaponName){
        case "supershockrifle":
            weaponClass = class'SuperShockRifle';
            break;
        case "biorifle":
            weaponClass = class'BioRifle';
            break;
        case "flakcannon":
            weaponClass = class'FlakCannon';
            break;
        case "linkgun":
            weaponClass = class'LinkGun';
            break;
        case "minigun":
            weaponClass = class'Minigun';
            break;
        case "redeemer":
            weaponClass = class'Redeemer';
            break;
        case "rocketlauncher":
            weaponClass = class'RocketLauncher';
            break;
        case "shockrifle":
            weaponClass = class'ShockRifle';
            break;
        case "lightninggun":
            weaponClass = class'SniperRifle';
            break;
        case "translocator":
            weaponClass = class'Translauncher';
            break;
        default:
            break;
    }
    
    return weaponClass;
}

function Weapon GiveWeaponToPawn(Pawn p, class<Weapon> WeaponClass, optional bool bBringUp)
{
    local Weapon NewWeapon;
    local Inventory inv;

    inv = p.FindInventoryType(WeaponClass);
    if (inv != None ) {
            newWeapon = Weapon(inv);
            newWeapon.GiveAmmo(0,None,true);
            return newWeapon;
        }
        
    newWeapon = Spawn(WeaponClass);
    if ( newWeapon != None ) {
        newWeapon.GiveTo(p);
        newWeapon.GiveAmmo(0,None,true);
        //newWeapon.SetSwitchPriority(p);
        //newWeapon.WeaponSet(p);
        newWeapon.AmbientGlow = 0;
        if ( p.Controller.IsA('PlayerController') )
                    newWeapon.SetHand(PlayerController(p.Controller).Handedness);
        else
                    newWeapon.GotoState('Idle');
        if ( bBringUp ) {
            p.Controller.ClientSetWeapon(WeaponClass);
        }
    }
    return newWeapon;
}

function Weapon FindMeleeWeaponInPawnInventory(Pawn p)
{
	local actor Link;
    local Weapon weap;

	for( Link = p; Link!=None; Link=Link.Inventory )
	{
		if( Weapon(Link.Inventory) != None )
		{
            weap = Weapon(Link.Inventory);
			if (weap.bMeleeWeapon==True){
                return weap;
            }
		}
	}
    
    return None;
}

function ForcePawnToMeleeWeapon(Pawn p)
{
    local Weapon meleeweapon;
    
    if (p.Weapon == None || p.Weapon.bMeleeWeapon==True) {
        return;  //No need to do a lookup if it's already melee or nothing
    }
    
    meleeweapon = FindMeleeWeaponInPawnInventory(p);

    p.Controller.ClientSetWeapon(meleeweapon.Class);
}

function ForceAllPawnsToMelee()
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn')){
            ForcePawnToMeleeWeapon(p);
        }
    }
}

//Find highest or lowest score player.
//If multiple have the same score, it'll use the first one with that score it finds
function Pawn findPawnByScore(bool highest, int avoidTeam)
{
    local Pawn cur;
    local Pawn p;
    local bool avoid;
    
    avoid = (avoidTeam!=255);
    
    cur = None;
    foreach AllActors(class'Pawn',p) {
        if (p.IsA('StationaryPawn')){
            continue; //Skip turrets and things like that
        }
        if (p.Health<=0){
            continue; //Skip anyone who might be dead
        }
        if (p.PlayerReplicationInfo==None){
            continue; //skip em if they don't have their PRI
        }
        //Broadcast(p.Controller.GetHumanReadableName()$" is on team "$p.PlayerReplicationInfo.Team);
        if (cur==None){
            if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                cur = p;
            }
        } else {
            if (highest){
                if (cur==None || p.PlayerReplicationInfo.Score > cur.PlayerReplicationInfo.Score) {
                    if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                        cur = p;
                    }
                }
            } else {
                if (cur==None || p.PlayerReplicationInfo.Score < cur.PlayerReplicationInfo.Score) {
                    if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                        cur = p;
                    }
                }            
            }
        }
    }
    return cur;
}

function int FindTeamByTeamScore(bool HighTeam)
{
    local int i,team;
    local TeamGame game;
    team = 0;

    if (Level.Game.bTeamGame==False){
        return 255;
    }
    
    game = TeamGame(Level.Game);
    
    if (game == None){
        return 255;
    }
    
    for (i=0;i<4;i++) {
        if (HighTeam) {
            if (game.Teams[i].Score > game.Teams[team].Score){
                team = i;
            }
        } else {
            if (game.Teams[i].Score < game.Teams[team].Score){
                team = i;
            }        
        }
    }
    
    return team;
}

function int FindTeamWithLeastPlayers()
{
    local Pawn p;
    local int pCount[256]; //Technically there are team ids up to 255, but really 0 to 3 and 255 are used
    local int i;
    local int lowTeam;
    
    lowTeam = 0;
    
    if (Level.Game.bTeamGame==False){
        return 255;
    }
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn')){
            pCount[p.PlayerReplicationInfo.TeamID]++;
        }
    }
    
    for (i = 0; i < 256;i++){        
        if (pCount[i]!=0 && pCount[i] < pCount[lowTeam]) {
            lowTeam = i;
        }
    }
    //Broadcast("Lowest team is "$lowTeam);
    return lowTeam;

}


function ForcePawnToSpecificWeapon(Pawn p, class<Weapon> weaponClass)
{
    if (p.Weapon==None || p.Weapon.Class == weaponClass) {
        return;  //No need to do a lookup if it's already melee or nothing
    }
    
    p.Controller.ClientSetWeapon(weaponClass);
}

simulated function Weapon FindSpecificWeaponInPawnInventory(Pawn p,class<Weapon> weaponClass)
{
	local actor Link;

	for( Link = p; Link!=None; Link=Link.Inventory )
	{
		if( Link.Inventory!= None && Link.Inventory.Class == weaponClass )
		{
            return Weapon(Link.Inventory);
		}
	}
    
    return None;
}

function TopUpWeaponAmmoAllPawns(class<Weapon> weaponClass)
{
    local Pawn p;
    local Weapon w;
    
    foreach AllActors(class'Pawn',p) {
        if (p.IsA('StationaryPawn') || p.IsA('Spectator') || p.Health<=0){
            continue;
        }
        w=None;
        w = FindSpecificWeaponInPawnInventory(p,weaponClass);
        
        if (w!=None){
            //if (w.AmmoType!=None && w.AmmoType.AmmoAmount==0){
                w.MaxOutAmmo();
            //}
        } else {
            GiveWeaponToPawn(p,weaponClass);
        }
        
    }
}

function bool IsGameRuleActive(class<GameRules> rule)
{
    local GameRules curRule,prevRule;

    prevRule = None;
    curRule=Level.Game.GameRulesModifiers;
    while (curRule!=None){
        if (curRule.class==rule){
            return True;
        }
        prevRule = curRule;
        curRule = curRule.NextGameRules;
    }
    return False;
}

function bool AddNewGameRule(class<GameRules> rule)
{
    local GameRules newRule;

    newRule = Spawn(rule);

    if (newRule==None){
        return False;
    }

    if (Level.Game.GameRulesModifiers==None){
        Level.Game.GameRulesModifiers=newRule;
    } else {
        Level.Game.GameRulesModifiers.AddGameRules(newRule);
    }

    return True;
}

function bool RemoveGameRule(class<GameRules> rule)
{
    local GameRules curRule,prevRule,removedRule;

    prevRule = None;
    removedRule = None;
    curRule=Level.Game.GameRulesModifiers;
    while (curRule!=None && removedRule==None){
        if (curRule.class==rule){
            removedRule = curRule;
            if (prevRule!=None){
                prevRule.NextGameRules = curRule.NextGameRules;
            } else {
                Level.Game.GameRulesModifiers = curRule.NextGameRules;
            }
        } else {
            prevRule = curRule;
            curRule = curRule.NextGameRules;
        }
    }

    if (removedRule==None){
        return False;
    }

    removedRule.Destroy();

    return True;
}

simulated function ForceAllPawnsToSpecificWeapon(class<Weapon> weaponClass)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            ForcePawnToSpecificWeapon(p, weaponClass);
        }
    }
}

simulated function RestoreBodyScale()
{
    local Pawn p;
    local int i;
    foreach AllActors(class'Pawn',p){
        p.SetHeadScale(1.0);
        for(i=0;i<=20;i++)
        SetPawnBoneScale(p,i);
    }
}

simulated function SetAllBoneScale(Pawn p, float scale)
{
    
    SetPawnBoneScale(p,10,scale,'lthigh');
    SetPawnBoneScale(p,11,scale,'rthigh');
    SetPawnBoneScale(p,12,scale,'rfarm');
    SetPawnBoneScale(p,13,scale,'lfarm');
    SetPawnBoneScale(p,14,scale,'head');
    SetPawnBoneScale(p,15,scale,'spine');
    
    //p.SetBoneScale(0,scale,p.RootBone);
}

simulated function SetLimblessScale(Pawn p)
{
    SetPawnBoneScale(p,10,HiddenScale,'Bip01 L Thigh');
    SetPawnBoneScale(p,11,HiddenScale,'Bip01 R Thigh');
    //p.SetBoneScale(12,HiddenScale,'rfarm');
    //p.SetBoneScale(13,HiddenScale,'lfarm');
    SetPawnBoneScale(p,12,HiddenScale,'rshoulder');
    SetPawnBoneScale(p,13,HiddenScale,'lshoulder');
}

function SetMoonPhysics(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z)
    {
        if (enabled && Z.Gravity != MoonGrav ) {
            SaveDefaultZoneGravity(Z);
            Z.Gravity = MoonGrav;
        }
        else if ( (!enabled) && Z.Gravity == MoonGrav ) {
            Z.Gravity = GetDefaultZoneGravity(Z);
        }
    }
}

function SetIcePhysics(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z) {
        if (enabled && Z.GroundFriction != IceFriction ) {
            SaveDefaultZoneFriction(Z);
            Z.GroundFriction = IceFriction;
        }
        else if ( (!enabled) && Z.GroundFriction == IceFriction ) {
            Z.GroundFriction = GetDefaultZoneFriction(Z);
        }
    }
}

function SetFlood(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z) {
        if (enabled && Z.bWaterVolume != True ) {
            SaveDefaultZoneWater(Z);
            Z.bWaterVolume = True;
        }
        else if ( (!enabled) && Z.bWaterVolume == True ) {
            Z.bWaterVolume = GetDefaultZoneWater(Z);
        }

        if (z.bWaterVolume && z.VolumeEffect==None){
            z.VolumeEffect = EFFECT_WaterVolume(Level.ObjectPool.AllocateObject(class'EFFECT_WaterVolume'));
            z.FluidFriction=class'WaterVolume'.Default.FluidFriction;
        } else if (!z.bWaterVolume && z.VolumeEffect!=None){
            Level.ObjectPool.FreeObject(z.VolumeEffect);
            z.VolumeEffect=None;
            z.FluidFriction=class'PhysicsVolume'.Default.FluidFriction;
        }
    }
}

function SetFog(bool enabled) {
    local PhysicsVolume Z;
    ForEach AllActors(class'PhysicsVolume', Z) {
        if (enabled) {
            SaveDefaultZoneFog(Z);
            Z.bDistanceFog = True;
            Z.DistanceFogStart = HeavyFogStart;
            Z.DistanceFogEnd   = HeavyFogEnd;
        }
        else if (!enabled) {
            Z.bDistanceFog = GetDefaultZoneFog(Z);
            Z.DistanceFogStart = GetDefaultZoneFogStart(Z);
            Z.DistanceFogEnd = GetDefaultZoneFogEnd(Z);
        }
    }
}

function UpdateAllPawnsSwimState()
{
    
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        //Broadcast("State before update was "$p.GetStateName());
        if (p.Health>0){
            if (p.HeadVolume.bWaterVolume) {
                p.setPhysics(PHYS_Swimming);
                p.SetBase(None);
                p.BreathTime = p.UnderWaterTime;
            } else {
                p.setPhysics(PHYS_Falling);
                p.BreathTime = -1.0;
            }

            if (p.IsPlayerPawn()){
                PlayerController(p.Controller).EnterStartState();
            }
        }
    }
}

function BounceAllPlayers()
{
    local Pawn P;
    
    foreach AllActors(class'Pawn',P) {
        if ( (P == None) || (P.Physics == PHYS_None) || (Vehicle(P) != None) || (P.DrivenVehicle != None) || p.Base==None || p.HeadVolume.bWaterVolume) { continue; }

        if ( P.Physics == PHYS_Walking ){
            P.SetPhysics(PHYS_Falling);
        }
        P.Velocity.Z +=  BouncyCastleVelocity.Z;
        //P.Acceleration = vect(0,0,0);
    }    
}

function bool IsGameActive()
{
    return !Level.Game.bWaitingToStartMatch && !Level.Game.bGameEnded;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                CROWD CONTROL EFFECT FUNCTIONS                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



function int SuddenDeath(string viewer)
{
    local xPawn p;
    
    foreach AllActors(class'xPawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            p.Health = 1;
            p.ShieldStrength=0;
            p.SmallShieldStrength=0;
        }
    }
    
    Broadcast(viewer$" has initiated sudden death!  All health reduced to 1, no armour!");

    return Success;
}

function int FullHeal(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Health>0){
            //Don't reduce health if someone is overhealed
            if (p.Health < 100) {
                p.Health = 100;
            }
        }
    }
    
    Broadcast("Everyone has been fully healed by "$viewer$"!");
  
    return Success;
}

function int FullArmour(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        p.AddShieldStrength(150);
    }
   
    Broadcast(viewer$" has given everyone full armour!");
   
    return Success;
}

function int FullAdrenaline(string viewer)
{
    local Controller c;
    
    foreach AllActors(class'Controller',c) {
        if (c.bAdrenalineEnabled==False){
            return TempFail;
        }
        c.Adrenaline=c.AdrenalineMax;
    }
   
    Broadcast(viewer$" has given everyone full adrenaline!");
   
    return Success;
}

function int GiveHealth(string viewer,int amount)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Health>0){
            p.Health = Min(p.Health + amount,199); //Let's allow this to overheal, up to 199
        }
    }
    
    Broadcast("Everyone has been given "$amount$" health by "$viewer$"!");
    
    return Success;
}

function SetAllPlayersBehindView(bool val)
{
    local PlayerController p;
    
    foreach AllActors(class'PlayerController',p) {
        p.ClientSetBehindView(val);
    }
}

function int ThirdPerson(String viewer, int duration)
{
    if (behindTimer>0) {
        return TempFail;
    }

    SetAllPlayersBehindView(True);
    
    if (duration==0){
        duration = BehindTimerDefault;
    }
    
    behindTimer = duration;

    Broadcast(viewer$" wants you to have an out of body experience!");
  
    return Success;

}

function int GiveDamageItem(String viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        p.EnableUDamage(30);
    }
    
    Broadcast(viewer$" gave everyone a damage powerup!");
   
    return Success;
}


function int GottaGoFast(String viewer, int duration)
{
    if (speedTimer>0) {
        return TempFail;
    }

    SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed * 3);
    if (duration==0){
        duration = SpeedTimerDefault;
    }
    speedTimer = duration;
    bFast=True;
    targetPlayer="";
    Broadcast(viewer$" made everyone fast like Sonic!");
   
    return Success;   
}

function int GottaGoSlow(String viewer, int duration)
{
    if (speedTimer>0) {
        return TempFail;
    }

    SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed / 3);

    if (duration==0){
        duration = SlowTimerDefault;
    }
    speedTimer = duration;
    bFast=False;
    targetPlayer="";
    Broadcast(viewer$" made everyone slow like a snail!");
   
    return Success;   
}

function int ThanosSnap(String viewer)
{
    local Pawn p;
    //local String origDamageString;
    
    //origDamageString = Level.Game.SpecialDamageString;
    //Level.Game.SpecialDamageString = "%o got snapped by "$viewer;
    
    foreach AllActors(class'Pawn',p) {
        if (p.IsA('StationaryPawn')){
            continue;
        }
        if (Rand(2)==0){ //50% chance of death
            P.TakeDamage
            (
                10000,
                P,
                P.Location,
                Vect(0,0,0),
                class'Gibbed'				
            );
        }
    }
    
    //Level.Game.SpecialDamageString = origDamageString;
    
    Broadcast(viewer$" snapped their fingers!");
  
    return Success;

}

//Leaving this here just in case we maybe want this as a standalone effect at some point?
function int swapPlayer(string viewer) {
    local Pawn a,b;
    local int tries;
    a = None;
    b = None;
    
    tries = 0; //Prevent a runaway
    
    while (tries < 5 && (a == None || b == None || a==b)) {
        a = findRandomPawn();
        b = findRandomPawn();
        tries++;
    }
    
    if (tries == 5) {
        return TempFail;
    }
    
    Swap(a,b);
    
    
    //If we swapped a bot, get them to recalculate their logic so they don't just run off a cliff
    if (a.PlayerReplicationInfo.bBot == True && Bot(a.Controller)!=None) {
        //Bot(a).WhatToDoNext('',''); //TODO
    }
    if (b.PlayerReplicationInfo.bBot == True && Bot(b.Controller)!=None) {
        //Bot(b).WhatToDoNext('',''); //TODO
    }
    
    Broadcast(viewer@"thought "$a.Controller.GetHumanReadableName()$" would look better if they were where"@b.Controller.GetHumanReadableName()@"was");

    return Success;
}

function int SwapAllPlayers(string viewer){
    //The game expects a maximum of 16 players, but it's possible to cram more in...  Just do up to 50, for safety
    local vector locs[50];
    local rotator rots[50];
    local EPhysics phys[50];
    local Actor bases[50];
    local Pawn pawns[50];
    local int numPlayers,num;
    local Pawn p;
    local int i,newLoc;

    //Collect all the information about where pawns are currently
    //and remove their collision
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            pawns[numPlayers] = p;
            locs[numPlayers]=p.Location;
            rots[numPlayers]=p.Rotation;
            phys[numPlayers]=p.Physics;
            bases[numPlayers]=p.Base;
            numPlayers++;

            p.SetCollision(False,False,False);

            if (numPlayers==ArrayCount(Pawns)){
                break; //Hit the limit, just work amongst these ones
            }
        }
    }
    
    //Move everyone
    num = numPlayers;
    for (i=numPlayers-1;i>=0;i--){
        newLoc = Rand(num);
        //Broadcast(pawns[i].Controller.GetHumanReadableName()@"moving to location "$newLoc);
        
        pawns[i].SetLocation(locs[newLoc]);
        pawns[i].SetRotation(rots[newLoc]);
        pawns[i].SetPhysics(phys[newLoc]);
        pawns[i].SetBase(bases[newLoc]);
        
        num--;

        locs[newLoc]=locs[num];
        rots[newLoc]=rots[num];
        phys[newLoc]=phys[num];
        bases[newLoc]=bases[num];
    }

    //Re-enable collision and recalculate bot logic
    for (i=numPlayers-1;i>=0;i--){
        pawns[i].SetCollision(True,True,True);
        if (pawns[i].PlayerReplicationInfo.bBot==True && Bot(pawns[i].Controller)!=None){
            //Bot(pawns[i].Controller).WhatToDoNext('',''); //TODO
        }
    }

    Broadcast(viewer@"decided to shuffle where everyone was");

    return Success;

}


function int NoAmmo(String viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn')){
            RemoveAllAmmoFromPawn(p);
        }
    }
    
    Broadcast(viewer$" stole all your ammo!");
    
    return Success;
}


function int GiveAmmo(String viewer, String ammoName, int amount)
{
    local class<Ammunition> ammoClass;
    local Weapon w;
    local int i;
    local bool added;
    
    ammoClass = GetAmmoClassByName(ammoName);
    
    added=False;
    foreach AllActors(class'Weapon',w) {
        if (w.Owner==None) continue;
        for (i=0;i<=1;i++){
            if (w.AmmoClass[i]==ammoClass){
                if (w.AddAmmo(ammoClass.Default.InitialAmount * amount,i)){
                    added=True;
                }
            }
        }
    }

    if (!added){
        return TempFail;
    }
    
    Broadcast(viewer$" gave everybody some ammo! ("$ammoClass.default.ItemName$")");

    return Success;
}

function int doNudge(string viewer) {
    local vector newAccel;
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        newAccel.X = Rand(501)-100;
        newAccel.Y = Rand(501)-100;
        //newAccel.Z = Rand(31);
        
        //Not super happy with how this looks,
        //Since you sort of just teleport to the new position
        p.MoveSmooth(newAccel);
    }
        
    Broadcast(viewer@"nudged you a little bit");

    return Success;
}


function int DropSelectedWeapon(string viewer) {
    local Pawn p;
    local Weapon w;

    //This won't do anything if people are being forced to a weapon, so postpone it
    if (forceWeaponTimer>0) {
        return TempFail;
    }        

    foreach AllActors(class'Pawn',p) {
        if (p.IsA('StationaryPawn')){
            continue;
        }
        if (IsWeaponRemovable(p.Weapon)){
            w=p.Weapon;
            p.DeleteInventory(p.Weapon);
            w.bHidden=True;
            //w.bDeleteMe=True;
            w.Destroy();
        }
    }
    
    Broadcast(viewer$" stole your current weapon!");
   
    return Success;

}



function int GiveWeapon(String viewer, String weaponName)
{
    local class<Weapon> weaponClass;
    local Pawn p;

    weaponClass = GetWeaponClassByName(weaponName);
    
    foreach AllActors(class'Pawn',p) {  //Probably could just iterate over PlayerControllers, but...
        if (p.IsA('StationaryPawn') || p.IsA('Spectator') || p.Health<=0){
            continue;
        }
        GiveWeaponToPawn(p,weaponClass);
    }
    
    Broadcast(viewer$" gave everybody a weapon! ("$weaponClass.default.ItemName$")");
  
    return Success;
}


function int StartMeleeOnlyTime(String viewer, int duration)
{
    if (meleeTimer > 0) {
        return TempFail;
    }
    if (forceWeaponTimer>0) {
        return TempFail;
    }    
    ForceAllPawnsToMelee();
    
    Broadcast(viewer@"requests melee weapons only!");
    if (duration==0){
        duration = MeleeTimerDefault;
    }
    meleeTimer = duration;
    
    return Success;
}

function int LastPlaceShield(String viewer)
{
    local Pawn p;

    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None || p.Controller==None) {
        return TempFail;
    }
    
    //Actually give them the shield belt
    //GiveInventoryToPawn(class'UT_ShieldBelt',p);
    p.AddShieldStrength(150);

    Broadcast(viewer@"gave full armour to "$p.Controller.GetHumanReadableName()$", who is in last place!");

    return Success;
}

function int LastPlaceDamage(String viewer)
{
    local Pawn p;

    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None || p.Controller==None) {
        return TempFail;
    }
    
    //Actually give them the damage bonus
    //GiveInventoryToPawn(class'UDamage',p);
    p.EnableUDamage(30);
    
    Broadcast(viewer@"gave a Damage Amplifier to "$p.Controller.GetHumanReadableName()$", who is in last place!");

    return Success;
}

function int LastPlaceUltraAdrenaline(String viewer)
{
    local Pawn p;


    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None) {
        return TempFail;
    }

    if (p.Controller.bAdrenalineEnabled==False){
        return TempFail;
    }

    if (p.Controller.GetHumanReadableName()==""){
        return TempFail;
    }
    
    p.Controller.Adrenaline=p.Controller.AdrenalineMax;
    Spawn(class'XGame.ComboSpeed',p);    
    Spawn(class'XGame.ComboBerserk',p);    
    Spawn(class'XGame.ComboDefensive',p);    
    Spawn(class'XGame.ComboInvis',p);    

    Broadcast(viewer@"triggered all adrenaline combos for "$p.Controller.GetHumanReadableName()$", who is in last place!");

    return Success;
}

function int AllPlayersBerserk(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Controller.bAdrenalineEnabled==False){
            return TempFail;
        }
        p.Controller.Adrenaline=p.Controller.AdrenalineMax;
        Spawn(class'XGame.ComboBerserk',p);
    }
   
    Broadcast(viewer$" has made everyone berserk!");
   
    return Success;
}

function int AllPlayersInvisible(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Controller.bAdrenalineEnabled==False){
            return TempFail;
        }
        p.Controller.Adrenaline=p.Controller.AdrenalineMax;
        Spawn(class'XGame.ComboInvis',p);
    }
   
    Broadcast(viewer$" has made everyone invisible!");
   
    return Success;
}

function int AllPlayersRegen(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (p.Controller.bAdrenalineEnabled==False){
            return TempFail;
        }
        p.Controller.Adrenaline=p.Controller.AdrenalineMax;
        Spawn(class'XGame.ComboDefensive',p);
    }
   
    Broadcast(viewer$" has made everyone regenerate!");
   
    return Success;
}


function int FirstPlaceSlow(String viewer, int duration)
{
    local Pawn p;

    if (speedTimer>0) {
        return TempFail;
    }
    
    p = findPawnByScore(True,255); //Get Highest score player
    
    if (p == None) {
        return TempFail;
    }

    p.GroundSpeed = (class'Pawn'.Default.GroundSpeed / 3);
    
    if (duration == 0){
        duration = SingleSlowTimerDefault;
    }
    speedTimer = duration;
    targetPlayer=p.Controller.GetHumanReadableName();

    Broadcast(viewer$" made "$p.Controller.GetHumanReadableName()$" slow as punishment for being in first place!");

    return Success;   
}

//If teams, should find highest on winning team, and lowest on losing team
function int BlueRedeemerShell(String viewer)
{
    local Pawn high,low;
    local RedeemerProjectile missile;
    local int avoidTeam;
    
    
    high = findPawnByScore(True,FindTeamByTeamScore(False));  //Target individual player who is doing best on a team that isn't in last place
    
    if (high==None){
        return TempFail;
    }
    
    if (Level.Game.bTeamGame==True){
        avoidTeam = high.PlayerReplicationInfo.TeamID;
    } else {
        avoidTeam = 255;
    }
    
    low = findPawnByScore(False,avoidTeam);  //Find worst player who is on a different team (if a team game)
    
    if (low == None || high == low){
        return TempFail;
    }
    
    missile = Spawn(class'RedeemerProjectile',low,,high.Location);
    missile.SetOwner(low);
    missile.Instigator = low;  //Instigator is the one who gets credit for the kill
    missile.GotoState('Flying');
    missile.Explode(high.Location,high.Location);

    Broadcast(viewer$" dropped a redeemer shell on "$high.Controller.GetHumanReadableName()$"'s head, since they are in first place!");

    return Success;
}

simulated function int StartBigHeadMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    //Check if game rule is already in place, fail if it is
    //This is different from what we're doing, but would interfere
    if (IsGameRuleActive(class'BigHeadRules')){
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        changed=True;
        p.SetHeadScale(BigHeadScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"inflated everyones head!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_BigHead;
    return Success;
}

simulated function int StartHeadlessMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    //Check if game rule is already in place, fail if it is
    //This is different from what we're doing, but would interfere
    if (IsGameRuleActive(class'BigHeadRules')){
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        changed=True;
        p.SetHeadScale(HiddenScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"removed everyones head!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_Headless;
    return Success;
}

simulated function int StartLimblessMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (!isLocal){
        return TempFail;
    }

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        changed=True;
        SetLimblessScale(p);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"removed everyones limbs!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_NoLimbs;
    return Success;
}

simulated function int StartFullFatMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (!isLocal){
        return TempFail;
    }

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        changed=True;
        SetAllBoneScale(p,FatScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"Puffed everyone up!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_Fat;
    return Success;
}

simulated function int StartSkinAndBonesMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (!isLocal){
        return TempFail;
    }

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        changed=True;
        SetAllBoneScale(p,SkinnyScale);
    }

    //No pawns to change!
    if (!changed){
        return TempFail;
    }

    Broadcast(viewer@"made everyone skinny!");
    if (duration==0){
        duration = BodyEffectTimerDefault;
    }
    bodyEffectTimer = duration;
    bodyEffect=BE_Skinny;
    return Success;
}

function int StartVampireMode(string viewer, int duration)
{
    if (vampireTimer>0) {
        return TempFail;
    }

    //Check if game rule is already in place, fail if it is
    if (IsGameRuleActive(class'VampireGameRules')){
        return TempFail;
    }

    //Attempt to add the game rules, fail if it doesn't for some reason
    if (!AddNewGameRule(class'VampireGameRules')){
        return TempFail;
    }

    Broadcast(viewer@"made everyone have a taste for blood!");
    if (duration==0){
        duration = VampireTimerDefault;
    }
    vampireTimer = duration;
    return Success;
}

function int ForceWeaponUse(String viewer, String weaponName, int duration)
{
    local class<Weapon> weaponClass;
    local Pawn p;

    if (forceWeaponTimer>0) {
        return TempFail;
    }
    if (meleeTimer > 0) {
        return TempFail;
    }
    
    weaponClass = GetWeaponClassByName(weaponName);
    
    foreach AllActors(class'Pawn',p) {  //Probably could just iterate over PlayerControllers, but...
        if (p.IsA('StationaryPawn') || p.IsA('Spectator') || p.Health<=0){
            continue;
        }
        GiveWeaponToPawn(p,weaponClass);
        
    }
    if (duration==0){
        duration = ForceWeaponTimerDefault;
    }
    forceWeaponTimer = duration;
    forcedWeapon = weaponClass;
     
    Broadcast(viewer$" forced everybody to use a specific weapon! ("$forcedWeapon.default.ItemName$")");
  
    return Success;

}

function int ResetDominationControlPoints(String viewer)
{
    local xDoubleDom game;
    local xDomPoint cp;
    local bool resetAny;

    game = xDoubleDom(Level.Game);
    
    if (game == None){
        return TempFail;
    }
    
    foreach AllActors(class'xDomPoint', cp) {
        if (cp.ControllingTeam!=None && cp.bControllable){
            //Level.Game.Broadcast(self,"Control Point controlled by "$cp.ControllingTeam.TeamName);
            resetAny=True;
            cp.ResetPoint(true);
        //} else {
            //Level.Game.Broadcast(self,"Control Point controlled by nobody");
        }
    }

    //Don't trigger if none of the control points were owned yet
    if (resetAny==False){
        return TempFail;
    }
    Broadcast(viewer$" reset all the control points!");
    return Success;
}

function int ReturnCTFFlags(String viewer)
{
    local CTFGame game;
    local CTFFlag flag;
    local bool resetAny;

    game = CTFGame(Level.Game);
    
    if (game == None){
        return TempFail;
    }
    
    foreach AllActors(class'CTFFlag', flag){
        if (flag.bHome==False){
            //Specifying BeginState seems unintuitive, but it bypasses the Begin: bit of the GameObject state
            //That Begin: bit causes problems if you're standing still when this comes through, as it immediately triggers you as having touched
            //the flag and gives it back to you.  This lets the flag go back even if you're standing still
            flag.GoToState('Home','BeginState');

            //Play the audio clip!
            BroadcastLocalizedMessage( Flag.MessageClass, 3, None, None, Flag.Team );
            resetAny=True;
        }
    }

    //Don't trigger if none of the control points were owned yet
    if (resetAny==False){
        return TempFail;
    }
    Broadcast(viewer$" returned the flags!");
    return Success;
}

function int EnableMoonPhysics(string viewer, int duration)
{
    if (gravityTimer>0) {
        return TempFail;
    }
    if (duration==0){
        duration = GravityTimerDefault;
    }
    Broadcast(viewer@"reduced gravity!");
    SetMoonPhysics(True);
    gravityTimer = duration;

    return Success;
}

function int EnableIcePhysics(string viewer, int duration)
{
    if (iceTimer>0) {
        return TempFail;
    }
    
    if (duration==0){
        duration = IceTimerDefault;
    }
    
    Broadcast(viewer@"made the ground freeze!");
    SetIcePhysics(True);
    iceTimer = duration;

    return Success;
}

function int StartFlood(string viewer, int duration)
{
    if (floodTimer>0) {
        return TempFail;
    }
    Broadcast(viewer@"started a flood!");

    SetFlood(True);
    UpdateAllPawnsSwimState();
    if (duration==0){
        duration = FloodTimerDefault;
    }
    floodTimer = duration;
    return Success;
}

function int StartFog(string viewer, int duration)
{
    if (!isLocal){
        return TempFail;
    }
    if (fogTimer>0) {
        return TempFail;
    }
    Broadcast("In their restless dreams,"@viewer@"saw that town.  Silent Hill.");

    SetFog(True);
    if (duration==0){
        duration = FogTimerDefault;
    }
    fogTimer = duration;
    return Success;
}

function int StartBounce(string viewer, int duration)
{
    if (bounceTimer>0) {
        return TempFail;
    }

    Broadcast(viewer@"threw everyone into the bouncy castle!");

    if (duration==0){
        duration = BounceTimerDefault;
    }
    bounceTimer = duration;
    return Success;
}


function int PlayTaunt(string viewer, optional name tauntSeq)
{
    local UnrealPlayer p;
    local bool found;

    found=False;

    foreach AllActors(class'UnrealPlayer',p){
        if (p.Pawn==None){continue;}

        if (tauntSeq!=''){
            p.Taunt(tauntSeq);
        } else {
            p.RandomTaunt();
        }
        found=True;
    }

    if (!found){
        return TempFail;
    }

    Broadcast(viewer@"made everyone wiggle!");

    return Success;
}

function int TeamBalance(string viewer)
{
    local Pawn p;
    local TeamGame tg;
    local UnrealTeamInfo NewTeam;
    local String playerName;
    local bool found;
    
    tg=TeamGame(Level.Game);
    if (tg==None){
        return TempFail;
    }

    p = findPawnByScore(True,255); //Get Highest score player

    if (p == None || p.Controller==None || p.PlayerReplicationInfo==None) {
        return TempFail;
    }
    
    playerName = p.Controller.GetHumanReadableName();

    found=False;
    foreach AllActors(class'UnrealTeamInfo',NewTeam){
        if (newTeam!=p.Controller.PlayerReplicationInfo.Team){
            found=True;
            break;
        }
    }

    if (NewTeam==None || found==False){
        Broadcast("New team was none?");
        return TempFail;
    }

    p.Controller.StartSpot=None;

    if ( p.Controller.PlayerReplicationInfo.Team != None ) {
        p.Controller.PlayerReplicationInfo.Team.RemoveFromTeam(p.Controller);
    }

    if (NewTeam.AddToTeam(p.Controller)){
        tg.BroadcastLocalizedMessage( tg.GameMessageClass, 3, p.Controller.PlayerReplicationInfo, None, NewTeam );
    }

    p.PlayerChangedTeam();
    p.NotifyTeamChanged();
    p.Controller.Restart();

    Broadcast(viewer@"thought the teams needed to be rebalanced, so moved "$playerName$" to the other team!");

    return Success;
}

simulated function int SetAllPlayerAnnouncerVoice(string viewer, string announcer)
{
    local PlayerController pc;
    local string voiceName;
    local class<AnnouncerVoice> VoiceClass;
    
    voiceName="";
    VoiceClass = class<AnnouncerVoice>(DynamicLoadObject(announcer,class'Class'));

    foreach AllActors(class'PlayerController',pc){
        if (pc.Pawn == None || pc.Pawn.Health<=0) { continue;}
        
        pc.StatusAnnouncer.Destroy();
        pc.StatusAnnouncer = pc.Spawn(VoiceClass);
        pc.RewardAnnouncer.Destroy();
        pc.RewardAnnouncer = pc.Spawn(VoiceClass);
        pc.PrecacheAnnouncements();

        voiceName = VoiceClass.Default.AnnouncerName;
    }

    if (voiceName==""){
        return TempFail;
    }

    Broadcast(viewer@"changed the announcer to "$voiceName);

    return Success;

}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                  CROWD CONTROL EFFECT MAPPING                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

function HandleEffectSelectability(UT2k4CrowdControlLink ccLink)
{
    ccLink.sendEffectSelectability("full_fat",isLocal);
    ccLink.sendEffectSelectability("skin_and_bones",isLocal);
    ccLink.sendEffectSelectability("limbless",isLocal);
    ccLink.sendEffectSelectability("silent_hill",isLocal);

    ccLink.sendEffectSelectability("reset_domination_control_points",xDoubleDom(Level.Game)!=None);
    ccLink.sendEffectSelectability("return_ctf_flags",CTFGame(Level.Game)!=None);
    ccLink.sendEffectSelectability("team_balance",TeamGame(Level.Game)!=None);
}

function int BranchCrowdControlType(string code, string param[5], string viewer, int type, int duration) {
    local int result;

    switch (type){
        case CCType_Start:
            result = doCrowdControlEvent(code,param,viewer,type,duration);
            break;
        case CCType_Stop:
            if (code==""){
                //Stop all
                StopAllCrowdControlEvents();
            } else {
                //Stop specific effect
                result = StopCrowdControlEvent(code);
            }
            break;
        default:
            result = Failed;
            break;
    }

    return result;
}

//Make sure to add any timed effects into this list
function StopAllCrowdControlEvents()
{
    StopCrowdControlEvent("third_person");
    StopCrowdControlEvent("gotta_go_fast"); //and gotta_go_slow, first_place_slow
    StopCrowdControlEvent("ice_physics");
    StopCrowdControlEvent("melee_only"); //and all forced weapon modes
    StopCrowdControlEvent("vampire_mode");
    StopCrowdControlEvent("big_head"); //and all body horror effects
    StopCrowdControlEvent("low_grav");
    StopCrowdControlEvent("flood");
    StopCrowdControlEvent("silent_hill");
    StopCrowdControlEvent("bouncy_castle");
}

function int StopCrowdControlEvent(string code, optional bool bKnownStop)
{
    switch(code) {
        case "third_person":
            if (bKnownStop || behindTimer > 0){
                SetAllPlayersBehindView(False);
                Broadcast("Returning to first person view...");
                behindTimer=0;
            }
            break;
        case "gotta_go_fast":
        case "gotta_go_slow":
        case "first_place_slow":
            if (bKnownStop || speedTimer > 0){
                SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed);
                Broadcast("Returning to normal move speed...");
                speedTimer=0;
            }
            break;
        case "ice_physics":
            if (bKnownStop || iceTimer > 0){
                SetIcePhysics(False);
                Broadcast("The ground thaws...");
                iceTimer=0;
            }
            break;
        case "melee_only":
            if (bKnownStop || meleeTimer > 0){
                Broadcast("You may use ranged weapons again...");
                meleeTimer=0;
            }
            break;
        case "force_weapon_use":
        case "force_instagib":
        case "force_redeemer":
            if (bKnownStop || forceWeaponTimer > 0){
                Broadcast("You can use any weapon again...");
                forcedWeapon = None;
                forceWeaponTimer=0;
            }
            break;
        case "vampire_mode":
            if (bKnownStop || vampireTimer > 0){
                RemoveGameRule(class'VampireGameRules');
                Broadcast("You no longer feed on the blood of others...");
                vampireTimer=0;
            }
            break;
        case "big_head":
        case "headless":
        case "limbless":
        case "full_fat":
        case "skin_and_bones":
            if (bKnownStop || bodyEffectTimer > 0){
                Broadcast("Your body returns to normal...");
                RestoreBodyScale();
                BodyEffect = BE_None;
                bodyEffectTimer=0;
            }
            break;
        case "low_grav":
            if (bKnownStop || gravityTimer > 0){
                SetMoonPhysics(False);
                Broadcast("Gravity returns to normal...");
                gravityTimer=0;
            }
            break;
        case "flood":
            if (bKnownStop || floodTimer > 0){
                SetFlood(False);
                UpdateAllPawnsSwimState();
                Broadcast("The flood drains away...");
                floodTimer=0;
            }
            break;
        case "silent_hill":
            if (bKnownStop || fogTimer > 0){
                SetFog(False);
                Broadcast("The fog drifts away...");
                fogTimer=0;
            }
            break;
        case "bouncy_castle":
            if (bKnownStop || bounceTimer > 0){
                Broadcast("The bouncy castle disappeared...");
                bounceTimer=0;
            }
            break;
    }
    return Success;
}

//Effects missing that were in UT99
//Spawn a bot (attack/defend)

//Ideas that could be added:
//-Spawn a vehicle (all the ONSVehicle types, I guess) - would need various space checks and stuff
//-Play a (random?) announcement

simulated function int doCrowdControlEvent(string code, string param[5], string viewer, int type, int duration) {
    
    //Universal checks
    if(!IsGameActive()){ //Only allow effects while the game is actually active
        return TempFail;
    }
    
    switch(code) {
        case "sudden_death":  //Everyone loses all armour and goes down to one health
            return SuddenDeath(viewer);
        case "full_heal":  //Everyone gets brought up to 100 health (not brought down if overhealed though)
            return FullHeal(viewer);
        case "full_armour": //Everyone gets a shield belt
            return FullArmour(viewer);
        case "full_adrenaline":
            return FullAdrenaline(viewer);
        case "give_health": //Give an arbitrary amount of health.  Allows overhealing, up to 199
            return GiveHealth(viewer,Int(param[0]));
        case "third_person":  //Switches to behind view for everyone
            return ThirdPerson(viewer,duration);
        case "bonus_dmg":   //Gives everyone a damage bonus item (triple damage)
            return GiveDamageItem(viewer);
        case "gotta_go_fast":  //Makes everyone really fast for a minute
            return GottaGoFast(viewer, duration);
        case "gotta_go_slow":  //Makes everyone really slow for 15 seconds (A minute was too much!)
            return GottaGoSlow(viewer, duration);
        case "thanos":  //Every player has a 50% chance of being killed
            return ThanosSnap(viewer);
        case "swap_player_position":  //Picks two random players and swaps their positions
            return SwapAllPlayers(viewer); //Swaps ALL players
        case "no_ammo":  //Removes all ammo from all players
            return NoAmmo(viewer); 
        case "give_ammo":  //Gives X boxes of a particular ammo type to all players
            return giveAmmo(viewer,param[0],Int(param[1]));
        case "nudge":  //All players get nudged slightly in a random direction
            return doNudge(viewer);
        case "drop_selected_item":  //Destroys the currently equipped weapon (Except for melee, translocator, and enforcers)
            return DropSelectedWeapon(viewer);
        case "give_weapon":  //Gives all players a specific weapon
            return GiveWeapon(viewer,param[0]);
        case "give_instagib":  //This is separate so that it can be priced differently
            return GiveWeapon(viewer,"supershockrifle");
        case "give_redeemer":  //This is separate so that it can be priced differently
            return GiveWeapon(viewer,"redeemer");
        case "melee_only": //Force everyone to use melee for the duration (continuously check weapon and switch to melee choice)
            return StartMeleeOnlyTime(viewer,duration);
        case "last_place_shield": //Give last place player a shield belt
            return LastPlaceShield(viewer);
        case "last_place_bonus_dmg": //Give last place player a bonus damage item
            return LastPlaceDamage(viewer);
        case "first_place_slow": //Make the first place player really slow   
            return FirstPlaceSlow(viewer, duration);
        case "blue_redeemer_shell": //Blow up first place player
            return BlueRedeemerShell(viewer);
        case "vampire_mode":  //Inflicting damage heals you for the damage dealt
            return StartVampireMode(viewer, duration);
        case "force_weapon_use": //Give everybody a weapon, then force them to use it for the duration.  Ammo tops up if run out  
            return ForceWeaponUse(viewer,param[0],duration);
        case "force_instagib": //Give everybody an enhanced shock rifle, then force them to use it for the duration.  Ammo tops up if run out  
            return ForceWeaponUse(viewer,"supershockrifle",duration);
        case "force_redeemer": //Give everybody a redeemer, then force them to use it for the duration.  Ammo tops up if run out  
            return ForceWeaponUse(viewer,"redeemer",duration);
        case "reset_domination_control_points":
            return ResetDominationControlPoints(viewer);
        case "return_ctf_flags":
            return ReturnCTFFlags(viewer);
        case "big_head":
            return StartBigHeadMode(viewer,duration);
        case "headless":
            return StartHeadlessMode(viewer,duration);
        case "limbless":
            return StartLimblessMode(viewer,duration); //TODO: Make this work in multiplayer somehow
        case "full_fat":
            return StartFullFatMode(viewer,duration); //TODO: Make this work in multiplayer somehow
        case "skin_and_bones":
            return StartSkinAndBonesMode(viewer,duration); //TODO: Make this work in multiplayer somehow
        case "low_grav":
            return EnableMoonPhysics(viewer, duration); 
        case "ice_physics":
            return EnableIcePhysics(viewer, duration);
        case "flood":
            return StartFlood(viewer, duration);
        case "last_place_ultra_adrenaline":
            return LastPlaceUltraAdrenaline(viewer);
        case "all_berserk":
            return AllPlayersBerserk(viewer);
        case "all_invisible":
            return AllPlayersInvisible(viewer);
        case "all_regen":
            return AllPlayersRegen(viewer);
        case "thrust":
            return PlayTaunt(viewer,'PThrust'); //Not super happy with this - needs more tweaking
        case "team_balance":
            return TeamBalance(viewer);
        case "announcer_male":
            return SetAllPlayerAnnouncerVoice(viewer,"UnrealGame.MaleAnnouncer"); //TODO: Make this work in multiplayer somehow
        case "announcer_female":
            return SetAllPlayerAnnouncerVoice(viewer,"UnrealGame.FemaleAnnouncer");//TODO: Make this work in multiplayer somehow
        case "announcer_ut2k3":
            return SetAllPlayerAnnouncerVoice(viewer,"UnrealGame.ClassicAnnouncer");//TODO: Make this work in multiplayer somehow
        case "announcer_ut99":
            return SetAllPlayerAnnouncerVoice(viewer,"UnrealGame.UTClassicAnnouncer");//TODO: Make this work in multiplayer somehow
        case "announcer_sexy":
            return SetAllPlayerAnnouncerVoice(viewer,"UnrealGame.SexyFemaleAnnouncer");//TODO: Make this work in multiplayer somehow
        case "silent_hill":
            return StartFog(viewer, duration);//TODO: Make this work in multiplayer somehow
        case "bouncy_castle":
            return StartBounce(viewer, duration); 
        default:
            Broadcast("Got Crowd Control Effect -   code: "$code$"   viewer: "$viewer );
            break;
        
    }
    
    return Success;
}

defaultproperties
{
      bHidden=True
      bAlwaysRelevant=True
      bNetTemporary=False
      RemoteRole=ROLE_SimulatedProxy
      NetUpdateFrequency=4.000000
}
