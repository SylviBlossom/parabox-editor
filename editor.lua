local Editor = {}

function Editor:init()
    self:reset()
    self.current_tool = 1
    self.mode = nil
    self.mx, self.my = 0, 0
    self.next_key = 1
    self.placed = {}

    self.settings_open = false
    self.settings_target = nil
    self.settings_pos = {0, 0}
    self.settings_pos_adjusted = false

    self.file_dialog = nil
    self.default_folder_path = self:getLevelsPath()
    print("Found default path: "..self.default_folder_path)

    self.music_popup = 0
    self.music_font = love.graphics.newFont(20)

    self.save_icon = false

    self.preview_canvas = love.graphics.newCanvas(SCALE, SCALE)
end

function Editor:reset()
    PALETTE = 1
    MUSIC = 0
    self.level_path = nil
    self.next_key = 1
    ROOT = Tiles.Block(-1, -1, 7, 7, nil, {color_index = COLOR_ROOT}) -- create a new root block
    ROOT.key = 0
    self:setBlock(ROOT) -- set the current editor block to the root block
    self.blocks = {ROOT}
end

function Editor:setBlock(block)
    self.block = block

    -- reset the tools to be parented to the current block
    self.tools = {
        Tiles.Wall(0, 0, self.block),
        Tiles.Block(0, 0, 5, 5, self.block),
        Tiles.Ref(0, 0, self.block, self.block),
        Tiles.Block(0, 0, 5, 5, self.block, {player = true, possessable = true}),
        Tiles.Floor(0, 0, self.block, "PlayerButton"),
        Tiles.Floor(0, 0, self.block, "Button")
    }
end

function Editor:inBounds(x, y)
    return x >= 0 and y >= 0 and x < self.block.width and y < self.block.height
end

function Editor:isUIOpen()
    return self.settings_open or self.file_dialog ~= nil
end

function Editor:update(dt)
    local transform = self:getTransform()
    self.mx, self.my = transform:inverseTransformPoint(love.mouse.getPosition())
    self.mx = math.floor(self.mx/SCALE)
    self.my = math.floor(self.my/SCALE)

    if self.file_dialog then
        self.mode = nil

        local dir = self.default_folder_path
        if dir:sub(-1, -1) == "/" then
            dir = dir:sub(1, -2)
        end

        local result = Slab.FileDialog({
            Type = self.file_dialog == "save" and "savefile" or "openfile",
            Directory = dir,
            Filters = {
                {"*.txt","Text Files"},
                {"*.*","All Files"}
            },
            AllowMultiSelect = false
        })

        if result.Button ~= "" then
            if result.Button == "OK" then
                local file = result.Files[1]
                self.default_folder_path = Utils.getPath(file)
                if self.file_dialog == "save" then
                    self.level_path = file
                    self:saveLevel()
                elseif self.file_dialog == "open" then
                    self:openLevel(file)
                end
            end
            self.file_dialog = nil
        end
    elseif self.settings_open then
        self.mode = nil

        if not self.settings_target then
            self.settings_open = false
        end

        local target_name = self.settings_target.type
        if self.settings_target.type == "Block" then
            target_name = target_name.." ["..tostring(self.settings_target.key).."]"
        end
        local opts = {Title = "Editing "..target_name, ShowMinimize = false, ConstrainPosition = true, X = self.settings_pos[1], Y = self.settings_pos[2]}
        if not self.settings_pos_adjusted then
            self.settings_pos_adjusted = true
            opts.ResetPosition = true
        end
        if Slab.BeginWindow("TileSettings", opts) then
            self.settings_target:openSettings()
            Slab.EndWindow()
        end
    else
        self.settings_pos_adjusted = false

        if self.mode == "place" and not love.mouse.isDown(1) then
            self.mode = nil
        elseif self.mode == "erase" and not love.mouse.isDown(2) then
            self.mode = nil
        end

        if self.mode == "place" then
            if not self.placed[self.mx..","..self.my] then
                if self:inBounds(self.mx, self.my) then
                    self.block:setTile(self.mx, self.my, self.tools[self.current_tool]:place(self.mx, self.my))
                end
                self.placed[self.mx..","..self.my] = true
            end
        elseif self.mode == "erase" then
            if self:inBounds(self.mx, self.my) then
                self.block:setTile(self.mx, self.my, nil)
            end
        end
    end

    self.music_popup = math.max(self.music_popup - dt, 0)
end

function Editor:mousepressed(x, y, btn)
    if self.settings_open then
        if Slab.IsVoidHovered() then
            self.settings_open = false
            self.settings_target = nil
        end
        return
    end
    if self.file_dialog then
        return
    end
    if btn == 1 then
        local tile = self.block:getTile(self.mx, self.my)
        if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
            if tile then
                self.settings_open = true
                self.settings_target = tile
                self.settings_pos = {love.mouse.getPosition()}
            end
            return
        end
        if tile and tile.type == "Block" then
            self:setBlock(tile)
        elseif tile and tile.type == "Ref" then
            self:openRefSelect(tile.ref, function(selected, exit)
                if tile.exit and tile.ref.exit_block == tile then
                    tile.ref.exit_block = nil
                end
                tile.exit = exit
                if exit then
                    selected.exit_block = tile
                end
                tile.ref = selected
            end)
        else
            self.mode = "place"
        end
    elseif btn == 2 then
        self.mode = "erase"
    end
