local RpcMgr = class("RpcMgr")

local srp = require("srp")
local aes = require("aes")
local network = require("network")
local login_proto = require("proto.login_proto")
local game_proto = require("proto.game_proto")
local constant = require("constant")
local Scheduler = cc.Director:getInstance():getScheduler()
RpcMgr.schedulerEntry = nil

local loginserver = {
    ip = "192.168.23.128",
    port = 9777,
}

-- get from server
local gameserver = {
    ip = "192.168.23.128",
    port = 9555,
    name = "gameserver",
}


local function send_message (msg)
    -- print("--- send_message, len:", #msg)
    network.send(msg)
end

local Utils = require "proto_2.utils"
local msg_define = require "proto_2.msg_define"
local Packer = require "proto_2.packer"

local function send_request(name, args)
    print("--- 【C>>S】, send_request:", name)
    local packet = Packer.pack(name, args)
    send_message (packet)
end

------------ register interface begin -------
local RESPONSE = {}
local REQUEST = {}
RpcMgr.response = RESPONSE
RpcMgr.request = REQUEST
RpcMgr.send_request = send_request
------------ register interface begin -------


function RESPONSE.rpc_cli_handshake (args)
    print ("--- rpc_cli_handshake")
    local name = user.name
    if args.user_exists then
        print("--- user user_exists")
        local key = srp.create_client_session_key (name, user.password, args.salt, user.private_key, user.public_key, args.server_pub)
        user.session_key = key
        local ret = { challenge = aes.encrypt (args.challenge, key) }
        rpcMgr.send_request ("rpc_svr_auth", ret)
    else
        print ("--- not exists, create default_password", name, constant.default_password)
        local key = srp.create_client_session_key (name, constant.default_password, args.salt, user.private_key, user.public_key, args.server_pub)
        print("--- key:", key)
        user.session_key = key
        local ret = { challenge = aes.encrypt (args.challenge, key), password = aes.encrypt (user.password, key) }
        rpcMgr.send_request ("rpc_svr_auth", ret)
    end
end

function RESPONSE.rpc_cli_auth (args)
    print ("RESPONSE.auth")

    user.session = args.session
    local challenge = aes.encrypt (args.challenge, user.session_key)
    rpcMgr.send_request ("rpc_svr_challenge", { session = args.session, challenge = challenge })
end

function RESPONSE.rpc_cli_challenge (args)
    print ("----- rpc_cli_challenge, login success, token", args.token)

    -- local token = aes.encrypt (args.token, user.session_key)
    -- print("------ token", token)
    -- user.token = token

    eventMgr.trigEvent(eventList.LoginSuccess)
end

local counter = 1
function RESPONSE.rpc_cli_user_info (args)
    print ("RESPONSE.rpc_cli_user_info")
    dump(args, "--- rpc_cli_user_info")
    user.info = args

    -- if counter < 5 then
    --     counter = counter + 1
    --     -- send_request ("rpc_svr_test_crash", {aaa=111})


    -- -- 测试上行
    -- local tmpTab = {yang=111, xuan=666}
    -- send_request ("rpc_svr_rank_info", tmpTab)
    -- end


end

function RESPONSE.rpc_cli_other_login (args)
    print ("--- 其他地方登陆")
end



function RESPONSE.rpc_cli_chat (args)
    assert (args.account and args.msg)
        
    local speaker = ""
    if user.info.account == args.account then
        speaker = "我"
    else
        speaker = args.nickName
    end
    print(string.format("--- 【%s】 说: %s ", speaker, args.msg))
end

local function handle_message (data)
    local proto_name, params_str = Packer.unpack(data)
    local paramTab = Utils.str_2_table(params_str)
    local f = RESPONSE[proto_name]
    if f then
        f(paramTab)
    else
        print("--- handle_response, not found func:", proto_name)
    end
end

local function unpack (text)
    if not text then return end

    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte (1) * 256 + text:byte (2)

    -- print(string.format("--- unpacking, realSize:%d, expectSize:%d",size, s))
    if size < s + 2 then
        return nil, text
    end

    return text:sub (3, 2 + s), text:sub (3 + s)
end

local last = ""
local function recv (last)
    local result
    result, last = unpack (last)
    if result then
        return result, last
    end

    local r, err = network:recv()
    if r then
        -- print("--- socket recv, r, len:", #r, r)
    end
    if err then
        return nil, last
    end
    if r == "" then
        error (string.format ("socket closed"))
    end

    return unpack (last .. r)
end

function RpcMgr.schedulerReceive( ... )
    local function dispatch_message ()
        while true do
            local v
            v, last = recv(last)
            if not v then
                break
            end

            handle_message (v)
        end
    end

    dispatch_message()
end

function RpcMgr.connect()
    -- local ret = network.connect(loginserver.ip, loginserver.port)
    local ret = network.connect(gameserver.ip, gameserver.port)
    local msg = ret and "connect loginserver success" or "connect loginserver fail"
    print("--- ", msg)
    if ret then
        network.startSRThread()
        RpcMgr.schedulerEntry = Scheduler:scheduleScriptFunc(RpcMgr.schedulerReceive, 0.1, false)
    end
    return ret
end

function RpcMgr.login(username, password)
    RpcMgr.loginGameServer(username, password)


    if true then
         return
    end

    local private_key, public_key = srp.create_client_key()
    user.private_key = private_key
    user.public_key = public_key
    print("--- private_key:", private_key)
    print("--- public_key:", public_key)
    print("--- username:", username)
    print("--- password:", password)
    user.name = username
    user.password = password
    send_request ("rpc_svr_handshake", { name = user.name, client_pub = public_key })
end

function RpcMgr.loginGameServer(username, password)
    user.info = { account = username }
    send_request ("rpc_svr_login_gameserver", {session = 666, stoken = "hello world", username = username})

end

function RpcMgr.connGameServer()
    -- local ret = network.connect(gameserver.ip, gameserver.port)
    -- local ret = network.connect(args.ip, args.port)
    local msg = ret and "connect gameserver success" or "connect gameserver fail"
    print("--- ", msg)
    if ret then
        -- send_request ("rpc_svr_login_gameserver", { session = user.session, token = user.token })

        -- host = sproto.new (game_proto.s2c):host "package"
        -- request = host:attach (sproto.new (game_proto.c2s))

        -- send_request ("character_list") -- 请求所有的角色数据
    end
end

function RpcMgr.close()

end

return RpcMgr
