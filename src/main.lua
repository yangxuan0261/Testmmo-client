
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

package.path = package.path .. "./?.lua;./proto/?.lua"

require "config"
require "cocos.init"



local mylog = function(...)
    print(string.format(...))
end

-- local printf= function(s, ...)  
--     return io.write(s:format(...))  
-- end  
-- printf("%s\n", "Hello World!")  

function __G__TRACKBACK__(errorMessage)
    mylog("----------------------------------------")
    mylog("--- LUA ERROR: " .. tostring(errorMessage) .. "\n")
    local traceback = debug.traceback("", 2)
    mylog(traceback)
    mylog("----------------------------------------")

    -- errorHandle(errorMessage, traceback)
end

local function main()
    require("app.MyApp"):create():run()
    printf("--------------- start")
   

end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
