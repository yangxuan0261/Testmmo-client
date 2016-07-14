local skynet = require "skynet"
local redis = require "redis"

local config = require "config.database" -- 数据库配置文件
local account = require "db.account"
local character = require "db.character"

local center
local group = {}
local ngroup

local function hash_str (str) -- string算hash值
	local hash = 0
	string.gsub (str, "(%w)", function (c)
		hash = hash + string.byte (c)
	end)
	return hash
end

local function hash_num (num) -- number算hash值
	local hash = num << 8
	return hash
end

-- 根据key算出一个索引值，索引redis连接池中的某个redis实例，进行存储数据
function connection_handler (key)
	local hash
	local t = type (key)
	if t == "string" then
		hash = hash_str (key)
	else
		hash = hash_num (assert (tonumber (key)))
	end

	return group[hash % ngroup + 1] -- group为redis连接池
end


local MODULE = {}
local function module_init (name, mod)
	MODULE[name] = mod
	mod.init (connection_handler) -- 
end

local traceback = debug.traceback

skynet.start (function ()
	module_init ("account", account) -- 不同模块分开处理
	module_init ("character", character)

	center = redis.connect (config.center)
	ngroup = #config.group
	for _, c in ipairs (config.group) do -- 初始化链接 ngroup 个redis实例丢进 group连接池中
		table.insert (group, redis.connect (c))
	end

	skynet.dispatch ("lua", function (_, _, mod, cmd, ...)
		local m = MODULE[mod] -- 先找对应模块 character
		if not m then
			return skynet.ret ()
		end
		local f = m[cmd] -- 再找对应模块下对应的方法 character.reserve
		if not f then
			return skynet.ret ()
		end
		
		local function ret (ok, ...)
			if not ok then
				skynet.ret ()
			else
				skynet.retpack (...) -- 返回执行结果
			end

		end
		ret (xpcall (f, traceback, ...)) -- 执行方法，并返回
	end)
end)
