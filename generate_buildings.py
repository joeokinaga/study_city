"""Generate unique isometric building PNGs for Study City."""

from PIL import Image, ImageDraw, ImageFont
import os

OUT = "assets/buildings"
SIZE = 128  # canvas size
os.makedirs(OUT, exist_ok=True)


def iso_box(draw, cx, cy, w, h, d, top_color, left_color, right_color):
    """Draw an isometric box (cuboid) at center-x, bottom-y."""
    hw = w // 2
    hd = d // 2

    # Top face
    top = [
        (cx, cy - h),
        (cx + hw, cy - h + hd),
        (cx, cy - h + d),
        (cx - hw, cy - h + hd),
    ]
    draw.polygon(top, fill=top_color, outline=(0, 0, 0, 60))

    # Left face
    left = [
        (cx - hw, cy - h + hd),
        (cx, cy - h + d),
        (cx, cy + d - h + h),  # bottom center
        (cx - hw, cy + hd),
    ]
    # Simplify: left face
    left = [
        (cx - hw, cy - h + hd),
        (cx, cy - h + d),
        (cx, cy + d),
        (cx - hw, cy + hd),
    ]
    draw.polygon(left, fill=left_color, outline=(0, 0, 0, 60))

    # Right face
    right = [
        (cx + hw, cy - h + hd),
        (cx, cy - h + d),
        (cx, cy + d),
        (cx + hw, cy + hd),
    ]
    draw.polygon(right, fill=right_color, outline=(0, 0, 0, 60))


def draw_iso_rect(draw, cx, cy, w, h, d, colors):
    """Draw a simple isometric rectangular building."""
    hw = w // 2
    hd = d // 2
    top_c, left_c, right_c = colors

    # Top face
    top = [(cx, cy - h), (cx + hw, cy - h + hd), (cx, cy - h + d), (cx - hw, cy - h + hd)]
    draw.polygon(top, fill=top_c, outline=(0, 0, 0, 40))

    # Left face
    left = [(cx - hw, cy - h + hd), (cx, cy - h + d), (cx, cy + d), (cx - hw, cy + hd)]
    draw.polygon(left, fill=left_c, outline=(0, 0, 0, 40))

    # Right face
    right = [(cx + hw, cy - h + hd), (cx, cy - h + d), (cx, cy + d), (cx + hw, cy + hd)]
    draw.polygon(right, fill=right_c, outline=(0, 0, 0, 40))


def draw_window(draw, x, y, w, h, color=(180, 220, 255, 255)):
    """Draw a small window rectangle."""
    draw.rectangle([x, y, x + w, y + h], fill=color, outline=(100, 100, 120, 120))


def draw_triangle_roof(draw, cx, cy, w, h, roof_h, color):
    """Draw a triangular roof on top of a building."""
    hw = w // 2
    hd = h // 2
    # Isometric peaked roof
    top = [
        (cx, cy - roof_h),  # peak
        (cx + hw, cy + hd),  # right
        (cx, cy + h),  # front
        (cx - hw, cy + hd),  # left
    ]
    # Left slope
    left_slope = [(cx, cy - roof_h), (cx - hw, cy + hd), (cx, cy + h)]
    draw.polygon(left_slope, fill=color, outline=(0, 0, 0, 50))
    # Right slope
    right_slope = [(cx, cy - roof_h), (cx + hw, cy + hd), (cx, cy + h)]
    darker = tuple(max(0, c - 30) for c in color[:3]) + (color[3],)
    draw.polygon(right_slope, fill=darker, outline=(0, 0, 0, 50))


def create_building(name, draw_func):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(draw, SIZE)
    img.save(os.path.join(OUT, f"{name}.png"))
    print(f"  Created {name}.png")


# =====================================================
# Individual building designs
# =====================================================

def draw_house(draw, s):
    cx, cy = s // 2, s - 20
    # Main body - warm beige
    draw_iso_rect(draw, cx, cy, 50, 35, 20, ((220, 200, 170, 255), (190, 170, 140, 255), (170, 150, 120, 255)))
    # Roof - red/brown
    draw_triangle_roof(draw, cx, cy - 35, 54, 22, 18, (180, 70, 50, 255))
    # Door
    draw.rectangle([cx - 4, cy + 2, cx + 4, cy + 16], fill=(120, 70, 40, 255), outline=(80, 50, 30, 200))
    # Windows on left face
    draw_window(draw, cx - 22, cy - 20, 6, 6)

