local Tips = class("Tips", function (_flag)
    return cc.Layer:create()
end)

function Tips:ctor(_flag)
    self.content = _flag

    self:initUI()
    self:initTouchEvent()
    self:anim(true)
end

function Tips:anim( _bStart )
    self._canTouch = false
    local function calback()
        self._canTouch = true

        if not _bStart then
            self:removeFromParent(true)
        end
    end

    local callfunc = cc.CallFunc:create(calback)
    local action = cc.Sequence:create(
        cc.ScaleTo:create(0.1,2.0,2.0),
        cc.ScaleTo:create(0.1,1.0,1.0),
        callfunc)

    self:runAction(action)
end

function Tips:initUI( ... )
    self.lblTips = cc.Label:createWithTTF(self.content, "simhei.ttf", 30)
    self.lblTips:setAnchorPoint(cc.p(0.5, 0.5))
    self.lblTips:move(display.center)
    self:addChild(self.lblTips, 1)
end

function Tips:initTouchEvent( ... )
    local function onTouchBegan(touch, event)
        return self._canTouch
    end

    local function onTouchEnded(touch, event)
        self:close()
    end

    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    self:setUserObject(listener1)

    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self)
end

function Tips:close( ... )
    self:anim(false)
end
-- function Tips:debugDraw( ... )

function Tips.show( _content )
    local tips = Tips.new(_content)
    mainScene:addChild(tips, 99)
end

return Tips