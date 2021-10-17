-- erzerkennung +
-- gps anbindung (kein internes gps ~ fucked ohne externes gps) +
-- bruteforceing durch wände +
-- automatisches auftanken +
-- arbeitsstop bei vollem inventar +
-- berechnen von relativen blockpositionen +
-- berechnen von rechteck koordinaten für mienenschächte +
-- automatisches ausrichten der turtle für eine mining operation +
-- 

-- benutzt vanilla chest idee slave der die erze trägt 
-- Homeing durch gänge
-- speichern des systems als graph (angefangen)


VERSION = "1.16"
POSITION = nil
FACING = nil
HOME = {
	position = nil,
	facing = nil,
	path = {}
}


-- // --- will be kept in inventory ---
ITEMS = {
	["chests"] = {
		["modChest16"] = "enderchests:ender_chest",
		["modChest12"] = "enderstorage:ender_storage",
		["vanillaChest16"] = "minecraft:shulker_box",
		["vanillaChest12"] = "minecraft:purple_shulker_box",
		["immersiveChest12"] = "immersiveengineering:wooden_device0",
		["immersiveChest16"] = "immersiveengineering:crate"
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
		print("#i"..tostring(v))
	end
end
-- math functions
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
-- controlling the turtle
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
--local chest = peripheral.find("minecraft:chest")
--for slot, item in pairs(chest.list()) do
--	print(("%d x %s in slot %d"):format(item.count, item.name, slot))
--end
function goHome()
	move(HOME.position)
end

-- end of control block
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

function mineVein()
	setPosition()
	local start = vector.new(POSITION.x,POSITION.y,POSITION.z)
	local direction = FACING
	local orePosStack = posStack:create()
	local succ,scanTable = scan(false)
	orePosStack = fillOreStack(orePosStack,scanTable)
	repeat
		if not orePosStack:isempty() then
			move(orePosStack:pop())
		end
		local succ,scanTable = scan(false)
		orePosStack = fillOreStack(orePosStack,scanTable)
	until orePosStack:isempty()
	move(start)
	turn(direction)
	return true
end


-- end of mining functions

-- start Job functions input of target location
function directionOfPoint(point)
	if point.x < POSITION.x and point.z > POSITION.z then
		-- south 0
		print("south")
		return 0
	elseif point.x > POSITION.x and point.z > POSITION.z then
		-- east 3
		print("east")
		return 3
	elseif point.x > POSITION.x and point.z < POSITION.z then
		-- north 2
		print("north")
		return 2
	elseif point.x < POSITION.x and point.z < POSITION.z then
		-- west 1
		print("west")
		return 1
	else
		-- looking in wrong direction
		return false
	end
end

function calcExpectedPosition(startPosition,distanceVector)
	-- (1,1,1)
	local direction = FACING
	local erg = vector.new(startPosition.x,startPosition.y,startPosition.z)
	if distanceVector.y >= 0 then
		erg.y = erg.y + distanceVector.y
	else
		erg.y = erg.y - distanceVector.y
	end

	if direction == 1 or direction == 3 then
		local z = distanceVector.x
		local x = distanceVector.z
		distanceVector.x = x
		distanceVector.z = z
	end

	if direction == 0 then
		-- if south right -x forward +z
		erg.x = erg.x - distanceVector.x
		erg.z = erg.z + distanceVector.z
	elseif direction == 1 then
		-- if west right -z forward -x
		erg.x = erg.x - distanceVector.x
		erg.z = erg.z - distanceVector.z
	elseif direction == 2 then
		-- if north right +x forward -z
		erg.x = erg.x + distanceVector.x
		erg.z = erg.z - distanceVector.z
	elseif direction == 3 then
		-- if east right +z forward +x
		erg.x = erg.x + distanceVector.x
		erg.z = erg.z + distanceVector.z
	end
	return erg
end

function getRectangleKoords(startPoint,length)
	local erg = {startPoint}
	erg[2] = calcExpectedPosition(startPoint,vector.new(length,0,0))
	erg[3] = calcExpectedPosition(startPoint,vector.new(length,1,0))
	erg[4] = calcExpectedPosition(startPoint,vector.new(0,1,0))
	return erg
end


function buildJob(startPoint,endPoint) -- start ist oben vorne links, ende ist unten hinten rechts vom würfel
	setPosition()
	local jobStack = posStack:create()
	-- tiefe
	local height = startPoint.y - endPoint.y -- verticale tiefe der operation
	--local depth = 

	for i = 0, height do
		if i % 3 == 0 then
			for j = 1, 10, 1 do
				-- hmm
			end
		end
	end
	


	local file = io.open("job","w")
	while not jobStack:isempty() do
		local vec = jobStack:pop():tostring()
		file:write(vec,"\n")
	end
	file:close()
end


-- end job functions


function main(x,y,z)
	if x == nil and y == nil and z == nil then
		error("please use ccturtleVan x y z",1)
	end
    setHome()
	setDirection()
	turtle.back()
	setPosition()
	--buildJob(x,y,z)
	--local succ = directionOfPoint(vector.new(x,y,z))
	--local succ = calcExpectedPosition(vector.new(x,y,z))
	--local succ = getRectangleKoords(vector.new(x,y,z),5)

	--for key, value in pairs(succ) do
	--	print(tostring(value))	
	--end
	
	

end

if #arg == 3 then
	main(tonumber(arg[1]),tonumber(arg[2]),tonumber(arg[3]))
else
	main(nil,nil,nil)
end