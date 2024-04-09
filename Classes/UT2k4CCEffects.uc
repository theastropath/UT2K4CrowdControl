Class UT2k4CCEffects extends Info;

var Mutator baseMutator;

const Success = 0;
const Failed = 1;
const NotAvail = 2;
const TempFail = 3;

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

var int cfgMinPlayers;

var bool bFat,bFast;
var string targetPlayer;

replication
{
    reliable if ( Role == ROLE_Authority )
        behindTimer,speedTimer,meleeTimer,iceTimer,vampireTimer,floodTimer,forceWeaponTimer,bFat,bFast,forcedWeapon,numAddedBots,targetPlayer,GetEffectList,bodyEffectTimer,bodyEffect,gravityTimer;
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
            SetAllPlayersBehindView(False);
            Broadcast("Returning to first person view...");
        } else {
            SetAllPlayersBehindView(True);
        }
    }  

    if (speedTimer > 0) {
        speedTimer--;
        if (speedTimer <= 0) {
            SetAllPlayersGroundSpeed(class'Pawn'.Default.GroundSpeed);
            Broadcast("Returning to normal move speed...");
        }
    }  
    if (iceTimer > 0) {
        iceTimer--;
        if (iceTimer <= 0) {
            SetIcePhysics(False);
            Broadcast("The ground thaws...");
        }
    } 
    if (meleeTimer > 0) {
        meleeTimer--;
        if (meleeTimer <= 0) {
            Broadcast("You may use ranged weapons again...");
        }
    }  
    if (floodTimer > 0) {
        floodTimer--;
        if (floodTimer <= 0) {
            SetFlood(False);
            UpdateAllPawnsSwimState();

            Broadcast("The flood drains away...");
        }
    } 
    if (vampireTimer > 0) {
        vampireTimer--;
        if (vampireTimer <= 0) {
            RemoveGameRule(class'VampireGameRules');
            Broadcast("You no longer feed on the blood of others...");
        }
    }  
    
    if (forceWeaponTimer > 0) {
        forceWeaponTimer--;
        if (forceWeaponTimer <= 0) {
            Broadcast("You can use any weapon again...");
            forcedWeapon = None;
        }
    }  
    if (bodyEffectTimer > 0) {
        bodyEffectTimer--;
        if (bodyEffectTimer <= 0) {
            Broadcast("Your body returns to normal...");
            RestoreBodyScale();
            BodyEffect = BE_None;
        }
    }  
    if (gravityTimer > 0) {
        gravityTimer--;
        if (gravityTimer <= 0) {
            SetMoonPhysics(False);
            Broadcast("Gravity returns to normal...");
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

    //Broadcast(Killer.PlayerReplicationInfo.PlayerName$" just killed "$Other.PlayerReplicationInfo.PlayerName);
    
    //Check if the killed pawn is a bot that we don't want to respawn
    for (i=0;i<MaxAddedBots;i++){
        if (added_bots[i]!=None && added_bots[i]==Other) {
            added_bots[i]=None;
            numAddedBots--;
            if (game!=None)
            {
                game.MinPlayers = Max(cfgMinPlayers+numAddedBots, game.NumPlayers + game.NumBots - 1);
            }

            //Broadcast("Should be destroying added bot "$Other.PlayerReplicationInfo.PlayerName);
            Broadcast("Crowd Control viewer "$Other.PlayerReplicationInfo.PlayerName$" has left the match");
            //Other.SpawnGibbedCarcass();
            Other.Destroy(); //This may cause issues if there are more mutators caring about ScoreKill.  Probably should schedule this deletion for later instead...
            break;
        }
    }    
}

function ModifyPlayer(Pawn Other)
{
    if (bodyEffectTimer>0) {
        if (bodyEffect==BE_BigHead){
            Other.SetHeadScale(BigHeadScale);
        } else if (bodyEffect==BE_Headless){
            Other.SetHeadScale(HiddenScale);
        } else if (bodyEffect==BE_NoLimbs){
            Other.SetBoneScale(0,HiddenScale,'lthigh');
            Other.SetBoneScale(1,HiddenScale,'rthigh');
            Other.SetBoneScale(2,HiddenScale,'rfarm');
            Other.SetBoneScale(3,HiddenScale,'lfarm');
        } else if (bodyEffect==BE_Fat){
            SetAllBoneScale(Other,FatScale);
        } else if (bodyEffect==BE_Skinny){
            SetAllBoneScale(Other,SkinnyScale);
        }
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
        case "flakammo":
            ammoClass = class'FlakAmmo';
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
			p.Weapon.GotoState('DownWeapon');
			p.PendingWeapon = None;
			p.Weapon = newWeapon;
			p.Weapon.BringUp();
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
    
    p.Weapon.GotoState('DownWeapon');
	p.PendingWeapon = None;
	p.Weapon = meleeweapon;
	p.Weapon.BringUp();
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
        //Broadcast(p.PlayerReplicationInfo.PlayerName$" is on team "$p.PlayerReplicationInfo.Team);
        if (cur==None){
            if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                cur = p;
            }
        } else {
            if (highest){
                if (p.PlayerReplicationInfo.Score > cur.PlayerReplicationInfo.Score) {
                    if (avoid==False || (avoid==True && p.PlayerReplicationInfo.TeamID!=avoidTeam)) {
                        cur = p;
                    }
                }
            } else {
                if (p.PlayerReplicationInfo.Score < cur.PlayerReplicationInfo.Score) {
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
    local Weapon specificweapon;
    
    if (p.Weapon.Class == weaponClass) {
        return;  //No need to do a lookup if it's already melee or nothing
    }
    
    specificweapon = FindSpecificWeaponInPawnInventory(p, weaponClass);
    
    p.Weapon.GotoState('DownWeapon');
	p.PendingWeapon = None;
	p.Weapon = specificweapon;
	p.Weapon.BringUp();
}

function Weapon FindSpecificWeaponInPawnInventory(Pawn p,class<Weapon> weaponClass)
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

function ForceAllPawnsToSpecificWeapon(class<Weapon> weaponClass)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            ForcePawnToSpecificWeapon(p, weaponClass);
        }
    }
}

function RestoreBodyScale()
{
    local Pawn p;
    local int i;
    foreach AllActors(class'Pawn',p){
        for(i=0;i<=5;i++)
        p.SetBoneScale(i,1.0);
    }
}

function SetAllBoneScale(Pawn p, float scale)
{
    p.SetBoneScale(0,scale,'lthigh');
    p.SetBoneScale(1,scale,'rthigh');
    p.SetBoneScale(2,scale,'rfarm');
    p.SetBoneScale(3,scale,'lfarm');
    p.SetBoneScale(4,scale,'head');
    p.SetBoneScale(5,scale,'spine');
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

function UpdateAllPawnsSwimState()
{
    
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        //Broadcast("State before update was "$p.GetStateName());
        if (p.Health>0){
            if (p.HeadVolume.bWaterVolume) {
                p.setPhysics(PHYS_Swimming);
                p.SetBase(None);
            } else {
                p.setPhysics(PHYS_Falling);
            }

            if (p.IsPlayerPawn()){
                PlayerController(p.Controller).EnterStartState();
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                CROWD CONTROL EFFECT FUNCTIONS                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



function int SuddenDeath(string viewer)
{
    local Pawn p;
    
    foreach AllActors(class'Pawn',p) {
        if (!p.IsA('StationaryPawn') && p.Health>0){
            p.Health = 1;
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
        p.BehindView(val);
    }
}

function int ThirdPerson(String viewer, int duration)
{
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
    
    Broadcast(viewer@"thought "$a.PlayerReplicationInfo.PlayerName$" would look better if they were where"@b.PlayerReplicationInfo.PlayerName@"was");

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
        //Broadcast(pawns[i].PlayerReplicationInfo.PlayerName@"moving to location "$newLoc);
        
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
    local Pawn p;
    local Inventory inv;
    local Ammunition amm;
    
    ammoClass = GetAmmoClassByName(ammoName);
    
    foreach AllActors(class'Pawn',p) {
        inv = p.FindInventoryType(ammoClass);
        
        if (inv == None) {
            inv = Spawn(ammoClass);
            amm = Ammunition(inv);
            AddItemToPawnInventory(p,inv);
            
            if (amount > 1) {
                amm.AddAmmo((amount-1)*amm.Default.AmmoAmount);    
            }
            
        } else {
            amm = Ammunition(inv);
            amm.AddAmmo(amount*amm.Default.AmmoAmount);  //Add the equivalent of picking up that many boxes
        }
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
    if (p == None) {
        return TempFail;
    }
    
    //Actually give them the shield belt
    //GiveInventoryToPawn(class'UT_ShieldBelt',p);
    p.AddShieldStrength(150);

    Broadcast(viewer@"gave full armour to "$p.PlayerReplicationInfo.PlayerName$", who is in last place!");

    return Success;
}

function int LastPlaceDamage(String viewer)
{
    local Pawn p;

    p = findPawnByScore(False,255); //Get lowest score player
    if (p == None) {
        return TempFail;
    }
    
    //Actually give them the damage bonus
    //GiveInventoryToPawn(class'UDamage',p);
    p.EnableUDamage(30);
    
    Broadcast(viewer@"gave a Damage Amplifier to "$p.PlayerReplicationInfo.PlayerName$", who is in last place!");

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
    targetPlayer=p.PlayerReplicationInfo.PlayerName;

    Broadcast(viewer$" made "$p.PlayerReplicationInfo.PlayerName$" slow as punishment for being in first place!");

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

    Broadcast(viewer$" dropped a redeemer shell on "$high.PlayerReplicationInfo.PlayerName$"'s head, since they are in first place!");

    return Success;
}

function int StartBigHeadMode(string viewer, int duration)
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

function int StartHeadlessMode(string viewer, int duration)
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

function int StartLimblessMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

    if (bodyEffectTimer>0) {
        return TempFail;
    }

    foreach AllActors(class'Pawn',p){
        changed=True;
        p.SetBoneScale(0,HiddenScale,'lthigh');
        p.SetBoneScale(1,HiddenScale,'rthigh');
        p.SetBoneScale(2,HiddenScale,'rfarm');
        p.SetBoneScale(3,HiddenScale,'lfarm');
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

function int StartFullFatMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

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

function int StartSkinAndBonesMode(string viewer, int duration)
{
    local Pawn p;
    local bool changed;

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
            //This needs to call Drop first
            //Since the "Held" state appears to ignore SendHome
            flag.Drop(vect(0,0,0)); //In case it's being held
            flag.SendHome();
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                  CROWD CONTROL EFFECT MAPPING                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Effects missing that were in UT99
//Spawn a bot (attack/defend)
function int doCrowdControlEvent(string code, string param[5], string viewer, int type, int duration) {
    switch(code) {
        case "sudden_death":  //Everyone loses all armour and goes down to one health
            return SuddenDeath(viewer);
        case "full_heal":  //Everyone gets brought up to 100 health (not brought down if overhealed though)
            return FullHeal(viewer);
        case "full_armour": //Everyone gets a shield belt
            return FullArmour(viewer);
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
        //case "give_ammo":  //Gives X boxes of a particular ammo type to all players
        //    return giveAmmo(viewer,param[0],Int(param[1]));  //TODO: Will need to figure out best way to handle ammo stuff
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
            return StartLimblessMode(viewer,duration);
        case "full_fat":
            return StartFullFatMode(viewer,duration);
        case "skin_and_bones":
            return StartSkinAndBonesMode(viewer,duration);
        case "low_grav":
            return EnableMoonPhysics(viewer, duration); 
        case "ice_physics":
            return EnableIcePhysics(viewer, duration);
        case "flood":
            return StartFlood(viewer, duration);
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
}
