local currentScene

local Audio = require("audio")

function LoadScene(scene,...)
    currentScene = scene
    local inGame = currentScene == require("game")
    love.mouse.setVisible(not inGame)
    love.mouse.setGrabbed(inGame)
    -- leaving a level must not leave the walk loop running
    Audio.stopMovement()
    if currentScene.enter then currentScene.enter(currentScene,...) end

end

-- Menu buttons slowly swell up while the pointer is over them,
-- and take a little longer (~0.2s) to settle back down
local HOVER_SCALE = 1.08
local GROW_SPEED = 8
local SHRINK_SPEED = 5

function MenuButtonScale(button, hovered)
    button.scale = button.scale or 1
    local target = hovered and HOVER_SCALE or 1
    local speed = hovered and GROW_SPEED or SHRINK_SPEED
    button.scale = button.scale + (target - button.scale) * math.min(love.timer.getDelta() * speed, 1)
end

function BeginMenuButton(button)
    love.graphics.push()
    love.graphics.translate(button.x + button.w / 2, button.y + button.h / 2)
    love.graphics.scale(button.scale or 1)
    love.graphics.translate(-button.w / 2, -button.h / 2)
end

function EndMenuButton()
    love.graphics.pop()
end

function love.load()
    json = require("libs.json")
    anim8 = require("libs.anim8")

    ctrls = json.decode(love.filesystem.read("controls.json"))

    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    buttonPressed = love.graphics.newImage("assets/sprites/buttons/buttonPressed.png")
    buttonUnpressed = love.graphics.newImage("assets/sprites/buttons/buttonUnpressed.png")

    mainFont = love.graphics.newFont(
    "assets/fonts/Exile-Regular.ttf",
    24
    )

    local icon = love.image.newImageData("assets/icons/icon.png")
    love.window.setIcon(icon)

    love.graphics.setDefaultFilter("nearest","nearest")
    particles = require("particles")
    softCursor = require("cursor")
    softCursor:enter()
    require("save").load()
    Audio.load()
    LoadScene(require("menus/main_menu"))

end

function love.update(dt)
    particles:update(dt)
    softCursor:update(dt)
    love.mouse.setVisible(false)
    if currentScene.update then currentScene.update(currentScene, dt) end

end

function love.draw()
    if currentScene.draw then currentScene.draw(currentScene) end
    if not love.mouse.isGrabbed() then softCursor:draw() end

end

function love.keypressed(key)
    if key == ctrls[5].keybind then LoadScene(require("menus/main_menu")) return end
    if currentScene.keypressed then currentScene.keypressed(currentScene,key) end

end

function love.mousepressed(x, y, button)
    if currentScene.mousepressed then
        currentScene:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if currentScene.mousereleased then
        currentScene:mousereleased(x, y, button)
    end
end