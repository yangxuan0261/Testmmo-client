local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"


local RESPONSE = {}
local REQUEST = {}
local user
handler = handler.new (REQUEST, RESPONSE)

handler:init (function (u)
	user = u
end)

function REQUEST.map_ready ()
	local ok = skynet.call (user.map, "lua", "character_ready", user.character.movement.pos) or error ()
end

function REQUEST.test1 (args)
    syslog.debugf ("------ REQUEST.test1,arg1:%d, arg2:%s", args.arg1, args.arg2)

    skynet.timeout (300, function()
        syslog.debugf ("------ user.send_request test2")
        user.send_request ("test2", { cat = "Betty" })
    end)

   return {ret1 = 789, ret2 = "bbbbbb"}
end

function RESPONSE:test2 (args)
    syslog.debugf ("------ RESPONSE.test2, dog:%s", args.dog)
end


return handler
