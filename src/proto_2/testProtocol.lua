-- package.path = package.path .. ";./?.lua"

local Utils = require "utils"
local msg_define = require "msg_define"
local Packer = require "packer"

local function testPack( ... )
    local aaa = Utils.int16_2_bytes(23)
    local bbb = Utils.bytes_2_int16(aaa)
    print("aaa", aaa)
    print("bbb", bbb)
end

-- 模拟发送协议
local function testSend( ... )
    local proto_name = "login.login"
    local msg = "hello world"
    local packet = Packer.pack(proto_name, msg)
    print("packet", packet)

    local proto_id, params = string.unpack(">Hs2", packet)
    local proto_name22 = msg_define.id_2_name(proto_id)
    print("proto_id", proto_id)
    print("proto_name22", proto_name22)
    print("params", params)
    print()
end

-- 模拟接收协议
local function testRecv( ... )
    local proto_name = "login.login"
    local msg = "hello world22"
    local id = msg_define.name_2_id(proto_name)
    -- local len = 2 + 2 + #msg
    -- local data = string.pack(">HHs2", len, id, msg)
    local data = string.pack(">Hs2", id, msg)
    print("data", data)

    local proto_name22, params = Packer.unpack(data)
    print("proto_name22", proto_name) 
    print("params", params)
end

-- testPack()
-- testSend()
testRecv()