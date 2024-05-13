--[[
    GD50 2018
    Pong Remake

    -- Ball Class --

    作者：Colton Ogden
    cogden@cs50.harvard.edu

    表示一个球，它将在挡板和墙之间来回弹动，直到通过屏幕的左侧或右侧边界，为对手得分一分。
]]

Ball = Class{}

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- 这些变量用于跟踪我们在X和Y轴上的速度，因为球可以在两个维度上移动
    self.dy = math.random(2) == 1 and -100 or 100
    self.dx = math.random(2) == 1 and math.random(-80, -100) or math.random(80, 100)
end

--[[
    期望一个挡板作为参数，并根据它们的矩形是否重叠返回true或false。
]]
function Ball:collides(paddle)
    -- 首先，检查任何一个的左边缘是否在另一个的右边缘的右侧
    if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
        return false
    end

    -- 然后检查任何一个的底边是否在另一个的顶边之上
    if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
        return false
    end 

    -- 如果以上条件都不成立，它们就重叠了
    return true
end

--[[
    将球放置在屏幕中央，并在两个轴上具有初始随机速度。
]]
function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dy = math.random(2) == 1 and -100 or 100
    self.dx = math.random(-50, 50)
end

--[[
    简单地将速度应用于位置，按deltaTime缩放。
]]
function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
