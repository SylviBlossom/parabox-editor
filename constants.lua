ROOT = nil -- the top block

COLOR_ROOT = 1
COLOR_ORANGE = 2
COLOR_BLUE = 3
COLOR_GREEN = 4
COLOR_TEAL = 5
COLOR_PLAYER = 6
COLORS = {
    "root",
    "orange",
    "blue",
    "green",
    "teal",
    "player",
}
PALETTES = {
    -- Palette 0
    {
        root   = {0   , 0  , 0.8},
        orange = {0.1 , 0.8, 1  },
        blue   = {0.6 , 0.8, 1  },
        player = {0.9 , 1  , 0.7},
        teal   = {0.55, 0.8, 1  },
        green  = {0.4 , 0.8, 1  },
    },
    -- Palette 1
    {
        root   = {0.05, 0.6 , 1.1},
        orange = {0.12, 0.6 , 1  },
        blue   = {0.63, 0.6 , 1  },
        player = {0.85, 0.53, 0.8},
        teal   = {0.55, 0.8 , 1  },
        green  = {0.32, 0.55, 1  },
    },
    -- Palette 2
    {
        root   = {0.6 , 0.3, 0.8 },
        orange = {0.55, 0.8, 0.85},
        blue   = {0.07, 0.7, 0.9 },
        player = {0.93, 0.7, 0.75},
        teal   = {0.55, 0.8, 1   },
        green  = {0.42, 0.8, 0.85},
    },
    -- Palette 3
    {
        root   = {0.68, 0.2, 0.6 },
        orange = {0.03, 0.7, 0.8 },
        blue   = {0.25, 0.7, 0.6 },
        player = {0.73, 0.7, 0.82},
        teal   = {0.55, 0.8, 1   },
        green  = {0.13, 0.7, 0.8 },
    },
    -- Palette 4
    {
        root   = {0   , 0.08, 0.7 },
        orange = {0.21, 0.7 , 0.8 },
        blue   = {0.6 , 0.55, 0.8 },
        player = {0.04, 0.8 , 0.85},
        teal   = {0.55, 0.8 , 1   },
        green  = {0.08, 0.75, 0.95},
    },
    -- Palette 5
    {
        root   = {0, 0, 0.5 },
        orange = {0, 0, 0.5 },
        blue   = {0, 0, 0.25},
        player = {0, 0, 0.5 },
        teal   = {0, 0, 0.5 },
        green  = {0, 0, 0.85},
    },
    -- Palette 6
    {
        root   = {0.6 , 0.6 , 0.8 },
        orange = {0.13, 0.75, 0.85},
        blue   = {0.55, 0.75, 0.7 },
        player = {0   , 0.7 , 0.7 },
        teal   = {0.55, 0.8 , 1   },
        green  = {0.45, 0.75, 0.75},
    },
    -- Palette 7
    {
        root   = {0.6 , 0.3 , 0.75},
        orange = {0.6 , 0.7 , 0.9 },
        blue   = {0.25, 0.83, 0.82},
        player = {0.96, 0.8 , 0.7 },
        teal   = {0.46, 0.7 , 0.8 },
        green  = {0.16, 1   , 0.75},
    },
    -- Palette 8
    {
        root   = {0.64, 0.6 , 0.85},
        orange = {0.45, 0.55, 0.8 },
        blue   = {0.68, 0.55, 0.9 },
        player = {0.85, 0.6 , 0.75},
        teal   = {0.58, 0.7 , 0.8 },
        green  = {0.95, 0.6 , 0.7 },
    },
    -- Palette 9
    {
        root   = {0.13, 0.15, 0.7 },
        orange = {0.5 , 0.7 , 0.8 },
        blue   = {0.92, 1   , 0.7 },
        player = {0.8 , 0.5 , 0.85},
        teal   = {0.09, 0.9 , 0.9 },
        green  = {0.22, 0.9 , 0.8 },
    },
    -- Palette 10
    {
        root   = {0.23, 0.6, 0.4},
        orange = {0.1 , 0.8, 0.8},
        blue   = {0.33, 0.6, 0.6},
        player = {0.62, 0.7, 0.8},
        teal   = {0.46, 0.7, 0.8},
        green  = {0.15, 0.8, 0.8},
    }
}

MUSIC_NAMES = {
    [0] = "Area_00_Intro",
    [1] = "Area_01_Enter",
    [2] = "Area_02_Empty",
    [3] = "Area_03_Eat",
    [4] = "Area_04_Reference",
    [5] = "Area_05_Center",
    [6] = "Area_06_Clone",
    [7] = "Area_07_Transfer",
    [8] = "Area_08_Open",
    [9] = "Area_09_Flip",
    [10] = "Area_10_Cycle",
    [11] = "Area_11_Swap",
    [12] = "Area_12_Player",
    [13] = "Area_13_Possess",
    [14] = "Area_14_Wall",
    [15] = "Area_15_InfiniteExit",
    [16] = "Area_16_InfiniteEnter",
    [17] = "Area_17_MultiInfinite",
    [18] = "Area_18_Reception",
    [19] = "Area_19_Appendix"
}
MAX_MUSIC = 4

LEVEL_VERSION = 4
PALETTE = 1
MUSIC = 0

SCALE = 100
PREVIEW_SIZE = 1024
SCREENSHOTTING = false