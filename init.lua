-- Load files
local magical_magnet_path = minetest.get_modpath("magical_magnet")
magical_magnet = {}

minetest.register_on_joinplayer(function(player)
    -- Если игрок выходит, то переменная продолжает содержать в себе данные этого игрока пока сервер не будет выключен
    local player_name = player:get_player_name()
    
    magical_magnet[player_name] = {
        magnet_radius = 3,
        blacklist = {}
    }
end)

dofile(magical_magnet_path.."/functions.lua")
dofile(magical_magnet_path.."/craftitems.lua")
dofile(magical_magnet_path.."/tools.lua")
dofile(magical_magnet_path.."/nodes.lua")
dofile(magical_magnet_path.."/crafting.lua")
dofile(magical_magnet_path.."/mapgen.lua")


-- Проверяем правый клик (on_rightclick) по ЛЕЖАЩИМ предметам
minetest.register_on_mods_loaded(function()
    local builtin_item = minetest.registered_entities["__builtin:item"]

    if builtin_item then
        -- Сохраняем старый обработчик правого клика (если он был)
        local old_rightclick = builtin_item.on_rightclick

        builtin_item.on_rightclick = function(self, clicker)
            if not clicker or not clicker:is_player() then return end -- Проверяем, что кликнул игрок

            local wielded_item = clicker:get_wielded_item()
            if wielded_item and wielded_item:get_name() == "gadgets_magic:tome_gravity" then

                local find_gravity_core = self.itemstring:find("magical_magnet:inert_gravity_core")
                local find_magnet = self.itemstring:find("magical_magnet:magnet_off") or self.itemstring:find("magical_magnet:magnet_on")
                if self.itemstring and (find_gravity_core or find_magnet) then
                    local mana_cost = 100
                    local player_name = clicker:get_player_name()
                    local current_mana = mana.get(player_name) or 0
                    if current_mana < mana_cost then
                        minetest.chat_send_player(player_name, "Not enough mana! You need: " .. mana_cost)
                        return
                    else
                        mana.subtract(player_name, mana_cost)
                    end

                    local wear_cost = 1092.25
                    wielded_item:add_wear(wear_cost)
                    clicker:set_wielded_item(wielded_item)

                    local pos = self.object:get_pos()
                    minetest.add_particlespawner({
                        amount = 30, time = 0.5,
                        minpos = {x=pos.x-0.3, y=pos.y, z=pos.z-0.3},
                        maxpos = {x=pos.x+0.3, y=pos.y+0.5, z=pos.z+0.3},
                        minvel = {x=-1, y=1, z=-1}, maxvel = {x=1, y=3, z=1},
                        minexptime = 0.5, maxexptime = 1,
                        minsize = 1, maxsize = 2,
                        texture = "thunder.png",
                    })

                    minetest.sound_play("default_cool_lava", { pos = pos, gain = 1.0 })

                    if find_gravity_core then
                        if self.set_item then
                            self:set_item("magical_magnet:charged_gravity_core")
                        else
                            self.itemstring = "magical_magnet:charged_gravity_core"
                            self.object:set_properties({
                                textures = { "magical_magnet_charged_gravity_core.png" },
                            })
                        end
                    elseif find_magnet then
                        local stack = ItemStack(self.itemstring)
                        stack:set_wear(0)
                        self.itemstring = stack:to_string()
                        self.object:set_properties({
                            wield_item = self.itemstring
                        })
                    end

                    return
                end
            end

            if old_rightclick then
                return old_rightclick(self, clicker)
            end
        end
    end
end)


local magnet_delay = .25
local pick_up_distance = .25
local wear_per_tick = 1500

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime

    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local inv = player:get_inventory()
        if not inv then goto continue end

        local inv_list = inv:get_list("main")


        if timer >= 2 then
            -- Find the first magnet in the inventory
            for _, stack in ipairs(inv_list) do
                if stack:get_name() == "magical_magnet:magnet_on" then

                    -- Copy meta magnet radius to local variable and break loop
                    local meta_magnet_radius = stack:get_meta():get_int("magnet_radius")
                    magical_magnet[player_name].magnet_radius = meta_magnet_radius
                    break
                end
            end

            magical_magnet[player_name].blacklist = {}
        end

        for index, stack in ipairs(inv_list) do
            -- LOW PRIORITY ACTIONS
            if timer >= 2 then
                if stack:get_name() == "magical_magnet:magnet_on" then
                    local magnet_meta = stack:get_meta()

                    for index = 1, 8 do
                        local blacklist_item = magnet_meta:get_string("magnet_stack_" .. index)
                        if blacklist_item ~= "" then
                            table.insert(magical_magnet[player_name].blacklist, blacklist_item)
                        end
                    end
                end
            end

            -- HIGH PRIORITY ACTIONS
            if stack:get_name() == "magical_magnet:magnet_on" then
                local wear = stack:get_wear()

                -- ПРОВЕРКА НА РАЗРЯДКУ
                if (wear + wear_per_tick) >= 65536 then
                    stack:set_name("magical_magnet:magnet_off")
                    stack:set_wear(65535)
                    inv:set_stack("main", index, stack)

                    minetest.chat_send_player(player_name, minetest.get_color_escape_sequence("#FF8800") .. "Магнит разряжен! Зарядите его с помощью книги гравитации.")
                    break  -- Хз чи це нада вобще
                end

                local player_pos = player:get_pos()
                local player_center = { x = player_pos.x, y = player_pos.y + 1.5, z = player_pos.z }

                local magnet_radius = magical_magnet[player_name].magnet_radius
                local objects = minetest.get_objects_inside_radius(player_center, magnet_radius)

                local item_was_pulled = false -- Делает так что за один тик прочность снимается только один раз
                -- даже если вокруг много выпавших предметов. Иначе прочность будет сниматься с каждым предметом по
                -- отдельности

                for _, obj in ipairs(objects) do
                    local entity = obj:get_luaentity()

                    if entity and entity.name == "__builtin:item" then
                        local item_name = ItemStack(entity.itemstring):get_name()
                        local is_object_ignored = false
                        for _, blacklist_el in ipairs(magical_magnet[player_name].blacklist) do
                            if blacklist_el == item_name then
                                is_object_ignored = true
                                break
                            end
                        end

                        if not is_object_ignored and not (entity.age and entity.age < magnet_delay) then
                            local obj_pos = obj:get_pos()
                            local distance = vector.distance(obj_pos, player_center)  -- Getting distance between player and dropped item

                            if distance <= pick_up_distance then
                                entity:on_punch(player)
                            else
                                -- Move dropped item to player
                                local dir = vector.direction(obj_pos, player_center)
                                obj:set_velocity(vector.multiply(dir, 6))
                                item_was_pulled = true
                            end
                        end
                    end
                end

                -- Тратим износ за работу
                if item_was_pulled then
                    stack:add_wear(wear_per_tick)
                    inv:set_stack("main", index, stack)
                end
            end
        end

        ::continue::
    end
    
    if timer >= 2 then
        timer = 0
        -- minetest.log(dump(magical_magnet))
    end
end)
