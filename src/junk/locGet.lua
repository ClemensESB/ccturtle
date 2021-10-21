local function main(directory,fileName)
shell.execute("rm",fileName..".lua")
shell.execute("wget","http://localhost/turtle/ccturtle/src/"..directory.."/"..fileName..".lua",fileName..".lua")
end

if #arg == 1 then
    local filename = tostring(arg[1])
    main("quarry",filename)
elseif #arg == 2 then
    local directory = tostring(arg[1])
    local filename = tostring(arg[2])
    main(directory,filename)
end