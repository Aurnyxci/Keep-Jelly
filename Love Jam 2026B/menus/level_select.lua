local menu = {}

local Levels = require("level")
local Save = require("save")

local JELLY_SCALE = 4
local JELLY_W, JELLY_H = 30 * JELLY_SCALE, 20 * JELLY_SCALE

local function isMouseOver(button, x, y)
    return x > button.x and x < button.x + button.w
        and y > button.y and y < button.y + button.h
end

function menu:enter(message)
    self.titleBackground = love.graphics.newImage("/assets/backgrounds/main_menu_placeholderbg.png")
    self.jellyImage = love.graphics.newImage("assets/sprites/unique/7-jelly.png")
    self.lockImage = love.graphics.newImage("assets/sprites/unique/unlockJelly.png")
    self.bigFont = love.graphics.newFont("assets/fonts/Exile-Regular.ttf", 48)
    self.titleFont = love.graphics.newFont("assets/fonts/Exile-Regular.ttf", 80)
    self.message = message or ""
    self.buttons = {}

    local cols = 5
    local paddingX, paddingY = 60, 40
    local levelCount = #Levels.order
    local backW, backH = buttonUnpressed:getWidth(), buttonUnpressed:getHeight()
    local buttonW, buttonH = JELLY_W + paddingX, JELLY_H + paddingY

    local rows = math.ceil(levelCount / cols)
    local gridW = cols * buttonW - paddingX
    local gridH = rows * buttonH - paddingY
    local startX = (screenWidth - gridW) / 2
    local startY = (screenHeight - gridH) / 2 - 40

    for index, levelName in ipairs(Levels.order) do
        local col = (index - 1) % cols
        local row = math.floor((index - 1) / cols)
        self.buttons[#self.buttons + 1] = {
            id = "level_" .. index,
            kind = "jelly",
            text = tostring(index),
            tip = "Level " .. index,
            levelName = levelName,
            levelIndex = index - 1,
            x = startX + col * buttonW,
            y = startY + row * buttonH,
            w = JELLY_W,
            h = JELLY_H,
        }
    end

    self.buttons[#self.buttons + 1] = {
        id = "back",
        kind = "button",
        text = "Back",
        tip = "Return to main menu",
        x = (screenWidth - backW) / 2,
        y = startY + gridH + buttonH,
        w = backW,
        h = backH,
    }
end

function menu:draw()
    local bgw = love.graphics.getWidth() / self.titleBackground:getWidth()
    local bgh = love.graphics.getHeight() / self.titleBackground:getHeight()
    love.graphics.draw(self.titleBackground, 0, 0, 0, bgw, bgh)

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Select Level", 0, 40, screenWidth, "center")

    local hovered = nil

    for _, button in ipairs(self.buttons) do
        local locked = button.kind == "jelly" and button.levelIndex and not Save.isUnlocked(button.levelIndex)
        local hover = isMouseOver(button, mx, my)

        MenuButtonScale(button, hover and not locked)
        BeginMenuButton(button)

        if button.kind == "jelly" then
            if locked then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(self.lockImage, 0, 0, 0, JELLY_SCALE, JELLY_SCALE)
            else
                if hover then
                    love.graphics.setColor(1, 1, 0.7)
                else
                    love.graphics.setColor(1, 1, 1)
                end
                love.graphics.draw(self.jellyImage, 0, 0, 0, JELLY_SCALE, JELLY_SCALE)
            end
            love.graphics.setColor(0, 0, 0)
            love.graphics.setFont(self.bigFont)
            love.graphics.printf(button.text, 0, 14, button.w, "center")
        else
            local image = hover and buttonPressed or buttonUnpressed
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(image, 0, 0)
            love.graphics.setFont(mainFont)
            love.graphics.printf(button.text, 0, 10, button.w, "center")
        end

        EndMenuButton()

        if hover and not locked and button.tip then
            hovered = button.tip
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mainFont)
    love.graphics.printf(hovered or self.message, 0, 680, screenWidth, "center")
end

function menu:mousepressed(x, y, button)
    if button ~= 1 then return end

    for _, b in ipairs(self.buttons) do
        if isMouseOver(b, x, y) then
            if b.id == "back" then
                LoadScene(require("menus/main_menu"))
            elseif b.levelName and Save.isUnlocked(b.levelIndex) then
                LoadScene(require("game"), b.levelName)
            elseif b.levelName then
                self.message = "Complete the previous level first."
            end
            return
        end
    end
end

return menu
