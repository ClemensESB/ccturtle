CCMessage = {
    header = {
        type = "typ",
        info = "info",
        targetChannel = 1,
        sender = ""
    },
    data = nil
}
function CCMessage:create(o, typ, data, addInfo, target, sender)
    o = o or {}
    setmetatable(o,self)
    self.header.type = typ
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
