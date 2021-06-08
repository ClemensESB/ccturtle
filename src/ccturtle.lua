-- north = 0 south = 2 west = 3 east = 1 up = 4 down = 5
-- x = west - east y = north - south z = up - down
-- TODO wireless control
-- listen to channel
-- local modem = peripheral.find("modem")
-- parallel.waitForAny(function,function,etc) --waits for one function to finish
-- parallel.waitForAll(function,function,etc) --waits for all given functions to finish
-- idee waitForAll(scan(),message()) message(){waitForAny(modemEvent(),sleep(2))}
-- TODO savepoints
-- change minecraft version 1.12//1.16
VERSION = "1.16"
FACEING = 0
POSITION = vector.new(0,0,0)
HOME = vector.new(0,0,0)
-- // --- will be kept in inventory ---
ITEMS = {
	["chests"] = {
		["enderChest16"] = "enderchests:ender_chest",
		["enderChest12"] = "enderstorage:ender_storage",
		["shulkerChest16"] = "minecraft:shulker_box",
		["shulkerChest12"] = "minecraft:purple_shulker_box",
		["immersiveChest12"] = "immersiveengineering:wooden_device0",
		["immersiveChest16"] = "immersiveengineering:crate",
		["mekanismChest16"] = "mekanism:personal_chest"
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
		print("#i"..v)
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
function putInChest()
	refuel()
	if invFull() then
		if turtle.detectUp() then
			turtle.digUp()
		end
		local chest = -1
		for k,v in pairs(ITEMS["chests"]) do
			if chest == -1 then
				chest = searchItem(v)
			end
		end
		if chest ~= -1 then
			turtle.select(chest)
			turtle.placeUp()
			local coal = searchItem(FUEL["coal"])
			for i=1,16 do
				if i ~= coal then
					turtle.select(i)
					local currItem = turtle.getItemDetail(i)
					if currItem ~= nil and not inArray(currItem.name,ITEMS) then
						turtle.dropUp()
					end
				end
			end
			turtle.digUp()
		else
			print("no usable chest found!")
			putInChest()
		end
	end
end

function turn(direction)
	local turnDirection = direction % 4
	local n = FACEING - turnDirection
	if n < 0 then
		n = n*(-1)
	end
	if n == 2 then
		turtle.turnRight()
		turtle.turnRight()
	elseif n == 1 then
		if FACEING > turnDirection then
			turtle.turnLeft()
		else
			turtle.turnRight()
		end
	elseif n == 3 then
		if FACEING < turnDirection then
			turtle.turnLeft()
		else
			turtle.turnRight()
		end
	else
		return false
	end
	FACEING = turnDirection
	return true
end

function move(targetVector)
	if targetVector == nil then return end
	local movV = targetVector:sub(POSITION)
	local success = true
	if movV.z > 0 then
		while movV.z > 0 do
			while turtle.detectUp() do
				turtle.digUp()
			end
			if turtle.up() then
				movV.z = movV.z - 1
			end
		end
	elseif movV.z < 0 then
		while movV.z < 0 do
			while turtle.detectDown() do
				turtle.digDown()
			end
			if turtle.down() then
				movV.z = movV.z + 1
			else
				success = false
			end
		end
	else
	end
	if success then
		POSITION.z = targetVector.z
	end
	if movV.y > 0 then
		turn(0)
		while movV.y > 0 do
			while turtle.detect() do
				turtle.dig()
			end
			if turtle.forward() then
				movV.y = movV.y - 1
			else
				success = false
			end
		end
	elseif movV.y < 0 then
		turn(2)
		while movV.y < 0 do
			while turtle.detect() do
				turtle.dig()
			end
			if turtle.forward() then
				movV.y = movV.y + 1
			else
				success = false
			end
		end
	else
	end
	if success then
		POSITION.y = targetVector.y
	end
	if movV.x > 0 then
		turn(1)
		while movV.x > 0 do
			while turtle.detect() do
				turtle.dig()
			end
			if turtle.forward() then
				movV.x = movV.x - 1
			else
				success = false
			end
		end
	elseif movV.x < 0 then
		turn(3)
		while movV.x < 0 do
			while turtle.detect() do
				turtle.dig()
			end
			if turtle.forward() then
				movV.x = movV.x + 1
			else
				success = false
			end
		end
	end
	if success then
		POSITION.x = targetVector.x
	end
	return success
end

function getSidePosition(face)
	local erg = vector.new(POSITION.x,POSITION.y,POSITION.z)
	local vectorX = vector.new(1,0,0)
	local vectorY = vector.new(0,1,0)
	local vectorZ = vector.new(0,0,1)
	if face == 0 then --north
		erg = erg + vectorY
	elseif	face == 2 then --south
		erg = erg - vectorY
	elseif	face == 3 then --west
		erg = erg - vectorX
	elseif	face == 1 then --east
		erg = erg + vectorX
	elseif	face == 4 then --up
		erg = erg + vectorZ
	elseif	face == 5 then --down
		erg = erg - vectorZ
	else
		erg = false
	end
	return erg
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

function scan(lookBack)
	local temp = FACEING
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

function fillOreStack(workStack,scanTable)
	for i,v in pairs(scanTable) do
		v:tostring()
	end
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

function clearVein(workStack)
	local nextTarget = workStack:pop()
		if nextTarget ~= false then
			move(nextTarget)
			local entrys,scanTable = scan(true)
			workStack = fillOreStack(workStack,scanTable)
			putInChest()
			if not workStack:isempty() then
				clearVein(workStack)
			end
		end
	return true
end

function mineVein(workStack)
	if not workStack:isempty() then
		clearVein(workStack)
	else
		return false
	end
	return true
end

function mineSchacht(startPos,length,mineDirection,back)
	refuel()
	move(startPos)
-- north = 0 south = 2 west = 3 east = 1 up = 4 down = 5
	local mineStack = posStack:create()
	for i=length,1,-1 do
		if mineDirection == 0 then
			mineStack:push(vector.new(POSITION.x,POSITION.y+i,POSITION.z))
		elseif mineDirection == 1 then
			mineStack:push(vector.new(POSITION.x+i,POSITION.y,POSITION.z))
		elseif mineDirection == 2 then
			mineStack:push(vector.new(POSITION.x,POSITION.y-i,POSITION.z))
		elseif mineDirection == 3 then
			mineStack:push(vector.new(POSITION.x-i,POSITION.y,POSITION.z))
		elseif mineDirection == 4 then
			mineStack:push(vector.new(POSITION.x,POSITION.y,POSITION.z+i))
		elseif mineDirection == 5 then
			mineStack:push(vector.new(POSITION.x,POSITION.y,POSITION.z-i))
		end
	end

	local scanBack = false
	if mineDirection == 4 or mineDirection == 5 then
		scanBack = true
	end
	local veinStack = posStack:create()
	while not mineStack:isempty()  do
		refuel()
		local entrys,scanTable = scan(scanBack)
		veinStack = fillOreStack(veinStack,scanTable)
		mineVein(veinStack)
		putInChest()
		move(mineStack:pop())
	end

	local entrys,scanTable = scan(scanBack)
	veinStack = fillOreStack(veinStack,scanTable)
	mineVein(veinStack)
	putInChest()

	if back then
		local returnPos = vector.new(POSITION.x,POSITION.y,POSITION.z+1)
		mineSchacht(returnPos,length,(mineDirection+2%4),false)
	end

	return true
end

function main(hasArgs)
	local startface = FACEING
	refuel()
	if not hasArgs then
		print("height")
		local EBN = read()
		local EBN = tonumber(EBN)
		print("length of tunnel:")
		local LEN = read()
		local LEN = tonumber(LEN)
		print("length of branches:")
		local LENG = read()
		local LENG = tonumber(LENG)
	else
		print("start script with z:"..EBN.." y:"..LEN.." x:"..LENG)
	end
	local chest = -1
	for k,v in pairs(ITEMS["chests"]) do
		if chest == -1 then
			chest = searchItem(v)
		end
	end
	if chest == -1 then
		print("no listed chest detected please provide chest or make")
	end
	
	


	local schachtStack = posStack:create()
	local gangStack = posStack:create()
	local pos = vector:new(POSITION.x,POSITION.y,POSITION.z)


	mineSchacht(pos,EBN,5,false)

	for i=0,EBN do
		if i % 4 == 0 then
			local pushPos = vector.new(0,0,-i)
			schachtStack:push(pushPos)
		end
	end

	while not schachtStack:isempty() do
		local popPos = schachtStack:pop()
		mineSchacht(popPos,LEN,0,true)
		for i=0,LEN do
			if i % 3 == 0 then
				local pushPos = vector.new(0,i,popPos.z)
				gangStack:push(pushPos)
			end
		end
		while not gangStack:isempty() do
			popPos = gangStack:pop()
			mineSchacht(popPos,LENG,1,true)
		end
	end
	move(HOME)
	turn(0)
	print("finshedJob!")
end

if #arg == 3 then
	EBN = arg[1]
	LEN = arg[2]
	LENG = arg[3]
	main(true)
else
	main(false)
end
