local cursor = {}

local NODE_COUNT = 16
local RADIUS = 12
local STEP = 1 / 60
local DAMPING = 0.80
local PULL = 0.18
local DRAG = 0.7
local ITERATIONS = 8
local SEGMENT = 2 * RADIUS * math.sin(math.pi / NODE_COUNT)

local nodes = {}
local accumulator = 0
local lastX, lastY = 0, 0

local function step()
    local mx, my = love.mouse.getPosition()
    local dirX, dirY = mx - lastX, my - lastY
    lastX, lastY = mx, my

    local length = math.sqrt(dirX * dirX + dirY * dirY)
    if length > 0 then
        dirX, dirY = dirX / length, dirY / length
    end

    for _, node in ipairs(nodes) do
        -- Verlet integration
        local vx = (node.x - node.px) * DAMPING
        local vy = (node.y - node.py) * DAMPING
        node.px, node.py = node.x, node.y
        node.x, node.y = node.x + vx, node.y + vy

        -- The trailing side is pulled less, so the body stretches while dragged
        local pull = PULL * (1 + DRAG * (node.offsetX * dirX + node.offsetY * dirY) / RADIUS)
        node.x = node.x + (mx + node.offsetX - node.x) * pull
        node.y = node.y + (my + node.offsetY - node.y) * pull
    end

    -- Keep the perimeter, the ring bends but never breaks
    for _ = 1, ITERATIONS do
        for i = 1, NODE_COUNT do
            local a = nodes[i]
            local b = nodes[i % NODE_COUNT + 1]
            local dx, dy = b.x - a.x, b.y - a.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > 0 then
                local fix = (dist - SEGMENT) / dist * 0.5
                a.x, a.y = a.x + dx * fix, a.y + dy * fix
                b.x, b.y = b.x - dx * fix, b.y - dy * fix
            end
        end
    end
end

function cursor:enter()
    nodes = {}
    accumulator = 0

    local mx, my = love.mouse.getPosition()
    lastX, lastY = mx, my

    for i = 1, NODE_COUNT do
        local angle = (i - 1) / NODE_COUNT * math.pi * 2
        local offsetX = math.cos(angle) * RADIUS
        local offsetY = math.sin(angle) * RADIUS

        nodes[i] = {
            x = mx + offsetX,
            y = my + offsetY,
            px = mx + offsetX,
            py = my + offsetY,
            offsetX = offsetX,
            offsetY = offsetY,
        }
    end
end

function cursor:update(dt)
    accumulator = math.min(accumulator + dt, STEP * 5)
    while accumulator >= STEP do
        accumulator = accumulator - STEP
        step()
    end
end

function cursor:draw()
    local vertices = {}
    for i, node in ipairs(nodes) do
        vertices[i * 2 - 1] = node.x
        vertices[i * 2] = node.y
    end

    love.graphics.setColor(0.35, 0.76, 0.21)
    love.graphics.polygon("fill", vertices)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", vertices)
end

return cursor
