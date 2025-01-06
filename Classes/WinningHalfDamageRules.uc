class WinningHalfDamageRules extends GameRules;

var float damageMult;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local int NewDamage;

    if (!PawnIsWinning(instigatedBy)){
        NewDamage = Damage;
    } else {
        NewDamage = Damage * damageMult;
    }

    if ( NextGameRules != None )
        return NextGameRules.NetDamage( OriginalDamage,NewDamage,injured,instigatedBy,HitLocation,Momentum,DamageType );
    

    //Level.Game.Broadcast(self,"Pawn "$instigatedBy$" is winning, so dealing reduced damage ("$Damage$" reduced to "$(Damage * damageMult)$")");

    return NewDamage;
}

function bool PawnIsWinning(pawn piw)
{
    local TeamGame tg;
    local DeathMatch dm;
    local Controller P, Winner;
    local UnrealTeamInfo winT;
    local int i;

    tg = TeamGame(Level.Game);
    dm = DeathMatch(Level.Game);

    if (tg!=None) {
        //Team game, winner means "on winning team"
        for (i=0;i<ArrayCount(tg.Teams);i++){
            if (winT==None || tg.Teams[i].Score>=winT.Score){
                winT=tg.Teams[i];
            }
        }
        if (piw.Controller.PlayerReplicationInfo.Team.Score==winT.Score){
            return true;
        }
    } else if (dm!=None){
        //Non-Team game, winner means first place
        for ( P=Level.ControllerList; P!=None; P=P.nextController ) {
            if ( Winner==None || P.PlayerReplicationInfo.Score >= Winner.PlayerReplicationInfo.Score)
            {
                Winner = P;
            }
        }

        //Considered a winner whether you *are* the winner found, or if your score is equal
        if (piw.Controller.PlayerReplicationInfo.Score==Winner.PlayerReplicationInfo.Score){
            return true;
        }
    }

    return false;
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
    damageMult=0.5
}
