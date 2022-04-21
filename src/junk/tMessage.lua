-- GLOBAL
local devices = peripheral.getNames()
MODEM = nil
REPLY = 128
SEND = 128

require("Message")

for key, side in pairs(devices) do
    if peripheral.getType(side) == "modem" then
        MODEM = peripheral.wrap(side)
    end
end
if MODEM == nil then
    error("argument remote used but turtle has no equipped modem",1)
end

-- GLOBAL END
local function print_r(array)
	for i,v in pairs(array) do
		print(string.format("%s: %s",i,v))
	end
end
local function send(message,channel)
    MODEM.transmit(channel,REPLY,message)
end

local function getAnswer()
    local event, side, channel, replyChannel, answer, distance = os.pullEvent("modem_message")
    print_r({event, side, channel, replyChannel,distance})
    print_r(answer)
end

local function listenOn(reply)
    if not MODEM.isOpen(reply) then
        MODEM.open(reply)
    end
end

if #arg >= 1 and arg[1] == "send" then
    listenOn(REPLY)
    if arg[2] == "msg" then
        local text = tostring(arg[3])
        local channel = SEND
        if arg[4] ~= nil then
            channel = tonumber(arg[4])
        end
        local msg = message:create("text", text, {}, channel)
        send(msg,channel)
    elseif arg[2] == "file" then
        local filename = tostring(arg[3])
        local channel = SEND
        if arg[4] ~= nil then
            channel = tonumber(arg[4])
        end
        local data = {}
        local c = 0
        for line in io.lines(filename) do
            c = c + 1
            data[c] = line
        end
        local msg = message:create("file", data, { filename = filename }, channel)
        send(msg,channel)
        getAnswer()
    elseif arg[2] == "run" then
        local program = tostring(arg[3])
        local channel = SEND
        if arg[4] ~= nil then
            channel = tonumber(arg[4])
        end
        local msg = message:create("run", program, {}, channel)
        send(msg,channel)
        getAnswer()
    elseif arg[2] == "turtle" then
        if arg[3] == "here" then
            local x,y,z = gps.locate(1)
            local program = "buildJob.lua "..math.floor(x).." "..(math.floor(y)-1).." "..math.floor(z).." "..arg[4].." "..arg[5].." "..arg[6]
            local msg = message:create("run", program, {}, SEND)
            send(msg,SEND)
            getAnswer()
        elseif arg[3] == "start" then
            local program = "ccturtleVan.lua"
            local msg = message:create("run", program, {}, SEND)
            send(msg,SEND)
            getAnswer()
        end
    end
elseif #arg >= 1 and arg[1] == "listen" then
    if arg[2] ~= nil then
        REPLY = tonumber(arg[2])
    end
    listenOn(REPLY)
    print("waiting for a message on channel "..REPLY.."...")
    local event, side, channel, replyChannel, answer, distance = os.pullEvent("modem_message")
    if answer.header.type == "text" then
        print(answer.data)
        shell.run("tMessage listen")
    elseif answer.header.type == "run" then
        shell.run(answer.data)
        MODEM.closeAll()
        local msg = message:create("text", "program sucessfully run", {}, replyChannel)
        send(msg,replyChannel)
        shell.run("tMessage listen")
    elseif answer.header.type == "file" then
        local file = io.open(answer.header.info.filename,"w")
        for line, content in pairs(answer.data) do
            file:write(content,"\n")
        end
        file:close()
        local msg = message:create("text", "file transfered", {}, replyChannel)
        send(msg,replyChannel)
        MODEM.closeAll()
        shell.run("tMessage listen")
    elseif answer.type == "stop" then

    end
else
    print("please use as following:")
    print("tMessage listen")
    print("tMessage listen [channel]")
    print("tMessage send msg <text> [channel]")
    print("tMessage send file <filename> [channel]")
    print("tMessage send run <program with arguments> [channel]")
    print("tMessage send turtle here <height> <depth> <width>")
    print("tMessage send turtle start")
end
MODEM.closeAll()
