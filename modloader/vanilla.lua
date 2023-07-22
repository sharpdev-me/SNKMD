local Mod = require("modloader.mod")
local ModTypes = require("modloader.modtypes")

local vanilla = Mod{
    name = "snkrx",
    description = "Base game",
    author = "adn",
    version = "1.0",
    main_file = "",
    mod_folder = ""
}

for k,_ in pairs(character_classes) do
    vanilla[k] = vanilla:createHero{
        name = k,
        classes = character_classes[k],
        tier = character_tiers[k],
        color = character_colors[k],

        description = function(self, lvl)
            return character_descriptions[k](lvl)
        end
    }

    vanilla[k]:setLevelThree(ModTypes.LevelThree{
        name = character_effect_names_gray[k]:sub(("[light_bg]"):len()),
        description = character_effect_descriptions[k],
        color = character_colors[k],
        hero = vanilla[k]
    })
end

-- just to make it nicer for me to convert all these
local u = setmetatable({}, {
    __newindex = function (table, key, value)
        local hero = vanilla[key]
        if not hero then
            ModLoader.debug("vanilla hero not found (" .. key .. ")")
            return
        end
        if hero.init ~= nil then
            ModLoader.debug("assigned vanilla hero init twice (" .. key .. ")")
            return
        end

        hero.init = function(self, player)
            return value(player)
        end
    end
})

u["vagrant"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 96)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy))
      end
    end, nil, nil, 'shoot')
end

u["swordsman"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 48)
    self.t:cooldown(3, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      self:attack(96)
    end, nil, nil, 'attack')
end

u["wizard"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 128)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy), {chain = (self.level == 3 and 2 or 0)})
      end
    end, nil, nil, 'shoot')
end

u["magician"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 96)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      if self.magician_invulnerable then return end
      local enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
      if enemy then
        self:attack(32, {x = enemy.x, y = enemy.y})
      end
    end, nil, nil, 'attack')
    if self.level == 3 then
      self.t:every(12, function()
        self.magician_aspd_m = 1.5
        self.t:after(6, function() self.magician_aspd_m = 1 end, 'magician_aspd_m')
      end)
    end
end

u["gambler"] = function(self)
  local cast = function(pitch_a)
    local enemy = table.shuffle(main.current.main:get_objects_by_classes(main.current.enemies))[1]
    if enemy then
      gambler1:play{pitch = pitch_a, volume = math.clamp(math.remap(gold, 0, 50, 0, 0.5), 0, 0.75)}
      enemy:hit(2*gold)
      self:repeatIfNecessary(true)
    end
  end
  self.t:every(2, function()
    cast(1)
    if self.level == 3 then
      if random:bool(60) then
        if random:bool(40) then
          if random:bool(20) then
            self.t:after(0.25, function()
              cast(1.1)
              self.t:after(0.25, function()
                cast(1.2)
                self.t:after(0.25, function()
                  cast(1.3)
                end)
              end)
            end)
          else
            self.t:after(0.25, function()
              cast(1.1)
              self.t:after(0.25, function()
                cast(1.2)
              end)
            end)
          end
        else
          self.t:after(0.25, function()
            cast(1.1)
          end)
        end
      end
    end
  end, nil, nil, 'attack')
end
vanilla["gambler"].sorcerer_repeat_delay = 0.25
vanilla["gambler"]:setRepeat(function(self)
  local enemy = table.shuffle(main.current.main:get_objects_by_classes(main.current.enemies))[1]
  gambler1:play{pitch = 1.1, volume = math.clamp(math.remap(gold, 0, 50, 0, 0.5), 0, 0.75)}
  enemy:hit(2*gold)
end)

u["archer"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 160)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy), {pierce = 1000, ricochet = (self.level == 3 and 3 or 0)})
      end
    end, nil, nil, 'shoot')
end

u["scout"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 64)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy), {chain = (self.level == 3 and 6 or 3)})
      end
    end, nil, nil, 'shoot')
end

u["thief"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 64)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy), {chain = (self.level == 3 and 10 or 5)})
      end
    end, nil, nil, 'shoot')
end

