local max_value = 15

-- helper function
function toHex(decimal)
	if (decimal < 0) then
		decimal = 0
	end
	if (decimal > max_value) then
		decimal = max_value
	end
    local hex = string.format("%01x", decimal)
    return hex
end

-- magic hsv/rgb functions
function hue_to_rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
end

-- magic hsv/rgb functions
function hsl_to_rgb(h, s, l)
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
function hsv_to_rgb(h, s, v)
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

-- magic oklab stuff
function lch_to_lab(L, C, h)
    local a = C * math.cos(h * math.pi / 180)
    local b = C * math.sin(h * math.pi / 180)
    return L, a, b
end

-- magic oklab stuff
function oklab_to_linear_srgb(L, a, b)
    local l_ = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
    local m_ = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
    local s_ = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3

    local r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    local g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    local b = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_

    return r, g, b
end

-- magic oklab stuff
function linear_to_srgb(x)
    if x <= 0.0031308 then
        return 12.92 * x
    else
        return 1.055 * x^(1/2.4) - 0.055
    end
end

-- magic oklab stuff
function lch_to_rgb(L, C, h)
    local r, g, b = oklab_to_linear_srgb(lch_to_lab(L, C, h))

    r = linear_to_srgb(r)
    g = linear_to_srgb(g)
    b = linear_to_srgb(b)

    return math.floor(r * max_value), math.floor(g * max_value), math.floor(b * max_value)
end


-- inverse converters
local function rgb_to_hsl_or_hsv(r, g, b, return_hsv)
    r = r / max_value
    g = g / max_value
    b = b / max_value

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, lv = 0, 0, (max + min) / 2

    local d = max - min
    if return_hsv then
        lv = max  -- Value for HSV
        s = max == 0 and 0 or d / max
    else
        lv = (max + min) / 2  -- Lightness for HSL
        s = max == min and 0 or (lv > 0.5 and d / (2 - max - min) or d / (max + min))
    end

    if max ~= min then
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return math.floor(h * 360), math.floor(s * 100), math.floor(lv * 100)
end

local function srgb_to_linear(c)
    if c <= 0.04045 then
        return c / 12.92
    else
        return ((c + 0.055) / 1.055) ^ 2.4
    end
end

local function rgb_to_linear_srgb(r, g, b)
    r = srgb_to_linear(r / max_value)
    g = srgb_to_linear(g / max_value)
    b = srgb_to_linear(b / max_value)
    return r, g, b
end

local function linear_srgb_to_oklab(r, g, b)
    local l = 0.4121656120 * r + 0.5362752080 * g + 0.0514575653 * b
    local m = 0.2118591070 * r + 0.6807189584 * g + 0.1074065790 * b
    local s = 0.0883097947 * r + 0.2818474174 * g + 0.6302613616 * b

    local l_ = l ^ (1 / 3)
    local m_ = m ^ (1 / 3)
    local s_ = s ^ (1 / 3)

    local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    local a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    local b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    return L, a, b
end

local function oklab_to_lch(L, a, b)
    local C = math.sqrt(a * a + b * b)
    local h = math.atan(b/a) * 180 / math.pi
    if h < 0 then h = h + 360 end
    return math.floor(L*100), math.floor(C*100), math.floor(h)
end

local function rgb_to_oklab_lch(r, g, b)
    local lr, lg, lb = rgb_to_linear_srgb(r, g, b)
    local L, a, b = linear_srgb_to_oklab(lr, lg, lb)
    return oklab_to_lch(L, a, b)
end

function convert_inverse(bars,prev_dropdown_index,new_dropdown_index)
    local r,g,b
    local x,y,z = tonumber(bars[1]),tonumber(bars[2]),tonumber(bars[3])
    if prev_dropdown_index == "1" then -- rgb
    r,g,b = x,y,z
    else if prev_dropdown_index == "2" then -- hsv
    r,g,b = hsv_to_rgb(x/360,y/100,z/100)
    else if prev_dropdown_index == "3" then -- hsl
    r,g,b = hsl_to_rgb(x/360,y/100,z/100)
    else if prev_dropdown_index == "4" then -- oklab
    r,g,b = lch_to_rgb(x/100,y/100,z/360)
    end end end end
    if new_dropdown_index == "1" -- rgb
    then return r,g,b end
    if new_dropdown_index == "4" -- oklab
    then return rgb_to_oklab_lch(r,g,b) end
    -- assume the other possiblities are hsv and hsl
    return rgb_to_hsl_or_hsv(r,g,b,new_dropdown_index=="2")
end