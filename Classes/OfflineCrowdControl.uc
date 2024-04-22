class OfflineCrowdControl extends Mutator config(CrowdControl);

var bool initialized;
var UT2k4CCEffects ccEffects;

struct EffectConfig {
    var string EffectName;
    var int quantityMin, quantityMax;
    var int durationMin, durationMax;
    var bool enabled;
};

var config String defaultMutatorName;
var config int effectFrequency;
var config float effectChance;
var config EffectConfig effects[75];
var config String botNames[75];

var int effectCountdown;
var int ticker;

replication
{
    reliable if ( Role == ROLE_Authority )
        SetPawnBoneScale;
}

function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
    if ( (xBombFlag(Other) != None) && (CrowdControlBombFlag(Other)==None) ){
        ReplaceWith( Other, "UT2k4CrowdControl.CrowdControlBombFlag");
        return false;
    }
    return true;
}

function InitCC()
{
    if (Role!=ROLE_Authority)
    {
        return;
    }
    if (initialized==True)
    {
        return;
    }

    foreach AllActors(class'UT2k4CCEffects',ccEffects){
        break;
    }
    ccEffects = Spawn(class'UT2k4CCEffects');
    ccEffects.Init(self);
    
    Level.Game.Broadcast(self,"Offline Crowd Control has initialized!");
    
    SetTimer(0.1,True);
    effectCountdown = effectFrequency;
    
    initialized = True;
    
    SaveConfig();
}

simulated function PreBeginPlay()
{
   initialized = False;
   InitCC();
   CheckServerPackages();
}

function CheckServerPackages()
{
    local string packages;

    if (Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer){
        //Not hosting a server, don't worry about it
        return;
    }

    packages=ConsoleCommand("get Engine.GameEngine ServerPackages");
    if (InStr(packages,"UT2k4CrowdControl")!=-1){
        log("UT2k4CrowdControl is set in ServerPackages!  Nice!");
    } else {
        log("UT2k4CrowdControl is not set in ServerPackages!  Bummer!");
        packages = Left(packages,Len(packages)-1)$",\"UT2k4CrowdControl\")";
        log("Added UT2k4CrowdControl to ServerPackages!");
        ConsoleCommand("set Engine.GameEngine ServerPackages "$packages);

        //Reload the level so that the serverpackages gets updated for real
        log("Restarting game so that ServerPackages are reloaded");
        Level.ServerTravel( "?Restart", false );
    }
}

function Timer() {

    ticker++;
    
    ccEffects.ContinuousUpdates();
    
    if (ticker%10 != 0) {
        return;
    }
    
    ccEffects.PeriodicUpdates();
    
    effectCountdown--;    
    if (effectCountdown <= 0){
        RandomOfflineEffects();
        effectCountdown=Default.effectFrequency;
    }
}

function String PickRandomName(){
    local int i;
    for(i=0;botNames[i]!="";i++){}
    return botNames[Rand(i)];
}

function String PickRandomAmmo(){
    switch(Rand(6)){
        case(0): return "assaultammo";
        case(1): return "bioammo";
        case(2): return "flakammo";
        case(3): return "linkammo";
        case(4): return "minigunammo";
        case(5): return "sniperammo";
    }
    return "";
}

function String PickRandomWeapon(){
    switch(Rand(8)){
        case(0): return "biorifle";
        case(1): return "flakcannon";
        case(2): return "linkgun";
        case(3): return "minigun";
        case(4): return "rocketlauncher";
        case(5): return "shockrifle";
        case(6): return "lightninggun";
        case(7): return "translocator";
    }
    return "";
}

function String PickRandomAnnouncer(){
    switch(Rand(5)){
        case(0): return "UnrealGame.MaleAnnouncer";
        case(1): return "UnrealGame.FemaleAnnouncer";
        case(2): return "UnrealGame.ClassicAnnouncer";
        case(3): return "UnrealGame.UTClassicAnnouncer";
        case(4): return "UnrealGame.SexyFemaleAnnouncer";
    }
    return "";
}

