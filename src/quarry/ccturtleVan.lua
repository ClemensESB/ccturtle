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
-- 

-- berechnen eines Weges AB mit zwischenkoordinaten -- PRIO
-- benutzt vanilla chest idee slave der die erze trägt 
-- Homeing durch gänge
-- speichern des systems als graph (angefangen)


VERSION = "1.16"
POSITION = nil
FACING = nil

-- // --- will be kept in inventory ---
ITEMS = {
	["chests"] = {
		["modChest16"] = "enderchests:ender_chest",
		["modChest12"] = "enderstorage:ender_storage",
		["vanillaChest16"] = "minecraft:shulker_box",
		["vanillaChest12"] = "minecraft:purple_shulker_box",
		["immersiveChest12"] = "immersiveengineering:wooden_device0",
		["immersiveChest16"] = "immersiveengineering:crate",
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
	setmetatable(stack,posStack)
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
	for i=1,self.index do
		local posTest = self.entry[i]
		if posTest.x == pos.x and posTest.y == pos.y and posTest.z == pos.z then
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
function inArray(needle,haystack)
	for key,value in pairs(haystack) do
		if needle == value then
			return true
		end
	end
	return false
end
function strContains(needle,haystack)
	local first,last = string.find(haystack,needle)
	if first ~= nil and last ~= nil then
		return true
	else
		return false
	end
end
function strToArray(stringToConvert)
	local erg = {}
	local i = 1
	if stringToConvert ~= nil then
		for param in stringToConvert:gmatch('[^,%s]+') do
			erg[i] = param
			i = i + 1
		end
	end
	return erg
end
function strToVector(stringToConvert)
	local temp = {}
	local i = 1
	for param in stringToConvert:gmatch('[^,%s]+') do
		temp[i] = tonumber(param)
		i = i + 1
	end
	local ergVector = vector.new(temp[1],temp[2],temp[3])
	return ergVector
end
function print_r(array)
	for i,v in pairs(array) do
		print(string.format("%s: %s",i,v))
	end
end
-- math functions
-- euler distance
function distance(a,b)
	local d = math.sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)+(a.z-b.z)*(a.z-b.z))
	return d
end
-- turtle functions
function refuel()
	local fuelLevel = turtle.getFuelLevel()
	local fuel = -1
	for key,value in pairs(FUEL) do
		if fuel == -1 then
			fuel = searchItem(value)
		end
	end
	if fuelLevel < 100 then
		if fuel > 0 then
			turtle.select(fuel)
			turtle.refuel()
		else
			print("turtle needs fuel fuellevel: "..fuelLevel)
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
function searchItem(itemstring)
	turtle.select(1)
	local erg = -1
	for i = 1,16 do
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
function invFull()
	turtle.select(1)
	local erg = false
	for i=1,16 do
		if turtle.getItemCount(i) == 0 then
			return false
		end
	end
	print("inventory full")
	return true
end
function invEmpty()
	for i=1,16 do
		if turtle.getItemCount(i) ~= 0 then
			return false
		end
	end
	return true
end
function setHome()
    local x,y,z = gps.locate(1)
	POSITION = vector.new(x,y,z)
    HOME.position = vector.new(x,y,z)
end
function setDirection()
	local x, y, z = gps.locate( 1 )
	if not x then
		error( "No GPS available", 0 )
	end
	if turtle.forward() then
		local nx, ny, nz = gps.locate( 1 )
		if x - nx == 1 then
			-- West
			HOME.facing= 1
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
function setPosition()
    local x,y,z = gps.locate(1)
    if not x then
		error( "No GPS available", 0 )
	end
    POSITION = vector.new(x,y,z)
