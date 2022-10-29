
--------------
-- Manual --
--------------

function fishing_boat.getPlaneFromPlayer(player)
    local seat = player:get_attach()
    if seat then
        local plane = seat:get_attach()
        return plane
    end
    return nil
end

function fishing_boat.pilot_formspec(name)
    local basic_form = table.concat({
        "formspec_version[5]",
        "size[6,10]",
	}, "")

    local player = minetest.get_player_by_name(name)
    local plane_obj = fishing_boat.getPlaneFromPlayer(player)
    if plane_obj == nil then
        return
    end
    local ent = plane_obj:get_luaentity()

    local take_control = "false"
    if ent._at_control then take_control = "true" end
    local anchor = "false"
    if ent.anchored == true then anchor = "true" end
    local light = "false"
    if ent._show_light == true then light = "true" end

	basic_form = basic_form.."button[1,1.0;4,1;turn_on;Start/Stop the engine]"
    basic_form = basic_form.."button[1,2.0;4,1;inventory;Open inventory]"
    basic_form = basic_form.."button[1,3.0;4,1;manual;Show Manual Menu]"

    basic_form = basic_form.."checkbox[1,4.6;take_control;Take the Control;"..take_control.."]"
    basic_form = basic_form.."checkbox[1,5.2;anchor;Anchor away;"..anchor.."]"
    basic_form = basic_form.."checkbox[1,5.8;light;Light;"..light.."]"
    
    basic_form = basic_form.."label[1,6.6;Disembark:]"
    basic_form = basic_form.."button[1,6.8;2,1;disembark_l;<< Left]"
    basic_form = basic_form.."button[3,6.8;2,1;disembark_r;Right >>]"

    basic_form = basic_form.."button[1,8.0;4,1;repair;Repair]"

    minetest.show_formspec(name, "fishing_boat:pilot_main", basic_form)
end

function fishing_boat.repair_formspec(name)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[6,4]",
	}, "")

    local player = minetest.get_player_by_name(name)
    local plane_obj = fishing_boat.getPlaneFromPlayer(player)
    if plane_obj == nil then
        return
    end
    local ent = plane_obj:get_luaentity()

    local tax = math.ceil(fishing_boat.getRepairTax(ent))

    basic_form = basic_form.."label[1,1.0;To do the repairs, we need\n"..tax.." steel ingots\nfrom your inventory]"
    basic_form = basic_form.."button[1.0,2.6;1.8,1;cancel;Cancel]"
    basic_form = basic_form.."button[3.4,2.6;1.8,1;doit;Do it]"

    minetest.show_formspec(name, "fishing_boat:repair", basic_form)
end

function fishing_boat.pax_formspec(name)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[6,3]",
	}, "")

    basic_form = basic_form.."label[1,1.0;Disembark:]"
    basic_form = basic_form.."button[1,1.2;2,1;disembark_l;<< Left]"
    basic_form = basic_form.."button[3,1.2;2,1;disembark_r;Right >>]"

    minetest.show_formspec(name, "fishing_boat:passenger_main", basic_form)
end

