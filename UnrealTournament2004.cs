using System;
using System.Collections.Generic;
using CrowdControl.Common;
using CrowdControl.Games.Packs;
using ConnectorType = CrowdControl.Common.ConnectorType;

namespace CrowdControl.Games.Packs.UnrealTournament2004;

public class UnrealTournament2004 : SimpleTCPPack
{
    public override string Host => "0.0.0.0";

    public override ushort Port => 43384;

    public override ISimpleTCPPack.MessageFormat MessageFormat => ISimpleTCPPack.MessageFormat.CrowdControlLegacy;

    public UnrealTournament2004(UserRecord player, Func<CrowdControlBlock, bool> responseHandler, Action<object> statusUpdateHandler) : base(player, responseHandler, statusUpdateHandler) { }

    public override Game Game { get; } = new(999, "Unreal Tournament 2004", "UnrealTournament2004", "PC", ConnectorType.SimpleTCPConnector);

    //Weapon list
    private static readonly ParameterDef weaponList = new("Weapons", "weapons",
        new Parameter("Translocator", "translocator"),
        new Parameter("BioRifle", "biorifle"),
        new Parameter("Flak Cannon", "flakcannon"),
        new Parameter("Lightning Gun", "lightninggun"),
        new Parameter("Shock Rifle", "shockrifle"),
        new Parameter("Link Gun", "linkgun"),
        new Parameter("Minigun", "minigun"),
        new Parameter("Rocket Launcher", "rocketlauncher"),
        new Parameter("Spider Mine Layer", "minelayer")
    );

    //Ammo List
    private static readonly ParameterDef ammoList = new("Ammo", "ammo",
        new Parameter("Assault Rifle Bullets", "assaultammo"),
        new Parameter("Bio-Rifle Goop", "bioammo"),
        new Parameter("Flak Shells", "flakammo"),
        new Parameter("Link Ammo", "linkammo"),
        new Parameter("Minigun Bullets", "minigunammo"),
        new Parameter("Rockets", "rocketammo"),
        new Parameter("Shock Core", "shockammo"),
        new Parameter("Lightning Charges", "sniperammo"),
        new Parameter("Parasite Mines", "mineammo")
    );

    //Announcer List
    private static readonly ParameterDef announcerList = new("Announcer", "announcer",
        new Parameter("Male Announcer", "UnrealGame.MaleAnnouncer"),
        new Parameter("Female Announcer", "UnrealGame.FemaleAnnouncer"),
        new Parameter("UT2003 Announcer", "UnrealGame.ClassicAnnouncer"),
        new Parameter("UT99 Announcer", "UnrealGame.UTClassicAnnouncer"),
        new Parameter("Sexy Female Announcer", "UnrealGame.SexyFemaleAnnouncer")
    );

