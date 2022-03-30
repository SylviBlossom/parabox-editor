local TextInput = {}

function TextInput:init()
    self.small_font = love.graphics.newFont(25)
    self.big_font = love.graphics.newFont(30)
end

function TextInput:enter(previous, prompt, text, f)
    self.last_scene = previous
    self.prompt = prompt
    self.on_return = f
    self.text = text or ""

    self.last_text_input = love.keyboard.hasTextInput()
    self.last_key_repeat = love.keyboard.hasKeyRepeat()
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
end

function TextInput:leave()
    love.keyboard.setTextInput(self.last_text_input)
    love.keyboard.setKeyRepeat(self.last_key_repeat)
end

function TextInput:textinput(text)
    self.text = self.text .. text
end

function TextInput:keypressed(key)
    if key == "backspace" then
        self.text = string.sub(self.text, 1, -2)
    elseif key == "return" then
        if self.on_return then
            self.on_return(self.text)
        end
        Gamestate.pop()
    elseif key == "escape" then
        Gamestate.pop()
    end
end

function TextInput:draw()
    self.last_scene:draw()

    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.big_font)
    love.graphics.printf(self.prompt, 0, love.graphics.getHeight()/2 - self.big_font:getHeight()/2 - 10, love.graphics.getWidth(), "center")
    love.graphics.setFont(self.small_font)
    love.graphics.printf(self.text, 0, love.graphics.getHeight()/2 + self.small_font:getHeight()/2 + 10, love.graphics.getWidth(), "center")

    if math.floor(love.timer.getTime() / 0.5) % 2 == 0 then
        local text_width = self.small_font:getWidth(self.text)
        love.graphics.rectangle("fill", love.graphics.getWidth()/2 + text_width/2, love.graphics.getHeight()/2 + 10 + self.small_font:getHeight()/2, 2, self.small_font:getHeight())
    end
end

return TextInput