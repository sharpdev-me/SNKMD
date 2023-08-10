--- Items are passive effects that can apply to the arena
-- @classmod Item

local item = function(mod, definition)
    local item = {}

    --- The item's name
    -- @string[opt="ModItem"] name
    item.name = definition.name or "ModItem"
    if mod._items[definition.name] then return nil, "item already exists" end

    --- The description of the item. Setting this to a function will call it with the item's current level
    -- @tparam[opt="ModItemDescription"] string|function description
    item.description = definition.description or "ModItemDescription"

    --- A table of upgrades per level.<br>
    -- NOTE: These are the number of upgrades needed to move from the *current* level to the next.<br>
    -- So, if this table is {2,3} then at level 1 the unit will need 2 upgrades to move to level 2, and at level 2 it will need 3.
    -- @tparam[opt] table levels
    item.levels = definition.levels or {2,3}

    --- The image that this item will display when it's rendered
    -- @tparam[opt=ultimatum] ModImage image
    item.image = definition.image or _G["ultimatum"]

    --- The cost of one *upgrade*<br>
    -- The number of ugprades needed per level is determined by `item.levels`
    -- @number[opt=5] xp_cost
    item.xp_cost = definition.xp_cost or 5

    --- The base value of the item when selling it.
    -- @number[opt=10] base_sell_cost
    item.base_sell_cost = definition.base_sell_cost or 10

    --- The mod that this item belongs to
    -- @tparam Mod mod
    item.mod = mod

    --- Creates a unique identifier for this item
    -- @treturn string A unique identifier
    function item:distinctName()
        return self.mod.name .. self.name
    end

    --- Gets the description of the item at the current level
    -- @number level The level of the item
    -- @treturn string The description of the item
    function item:getDescription(level)
        if type(self.description) == "function" then return self:description(level) else return self.description end
    end

    --- Calculates the sell cost for an item at the current level.<br>
    -- This number is calculated as follows: `self.base_sell_cost + (self.xp_cost * self.levels[level]))`
    -- @number level The level of the item
    -- @treturn number The amount this item should sell for
    function item:getSellCost(level)
        local sellCost = self.base_sell_cost
        if level == 1 then return sellCost end
        repeat
            level = level - 1
            sellCost = sellCost + self.xp_cost * self.levels[level]
        until level <= 1

        return sellCost
    end

    --- Tries to figure out the level of the item.
    -- @treturn number The level of the unit, or -1 if it can't be found
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

--- The definition used in `Mod:createItem`
-- @type ItemDefinition
local Definition = {}

--- The item's name
-- @string[opt="ModItem"] name
Definition.name = nil

--- The description of the item. Setting this to a function will call it with the item's current level
-- @tparam[opt="ModItemDescription"] string|function description
Definition.description = nil

--- A table of upgrades per level.<br>
-- NOTE: These are the number of upgrades needed to move from the *current* level to the next.<br>
-- So, if this table is {2,3} then at level 1 the unit will need 2 upgrades to move to level 2, and at level 2 it will need 3.
-- @tparam[opt] table levels
Definition.levels = nil

--- The image that this item will display when it's rendered
-- @tparam[opt=ultimatum] ModImage image
Definition.image = nil

--- The cost of one *upgrade*<br>
-- The number of ugprades needed per level is determined by `item.levels`
-- @number[opt=5] xp_cost
Definition.xp_cost = nil

--- The base value of the item when selling it.
-- @number[opt=10] base_sell_cost
Definition.base_sell_cost = nil
--- @section end

return item