require("ccModem")
require("ccMessage")

local modem = ccModem:create()

modem:listenOn(128)
while true do
    local turtleInformation = modem:receive()
    shell.run("clear")
    local function print_r(array)
        for i, v in pairs(array) do
            print(string.format("%s: %s", i, v))
        end
    end
end
