local Handler = require("handler.Handler")

local TestAoiHandler = class("TestAoiHandler", TestAoiHandler)

local testAoiHdl = nil
local user = nil

function TestAoiHandler:ctor( _user )
    testAoiHdl = self
    user = _user
    self:initActors()
end

function TestAoiHandler:initActors( )
    local char1 = {
        id = 1,
        general = { name = "actor11" },
        movement = {
            pos = { x = 100, y = 100 }
        },
    }

    local char2 = {
        id = 2,
        general = { name = "actor22" },
        movement = {
            pos = { x = 120, y = 120 }
        },
    }
end

return TestAoiHandler