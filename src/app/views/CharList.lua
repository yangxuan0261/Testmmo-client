local CharList = class("CharList")

function CharList:ctor(_dataTab, _parent)
    self.dataTab = _dataTab
    self.parent = _parent
    self:initUI()
    self:fillData()
end

function CharList:initUI( ... )
    local widgetSize = self.parent:getContentSize()

    local listView = ccui.ListView:create()
    -- set list view ex direction
    listView:setDirection(ccui.ScrollViewDir.vertical)
    listView:setTouchEnabled(true)
    listView:setBounceEnabled(true)
    listView:setAnchorPoint(cc.p(0.5, 0.5))
    listView:setBackGroundImage("alert_bg.png")
    listView:setBackGroundImageScale9Enabled(true)
    listView:setContentSize(cc.size(240, 130))
    listView:setPosition(cc.p(widgetSize.width/2, widgetSize.height/2))
    -- listView:addEventListener(listViewEvent)
    self.parent:addChild(listView)
    self.listView = listView
end

function CharList:fillData( ... )
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
        local btnSize = btnSel:getContentSize()
        local lblSize = lblName:getContentSize()

        local lvItem = ccui.Layout:create()
        lvItem:setContentSize(cc.size(lvSize.width, btnSize.height))
        lblName:setPosition(cc.p(lblSize.width / 2, lvItem:getContentSize().height / 2.0))
        btnSel:setPosition(cc.p(lvSize.width - btnSize.width / 2, lvItem:getContentSize().height / 2.0))
        lvItem:addChild(lblName)
        lvItem:addChild(btnSel)

        listView:pushBackCustomItem(lvItem)
    end
end

function CharList:remove( ... )
    self.listView:removeFromParent(true)
end

return CharList