def draw_park(draw, s):
    cx, cy = s // 2, s - 18
    # Grass base
    base = [(cx - 30, cy), (cx, cy - 12), (cx + 30, cy), (cx, cy + 12)]
    draw.polygon(base, fill=(100, 180, 80, 255), outline=(70, 140, 60, 150))
    # Tree trunk
    draw.rectangle([cx - 3, cy - 45, cx + 3, cy - 12], fill=(120, 80, 40, 255))
    # Tree canopy (circle-ish)
    draw.ellipse([cx - 18, cy - 65, cx + 18, cy - 35], fill=(60, 160, 60, 255), outline=(40, 120, 40, 200))
    draw.ellipse([cx - 14, cy - 72, cx + 14, cy - 45], fill=(80, 190, 70, 255))
    # Bench
    draw.rectangle([cx + 10, cy - 6, cx + 25, cy - 3], fill=(140, 90, 50, 255), outline=(100, 60, 30, 200))
    draw.rectangle([cx + 12, cy - 3, cx + 14, cy + 2], fill=(100, 60, 30, 255))
    draw.rectangle([cx + 22, cy - 3, cx + 24, cy + 2], fill=(100, 60, 30, 255))

def draw_library(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - stone gray/blue
    draw_iso_rect(draw, cx, cy, 56, 45, 24, ((180, 190, 210, 255), (140, 150, 175, 255), (120, 130, 155, 255)))
    # Flat top stripe
    draw_iso_rect(draw, cx, cy - 45, 60, 4, 26, ((160, 140, 100, 255), (130, 110, 80, 255), (110, 90, 60, 255)))
    # Columns on front (left face)
    for i in range(3):
        x = cx - 26 + i * 10
        y = cy - 10 + i * 4
        draw.rectangle([x, y - 28, x + 3, y + 5], fill=(200, 200, 210, 255), outline=(150, 150, 160, 200))
    # Windows
    for i in range(2):
        draw_window(draw, cx + 8 + i * 10, cy - 30 + i * 4, 5, 8)
    # Book symbol on front
    draw.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=(180, 60, 50, 255), outline=(140, 40, 30, 200))

