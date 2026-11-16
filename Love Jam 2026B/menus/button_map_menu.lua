local menu = {}

function menu:enter()
    self.titleBackground = love.graphics.newImage("/assets/backgrounds/main_menu_placeholderbg.png")
    self.titleFont = love.graphics.newFont("assets/fonts/Exile-Regular.ttf", 80)

    self.buttons = {
        {
            id = "exit",
            text = "Back",
            tip = "Return to options",
            x = (screenWidth / 2) - 100,
            y = 650,
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

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Controls", 0, 40, screenWidth, "center")

    local hoverTip = nil

    for _, button in ipairs(self.buttons) do
        local hover = isMouseOver(button)
        local image = hover and buttonPressed or buttonUnpressed

        MenuButtonScale(button, hover)
        BeginMenuButton(button)
        love.graphics.draw(image, 0, 0)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mainFont)
        love.graphics.printf(button.text, 0, 10, button.w, "center")
        EndMenuButton()

        if hover and button.tip then
            hoverTip = button.tip
        end
    end

    local listW = 520
    local listX = (screenWidth - listW) / 2
    local lineH = 46
    local startY = 150

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mainFont)

    for i, c in ipairs(ctrls) do
        local y = startY + (i - 1) * lineH
        love.graphics.print(c.action, listX, y)
        love.graphics.printf(string.upper(c.keybind), listX, y, listW, "right")
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

            if b.id == "exit" then
                LoadScene(require("menus/options_menu"))
            end
            return
        end
    end
end

return menu
