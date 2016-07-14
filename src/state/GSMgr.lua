local GSBase = require("state.GSBase")
local GSInit = require("state.GSInit")
local GSLogin = require("state.GSLogin")
local GSLoading = require("state.GSLoading")
local GSMainCity = require("state.GSMainCity")
local GSBattle = require("state.GSBattle")
local Scheduler = cc.Director:getInstance():getScheduler()

local GSMgr = class("GSMgr")

function GSMgr:ctor()
    self.gsTab = {}
    self.currState = nil

    table.insert(self.gsTab, GSInit.new())
    table.insert(self.gsTab, GSLogin.new())
    table.insert(self.gsTab, GSLoading.new())
    table.insert(self.gsTab, GSMainCity.new())
    table.insert(self.gsTab, GSBattle.new())

    self.schedulerEntry = Scheduler:scheduleScriptFunc(handler(self, self.tick), 1.0 / 60, false)

    self:changeState(GSBase.EnumGSInit)
end

function GSMgr:tick( _dt )
    if self.currState then
        self.currState:onTick(_dt)
    end
end


function GSMgr:getState( _state )
    for _,v in pairs(self.gsTab) do
        if _state == v:getState() then
            return v
        end
    end
    assert(false, "Error: no state found:".._state)
end

function GSMgr:changeState( _state )
    local nextState = self:getState(_state)
    local currState = self.currState
    if currState == nextState then
        return
    end

    if currState ~= nil then
        currState:onExitState()
    end
    nextState:onEnterState()
    self.currState = nextState
end

return GSMgr