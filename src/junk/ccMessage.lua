CCMessage = {
    header = {
        type = "typ",
        info = "info",
        targetChannel = 1,
        sender = ""
    },
    data = nil
}
function CCMessage:create(type, data, addInfo, target, sender,o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    self.header.type = type
    self.header.info = addInfo
    self.header.targetChannel = target
    self.sender = sender
    self.data = data
    return o
end
function CCMessage:toJson()
    return textutils.serialiseJSON(self)
end
return { CCMessage = CCMessage }
