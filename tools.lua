-- Add Translator
local S = minetest.get_translator("magical_magnet")


local function merge(t1, t2)
    local t = table.copy(t1)
    for k, v in pairs(t2) do
        t[k] = v
    end
    return t
end

local function get_magnet_description(status, radius, blacklist)
    radius = radius or 3
    blacklist = blacklist or {}

    local c_gold = minetest.get_color_escape_sequence("#f5d576")
    local c_red = minetest.get_color_escape_sequence("#e05c5c")
    local c_reset = minetest.get_color_escape_sequence("#FFFFFF")

    -- Blacklist
    local blacklist_str = ""
    
    for _, el in ipairs(blacklist) do
        blacklist_str = blacklist_str .. "- " .. el .. "\n"
    end
    blacklist_str = blacklist_str:gsub("\n+$", "")

    if blacklist_str == "" then
        blacklist_str = "  " .. S("(empty)")
    end

    -- On/Off
    if status == "on" then
        status = S("On")
    elseif status == "off" then
        status = S("Off")
    end

    local desc = S("Magnet (@1)", status) .. "\n" .. c_gold ..
                S("Range:") .. "\n" ..
                "  " .. radius .. " " .. S("blocks") .. "\n" ..
                "" ..
                c_red .. S("Blacklisted items:") .. "\n" ..
                blacklist_str .. c_reset

    return desc
end

local function change_description_part(player, desc_part, val, intermediate_mode_stack)
    local player_name = player:get_player_name()

    local stack
    if intermediate_mode_stack then
        stack = intermediate_mode_stack
    else
        stack = player:get_wielded_item()
    end
    local meta = stack:get_meta()

    -- Get Status Function
    local function get_status()
        return meta:get_string("description"):find(S("On"), 1, true) ~= nil and "on" or "off"
    end

    -- Get Radius Function
    local function get_radius()
        return meta:get_int("magnet_radius")
    end

    -- Get Blacklist Function
    local function get_blacklist()
        local blakclist = {}
        for index = 1, 8 do
            local blacklist_item = meta:get_string("magnet_stack_" .. index)
            if blacklist_item ~= "" then
                table.insert(blakclist, blacklist_item)
            end
        end
        return blakclist
    end

    -- Get Description
    local desc = ""
    if desc_part == "status" then
        desc = get_magnet_description(val, get_radius(), get_blacklist())
    elseif desc_part == "radius" then
        desc = get_magnet_description(get_status(), val, get_blacklist())
    elseif desc_part == "blacklist" then
        desc = get_magnet_description(get_status(), get_radius(), val)
    end

    -- Set Description
    meta:set_string("description", desc)
    if intermediate_mode_stack then
        return stack
    else
        player:set_wielded_item(stack)
    end
end
magical_magnet.change_description_part = change_description_part

local function update_description_blacklist(player, meta)
    local blakclist = {}
    for index = 1, 8 do
        local blacklist_item = meta:get_string("magnet_stack_" .. index)
        if blacklist_item ~= "" then
            table.insert(blakclist, blacklist_item)
        end
    end

    change_description_part(player, "blacklist", blakclist)
end

