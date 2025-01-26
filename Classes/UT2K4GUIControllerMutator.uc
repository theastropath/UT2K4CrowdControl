class UT2K4GUIControllerMutator extends UT2K4GUIController;

function String SwapSPMenuClass(string NewMenuName)
{
    if ( NewMenuName ~= "GUI2K4.UT2K4SP_Main") //The vanilla single player menu
    {
        NewMenuName=Default.MainMenuOptions[0];
    }

    return NewMenuName;
}

event bool OpenMenu(string NewMenuName, optional string Param1, optional string Param2)
{
    return Super.OpenMenu(SwapSPMenuClass(NewMenuName), Param1, Param2);
}

event bool ReplaceMenu(string NewMenuName, optional string Param1, optional string Param2, optional bool bCancelled)
{
    return Super.ReplaceMenu(SwapSPMenuClass(NewMenuName),Param1,Param2,bCancelled);
}

defaultproperties
{
    MainMenuOptions(0)="UT2k4CrowdControl.UT2K4SPMutator_Main"
}