VERSION = "1.16"
FACEING = 0
POSITION = vector.new(0,0,0)
HOME = vector.new(0,0,0)
GLOB_FUNC = {
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
end
}

NET = {
    server = "ws://localhost:2256",
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

function procedure(loaded)
    local erg =  {}
    local ok,func = pcall(loaded)
        if ok then
            local temp = {loaded()}
            table.insert(erg,1,temp)
        else
            print("Execution error:", func)
        end
    return erg
end

function locally(loaded)
    if loaded["funk"] == "turn" then
        return GLOB_FUNC.turn(loaded["param"])
    elseif loaded["funk"] == "getSidePosition" then
        return GLOB_FUNC.getSidePosition(loaded["param"])
    end
end

function print_r(array)
	for i,v in pairs(array) do
		print(i,v)
	end
end

local myURL = "ws://localhost:2256"
NET.send("connection established")
while true do
    repeat
    event, url, message = os.pullEvent("websocket_message")
    until url == myURL
    local msg = message
    local obj,erro = textutils.unserializeJSON(msg)
    local func,err
    if obj ~= nil or obj["func"] ~= nil then
        func,err = load(obj["func"])
    else
        err = true
    end
    local erg = {}
    if err == nil then
        local pro = procedure(func)
        table.insert(erg,1,pro)
    else
        --print("Compilation error:",err)
    end
    if obj["shell"] ~= nil then
        table.insert(erg,2,shell.run(obj["shell"]))
    end
    if obj["local"] ~= nil then
        local temp = obj["local"]
        table.insert(erg,3,locally(temp))
    end
    
    

    if erg ~= nil then
        print(textutils.serializeJSON(erg))
        NET.send(textutils.serializeJSON(erg)) 
    end
end
NET.close()