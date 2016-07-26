local Handler = require("handler.Handler")

local GmHandler = class("GmHandler", Handler)

local RESPONSE = {}
local REQUEST = {}
local gmHdl = nil
local user = nil

function GmHandler:ctor( _user )
    table.merge(self.response, RESPONSE)
    table.merge(self.request, REQUEST)
    gmHdl = self
    user = _user
end


function RESPONSE:gm( args )
    dump(args, "--- gm")
    -- eventMgr.trigEvent(eventList.ListChar, args.character)
end

return GmHandler