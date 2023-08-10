--- The base type for all custom classes.
-- To avoid breaking other mods, developers should use `Mod:createClass` instead of directly creating a Class object.
-- @classmod Class

local class = function(mod, definition)
    local class = {}

    --- The name of the class
    -- @string[opt="ModClass"] name
    class.name = definition.name or "ModClass"
    if mod._classes[definition.name] then return nil, "class already exists" end

    --- The description of the hero. Setting this to a function will call it with the hero's current level
    -- @tparam[opt="ModClassDescription"] string|function description Setting this value to a function will call the function with the number of units and expect a string result.
    class.description = definition.description or "ModClassDescription"

    --- The color of this class. This color may be used by units in the class.
    -- @tparam[opt=green] Color color
    class.color = definition.color or green

    --- The level groups for this class. Used to create shop tooltips and calculate the level of the class. (e.g: `{2,4,6}` or `{1,3,7}`)
    -- @tparam[opt={1}] table groups
    class.groups = definition.groups or {1}

    --- The image display in the shop for this class
    -- @tparam[opt=ranger] ModImage image
    class.image = definition.image or _G["ranger"]

    --- The stats that units should inherit
    -- @tparam Stats stats
    class.stats = definition.stats or {}

    --- Stats for units and classes is likely to be reworked in the near future. Expected breaking changes for this section.
    -- @type Stats

    --- Hit Points
    -- @number[opt=1] hp
    class.stats.hp = definition.stats.hp or 1

    --- Damage
    -- @number[opt=1] dmg
    class.stats.dmg = definition.stats.dmg or 1

    --- Attack Speed
    -- @number[opt=1] aspd
    class.stats.aspd = definition.stats.aspd or 1

    --- Area Damage
    -- @number[opt=1] area_dmg
    class.stats.area_dmg = definition.stats.area_dmg or 1

    --- Area Size
    -- @number[opt=1] area_size
    class.stats.area_size = definition.stats.area_size or 1

    --- Defense
    -- @number[opt=1] def
    class.stats.def = definition.stats.def or 1

    --- Move Speed
    -- @number[opt=1] mvspd
    class.stats.mvspd = definition.stats.mvspd or 1

    -- @section end

    --- The mod this class belongs to
    -- @tparam Mod mod
    class.mod = mod

    --- Creates a unique identifier for this class
    -- @treturn string A unique identifier
    function class:distinctName()
        return self.mod.name .. self.name
    end

    --- Gets the color of the class
    -- @treturn Color
    function class:getColor()
        return self.color
    end

    --- Gets the render color of the class.
    -- @see Hero:getRenderColor
    -- @treturn Color
    function class:getRenderColor()
        if self.color[0] ~= nil then return self.color[0] else return self.color end
    end

    --- Gets the dim color of the class.
    -- @see Hero:getDimColor
    -- @treturn Color
    function class:getDimColor()
        if not self.colorRamp then self.colorRamp = ColorRamp(self:getRenderColor(), 0.025) end
        return self.colorRamp[-5]
    end

    --- Capitalizes the name of the class
    -- @see Hero:capitalize
    -- @treturn string
    function class:capitalize()
        return self.name:gsub("_", " "):capitalize()
    end

    --- Returns the description of the class. If `Class.description` is a function, it will be called with the number of units.
    -- @number num_units
    -- @treturn string
    function class:getDescription(num_units)
        if type(self.description) == "function" then return self:description(num_units) else return self.description end
    end

    --- Returns a colored version of the description using the class's render colors
    -- @see Class:getDescription
    -- @number num_units
    -- @treturn string A colored description
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

    --- Calculates the number of units in the snake that have this class.
    -- @treturn number The number of units in the snake with this class
    function class:getNumberOfUnits()
        return get_number_of_units_per_class(self.mod:getAllUnits())[self]
    end

    --- Calculates the class level
    -- @treturn number The level of the class, calculated using `Class.groups`
    function class:getClassLevel()
        return get_class_levels(self.mod:getAllUnits())[self]
    end

    return class
end

--- The definition of the Class. Used in `Mod:createClass`
-- @type ClassDefinition
local Definition = {}
--- The name of the class
-- @string[opt="ModClass"] name
Definition.name = nil

--- The description of the class
-- @tparam[opt="ModClassDescription"] string|function description Setting this value to a function will call the function with the number of units and expect a string result.
Definition.description = nil

--- The color of this class. This color may be used by units in the class.
-- @tparam[opt=green] Color color
Definition.color = nil

--- The level groups for this class. Used to create shop tooltips and calculate the level of the class. (e.g: `{2,4,6}` or `{1,3,7}`)
-- @tparam[opt={1}] table groups
Definition.groups = nil

--- The image display in the shop for this class
-- @tparam[opt=_G["ranger"]] ModImage image
Definition.image = nil

--- The stats that units should inherit
-- @tparam Stats stats
Definition.stats = nil
-- @section end

return class