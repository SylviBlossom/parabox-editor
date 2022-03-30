-- graphics extensions

local graphics = love.graphics

local old_getScissor = love.graphics.getScissor

local scissorStack = {}

function graphics.getScissor()
    if old_getScissor() then
        local x, y, w, h = old_getScissor()
        local x2, y2 = x + w, y + h

        x, y = love.graphics.inverseTransformPoint(x, y)
        x2, y2 = love.graphics.inverseTransformPoint(x2, y2)

        w, h = x2 - x, y2 - y

        return x, y, w, h
    else
        local x, y, w, h = 0, 0, love.graphics.getWidth(), love.graphics.getHeight()
        local x2, y2 = x + w, y + h

        x, y = love.graphics.inverseTransformPoint(x, y)
        x2, y2 = love.graphics.inverseTransformPoint(x2, y2)

        w, h = x2 - x, y2 - y

        return x, y, w, h
    end
end

function graphics.pushScissor()
    local x, y, w, h = old_getScissor()

    table.insert(scissorStack, 1, {x, y, w, h})
end

function graphics.popScissor()
    local x, y, w, h = unpack(scissorStack[1])

    love.graphics.setScissor(x, y, w, h)
    table.remove(scissorStack, 1)
end

function graphics.scissor(x, y, w, h)
    local sx, sy = love.graphics.transformPoint(x, y)
    local sx2, sy2 = love.graphics.transformPoint(x+w, y+h)

    if old_getScissor() == nil then
        love.graphics.setScissor(math.min(sx, sx2), math.min(sy, sy2), math.abs(sx2-sx), math.abs(sy2-sy))
    else
        love.graphics.intersectScissor(math.min(sx, sx2), math.min(sy, sy2), math.abs(sx2-sx), math.abs(sy2-sy))
    end
end

-- misc

function string.starts(self, start)
    return self:sub(1, start:len()) == start
end

function string.ends(self, ending)
    return ending == "" or self:sub(-#ending) == ending
end

function string.trim(self)
    return self:gsub("^%s*(.-)%s*$", "%1")
end

function table.removeValue(tbl, val)
    for i,v in ipairs(tbl) do
        if v == val then
            table.remove(tbl, i)
            return val
        end
    end
end