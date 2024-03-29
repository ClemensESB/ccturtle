-- erzerkennung +
-- gps anbindung (kein internes gps ~ fucked ohne externes gps) +
-- bruteforceing durch wände +
-- automatisches auftanken +
-- arbeitsstop bei vollem inventar +
-- berechnen von relativen blockpositionen +
-- berechnen von rechteck koordinaten für mienenschächte +
-- berechnung von Ebene mit rechtecken +
-- speichern der jobanweisungen +
-- parsen der jobanweisungen +
-- automatisches ausrichten der turtle für eine mining operation +
-- berechnen eines Weges AB mit zwischenkoordinaten  +
-- benutzt vanilla chest +
-- Homeing durch gänge +
-- speichern des systems als graph (angefangen) +


-- aufteilung eines jobs auf mehrere turtles
-- jobübermittlung via wireless modem
-- erze gesammelt tracking
-- idee sklave der die erze trägt

-- require("ccMessage")
-- require("ccModem")



VERSION = "1.16"
POSITION = nil
FACING = nil
OPERATIONSTART = nil

TURTLEDATA = {
	name = os.computerLabel(),
	fuel = turtle.getFuelLevel(),
	minedBlockTypes = {},
	minedBlocks = 0,
	estimatedBlocks = 0,
	speed = 0.0,
	estimatedTIme = 0.0,
	startTime = os.epoch("local"),
	runtime = 0.0
}
OLDTIME = os.epoch("local")

-- // --- will be kept in inventory ---
ITEMS = {
	["chests"] = {
		["1.16"] = {
			["modChest16"] = "enderchests:ender_chest",
			["vanillaChest16"] = "minecraft:shulker_box",
			["immersiveChest16"] = "immersiveengineering:crate"
		},
		["1.12"] = {
			["modChest12"] = "enderstorage:ender_storage",
			["vanillaChest12"] = "minecraft:purple_shulker_box",
			["immersiveChest12"] = "immersiveengineering:wooden_device0",
		},
		["chest"] = "minecraft:chest"
	},
	["pickaxe"] = "minecraft:diamond_pickaxe",
	["modemNormal"] = "computercraft:wireless_modem_normal",
	["modemAdvanced"] = "computercraft:wireless_modem_advanced",
	["chunkLoader"] = "advancedperipherals:chunk_controller"
}
-- // --- will be used as fuel---
FUEL = {
	["coal"] = "minecraft:coal",
	["charcoal"] = "minecraft:charcoal",
	["coalBlock"] = "minecraft:coal_block"
}
-- // --- will not try to farm ---
NOT_BREAKABLE = {
	["allthemodium"] = "allthemodium:allthemodium_ore",
	["vibranium"] = "allthemodium:vibranium_ore",
	["unobtainium"] = "allthemodium:unobtainium_ore"
}
-- // --- ores which have no ore in id ---
ADDITIONAL_ORES = {
	["blackQuarz"] = "actuallyadditions:block_misc"
}



posStack = {}
posStack.__index = posStack
function posStack:create()
	local stack = {}
	setmetatable(stack, posStack)
	stack.index = 0
	stack.entry = {}
	return stack
end

function posStack:push(pos)
	self.index = self.index + 1
	self.entry[self.index] = pos
	return true
end

function posStack:pop()
	if self.index > 0 then
		local erg = self.entry[self.index]
		self.entry[self.index] = nil
		self.index = self.index - 1
		return erg
	end
	return false
end

function posStack:inStack(pos)
	local erg = false
	for i = 1, self.index do
		local posTest = self.entry[i]
		if posTest == pos then
			erg = true
		else
		end
	end
	return erg
end

function posStack:isempty()
	return self.index <= 0
end

function posStack:getIndex()
	return self.index
end

function posStack:getByIndex(i)
	return self.entry[i]
end

function posStack:tostring()
	local erg = ""
	for key, value in pairs(self.entry) do
		erg = erg .. "k:" .. key .. " v:" .. tostring(value) .. "\n"
	end
	return erg
end

function posStack:clear()
	self.entry = {}
	self.index = 0
end

HOME = {
	position = nil,
	facing = nil,
	path = posStack:create()
}
JOB = {
	koords = nil,
	path = posStack:create()
}


