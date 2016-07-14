local Actor = class("Actor", function ()
    return cc.Sprite:create()
end)

function Actor:ctor( _data )
    self.lbId = nil
    self.aoiRadius = 100
    self.data = _data

    -- self:setTexture("blue1.png")
    self:setTexture("slider_bar_button2.png")

    self:initTouchEvent()
    self:setAnchorPoint(cc.p(0.5, 0.5))

    -- id label
    local name = "【"..self.data.general.name.."】"
    self.lbId = cc.Label:createWithTTF(name, "simhei.ttf", 20)
    self:addChild(self.lbId)
    self.lbId:setAnchorPoint(cc.p(0.5, 0.5))
    local size = self:getContentSize()
    self.lbId:setPosition(cc.p(size.width/2, size.height/2))

    -- draw range
    self:debugDraw()
end

function Actor:initTouchEvent( ... )
    local function onTouchBegan(touch, event)
        local locationInNode = self:convertToNodeSpace(touch:getLocation())
        local s = self:getContentSize()
        local rect = cc.rect(0, 0, s.width, s.height)
            
        if cc.rectContainsPoint(rect, locationInNode) then
            print("--- actor1 onTouchBegan")
            return true
        end
        return false
    end

    local function onTouchMoved(touch, event)
        print("--- actor1 - onTouchMoved")
    end

    local function onTouchEnded(touch, event)
        print("--- actor1 onTouchEnded")
    end

    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    self:setUserObject(listener1)

    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener1:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self)
end

function Actor:debugDraw( ... )
    self.drawNode = cc.DrawNode:create()
    self.drawNode:setAnchorPoint(cc.p(0.5, 0.5))
    self.drawNode:drawRect(cc.p(-self.aoiRadius,self.aoiRadius)
                           , cc.p(self.aoiRadius,-self.aoiRadius)
                           , cc.c4f(1,1,0,1))
    self:addChild(self.drawNode)
end

return Actor