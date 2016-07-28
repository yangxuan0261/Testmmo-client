local ChatPanel = class("ChatPanel")

local friendMsgTab = {}
local laborMsgTab = {}
local worldMsgTab = {}

function ChatPanel:ctor(_parent)
    self.dataTab = _dataTab
    self._parent = _parent
    self:initUI()
    -- self:fillData()
    self:regEvent()
end

function ChatPanel:initUI( ... )
    local uipath = "ChatUI_1/ChatUI_1.json"
    print("------ load json:"..uipath)
    self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile(uipath)
    self._layer = cc.Layer:create()
    self._layer:setAnchorPoint(cc.p(0.5, 0.5))
    self._layer:addChild(self._widget)
    self._parent:addChild(self._layer)
    self:regWiget()
    self:initEditBox()
    self:initListView()
end

function ChatPanel:regEvent( ... )
    eventMgr.regEvent(eventList.FriendMsg, handler(self, self.onFriendMsg))
    eventMgr.regEvent(eventList.LaborMsg, handler(self, self.onLaborMsg))
    eventMgr.regEvent(eventList.WorldMsg, handler(self, self.onWorldMsg))
end

function ChatPanel:unregEvent( ... )
    eventMgr.unregEvent(eventList.FriendMsg, handler(self, self.onFriendMsg))
    eventMgr.unregEvent(eventList.LaborMsg, handler(self, self.onLaborMsg))
    eventMgr.unregEvent(eventList.WorldMsg, handler(self, self.onWorldMsg))
end

function ChatPanel:regWiget( ... )
    local function onSend(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local inputStr = self.eb_msg:getText()
            print("--- inputStr:", inputStr)
        end
    end

    local function onClose(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self._layer:removeFromParent(true)
        end
    end

    local function onFriend(sender,eventType)
        if eventType == ccui.TouchEventType.ended then

        end
    end

    local function onLabor(sender,eventType)
        if eventType == ccui.TouchEventType.ended then

        end
    end

    local function onWorld(sender,eventType)
        if eventType == ccui.TouchEventType.ended then

        end
    end

    local root = self._widget
    local btnSend = ccui.Helper:seekWidgetByName(root, "Button_send")
    local btnClose = ccui.Helper:seekWidgetByName(root, "Button_close")
    btnSend:addTouchEventListener(onSend)
    btnClose:addTouchEventListener(onClose)
    self.imgMsgBg = ccui.Helper:seekWidgetByName(root, "Image_msgBg")
    self.imgLvBg = ccui.Helper:seekWidgetByName(root, "Image_lvBg")

    local btnFriend = ccui.Helper:seekWidgetByName(root, "Button_friend")
    local btnLabor = ccui.Helper:seekWidgetByName(root, "Button_labor")
    local btnWorld = ccui.Helper:seekWidgetByName(root, "Button_world")
    btnFriend:addTouchEventListener(onFriend)
    btnLabor:addTouchEventListener(onLabor)
    btnWorld:addTouchEventListener(onWorld)
end

function ChatPanel:initEditBox( ... )
    local size = self.imgMsgBg:getContentSize()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local eb_msg = cc.EditBox:create(size, cc.Scale9Sprite:create("box.png"))
    eb_msg:setAnchorPoint(cc.p(0, 0))
    eb_msg:setPosition(cc.p(0, 0))
    eb_msg:setFontName("simhei.ttf")
    eb_msg:setFontSize(25)
    eb_msg:setFontColor(cc.c3b(255,0,0))
    eb_msg:setPlaceHolder("msg:")
    eb_msg:setPlaceholderFontColor(cc.c3b(255,255,255))
    eb_msg:setMaxLength(255)
    eb_msg:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE )
    self.eb_msg = eb_msg
    self.imgMsgBg:addChild(self.eb_msg)
end


function ChatPanel:initListView( ... )
    local size = self.imgLvBg:getContentSize()

    local listView = ccui.ListView:create()
    listView:setDirection(ccui.ScrollViewDir.vertical)
    listView:setTouchEnabled(true)
    listView:setBounceEnabled(true)
    listView:setAnchorPoint(cc.p(0, 0))
    listView:setPosition(cc.p(0, 0))
    -- listView:setBackGroundImage("alert_bg.png")
    listView:setBackGroundImageScale9Enabled(true)
    listView:setContentSize(size)
    self.imgLvBg:addChild(listView)
    self.listView = listView
end

function ChatPanel:fillData( ... )
    local btnTab = {}
    local function touchEvent(sender,eventType)
       if eventType == ccui.TouchEventType.ended then
            local data = btnTab[sender]
            local id = tonumber(data.id)
            print("------- character_pick, id:", id)
            rpcMgr.send_request("character_pick", { id = id })
       end
    end

    --add custom item
    local listView = self.listView
    for k,v in pairs(self.dataTab) do
        local name = "【"..v.general.name.."】"
        local lblName = cc.Label:createWithTTF(name, "simhei.ttf", 20)
        lblName:setAnchorPoint(cc.p(0.5, 0.5))

        local btnSel = ccui.Button:create("DemoLogin/button_p.png", "DemoLogin/button.png")
        btnSel:setScale9Enabled(true)
        btnSel:addTouchEventListener(touchEvent)
        btnTab[btnSel] = v

        local lvSize = listView:getContentSize()
        local lblSize = lblName:getContentSize()

        local lvItem = ccui.Layout:create()
        lvItem:setContentSize(cc.size(lvSize.width, btnSize.height))
        lblName:setPosition(cc.p(lblSize.width / 2, lvItem:getContentSize().height / 2.0))
        lvItem:addChild(lblName)

        listView:pushBackCustomItem(lvItem)
    end
end

function ChatPanel:onFriendMsg(  )

end

function ChatPanel:onLaborMsg( _data )
    table.insert(laborMsgTab, _data)
end

function ChatPanel:onWorldMsg( ... )
end

function ChatPanel:remove( ... )
    self:unregEvent()
    self.listView:removeFromParent(true)
end

return ChatPanel