end
function getSidePosition(face)
    setPosition()
    local erg = vector.new(POSITION.x,POSITION.y,POSITION.z)
	local vectorX = vector.new(1,0,0)
	local vectorY = vector.new(0,1,0)
	local vectorZ = vector.new(0,0,1)
	if face == 2 then --north
		erg = erg - vectorZ
	elseif	face == 0 then --south
		erg = erg + vectorZ
	elseif	face == 1 then --west
		erg = erg - vectorX
	elseif	face == 3 then --east
		erg = erg + vectorX
	elseif	face == 4 then --up
		erg = erg + vectorY
	elseif	face == 5 then --down
		erg = erg - vectorY
	else
		erg = false
	end
	return erg
end
-- end of turtle functions

-- start of control block
function turn(direction)
	local turnDirection = direction % 4
	local n = FACING - turnDirection
	if n < 0 then
		n = n*(-1)
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
function scanSide(side)
	local success,erg
	if side <= 3 then
		turn(side)
		success,erg = turtle.inspect()
	elseif side == 4 then
		success,erg = turtle.inspectUp()
	elseif side == 5 then
		success,erg = turtle.inspectDown()
	else
		return false
	end
	return success,erg
end
function move(targetVector)
	if targetVector == nil then return end
    setPosition()
    -- oben unten als erstes brute forced
	if targetVector.y > POSITION.y then
		while targetVector.y > POSITION.y do
			while turtle.detectUp() do
				turtle.digUp()
			end
            turtle.up()
            setPosition()
            refuel()
		end
	elseif targetVector.y < POSITION.y then
		while targetVector.y < POSITION.y do
			while turtle.detectDown() do
				turtle.digDown()
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
				turtle.dig()
			end
			turtle.forward()
			setPosition()
            refuel()
		end
	elseif targetVector.z < POSITION.z then -- geh nach norden
		turn(2)
		while targetVector.z < POSITION.z do
			while turtle.detect() do
				turtle.dig()
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
				turtle.dig()
			end
			turtle.forward()
			setPosition()
            refuel()
		end
	elseif targetVector.x < POSITION.x then -- geh nach westen
		turn(1)
		while targetVector.x < POSITION.x do
			while turtle.detect() do
				turtle.dig()
			end
			turtle.forward()
			setPosition()
            refuel()
		end
	end
	return true
end
function scan(lookBack)
	local temp = FACING
	local tempTable = nil
	local ergTable = {}
	local back = -1
	if lookBack then
		back = (temp+2)%4
	else
		back = temp
	end
	local a = 0
	local sideArray = {(temp-1)%4,back,(temp+1)%4,temp,4,5}
	for index,value in pairs(sideArray) do
		local success,tempTable = scanSide(value)
		if success then
			if (strContains("ore",tempTable.name) or inArray(tempTable.name,ADDITIONAL_ORES)) and not inArray(tempTable.name,NOT_BREAKABLE) then
				a = a+1
				ergTable[a] = getSidePosition(value)
			end
		end
	end
	turn(temp)
	return a,ergTable
end

function goHome()
	while not HOME.path:isempty() do
		local temp = HOME.path:pop()
		move(temp)
		JOB.path:push(temp)
	end
	turn(HOME.facing)
end
function returnToJob()
	while not JOB.path:isempty() do
		local temp = JOB.path:pop()
		move(temp)
		HOME.path:push(temp)
	end
end
function adjectedInventoryFull()

end
function locateChests()
	local temp = FACING
	local sideArray = {(temp-1) % 4,(temp+1) % 4}
	turtle.select(1)
	local canUp = false
	while not invEmpty() do
		for index,value in pairs(sideArray) do
			local success,tempTable = scanSide(value)
			if success and inArray(tempTable.name,ITEMS["chests"])  then
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
			move(vector.new(POSITION.x,POSITION.y+1,POSITION.z))
		end
	end
end
function putInChest()
	goHome()
	locateChests()
	returnToJob()
end
-- end of control block

-- start Job functions input of target location
function fileLines (fileName)
  local count = 0
  for line in io.lines(fileName) do
    count = count + 1
  end
  return count
