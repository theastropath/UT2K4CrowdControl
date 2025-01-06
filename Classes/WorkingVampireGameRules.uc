class WorkingVampireGameRules extends VampireGameRules;

//The original VampireGameRules don't stack with other damage modifying rules
function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    if ( (InstigatedBy != Injured) && (InstigatedBy != None) && (InstigatedBy.Health > 0) 
        && (InstigatedBy.PlayerReplicationInfo != None) && (Injured.PlayerReplicationInfo != None) 
        && ((InstigatedBy.PlayerReplicationInfo.Team == None) || (InstigatedBy.PlayerReplicationInfo.Team != Injured.PlayerReplicationInfo.Team)) )
        InstigatedBy.Health = Min( InstigatedBy.Health+Damage*ConversionRatio, Max(InstigatedBy.Health,InstigatedBy.HealthMax) );

    if ( NextGameRules != None ) //The original implementation returned this before doing the health adjustment above, so it just didn't stack at all?
        return NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

    return Damage;
}
