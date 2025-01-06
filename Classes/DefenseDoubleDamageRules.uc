class DefenseDoubleDamageRules extends GameRules;

var bool bSameTeam;
var float damageMult;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local xBombingRun brGame;
    local ASGameInfo asGame;
    local CrowdControlBombFlag ccBomb;
    local int attackTeamId, NewDamage;

    
    attackTeamId=-1;
    
    brGame=xBombingRun(Level.Game);
    if (brGame!=None){
        ccBomb = CrowdControlBombFlag(brGame.Bomb);
        if (ccBomb!=None){
            attackTeamId=ccBomb.Holder.PlayerReplicationInfo.Team.TeamIndex;
        }
    }

    asGame=ASGameInfo(Level.Game);
    if (asGame!=None){
        attackTeamId=asGame.CurrentAttackingTeam;
    }

    if (attackTeamId==-1){
        NewDamage = Damage;
    } else if (bSameTeam!=(attackTeamId==InstigatedBy.PlayerReplicationInfo.Team.TeamIndex)){
        NewDamage = Damage;
    } else {
        NewDamage = Damage * damageMult;
    }

    if ( NextGameRules != None )
        return NextGameRules.NetDamage( OriginalDamage,NewDamage,injured,instigatedBy,HitLocation,Momentum,DamageType );

    return NewDamage;
}

//
// server querying
//
function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    // append the gamerules name- only used if mutator adds me and deletes itself.
    local int i;
    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i+1;
    ServerState.ServerInfo[i].Key = "Mutator";
    ServerState.ServerInfo[i].Value = GetHumanReadableName();
}

defaultproperties
{
    bSameTeam=False
    damageMult=2.0
}
