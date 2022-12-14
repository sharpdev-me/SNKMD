local ModTypes = require 'modloader.modtypes'
local ModShapes = require 'modloader.modshapes'

return function(data)
    local mod = {}
    mod.name = data.name
    mod.author = data.author
    mod.description = data.description
    mod.version = data.version
    mod._main_file = data.main_file
    mod._mod_folder = data.mod_folder

    mod._heroes = {}
    mod._classes = {}

    function mod:getConfigurationFolder()
        return self._mod_folder .. "/config"
    end

    function mod:getConfigurationFolderAbsolute()
        return self:getModFolderAbsolute() .. "/config"
    end

    function mod:getModFolderAbsolute()
        return love.filesystem.getSaveDirectory() .. "/" .. self._mod_folder
    end

    function mod:getConfiguration()
        if mod.configuration then
            return mod.configuration
        else
            local configPath = self:getConfigurationFolder() .. "/config.lua"
            local configChunk, err = love.filesystem.load(configPath)
            if not configChunk then
                self:error(err)
                return nil, err
            end

            mod.configuration = configChunk()

            return mod.configuration
        end
    end

    function mod:addEventHandler(eventName, handler)
        return ModLoader.addEventHandler(eventName, handler)
    end

    function mod:log(msg)
        io.stdout:write("[" .. self.name .. "] " .. msg .. "\n")
        io.stdout:flush()
    end

    function mod:error(msg)
        io.stderr:write("[" .. self.name .. "][ERROR] " .. msg .. "\n")
        io.stderr:flush()
    end

    function mod:createHero(definition)
        definition.name = definition.name or "ModHero"
        if self._heroes[definition.name] then return nil, "hero already exists" end
        definition.description = definition.description or "ModHeroDescription"
        definition.tier = definition.tier or 1
        -- TODO: revamp class system and update it here
        definition.classes = definition.classes or {"warrior"}
        definition.mod = self

        local hero = ModTypes.Hero(definition)

        self._heroes[hero.name] = hero

        global_text_tags[hero:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(hero:getRenderColor()) end}

        return hero
    end

    function mod:createClass(definition)
        definition.name = definition.name or "ModClass"
        if self._classes[definition.name] then return nil, "class already exists" end
        definition.description = definition.description or "ModClassDescription"
        definition.color = definition.color or green
        definition.groups = definition.groups or {1}
        definition.image = definition.image or _G["ranger"]
        definition.stats = definition.stats or {}

        definition.stats.hp = definition.stats.hp or 1
        definition.stats.dmg = definition.stats.dmg or 1
        definition.stats.aspd = definition.stats.aspd or 1
        definition.stats.area_dmg = definition.stats.area_dmg or 1
        definition.stats.area_size = definition.stats.area_size or 1
        definition.stats.def = definition.stats.def or 1
        definition.stats.mvspd = definition.stats.mvspd or 1

        definition.mod = self

        local class = ModTypes.Class(definition)

        self._classes[class.name] = class

        global_text_tags[class:distinctName()] = TextTag{draw = function(c, i, text) graphics.set_color(class:getRenderColor()) end}

        return class
    end

    -- Should only be called in the arena
    function mod:getAllUnits()
        return main.current.units
    end

    return mod
end