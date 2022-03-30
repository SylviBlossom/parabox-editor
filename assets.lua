local Assets = {}

function Assets:load()
    self.sprites = {}

    local function addSprites(d)
        local dir = "assets"
        if d then
            dir = dir .. "/" .. d
        end
        local files = love.filesystem.getDirectoryItems(dir)
        for _,file in ipairs(files) do
            if string.sub(file, -4) == ".png" then
                local spritename = string.sub(file, 1, -5)
                local sprite = love.graphics.newImage(dir .. "/" .. file)
                if d then
                    spritename = d .. "/" .. spritename
                end
                self.sprites[spritename] = sprite
            elseif love.filesystem.getInfo(dir .. "/" .. file).type == "directory" then
                local newdir = file
                if d then
                    newdir = d .. "/" .. newdir
                end
                addSprites(newdir)
            end
        end
    end
    addSprites()
end

return Assets