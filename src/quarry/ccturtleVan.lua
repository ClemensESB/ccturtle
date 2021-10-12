-- benutzt vanilla chest idee slave der die erze trägt
-- Homeing durch gänge
-- speichern des systems als graph


VERSION = "1.16"
POSITION = nil
FACING = nil
HOME = {
	position = nil,
	facing = nil
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
-- end of control block

function main(hasArgs)
    setHome()
	setDirection()
	turtle.back()

end

if #arg == 3 then
	EBN = arg[1]
	LEN = arg[2]
	LENG = arg[3]
	main(true)
else
	main(false)
end