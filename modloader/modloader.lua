require 'modloader.modmenu'

local Mod = require("modloader.mod")
local createGlobals = require("modloader.modglobals")

ModLoader = {}

ModLoader.loadedMods = {}
ModLoader.heroTierMap = {}
ModLoader.eventHandlers = {}

ModLoader.loadedMods["snkrx"] = Mod{
    name = "snkrx",
    description = "Base game",
    author = "adn",
    version = "1.0",
    main_file = "",
    mod_folder = ""
}

function ModLoader.load()
    -- initialize ModLoader state

    -- replace builtin heroes and classes
    do
        
    end

    -- load mods from mod folder
    do
        if not system.does_file_exist(ModLoader.getModsFolder()) then
            love.filesystem.createDirectory("mods")
        end

        local modFolderFiles = love.filesystem.getDirectoryItems("mods")

        for _,v in ipairs(modFolderFiles) do
            if ModLoader.modExists(v) then
                ModLoader.loadMod(v)
            else
                local r = ModLoader.unpackModZip(v)
                if r then ModLoader.loadMod(r) end
            end
        end

        ModLoader.pushEvent("mods_loaded", unpack(ModLoader.loadedMods))
    end

    ModLoader.pushEvent("modloader_done")
end

function ModLoader.getModsFolder()
    return system.get_save_directory() .. "/mods/"
end

function ModLoader.loadMod(modName)
    ModLoader.log("loading " .. modName)
    local modFolder = "mods/" .. modName

    local modDefinition = io.open(ModLoader.getModsFolder() .. modName .. "/mod_data.txt", "r")
    
    if not modDefinition then
        ModLoader.error("error loading " .. modName .. ": missing mod_data.txt")
        return false
    end
    local properties = ModLoader.parseModFile(modDefinition)
    modDefinition:close()

    if not properties then
        ModLoader.error("error loading " .. modName .. ": malformed mod_data.txt")
        return false
    end

    local name = properties.name
    if not name then
        ModLoader.error("error loading " .. modName .. ": mod_data.txt is missing 'name' field")
        return false
    end

    local main = properties.main
    if not main then
        ModLoader.error("error loading " .. name .. ": mod_data.txt is missing 'main' field")
        return false
    end

    local mod = Mod{
        name = name,
        description = properties.description,
        author = properties.author,
        version = properties.version,
        main_file = main,
        mod_folder = modFolder
    }

    local mainHandle, mainError = io.open(ModLoader.getModsFolder() .. modName .. "/" .. mod._main_file, "r")
    if not mainHandle then
        ModLoader.error("error loading " .. name .. ": " .. mainError)
        return false
    end

    local mainData = mainHandle:read("*a")
    mainHandle:close()

    local globals = createGlobals(mod)

    local mainLoad, mainLoadError = load(mainData, name, "bt", globals)
    if not mainLoad then
        ModLoader.error("error loading " .. name .. ": " .. mainLoadError)
        return false
    end
    local pcallResult, msg = pcall(mainLoad)
    if not pcallResult then
        ModLoader.error("there was en error loading " .. name .. ": " .. msg)
        return false
    else
        ModLoader.log("loaded " .. name)
    end

    ModLoader.loadedMods[name] = mod
end

function ModLoader.unpackModZip(file)
    local path = "mods/_temp/";
    local success = love.filesystem.mount("mods/" .. file, "mods/_temp/")
    if not success then return false end

    ModLoader.log("attempting to parse " .. file)

    local modDefinition, err = love.filesystem.read(path .. "mod_data.txt")

    if not modDefinition then
        ModLoader.log("error parsing " .. file .. ": " .. err)
        return false
    end

    local properties, msg = ModLoader.parseModString(modDefinition)
    if not properties then
        ModLoader.error("error parsing " .. file .. ": " .. msg)
        return false
    end

    local name = properties.name
    if not name then
        ModLoader.error("error parsing " .. file .. ": mod_data.txt is missing 'name' field")
        return false
    end

    local main = properties.main
    if not main then
        ModLoader.error("error parsing " .. file .. ": mod_data.txt is missing 'main' field")
        return false
    end

    ModLoader.log("finished parsing " .. name .. ". beginning to unpack")

    if ModLoader.modExists(name) then
        ModLoader.error("error unpacking " .. name .. ": directory already exists")
        return false
    end

    love.filesystem.createDirectory("mods/" .. name)

    local failed = false

    for _,file in ipairs(system.enumerate_files("mods/_temp")) do
        local fileName = string.sub(file, string.len("mods/_temp") + 1)
        ModLoader.log("unpacking " .. fileName)
        local fileData = love.filesystem.read(file)

        if fileData ~= nil and fileData ~= "" then
            if not ModLoader.writeFileInModFolder(name, fileName, fileData) then
                ModLoader.error("there was an error writing " .. fileName)
                failed = true
                break
            end
        end
    end

    if failed then
        ModLoader.error("there was an error unpacking " .. name .. ". no changes will be made")
        ModLoader.removeDirectory("mods/" .. name)
        return false
    end

    if not love.filesystem.remove("mods/" .. file) then
        ModLoader.error("there was an error removing the mod's zip file. you should try to delete it manually.")
        return false
    end

    ModLoader.log("finished unpacking " .. name .. "!")

    return name
end

function ModLoader.removeHero(mod, hero)
    if mod == nil then
        -- remove hero from base game here
    else
        if type(mod) == "string" and ModLoader.loadedMods[mod] then
            mod = ModLoader.loadedMods[mod]
        end
        if type(hero) == "string" then
            mod._heroes[hero] = nil
            return
        end
        mod._heroes[hero.name] = nil
    end
end

