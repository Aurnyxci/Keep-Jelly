-- Per level setup. The map only provides tiles, everything else is set here.
local Levels = {}

Levels.level_0 = {
    spawn = { x = 320, y = 536 },

    items = {
        { x = 800, y = 640 },
    },

    -- every exit has to reach its required count to finish the level
    exits = {
        {
            x = 1000,
            y = 576,
            w = 128,
            h = 96,
            required = 1,
        },
    },

    -- next level to load after the exit is filled (nil = stay on this level)
    next = "level_1",
}

Levels.level_1 = {
    spawn = { x = 176, y = 536 },

    items = {
        { x = 678, y = 640 },
    },

    -- behind the pillar, the jelly has to be thrown over it
    exits = {
        {
            x = 1048,
            y = 576,
            w = 120,
            h = 96,
            required = 1,
        },
    },

    next = "level_2",
}

Levels.level_2 = {
    spawn = { x = 352, y = 544 },

    items = {
        -- left of the door, use it to keep the button pressed
        { x = 704, y = 642 },
        -- locked behind the blocker
        { x = 1015, y = 642 },
    },

    exits = {
        {
            x = 96,
            y = 544,
            w = 112,
            h = 128,
            required = 2,
        },
    },

    -- pressing the button removes its blocker, so something has to hold it down
    buttons = {
        {
            x = 528,
            y = 656,
            w = 104,
            h = 16,
            blocker = {
                x = 800,
                y = 480,
                w = 64,
                h = 192, 
            },
        },
    },

    next = "level_3",
}

Levels.level_3 = {
    spawn = { x = 160, y = 544 },

    items = {
        -- top-left of the jelly, on the ground
        { x = 327, y = 642 },
    },

    exits = {
        {
            x = 1024,
            y = 576,
            w = 128,
            h = 96,
            required = 1,
        },
    },

    -- blows left, its right end sits against the wall
    fans = {
        {
            x = 672,
            y = 384,
            w = 544,
            h = 96,
            dir = "left",
        },
    },

    next = "level_4",
}

Levels.level_4 = {
    spawn = { x = 456, y = 544 },

    items = {
        -- on the upper left platform
        { x = 244, y = 194 },
        -- on the right platform
        { x = 978, y = 386 },
        -- on the ground
        { x = 982, y = 642 },
    },

    exits = {
        {
            x = 128,
            y = 576,
            w = 120,
            h = 96,
            required = 3,
        },
    },
}

return Levels
