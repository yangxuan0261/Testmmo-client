local Handler = require("handler.Handler")

local AoiHandler = class("AoiHandler", Handler)

local RESPONSE = {}
local REQUEST = {}
local aoiHdl = nil
local user = nil

function AoiHandler:ctor( _user )
    table.merge(self.response, RESPONSE)
    table.merge(self.request, REQUEST)

    self.charTab = {}
    aoiHdl = self
    user = _user
end

-------- server response
function RESPONSE:move (args)
    assert(args.pos)
    local id = user:getSelCharId()
    local pos = args.pos
    eventMgr.trigEvent(eventList.ActorMove, id, pos.x, pos.y)

    dump(pos, "selfChar move")
end

-------- server request
function REQUEST:aoi_add (args)
    local character = args.character
    assert(character, "Error: character is nil")
    dump(character,"REQUEST:aoi_add")

    local id = character.id
    if aoiHdl.charTab[id] then
        assert(false, "Error: is exist before, id:"..character.id)
    end
    aoiHdl:setCharData(character) -- insert char pool
    local pos = character.movement.pos
    eventMgr.trigEvent(eventList.CreateChar, id, pos.x, pos.y)
    return nil
end

function REQUEST:aoi_remove (args)
    local id = args.character
    print("--- REQUEST:aoi_remove, id:"..id)
    assert(aoiHdl.charTab[id], "Error: not found character")
    aoiHdl:removeCharData(id)

    eventMgr.trigEvent(eventList.RemoveChar, id)
    return nil
end

function REQUEST:aoi_update_move (args)
    print("--- REQUEST:aoi_update_move")
    local selCharId = user:getSelCharId()
    local id = args.character.id
    if selCharId == id then
        return
    end

    local character = aoiHdl.charTab[id]
    assert(character, "Error: not found character, id:"..id)

    local pos = character.movement.pos
    eventMgr.trigEvent(eventList.ActorMove, id, pos.x, pos.y)

    dump(pos, "otherChar move")
 -- - "<var>" = {
 -- -     "o" = 180
 -- -     "x" = 322
 -- -     "y" = 292
 -- -     "z" = 100
 -- - }

    return nil
end

function REQUEST:aoi_update_attribute (args)

    return nil
end

function AoiHandler:getCharData(_id)
    local charData = self.charTab[_id]
    assert(charData, "Error: not found character, id:".._id)
    return charData
end

function AoiHandler:setCharData(_charData)
    self.charTab[_charData.id] = _charData
end

function AoiHandler:removeCharData( _id )
    assert(self.charTab[_id], "Error: not found character")
    self.charTab[_id] = nil
end


return AoiHandler