def draw_cafeteria(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - warm orange/yellow
    draw_iso_rect(draw, cx, cy, 52, 32, 22, ((245, 200, 120, 255), (220, 170, 90, 255), (200, 150, 70, 255)))
    # Awning - striped red/white
    awning = [(cx - 28, cy - 32 + 10), (cx, cy - 32), (cx + 28, cy - 32 + 10), (cx, cy - 32 + 20)]
    draw.polygon(awning, fill=(200, 50, 50, 255), outline=(0, 0, 0, 40))
    # Stripes on awning
    for i in range(-2, 3):
        x = cx + i * 8
        draw.line([(x, cy - 32 + abs(i) * 2 + 3), (x, cy - 32 + abs(i) * 2 + 8)], fill=(255, 255, 255, 180), width=2)
    # Table & chair dots
    draw.ellipse([cx - 15, cy + 4, cx - 7, cy + 10], fill=(160, 120, 80, 255))
    draw.ellipse([cx + 7, cy + 4, cx + 15, cy + 10], fill=(160, 120, 80, 255))
    # Door
    draw.rectangle([cx - 4, cy + 4, cx + 4, cy + 18], fill=(140, 80, 40, 255))

def draw_gym(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - steel blue
    draw_iso_rect(draw, cx, cy, 56, 38, 24, ((100, 140, 190, 255), (70, 110, 160, 255), (50, 90, 140, 255)))
    # Curved roof highlight
    draw_iso_rect(draw, cx, cy - 38, 58, 6, 25, ((120, 160, 210, 255), (90, 130, 180, 255), (70, 110, 160, 255)))
    # Windows row
    for i in range(3):
        draw_window(draw, cx + 5 + i * 10, cy - 22 + i * 4, 6, 10, (200, 230, 255, 255))
    # Dumbbell symbol
    draw.ellipse([cx - 18, cy - 15, cx - 12, cy - 9], fill=(60, 60, 60, 255))
    draw.rectangle([cx - 12, cy - 13, cx - 4, cy - 11], fill=(80, 80, 80, 255))
    draw.ellipse([cx - 6, cy - 15, cx, cy - 9], fill=(60, 60, 60, 255))

def draw_art_room(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - lavender/purple
    draw_iso_rect(draw, cx, cy, 48, 36, 20, ((210, 180, 230, 255), (180, 150, 200, 255), (160, 130, 180, 255)))
    # A-frame roof
    draw_triangle_roof(draw, cx, cy - 36, 52, 22, 20, (180, 140, 200, 255))
    # Palette symbol - colorful dots
    colors = [(220, 60, 60, 255), (60, 60, 220, 255), (60, 200, 60, 255), (240, 200, 40, 255)]
    for i, c in enumerate(colors):
        draw.ellipse([cx - 18 + i * 9, cy - 8, cx - 12 + i * 9, cy - 2], fill=c)
    # Skylight window
    draw_window(draw, cx + 10, cy - 25, 8, 12, (220, 240, 255, 255))

def draw_science_lab(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - white/light gray
    draw_iso_rect(draw, cx, cy, 54, 40, 22, ((230, 240, 240, 255), (200, 210, 210, 255), (180, 190, 190, 255)))
    # Flat modern roof
    draw_iso_rect(draw, cx, cy - 40, 56, 3, 23, ((180, 200, 200, 255), (150, 170, 170, 255), (130, 150, 150, 255)))
    # Flask/beaker symbol
    draw.polygon([(cx - 6, cy - 20), (cx + 6, cy - 20), (cx + 10, cy - 6), (cx - 10, cy - 6)],
                 fill=(200, 240, 200, 200), outline=(100, 160, 100, 255))
    draw.rectangle([cx - 4, cy - 26, cx + 4, cy - 20], fill=(200, 200, 200, 255), outline=(150, 150, 150, 255))
    # Liquid inside
    draw.polygon([(cx - 8, cy - 10), (cx + 8, cy - 10), (cx + 10, cy - 6), (cx - 10, cy - 6)],
                 fill=(100, 220, 150, 220))
    # Windows
    for i in range(2):
        draw_window(draw, cx + 12 + i * 8, cy - 28 + i * 4, 5, 8)

def draw_fountain(draw, s):
    cx, cy = s // 2, s - 16
    # Base pool - ellipse
    draw.ellipse([cx - 28, cy - 6, cx + 28, cy + 12], fill=(120, 180, 220, 255), outline=(80, 140, 180, 200))
    draw.ellipse([cx - 24, cy - 3, cx + 24, cy + 9], fill=(150, 200, 240, 255))
    # Center pillar
    draw.rectangle([cx - 4, cy - 35, cx + 4, cy - 2], fill=(190, 190, 200, 255), outline=(150, 150, 160, 200))
    # Top basin
    draw.ellipse([cx - 14, cy - 38, cx + 14, cy - 28], fill=(200, 200, 210, 255), outline=(160, 160, 170, 200))
    # Water spray lines
    draw.line([(cx, cy - 38), (cx - 8, cy - 52)], fill=(140, 200, 255, 200), width=2)
    draw.line([(cx, cy - 38), (cx, cy - 55)], fill=(140, 200, 255, 200), width=2)
    draw.line([(cx, cy - 38), (cx + 8, cy - 52)], fill=(140, 200, 255, 200), width=2)
    # Droplets
    for dx, dy in [(-10, -48), (10, -48), (0, -53), (-6, -45), (6, -45)]:
        draw.ellipse([cx + dx - 2, cy + dy - 2, cx + dx + 2, cy + dy + 2], fill=(180, 220, 255, 220))

def draw_music_room(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - deep teal/green
    draw_iso_rect(draw, cx, cy, 48, 34, 20, ((80, 170, 160, 255), (60, 140, 130, 255), (40, 120, 110, 255)))
    # Wavy roof
    draw_triangle_roof(draw, cx, cy - 34, 52, 22, 22, (70, 150, 140, 255))
    # Musical note symbol
    draw.ellipse([cx - 8, cy - 8, cx - 2, cy - 2], fill=(40, 40, 40, 255))
    draw.rectangle([cx - 2, cy - 22, cx, cy - 4], fill=(40, 40, 40, 255))
    draw.line([(cx, cy - 22), (cx + 6, cy - 18)], fill=(40, 40, 40, 255), width=2)
    draw.ellipse([cx + 2, cy - 16, cx + 8, cy - 10], fill=(40, 40, 40, 255))
    # Windows
    draw_window(draw, cx + 12, cy - 22, 6, 8, (200, 230, 220, 255))

def draw_bookstore(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - warm brown
    draw_iso_rect(draw, cx, cy, 48, 36, 20, ((180, 140, 100, 255), (150, 110, 70, 255), (130, 90, 50, 255)))
    # Flat roof with sign board
    draw_iso_rect(draw, cx, cy - 36, 50, 4, 21, ((160, 120, 80, 255), (130, 90, 50, 255), (110, 70, 30, 255)))
    # Book shapes on left face
    book_colors = [(200, 60, 60, 255), (60, 120, 200, 255), (60, 180, 60, 255), (200, 180, 40, 255)]
    for i, c in enumerate(book_colors):
        draw.rectangle([cx - 22 + i * 5, cy - 18, cx - 18 + i * 5, cy - 4], fill=c, outline=(0, 0, 0, 60))
    # Awning
    awning = [(cx - 24, cy - 6), (cx, cy - 14), (cx + 24, cy - 6), (cx, cy + 2)]
    draw.polygon(awning, fill=(160, 50, 40, 230), outline=(0, 0, 0, 40))
    # Door
    draw.rectangle([cx - 4, cy + 4, cx + 4, cy + 16], fill=(100, 60, 30, 255), outline=(70, 40, 20, 200))

def draw_hospital(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - white with light blue tint
    draw_iso_rect(draw, cx, cy, 52, 42, 22, ((240, 245, 250, 255), (210, 220, 230, 255), (190, 200, 210, 255)))
    # Flat roof
    draw_iso_rect(draw, cx, cy - 42, 54, 3, 23, ((200, 210, 220, 255), (170, 180, 190, 255), (150, 160, 170, 255)))
    # Red cross
    draw.rectangle([cx - 3, cy - 32, cx + 3, cy - 18], fill=(220, 50, 50, 255))
    draw.rectangle([cx - 9, cy - 28, cx + 9, cy - 22], fill=(220, 50, 50, 255))
    # Windows grid
    for row in range(2):
        for col in range(2):
            draw_window(draw, cx + 8 + col * 8, cy - 30 + row * 12 + col * 3, 5, 6, (200, 230, 255, 255))
    # Door with cross
    draw.rectangle([cx - 5, cy + 4, cx + 5, cy + 18], fill=(200, 210, 220, 255), outline=(150, 160, 170, 200))

def draw_computer_lab(draw, s):
    cx, cy = s // 2, s - 18
    # Main body - dark gray/charcoal modern
    draw_iso_rect(draw, cx, cy, 54, 38, 22, ((80, 90, 100, 255), (60, 70, 80, 255), (45, 55, 65, 255)))
    # Glass front - bright blue windows
    draw_window(draw, cx + 4, cy - 28, 18, 20, (60, 140, 220, 230))
    # Antenna/satellite
    draw.rectangle([cx + 18, cy - 52, cx + 20, cy - 38], fill=(120, 120, 130, 255))
    draw.ellipse([cx + 14, cy - 56, cx + 24, cy - 50], fill=(140, 140, 150, 255), outline=(100, 100, 110, 200))
    # Monitor symbol on front
    draw.rectangle([cx - 12, cy - 16, cx - 2, cy - 8], fill=(40, 180, 220, 255), outline=(30, 30, 40, 200))
    draw.rectangle([cx - 9, cy - 8, cx - 5, cy - 5], fill=(80, 80, 90, 255))
    # LED strip on top
    draw_iso_rect(draw, cx, cy - 38, 56, 2, 23, ((60, 180, 220, 255), (40, 150, 190, 255), (30, 130, 170, 255)))

def draw_shrine(draw, s):
    cx, cy = s // 2, s - 16
    # Steps/platform
    draw_iso_rect(draw, cx, cy, 50, 6, 22, ((200, 180, 160, 255), (170, 150, 130, 255), (150, 130, 110, 255)))
    # Main body - deep red wood
    draw_iso_rect(draw, cx, cy - 6, 40, 30, 18, ((180, 60, 50, 255), (150, 40, 30, 255), (130, 30, 20, 255)))
    # Roof tiers (pagoda style)
    # Lower roof
    roof1 = [(cx - 28, cy - 36 + 8), (cx, cy - 36 - 2), (cx + 28, cy - 36 + 8), (cx, cy - 36 + 18)]
    draw.polygon(roof1, fill=(60, 60, 70, 255), outline=(0, 0, 0, 60))
    # Upper roof
    draw_iso_rect(draw, cx, cy - 42, 24, 12, 10, ((180, 50, 40, 255), (150, 35, 25, 255), (130, 25, 15, 255)))
    roof2 = [(cx - 18, cy - 54 + 4), (cx, cy - 54 - 2), (cx + 18, cy - 54 + 4), (cx, cy - 54 + 10)]
    draw.polygon(roof2, fill=(50, 50, 60, 255), outline=(0, 0, 0, 60))
    # Torii gate essence - pillars
    draw.rectangle([cx - 14, cy - 2, cx - 11, cy + 12], fill=(200, 60, 40, 255))
    draw.rectangle([cx + 11, cy - 2, cx + 14, cy + 12], fill=(200, 60, 40, 255))

def draw_clock_tower(draw, s):
    cx, cy = s // 2, s - 16
    # Base platform
    draw_iso_rect(draw, cx, cy, 40, 8, 18, ((180, 170, 160, 255), (150, 140, 130, 255), (130, 120, 110, 255)))
    # Tower body - tall and narrow, brick
    draw_iso_rect(draw, cx, cy - 8, 28, 55, 12, ((190, 160, 130, 255), (160, 130, 100, 255), (140, 110, 80, 255)))
    # Clock face
    draw.ellipse([cx - 8, cy - 52, cx + 8, cy - 36], fill=(240, 240, 230, 255), outline=(100, 90, 80, 200))
    # Clock hands
    draw.line([(cx, cy - 44), (cx, cy - 50)], fill=(40, 40, 40, 255), width=2)  # minute
    draw.line([(cx, cy - 44), (cx + 4, cy - 41)], fill=(40, 40, 40, 255), width=2)  # hour
    # Pointed roof
    draw.polygon([(cx, cy - 75), (cx - 16, cy - 63 + 5), (cx, cy - 63 + 10), (cx + 16, cy - 63 + 5)],
                 fill=(120, 80, 50, 255), outline=(0, 0, 0, 50))
    # Bell shape hint
    draw.arc([cx - 5, cy - 30, cx + 5, cy - 22], 0, 180, fill=(200, 180, 50, 255), width=2)

def draw_stadium(draw, s):
    cx, cy = s // 2, s - 14
    # Base elliptical shape
    draw.ellipse([cx - 38, cy - 8, cx + 38, cy + 12], fill=(180, 180, 190, 255), outline=(120, 120, 130, 200))
    # Inner field (green)
    draw.ellipse([cx - 28, cy - 2, cx + 28, cy + 8], fill=(90, 180, 90, 255))
    # Walls - left
    draw.polygon([(cx - 38, cy), (cx - 38, cy - 30), (cx - 10, cy - 38), (cx - 10, cy - 6)],
                 fill=(160, 160, 175, 255), outline=(120, 120, 130, 150))
    # Walls - right
    draw.polygon([(cx + 38, cy), (cx + 38, cy - 30), (cx + 10, cy - 38), (cx + 10, cy - 6)],
                 fill=(140, 140, 155, 255), outline=(120, 120, 130, 150))
    # Back wall
    draw.polygon([(cx - 10, cy - 38), (cx, cy - 42), (cx + 10, cy - 38), (cx, cy - 10)],
                 fill=(150, 150, 165, 255), outline=(120, 120, 130, 150))
    # Seating rows (colored lines)
    for i in range(4):
        y_off = cy - 15 - i * 5
        draw.line([(cx - 34 + i * 4, y_off), (cx - 14 + i * 2, y_off - 3)], fill=(200, 80, 80, 200), width=2)
        draw.line([(cx + 34 - i * 4, y_off), (cx + 14 - i * 2, y_off - 3)], fill=(80, 80, 200, 200), width=2)
    # Floodlight poles
    draw.rectangle([cx - 36, cy - 45, cx - 34, cy - 28], fill=(100, 100, 110, 255))
    draw.ellipse([cx - 39, cy - 48, cx - 31, cy - 44], fill=(255, 255, 200, 255))
    draw.rectangle([cx + 34, cy - 45, cx + 36, cy - 28], fill=(100, 100, 110, 255))
    draw.ellipse([cx + 31, cy - 48, cx + 39, cy - 44], fill=(255, 255, 200, 255))


# Generate all buildings
buildings = {
    "house": draw_house,
    "park": draw_park,
    "library": draw_library,
    "cafeteria": draw_cafeteria,
    "gym": draw_gym,
    "art_room": draw_art_room,
    "science_lab": draw_science_lab,
    "fountain": draw_fountain,
    "music_room": draw_music_room,
    "bookstore": draw_bookstore,
    "hospital": draw_hospital,
    "computer_lab": draw_computer_lab,
    "shrine": draw_shrine,
    "clock_tower": draw_clock_tower,
    "stadium": draw_stadium,
}

print(f"Generating {len(buildings)} building images...")
for name, func in buildings.items():
    create_building(name, func)
print("Done!")
