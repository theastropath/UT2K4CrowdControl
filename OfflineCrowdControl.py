# Can't use real Crowd Control?  Get a taste of the experience with this!

import socket
import time
import random


def genMsg(code,param):
    msg = '{"id":1,"viewer":"Python","code":"'+code+'","type":1'
    if param:
        msg+=',"parameters":['
        paramstr = ""
        for p in param:
            print(p)
            if isinstance(p,int):
                paramstr+=str(p)
            elif isinstance(p,str):
                paramstr+='"'+p+'"'
            paramstr+=","
        paramstr = paramstr[:-1]
        print(paramstr)
        msg+=paramstr
        msg+=']'

    msg+=',"duration":'
    msg+= str(random.randint(10,80)*1000)
        
    msg+='}\0'

    return msg

def randomAmmo():
    ammo = []
    ammo.append('flakammo')
    ammo.append('assaultammo')
    ammo.append('bioammo')
    ammo.append('linkammo')
    ammo.append('minigunammo')
    ammo.append('rocketammo') 
    ammo.append('shockammo')
    ammo.append('sniperammo') 
    ammo.append('mineammo') 

    return random.choice(ammo).lower()

def randomWeapon():
    weapon = []
    weapon.append('balllauncher')
    weapon.append('biorifle')
    weapon.append('flakcannon')
    weapon.append('linkgun')
    weapon.append('minigun')
    weapon.append('redeemer')
    weapon.append('rocketlauncher')
    weapon.append('shockrifle')
    weapon.append('lightninggun')
    weapon.append('translocator')
    weapon.append('supershockrifle')
    weapon.append('minelayer')

    return random.choice(weapon).lower()

def randomAnnouncer():
    announce = []
    announce.append('MaleAnnouncer')
    announce.append('FemaleAnnouncer')
    announce.append('ClassicAnnouncer')
    announce.append('UTClassicAnnouncer')
    announce.append('SexyFemaleAnnouncer')

    return random.choice(announce)


def pickEffect():
    effects = []
    
    effects.append(("sudden_death",None))
    effects.append(("full_heal",None))
    effects.append(("full_armour",None))
    effects.append(("full_adrenaline",None))
    effects.append(("give_health",[str(random.randint(10,100))]))
    effects.append(("third_person",None))
    effects.append(("bonus_dmg",None))
    effects.append(("gotta_go_fast",None))
    effects.append(("gotta_go_slow",None))
    effects.append(("thanos",None))
    effects.append(("swap_player_position",None))
    effects.append(("no_ammo",None))
    effects.append(("give_ammo",[randomAmmo(),str(random.randint(1,3))]))
    effects.append(("nudge",None))
    effects.append(("drop_selected_item",None))
    effects.append(("give_weapon",[randomWeapon()]))
    effects.append(("give_instagib",None))
    effects.append(("give_redeemer",None))
    effects.append(("melee_only",None))
    effects.append(("last_place_shield",None))
    effects.append(("last_place_bonus_dmg",None))
    effects.append(("first_place_slow",None))
    effects.append(("blue_redeemer_shell",None))
    effects.append(("vampire_mode",None))
    effects.append(("force_weapon_use",[randomWeapon()]))
    effects.append(("force_instagib",None))
    effects.append(("force_redeemer",None))
    effects.append(("reset_domination_control_points",None))
    effects.append(("return_ctf_flags",None))
    effects.append(("big_head",None))
    effects.append(("headless",None))
    effects.append(("limbless",None))
    effects.append(("full_fat",None))
    effects.append(("skin_and_bones",None))
    effects.append(("low_grav",None))
    effects.append(("ice_physics",None))
    effects.append(("flood",None))
    effects.append(("last_place_ultra_adrenaline",None))
    effects.append(("all_berserk",None))
    effects.append(("all_invisible",None))
    effects.append(("all_regen",None))
    effects.append(("thrust",None))
    effects.append(("team_balance",None))
    effects.append(("bouncy_castle",None))
    effects.append(("silent_hill",None))
    effects.append(("announcer",[randomAnnouncer()]))
    effects.append(("heal_onslaught_cores",None))
    effects.append(("reset_onslaught_links",None))
    effects.append(("winner_half_dmg",None))
    effects.append(("red_light_green_light",None))
    effects.append(("massive_momentum",None))

    return random.choice(effects)


s=socket.create_server(("localhost",43384))

while True:
    print("Connecting...")
    conn,addr = s.accept()

    with conn:
        print("Connected to ",addr)
        while True:
            #conn.send(x)
            time.sleep(random.randint(5,10))
            effect = pickEffect()
            if effect!=None:
                msg = genMsg(effect[0],effect[1])
                print("Sending "+msg)
                try:
                    conn.send(msg.encode('utf-8'))
                except:
                    break
                print("Sent")
            time.sleep(random.randint(1,2))