u["cleric"] = function(self)
    self.t:every(8, function()
        if self.level == 3 then
          for i = 1, 4 do
            local check_circle = Circle(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16), 2)
            local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Sentry, Automaton, Bomb, Volcano, Saboteur, Pet, Turret})
            while #objects > 0 do
              check_circle:move_to(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16))
              objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Sentry, Automaton, Bomb, Volcano, Saboteur, Pet, Turret})
            end
            SpawnEffect{group = main.current.effects, x = check_circle.x, y = check_circle.y, color = green[0], action = function(x, y)
              local check_circle = Circle(x, y, 2)
              local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Sentry, Automaton, Bomb, Volcano, Saboteur, Pet, Turret})
              if #objects == 0 then
                HealingOrb{group = main.current.main, x = x, y = y}
              end
            end}
          end
        else
          local check_circle = Circle(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16), 2)
          local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Sentry, Automaton, Bomb, Volcano, Saboteur, Pet, Turret})
          while #objects > 0 do
            check_circle:move_to(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16))
            objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Sentry, Automaton, Bomb, Volcano, Saboteur, Pet, Turret})
          end
          SpawnEffect{group = main.current.effects, x = check_circle.x, y = check_circle.y, color = green[0], action = function(x, y)
            local check_circle = Circle(x, y, 2)
            local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Sentry, Automaton, Bomb, Volcano, Saboteur, Pet, Turret})
            if #objects == 0 then
              HealingOrb{group = main.current.main, x = x, y = y}
            end
          end}
        end
        --[[
        local all_units = self:get_all_units()
        local unit_index = table.contains(all_units, function(v) return v.hp <= 0.5*v.max_hp end)
        if unit_index then
          local unit = all_units[unit_index]
          self.last_heal_time = love.timer.getTime()
          if self.level == 3 then
            for _, unit in ipairs(all_units) do unit:heal(0.2*unit.max_hp*(self.heal_effect_m or 1)) end
          else
            unit:heal(0.2*unit.max_hp*(self.heal_effect_m or 1))
          end
          heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        end
        ]]--
    end, nil, nil, 'heal')
end

u["arcanist"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(4, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    if closest_enemy then
      self:shoot(self:angle_to_object(closest_enemy), {pierce = 10000, v = 40})
      self:repeatIfNecessary(true)
    end
  end, nil, nil, 'shoot')
end
vanilla["arcanist"].sorcerer_repeat_delay = 0.25
vanilla["arcanist"]:setRepeat(function(self)
  local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
  if closest_enemy then
    self:shoot(self:angle_to_object(closest_enemy), {pierce = 10000, v = 40})
  end
end)

u["artificer"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.t:every(6, function()
    SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = self.color, action = function(x, y)
      artificer1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      local check_circle = Circle(self.x, self.y, 2)
      local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Pet, Turret, Sentry, Bomb})
      if #objects == 0 then Automaton{group = main.current.main, x = x, y = y, parent = self, level = self.level, conjurer_buff_m = self.conjurer_buff_m or 1} end
      if #objects == 0 then self:repeatIfNecessary(true) end
    end}
  end, nil, nil, 'spawn')
end
vanilla["artificer"].sorcerer_repeat_delay = 0.25
vanilla["artificer"]:setRepeat(function(self)
  SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = self.color, action = function(x, y)
    artificer1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    local check_circle = Circle(self.x, self.y, 2)
    local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Pet, Turret, Sentry, Bomb})
    if #objects == 0 then Automaton{group = main.current.main, x = x, y = y, parent = self, level = self.level, conjurer_buff_m = self.conjurer_buff_m or 1} end
  end}
end)

u["outlaw"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 96)
    self.t:cooldown(3, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy), {homing = (self.level == 3)})
      end
    end, nil, nil, 'shoot')
end

u["blade"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 64)
    self.t:cooldown(4, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      self:shoot()
    end, nil, nil, 'shoot')
end

u["elementor"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 128)
    self.t:cooldown(7, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
      if enemy then
        self:attack(128, {x = enemy.x, y = enemy.y})
      end
    end, nil, nil, 'attack')
end

u["psychic"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, self.level == 3 and 512 or 64)
  self.t:cooldown(3, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local strike = function()
      local enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
      if enemy then
        if self.level == 3 then
          self:attack(32, {x = enemy.x, y = enemy.y})
          self.t:after(0.5, function()
            local enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
            if enemy then
              self:attack(32, {x = enemy.x, y = enemy.y})
            end
          end)
        else
          self:attack(32, {x = enemy.x, y = enemy.y})
        end
      end
    end
    strike()
    self:repeatIfNecessary(true)
  end, nil, nil, 'attack')
