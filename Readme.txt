Made by Richard Jones
Started: 2/18/2014
I'm so bad at Super Mario Bros. Why should I be doing all the hard work? Mario should just do it himself.

The goal of this script is to finish Super Mario Bros with only a very limited amount of information and skill set. It brute forces solutions and saves ones that work.
This script was made for the FCEUX emulator with the Super Mario Bros. (Japan, USA).nes ROM.

This is the information that "Mario" knows:
	-When he dies
	-Whether he died from running out of time
	-When he finishes a level
	-When he finishes the game
	-The end of the level is to the right
	-Knows when he isn't moving forward
	-What level he is on (But no more information about the level other than the fact that he has to duck to go down a pipe at some point in 8-4)
	-Whether he is swimming and that he has to paddle quickly sometimes in water levels
	
Things that "Mario" DOESN'T know:
	-Where enemies are
	-Where obstacles are
	-The layout of the level
	-Existence of powerups
	-Shortcuts
	-Bonus areas
	
This is the abilities that "Mario" has:
	-Allowed to savestate at the beginning of a level
	-Ability to repeat his previous actions perfectly
	
Memory addresses that "Mario" uses:
	-0x07CA: Only changes when Mario dies.
	-0x010F: Only changes when Mario finishes a regular level.
	-0x0770: Only changes when Mario finishes a castle.
	-0x????: Only changes when Mario finishes the game.
	-0x000E: Determines whether or not Mario is controllable.
	-0x07F8, 0x07F9, and 0x07FA: The three digits of the timer.
	-0x075f: Current World.
	-0x0760: Current Level.
	-0x073f: Current spot on the map. Used only to find out if Mario is moving.
	-0x0704: Determines whether or not Mario is swimming.



To start the script:

1. Run fceux.exe
2. File -> open ROM and select Super Mario Bros. (Japan, USA).nes
3. File -> Lua -> new lua scipt window. Browse to the lua scipt folder and open "do it your damn self mario". Click run.

This will run the moveset that will get mario to the last level of the game. To have the script rediscover the solutions to the levels rename the "complete" file in the lua scripts folder.

"+" and "-" increase and decrease the speed of the emulation respectively.

A solution file "Complete.txt" has the solution for all levels except for the final one. If you would like to start the discovery process delete or rename this file. 