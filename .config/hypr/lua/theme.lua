-- rose-pine-moon colors
local	base          = "#232136"
local	surface       = "#2a273f"
local	overlay       = "#393552"
local	muted         = "#6e6a86"
local	subtle        = "#908caa"
local	text          = "#e0def4"
local	love          = "#eb6f92"
local	gold          = "#f6c177"
local	rose          = "#ea9a97"
local	pine          = "#3e8fb0"
local	foam          = "#9ccfd8"
local	iris          = "#c4a7e7"
local	highlightLow  = "#2a283e"
local	highlightMed  = "#44415a"
local	highlightHigh = "#56526e"


hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,
        border_size = 2,
        col = {
            active_border = { 
                colors = {
                    rose,
                    pine,
                    love,
                    iris
                }, 
                angle = 90 
            },
            inactive_border = muted,
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = false,
    },
})
