LINKS = {
    "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/quarry/buildJob.lua",
    "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/quarry/ccturtleMK3.lua",
    "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/junk/ccMessage.lua",
    "https://raw.githubusercontent.com/ClemensESB/ccturtle/main/src/junk/ccModem.lua"
}

for k,v in pairs(LINKS) do
    shell.run("wget "..v)
end
