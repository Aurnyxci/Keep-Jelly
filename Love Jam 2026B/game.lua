local Game = {}

local tmx = require("libs.tmx")
local Levels = require("level")
local Save = require("save")
local Audio = require("audio")
local Clouds = require("clouds")

local DEFAULT_LEVEL = "maps/tmx/level_0.tmx"

local function levelFile(name)
    if not name then return DEFAULT_LEVEL end
    if name:find("%.tmx$") then return name end
    return "maps/tmx/" .. name .. ".tmx"
end

local BUCKET_WALL = 8
local EXIT_MARGIN = 8

local WIND_SPEED = 320
local WIND_DOTS = 3

local VACUUM_SPEED = 320
local VACUUM_DOTS = 3

local ITEM_THROW_SPEED = 640
local ITEM_THROW_DOTS = 16

-- We mainly use playerBody:setLinearVelocity() to change player's velocity
-- It is Love Engine's Box2D function of the linear velocity of a rigidbody object
local JUMP_VELOCITY = math.sqrt(2 * 900 * 67)

-- The jelly works like a spring pad, it only bounces the player when stepped on from above and it can still be pushed left/right
local ITEM_BOUNCE_SQUASH = 0.5
local ITEM_BOUNCE_SQUEEZE = 0.15
local ITEM_HEIGHT_VISUAL = 30
local ITEM_BOUNCE_VELOCITY = JUMP_VELOCITY * math.sqrt(4)

local player = {
    x = 320,
    y = 248,
    w = 64,
    h = 128,
    isOnGround = false,
    scaleX = 1,
    scaleY = 1,
    squash = 1,
    squashV = 0,
    sink = 0,
    lastMoveX = 0,
    facing = 1
}

local tray = {
    halfW = 64, 
    gap = 8, 
    offset = 0, 
    x = 336,
    y = 288,
    vx = 0, 
    vy = 0, 
    tilt = 0, 
    extend = 16
}

local items = {}
 
local world
local playerBody
local playerFixture
local trayBody
local trayFixture
local solids
local map
local currentLevel
local exits
local nextLevel
local isFinalLevel
local titleFont
local buttons
local blockers
local fans
local vacuums
local nearbyItem
local holdSerial = 0

-- The player is assembled from several layered sprites (body, legs, head)
local playerSprites
local itemSprite
-- Left and right arm sprites with their own shoulder(anchor)/hand positions
local armLSprite
local armRSprite
local ARM_L_ANCHOR_X, ARM_L_ANCHOR_Y = 37, 41
local ARM_L_HAND_X, ARM_L_HAND_Y = 14, 6
local ARM_R_ANCHOR_X, ARM_R_ANCHOR_Y = 2, 41
local ARM_R_HAND_X, ARM_R_HAND_Y = 27, 6
local traySprite

local function isGrounded()
    for _, contact in ipairs(world:getContacts()) do
        if contact:isTouching() then
            local fixtureA, fixtureB = contact:getFixtures()

            local otherFixture
            if fixtureA:getBody() == playerBody then
                otherFixture = fixtureB
            elseif fixtureB:getBody() == playerBody then
                otherFixture = fixtureA
            end
            local solid = otherFixture and solids[otherFixture]
            if solid and player.y + player.h <= solid.y + 6 then
                return true
            end
        end
    end
    return false
end

-- The player must be standing on top of the jelly (not just touching its sides)
local function isStandingOnItem(item)
    for _, contact in ipairs(world:getContacts()) do
        if contact:isTouching() then
            local fixtureA, fixtureB = contact:getFixtures()

            local otherFixture
            if fixtureA == playerFixture then
                otherFixture = fixtureB
            elseif fixtureB == playerFixture then
                otherFixture = fixtureA
            end

            if otherFixture == item.fixture then
                return player.y + player.h <= select(2, item.body:getPosition()) - 2
            end
        end
    end
    return false
end

-- The player is above the jelly (used for the launch, since the soft jelly can
-- physically pop the player off its surface during the compression).
-- The x range covers the whole body width, so standing on the jelly's edge still counts.
local function isOnItemTop(item)
    local itemX, itemY = item.body:getPosition()
    return math.abs(player.x + player.w * 0.5 - itemX) <= (item.w + player.w) * 0.5 - 8
        and player.y + player.h <= itemY - 2
        and player.y + player.h >= itemY - 40
end

-- Another jelly is above this one (position only: the soft contact can pop it up a
-- few pixels during the compression, which must not cancel the launch)
local function isItemAbove(bottom, top)
    local bottomX, bottomY = bottom.body:getPosition()
    local topX, topY = top.body:getPosition()
    return math.abs(topX - bottomX) <= (bottom.w + top.w) * 0.5 - 8
        and topY + top.h * 0.5 <= bottomY - 2
        and topY + top.h * 0.5 >= bottomY - 40
end

