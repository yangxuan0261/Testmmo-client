local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"
local aoi_handler = require "agent.aoi_handler"


local REQUEST = {}
local CMD = {}
local user
handler = handler.new (REQUEST, nil, CMD)

handler:init (function (u)
	user = u
end)


function REQUEST.combat (args) -- 都到攻击tid的指令
	assert (args and args.target)

	local tid = args.target
	local agent = aoi_handler.find (tid) or error () -- 找到aoi范围内的这个tid(角色id)所属的agent

	local damage = user.character.attribute.attack_power -- 我的攻击伤害值
	damage = skynet.call (agent, "lua", "combat_melee_damage", user.character.id, damage) -- 通知agent受伤

	return { target = tid, damage = damage } -- 返回被攻击的角色id及伤害值
end

function CMD.combat_melee_damage (attacker, damage) -- 攻击我的角色(attacker)，及伤害值damage
	damage = math.floor (damage * 0.75)

	hp = user.character.attribute.health - damage -- 扣血
	if hp <= 0 then
		damage = damage + hp -- 实际造成的伤害值
		hp = user.character.attribute.health_max -- 测试，死了满血复活
	end
	user.character.attribute.health = hp

	aoi_handler.boardcast ("attribute") -- aoi范围内广播attribute属性变更
	return damage
end

return handler
