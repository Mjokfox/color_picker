local max_value = 15
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