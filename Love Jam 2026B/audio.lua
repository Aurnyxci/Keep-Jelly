local Audio = {}

local MUSIC_PATH = "assets/audio/JellyMusic.mp3"

-- One shot sounds. Every sound keeps a few voices, so the same sound can
-- overlap itself (several jellies bouncing at once) without cutting off.
local SFX = {
    button = { path = "assets/audio/sfx/button.wav", voices = 2, volume = 0.7 },
    collect = { path = "assets/audio/sfx/collcect.wav", voices = 2, volume = 0.8 },
    jelly = { path = "assets/audio/sfx/jelly.wav", voices = 4, volume = 0.7 },
    jump = { path = "assets/audio/sfx/jump.wav", voices = 3, volume = 0.7 },
}

local MOVE_PATH = "assets/audio/sfx/slimeMove.wav"
local MOVE_VOLUME = 0.45

local music
local voices = {}
local nextVoice = {}
local moveSource

local function newStaticSource(path, volume)
    if not love.filesystem.getInfo(path) then return nil end
    local source = love.audio.newSource(path, "static")
    source:setVolume(volume)
    return source
end

function Audio.load()
    if love.filesystem.getInfo(MUSIC_PATH) then
        music = love.audio.newSource(MUSIC_PATH, "stream")
        music:setLooping(true)
        music:play()
    end

    for name, sound in pairs(SFX) do
        local list = {}
        for _ = 1, sound.voices do
            local source = newStaticSource(sound.path, sound.volume)
            if source then list[#list + 1] = source end
        end
        voices[name] = list
        nextVoice[name] = 1
    end

    moveSource = newStaticSource(MOVE_PATH, MOVE_VOLUME)
    if moveSource then moveSource:setLooping(true) end
end

-- Plays a one shot sound, voices are used in a round robin order
function Audio.play(name)
    local list = voices[name]
    if not list or #list == 0 then return end

    local index = nextVoice[name]
    nextVoice[name] = index % #list + 1

    local source = list[index]
    source:stop()
    source:play()
end

function Audio.setMoving(moving)
    if not moveSource then return end
    if moving then
        if not moveSource:isPlaying() then moveSource:play() end
    elseif moveSource:isPlaying() then
        moveSource:stop()
    end
end

function Audio.stopMovement()
    if moveSource and moveSource:isPlaying() then
        moveSource:stop()
    end
end

function Audio.setVolume(v)
    love.audio.setVolume(v)
end

return Audio