    public override EffectList Effects { get; } = new Effect[]
    {
        //General Effects
        new Effect("Go Third-Person", "third_person"){Price = 10, Description = "Force players to see themselves!", Duration=60},
        new Effect("Full Fat Tournament", "full_fat"){Price = 4, Description = "All players become extremely fat!", Duration=60},
        new Effect("Just Skin and Bones", "skin_and_bones"){Price = 4, Description = "All players become extremely skinny!", Duration=60},
        new Effect("Big Head Mode", "big_head"){Price = 4, Description = "All players get an inflated ego!", Duration=60},
        new Effect("Headless", "headless"){Price = 4, Description = "All players lose their head!", Duration=60},
        new Effect("Limbless Mode", "limbless"){Price = 4, Description = "All players lose their limbs!", Duration=60},
        new Effect("Pint-Sized", "pint_sized"){Price = 4, Description = "All players become much smaller!", Duration=60},
        new Effect("Gotta Go Fast", "gotta_go_fast"){Price = 10, Description = "It's extra fast mode!", Duration=60},
        new Effect("Gotta Go Slow", "gotta_go_slow"){Price = 10, Description = "It's extra slow mode!", Duration=15},
        new Effect("Swap All Players Positions", "swap_player_position"){Price = 10, Description = "All players swap positions on the map!"},
        new Effect("Nudge All Players", "nudge"){Price = 5, Description = "Push the players around!"},
        new Effect("Ice Physics", "ice_physics"){Price = 10, Description = "Summon frosty floors!", Duration=60},
        new Effect("Low Gravity", "low_grav"){Price = 5, Description = "Low gravity means players jump higher!", Duration=60},
        new Effect("Flood the Arena", "flood"){Price = 10, Description = "Flood the arena!", Duration=20},
        new Effect("Slow First Place Player", "first_place_slow"){Price = 5, Description = "The first place player is too good, let's punish them!", Duration=45},
        //new Effect("Spawn an Attacking Bot (One Death)", "spawn_a_bot_attack"){Price = 10, Description = "This will spawn a bot on whatever team has the least amount of players and will be on the offensive"},
        //new Effect("Spawn a Defending Bot (One Death)", "spawn_a_bot_defend"){Price = 10, Description = "This will spawn a bot on whatever team is has the least amount of players with orders to defend their base"},
        new Effect("Reset Domination Control Points", "reset_domination_control_points"){Category = "Game Mode Specific Effects", Price = 5, Description = "This will reset all control points in Domination Mode to neutral"},
        new Effect("Return Flags", "return_ctf_flags"){Category = "Game Mode Specific Effects", Price = 5, Description = "In Capture the Flag Mode, this will return all flags to their base"},
        new Effect("Heal Onslaught Power Cores", "heal_onslaught_cores"){Category = "Game Mode Specific Effects", Price = 10, Description = "In Onslaught Mode, this will fully heal both power cores."},
        new Effect("Reset Onslaught Power Nodes", "reset_onslaught_links"){Category = "Game Mode Specific Effects", Price = 15, Description = "In Onslaught Mode, this will reset all the intermediate power nodes to neutral."},
        new Effect("Fumble Bombing Run Ball", "fumble_bombing_run_ball"){Category = "Game Mode Specific Effects", Price = 5, Description = "In Bombing Run Mode, cause the ball carrier to fumble the ball!"},
        new Effect("Hot Potato", "bombing_run_hot_potato"){Category = "Game Mode Specific Effects", Price = 5, Description = "In Bombing Run Mode, the ball becomes a hot potato!  If a player holds the ball for more than five seconds, they explode!", Duration=60 },
        new Effect("Attacking Team Double Damage", "attack_team_double_dmg"){Category = "Game Mode Specific Effects", Price = 5, Description = "In Bombing Run or Assault Mode, the attacking team deals double damage!", Duration=60 },
        new Effect("Defending Team Double Damage", "defend_team_double_dmg"){Category = "Game Mode Specific Effects", Price = 5, Description = "In Bombing Run or Assault Mode, the defending team deals double damage!", Duration=60 },
        new Effect("Head Shots Only", "head_shots_only"){Category = "Weapons & Damage", Price = 10, Description = "Only shots to the head actually do damage!", Duration=60 },
        new Effect("Wiggle Time", "thrust"){Price = 1, Description = "Everyone gets wiggly!", Duration=60 },
        new Effect("Switch First Place Player Team", "team_balance"){Category = "Game Mode Specific Effects", Price = 5, Description = "The player in first place switches to the other team!"},
        new Effect("Bouncy Castle", "bouncy_castle"){Price = 5, Description = "Everyone gets periodically bounced up into the air!", Duration=60},
        new Effect("Silent Hill Mode", "silent_hill"){Price = 10, Description = "The whole level becomes as foggy as Silent Hill!", Duration=60},
        new Effect("Octojump", "octojump"){Price = 2, Description = "Everyone can jump in the air 8 times!", Duration=60 },
        new Effect("Winner Deals Half Damage", "winner_half_dmg"){Category = "Weapons & Damage", Price = 3, Description = "The player or team in first place only deals half damage!", Duration=60},
        new Effect("Red Light, Green Light", "red_light_green_light"){Price = 5, Description = "The light randomly changes between Red and Green!  Move while the light is red and... KABOOM!", Duration=60},
        new Effect("Massive Momentum", "massive_momentum"){Category = "Weapons & Damage", Price = 3, Description = "All damage imparts significantly more momentum to the target!", Duration=60},
        new Effect("Select Announcer Voice", "announcer")
        {
            Parameters = announcerList,
            Price = 10,
            Description = "Select what announcer the player should hear in-game!"
        },
        ////////////////////////////////////////////////////////////////
        
        //new Effect("Health and Armor","health",ItemKind.Folder),
        new Effect("Full Heal", "full_heal") { Category = "Health & Ammo", Price = 5, Description = "Send a full heal to all players!" },
        new Effect("Shield Belts for All", "full_armour") { Category = "Health & Ammo", Price = 5, Description = "You get a shield belt and you get a shield belt! Everyone gets shield belts!" },
        new Effect("Give Health", "give_health")
        {
            Quantity = 200,
            Category = "Health & Ammo",
            Price = 1,
            Description = "Give a little health!"
        },
        new Effect("Sudden Death", "sudden_death") { Category = "Health & Ammo", Price = 10, Description = "Activate sudden death mode!" },
        new Effect("Thanos Snap", "thanos") { Category = "Health & Ammo", Price = 15, Description = "Half of the living players in the match get blown to bits!  Perfectly balanced, as all things should be." },
        new Effect("Vampiric Attacks", "vampire_mode") { Category = "Health & Ammo", Price = 10, Description = "All attacks by players sap some life, healing the player!", Duration=60 },
        new Effect("Give Shield Belt to Last Place", "last_place_shield") { Category = "Health & Ammo", Price = 5, Description = "Help out that last place player!" },
        new Effect("Blue (Redeemer) Shell", "blue_redeemer_shell") { Category = "Health & Ammo", Price = 15, Description = "Drops a redeemer explosion on the player in first place!" },
        
        /////////////////////////////////////////////////////////////////
        
        //new Effect("Weapons and Damage","weapons",ItemKind.Folder),
        new Effect("Give Weapon to All", "give_weapon")
        {
            Parameters = weaponList,
            Category = "Weapons & Damage",
            Price = 5,
            Description = "Give all players any normal weapon in the game!"
        }, //Needs to use a weapons list
        new Effect("Give Instagib Rifles to All", "give_instagib") { Category = "Weapons & Damage", Price = 15, Description = "Give an Instagib Rifle to all players!" },
        new Effect("Give Redeemers to All", "give_redeemer") { Category = "Weapons & Damage", Price = 15, Description = "Give a redeemer to all players!" },
        new Effect("Force Everybody to Use Weapon", "force_weapon_use")
        {
            Parameters = weaponList,
            Category = "Weapons & Damage",
            Price = 25,
            Description = "Force all players to only use one specific weapon you choose!",
            Duration=60
        }, //Needs to use a weapons list
        new Effect("Force All Players to use Instagib Rifle", "force_instagib") { Category = "Weapons & Damage", Price = 15, Description = "Force all players to use an Instagib Rifle only", Duration=60 },
        new Effect("Force All Players to use Redeemers", "force_redeemer") { Category = "Weapons & Damage", Price = 15, Description = "Force all players to use redeemers only!", Duration=60 },
        new Effect("Give Ammo", "give_ammo")
        {
            Quantity = 10,
            Parameters = ammoList,
            Category = "Weapons & Damage",
            Price = 1,
            Description = "Give some specific ammo of your choice to all players!"
        },
        new Effect("Remove All Ammo", "no_ammo") { Category = "Weapons & Damage", Price = 10, Description = "Steal all ammo from players!" },
        new Effect("Bonus Damage for All", "bonus_dmg") { Category = "Weapons & Damage", Price = 5, Description = "Pump up the damage on all players" },
        new Effect("Melee Only!", "melee_only") { Category = "Weapons & Damage", Price = 10, Description = "Never mind these guns, it's punching time!", Duration=60 },
        new Effect("Bonus Damage for Last Place", "last_place_bonus_dmg") { Category = "Weapons & Damage", Price = 5, Description = "Help out the last place player and grant them bonus damage!" },
        new Effect("All Players Drop Current Weapon", "drop_selected_item") { Category = "Weapons & Damage", Price = 10, Description = "Who needs this weapon anyway..." },
        new Effect("Thorns", "thorns") { Category = "Weapons & Damage", Price = 5, Description = "Any damage a player deals gets reflected back on them at 50% strength!", Duration=60 },

        //new("Announcer Voice", "announcer", ItemKind.BidWar)
        //{
        //    Parameters = new ParameterDef("Voice", "voice_param",
        //        new("Male Announcer", "male"),
        //        new("Female Announcer", "female"),
        //        new("UT2003 Announcer", "ut2k3"),
        //        new("UT99 Announcer", "ut99"),
        //        new("Sexy Female Announcer", "sexy"))
        //},

        new Effect("Full Adrenaline", "full_adrenaline") { Category = "Adrenaline & Combos", Price = 2, Description = "Max out all players adrenaline!" },
        new Effect("Infinite Adrenaline", "infinite_adrenaline") { Category = "Adrenaline & Combos", Price = 10, Description = "All players have infinite adrenaline for a period of time!", Duration=60 },
        new Effect("Ultra Adrenaline Powers for Last Place", "last_place_ultra_adrenaline") { Category = "Adrenaline & Combos", Price = 10, Description = "The player in last place gains all of the adrenaline powers at once!" },
        new Effect("Invisible Players", "all_invisible") { Category = "Adrenaline & Combos", Price = 5, Description = "All players become temporarily invisible!" },
        new Effect("Berserker!", "all_berserk") { Category = "Adrenaline & Combos", Price = 5, Description = "All players become berserk temporarily!" },
        new Effect("All Players Regenerate", "all_regen") { Category = "Adrenaline & Combos", Price = 5, Description = "All players begin to regenerate health temporarily!" }
    };
}
