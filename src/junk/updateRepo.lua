LINKS = {
    ["buildJob"] = "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/quarry/buildJob.lua",
    ["ccturtleMK3"] = "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/quarry/ccturtleMK3.lua",
    ["ccMessage"] = "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/junk/ccMessage.lua",
    ["ccModem"] = "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/junk/ccModem.lua"
}

for k,v in pairs(LINKS) do
    shell.run("rm "..k..".lua")
    shell.run("wget "..v)
end
