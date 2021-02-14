--[[
Made by Richard Jones
I'm so bad at Super Mario Bros. Why should I be doing all the hard work? Mario should just do it himself.

The goal of this script is to finish Super Mario Bros with only a very limited amount of information and skill set.
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
	
	


Memory address notes:

Timer:
0x07F8-0x07FA When all 3 of the memory addresses reach 0 Mario dies.

Finish trigger:
0x010f changes to 4 once the flag is touched and turns 0 when it shows the level screen.
0x070f changes to -96 once the flag is touched and turns 0 when it shows the level screen.
0x0770 Changes from 1 to 2 the moment Mario touches the axe.

Death Trigger:
0x07CA is 0 and becomes -108 when the frame death occurs. Returns to 0 the frame the black 
screen comes up.

World:
0x075f appears to start at 0 and adds 1 when it gets to the next world.

Level:
0x0760 The first level of every world is 0. It changes the frame the black life screen 
appears or the frame when the level appears if there is no black screen.
The number of the next level depends on if there is a transition sequence between the 
first level and the 2nd(walking from the castle to a pipe to go down to the underground/sewer.
Levels that have a transition scene before the level: 1-2, 2-2, 4-2, 7-2

Movement speed:
0x0057 max of 40 when running right. Max of -40 when running left.
max walking speed is 24 and -24 respectively.

Position on map:
0x073f and 0x071C seem to be the same as each other. They increase by 1 for every pixel the 
CAMERA moves to the right. when it reaches 127 the next increment is -128
0x0086 increments by 1 every time Mario moves right by 1 pixel and decrements by 1 every 
pixel he moves left. It does not change if Mario is running against a wall. when it 
reaches 127 it goes down to -128 and vice versa.

Swimming:
0x0704 is 1 when swimming. 0 when not swimming.

Prelevel screen
0x075E Set to 1 during "prelevel" screen

Player's State:
0x000E is 8 when the player is able to move normally.
The moment Mario is able to move at the start of the level player's state turns to 8. 
0x00 - Leftmost of screen
0x01 - Climbing vine
0x02 - Entering reversed-L pipe
0x03 - Going down a pipe
0x04 - Autowalk
0x05 - Autowalk
0x06 - Player dies (Doesn't turn this value if Mario falls in a hole)
0x07 - Entering area
0x08 - Normal
0x09 - Cannot move
0x0B - Dying
0x0C - Palette cycling, can't move

--]]

--[[---------------------------------------------------
	----------------------CHECKS-----------------------
--]]---------------------------------------------------
--A check to see if Mario died. 0x07CA only changes when Mario dies. 0x07CA is 0 and becomes -108 when the frame death occurs. Returns to 0 the frame the black screen comes up.
Death = function()
	if memory.readbyte(0x07CA) == 0 then
		return false
	else
		return true
	end
end

--A check to see if Mario finished the level. 0x010F only changes when Mario finishes the level. 0x010F changes to 4 once the flag pole is touched and turns 0 when it shows the level screen.
WinLevel = function()
	if memory.readbyte(0x010F) == 0 then --an alternate memory address is 0x070F. It seems to work in the same way but it changes to -96 instead when the level finishes.
		return false
	else
		return true
	end
end

--A check to see if Mario finished a castle. 0x0770 Changes from 1 to 2 the moment Mario touches the axe.
WinCastle = function()
	if memory.readbyte(0x0770) == 1 then
		return false
	else
		return true
	end
end

--A check to see if Mario is controllable. Used for finding when a level starts.
MarioControllable = function()
	if memory.readbyte(0x000E) == 8 then
		if WinCastle() == false then
			return true
		else
			return false
		end
	else
		return false
	end
end

Swimming = function()
	if memory.readbyte(0x0704) == 1 then
		return true
	else
		return false
	end
end

--Checks to see if Mario's last few moves just made him stay in the same spot(Ex: jump, wait, jump, wait. Without any forward movement). Does not check to see if he has made progress(Ex: Doesn't know if he is stuck against a pipe)
StagnantCheck = function(movesTable, movesToCheck)
	movesToCheck = movesToCheck * 2 --The first value: amount of moves the function will check for stagnation.
	movesStagnant = true
	movesCount = 1
	while movesTable[movesCount] do
		movesCount = movesCount + 1
	end
	movesCount = movesCount - 1
	
	if movesCount < movesToCheck then --If the amount of moves that are stored is less than the amount of moves that it takes to trigger the function then it exits right away
		return false
	else
	--Checks the moves at the end of the table. If any of them isn't wait or jump then it breaks the loop and returns false right away. else it returns true.
		for i = movesCount - 1, movesCount - movesToCheck, -2 do
			if movesTable[i] ~= "A" and movesTable[i] ~= "wait" then
				movesStagnant = false
				break
			end
		end
		return movesStagnant
	end
end

FileExists = function(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

--[[---------------------------------------------------
	-----------------RETURN FUNCTIONS------------------
--]]---------------------------------------------------
--Returns the current time. The three memory addresses used are the three different digits in the timer.
Timer = function()
	local timer = 0
	timer = memory.readbyte(0x07F8) * 100
	timer = timer + (memory.readbyte(0x07F9) * 10)
	timer = timer + memory.readbyte(0x07FA)
	return timer
end

--Returns the position on map Mario is.
MapPosition = function()
	return memory.readbyte(0x0086)
end

World = function()
	return memory.readbyte(0x075f) + 1
end

--Returns the current level. This function is necessary due to the way the game keeps track of the levels. If there is a transition scene between the first and 2nd level there is considered 1 extra level in that world.
--Memory addresses referenced in this function: 
--0x0760: Current Level
--0x075F: Current World
Level = function()
	if memory.readbyte(0x0760) == 0 then --if the level is 0 always return that it is the first level.
		return 1
	else
		--The following worlds have the levels messed with: 1, 2, 4, 7. The worlds in the memory start at 0.
		if memory.readbyte(0x075F) == 0 or memory.readbyte(0x075F) == 1 or memory.readbyte(0x075F) == 3 or memory.readbyte(0x075F) == 6 then
			return memory.readbyte(0x0760)
		else
			return memory.readbyte(0x0760) + 1
		end
	end
end

RandomLeftMove = function(movesText)
	local ranNum = math.random(4)
	if ranNum == 1 then
		movesText = movesText .. "left " .. math.random(15, 50) .. " "
	elseif ranNum >= 2 and ranNum <= 4 then
		movesText = movesText .. "LeftJump " .. math.random(30, 70) .. " "
	end
	
	return movesText
end

--Randomly assigns a command to be put in to the moves text
RandomMove = function(movesText)
	local previousRan = 0
	local ranNum = math.random(7)
	moveChosen = false
	
	--These variables define the "weight" each move will have. They work off the raffle system. The numbers represent how many tickets the moves have. The more tickets the move has the more likely it is to be chosen.
	--TLDR: The higher the number, the more likely the move is to be chosen.
	local jump = 18
	local right = 30
	local rightJump = 60
	local wait = 12
	local left = 1
	local leftJump = 1
	local maxRandom = right + jump + rightJump + wait + left + leftJump
	
	
	repeat
		ranNum = math.random(maxRandom)
	until not ((ranNum <= jump) and (previousRan <= jump)) --Prevents Mario from doing nothing but jumping in place to stall for time.
	
	if ranNum <= jump then
		movesText = movesText .. "A " .. math.random(30, 40) .. " "
		moveChosen = true
	else ranNum = ranNum - jump end
	
	if ranNum <= right and moveChosen == false then
		movesText = movesText .. "right " .. math.random(15, 100) .. " "
		moveChosen = true
	else ranNum = ranNum - right end
	
	if ranNum <= rightJump and moveChosen == false then
		movesText = movesText .. "RightJump " .. math.random(35, 80) .. " "
		moveChosen = true
	else ranNum = ranNum - rightJump end
	
	if ranNum <= wait and moveChosen == false then
		movesText = movesText .. "wait " .. math.random(10, 100) .. " "
		moveChosen = true
	else ranNum = ranNum - wait end
	
	if ranNum <= left and moveChosen == false then
		movesText = movesText .. "left " .. math.random(20, 80) .. " "
		moveChosen = true
	else ranNum = ranNum - left end
	
	if ranNum <= leftJump and moveChosen == false then
		movesText = movesText .. "LeftJump " .. math.random(20, 80) .. " "
	end
	previousRan = ranNum
		
	return movesText
end

RandomWaterMove = function(movesText)
	local ranNum = math.random(6)
	if ranNum == 1 then
		movesText = movesText .. "A " .. math.random(20, 40) .. " "
	elseif ranNum == 2 then
		movesText = movesText .. "QuickSwim " .. math.random(35, 100) .. " "
	elseif ranNum == 3 then
		movesText = movesText .. "wait " .. math.random(20, 100) .. " "
	elseif ranNum >= 4 and ranNum <= 6 then
		movesText = movesText .. "RightJump " .. math.random(20, 40) .. " "
	end
	return movesText
end

--[[---------------------------------------------------
	-----------------ACTION FUNCTIONS------------------
--]]---------------------------------------------------

--Takes the data from the string and returns a readable table. The first being the name of the move and then the length of the move.
ProcessFile = function(movesText)
	local beginWord = 1
	local endWord = 1
	local movesTable = {}
	local counter = 0
	while string.len(movesText) > endWord + 1
	do
		counter = counter + 1
		if counter ~= 1 then endWord = endWord + 2 end --if endWord isn't at the start then it adds 2 to skip the space
		beginWord = endWord --set beginWord to endWord. It should be at the beginning of the next word
		endWord = (string.find(movesText, " ", endWord)) - 1--Find the end of the next word and set endWord to it
		movesTable[counter] = string.sub(movesText, beginWord, endWord) --extract the word between beginWord and endWord and put it in to movesTable
	end
	return movesTable
	
end

--Updates the current amount of deaths and appends the move set for the finished level
UpdateCompleteFile = function(deaths, movesText, world, level)
	local fileText = ""
	local completeFile = assert(io.open("complete.txt", "r"))
			while completeFile:read(1) do
			completeFile:seek("cur", -1)
			fileText = fileText .. completeFile:read(50) --Reads in the moves from complete.txt
	end
	
	if string.find(fileText, ":" .. world .. level) == nil then --if the solution for the current level doesn't exist then save the solution to complete.txt
		fileText = string.sub(fileText,string.find(fileText, "\n") + 1)
		
		local completeFile = assert(io.open("complete.txt", "w"))
		completeFile:write(deaths .. "\n" .. fileText .. "\n:" .. world .. level .. "\n" .. movesText .. "\n\n")
		completeFile:close()
	end
end

--Returns a move set for the given level in complete.txt
ReadCompleteFile = function(world, level)
	local completeFile = assert(io.open("complete.txt", "r"))
	local movesText = ""
	local findBegin = 0
	local findEndLevel = 0
	local findEndMoves = 0
	
	while completeFile:read(1) do
		completeFile:seek("cur", -1)
		movesText = movesText .. completeFile:read(50) --Reads in the moves from complete.txt
	end
	
	completeFile:close()
	
	findBegin, findEndLevel = string.find(movesText, ":" .. world .. level)
	if findBegin == nil then
		return nil
	else
		findBegin, findEndMoves = string.find(movesText, "\n", findEndLevel + 2)
		return string.sub(movesText, findEndLevel + 2, findEndMoves - 1)
	end
end

PreviousDeaths = function()
	local completeFile = assert(io.open("complete.txt", "r"))
	--local deaths = completeFile:read("*n")
	local deaths = string.sub(completeFile:read(), 1, -1)
	completeFile:close()
	return deaths
end

--Writes the given line to the moves file
WriteToFile = function (movesText)
	local saveFile = assert(io.open("moves.txt", "w"))
	saveFile:write(movesText)
	saveFile:close()
end

--function translates movesTable into a string
TableToString = function(movesTable)
	local counter = 1
	local movesText = ""
	while movesTable[counter] do
		movesText = movesText .. movesTable[counter] .. " "
		counter = counter + 1
	end
	return movesText
end

--Takes a basic button input such as "right" "left" "up" "down" "A" "B" "R" "L" "start" "select"
NormalMove = function(movesTable, counter)
	local buttonPresses = {}
	buttonPresses["B"] = 1
	buttonPresses[movesTable[counter]] = 1 --reads the name of the button being pressed and sets it as pressed in the buttonPresses table
	joypad.set(1, buttonPresses)
end

--Moves right and jumps at the same time and inputs it
RightJump = function()
	local buttonPresses = {}
	buttonPresses["A"] = 1
	buttonPresses["B"] = 1
	buttonPresses["right"] = 1
	joypad.set(1, buttonPresses)
end

LeftJump = function()
	local buttonPresses = {}
	buttonPresses["A"] = 1
	buttonPresses["B"] = 1
	buttonPresses["left"] = 1
	joypad.set(1, buttonPresses)
end

Start = function()
	local buttonPresses = {}
	buttonPresses["start"] = 1
	joypad.set(1, buttonPresses)
end

QuickSwim = function()
	local buttonPresses = {}
	local buttonsPressed = joypad.getdown(1)
	if buttonsPressed["A"] == true then
		buttonPresses["A"] = false
	else
		buttonPresses["A"] = 1
	end
	buttonPresses["B"] = 1
	buttonPresses["right"] = 1
	joypad.set(1, buttonPresses)
end

--Displays the moves being executed at the bottom left of the screen.
DisplayMove = function(move, moveFrames)
	local moveString = move .. " (" .. moveFrames .. " frames)"
	gui.text(0, 217, moveString)
end

--Displays the deaths
DisplayDeaths = function(deaths)
	local deathString = "Deaths: " .. deaths
	gui.text(0, 225, deathString)
end

--Deletes the given amount of nodes from the end of the movesTable. If Mario died then it displays the moves deleted and pauses.
DeleteNodes = function(movesTable, nodesToDelete)
	nodesToDelete = nodesToDelete * 2
	counter = 1
	deletedNodes = "Deleting:\n"
	while movesTable[counter] do
		counter = counter + 1
	end
	counter = counter - 1
	
	--Prevents from attempting to delete more nodes than there are in the table.
	if counter < nodesToDelete then
		nodesToDelete = counter
	end
	
	--Deletes movement nodes and records what it is deleting to be displayed in the UI.
	for i = counter, counter - nodesToDelete + 1, -1 do
		if (i % 2) == 0 then
			deletedNodes = deletedNodes .. movesTable[i - 1] .. " (" .. movesTable[i] .. " frames)".. "\n"
		end
		movesTable[i] = nil
	end
	
	if(Death() == true) then
		--waits 190 frames before reloading the save when he dies and displays the moves that were deleted.
		for i = 1, 190 do
			emu.frameadvance()
			gui.text(0, 217 - ((nodesToDelete/2) * 8), deletedNodes)
			DisplayDeaths(deaths)
		end
	end
	emu.print("nodesToDelete: ", nodesToDelete)
	return counter - nodesToDelete
end

--[[
	---------------------------------------------------------------
	------------------------MAIN PROGRAM---------------------------
	---------------------------------------------------------------
--]]

emu.print("Starting script")

--Starts the script at the same frame every time
emu.poweron()
WriteToFile("")
for i=1, 33, 1 do emu.frameadvance() end
Start()
for i=1, 170, 1 do emu.frameadvance() end

levelSave = savestate.create()
savestate.save(levelSave)
savestate.load(levelSave)
deaths = 0
local lastMapPosition = 0
local framesStuck = 0
local movesText = ""
local movesFile = assert(io.open("moves.txt", "r"))
while movesFile:read(1) do
		movesFile:seek("cur", -1)
		movesText = movesText .. movesFile:read(50) --Reads in the moves from moves.txt
end

--Creates and formats complete.txt if it doesn't exist
if FileExists("complete.txt") == false then
	local completeFile = assert(io.open("complete.txt", "w"), "Complete.txt couldn't be opened")
	completeFile:write(0 .. "\n")
	completeFile:close()
else
	deaths = PreviousDeaths()
	movesText = ReadCompleteFile(1,1)
	if movesText == nil then movesText = "" end
end

completeFile = assert(io.open("complete.txt", "r"), "Complete.txt couldn't be opened")

repeat
	emu.print("Start: ", movesText)
	local movesTable = ProcessFile(movesText)
	local counter = 1
	--executes the moves from the movesTable
	while (WinLevel() == false) and (WinCastle() == false) and (Death() == false) do
		--If there is no more moves in the buffer this decides what move to make next
		if movesTable[counter] == nil then
			if Swimming() == true then
				movesText = RandomWaterMove(movesText)
			else
				movesText = RandomMove(movesText)
			end
			--World 4-4 contains a spot that is required to turn around and fall down a hole to continue. This attempts to find it.
			if World() == 4 and Level() == 4 then
				if math.random(100) <= 30 then
					movesText = movesText .. "left " .. math.random(20, 50) .. " "
				end
			end
			--World 8 has requires the player to fall down a pipe. This attempts to find that pipe.
			if World() == 8 and Level() == 4 then
				if math.random(100) <= 30 then
					movesText = movesText .. "down " .. math.random(20) .. " "
				end
			end
			movesTable = ProcessFile(movesText)
			if StagnantCheck(movesTable, 5) == true then
				counter = DeleteNodes(movesTable, 5) + 1
				movesText = TableToString(movesTable)
				movesText = RandomLeftMove(movesText)
				movesTable = ProcessFile(movesText)
			elseif framesStuck >= 400 then
				if math.random(2) == 2 then
					movesText = movesText .. "wait " .. 50 .. " "
				end
				movesText = RandomLeftMove(movesText)
				if math.random(2) == 2 then
					movesText = movesText .. "wait " .. 35 .. " "
				end
				movesTable = ProcessFile(movesText)
			end
		end
		for y = 1, movesTable[counter + 1] do --Presses the button and advances the frames the amount of times specified in the file
			if movesTable[counter] ~= "wait" then
				if movesTable[counter] == "RightJump" then
					RightJump()
				elseif movesTable[counter] == "LeftJump" then
					LeftJump()
				elseif movesTable[counter] == "QuickSwim" then
					QuickSwim()
				else
					NormalMove(movesTable, counter) --if the command is a single button then it presses it
				end
			end
			if lastMapPosition == MapPosition() then
				framesStuck = framesStuck + 1
				gui.text(0, 209, "framesStuck: " .. framesStuck)
			else
				framesStuck = 0
			end
			lastMapPosition = MapPosition()
			emu.frameadvance()
			DisplayMove(movesTable[counter], movesTable[counter + 1])
			DisplayDeaths(deaths)
			if (WinLevel() == true) or (WinCastle() == true) or (Death() == true) then break end
		end
		counter = counter + 2
		emu.frameadvance()
		DisplayDeaths(deaths)
	end

	--saves the moves to the moves.txt file and does other action depending on whether or not Mario wins or dies.
	if (WinLevel() == true) or (WinCastle() == true) then
		emu.print("Congratulations! Mario finished level ", Level())
		movesText = TableToString(movesTable)
		WriteToFile(movesText)
		UpdateCompleteFile(deaths, movesText, World(), Level())--Write to completed moves file here.
		movesText = ""
		local castleDelay = WinCastle();
		--Continues the game until the next level starts
		repeat
			emu.frameadvance()
			--This creates a delay for castle levels. Due to mario being technically controllable and the level being finished for 1 frame before the next level starts loading. Without this Mario will try to save and do moves before the level starts.
			if castleDelay == true and MarioControllable() == true then
				for y = 1, 5, 1 do
					emu.frameadvance()
				end
				castleDelay = false
			end
		until MarioControllable() == true and castleDelay == false
		savestate.save(levelSave)
		--If there is a solution for the next level in complete.txt then it places it into the buffer
		if ReadCompleteFile(World(), Level()) ~= nil then
			movesText = ReadCompleteFile(World(), Level())
		end
	else
		emu.print("Mario has died")
		deaths = deaths + 1
		DeleteNodes(movesTable, 2)
		if Timer() ~= 0 then
			movesText = TableToString(movesTable)
		else --If the timer runs out it erases the file. This is to prevent Mario getting constantly stuck on a wall or going to the wrong way in an endless level.
			movesText = ""
		end
		emu.print("Finish: ", movesText)
		WriteToFile(movesText)
		savestate.load(levelSave)
	end
	framesStuck = 0
until World() ==  8 and Level() == 4 and WinCastle() == true

movesFile:close()
completeFile:close()
emu.print("Ending script")
