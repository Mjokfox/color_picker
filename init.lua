local color_picker = {}
local width = 64
local height = 64;
local max_value = 15
local saturation = 0;
local mapping_type_index = "1"
local dropdown_index = "3"
local bars = {"0","100","50"}
local fs = {}

-- magic hsv/rgb functions
local function hue_to_rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
end

-- magic hsv/rgb functions
local function hsl_to_rgb(h, s, l)
    local r, g, b

    if s == 0 then
        r = l
        g = l
        b = l
    else
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1/3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1/3)
    end

    return math.floor(r * max_value), math.floor(g * max_value), math.floor(b * max_value)
end

-- magic hsv/rgb functions
local function hsv_to_rgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return math.floor(r * max_value), math.floor(g * max_value), math.floor(b * max_value)
end

-- helper function
local function toHex(decimal)
    local hex = string.format("%01x", decimal)
    return hex
end

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
	else
		labels = {"R","G","B"}
		units = {"","",""}
		maxs = {15,15,15}
		steps = {1,1,1}
		r,g,b = tonumber(bars[1]),tonumber(bars[2]),tonumber(bars[3])
	end end
	local hexr,hexg,hexb = toHex(r),toHex(g),toHex(b)
	-- preview color
	buf[#buf + 1] = "label[".. x + w/3 ..",".. y + h/1.5 ..";click me!]"
	y=y+h
	buf[#buf + 1] = "item_image_button[".. x..",".. y ..";"..w..","..2*h..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";]"

	-- generate the sliders
	y=y+h
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

	if (dropdown_index ~= "1") then
		buf[#buf + 1] = "label[".. x_off + 6.6 ..",".. y_off + 0.5 ..";saturation]"
		y_off=y_off+1
		-- saturation slider
		buf[#buf + 1] = "scrollbaroptions[min=0;max=10;smallstep=1;largestep=3]"
		buf[#buf + 1] = "scrollbar[".. x_off + 7 ..",".. y_off ..";1,6.5;vertical;saturation;".. saturation .."]"
	else
		y_off=y_off+1
	end
	-- full map
	local size = 0.1
	for x = 0,width-1 do
		for y = 0,height-1 do
			-- set r,g,b using the selected mapping method
			local r,g,b = 0,0,0;
			if (dropdown_index == "2") then
				r,g,b = hsv_to_rgb(x / width,1-saturation/10,(height-y) / height)
			else if (dropdown_index == "3") then
				r,g,b = hsl_to_rgb(x / width,1-saturation/10,(height-y) / height)
			else
				r,g,b = math.floor(x/(width/4))+math.floor(y/(width/4))*(width/16),y%16,x%16
			end end
	
			local hexr,hexg,hexb = toHex(r),toHex(g),toHex(b)
			-- use hexcol mod to display the buttons as their blocks
			buf[#buf + 1] = "item_image_button[".. x*size + x_off + 0.0001 ..",".. y*size + y_off + 0.0001 ..";"..size..","..size..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";]"
		end
	end
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
		"size[10,9]",
		"padding[0.05, 0.05]",
		"dropdown[1,0.3;2.5,0.6;mapping_type;map,sliders;" .. mapping_type_index ..";true]" ,
		"dropdown[4,0.3;2.5,0.6;color_space;rgb,hsv,hsl;" .. dropdown_index ..";true]" ,
		"container[1,1]"
	}
	local x_off,y_off = 0,0
	local fs2 = {}
	if (mapping_type_index == "1") then fs2 = Assemble_Map(x_off,y_off)
	else if (mapping_type_index == "2") then fs2 = assemble_sliders(x_off,y_off,6,1) end end
	TableConcat(fs, fs2);
	fs[#fs+1] = "container_end[]"
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
	unified_inventory.register_button("hexcol_picker", {
		type = "image",
		image = "cspace.png",
		tooltip = "Colour Picker",
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