function int RandomOfflineEffects()
{
    local string param[5];
    local string viewer;
    local int duration,quantity;
    
    local EffectConfig enabledEffects[50];
    local int i,j;
    
    // only 2% chance for an effect, each second
    if(FRand() > Default.effectChance) return 0;

    viewer = defaultMutatorName;
    param[0] = "1";
    
    i=0;
    
    for (j=0;j<ArrayCount(effects);j++){
        if (effects[j].enabled){
            enabledEffects[i++]=effects[j];
        }
    }
    
    j = Rand(i);    
    duration=0;
    if (enabledEffects[j].durationMax>0){
        duration = Rand(enabledEffects[j].durationMax-enabledEffects[j].durationMin) + enabledEffects[j].durationMin;
    }
    
    quantity=0;
    if (enabledEffects[j].quantityMax>0){
        quantity = Rand(enabledEffects[j].quantityMax-enabledEffects[j].quantityMin) + enabledEffects[j].quantityMin;
        param[0]=String(quantity);
    }
    
    //Special cases
    switch(enabledEffects[j].EffectName){
        case "give_ammo":
            param[0]=PickRandomAmmo();
            param[1]=String(quantity);
            break;
        case "give_weapon":
        case "force_weapon_use":
            param[0]=PickRandomWeapon();
            break;
        case "spawn_a_bot_attack":
        case "spawn_a_bot_defend":
            viewer = PickRandomName();
            break;
        case "announcer":
            param[0]=PickRandomAnnouncer();
            break;
    }
    
    return ccEffects.doCrowdControlEvent(enabledEffects[j].EffectName,param,viewer,0,duration);
    
    return 0;
}

function ModifyPlayer(Pawn Other)
{
    if (ccEffects!=None){
        ccEffects.ModifyPlayer(Other);
    }
    if (NextMutator != None)
        NextMutator.ModifyPlayer(Other);
}

function ModifyLogin(out string Portal, out string Options)
{
    Super.ModifyLogin(Portal, Options);

    if(level.game.hudtype~="xInterface.HudCTeamDeathmatch")
        Level.Game.HudType=string(class'CrowdControl_HudCTeamDeathMatch');
    else if(level.game.hudtype~="xInterface.HudCDeathmatch")
        Level.Game.HudType=string(class'CrowdControl_HudCDeathMatch');
    else if(level.game.hudtype~="xInterface.HudCBombingRun")
        Level.Game.HudType=string(class'CrowdControl_HudCBombingRun');
    else if(level.game.hudtype~="xInterface.HudCCaptureTheFlag")
        Level.Game.HudType=string(class'CrowdControl_HudCCaptureTheFlag');
    else if(level.game.hudtype~="xInterface.HudCDoubleDomination")
        Level.Game.HudType=string(class'CrowdControl_HudCDoubleDomination');
    else if(level.game.hudtype~="Onslaught.ONSHUDOnslaught")
        Level.Game.HudType=string(class'CrowdControl_ONSHUDOnslaught');
    else if(level.game.hudtype~="SkaarjPack.HUDInvasion")
        Level.Game.HudType=string(class'CrowdControl_HUDInvasion');
    else if(level.game.hudtype~="BonusPack.HudLMS")
        Level.Game.HudType=string(class'CrowdControl_HudLMS');
    else if(level.game.hudtype~="BonusPack.HudMutant")
        Level.Game.HudType=string(class'CrowdControl_HudMutant');
    else if(level.game.hudtype~="ut2k4assault.Hud_Assault")
        Level.Game.HudType=string(class'CrowdControl_Hud_Assault');
}

simulated function SetPawnBoneScale(Pawn p, int Slot, optional float BoneScale, optional name BoneName)
{
    p.SetBoneScale(Slot,BoneScale,BoneName);
}

