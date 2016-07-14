local GSBase = require("state.GSBase")
local GSInit = class("GSInit", GSBase)

function GSInit:ctor()
    GSInit.super.ctor(self)
    self:setState(GSBase.EnumGSInit)
end

function GSInit:onEnterState( ... )
    print("--- GSInit:onEnterState")
end

function GSInit:onExitState( ... )
    print("--- GSInit:onExitState")
end

function GSInit:onTick( _dt )
    GSInit.super.onTick(self, _dt)

    self.counter = self.counter + _dt
    if self.counter > 0 then
        gameStateMgr:changeState(GSBase.EnumGSLogin)
        -- gameStateMgr:changeState(GSBase.EnumGSLoading)
    end
end

return GSInit