Gamestate = require "lib.gamestate"
Class = require "lib.class"

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

function love.load()
    Assets:load()
    Gamestate.registerEvents()
    Gamestate.switch(Editor)
end