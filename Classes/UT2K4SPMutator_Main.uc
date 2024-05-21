class UT2K4SPMutator_Main extends UT2K4SP_Main;

var UT2K4Tab_MutatorSPLadder tpMutators;

function UpdateTabs(optional bool bPurge, optional bool bSetActive)
{
    local GUITabPanel tmp;
    
    Super.UpdateTabs(bPurge,bSetActive);
    
    if (GP != none)
    {
        tmp=addTab(8,false);
        if (tmp!=None) tpMutators = UT2K4Tab_MutatorSPLadder(tmp);
    }
}

defaultproperties
{
     PanelClass(0)="UT2k4CrowdControl.UT2K4SPTabMutator_Profile"
     PanelClass(1)="UT2k4CrowdControl.UT2K4SPTabMutator_ProfileNew"
     PanelClass(2)="UT2k4CrowdControl.UT2K4SPTabMutator_Tutorials"
     PanelClass(3)="UT2k4CrowdControl.UT2K4SPTabMutator_Qualification"
     PanelClass(4)="UT2k4CrowdControl.UT2K4SPTabMutator_TeamQualification"
     PanelClass(5)="UT2k4CrowdControl.UT2K4SPTabMutator_Ladder"
     PanelClass(6)="UT2k4CrowdControl.UT2K4SPTabMutator_TeamManagement"
     PanelClass(7)="UT2k4CrowdControl.UT2K4SPTabMutator_ExtraLadder"
     PanelClass(8)="UT2k4CrowdControl.UT2K4Tab_MutatorSPLadder"
     PanelCaption(8)="Mutators"
     PanelHint(8)="Select your ladder mutators"
}