-- Another jelly resting on top of this one -> jellies can bounce each other too
local function isItemOnItemTop(bottom, top)
    if not isItemAbove(bottom, top) then return false end
    for _, contact in ipairs(world:getContacts()) do
        if contact:isTouching() then
            local a, b = contact:getFixtures()
            if (a == bottom.fixture and b == top.fixture)
                or (a == top.fixture and b == bottom.fixture) then
                return true
            end
        end
    end
    return false
end

local function holdItem(item)
    holdSerial = holdSerial + 1
    item.held = true
    item.holdOrder = holdSerial
    item.flying = false
    item.isBouncing = false
    item.bounceTarget = nil
    item.body:setLinearVelocity(0, 0)
    item.body:setAwake(true)
end

local function unholdItem(item)
    item.held = false
    -- the tray must not immediately grab a thrown or dropped jelly again
    item.trayCooldown = 0.25
end

-- the most recently picked jelly is on top and is the next one to leave
local function topHeldItem()
    local top
    for _, item in ipairs(items) do
        if item.held and (not top or item.holdOrder > top.holdOrder) then
            top = item
        end
    end
    return top
end

local function heldStackIndex(item)
    local index = 0
    for _, other in ipairs(items) do
        if other.held and other.holdOrder < item.holdOrder then
            index = index + 1
        end
    end
    return index
end

local function throwVelocity(item)
    local startX, startY = item.body:getPosition()
    local mouseX, mouseY = love.mouse.getPosition()
    local dx, dy = mouseX - startX, mouseY - startY
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then
        return player.facing * ITEM_THROW_SPEED, 0
    end
    return dx / length * ITEM_THROW_SPEED, dy / length * ITEM_THROW_SPEED
end

local function releaseHeldItems()
    for _, item in ipairs(items) do
        if item.held then
            unholdItem(item)
            item.flying = true
            -- keeps moving with the player and gets an extra push sideways
            item.body:setLinearVelocity(
                playerBody:getLinearVelocity() * 1.5,
                select(2, playerBody:getLinearVelocity())
            )
        end
    end
end

-- A blocker is a static rectangle that only exists while its button is released
local function newBlockerBody(blocker)
    local body = love.physics.newBody(world, blocker.x + blocker.w * 0.5, blocker.y + blocker.h * 0.5, "static")
    local fixture = love.physics.newFixture(body, love.physics.newRectangleShape(blocker.w, blocker.h))
    fixture:setFriction(1.5)
    -- a block counts as ground, so the player can jump while standing on it
    solids[fixture] = blocker
    blocker.fixture = fixture
    return body
end

-- A blocker is solid while no button holding it open is pressed
local function setBlockerOpen(blocker, open)
    if open and blocker.body then
        solids[blocker.fixture] = nil
        blocker.fixture = nil
        blocker.body:destroy()
        blocker.body = nil
    elseif not open and not blocker.body then
        blocker.body = newBlockerBody(blocker)
    end
end

local function updateButtons()
    for _, button in ipairs(buttons) do
        if not (button.trigger and button.pressed) then
            local pressed =
                player.x < button.x + button.w and player.x + player.w > button.x
                and player.y < button.y + button.h and player.y + player.h > button.y

            for _, item in ipairs(items) do
                local itemX, itemY = item.body:getPosition()
                if itemX + item.w * 0.5 > button.x and itemX - item.w * 0.5 < button.x + button.w
                    and itemY + item.h * 0.5 > button.y and itemY - item.h * 0.5 < button.y + button.h then
                    pressed = true
                    break
                end
            end

            if pressed ~= button.pressed then
                button.pressed = pressed
                if pressed then Audio.play("button") end
                for _, blocker in ipairs(button.blockers) do
                    blocker.held = blocker.held + (pressed and 1 or -1)
                    setBlockerOpen(blocker, blocker.held > 0)
                end
            end
        end
    end
end

-- Area of effect of a fan / vacuum. It is exactly the rectangle written in level.lua,
-- cut short by the first active blocker between the machine and the far end.
-- A fan blows away from its machine (near end of `dir`), a vacuum pulls toward its
-- machine (far end of `dir`), so `pull` tells from which end blockers are measured.
local function fieldRect(field, pull)
    local horizontal = field.dir == "left" or field.dir == "right"
    local lo, hi
    if horizontal then
        lo, hi = field.x, field.x + field.w
    else
        lo, hi = field.y, field.y + field.h
    end

    -- machine sits at the low end for "right"/"down"
    local machineAtLow = (field.dir == "right" or field.dir == "down") ~= pull

    for _, blocker in ipairs(blockers) do
        if blocker.body then
            local bLo, bHi
            if horizontal then
                if blocker.y < field.y + field.h and blocker.y + blocker.h > field.y then
                    bLo, bHi = blocker.x, blocker.x + blocker.w
                end
            else
                if blocker.x < field.x + field.w and blocker.x + blocker.w > field.x then
                    bLo, bHi = blocker.y, blocker.y + blocker.h
                end
            end

            if bLo then
                if machineAtLow then
                    if bLo > lo then hi = math.min(hi, bLo) end
                elseif bHi > lo and bHi < hi then
                    lo = math.max(lo, bHi)
                end
            end
        end
    end

    if horizontal then
        return lo, field.y, hi - lo, field.h
    end
    return field.x, lo, field.w, hi - lo
