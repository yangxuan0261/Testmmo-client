local GSBase = class("GSBase")

GSBase.EnumGSInit = "EnumGSInit"
GSBase.EnumGSLogin = "EnumGSLogin"
GSBase.EnumGSLoading = "EnumGSLoading"
GSBase.EnumGSMainCity = "EnumGSMainCity"
GSBase.EnumGSBattle = "EnumGSBattle"

function GSBase:ctor(_flag)
    self.state = nil
    self.counter = 0
end

function GSBase:setState( _state )
    self.state = _state
end

function GSBase:getState( ... )
    return self.state
end

function GSBase:onEnterState( ... )
    assert(false, "Error: GSBase:onEnterState")
end

function GSBase:onExitState( ... )
    assert(false, "Error: GSBase:onEnterState")
end

function GSBase:onTick( _dt )

end

return GSBase