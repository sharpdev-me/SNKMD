local ModShapes = require 'modloader.modshapes'
local ModTypes = require 'modloader.modtypes'
local JSON = require 'modloader.external.json'

local function ExtraGlobals(mod)
    return {
        Shapes = ModShapes,
        Types = ModTypes,
        JSON = JSON,
        print = mod.print,
        require = function(modname)
            if modname == "Mod" or modname == "mod" or modname == "self" or modname == "Self" then return mod end
            return require(modname)
        end
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