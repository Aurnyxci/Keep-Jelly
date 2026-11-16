local Levels = {}

Levels.level_0 = {
    spawn = { x = 320, y = 536 },

    items = {
        { x = 800, y = 640 },
    },

    exits = {
        {
            x = 1000,
            y = 576,
            w = 128,
            h = 96,
            required = 1,
        },
    },

    next = "level_1",
}

Levels.level_1 = {
    spawn = { x = 176, y = 536 },

    items = {
        { x = 678, y = 640 },
    },

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
        { x = 704, y = 642 },
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

    fans = {
        {
            x = 736,
            y = 448,
            w = 480,
            h = 128,
            dir = "left",
        },
    },

    next = "level_4",
}

Levels.level_4 = {
    spawn = { x = 456, y = 544 },

    items = {
        { x = 244, y = 194 },
        { x = 978, y = 386 },
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

    next = "level_5",
}

Levels.level_5 = {
    spawn = { x = 384, y = 544 },

    items = {
        { x = 682, y = 642 },
    },

    exits = {
        {
            x = 1024,
            y = 608,
            w = 128,
            h = 64,
            required = 1,
        },
    },

    triggers = {
        {
            x = 160,
            y = 384,
            w = 128,
            h = 32,
            blocker = {
                x = 800,
                y = 480,
                w = 64,
                h = 192,
            },
        },
    },

    next = "level_6",
}

Levels.level_6 = {
    spawn = { x = 416, y = 544 },

    items = {
        { x = 554, y = 642 },
    },

    exits = {
        {
            x = 992,
            y = 608,
            w = 128,
            h = 64,
            required = 1,
        },
    },

    buttons = {
        {
            x = 224,
            y = 640,
            w = 128,
            h = 32,
            blocker = {
                x = 800,
                y = 608,
                w = 64,
                h = 64,
            },
        },
    },

    vacuums = {
        {
            x = 800,
            y = 608,
            w = 416,
            h = 64,
            dir = "right",
        },
    },

    next = "level_7",
}

Levels.level_7 = {
    spawn = { x = 64, y = 144 },

    items = {
        { x = 528, y = 352 },
        { x = 720, y = 352 },
    },

    exits = {
        {
            x = 1056,
            y = 608,
            w = 128,
            h = 64,
            required = 2,
        },
    },

    buttons = {
        {
            x = 1056,
            y = 64,
            w = 128,
            h = 32,
            blocker = {
                x = 320,
                y = 368,
                w = 192,
                h = 32,
            },
        },
    },

    triggers = {
        {
            x = 320,
            y = 640,
            w = 128,
            h = 32,
            blocker = {
                x = 1024,
                y = 368,
                w = 192,
                h = 32,
            },
        },
    },

    next = "level_9",
}


Levels.level_9 = {
    spawn = { x = 96, y = 544 },

    items = {
        { x = 618, y = 82 },
    },

    exits = {
        {
            x = 576,
            y = 576,
            w = 128,
            h = 96,
            required = 1,
        },
    },

    buttons = {
        {
            x = 176,
            y = 640,
            w = 112,
            h = 32,
            color = "green",
            blockers = {
                { x = 128, y = 64, w = 64, h = 384 },
            },
        },
        {
            x = 1040,
            y = 640,
            w = 112,
            h = 32,
            color = "yellow",
            blockers = {
                { x = 1088, y = 64, w = 64, h = 384 },
            },
        },
    },

    fans = {
        { x = 64, y = 64, w = 1152, h = 64, dir = "left" },
        { x = 64, y = 64, w = 1216, h = 64, dir = "right" },
        { x = 64, y = 192, w = 1152, h = 64, dir = "left" },
        { x = 64, y = 192, w = 1216, h = 64, dir = "right" },
        { x = 64, y = 320, w = 1152, h = 64, dir = "left" },
        { x = 64, y = 320, w = 1216, h = 64, dir = "right" },
    },

    next = "level_10",
}


Levels.level_10 = {
    spawn = { x = 608, y = 544 },

    items = {
        { x = 96, y = 96 },
        { x = 1120, y = 280 },
    },

    exits = {
        {
            x = 1088,
            y = 576,
            w = 128,
            h = 96,
            required = 2,
        },
    },

    buttons = {
        {
            x = 96,
            y = 640,
            w = 112,
            h = 32,
            color = "yellow",
            blockers = {
                { x = 1056, y = 192, w = 64, h = 32 },
            },
        },
        {
            x = 352,
            y = 640,
            w = 112,
            h = 32,
            color = "green",
            blockers = {
                { x = 64, y = 384, w = 64, h = 64 },
                { x = 896, y = 64, w = 64, h = 128 },
            },
        },
    },

    fans = {
        { x = 64, y = 64, w = 1152, h = 128, dir = "right" },
        { x = 128, y = 256, w = 1088, h = 128, dir = "left" },
    },

    next = "level_win",
}

Levels.level_win = {
    spawn = { x = 296, y = 544 },

    items = {
        { x = 96, y = 642 },
        { x = 160, y = 642 },
        { x = 224, y = 642 },
        { x = 390, y = 610 },
        { x = 428, y = 610 },
        { x = 466, y = 610 },
        { x = 778, y = 610 },
        { x = 816, y = 610 },
        { x = 854, y = 610 },
        { x = 1010, y = 642 },
    },

    exits = {
        {
            x = 1088,
            y = 576,
            w = 128,
            h = 96,
            required = 10,
        },
    },

    buttons = {
        {
            x = 528,
            y = 640,
            w = 112,
            h = 32,
            color = "green",
            blockers = {
                { x = 640, y = 352, w = 32, h = 160 },
            },
        },
        {
            x = 656,
            y = 640,
            w = 112,
            h = 32,
            color = "yellow",
            blockers = {
                { x = 1024, y = 352, w = 32, h = 160 },
            },
        },
    },

    fans = {
        { x = 64, y = 512, w = 320, h = 160, dir = "right" },
        { x = 480, y = 64, w = 256, h = 320, dir = "down" },
    },

    vacuums = {
        { x = 768, y = 512, w = 288, h = 160, dir = "left" },
    },
}


Levels.order = {
    "level_0",
    "level_1",
    "level_2",
    "level_3",
    "level_4",
    "level_5",
    "level_6",
    "level_7",
    "level_9",
    "level_10",
}

return Levels
