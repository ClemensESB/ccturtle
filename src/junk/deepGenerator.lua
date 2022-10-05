local function main(side)
    local genType,storageType = peripheral.getType(side)
    local generator = nil
    if genType == "deepresonance:generator_part" then
        generator = peripheral.wrap(side)
        local capacity = generator.getEnergyCapacity()
        local safetyPercentage = 0.25
        while true do
            local energy = generator.getEnergy()
            if (capacity * safetyPercentage) > energy  then
               redstone.setOutput(side,true)
            elseif (capacity * (0.5 + safetyPercentage)) < energy then
                redstone.setOutput(side,false)
            end
            sleep(0)
        end
    end
end


if #arg == 1 then
    main(arg[1])
else 
    
end