end
vanilla["psychic"].sorcerer_repeat_delay = 0.1
vanilla["psychic"]:setRepeat(function(self)
  local enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
  if enemy then
    if self.level == 3 then
      self:attack(32, {x = enemy.x, y = enemy.y})
      self.t:after(0.5, function()
        local enemy = self:get_random_object_in_shape(self.attack_sensor, main.current.enemies)
        if enemy then
          self:attack(32, {x = enemy.x, y = enemy.y})
        end
      end)
    else
      self:attack(32, {x = enemy.x, y = enemy.y})
    end
  end
end)

u["saboteur"] = function(self)
    self.t:every(8, function()
        self.t:every(0.25, function()
          SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = self.color, action = function(x, y)
            Saboteur{group = main.current.main, x = x, y = y, parent = self, level = self.level, conjurer_buff_m = self.conjurer_buff_m or 1, crit = (self.level == 3) and random:bool(50)}
          end}
        end, 2)
    end, nil, nil, 'spawn')
end

u["bomber"] = function(self)
    self.t:every(8, function()
        SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = self.color, action = function(x, y)
          Bomb{group = main.current.main, x = x, y = y, parent = self, level = self.level, conjurer_buff_m = self.conjurer_buff_m or 1}
        end}
    end, nil, nil, 'spawn')
end

u["stormweaver"] = function(self)
    self.t:every(8, function()
        stormweaver1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        local units = self:get_all_units()
        for _, unit in ipairs(units) do
          unit:chain_infuse(4)
        end
    end, nil, nil, 'buff')
end

u["sage"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 96)
    self.t:cooldown(9, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy))
      end
    end, nil, nil, 'shoot')
end

u["cannoneer"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 128)
    self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy))
      end
    end, nil, nil, 'shoot') 
end

u["vulcanist"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 128)
  self.t:every(12, function()
    local volcano = function()
      local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
      local x, y = 0, 0
      if enemies and #enemies > 0 then
        for _, enemy in ipairs(enemies) do
          x = x + enemy.x
          y = y + enemy.y
        end
        x = x/#enemies
        y = y/#enemies
      end
      if x == 0 and y == 0 then x, y = gw/2, gh/2 end
      x, y = x + self.x, y + self.y
      x, y = x/2, y/2
      main.current.t:every_immediate(0.1, function()
        local check_circle = Circle(x, y, 2)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Player, Seeker, EnemyCritter, Critter, Saboteur, Pet, Turret, Sentry, Bomb})
        if #objects == 0 then
          Volcano{group = main.current.main, x = x, y = y, color = self.color, parent = self, rs = 24, level = self.level}
          main.current.t:cancel('volcano_spawn')
        end
      end, nil, nil, 'volcano_spawn')
    end
    volcano()
    self:repeatIfNecessary(true)
  end, nil, nil, 'attack')
end
vanilla["vulcanist"].sorcerer_repeat_delay = 0.5
vanilla["vulcanist"]:setRepeat(function(self)
  local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
  local x, y = 0, 0
  if enemies and #enemies > 0 then
    for _, enemy in ipairs(enemies) do
      x = x + enemy.x
      y = y + enemy.y
    end
    x = x/#enemies
    y = y/#enemies
  end
  if x == 0 and y == 0 then x, y = gw/2, gh/2 end
  x, y = x + self.x, y + self.y
  x, y = x/2, y/2
  main.current.t:every_immediate(0.1, function()
    local check_circle = Circle(x, y, 2)
    local objects = main.current.main:get_objects_in_shape(check_circle, {Player, Seeker, EnemyCritter, Critter, Saboteur, Pet, Turret, Sentry, Bomb})
    if #objects == 0 then
      Volcano{group = main.current.main, x = x, y = y, color = self.color, parent = self, rs = 24, level = self.level}
      main.current.t:cancel('volcano_spawn')
    end
  end, nil, nil, 'volcano_spawn')
end)

