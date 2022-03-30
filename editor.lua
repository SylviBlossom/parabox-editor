local Editor = {}

function Editor:init()
    self:reset()
    self.current_tool = 1
    self.mode = nil
    self.mx, self.my = 0, 0
    self.next_key = 0
    self.placed = {}

    self.music_popup = 0
    self.music_font = love.graphics.newFont(20)

    self.save_icon = false

    self.preview_canvas = love.graphics.newCanvas(SCALE, SCALE)
end

function Editor:reset()
    PALETTE = 1
    MUSIC = 0
    self.level_name = nil
    self.next_key = 0
    ROOT = Tiles.Block(-1, -1, 7, 7, nil, {color_index = COLOR_ROOT}) -- create a new root block
    self:setBlock(ROOT) -- set the current editor block to the root block
    self.blocks = {ROOT}

    self.hub_lines = {}
    self.editing_lines = false
    self.selected_portal = nil
end

function Editor:setBlock(block)
    self.block = block

    -- reset the tools to be parented to the current block
    self.tools = {
        Tiles.Wall(0, 0, self.block),
        Tiles.Block(0, 0, 5, 5, self.block),
        Tiles.Ref(0, 0, self.block, self.block),
        Tiles.Block(0, 0, 5, 5, self.block, {player = true}),
        Tiles.Block(0, 0, 5, 5, self.block, {possessable = true}),
        Tiles.Floor(0, 0, self.block, "PlayerButton"),
        Tiles.Floor(0, 0, self.block, "Button"),
        Tiles.Floor(0, 0, self.block, "Portal"),
    }
end

function Editor:inBounds(x, y)
    return x >= 0 and y >= 0 and x < self.block.width and y < self.block.height
end

function Editor:addLine(from, to, immediate)
    table.insert(self.hub_lines, {from = from, to = to, immediate = immediate})
end

function Editor:removeLinesWith(floor)
    local remove_line = {}
    local count = 0
    for i,line in ipairs(self.hub_lines) do
        if line.from == floor or line.to == floor then
            remove_line[i-count] = true
            count = count + 1
        end
    end
    for i,_ in pairs(remove_line) do
        table.remove(self.hub_lines, i)
    end
end

function Editor:update(dt)
    local transform = self:getTransform()
    self.mx, self.my = transform:inverseTransformPoint(love.mouse.getPosition())
    self.mx = math.floor(self.mx/SCALE)
    self.my = math.floor(self.my/SCALE)

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
            if not self.editing_lines then
                self.block:setTile(self.mx, self.my, nil)
            else
                local tile = self.block:getTile(self.mx, self.my)
                if tile and tile.type == "Floor" and tile.floor == "Portal" then
                    self:removeLinesWith(tile)
                end
            end
        end
    end

    self.music_popup = math.max(self.music_popup - dt, 0)
end

function Editor:mousepressed(x, y, btn)
    if btn == 1 then
        local tile = self.block:getTile(self.mx, self.my)
        if not self.editing_lines then
            if tile and tile.type == "Block" then
                self:setBlock(tile)
            elseif tile and tile.type == "Ref" then
                local ref_blocks = {}
                for _,block in ipairs(self.blocks) do
                    if not block.filled then
                        table.insert(ref_blocks, block)
                    end
                end
                Gamestate.switch(RefSelect, tile, ref_blocks)
            elseif tile and tile.type == "Floor" and tile.floor == "Portal" then
                self.editing_lines = true
            else
                self.mode = "place"
            end
        else
            if tile and tile.type == "Floor" and tile.floor == "Portal" then
                if not self.selected_portal then
                    self.selected_portal = tile
                elseif self.selected_portal == tile then
                    self.selected_portal = nil
                else
                    local from, to = self.selected_portal, tile
                    local immediate = true
                    local dx, dy = math.abs(to.x - from.x), math.abs(to.y - from.y)

                    if dx + dy > 1 then
                        immediate = false
                    end

                    self:addLine(from, to, immediate)
                    self.selected_portal = nil
                end
            end
        end
    elseif btn == 2 then
        self.mode = "erase"
    end
end

function Editor:mousereleased(x, y, btn)
    self.placed = {}
    self.mode = nil
end

