--[[
    GD50 2018
    Pong Remake

    -- Paddle Class --

    作者：Colton Ogden
    cogden@cs50.harvard.edu

    表示一个能够上下移动的挡板。在主程序中用于将球反弹回对手处。
]]

Paddle = Class{}

--[[
    我们类中的 `init` 函数在对象第一次创建时调用一次。用于设置类中的所有变量，并准备好使用。

    我们的挡板应该接受 X 和 Y 作为定位参数，以及宽度和高度作为其尺寸。

    请注意，`self` 是对*当前*对象的引用，无论在调用此函数时实例化的是哪个对象。不同的对象可以有自己的 x、y、width 和 height 值，因此可以作为数据的容器。在这方面，它们与 C 中的结构非常相似。
]]
function Paddle:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dy = 0
end

function Paddle:update(dt)
    -- 这里的 math.max 确保我们在按向上键时，我们的当前计算的 Y 位置大于0，这样我们就不会进入负值；运动计算仅仅是我们先前定义的挡板速度乘以 dt。
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)
    -- 类似于前面，这次我们使用 math.min 来确保我们不会超过屏幕底部减去挡板的高度（否则它将部分地移动到下方，因为位置是基于其左上角的）。
    else
        self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
    end
end

--[[
    理想情况下，我们的主函数在 `love.draw` 中调用这个函数。使用 LÖVE2D 的 `rectangle` 函数，它接受一个绘制模式作为第一个参数，以及矩形的位置和尺寸。要改变颜色，必须调用 `love.graphics.setColor`。截至最新版本的 LÖVE2D，甚至可以绘制圆角矩形！
]]
function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
