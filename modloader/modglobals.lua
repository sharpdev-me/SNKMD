local ModShapes = require 'modloader.modshapes'
local ModTypes = require 'modloader.modtypes'
local JSON = require 'modloader.external.json'
local orginal_path = love.filesystem.getRequirePath()

local function ExtraGlobals(mod)
    love.filesystem.setRequirePath(orginal_path .. ";" .. mod._mod_folder .. "/?.lua;" .. "mods/?.lua")
    return {
        Shapes = ModShapes,
        Types = ModTypes,
        JSON = JSON,
        print = mod.print
    }
end

return function(mod)
    local extraGlobals = ExtraGlobals(mod)
    return setmetatable({}, {
        __index = function(self, key)
            if key == "self" then return mod end
            if mod[key] ~= nil then
                local v = mod[key]
                if type(v) == "function" then
                    return function(...)
                        return v(mod, ...)
                    end
                end
                return v
            end
            if extraGlobals[key] ~= nil then return extraGlobals[key] end
            return _G[key]
        end
    })
end