function MutateStatus(PlayerController Sender)
{
    local int i;
    
    //Show the current state of everything
    Sender.ClientMessage("UT2k4 Simulated Crowd Control Status:");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("Effect Frequency: "$effectFrequency);
    Sender.ClientMessage("Effect Chance: "$effectChance);
    Sender.ClientMessage("Mutator Name: "$defaultMutatorName);    
    Sender.ClientMessage(" ");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("Effect Configuration:");
    Sender.ClientMessage("--------------------------");
    Sender.ClientMessage(" ");

    
    for(i=0;i<ArrayCount(effects) && effects[i].EffectName!="";i++){
        Sender.ClientMessage("Name: "$effects[i].EffectName);
        Sender.ClientMessage("Quantity: "$effects[i].quantityMin$"-"$effects[i].quantityMax);
        Sender.ClientMessage("Duration: "$effects[i].durationMin$"-"$effects[i].durationMax$" seconds");
        Sender.ClientMessage("Enabled: "$effects[i].Enabled);
        Sender.ClientMessage(" ");
    }

}

function MutateShowEffect(PlayerController Sender, string effectName)
{
    local int i;
    for(i=0;i<ArrayCount(effects) && effects[i].EffectName!="";i++){
        if (effects[i].EffectName~=effectName){
            Sender.ClientMessage("Name: "$effects[i].EffectName);
            Sender.ClientMessage("Quantity: "$effects[i].quantityMin$"-"$effects[i].quantityMax);
            Sender.ClientMessage("Duration: "$effects[i].durationMin$"-"$effects[i].durationMax$" seconds");
            Sender.ClientMessage("Enabled: "$effects[i].Enabled);
            return;
        }
    }
    Sender.ClientMessage("Couldn't find effect <"$effectName$">");
}

function MutateSetFrequency(PlayerController Sender, string frequency)
{
    local int newFreq;
    //Configure the effectFrequency
    
    newFreq = int(frequency);
    if (newFreq > 0) {
        Sender.ClientMessage("Setting Effect Frequency to <"$frequency$">");
        effectFrequency = newFreq;
    } else {
        Sender.ClientMessage("Invalid Effect Frequency <"$frequency$">");
    }
}

function MutateSetChance(PlayerController Sender, string chance)
{
    local float newChance;
    //Configure the effectChance
    newChance = float(chance);
    if (newChance > 0) {
        Sender.ClientMessage("Setting Effect Chance to <"$chance$">");
        effectChance = newChance;
    } else {
        Sender.ClientMessage("Invalid Effect Chance <"$chance$">");
    }    
}

function MutateSetName(PlayerController Sender, string mutName)
{
    Sender.ClientMessage("Setting mutator name to <"$mutName$">");
    defaultMutatorName = mutName;
}

function MutateSetEffectState(PlayerController Sender, string effectName, bool enabled)
{
    //Set an effect to the enabled state provided
    local int i;
    for(i=0;i<ArrayCount(effects) && effects[i].EffectName!="";i++){
        if (effects[i].EffectName~=effectName){
            effects[i].Enabled = enabled;
            Sender.ClientMessage("Setting effect <"$effectName$"> enabled state to "$enabled);
            return;
        }
    }
    Sender.ClientMessage("Couldn't find effect <"$effectName$">");
}

function bool GetThreeVals(string input, out string first, out string second, out string third)
{
    local string remainingStr;
    local int pos;
    
    remainingStr = input;
    pos = InStr(remainingStr," ");
    
    if (pos==-1){
        return False;
    }
    
    first = Mid(remainingStr,0,pos);
    remainingStr = Mid(remainingStr,pos+1);
    
    pos = InStr(remainingStr," ");
    if (pos==-1){
        return False;
    }
    
    second = Mid(remainingStr,0,pos);
    remainingStr = Mid(remainingStr,pos+1);
    
    pos = InStr(remainingStr," ");
    if (pos==-1){
        third = remainingStr;
    } else {
        third = Mid(remainingStr,0,pos);
    }
    
    return True;
}

