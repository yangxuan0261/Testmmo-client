local Handler = require("handler.Handler")
local cjson = require("cjson")

local ChatHandler = class("ChatHandler", Handler)

local RESPONSE = {}
local REQUEST = {}
local chatHdl = nil
local user = nil

function ChatHandler:ctor( _user )
    table.merge(self.response, RESPONSE)
    table.merge(self.request, REQUEST)
    chatHdl = self
    user = _user
end

function RESPONSE:helloFunc( args ) -- for test
end

return ChatHandler