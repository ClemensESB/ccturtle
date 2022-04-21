ccModem = {}
ccModem.__index = ccModem
function ccModem:create()
    local properties = {}
    setmetatable(properties, modem)
    local devices = peripheral.getNames()
    local device = nil
    local side = nil
    for key, tempSide in pairs(devices) do
        if peripheral.getType(tempSide) == "modem" then
            device = peripheral.wrap(tempSide)
            side = tempSide
        end
    end
    properties = {
        side = side,
        modem = device,
    }
    return properties
end
function ccModem:send(channel, reply, message)
    self.properties.modem.transmit(channel,reply, message)
end

function ccModem:listenOn(channel)
    if not self.properties.modem.isOpen(channel) then
        self.properties.modem.open(channel)
    end
end
function ccModem:receive()
    local event, side, channel, replyChannel, answer, distance = os.pullEvent("modem_message")
    --print_r({ event, side, channel, replyChannel, distance })
    --print_r(answer)
    return answer
end
function ccModem:close()
    self.properties.modem.closeAll()
end

return { ccModem = ccModem }