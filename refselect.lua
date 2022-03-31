local RefSelect = {}

function RefSelect:enter(previous, selected, blocks, callback)
    self.blocks = blocks
    self.callback = callback
    self.selected = 1
    for i,block in ipairs(self.blocks) do
        if block == selected then
            self.selected = i
        end
    end
end

function RefSelect:keypressed(key)
    if key == "left" or key == "a" then
        self.selected = (self.selected - 1 - 1) % #self.blocks + 1
    elseif key == "right" or key == "d" then
        self.selected = (self.selected + 1 - 1) % #self.blocks + 1
    elseif key == "return" then
        self.callback(self.blocks[self.selected], love.keyboard.isDown("lctrl"))
        Gamestate.switch(Editor)
    elseif key == "escape" then
        Gamestate.switch(Editor)
    end
end

function RefSelect:mousepressed(x, y, btn)
    local mx, my = love.mouse.getPosition()
    local bx, by = (love.graphics.getWidth() - love.graphics.getWidth()*(2/3)) / 2
    if btn == 1 or btn == 3 then
        self.callback(self.blocks[self.selected], btn == 3)
        Gamestate.switch(Editor)
    elseif btn == 2 then
        Gamestate.switch(Editor)
    end
end

function RefSelect:getTransform(block)
    local target_size = math.max(block.width, block.height) + 1
    local target_scale = (love.graphics.getHeight()*(2/3)) / (target_size*SCALE)

    local transform = love.math.newTransform()
    transform:scale(target_scale, target_scale)
    transform:translate(-block.width/2 *SCALE, -block.height/2 *SCALE)

    return transform
end

function RefSelect:draw()
    for i = -1, 1 do
        local index = (self.selected + i - 1) % #self.blocks + 1
        local block = self.blocks[index]

        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
        love.graphics.translate(love.graphics.getHeight()*(2/3) * i, 0)
        if i ~= 0 then
            love.graphics.scale(0.8, 0.8)
        end
        love.graphics.applyTransform(self:getTransform(block))
        block:draw(0, true)
        if i == 0 then
            love.graphics.setColor(1, 1, 1, math.abs(math.sin(love.timer.getTime() * 2)) * 0.3 + 0.2)
            love.graphics.rectangle("fill", 0, 0, block.width * SCALE, block.height * SCALE)
        else
            love.graphics.setColor(0, 0, 0, 0.2)
            love.graphics.rectangle("fill", 0, 0, block.width * SCALE, block.height * SCALE)
        end
        love.graphics.pop()
    end
end

return RefSelect