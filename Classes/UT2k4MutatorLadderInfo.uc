class UT2k4MutatorLadderInfo extends UT2K4LadderInfo config(MutatorLadder);

var config string MutatorList;

static function string MakeURLFoMatchInfo(MatchInfo M, GameProfile G)
{
    local string URL;
    //local string mutList
    //local array<CacheManager.MutatorRecord> MutatorArr;
    //local int i;

    if ( M == none ) {
        Warn("MatchInfo == none");
        return "";
    }

    StaticSaveConfig();

    URL = Super.MakeURLFoMatchInfo(M,G);

/*
    //Maybe we can add a mutator menu for the campaign
    class'CacheManager'.static.GetMutatorList(MutatorArr);
    mutList="";
    for ( i = MutatorArr.Length - 1; i >= 0; i-- ){
        log("Mutator "$MutatorArr[i].ClassName$" is active? "$MutatorArr[i].bActivated);
        if (MutatorArr[i].bActivated==0) continue;

        mutList $= MutatorArr[i].ClassName;
        mutList $= ",";
    }
*/

    URL$="?Mutator="$Default.MutatorList;
    //URL$="?Mutator="$mutList;

    return URL;
}

defaultproperties
{
    MutatorList="UT2k4CrowdControl.CrowdControl"
}