end

function Editor:openRefSelect(selected, callback)
    local ref_blocks = {}
    for _,block in ipairs(self.blocks) do
        if not block.filled or block == ROOT then
            table.insert(ref_blocks, block)
        end
    end
    Gamestate.switch(RefSelect, selected, ref_blocks, callback)
end

function Editor:getBlockByKey(key)
    for _,block in ipairs(self.blocks) do
        if block.key == key then
            return block
        end
    end
end

function Editor:mousereleased(x, y, btn)
    self.placed = {}
    self.mode = nil
end

function Editor:keypressed(key)
    if self.settings_open then
        if love.keyboard.isDown("escape") then
            self.settings_open = false
            self.settings_target = nil
        end
        return
    end
    if self.file_dialog then
        return
    end
    if key == "=" then
        if love.keyboard.isDown("w") or love.keyboard.isDown("s") then
            self.block:resize(self.block.width, self.block.height + 1)
        elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
            self.block:resize(self.block.width + 1, self.block.height)
        else
            self.block:resize(self.block.width + 1, self.block.height + 1)
        end
    elseif key == "-" then
        if love.keyboard.isDown("w") or love.keyboard.isDown("s") then
            self.block:resize(self.block.width, self.block.height - 1)
        elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
            self.block:resize(self.block.width - 1, self.block.height)
        else
            self.block:resize(self.block.width - 1, self.block.height - 1)
        end
    elseif key == "c" then
        self.block.color_index = (self.block:getColorIndex() + 1 - 1) % #COLORS + 1
    elseif key == "p" then
        PALETTE = (PALETTE + 1 - 1) % #PALETTES + 1
    elseif key == "m" then
        if MUSIC == -1 then
            MUSIC = 0
        else
            MUSIC = MUSIC + 1
        end
        if MUSIC > #MUSIC_NAMES then
            MUSIC = -1
        end
        self.music_popup = 3
    elseif key == "tab" then
        self.current_tool = self.current_tool + 1
        if self.current_tool > #self.tools then
            self.current_tool = 1
        end
    elseif key == "escape" then
        if self.block.block then
            self:setBlock(self.block.block)
        end
    elseif key == "r" and love.keyboard.isDown("lctrl") then
        self:reset()
    elseif key == "s" and love.keyboard.isDown("lctrl") then
        if not self.level_path or love.keyboard.isDown("lshift") then
            self.file_dialog = "save"
        else
            self:saveLevel()
        end
    elseif key == "o" and love.keyboard.isDown("lctrl") then
        self.file_dialog = "open"
    end
end

function Editor:getLevelsPath()
    local current_os = love.system.getOS()
    if current_os == "Windows" then
        local parabox_path = os.getenv('UserProfile').."\\AppData\\LocalLow\\Patrick Traynor\\Patrick's Parabox\\"
        if Utils.fileExists(parabox_path) then
            return string.gsub(parabox_path.."custom_levels", "\\", "/")
        end
    elseif current_os == "Linux" then
        local parabox_path
        if os.getenv('XDG_CONFIG_HOME') then
            parabox_path = os.getenv('XDG_CONFIG_HOME').."/unity3d/Patrick Traynor/Patrick's Parabox/"
        else
            parabox_path = os.getenv('HOME').."/.config/unity3d/Patrick Traynor/Patrick's Parabox/"
        end
        if Utils.fileExists(parabox_path) then
            return parabox_path.."custom_levels"
        end
    elseif current_os == "OS X" then
        local parabox_path = "~/Library/Application Support/Patrick Traynor/Patrick's Parabox/"
        if Utils.fileExists(parabox_path) then
            return parabox_path.."custom_levels"
        end
    else
        print("No default filepaths for OS: "..current_os)
    end
end

function Editor:saveLevel()
    --[[for i,block in ipairs(self.blocks) do
        block.key = i - 1
    end]]

    local data = {depth = 0}
    ROOT:save(data)

    local savestr = table.concat({
        "version "..LEVEL_VERSION,
        "custom_level_palette "..(PALETTE > 1 and PALETTE-1 or -1),
        "custom_level_music "..MUSIC
    },"\n").."\n#\n"
    for _,tile in ipairs(data) do
        local args = {tile.type}
        for _,arg in ipairs(tile) do
            if type(arg) == "boolean" then
                table.insert(args, arg and "1" or "0")
            else
                table.insert(args, tostring(arg))
            end
        end
        local line = ""
        for i=1,tile.depth do
            line = line.."\t"
        end
        line = line..table.concat(args, " ")

        savestr = savestr..line.."\n"
    end

    local f, err = io.open(self.level_path, "w")
    if not f then
        error(err)
    end
    f:write(savestr)
    f:close()
