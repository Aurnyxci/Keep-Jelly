local menu = {}

function menu:enter()
    particles:enter()

    self.titleFont = love.graphics.newFont(
        "assets/fonts/Exile-Regular.ttf",
        80
    )

    self.titleBackground = love.graphics.newImage("/assets/backgrounds/main_menu_placeholderbg.png")

    self.buttons = {
        {
            id = "play",
            text = "Play",
            tip = "Select a level to start",
            x = (screenWidth / 2) - 100,
            y = 300,
            w = 200,
            h = 50
        },
        {
            id = "options",
            text = "Options",
            tip = "Audio and preferences",
            x = (screenWidth / 2) - 100,
            y = 400,
            w = 200,
            h = 50
        },
        {
            id = "quit",
            text = "Quit",
            tip = "Close the game",
            x = (screenWidth / 2) - 100,
            y = 500,
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

function menu:draw()
    local bgw = love.graphics.getWidth() / self.titleBackground:getWidth()
    local bgh = love.graphics.getHeight() / self.titleBackground:getHeight()
    love.graphics.draw(self.titleBackground, 0, 0, 0, bgw, bgh)

    local y = 100 + math.sin(love.timer.getTime() * 2) * 15
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("KEEP JELLY", 0, y, screenWidth, "center")

    local hoverTip = nil

    for _, button in ipairs(self.buttons) do
        local hovered = isMouseOver(button)
        MenuButtonScale(button, hovered)

        local image = hovered and buttonPressed or buttonUnpressed
        BeginMenuButton(button)
        love.graphics.draw(image, 0, 0)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mainFont)
        love.graphics.printf(button.text, 0, 10, button.w, "center")
        EndMenuButton()

        if hovered and button.tip then
            hoverTip = button.tip
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mainFont)
    love.graphics.printf(hoverTip or "", 0, 680, screenWidth, "center")
end

function menu:mousepressed(x, y, button)
    if button ~= 1 then return end

    for _, b in ipairs(self.buttons) do
        if x > b.x and x < b.x + b.w
            and y > b.y and y < b.y + b.h then

            if b.id == "play" then
                LoadScene(require("menus/level_select"))
            elseif b.id == "options" then
                LoadScene(require("menus/options_menu"))
            elseif b.id == "quit" then
                love.event.quit()
            end
            return
        end
    end
end

return menu
