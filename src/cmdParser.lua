local Cmd = {}

function Cmd:Send( _cmdStr , _sendFunc)
    print("--- cmd 111:".._cmdStr)
    local cmd, t = self:CmdParser(_cmdStr)
    print("--- cmd222:"..cmd..", argTab:")
    dump(t)

    if cmd and _sendFunc then
        local ok, err = pcall (_sendFunc, cmd, t)
        if not ok then
            print (string.format ("invalid command (%s), error (%s)", cmd, err))
        end
    end
end

function Cmd:CmdParser( cmdStr )
    -- body
    local strTab = {}
    local rets = string.gmatch(cmdStr, "%S+")
    for i in (rets) do
        table.insert(strTab, i)
    end
    local argTab = {}
    local cmd = strTab[1]

    if cmd == "create" then
        cmd = "character_create"
        argTab = {
            character = { 
                name = strTab[2],
                race = strTab[3],
                class = strTab[4]
            }
        }

    elseif cmd == "pick" then
        cmd = "character_pick"
        local ids = {
            [1] = 3152259373946897409,
            [2] = 3151658778605126657
        }
        argTab = { id = ids[tonumber(strTab[2])] }

    elseif cmd == "list" then
        cmd = "character_list"

    elseif cmd == "del" then
        cmd = "character_delete"
        argTab = { id = tonumber(strTab[2])}

    elseif cmd == "move" then
        argTab = {
            pos = {
                x = tonumber(strTab[2]),
                y = tonumber(strTab[3])
            }
        }

    elseif cmd == "enter" then
        cmd = "map_ready"

    elseif cmd == "atk" then
        cmd = "combat"
        argTab = { target = tonumber(strTab[2]) }

    elseif cmd == "test1" then
        argTab = { 
          arg1 = tonumber(strTab[2]), 
          arg2 = strTab[3]
      }
    end

    return cmd, argTab
end

return Cmd