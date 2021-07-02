_G.shell = shell
local myURL = "ws://localhost:2256"
VERSION = "1.16"
FACEING = 0
POSITION = vector.new(0,0,0)
HOME = vector.new(0,0,0)
LABEL = os.getComputerLabel()

MESSAGE = {
	sender = LABEL,
	receiver = "Client",
	data = nil
}

_G.GLOB_FUNC = {
turn = function(direction)
    direction = tonumber(direction)
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
	return {["faceing"] = FACEING}
end,
turnDirect = function (side)
	--print(side)
	local face = FACEING
	if side == "left" then
		return GLOB_FUNC.turn((face-1)%4)
	elseif side == "right" then
		return GLOB_FUNC.turn((face+1)%4)
	end
end,
getSidePosition = function(face)
    face = tonumber(face)
	local erg = vector.new(POSITION.x,POSITION.y,POSITION.z)
	local vectorX = vector.new(1,0,0)
	local vectorY = vector.new(0,1,0)
	local vectorZ = vector.new(0,0,1)
	if face == 0 then --north
		erg = erg - vectorZ
	elseif	face == 2 then --south
		erg = erg + vectorZ
	elseif	face == 3 then --west
		erg = erg - vectorX
	elseif	face == 1 then --east
		erg = erg + vectorX
	elseif	face == 4 then --up
		erg = erg + vectorY
	elseif	face == 5 then --down
		erg = erg - vectorY
	else
		erg = false
	end
	return erg
end,
-- north = 0 south = 2 west = 3 east = 1 up = 4 down = 5
move = function (direction)
	if direction == "up" then
		if turtle.up() then
			POSITION.y = POSITION.y+1
			return GLOB_FUNC.getPosition()
		end
	elseif direction == "down" then
		if turtle.down() then
			POSITION.y = POSITION.y-1
			return GLOB_FUNC.getPosition()
		end
	elseif direction == "forward" then
		if FACEING == 0 then
			if turtle.forward() then
				POSITION.z = POSITION.z-1
				return GLOB_FUNC.getPosition()
			end
		elseif FACEING == 1 then
			if turtle.forward() then
				POSITION.x = POSITION.x+1
				return GLOB_FUNC.getPosition()
			end
		elseif FACEING == 2 then
			if turtle.forward() then
				POSITION.z = POSITION.z+1
				return GLOB_FUNC.getPosition()
			end
		elseif FACEING == 3 then
			if turtle.forward() then
				POSITION.x = POSITION.x-1
				return GLOB_FUNC.getPosition()
			end
		end
	elseif direction == "back" then
		if FACEING == 0 then
			if turtle.back() then
				POSITION.z = POSITION.z+1
				return GLOB_FUNC.getPosition()
			end
		elseif FACEING == 1 then
			if turtle.back() then
				POSITION.x = POSITION.x-1
				return GLOB_FUNC.getPosition()
			end
		elseif FACEING == 2 then
			if turtle.back() then
				POSITION.z = POSITION.z-1
				return GLOB_FUNC.getPosition()
			end
		elseif FACEING == 3 then
			if turtle.back() then
				POSITION.x = POSITION.x+1
				return GLOB_FUNC.getPosition()
			end
		end
	end
	return false
end,
getPosition = function()
	local erg = {["position"] = vector.new(POSITION.x,POSITION.y,POSITION.z),["faceing"] = FACEING}
	return erg
end,
inspect = function(side)
	local erg = {["block"] = 0,["position"]=0}
	if side == "up" then
		erg["position"]=GLOB_FUNC.getSidePosition(4)
		erg["block"]={turtle.inspectUp()}
	elseif side == "down" then
		erg["position"]=GLOB_FUNC.getSidePosition(5)
		erg["block"]={turtle.inspectDown()}
	elseif side == "front" then
		erg["position"]=GLOB_FUNC.getSidePosition(FACEING)
		erg["block"]={turtle.inspect()}
	end
	return erg
end
}

NET = {
    server = myURL,
    socket = nil,
    open_channels = {},
    messageq = nil
}
function NET.connect(force)
	if not NET.socket or force then
		-- If we already have a socket and are throwing it away, close old one.
		if NET.socket then NET.socket.close() end
		local sock = http.websocket(NET.server)
		if not sock then return "NET server unavailable, broken or running newer protocol version." end
		NET.socket = sock
	end
end
function NET.send(data)
    NET.connect()
	MESSAGE.data = data
    data = textutils.serializeJSON(MESSAGE)
	--print(MESSAGE)
    NET.socket.send(data)
end
function NET.receive(timeout)
    NET.connect()
    local message = NET.socket.receive(timeout)
	--local obj,err = textutils.unserializeJSON(message)
	--if err == nil and obj ~= nil then
		--return obj
	--else 
	--	return nil
	--end
	return message
end
function NET.close()
    if NET.socket then NET.socket.close() end
end
function print_r(array)
	for i,v in pairs(array) do
		print(i,v)
	end
end



repeat
	local okest,msgest = pcall(NET.send,"connected")
until okest
---if not okest then
--	os.reboot()
--end
os.sleep(1)
while true do
	local msgok,message =  nil,nil
    repeat
		os.sleep(0.1)
		msgok,message = pcall(NET.receive,5)
		if message == "client.lua:169: attempt to use a closed file" then
			os.reboot()
		end
    --event, url, message = os.pullEvent("websocket_message")
    --until url == myURL
	until msgok == true and message ~= nil
    local msg = message
    local obj,erro = textutils.unserializeJSON(msg)
	if obj.receiver == LABEL then
		local func,err
		local erg ={}
		if erro == nil and obj ~= nil then
			print_r(obj)
			func,err = load(obj.data)
			if func ~= nil then
				local ok = {pcall(func)}
				if ok[1] then
					--print_r(ok)
					for k,v in pairs(ok) do
						table.insert(erg,k,v)
					end
				else
					print("Execution error:", func)
				end
			else
				print("Compilation error:")
			end
		else
			err = true
		end
		if erg ~= nil then
			--print(textutils.serializeJSON(erg))
			NET.send(erg) 
		end
	end
end
NET.close()
