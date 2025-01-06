class HeadShotsOnlyRules extends GameRules;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local int NewDamage;

    //Sneak these special Crowd Control damage types past the headshot restriction
    if (DamageType==class'HotPotato' || DamageType==class'ThanosSnapped' || DamageType==class'Thorns'){
        NewDamage = Damage;
    } else if (!injured.IsHeadShot(HitLocation,injured.Location-instigatedBy.Location, 1.0)){
        NewDamage = 0;
    } else {
        NewDamage = Damage;
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
