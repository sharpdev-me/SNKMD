require 'modloader.modmenu'
local zip = require 'zip'

ModLoader = {}

local Mod = require("modloader.mod")
local createGlobals = require("modloader.modglobals")

ModLoader.loadedMods = {}
ModLoader.heroTierMap = {}

function ModLoader.load()
    -- initialize ModLoader state

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
    end
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
    local zFile = zip.open(ModLoader.getModsFolder() .. file)
    if not zFile then return false end

    ModLoader.log("attempting to parse " .. file)

    local modDefinition = zFile:open("mod_data.txt")

    if not modDefinition then
        ModLoader.log("error parsing " .. file .. ": mod_data.txt not found")
        return false
    end

    local properties, msg = ModLoader.parseModFile(modDefinition)
    if not properties then
        ModLoader.error("error parsing " .. file .. ": " .. msg)
        return false
    end

    modDefinition:close()

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

    for file in zFile:files() do
        ModLoader.log("unpacking " .. file.filename .. " (" .. math.round(file.uncompressed_size / 1024, 1) .. "KB)")
        local fileHandle = zFile:open(file.filename)
        local fileData = fileHandle:read("*a")

        fileHandle:close()
        if fileData ~= nil and fileData ~= "" then
            if not ModLoader.writeFileInModFolder(name, file.filename, fileData) then
                ModLoader.error("there was an error writing " .. file.filename)
                failed = true
                break
            end
        end
    end

    zFile:close()

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

function ModLoader.aggregateHeroes()
    local aggregate = {}
    for _, mod in pairs(ModLoader.loadedMods) do
        for _, hero in pairs(mod._heroes) do
            table.insert(aggregate, hero)
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

function ModLoader.stringifyRun(run)
    if run.units then
        local newUnits = table.shallow_copy(run.units)
        run.units = {}

        for _, unit in ipairs(newUnits) do
            if unit.hero then
                local u = {
                    name = unit.hero.name,
                    mod = unit.hero.mod.name
                }

                local uu = table.shallow_copy(unit)
                uu.hero = u
                table.insert(run.units, uu)
            else
                table.insert(run.units, unit)
            end
        end
    end

    return table.tostring(run)
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