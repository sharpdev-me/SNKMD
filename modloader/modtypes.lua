local ModTypes = {}

function ModTypes.Hero(definition)
    local hero = table.shallow_copy(definition)

    function hero:getDescription(l)
        if type(self.description) == "function" then return self:description(l) else return self.description end
    end

    function hero:getColor()
        if self.color then return self.color end

        local colorClass = self.classes[1]
        if colorClass.mod ~= nil then
            return colorClass:getColor()
        end
        return class_colors[colorClass]
    end

    function hero:distinctName()
        return "hero_" .. self.mod.name .. self.name
    end

    function hero:getRenderColor()
        local hColor = self:getColor()

        if hColor[0] ~= nil then return hColor[0] else return hColor end
    end

    function hero:getDimColor()
        if not self.colorRamp then self.colorRamp = ColorRamp(self:getRenderColor(), 0.025) end
        return self.colorRamp[-5]
    end

    function hero:capitalize()
        return self.name:gsub("_", " "):capitalize()
    end

    function hero:createClassString()
        local result = {}

        for _, class in ipairs(self.classes) do
            if class.mod ~= nil then
                table.insert(result, '[' .. class:distinctName() .. ']' .. class:capitalize())
            else table.insert(result, '[' .. class_color_strings[class] .. ']' .. class:capitalize()) end
        end

        return table.concat(result, ", ")
    end

    function hero:setLevelThree(level_three)
        level_three.hero = self
        self.level_three = level_three
        global_text_tags[level_three:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(level_three:getRenderColor()) end}
    end

    function hero:getLevelThree()
        if self.level_three then return self.level_three end
        return ModTypes.LevelThree.default(self)
    end

    function hero:setRepeat(func)
        self.repeat_func = func
    end

    return hero
end

function ModTypes.Class(definition)
    local class = table.shallow_copy(definition)

    function class:distinctName()
        return self.mod.name .. self.name
    end

    function class:getColor()
        return self.color
    end

    function class:getRenderColor()
        if self.color[0] ~= nil then return self.color[0] else return self.color end
    end

    function class:getDimColor()
        if not self.colorRamp then self.colorRamp = ColorRamp(self:getRenderColor(), 0.025) end
        return self.colorRamp[-5]
    end

    function class:capitalize()
        return self.name:gsub("_", " "):capitalize()
    end

    function class:getDescription(num_units)
        if type(self.description) == "function" then return self:description(num_units) else return self.description end
    end

    function class:getColoredDescription(num_units)
        local u = 0
        local s = ""
        for _,v in ipairs(self.groups) do
            if num_units >= v then u = v end
        end

        for i,v in ipairs(self.groups) do
            if i ~= 1 then s = s .. "[light_bg]/" end
            local color
            if v == u then color = "yellow" else color = "light_bg" end
            s = s .. '[' .. color .. ']' .. v
        end
        return s .. " [fg] - " .. self:getDescription(num_units)
    end

    function class:getNumberOfUnits()
        return get_number_of_units_per_class(self.mod:getAllUnits())[self]
    end

    function class:getClassLevel()
        return get_class_levels(self.mod:getAllUnits())[self]
    end

    return class
end

function ModTypes.Item(definition)
    local item = table.shallow_copy(definition)

    function item:distinctName()
        return self.mod.name .. self.name
    end

    function item:getDescription(level)
        if type(self.description) == "function" then return self:description(level) else return self.description end
    end

    function item:getSellCost(level)
        local sellCost = 10
        if level == 1 then return sellCost end
        repeat
            level = level - 1
            sellCost = sellCost + self.levels[level]
        until level <= 1

        return sellCost
    end

    function item:getLevel()
        local arena = ModLoader.getArena()
        if not arena then return -1 end

        for _,v in ipairs(arena.passives) do
            if ModLoader.isXModded(v.passive) and v.passive:distinctName() == self:distinctName() then
                return v.level
            end
        end

        return -1
    end

    return item
end

-- The base Image class.
ModTypes.ModImage = Object:extend()
function ModTypes.ModImage:init(mod, image_path)
    local filePath = mod:getModFolderAbsolute() .. "/" .. image_path
    local file = io.open(filePath, "r")
    if not file then return nil end
    local data = love.filesystem.newFileData(file:read("*a"), ModLoader.getFileName(filePath))
    self.image = love.graphics.newImage(data)
    self.w = self.image:getWidth()
    self.h = self.image:getHeight()
end


function ModTypes.ModImage:draw(x, y, r, sx, sy, ox, oy, color)
  local _r, g, b, a
  if color then
    _r, g, b, a = love.graphics.getColor()
    graphics.set_color(color)
  end
  love.graphics.draw(self.image, x, y, r or 0, sx or 1, sy or sx or 1, self.w/2 + (ox or 0), self.h/2 + (oy or 0))
  if color then love.graphics.setColor(_r, g, b, a) end
end

local function LevelThree(definition)
    local levelThree = table.shallow_copy(definition)

    function levelThree:distinctName()
        local heroName = (self.hero == nil) and "unknown" or self.hero.name
        local modName = (self.hero == nil) and "unknown" or self.hero.mod.name

        return modName .. heroName .. self.name
    end

    function levelThree:getString(isActive)
        if not isActive then return "[light_bg]" .. self.name else return '[' .. self:distinctName() .. ']' .. self.name end
    end

    function levelThree:getDescription(isActive)
        local text = type(self.description) == "function" and self.description(self) or self.description
        if not isActive then return "[light_bg]" .. text:gsub("%[%w+%]", "") else return "[fg]" .. text end
    end

    function levelThree:getRenderColor()
        local hColor = self.color

        if hColor[0] ~= nil then return hColor[0] else return hColor end
    end

    return levelThree
end

ModTypes.LevelThree = setmetatable({
    default = function(hero)
        local level_three = LevelThree({
            name = "Unknown",
            description = "The mod author has not defined a level three effect",
            color = red,
            hero = hero
        })

        global_text_tags[level_three:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(level_three:getRenderColor()) end}

        return level_three
    end
}, {
    __call = function(_, definition)
        return LevelThree(definition)
    end
})

return ModTypes