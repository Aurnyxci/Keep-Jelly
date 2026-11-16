local Save = {
    highestUnlocked = 0,
}

local SAVE_FILE = "save.dat"

local function writeSave()
    love.filesystem.write(SAVE_FILE, tostring(Save.highestUnlocked))
end

function Save.load()
    local contents = love.filesystem.read(SAVE_FILE)
    Save.highestUnlocked = math.max(0, math.floor(tonumber(contents) or 0))
end

function Save.isUnlocked(index)
    return index <= Save.highestUnlocked
end

function Save.unlock(index)
    if index > Save.highestUnlocked then
        Save.highestUnlocked = index
        writeSave()
    end
end

function Save.reset()
    Save.highestUnlocked = 0
    writeSave()
end

return Save
