
VERSION = "1.16"
POSITION = nil
FACING = nil

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

function print_r(array)
	for i,v in pairs(array) do
		print(string.format("%s: %s",i,v))
	end
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
function setHome()
    local x,z,y = gps.locate(1)
	POSITION = vector.new(x,y,z)
    HOME.position = vector.new(x,y,z)
end
function setDirection()
	local x, z, y = gps.locate( 1 )
	if not x then
		error( "No GPS available", 0 )
	end
	if turtle.forward() then
		local nx, nz, ny = gps.locate( 1 )
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
function setPosition()
    local x,z,y = gps.locate(1)
    if not x then
		error( "No GPS available", 0 )
	end
    POSITION = vector.new(x,y,z)
end

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

function directionOfPoint(point)
	--print(tostring(point))
	--print(tostring(POSITION))
	if point.x <= POSITION.x and point.z > POSITION.z then
		-- south 0
		print("south")
		return 0
	elseif point.x > POSITION.x and point.z >= POSITION.z then
		-- east 3
		print("east")
		return 3
	elseif point.x >= POSITION.x and point.z < POSITION.z then
		-- north 2
		print("north")
		return 2
	elseif point.x < POSITION.x and point.z <= POSITION.z then
		-- west 1
		print("west")
		return 1
	else
		-- looking in wrong direction
		return false
	end
end
-- calculates the relative position to a given point and distance 
-- depends on the direction the turtle is facing
function calcExpectedPosition(startPosition,distanceVector)
	-- (1,1,1)
	local direction = FACING
	local erg = vector.new(startPosition.x,startPosition.y,startPosition.z)
	
	erg.y = erg.y + distanceVector.y

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
	local erg1 = startPoint
	local erg2 = calcExpectedPosition(startPoint,vector.new(length,0,0))
	local erg3 = calcExpectedPosition(startPoint,vector.new(length,1,0))
	local erg4 = calcExpectedPosition(startPoint,vector.new(0,1,0))
	return erg1,erg2,erg3,erg4
end
function getPlainRectangles(startPoint,depth,width)
	local erg = {}
	for i = 0, depth do
		if i % 3 == 0 then
			local rectStart = calcExpectedPosition(startPoint,vector.new(0,0,i))
			local p1,p2,p3,p4 = getRectangleKoords(rectStart,width)
			table.insert(erg,p1)
			table.insert(erg,p2)
			table.insert(erg,p3)
			table.insert(erg,p4)
		end
	end
	return erg
end
function buildJob(startPoint,height,depth,width) -- start ist oben vorne links, ende ist unten hinten rechts vom würfel
	setPosition()
	local t = directionOfPoint(startPoint)
	turn(t)
	local file = io.open("job.json","w")
	local c = 0
	for i = 0, height do
		if i % 3 == 0 then
			local plainStartPoint = calcExpectedPosition(startPoint,vector.new(0,-i,0))
			local calculatedPlain = getPlainRectangles(plainStartPoint,depth,width)
			table.insert(calculatedPlain,vector.new(plainStartPoint.x,plainStartPoint.y+1,plainStartPoint.z))
			--table.insert(calculatedPlain,plainStartPoint)
			local job = textutils.serializeJSON(calculatedPlain)
			file:write(job,"\n")
			c = c + 1
		end
	end
    -- end of file descriptor
    local information = {
        lines = c,
		start = startPoint,
		estimatedBlocks = (c * math.ceil(depth / 3) * (width + 1) + (depth - math.ceil(depth / 3))) * 2
    }
    file:write(textutils.serializeJSON(information))
	file:close()
	return c
end

function main(x,y,z,height,depth,width)
    setHome()
	setDirection()
	turtle.back()
	HOME.facing = FACING
	setPosition()
	local vec = vector.new(x,y,z)
	local ebenen = buildJob(vec,height,depth,width)
	print("Job created successfully plains: "..ebenen)
    return true
end

if #arg == 6 then
	main(tonumber(arg[1]),tonumber(arg[2]),tonumber(arg[3]),tonumber(arg[4]),tonumber(arg[5]),tonumber(arg[6]))
else
	shell.execute("clear")
	print("please enter the target location x,y,z")
	local vec = io.read()

	print("please enter the target location heigth,depth,width")
	local dimensions = io.read()

	vec = strToVector(vec)
	dimensions = strToVector(dimensions)
	main(vec.x,vec.y,vec.z,dimensions.x,dimensions.y,dimensions.z)
end