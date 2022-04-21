local devices = peripheral.getNames()
MODEM = nil
CHANNEL = 100
require("Message")

for key, side in pairs(devices) do
    if peripheral.getType(side) == "modem" then
        MODEM = peripheral.wrap(side)
    end
end
if MODEM == nil then
    error("argument remote used but turtle has no equipped modem", 1)
end

local function listenOn(reply)
    if not MODEM.isOpen(reply) then
        MODEM.open(reply)
    end
end

local function send(message, channel, reply)
    MODEM.transmit(channel, reply, message)
end

while true do
    listenOn(CHANNEL)
    local event, side, channel, replyChannel, sMessage, distance = os.pullEvent("modem_message")
    send(sMessage, sMessage.header.targetChannel, replyChannel)
end
MODEM.closeAll()