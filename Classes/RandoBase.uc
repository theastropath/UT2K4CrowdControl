//=============================================================================
// RandoBase
// A clone of xWeaponBase that behaves like every other xPickupBase instead of
// having special weapon logic.  Could be used if we wanted to shuffle weapons
// the same pool as other things on pickup bases
//=============================================================================
class RandoBase extends xPickUpBase
    placeable;

#exec OBJ LOAD FILE=2k4ChargerMeshes.usx

var bool isSuper;
var bool isWeapon;
var bool isPickup;
var bool isHealth;
var bool isAmmo;
var bool isAdrenaline;

simulated function SetWeaponType(class<Weapon> WeaponType)
{
    if (WeaponType != None)
    {
        PowerUp = WeaponType.default.PickupClass;
        if ( WeaponType.Default.InventoryGroup == 0 ){
            bDelayedSpawn = true;
            isSuper=true;
        } else {
            bDelayedSpawn = false;
            isSuper=false;
        }
        isWeapon=true;
        isPickup=false;
        isHealth=false;
        isAmmo=false;
        isAdrenaline=false;
    }
}

simulated function ReplacePickupBase(xPickupBase pub)
{
    if (pub==None){return;}
    bDelayedSpawn = pub.bDelayedSpawn;
    PowerUp = pub.PowerUp;
    SpawnHeight = pub.SpawnHeight;
    isWeapon=false;
    isSuper=false;
    isPickup=true;
    isHealth=false;
    isAmmo=false;
    isAdrenaline=false;
    if (HealthCharger(pub)!=None || 
        ShieldCharger(pub)!=None || 
        SuperHealthCharger(pub)!=None || 
        SuperShieldCharger(pub)!=None){
        isHealth=true;
    }
}

simulated function MakeBaseForPickup(Pickup p)
{
    PowerUp=p.Class;
    bDelayedSpawn=False;
    SetStaticMesh(None);

    isWeapon=false;
    isSuper=false;
    isPickup=true;
    isHealth=ShieldPickup(p)!=None || TournamentHealth(p)!=None;
    isAmmo= (Ammo(p)!=None);
    isAdrenaline=(AdrenalinePickup(p)!=None);
    
    SpawnHeight=10;
}

simulated function DuplicateAppearance(xPickupBase pub)
{
    local int i;

    SetStaticMesh(pub.StaticMesh);
    SetDrawScale(pub.DrawScale);
    
    for(i=0;i<Skins.Length;i++){
        Skins[i]=None;
    }
    if(pub.Skins.Length>0){
        for(i=0;i<pub.Skins.length;i++){
            Skins[i]=pub.Skins[i];
        }
    }
}

function byte GetInventoryGroup()
{
    local class<UTWeaponPickup> pickup;
    local class<Weapon> WeaponType;

    if (!isWeapon){return 0;}

    pickup = class<UTWeaponPickup>(PowerUp);
    if (pickup==None){return 0;}
    WeaponType = class<Weapon>(pickup.default.InventoryType);
    if (WeaponType != None)
        return WeaponType.Default.InventoryGroup;
    return 999;
}

defaultproperties
{
     bStatic=False
     SpiralEmitter=Class'XEffects.Spiral'
     NewStaticMesh=StaticMesh'2k4ChargerMeshes.ChargerMeshes.WeaponChargerMesh-DS'
     NewPrePivot=(Z=3.700000)
     NewDrawScale=0.500000
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'XGame_rc.WildcardChargerMesh'
     Texture=None
     DrawScale=0.500000
     Skins(0)=Texture'XGameTextures.WildcardChargerTex'
     Skins(1)=Texture'XGameTextures.WildcardChargerTex'
     CollisionRadius=60.000000
     CollisionHeight=3.000000
}