-- // --- END of global Variables ---
-- nützliche logik
local function inArray(needle, haystack)
	for key, value in pairs(haystack) do
		if needle == value then
			return true
		end
	end
	return false
end

local function strContains(needle, haystack)
	local first, last = string.find(haystack, needle)
	if first ~= nil and last ~= nil then
		return true
	else
		return false
	end
end

local function strToArray(stringToConvert, limit)
	local erg = {}
	local i = 1
	if stringToConvert ~= nil then
		for param in stringToConvert:gmatch('[^' .. limit .. '%s]+') do
			erg[i] = param
			i = i + 1
		end
	end
	return erg
end

local function strToVector(stringToConvert)
	local temp = {}
	local i = 1
	for param in stringToConvert:gmatch('[^,%s]+') do
		temp[i] = tonumber(param)
		i = i + 1
	end
	local ergVector = vector.new(temp[1], temp[2], temp[3])
	return ergVector
end

local function print_r(array)
	for i, v in pairs(array) do
		if type(v) == "table" then
			print_r(v)
		else
			print(string.format("%s: %s", i, v))
		end

	end
end

local function vecEqual(vec1, vec2)
	if vec1.x == vec2.x and vec1.y == vec2.y and vec1.z == vec2.z then
		return true
	end
	return false
end

-- math local functions
-- euklid distance
local function edistance(a, b)
	local d = math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z))
	return d
end

local function odistance(a, b)
	local d = math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
	return d
end

-- turtle functions
local function searchItem(itemstring)
	turtle.select(1)
	local erg = -1
	for i = 1, 16 do
		if turtle.getItemCount(i) > 0 then
			local item = turtle.getItemDetail(i)
			if item.name == itemstring then
				return i
			else
				erg = -1
			end
		else
			erg = -1
		end
	end
	return erg
end

local function refuel()
	local fuelLevel = turtle.getFuelLevel()
	local fuel = -1
	for key, value in pairs(FUEL) do
		if fuel == -1 then
			fuel = searchItem(value)
		end
	end
	if fuelLevel < 100 then
		if fuel > 0 then
			turtle.select(fuel)
			turtle.refuel()
		else
			print("turtle needs fuel fuellevel: " .. fuelLevel)
		end
	elseif fuelLevel < 5000 then
		if fuel > 0 then
			turtle.select(fuel)
			turtle.refuel()
		end
	end
	if turtle.getFuelLevel() == 0 then
		print("turtle has no fuelitem")
		refuel()
	end
	return true
end

local function invFull()
	turtle.select(1)
	local erg = false
	for i = 1, 16 do
		if turtle.getItemCount(i) == 0 then
			return false
		end
	end
	print("inventory full")
	return true
end

local function invEmpty()
	for i = 1, 16 do
		if turtle.getItemCount(i) ~= 0 then
			return false
		end
	end
	return true
end

local function setHome()
	local x, y, z = gps.locate(1)
	POSITION = vector.new(x, y, z)
	HOME.position = vector.new(x, y, z)
end

local function setDirection()
	local x, y, z = gps.locate(1)
	if not x then
		error("No GPS available", 0)
	end
	if turtle.forward() then
		local nx, ny, nz = gps.locate(1)

		if x - nx == 1 then
			-- West
			HOME.facing = 1
		elseif x - nx == -1 then
			-- East
			HOME.facing = 3
		elseif z - nz == 1 then
			-- North
			HOME.facing = 2
		else
			-- South
			HOME.facing = 0
		end
	end
	FACING = HOME.facing
end

local function setPosition()
	local x, y, z = gps.locate(1)
	if not x then
		error("No GPS available", 0)
	end
	tempVec = vector.new(x, y, z)
	if not vecEqual(tempVec, POSITION) then
		local speed = os.epoch("local") - OLDTIME --ms seit der letzten positionsänderung
		OLDTIME = os.epoch("local")
		local speedPerHour = 60 / ((speed / 1000) / 60) --blocks per hour
		TURTLEDATA.estimatedTIme = TURTLEDATA.estimatedBlocks / speedPerHour
		TURTLEDATA.speed = speedPerHour
		TURTLEDATA.runtime = (os.epoch("local") - TURTLEDATA.startTime) / 1000 / 60 / 60 --runtime in hours
		local CCMessage = require("ccMessage")
		local CCModem = require("ccModem")
		local msg = CCMessage.CCMessage:create("turtleStatus", TURTLEDATA, "running", 128, TURTLEDATA.name)
		local modem = CCModem.CCModem:create()
		modem:send(128, 129, textutils.serialiseJSON({ msg.header, msg.data }))
	end
	POSITION = tempVec
