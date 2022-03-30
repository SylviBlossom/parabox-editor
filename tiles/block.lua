local Block = Class{type="Block"}

function Block:init(x, y, width, height, parent, o)
    local o = o or {}
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.block = parent
    self.exit_block = nil
    self.blink_timer = love.math.random()*5 -- used for blinking effect

    self.key = -1 -- used when saving

    self.color = o.color -- custom color override
    self.color_index = o.color_index -- custom color index override
    self.player = o.player or false
    self.possessable = o.possessable or o.player or false

    self.tiles = {}
    self.walls = {}
    self.blocks = {}
    if not o.empty then
        self.filled = true -- true when the sides are covered with walls, which we doooo here
        self:fillSides()
    else
        self.filled = false
    end
end

function Block:resize(width, height)
    if not height then height = width end
    if width < 1 or height < 1 or (width == self.width and height == self.height) then return end
    --if size < 1 or size == self.size then return end

    local new_filled = true
    for x = 0, math.max(width, self.width) - 1 do
        for y = 0, math.max(height, self.height) - 1 do
            -- remove oob tiles
            if (width < self.width and x >= width) or (height < self.height and y >= height) then
                self:eraseTile(x, y)
            end
            -- remove old side walls if filled
            if self.filled and (x == 0 or y == 0 or x == self.width-1 or y == self.height-1) then
                self:eraseTile(x, y)
            end
            -- ...then create new side walls if filled!
            if self.filled and (x == 0 or y == 0 or x == width-1 or y == height-1) then
                self:eraseTile(x, y)
                self:addTile(x, y, Tiles.Wall(x, y, self))
            end

            -- redo filled check just incase it gets filled when shrinking
            if x == 0 or y == 0 or x == width-1 or y == height-1 then
                local tile = self.tiles[x..","..y]
                if not tile or tile.type ~= "Wall" then
                    new_filled = false
                end
            end
        end
    end
    self.filled = new_filled
    self.width = width
    self.height = height

    -- update wall tiling
    for _,tile in pairs(self.tiles) do
        if tile.type == "Wall" then
            tile:calculateNeighbors()
        end
    end
end

function Block:eraseTile(x, y)
    local tile = self.tiles[x..","..y]
    if tile then
        if tile.type == "Wall" then
            table.removeValue(self.walls, tile)
        elseif tile.type == "Block" then
            table.removeValue(self.blocks, tile)
        end
        if tile.erase then
            tile:erase()
        end
    end
    self.tiles[x..","..y] = nil
end

function Block:addTile(x, y, tile)
    self.tiles[x..","..y] = tile
    if tile then
        if tile.type == "Wall" then
            table.insert(self.walls, tile)
        elseif tile.type == "Block" then
            table.insert(self.blocks, tile)
        end
    end
end

function Block:fillSides()
    for x = 0, self.width - 1 do
        for y = 0, self.height - 1 do
            if x == 0 or y == 0 or x == self.width-1 or y == self.height-1 then
                self:eraseTile(x, y)
                self:addTile(x, y, Tiles.Wall(x, y, self))
            end
        end
    end
    self.filled = true

    -- update wall tiling
    for _,tile in pairs(self.tiles) do
        if tile.type == "Wall" then
            tile:calculateNeighbors()
        end
    end
end

function Block:getTile(x, y)
    return self.tiles[x..","..y]
end

function Block:setTile(x, y, tile)
    self:eraseTile(x, y)
    self:addTile(x, y, tile)

    -- update tiling for surrounding walls
    for i = -1, 1 do
        for j = -1, 1 do
            local tile = self.tiles[(x+i)..","..(y+j)]
            if tile and tile.type == "Wall" then
                tile:calculateNeighbors()
            end
        end
    end

    self.filled = true
    for x = 0, self.width - 1 do
        for y = 0, self.height - 1 do
            if x == 0 or y == 0 or x == self.width-1 or y == self.height-1 then
                local tile = self.tiles[x..","..y]
                if not tile or tile.type ~= "Wall" then
                    self.filled = false
                    break
                end
            end
        end
    end
end

function Block:getColorIndex()
    if self.color_index then
        return self.color_index
    elseif self.possessable then
        return COLOR_PLAYER
    elseif self.filled then
        return COLOR_ORANGE
    else
        return COLOR_BLUE
    end
end

function Block:getColor()
    if self.color then
        return self.color
    else
        return COLORS[self:getColorIndex()]
    end
end

