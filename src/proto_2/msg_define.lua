local MsgDefine = {}

local id_tbl = {
------- 登陆 -------
{name = "rpc_cli_handshake_1"},
{name = "rpc_cli_handshake_2"},
{name = "rpc_svr_handshake"},
{name = "rpc_cli_challenge"},

{name = "rpc_svr_auth"},
{name = "rpc_cli_token"},

{name = "rpc_svr_login_gameserver"},
{name = "rpc_cli_testsvr_down"},
{name = "rpc_svr_testcli_up"},
{name = "rpc_svr_testhdl"},

------- 游戏 -------
{name = "rpc_cli_user_info"},
{name = "rpc_svr_rank_info"},

------- 聊天 -------
{name = "rpc_svr_chat"},
{name = "rpc_cli_chat"},
{name = "rpc_cli_tips"},

{name = "rpc_svr_test_crash"},
{name = "rpc_cli_other_login"},
}

local name_tbl = {}

for id,v in ipairs(id_tbl) do
    name_tbl[v.name] = id
end

function MsgDefine.name_2_id(name)
    return name_tbl[name]
end

function MsgDefine.id_2_name(id)
    local v = id_tbl[id]
    if v == nil then
        print("---------- id_2_name, no rpc, id", id)
    end
    return v.name
end

function MsgDefine.get_by_id(id)
    return id_tbl[id]
end

function MsgDefine.get_by_name(name)
    local id = name_tbl[name]
    return id_tbl[id]
end

return MsgDefine
