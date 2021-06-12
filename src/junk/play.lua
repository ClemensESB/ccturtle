local drives = {peripheral.find("drive")}
for _,drive in pairs(drives) do
    if drive.hasAudio() then
        drive.playAudio()
    end
end
