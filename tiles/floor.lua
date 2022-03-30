local Floor = Class{type="Floor"}

function Floor:init(x, y, parent, floor, o)
    o = o or {}
    self.x = x
    self.y = y
    self.block = parent
    self.floor = floor

    -- for Portals
    self.portal_icon = nil
    self:setPortal(o.portal or "")
end

function Floor:setPortal(name)
    self.portal = name

    if name ~= "" and not name:starts("base:") then
        local fname = name:gsub(" ", "_")
        local f, err = io.open(os.getenv('UserProfile').."\\AppData\\LocalLow\\Patrick Traynor\\Patrick's Parabox Demo\\levels\\"..fname..".png", "rb")
        if f then
            local byte_str = f:read("*all")
            f:close()

            local byte_data = love.data.newByteData(byte_str)
            local image_data = love.image.newImageData(byte_data)
            self.portal_icon = love.graphics.newImage(image_data)
        end
    end
end

function Floor:draw()
    Utils.setColor(self.block:getColor(), 1, 0.75)
    if self.floor == "Button" then
        love.graphics.draw(Assets.sprites["floor_button"])
    elseif self.floor == "PlayerButton" then
        love.graphics.draw(Assets.sprites["floor_playerbutton"])
    elseif self.floor == "Portal" then
        if not self.portal_icon then
            love.graphics.draw(Assets.sprites["floor_portal"])
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.scale(SCALE/self.portal_icon:getWidth(), SCALE/self.portal_icon:getHeight())
            love.graphics.draw(self.portal_icon)
        end
    else
        love.graphics.draw(Assets.sprites["floor_unknown"])
    end
end

function Floor:save(data)
    local x, y = self.x, self.block.height-self.y-1
    local new_data = {
        depth = data.depth,
        type = "Floor",

        x, y,           -- x, y
        self.floor,     -- text
    }
    if self.floor == "Portal" then
        table.insert(new_data, Utils.toSaveName(self.portal))
    end

    table.insert(data, new_data)
end

function Floor.load(data)
    local x, y = Utils.readNum(data, 2)
    local text = Utils.readStr(data)

    local portal = ""
    if text == "Portal" then
        portal = Utils.fromSaveName(Utils.readStr(data))
    end

    if data.parent then y = data.parent.height-y-1 end
    return Floor(x, y, data.parent, text, {portal = portal})
end

function Floor:place(x, y)
    local floor = Floor(x, y, self.block, self.floor, {portal = self.portal})

    if self.floor == "Portal" then
        Gamestate.push(TextInput, "Level portal:", floor.portal, function(levelname)
            floor:setPortal(levelname)
        end)
    end

    return floor
end

return Floor