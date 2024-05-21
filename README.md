# Crowd Control for Unreal Tournament 2004

This is a mutator which can be used to connect to the Crowd Control service, which allows Twitch Viewers to interact with a game that a streamer is participating in.
Since only one instance of Crowd Control can be attached at a time, most effects apply to all players on the server simultaneously.  A few apply to the player in first/last place, and a few more apply to random players.


## Compiling

I have been compiling this project using UMake (https://github.com/SeriousBuggie/unreal-umake).  Simply put the contents of this repository into a UT2k4CrowdControl folder in the main Unreal Tournament 2004 install directory, then drag the files inside the Classes folder onto UMake.
The compiled .u file will be put into the System folder.


## Installing

Either compile the .u file or download it from the Releases page and put it into the System folder of your Unreal Tournament 2004 installation.  The mutator should then be available to use in the Mutators menu.


## Restoring Online Servers

Want to try this out on the greater internet?  You'll probably want to connect to the community master server instead of the now-defunct original servers.  If you're playing and hosting from your regular game, [you can follow the instructions here](https://ut2004serverlist.com/how-to-update-your-game/) to update the master servers.  If you are going to run a dedicated server (using the server software), [you can follow the instructions here](https://ut2004serverlist.com/updating-your-game-server/) instead.


## Campaign Mode

Campaign support for Crowd Control (including Simulated Crowd Control or the Randomizer, or all at once) is here!  Unfortunately this requires some additional setup beyond the normal installation and you **cannot** use an existing campaign save (in fact, you can't even load them at the moment).

Locate your UT2004.ini file in the System directory and open it.

Find the line that starts with "SinglePlayerMenuClass=" and change it to

```
SinglePlayerMenuClass=UT2k4CrowdControl.UT2K4SPMutator_Main
```

Next, find the line that starts with "GUIController=" and change it to

```
GUIController=UT2k4CrowdControl.UT2K4GUIControllerMutator
```

and you should be able to create a new save in the Single Player menu and start playing Crowd Control!

If you want to revert to the normal single player campaign, you can change those lines back to:

```
SinglePlayerMenuClass=GUI2K4.UT2K4SP_Main
GUIController=GUI2K4.UT2K4GUIController
```

## Adjusting Mutators Used in Campaign Mode

Start a single player match (even just the very first tutorial is fine), then quit the game.  In your System directory you should find a file called **MutatorLadder.ini**.

There should be a line that starts with "MutatorList=".  This line defines which mutators will be loaded in the single player campaign.  This is a simple comma-separated list and can include any mutator you have installed.  The names of the mutators in this package are:

```
Crowd Control = UT2k4CrowdControl.CrowdControl
Simulated Crowd Control = UT2k4CrowdControl.OfflineCrowdControl
Randomizer = UT2k4CrowdControl.Randomizer
```

If you wanted all three of those mutators running in the single player campaign, you could modify your MutatorList line in MutatorLadder.ini to look like this:

```
MutatorList=UT2k4CrowdControl.CrowdControl,UT2k4CrowdControl.OfflineCrowdControl,UT2k4CrowdControl.Randomizer
```

## Feedback
  
Join the Discord server to discuss this mod or to provide feedback: https://mods4ever.com/discord

  

