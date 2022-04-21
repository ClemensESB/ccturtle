require("ccMessage")
local CCModem = require("ccModem")
local modem = CCModem.CCModem:create()
local function print_r(array)
    for i, v in pairs(array) do
        print(string.format("%s: %s", i, v))
    end
end
modem:listenOn(128)
while true do
    local turtleInformation = modem:receive()
    shell.run("clear")
    print(turtleInformation)
end
