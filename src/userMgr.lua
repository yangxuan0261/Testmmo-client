local Handler = require("handler.Handler")
local CharHandler = require("handler.CharHandler")
local AoiHandler = require("handler.AoiHandler")
local GmHandler = require("handler.GmHandler")
local UserHandler = require("handler.UserHandler")
local ChatHandler = require("handler.ChatHandler")

local User = class("User", Handler)

local RESPONSE = {}
local REQUEST = {}

function User:ctor()
    table.merge(self.response, RESPONSE)
    table.merge(self.request, REQUEST)
    self.charTab = {}
    self.selCharId = 0
    self:regEvent()

    -- register all handler
    self.charHdl = CharHandler.new(self)
    self.aoiHdl = AoiHandler.new(self)
    self.gmHdl = GmHandler.new(self)
    self.userHdl = UserHandler.new(self)
    self.chatHdl = ChatHandler.new(self)
    self.charHdl:regHandler(rpcMgr.request, rpcMgr.response)
    self.aoiHdl:regHandler(rpcMgr.request, rpcMgr.response)
    self.gmHdl:regHandler(rpcMgr.request, rpcMgr.response)
    self.userHdl:regHandler(rpcMgr.request, rpcMgr.response)
    self.chatHdl:regHandler(rpcMgr.request, rpcMgr.response)
end

function User:regEvent( ... )
    eventMgr.regEvent(eventList.SelChar, handler(self, self.selChar))

end

-------- RESPONSE begin --------
function RESPONSE:test1(args)
    print("---- RESPONSE:test1")
    dump(args)
end
-------- RESPONSE end --------


-------- REQUEST begin --------
function REQUEST:test2(args)
    print("---- REQUEST:test2:", args.cat)
    return { dog = "Tim" }
end

-------- REQUEST end --------

function User:selChar(charData)
    self:getCharData(charData.id)
    self.selCharId = charData.id
    dump(charData)
end

function User:getSelCharId()
    return self.selCharId
end

function User:getCharData(_id)
    local data = self.charTab[_id]
    assert(data, "Error: no charData, id:".._id)
    return data
end

return User