end

function Editor:openLevel(path)
    local f = io.open(path, "r")
    if not f then return end
    local data_str = f:read("*all")

    self.level_path = path
    self.next_key = 1
    self.blocks = {}

    local section = "header"
    local last_depth = 0
    local parents = {}
    local last_block = nil
    for line in data_str:gmatch("[^\r\n]+") do
        if section == "header" then
            local args = Utils.getArgs(line)
            if args[1] == "version" then
                if args[2] ~= tostring(LEVEL_VERSION) then
                    error("Unsupported level version: "..args[2])
                end
            elseif args[1] == "custom_level_palette" then
                if tonumber(args[2]) == -1 then
                    PALETTE = 1
                else
                    PALETTE = tonumber(args[2]) + 1
                end
            elseif args[1] == "custom_level_music" then
                MUSIC = tonumber(args[2])
            elseif args[1] == "#" then
                section = "tiles"
            end
        else
            local depth = 0
            while line:sub(1, 1) == "\t" do
                line = line:sub(2)
                depth = depth + 1
            end

            if depth > last_depth then
                for i = 1, depth - last_depth do
                    table.insert(parents, 1, last_block)
                end
            elseif depth < last_depth then
                for i = 1, last_depth - depth do
                    table.remove(parents, 1)
                end
            end

            local args = Utils.getArgs(line)
            args.parent = parents[1]

            local type = Utils.readStr(args)
            local new_tile = Tiles[type].load(args)

            if depth == 0 then
                ROOT = new_tile
                self:setBlock(new_tile)
            else
                new_tile.block:setTile(new_tile.x, new_tile.y, new_tile)
            end

            last_depth = depth
            last_block = new_tile
        end
    end

    local function loopBlock(block)
        for _,tile in pairs(block.tiles) do
            if tile.type == "Block" then
                loopBlock(tile)
            end
            if tile.postLoad then
                tile:postLoad()
            end
        end
    end
    loopBlock(self.block)
    self.block:postLoad()
end

function Editor:getDrawSize()
    if SCREENSHOTTING then
        return 1000
    else
        return math.min(love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function Editor:getTransform()
    local target_size = math.max(self.block.width, self.block.height) + 2
    local target_scale = math.min(love.graphics.getWidth() / (target_size*SCALE), love.graphics.getHeight() / (target_size*SCALE))

    local transform = love.math.newTransform()
    transform:translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    transform:scale(target_scale, target_scale)
    transform:translate(-self.block.width/2 *SCALE, -self.block.height/2 *SCALE)

    return transform
end

function Editor:getIconTransform()
    local target_scale_x = PREVIEW_SIZE / (ROOT.width*SCALE)
    local target_scale_y = PREVIEW_SIZE / (ROOT.height*SCALE)

    local transform = love.math.newTransform()
    transform:scale(target_scale_x, target_scale_y)

    return transform
end

function Editor:draw()
    if self.block.block or self.block.exit_block then
        love.graphics.push()
        love.graphics.replaceTransform(self:getTransform())
        love.graphics.scale(self.block.width, self.block.height)
        if self.block.exit_block then
            love.graphics.translate(-self.block.exit_block.x*SCALE, -self.block.exit_block.y*SCALE)
            self.block.exit_block.block:draw(-1, true, self.block)
        else
            love.graphics.translate(-self.block.x*SCALE, -self.block.y*SCALE)
            self.block.block:draw(-1, true, self.block)
        end
        love.graphics.pop()

        love.graphics.setColor(0, 0, 0, 0.25)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    love.graphics.replaceTransform(self:getTransform())
    self.block:draw(0, true)

    if not self.settings_open then
        love.graphics.push()
        love.graphics.origin()
        love.graphics.setCanvas(self.preview_canvas)
        love.graphics.clear()
        self.tools[self.current_tool]:draw(1)
        love.graphics.setCanvas()
        love.graphics.pop()

        love.graphics.translate(self.mx*SCALE, self.my*SCALE)
        love.graphics.setColor(1, 1, 1, math.abs(math.sin(love.timer.getTime() * 2)) * 0.3 + 0.2)
        love.graphics.draw(self.preview_canvas)
        love.graphics.setColor(1, 1, 1)
    end

    -- draw music name popup
    if self.music_popup > 0 then
        love.graphics.origin()
        love.graphics.setFont(self.music_font)

        local music_string = MUSIC_NAMES[MUSIC] or "None"
        local alpha = math.min(self.music_popup, 1)

        love.graphics.setColor(0, 0, 0, alpha)
        for i = -1, 1 do
            for j = -1, 1 do
                if i ~= 0 or j ~= 0 then
                    love.graphics.printf(music_string, 50 + i*2, 20 + j*2, love.graphics.getWidth(), "left")
                end
            end
        end
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(music_string, 50, 20, love.graphics.getWidth(), "left")

        love.graphics.draw(Assets.sprites["musicnote"], 20, 20)
    end
end

return Editor