end

local function getSidePosition(face)
	setPosition()
	local erg = vector.new(POSITION.x, POSITION.y, POSITION.z)
	local vectorX = vector.new(1, 0, 0)
	local vectorY = vector.new(0, 1, 0)
	local vectorZ = vector.new(0, 0, 1)
	if face == 2 then --north
		erg = erg - vectorZ
	elseif face == 0 then --south
		erg = erg + vectorZ
	elseif face == 1 then --west
		erg = erg - vectorX
	elseif face == 3 then --east
		erg = erg + vectorX
	elseif face == 4 then --up
		erg = erg + vectorY
	elseif face == 5 then --down
		erg = erg - vectorY
	else
		erg = false
	end
	return erg
end

-- end of turtle functions

-- start of control block
local function turn(direction)
	local turnDirection = direction % 4
	local n = FACING - turnDirection
	if n < 0 then
		n = n * (-1)
	end
	if n == 2 then
		turtle.turnRight()
		turtle.turnRight()
	elseif n == 1 then
		if FACING > turnDirection then
			turtle.turnLeft()
		else
			turtle.turnRight()
		end
	elseif n == 3 then
		if FACING < turnDirection then
			turtle.turnLeft()
		else
			turtle.turnRight()
		end
	else
		return false
	end
	FACING = turnDirection
	return true
end

local function scanSide(side)
	local success, erg
	if side <= 3 then
		turn(side)
		success, erg = turtle.inspect()
	elseif side == 4 then
		success, erg = turtle.inspectUp()
	elseif side == 5 then
		success, erg = turtle.inspectDown()
	else
		return false
	end
	return success, erg
end

local function dig(digDirection)
	local blockname = ""
	if digDirection == "up" then
		local success, erg = turtle.inspectUp()
		if turtle.digUp() then
			blockname = erg.name
		end
	elseif digDirection == "down" then
		local success, erg = turtle.inspectDown()
		if turtle.digDown() then
			blockname = erg.name
		end
	elseif digDirection == "forward" then
		local success, erg = turtle.inspect()
		if turtle.dig() then
			blockname = erg.name
		end
	else
		return false
	end

	if TURTLEDATA["minedBlockTypes"][blockname] ~= nil then
		TURTLEDATA["minedBlockTypes"][blockname] = TURTLEDATA["minedBlockTypes"][blockname] + 1
	else
		TURTLEDATA["minedBlockTypes"][blockname] = 1
	end
	TURTLEDATA.minedBlocks = TURTLEDATA.minedBlocks + 1
	return true
end

local function move(targetVector)
	if targetVector == nil then return end
	setPosition()
	-- oben unten als erstes brute forced
	if targetVector.y > POSITION.y then
		while targetVector.y > POSITION.y do
			while turtle.detectUp() do
				dig("up")
			end
			turtle.up()
			setPosition()
			refuel()
		end
	elseif targetVector.y < POSITION.y then
		while targetVector.y < POSITION.y do
			while turtle.detectDown() do
				dig("down")
			end
			turtle.down()
			setPosition()
			refuel()
		end
	else
	end

	if targetVector.z > POSITION.z then --geh nach süden
		turn(0)
		while targetVector.z > POSITION.z do
			while turtle.detect() do
				dig("forward")
			end
			turtle.forward()
			setPosition()
			refuel()
		end
	elseif targetVector.z < POSITION.z then -- geh nach norden
		turn(2)
		while targetVector.z < POSITION.z do
			while turtle.detect() do
				dig("forward")
			end
			turtle.forward()
			setPosition()
			refuel()
		end
	else
	end
	-- x als letztes
	if targetVector.x > POSITION.x then -- geh nach osten
		turn(3)
		while targetVector.x > POSITION.x do
			while turtle.detect() do
				dig("forward")
			end
			turtle.forward()
			setPosition()
			refuel()
		end
	elseif targetVector.x < POSITION.x then -- geh nach westen
		turn(1)
		while targetVector.x < POSITION.x do
			while turtle.detect() do
				dig("forward")
			end
			turtle.forward()
			setPosition()
			refuel()
		end
	end
	TURTLEDATA.fuel = turtle.getFuelLevel()
	return true
