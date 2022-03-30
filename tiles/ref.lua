local Ref = Class{type="Ref"}

function Ref:init(x, y, parent, ref, exit)
    self.x = x
    self.y = y
    self.block = parent
    self.ref = ref or parent
    self.exit = exit or false
end

function Ref:draw(depth)
    self.ref:draw(depth)

    if not SCREENSHOTTING then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(12)
        love.graphics.line(40, 40, 60, 60)
        love.graphics.line(60, 40, 40, 60)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(10)
        love.graphics.line(40, 40, 60, 60)
        love.graphics.line(60, 40, 40, 60)
    end
end

function Ref:drawShadow()
    love.graphics.rectangle("fill", 0, 0, 100, 100)
end

function Ref:save(data)
    local x, y = self.x, self.block.height-self.y-1
    table.insert(data, {
        depth = data.depth,
        type = "Ref",

        x, y,             -- x, y
        self.ref.key,     -- ref key
        self.exit,        -- exit block
        false,            -- inf exit
        0,                -- inf exit number
        false,            -- inf enter
        0,                -- inf enter number
        -1,               -- inf enter level key
        false,            -- is player
        false,            -- possessable
        0,                -- player order
        false,            -- flip horizontally
        false,            -- float in space (no parent)
        0,                -- special effect
    })
end

function Ref.load(data)
    local x, y = Utils.readNum(data, 2)
    local key = Utils.readNum(data)
    local exit = Utils.readNum(data)
    local inf_exit = Utils.readBool(data)
    local inf_exit_num = Utils.readNum(data)
    local inf_enter = Utils.readBool(data)
    local inf_enter_num = Utils.readNum(data)
    local inf_enter_key = Utils.readNum(data)
    local player = Utils.readBool(data)
    local possessable = Utils.readBool(data)
    local player_order = Utils.readNum(data)
    local flip_h = Utils.readBool(data)
    local float_in_space = Utils.readBool(data)
    local special_effect = Utils.readNum(data)

    if data.parent then y = data.parent.height-y-1 end
    local new_ref = Ref(x, y, data.parent, nil, exit)
    new_ref.ref_key = key

    return new_ref
end

function Ref:postLoad()
    for _,block in ipairs(Editor.blocks) do
        if block.key == self.ref_key then
            self.ref = block
            if self.exit then
                print("nya,,,,")
                self.ref.exit_block = self
            end
        end
    end
end

function Ref:place(x, y)
    local exit = self.ref == ROOT and not self.ref.exit_block
    local new_ref = Ref(x, y, self.block, self.ref, exit)
    if exit then
        self.ref.exit_block = new_ref
    end
    return new_ref
end

function Ref:erase()
    if self.ref and self.exit then
        self.ref.exit_block = nil
    end
end

return Ref