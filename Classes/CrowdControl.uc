class CrowdControl extends Mutator config(CrowdControl);

var bool initialized;
var UT2k4CrowdControlLink ccLink;
var UT2k4CCHUDOverlay hudOverlay;
var config string crowd_control_addr;


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
    //I bet this doesn't work in multiplayer
    if (PlayerController(Other.Controller)!=None){
        if (PlayerController(Other.Controller).myHUD!=None){
            if (hudOverlay==None){
                hudOverlay=Spawn(class'UT2k4CCHUDOverlay');
            }
            PlayerController(Other.Controller).myHUD.AddHudOverlay(hudOverlay);
        }
    }
    if (ccLink!=None && ccLink.ccEffects!=None){
        ccLink.ccEffects.ModifyPlayer(Other);
    }
    if (NextMutator != None)
        NextMutator.ModifyPlayer(Other);
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
