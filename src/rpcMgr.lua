local RpcMgr = class("RpcMgr")

local sproto = require("sproto")
local srp = require("srp")
local aes = require("aes")
local network = require("network")
local login_proto = require("proto.login_proto")
local game_proto = require("proto.game_proto")
local constant = require("constant")
local Scheduler = cc.Director:getInstance():getScheduler()
RpcMgr.schedulerEntry = nil

local loginserver = {
    ip = "192.168.253.131",
    port = 9777,
}

-- get from server
local gameserver = {
    addr = "192.168.253.131",
    port = 9555,
    name = "gameserver",
}

local host = sproto.new (login_proto.s2c):host "package"
local request = host:attach (sproto.new (login_proto.c2s))

local function send_message (msg)
    local packmsg = string.pack (">s2", msg)
    -- print ("^^^C>>S send_message, len:"..#packmsg..", type:"..type(packmsg))
    network.send(packmsg)
end

local session = {}
local session_id = 0
local function send_request (name, args)
    print("--- 【C>>S】, send_request:", name)
    session_id = session_id + 1
    local str = request (name, args, session_id)
    send_message (str)
    session[session_id] = { name = name, args = args }
end

------------ register interface begin -------
local RESPONSE = {}
local REQUEST = {}
RpcMgr.response = RESPONSE
RpcMgr.request = REQUEST
RpcMgr.send_request = send_request
------------ register interface begin -------


function RESPONSE:handshake (args)
    print ("RESPONSE.handshake, self.name", self.name)
    local name = self.name
    assert (name == user.name)

    if args.user_exists then
        print("--- user user_exists")
        local key = srp.create_client_session_key (name, user.password, args.salt, user.private_key, user.public_key, args.server_pub)
        user.session_key = key
        local ret = { challenge = aes.encrypt (args.challenge, key) }
        rpcMgr.send_request ("auth", ret)
    else
        print ("--- not exists, create default_password", name, constant.default_password)
        local key = srp.create_client_session_key (name, constant.default_password, args.salt, user.private_key, user.public_key, args.server_pub)
        print("--- key:", key)
        user.session_key = key
        local ret = { challenge = aes.encrypt (args.challenge, key), password = aes.encrypt (user.password, key) }
        rpcMgr.send_request ("auth", ret)
    end
end

function RESPONSE:auth (args)
    print ("RESPONSE.auth")

    user.session = args.session
    local challenge = aes.encrypt (args.challenge, user.session_key)
    rpcMgr.send_request ("challenge", { session = args.session, challenge = challenge })
end

function RESPONSE:challenge (args)
    print ("RESPONSE.challenge")

    local token = aes.encrypt (args.token, user.session_key)
    print("------ token", token)
    user.token = token

    eventMgr.trigEvent(eventList.LoginSuccess)
end

local function handle_request (name, args, response)
    print ("--- 【S>>C】, request from server:", name)

    -- if args then
    --     dump (args)
    -- end

    local f = REQUEST[name]
    if f then
        local ret = f(nil, args)
        if ret and response then
            send_message (response (ret))
        end
    else
        print("--- handle_request, not found func:"..s.name)
    end
end

local function handle_response (id, args)
    local s = assert (session[id])
    session[id] = nil
    local f = RESPONSE[s.name]

    print ("--- 【S>>C】, response from server:", s.name)
    -- dump (args)

    if f then
        f (s.args, args)
    else
        print("--- handle_response, not found func:"..s.name)
    end
end

local function handle_message (t, ...)
    if t == "REQUEST" then
        handle_request (...)
    else
        handle_response (...)
    end
end

local function unpack (text)
    if not text then return end

    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte (1) * 256 + text:byte (2)

    print(string.format("--- unpacking, realSize:%d, expectSize:%d",size, s))
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
        print("--- socket recv, r, len:", #r, r)
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

            handle_message (host:dispatch (v))
        end
    end

    dispatch_message()
end

local function RpcCallback(flag)
    print("--- lua net callback", flag)
    if flag == 2 then
        RpcMgr.schedulerEntry = Scheduler:scheduleScriptFunc(RpcMgr.schedulerReceive, 0.1, false)
    end
end
_G["RpcCallback"] = RpcCallback

function RpcMgr.connect()
    network.regCallback("RpcCallback")
    local ret = network.connect(loginserver.ip, loginserver.port)
    local msg = ret and "connect loginserver success" or "connect loginserver fail"
    print("--- ", msg)
    -- if ret then
    --     RpcMgr.schedulerEntry = Scheduler:scheduleScriptFunc(RpcMgr.schedulerReceive, 0.1, false)
    -- end
    return ret
end

function RpcMgr.login(username, password)
    local private_key, public_key = srp.create_client_key()
    user.private_key = private_key
    user.public_key = public_key
    print("--- private_key:", private_key)
    print("--- public_key:", public_key)
    user.name = username
    user.password = password
    send_request ("handshake", { name = user.name, client_pub = public_key })
end

function RpcMgr.connGameServer()
    local ret = network.connect(gameserver.addr, gameserver.port)
    -- local ret = network.connect(args.ip, args.port)
    local msg = ret and "connect gameserver success" or "connect gameserver fail"
    print("--- ", msg)
    if ret then
        send_request ("login", { session = user.session, token = user.token })

        host = sproto.new (game_proto.s2c):host "package"
        request = host:attach (sproto.new (game_proto.c2s))

        send_request ("character_list") -- 请求所有的角色数据
    end
end

function RpcMgr.close()

end

return RpcMgr
