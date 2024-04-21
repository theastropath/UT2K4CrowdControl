class ThornsRules extends GameRules;

var() float ConversionRatio;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local vector newHitLoc,newMomentum;
    if ( NextGameRules != None )
        return NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

    if ( (DamageType!=class'Thorns') && (InstigatedBy != Injured) && (InstigatedBy != None) && (InstigatedBy.Health > 0) 
        && (InstigatedBy.PlayerReplicationInfo != None) && (Injured.PlayerReplicationInfo != None) 
        && ((InstigatedBy.PlayerReplicationInfo.Team == None) || (InstigatedBy.PlayerReplicationInfo.Team != Injured.PlayerReplicationInfo.Team)) )
    {
        newHitLoc = ((HitLocation-injured.Location)+instigatedBy.Location) * vect(-1,-1,1);
        newMomentum = Momentum * vect(-1,-1,1);
        InstigatedBy.TakeDamage
        (
            Damage * ConversionRatio,
            injured,
            newHitLoc,
            newMomentum,
            class'Thorns'
        );
    }
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
    ConversionRatio=0.500000
}
