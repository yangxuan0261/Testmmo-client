local LoadingLayer = require("app.views.Loading")
local GSBase = require("state.GSBase")
local GSLoading = class("GSLoading", GSBase)

function GSLoading:ctor()
    GSLoading.super.ctor(self)
    self:setState(GSBase.EnumGSLoading)
end

function GSLoading:onEnterState( ... )
    self.loadly = LoadingLayer.new()
    mainScene:addChild(self.loadly)
end

function GSLoading:onExitState( ... )
    self.loadly:removeFromParent(true)
end

function GSLoading:onTick( _dt )
    GSLoading.super.onTick(self, _dt)

    self.counter = self.counter + 0.5
    if self.counter > 100 then
        gameStateMgr:changeState(GSBase.EnumGSMainCity)
    end

    self.loadly:setPercent(self.counter)
end

return GSLoading