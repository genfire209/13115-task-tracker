"""Generates the 13115 Task Tracker app icon: a mechanical gear cluster with '13115' in red."""
import math
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
BG = (14, 14, 18, 255)  # matches AppTheme.background
RED = (255, 59, 87, 255)  # matches AppTheme.primary
RED_DIM = (110, 30, 45, 255)
RED_DIMMER = (72, 22, 32, 255)
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Black.ttf"


def draw_gear(draw, cx, cy, inner_r, tooth_r, teeth, color, rotation=0.0, hub_r=None, hub_color=BG):
    points = []
    for i in range(teeth * 2):
        angle = math.pi * i / teeth + rotation
        r = tooth_r if i % 2 == 0 else inner_r
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=color)
    if hub_r:
        draw.ellipse([cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r], fill=hub_color)


def main():
    img = Image.new("RGBA", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE / 2, SIZE / 2

    # Background gear cluster: several interlocking gears of varying size,
    # some clipped by the canvas edge, for a busy mechanical-assembly feel.
    draw_gear(draw, -40, -40, inner_r=230, tooth_r=270, teeth=12, color=RED_DIMMER, rotation=0.15)
    draw_gear(draw, SIZE + 60, 120, inner_r=200, tooth_r=236, teeth=10, color=RED_DIMMER, rotation=0.3)
    draw_gear(draw, 90, SIZE + 30, inner_r=210, tooth_r=248, teeth=11, color=RED_DIMMER, rotation=0.0)
    draw_gear(draw, SIZE + 20, SIZE + 60, inner_r=190, tooth_r=224, teeth=10, color=RED_DIMMER, rotation=0.2)

    # Main gear ring behind the text, with a hub hole so the text sits on
    # the background color.
    draw_gear(draw, cx, cy, inner_r=420, tooth_r=468, teeth=18, color=RED_DIM, hub_r=420, hub_color=BG)
    draw.ellipse([cx - 420, cy - 420, cx + 420, cy + 420], outline=RED_DIM, width=16)

    # Small accent gears, fully visible, tucked at opposite corners inside
    # the frame with their own hubs so they read as real gears, not blobs.
    draw_gear(draw, 150, 860, inner_r=64, tooth_r=86, teeth=9, color=RED_DIM, hub_r=30, hub_color=BG)
    draw_gear(draw, 900, 150, inner_r=50, tooth_r=68, teeth=8, color=RED_DIM, hub_r=22, hub_color=BG)

    font = ImageFont.truetype(FONT_PATH, 230)
    text = "13115"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((cx - tw / 2 - bbox[0], cy - th / 2 - bbox[1]), text, font=font, fill=RED)

    img.convert("RGB").save("scripts/icon_master.png")
    print("wrote scripts/icon_master.png")


if __name__ == "__main__":
    main()
