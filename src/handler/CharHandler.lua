local Handler = require("handler.Handler")

local CharHandler = class("CharHandler", Handler)

local RESPONSE = {}
local REQUEST = {}
local charHdl = nil
local user = nil

function CharHandler:ctor( _user )
    table.merge(self.response, RESPONSE)
    table.merge(self.request, REQUEST)
    charHdl = self
    user = _user
end


function RESPONSE:character_create( args )
    print("--- RESPONSE:character_create, success")
    dump(args.character)
end

function RESPONSE:character_list( args )
    assert(table.nums(args.character) > 0, "Notice: character_list is empty")

    for k, v in pairs (args.character) do
        user.charTab[k] = v
    end
    dump(user.charTab)

    eventMgr.trigEvent(eventList.ListChar, args.character)
end

function RESPONSE:character_pick (args)
    assert(args.character, "Error: not found character")
    user.aoiHdl:setCharData(args.character)

    eventMgr.trigEvent(eventList.SelChar, args.character)
    rpcMgr.send_request("map_ready", {})
end

--------------------- request from server
function REQUEST:tips( args )
    print("--- tips:"..args.content)
    eventMgr.trigEvent(eventList.Tips, args.content)
end


return CharHandler