u["dual_gunner"] = function(self)
    self.dg_counter = 0
    self.attack_sensor = Circle(self.x, self.y, 96)
    self.gun_kata_sensor = Circle(self.x, self.y, 160)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy))
      end
    end, nil, nil, 'shoot')
end

u["hunter"] = function(self)
    self.attack_sensor = Circle(self.x, self.y, 160)
    self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
      if closest_enemy then
        self:shoot(self:angle_to_object(closest_enemy))
      end
    end, nil, nil, 'shoot')
end

u["chronomancer"] = function(self)
    if self.level == 3 then
        main.current.chronomancer_dot = 0.5
    end
end

u["spellblade"] = function(self)
    self.t:every(2, function()
        self:shoot(random:float(0, 2*math.pi))
    end, nil, nil, 'shoot')
end

u["psykeeper"] = function(self)
    self.stored_heal = 0
    self.last_heal_time = love.timer.getTime()
end

u["engineer"] = function(self)
  self.t:every(8, function()
    SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = orange[0], action = function(x, y)
      Turret{group = main.current.main, x = x, y = y, parent = self}
    end}
  end, nil, nil, 'spawn')

  if self.level == 3 then
    self.t:every(24, function()
      SpawnEffect{group = main.current.effects, x = self.x - 16, y = self.y + 16, color = orange[0], action = function(x, y) Turret{group = main.current.main, x = x, y = y, parent = self} end}
      SpawnEffect{group = main.current.effects, x = self.x + 16, y = self.y + 16, color = orange[0], action = function(x, y) Turret{group = main.current.main, x = x, y = y, parent = self} end}

      self.t:after(0.5, function()
        local turrets = main.current.main:get_objects_by_class(Turret)
        buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        for _, turret in ipairs(turrets) do
          HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = orange[0], duration = 0.1}
          LightningLine{group = main.current.effects, src = self, dst = turret, color = orange[0]}
          turret:upgrade()
        end
      end)
    end)
  end
end

u["plague_doctor"] = function(self)
  self.t:every(5, function()
    self:dot_attack(24, {duration = 12, plague_doctor_unmovable = true})
  end, nil, nil, 'attack')

  if self.level == 3 then
    self.t:after(0.01, function()
      self.dot_area = DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.area_size_m*48, color = self.color, dmg = self.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self}
    end)
  end
end

u["witch"] = function(self)
  self.t:every(4, function()
    self:dot_attack(42, {duration = random:float(12, 16)})
    self:repeatIfNecessary(true)
  end, nil, nil, 'attack')
end
vanilla["witch"].sorcerer_repeat_delay = 0.25
vanilla["witch"]:setRepeat(function(self)
  self:dot_attack(42, {duration = random:float(12, 16)})
end)

u["barbarian"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 48)
  self.t:cooldown(8, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    self:attack(96, {stun = 4})
  end, nil, nil, 'attack')
end

u["juggernaut"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 64)
  self.t:cooldown(8, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    self:attack(128, {juggernaut_push = true})
  end, nil, nil, 'attack')
end

u["lich"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(4, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    if closest_enemy then
      self:shoot(self:angle_to_object(closest_enemy), {chain = (self.level == 3 and 14 or 7), v = 140})
    end
  end, nil, nil, 'shoot')
end

u["cryomancer"] = function(self)
  self.t:after(0.01, function()
    self.dot_area = DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.area_size_m*72, color = self.color, dmg = self.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self}
  end)
end

u["pyromancer"] = function(self)
  self.t:after(0.01, function()
    self.dot_area = DotArea{group = main.current.effects, x = self.x, y = self.y, rs = self.area_size_m*48, color = self.color, dmg = self.area_dmg_m*self.dmg, character = self.character, level = self.level, parent = self}
  end)
end

u["corruptor"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 160)
  self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    if closest_enemy then
      self:shoot(self:angle_to_object(closest_enemy), {spawn_critters_on_kill = 3, spawn_critters_on_hit = (self.level == 3 and 2 or nil)})
    end
  end, nil, nil, 'shoot')
end

u["beastmaster"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 160)
  self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    if closest_enemy then
      self:shoot(self:angle_to_object(closest_enemy), {spawn_critters_on_crit = 2})
    end
  end, nil, nil, 'shoot')
end

