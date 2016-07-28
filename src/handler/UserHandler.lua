local Handler = require("handler.Handler")
local cjson = require("cjson")

local UserHandler = class("UserHandler", Handler)

local RESPONSE = {}
local REQUEST = {}
local userHdl = nil
local user = nil

function UserHandler:ctor( _user )
    table.merge(self.response, RESPONSE)
    table.merge(self.request, REQUEST)
    userHdl = self
    user = _user
end

--------------------- request from server
function REQUEST:user_info( args )
    local info = cjson.decode(args.data)
    dump(info, "--- user_info")
    user.info  = info
    -- eventMgr.trigEvent(eventList.Tips, args.content)
end

return UserHandler