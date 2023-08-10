--- Heroes are the units that are added to the snake.
-- To avoid breaking other mods, developers should use `Mod:createHero` instead of directly creating a Hero object.
-- @classmod Hero

local LevelThree = require 'modloader.types.levelthree'

local v = function(mod, definition)
    local hero = {}

    --- The name of the hero, should be unique per mod
    -- @string[opt="ModHero"] name
    hero.name = definition.name or "ModHero"

    if mod._heroes[definition.name] then return nil, "hero already exists" end

    --- The description of the hero. Setting this to a function will call it with the hero's current level
    -- @see hero:getDescription
    -- @tparam[opt="ModHeroDescription"] string|function description
    hero.description = definition.description or "ModHeroDescription"

    --- The tier of the unit. This is used for rarities in the shop.
    -- @tparam[opt=1] number tier
    hero.tier = definition.tier or 1

    --- A list of classes that this unit belongs to.
    -- @todo revamp class system and update it here
    -- @tparam[opt={"warrior"}] {string|Class} classes
    hero.classes = definition.classes or {"warrior"}

    --- The mod that created this Hero
    -- @tparam mod mod
    hero.mod = mod

    --- Returns the descrption of the hero.
    -- If `hero.descrption` is a function, its value will be returned instead.
    -- @tparam number level The level of the unit
    -- @treturn string The unit's descrption to be displayed in the shop
    function hero:getDescription(level)
        if type(self.description) == "function" then return self:description(level) else return self.description end
    end

    --- Returns the color that the hero should be rendered with<br>
    -- - If `hero.color` is not undefined, it will return that value<br>
    -- - Otherwise, this function will return the color of the unit's first class.
    -- @treturn Color The color object
    function hero:getColor()
        if self.color then return self.color end

        local colorClass = self.classes[1]
        if colorClass.mod ~= nil then
            return colorClass:getColor()
        end
        return class_colors[colorClass]
    end

    --- Creates a unique identifier for this hero
    -- @treturn string A unique identifier
    function hero:distinctName()
        return "hero_" .. self.mod.name .. self.name
    end

    --- If `hero:getColor` returns a gradient, this function will return the 0-th index of that gradient.<br>
    -- If `hero:getColor` doesn't return a gradient, that value will be returned instead
    -- @treturn Color
    function hero:getRenderColor()
        local hColor = self:getColor()

        if hColor[0] ~= nil then return hColor[0] else return hColor end
    end

    --- Creates a gradient from this hero's color and returns a dim version
    -- @treturn Color
    function hero:getDimColor()
        if not self.colorRamp then self.colorRamp = ColorRamp(self:getRenderColor(), 0.025) end
        return self.colorRamp[-5]
    end

    --- Helps with SNKRX visual styling. This function is used in the shop to capitalize unit names
    -- @treturn string Capitalized unit name
    function hero:capitalize()
        return self.name:gsub("_", " "):capitalize()
    end

    --- Creates a colored string containing the class name
    -- @treturn string
    function hero:createClassString()
        local result = {}

        for _, class in ipairs(self.classes) do
            if class.mod ~= nil then
                table.insert(result, '[' .. class:distinctName() .. ']' .. class:capitalize())
            else table.insert(result, '[' .. class_color_strings[class] .. ']' .. class:capitalize()) end
        end

        return table.concat(result, ", ")
    end

    --- Sets the level three effect of this hero
    -- @tparam LevelThree level_three The level three effect
    function hero:setLevelThree(level_three)
        level_three.hero = self
        self.level_three = level_three
        global_text_tags[level_three:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(level_three:getRenderColor()) end}
    end

    --- Gets this hero's level three effect
    -- @treturn LevelThree
    function hero:getLevelThree()
        return self.level_three
    end

    --- Sets function to be called when this unit should repeat.<br>
    -- Will only be called if the unit is in the sorcerer class
    -- @tparam function func This function will be called with the following parameter:<br>
    -- - `player`: The player object
    function hero:setRepeat(func)
        self.repeat_func = func
    end

    hero:setLevelThree(LevelThree({
        name = "Unknown",
        description = "The mod author has not defined a level three effect",
        color = red,
        hero = hero
    }))

    return hero
end

--- The definition of the Hero. Used in `Mod:createHero`
-- @type HeroDefinition
local Definition = {}
--- The name of the hero, should be unique per mod
-- @string[opt="ModHero"] name
Definition.name = "ModHero"

--- The description of the hero. Setting this to a function will call it with the hero's current level
-- @see hero:getDescription
-- @tparam[opt="ModHeroDescription"] string|function description
Definition.description = "ModHeroDescription"

--- The tier of the unit. This is used for rarities in the shop.
-- @tparam[opt=1] number tier
Definition.tier = 1

--- A list of classes that this unit belongs to.
-- @todo revamp class system and update it here
-- @tparam[opt={"warrior"}] {string|Class} classes
Definition.classes = {}

-- @section end

return v