u["launcher"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, enemy in ipairs(enemies) do
      if self:distance_to_object(enemy) < 128 then
        local resonance_dmg = 0
        if self.resonance then resonance_dmg = (self.level == 3 and 6*self.dmg*0.05*#enemies or 2*self.dmg*0.05*#enemies) end
        enemy:curse('launcher', 4*(self.hex_duration_m or 1), (self.level == 3 and 6*self.dmg or 2*self.dmg) + resonance_dmg, self)
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = yellow[0], duration = 0.1}
        LightningLine{group = main.current.effects, src = self, dst = enemy, color = yellow[0]}
      end
    end
  end, nil, nil, 'attack')
end

u["jester"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.wide_attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    local enemies = table.first2(table.shuffle(self:get_objects_in_shape(self.wide_attack_sensor, main.current.enemies)),
      6 + ((self.malediction == 1 and 1) or (self.malediction == 2 and 3) or (self.malediction == 3 and 5) or 0) + ((main.current.curser_level == 2 and 3) or (main.current.curser_level == 1 and 1) or 0))
    for _, enemy in ipairs(enemies) do
      if self:distance_to_object(enemy) < 128 then
        enemy:curse('jester', 6*(self.hex_duration_m or 1), self.level == 3, self)
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = red[0], duration = 0.1}
        LightningLine{group = main.current.effects, src = self, dst = enemy, color = red[0]}
      end
    end
  end, nil, nil, 'attack')
end

u["usurer"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.wide_attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    local enemies = table.first2(table.shuffle(self:get_objects_in_shape(self.wide_attack_sensor, main.current.enemies)),
      3 + ((self.malediction == 1 and 1) or (self.malediction == 2 and 3) or (self.malediction == 3 and 5) or 0) + ((main.current.curser_level == 2 and 3) or (main.current.curser_level == 1 and 1) or 0))
    for _, enemy in ipairs(enemies) do
      enemy:curse('usurer', 10000, self.level == 3, self)
      enemy:apply_dot(self.dmg*(self.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 10000)
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = purple[0], duration = 0.1}
      LightningLine{group = main.current.effects, src = self, dst = enemy, color = purple[0]}
    end
  end, nil, nil, 'attack')
end

u["silencer"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.wide_attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local curse = function()
      buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
      local enemies = table.first2(table.shuffle(self:get_objects_in_shape(self.wide_attack_sensor, main.current.enemies)),
        6 + ((self.malediction == 1 and 1) or (self.malediction == 2 and 3) or (self.malediction == 3 and 5) or 0) + ((main.current.curser_level == 2 and 3) or (main.current.curser_level == 1 and 1) or 0))
      for _, enemy in ipairs(enemies) do
        enemy:curse('silencer', 6*(self.hex_duration_m or 1), self.level == 3, self)
        if self.level == 3 then
          enemy:apply_dot(self.dmg*(self.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 6*(self.hex_duration_m or 1))
        end
        HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = blue2[0], duration = 0.1}
        LightningLine{group = main.current.effects, src = self, dst = enemy, color = blue2[0]}
      end
    end
    curse()
    self:repeatIfNecessary(true)
  end, nil, nil, 'attack')
end
vanilla["silencer"].sorcerer_repeat_delay = 0.5
vanilla["silencer"]:setRepeat(function(self)
  buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
  local enemies = table.first2(table.shuffle(self:get_objects_in_shape(self.wide_attack_sensor, main.current.enemies)),
    6 + ((self.malediction == 1 and 1) or (self.malediction == 2 and 3) or (self.malediction == 3 and 5) or 0) + ((main.current.curser_level == 2 and 3) or (main.current.curser_level == 1 and 1) or 0))
  for _, enemy in ipairs(enemies) do
    enemy:curse('silencer', 6*(self.hex_duration_m or 1), self.level == 3, self)
    if self.level == 3 then
      enemy:apply_dot(self.dmg*(self.dot_dmg_m or 1)*(main.current.chronomancer_dot or 1), 6*(self.hex_duration_m or 1))
    end
    HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = blue2[0], duration = 0.1}
    LightningLine{group = main.current.effects, src = self, dst = enemy, color = blue2[0]}
  end
end)

u["assassin"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 64)
  self.t:cooldown(2, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    if closest_enemy then
      self:shoot(self:angle_to_object(closest_enemy), {pierce = 1000})
    end
  end, nil, nil, 'shoot')
