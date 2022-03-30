Gamestate = require "lib.hump.gamestate"
Class = require "lib.hump.class"

Slab = require "lib.slab"
SlabDebug = require "lib.slab.SlabDebug"

require "constants"
require "extensions"
Utils = require "utils"
Assets = require "assets"
Editor = require "editor"
RefSelect = require "refselect"
TextInput = require "textinput"

Tiles = {}
Tiles.Block = require "tiles.block"
Tiles.Wall = require "tiles.wall"
Tiles.Floor = require "tiles.floor"
Tiles.Ref = require "tiles.ref"

function love.load(args)
    Slab.Initialize(args)
    Slab.SetScrollSpeed(15)

    local style = Slab.GetStyle()
    style.API.LoadStyle("ui.style") -- or not i guess
    style.API.SetStyle("ui")

    Assets:load()
    Gamestate.registerEvents()

    local old_draw = love.draw
    function love.draw()
        old_draw()
        Slab.Draw()
    end

    Gamestate.switch(Editor)

    --[[Gamestate.switch({
        update = function(self, dt)
            Slab.BeginWindow('Basic Window', {Title = "Basic Window", ShowMinimize = false})

            Slab.Text("Hello World")
            Slab.Button("Button")

            Slab.EndWindow()

            if Slab.BeginMainMenuBar() then
                SlabDebug.Menu()
                Slab.EndMainMenuBar()
            end
            SlabDebug.Begin()
        end,
        draw = function(self)
            love.graphics.clear(0.7, 1, 1)
        end
    })]]
end

function love.update(dt)
    Slab.Update(dt)
end