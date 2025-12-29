section .data
    err_nulinput: db "Error: NULL input.", 0

    pmt_dirc: db "1 (North), 2 (East), 3 (West), 4 (South): ", 0
    err_dirc: db "Invalid direction.", 0
    msg_nort: db "You walk North.", 0
    msg_east: db "You walk East.", 0
    msg_west: db "You walk West.", 0
    msg_sout: db "You walk South.", 0

    msg_fight_01_1: db "Your HP: ", 0
    msg_fight_01_2: db ", Enemy HP: ", 0
    msg_fight_02: db "What do you do?", 0
    pmt_fight_02: db "1 (Attack), 2 (Block), 3 (Run)", 0
    err_fight_02: db "You got a bit confused and whacked yourself in the face.", 0
    res_fight_02_1_1: db "You dealt ", 0
    res_fight_02_1_2: db " damage! current Enemy HP: ", 0
    res_fight_02_2: db "You blocked the oncoming attack!", 0
    res_fight_02_3_1: db "You failed to escape the battle.", 0
    res_fight_02_3_2: db "You escape the battle.", 0
    msg_fight_03_1: db "The enemy deals ", 0
    msg_fight_03_2: db " damage!", 0
    res_fight_01: db "You lost...", 0
    res_fight_02: db "You won!", 0

    msg_0000: db "Welcome to the Assembly Text Adventure Game!", 0
    pmt_0000: db "Choose difficulty: 1 (Easy), 2 (Hard) ", 0
    err_0000: db "Invalid input.", 0
    res_0000_1: db "You chose easy difficulty.", 0
    res_0000_2: db "You chose hard difficulty.", 0

    msg_0001: db "You wake up in a dark basement. Which direction do you go?", 0
    res_0001_1: db "It's a dead end.", 0
    res_0001_2: db "You enter another, seemingly identical room.", 0
    res_0001_3_v1: db "You bump into a goblin, and it attacks!", 0
    res_0001_3_v2: db "It's a dead end.", 0
    res_0001_4: db "You enter another, seemingly identical room.", 0

    msg_0002: db "You are in a nondescript dark room. Where do you go?", 0
    res_0002_1: db "It's a dead end.", 0
    res_0002_2_v1: db "You find a healing potion!", 0
    res_0002_2_v2: db "It's a dead end.", 0
    res_0002_3: db "You go back to the starting room.", 0
    res_0002_4: db "You enter another dark room.", 0

    pmt_pot: db "Do you 1 (use it) or 2 (leave it)? ", 0
    err_pot: db "Invalid input.", 0
    res_pot_1: db "You drank the potion.", 0
    res_pot_2: db "You left the potion where it is.", 0

    msg_0003: db "You are... still in a dark room. Where do you go?", 0
    res_0003_1: db "You enter the starting room.", 0
    res_0003_2_v1: db "You find some gold! 50, to be exact.", 0
    res_0003_2_v2: db "It's a dead end.", 0
    res_0003_3: db "You enter another dark room.", 0
    res_0003_4_v1: db "You find a healing potion!", 0
    res_0003_4_v2: db "It's a dead end.", 0

    msg_0004: db "This must be getting old. You are in a dark room. Where do you go?", 0
    res_0004_1: db "You enter the room you came from.", 0
    res_0004_2: db "It's a dead end.", 0
    res_0004_3: db "It's a dead end.", 0
    res_0004_4: db "It's a dead end, but as you turn around... A goblin blocks your path!", 0

    msg_0005: db "Guess where you are. Yep, a dark room!", 0
    res_0005_1_v1: db "There's a goblin staring at you.", 0
    res_0005_1_v2: db "You enter a dimly lit room.", 0
    res_0005_2: db "It's a dead end.", 0
    res_0005_3: db "It's a dead end.", 0
    res_0005_4: db "You enter the room you came from.", 0

    msg_0006: db "It's dark in here, isn't it?", 0
    res_0006_1: db "You enter another dark room, but there seems to be a little bit of light to the North.", 0
    res_0006_2: db "You enter another dark room.", 0
    res_0006_3: db "There's a goblin, and it attacks!", 0
    res_0006_4_v1: db "You find a healing potion!", 0
    res_0006_4_v2: db "It's a dead end.", 0

    msg_0007: db "There's light to the North.", 0
    res_0007_1: db "It's the exit! You made it!", 0
    res_0007_2: db "It's a dead end.", 0
    res_0007_3: db "It's a dead end.", 0
    res_0007_4: db "You stepped back into darkness.", 0
