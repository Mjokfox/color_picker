local color_picker = {}
local width = 64
local height = 64;
local saturation = 0;
local mapping_type_index = "2"
local dropdown_index = "3"
local bars = {"0","100","50"}
local fs = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/converters.lua")

-- color sliders 
local function assemble_sliders(x,y,w,h)
	-- labels
	local buf = {}
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
	buf[#buf + 1] = "label[".. x + w/3 ..",".. y + h/1.5 ..";click me!]"
	y=y+h
	buf[#buf + 1] = "item_image_button[".. x..",".. y ..";"..w..","..3*h..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";]"

	-- generate the sliders
	y=y+2*h
	for i=1,3 do
		buf[#buf + 1] = "label[".. x-0.4 ..",".. y+(i+0.5)*h ..";".. labels[i] .."]" -- label showing what kind of slider
		buf[#buf + 1] = "scrollbaroptions[min=0;max=".. maxs[i] ..";smallstep=".. steps[i] .."]" -- options
		buf[#buf + 1] = "scrollbar[".. x ..",".. y + i*h ..";".. w ..",".. h ..";horizontal;bar" .. i .. ";" .. bars[i] .. "]" -- slider itself

		-- slider exact value showing
		buf[#buf + 1] = "scroll_container[".. x + w + 0.3 ..",".. y + i*h + h*0.2 ..";1,0.6;bar" .. i .. ";vertical;1]"
		for n = 0, maxs[i] do
			buf[#buf + 1] = ("label[0,%s;%s".. units[i] .."]"):format(n + h*0.3, n)
		end
		buf[#buf + 1] = "scroll_container_end[]"
	end
	return buf
end

-- color map
local function Assemble_Map(x_off,y_off)
	local buf = {}
	buf[#buf + 1] = "label[".. x_off + 2 ..",".. y_off + 0.5 ..";click any color!]"
	local label = "saturation"
	if (dropdown_index == "4") then label = "chroma" end
	if (dropdown_index ~= "1") then
		buf[#buf + 1] = "label[".. x_off + 6.6 ..",".. y_off + 0.5 ..";".. label .."]"
		y_off=y_off+1
		-- saturation slider
		buf[#buf + 1] = "scrollbaroptions[min=0;max=10;smallstep=1;largestep=3]"
		buf[#buf + 1] = "scrollbar[".. x_off + 7 ..",".. y_off ..";1,6.4;vertical;saturation;".. saturation .."]"
	else
		y_off=y_off+1
	end
	-- full map
	local size = 0.1
	local size_increase = 1.5
	local y_axis,x_axis = "lightness","hue"
	local hexr,hexg,hexb
	local ohexr,ohexg,ohexb
	local temp_width = 1;
	local old_x = 0;
	local map_optimization = true;
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
				y_axis,x_axis = "",""
				r,g,b = math.floor(x/(width/4))+math.floor(y/(width/4))*(width/16),y%16,x%16
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
	buf[#buf + 1] = "vertlabel[".. x_off-0.3 ..",".. y_off + (height*size)/(string.len(y_axis)/1.3) ..";".. y_axis .."]"
	buf[#buf + 1] = "label[".. x_off + (width*size)/(string.len(x_axis)/1.3) ..",".. y_off+(height*size)+0.3 ..";".. x_axis .."]"
	return buf
end

-- helper function
local function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function assemble_colorspace()
	-- stuff always in formspec
	fs = {
		"formspec_version[7]",
		"size[10.7,14]",
		"padding[0.05, 0.05]",
		"dropdown[2,0.3;3,0.7;mapping_type;map,sliders;" .. mapping_type_index ..";true]" ,
		"dropdown[5.5,0.3;3,0.7;color_space;rgb,hsv,hsl,Oklab;" .. dropdown_index ..";true]" ,
		"container[1,1]"
	}
	local x_off,y_off = 1,0
	local fs2 = {}
	if (mapping_type_index == "1") then fs2 = Assemble_Map(x_off,y_off)
	else if (mapping_type_index == "2") then fs2 = assemble_sliders(x_off,y_off,6.5,1) end end
	TableConcat(fs, fs2);
	fs[#fs+1] = "container_end[]"
	fs[#fs+1] = "list[current_player;main;0.5,9;8,4]"
end

-- helper function
function color_picker.show_formspec(user)
	assemble_colorspace();
	minetest.show_formspec(user:get_player_name(), "color_picker:picker", table.concat(fs))
end

-- register item
minetest.register_craftitem("color_picker:picker", {
	description = "color picker",
	inventory_image = "cspace.png",
	on_secondary_use = function(itemstack, user, pointed_thing)
		color_picker.show_formspec(user)
	end,
	on_place = function(itemstack, user, pointed_thing)
		color_picker.show_formspec(user)
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
	
	for key,value in pairs(fields) do
		-- minetest.chat_send_all(key .. ": " .. value)
		if (string.sub(key,1,7) == "hexcol:") then
			local inv = player:get_inventory()
			inv:add_item("main",key .." 99");
		end
		if (string.sub(key,1,3) == "bar") then
			bars[tonumber(string.sub(key,4,4))] = value.split(value, ":")[2]
			if (value.split(value, ":")[1] == "CHG") then
				
				color_picker.show_formspec(player)
			end
		end
		
	end
	if (fields.saturation) then
		saturation = minetest.explode_scrollbar_event(fields.saturation).value
		color_picker.show_formspec(player)
	end
	if (fields.mapping_type) then
		mapping_type_index = fields.mapping_type
		color_picker.show_formspec(player)
	end
	if (fields.color_space) then
		dropdown_index = fields.color_space
		if (dropdown_index == "1") then
			for i=1,#bars do
				if (tonumber(bars[i]) > 15) then
					bars[i] = "15";
				end
			end
		end
		color_picker.show_formspec(player)
	end
end)
