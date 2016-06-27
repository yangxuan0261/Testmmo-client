local skynet = require "skynet"
local queue = require "skynet.queue"
local sharemap = require "sharemap"
local socket = require "socket"

local syslog = require "syslog"
local protoloader = require "protoloader"
local character_handler = require "agent.character_handler"
local map_handler = require "agent.map_handler"
local aoi_handler = require "agent.aoi_handler"
local move_handler = require "agent.move_handler"
local combat_handler = require "agent.combat_handler"


local gamed = tonumber (...)
local database

local host, proto_request = protoloader.load (protoloader.GAME)

--[[
.user {
	fd : integer
	account : integer

	character : character
	world : integer
	map : integer
}
]]

local user

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end

local user_fd
local session = {}
local session_id = 0
local function send_request (name, args)
	session_id = session_id + 1
	local str = proto_request (name, args, session_id)
	send_msg (user_fd, str)
	session[session_id] = { name = name, args = args } -- 保存会话数据，客户端返回时重这里取出来对比
end

local function kick_self ()
	skynet.call (gamed, "lua", "kick", skynet.self (), user_fd)
end

local last_heartbeat_time
local HEARTBEAT_TIME_MAX = 0 -- 3 * 100 -- 3秒钟未收到消息，则判断为客户端失联
local function heartbeat_check ()
	if HEARTBEAT_TIME_MAX <= 0 or not user_fd then return end

	local t = last_heartbeat_time + HEARTBEAT_TIME_MAX - skynet.now ()
	if t <= 0 then
        syslog.debugf ("--- heatbeat:%s, last:%s, now:%s", HEARTBEAT_TIME_MAX, last_heartbeat_time, skynet.now() )

		syslog.warning ("--- heatbeat check failed, exe kick_self()")
		kick_self ()
	else
		skynet.timeout (t, heartbeat_check)
	end
end

local traceback = debug.traceback
local REQUEST -- 在各个handler中各种定义处理，模块化，但必须确保函数不重名，所以一般 模块名_函数名
local function handle_request (name, args, response)
	local f = REQUEST[name]
	if f then
        syslog.debugf ("^^^@ request from client, exe func:%s", name)
		local ok, ret = xpcall (f, traceback, args)
		if not ok then
			syslog.warningf ("handle message(%s) failed : %s", name, ret) 
			kick_self ()
		else
			last_heartbeat_time = skynet.now () -- 每次收到客户端端请求，重新计时心跳时间
			if response and ret then -- 如果该请求要求返回，则返回结果
				send_msg (user_fd, response (ret))
			end
		end
	else
		syslog.warningf ("----- unhandled message : %s", name)
		kick_self ()
	end
end

local RESPONSE
local function handle_response (id, args)
	local s = session[id] -- 检查是否存在此次会话
	if not s then
		syslog.warningf ("session %d not found", id)
		kick_self ()
		return
	end

	local f = RESPONSE[s.name] -- 检查是否存在user.send_request("aaa", xxx)中对应的响应方法 RESPONSE.aaa
	if not f then
		syslog.warningf ("unhandled response : %s", s.name)
		kick_self () -- 不存在则踢下线，因为可能会话被篡改
		return
	end

    syslog.debug ("^^^# response from client, exe func:%s", s.name)
	local ok, ret = xpcall (f, traceback, s.args, args) 
	if not ok then
		syslog.warningf ("handle response(%d-%s) failed : %s", id, s.name, ret) 
		kick_self ()
	end
end

skynet.register_protocol { -- 注册与客户端交互的协议
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch (msg, sz) -- 客户端使用的sproto，所以这里用sproto解码
	end,
	dispatch = function (source, session, type, ...)
		if type == "REQUEST" then
			handle_request (...) -- 处理客户端的请求
		elseif type == "RESPONSE" then
			handle_response (...) -- 处理请求客户端后的响应（客户端返回）
		else
			syslog.warningf ("invalid message type : %s", type) 
			kick_self ()
		end
	end,
}

local CMD = {}

function CMD.open (fd, account)
	local name = string.format ("agent:%d", account)
	syslog.debug ("-------- agent opened:"..account)

	user = { 
		fd = fd, 
		account = account,
		REQUEST = {},
		RESPONSE = {},
		CMD = CMD,
		send_request = send_request,
	}
	user_fd = user.fd
	REQUEST = user.REQUEST
	RESPONSE = user.RESPONSE
	
    character_handler:register (user)

	last_heartbeat_time = skynet.now () -- 开启心跳
	heartbeat_check ()
end

function CMD.close ()
	syslog.debugf ("agent closed")
	
	local account
	if user then
		account = user.account

		if user.map then -- 先离开 地图
			skynet.call (user.map, "lua", "character_leave")
			user.map = nil
			map_handler:unregister (user)
			aoi_handler:unregister (user)
			move_handler:unregister (user)
			combat_handler:unregister (user)
		end

		if user.world then -- 后离开 世界
			skynet.call (user.world, "lua", "character_leave", user.character.id)
			user.world = nil
		end

		character_handler.save (user.character) -- 保存角色数据

		user = nil
		user_fd = nil
		REQUEST = nil
	end
    -- 通知服务器关掉这个agent的socket
	skynet.call (gamed, "lua", "close", skynet.self (), account) 
end

function CMD.kick ()
	error ()
	syslog.debug ("agent kicked")
	skynet.call (gamed, "lua", "kick", skynet.self (), user_fd)
end

function CMD.world_enter (world)
	local name = string.format ("agent:%d:%s", user.character.id, user.character.general.name)
    syslog.notice (string.format ("--- agent, world_enter, name:%s", name))


	character_handler.init (user.character)

	user.world = world
	character_handler:unregister (user)
    syslog.notice (string.format ("--- agent, world_enter, character_handler:unregister"))

	return user.character.general.map, user.character.movement.pos
end

function CMD.map_enter (map)
    syslog.notice (string.format ("--- agent, map_enter"))

	user.map = map

	map_handler:register (user)
	aoi_handler:register (user)
	move_handler:register (user)
	combat_handler:register (user)
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f then
			syslog.warningf ("unhandled message(%s)", command) 
			return skynet.ret ()
		end

		local ok, ret = xpcall (f, traceback, ...)
		if not ok then
			syslog.warningf ("handle message(%s) failed : %s", command, ret) 
			kick_self ()
			return skynet.ret ()
		end
		skynet.retpack (ret)
	end)
end)

