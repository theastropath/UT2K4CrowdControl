class UT2K4SPTabMutator_ProfileNew extends UT2K4SPTab_ProfileNew;

function InitComponent(GUIController pMyController, GUIComponent MyOwner)
{
    Super.Initcomponent(pMyController, MyOwner);
}

defaultproperties
{
     profileclass=Class'UT2k4CrowdControl.UT2k4MutatorGameProfile'
}