end
function fileLine (lineNum, fileName)
  local count = 0
  for line in io.lines(fileName) do
    count = count + 1
    if count == lineNum then return line end
  end
  error(fileName .. " has fewer than " .. lineNum .. " lines.")
end
function parseJob(startLine,endLine)
	local file = io.open("job.json","r")
	local temp = {}
	local c = 1
	local lines = fileLines("job.json")
	local information = textutils.unserializeJSON(fileLine(lines,"job.json"))

	print_r(information)

	if endLine < 0 or endLine > information.lines then
		endLine = information.lines
	end

	for i = startLine, endLine do
		file:seek("set",i)
		temp[c] = textutils.unserializeJSON(file:read())
		c = c + 1
	end
	file:close()
	local erg = {}
	local i = 1
	for ebene, vecTable in pairs(temp) do
		local tableLength = #(vecTable)
		erg[ebene] = {}
		for i = 1, tableLength do
			erg[ebene][i] = vector.new(vecTable[i].x,vecTable[i].y,vecTable[i].z)
		end
	end
	JOB.koords = erg
	return true
end
-- end job functions

-- start of mining functions
function fillOreStack(workStack,scanTable)
	for index,value in pairs(scanTable) do
		if value ~= nil then
			local orePos = vector.new(value.x,value.y,value.z)
			if not workStack:inStack(orePos) then
				workStack:push(orePos)
			end
		end
	end
	return workStack
end
function mineVein(vertical)
	setPosition()
	local start = vector.new(POSITION.x,POSITION.y,POSITION.z)
	local direction = FACING
	local orePosStack = posStack:create()
	repeat
		if not orePosStack:isempty() then
			move(orePosStack:pop())
		end
		local succ,scanTable = scan(vertical)
		orePosStack = fillOreStack(orePosStack,scanTable)
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
function mineToTarget(target)
	setPosition()
	while POSITION.y ~= target.y do
		if POSITION.y > target.y then
			mineVein(true)
			move(vector.new(POSITION.x,POSITION.y - 1,POSITION.z))
		else
			mineVein(true)
			move(vector.new(POSITION.x,POSITION.y + 1,POSITION.z))
		end
	end

	while POSITION.x ~= target.x do
		if POSITION.x > target.x then
			mineVein(false)
			move(vector.new(POSITION.x - 1,POSITION.y,POSITION.z))
		else
			mineVein(false)
			move(vector.new(POSITION.x + 1,POSITION.y,POSITION.z))
		end
	end

	while POSITION.z ~= target.z do
		if POSITION.z > target.z then
			mineVein(false)
			move(vector.new(POSITION.x,POSITION.y,POSITION.z - 1))
		else
			mineVein(false)
			move(vector.new(POSITION.x,POSITION.y,POSITION.z + 1))
		end
	end
end
function mineJob()	
	HOME.path:push(HOME.position) -- home position
	HOME.path:push(vector.new(JOB.koords[1][1].x,HOME.position.y,JOB.koords[1][1].z)) -- start operation position
	
	for key, ebene in pairs(JOB.koords) do
		local arrLength = #(ebene)
		HOME.path:push(ebene[1]) -- start ebene position
		HOME.path:push(ebene[1]) -- start ebene position
		for i = 0, arrLength-1 do
			mineToTarget(ebene[i+1])
			if i % 4 == 0 then
				HOME.path:pop()
				HOME.path:push(ebene[i+1]) -- start gang position
			end
		end
	end
end
-- end of mining functions

function main(startE,endE)
	refuel()
	setHome()
	setDirection()
	turtle.back()
	HOME.facing = FACING
	setPosition()
	--local ebenen = 1
	local succ = parseJob(startE,endE)
	if succ then
		mineJob()
	end
	print("returning to Home")
	goHome()
	turn(HOME.facing)
	print("finished!")
end
if #arg == 1 then
	main(arg[1],arg[2])
else
	main(1,-1)
end