end

-- A fan blows every jelly inside its rectangle, even one resting on the tray
local function updateFans(dt)
    for _, fan in ipairs(fans) do
        local wx, wy, ww, wh = fieldRect(fan, false)
        local reach = (fan.dir == "left" or fan.dir == "right") and ww or wh

        for _, dot in ipairs(fan.dots) do
            dot.t = (dot.t + WIND_SPEED * dt / math.max(reach, 1)) % 1
        end

        if reach > 0 then
            for _, item in ipairs(items) do
                local itemX, itemY = item.body:getPosition()
                if itemX > wx and itemX < wx + ww
                    and itemY > wy and itemY < wy + wh then
                    -- a jelly on the tray is pushed off it, otherwise the tray keeps holding it
                    unholdItem(item)
                    item.flying = true
                    -- a short grace time, so the tray does not snap it back on the next frame
                    item.trayCooldown = 0.3

                    local itemVx, itemVy = item.body:getLinearVelocity()
                    if fan.dir == "left" then
                        itemVx = -WIND_SPEED
                    elseif fan.dir == "right" then
                        itemVx = WIND_SPEED
                    elseif fan.dir == "up" then
                        itemVy = -WIND_SPEED
                    else
                        itemVy = WIND_SPEED
                    end
                    item.body:setLinearVelocity(itemVx, itemVy)
                end
            end
        end
    end
end

-- A vacuum pulls jellies toward the machine at the end of its rectangle
local function updateVacuums(dt)
    for _, vacuum in ipairs(vacuums) do
        local vx, vy, vw, vh = fieldRect(vacuum, true)
        local reach = (vacuum.dir == "left" or vacuum.dir == "right") and vw or vh

        for _, dot in ipairs(vacuum.dots) do
            dot.t = (dot.t + VACUUM_SPEED * dt / math.max(reach, 1)) % 1
        end

        if reach > 0 then
            for _, item in ipairs(items) do
                local itemX, itemY = item.body:getPosition()
                if itemX > vx and itemX < vx + vw
                    and itemY > vy and itemY < vy + vh then
                    unholdItem(item)
                    item.flying = true
                    item.trayCooldown = 0.3

                    local itemVx, itemVy = item.body:getLinearVelocity()
                    if vacuum.dir == "left" then
                        itemVx = -VACUUM_SPEED
                    elseif vacuum.dir == "right" then
                        itemVx = VACUUM_SPEED
                    elseif vacuum.dir == "up" then
                        itemVy = -VACUUM_SPEED
                    else
                        itemVy = VACUUM_SPEED
                    end
                    item.body:setLinearVelocity(itemVx, itemVy)
                end
            end
        end
    end
end

-- Returns true when every exit of the level has enough jellies
local function collectItemsInExit()
    for index = #items, 1, -1 do
        local itemX, itemY = items[index].body:getPosition()
        for _, exit in ipairs(exits) do
            if itemX > exit.x - EXIT_MARGIN and itemX < exit.x + exit.w + EXIT_MARGIN
                and itemY > exit.y - EXIT_MARGIN and itemY < exit.y + exit.h + EXIT_MARGIN then
                items[index].body:destroy()
                if items[index] == nearbyItem then nearbyItem = nil end
                table.remove(items, index)
                exit.collected = exit.collected + 1
                Audio.play("collect")
                break
            end
        end
    end

    for _, exit in ipairs(exits) do
        if exit.collected < exit.required then return false end
    end
    return true
end

local function trayEnds()
    local dx = math.cos(tray.tilt) * tray.halfW
    local dy = math.sin(tray.tilt) * tray.halfW
    return tray.x - dx, tray.y + dy, tray.x + dx, tray.y - dy
end

local function drawArm(sprite, anchorX, anchorY, handX, handY, startX, startY, endX, endY)
    local dx = endX - startX
    local dy = endY - startY
    local armLength = math.sqrt((handX - anchorX) ^ 2 + (handY - anchorY) ^ 2)
    local stretch = math.sqrt(dx * dx + dy * dy) / armLength
    local width = 1 + (stretch - 1) * 0.2
    local handAngle = math.atan2(
        (handY - anchorY) * stretch,
        (handX - anchorX) * width
    )

    love.graphics.draw(sprite, startX, startY, math.atan2(dy, dx) - handAngle, width, stretch, anchorX, anchorY)
end

