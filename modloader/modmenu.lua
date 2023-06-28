ModMenu = Object:extend()
ModMenu:implement(State)

function ModMenu:init(name)
  self:init_state(name)
end

function ModMenu:on_enter(from)
    camera.x, camera.y = gw/2, gh/2
    self.w = gw
    self.h = gh

    self.t = Trigger()

    self.main_ui = Group():no_camera()

    self.title_text = Text({{text = '[wavy_mid, fg]Mods', font = fat_font, alignment = 'center'}}, global_text_tags)

    self.back_button = Button{group = self.main_ui, x = 40, y = gh - 15, force_update = true, button_text = 'main menu', fg_color = 'bg10', bg_color = 'bg', action = function(b)
        self.transitioning = true
        ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
          main:add(MainMenu'main_menu')
          main:go_to('main_menu')
        end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']loading...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
    end}

    local kT = {}
    for k,_ in pairs(ModLoader.loadedMods) do
        table.insert(kT, k)
    end

    table.sort(kT)

    local i = 0
    for _,v in ipairs(kT) do
        ModCard{group = self.main_ui, x = 80 + (85 * i), y = self.title_text.h + 80, w = 80, h = 65, mod = ModLoader.loadedMods[v]}
        i = 1 + i
    end

    self.t:every(0.375, function()
        local p = random:table(star_positions)
        Star{group = star_group, x = p.x, y = p.y}
    end)
end

function ModMenu:on_exit()
    self.main_ui:destroy()
end

function ModMenu:draw()
    star_canvas:draw(0, 0, 0, 1, 1)
    graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent)

    self.main_ui:draw()

    self.title_text:draw(gw / 2, self.title_text.h + 5)
end

function ModMenu:update(dt)
    self.t:update(dt*slow_amount)

    if not self.paused and not self.transitioning then
        star_group:update(dt*slow_amount)
        self.main_ui:update(dt*slow_amount)
    end
end

ToggleButton = Object:extend()
ToggleButton:implement(GameObject)

function ToggleButton:init(args)
    self:init_game_object(args)
    self.interact_with_mouse = true

    local v = self.mod:isEnabled() and "enabled" or "disabled"

    self.text = Text({{text = '[fg]' .. v, font = pixul_font, alignment = 'center'}}, global_text_tags)
    self.shape = Rectangle(self.x, self.y, 54, 16)
end

function ToggleButton:update(dt)
    self:update_game_object(dt)
end

function ToggleButton:draw()
    local v = self.mod:isEnabled() and "enabled" or "disabled"
    self.text:set_text{{text = '[fg]' .. v, font = pixul_font, alignment = 'center'}}
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
        graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.mod:isEnabled() and green[0] or red[0])
        self.text:draw(self.x, self.y + 1)
    graphics.pop()
end

function ToggleButton:die()
    self.dead = true
    self.text.dead = true
    self.text = nil
end

ModCard = Object:extend()
ModCard:implement(GameObject)

function ModCard:init(args)
    self:init_game_object(args)
    self.shape = Rectangle(self.x, self.y, self.w, self.h)
    self.interact_with_mouse = true

    self.spring:pull(0.2, 200, 10)

    -- contains image & title & stuff
    self.data = self.mod:getModCardData()

    self.title_text = Text({{text = self.data.name, font = pixul_font, alignment = "center"}}, global_text_tags)
    self.toggle_button = ToggleButton{mod = self.mod, group = self.main_ui, x = self.x, y = self.y + 17}
end

function ModCard:update(dt)
    self:update_game_object(dt)

    if self.selected and input.m1.pressed then
        if self.mod:isEnabled() then
            ModLoader.disableMod(self.mod)
        else
            ModLoader.enableMod(self.mod)
        end
    end
end

function ModCard:select()
    self.selected = true
    self.spring:pull(0.2, 200, 10)
    self.t:every_immediate(1.4, function()
      if self.selected then
        self.t:tween(0.7, self, {sx = 0.97, sy = 0.97, plus_r = -math.pi/32}, math.linear, function()
          self.t:tween(0.7, self, {sx = 1.03, sy = 1.03, plus_r = math.pi/32}, math.linear, nil, 'pulse_1')
        end, 'pulse_2')
      end
    end, nil, nil, 'pulse')
end

function ModCard:unselect()
    self.selected = false
    self.t:cancel'pulse'
    self.t:cancel'pulse_1'
    self.t:cancel'pulse_2'
    self.t:tween(0.1, self, {sx = 1, sy = 1, plus_r = 0}, math.linear, function() self.sx, self.sy, self.plus_r = 1, 1, 0 end, 'pulse')
end

function ModCard:draw()
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    
        graphics.rectangle(self.x, self.y, self.w, self.h, 5, 5, bg[2])
        self.title_text:draw(self.x, self.y - 17)
        self.data.image:draw(self.x, self.y - 3, 0, 0.5, 0.5)
        self.toggle_button:draw()

    graphics.pop()
end

function ModCard:on_mouse_enter()
    ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.selected = true
    self.spring:pull(0.1)
end

function ModCard:on_mouse_exit()
    self.selected = false
end

function ModCard:die(dont_spawn_effect)
    self.dead = true
    self.title_text.dead = true
    self.title_text = nil
end