local function show_magnet_ui(player)
    local inv = player:get_inventory()
    local wielded_magnet_index = player:get_wield_index()
    local wielded_magnet = inv:get_stack("main", wielded_magnet_index)

    local meta = wielded_magnet:get_meta()
    local magnet_radius = meta:get_int("magnet_radius")

    if magnet_radius == 0 then  -- The radius may already be defined in the meta data, but this function may be called before the stack is updated; therefore, if the function encounters an undefined radius, it is assumed to be already defined, and we set the default value
        magnet_radius = 3
    end

    local player_name = player:get_player_name()

    -- Check if magnet is main or dependent
    local show_full_formspec = false
    if wielded_magnet:get_name() == "magical_magnet:magnet_off" then
        show_full_formspec = true
    else
        local inv_list = player:get_inventory():get_list("main")
        for index, stack in ipairs(inv_list) do
            if stack:get_name() == "magical_magnet:magnet_on" then
                if index == wielded_magnet_index then
                    show_full_formspec = true
                end
                break
            end
        end
    end

    -- Set the appropriate windows for the dependent or main magnet
    local F = minetest.formspec_escape
    local formspec = ""
    if show_full_formspec then
        formspec = "size[8,6.8]" ..
            "style_type[button;bgcolor=#2d223c;textcolor=#00ffff;border=true;content_offset=0]" ..
            "style_type[button:hover;bgcolor=#44305c;textcolor=#ffffff]" ..
            "background[0,0;8,6.8;magnet_ui_bg.png;true]" ..

            "list[current_player;main;0,2.8;8,4;]" ..
            "list[detached:magnet_filter_" .. player_name .. ";main;0,1.48;8,1;0]" ..

            "label[0,.2;" .. F(S("Magnet radius:")) .. " " .. magnet_radius .. " " .. F(S("blocks")) .. "]" ..
            "button[4.66,0;1,1;radius_minimum;" .. F(S("Min")) .. "]" ..
            "button[5.44,0;1,1;radius_minus;-]" ..
            "button[6.22,0;1,1;radius_plus;+]" ..
            "button[7,0;1,1;radius_maximum;" .. F(S("Max")).. "]" ..

            "image[0,0.9;.5,.5;magnet_ui_tooltip.png]" ..
            "tooltip[0,0.9;.5,.5;" .. F(S("Use two or more magnets at the same time to@nexpand the blacklist.")) .. "]" ..
            "label[.5,0.875;" .. F(S("Blacklist:")) .. "]" ..

            "listring[detached:magnet_filter_" .. player_name .. ";main]" ..
            "listring[current_player;main]"
    else
        formspec = "size[8,7.4]" ..
            "style_type[button;bgcolor=#3a3a3a;textcolor=#888888;border=true;content_offset=0]" ..
            "style_type[button:hover;bgcolor=#3a3a3a;textcolor=#888888]" ..
            "background[0,0;8,7.4;magnet_ui_bg.png;true]" ..

            "list[current_player;main;0,3.4;8,4;]" ..
            "list[detached:magnet_filter_" .. player_name .. ";main;0,2.08;8,1;0]" ..

            "label[0,.2;" .. minetest.colorize("#888888", F(S("Magnet radius:")) .. " " .. magnet_radius .. " " .. F(S("blocks"))) .. "]" ..

            -----
            "image[0,.82;.5,.5;magnet_ui_tooltip.png]" ..
            "tooltip[0,.82;.5,.5;" .. F(S("The radius applies only to the first magnet in your inventory.")) .. "]" ..
            "label[.5,.8;" .. minetest.colorize("#888888", F(S("This magnet is dependent. You cannot change the radius."))) .. "]" ..
            -----

            "button[4.66,0;1,1;;" .. F(S("Min")) .. "]" ..
            "button[5.44,0;1,1;;-]" ..
            "button[6.22,0;1,1;;+]" ..
            "button[7,0;1,1;;" .. F(S("Max")) .. "]" ..
            "label[0,1.5;" .. F(S("Blacklist:")) .. "]" ..

            "listring[detached:magnet_filter_" .. player_name .. ";main]" ..
            "listring[current_player;main]"
    end


    minetest.show_formspec(player_name, "magical_magnet:config_form", formspec)
end

