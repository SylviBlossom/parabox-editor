local Utils = {}

function Utils.rgb2hsv( r, g, b )
    local M, m = math.max( r, g, b ), math.min( r, g, b )
    local C = M - m
    local K = 1.0/(6.0 * C)
    local h = 0.0
    if C ~= 0.0 then
        if M == r then     h = ((g - b) * K) % 1.0
        elseif M == g then h = (b - r) * K + 1.0/3.0
        else               h = (r - g) * K + 2.0/3.0
        end
    end
    return h, M == 0.0 and 0.0 or C / M, M
end

function Utils.hsv2rgb( h, s, v)
    local C = v * s
    local m = v - C
    local r, g, b = m, m, m
    if h == h then
        local h_ = (h % 1.0) * 6
        local X = C * (1 - math.abs(h_ % 2 - 1))
        C, X = C + m, X + m
        if     h_ < 1 then r, g, b = C, X, m
        elseif h_ < 2 then r, g, b = X, C, m
        elseif h_ < 3 then r, g, b = m, C, X
        elseif h_ < 4 then r, g, b = m, X, C
        elseif h_ < 5 then r, g, b = X, m, C
        else               r, g, b = C, m, X
        end
    end
    return r, g, b
end

function Utils.calcHSVI(h,s,bv,v)
    v = Utils.clamp(v, 0, 2)
    if v > 1 then
        local d = 1 * (v - 1)
        local dv = (1 - bv)
        v = Utils.clamp(bv + d, 0, 1)
        d = math.max(d - dv, 0)
        s = Utils.clamp(s - d, 0, 1)
    end
    return h, s, v
end

function Utils.clamp(val, a, b)
    return math.max(a, math.min(b, val))
end

function Utils.getHSV(color, palette)
    if type(color) == "table" then
        return unpack(color)
    elseif type(color) == "string" then
        return unpack(PALETTES[palette or PALETTE][color])
    end
end

function Utils.setColor(t, brightness, alpha)
    local h, s, v = Utils.getHSV(t)
    h = math.max(math.min(h, 1), 0)
    s = math.max(math.min(s, 1), 0)
    v = math.max(math.min(v * (brightness or 1), 1), 0)
    local r, g, b = Utils.hsv2rgb(h, s, v)
    love.graphics.setColor(r, g, b, math.min(alpha or 1, 1))
end

function Utils.getArgs(str)
    local args = {}
    for arg in str:gmatch("[^%s]+") do
        table.insert(args, arg)
    end
    return args
end

function Utils.readStr(args, amt)
    local ret = {}
    for i = 1, amt or 1 do
        table.insert(ret, table.remove(args, 1))
    end
    return unpack(ret)
end

function Utils.readBool(args, amt)
    local ret = {}
    for i = 1, amt or 1 do
        table.insert(ret, table.remove(args, 1) == "1")
    end
    return unpack(ret)
end

function Utils.readNum(args, amt)
    local ret = {}
    for i = 1, amt or 1 do
        table.insert(ret, tonumber(table.remove(args, 1)))
    end
    return unpack(ret)
end

function Utils.read(args, amt)
    for i = 1, amt or 1 do
        table.remove(args, 1)
    end
end


-- converts between the level name format used in the editor
-- and the level name format used in level files

function Utils.fromSaveName(name)
    local new_name = name:gsub("_", " "):trim()
    if new_name:starts("custom:") then
        return new_name:sub(8)
    else
        return "base:"..new_name
    end
end

function Utils.toSaveName(name)
    local new_name = name:trim():gsub(" ", "_")
    if new_name == "" then
        return "_"
    elseif new_name:starts("base:") then
        return new_name:sub(6)
    else
        return "custom:"..new_name
    end
end

return Utils