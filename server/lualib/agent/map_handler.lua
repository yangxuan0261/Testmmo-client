local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"


local REQUEST = {}
local user
handler = handler.new (REQUEST)

handler:init (function (u)
	user = u
end)

function REQUEST.map_ready ()
	local ok = skynet.call (user.map, "lua", "character_ready", user.character.movement.pos) or error ()
end

function REQUEST.test1 (args)
    syslog.debug ("------ REQUEST.test1,arg1:%d, arg2:%s", args.arg1, args.arg2)
   return {ret1 = 789, ret2 = "bbbbbb"}
end

return handler
