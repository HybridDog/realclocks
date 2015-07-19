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

local function punch_clock(pos, node, puncher, pt)
	if not (pos and node and puncher and pt
		and puncher:get_player_control().aux1
	) then
		return
	end
	local pname = puncher:get_player_name()
	if not minetest.check_player_privs(pname, {settime=true}) then
		return
	end
	-- abort if the clock is punched not on the frontside
	if minetest.dir_to_facedir(vector.subtract(pt.under, pt.above)) ~= node.param2 then
		return
	end
	local dir = puncher:get_look_dir()
	local dist = vector.new(dir)

	local plpos = puncher:getpos()
	plpos.y = plpos.y+1.625

	local newtime,a,b,c,mpa,mpc
	b = "y"
	if node.param2 == 0 then
		a = "x"
		c = "z"
	elseif node.param2 == 1 then
		a = "z"
		c = "x"
		mpa = -1
	elseif node.param2 == 2 then
		a = "x"
		c = "z"
		mpc = -1
		mpa = -1
	elseif node.param2 == 3 then
		a = "z"
		c = "x"
		mpc = -1
	else
		return
	end

	mpa = mpa or 1
	mpc = mpc or 1
	local shpos = {[a]=pos[a], [b]=pos[b], [c]=pos[c]+7/16*mpc}

	dist[c] = shpos[c]-plpos[c]
	local m = dist[c]/dir[c]
	dist[a] = dist[a]*m
	dist[b] = dist[b]*m
	local newp = vector.add(plpos, dist)
	local tp = vector.subtract(newp, shpos)
	tp[a] = tp[a]*mpa
	local tm = math.acos(-tp[b]/math.hypot(tp[a], tp[b]))/(2*math.pi)
	newtime = 0.5+tm
	if tp[a] > 0 then
		newtime = 0.5-tm
	end
	newtime = newtime/2
	local oldtime = minetest.get_timeofday()
	if oldtime > 0.5 then
		newtime = 0.5+newtime
	end
	if oldtime > newtime then
		newtime = (0.5+newtime)%1
	end

	minetest.set_timeofday(newtime)

	local nodename = node.name
	nodename = string.sub(nodename, 1, -3)
	if string.sub(nodename, -1) ~= "_" then
		nodename = nodename.."_"
	end
	local readtime = math.floor(newtime*24+0.5)
	local nodenumber = readtime%12
	nodename = nodename..(nodenumber == 0 and 12 or nodenumber)
	if node.name ~= nodename then
		node.name = nodename
		minetest.set_node(pos, node)
	end
	minetest.chat_send_player(pname, "it's about "..readtime.." o'clock")
	--[[local cm = 16*(tp[a]*tp[a]+tp[b]*tp[b])/(3/16)^2
	local x = math.floor(tp[a]*cm+0.5)
	local y = math.floor(tp[b]*cm+0.5)
	update_object(pos, get_object_texture(x,y))]]
end

-- it needs to be 3/16 long (tx*tx+ty*ty)/(3/16)^2
local function get_object_texture(x,y)
	local antile = "_alpha16.png^[combine:16x16:"
	for _,p in pairs(vector.twoline(x-8, y-8)) do
		antile = antile..p[1]+8 ..","..p[2]+8 .."=_black.png:"
	end
	return string.sub(antile, 1, -2)
end

--[[minetest.register_node("realclocks:maa", {
	description = "Anlok",
	tiles = {get_object_texture(2,3)},
	groups = {snappy=3},
})]]

for _,m in pairs(materials) do

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
	on_punch = punch_clock
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
		on_punch = punch_clock
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
