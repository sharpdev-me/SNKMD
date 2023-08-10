--- Extra types that don't belong anywhere else
-- @module ModLoader.ModTypes
local ModTypes = {}

ModTypes.ModImage = Object:extend()

function ModTypes.ModImage:init(mod, image_path)
    local filePath = mod:getModFolderAbsolute() .. "/" .. image_path
    local file = io.open(filePath, "r")
    if not file then return nil end
    local data = love.filesystem.newFileData(file:read("*a"), ModLoader.getFileName(filePath))
    self.image = love.graphics.newImage(data)
    self.w = self.image:getWidth()
    self.h = self.image:getHeight()
end

---
function ModTypes.ModImage:draw(x, y, r, sx, sy, ox, oy, color)
  local _r, g, b, a
  if color then
    _r, g, b, a = love.graphics.getColor()
    graphics.set_color(color)
  end
  love.graphics.draw(self.image, x, y, r or 0, sx or 1, sy or sx or 1, self.w/2 + (ox or 0), self.h/2 + (oy or 0))
  if color then love.graphics.setColor(_r, g, b, a) end
end

return ModTypes