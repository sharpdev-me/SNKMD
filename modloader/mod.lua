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

    return mod
end