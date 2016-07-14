local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local EventList = require("eventList")
eventList = EventList.new()

local EventMgr = require("eventMgr")
eventMgr = EventMgr.new()

local RpcMgr = require("rpcMgr") 
rpcMgr = RpcMgr.new() -- step: 1st

local User = require("userMgr")
user = User.new() -- step: 2nd

local GSBase = require("state.GSBase")
local GSMgr = require("state.GSMgr")
gameStateMgr = nil

local LoginLayer = require("app.views.Login")
local MainCity = require("app.views.MainCity")

------------ reg all RESPONSE begin -------
user:regHandler(rpcMgr.request, rpcMgr.response)
------------ reg all RESPONSE end -------

mainScene = nil
function MainScene:onCreate()
    mainScene = self
    self:regEvent()
    gameStateMgr = GSMgr.new()

    -- local size = cc.Director:getInstance():getVisibleSize()
    -- self.loginLy = LoginLayer.new()
    -- self:addChild(self.loginLy)
end

function MainScene:regEvent()
    eventMgr.regEvent(eventList.ExitGame, handler(self, self.exitGame))
    eventMgr.regEvent(eventList.LoginSuccess, handler(self, self.onLoginSuccess))
end

function MainScene:onLoginSuccess()
    -- 切到主城状态
    gameStateMgr:changeState(GSBase.EnumGSMainCity)
    -- gameStateMgr:changeState(GSBase.EnumGSLoading) -- test
end

function MainScene:exitGame( ... )
    cc.Director:getInstance():endToLua()
end

return MainScene
