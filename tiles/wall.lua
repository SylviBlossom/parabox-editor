local Wall = Class{type="Wall"}

function Wall:init(x, y, parent)
    self.x = x
    self.y = y
    self.block = parent

    self.neighbors = {ul = false, u = false, ur = false, l = false, r = false, dl = false, d = false, dr = false}
end

function Wall:getDrawColor(screen_space, brightness)
    local h,s,bv = Utils.getHSV(self.block:getColor())
    local v = 1
    v = v * (-0.25 * (math.log(screen_space + 0.005) / math.log(20)) + 0.5)
    v = v * bv
    v = v * 2

    return {Utils.calcHSVI(h,s,bv,v*(brightness or 1))}
end

function Wall:draw(depth, shadow)
    local px1,py1 = love.graphics.transformPoint(0, 0)
    local px2,py2 = love.graphics.transformPoint(100, 100)
    local screen_space = ((px2 - px1) + (py2 - py1)) / 2 / math.min(love.graphics.getWidth(), love.graphics.getHeight())
    if not shadow then
        -- wall fill color
        Utils.setColor(self:getDrawColor(screen_space, 0.75))
    end

    local corners = {"ul", "ur", "dl", "dr"}

    -- middle of the wall
    love.graphics.rectangle("fill", 10, 10, 80, 80)

    if self.neighbors.l then -- left side of the wall
        love.graphics.rectangle("fill", 0, 25, 25, 50)
        corners[1] = "u"
        corners[3] = "d"
    end
    if self.neighbors.r then -- right side of the wall
        love.graphics.rectangle("fill", 75, 25, 25, 50)
        corners[2] = "u"
        corners[4] = "d"
    end
    if self.neighbors.u then -- top side of the wall
        love.graphics.rectangle("fill", 25, 0, 50, 25)
        if corners[1] == "u" then
            corners[1] = "ul_corner"
        else
            corners[1] = "l"
        end
        if corners[2] == "u" then
            corners[2] = "ur_corner"
        else
            corners[2] = "r"
        end
    end
    if self.neighbors.d then -- bottom side of the wall
        love.graphics.rectangle("fill", 25, 75, 50, 25)
        if corners[3] == "d" then
            corners[3] = "dl_corner"
        else
            corners[3] = "l"
        end
        if corners[4] == "d" then
            corners[4] = "dr_corner"
        else
            corners[4] = "r"
        end
    end
    if self.neighbors.ul then -- top-left side of the wall
        love.graphics.rectangle("fill", 0, 0, 25, 25)
        corners[1] = nil
    end
    if self.neighbors.ur then -- top-right side of the wall
        love.graphics.rectangle("fill", 75, 0, 25, 25)
        corners[2] = nil
    end
    if self.neighbors.dl then -- down-left side of the wall
        love.graphics.rectangle("fill", 0, 75, 25, 25)
        corners[3] = nil
    end
    if self.neighbors.dr then -- down-right side of the wall
        love.graphics.rectangle("fill", 75, 75, 25, 25)
        corners[4] = nil
    end

    for i = 1, 4 do
        if corners[i] then
            local x = ((i - 1) % 2) * 50
            local y = math.floor((i - 1) / 2) * 50

            if corners[i]:sub(-6) ~= "_corner" then
                if Assets.sprites["wall/light_"..corners[i]] then
                    if not shadow then Utils.setColor(self:getDrawColor(screen_space)) end
                    love.graphics.draw(Assets.sprites["wall/light_"..corners[i]], x, y)
                end
                if Assets.sprites["wall/shade_"..corners[i]] then
                    if not shadow then Utils.setColor(self:getDrawColor(screen_space, 0.54)) end
                    love.graphics.draw(Assets.sprites["wall/shade_"..corners[i]], x, y)
                end
            else
                if Assets.sprites["wall/shade_"..corners[i]] then
                    if not shadow then Utils.setColor(self:getDrawColor(screen_space, 0.54)) end
                    love.graphics.draw(Assets.sprites["wall/shade_"..corners[i]], x, y)
                end
                if Assets.sprites["wall/light_"..corners[i]] then
                    if not shadow then Utils.setColor(self:getDrawColor(screen_space)) end
                    love.graphics.draw(Assets.sprites["wall/light_"..corners[i]], x, y)
                end
            end
        end
    end
end

function Wall:drawShadow(depth)
    self:draw(depth, true)
end

function Wall:calculateNeighbors()
    local dirs = {
        {"ul", "u", "ur"},
        {"l", nil, "r"},
        {"dl", "d", "dr"}
    }
    for i = -1, 1 do
        for j = -1, 1 do
            local dir = dirs[j+2][i+2]
            if dir then
                local x, y = self.x + i, self.y + j

                if x < 0 or y < 0 or x >= self.block.width or y >= self.block.height then
                    self.neighbors[dir] = true
                elseif self.block:getTile(x, y) and self.block:getTile(x, y).type == "Wall" then
                    self.neighbors[dir] = true
                else
                    self.neighbors[dir] = false
                end
            end
        end
    end
    if not (self.neighbors.u and self.neighbors.l) then self.neighbors.ul = false end
    if not (self.neighbors.u and self.neighbors.r) then self.neighbors.ur = false end
    if not (self.neighbors.d and self.neighbors.l) then self.neighbors.dl = false end
    if not (self.neighbors.d and self.neighbors.r) then self.neighbors.dr = false end
end

function Wall:save(data)
    local x, y = self.x, self.block.height-self.y-1
    table.insert(data, {
        depth = data.depth,
        type = "Wall",

        x, y,           -- x, y
        false,          -- is player
        false,          -- possessable
        0,              -- player order
    })
end

function Wall.load(data)
    local x, y = Utils.readNum(data, 2)
    local player = Utils.readBool(data)
    local possessable = Utils.readBool(data)
    local player_order = Utils.readNum(data)

    if data.parent then y = data.parent.height-y-1 end
    return Wall(x, y, data.parent)
end

-- [[ Brush Functions ]]

function Wall:place(x, y)
    return Wall(x, y, self.block)
end

return Wall