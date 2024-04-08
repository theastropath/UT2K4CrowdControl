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

var int cfgMinPlayers;

var bool bFat,bFast;
var string targetPlayer;

replication
{
    reliable if ( Role == ROLE_Authority )
        behindTimer,speedTimer,meleeTimer,vampireTimer,forceWeaponTimer,bFat,bFast,forcedWeapon,numAddedBots,targetPlayer,GetEffectList;
}

function Init(Mutator baseMut)
{
    local int i;
    local DeathMatch game;

    game = DeathMatch(Level.Game);
    
    baseMutator = baseMut;
    
    //NormalGravity=vect(0,0,-950);
    //FloatGrav=vect(0,0,0.15);
    //MoonGrav=vect(0,0,-100);  
    
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
    if (vampireTimer > 0) {
        effects[i]="Vampire: "$vampireTimer;
        i++;
    }
    if (forceWeaponTimer > 0) {
        effects[i]="Forced "$forcedWeapon.default.ItemName$": "$forceWeaponTimer;
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
    if (meleeTimer > 0) {
        meleeTimer--;
        if (meleeTimer <= 0) {
            Broadcast("You may use ranged weapons again...");
        }
    }  

    if (vampireTimer > 0) {
        vampireTimer--;
        if (vampireTimer <= 0) {
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


function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, 
						out Vector Momentum, name DamageType)
{
    //Broadcast(InstigatedBy.PlayerReplicationInfo.PlayerName$" inflicted "$ActualDamage$" damage to "$Victim.PlayerReplicationInfo.PlayerName);
    
    //Check if vampire mode timer is running, and if it is, do the vampire thing
    //Don't allow healing off of damage to yourself
    if (vampireTimer > 0 && InstigatedBy!=None && Victim!=InstigatedBy) {
        InstigatedBy.Health += (ActualDamage/2); //Don't heal the full amount of damage
        
        //Don't let it overheal
        if (InstigatedBy.Health > 199) {
            InstigatedBy.Health = 199;
        }
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                               CROWD CONTROL UTILITY FUNCTIONS                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

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


function int StartVampireMode(string viewer, int duration)
{
    if (vampireTimer>0) {
        return TempFail;
    }
    Broadcast(viewer@"made everyone have a taste for blood!");
    if (duration==0){
        duration = VampireTimerDefault;
    }
    vampireTimer = duration;
    return Success;
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                  CROWD CONTROL EFFECT MAPPING                                       ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Effects missing that were in UT99
//Full Fat
//Skin and Bones
//Ice Physics
//Low Grav
//Flood
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
        //case "vampire_mode":  //Inflicting damage heals you for the damage dealt (Can grab damage via MutatorTakeDamage)
        //    return StartVampireMode(viewer, duration);  //TODO: Will need to make a GameRules (or use a pre-existing one from the vampire mutator?) and apply it to the game for the duration of this effect
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
