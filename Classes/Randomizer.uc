class Randomizer extends Mutator;

var config bool bShuffleSupers, bShuffleWeapons, bShuffleHealth, bShuffleAmmo, bShuffleAdrenaline, bShuffleOther,bShuffleWeaponsWithOthers, bRandomWeaponLockers, bSuperWeaponsInLockers;


function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
    if (bShuffleWeaponsWithOthers && xWeaponBase(Other) != None ){
        return false; //Just despawn them, we've already replaced them
    }

    return True;
}

function ReplaceWeaponBases()
{
    local xWeaponBase weapBase;
    local RandoWeaponBase rwb;

    foreach AllActors(class'xWeaponBase',weapBase){
        rwb=Spawn(class'RandoWeaponBase',weapBase.Owner,weapBase.tag,weapBase.Location,weapBase.Rotation);
        rwb.SetWeaponType(weapBase.WeaponType);
    }
}

function InitRando()
{
    if (bShuffleWeaponsWithOthers){
        ReplaceWeaponBases();
    }
    ShuffleItems(self);
}

function ShuffleItems(Actor a)
{
    local xPickupBase item, bases[128],weapons[128];
    local Pickup pick,pickups[256];
    local WeaponLocker locker;
    local int num_bases, num_weapons, num_pickups, i, slot;

    foreach a.AllActors(class'xPickupBase', item) {
        if(item.Owner != None) continue;
        //if(item.bStatic){continue;} //Can't move static things
        if (xWeaponBase(item)!=None){
            if (!bShuffleWeapons){continue;}
            if (!bShuffleSupers && (xWeaponBase(item).WeaponType.Default.InventoryGroup==0)){continue;}
            if (bShuffleWeaponsWithOthers){continue;}
            weapons[num_weapons++] = item;
            //log("shuffling weapon base "$item);
        } else if (WildcardBase(item)!=None){
            continue; //Ignore these for now, until we come up with a better solution
        } else {
            if(!bShuffleHealth){
                if (HealthCharger(item)!=None){continue;}
                if (ShieldCharger(item)!=None){continue;}
                if (SuperHealthCharger(item)!=None){continue;}
                if (SuperShieldCharger(item)!=None){continue;}
            }
            if (!bShuffleOther){
                if (UDamageCharger(item)!=None){continue;}
            }
            if (RandoWeaponBase(item)!=None){
                if (!bShuffleWeapons) {continue;}
                if (!bShuffleSupers && RandoWeaponBase(item).isSuper){continue;}
            }
            bases[num_bases++] = item;
            //log("shuffling pickup base "$item);
        }
    }

    foreach a.AllActors(class'Pickup',pick){
        if (pick.Owner != None) continue;
        if (pick.bStatic){continue;} //Can't move static things
        if (!bShuffleAmmo && Ammo(pick)!=None){continue;}
        if (!bShuffleAdrenaline && AdrenalinePickup(pick)!=None){continue;}
        if (!bShuffleHealth && (TournamentHealth(pick)!=None || ShieldPickup(pick)!=None)){continue;}
        pickups[num_pickups++] = pick;
        //log("shuffling pickup "$pick);
        pick.RemoveFromNavigation(); //Take them out of the navigation info (not *totally* sure what this means)
    }

    for(i=0; i<num_bases; i++) {
        slot = Rand(num_bases);
        if(slot != i)
            SwapPickupBases(bases[i], bases[slot]);
    }

    for(i=0; i<num_weapons; i++) {
        slot = Rand(num_weapons);
        if(slot != i)
            SwapPickupBases(weapons[i], weapons[slot]);
    }

    for(i=0; i<num_pickups; i++) {
        slot = Rand(num_pickups);
        if(slot != i)
            SwapActors(pickups[i], pickups[slot]);
    }

    //All the pickups have been moved, add them back into the navigation info
    for(i=0; i<num_pickups; i++) {
        pickups[i].AddToNavigation(); //Add them back to the navigation info (so that, I guess, NPCs recalculate their paths)
    }

    if (bRandomWeaponLockers){
        foreach a.AllActors(class'WeaponLocker', locker) {
            for (i=0;i<locker.Weapons.Length;i++){
                locker.Weapons[i].WeaponClass=PickRandomWeaponClass();
            }
        }
    }

}

function class<Weapon> PickRandomWeaponClass()
{
    local int numWeaponTypes;

    numWeaponTypes=10;

    if (bSuperWeaponsInLockers){
        numWeaponTypes+=2; //Redeemer and instagib rifle
    }

    switch(Rand(numWeaponTypes)){
        case 0:
            return class'BioRifle';
        case 1:
            return class'FlakCannon';
        case 2:
            return class'LinkGun';
        case 3:
            return class'Minigun';
        case 4:
            return class'RocketLauncher';
        case 5:
            return class'ShockRifle';
        case 6:
            return class'SniperRifle';
        case 7:
            return class'ONSAVRiL';
        case 8:
            return class'ONSGrenadeLauncher';
        case 9:
            return class'ONSMineLayer';
        
        //Make sure super weapons are all at the end
        case 10:
            return class'Redeemer';
        case 11:
            return class'SuperShockRifle';
    }

    return None;
}