function MutateSetEffectDuration(PlayerController Sender, string durationStr)
{
    local string effectName, minDur, maxDur;
    local int i;
    //Configure the min and max duration for an effect
    if (GetThreeVals(durationStr,effectName,minDur,maxDur)){
    
        if (int(minDur)==0 || int(maxDur)==0 || int(minDur) > int (maxDur)){
            Sender.ClientMessage("Duration values must be integers and the minimum must be less than or equal to the maximum");
            return;
        }
    
        for(i=0;i<ArrayCount(effects) && effects[i].EffectName!="";i++){
            if (effects[i].EffectName~=effectName){
                effects[i].durationMin = int(minDur);
                effects[i].durationMax = int(maxDur);
                Sender.ClientMessage("Setting effect <"$effectName$"> to duration: "$minDur$"-"$maxDur$" seconds");
                return;
            }
        }
        Sender.ClientMessage("Couldn't find effect <"$effectName$">");
    } else {
        Sender.ClientMessage("Invalid parameters - Provide <effect name> <min duration> <max duration>");
    }
}

function MutateSetEffectQuantity(PlayerController Sender, string durationStr)
{
    local string effectName, minQuant, maxQuant;
    local int i;
    //Configure the min and max quantity for an effect
    if (GetThreeVals(durationStr,effectName,minQuant,maxQuant)){
    
        if (int(minQuant)==0 || int(maxQuant)==0 || int(minQuant) > int (maxQuant)){
            Sender.ClientMessage("Duration values must be integers and the minimum must be less than or equal to the maximum");
            return;
        }
        
        for(i=0;i<ArrayCount(effects) && effects[i].EffectName!="";i++){
            if (effects[i].EffectName~=effectName){
                effects[i].quantityMin = int(minQuant);
                effects[i].quantityMax = int(maxQuant);
                Sender.ClientMessage("Setting effect <"$effectName$"> to quantity: "$minQuant$"-"$maxQuant);
                return;
            }
        }
        Sender.ClientMessage("Couldn't find effect <"$effectName$">");
    } else {
        Sender.ClientMessage("Invalid parameters - Provide <effect name> <min quantity> <max quantity>");
    }
}

function MutateHelp(PlayerController Sender)
{
    Sender.ClientMessage("UT2k4 Simulated Crowd Control Help:");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc status");
    Sender.ClientMessage("     Displays current status of the Crowd Control Mutator");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc setfrequency <frequency>");
    Sender.ClientMessage("     Sets how frequently the mutator should see if it should send an effect, in seconds");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc setchance <chance>");
    Sender.ClientMessage("     Sets how frequently the mutator should see if it should send an effect, as a decimal between 0 and 1");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc enable <effect name>");
    Sender.ClientMessage("     Enables a specific effect");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc disable <effect name>");
    Sender.ClientMessage("     Disables a specific effect");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("   mutate cc setduration <effect name> <minimum duration> <maximum duration>");
    Sender.ClientMessage("     Sets the random duration range for the specified effect");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("   mutate cc setquantity <effect name> <minimum quantity> <maximum quantity>");
    Sender.ClientMessage("     Sets the random quantity range for the specified effect");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("   mutate cc show <effect name>");
    Sender.ClientMessage("     Shows the state of the specified effect");
    Sender.ClientMessage(" ");    
    Sender.ClientMessage("   mutate cc help");
    Sender.ClientMessage("     How did you get here without knowing about this command?");
    Sender.ClientMessage(" ");
}

