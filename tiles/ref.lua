local Ref = Class{type="Ref"}

function Ref:init(x, y, parent, ref, o)
    o = o or {}
    self.x = x
    self.y = y
    self.block = parent
    self.ref = ref or parent

    self.exit = o.exit or false
    self.player = o.player or false
    self.possessable = o.possessable or false
    self.flip_h = o.flip_h or false

    self.blink_timer = love.math.random()*5 -- used for blinking effect
end

function Ref:draw(depth)
    self.ref:draw(depth, nil, nil, self)

    if not SCREENSHOTTING then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(12)
        love.graphics.line(40, 40, 60, 60)
        love.graphics.line(60, 40, 40, 60)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(10)
        love.graphics.line(40, 40, 60, 60)
        love.graphics.line(60, 40, 40, 60)
        love.graphics.setLineWidth(1)
    end

    -- draw player eyes
    Utils.setColor(self.ref:getColor(), 0.3)
    if self.player then
        if (love.timer.getTime() - self.blink_timer) % 5 >= 4.8 and not SCREENSHOTTING then
            love.graphics.draw(Assets.sprites["player_eyes_blink"])
        else
            love.graphics.draw(Assets.sprites["player_eyes"])
        end
    elseif self.possessable then
        love.graphics.draw(Assets.sprites["player_eyes_empty"])
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
        self.player,      -- is player
        self.possessable, -- possessable
        0,                -- player order
        self.flip_h,      -- flip horizontally
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
    local new_ref = Ref(x, y, data.parent, nil, {
        exit = exit,
        player = player,
        possessable = possessable,
        flip_h = flip_h
    })
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
    local new_ref = Ref(x, y, self.block, self.ref, {
        exit = exit,
        player = self.player,
        possessable = self.possessable,
        flip_h = self.flip_h
    })
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

function Ref:openSettings()
    if Slab.CheckBox(self.exit, "Ref Exit") then
        self.exit = not self.exit
        if self.exit then
            if self.ref.exit_block and self.ref.exit_block.type == "Ref" then
                self.ref.exit_block.exit = nil
            end
            self.ref.exit_block = self
        else
            self.ref.exit_block = nil
        end
    end
    if Slab.CheckBox(self.player, "Player") then
        self.player = not self.player
    end
    if Slab.CheckBox(self.possessable, "Possessable") then
        self.possessable = not self.possessable
    end
    if Slab.CheckBox(self.flip_h, "Flip H") then
        self.flip_h = not self.flip_h
    end
end

return Ref