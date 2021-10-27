-- scrollable area mit anzeige der items sortiert 
-- bestellung
-- auto sort
-- item suche
CHESTS = nil
KEYLIST = {}
ITEMLIST = {}
INDEX = 1

local function print_r(array)
	for i,v in pairs(array) do
		print(string.format("%s: %s",i,v))
	end
end



local function inArray(needle,haystack)
	for key,value in pairs(haystack) do
		if needle == value then
			return true
		end
	end
	return false
end
local function strContains(needle,haystack)
	local first,last = string.find(haystack:upper(),needle:upper())
	if first ~= nil and last ~= nil then
		return true
	else
		return false
	end
end
local function strToArray(stringToConvert)
	local erg = {}
	local i = 1
	if stringToConvert ~= nil then
		for param in stringToConvert:gmatch('[^,%s]+') do
			erg[i] = param
			i = i + 1
		end
	end
	return erg
end

local function toKeyList(itemId,itemName)
    if KEYLIST[itemId] == nil then
        KEYLIST[itemId] = INDEX
        INDEX = INDEX + 1
    end
    if ITEMLIST[KEYLIST[itemId]] == nil then
        local temp = {
            id = itemId,
            name = itemName,
            count = 0,
            details = {}
        }
        ITEMLIST[KEYLIST[itemId]] = temp
    end
end

local function getItemById(itemId)
    return ITEMLIST[KEYLIST[itemId]]
end

local function addToItemListByKey(itemId,itemDetail)
    ITEMLIST[KEYLIST[itemId]].count = ITEMLIST[KEYLIST[itemId]].count + itemDetail.count
    table.insert(ITEMLIST[KEYLIST[itemId]].details,itemDetail)
end

local function printItems(itemIndex,itemList)
    term.clear()
    if itemIndex < 0 then
        itemIndex = 0
    end
    for i = 1,19 do
        term.setCursorPos(1,i)
        local pos = i + itemIndex
        if pos > #(itemList) then
            break
        end
        local temp = itemList[pos]
        term.write(string.format("%s: %s",temp.name,temp.count))
    end
end

local function mapItems()
    for key, chestName in pairs(CHESTS) do
        local chest = peripheral.wrap(chestName)
        for slot, item in pairs(chest.list()) do
            local id = item.name
            local detail = {
                chest = chest,
                slot = slot,
                count = item.count
            }
            toKeyList(id,chest.getItemDetail(slot).displayName)
            addToItemListByKey(id,detail)
            --addToList(items,name,item.count)
        end
    end
end

local function browse()
    local itemIndex = 0
    while true do
        local event, dir, x, y = os.pullEvent("mouse_scroll")
        if (itemIndex + 18 < #(ITEMLIST) and dir == 1) or (itemIndex > 0 and dir == -1) then
            --print(itemIndex)
            term.scroll(dir)
            itemIndex = itemIndex + dir
        end
        printItems(itemIndex,ITEMLIST)
    end
end

local function searchWindow()
    term.clear()
    term.setCursorPos(1,1)
    print("searching...")
    term.setCursorPos(1,2)
    local input = io.read()
    local temp = {}
    local found = false
    for key, value in pairs(ITEMLIST) do
        if strContains(input,value.name) then
            table.insert(temp,value)
            found = true
        end
    end
    term.clear()
    term.setCursorPos(1,1)
    local i = 1
    if found then
        for key, value in pairs(temp) do
            term.setCursorPos(1,i)
            term.write(string.format("%s: %s",value.name,value.count))
            i = i + 1
        end
    end
end

local function itemSort(itemId)
    local item = getItemById(itemId) -- die Itemgruppe um die es geht
    local itemSum = item.count -- alle Items zusammengezählt
    local stackLimit = item.details[1].chest.getItemLimit(item.details[1].slot) -- wievile items passen in einen slot
    local stacks = math.ceil(item.count / stackLimit) -- wieviele stacks darf es maximal geben
    local c = #(item.details) -- die menge der angefangenen stacks
    local processedItems = 0 -- wieviele items bearbeitet wurden
    local itemsLeft = itemSum - processedItems -- wieviele items noch geshuffelt werden müssen
    if #(item.details) > stacks then
        for i,itemDetail in pairs(item.details) do
            processedItems = processedItems + itemDetail.count -- wieviele items bearbeitet wurden
            itemsLeft = itemSum - processedItems -- wieviele items noch geshuffelt werden müssen
            local missingItems = stackLimit - itemDetail.count -- wieviele items im stack fehlen
            local expectedSize = 0 -- die erwartete stackgröße
            if itemsLeft > missingItems then
                expectedSize = stackLimit
            else
                expectedSize = itemDetail.count + itemsLeft
            end

            while expectedSize > itemDetail.count do -- soloange die erwartete größe nicht erreicht wurde
                print(string.format("%s %s",itemId,expectedSize))
                local pushed = itemDetail.chest.pullItems(peripheral.getName(item.details[c].chest),item.details[c].slot,stackLimit,itemDetail.slot) -- hohle möglichst viele items aus dem letzten stack
                itemDetail.count = itemDetail.count + pushed
                item.details[c].count = item.details[c].count - pushed
                processedItems = processedItems + pushed
                itemsLeft = itemSum - processedItems
                if item.details[c].count <= 0 then
                    table.remove(item.details,c)
                    c = c - 1
                end
            end
        end
    end
    --print(string.format("%s %s","stacks: ",stacks))
end

local function inventorySort()
    term.clear()
    term.setCursorPos(1,1)
    print("sorting Inventory please wait...")
    for i=1,#(ITEMLIST) do
        itemSort(ITEMLIST[i].id)
    end
    term.clear()
    term.setCursorPos(1,1)
    print("inventory sorted")
end

local function wait_for_key()
    local key = nil
    repeat
        local _ = nil
        _, key = os.pullEvent("key")
    until key == keys.s or key == keys.a

    if key == keys.s then
        searchWindow()
    elseif key == keys.a then
        inventorySort()
    end
end

local function idle()
    parallel.waitForAll(browse,wait_for_key)
end

function main()
    local angeschlossen = peripheral.getNames()
    local chests = {}
    local c = 0
    for key, value in pairs(angeschlossen) do
        if peripheral.getType(value) == "minecraft:chest" then
            c = c + 1
            chests[c] = value
        end
    end
    CHESTS = chests
    term.clear()
    term.setCursorPos(1,1)
    term.write(string.format("%s %i %s","found",c,"chests"))
    term.setCursorPos(1,2)
    term.write(string.format("%s","beginning to map items..."))
    mapItems()

    table.sort(ITEMLIST, function(a, b) return a.name:upper() < b.name:upper() end)
    for key, value in pairs(ITEMLIST) do
        KEYLIST[value.id] = key
    end
    printItems(0,ITEMLIST)
    -- print_r(ITEMLIST[1].details[1])
    -- print_r(ITEMLIST[1].details[2])

    --itemSort(ITEMLIST[1].name)
    idle()
end

main()