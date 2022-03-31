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
    self.player_order = o.player_order or 0
    self.flip_h = o.flip_h or false
    self.hidden = o.hidden or false

    self.inf_exit = o.inf_exit or false
    self.inf_exit_num = o.inf_exit_num or 0
    self.inf_enter = o.inf_enter or false
    self.inf_enter_num = o.inf_enter_num or 0
    self.inf_enter_key = o.inf_enter_key or 0

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

        x, y,               -- x, y
        self.ref.key,       -- ref key
        self.exit,          -- exit block
        self.inf_exit,      -- inf exit
        self.inf_exit_num,  -- inf exit number
        self.inf_enter,     -- inf enter
        self.inf_enter_num, -- inf enter number
        self.inf_enter_key, -- inf enter level key
        self.player,        -- is player
        self.possessable,   -- possessable
        self.player_order,  -- player order
        self.flip_h,        -- flip horizontally
        self.hidden,        -- float in space (no parent)
        0,                  -- special effect
    })
end

function Ref.load(data)
    local x, y = Utils.readNum(data, 2)
    local key = Utils.readNum(data)
    local exit = Utils.readBool(data)
    local inf_exit = Utils.readBool(data)
    local inf_exit_num = Utils.readNum(data)
    local inf_enter = Utils.readBool(data)
    local inf_enter_num = Utils.readNum(data)
    local inf_enter_key = Utils.readNum(data)
    local player = Utils.readBool(data)
    local possessable = Utils.readBool(data)
    local player_order = Utils.readNum(data)
    local flip_h = Utils.readBool(data)
    local hidden = Utils.readBool(data)
    local special_effect = Utils.readNum(data)

    if data.parent then y = data.parent.height-y-1 end
    local new_ref = Ref(x, y, data.parent, nil, {
        exit = exit,
        inf_exit = inf_exit,
        inf_exit_num = inf_exit_num,
        inf_enter = inf_enter,
        inf_enter_num = inf_enter_num,
        inf_enter_key = inf_enter_key,
        player = player,
        possessable = possessable,
        player_order = player_order,
        flip_h = flip_h,
        hidden = hidden
    })
    new_ref.ref_key = key

    return new_ref
end

function Ref:postLoad()
    for _,block in ipairs(Editor.blocks) do
        if block.key == self.ref_key then
            self.ref = block
            if self.exit then
                self.ref.exit_block = self
            end
        end
    end
end

function Ref:place(x, y)
    local exit = self.ref == ROOT and not self.ref.exit_block
    local new_ref = Ref(x, y, self.block, self.ref, {
        exit = exit,
        inf_exit = self.inf_exit,
        inf_exit_num = self.inf_exit_num,
        inf_enter = self.inf_enter,
        inf_enter_num = self.inf_enter_num,
        player = self.player,
        possessable = self.possessable,
        player_order = self.player_order,
        flip_h = self.flip_h,
        hidden = self.hidden
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
    Slab.Text("Ref")
    Slab.SameLine()
    self:addBlockInput("RefKeyInput", self.ref.key, function(selected, exit)
        if self.ref.exit_block == self then
            self.ref.exit_block = nil
        end
        if exit ~= nil then
            self.ref.exit = exit
        end
        self.ref = selected
        if self.exit then
            self.ref.exit_block = self
        end
    end)
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
    if Slab.CheckBox(self.inf_exit, "Inf Exit") then
        self.inf_exit = not self.inf_exit
    end
    Slab.SameLine()
    if Slab.Input("InfExitNumInput", {Text = tostring(self.inf_exit_num), NumbersOnly = true, NoDrag = true, W = 40}) then
        self.inf_exit_num = Slab.GetInputNumber()
    end
    if Slab.CheckBox(self.inf_enter, "Inf Enter") then
        self.inf_enter = not self.inf_enter
    end
    Slab.SameLine()
    if Slab.Input("InfEnterNumInput", {Text = tostring(self.inf_enter_num), NumbersOnly = true, NoDrag = true, W = 40}) then
        self.inf_enter_num = Slab.GetInputNumber()
    end
    Slab.Text("Inf Enter From")
    Slab.SameLine()
    self:addBlockInput("InfEnterKeyInput", self.inf_enter_key, function(selected)
        self.inf_enter = true
        self.inf_enter_key = selected.key
    end)
    Slab.Separator()
    if Slab.CheckBox(self.player, "Player") then
        self.player = not self.player
    end
    Slab.SameLine()
    if Slab.Input("PlayerOrderInput", {Text = tostring(self.player_order), NumbersOnly = true, NoDrag = true, W = 40}) then
        self.player_order = Slab.GetInputNumber()
    end
    if Slab.CheckBox(self.possessable, "Possessable") then
        self.possessable = not self.possessable
    end
    if Slab.CheckBox(self.flip_h, "Flip") then
        self.flip_h = not self.flip_h
    end
    if Slab.CheckBox(self.hidden, "Float In Space") then
        self.hidden = not self.hidden
    end
end

function Ref:addBlockInput(id, current_key, callback)
    if Slab.Input(id, {Text = tostring(current_key), NumbersOnly = true, ReturnOnText = false, NoDrag = true, W = 40}) then
        local num = Slab.GetInputNumber()
        for _,block in ipairs(Editor.blocks) do
            if block.key == num then
                callback(block)
                return
            end
        end
        callback(ROOT)
        return
    end
    Slab.SameLine()
    if Slab.Button("...", {W = 30, H = 16}) then
        Editor:openRefSelect(Editor:getBlockByKey(current_key), callback)
    end
end

return Ref