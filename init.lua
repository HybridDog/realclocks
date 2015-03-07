local clock_cbox = {
	type = "fixed",
	fixed = {
		{ -1/4, -3/32, 7/16, 1/4, 3/32, .5 },
		{ -7/32, -5/32, 7/16, 7/32, 5/32, .5 },
		{ -3/16, -3/16, 7/16, 3/16, 3/16, .5 },
		{ -5/32, -7/32, 7/16, 5/32, 7/32, .5 },
		{ -3/32, -1/4, 7/16, 3/32, 1/4, .5 }
	}
}

local clock_sbox = {
	type = "fixed",
	fixed = { -1/4, -1/4, 7/16, 1/4, 1/4, .5 }
}

local materials = {"plastic", "wood"}

for _,m in ipairs(materials) do

minetest.register_node("realclocks:analog_clock_"..m.."_12", {
	drawtype = "mesh",
	description = "Analog "..m.." clock",
	mesh = "realclocks_analog_clock.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	tiles = { "realclocks_analog_clock_"..m..".png^clock_12.png" },
	inventory_image = "realclocks_analog_clock_"..m.."_inv.png",
	wield_image = "realclocks_analog_clock_"..m.."_inv.png",
	collision_box = clock_cbox,
	selection_box = clock_sbox,
	groups = {snappy=3},
})

minetest.register_craft({
    output = "realclocks:analog_clock_"..m.."_12",
    recipe = {
		{ "", "dye:black", "" },
		{ "", "default:stick", "" },
		{ "", "dye:black", "" },
    },
})

for i = 1,11 do

	minetest.register_node("realclocks:analog_clock_"..m.."_"..i, {
		drawtype = "mesh",
		mesh = "realclocks_analog_clock.obj",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		tiles = { "realclocks_analog_clock_"..m..".png^clock_"..i..".png" },
		collision_box = clock_cbox,
		selection_box = clock_sbox,
		groups = {snappy=3, not_in_creative_inventory=1},
		drop = "realclocks:analog_clock_"..m.."_12",
		on_punch = function(pos, node, puncher, pt)
			minetest.chat_send_all("k…")
			local dir = puncher:get_look_dir()
			local dist = vector.new(dir)

			local plpos = puncher:getpos()
			plpos.y = plpos.y+1.625

			if node.param2 == 0 then
				local shpos = {x=pos.x, y=pos.y, z=pos.z+7/16}

				dist.z = shpos.z-plpos.z
				local m = dist.z/dir.z
				dist.x = dist.x*m
				dist.y = dist.y*m
				local newp = vector.add(plpos, dist)
				local tp = vector.subtract(newp, shpos)
				local newtime = 0.25+math.acos(-tp.y/math.hypot(tp.x, tp.y))/(4*math.pi)
				local oldtime = minetest.get_timeofday()
				if oldtime < 0.25
				or oldtime > 0.75
				or oldtime > newtime then
					newtime = (0.5+newtime)%1
				end
				minetest.chat_send_all("time "..newtime*24)
				minetest.set_timeofday(newtime)
			end
			minetest.chat_send_all("it works again")
		end,
	})

end

for n = 1,12 do

	minetest.register_abm({
		nodenames = { "realclocks:analog_clock_"..m.."_"..n },
		interval = math.min(60, (3600 / (tonumber(minetest.setting_get("time_speed")))) / 3),
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local hour = minetest.get_timeofday() * 24
			if hour > 12 then
				hour = hour - 12
			end
			hour = math.ceil(hour)
			if hour < 1 then
				hour = 1
			elseif hour > 12 then
				hour = 12
			end
			if node.name ~= "realclocks:analog_clock_"..m.."_"..hour then
				local fdir = minetest.get_node(pos).param2
				minetest.set_node(pos, {name="realclocks:analog_clock_"..m.."_"..hour, param2=fdir})
			end
		end
	})
	
end
end
