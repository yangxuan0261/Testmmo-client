local LoginLayer = require("app.views.Login")
local GSBase = require("state.GSBase")
local GSLogin = class("GSLogin", GSBase)


function GSLogin:ctor()
    GSLogin.super.ctor(self)
    self:setState(GSBase.EnumGSLogin)
    self.loginLy = nil
end

function GSLogin:onEnterState( ... )
    local size = cc.Director:getInstance():getVisibleSize()
    self.loginLy = LoginLayer.new()
    mainScene:addChild(self.loginLy)
end

function GSLogin:onExitState( ... )
    print("--- GSLogin:onExitState")
    self.loginLy:removeFromParent(true)
end

function GSLogin:onTick( _dt )
    GSLogin.super.onTick(self, _dt)

    -- if self.counter > 3 then
    --     gameStateMgr:changeState(GSBase.EnumGSLoading)
    -- end
end

return GSLogin