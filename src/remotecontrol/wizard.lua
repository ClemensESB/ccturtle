local datei1 = fs.exists("/remote/client.lua")
local datei2 = fs.exists("/startup/wizard.lua")
if not datei1 then
    shell.run("pastebin get q4FgYetf /remote/client.lua")
end
if not datei2 then
    shell.run("cp /disk/startup/wizard.lua /startup/wizard.lua")
end
local bg = shell.resolveProgram("bg")
if bg ~= nil then
    shell.run("bg /remote/client.lua")
else
    shell.run("/remote/client.lua")
end
