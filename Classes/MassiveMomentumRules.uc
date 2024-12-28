class MassiveMomentumRules extends GameRules;

var int momentumMult;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    //if (PlayerController(instigatedBy.Controller)!=None){
    //    Level.Game.Broadcast(instigatedBy,"Momentum dealt was "$Momentum);
    //}

    if (VSize(Momentum)<1){
        //apply some baseline momentum to work from
        Momentum = Normal(injured.Location - instigatedBy.Location) * Damage * 2;
    }
    Momentum = Momentum * momentumMult;
    return Damage;
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
    momentumMult=25
}