function Block:getDrawColor(screen_space)
    local h,s,v = Utils.getHSV(self:getColor())
    v = v * (-0.25 * (math.log(screen_space + 0.005) / math.log(20)) + 0.5)
    v = v * 0.9
    v = Utils.clamp(v, 0, 1)
    return {h,s,v}
end

function Block:isFilled()
    local filled = self.filled and self ~= ROOT
    if filled then
        for _,tile in pairs(self.tiles) do
            if tile.type ~= "Wall" then
                filled = false
                break
            end
        end
    end
    return filled
end

function Block:draw(depth, full, exclude)
    if (full or not self:isFilled()) and depth < 4 then
        -- scale down to 1x1 if this is not the active block
        love.graphics.push()
        if not full then
            love.graphics.scale(1/self.width, 1/self.height)
        end

        -- draw background
        local px1,py1 = love.graphics.transformPoint(0, 0)
        local px2,py2 = love.graphics.transformPoint(self.width * SCALE, self.height * SCALE)
        local bgspace = (((px2 - px1) + (py2 - py1)) / 2) / math.min(love.graphics.getWidth(), love.graphics.getHeight())
        Utils.setColor(self:getDrawColor(bgspace))

        love.graphics.rectangle("fill", 0, 0, self.width * SCALE, self.height * SCALE)

        love.graphics.setColor(0, 0, 0, 0.08)
        local bg_sprite = Assets.sprites["center_gradient"]
        love.graphics.draw(bg_sprite, 0, 0, 0, (self.width * SCALE) / bg_sprite:getWidth(), (self.height * SCALE) / bg_sprite:getHeight())

        -- scissor area so wall shadows dont go outside
        love.graphics.pushScissor()
        love.graphics.scissor(0, 0, self.width * SCALE, self.height * SCALE)

        -- draw shadows
        love.graphics.setColor(0, 0, 0, 0.25)
        for x = 0, self.width - 1 do
            for y = 0, self.height - 1 do
                local tile = self.tiles[x..","..y]
                if tile and tile.drawShadow then
                    -- translate to the tile's position
                    love.graphics.push()
                    love.graphics.translate(x*SCALE, y*SCALE)

                    -- shadow size
                    local sdist = 1
                    if depth == 1 then
                        sdist = 2
                    elseif depth == 0 then
                        sdist = 4
                    elseif depth < 0 then
                        sdist = 6
                    end
                    sdist = sdist * math.max(1, math.floor(Editor:getDrawSize() / 400))

                    -- shadow offset
                    local ax,ay = love.graphics.inverseTransformPoint(0, 0)
                    local bx,by = love.graphics.inverseTransformPoint(sdist, sdist)
                    love.graphics.translate(bx-ax, by-ay)

                    tile:drawShadow(depth + 1)

                    love.graphics.pop()
                end
            end
        end

        -- draw tiles!
        for x = 0, self.width - 1 do
            for y = 0, self.height - 1 do
                local tile = self.tiles[x..","..y]
                if tile and tile ~= exclude then
                    -- translate to the tile's position
                    love.graphics.push()
                    love.graphics.translate(x*SCALE, y*SCALE)
                    tile:draw(depth + 1)
                    love.graphics.pop()
                end
            end
        end

        -- pop stuff
        love.graphics.pop()
        love.graphics.popScissor()
    else
        -- draw solid filled color
        Utils.setColor(self:getColor())
        love.graphics.rectangle("fill", 0, 0, 100, 100)

        -- draw player eyes
        if self.possessable then
            Utils.setColor(self:getColor(), 0.3)
            if self.player then
                if (love.timer.getTime() - self.blink_timer) % 5 >= 4.8 then
                    love.graphics.draw(Assets.sprites["player_eyes_blink"])
                else
                    love.graphics.draw(Assets.sprites["player_eyes"])
                end
            else
                love.graphics.draw(Assets.sprites["player_eyes_empty"])
            end
        end
    end

    local ox1,oy1,ox2,oy2
    if full then
        -- use full size rect if not displaying full
        ox1,oy1 = love.graphics.transformPoint(0, 0)
        ox2,oy2 = love.graphics.transformPoint(self.width*SCALE, self.height*SCALE)
    else
        -- use 1x1 rect if not displaying full
        ox1,oy1 = love.graphics.transformPoint(0, 0)
        ox2,oy2 = love.graphics.transformPoint(100, 100)

        -- draw player eyes
        if self.possessable then
            Utils.setColor(self:getColor(), 0.3)
            if self.player then
                if (love.timer.getTime() - self.blink_timer) % 5 >= 4.8 and not SCREENSHOTTING then
                    love.graphics.draw(Assets.sprites["player_eyes_blink"])
                else
                    love.graphics.draw(Assets.sprites["player_eyes"])
                end
            else
                love.graphics.draw(Assets.sprites["player_eyes_empty"])
            end
        end
    end

    -- set outline color
    Utils.setColor(self:getColor(), 0.2)

    -- dont scale the outline
    love.graphics.push()
    love.graphics.origin()
    local linediv = 1
    if depth > 1 then
        -- draw 1px line at lower depths
        linediv = 500
    elseif depth == 1 then
        -- draw 2px line at normal depth
        linediv = 250
    else
        -- draw 4px line at higher depths
        linediv = 125
    end
    local linew = math.max(1, math.floor(Editor:getDrawSize() / linediv))
    love.graphics.rectangle("fill", ox1, oy1, linew, oy2-oy1)
    love.graphics.rectangle("fill", ox1, oy1, ox2-ox1, linew)
    love.graphics.rectangle("fill", ox2-linew, oy1, linew, oy2-oy1)
    love.graphics.rectangle("fill", ox1, oy2-linew, ox2-ox1, linew)
    love.graphics.pop()