end

u["host"] = function(self)
  if self.level == 3 then
    self.t:every(1, function()
      critter1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      for i = 1, 2 do
        Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 10, dmg = self.dmg, parent = self}
      end
    end, nil, nil, 'spawn')
  else
    self.t:every(2, function()
      critter1:play{pitch = random:float(0.95, 1.05), volume = 0.35}
      Critter{group = main.current.main, x = self.x, y = self.y, color = orange[0], r = random:float(0, 2*math.pi), v = 10, dmg = self.dmg, parent = self}
    end, nil, nil, 'spawn')
  end
end

u["carver"] = function(self)
  self.t:every(16, function()
    Tree{group = main.current.main, x = self.x, y = self.y, color = self.color, parent = self, level = self.level}
  end, nil, nil, 'spawn')
end

u["sentry"] = function(self)
  self.t:every(7, function()
    Sentry{group = main.current.main, x = self.x, y = self.y, color = self.color, parent = self, level = self.level}
  end, nil, nil, 'spawn')
end

u["bane"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.wide_attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    local enemies = table.first2(table.shuffle(self:get_objects_in_shape(self.wide_attack_sensor, main.current.enemies)),
      6 + ((self.malediction == 1 and 1) or (self.malediction == 2 and 3) or (self.malediction == 3 and 5) or 0) + ((main.current.curser_level == 2 and 3) or (main.current.curser_level == 1 and 1) or 0))
    for _, enemy in ipairs(enemies) do
      enemy:curse('bane', 6*(self.hex_duration_m or 1), self.level == 3, self)
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = purple[0], duration = 0.1}
      LightningLine{group = main.current.effects, src = self, dst = enemy, color = purple[0]}
    end
  end, nil, nil, 'attack')
end

u["psykino"] = function(self)
  self.t:every(4, function()
    local center_enemy = self:get_random_object_in_shape(Circle(self.x, self.y, 160), main.current.enemies)
    if center_enemy then
      ForceArea{group = main.current.effects, x = center_enemy.x, y = center_enemy.y, rs = self.area_size_m*64, color = self.color, character = self.character, level = self.level, parent = self}
    end
  end, nil, nil, 'attack')
end

u["barrager"] = function(self)
  self.barrager_counter = 0
  self.attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(4, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.enemies)
    local r = self:angle_to_object(closest_enemy)
    self.barrager_counter = self.barrager_counter + 1
    if self.barrager_counter == 3 and self.level == 3 then
      self.barrager_counter = 0
      for i = 1, 15 do
        self.t:after((i-1)*0.05, function()
          self:shoot(r + random:float(-math.pi/32, math.pi/32), {knockback = (self.level == 3 and 14 or 7)})
        end)
      end
    else
      for i = 1, 3 do
        self.t:after((i-1)*0.075, function()
          self:shoot(r + random:float(-math.pi/32, math.pi/32), {knockback = (self.level == 3 and 14 or 7)})
        end)
      end
    end
  end, nil, nil, 'shoot')
end

u["highlander"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 36)
  self.t:cooldown(4, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    if self.level == 3 then
      self.t:every(0.25, function()
        self:attack(72)
      end, 3)
    else
      self:attack(72)
    end
  end, nil, nil, 'attack')
end

