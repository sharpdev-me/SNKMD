local ModTypes = {}

ModTypes.Hero = setmetatable({

}, {
    __call = function(_, definition)
        local hero = table.copy(definition)

        function hero:getDescription()
            if type(hero.description) == "function" then return hero.description(hero) else return hero.description end
        end

        function hero:getColor()
            if hero.color then return hero.color end

            -- change this when you do the class revamp
            return class_colors[self.classes[1]]
        end

        function hero:distinctName()
            return hero.mod.name .. hero.name
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
            return hero.name:gsub("_", " "):capitalize()
        end

        function hero:createClassString()
            local result = {}

            -- fix in class revamp
            for _, class in ipairs(self.classes) do
                table.insert(result, '[' .. class_color_strings[class] .. ']' .. class:capitalize())
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

        return hero
    end
})

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
        local text = type(self.description) == "table" and self.description(self) or self.description
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
    _call = function(_, definition)
        return LevelThree(definition)
    end
})

return ModTypes