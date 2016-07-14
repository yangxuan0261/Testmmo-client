local GSBase = require("state.GSBase")
local GSBattle = class("GSBattle", GSBase)

function GSBattle:ctor()
    GSBattle.super.ctor(self)
    self:setState(GSBase.EnumGSBattle)
end

function GSBattle:onEnterState( ... )
    print("--- GSBattle:onEnterState")
end

function GSBattle:onExitState( ... )
    print("--- GSBattle:onExitState")
end

return GSBattle