u["fairy"] = function(self)
  self.t:every(6, function()
    if self.level == 3 then
      local units = self:get_all_units()
      local unit_1 = random:table(units)
      local runs = 0
      if unit_1 then
        while table.any(non_attacking_characters, function(v) return v == unit_1.character end) and runs < 1000 do unit_1 = random:table(units); runs = runs + 1 end
      end
      local unit_2 = random:table(units)
      local runs = 0
      if unit_2 then
        while table.any(non_attacking_characters, function(v) return v == unit_2.character end) and runs < 1000 do unit_2 = random:table(units); runs = runs + 1 end
      end
      if unit_1 then
        unit_1.fairy_aspd_m = 3
        unit_1.fairyd = true
        unit_1.t:after(5.98, function() unit_1.fairy_aspd_m = 1; unit_1.fairyd = false end)
      end
      if unit_2 then
        unit_2.fairy_aspd_m = 3
        unit_2.fairyd = true
        unit_2.t:after(5.98, function() unit_2.fairy_aspd_m = 1; unit_2.fairyd = false end)
      end
      heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      for i = 1, 2 do
        local check_circle = Circle(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16), 2)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry})
        while #objects > 0 do
          check_circle:move_to(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16))
          objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Pet, Turret, Sentry, Bomb})
        end
        SpawnEffect{group = main.current.effects, x = check_circle.x, y = check_circle.y, color = green[0], action = function(x, y)
          local check_circle = Circle(x, y, 2)
          local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry})
          if #objects == 0 then
            HealingOrb{group = main.current.main, x = x, y = y}
          end
        end}
      end

    else
      local unit = random:table(self:get_all_units())
      local runs = 0
      while table.any(non_attacking_characters, function(v) return v == unit.character end) and runs < 1000 do unit = random:table(self:get_all_units()); runs = runs + 1 end
      if unit then
        unit.fairyd = true
        unit.fairy_aspd_m = 2
        unit.t:after(5.98, function() unit.fairy_aspd_m = 1; unit.fairyd = false end)
      end
      heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      buff1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      local check_circle = Circle(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16), 2)
      local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry})
      while #objects > 0 do
        check_circle:move_to(random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16))
        objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry})
      end
      SpawnEffect{group = main.current.effects, x = check_circle.x, y = check_circle.y, color = green[0], action = function(x, y)
        local check_circle = Circle(x, y, 2)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Pet, Turret, Sentry, Bomb})
        if #objects == 0 then
          HealingOrb{group = main.current.main, x = x, y = y}
        end
      end}
    end
  end, nil, nil, 'heal')
end

u["warden"] = function(self)
  self.t:every(12, function()
    local ward = function()
      if self.level == 3 then
        local units = self:get_all_units()
        local unit_1 = random:table_remove(units)
        local unit_2 = random:table_remove(units)
        if unit_1 then
          illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          main.current.t:every_immediate(0.1, function()
            local check_circle = Circle(unit_1.x, unit_1.y, 6)
            local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter})
            if #objects == 0 then
              ForceField{group = main.current.main, x = unit_1.x, y = unit_1.y, parent = unit_1}
              main.current.t:cancel('warden_force_field_1')
            end
          end, nil, nil, 'warden_force_field_1')
        end
        if unit_2 then
          illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          ForceField{group = main.current.main, x = unit_2.x, y = unit_2.y, parent = unit_2}
          main.current.t:every_immediate(0.1, function()
            local check_circle = Circle(unit_2.x, unit_2.y, 6)
            local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter})
            if #objects == 0 then
              ForceField{group = main.current.main, x = unit_2.x, y = unit_2.y, parent = unit_2}
              main.current.t:cancel('warden_force_field_2')
            end
          end, nil, nil, 'warden_force_field_2')
        end
      else
        local unit = random:table(self:get_all_units())
        if unit then
          illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
          main.current.t:every_immediate(0.1, function()
            local check_circle = Circle(unit.x, unit.y, 6)
            local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter})
            if #objects == 0 then
              ForceField{group = main.current.main, x = unit.x, y = unit.y, parent = unit}
              main.current.t:cancel('warden_force_field_0')
            end
          end, nil, nil, 'warden_force_field_0')
        end
      end
    end
    ward()
    self:repeatIfNecessary(true)
  end, nil, nil, 'buff')
end
vanilla["warden"].sorcerer_repeat_delay = 0.5
vanilla["warden"]:setRepeat(function(self)
  if self.level == 3 then
    local units = self:get_all_units()
    local unit_1 = random:table_remove(units)
    local unit_2 = random:table_remove(units)
    if unit_1 then
      illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      main.current.t:every_immediate(0.1, function()
        local check_circle = Circle(unit_1.x, unit_1.y, 6)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter})
        if #objects == 0 then
          ForceField{group = main.current.main, x = unit_1.x, y = unit_1.y, parent = unit_1}
          main.current.t:cancel('warden_force_field_1')
        end
      end, nil, nil, 'warden_force_field_1')
    end
    if unit_2 then
      illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ForceField{group = main.current.main, x = unit_2.x, y = unit_2.y, parent = unit_2}
      main.current.t:every_immediate(0.1, function()
        local check_circle = Circle(unit_2.x, unit_2.y, 6)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter})
        if #objects == 0 then
          ForceField{group = main.current.main, x = unit_2.x, y = unit_2.y, parent = unit_2}
          main.current.t:cancel('warden_force_field_2')
        end
      end, nil, nil, 'warden_force_field_2')
    end
  else
    local unit = random:table(self:get_all_units())
    if unit then
      illusion1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      main.current.t:every_immediate(0.1, function()
        local check_circle = Circle(unit.x, unit.y, 6)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter})
        if #objects == 0 then
          ForceField{group = main.current.main, x = unit.x, y = unit.y, parent = unit}
          main.current.t:cancel('warden_force_field_0')
        end
      end, nil, nil, 'warden_force_field_0')
    end
  end
