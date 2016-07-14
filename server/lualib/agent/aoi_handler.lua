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

local function send_self (scope) -- 下行给客户端对应属性
	local flag = self_flag[scope]
	if flag.dirty and flag.wantmore then
		flag.dirty = false
		flag.wantmore = false
        syslog.debugf("--- send_self, scope:%s", scope)
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
	syslog.debugf ("--- agent:%d subscribe agent:%d, reader:%s:", agent, skynet.self(), reader)
	local c = sharemap.reader ("character", reader) -- 读出agent种的reader中的 角色数据

    dump(c)


	local flag = {}
	for k, _ in pairs (scope2proto) do
		flag[k] = { dirty = false, wantmore = false }
	end

	local t = {
		character = c, -- 要取最新的数据时，必须先update一下
		agent = agent,
		flag = flag,
	}
	subscribe_character[c.id] = t -- 丢进我的 character订阅者列表中
	subscribe_agent[agent] = t -- 丢进我的 agent订阅者列表中

	user.send_request ("aoi_add", { character = c }) -- 告诉我的客户端，添加了 角色c
end

local function refresh_aoi (id, scope) -- 刷新对应id的角色属性
	syslog.debugf ("--- refresh_aoi, agent:%d chId:%d, scope:%s", skynet.self(), id, scope)

	local t = subscribe_character[id]
	if not t then return end
	local c = t.character

	t = t.flag[scope]
	if not t then return end

	syslog.debugf ("--- dirty(%s) wantmore(%s)", t.dirty, t.wantmore)
    -- 如果wantmore标记也为true，则下行给客户端整个角色的信息
	if t.dirty and t.wantmore then
		c:update () -- 更新character数据

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

            -- 传入自己的reader到target中，返回 target 的 aoi_subscribe 中返回的reader
			local reader = skynet.call (target, "lua", "aoi_subscribe", self, create_reader ())
			subscribe (target, reader) -- 订阅 添加进视野的角色

            -- 其实就是为了获取到对方的reader，读出对方的角色数据，下行给自己的客户端
		end)
	end
end

local function aoi_update (list, scope) -- 更新aoi范围内的属性
	if not list then return end

    syslog.debugf("--- aoi_update, self:%d, scope:%s", skynet.self(), scope)
    dump(list)

	self_flag[scope].dirty = true -- 属性标记为脏数据
	send_self (scope) -- 下行给自己的客户端

	local self = skynet.self ()
	for _, target in pairs (list) do -- 通知aoi范围内更新 "我" 的属性
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
	if (alist or ulist) and character_writer then -- 只有添加和更新时才需要将character的数据同步出去，坐等别人update取出来用
		character_writer:commit () --
	end

    if alist then
        for _,v in pairs(alist) do
            syslog.debugf ("--- aoi_manage, add list:%d", v)
        end
    end

    if rlist then
        for _,v in pairs(rlist) do
            syslog.debugf ("--- aoi_manage, remove list:%d", v)
        end
    end

    if ulist then
        for _,v in pairs(ulist) do
            syslog.debugf ("--- aoi_manage, update list:%d", v)
        end
    end

	aoi_add (alist)
	aoi_remove (rlist)
	aoi_update (ulist, scope)
end

function CMD.aoi_send (agent, scope) -- 接收到 广播源agent 发送的 属性变更消息
	local t = subscribe_agent[agent] -- 接收者的 订阅者列表，agent就在其中
	if not t then return end
	local id = t.character.id -- 广播源agent的 角色id

	mark_flag (id, scope, "dirty", true) -- 将广播源的角色属性标记为dirty，在下一行代码中需要用到这个标记
	refresh_aoi (id, scope)
end

function RESPONSE.aoi_add (request, response) -- 如果客户端想要更多的信息(response.wantmore == true)，则下行这个角色(request.character.id)的数据
	if not response or not response.wantmore then return end
    syslog.debugf ("--- RESPONSE.aoi_add, aaa")
	local id = request.character.id
    for k, _ in pairs (scope2proto) do
		mark_flag (id, k, "wantmore", true) -- 标记wantmore为true
		refresh_aoi (id, k)
	end
end

function RESPONSE.aoi_update_move (request, response)
    syslog.debugf ("@@@ response from client, RESPONSE.aoi_update_move")
	if not response or not response.wantmore then return end
	aoi_update_response (request.character.id, "move")
end

function RESPONSE.aoi_update_attribute (request, response)
    syslog.debugf ("~~~ RESPONSE.aoi_update_attribute")
	if not response or not response.wantmore then return end
	aoi_update_response (request.character.id, "attribute")
end

function handler.find (id) -- 通过角色id找到对应的agent
	local t = subscribe_character[id]
	if t then
		return t.agent
	end
end

function handler.boardcast (scope) -- "move", "attribute"，主要中在attribute中，因为move会在aoi移动中更新，attribute用在战斗时广播
	if not character_writer then return end
	character_writer:commit ()

	self_flag[scope].dirty = true
	send_self (scope) -- 通知自己属性更新

	local self = skynet.self ()
	for a, _ in pairs (subscribe_agent) do -- 通知我的所有订阅者，我这个属性变了
        syslog.debugf ("--- handler.boardcast to agent:%d, scope:%s", a, scope)
		skynet.fork (function ()
			skynet.call (a, "lua", "aoi_send", self, scope)
		end)
	end
end

return handler