function fishing_boat.owner_formspec(name)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[6,4.2]",
	}, "")

	basic_form = basic_form.."button[1,1.0;4,1;take;Take the Control Now]"
    basic_form = basic_form.."label[1,2.2;Disembark:]"
    basic_form = basic_form.."button[1,2.4;2,1;disembark_l;<< Left]"
    basic_form = basic_form.."button[3,2.4;2,1;disembark_r;Right >>]"

    minetest.show_formspec(name, "fishing_boat:owner_main", basic_form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "fishing_boat:owner_main" then
        local name = player:get_player_name()
        local plane_obj = fishing_boat.getPlaneFromPlayer(player)
        if plane_obj == nil then
            minetest.close_formspec(name, "fishing_boat:owner_main")
            return
        end
        local ent = plane_obj:get_luaentity()
        if ent then
		    if fields.disembark_l then
                fishing_boat.dettach_pax(ent, player, "l")
		    end
		    if fields.disembark_r then
                fishing_boat.dettach_pax(ent, player, "r")
		    end
		    if fields.take then
                ent._at_control = true
                for i = 5,1,-1 
                do 
                    if ent._passengers[i] == name then
                        ent._passengers_base_pos[i] = vector.new(fishing_boat.pilot_base_pos)
                        ent._passengers_base[i]:set_attach(ent.object,'',fishing_boat.pilot_base_pos,{x=0,y=0,z=0})
                        player:set_attach(ent._passengers_base[i], "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
                    end
                    if ent._passengers[i] == ent.driver_name then
                        ent._passengers_base_pos[i] = vector.new(fishing_boat.passenger_pos[i])
                        ent._passengers_base[i]:set_attach(ent.object,'',ent._passengers_base_pos[i],{x=0,y=0,z=0})
                    end
                end
                ent.driver_name = name
		    end
        end
        minetest.close_formspec(name, "fishing_boat:owner_main")
    end
	if formname == "fishing_boat:passenger_main" then
        local name = player:get_player_name()
        local plane_obj = fishing_boat.getPlaneFromPlayer(player)
        if plane_obj == nil then
            minetest.close_formspec(name, "fishing_boat:passenger_main")
            return
        end
        local ent = plane_obj:get_luaentity()
        if ent then
		    if fields.disembark_l then
                fishing_boat.dettach_pax(ent, player, "l")
		    end
		    if fields.disembark_r then
                fishing_boat.dettach_pax(ent, player, "r")
		    end
        end
        minetest.close_formspec(name, "fishing_boat:passenger_main")
	end
    if formname == "fishing_boat:pilot_main" then
        local name = player:get_player_name()
        local plane_obj = fishing_boat.getPlaneFromPlayer(player)
        if plane_obj == nil then
            minetest.close_formspec(name, "fishing_boat:pilot_main")
            return
        end
        local ent = plane_obj:get_luaentity()
        if ent then
		    if fields.turn_on then
                if ent._engine_running == true then
                    ent._engine_running = false
                else
                    ent._engine_running = true
                end
		    end
            if fields.inventory then
                airutils.show_vehicle_trunk_formspec(ent, player, fishing_boat.trunk_slots)
            end
            if fields.manual then
                fishing_boat.manual_formspec(name)
            end
		    if fields.take_control then
                if fields.take_control == "true" then
                    if ent.driver_name == nil or ent.driver_name == "" then
                        ent._at_control = true
                        for i = 5,1,-1 
                        do 
                            if ent._passengers[i] == name then
                                ent._passengers_base_pos[i] = vector.new(fishing_boat.pilot_base_pos)
                                ent._passengers_base[i]:set_attach(ent.object,'',fishing_boat.pilot_base_pos,{x=0,y=0,z=0})
                                player:set_attach(ent._passengers_base[i], "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
                                ent.driver_name = name
                                --minetest.chat_send_all(">>"..ent.driver_name)
                                break
                            end
                        end
                    else
                        minetest.chat_send_player(name,core.colorize('#ff0000', " >>> Impossible. Someone is at the boat control now."))
                    end
                else
                    ent.driver_name = nil
                    ent._at_control = false
                    fishing_boat.remove_hud(player)

                    --[[for i = 5,1,-1 
                    do 
                        if ent._passengers[i] == name then
                            --ent._passengers_base_pos[i] = fishing_boat.copy_vector(fishing_boat.passenger_pos[i])
                            ent._passengers_base_pos[i] = vector.new(fishing_boat.passenger_pos[i])
                            ent._passengers_base[i]:set_attach(ent.object,'',ent._passengers_base_pos[i],{x=0,y=0,z=0})
                            break
                        end
                    end]]--

                end
		    end
		    if fields.disembark_l then
                --=========================
                --  dettach player
                --=========================
                -- eject passenger if the plane is on ground
                ent.driver_name = nil
                ent._at_control = false

                fishing_boat.dettach_pax(ent, player, "l")

		    end
		    if fields.disembark_r then
                --=========================
                --  dettach player
                --=========================
                -- eject passenger if the plane is on ground
                ent.driver_name = nil
                ent._at_control = false

                fishing_boat.dettach_pax(ent, player, "r")

		    end
		    if fields.bring then

		    end
            if fields.anchor then
                if fields.anchor == "true" then
                    local max_speed_anchor = 0.5
                    if ent._longit_speed then
                        if ent._longit_speed < max_speed_anchor and
                           ent._longit_speed > -max_speed_anchor then

                            ent.anchored = true
                            ent.object:set_velocity(vector.new())
                            if name then
                                minetest.chat_send_player(name,core.colorize('#00ff00', " >>> Anchor away!"))
                            end
                            --ent.buoyancy = 0.1
                        else
                            if name then
                                minetest.chat_send_player(name,core.colorize('#ff0000', " >>> Too fast to set anchor!"))
                            end
                        end
                    end
                else
                    ent.anchored = false
                    if name then
                        minetest.chat_send_player(name,core.colorize('#00ff00', " >>> Weigh anchor!"))
                    end
                end
                --ent._rudder_angle = 0
            end
            if fields.light then
                if fields.light == "true" then
                    ent._show_light = true
                else
                    ent._show_light = false
                end
            end
            if fields.repair then
                fishing_boat.repair_formspec(name)
            end
        end
        minetest.close_formspec(name, "fishing_boat:pilot_main")
    end
    if formname == "fishing_boat:repair" then
        local name = player:get_player_name()
        local plane_obj = fishing_boat.getPlaneFromPlayer(player)
        if plane_obj == nil then
            minetest.close_formspec(name, "fishing_boat:repair")
            return
        end
        local ent = plane_obj:get_luaentity()
        if ent then
		    if fields.doit then
                local plane_obj = fishing_boat.getPlaneFromPlayer(player)
                if plane_obj == nil then
                    return
                end
                local ent = plane_obj:get_luaentity()
                local buoyancy = ent.buoyancy
                local tax = math.ceil(fishing_boat.getRepairTax(ent))

                local inventory_item = "default:steel_ingot"
                local inv = player:get_inventory()
                if inv:contains_item("main", inventory_item) then
                    if tax > 6 then
                        --the ship is sunk, so check if the player have all the value to repair
                        if inv:contains_item("main", inventory_item.." "..tax) == false then
                            minetest.chat_send_player(player:get_player_name(), "The boat is sunk, so you need all the ammount to do the repair.")
                            minetest.close_formspec(name, "fishing_boat:repair")
                            return
                        end
                    end
                    local stack = ItemStack(inventory_item.." "..tax)
                    --local stack = ItemStack(inventory_item .. " 1")
                    local taken = inv:remove_item("main", stack)
                    local total = taken:get_count()
                    local buoyancy_tax = 0.02
                    ent.buoyancy = buoyancy - (total*buoyancy_tax)
                    if ent.buoyancy < fishing_boat.default_buoyancy then ent.buoyancy = fishing_boat.default_buoyancy end
                else
                    minetest.chat_send_player(player:get_player_name(), "You need steel ingots in your inventory to perform this repair.")
                end
		    end

        end
        minetest.close_formspec(name, "fishing_boat:repair")
    end
end)


minetest.register_chatcommand("fishing_boat_share", {
	params = "name",
	description = "Share ownewrship with your friends",
	privs = {interact = true},
	func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local target_player = minetest.get_player_by_name(param)
        local attached_to = player:get_attach()
    
		if attached_to ~= nil and target_player ~= nil then
            local seat = attached_to:get_attach()
            if seat ~= nil then
                local entity = seat:get_luaentity()
                if entity then
                    if entity.name == "fishing_boat:boat" then
                        if entity.owner == name then
                            local exists = false
                            for k, v in pairs(entity._shared_owners) do
                                if v == param then
                                    exists = true
                                    break
                                end
                            end
                            if exists == false then
                                table.insert(entity._shared_owners, param)
                                minetest.chat_send_player(name,core.colorize('#00ff00', " >>> boat shared"))
                                --minetest.chat_send_all(dump(entity._shared_owners))
                            else
                                minetest.chat_send_player(name,core.colorize('#ff0000', " >>> this user is already registered for boat share"))
                            end
                        else
                            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> only the owner can share this boat"))
                        end
                    else
			            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
                    end
                end
            end
		else
			minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
		end
	end
})

minetest.register_chatcommand("fishing_boat_remove", {
	params = "name",
	description = "Removes ownewrship from someone",
	privs = {interact = true},
	func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local attached_to = player:get_attach()
    
		if attached_to ~= nil then
            local seat = attached_to:get_attach()
            if seat ~= nil then
                local entity = seat:get_luaentity()
                if entity then
                    if entity.name == "fishing_boat:boat" then
                        if entity.owner == name then
                            for k, v in pairs(entity._shared_owners) do
                                if v == param then
                                    table.remove(entity._shared_owners,k)
                                    break
                                end
                            end
                            minetest.chat_send_player(name,core.colorize('#00ff00', " >>> user removed"))
                            --minetest.chat_send_all(dump(entity._shared_owners))
                        else
                            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> only the owner can do this action"))
                        end
                    else
			            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
                    end
                end
            end
		else
			minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
		end
	end
})

minetest.register_chatcommand("fishing_boat_list", {
	params = "",
	description = "Lists the boat shared owners",
	privs = {interact = true},
	func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local attached_to = player:get_attach()
    
		if attached_to ~= nil then
            local seat = attached_to:get_attach()
            if seat ~= nil then
                local entity = seat:get_luaentity()
                if entity then
                    if entity.name == "fishing_boat:boat" then
                        minetest.chat_send_player(name,core.colorize('#ffff00', " >>> Current owners are:"))
                        minetest.chat_send_player(name,core.colorize('#0000ff', entity.owner))
                        for k, v in pairs(entity._shared_owners) do
                            minetest.chat_send_player(name,core.colorize('#00ff00', v))
                        end
                        --minetest.chat_send_all(dump(entity._shared_owners))
                    else
			            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
                    end
                end
            end
		else
			minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
		end
	end
})

minetest.register_chatcommand("fishing_boat_lock", {
	params = "true/false",
	description = "Blocks boarding of non-owners. true to lock, false to unlock",
	privs = {interact = true},
	func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local attached_to = player:get_attach()
    
		if attached_to ~= nil then
            local seat = attached_to:get_attach()
            if seat ~= nil then
                local entity = seat:get_luaentity()
                if entity then
                    if entity.name == "fishing_boat:boat" then
                        if param == "true" then
                            entity._passengers_locked = true
                            minetest.chat_send_player(name,core.colorize('#ffff00', " >>> Non owners cannot enter now."))
                        elseif param == "false" then
                            entity._passengers_locked = false
                            minetest.chat_send_player(name,core.colorize('#00ff00', " >>> Non owners are free to enter now."))
                        end
                    else
			            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
                    end
                end
            end
		else
			minetest.chat_send_player(name,core.colorize('#ff0000', " >>> you are not inside a boat to perform this command"))
		end
	end
})

minetest.register_chatcommand("fishing_boat_eject", {
	params = "",
	description = "Ejects from the boat - useful for clients before 5.3",
	privs = {interact = true},
	func = function(name, param)
        local colorstring = core.colorize('#ff0000', " >>> you are not inside a boat")
        local player = minetest.get_player_by_name(name)
        local attached_to = player:get_attach()

		if attached_to ~= nil then
            local seat = attached_to:get_attach()
            if seat ~= nil then
                local entity = seat:get_luaentity()
                if entity then
                    if entity.name == "fishing_boat:boat" then
                        for i = 5,1,-1 
                        do 
                            if entity._passengers[i] == name then
                                fishing_boat.dettach_pax(entity, player, "l")
                                break
                            end
                        end
                    else
			            minetest.chat_send_player(name,colorstring)
                    end
                end
            end
		else
			minetest.chat_send_player(name,colorstring)
		end
	end
})
