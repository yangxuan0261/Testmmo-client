local Actor = require("Actor")
local CmdParser = require("cmdParser")
local Tips = require("util.Tips")
local CharList = require("app.views.CharList")

local MainCity = class("MainCity", function ()
    return cc.Layer:create()
end)

local abs = math.abs
local sqrt = math.sqrt
local floor = math.floor

function MainCity:ctor( ... )
    self:initUI()
    self:initTouchEvent()
    self:initLogic()
end

function MainCity:initUI( ... )
    self.eb_cmd = nil
    self.bigmap = nil
    self.selCharId = 0
    self.selActor = nil
    self.actorTab = {}

    local uipath = "DemoMap/DemoMap.json"
    print("------ load json:"..uipath)
    self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile(uipath)
    self:addChild(self._widget)

    self:regWiget()
    self:regEvent()
end

function MainCity:regEvent()
    eventMgr.regEvent(eventList.SelChar, handler(self, self.selChar))
    eventMgr.regEvent(eventList.ActorMove, handler(self, self.actorMove))
    eventMgr.regEvent(eventList.Tips, handler(self, self.showTips))
    eventMgr.regEvent(eventList.ListChar, handler(self, self.lvCtor))
    eventMgr.regEvent(eventList.CreateChar, handler(self, self.createActor))
    eventMgr.regEvent(eventList.RemoveChar, handler(self, self.removeActor))
end

function MainCity:unregEvent()
    eventMgr.unregEvent(eventList.SelChar, handler(self, self.selChar))
    eventMgr.unregEvent(eventList.ActorMove, handler(self, self.actorMove))
    eventMgr.unregEvent(eventList.Tips, handler(self, self.showTips))
    eventMgr.unregEvent(eventList.ListChar, handler(self, self.lvCtor))
    eventMgr.unregEvent(eventList.CreateChar, handler(self, self.createActor))
    eventMgr.unregEvent(eventList.RemoveChar, handler(self, self.removeActor))
end

function MainCity:regWiget()
    local function onSend(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            local inputStr = self.EditName:getText()
            print("--- inputStr:", inputStr)
            -- CmdParser:Send(self.eb_cmd:getString(), rpcMgr.send_request)
            if #inputStr == 0 then
                return
            end

            rpcMgr.send_request("gm", { data = inputStr })
        end
    end

    local function onClose( ... )
        eventMgr.trigEvent(eventList.ExitGame)
    end

    local root = self._widget
    local btnSend = ccui.Helper:seekWidgetByName(root, "Btn_send")
    btnSend:addTouchEventListener(onSend)
    local btnClose = ccui.Helper:seekWidgetByName(root, "Btn_close")
    btnClose:addTouchEventListener(onClose)
    self.eb_cmd = ccui.Helper:seekWidgetByName(root, "TextField_cmd")
    self.bigmap = ccui.Helper:seekWidgetByName(root, "ImageView_map")
    dump(self.eb_cmd, "--- self.eb_cmd")
    dump(self.bigmap, "--- self.bigmap")
    self:initEditbox()
end

function MainCity:initEditbox( ... )
    -- local function editBoxTextEventHandle(strEventName,pSender)
    --     local edit = pSender
    --     local strFmt 
    --     if strEventName == "return" then
     -- edit:getText()
    --         strFmt = string.format("editBox %p was returned !",edit)
    --     end
    -- end

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local editBoxSize = self.eb_cmd:getContentSize()
    -- cc.size(visibleSize.width - 100, 60)
    local posX, posY = self.eb_cmd:getPosition()
    self.EditName = cc.EditBox:create(editBoxSize, cc.Scale9Sprite:create("box.png"))
    self.EditName:setPosition(cc.p(posX, posY))
    self.EditName:setFontName("simhei.ttf")
    self.EditName:setFontSize(25)
    self.EditName:setFontColor(cc.c3b(255,0,0))
    self.EditName:setPlaceHolder("gm cmd:")
    self.EditName:setPlaceholderFontColor(cc.c3b(255,255,255))
    self.EditName:setMaxLength(255)
    self.EditName:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE )
    -- self.EditName:registerScriptEditBoxHandler(editBoxTextEventHandle)
    self.eb_cmd:addChild(self.EditName)
end

function MainCity:showTips( _content)
    Tips.show(_content)
end

function MainCity:selChar(_charData)
    if self.listView then
        self.listView:remove()
        self.listView = nil
    end

    local id = _charData.id
    if self.selCharId == id then
        return
    end

    self.selCharId = id
    if self.selCharId > 0 then
        if self.selActor then
            self.selActor:removeFromParent(true);
            self.selActor = nil
        end

        local x = _charData.movement.pos.x
        local y = _charData.movement.pos.y
        self:createActor(id, x, y)
    end

    dump(_charData)
end

function MainCity:createActor(_id, _x, _y)
    local data = user.aoiHdl:getCharData(_id)
    local actor1 = Actor.new(data)
    actor1:setPosition(cc.p(_x, _y))
    if _id == self.selCharId then
        actor1:setColor(cc.c3b(255, 0, 0))
        self.selActor = actor1
    else
        actor1:setColor(cc.c3b(0, 255, 0))
    end
    self.bigmap:addChild(actor1)

    self.actorTab[_id] = actor1
end

function MainCity:removeActor(_id)
    local actor = self.actorTab[_id]
    if not actor then
        assert(actor, "Error, removeActor id:".._id)
        return
    end

    actor:removeFromParent(true)
    if _id == self.selCharId then
        self.selCharId = 0
        self.selActor = nil
    end
end

function MainCity:initTouchEvent( ... )
    local function onTouchBegan(touch, event)
        local locationInNode = self.bigmap:convertToNodeSpace(touch:getLocation())
        local s = self.bigmap:getContentSize()
        local rect = cc.rect(0, 0, s.width, s.height)

        if cc.rectContainsPoint(rect, locationInNode) then
            -- dump(locationInNode)

            -- move owner character
            if self.selCharId > 0 then
                -- self:actorMove(self.selCharId, locationInNode.x, locationInNode.y)
                rpcMgr.send_request("move", {pos = {
                x = floor(locationInNode.x+0.5), -- avoid number error
                y = floor(locationInNode.y+0.5),
            }})
            end

            return true
        end

        return false
    end
    
    local function onTouchEnded(touch, event)

    end

    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    self:setUserObject(listener1)

    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self.bigmap)
end

function MainCity:actorMove( _id, _x, _y )
    local actor = self.actorTab[_id]
    if not actor then
        return
    end

    -- caclu time
    local posX, posY = actor:getPosition()
    local dist =sqrt(abs(posX - _x)^2 + abs(posY - _y)^2)
    local v = 500 -- speed
    actor:stopAllActions()
    local move = cc.MoveTo:create(dist/v, cc.p(_x, _y))
    actor:runAction(move)
end

function MainCity:lvCtor( _dataTab )
    if self.listView then
        self.listView:remove()
        self.listView = nil
    end

    dump(self.bigmap, "--- MainCity:lvCtor 222")
    self.listView = CharList.new(_dataTab, self.bigmap)
end

function MainCity:initLogic()
    -- rpcMgr.send_request("character_list") -- 请求所有的角色数据
end

function MainCity:onEixt()
    self:unregEvent()
end

return MainCity