function Mutate (string MutateString, PlayerController Sender)
{
	local string remainingStr,nextBatch;
    local int pos;

    remainingStr = MutateString;
    
    pos = InStr(remainingStr," ");
    if (pos!=-1){
        nextBatch = Mid(remainingStr,0,pos);
        remainingStr = Mid(remainingStr,pos+1);
    } else {
        nextBatch = Mid(remainingStr,0);
        remainingStr = "";
    }
    
    if (nextBatch~="occ") {
        
        if (Sender.PlayerReplicationInfo.bAdmin || Level.NetMode==NM_Standalone) {
        
            pos = InStr(remainingStr," ");
            if (pos!=-1){
                nextBatch = Mid(remainingStr,0,pos);
                remainingStr = Mid(remainingStr,pos+1);
            } else {
                nextBatch = Mid(remainingStr,0);
                remainingStr = "";
            }
            
            if (nextBatch~="status"){
                MutateStatus(Sender); //Show config
            } else if (nextBatch~="setfrequency"){
                MutateSetFrequency(Sender,remainingStr);
            } else if (nextBatch~="setchance"){
                MutateSetChance(Sender,remainingStr);
            } else if (nextBatch~="setname"){
                MutateSetName(Sender,remainingStr);
            } else if (nextBatch~="enable"){
                MutateSetEffectState(Sender,remainingStr,True);
            } else if (nextBatch~="disable"){
                MutateSetEffectState(Sender,remainingStr,False);
            } else if (nextBatch~="setduration"){
                MutateSetEffectDuration(Sender,remainingStr);
            } else if (nextBatch~="setquantity"){
                MutateSetEffectQuantity(Sender,remainingStr);
            } else if (nextBatch~="show"){
                MutateShowEffect(Sender,remainingStr);
            } else if (nextBatch~="help"){
                MutateHelp(Sender);
            } else {
                Sender.ClientMessage("Unrecognized UT2k4 Offline Crowd Control command: <"$nextBatch$">  Use 'mutate occ help' for more help");
            }
            SaveConfig();
        
        } else {
            Sender.ClientMessage("Offline Crowd Control mutator commands only available to admins - Please login!");
        }
    }
    
    
    if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
}

function EnableEffect(int i,bool Enabled)
{
    effects[i].enabled=Enabled;
    SaveConfig();
}

static function SetEffectEnabled(PlayerController p, int i,bool enabled)
{
    local OfflineCrowdControl occ;
    local bool spawned;
    
    spawned=class'OfflineCrowdControl'.static.GetOCC(p,occ);
    
    occ.EnableEffect(i,enabled);
    
    if (spawned){
        occ.Destroy();
    }
}

function SetEffectDur(int i,int minDur, int maxDur)
{
    if (minDur!=-1){
        effects[i].durationMin=minDur;
    }
    if (maxDur!=-1){
        effects[i].durationMax=maxDur;
    }
    SaveConfig();
}

static function SetEffectDuration(PlayerController p, int i,int minDur, int maxDur)
{
    local OfflineCrowdControl occ;
    local bool spawned;
    
    spawned=class'OfflineCrowdControl'.static.GetOCC(p,occ);
    
    occ.SetEffectDur(i,minDur,maxDur);
    
    if (spawned){
        occ.Destroy();
    }
}

function SetEffectQuant(int i,int minQuant, int maxQuant)
{
    if (minQuant!=-1){
        effects[i].quantityMin=minQuant;
    }
    if (maxQuant!=-1){
        effects[i].quantityMax=maxQuant;
    }
    SaveConfig();
}

static function SetEffectQuantity(PlayerController p, int i,int minQuant, int maxQuant)
{
    local OfflineCrowdControl occ;
    local bool spawned;
    
    spawned=class'OfflineCrowdControl'.static.GetOCC(p,occ);
    
    occ.SetEffectQuant(i,minQuant,maxQuant);
    
    if (spawned){
        occ.Destroy();
    }
}

static function SetEffectFrequency(PlayerController p, int freq)
{
    local OfflineCrowdControl occ;
    local bool spawned;
    
    spawned=class'OfflineCrowdControl'.static.GetOCC(p,occ);
    
    occ.effectFrequency=freq;
    occ.SaveConfig();
    
    if (spawned){
        occ.Destroy();
    }
}

static function SetEffectChance(PlayerController p, float chance)
{
    local OfflineCrowdControl occ;
    local bool spawned;
    
    spawned=class'OfflineCrowdControl'.static.GetOCC(p,occ);
    
    occ.effectChance=chance;
    occ.SaveConfig();
    
    if (spawned){
        occ.Destroy();
    }
}

