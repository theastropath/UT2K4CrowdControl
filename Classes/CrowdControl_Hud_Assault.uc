class CrowdControl_Hud_Assault extends Hud_Assault;

var UT2k4CCHUDOverlay hudOverlay;

simulated event PostBeginPlay() {
    Super.PostBeginPlay();

    if (hudOverlay==None && PlayerOwner!=None){
        hudOverlay=Spawn(class'UT2k4CCHUDOverlay',self);
    }
    if (hudOverlay!=None){
        AddHudOverlay(hudOverlay);
    }
}