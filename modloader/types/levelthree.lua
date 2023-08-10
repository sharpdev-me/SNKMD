--- Describes the level three effect for a unit. Currently only used in the shop
-- @classmod LevelThree

local levelthree = function(definition)
    local levelThree = {}

    --- The name of the level three effect
    -- @string name
    levelThree.name = definition.name or "Unknown"

    --- The description of the level three effect
    -- @string description
    levelThree.description = definition.description or "The mod author has not defined a level three effect"

    --- The color of the level three effect, typically the same as the hero's color
    -- @tparam Color color
    levelThree.color = definition.color or red

    --- Creates a unique identifier for this level three effect
    -- @treturn string A unique identifier
    function levelThree:distinctName()
        local heroName = (self.hero == nil) and "unknown" or self.hero.name
        local modName = (self.hero == nil) and "unknown" or self.hero.mod.name

        return modName .. heroName .. self.name
    end

    --- Creates the display string for this level three effect
    -- @bool isActive Whether or not the unit is level three
    -- @treturn string
    function levelThree:getString(isActive)
        if not isActive then return "[light_bg]" .. self.name else return '[' .. self:distinctName() .. ']' .. self.name end
    end

    --- Gets the description for the level three effect
    -- @bool isActive Whether or not the unit is level three
    -- @treturn string
    function levelThree:getDescription(isActive)
        local text = type(self.description) == "function" and self.description(self) or self.description
        if not isActive then return "[light_bg]" .. text:gsub("%[%w+%]", "") else return "[fg]" .. text end
    end

    --- Gets the render color for the level three effect.<br>
    -- To see how this is determinated, see `Hero:getRenderColor`
    -- @treturn Color
    function levelThree:getRenderColor()
        local hColor = self.color

        if hColor[0] ~= nil then return hColor[0] else return hColor end
    end

    return levelThree
end

--- The definition of the Level Three effect.
-- @type LevelThreeDefinition
local Definition = {}
--- The name of the level three effect
-- @string name
Definition.name = nil

--- The description of the level three effect
-- @string description
Definition.description = nil

--- The color of the level three effect, typically the same as the hero's color
-- @tparam Color color
Definition.color = nil
--- @section end

return levelthree