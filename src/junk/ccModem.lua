-- Class Declaration
CCModem = { 
    side = '',
    modem = nil
}
function CCModem:create(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    local devices = peripheral.getNames()
    local device = nil
    local side = nil
    for key, tempSide in pairs(devices) do
        if peripheral.getType(tempSide) == "modem" then
            device = peripheral.wrap(tempSide)
            side = tempSide
        end
    end
    self.side = side
    self.modem = device
    return o
end
function CCModem:send(channel, reply, message)
    self.properties.modem.transmit(channel,reply, message)
end

function CCModem:listenOn(channel)
    if not self.modem.isOpen(channel) then
        self.modem.open(channel)
    end
end
function CCModem:receive()
    local event, side, channel, replyChannel, answer, distance = os.pullEvent("modem_message")
    --print_r({ event, side, channel, replyChannel, distance })
    --print_r(answer)
    return answer
end
function CCModem:close()
    self.modem.closeAll()
end

return { CCModem = CCModem }
