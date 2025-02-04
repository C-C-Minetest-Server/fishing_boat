--
-- constants
--
local LONGIT_DRAG_FACTOR = 0.13*0.13
local LATER_DRAG_FACTOR = 2.0

--
-- seat pivot
--
minetest.register_entity('fishing_boat:stand_base',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=true,
        collisionbox = {-2, -2, -2, 2, 0, 2},
	    pointable=false,
	    visual = "mesh",
	    mesh = "fishing_boat_stand_base.b3d",
        textures = {"fishing_boat_alpha.png",},
	},
    dist_moved = 0,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
})

minetest.register_entity('fishing_boat:light',{
initial_properties = {
	physical = false,
	collide_with_objects=false,
	pointable=false,
    glow = 0,
	visual = "mesh",
	mesh = "fishing_boat_light.b3d",
    textures = {"fishing_boat_light_off.png","fishing_boat_black.png",},
	},

    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
	
})

minetest.register_entity("fishing_boat:boat", {
    initial_properties = {
        physical = true,
        collide_with_objects = true, --true,
        collisionbox = {-2, -2.5, -2, 2, 6, 2}, --{-1,0,-1, 1,0.3,1},
        --selectionbox = {-0.6,0.6,-0.6, 0.6,1,0.6},
        visual = "mesh",
        --backface_culling = false,
        mesh = "fishing_boat.b3d",
        textures = fishing_boat.textures_copy(),
    },
    textures = {},
    driver_name = nil,
    sound_handle = nil,
    static_save = true,
    infotext = "A nice Fishing boat",
    lastvelocity = vector.new(),
    hp = 50,
    color = "#0063b0",
    color2 = "#dc1818",
    logo = "fishing_boat_alpha_logo.png",
    timeout = 0;
    buoyancy = fishing_boat.default_buoyancy,
    max_hp = 50,
    anchored = false,
    physics = fishing_boat.physics,
    hull_integrity = nil,
    owner = "",
    _last_time_command = 0,
    _shared_owners = {},
    _engine_running = false,
    _power_lever = 0,
    _last_applied_power = -100,
    _at_control = false,
    _rudder_angle = 0,
    _show_hud = true,
    _energy = 1.0,--0.001,
    _passengers = {}, --passengers list
    _passengers_base = {}, --obj id
    _passengers_base_pos = fishing_boat.copy_vector({}),
    _passengers_locked = false,
    _disconnection_check_time = 0,
    _inv = nil,
    _inv_id = "",
    _show_light = false,
    _light_old_pos = nil,

    get_staticdata = function(self) -- unloaded/unloads ... is now saved
        return minetest.serialize({
            stored_is_running = self._engine_running,
            stored_energy = self._energy,
            stored_owner = self.owner,
            stored_shared_owners = self._shared_owners,
            stored_color = self.color,
            stored_color2 = self.color2,
            stored_anchor = self.anchored,
            stored_hull_integrity = self.hull_integrity,
            stored_inv_id = self._inv_id,
            stored_passengers = self._passengers, --passengers list
            stored_passengers_locked = self._passengers_locked,
            stored_light_old_pos = self._light_old_pos,
            stored_show_light = self._show_light,
            stored_buoyancy = self.buoyancy,
        })
    end,

	on_deactivate = function(self)
        airutils.save_inventory(self)
        if self.sound_handle then minetest.sound_stop(self.sound_handle) end
	end,

    on_activate = function(self, staticdata, dtime_s)
        --minetest.chat_send_all('passengers: '.. dump(self._passengers))
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.deserialize(staticdata) or {}
            self._engine_running = data.stored_is_running or false
            self._energy = data.stored_energy or 0
            self.owner = data.stored_owner or ""
            self._shared_owners = data.stored_shared_owners or {}
            self.color = data.stored_color
            self.color2 = data.stored_color2
            self.logo = data.stored_logo or "fishing_boat_alpha_logo.png"
            self.anchored = data.stored_anchor or false
            self.hull_integrity = data.stored_hull_integrity
            self._inv_id = data.stored_inv_id
            self._passengers = data.stored_passengers or fishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
            self._passengers_locked = data.stored_passengers_locked
            self._light_old_pos = data.stored_light_old_pos
            self._show_light = data.stored_show_light
            self.buoyancy = data.stored_buoyancy
            --minetest.debug("loaded: ", self._energy)
            local properties = self.object:get_properties()
            properties.infotext = data.stored_owner .. " nice Fishing boat"
            self.object:set_properties(properties)
        end


        fishing_boat.paint(self)

        local pos = self.object:get_pos()
        self._light = minetest.add_entity(pos,'fishing_boat:light')
        self._light:set_attach(self.object,'',self._passengers_base_pos[1],{x=0,y=0,z=0})

        self._passengers_base = fishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
        self._passengers_base_pos = fishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
        self._passengers_base_pos = {
                [1]=fishing_boat.copy_vector(fishing_boat.passenger_pos[1]),
                [2]=fishing_boat.copy_vector(fishing_boat.passenger_pos[2]),
                [3]=fishing_boat.copy_vector(fishing_boat.passenger_pos[3]),
                [4]=fishing_boat.copy_vector(fishing_boat.passenger_pos[4]),
                [5]=fishing_boat.copy_vector(fishing_boat.passenger_pos[5]),} --curr pos
        --self._passengers = {[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,} --passenger names

        self._passengers_base[1]=minetest.add_entity(pos,'fishing_boat:stand_base')
        self._passengers_base[1]:set_attach(self.object,'',self._passengers_base_pos[1],{x=0,y=0,z=0})

        self._passengers_base[2]=minetest.add_entity(pos,'fishing_boat:stand_base')
        self._passengers_base[2]:set_attach(self.object,'',self._passengers_base_pos[2],{x=0,y=0,z=0})

        self._passengers_base[3]=minetest.add_entity(pos,'fishing_boat:stand_base')
        self._passengers_base[3]:set_attach(self.object,'',self._passengers_base_pos[3],{x=0,y=0,z=0})

        self._passengers_base[4]=minetest.add_entity(pos,'fishing_boat:stand_base')
        self._passengers_base[4]:set_attach(self.object,'',self._passengers_base_pos[4],{x=0,y=0,z=0})

        self._passengers_base[5]=minetest.add_entity(pos,'fishing_boat:stand_base')
        self._passengers_base[5]:set_attach(self.object,'',self._passengers_base_pos[5],{x=0,y=0,z=0})

        --animation load - stoped
        self.object:set_animation({x = 1, y = 47}, 0, 0, true)

        self.object:set_bone_position("low_rudder_a", {x=0,y=-23,z=-27}, {x=-0,y=0,z=0})

        self.object:set_armor_groups({immortal=1})

        airutils.actfunc(self, staticdata, dtime_s)

        self.object:set_armor_groups({immortal=1})        

		local inv = minetest.get_inventory({type = "detached", name = self._inv_id})

        fishing_boat.engine_set_sound_and_animation(self)

		-- if the game was closed the inventories have to be made anew, instead of just reattached
		if not inv then
            airutils.create_inventory(self, fishing_boat.trunk_slots)
		else
		    self.inv = inv
        end
    end,

    on_step = function(self,dtime,colinfo)
	    self.dtime = math.min(dtime,0.2)
	    self.colinfo = colinfo
	    self.height = airutils.get_box_height(self)
	    
    --  physics comes first
	    local vel = self.object:get_velocity()
	    
	    if colinfo then 
		    self.isonground = colinfo.touching_ground
	    else
		    if self.lastvelocity.y==0 and vel.y==0 then
			    self.isonground = true
		    else
			    self.isonground = false
		    end
	    end
	    
	    self:physics()

	    if self.logic then
		    self:logic()
	    end
	    
	    self.lastvelocity = self.object:get_velocity()
	    self.time_total=self.time_total+self.dtime
    end,
    logic = function(self)
        
        local accel_y = self.object:get_acceleration().y
        local rotation = self.object:get_rotation()
        local yaw = rotation.y
        local newyaw=yaw
        local pitch = rotation.x
        local newpitch = pitch
        local roll = rotation.z

        local hull_direction = minetest.yaw_to_dir(yaw)
        local nhdir = {x=hull_direction.z,y=0,z=-hull_direction.x}        -- lateral unit vector
        local velocity = self.object:get_velocity()

        local longit_speed = fishing_boat.dot(velocity,hull_direction)
        self._longit_speed = longit_speed --for anchor verify
        local longit_drag = vector.multiply(hull_direction,longit_speed*
                longit_speed*LONGIT_DRAG_FACTOR*-1*fishing_boat.sign(longit_speed))
        local later_speed = fishing_boat.dot(velocity,nhdir)
        local later_drag = vector.multiply(nhdir,later_speed*later_speed*
                LATER_DRAG_FACTOR*-1*fishing_boat.sign(later_speed))
        local accel = vector.add(longit_drag,later_drag)

        local vel = self.object:get_velocity()
        local curr_pos = self.object:get_pos()
        self._last_pos = curr_pos
        self.object:move_to(curr_pos)

        --minetest.chat_send_all(self._energy)
        --local node_bellow = airutils.nodeatpos(airutils.pos_shift(curr_pos,{y=-2.8}))
        --[[local is_flying = true
        if node_bellow and node_bellow.drawtype ~= 'airlike' then is_flying = false end]]--

        local is_attached = false
        local player = nil
        if self.driver_name then
            player = minetest.get_player_by_name(self.driver_name)
            
            if player then
                is_attached = fishing_boat.checkAttach(self, player)
            end

            if is_attached then
        		local ctrl = player:get_player_control()
	            if ctrl.jump then
                    --sets the engine running - but sets a delay also, cause keypress
                    if self._last_time_command > 2.0 then
                        self._last_time_command = 0.0
                        minetest.sound_play({name = "fishing_boat_horn"},
	                            {object = self.object, gain = 0.6, pitch = 1.0, max_hear_distance = 32, loop = false,})
                    end
	            end
            end
        end

        if self.owner == "" then return end

        --detect collision
        fishing_boat.testDamage(self, vel, curr_pos)

        accel = fishing_boat.control(self, self.dtime, hull_direction, longit_speed, accel) or vel

        --get disconnected players
        fishing_boat.rescueConnectionFailedPassengers(self)

        local turn_rate = math.rad(18)
        newyaw = yaw + self.dtime*(1 - 1 / (math.abs(longit_speed) + 1)) *
            self._rudder_angle / 30 * turn_rate * fishing_boat.sign(longit_speed)



        --roll adjust
        ---------------------------------
        local sdir = minetest.yaw_to_dir(newyaw)
        local snormal = {x=sdir.z,y=0,z=-sdir.x}    -- rightside, dot is negative
        local prsr = fishing_boat.dot(snormal,nhdir)
        local rollfactor = -15
        local newroll = 0
        if self._last_roll ~= nil then newroll = self._last_roll end
        --oscilation when stoped
        if longit_speed == 0 and self.buoyancy < 0.35 then
            local time_correction = (self.dtime/fishing_boat.ideal_step)
            --stoped
            if self._roll_state == nil then
                self._roll_state = math.floor(math.random(-1,1))
                if self._roll_state == 0 then self._roll_state = 1 end
                self._last_roll = newroll
            end
            local max_roll_bob = 2
            if math.deg(newroll) >= max_roll_bob and self._roll_state == 1 then
                self._roll_state = -1
                fishing_boat.play_rope_sound(self);
            end
            if math.deg(newroll) <= -max_roll_bob and self._roll_state == -1 then
                self._roll_state = 1
                fishing_boat.play_rope_sound(self);
            end
            local roll_factor = (self._roll_state * 0.01) * time_correction
            self._last_roll = self._last_roll + math.rad(roll_factor)
        else
            --in movement
            self._roll_state = nil
            newroll = (prsr*math.rad(rollfactor))*later_speed
            if self._last_roll ~= nil then 
                if math.sign(newroll) ~= math.sign(self._last_roll) then
                    fishing_boat.play_rope_sound(self)
                end
            end
            self._last_roll = newroll
        end
        --minetest.chat_send_all('newroll: '.. newroll)
        ---------------------------------
        -- end roll

        accel.y = accel_y
        newpitch = velocity.y * math.rad(1.5)

        --lets do some bob and set acceleration
		local bob = fishing_boat.minmax(fishing_boat.dot(accel,hull_direction),0.5)	-- vertical bobbing
		if self.isinliquid then
            if self._last_rnd == nil then self._last_rnd = math.random(1, 3) end
            if self._last_water_touch == nil then self._last_water_touch = self._last_rnd end
            if self._last_water_touch <= self._last_rnd then
                self._last_water_touch = self._last_water_touch + self.dtime
            end
            if math.abs(bob) > 0.1 and self._last_water_touch >=self._last_rnd then
                self._last_rnd = math.random(1, 3)
                self._last_water_touch = 0
                minetest.sound_play("default_water_footstep", {
                    --to_player = self.driver_name,
                    object = self.object,
                    max_hear_distance = 15,
                    gain = 0.07,
                    fade = 0.0,
                    pitch = 1.0,
                }, true)
            end

			accel.y = accel_y + bob
			newpitch = velocity.y * math.rad(6)

            self.object:set_acceleration(accel)
		end

        fishing_boat.engine_set_sound_and_animation(self)

        --time for rotations
        self.object:set_rotation({x=newpitch,y=newyaw,z=newroll})

        self.object:set_bone_position("rudder", {x=0,y=0,z=0}, {x=0,y=self._rudder_angle,z=0})
        self.object:set_bone_position("timao", {x=0,y=7.06,z=15}, {x=0,y=0,z=self._rudder_angle*8})

        local N_angle = math.deg(newyaw)
        local S_angle = N_angle + 180

        self.object:set_bone_position("compass_axis", {x=0,y=11.3,z=19.2}, {x=0, y=S_angle, z=0}) -- y 19.24    z 11.262

        --saves last velocy for collision detection (abrupt stop)
        self._last_vel = self.object:get_velocity()
        self._last_accell = accel

        fishing_boat.move_persons(self)

        --lets work on light now
        if self._last_light_move == nil then self._last_light_move = 0 end
        self._last_light_move = self._last_light_move + self.dtime
        if self._last_light_move > 0.15 then
            self._last_light_move = 0
            if self._show_light == true then
                --self.lights:set_properties({is_visible=true})
                fishing_boat.put_light(self)
                self._light:set_properties({textures={"fishing_boat_light_on.png","fishing_boat_black.png",}, glow=32})
            else
                --self.lights:set_properties({is_visible=false})
                fishing_boat.remove_light(self)
                self._light:set_properties({textures={"fishing_boat_light_off.png","fishing_boat_black.png",}, glow=0})
            end
        end

        --let sunk
        if self.buoyancy > 0.35 and self.buoyancy < 1.02 then self.buoyancy = self.buoyancy + 0.001 end
        if self.buoyancy > 0.30 then self._engine_running = false end


    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        if not puncher or not puncher:is_player() then
            return
        end
        local is_admin = false
        is_admin = minetest.check_player_privs(puncher, {server=true})
		local name = puncher:get_player_name()
        if self.owner == nil then
            self.owner = name
        end
            
        if self.driver_name and self.driver_name ~= name then
            -- do not allow other players to remove the object while there is a driver
            return
        end
        
        local is_attached = fishing_boat.checkAttach(self, puncher)

        local itmstck=puncher:get_wielded_item()
        local item_name = ""
        if itmstck then item_name = itmstck:get_name() end

        if is_attached == true then
            --refuel
            fishing_boat.load_fuel(self, puncher)
        end
        if self.owner and self.owner ~= name and self.owner ~= "" then
            if is_admin == false then return end
        end
        -- deal with painting or destroying
        if itmstck then
            local _,indx = item_name:find('dye:')
            if indx then

                --lets paint!!!!
                local color = item_name:sub(indx+1)
                local colstr = fishing_boat.colors[color]
                --minetest.chat_send_all(color ..' '.. dump(colstr))
                if colstr and (name == self.owner or minetest.check_player_privs(puncher, {protection_bypass=true})) then
                    local ctrl = puncher:get_player_control()
                    if ctrl.aux1 then
                        fishing_boat.paint2(self, colstr)
                    else
                        fishing_boat.paint1(self, colstr)
                    end
                    itmstck:set_count(itmstck:get_count()-1)
                    puncher:set_wielded_item(itmstck)
                end
                return
                -- end painting
            end
        end

        if is_attached == false then
            local i = 0
            local has_passengers = false
            for i = fishing_boat.max_seats,1,-1 
            do 
                if self._passengers[i] ~= nil then
                    has_passengers = true
                    break
                end
            end

            if not has_passengers and toolcaps and toolcaps.damage_groups and
                    toolcaps.groupcaps and toolcaps.groupcaps.choppy then

                local is_empty = true --[[false
                local inventory = airutils.get_inventory(self)
                if inventory then
                    if inventory:is_empty("main") then is_empty = true end
                end]]--

                --airutils.make_sound(self,'hit')
                if is_empty == true then
                    self.hp = self.hp - 10
                    minetest.sound_play("fishing_boat_collision", {
                        object = self.object,
                        max_hear_distance = 5,
                        gain = 1.0,
                        fade = 0.0,
                        pitch = 1.0,
                    })
                end
            end

            if self.hp <= 0 then
                fishing_boat.destroy(self, false)
            end

        end
        
    end,

    on_rightclick = function(self, clicker)
        local message = ""
		if not clicker or not clicker:is_player() then
			return
		end

        local name = clicker:get_player_name()

        if self.owner == "" then
            self.owner = name
        end

        local touching_ground, liquid_below = airutils.check_node_below(self.object, 2.5)
        local is_on_ground = self.isinliquid or touching_ground or liquid_below
        local is_under_water = airutils.check_is_under_water(self.object)

        --minetest.chat_send_all('passengers: '.. dump(self._passengers))
        --=========================
        --  form to pilot
        --=========================
        local is_attached = false
        local seat = clicker:get_attach()
        if seat then
            local plane = seat:get_attach()
            if plane == self.object then is_attached = true end
        end

        --check error after being shot for any other mod
        if is_attached == false then
            for i = fishing_boat.max_seats,1,-1 
            do 
                if self._passengers[i] == name then
                    self._passengers[i] = nil --clear the wrong information
                    break
                end
            end
        end

        --shows pilot formspec
        if name == self.driver_name then
            if is_attached then
                fishing_boat.pilot_formspec(name)
            else
                self.driver_name = nil
            end
        --=========================
        --  attach passenger
        --=========================
        else
            local pass_is_attached = fishing_boat.check_passenger_is_attached(self, name)

            if pass_is_attached then
                local can_bypass = minetest.check_player_privs(clicker, {protection_bypass=true})
                if clicker:get_player_control().aux1 == true then --lets see the inventory
                    local is_shared = false
                    --share to owner, bypass or if the ship is sunk
                    if name == self.owner or can_bypass or self.buoyancy > 0.7 then is_shared = true end
                    for k, v in pairs(self._shared_owners) do
                        if v == name then
                            is_shared = true
                            break
                        end
                    end
                    if is_shared then
                        airutils.show_vehicle_trunk_formspec(self, clicker, fishing_boat.trunk_slots)
                    end
                else
                    if self.driver_name ~= nil and self.driver_name ~= "" then
                        --lets take the control by force
                        if name == self.owner or can_bypass then
                            --require the pilot position now
                            fishing_boat.owner_formspec(name)
                        else
                            fishing_boat.pax_formspec(name)
                        end
                    else
                        --check if is on owner list
                        local is_shared = false
                        if name == self.owner or can_bypass then is_shared = true end
                        for k, v in pairs(self._shared_owners) do
                            if v == name then
                                is_shared = true
                                break
                            end
                        end
                        --normal user
                        if is_shared == false then
                            fishing_boat.pax_formspec(name)
                        else
                            --owners
                            fishing_boat.pilot_formspec(name)
                        end
                    end
                end
            else
                --first lets clean the boat slots
                --note that when it happens, the "rescue" function will lost the historic
                for i = fishing_boat.max_seats,1,-1 
                do 
                    if self._passengers[i] ~= nil then
                        local old_player = minetest.get_player_by_name(self._passengers[i])
                        if not old_player then self._passengers[i] = nil end
                    end
                end
                --attach normal passenger
                --if self._door_closed == false then
                    fishing_boat.attach_pax(self, clicker)
                --end
            end
        end

    end,
})
