class UT2K4Tab_MutatorSPLadder extends UT2K4Tab_MutatorBase;

function InitComponent(GUIController pMyController, GUIComponent MyOwner)
{
    Super.Initcomponent(pMyController, MyOwner);
    InitMutatorList();
}

//From UT2K4Tab_MutatorBase  SetCurrentGame (but without the parameter)
function InitMutatorList()
{
    local int i;
    local string m, t;

    if ( MutatorList.Length > 0 )
        m = BuildActiveMutatorString();
    else m = LastActiveMutators;

    class'CacheManager'.static.GetMutatorList(MutatorList);

    // Disable the list's OnChange() delegate
    lb_Active.List.bNotify = False;
    lb_Avail.List.bNotify = False;

    lb_Active.List.Clear();
    lb_Avail.List.Clear();

    for (i=0;i<MutatorList.Length;i++)
        lb_Avail.List.Add(MutatorList[i].FriendlyName,,MutatorList[i].Description);

    t = NextMutatorInString(m);
    while (t!="")
    {
        SelectMutator(t);
        t = NextMutatorInString(m);
    }

    lb_Active.List.bNotify = True;
    lb_Avail.List.bNotify = True;

    lb_Active.List.CheckLinkedObjects(lb_Active.List);
    lb_Avail.List.CheckLinkedObjects(lb_Avail.List);

}

defaultproperties
{
}
