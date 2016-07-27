local Handler = require("handler.Handler")
local cjson = require("cjson")

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
    if not args.func or not args.data then
        return
    end

    local f = gmHdl.response[args.func]
    if f then
        local argTab = cjson.decode(args.data)
        f(nil, argTab)
    end
end

function RESPONSE:helloFunc( args ) -- for test
    dump(args, "--- helloFunc")
end

return GmHandler