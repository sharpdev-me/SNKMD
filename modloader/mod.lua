--- The type that all Mods extend.
-- @classmod Mod
local MHero = require 'modloader.types.hero'
local MClass = require 'modloader.types.class'
local ModShapes = require 'modloader.modshapes'

return function(data)
    local mod = setmetatable({}, {
        __call = function (t)
            return t
        end
    })
    --- The name of the mod.
    mod.name = data.name
    --- The mod's author.
    mod.author = data.author
    --- The description of the mod.
    mod.description = data.description
    --- The mod's version.
    mod.version = data.version

    mod._main_file = data.main_file
    mod._mod_folder = data.mod_folder

    mod.modCard = {}

    mod._heroes = {}
    mod._classes = {}
    mod._items = {}

    mod._shopConditions = {}

    mod._patches = {}

    mod._onLoad = function(self) end
    mod._onEnable = function(self) end
    mod._onDisable = function(self) end

    --- Sets a function to be automatically called when the mod is loaded.
    -- Note: this function will be run **even if your mod is disabled**
    -- @func func The function to be called when the mod is loaded
    function mod:onLoad(func)
        self._onLoad = func
    end

    --- Sets a function to be automatically called when the mod is enabled.
    -- This is where you should initialize your mod's state and add event handlers and patches
    -- @func func The function to be called when the mod is enabled
    -- @see ModLoader.addEventHandler
    function mod:onEnable(func)
        self._onEnable = func
    end

    --- Sets a function to be automatically called when the mod is disabled.
    -- This is where you will cleanup your mod's state. This is where you will remove event handlers and patches.
    -- @func func The function to be called when the mod is disabled
    -- @see mod:unpatchAll
    function mod:onDisable(func)
        self._onDisable = func
    end

    --- Gets the mod's configuration folder relative to the LOVE directory
    -- @treturn string The path of the mod's configuration folder
    function mod:getConfigurationFolder()
        return self._mod_folder .. "/config"
    end

    --- Gets the mod's configuration folder as an absolute path
    -- @treturn string The absolute path of the mod's configuration folder
    function mod:getConfigurationFolderAbsolute()
        return self:getModFolderAbsolute() .. "/config"
    end

    --- Gets the mod's folder as an absolute path
    -- @treturn string The absolute path of the mod's folder
    function mod:getModFolderAbsolute()
        return love.filesystem.getSaveDirectory() .. "/" .. self._mod_folder
    end

    --- Returns the mod's configuration
    -- @treturn unknown The data loaded from the mod's `config.lua` file
    function mod:getConfiguration()
        if self.configuration then
            return self.configuration
        else
            local configPath = self:getConfigurationFolder() .. "/config.lua"
            local configChunk, err = love.filesystem.load(configPath)
            if not configChunk then
                self:error(err)
                return nil, err
            end

            self.configuration = configChunk()

            return self.configuration
        end
    end

    ---
    -- @string eventName The name of the event to listen to
    -- @func handler The function to be called with the event data
    -- @see ModLoader.addEventHandler
    function mod:addEventHandler(eventName, handler)
        return ModLoader.addEventHandler(eventName, handler)
    end

    function mod:getModCardData()
        -- make the default mod card data here
        -- if one of the fields from self#setModCardData(modCardData) is missing, then replace it with the default value
        local v = {}
        v.name = self.modCard.name or self.name
        v.image = self.modCard.image or meat_shield

        return v
    end

    function mod:setModCardData(modCardData)
        if type(modCardData) ~= "table" then
            self:error("modCardData is not of type \"table\"")
            return
        end
        self.modCard = modCardData
    end

    function mod:isEnabled()
        return ModLoader.isModEnabled(self)
    end

    function mod:log(...)
        local b = {...}
        local t = ""
        for _,v in ipairs(b) do
            t = t .. tostring(v) .. "\t"
        end
        io.stdout:write("[" .. self.name .. "] " .. t .. "\n")
        io.stdout:flush()
    end

    function mod:error(...)
        local b = {...}
        local t = ""
        for _,v in ipairs(b) do
            t = t .. tostring(v) .. "\t"
        end
        io.stdout:write("[" .. self.name .. "][ERR] " .. t .. "\n")
        io.stdout:flush()
    end

    function mod:addShopCondition(comp)
        if type(comp) ~= "function" then
            mod:error("shop condition comp was not of type \"function\"")
            return
        end

        table.insert(self._shopConditions, comp)
    end

    --- Registers a new hero.<br>
    -- NOTE: While it would be good practice to only add heroes in `mod:onEnable`, only enabled mods will have heroes added to the game.<br>
    -- @tparam Hero.HeroDefinition definition
    function mod:createHero(definition)
        local hero, err = MHero(self, definition)
        if hero == nil then
            self:error(err)
            return nil
        end

        self._heroes[hero.name] = hero

        global_text_tags[hero:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(hero:getRenderColor()) end}

        return hero
    end

    function mod:createClass(definition)
        local class, err = MClass(self, definition)
        if class == nil then
            self:error(err)
            return nil
        end

        self._classes[class.name] = class

        global_text_tags[class:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(class:getRenderColor()) end}

        return class
    end

    function mod:createItem(definition)
        local item, err = MItem(self, definition)
        if item == nil then
            self:error(err)
            return nil
        end

        self._items[item.name] = item

        return item
    end

    -- Should only be called in the arena
    function mod:getAllUnits()
        return main.current.units
    end

    function mod:getArena()
        return ModLoader.getArena()
    end

    function mod:disableMod()
        ModLoader.disableMod(self)
    end

    function mod:patchFunction(patchPath, patch)
        self._patches[patchPath] = patch
        ModLoader.patches[patchPath] = patch

        return function()
            return mod:unpatchFunction(patchPath)
        end
    end

    function mod:unpatchFunction(patchPath)
        if not self:isPatched(patchPath, true) then return false end
        self._patches[patchPath] = nil
        ModLoader.patches[patchPath] = nil

        return true
    end

    function mod:isPatched(patchPath, strict)
        if not strict then strict = false end

        local patch = ModLoader.patches[patchPath]
        if not patch then return false end
        if not strict then return true end

        return patch == self._patches[patchPath]
    end

    --- Disables all patches added by the mod
    function mod:unpatchAll()
        for k,_ in pairs(self._patches) do
            mod:unpatchFunction(k)
        end
    end

    return mod
end