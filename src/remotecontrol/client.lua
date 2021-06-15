_G.shell = shell
local myURL = "ws://66568dd80de6.ngrok.io:80"
VERSION = "1.16"
FACEING = 0
POSITION = vector.new(0,0,0)
HOME = vector.new(0,0,0)
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
	return true
end,

    getSidePosition = function(face)
    face = tonumber(face)
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
end,
-- north = 0 south = 2 west = 3 east = 1 up = 4 down = 5
move = function (direction)
	if direction == "up" then
		if turtle.up() then
			POSITION.y = POSITION.y+1
			return true
		end
	elseif direction == "down" then
		if turtle.down() then
			POSITION.y = POSITION.y-1
			return true
		end
	elseif direction == "forward" then
		if FACEING == 0 then
			if turtle.forward() then
				POSITION.z = POSITION.z-1
				return true
			end
		elseif FACEING == 1 then
			if turtle.forward() then
				POSITION.x = POSITION.x+1
				return true
			end
		elseif FACEING == 2 then
			if turtle.forward() then
				POSITION.z = POSITION.z+1
				return true
			end
		elseif FACEING == 3 then
			if turtle.forward() then
				POSITION.x = POSITION.x-1
				return true
			end
		end
	elseif direction == "back" then
		if FACEING == 0 then
			if turtle.forward() then
				POSITION.z = POSITION.z+1
				return true
			end
		elseif FACEING == 1 then
			if turtle.forward() then
				POSITION.x = POSITION.x-1
				return true
			end
		elseif FACEING == 2 then
			if turtle.forward() then
				POSITION.z = POSITION.z-1
				return true
			end
		elseif FACEING == 3 then
			if turtle.forward() then
				POSITION.x = POSITION.x+1
				return true
			end
		end
	end
end,
getPosition = function()
	local erg = {POSITION.x,POSITION.y,POSITION.z}
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
		if not sock then error "NET server unavailable, broken or running newer protocol version." end
		NET.socket = sock
	end
end
function NET.send(data)
    NET.connect()
    data = textutils.serializeJSON(data)
    NET.socket.send(data)
end
function NET.receive()
    NET.connect()
    NET.messageq = textutils.unserializeJSON(NET.socket.receive())
end
function NET.close()
    if NET.socket then NET.socket.close() end
end
function print_r(array)
	for i,v in pairs(array) do
		print(i,v)
	end
end


NET.send("connection established")
while true do
    repeat
    event, url, message = os.pullEvent("websocket_message")
    until url == myURL
    local msg = message
    local obj,erro = textutils.unserializeJSON(msg)
    local func,err
	local erg ={}
    if erro == nil and obj ~= nil then
        func,err = load(obj["func"])
        if func ~= nil then
            local ok = {pcall(func)}
            if ok[1] then
				print_r(ok)
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
        print(textutils.serializeJSON(erg))
        NET.send(textutils.serializeJSON(erg)) 
    end
end
NET.close()