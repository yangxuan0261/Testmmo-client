local MainCity = require("app.views.MainCity")
local ChatPanel = require("app.views.ChatPanel")
local GSBase = require("state.GSBase")
local GSMainCity = class("GSMainCity", GSBase)

function GSMainCity:ctor()
    GSMainCity.super.ctor(self)
    self:setState(GSBase.EnumGSMainCity)
    self.mainCityLy = nil
end

function GSMainCity:onEnterState( ... )
    rpcMgr.connGameServer()

    self.mainCityLy = MainCity.new()
    self.mainCityLy = ChatPanel.new(mainScene)
    -- mainScene:addChild(self.mainCityLy)
end

function GSMainCity:onExitState( ... )
    self.mainCityLy:removeFromParent(true)
end

function GSMainCity:onTick( _dt )
    GSMainCity.super.onTick(self, _dt)

    -- if self.counter > 3 then
    --     gameStateMgr:changeState(GSBase.EnumGSBattle)
    -- end
end

return GSMainCity