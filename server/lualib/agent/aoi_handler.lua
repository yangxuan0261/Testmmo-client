local skynet = require "skynet"
local sharemap = require "sharemap"

local syslog = require "syslog"
local handler = require "agent.handler"
local dump = require "print_r"


local RESPONSE = {}
local CMD = {}
handler = handler.new (nil, RESPONSE, CMD)

local subscribe_character
local subscribe_agent
local user
local character_writer
local self_id
local self_flag
local scope2proto = {
	["move"] = "aoi_update_move",
	["attribute"] = "aoi_update_attribute",
}

handler:init (function (u)
	user = u
	character_writer = nil
	subscribe_character = {}
	subscribe_agent = {}

	self_id = user.character.id
	self_flag = {}
	for k, _ in pairs (scope2proto) do
		self_flag[k] = { dirty = false, wantmore = true }
	end
end)

local function send_self (scope) -- 请求客户端信息
	local flag = self_flag[scope]
	if flag.dirty and flag.wantmore then
		flag.dirty = false
		flag.wantmore = false
		user.send_request (scope2proto[scope], { character = user.character })
	end
end

local function agent2id (agent)
	local t = subscribe_agent[agent]
	if not t then return end
	return t.character.id
end

local function mark_flag (character, scope, field, value) -- 标记角色属性值
	local t = subscribe_character[character]
	if not t then return end

	t = t.flag[scope]
	if not t then return end

	if value == nil then value = true end
	t[field] = value
end

local function create_reader ()
	syslog.debug ("aoi_handler create_reader")
	if not character_writer then
		character_writer = sharemap.writer ("character", user.character)
	end
	return character_writer:copy ()
end

local function subscribe (agent, reader)
	syslog.debugf ("aoi_handler aoi_subscribe agent(%d) reader(%s)", agent, reader)
	local c = sharemap.reader ("character", reader) -- 读出数据流里对应的数据

	local flag = {}
	for k, _ in pairs (scope2proto) do
		flag[k] = { dirty = false, wantmore = false }
	end

	local t = {
		character = c,
		agent = agent,
		flag = flag,
	}
	subscribe_character[c.id] = t
	subscribe_agent[agent] = t -- 添加进视野的目标 丢进 订阅者列表

	user.send_request ("aoi_add", { character = c })
end

local function refresh_aoi (id, scope) -- 刷新对应id的角色属性
	syslog.debugf ("--- refresh_aoi, agent:%d chId:%d, scope:%s", skynet.self(), id, scope)

	local t = subscribe_character[id]
	if not t then return end
	local c = t.character

	t = t.flag[scope]
	if not t then return end

	syslog.debugf ("--- dirty(%s) wantmore(%s)", t.dirty, t.wantmore)

	if t.dirty and t.wantmore then
		c:update ()

		user.send_request (scope2proto[scope], { character = c })
		t.wantmore = false
		t.dirty = false
	end
end

local function aoi_update_response (id, scope)
	if id == self_id then
		self_flag[scope].wantmore = true
		send_self (scope)
		return
	end

    print("~~~ debug, "..debug.traceback())
	mark_flag (id, scope, "wantmore", true)
	refresh_aoi (id, scope)
end

local function aoi_add (list)
	if not list then return end

	local self = skynet.self ()
	for _, target in pairs (list) do
		skynet.fork (function ()
            syslog.debugf ("--- aoi_add, self:%d, target:%d", self, target)

            -- 返回 target 的 aoi_subscribe 中返回的reader
			local reader = skynet.call (target, "lua", "aoi_subscribe", self, create_reader ())
			subscribe (target, reader) -- 订阅 添加进视野的角色

            -- 其实就是为了获取到对方的reader，读出对方的角色数据，下行给自己的客户端
		end)
	end
end

local function aoi_update (list, scope)
	if not list then return end

	self_flag[scope].dirty = true
	send_self (scope) -- 下行给自己的客户端

	local self = skynet.self ()
	for _, target in pairs (list) do -- 下行给target的客户端
		skynet.fork (function ()
			skynet.call (target, "lua", "aoi_send", self, scope)
		end)
	end
