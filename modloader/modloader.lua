--- Utility functions exposed by the Modloader.
-- Functions in this file are not tied to any one mod
-- @module ModLoader

require 'modloader.modmenu'

-- replace this when you turn the base game into a "mod"
local default_passive_pool = {
    'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista', 'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
    'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping', 'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
    'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow', 'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
    'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback', 'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
    'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste', 'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
    'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike', 'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
    'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening', 'kinetic_strike',
}

local Mod = require("modloader.mod")
local createGlobals = require("modloader.modglobals")

ModLoader = {}

--- Set the environment variable `DEVELOPER_MODE` to enable "developer mode"
ModLoader.developerMode = os.getenv("DEVELOPER_MODE") ~= nil
--- Set the environment variable `EXTRA_DEBUG_INFO` to enable extra info in debug logs
ModLoader.extraDebugInfo = os.getenv("EXTRA_DEBUG_INFO") ~= nil
--- Set the environment variable `DEBUG_MEMORY` to enable memory debugging
ModLoader.debugMemory = os.getenv("DEBUG_MEMORY") ~= nil
--- Set the environment variable `DEBUG_TYPES` to enable debugging types
ModLoader.debugTypes = os.getenv("DEBUG_TYPES") ~= nil

---
-- A list of loaded mods.
-- Do not modify this table directly.
ModLoader.loadedMods = {}
---
-- A list of enabled mods.
-- Do not modify this table directly.
ModLoader.enabledMods = {}

ModLoader.heroTierMap = {}
ModLoader.eventHandlers = {}

ModLoader.patches = {}

ModLoader.ModShapes = require 'modloader.modshapes'

local function wrapFunctions(obj, name)
    for k,v in pairs(obj) do
        if k ~= "__index" then
            if type(v) == "function" and v ~= print then
                local info = debug.getinfo(v, "S")
                if info.what ~= "C" then
                    obj[k] = function(...)
                        local f = ModLoader.patches[name .. "." .. k]
                        if not f then return v(...) end
                        local s, e = pcall(f, v, ...)
                        if not s then
                            ModLoader.error(e)
                            return v(...)
                        end
                        return e
                    end
                end
            elseif type(v) == "table" then
                if not (v == Object or v == love or v == table or v == string or v == math or v == _G or v == package or v == debug or v == os) then
                    wrapFunctions(v, name .. "." .. k)
                end
            end
        end
    end
end

