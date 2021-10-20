-- scrollable area mit anzeige der items sortiert 
-- bestellung
-- auto sort
-- item suche
CHESTS = nil


function print_r(array)
	for i,v in pairs(array) do
		print(string.format("%s: %s",i,v))
	end
end

function inArray(needle,haystack)
	for key,value in pairs(haystack) do
		if needle == value then
			return true
		end
	end
	return false
end
function strContains(needle,haystack)
	local first,last = string.find(haystack,needle)
	if first ~= nil and last ~= nil then
		return true
	else
		return false
	end
end
function strToArray(stringToConvert)
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

function countItems()
    local items = {}
    for key, chestName in pairs(CHESTS) do
        local chest = peripheral.wrap(chestName)
        for slot, item in pairs(chest.list()) do
            if items[item.name] == nil then
                items[item.name] = 0
            end
            items[item.name] = items[item.name] + item.count
            --print(("%d x %s in slot %d"):format(item.count, item.name, slot))
        end
    end
    return items
end

function main()
    local angeschlossen = peripheral.getNames()
    local chests = {}
    local c = 0
    --local chest = peripheral.wrap("minecraft:chest_4")
    for key, value in pairs(angeschlossen) do
        --print(peripheral.getType(value))
        if peripheral.getType(value) == "minecraft:chest" then
            c = c + 1
            chests[c] = value
        end
    end
    CHESTS = chests
    local items = countItems()

    print_r(items) 
end

main()