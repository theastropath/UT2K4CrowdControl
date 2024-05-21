class UT2K4SPTabMutator_ExtraLadder extends UT2K4SPTab_ExtraLadder;

function InitComponent(GUIController pMyController, GUIComponent MyOwner)
{
    Super.Initcomponent(pMyController, MyOwner);
}

defaultproperties
{
     profileclass=Class'UT2k4CrowdControl.UT2k4MutatorGameProfile'
}