local function stringStartsWith(str, start)
    return str:sub(1, #start) == start
end

function ModLoader.load()
    -- initialize ModLoader state

    wrapFunctions(_G, "_G")

    if ModLoader.developerMode then ModLoader.debug("developer mode enabled") end
    if ModLoader.extraDebugInfo then ModLoader.debug("showing extra debug info") end

    -- add a package loader for lua require
    do
        local function simpleLoader(value)
            return function() return value end
        end
        
        table.insert(package.loaders, 2, function(modname)
            if modname == "modloader" or modname == "Modloader" then return simpleLoader(ModLoader) end
            if not ModLoader.loadedMods then return end
            local mod = ModLoader.loadedMods[modname]
            if mod ~= nil then return simpleLoader(mod) end

            for _,v in ipairs(ModLoader.loadedMods) do
                if stringStartsWith(modname .. ".", v.name) then
                    local parts = string.split(modname, ".")
                    _, parts = table.shift(parts, 1)
                    local path = v._mod_folder .. "/" .. table.concat(parts, "/")
                    local fsinfo = love.filesystem.getInfo(path .. ".lua", "file")
                    if fsinfo ~= nil then
                        return love.filesystem.load(path .. ".lua")
                    else
                        fsinfo = love.filesystem.getInfo(path .. "/init.lua", "file")
                        if fsinfo ~= nil then
                            return love.filesystem.load(path .. "/init.lua")
                        end
                    end
                end
            end
        end)
    end

    -- replace builtin heroes and classes
    do
        -- ModLoader.loadedMods["snkrx"] = Mod{
        --     name = "snkrx",
        --     description = "Base game",
        --     author = "adn",
        --     version = "1.0",
        --     main_file = "",
        --     mod_folder = ""
        -- }
        
        -- ModLoader.loadedMods["snkrx"]:addShopCondition(function(all_units)
        --     return not table.all(all_units, function(v) return table.any(non_attacking_characters, function(u) return v == u end) end)
        -- end)

        ModLoader.loadedMods["snkrx"] = require("modloader.vanilla")
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
        ModLoader.pushEvent("mods_loaded", ModLoader.loadedMods)
    end

    -- enable mods
    do
        if not system.does_file_exist(ModLoader.getModsFolder() .. "enabled.txt") then
            ModLoader.enableMod("snkrx")
            ModLoader.writeEnabledMods()
        else
            for _,v in ipairs(ModLoader.readEnabledMods()) do
                ModLoader.enableMod(v)
            end
        end
    end

    ModLoader.pushEvent("modloader_done")
end

--- Gets the mods folder on the filesystem
-- @treturn string The mods folder *relative to the LOVE data folder*
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
    if mod._onLoad then mod:_onLoad() end
end

function ModLoader.unpackModZip(file)
    local path = "mods/_temp/";
    local success = love.filesystem.mount("mods/" .. file, "mods/_temp/")
    if not success then return false end

    ModLoader.debug("attempting to parse " .. file)

    local modDefinition, err = love.filesystem.read(path .. "mod_data.txt")

    if not modDefinition then
        ModLoader.error("error parsing " .. file .. ": " .. err)
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

    ModLoader.debug("finished parsing " .. name .. ". beginning to unpack")

    if ModLoader.modExists(name) then
        ModLoader.error("error unpacking " .. name .. ": directory already exists")
        return false
    end

    love.filesystem.createDirectory("mods/" .. name)

    local failed = false

    for _,file in ipairs(system.enumerate_files("mods/_temp")) do
        local fileName = string.sub(file, string.len("mods/_temp") + 1)
        ModLoader.debug("unpacking " .. fileName)
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

    ModLoader.log("finished unpacking " .. name)

    return name
end

--- Removes a hero added by the specified mod
-- @modresolvable mod Mod can either be a string or a Mod object
-- @tparam string|Hero hero The hero to be removed
function ModLoader.removeHero(mod, hero)
    if mod == nil then
        -- remove hero from base game here
    else
        if type(mod) == "string" and ModLoader.enabledMods[mod] then
            mod = ModLoader.enabledMods[mod]
        end
        if type(hero) == "string" then
            mod._heroes[hero] = nil
            return
        end
        mod._heroes[hero.name] = nil
    end
end

--- Removes and replaces a hero added by the specified mod
-- @modresolvable mod The mod to remove the hero from
-- @modresolvable newmod The mod to add the new hero to
-- @tparam Hero.HeroDefinition hero The definition of the hero to create
-- @see Mod:createHero
function ModLoader.replaceHero(mod, newmod, hero)
    ModLoader.removeHero(mod, hero)
    if type(newmod) == "string" and ModLoader.enabledMods[newmod] then
        newmod = ModLoader.enabledMods[newmod]
    end
    return newmod:createHero(hero)
end

function ModLoader.getFileName(file)
    return file:match("^.+/(.+)$")
end

function ModLoader.getFileExtension(file)
    return file:match("^.+(%..+)$")
end

--- Returns a list of all units in the game
-- @return A list of all units in the game
function ModLoader.aggregateHeroes()
    local aggregate = {}
    for _, mod in pairs(ModLoader.enabledMods) do
        for _, hero in pairs(mod._heroes) do
            table.insert(aggregate, hero)
        end
    end
    return aggregate
end

--- Gets a list of all classes in the game
-- @return A list of all classes in the game
function ModLoader.aggregateClasses()
    local aggregate = {}
    for _, mod in pairs(ModLoader.enabledMods) do
        for _, class in pairs(mod._classes) do
            table.insert(aggregate, class)
        end
    end
    return aggregate
end

--- Gets a list of all items in the game
-- @return A list of all items in the game
function ModLoader.aggregateItems()
    local aggregate = {}
    for _, mod in pairs(ModLoader.enabledMods) do
        for _, item in pairs(mod._items) do
            table.insert(aggregate, item)
        end
    end

    return aggregate
end

--- Gets a list of all the shop conditions. Used for modifying the results of the reroll button
-- @return A list of all shop conditions
function ModLoader.aggregateShopConditions()
    local aggregate = {}
    for _, mod in pairs(ModLoader.enabledMods) do
        for _, condition in pairs(mod._shopConditions) do
            table.insert(aggregate, condition)
        end
    end

    return aggregate
end

function ModLoader.aggregateX(key)
    local aggregate = {}
    for _, mod in pairs(ModLoader.enabledMods) do
        for _, x in pairs(mod[key]) do
            table.insert(aggregate, x)
        end
    end

    return aggregate
end

--- Verifies that every condition is met
-- @tparam table all_units A list of units that would be generated if this function returns true
-- @tparam BuyScreen buyScreen The instance of the BuyScreen
-- @treturn bool True if the list of units is okay, false if it should be rerolled again
function ModLoader.verifyShopConditions(all_units, buyScreen)
    for _,v in ipairs(ModLoader.aggregateShopConditions()) do
        if not v(all_units, buyScreen) then return false end
    end

    return true
end

function ModLoader.randomHero(tier_weights, except_heroes)
    except_heroes = except_heroes or {}
    -- unit_1 = random:table(tier_to_characters[random:weighted_pick(unpack(tier_weights))])
    local tier = random:weighted_pick(unpack(tier_weights))

    -- local combined = table.copy(tier_to_characters[tier])
    local combined = {}

    for _, hero in pairs(ModLoader.aggregateHeroes()) do
        if hero.tier == tier then
            table.insert(combined, hero)
        end
    end

    for i,v in ipairs(combined) do
        if table.contains(except_heroes, v) then table.remove(combined, i) end
    end

    return random:table(combined)
end

--- Returns a random item
-- @tparam[opt] table current_items A list of items that the player already has. This prevents the player from finding duplicates in the Arena
-- @treturn Item|string Will return a string if a vanilla item is picked. In the future, this will be changed.
function ModLoader.randomItem(current_items)
    current_items = current_items or {}
    -- after you convert all the vanilla stuff into a "mod", you won't need this part
    local combined = table.shallow_copy(default_passive_pool)
    -- local combined = {}
    combined = table.reject(combined, function(v)
        return not table.contains(current_items, v)
    end)

    for _, item in pairs(ModLoader.aggregateItems()) do
        if not table.any(current_items, function(v)
            return type(v) == "table" and v:distinctName() == item:distinctName()
        end) then table.insert(combined, item) end
    end

    -- for i,v in ipairs(combined) do print(i,v) end

    return random:table(combined)
end

function ModLoader.isCharacterModded(character)
    return type(character) == "table" and character.name ~= nil
end

function ModLoader.isXModded(x)
    return type(x) == "table" and x.distinctName ~= nil
end

function ModLoader.addArenaWall(x, y, w, h)
    local arena = ModLoader.getArena()
    if not arena then return nil end
    return ModLoader.ModShapes.NewWall{group = arena.main, x = x, y = y, w = w, h = h}
end

--- Calls a function whenever an event is fired of the specified type.<br>
-- NOTE: this is subject to change as the ModLoader develops. Expect more functional events in the future
-- @string eventName The name of the event you want to listen to
-- @func handler The function to be called with the event data
-- @treturn function A reference to the event handler, can be used to cancel it
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

--- Pushes an event to all registered event handlers<br>
-- NOTE: this is subject to change as the ModLoader develops. Expect more functional events in the future
-- @string eventName The name of the event to fire
-- @param ... The rest of the event data, passed directly to the event handler
function ModLoader.pushEvent(eventName, ...)
    local event = {cancelled = false}
    local i = 0
    for _,h in pairs(ModLoader.eventHandlers[eventName] or {}) do
        i = i + 1
        h.handler(h, event, ...)
        if event.cancelled then break end
    end
    ModLoader.debug("pushed event " .. eventName .. " (" .. i .. ")")
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

    if run.passives then
        local newPassives = run.passives
        run.passives = {}

        for _, passive in ipairs(newPassives) do
            if ModLoader.isXModded(passive.passive) then
                local u = {
                    name = passive.passive.name,
                    mod = passive.passive.mod.name
                }
                passive = {
                    passive = u,
                    level = passive.level,
                    xp = passive.xp
                }
            end
            table.insert(run.passives, passive)
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

--- Checks if a mod is enabled
-- @modresolvable mod
-- @treturn bool Whether or not the mod is enabled
function ModLoader.isModEnabled(mod)
    if type(mod) == "table" then
        return table.rcontains(ModLoader.enabledMods, mod)
    else
        return ModLoader.enabledMods[mod] ~= nil
    end
end

--- Enables a mod. This should be done only in rare cases where you must ensure the order of enabled mods.<br>
-- Attempting to enable an already enabled mod will not do anything
-- @modresolvable mod
function ModLoader.enableMod(mod)
    if mod == nil then return end
    if type(mod) == "table" then
        if ModLoader.enabledMods[mod.name] ~= nil then return end
        ModLoader.log("enabling " .. mod.name)
        ModLoader.enabledMods[mod.name] = mod
        ModLoader.pushEvent("mod_enabled", mod)
        if mod._onEnable then mod:_onEnable() end
    else
        ModLoader.enableMod(ModLoader.loadedMods[mod])
    end

    ModLoader.writeEnabledMods()
end

--- Disables a mod.<br>
-- If you would disable a mod because of a conflict, instead get in touch with the ModLoader developers to see if that conflict will be resolved in a future update.
-- @modresolvable mod
function ModLoader.disableMod(mod)
    if mod == nil then return end
    if type(mod) == "table" then
        if mod._onDisable then mod:_onDisable() end
        ModLoader.enabledMods[mod.name] = nil
        ModLoader.log("disabling " .. mod.name)
        ModLoader.pushEvent("mod_disabled", mod)
    else
        ModLoader.disableMod(ModLoader.enabledMods[mod])
    end

    ModLoader.writeEnabledMods()
end

function ModLoader.parse_run(run)
    if run.units then
        local newUnits = table.shallow_copy(run.units)
        run.units = {}

        for _, unit in ipairs(newUnits) do
            local add = true
            if unit.hero then
                local mod = ModLoader.enabledMods[unit.hero.mod]
                if mod then
                    unit.hero = mod._heroes[unit.hero.name]
                else add = false end
            end

            if add then table.insert(run.units, unit) end
        end
    end

    if run.passives then
        local newPassives = table.shallow_copy(run.passives)
        run.passives = {}

        for _, passive in ipairs(newPassives) do
            local add = true
            if type(passive.passive) == "table" then
                local mod = ModLoader.enabledMods[passive.passive.mod]
                if mod then
                    local n = {
                        xp = passive.xp,
                        level = passive.level,
                        passive = mod._items[passive.passive.name]
                    }
                    passive = n
                else add = false end
            end

            if add then table.insert(run.passives, passive) end
        end
    end

    if run.locked_state then
        local newCards = table.shallow_copy(run.locked_state.cards)
        run.locked_state.cards = {}

        for _, card in ipairs(newCards) do
            if type(card) == "table" then
                local mod = ModLoader.enabledMods[card.mod]
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

--- Checks if a mod exists. This can be useful if your mod relies on another.<br>
-- NOTE: this checks if the mod is found on the filesystem. To check if a mod is *loaded*, look for it in `ModLoader.loadedMods` or `ModLoader.enabledMods`
-- @string modName
-- @treturn bool Whether or not the mod is found
function ModLoader.modExists(modName)
    return ModLoader.isDirectory("mods/" .. modName)
end

function ModLoader.getMemoryUsage()
    return math.round(tonumber(collectgarbage("count"))/1024, 3)
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

function ModLoader.writeEnabledMods()
    local v = {}
    for k,_ in pairs(ModLoader.enabledMods) do
        table.insert(v, k)
    end
    local contents = table.concat(v, "\n")
    local success, msg = love.filesystem.write("mods/enabled.txt", contents)
    if not success then
        ModLoader.error("error writing enabled mods: " .. msg)
        return false
    end

    return true
end

function ModLoader.readEnabledMods()
    local contents, error = love.filesystem.read("mods/enabled.txt")
    if contents == nil then
        ModLoader.error("error reading enabled mods: " .. error)
        return {}
    end

    local v = {}
    for w in string.gmatch(contents, "([^\n]+)") do table.insert(v, w) end

    return v
end

--- Returns the current instance of the Arena
-- @treturn Arena|nil The instance of the Arena, or nil if it cannot be found.
function ModLoader.getArena()
    return main:get("arena")
end

--- Logs a message to the console *as the ModLoader*<br>
-- If you would like to log a message from your mod, use `Mod:log` instead.
-- @param ... The data to be logged to the console
function ModLoader.log(...)
    local b = {...}
    local t = ""
    for _,v in ipairs(b) do
        t = t .. tostring(v) .. "\t"
    end
    io.stdout:write("[SNKMD] " .. t .. "\n")
    io.stdout:flush()
end

--- Logs a debug message to the console *as the ModLoader*<br>
-- If `ModLoader.developerMode` is unset, the message will not be logged. If `ModLoader.extraDebugInfo` is set, then extra debug info will be displayed.
-- @param ... The data to be logged to the console
function ModLoader.debug(...)
    if not ModLoader.developerMode then return end
    local b = {...}
    local t = "[SNKMD][D]"
    if ModLoader.extraDebugInfo then
        local gi = debug.getinfo(2)
        t = t .. "(" .. gi.short_src .. ":" .. gi.currentline .. ")"
    end
    t = t .. " "
    for _,v in ipairs(b) do
        t = t .. tostring(v) .. "\t"
    end
    io.stdout:write(t .. "\n")
    io.stdout:flush()
end

--- Logs an error message to the console *as the ModLoader*<br>
-- If you would like to log a message from your mod, use `Mod:error` instead.<br>
-- @param ... The error data to be logged to the console
function ModLoader.error(...)
    local b = {...}
    local t = ""
    for _,v in ipairs(b) do
        t = t .. tostring(v) .. "\t"
    end
    io.stderr:write("[SNKMD][ERR] " .. t .. "\n")
    io.stderr:flush()
end

_G.print = ModLoader.debug