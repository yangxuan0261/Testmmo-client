local Tips = require("util.Tips")

local LoginLayer = class("LoginLayer", function ()
    return cc.Layer:create()
end)

function LoginLayer:ctor( ... )
    self.bConnect = nil

    self:initUI()
end

function LoginLayer:initUI( ... )
    local uipath = "DemoLogin/DemoLogin.json"
    print("------ load json:"..uipath)
    self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile(uipath)
    self:addChild(self._widget)

    self._widget:setAnchorPoint(cc.p(0.5, 0.5))
    self._widget:move(display.center)
    self:regWiget()
end

function LoginLayer:regWiget()
    local function onClose(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            -- eventMgr.trigEvent(eventList.ExitGame)
            -- Tips.show("hello")
            local test = require("state.GSInit").new("--- gamestate aaa")
        end
    end

    local function onLogin(sender, eventType)
        if eventType == ccui.TouchEventType.ended then

            local name = self.tfName:getString()
            local pwd = self.tfPwd:getString()
            print("--- name, pwd:", name, pwd)

            self.bConnect = rpcMgr.connect()
            -- assert(self.bConnect, "loginServer connect fail")

            rpcMgr.login(name, pwd)
        end
    end

    local root = self._widget
    local btnClose = ccui.Helper:seekWidgetByName(root, "Btn_close")
    btnClose:addTouchEventListener(onClose)
    local btnLogin = ccui.Helper:seekWidgetByName(root, "Btn_login")
    btnLogin:addTouchEventListener(onLogin)

    self.tfName = ccui.Helper:seekWidgetByName(root, "name_TextField")
    self.tfPwd = ccui.Helper:seekWidgetByName(root, "password_TextField")
end

return LoginLayer