function Editor:keypressed(key)
    if not self.editing_lines then
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
            if not self.level_name or love.keyboard.isDown("lshift") then
                Gamestate.push(TextInput, "Save level as:", self.level_name, function(levelname)
                    if levelname ~= "" then
                        self.level_name = levelname
                        self:saveLevel()
                    end
                end)
            else
                self:saveLevel()
            end
        elseif key == "o" and love.keyboard.isDown("lctrl") then
            Gamestate.push(TextInput, "Enter level to open:", "", function(levelname)
                if levelname ~= "" then
                    self:openLevel(levelname)
                end
            end)
        end
    else
        if key == "escape" then
            self.editing_lines = false
        end
    end
end

function Editor:saveLevel()
    for i,block in ipairs(self.blocks) do
        block.key = i - 1
    end

    local data = {depth = 0}
    ROOT:save(data)

    savestr = table.concat({
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

    local f, err = io.open(os.getenv('UserProfile').."\\AppData\\LocalLow\\Patrick Traynor\\Patrick's Parabox\\custom_levels\\"..self.level_name..".txt", "w")
    if not f then
        error(err)
    end
    f:write(savestr)
    f:close()

    --[[if self.level_name == "hub" or self.level_name:ends("/hub") or self.level_name:ends("\\hub") then
        local dir = self.level_name:sub(1, -4)

        local linestr = ""
        for _,line in ipairs(self.hub_lines) do
            linestr = linestr..(Utils.toSaveName(line.from.portal)).." "
            linestr = linestr..(Utils.toSaveName(line.to.portal)).." "
            linestr = linestr..(line.immediate and "1" or "0").."\n"
        end

        local f, err = io.open(os.getenv('UserProfile').."\\AppData\\LocalLow\\Patrick Traynor\\Patrick's Parabox\\custom_levels\\"..dir.."puzzle_lines.txt", "w")
        if not f then
            error(err)
        end
        f:write(linestr)
        f:close()
    end

    self.save_icon = true]]
end

function Editor:openLevel(levelname)
    local f = io.open(os.getenv('UserProfile').."\\AppData\\LocalLow\\Patrick Traynor\\Patrick's Parabox\\custom_levels\\"..levelname..".txt", "r")
    if not f then return end
    local data_str = f:read("*all")

    self.level_name = levelname
    self.next_key = 0
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

    if self.editing_lines then
        love.graphics.push()
        love.graphics.origin()
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.pop()

        for _,tile in pairs(self.block.tiles) do
            if tile.type == "Floor" and tile.floor == "Portal" then
                if self.selected_portal == tile then
                    love.graphics.setColor(1, 1, 0.5, 0.5)
                elseif self.mx == tile.x and self.my == tile.y then
                    love.graphics.setColor(1, 1, 1, math.abs(math.sin(love.timer.getTime() * 2)) * 0.3 + 0.2)
                else
                    love.graphics.setColor(0, 0, 0, 0)
                end
                love.graphics.rectangle("fill", tile.x*SCALE, tile.y*SCALE, SCALE, SCALE)
            end
        end

        for _,line in ipairs(self.hub_lines) do
            local x1, y1 = (line.from.x + 0.5)*SCALE, (line.from.y + 0.5)*SCALE
            local x2, y2 = (line.to.x + 0.5)*SCALE, (line.to.y + 0.5)*SCALE

            if line.immediate then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 1)
                love.graphics.setLineWidth(5)
                love.graphics.line(x1, y1, x2, y2)
            end

            love.graphics.push()
            love.graphics.translate((x1 + x2)/2, (y1 + y2)/2)
            love.graphics.rotate(math.atan2(y2 - y1, x2 - x1))
            love.graphics.polygon("fill", -10, -20, -10, 20, 10, 0)
            love.graphics.pop()
        end
    else
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


    -- save preview icon for level portals
    --[[if self.save_icon then
        local canvas = love.graphics.newCanvas(PREVIEW_SIZE, PREVIEW_SIZE)
        love.graphics.setCanvas(canvas)
        love.graphics.replaceTransform(self:getIconTransform())
        SCREENSHOTTING = true
        ROOT:draw(0, true)
        SCREENSHOTTING = false
        love.graphics.setCanvas()

        local img_data = canvas:newImageData()

        local success, png_data = pcall(function() return img_data:encode("png") end)
        if success then
            local f, err = io.open(os.getenv('UserProfile').."\\AppData\\LocalLow\\Patrick Traynor\\Patrick's Parabox\\custom_levels\\"..self.level_name..".png", "wb")
            if not f then
                error(err)
            end
            f:write(png_data:getString())
            f:close()
        end

        self.save_icon = false
    end]]
end

return Editor