end)

u["priest"] = function(self)
  if self.level == 3 then
    self.t:after(0.01, function()
      local all_units = self:get_all_units()
      local unit_1 = random:table_remove(all_units)
      local unit_2 = random:table_remove(all_units)
      local unit_3 = random:table_remove(all_units)
      if unit_1 then unit_1.divined = true end
      if unit_2 then unit_2.divined = true end
      if unit_3 then unit_3.divined = true end
    end)
  end

  self.t:every(12, function()
    local x, y = random:float(main.current.x1 + 16, main.current.x2 - 16), random:float(main.current.y1 + 16, main.current.y2 - 16)
    for i = 1, 3 do
      SpawnEffect{group = main.current.effects, x = x, y = y, color = green[0], action = function(x, y)
        local check_circle = Circle(x, y, 2)
        local objects = main.current.main:get_objects_in_shape(check_circle, {Seeker, EnemyCritter, Critter, Volcano, Saboteur, Bomb, Pet, Turret, Sentry, Automaton})
        if #objects == 0 then HealingOrb{group = main.current.main, x = x, y = y} end
      end}
    end
    --[[
    local all_units = self:get_all_units()
    for _, unit in ipairs(all_units) do unit:heal(0.2*unit.max_hp*(self.heal_effect_m or 1)) end
    heal1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ]]--
  end, nil, nil, 'heal')
end

u["infestor"] = function(self)
  self.attack_sensor = Circle(self.x, self.y, 96)
  self.wide_attack_sensor = Circle(self.x, self.y, 128)
  self.t:cooldown(6, function() local enemies = self:get_objects_in_shape(self.attack_sensor, main.current.enemies); return enemies and #enemies > 0 end, function()
    buff1:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    local enemies = table.first2(table.shuffle(self:get_objects_in_shape(self.wide_attack_sensor, main.current.enemies)),
      8 + ((self.malediction == 1 and 1) or (self.malediction == 2 and 3) or (self.malediction == 3 and 5) or 0) + ((main.current.curser_level == 2 and 3) or (main.current.curser_level == 1 and 1) or 0))
    for _, enemy in ipairs(enemies) do
      enemy:curse('infestor', 6*(self.hex_duration_m or 1), (self.level == 3 and 6 or 2), self.dmg, self)
      HitCircle{group = main.current.effects, x = self.x, y = self.y, rs = 6, color = orange[0], duration = 0.1}
      LightningLine{group = main.current.effects, src = self, dst = enemy, color = orange[0]}
    end
  end, nil, nil, 'attack')
end

u["flagellant"] = function(self)
  self.t:every(8, function()
    buff1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
    flagellant1:play{pitch = random:float(0.95, 1.05), volume = 0.4}
    local all_units = self:get_all_units()
    for _, unit in ipairs(all_units) do
      if unit.character == 'flagellant' then
        hit2:play{pitch = random:float(0.95, 1.05), volume = 0.4}
        unit:hit(self.level == unit.dmg or 2*unit.dmg)
      end
      if not unit.flagellant_dmg_m then
        unit.flagellant_dmg_m = 1
      end
      if self.level == 3 then
        unit.flagellant_dmg_m = unit.flagellant_dmg_m + 0.12
      else
        unit.flagellant_dmg_m = unit.flagellant_dmg_m + 0.04
      end
    end
  end, nil, nil, 'buff')
end

vanilla:addShopCondition(function(all_units)
    return not table.all(all_units, function(v) return table.any(non_attacking_characters, function(u) return v == u end) end)
end)

return vanilla