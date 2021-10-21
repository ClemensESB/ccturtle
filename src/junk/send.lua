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

local function main(message,channel)
    local devices = peripheral.getNames()
    local modem = nil
    for key, side in pairs(devices) do
        if peripheral.getType(side) == "modem" then
            modem = peripheral.wrap(side)
        end
    end

    if not modem.isOpen(channel) then
        modem.open(channel)
    end
    local msg = message
    modem.transmit(channel,channel,msg)
    modem.close(channel)
end

if #arg == 2 then
    local message = tostring(arg[1])
    local channel = tonumber(arg[2])
    main(message,channel)
elseif #arg == 1 and arg[1] == "turtle" then
    local channel = 187
    print("enter koordinates x,y,z\n")
    local loc = io.read()
    local koordVector = strToVector(loc)
    print("enter dimensions height,depth,width\n")
    local dimensions = io.read()
    local dimensionVector = strToVector(dimensions)

    local message = {
        koords = koordVector,
        dimensions = dimensionVector
    }
    main(message,channel)
end