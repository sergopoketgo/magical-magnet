-- Declaration of a Global Variable of this mode
magical_magnet = {
    player_data = {}
}

-- Write Information about Players to the Mode Variable
minetest.register_on_joinplayer(function(player)
    -- If the player leaves, the variable continues to contain this player's data until the server is shut down
    local player_name = player:get_player_name()

    magical_magnet.player_data[player_name] = {
        magnet_radius = 3,
        blacklist = {}
    }
end)

-- Load files
local magical_magnet_path = minetest.get_modpath("magical_magnet")

dofile(magical_magnet_path.."/craftitems.lua")
dofile(magical_magnet_path.."/tools.lua")
dofile(magical_magnet_path.."/nodes.lua")
dofile(magical_magnet_path.."/crafting.lua")
dofile(magical_magnet_path.."/mapgen.lua")

-- Add Translator
local S = minetest.get_translator("magical_magnet")


-- Checking the Right-Click on Builtin Items
minetest.register_on_mods_loaded(function()
    local builtin_item = minetest.registered_entities["__builtin:item"]
    if not builtin_item then return end

    -- Keep the old right-click handler (if there was one)
    local old_rightclick = builtin_item.on_rightclick

    builtin_item.on_rightclick = function(self, player)
        if not player or not player:is_player() then return end

        local wielded_item = player:get_wielded_item()
        if wielded_item and wielded_item:get_name() == "gadgets_magic:tome_gravity" then

            local find_gravity_core = self.itemstring:find("magical_magnet:inert_gravity_core")
            local find_magnet = self.itemstring:find("magical_magnet:magnet_off") or self.itemstring:find("magical_magnet:magnet_on")
            if self.itemstring and (find_gravity_core or find_magnet) then
                local player_name = player:get_player_name()
                local current_mana = mana.get(player_name) or 0

                if current_mana < 100 then
                    minetest.chat_send_player(player_name, minetest.get_color_escape_sequence("#FF8800") .. S("Not enough mana. Required: 100 mana."))
                    return
                else
                    mana.subtract(player_name, 100)
                end

                local wear_cost = 1092.25
                wielded_item:add_wear(wear_cost)
                player:set_wielded_item(wielded_item)

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

                minetest.sound_play("magical_magnet_charging", { pos = pos, gain = 1.0 })

                if find_gravity_core then
                    local stack = ItemStack("magical_magnet:charged_gravity_core")
                    local meta = stack:get_meta()
                    meta:set_string("description", S("Gravity Core (active)"))
                    self:set_item(stack:to_string())
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
            return old_rightclick(self, player)
        end
    end
end)


local magnet_delay = .25
local pick_up_distance = .25
local wear_per_tick = 75

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime

    local connected_players = minetest.get_connected_players()
    for _, player in ipairs(connected_players) do
        local player_name = player:get_player_name()
        local inv = player:get_inventory()
        if not inv then goto continue end
        local inv_list = inv:get_list("main")

        if timer >= 2 then
            -- Radius (of the First Magnet)
            for _, stack in ipairs(inv_list) do
                if stack:get_name() == "magical_magnet:magnet_on" then

                    -- Copy meta magnet radius to local variable and break loop
                    local meta_magnet_radius = stack:get_meta():get_int("magnet_radius")
                    magical_magnet.player_data[player_name].magnet_radius = meta_magnet_radius

                    -- Clear Blacklist
                    magical_magnet.player_data[player_name].blacklist = {}
                    break
                end
            end
        end

        for index, stack in ipairs(inv_list) do
            -- LOW PRIORITY ACTIONS
            if timer >= 2 then
                if stack:get_name() == "magical_magnet:magnet_on" then
                    local magnet_meta = stack:get_meta()

                    -- Blacklist
                    for index = 1, 8 do
                        local blacklist_item = magnet_meta:get_string("magnet_stack_" .. index)
                        if blacklist_item ~= "" then
                            table.insert(magical_magnet.player_data[player_name].blacklist, blacklist_item)
                        end
                    end

                    -- Magnet Wear
                    local wear = stack:get_wear()

                    -- Checking if The Magnet is discharged or not
                    if (wear + wear_per_tick) >= 65536 then
                        -- Replace with a discharged magnet
                        stack:set_name("magical_magnet:magnet_off")
                        stack:set_wear(65535)
                        stack = magical_magnet.change_description_part(player, "status", "off", stack)

                        inv:set_stack("main", index, stack)

                        minetest.chat_send_player(player_name, minetest.get_color_escape_sequence("#FF8800") .. S("The magnet is discharged! To charge it, drop the magnet on the ground and right-click on the magnet lying on the ground while holding the Tome of Gravity and having 100 mana."))
                    else
                        -- Spend wear while using
                        stack:add_wear(wear_per_tick)
                        inv:set_stack("main", index, stack)
                    end
                end
                
                -- minetest.log(dump(magical_magnet.player_data))
            end

            -- HIGH PRIORITY ACTIONS
            if stack:get_name() == "magical_magnet:magnet_on" then
                local player_pos = player:get_pos()
                local player_center = { x = player_pos.x, y = player_pos.y + 1.5, z = player_pos.z }

                local magnet_radius = magical_magnet.player_data[player_name].magnet_radius
                local objects = minetest.get_objects_inside_radius(player_center, magnet_radius)

                for _, obj in ipairs(objects) do
                    local entity = obj:get_luaentity()

                    if entity and entity.name == "__builtin:item" then
                        local item_name = ItemStack(entity.itemstring):get_name()
                        local is_object_ignored = false
                        for _, blacklist_el in ipairs(magical_magnet.player_data[player_name].blacklist) do
                            if blacklist_el == item_name then
                                is_object_ignored = true
                                break
                            end
                        end

                        if not is_object_ignored and not (entity.age and entity.age < magnet_delay) then
                            local obj_pos = obj:get_pos()
                            local distance = vector.distance(obj_pos, player_center)  -- Getting distance between player and dropped item

                            local player_pickuper = nil
                            local last_distance = nil
                            for _, _player in ipairs(connected_players) do
                                local _player_name = _player:get_player_name()

                                local _player_pos = _player:get_pos()
                                local _player_center = { x = _player_pos.x, y = _player_pos.y + 1.5, z = _player_pos.z }
                                local _distance = vector.distance(obj_pos, _player_center)

                                local _player_inv = _player:get_inventory()
                                local _player_has_magnet_on = _player_inv and _player_inv:contains_item("main", "magical_magnet:magnet_on")
                                local _player_magnet_radius = magical_magnet.player_data[_player_name].magnet_radius

                                if _player_has_magnet_on and _distance <= _player_magnet_radius then
                                    if not player_pickuper or _distance < last_distance then
                                        player_pickuper = _player
                                        last_distance = _distance
                                    end
                                end
                            end
                            -- minetest.log(dump(player_pickuper and player_pickuper:get_player_name() or "no player"))

                            if player == player_pickuper then
                                if distance <= pick_up_distance then
                                    entity:on_punch(player)
                                else
                                    -- Move dropped item to player
                                    local dir = vector.direction(obj_pos, player_center)
                                    obj:set_velocity(vector.multiply(dir, 6))
                                end
                            end
                        end
                    end
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