static function SetMutatorName(PlayerController p, string mutName)
{
    local OfflineCrowdControl occ;
    local bool spawned;
    
    spawned=class'OfflineCrowdControl'.static.GetOCC(p,occ);
    
    occ.defaultMutatorName=mutName;
    occ.SaveConfig();
    
    if (spawned){
        occ.Destroy();
    }
}
static function bool GetOCC(PlayerController p, out OfflineCrowdControl occ)
{
    local bool spawned;   
    spawned=False;
    
    foreach p.AllActors(class'OfflineCrowdControl',occ){
        break;
    }
    
    if (occ==None){
        occ=p.Spawn(class'OfflineCrowdControl');
        spawned=True;
    }
    
    return spawned;

}
static function EffectConfig GetEffectInfo(int i)
{
    return Default.effects[i];
}

static event string GetDescriptionText(string PropName) {
    // The value of PropName passed to the function should match the variable name
    // being configured.
    switch (PropName) {
        case "effectFrequency":  return "How frequently the mutator will try to send effects";
        case "effectChance":  return "The chance for an effect to go off each time the mutator tries to send an effect";
        case "defaultMutatorName":  return "The name that Simulated Crowd Control will say sent the effect";
    }
    return Super.GetDescriptionText(PropName);
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    Super.FillPlayInfo(PlayInfo);  // Always begin with calling parent
    
    PlayInfo.AddSetting("Simulated Crowd Control", "effectFrequency", "Effect Frequency", 0, 2, "Text","3;1:300");
    PlayInfo.AddSetting("Simulated Crowd Control", "effectChance", "Effect Chance", 0, 2, "Text","4;0.01:1.0");
    PlayInfo.AddSetting("Simulated Crowd Control", "defaultMutatorName", "'Viewer' Name", 0, 2, "Text","30");
}

