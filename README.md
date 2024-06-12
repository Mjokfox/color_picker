# Color picker for hexcol mod
Quite heavy weight color picker for [hexcol](https://gitoverit.ofafox.com/Bob/hexcol). Featuring two mapping options and four different color spaces.
## mapping
- Sliders: Adjust sliders to the exact value for the selected color space, click on the color preview to receive the item.
- 2d map: A map showing a whole range of colors in the selected color space, including a slider since evey space is 3 dimensions wide.

## color spaces
- RGB: The simple direct represenation of the color, the mapping is a little different than the other spaces, with b/g on x/y and red as slider
- HSV: Hue Saturation Value, represented in degrees, and percentage. Value being "brightness"
- HSL: same as hsv, expect lightness instead of brightness
- Oklab: actually OklcH, a space where lightness is not direct, rather perceived brightness, selecting a hue and chroma (similar to saturation) and sliding through brightness, should yield colors that look equally bright

In the top left, the mapping can be selected with the dropdown, and the top right the color space.
The 2d map is quite heavy on resources, hence sliders is the default selected option. A "rate limiter" is added with the option to modify the minimum interval between updates for the map int he mod settings.
The picker is added as an inventory item, with the option to disable, but also integrated into unified inventory as a button.
It can also be set as the default inventory from the settings (not compatible with any other inventory mod).

![screenshot](https://github.com/Mjokfox/color_picker/blob/main/Screenshot.png)