local function handle_magnet_use(itemstack, handler, pointed_thing)
        if not handler or not handler:is_player() then return end
        local player_name = handler:get_player_name()

        -- Magnet Settings work only if magnet is charged
        if itemstack:get_wear() == 65535 then
            minetest.chat_send_player(player_name, minetest.get_color_escape_sequence("#FF8800") .. S("The magnet is discharged! To charge it, drop the magnet on the ground and right-click on the magnet lying on the ground while holding the Tome of Gravity and having 100 mana."))
            return
        end

        local meta = itemstack:get_meta()
        local magnet_radius = meta:get_int("magnet_radius")
        if magnet_radius == 0 then
            meta:set_int("magnet_radius", 3) -- Meta is not defined in the case of magnet on/off give via Creative
        end

        local filter_inv = minetest.create_detached_inventory("magnet_filter_" .. player_name, {
            allow_put = function(inv, listname, index, stack, player)
                local item_copy = ItemStack(stack)
                item_copy:set_count(1)

                inv:set_stack(listname, index, item_copy)

                local wielded_item = player:get_wielded_item()
                local wielded_item_meta = wielded_item:get_meta()

                wielded_item_meta:set_string("magnet_stack_" .. index, stack:get_name())
                player:set_wielded_item(wielded_item)

                update_description_blacklist(player, wielded_item_meta)

                -- minetest.log(dump(wielded_item:get_meta():to_table()))
                return 0  -- Disable the default behavior
            end,

            allow_take = function(inv, listname, index, stack, player)
                inv:set_stack(listname, index, "")

                local wielded_item = player:get_wielded_item()
                local wielded_item_meta = wielded_item:get_meta()

                wielded_item_meta:set_string("magnet_stack_" .. index, "")
                player:set_wielded_item(wielded_item)

                update_description_blacklist(player, wielded_item_meta)

                return 0
            end,

            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                local stack = inv:get_stack(from_list, from_index)
                inv:set_stack(to_list, to_index, stack)

                inv:set_stack(from_list, from_index, "")

                local wielded_item = player:get_wielded_item()
                local wielded_item_meta = wielded_item:get_meta()

                wielded_item_meta:set_string("magnet_stack_" .. from_index, "")
                wielded_item_meta:set_string("magnet_stack_" .. to_index, stack:get_name())
                player:set_wielded_item(wielded_item)

                update_description_blacklist(player, wielded_item_meta)

                return 0
            end,
        })
        filter_inv:set_size("main", 8)

        -- Load the saved blacklist stacks from the magnet's metadata
        local wielded_item = handler:get_wielded_item()
        local wielded_meta = wielded_item:get_meta()
        for index = 1, 8 do
            local item_name = wielded_meta:get_string("magnet_stack_" .. index)
            if item_name ~= "" then
                filter_inv:set_stack("main", index, ItemStack(item_name))
            end
        end

        show_magnet_ui(handler)
        return itemstack
end

local base_def = {
    groups = { tool = 1 },
    on_place = handle_magnet_use,
    on_secondary_use = handle_magnet_use,
}

local off_def = merge(base_def, {
    description = get_magnet_description("off"),
    inventory_image = "magical_magnet_magnet_off.png",
    on_use = function(stack, player)
        if stack:get_wear() ~= 65535 then
            local meta = stack:get_meta()
            local magnet_radius = meta:get_int("magnet_radius")
            if magnet_radius == 0 then
                meta:set_int("magnet_radius", 3)
            end

            stack:set_name("magical_magnet:magnet_on")
            return change_description_part(player, "status", "on", stack)
        end

        return stack
    end,
})

local on_def = merge(base_def, {
    description = get_magnet_description("on"),
    inventory_image = "magical_magnet_magnet_on.png",
    light_source = 12,
    groups = {tool = 1, not_in_creative_inventory = 1},
    on_use = function(stack, player)
        stack:set_name("magical_magnet:magnet_off")
        return change_description_part(player, "status", "off", stack)
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "magical_magnet:config_form" then return end

    -- Get Meta
    local stack = player:get_wielded_item()
    if not stack then return end
    local meta = stack:get_meta()

    -- Helper Functions
    local function get_radius() return meta:get_int("magnet_radius") end

    local function set_radius(val)
        -- Set Radius to the Meta
        meta:set_int("magnet_radius", val)
        player:set_wielded_item(stack)

        -- Change Radius to the Description
        change_description_part(player, "radius", val)
    end


    -- Buttons Event Listeners
    if fields.radius_minimum then
        set_radius(3)
        show_magnet_ui(player)
    elseif fields.radius_maximum then
        set_radius(10)
        show_magnet_ui(player)
    elseif fields.radius_minus then
        local new_magnet_radius = get_radius() - 1

        if new_magnet_radius >= 3 then
            set_radius(new_magnet_radius)
            show_magnet_ui(player)
        end
    elseif fields.radius_plus then
        local new_magnet_radius = get_radius() + 1

        if new_magnet_radius <= 10 then
            set_radius(new_magnet_radius)
            show_magnet_ui(player)
        end
    end
end)

minetest.register_tool("magical_magnet:magnet_off", off_def)
minetest.register_tool("magical_magnet:magnet_on", on_def)