end

local function scan(lookBack, checkedStack)
	local temp = FACING -- alte richtung
	local ergTable = {} -- ergebnis
	local back = -1 -- rückrichtung
	if lookBack then
		back = (temp + 2) % 4
	else
		back = temp
	end
	local a = 0
	local sideArray = { (temp - 1) % 4, back, (temp + 1) % 4, temp, 4, 5 }
	for index, value in pairs(sideArray) do
		local sidePosition = getSidePosition(value)
		if not checkedStack:inStack(sidePosition) then
			local success, tempTable = scanSide(value)
			if success then
				if (strContains("ore", tempTable.name) or inArray(tempTable.name, ADDITIONAL_ORES)) and
					not inArray(tempTable.name, NOT_BREAKABLE) then
					a = a + 1
					ergTable[a] = sidePosition

				end
			end
			checkedStack:push(sidePosition)
		end
	end
	turn(temp)
	return a, ergTable
end

local function goHome()
	while not HOME.path:isempty() do
		local temp = HOME.path:pop()
		move(temp)
		JOB.path:push(temp)
	end
	turn(HOME.facing)
end

local function returnToJob()
	while not JOB.path:isempty() do
		local temp = JOB.path:pop()
		move(temp)
		HOME.path:push(temp)
	end
end

local function adjectedInventoryFull()
end

local function locateChests()
	local temp = FACING
	local sideArray = { (temp - 1) % 4, (temp + 1) % 4 }
	turtle.select(1)
	local canUp = false
	while not invEmpty() do
		for index, value in pairs(sideArray) do
			local success, tempTable = scanSide(value)
			if success and inArray(tempTable.name, ITEMS["chests"]) then
				for slot = 1, 16 do
					turtle.select(slot)
					turtle.drop()
				end
				canUp = true
			else
				canUp = false
			end
		end
		if canUp then
			move(vector.new(POSITION.x, POSITION.y + 1, POSITION.z))
		end
	end
end

local function putInChest()
	refuel()
	if invFull() then
		local chest = -1
		for k, v in pairs(ITEMS["chests"][VERSION]) do
			if chest == -1 then
				chest = searchItem(v)
			end
		end
		if chest ~= -1 then
			turtle.select(chest)
			if turtle.detectUp() then
				dig("up")
			end
			turtle.placeUp()
			local coal = searchItem(FUEL["coal"])
			for i = 1, 16 do
				if i ~= coal then
					turtle.select(i)
					local currItem = turtle.getItemDetail(i)
					if currItem ~= nil and not inArray(currItem.name, ITEMS) then
						turtle.dropUp()
					end
				end
			end
			turtle.digUp() -- hier damit die chest nicht mitgezählt wird
		else
			print("no usable chest found!")
			goHome()
			locateChests()
			returnToJob()
		end
	end
end

-- end of control block

-- start Job functions input of target location
local function fileLines(fileName)
	local count = 0
	for line in io.lines(fileName) do
		count = count + 1
	end
	return count
end

local function fileLine(fileName, lineNum)
	local count = 0
	for line in io.lines(fileName) do
		count = count + 1
		if count == lineNum then return line end
	end
	error(fileName .. " has fewer than " .. lineNum .. " lines.")
end