end

function Block:drawShadow()
    love.graphics.rectangle("fill", 0, 0, 100, 100)
end

function Block:save(data)
    local x, y = self.x, self.y
    if self.block then
        y = self.block.height - self.y - 1
    end
    local h,s,v = Utils.getHSV(self:getColor(), 1)
    local true_filled = self:isFilled()
    table.insert(data, {
        depth = data.depth,
        type = "Block",

        x, y,                         -- x, y
        self.key,                     -- key
        self.width, self.height,      -- width, height
        h, s, v,                      -- hue, saturation, value
        1,                            -- camera zoom factor
        true_filled and self ~= ROOT, -- fill with walls
        self.player,                  -- is player
        self.possessable,             -- possessable
        0,                            -- player order
        false,                        -- flip horizontally
        false,                        -- float in space (no parent)
        0,                            -- special effect
    })
    if not true_filled then
        data.depth = data.depth + 1
        for x = 0, self.width - 1 do
            for y = 0, self.height - 1 do
                if self.tiles[x..","..y] then
                    self.tiles[x..","..y]:save(data)
                end
            end
        end
        data.depth = data.depth - 1
    end
end

function Block.load(data)
    local x, y = Utils.readNum(data, 2)
    local key = Utils.readNum(data)
    local width, height = Utils.readNum(data, 2)
    local h, s, v = Utils.readNum(data, 3)
    local zoom_factor = Utils.readNum(data)
    local filled = Utils.readBool(data)
    local player = Utils.readBool(data)
    local possessable = Utils.readBool(data)
    local player_order = Utils.readNum(data)
    local flip_h = Utils.readBool(data)
    local float_in_space = Utils.readBool(data)
    local special_effect = Utils.readNum(data)

    if data.parent then y = data.parent.height-y-1 end
    local new_block = Block(x, y, width, height, data.parent, {
        player = player,
        possessable = possessable,
        color = {h, s, v},
        empty = not filled
    })
    new_block.key = key

    Editor.next_key = math.max(Editor.next_key, key + 1)
    table.insert(Editor.blocks, new_block)
    return new_block
end

function Block:postLoad()
    local h, s, v = Utils.getHSV(self.color, 1)
    self.color = nil

    local auto_h, auto_s, auto_v = Utils.getHSV(self:getColor(), 1)
    if h ~= auto_h or s ~= auto_s or v ~= auto_v then
        for i,color_name in ipairs(COLORS) do
            local color = PALETTES[1][color_name]
            if h == color[1] and s == color[2] and v == color[3] then
                self.color_index = i
            end
        end
        if not self.color_index then
            self.color = {h, s, v}
        end
    end
end

-- [[ Brush Functions ]]

function Block:place(x, y)
    local block = Block(x, y, self.width, self.height, self.block, {color = self.color, color_index = self.color_index, player = self.player, possessable = self.possessable})
    block.key = Editor.next_key
    Editor.next_key = Editor.next_key + 1
    table.insert(Editor.blocks, block)
    return block
end

function Block:erase()
    for _,tile in pairs(self.tiles) do
        if tile.erase then
            tile:erase()
        end
    end
    for i,block in ipairs(Editor.blocks) do
        if block == self then
            table.remove(Editor.blocks, i)
            break
        end
    end
end

return Block