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