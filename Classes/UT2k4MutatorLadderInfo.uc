class UT2k4MutatorLadderInfo extends UT2K4LadderInfo;

static function string MakeURLFoMatchInfo(MatchInfo M, GameProfile G)
{
    local string URL;

    if ( M == none ) {
        Warn("MatchInfo == none");
        return "";
    }

    StaticSaveConfig();

    URL = Super.MakeURLFoMatchInfo(M,G);

    URL$="?Mutator="$class'UT2k4CrowdControl.UT2K4Tab_MutatorSPLadder'.Default.LastActiveMutators;

    return URL;
}