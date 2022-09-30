require("ccMessage")
local CCModem = require("ccModem")
local modem = CCModem.CCModem:create()
local function isTable(t)
    return type(t) == 'table'
end
local function print_r(array)
    for i, v in pairs(array) do
        if not isTable(v) then
            print(string.format("%s: %s", i, v))
        else
            print_r(v)
        end
    end
end

local function scrollview(list,x,y,w,h)
    local itemIndex = 0
    while true do
        local event, dir, xm, ym = os.pullEvent("mouse_scroll")
        if (xm >= x or xm <= x+w) and (ym >= y or ym <= y+h) then
            if (itemIndex + 18 < #(list) and dir == 1) or (itemIndex > 0 and dir == -1) then
                --print(itemIndex)
                term.scroll(dir)
                itemIndex = itemIndex + dir
            end
            for i = 1, y+h do
                term.setCursorPos(x, i)
                local pos = i + itemIndex
                if pos > #(list) then
                    break
                end
                local temp = list[pos]
                term.write(string.format("%s: %s", temp.name, temp.count))
            end
        end
    end
end

local function convertItemList(list)
    local newList = {}
    for key, value in pairs(list) do
        local temp = {name = key,count = value}
        table.insert( newList,temp )
    end
    return newList
end

modem:listenOn(128)
while true do
    local turtleInformation = modem:receive()
    shell.run("clear")
    local ti = textutils.unserializeJSON(turtleInformation)
    print(turtleInformation)
end