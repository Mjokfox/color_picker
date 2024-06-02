# This python script is used to generate the cspace.png file which is used as the item texture and button texture.

from PIL import Image, ImageDraw
import colorsys

width = 64
height = 64

image = Image.new("RGB", (width, height), "white")
draw = ImageDraw.Draw(image)

for x in range(width):
    for y in range(height):
        hue = x / width
        lightness = y / height
        saturation = 1.0 

        r, g, b = colorsys.hls_to_rgb(hue, lightness, saturation)

        r = int(r * 255)
        g = int(g * 255)
        b = int(b * 255)

        draw.point((x, height-y), (r, g, b))

image.save("cspace.png")

print("Done")