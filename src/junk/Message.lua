message = {}
message.__index = message
function message:create(typ, data, addInfo,target)
    local msg = {}
    setmetatable(msg, message)
    msg.header = {
        type = typ,
        info = addInfo,
        targetChannel = target
    }
    msg.data = data
    return msg
end

return {message = message}
