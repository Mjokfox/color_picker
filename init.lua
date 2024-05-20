local color_picker = {}
local width = 64
local height = 64;
local max_value = 15
local saturation = 0;
local mapping_type_index = "2"
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

--magic oklab stuff
local function lch_to_lab(L, C, h)
    local a = C * math.cos(h * math.pi / 180)
    local b = C * math.sin(h * math.pi / 180)
    return L, a, b
end

--magic oklab stuff
local function oklab_to_linear_srgb(L, a, b)
    local l_ = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
    local m_ = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
    local s_ = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3

    local r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    local g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    local b = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_

    return r, g, b
end

--magic oklab stuff
local function linear_to_srgb(x)
    if x <= 0.0031308 then
        return 12.92 * x
    else
        return 1.055 * x^(1/2.4) - 0.055
    end
end

--magic oklab stuff
local function lch_to_rgb(L, C, h)
    local r, g, b = oklab_to_linear_srgb(lch_to_lab(L, C, h))

    r = linear_to_srgb(r)
    g = linear_to_srgb(g)
    b = linear_to_srgb(b)

    return math.floor(r * max_value), math.floor(g * max_value), math.floor(b * max_value)
end

-- helper function
local function toHex(decimal)
	if (decimal < 0) then
		decimal = 0
	end
	if (decimal > max_value) then
		decimal = max_value
	end
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
	else if (dropdown_index == "4") then
		labels = {"L","C","h"}
		maxs = {100,100,360}
		units = {"%%","%%","\u{00B0}"}
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
					buf[#buf + 1] = "item_image_button[".. old_x*size + x_off + 0.0001 ..",".. y*size + y_off + 0.0001 ..";"..size*temp_width..","..size..";hexcol:".. ohexr .. ohexg .. ohexb ..";hexcol:".. ohexr .. ohexg .. ohexb ..";]"
					temp_width = 1
					old_x = x;
				end
				ohexr,ohexg,ohexb = hexr,hexg,hexb
			else
				buf[#buf + 1] = "item_image_button[".. x*size + x_off + 0.0001 ..",".. y*size + y_off + 0.0001 ..";"..size..","..size..";hexcol:".. hexr .. hexg .. hexb ..";hexcol:".. hexr .. hexg .. hexb ..";]"
			end
			
		end
		if (map_optimization) then
			if (temp_width>1) then
				buf[#buf + 1] = "item_image_button[".. old_x*size + x_off + 0.0001 ..",".. y*size + y_off + 0.0001 ..";"..size*(temp_width-1)..","..size..";hexcol:".. ohexr .. ohexg .. ohexb ..";hexcol:".. ohexr .. ohexg .. ohexb ..";]"
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
