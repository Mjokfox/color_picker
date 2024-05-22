local color_picker = {}
local playermodes = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/converters.lua")

local width = minetest.settings:get("map_size")

if (width == nil) then
	width = 64
	minetest.settings:set("map_size",64)
end

local mapUpdateTimeout = tonumber(minetest.settings:get("mapUpdateTimeout"))

if (mapUpdateTimeout == nil) then
	mapUpdateTimeout = 1
	minetest.settings:set("mapUpdateTimeout",1)
end

local height = width

-- helper function
local function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

-- color sliders 
local function assemble_sliders(player,x,y,w,h)
	-- labels
	local buf = {}
	local user = playermodes[player:get_player_name()]
	if (not user) then return buf end
	local dropdown_index = user.dropdown_index
	local bars = user.bars
	local r,g,b
	local labels = {"H","S","V"}
	local units = {"\u{00B0}","%%","%%"}
	local maxs = {360,100,100}
	local steps = {36,10,10}

	-- set r,g,b and change labels if necessary
	if (dropdown_index == "2") then
		r,g,b = hsv_to_rgb(bars[1]/360,bars[2]/100,bars[3]/100)
	else if (dropdown_index == "3") then
		labels[3] = "L"
		r,g,b = hsl_to_rgb(bars[1]/360,bars[2]/100,bars[3]/100)
	else if (dropdown_index == "4") then
		labels = {"L","C","h"}
		maxs = {100,100,360}
		units = {"%%","%%","\u{00B0}"}
		steps = {10,10,36}
		r,g,b = lch_to_rgb(bars[1]/100,bars[2]/100,bars[3])
	else
		labels = {"R","G","B"}
		units = {"","",""}
		maxs = {15,15,15}
		steps = {1,1,1}
		r,g,b = tonumber(bars[1]),tonumber(bars[2]),tonumber(bars[3])
	end end end
	local hexr,hexg,hexb = toHex(r),toHex(g),toHex(b)
	-- preview color
	local label = "click me!"
	local temp = minetest.formspec_escape(";")
	if (r==4 and g==2 and b==0) then label = "Nice" 
	else if (r==6 and g==2 and b==1) then label = temp .."3"
	else if (r==6 and g==6 and b==6) then label = "Feeling devious today.." 
	else if (r==7 and g==7 and b==7) then label = "Feeling lucky today.." end end end end
	buf[#buf + 1] = "item_image_button[".. x..",".. y+h ..";"..w..","..5*h..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";"..label.."]"

	-- generate the sliders
	y=y+5*h
	for i=1,3 do
		buf[#buf + 1] = "label[".. x-0.4 ..",".. y+(i+0.5)*h ..";".. labels[i] .."]" -- label showing what kind of slider
		buf[#buf + 1] = "scrollbaroptions[min=0;max=".. maxs[i] ..";smallstep=".. steps[i] .."]" -- options
		buf[#buf + 1] = "scrollbar[".. x ..",".. y + i*h ..";".. w ..",".. h ..";horizontal;bar" .. i .. ";" .. bars[i] .. "]" -- slider itself

		-- slider exact value showing
		buf[#buf + 1] = "scroll_container[".. x + w + 0.3 ..",".. y + i*h + h*0.2 ..";1,0.6;bar" .. i .. ";vertical;1]"
		if (dropdown_index == "1") then
			for n = 0, maxs[i] do
				buf[#buf + 1] = ("label[0,%s;%s".. units[i] .."]"):format(n + h*0.3, toHex(n))
			end
		else
			for n = 0, maxs[i] do
				buf[#buf + 1] = ("label[0,%s;%s".. units[i] .."]"):format(n + h*0.3, n)
			end
		end
		buf[#buf + 1] = "scroll_container_end[]"
	end
	return buf
end

-- color map
local function Assemble_Map(player,x_off,y_off)
	local buf = {}
	local user = playermodes[player:get_player_name()]
	if (not user) then return buf end
	local dropdown_index = user.dropdown_index
	local saturation = user.saturation
	local size = 12.8/(width + height)
	buf[#buf + 1] = "label[".. x_off + (width*size)/2 - string.len("click any color!")/15 ..",".. y_off + 0.5 ..";click any color!]"
	local label = "saturation"
	if (dropdown_index == "4") then label = "chroma " end
	if (dropdown_index == "1") then label = "red" end
	buf[#buf + 1] = "label[".. x_off + 7.5 - string.len(label)/15 ..",".. y_off + 0.5 ..";".. label .."]"
	y_off=y_off+1
	-- saturation slider
	local max = 10
	local step = 1;
	if (dropdown_index == "1") then max = 15; step = 1 end
	buf[#buf + 1] = "scrollbaroptions[min=0;max=".. max ..";smallstep=".. step ..";thumbsize=1]"
	buf[#buf + 1] = "scrollbar[".. x_off + 7 ..",".. y_off ..";0.5,6.4;vertical;saturation;".. saturation .."]"
	-- full map
	
	local size_increase = 1.5
	local y_axis,x_axis = "lightness","hue"
	local hexr,hexg,hexb
	local ohexr,ohexg,ohexb
	local temp_width = 1;
	local old_x = 0;
	local map_optimization = true;
	if (dropdown_index == "1") then
		local temp_size = 0.4
		local r,g,b
		for y = 0,15 do
			for x = 0,15 do
				r,g,b = 15-saturation,y%16,x%16
				hexr,hexg,hexb = toHex(r),toHex(g),toHex(b)
				buf[#buf + 1] = "item_image_button[".. x*temp_size + x_off ..",".. y*temp_size + y_off ..";"..(temp_size*size_increase)..","..(temp_size*size_increase)..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";]"
			end
		end
		y_axis,x_axis = "green","blue"
	else
		for y = 0,height-1 do
			for x = 0,width-1 do
				-- set r,g,b using the selected mapping method
				local r,g,b = 0,0,0;
				if (dropdown_index == "2") then
					y_axis,x_axis = "value","hue"
					r,g,b = hsv_to_rgb(x / width,1-saturation/10,(height-y) / height)
				else if (dropdown_index == "3") then
					r,g,b = hsl_to_rgb(x / width,1-saturation/10,(height-y) / height)
				else if (dropdown_index == "4") then
					y_axis = "p lightness"
					r,g,b = lch_to_rgb((height-y) / height, 1-saturation/10, 360*(x / width))
				else
					y_axis = "chroma"
					-- r,g,b = math.floor(x/(width/4))+math.floor(y/(width/4))*(width/16),y%16,x%16
					r,g,b = lch_to_rgb(1-saturation/10, (height-y) / height, 360*(x / width))
				end end end
				
				hexr,hexg,hexb = toHex(r),toHex(g),toHex(b)
				if (x==0) then
					ohexr,ohexg,ohexb = hexr,hexg,hexb
				end

				if (map_optimization) then
					if (ohexr == hexr and ohexg == hexg and ohexb == hexb) then
						temp_width = temp_width + 1
						if (temp_width == 2) then old_x = x end
					else
						-- use hexcol mod to display the buttons as their blocks
						if temp_width == 1 then
							old_x = x
						end
						buf[#buf + 1] = "item_image_button[".. old_x*size + x_off ..",".. y*size + y_off ..";"..size*(temp_width-1+size_increase)..","..(size*size_increase)..";hexcol:".. ohexr .. ohexg .. ohexb ..";hexcol:".. ohexr .. ohexg .. ohexb ..";]"
						temp_width = 1
						old_x = x;
					end
					ohexr,ohexg,ohexb = hexr,hexg,hexb
				else
					buf[#buf + 1] = "item_image_button[".. x*size + x_off ..",".. y*size + y_off ..";"..(size*size_increase)..","..(size*size_increase)..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";]"
				end
				
			end
			if (map_optimization) then
				if (temp_width>1) then
					buf[#buf + 1] = "item_image_button[".. old_x*size + x_off ..",".. y*size + y_off ..";"..(size)*(temp_width-2+size_increase)..","..(size*size_increase)..";hexcol:".. ohexr .. ohexg .. ohexb ..";hexcol:".. ohexr .. ohexg .. ohexb ..";]"
					temp_width = 1;
				end
			end
		end
	end
	buf[#buf + 1] = "vertlabel[".. x_off-0.3 ..",".. y_off + (height*size)/2 - string.len(y_axis)/7 ..";".. y_axis .."]"
	buf[#buf + 1] = "label[".. x_off + (width*size)/2 - string.len(x_axis)/15 ..",".. y_off+(height*size)+0.3 ..";".. x_axis .."]"
	return buf
end


local function assemble_colorspace(player)
	local user = playermodes[player:get_player_name()]
	if (not user) then return end
	-- stuff always in formspec
	user.fs = {
		"formspec_version[7]",
		"size[10.7,14]",
		"padding[0.05, 0.05]",
		"dropdown[2,0.3;3,0.7;mapping_type;map,sliders;" .. user.mapping_type_index ..";true]" ,
		"dropdown[5.5,0.3;3,0.7;color_space;rgb,hsv,hsl,Oklab;" .. user.dropdown_index ..";true]" ,
		"container[1,1]"
	}
	local x_off,y_off = 1,0
	local fs2 = {}
	if (user.mapping_type_index == "1") then fs2 = Assemble_Map(player,x_off,y_off)
	else if (user.mapping_type_index == "2") then fs2 = assemble_sliders(player,x_off,y_off,6.5,0.8) end end
	TableConcat(user.fs, fs2);
	user.fs[#user.fs+1] = "container_end[]"
	user.fs[#user.fs+1] = "list[current_player;main;0.5,9;8,4]"
end

-- helper function
function color_picker.show_formspec(player)
	local name = player:get_player_name()
	local user = playermodes[name]
	if (not user) then return end
	if (user.mapping_type_index == "1") then
		local now = os.time()
		local difftime = os.difftime(now,user.LastUpdate) 
		if (not user.job_active) then
			if (difftime > mapUpdateTimeout) then
				user.job_active = true
				
				assemble_colorspace(player);
				minetest.show_formspec(name, "color_picker:picker", table.concat(user.fs))
				user.LastUpdate = now
				minetest.after(mapUpdateTimeout - difftime, function () 
					if (not playermodes[player:get_player_name()]) then return end
					user.job_active = false
				end
				)
			else 
				user.job_active = true
				minetest.after(mapUpdateTimeout - difftime,
				function() 
					if (not playermodes[player:get_player_name()]) then return end
					assemble_colorspace(player)
					minetest.show_formspec(name, "color_picker:picker", table.concat(user.fs))
					user.LastUpdate = os.time()
					user.job_active = false
				end
				)
			end
		end
	else
		-- not map active
		assemble_colorspace(player);
		minetest.show_formspec(name, "color_picker:picker", table.concat(user.fs))
	end
	
end

-- register item
minetest.register_craftitem("color_picker:picker", {
	description = "color picker",
	inventory_image = "cspace.png",
	on_secondary_use = function(itemstack, player, pointed_thing)
		color_picker.show_formspec(player)
	end,
	on_place = function(itemstack, player, pointed_thing)
		color_picker.show_formspec(player)
	end
})

-- register button in inventory
if unified_inventory then
	unified_inventory.register_button("color_picker:picker", {
		type = "image",
		image = "cspace.png",
		tooltip = "Color Picker",
		action = function (player)
            color_picker.show_formspec(player)
		end,
		hide_lite = false,
	})
end

-- player does stuff in formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "color_picker:picker" then return end
	local user = playermodes[player:get_player_name()]
	if (not user) then return end
	for key,value in pairs(fields) do
		-- minetest.chat_send_all(key .. ": " .. value)
		if (string.sub(key,1,7) == "hexcol:") then
			local inv = player:get_inventory()
			inv:add_item("main",key .." 99");
		end
		if (string.sub(key,1,3) == "bar") then
			user.bars[tonumber(string.sub(key,4,4))] = value.split(value, ":")[2]
			if (value.split(value, ":")[1] == "CHG") then
				
				color_picker.show_formspec(player)
			end
		end
		
	end
	if (fields.saturation) then
		user.saturation = minetest.explode_scrollbar_event(fields.saturation).value
		if (user.dropdown_index == "1" and tonumber(user.saturation) > 15) then
			user.saturation = 15;
		end
		color_picker.show_formspec(player)
	end
	if (fields.mapping_type) then
		user.mapping_type_index = fields.mapping_type
		color_picker.show_formspec(player)
	end
	if (fields.color_space) then
		user.dropdown_index = fields.color_space
		if (user.dropdown_index == "1") then
			for i=1,#user.bars do
				if (tonumber(user.bars[i]) > 15) then
					user.bars[i] = "15";
				end
			end
		end
		color_picker.show_formspec(player)
	end
end)

minetest.register_on_joinplayer(function(ObjectRef, last_login)
	local name = ObjectRef:get_player_name()
	if (not playermodes[name]) then
		playermodes[name] = {}
		local user = playermodes[name]
		user.saturation = 0;
		user.mapping_type_index = "2"
		user.dropdown_index = "3"
		user.bars = {"0","100","50"}
		user.fs = {}
		user.LastUpdate = os.time()
		user.job_active = false
	end
end)


minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
	local name = ObjectRef:get_player_name()
	if (playermodes[name]) then playermodes[name] = nil end
end)
