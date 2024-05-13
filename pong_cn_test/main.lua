--[[
    GD50 2018
    Pong Remake

    pong-12
    "The Resize Update"

    -- Main Program --

    作者：Colton Ogden
    cogden@cs50.harvard.edu

    原始由Atari于1972年编写。具有两个由玩家控制的挡板，目标是将球传过对手的边缘。首先得到10分的玩家获胜。

    这个版本更接近NES，而不是原始的Pong机器或Atari 2600，从分辨率上来说，尽管是宽屏（16:9），所以在现代系统上看起来更好。
]]

-- push是一个库，它允许我们以虚拟分辨率而不是窗口的实际大小来绘制游戏；用于提供更复古的美学
--
-- https://github.com/Ulydev/push
push = require 'push'

-- 我们使用的“Class”库将允许我们将游戏中的任何东西表示为代码，而不是跟踪许多不同的变量和方法
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- 我们的Paddle类，用于存储每个Paddle的位置和尺寸以及呈现它们的逻辑
require 'Paddle'

-- 我们的Ball类，在结构上与Paddle没有太大的不同，但在机械上的功能会有很大的不同
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- 我们将移动挡板的速度；在update中通过dt相乘以实现移动
PADDLE_SPEED = 200

--[[
    当游戏第一次启动时运行，仅运行一次；用于初始化游戏。
]]
function love.load()
    -- 将love的默认过滤器设置为“nearest-neighbor”，这实际上意味着像素没有过滤（模糊），这对于获得清晰的2D外观非常重要
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- 设置应用窗口的标题
    love.window.setTitle('Pong')

    -- “种子化”随机数生成器，以便随机调用始终是随机的
    -- 使用当前时间，因为每次启动时它会变化
    math.randomseed(os.time())

    -- 初始化我们漂亮的复古文本字体
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- 设置声音效果；稍后，我们可以通过索引此表并调用每个条目的`play`方法
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- 使用虚拟分辨率初始化窗口
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    -- 初始化用于在屏幕上渲染和跟踪获胜者的分数变量
    player1Score = 0
    player2Score = 0

    -- 将要么是1要么是2；被得分的玩家将在以下回合中提供服务
    servingPlayer = 1

    -- 初始化玩家挡板和球
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    gameState = 'start'
end

--[[
    当我们调整屏幕大小时由LÖVE调用；在这里，我们只需传递宽度和高度给push，以便我们的虚拟分辨率可以根据需要进行调整。
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    每帧运行，由“dt”传递，是自上一帧以来的秒数，LÖVE2D会提供给我们。
]]
function love.update(dt)
    if gameState == 'serve' then
        -- 在切换到play之前，根据最后得分的玩家初始化球的速度
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- 检测球与挡板的碰撞，如果碰撞则反转dx并略微增加它，然后根据碰撞位置改变dy
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- 保持速度朝着同一方向，但随机化它
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- 保持速度朝着同一方向，但随机化它
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        -- 检测上下屏幕边界碰撞并在碰撞时反转
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4是为了考虑球的大小
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end
        
        -- 如果达到屏幕的左边缘或右边缘，
        -- 回到开始并更新得分
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- 如果我们达到10分，则游戏结束；将状态设置为done，以便我们可以显示胜利消息
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- 将球放在屏幕中央，没有速度
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()
            
            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    -- 玩家1的移动
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- 玩家2的移动
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- 如果我们处于播放状态，则基于其DX和DY更新球；通过dt缩放速度，以便移动与帧率无关
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    键盘处理，由LÖVE2D每帧调用；传入我们按下的键，以便我们可以访问。
]]
function love.keypressed(key)

    if key == 'escape' then
        love.event.quit()
    -- 如果我们在开始或服务阶段按下回车键，则应转换到下一个适当的状态
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- 游戏只是在这里处于重新启动阶段，但是将服务的玩家设置为赢得比赛的对手以公平起见！
            gameState = 'serve'

            ball:reset()

            -- 将得分重置为0
            player1Score = 0
            player2Score = 0

            -- 将服务的玩家决定为获胜者的对手
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[
    由LÖVE2D在update之后调用，用于将任何东西绘制到屏幕上，更新或其他。
]]
function love.draw()

    push:apply('start')

    -- 用特定颜色清除屏幕；在这种情况下，颜色类似于原始Pong的某些版本
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    love.graphics.setFont(smallFont)

    displayScore()

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- 在播放时没有UI消息
    elseif gameState == 'done' then
        -- UI消息
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    player1:render()
    player2:render()
    ball:render()

    displayFPS()

    push:apply('end')
end

--[[
    渲染当前FPS。
]]
function displayFPS()
    -- 在所有状态下显示简单的FPS
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

--[[
    简单地将得分绘制到屏幕上。
]]
function displayScore()
    -- 在屏幕的左右中心绘制分数
    -- 需要切换字体以便在实际打印之前绘制
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end
