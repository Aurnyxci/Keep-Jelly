local Clouds = {}

local SPRITE_COUNT = 5
local MIN_CLOUDS, MAX_CLOUDS = 4, 6
local MIN_SCALE, MAX_SCALE = 0.3, 0.55
local GAP = 48
local INSET = 64
local PLACEMENT_TRIES = 300
local ALPHA = 0.9

local sprites
local clouds = {}
local time = 0

local function loadSprites()
    if sprites then return end
    sprites = {}
    for index = 0, SPRITE_COUNT - 1 do
        sprites[#sprites + 1] =
            love.graphics.newImage("assets/sprites/unique/Cloud_" .. index .. ".png")
    end
end

local function overlaps(x, y, w, h)
    for _, cloud in ipairs(clouds) do
        if x < cloud.x + cloud.w + GAP and x + w + GAP > cloud.x
            and y < cloud.y + cloud.h + GAP and y + h + GAP > cloud.y then
            return true
        end
    end
    return false
end

local function spawn(width, height)
    local count = love.math.random(MIN_CLOUDS, MAX_CLOUDS)

    for _ = 1, PLACEMENT_TRIES do
        if #clouds >= count then break end

        local image = sprites[love.math.random(#sprites)]
        local imageWidth, imageHeight = image:getDimensions()
        local scale = MIN_SCALE + love.math.random() * (MAX_SCALE - MIN_SCALE)
        local w, h = imageWidth * scale, imageHeight * scale

        local x = INSET + love.math.random() * math.max(0, width - w - INSET * 2)
        local y = INSET + love.math.random() * math.max(0, height - h - INSET * 2)

        if not overlaps(x, y, w, h) then
            clouds[#clouds + 1] = {
                image = image,
                x = x,
                y = y,
                w = w,
                h = h,
                scale = scale,
                facing = love.math.random() < 0.5 and -1 or 1,
                ax = 8 + love.math.random() * 8,
                ay = 4 + love.math.random() * 6,
                periodX = 5 + love.math.random() * 4,
                periodY = 4 + love.math.random() * 4,
                phaseX = love.math.random() * math.pi * 2,
                phaseY = love.math.random() * math.pi * 2,
            }
        end
    end
end

function Clouds.reset(width, height)
    loadSprites()
    clouds = {}
    time = 0
    spawn(width, height)
end

function Clouds.update(dt)
    time = time + dt
end

function Clouds.draw()
    for _, cloud in ipairs(clouds) do
        local x = cloud.x + math.sin(time / cloud.periodX * math.pi * 2 + cloud.phaseX) * cloud.ax
        local y = cloud.y + math.sin(time / cloud.periodY * math.pi * 2 + cloud.phaseY) * cloud.ay

        -- a mirrored cloud is drawn to the left of `x`, keep the anchor on the box
        if cloud.facing < 0 then x = x + cloud.w end

        love.graphics.setColor(1, 1, 1, ALPHA)
        love.graphics.draw(cloud.image, x, y, 0, cloud.scale * cloud.facing, cloud.scale)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Clouds