end

local function aoi_remove (list)
	if not list then return end

	local self = skynet.self ()
	for _, agent in pairs (list) do
		skynet.fork (function ()
			local t = subscribe_agent[agent] -- 移除自己的订阅者
			if t then
				local id = t.character.id
				subscribe_agent[agent] = nil
				subscribe_character[id] = nil

				user.send_request ("aoi_remove", { character = id }) --下行移除视野外的角色

				skynet.call (agent, "lua", "aoi_unsubscribe", self) -- 通知订阅者 取消 订阅自己
			end
		end)
	end
end

function CMD.aoi_subscribe (agent, reader)
	syslog.debugf ("aoi_subscribe agent(%d) reader(%s)", agent, reader)
	subscribe (agent, reader)
	return create_reader ()
end

function CMD.aoi_unsubscribe (agent)
	syslog.debugf ("aoi_unsubscribe agent(%d)", agent)
	local t = subscribe_agent[agent]
	if t then
		local id = t.character.id
		subscribe_agent[agent] = nil
		subscribe_character[id] = nil
		user.send_request ("aoi_remove", { character = id }) -- 下行移除视野外的角色
	end
end

function CMD.aoi_manage (alist, rlist, ulist, scope)
	if (alist or ulist) and character_writer then
		character_writer:commit () -- 同步一次最新的数据到共享中心，坐等别人update刷新
	end

    -- debug
    if alist then
        for k,v in pairs(alist) do
            syslog.debugf ("--- aoi_manage, agent:%d add target:%d", skynet.self(), v)
        end
    end
    if rlist then
        for k,v in pairs(rlist) do
            syslog.debugf ("--- aoi_manage, agent:%d remove target:%d", skynet.self(), v)
        end
    end
    if ulist then
        for k,v in pairs(ulist) do
            syslog.debugf ("--- aoi_manage, agent:%d update target:%d", skynet.self(), v)
        end
    end

	aoi_add (alist)
	aoi_remove (rlist)
	aoi_update (ulist, scope)
end

function CMD.aoi_send (agent, scope) -- 接收到 广播源agent 发送的 属性变更消息
	local t = subscribe_agent[agent] -- 接收者的 订阅者列表，agent就在其中
	if not t then return end
	local id = t.character.id

	mark_flag (id, scope, "dirty", true) -- 将广播源的角色属性标记为dirty
	refresh_aoi (id, scope)
end

function RESPONSE.aoi_add (request, response)
	if not response or not response.wantmore then return end
    syslog.debugf ("--- RESPONSE.aoi_add, aaa")
	local id = request.character.id
    for k, _ in pairs (scope2proto) do
		mark_flag (id, k, "wantmore", true)
		refresh_aoi (id, k)
	end
end

function RESPONSE.aoi_update_move (request, response)
    syslog.debugf ("@@@ response from client, RESPONSE.aoi_update_move")
    request.myflag = "aaa"
    response.myflag = "bbb"
    -- dump(request)
    -- dump(response)
	if not response or not response.wantmore then return end
	aoi_update_response (request.character.id, "move")
end

function RESPONSE.aoi_update_attribute (request, response)
    syslog.debugf ("~~~ RESPONSE.aoi_update_attribute")
    request.myflag = "ccc"
    response.myflag = "ddd"
    -- dump(request)
    -- dump(response)
	if not response or not response.wantmore then return end
	aoi_update_response (request.character.id, "attribute")
end

function handler.find (id)
	local t = subscribe_character[id]
	if t then
		return t.agent
	end
end

function handler.boardcast (scope) -- "move", "attribute"
	if not character_writer then return end
	character_writer:commit ()

	self_flag[scope].dirty = true
	send_self (scope)

	local self = skynet.self ()
	for a, _ in pairs (subscribe_agent) do -- 通知订阅者，我这个属性变了
        syslog.debugf ("--- handler.boardcast to agent:%d, scope:%s", a, scope)
		skynet.fork (function ()
			skynet.call (a, "lua", "aoi_send", self, scope)
		end)
	end
end

return handler
