class UT2K4SPTabMutator_Ladder extends UT2K4SPTab_Ladder;

function InitComponent(GUIController pMyController, GUIComponent MyOwner)
{
    Super.Initcomponent(pMyController, MyOwner);
}

defaultproperties
{
     profileclass=Class'UT2k4CrowdControl.UT2k4MutatorGameProfile'
}