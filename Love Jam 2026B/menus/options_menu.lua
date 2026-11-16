local options = {}

local Levels = require("level")
local Save = require("save")
local Audio = require("audio")

musicOrSound = true

function options:enter()
    self.titleBackground = love.graphics.newImage("/assets/backgrounds/main_menu_placeholderbg.png")
    self.message = ""
    Audio.setVolume(musicOrSound and 1 or 0)

    self.buttons = {
        {
            id = "map",
            text = "Map",
            tip = "Show button bindings",
            x = (screenWidth / 2) - 100,
            y = 100,
            w = 200,
            h = 50
        },
        {
            id = "sound",
            text = "Sound",
            tip = "Toggle music and sound effects",
            x = (screenWidth / 2) - 100,
            y = 190,
            w = 200,
            h = 50
        },
        {
            id = "unlock",
            text = "Unlock",
            tip = "Unlock every level",
            x = (screenWidth / 2) - 100,
            y = 280,
            w = 200,
            h = 50
        },
        {
            id = "reset",
            text = "Reset",
            tip = "Delete saved progress",
            x = (screenWidth / 2) - 100,
            y = 370,
            w = 200,
            h = 50
        },
        {
            id = "exit",
            text = "Exit",
            tip = "Return to main menu",
            x = (screenWidth / 2) - 100,
            y = 460,
            w = 200,
            h = 50
        }
    }
end

local function isMouseOver(button)
    local mx, my = love.mouse.getPosition()
    return mx > button.x and mx < button.x + button.w
        and my > button.y and my < button.y + button.h
end

function options:draw()
    local bgw = love.graphics.getWidth() / self.titleBackground:getWidth()
    local bgh = love.graphics.getHeight() / self.titleBackground:getHeight()
    love.graphics.draw(self.titleBackground, 0, 0, 0, bgw, bgh)

    local hoverTip = nil

    for _, button in ipairs(self.buttons) do
        local hover = isMouseOver(button)
        local image = hover and buttonPressed or buttonUnpressed

        MenuButtonScale(button, hover)
        BeginMenuButton(button)
        love.graphics.draw(image, 0, 0)

        love.graphics.setFont(mainFont)
        love.graphics.setColor(1, 1, 1)
        if button.id == "sound" then
            love.graphics.printf(button.text .. ": " .. (musicOrSound and "on" or "off"), 0, 10, button.w, "center")
        else
            love.graphics.printf(button.text, 0, 10, button.w, "center")
        end
        EndMenuButton()

        if hover and button.tip then
            hoverTip = button.tip
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mainFont)
    love.graphics.printf(hoverTip or self.message, 0, 680, screenWidth, "center")
end

function options:mousepressed(x, y, button)
    if button ~= 1 then return end

    for _, b in ipairs(self.buttons) do
        if x > b.x and x < b.x + b.w
            and y > b.y and y < b.y + b.h then

            if b.id == "exit" then
                LoadScene(require("menus/main_menu"))
            elseif b.id == "map" then
                LoadScene(require("menus/button_map_menu"))
            elseif b.id == "sound" then
                musicOrSound = not musicOrSound
                Audio.setVolume(musicOrSound and 1 or 0)
            elseif b.id == "unlock" then
                Save.unlock(#Levels.order - 1)
                self.message = "All levels unlocked."
            elseif b.id == "reset" then
                Save.reset()
                self.message = "Save reset."
            end
            return
        end
    end
end

return options
