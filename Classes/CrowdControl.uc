class CrowdControl extends Mutator config(CrowdControl);

var bool initialized;
var UT2k4CrowdControlLink ccLink;
var config string crowd_control_addr;

replication
{
    reliable if ( Role == ROLE_Authority )
        SetPawnBoneScale;
}


simulated function InitCC()
{
    if (Role!=ROLE_Authority)
    {
        return;
    }
    if (initialized==True)
    {
        return;
    }
    
    if (crowd_control_addr==""){
        crowd_control_addr = "127.0.0.1"; //Default to locally hosted
    }
    SaveConfig();
    
    foreach AllActors(class'UT2k4CrowdControlLink',ccLink){
        break;
    }
    if (ccLink==None){
        ccLink = Spawn(class'UT2k4CrowdControlLink');
        ccLink.Init(self,crowd_control_addr);
    }

    Level.Game.Broadcast(self,"Crowd Control has initialized!");

    initialized = True;
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

//This really makes sure the old CCLink is gone, since it seems like it used to kind of persist (despite being transient)
//which prevented the client from sending messages to the right one
function ServerTraveling(string URL, bool bItems)
{
    if (ccLink!=None){
        ccLink.Close();
        ccLink.Destroy();
        ccLink=None;
    }
    if (NextMutator != None)
        NextMutator.ServerTraveling(URL,bItems);
}

simulated function ModifyPlayer(Pawn Other)
{
    if (ccLink!=None && ccLink.ccEffects!=None){
        ccLink.ccEffects.ModifyPlayer(Other);
    }
    if (NextMutator != None)
        NextMutator.ModifyPlayer(Other);
}

function ModifyLogin(out string Portal, out string Options)
{
    Super.ModifyLogin(Portal, Options);

    //Conceptually stolen from UTComp Mutator:
    // https://github.com/Deaod/UTComp
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

//Changes both here and in link class, as well as saves the config
function ChangeIp(String newIp)
{
    crowd_control_addr = newIp;
    ccLink.crowd_control_addr = newIp;
    SaveConfig();
}

function MutateHelp(PlayerController Sender)
{
    Sender.ClientMessage("UT2k4 Crowd Control Help:");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc status");
    Sender.ClientMessage("     Displays current status of the Crowd Control Mutator");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc reconnect");
    Sender.ClientMessage("     Forces a reconnect of the mutator to the configured IP");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc enable");
    Sender.ClientMessage("     Enables Crowd Control if disabled");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("  mutate cc disable");
    Sender.ClientMessage("     Disables Crowd Control if enabled");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("   mutate cc setip ip-address");
    Sender.ClientMessage("     Changes the IP used for Crowd Control (replace ip-address with the address you want)");
    Sender.ClientMessage("     Note that this doesn't force a reconnect if already connected to a CC server");
    Sender.ClientMessage(" ");
    Sender.ClientMessage("   mutate cc help");
    Sender.ClientMessage("     How did you get here without knowing about this command?");
    Sender.ClientMessage(" ");
}

function MutateReconnect(PlayerController Sender)
{
    Sender.ClientMessage("Sending reconnect request...");
    ccLink.Close();
    ccLink.Resolve(ccLink.crowd_control_addr);
}

function MutateSetIp(PlayerController Sender,string newIp)
{
     Sender.ClientMessage("Changing Crowd Control IP to <"$newIp$">");
     ChangeIp(newIp);
}

function MutateStatus(PlayerController Sender)
{
    Sender.ClientMessage("Crowd Control Status:");
    Sender.ClientMessage("CC IP: "$crowd_control_addr);
    if (ccLink.enabled){
        Sender.ClientMessage("Enabled");
    } else {
        Sender.ClientMessage("Disabled");
    }
    if(ccLink.IsConnected()){
        Sender.ClientMessage("Connected");
    } else {
        Sender.ClientMessage("Disconnected");
    }
}

function MutateChangeCCState(PlayerController Sender, bool enable)
{
    if (enable){
        Sender.ClientMessage("Enabling Crowd Control");
        ccLink.enabled=True;
        if(!ccLink.IsConnected()){
            ccLink.Resolve(ccLink.crowd_control_addr);
        }
    } else {
        Sender.ClientMessage("Disabling Crowd Control");
        ccLink.enabled=False;
        if(ccLink.IsConnected()){
            ccLink.Close();
        }
    }
}

function Mutate (string MutateString, PlayerController Sender)
{
	local string remainingStr,nextBatch;
    local int pos;
    //Command to enable/disable crowd control
    //Command to change IP
    //Command to initiate reconnect
    remainingStr = MutateString;
    
    pos = InStr(remainingStr," ");
    if (pos!=-1){
        nextBatch = Mid(remainingStr,0,pos);
        remainingStr = Mid(remainingStr,pos+1);
    } else {
        nextBatch = Mid(remainingStr,0);
        remainingStr = "";
    }
    
    if (nextBatch~="cc") {
        
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
                MutateStatus(Sender);
            } else if (nextBatch~="reconnect"){
                MutateReconnect(Sender);
            } else if (nextBatch~="setip"){
                MutateSetIp(Sender,remainingStr);
            } else if (nextBatch~="enable"){
                MutateChangeCCState(Sender,True);
            } else if (nextBatch~="disable"){
                MutateChangeCCState(Sender,False);
            } else if (nextBatch~="help"){
                MutateHelp(Sender);
            } else {
                Sender.ClientMessage("Unrecognized UT2k4 Crowd Control command: <"$nextBatch$">  Use 'mutate cc help' for more help");
            }
        
        } else {
            Sender.ClientMessage("Crowd Control mutator commands only available to admins - Please login!");
        }
    }
    
    
    if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
}

static event string GetDescriptionText(string PropName) {
    // The value of PropName passed to the function should match the variable name
    // being configured.
    switch (PropName) {
        case "crowd_control_addr":  return "The IP Address where the Crowd Control client is running";
    }
    return Super.GetDescriptionText(PropName);
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    Super.FillPlayInfo(PlayInfo);  // Always begin with calling parent
    
    PlayInfo.AddSetting("Crowd Control", "crowd_control_addr", "Crowd Control Address", 0, 2, "Text","15");

    PlayInfo.PopClass();
}

defaultproperties
{
    bAddToServerPackages=True
    FriendlyName="Crowd Control"
    Description="Let viewers mess with your game by sending effects!"
    crowd_control_addr="127.0.0.1"
}