local function parseJob(startLine, endLine)
	local temp = {}
	local c = 1
	local lines = fileLines("job.json")
	local information = textutils.unserializeJSON(fileLine("job.json", lines))

	if endLine < 0 or endLine > information.lines then
		endLine = information.lines
		TURTLEDATA.estimatedBlocks = information.estimatedBlocks
	end

	for i = startLine, endLine do
		temp[c] = textutils.unserializeJSON(fileLine("job.json", i))
		c = c + 1
	end
	local erg = {}
	local i = 1
	OPERATIONSTART = vector.new(information.start.x, information.start.y, information.start.z)
	for ebene, vecTable in pairs(temp) do
		local tableLength = #(vecTable)
		erg[ebene] = {}
		for i = 1, tableLength do
			erg[ebene][i] = vector.new(vecTable[i].x, vecTable[i].y, vecTable[i].z)
		end
	end
	JOB.koords = erg
	return true
end

-- end job functions

-- start of mining functions
local function fillOreStack(workStack, scanTable)
	for index, value in pairs(scanTable) do
		if value ~= nil then
			local orePos = vector.new(value.x, value.y, value.z)
			if not workStack:inStack(orePos) then
				workStack:push(orePos)
			end
		end
	end
	return workStack
end

local function mineVein(vertical, checkedStack)
	setPosition()
	local start = vector.new(POSITION.x, POSITION.y, POSITION.z)
	local direction = FACING
	local orePosStack = posStack:create()

	repeat
		if not orePosStack:isempty() then
			move(orePosStack:pop())
		end
		local succ, scanTable = scan(vertical, checkedStack)

		orePosStack = fillOreStack(orePosStack, scanTable)
		if invFull() then
			HOME.path:push(start)
			HOME.path:push(POSITION)
			putInChest()
			HOME.path:pop()
			HOME.path:pop()
		end
	until orePosStack:isempty()
	move(start)
	turn(direction)
	return true
end

local function mineToTarget(target, checkedStack)
	setPosition()

	while POSITION.y ~= target.y do
		if POSITION.y > target.y then
			mineVein(true, checkedStack)
			move(vector.new(POSITION.x, POSITION.y - 1, POSITION.z))
		else
			mineVein(true, checkedStack)
			move(vector.new(POSITION.x, POSITION.y + 1, POSITION.z))
		end
	end

	while POSITION.x ~= target.x do
		if POSITION.x > target.x then
			mineVein(false, checkedStack)
			move(vector.new(POSITION.x - 1, POSITION.y, POSITION.z))
		else
			mineVein(false, checkedStack)
			move(vector.new(POSITION.x + 1, POSITION.y, POSITION.z))
		end
	end

	while POSITION.z ~= target.z do
		if POSITION.z > target.z then
			mineVein(false, checkedStack)
			move(vector.new(POSITION.x, POSITION.y, POSITION.z - 1))
		else
			mineVein(false, checkedStack)
			move(vector.new(POSITION.x, POSITION.y, POSITION.z + 1))
		end
	end
end

local function mineJob()
	HOME.path:push(HOME.position) -- home position
	HOME.path:push(OPERATIONSTART) -- start operation position
	local checkedStack = posStack:create()
	mineToTarget(OPERATIONSTART, checkedStack)
	for key, ebene in pairs(JOB.koords) do
		local arrLength = #(ebene)
		HOME.path:push(ebene[1]) -- start ebene position
		checkedStack:clear()
		for i = 0, arrLength - 1 do
			mineToTarget(ebene[i + 1], checkedStack)
			if i % 4 == 0 then
				HOME.path:pop()
				HOME.path:push(ebene[i + 1]) -- start gang position
			end
		end
	end
end

-- end of mining functions

local function main(startE, endE)
	refuel()
	setHome()
	setDirection()
	turtle.back()
	HOME.facing = FACING
	setPosition()
	local succ = parseJob(startE, endE)
	if succ then
		mineJob()
	end
	print("returning to Home")
	goHome()
	turn(HOME.facing)
	print("finished!")
	return true
end

if #arg == 2 then
	main(tonumber(arg[1]), tonumber(arg[2]))
elseif #arg == 1 and arg[1] == "test" then
	-- hier können funktionen getestet werden
	local tstack = posStack:create()
	local vec1 = vector.new(1, 1, 1)
	local vec2 = vector.new(1, 1, 1)
	local vec3 = vector.new(1, 1, 2)

	tstack:push(vec2)


	print(vec1 == vec2)
	print(vec1 == vec3)
	print(inArray(vec1, tstack:array()))
else
	main(1, -1)
end
