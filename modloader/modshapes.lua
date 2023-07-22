local ModShapes = {}

local OpenCircle = Object:extend()
OpenCircle:implement(GameObject)

function OpenCircle:init(args)
    self:init_game_object(args)

    if not self.shape then self.shape = Circle(self.x, self.y, self.rs) else
        self.x = self.shape.x
        self.y = self.shape.y
        self.rs = self.shape.rs
    end

    self.color_transparent = Color(self.color.r, self.color.g, self.color.b, 0.08)

    self.hidden = false

    self.vr = 0
    self.dvr = random:float(-math.pi/4, math.pi/4)
end

function OpenCircle:update(dt)
    self:update_game_object(dt)
    self.vr = self.vr + self.dvr*dt
end

function OpenCircle:draw()
    if self.hidden then return end
  
    graphics.push(self.x, self.y, self.r + self.vr, self.spring.x, self.spring.x)
      -- graphics.circle(self.x, self.y, self.shape.rs + random:float(-1, 1), self.color, 2)
      graphics.circle(self.x, self.y, self.shape.rs, self.color_transparent)
      local lw = math.remap(self.shape.rs, 32, 256, 2, 4)
      for i = 1, 4 do graphics.arc('open', self.x, self.y, self.shape.rs, (i-1)*math.pi/2 + math.pi/4 - math.pi/8, (i-1)*math.pi/2 + math.pi/4 + math.pi/8, self.color, lw) end
    graphics.pop()
end

function OpenCircle:scale(v)
    self.shape = Circle(self.x, self.y, (v or 1)*self.rs)
end

local NewWall = Object:extend()
NewWall:implement(GameObject)
NewWall:implement(Physics)

function NewWall:init(args)
    self:init_game_object(args)
    self:set_as_rectangle(self.w, self.h, "static", "solid")
    self.color = self.color or fg[0]
end

function NewWall:update(dt)
    self:update_game_object(dt)
end

function NewWall:draw()
    self.shape:draw(self.color)
end

ModShapes.NewWall = NewWall
ModShapes.OpenCircle = OpenCircle

return ModShapes