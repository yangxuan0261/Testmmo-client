local M = {}

local id_tbl = {
------- 登陆 -------
{name = "rpc_client_handshake"},
{name = "rpc_server_handshake"},
{name = "rpc_client_auth"},
{name = "rpc_server_auth"},
{name = "rpc_client_challenge"},
{name = "rpc_server_challenge"},
{name = "rpc_server_login_gameserver"},

------- 游戏 -------
{name = "rpc_client_user_info"},
{name = "rpc_server_rank_info"},

------- 聊天 -------
{name = "rpc_server_world_chat"},
{name = "rpc_client_word_chat"},
{name = "rpc_client_tips"},

{name = "rpc_server_test_crash"},
{name = "rpc_client_other_login"},
}

local name_tbl = {}

for id,v in ipairs(id_tbl) do
    name_tbl[v.name] = id
end

function M.name_2_id(name)
    local id = name_tbl[name]
    assert(id ~= nil, string.format("------- 不存在协议 【%s】", name))
    return id
end

function M.id_2_name(id)
    local v = id_tbl[id]
    if not v then
        return
    end

    return v.name
end

function M.get_by_id(id)
    return id_tbl[id]
end

function M.get_by_name(name)
    local id = name_tbl[name]
    return id_tbl[id]
end

return M