function ModLoader.replaceHero(mod, newmod, hero)
    ModLoader.removeHero(mod, hero)
    if type(newmod) == "string" and ModLoader.loadedMods[newmod] then
        newmod = ModLoader.loadedMods[newmod]
    end
    newmod:createHero(hero)
end

function ModLoader.getFileName(file)
    return file:match("^.+/(.+)$")
end

function ModLoader.getFileExtension(file)
    return file:match("^.+(%..+)$")
end

function ModLoader.aggregateHeroes()
    local aggregate = {}
    for _, mod in pairs(ModLoader.loadedMods) do
        for _, hero in pairs(mod._heroes) do
            table.insert(aggregate, hero)
        end
    end
    return aggregate
end

function ModLoader.aggregateClasses()
    local aggregate = {}
    for _, mod in pairs(ModLoader.loadedMods) do
        for _, class in pairs(mod._classes) do
            table.insert(aggregate, class)
        end
    end
    return aggregate
end

function ModLoader.randomHero(tier_weights)
    -- unit_1 = random:table(tier_to_characters[random:weighted_pick(unpack(tier_weights))])
    local tier = random:weighted_pick(unpack(tier_weights))

    local combined = table.copy(tier_to_characters[tier])
    -- local combined = {}

    for _, hero in pairs(ModLoader.aggregateHeroes()) do
        if hero.tier == tier then table.insert(combined, hero) end
    end

    return random:table(combined)
end

function ModLoader.isCharacterModded(character)
    return type(character) == "table" and character.name ~= nil
end

function ModLoader.addEventHandler(eventName, handler)
    if not ModLoader.eventHandlers[eventName] then ModLoader.eventHandlers[eventName] = {} end
    local eventHandler = {
        eventName = eventName,
        handler = handler,

        cancel = function(self)
            local t = ModLoader.eventHandlers[self.eventName]
            table.remove(t, table.index(t, self))
        end
    }

    table.insert(ModLoader.eventHandlers[eventName], eventHandler)

    return eventHandler
end

function ModLoader.pushEvent(eventName, ...)
    local event = {cancelled = false}
    for _,h in pairs(ModLoader.eventHandlers[eventName] or {}) do
        h.handler(h, event, ...)
        if event.cancelled then break end
    end
    return event
end

function ModLoader.convertForStringification(unit)
    local u = {
        name = unit.hero.name,
        mod = unit.hero.mod.name
    }

    local uu = table.shallow_copy(unit)
    uu.hero = u

    return uu
end

function ModLoader.stringifyRun(run)
    if run.units then
        local newUnits = table.shallow_copy(run.units)
        run.units = {}

        for _, unit in ipairs(newUnits) do
            if unit.hero then
                local uu = ModLoader.convertForStringification(unit)
                table.insert(run.units, uu)
            else
                table.insert(run.units, unit)
            end
        end
    end

    local newCards
    if run.locked_state then
        newCards = table.shallow_copy(run.locked_state.cards)
        run.locked_state.cards = {}

        for _, card in ipairs(newCards) do
            if ModLoader.isCharacterModded(card) then
                local u = {
                    name = card.name,
                    mod = card.mod.name
                }
                table.insert(run.locked_state.cards, u)
            else
                table.insert(run.locked_state.cards, card)
            end
        end
    end

    local r = table.tostring(run)
    if run.locked_state then run.locked_state.cards = newCards end
    return r
end

function ModLoader.parse_run(run)
    if run.units then
        local newUnits = table.shallow_copy(run.units)
        run.units = {}

        for _, unit in ipairs(newUnits) do
            local add = true
            if unit.hero then
                local mod = ModLoader.loadedMods[unit.hero.mod]
                if mod then
                    unit.hero = mod._heroes[unit.hero.name]
                else add = false end
            end

            if add then table.insert(run.units, unit) end
        end
    end

    if run.locked_state then
        local newCards = table.shallow_copy(run.locked_state.cards)
        run.locked_state.cards = {}

        for _, card in ipairs(newCards) do
            if type(card) == "table" then
                local mod = ModLoader.loadedMods[card.mod]
                if mod then
                    table.insert(run.locked_state.cards, mod._heroes[card.name])
                end
            else
                table.insert(run.locked_state.cards, card)
            end
        end
    end

    return run
end

function ModLoader.isDirectory(dir)
    return love.filesystem.getInfo(dir, "directory") ~= nil
end

function ModLoader.modExists(modName)
    return ModLoader.isDirectory("mods/" .. modName)
end

function ModLoader.removeDirectory(directory)
    local files = system.enumerate_files(directory)

    for _, file in ipairs(files) do
        love.filesystem.remove(file)
    end

    love.filesystem.remove(directory)
end

function ModLoader.parseModFile(fileHandle)
    local properties = {}

    local line = fileHandle:read("*l")
    if not line then
        return false, "malformed mod_data.txt"
    end

    while line do
        local kv = line:split("=")
        properties[kv[1]] = kv[2]
        line = fileHandle:read("*l")
    end

    return properties
end

function ModLoader.parseModString(fileData)
    local properties = {}

    for line in fileData:gmatch("([^\n\r]*)[\n\r]?") do
        local kv = line:split("=")
        if kv[1] then properties[kv[1]] = kv[2] end
    end

    return properties
end

function ModLoader.writeFileInModFolder(modName, file, contents)
    local filePath = "mods/" .. modName .. "/" .. file

    local success, msg = love.filesystem.write(filePath, contents)
    if not success then
        ModLoader.error("error writing " .. filePath .. ": " .. msg)
        return false
    end
    return true
end

function ModLoader.log(msg)
    io.stdout:write("[SNKMD] " .. msg .. "\n")
    io.stdout:flush()
end

function ModLoader.error(msg)
    io.stderr:write("[SNKMD] " .. msg .. "\n")
    io.stderr:flush()
end