function SwapPickupBases(xPickupBase a, xPickupBase b)
{
    local class<PickUp> powerUpA;
    local class<Weapon> weaponTypeA;
    local float pathCostA,spawnHeightA;
    local bool delayedA;
    local xWeaponBase wepA,wepB;

    powerUpA = a.PowerUp;
    a.PowerUp = b.PowerUp;
    b.PowerUp = powerUpA;

    pathCostA = a.ExtraPathCost;
    a.ExtraPathCost = b.ExtraPathCost;
    b.ExtraPathCost = pathCostA;

    spawnHeightA = a.SpawnHeight;
    a.SpawnHeight = b.SpawnHeight;
    b.SpawnHeight = spawnHeightA;

    delayedA = a.bDelayedSpawn;
    a.bDelayedSpawn = b.bDelayedSpawn;
    b.bDelayedSpawn = delayedA;

    wepA=xWeaponBase(a);
    wepB=xWeaponBase(b);

    if (wepA!=None && wepB!=None){
        weaponTypeA = wepA.WeaponType;
        wepA.WeaponType = wepB.WeaponType;
        wepB.WeaponType = weaponTypeA;

        wepA.bDelayedSpawn = (wepA.WeaponType.Default.InventoryGroup==0);
        wepB.bDelayedSpawn = (wepB.WeaponType.Default.InventoryGroup==0);
    }
}


function SwapActors(Actor a, Actor b)
{
    local vector locA;
    local Rotator rotA;
    local InventorySpot invSpot;
    local Pickup pupA, pupB;

    locA = a.Location;
    rotA = a.Rotation;
    a.SetLocation(b.Location);
    a.SetRotation(b.Rotation);
    b.SetLocation(locA);
    b.SetRotation(rotA);
    
    //At the moment, these should both be Inventory items, but...
    if (Pickup(a)!=None && Pickup(b)!=None) {
        pupA = Pickup(a);
        pupB = Pickup(b);
        
        invSpot = pupA.MyMarker;
        pupA.MyMarker = pupB.MyMarker;
        pupB.MyMarker = invSpot;
        
        pupA.MyMarker.markedItem = pupA;
        pupB.MyMarker.markedItem = pupB;
    }
}

simulated function PreBeginPlay()
{
   InitRando();
   CheckServerPackages();
}

function CheckServerPackages()
{
    local string packages;

    if (Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer){
        //Not hosting a server, don't worry about it
        return;
    }

    packages=ConsoleCommand("get Engine.GameEngine ServerPackages");
    if (InStr(packages,"UT2k4CrowdControl")!=-1){
        log("UT2k4CrowdControl is set in ServerPackages!  Nice!");
    } else {
        log("UT2k4CrowdControl is not set in ServerPackages!  Bummer!");
        packages = Left(packages,Len(packages)-1)$",\"UT2k4CrowdControl\")";
        log("Added UT2k4CrowdControl to ServerPackages!");
        ConsoleCommand("set Engine.GameEngine ServerPackages "$packages);

        //Reload the level so that the serverpackages gets updated for real
        log("Restarting game so that ServerPackages are reloaded");
        Level.ServerTravel( "?Restart", false );
    }
}

static event string GetDescriptionText(string PropName) {
    // The value of PropName passed to the function should match the variable name
    // being configured.
    switch (PropName) {
        case "bShuffleSupers":  return "Should super weapons (eg. Redeemers) get randomized?";
        case "bShuffleWeapons":  return "Should weapons get randomized?";
        case "bShuffleHealth":  return "Should Health and Armour items be randomized?";
        case "bShuffleAmmo":  return "Should Ammo get randomized?";
        case "bShuffleAdrenaline":  return "Should Adrenaline get randomized?";
        case "bShuffleOther":  return "Should other items (eg. UDamage) get randomized?";
        case "bShuffleWeaponsWithOthers":  return "Should weapons be randomized in the same pool as health, armour, and UDamage?";
        case "bRandomWeaponLockers":  return "Should the weapons available in weapon lockers be randomized?";
        case "bSuperWeaponsInLockers":  return "Should super weapons (Redeemer and Instagib Rifle) be allowed in randomized weapon lockers?";
    }
    return Super.GetDescriptionText(PropName);
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    Super.FillPlayInfo(PlayInfo);  // Always begin with calling parent

    PlayInfo.AddSetting("Randomizer", "bShuffleSupers", "Shuffle Super Weapons", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bShuffleWeapons", "Shuffle Weapons", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bShuffleHealth", "Shuffle Health and Armour", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bShuffleAmmo", "Shuffle Ammo", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bShuffleAdrenaline", "Shuffle Adrenaline", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bShuffleOther", "Shuffle Other Items", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bShuffleWeaponsWithOthers", "Shuffle Weapons With Other Items", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bRandomWeaponLockers", "Randomize Weapon Lockers", 0, 1, "Check");
    PlayInfo.AddSetting("Randomizer", "bSuperWeaponsInLockers", "Super Weapons in Random Weapon Lockers", 0, 1, "Check");
}


defaultproperties
{
    FriendlyName="Randomizer"
    Description="Shuffle all the items in the level amongst themselves!||Encountering issues or just want to learn more?  Join us on Discord at https://Mods4Ever.com/discord||Source code and updates for this mutator can be found at https://Github.com/TheAstropath/UT2K4CrowdControl"
    bShuffleSupers=True
    bShuffleWeapons=True
    bShuffleHealth=True
    bShuffleAmmo=True
    bShuffleAdrenaline=True
    bShuffleOther=True
    bShuffleWeaponsWithOthers=False
    bRandomWeaponLockers=True
    bSuperWeaponsInLockers=False
}