local function drawArms(offsetY)
    love.graphics.setColor(1, 1, 1)

    local leftX, leftY, rightX, rightY = trayEnds()
    leftY = leftY + offsetY
    rightY = rightY + offsetY

    local shoulderX = player.x + player.w * 0.5
    local shoulderY = player.y + player.h - 81 * player.scaleY + offsetY

    drawArm(armLSprite, ARM_L_ANCHOR_X, ARM_L_ANCHOR_Y, ARM_L_HAND_X, ARM_L_HAND_Y, shoulderX - 7 * player.scaleX, shoulderY, leftX, leftY)
    drawArm(armRSprite, ARM_R_ANCHOR_X, ARM_R_ANCHOR_Y, ARM_R_HAND_X, ARM_R_HAND_Y, shoulderX + 7 * player.scaleX, shoulderY, rightX, rightY)
end

function Game.enter(self, level)
    currentLevel = levelFile(level)
    map = tmx.load(currentLevel)

    Clouds.reset(map.width * map.tileWidth, map.height * map.tileHeight)

    local levelKey = map.path:match("([^/]+)%.tmx$")
    local config = Levels[levelKey] or {}
    isFinalLevel = levelKey == "level_win"

    items = {}
    holdSerial = 0
    for _, entry in ipairs(config.items or {}) do
        items[#items + 1] = {
            x = entry.x,
            y = entry.y,
            w = entry.w or 45,
            h = entry.h or 30,
        }
    end

    exits = {}
    for _, entry in ipairs(config.exits or {}) do
        exits[#exits + 1] = {
            x = entry.x,
            y = entry.y,
            w = entry.w,
            h = entry.h,
            required = entry.required,
            collected = 0,
        }
    end
    nextLevel = config.next and levelFile(config.next)

    player.x, player.y = config.spawn.x, config.spawn.y
    player.isOnGround = false
    player.sink = 0
    tray.offset, tray.vy = 0, 0
    tray.x, tray.vx = player.x + player.w * 0.5, 0
    tray.y = player.y - tray.gap
    tray.tilt = 0
    nearbyItem = nil

    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 900, true)

    playerBody = love.physics.newBody(world, player.x + player.w * 0.5, player.y + player.h * 0.5, "dynamic")
    playerBody:setFixedRotation(true)
    playerBody:setSleepingAllowed(false)

    playerFixture = love.physics.newFixture(playerBody, love.physics.newRectangleShape(player.w, player.h))
    playerFixture:setFriction(0)
    playerFixture:setGroupIndex(-1)

    solids = {}
    local function addSolid(rect)
        local body = love.physics.newBody(world, rect.x + rect.w * 0.5, rect.y + rect.h * 0.5, "static")
        local fixture = love.physics.newFixture(body, love.physics.newRectangleShape(rect.w, rect.h))
        fixture:setFriction(1.5)
        solids[fixture] = rect
    end

    for _, rect in ipairs(map.collision) do addSolid(rect) end


    buttons = {}
    blockers = {}

    -- A button can drive several blockers, and one blocker can be shared by several
    -- buttons (it opens while any of them is pressed), so blockers are created once
    local function shareBlocker(rect, trigger, color)
        for _, blocker in ipairs(blockers) do
            if blocker.x == rect.x and blocker.y == rect.y
                and blocker.w == rect.w and blocker.h == rect.h then
                return blocker
            end
        end
        local blocker = {
            x = rect.x,
            y = rect.y,
            w = rect.w,
            h = rect.h,
            trigger = trigger,
            color = color,
            held = 0,
        }
        blocker.body = newBlockerBody(blocker)
        blockers[#blockers + 1] = blocker
        return blocker
    end

    local function addButton(entry, trigger, defaultColor)
        local button = {
            x = entry.x,
            y = entry.y,
            w = entry.w,
            h = entry.h,
            trigger = trigger,
            color = entry.color or defaultColor,
            pressed = false,
            blockers = {},
        }
        for _, rect in ipairs(entry.blockers or { entry.blocker }) do
            button.blockers[#button.blockers + 1] = shareBlocker(rect, trigger, button.color)
        end
        buttons[#buttons + 1] = button
    end
    for _, entry in ipairs(config.buttons or {}) do addButton(entry, false, "green") end
    for _, entry in ipairs(config.triggers or {}) do addButton(entry, true, "white") end

    -- a button drives every door of its own colour
    for _, button in ipairs(buttons) do
        button.blockers = {}
        for _, blocker in ipairs(blockers) do
            if blocker.color == button.color then
                button.blockers[#button.blockers + 1] = blocker
            end
        end
    end

    -- the dots start at the upwind end
    fans = {}
    for _, entry in ipairs(config.fans or {}) do
        local fan = { x = entry.x, y = entry.y, w = entry.w, h = entry.h, dir = entry.dir, dots = {} }
        for index = 1, WIND_DOTS do
            fan.dots[index] = { t = (index - 1) / WIND_DOTS }
        end
        fans[#fans + 1] = fan
    end

    vacuums = {}
    for _, entry in ipairs(config.vacuums or {}) do
        local vacuum = { x = entry.x, y = entry.y, w = entry.w, h = entry.h, dir = entry.dir, dots = {} }
        for index = 1, VACUUM_DOTS do
            vacuum.dots[index] = { t = (index - 1) / VACUUM_DOTS }
        end
        vacuums[#vacuums + 1] = vacuum
    end

    -- collider matches the flat plate sprite
    trayBody = love.physics.newBody(world, tray.x, player.y - tray.gap, "kinematic")
    trayFixture = love.physics.newFixture(
        trayBody,
        love.physics.newRectangleShape(tray.halfW * 2, 8)
    )
    trayFixture:setFriction(1.5)
    trayFixture:setGroupIndex(-1)

    for _, item in ipairs(items) do
        item.body = love.physics.newBody(
            world,
            item.x + item.w * 0.5,
            item.y + item.h * 0.5,
            "dynamic"
        )
        -- keep the jelly upright, only slides instead of rolling
        item.body:setFixedRotation(true)
        item.fixture = love.physics.newFixture(
            item.body,
            -- trapezoid fitted to the jelly sprite -> wide bottom, narrower top
            love.physics.newPolygonShape(-18, 15, 18, 15, 13.5, -15, -13.5, -15)
        )
        item.fixture:setFriction(1.5)
        item.fixture:setRestitution(0.1)

        item.squash = 1
        item.squashV = 0
        item.lastVy = 0
        item.bounceTimer = 0
        item.bounceCooldown = 0
        item.isBouncing = false
        item.bounceTarget = nil
        item.held = false
        item.trayCooldown = 0
        item.flying = false
    end

    -- The layered images share the same 96x128 canvas, so drawing them in order works
    -- Arms are not drawn here, they are soft arms following the tray
    -- Loaded once and reused when switching levels
    if not playerSprites then
        playerSprites = {}
        for _, partName in ipairs({
            "1-body",
            "2-right_leg",
            "3-left_leg",
            "6-head"
        }) do
            table.insert(playerSprites, love.graphics.newImage("assets/sprites/layered/" .. partName .. ".png"))
        end

        armLSprite = love.graphics.newImage("assets/sprites/unique/armL_rev01.png")
        armRSprite = love.graphics.newImage("assets/sprites/unique/armR_rev01.png")

        traySprite = love.graphics.newImage("assets/sprites/unique/plate_rev01.png")

        itemSprite = love.graphics.newImage("assets/sprites/unique/7-jelly.png")
    end

    -- same font size as the main menu title
    if not titleFont then
        titleFont = love.graphics.newFont("assets/fonts/Exile-Regular.ttf", 80)
    end
end

function Game.update(self, dt)
    Clouds.update(dt)

    local speed = 320
    local moveX = 0
    if love.keyboard.isDown(ctrls[2].keybind) then
        moveX = moveX + speed
    end
    if love.keyboard.isDown(ctrls[1].keybind) then
        moveX = moveX - speed
    end

    if moveX ~= 0 then
        player.facing = moveX > 0 and 1 or -1
    end

    -- keep our horizontal velocity, and use engine's rigidbody physics velocity(for gravity)
    local _, currentVy = playerBody:getLinearVelocity()
    playerBody:setLinearVelocity(moveX, currentVy)

    -- soft body -> starting or stopping gives the body an impulse, then the spring wobbles it back to its normal shape
    if moveX ~= player.lastMoveX then
        player.squashV = player.squashV - (moveX - player.lastMoveX) * 0.008
        player.lastMoveX = moveX
    end

    player.squashV = player.squashV + ((1 - player.squash) * 300 - player.squashV * 12) * dt
    player.squash = player.squash + player.squashV * dt
    player.scaleX = 1 + (1 - player.squash) * 0.7
    player.scaleY = player.squash

    world:update(dt)

    -- player's box2D position is the center of the rectangle, but player's position is the top-left corner, convert it here
    local bodyX, bodyY = playerBody:getPosition()
    player.x = bodyX - player.w * 0.5
    player.y = bodyY - player.h * 0.5

    local grounded = isGrounded()
    if grounded and not player.isOnGround and currentVy > 100 then
        tray.vy = tray.vy + currentVy * 2
        player.squashV = player.squashV - math.min(currentVy, 480) * 0.01
    end
    player.isOnGround = grounded

    -- the slime walk loop runs while the player is walking on the ground
    Audio.setMoving(moveX ~= 0 and grounded)

    local playerCenterX = player.x + player.w * 0.5
    local playerCenterY = player.y + player.h * 0.5

    -- Horizontal spring makes the tray lag behind the player
    tray.vx = tray.vx + (-40 * (tray.x - playerCenterX) - 5 * tray.vx) * dt
    tray.x = tray.x + tray.vx * dt

    -- Soft vertical movement
    tray.vy = tray.vy + (-500 * tray.offset - 7 * tray.vy) * dt
    tray.offset = tray.offset + tray.vy * dt
    tray.y = player.y - tray.gap + tray.offset

    -- Slight tilt caused by the horizontal lag
    local targetTilt = math.max(-0.35, math.min(0.35, (playerCenterX - tray.x) * 0.006))
    tray.tilt = tray.tilt + (targetTilt - tray.tilt) * 10 * dt

    -- Move the tray with real velocities so collisions transfer momentum
    local trayBodyX, trayBodyY = trayBody:getPosition()
    trayBody:setLinearVelocity((tray.x - trayBodyX) / dt, (tray.y - trayBodyY) / dt)
    trayBody:setAngularVelocity((-tray.tilt - trayBody:getAngle()) / dt)

    -- Items soft body -> landings squash the jelly, then the spring wobbles it back
    for _, item in ipairs(items) do
        item.trayCooldown = math.max(0, item.trayCooldown - dt)

        local onGround = false
        local onTray = false
        for _, contact in ipairs(world:getContacts()) do
            if contact:isTouching() then
                local fixtureA, fixtureB = contact:getFixtures()

                local otherFixture
                if fixtureA == item.fixture then
                    otherFixture = fixtureB
                elseif fixtureB == item.fixture then
                    otherFixture = fixtureA
                end

                if solids[otherFixture] then
                    onGround = true
                    -- lower friction so a push makes the jelly slide a little before it stops
                    contact:setFriction(0.35)
                elseif otherFixture == trayFixture then
                    onTray = true
                end
            end
        end

        local itemVx, itemVy = item.body:getLinearVelocity()

        item.onGround = onGround

        if item.held then
            -- held jellies form a vertical stack above the tray center and follow its tilt
            local stack = heldStackIndex(item)
            local offset = 4 + item.h * 0.5 + stack * (item.h + 2)
            item.body:setPosition(
                tray.x - math.sin(tray.tilt) * offset,
                tray.y - math.cos(tray.tilt) * offset
            )
            item.body:setLinearVelocity(0, 0)
        elseif onTray and itemVy >= 0 and item.trayCooldown <= 0 then
            -- anything that comes to rest on the tray sticks to it
            holdItem(item)
        else
            -- keeps sliding on the ground, the tray slows it down faster.
            if onGround then item.flying = false end
            if not item.flying then
                local glide = 0.2
                if onTray then
                    glide = 2.5
                elseif onGround then
                    glide = 0.6
                end
                item.body:setLinearVelocity(itemVx * math.exp(-glide * dt), itemVy)
            end
        end

        local _, itemVy = item.body:getLinearVelocity()
        if item.lastVy > 40 and itemVy < item.lastVy then
            item.squashV = item.squashV - math.min(item.lastVy - itemVy, 480) * 0.01
        end
        item.lastVy = itemVy

        item.squashV = item.squashV + ((1 - item.squash) * 300 - item.squashV * 12) * dt
        item.squash = item.squash + item.squashV * dt

        -- The jelly is like a spring pad
        if item.bounceCooldown > 0 then
            item.bounceCooldown = item.bounceCooldown - dt
        end

        if item.isBouncing then
            item.bounceTimer = item.bounceTimer - dt
            -- squash the jelly down (squashV is parked so the spring does not fight it)
            item.squash = 1 - (1 - ITEM_BOUNCE_SQUASH)
                * (1 - math.max(item.bounceTimer, 0) / ITEM_BOUNCE_SQUEEZE)
            item.squashV = 0

            local target = item.bounceTarget
            if target == "player" then
                -- the player sinks with the compressed jelly
                player.sink = (1 - item.squash) * ITEM_HEIGHT_VISUAL
                -- keep them seated, otherwise the soft contact pops them off and the launch would be skipped
                if isOnItemTop(item) then
                    local playerVx, playerVy = playerBody:getLinearVelocity()
                    if playerVy < 0 then
                        playerBody:setLinearVelocity(playerVx, 0)
                    end
                end
            elseif target and isItemAbove(item, target) then
                -- the jelly on top sinks along with the one below it
                target.sink = (1 - item.squash) * ITEM_HEIGHT_VISUAL
                local targetVx, targetVy = target.body:getLinearVelocity()
                if targetVy < 0 then
                    target.body:setLinearVelocity(targetVx, 0)
                end
            end

            if item.bounceTimer <= 0 then
                item.isBouncing = false
                item.bounceCooldown = 0.4
                -- release the spring, so the jelly wobbles back up into a stretch
                item.squashV = 14

                if target == "player" then
                    player.sink = 0
                    if isOnItemTop(item) then
                        playerBody:setLinearVelocity(playerBody:getLinearVelocity(), -ITEM_BOUNCE_VELOCITY)
                        player.squashV = player.squashV + 2.5
                        releaseHeldItems()
                    end
                elseif target then
                    target.sink = 0
                    if isItemAbove(item, target) then
                        target.body:setLinearVelocity(target.body:getLinearVelocity(), -ITEM_BOUNCE_VELOCITY)
                        target.squashV = target.squashV + 4
                    end
                end
                item.bounceTarget = nil
            end
        elseif item.bounceCooldown <= 0 and onGround and not item.held then
            -- only a jelly resting on the ground can bounce the player or another jelly
            local target
            if isStandingOnItem(item) then
                target = "player"
            else
                for _, other in ipairs(items) do
                    if other ~= item and isItemOnItemTop(item, other) then
                        target = other
                        break
                    end
                end
            end

            if target then
                item.isBouncing = true
                item.bounceTimer = ITEM_BOUNCE_SQUEEZE
                item.bounceTarget = target
                Audio.play("jelly")

                if target == "player" then
                    -- the player's weight pushes the jelly down before the launch
                    player.squashV = player.squashV - 1.2
                end
            end
        end
    end

    nearbyItem = nil
    local closestDistance = 100*100
    for _, item in ipairs(items) do
        if item.onGround then
            local itemX, itemY = item.body:getPosition()
            local dx = itemX - playerCenterX
            local dy = itemY - playerCenterY
            local distance = dx * dx + dy * dy
            if distance < closestDistance then
                closestDistance = distance
                nearbyItem = item
            end
        end
    end 

    updateButtons()
    updateFans(dt)
    updateVacuums(dt)

    if collectItemsInExit() then
        local levelName = currentLevel:match("([^/]+)%.tmx$")
        for index, name in ipairs(Levels.order) do
            if name == levelName then
                Save.unlock(math.min(index, #Levels.order - 1))
                break
            end
        end

        if nextLevel then
            LoadScene(Game, nextLevel)
        else
            LoadScene(require("menus/level_select"), "All levels completed!")
        end
    end
end

function Game.keypressed(self, key)     
    if key == "r" then
        LoadScene(Game, currentLevel)
        return
    end

    if key == ctrls[3].keybind then
        if player.isOnGround then
            playerBody:setLinearVelocity(playerBody:getLinearVelocity(), -JUMP_VELOCITY)
            player.isOnGround = false
            tray.vy = tray.vy + 130
            -- stretches the body when jumping
            player.squashV = player.squashV + 2.5
            releaseHeldItems()
            Audio.play("jump")
        end
    end
    -- E picks up a nearby jelly, otherwise it puts the top held jelly on the ground ahead
    if key == ctrls[4].keybind then
        if nearbyItem then
            holdItem(nearbyItem)
        else
            local item = topHeldItem()
            if item then
                unholdItem(item)
                item.flying = false
                item.body:setPosition(
                    player.x + player.w * 0.5 + player.facing * (player.w * 0.5 + item.w * 0.5 + 8),
                    player.y + player.h - item.h * 0.5
                )
                item.body:setLinearVelocity(0, 0)
                item.body:setAwake(true)
            end
        end
    end
end

function Game.mousereleased(self, x, y, button)
    if button ~= 1 then return end

    tray.vy = tray.vy + 180

    local item = topHeldItem()
    if item then
        local vx, vy = throwVelocity(item)
        unholdItem(item)
        item.flying = true
        item.body:setLinearVelocity(vx, vy)
        item.body:setAwake(true)
    end
end

function Game.draw(self)
    love.graphics.clear(0.13, 0.84, 0.78)

    Clouds.draw()

    tmx.draw(map)

    for _, fan in ipairs(fans) do
        local wx, wy, ww, wh = fieldRect(fan, false)
        local reach = (fan.dir == "left" or fan.dir == "right") and ww or wh

        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.rectangle("fill", wx, wy, ww, wh)

        love.graphics.setColor(1, 1, 1, 0.75)
        for _, dot in ipairs(fan.dots) do
            local x, y = wx + ww * 0.5, wy + wh * 0.5
            if fan.dir == "left" then
                x = wx + reach * (1 - dot.t)
            elseif fan.dir == "right" then
                x = wx + reach * dot.t
            elseif fan.dir == "up" then
                y = wy + reach * (1 - dot.t)
            else
                y = wy + reach * dot.t
            end
            love.graphics.circle("fill", x, y, 3)
        end

        love.graphics.setColor(0.35, 0.35, 0.45)
        if fan.dir == "left" then
            love.graphics.rectangle("fill", fan.x + fan.w - 16, fan.y, 16, fan.h)
        elseif fan.dir == "right" then
            love.graphics.rectangle("fill", fan.x, fan.y, 16, fan.h)
        elseif fan.dir == "up" then
            love.graphics.rectangle("fill", fan.x, fan.y + fan.h - 16, fan.w, 16)
        else
            love.graphics.rectangle("fill", fan.x, fan.y, fan.w, 16)
        end
    end

    for _, vacuum in ipairs(vacuums) do
        local vx, vy, vw, vh = fieldRect(vacuum, true)

        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.rectangle("fill", vx, vy, vw, vh)

        love.graphics.setColor(1, 1, 1, 0.75)
        for _, dot in ipairs(vacuum.dots) do
            local x, y = vx, vy
            if vacuum.dir == "right" then
                x = vx + vw * dot.t
                y = vy + vh * 0.5
            elseif vacuum.dir == "left" then
                x = vx + vw * (1 - dot.t)
                y = vy + vh * 0.5
            elseif vacuum.dir == "down" then
                x = vx + vw * 0.5
                y = vy + vh * dot.t
            else
                x = vx + vw * 0.5
                y = vy + vh * (1 - dot.t)
            end
            love.graphics.circle("fill", x, y, 3)
        end

        love.graphics.setColor(0.35, 0.35, 0.45)
        if vacuum.dir == "left" then
            love.graphics.rectangle("fill", vacuum.x, vacuum.y, 16, vacuum.h)
        elseif vacuum.dir == "right" then
            love.graphics.rectangle("fill", vacuum.x + vacuum.w - 16, vacuum.y, 16, vacuum.h)
        elseif vacuum.dir == "up" then
            love.graphics.rectangle("fill", vacuum.x, vacuum.y, vacuum.w, 16)
        else
            love.graphics.rectangle("fill", vacuum.x, vacuum.y + vacuum.h - 16, vacuum.w, 16)
        end
    end

    for _, button in ipairs(buttons) do
        if button.color == "white" then
            love.graphics.setColor(0.95, 0.95, 0.9, button.pressed and 0.4 or 1)
        elseif button.color == "yellow" then
            love.graphics.setColor(0.95, 0.8, 0.2, button.pressed and 0.4 or 1)
        else
            love.graphics.setColor(0.2, 0.95, 0.4, button.pressed and 0.4 or 1)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
    end

    for _, blocker in ipairs(blockers) do
        if blocker.body then
            if blocker.color == "white" then
                love.graphics.setColor(0.85, 0.85, 0.8, 0.75)
            elseif blocker.color == "yellow" then
                love.graphics.setColor(0.9, 0.72, 0.15, 0.75)
            else
                love.graphics.setColor(0.15, 0.75, 0.3, 0.75)
            end
            love.graphics.rectangle("fill", blocker.x, blocker.y, blocker.w, blocker.h)
        end
    end

    for _, exit in ipairs(exits) do
        love.graphics.setColor(0.45, 0.30, 0.18)
        love.graphics.rectangle("fill", exit.x, exit.y, BUCKET_WALL, exit.h)
        love.graphics.rectangle("fill", exit.x + exit.w - BUCKET_WALL, exit.y, BUCKET_WALL, exit.h)
        love.graphics.rectangle("fill", exit.x, exit.y + exit.h - BUCKET_WALL, exit.w, BUCKET_WALL)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mainFont)
        local text = exit.collected .. "/" .. exit.required
        local textWidth = love.graphics.getFont():getWidth(text) * 2
        love.graphics.print(text, exit.x + (exit.w - textWidth) * 0.5, exit.y - 64, 0, 2, 2)
    end


    local item = love.mouse.isDown(1) and topHeldItem()
    if item then
        local startX, startY = item.body:getPosition()
        local vx, vy = throwVelocity(item)
        for index = 1, ITEM_THROW_DOTS do
            local t = index * 0.08
            local x = startX + vx * t
            local y = startY + vy * t + 0.5 * 900 * t * t
            love.graphics.setColor(1, 1, 1, 1 - index / (ITEM_THROW_DOTS + 1))
            love.graphics.circle("fill", x, y, 3)
        end
    end

    love.graphics.setColor(1, 1, 1)
    local s = (tray.halfW * 2 + tray.extend * 2) / traySprite:getWidth()
    love.graphics.draw(traySprite, tray.x, tray.y + player.sink, -tray.tilt, s, s, traySprite:getWidth() * 0.5, traySprite:getHeight() * 0.5)

    drawArms(player.sink)

    for _, sprite in ipairs(playerSprites) do
        love.graphics.draw(sprite, player.x + player.w * 0.5, player.y + player.h + player.sink, 0, player.scaleX * player.facing, player.scaleY, 31, 128)
    end

    for _, item in ipairs(items) do
        local itemX, itemY = item.body:getPosition()
        love.graphics.push()
        love.graphics.translate(itemX, itemY)
        if item.held then
            love.graphics.rotate(-tray.tilt)
        end
        -- scale around the sprite's bottom, keep the jelly stays on the ground
        love.graphics.draw(itemSprite, 0, 15, 0, 1.5 * (1 + (1 - item.squash) * 0.7), 1.5 * item.squash, itemSprite:getWidth() * 0.5, itemSprite:getHeight())
        if item == nearbyItem then
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", -item.w * 0.5 - 2, -item.h * 0.5 - 2, item.w + 4, item.h + 4)
        end
        love.graphics.pop()
    end

    if isFinalLevel then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.printf(
            "Thanks For Playing!",
            0,
            100 + math.sin(love.timer.getTime() * 2) * 15,
            screenWidth,
            "center"
        )
    end
end

return Game
