local table_remove = table.remove
local table_insert = table.insert
local table_sort = table.sort

local EventMgr = class("EventMgr")
local EventTab = {}
local DefaultPriority = 0

function EventMgr:ctor( ... )

end

function EventMgr.regEvent( _key, _func, _priority, ... )
    assert(type(_func) == "function", "Error: not func type:"..type(_func))
    local eventFuncs = EventTab[_key]
    if eventFuncs == nil then
        EventTab[_key] = {}
        eventFuncs = EventTab[_key]
    end

    local priority = _priority or DefaultPriority
    local eventFunc = { _func, priority, {...} }
    table_insert(eventFuncs, eventFunc)

    table_sort(eventFuncs, function(t1, t2)
        return t1[2] > t2[2]
    end)
end

function EventMgr.unregEvent( _key, _func)
    assert(type(_func) == "function", "Error: not func type")
    local eventFuncs = EventTab[_key]
    if eventFuncs == nil then
        return
    end

    for k, v in ipairs(eventFuncs) do
        if v[1] == _func then
            table_remove(eventFuncs, k)
            return
        end
    end

end

function EventMgr.trigEvent( _key, ... )
    local eventFuncs = EventTab[_key]
    if eventFuncs == nil or #eventFuncs == 0 then
        return
    end

    for k,v in pairs(eventFuncs) do
        v[1](...)
    end
end

return EventMgr