defaultproperties
{
    bAddToServerPackages=True
    FriendlyName="Simulated Crowd Control"
    Description="Randomly send Crowd Control effects without any viewers!||Encountering issues or just want to learn more?  Join us on Discord at https://Mods4Ever.com/discord||Source code and updates for this mutator can be found at https://Github.com/TheAstropath/UT2K4CrowdControl"
    defaultMutatorName="Simulated Crowd Control"
    effectFrequency=1
    effectChance=0.05
    effects(0)=(EffectName="sudden_death",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(1)=(EffectName="full_heal",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(2)=(EffectName="full_armour",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(3)=(EffectName="full_adrenaline",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(4)=(EffectName="give_health",quantityMin=1,quantityMax=25,durationMin=0,durationMax=0,enabled=true)
    effects(5)=(EffectName="third_person",quantityMin=0,quantityMax=0,durationMin=5,durationMax=45,enabled=true)
    effects(6)=(EffectName="bonus_dmg",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(7)=(EffectName="gotta_go_fast",quantityMin=0,quantityMax=0,durationMin=5,durationMax=60,enabled=true)
    effects(8)=(EffectName="gotta_go_slow",quantityMin=0,quantityMax=0,durationMin=5,durationMax=30,enabled=true)
    effects(9)=(EffectName="thanos",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(10)=(EffectName="swap_player_position",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(11)=(EffectName="no_ammo",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(12)=(EffectName="give_ammo",quantityMin=1,quantityMax=3,durationMin=0,durationMax=0,enabled=true)
    effects(13)=(EffectName="nudge",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(14)=(EffectName="drop_selected_item",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(15)=(EffectName="give_weapon",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(16)=(EffectName="give_instagib",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(17)=(EffectName="give_redeemer",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(18)=(EffectName="melee_only",quantityMin=0,quantityMax=0,durationMin=15,durationMax=60,enabled=true)
    effects(19)=(EffectName="last_place_shield",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(20)=(EffectName="last_place_bonus_dmg",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(21)=(EffectName="first_place_slow",quantityMin=0,quantityMax=0,durationMin=5,durationMax=30,enabled=true)
    effects(22)=(EffectName="blue_redeemer_shell",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(23)=(EffectName="vampire_mode",quantityMin=0,quantityMax=0,durationMin=15,durationMax=120,enabled=true)
    effects(24)=(EffectName="force_weapon_use",quantityMin=0,quantityMax=0,durationMin=15,durationMax=60,enabled=true)
    effects(25)=(EffectName="force_instagib",quantityMin=0,quantityMax=0,durationMin=20,durationMax=120,enabled=true)
    effects(26)=(EffectName="force_redeemer",quantityMin=0,quantityMax=0,durationMin=10,durationMax=30,enabled=true)
    effects(27)=(EffectName="reset_domination_control_points",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(28)=(EffectName="return_ctf_flags",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(29)=(EffectName="big_head",quantityMin=0,quantityMax=0,durationMin=5,durationMax=120,enabled=true)
    effects(30)=(EffectName="headless",quantityMin=0,quantityMax=0,durationMin=5,durationMax=120,enabled=true)
    effects(31)=(EffectName="limbless",quantityMin=0,quantityMax=0,durationMin=5,durationMax=120,enabled=true)
    effects(32)=(EffectName="full_fat",quantityMin=0,quantityMax=0,durationMin=5,durationMax=120,enabled=true)
    effects(33)=(EffectName="skin_and_bones",quantityMin=0,quantityMax=0,durationMin=5,durationMax=120,enabled=true)
    effects(34)=(EffectName="low_grav",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(35)=(EffectName="ice_physics",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(36)=(EffectName="flood",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(37)=(EffectName="last_place_ultra_adrenaline",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(38)=(EffectName="all_berserk",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(39)=(EffectName="all_invisible",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(40)=(EffectName="all_regen",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(41)=(EffectName="thrust",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(42)=(EffectName="team_balance",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(43)=(EffectName="announcer",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(44)=(EffectName="fumble_bombing_run_ball",quantityMin=0,quantityMax=0,durationMin=0,durationMax=0,enabled=true)
    effects(45)=(EffectName="bombing_run_hot_potato",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(46)=(EffectName="attack_team_double_dmg",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(47)=(EffectName="defend_team_double_dmg",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(48)=(EffectName="head_shots_only",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(49)=(EffectName="infinite_adrenaline",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(50)=(EffectName="thorns",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(51)=(EffectName="octojump",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    effects(52)=(EffectName="pint_sized",quantityMin=0,quantityMax=0,durationMin=10,durationMax=60,enabled=true)
    botNames(0)="Jim"
    botNames(1)="James"
    botNames(2)="Jeremy"
    botNames(3)="Jane"
    botNames(4)="Olivia"
    botNames(5)="Evelyn"
    botNames(6)="Oliver"
    botNames(7)="William"
    botNames(8)="Noah"
    botNames(9)="Liam"
    botNames(10)="Lucas"
    botNames(11)="Wilford"
    botNames(12)="Henry"
    botNames(13)="Theo"
    botNames(14)="Benjamin"
    botNames(15)="Claus"
    botNames(16)="Sonic"
    botNames(17)="Eggman"
    botNames(18)="JC"
    botNames(19)="Paul"
    botNames(20)="Jock"
    botNames(21)="Stauf"
    botNames(22)="Gaspra"
    botNames(23)="Yokan"
    botNames(24)="Morshu"
    botNames(25)="Bowser"
    botNames(26)="Terra"
    botNames(27)="Edgar"
    botNames(28)="Sabin"
    botNames(29)="Cecil"
    botNames(30)="Rosa"
    botNames(31)="Gabriel"
    botNames(32)="Tiz"
    botNames(33)="Tingle"
    botNames(34)="Solidus"    
    botNames(35)="Raiden"    
    botNames(36)="Hal"    
    botNames(37)="Celes"    
    botNames(38)="Samus"    
    botNames(39)="Emma"    
    botNames(40)="Zelda"    
    botNames(41)="Sypha"    
    botNames(42)="Carmilla"    
    botNames(43)="Maria"    
    botNames(44)="Sonia"    
    botNames(45)="Soma"    
    botNames(46)="Shanoa"    
    botNames(47)="Miriam"    
    botNames(48)="Dominique"    
    botNames(49)="Gebel"    
}