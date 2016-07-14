local LoadingLayer = class("LoadingLayer", function ()
    return cc.Layer:create()
end)

function LoadingLayer:ctor()
    self:initUI()
end

function LoadingLayer:initUI( ... )
    local uipath = "DemoHead_UI/DemoHead_UI.json"
    print("------ load json:"..uipath)
    self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile(uipath)
    self:addChild(self._widget)

    self._widget:setAnchorPoint(cc.p(0.5, 0.5))
    self._widget:move(display.center)
    self:regWiget()
    self:anim()
end

function LoadingLayer:regWiget()
    local root = self._widget
    self.barRed = ccui.Helper:seekWidgetByName(root, "redBar")
    self.barBlue = ccui.Helper:seekWidgetByName(root, "blueBar")
    self.imgHead = ccui.Helper:seekWidgetByName(root, "head")
end

function LoadingLayer:anim()
    -- local actionBy2 = cc.RotateBy:create(1.0, 360)
    -- self.imgHead:runAction(cc.RepeatForever:create(actionBy2))

    local to1 = cc.ProgressTo:create(2, 100)
    self.barRed:runAction(cc.RepeatForever:create(to1))
end

function LoadingLayer:setPercent(_dt)
    print("--- _dt:", _dt)
    -- self.barRed:setPercentage(_dt)
end

return LoadingLayer