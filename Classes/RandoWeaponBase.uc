//=============================================================================
// RandoWeaponBase
// A clone of xWeaponBase that behaves like every other xPickupBase instead of
// having special weapon logic.  Could be used if we wanted to shuffle weapons
// the same pool as other things on pickup bases
//=============================================================================
class RandoWeaponBase extends xPickUpBase
    placeable;

#exec OBJ LOAD FILE=2k4ChargerMeshes.usx

var bool isSuper;

simulated function SetWeaponType(class<Weapon> WeaponType)
{
    if (WeaponType != None)
    {
        PowerUp = WeaponType.default.PickupClass;
        if ( WeaponType.Default.InventoryGroup == 0 ){
            bDelayedSpawn = true;
            isSuper=true;
        }
    }
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetLocation(Location + vect(0,0,-2)); // adjust because reduced drawscale
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
