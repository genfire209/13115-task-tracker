"""Generates the Android status-bar notification icon: a plain white gear
silhouette on transparent background (required by Android — any color info
in a notification icon gets stripped/tinted by the OS on API 21+, so a
full-color icon renders as a broken white blob; a proper white/alpha-only
shape is the only thing that renders correctly)."""
import math
from PIL import Image, ImageDraw

MASTER_SIZE = 384
WHITE = (255, 255, 255, 255)

# (directory, px size) - standard Android notification icon density buckets.
DENSITIES = [
    ("mipmap-mdpi", 24),
    ("mipmap-hdpi", 36),
    ("mipmap-xhdpi", 48),
    ("mipmap-xxhdpi", 72),
    ("mipmap-xxxhdpi", 96),
]


def draw_gear(draw, cx, cy, inner_r, tooth_r, teeth, hub_r):
    points = []
    for i in range(teeth * 2):
        angle = math.pi * i / teeth
        r = tooth_r if i % 2 == 0 else inner_r
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=WHITE)
    draw.ellipse([cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r], fill=(0, 0, 0, 0))


def main():
    img = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = MASTER_SIZE / 2
    draw_gear(draw, cx, cy, inner_r=120, tooth_r=155, teeth=9, hub_r=58)

    for directory, size in DENSITIES:
        out_dir = f"android/app/src/main/res/{directory}"
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(f"{out_dir}/ic_stat_notification.png")
        print(f"wrote {out_dir}/ic_stat_notification.png ({size}x{size})")


if __name__ == "__main__":
    main()
