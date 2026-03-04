"""Generate crisp isometric building PNGs for Study City.

Renders directly at target resolution (no supersampling) for clean pixel
edges.  The isometric diamond footprint aligns with the bottom half of
the square canvas; building bodies extend upward into the top half.

Flutter alignment
─────────────────
In a S×S PNG the diamond vertices are:
  top  (back)  = (S/2, S/2)
  right        = (S,   3S/4)
  bottom (front)= (S/2, S)
  left         = (0,   3S/4)

The Flutter renderer displays the image at  scaledSize = 64 * footprintFactor
* levelScale  pixels, positioned so the image bottom edge sits on the
diamond's bottom vertex.  A 128 px PNG is shown at ~64 px (2× Retina).

Canvas sizes (2× Retina)
────────────────────────
  1×1           →  128 px
  1×2  /  2×1   →  192 px
  2×2           →  256 px
  3×3           →  384 px
"""

from PIL import Image, ImageDraw
import os

OUT = "assets/buildings"
os.makedirs(OUT, exist_ok=True)

# ─── outline constant ────────────────────────────────────────────────
OL = (0, 0, 0, 45)

# ─── colour helpers ──────────────────────────────────────────────────

def dk(c, a=30):
    """Darken a colour."""
    return (max(0, c[0]-a), max(0, c[1]-a), max(0, c[2]-a),
            c[3] if len(c) > 3 else 255)

def lt(c, a=30):
    """Lighten a colour."""
    return (min(255, c[0]+a), min(255, c[1]+a), min(255, c[2]+a),
            c[3] if len(c) > 3 else 255)

# ─── isometric drawing primitives ────────────────────────────────────

def box(draw, cx, fy, hw, hd, h, tc, lc, rc, ol=OL):
    """Draw an isometric box.

    cx, fy : front-bottom vertex (closest to viewer, at image bottom)
    hw     : half-width  (screen X)
    hd     : half-depth  (screen Y, should be hw//2 for 2:1 iso)
    h      : height      (pixels upward)
    tc/lc/rc : top / left / right face colours
    """
    gf = (cx, fy);          gl = (cx-hw, fy-hd)
    gb = (cx, fy-2*hd);     gr = (cx+hw, fy-hd)
    tf = (cx, fy-h);        tl = (cx-hw, fy-hd-h)
    tb = (cx, fy-2*hd-h);   tr = (cx+hw, fy-hd-h)
    draw.polygon([tb, tr, tf, tl], fill=tc, outline=ol)   # top
    draw.polygon([gl, gf, tf, tl], fill=lc, outline=ol)   # left
    draw.polygon([gr, gf, tf, tr], fill=rc, outline=ol)   # right


def boxc(draw, cx, fy, hw, hd, h, c, ol=OL):
    """iso box with automatic 3-face shading from a base colour."""
    box(draw, cx, fy, hw, hd, h, lt(c, 25), dk(c, 10), dk(c, 35), ol)


def roof(draw, cx, by, hw, hd, ph, c):
    """Triangular isometric roof.

    by : Y of the *back-top* vertex of the underlying box
         (= fy - 2*hd - h for the box below).
    The roof front edge sits at by+2*hd (= front-top of box).
    """
    draw.polygon([(cx, by-ph), (cx-hw, by+hd), (cx, by+2*hd)],
                 fill=c, outline=OL)
    draw.polygon([(cx, by-ph), (cx+hw, by+hd), (cx, by+2*hd)],
                 fill=dk(c, 25), outline=OL)


def win(draw, x, y, w, h, c=(180, 220, 255, 255)):
    """Small window rectangle."""
    draw.rectangle([x, y, x+w, y+h], fill=c, outline=dk(c, 55))


# ─── canvas-size calculation ─────────────────────────────────────────

def _sz(tr, tc):
    """Final PNG side length for tile footprint (tr × tc)."""
    return int(128 * (tr + tc) / 2.0)


def create(name, tr, tc, fn):
    s = _sz(tr, tc)
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fn(d, s)
    path = os.path.join(OUT, f"{name}.png")
    img.save(path)
    px = img.load()
    filled = sum(1 for y in range(s) for x in range(s) if px[x, y][3] > 10)
    pct = filled / (s * s) * 100
    print(f"  ✓ {name}.png  {s}×{s}  fill {pct:.1f}%")


# =====================================================================
# 1×1  BUILDINGS  (128 px canvas)
# =====================================================================
# Convention for 1×1 buildings:
#   cx = S//2,  fy = S - S//20  (tiny margin at bottom)
#   hw ≈ 0.40*S,  hd = hw//2,  h ≈ 0.32-0.38*S
#   Target fill: 50-65 %

def draw_house(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.40); hd = hw//2; h = int(S*0.34)
    # Walls
    boxc(d, cx, fy, hw, hd, h, (215, 195, 160, 255))
    # Pitched roof
    by = fy - 2*hd - h
    roof(d, cx, by, int(hw*1.12), int(hd*1.12), int(h*0.60), (180, 70, 50, 255))
    # Chimney
    chw = max(2, hw//7); chd = max(1, hd//7)
    boxc(d, cx + hw//3, by + hd//2, chw, chd, int(h*0.40), (150, 110, 85, 255))
    # Door (on front / left face)
    dw = max(3, hw//4); dh = int(h*0.38)
    dx = cx - hw//3; dy = fy - hd//3 - dh
    d.rectangle([dx, dy, dx+dw, dy+dh], fill=(130, 78, 42, 255), outline=(95, 55, 30))
    # Windows
    ww = max(3, hw//4); wh = int(h*0.22)
    win(d, cx - int(hw*0.72), fy - int(hd*0.72) - int(h*0.58), ww, wh)
    win(d, cx + int(hw*0.28), fy - int(hd*0.28) - int(h*0.58), ww, wh)


def draw_cafeteria(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.40); hd = hw//2; h = int(S*0.30)
    # Walls
    boxc(d, cx, fy, hw, hd, h, (245, 208, 130, 255))
    # Flat roof
    boxc(d, cx, fy - 2*hd - h, int(hw*1.06), int(hd*1.06), max(2, S//30),
         (225, 188, 105, 255))
    # Red awning (two parallelogram halves)
    ay = fy - h + int(h*0.22)   # awning Y on front face
    adrop = max(3, S//22)
    # Left half of awning
    d.polygon([(cx-hw, ay-hd), (cx, ay), (cx, ay+adrop), (cx-hw, ay-hd+adrop)],
              fill=(205, 55, 55, 255), outline=OL)
    # Right half
    d.polygon([(cx+hw, ay-hd), (cx, ay), (cx, ay+adrop), (cx+hw, ay-hd+adrop)],
              fill=(180, 45, 45, 255), outline=OL)
    # Stripes on awning
    sw = max(1, S//50)
    for i in range(3):
        sx = cx - hw//2 + i * hw//2
        sy = ay - hd//2 + i * hd//4
        d.line([(sx, sy), (sx, sy + adrop)], fill=(255, 255, 255, 160), width=sw)
    # Door
    dw = max(3, hw//4); dh = int(h*0.34)
    dx = cx - dw//2; dy = fy - hd//5 - dh
    d.rectangle([dx, dy, dx+dw, dy+dh], fill=(140, 85, 42, 255), outline=(100, 55, 25))
    # Window on right face
    ww = max(3, hw//3); wh = int(h*0.22)
    win(d, cx + int(hw*0.28), fy - int(hd*0.30) - int(h*0.55), ww, wh)


def draw_art_room(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.40); hd = hw//2; h = int(S*0.32)
    # Walls — lavender
    boxc(d, cx, fy, hw, hd, h, (212, 185, 232, 255))
    # Pitched roof
    by = fy - 2*hd - h
    roof(d, cx, by, int(hw*1.10), int(hd*1.10), int(h*0.50), (188, 155, 215, 255))
    # Large skylight (right face)
    ww = max(4, hw//3); wh = int(h*0.30)
    win(d, cx + int(hw*0.22), fy - int(hd*0.35) - int(h*0.60), ww, wh,
        (228, 240, 255, 255))
    # Palette circles on left face
    pr = max(2, S//32)
    cols = [(230, 68, 68, 255), (68, 68, 230, 255),
            (68, 200, 68, 255), (248, 215, 48, 255)]
    for i, c in enumerate(cols):
        px_ = cx - int(hw*0.68) + i * int(hw*0.32)
        py_ = fy - int(hd*0.50) - int(h*0.30) + i * int(hd*0.08)
        d.ellipse([px_-pr, py_-pr, px_+pr, py_+pr], fill=c)
    # Paintbrush accent
    bx = cx - int(hw*0.15); b_top = fy - hd - int(h*0.85)
    bw = max(1, S//55)
    d.line([(bx, b_top), (bx + hw//4, b_top + int(h*0.35))],
           fill=(110, 80, 50, 255), width=bw)


def draw_fountain(d, S):
    cx = S//2; fy = S - S//18
    hw = int(S*0.44); hd = hw//2
    # Circular base pool (isometric ellipse)
    pool_cy = fy - hd
    d.ellipse([cx-hw, pool_cy-hd, cx+hw, pool_cy+hd],
              fill=(115, 175, 225, 255), outline=(82, 142, 188))
    d.ellipse([cx - int(hw*0.78), pool_cy - int(hd*0.70),
               cx + int(hw*0.78), pool_cy + int(hd*0.70)],
              fill=(152, 205, 245, 255))
    # Central pillar
    pw = max(3, hw//5); pd = pw//2; ph = int(S*0.34)
    boxc(d, cx, pool_cy, pw, pd, ph, (198, 198, 210, 255))
    # Upper basin
    bw = max(5, hw//2); bh = bw//2
    basin_y = pool_cy - ph
    d.ellipse([cx-bw, basin_y-bh, cx+bw, basin_y+bh],
              fill=(208, 208, 218, 255), outline=(168, 168, 178))
    # Water jets (3 vertical lines)
    jh = int(S*0.14)
    jw = max(1, S//55)
    for dx in [-pw, 0, pw]:
        d.line([(cx+dx, basin_y - bh//2), (cx+dx, basin_y - bh//2 - jh)],
               fill=(140, 200, 255, 210), width=jw)
    # Droplets at top
    dr = max(1, S//48)
    for ddx, ddy in [(-pw*2, -jh+dr), (pw*2, -jh+dr), (0, -jh-dr*3)]:
        d.ellipse([cx+ddx-dr, basin_y-bh//2+ddy-dr,
                   cx+ddx+dr, basin_y-bh//2+ddy+dr],
                  fill=(185, 225, 255, 220))


def draw_music_room(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.40); hd = hw//2; h = int(S*0.32)
    # Walls — teal
    boxc(d, cx, fy, hw, hd, h, (82, 175, 162, 255))
    # Pitched roof
    by = fy - 2*hd - h
    roof(d, cx, by, int(hw*1.12), int(hd*1.12), int(h*0.55), (72, 155, 142, 255))
    # Musical note on left face
    nr = max(3, S//28)
    nx = cx - int(hw*0.38)
    ny = fy - int(hd*0.45) - int(h*0.32)
    d.ellipse([nx-nr, ny-nr, nx+nr, ny+nr], fill=(42, 42, 42, 255))
    stem_w = max(1, S//55)
    d.rectangle([nx+nr-stem_w, ny - int(h*0.38), nx+nr, ny],
                fill=(42, 42, 42, 255))
    # Flag on stem
    fx = nx + nr
    ft = ny - int(h*0.38)
    d.polygon([(fx, ft), (fx + nr, ft + nr//2), (fx, ft + nr)],
              fill=(42, 42, 42, 255))
    # Window on right face
    ww = max(4, hw//3); wh = int(h*0.24)
    win(d, cx + int(hw*0.22), fy - int(hd*0.35) - int(h*0.58), ww, wh,
        (205, 235, 225, 255))


def draw_bookstore(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.40); hd = hw//2; h = int(S*0.32)
    # Walls — warm brown
    boxc(d, cx, fy, hw, hd, h, (185, 145, 105, 255))
    # Flat roof with parapet
    boxc(d, cx, fy - 2*hd - h, int(hw*1.06), int(hd*1.06), max(2, S//28),
         (168, 128, 88, 255))
    # Awning over front
    ay = fy - int(h*0.42)
    d.polygon([(cx - hw, ay - hd), (cx, ay - 2*hd),
               (cx + hw, ay - hd), (cx, ay)],
              fill=(168, 52, 42, 240), outline=OL)
    # Book spines on left face (colourful vertical rectangles)
    bcs = [(208, 62, 62, 255), (62, 125, 208, 255),
           (62, 185, 62, 255), (208, 185, 42, 255)]
    bw = max(2, hw//6); bh = int(h*0.24)
    for i, c in enumerate(bcs):
        bx = cx - int(hw*0.82) + i * int(hw*0.32)
        b_y = fy - int(hd*0.60) - int(h*0.52) + i * int(hd*0.08)
        d.rectangle([bx, b_y, bx+bw, b_y+bh], fill=c, outline=(0, 0, 0, 55))
    # Door
    dw = max(3, hw//4); dh = int(h*0.32)
    dx = cx - dw//2; dy = fy - hd//5 - dh
    d.rectangle([dx, dy, dx+dw, dy+dh], fill=(108, 68, 35, 255),
                outline=(78, 48, 22))


def draw_clock_tower(d, S):
    cx = S//2; fy = S - S//18
    # Wide base platform
    bhw = int(S*0.38); bhd = bhw//2
    boxc(d, cx, fy, bhw, bhd, int(S*0.08), (188, 178, 165, 255))
    base_top = int(S*0.08)
    # Tower body (wider than before)
    thw = int(S*0.26); thd = thw//2; th = int(S*0.45)
    boxc(d, cx, fy - base_top, thw, thd, th, (198, 168, 138, 255))
    tower_back_top = fy - base_top - 2*thd - th
    # Clock face
    cr = int(S*0.10)
    cf_y = fy - base_top - thd - int(th*0.72)
    d.ellipse([cx-cr, cf_y-cr, cx+cr, cf_y+cr],
              fill=(248, 248, 238, 255), outline=(108, 98, 88))
    # Clock hands
    clw = max(1, S//45)
    d.line([(cx, cf_y), (cx, cf_y - cr + clw)], fill=(42, 42, 42), width=clw)
    d.line([(cx, cf_y), (cx + cr//2, cf_y + cr//4)], fill=(42, 42, 42), width=clw)
    # Pointed spire
    sp_hw = int(thw*1.18); sp_hd = int(thd*1.18)
    sp_ph = int(S*0.18)
    roof(d, cx, tower_back_top, sp_hw, sp_hd, sp_ph, (128, 88, 55, 255))
    # Bell opening (arch on front face)
    bell_y = fy - base_top - thd//2 - int(th*0.28)
    bell_r = max(3, thw//3)
    d.arc([cx - bell_r, bell_y - bell_r, cx + bell_r, bell_y + bell_r],
          180, 360, fill=(205, 185, 55, 255), width=max(1, S//42))
    # Windows on left and right faces
    ww = max(3, thw//3); wh = int(th*0.12)
    # Right face window
    win(d, cx + int(thw*0.18), fy - base_top - int(thd*0.28) - int(th*0.48), ww, wh)
    # Left face window
    win(d, cx - int(thw*0.72), fy - base_top - int(thd*0.72) - int(th*0.48), ww, wh)


# =====================================================================
# 1×2  /  2×1  BUILDINGS  (192 px canvas)
# =====================================================================
# These buildings are wider/deeper.  hw ≈ 0.42*S.

def draw_library(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.42); hd = hw//2; h = int(S*0.34)
    # Main body — classical stone
    boxc(d, cx, fy, hw, hd, h, (188, 198, 218, 255))
    # Frieze / pediment base
    by = fy - 2*hd - h
    boxc(d, cx, by + 2*hd, int(hw*1.06), int(hd*1.06), max(2, S//28),
         (168, 148, 108, 255))
    # Triangular pediment (gable)
    roof(d, cx, by, int(hw*1.06), int(hd*1.06), int(h*0.38),
         (178, 158, 118, 255))
    # Columns on left face (4 columns)
    for i in range(4):
        u = (i + 0.5) / 4
        col_x = int(cx - hw + u * hw)
        col_fy = int(fy - hd + u * hd)
        cw = max(2, hw//14)
        boxc(d, col_x, col_fy, cw, cw//2, int(h*0.88), (208, 208, 218, 255))
    # Windows on right face (3 tall windows)
    ww = max(3, hw//6); wh = int(h*0.28)
    for i in range(3):
        u = (i + 0.5) / 3
        wx = int(cx + u * hw)
        wy = int(fy - u * hd - int(h*0.60))
        win(d, wx, wy, ww, wh)
    # Book emblem on front
    ew = max(3, hw//5); eh = max(2, int(h*0.10))
    d.rectangle([cx - ew//2, fy - hd//5 - eh, cx + ew//2, fy - hd//5],
                fill=(185, 62, 52, 255), outline=(145, 42, 32))


def draw_gym(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.42); hd = hw//2; h = int(S*0.34)
    # Main body — sport blue
    boxc(d, cx, fy, hw, hd, h, (108, 148, 198, 255))
    # Rounded roof (flat box)
    by = fy - 2*hd - h
    boxc(d, cx, by + 2*hd, int(hw*1.08), int(hd*1.08), max(2, S//22),
         (128, 168, 218, 255))
    # Windows on right face (3 tall windows)
    ww = max(3, hw//6); wh = int(h*0.32)
    for i in range(3):
        u = (i + 0.5) / 3
        wx = int(cx + u * hw)
        wy = int(fy - u * hd - int(h*0.58))
        win(d, wx, wy, ww, wh, (208, 235, 255, 255))
    # Dumbbell icon on left face
    r = max(3, S//30)
    bar_x = cx - int(hw*0.48)
    bar_y = fy - int(hd*0.52) - int(h*0.35)
    d.ellipse([bar_x-r, bar_y-r, bar_x+r, bar_y+r], fill=(62, 62, 62, 255))
    bar_len = int(hw*0.30)
    bar_h = max(1, r//2)
    d.rectangle([bar_x+r, bar_y-bar_h, bar_x+r+bar_len, bar_y+bar_h],
                fill=(82, 82, 82, 255))
    d.ellipse([bar_x+r+bar_len-r, bar_y-r, bar_x+r+bar_len+r, bar_y+r],
              fill=(62, 62, 62, 255))
    # Entrance
    dw = max(4, hw//4); dh = int(h*0.28)
    dx = cx - dw//2; dy = fy - hd//5 - dh
    d.rectangle([dx, dy, dx+dw, dy+dh], fill=(85, 128, 175, 255),
                outline=(62, 98, 148))


def draw_science_lab(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.42); hd = hw//2; h = int(S*0.34)
    # Main body — clean white
    boxc(d, cx, fy, hw, hd, h, (238, 248, 248, 255))
    # Flat roof
    boxc(d, cx, fy - 2*hd - h, int(hw*1.06), int(hd*1.06), max(2, S//28),
         (188, 208, 208, 255))
    # Large glass panels on right face
    ww = max(4, hw//5); wh = int(h*0.38)
    for i in range(3):
        u = (i + 0.5) / 3
        wx = int(cx + u * hw)
        wy = int(fy - u * hd - int(h*0.62))
        win(d, wx, wy, ww, wh, (208, 238, 255, 242))
    # Flask symbol on left face
    fx = cx - int(hw*0.42)
    f_base_y = fy - int(hd*0.52) - int(h*0.28)
    fw = max(4, hw//7); fh = int(h*0.22)
    # Flask body (trapezoid)
    d.polygon([(fx - fw//4, f_base_y - fh), (fx + fw//4, f_base_y - fh),
               (fx + fw//2, f_base_y),      (fx - fw//2, f_base_y)],
              fill=(208, 248, 208, 200), outline=(108, 168, 108))
    # Flask neck
    nw = max(1, fw//3)
    d.rectangle([fx - nw//2, f_base_y - fh - fh//3, fx + nw//2, f_base_y - fh],
                fill=(208, 208, 208, 255), outline=(158, 158, 158))
    # Green liquid
    lh = fh // 2
    d.polygon([(fx - fw//3, f_base_y - lh), (fx + fw//3, f_base_y - lh),
               (fx + fw//2, f_base_y),      (fx - fw//2, f_base_y)],
              fill=(108, 228, 158, 220))


def draw_computer_lab(d, S):
    cx = S//2; fy = S - S//20
    hw = int(S*0.42); hd = hw//2; h = int(S*0.32)
    # Main body — dark modern
    boxc(d, cx, fy, hw, hd, h, (82, 92, 108, 255))
    # LED strip on roof edge — bright cyan
    boxc(d, cx, fy - 2*hd - h, int(hw*1.06), int(hd*1.06), max(2, S//24),
         (62, 188, 228, 255))
    # Large glass panel on right face
    gw = int(hw*0.65); gh = int(h*0.42)
    gx = cx + int(hw*0.22); gy = fy - int(hd*0.32) - int(h*0.58)
    win(d, gx, gy, gw, gh, (62, 148, 228, 232))
    # Antenna
    aw = max(1, S//55)
    ax = cx + int(hw*0.82)
    a_top_y = fy - 2*hd - h - int(S*0.08)
    d.rectangle([ax - aw//2, a_top_y, ax + aw//2, fy - 2*hd - h],
                fill=(128, 128, 138, 255))
    ar = max(2, S//38)
    d.ellipse([ax-ar, a_top_y - ar//2, ax+ar, a_top_y + ar//2],
              fill=(148, 148, 158, 255))
    # Monitor icons on left face (2 screens)
    for i in range(2):
        mx = cx - int(hw*0.72) + i * int(hw*0.38)
        my = fy - int(hd*0.55) - int(h*0.45) + i * int(hd*0.10)
        mw = max(4, int(hw*0.25)); mh = max(3, int(h*0.15))
        d.rectangle([mx, my, mx+mw, my+mh],
                    fill=(42, 188, 228, 255), outline=(32, 32, 42))
        # Monitor stand
        sw = max(1, mw//3)
        d.rectangle([mx + mw//2 - sw//2, my+mh, mx + mw//2 + sw//2, my+mh+mh//3],
                    fill=(82, 82, 92, 255))


# =====================================================================
# 2×2  BUILDINGS  (256 px canvas)
# =====================================================================

def draw_park(d, S):
    cx = S//2; fy = S - S//18
    hw = int(S*0.44); hd = hw//2
    # Grass diamond (full footprint)
    d.polygon([(cx, fy - 2*hd), (cx + hw, fy - hd),
               (cx, fy),        (cx - hw, fy - hd)],
              fill=(108, 188, 82, 255), outline=(78, 148, 62, 160))
    # Lighter inner grass
    ihw = int(hw*0.82); ihd = ihw//2
    ioff = int(hd*0.18)
    d.polygon([(cx, fy - 2*ihd - ioff), (cx + ihw, fy - ihd - ioff),
               (cx, fy - ioff),         (cx - ihw, fy - ihd - ioff)],
              fill=(122, 198, 95, 255))
    # Winding path
    pw = max(2, S//35)
    d.line([(cx - int(hw*0.45), fy - int(hd*0.55)),
            (cx, fy - hd),
            (cx + int(hw*0.45), fy - int(hd*1.45))],
           fill=(208, 198, 178, 200), width=pw)
    # ─── Hedge border (thick green outline along diamond edges) ───
    hedge_w = max(2, S//30)
    hedge_c = (55, 135, 55, 200)
    d.line([(cx, fy - 2*hd), (cx + hw, fy - hd)],
           fill=hedge_c, width=hedge_w)
    d.line([(cx + hw, fy - hd), (cx, fy)],
           fill=hedge_c, width=hedge_w)
    d.line([(cx, fy), (cx - hw, fy - hd)],
           fill=hedge_c, width=hedge_w)
    d.line([(cx - hw, fy - hd), (cx, fy - 2*hd)],
           fill=hedge_c, width=hedge_w)
    # ─── Large tree (left-back area) ───
    trunk_w = max(3, S//32)
    tx = cx - int(hw*0.35); ty = fy - int(hd*1.0)
    trunk_h = int(S*0.25)
    d.rectangle([tx - trunk_w//2, ty - trunk_h, tx + trunk_w//2, ty],
                fill=(128, 88, 48, 255))
    # Crown (three overlapping ellipses for full, round canopy)
    cr = int(S*0.14)
    c_y = ty - trunk_h - cr//4
    d.ellipse([tx-cr, c_y-cr, tx+cr, c_y+cr],
              fill=(58, 158, 58, 255), outline=(40, 125, 40))
    d.ellipse([tx - int(cr*0.6), c_y - int(cr*1.1),
               tx + int(cr*0.6), c_y - int(cr*0.2)],
              fill=(78, 192, 68, 255))
    d.ellipse([tx - int(cr*0.8), c_y - int(cr*0.5),
               tx + int(cr*0.8), c_y + int(cr*0.5)],
              fill=(68, 175, 62, 255))
    # ─── Medium tree (right-back area) ───
    tx2 = cx + int(hw*0.28); ty2 = fy - int(hd*1.30)
    trunk_h2 = int(S*0.18)
    d.rectangle([tx2 - trunk_w//2, ty2 - trunk_h2, tx2 + trunk_w//2, ty2],
                fill=(118, 78, 42, 255))
    cr2 = int(S*0.10)
    c_y2 = ty2 - trunk_h2 - cr2//4
    d.ellipse([tx2-cr2, c_y2-cr2, tx2+cr2, c_y2+cr2],
              fill=(68, 172, 62, 255), outline=(45, 130, 42))
    d.ellipse([tx2 - int(cr2*0.65), c_y2 - int(cr2*0.9),
               tx2 + int(cr2*0.65), c_y2 - int(cr2*0.1)],
              fill=(82, 195, 72, 255))
    # ─── Small tree / bush (front-right) ───
    tx3 = cx + int(hw*0.15); ty3 = fy - int(hd*0.45)
    cr3 = int(S*0.06)
    d.ellipse([tx3-cr3, ty3-cr3*2, tx3+cr3, ty3],
              fill=(72, 168, 62, 255))
    # ─── Small gazebo (right-center) ───
    gx = cx + int(hw*0.05); gy = fy - int(hd*0.78)
    ghw = int(S*0.04); ghd = ghw//2; gh = int(S*0.06)
    boxc(d, gx, gy, ghw, ghd, gh, (188, 168, 148, 255))
    # Gazebo roof
    g_by = gy - 2*ghd - gh
    roof(d, gx, g_by, int(ghw*1.5), int(ghd*1.5), int(gh*0.7),
         (148, 88, 62, 255))
    # Bench
    bx = cx - int(hw*0.15); b_y = fy - int(hd*0.62)
    bw = int(S*0.10); bh = max(2, S//48)
    d.rectangle([bx, b_y, bx+bw, b_y+bh],
                fill=(148, 98, 55, 255), outline=(108, 65, 35))
    lw = max(1, S//75)
    d.rectangle([bx+lw, b_y+bh, bx+2*lw, b_y+bh+bh], fill=(108, 65, 35, 255))
    d.rectangle([bx+bw-2*lw, b_y+bh, bx+bw-lw, b_y+bh+bh], fill=(108, 65, 35, 255))
    # Flower patches (multiple small circles)
    fcs = [(248, 82, 82, 255), (248, 208, 82, 255), (208, 82, 248, 255),
           (255, 155, 82, 255), (82, 208, 248, 255)]
    fr = max(2, S//48)
    positions = [(-0.18, -0.28), (-0.05, -0.18), (0.10, -0.32),
                 (-0.30, -0.62), (0.25, -0.72)]
    for i, (fx_f, fy_f) in enumerate(positions):
        ffx = cx + int(hw * fx_f)
        ffy = fy + int(hd * fy_f)
        fc = fcs[i % len(fcs)]
        d.ellipse([ffx-fr, ffy-fr, ffx+fr, ffy+fr], fill=fc)
        # Small leaf near flower
        d.ellipse([ffx+fr, ffy-fr//2, ffx+fr*2, ffy+fr//2],
                  fill=(82, 168, 62, 200))


def draw_hospital(d, S):
    cx = S//2; fy = S - S//18
    hw = int(S*0.42); hd = hw//2; h = int(S*0.38)
    # Main body — clinical white
    boxc(d, cx, fy, hw, hd, h, (245, 248, 252, 255))
    # Flat roof
    boxc(d, cx, fy - 2*hd - h, int(hw*1.05), int(hd*1.05), max(2, S//28),
         (208, 218, 228, 255))
    # Red cross symbol (prominent, on upper front)
    cross_cy = fy - 2*hd - int(h*0.68)
    carm = max(4, int(hw*0.12))  # cross arm half-length
    cth = max(2, carm//2)         # cross arm thickness
    d.rectangle([cx - cth, cross_cy - carm, cx + cth, cross_cy + carm],
                fill=(228, 52, 52, 255))
    d.rectangle([cx - carm, cross_cy - cth, cx + carm, cross_cy + cth],
                fill=(228, 52, 52, 255))
    # Windows — right face grid (2 rows × 3 cols)
    ww = max(3, hw//7); wh = int(h*0.10)
    for row in range(2):
        for col in range(3):
            u = (col + 0.5) / 3
            wx = int(cx + u * hw)
            wy = int(fy - u * hd - int(h*(0.35 + row*0.28)))
            win(d, wx, wy, ww, wh, (208, 235, 255, 255))
    # Windows — left face grid (2 rows × 2 cols)
    for row in range(2):
        for col in range(2):
            u = (col + 0.5) / 2
            wx = int(cx - hw + u * hw)
            wy = int(fy - hd + u * hd - int(h*(0.35 + row*0.28)))
            win(d, wx, wy, ww, wh, (208, 235, 255, 255))
    # Entrance
    dw = max(5, hw//4); dh = int(h*0.16)
    dx = cx - dw//2; dy = fy - hd//5 - dh
    d.rectangle([dx, dy, dx+dw, dy+dh],
                fill=(208, 218, 228, 255), outline=(158, 168, 178))


def draw_shrine(d, S):
    cx = S//2; fy = S - S//14
    hw = int(S*0.42); hd = hw//2

    # ─── Stone platform / steps ───
    step_h = int(S*0.04)
    boxc(d, cx, fy, int(hw*1.12), int(hd*1.12), step_h, (208, 188, 168, 255))

    # ─── Main hall ───
    mhw = int(hw*0.85); mhd = mhw//2; mh = int(S*0.20)
    boxc(d, cx, fy - step_h, mhw, mhd, mh, (188, 62, 52, 255))
    m_back_top = fy - step_h - 2*mhd - mh

    # ─── Lower sweeping roof ───
    r1hw = int(hw*1.05); r1hd = int(hd*0.55)
    r1ph = int(S*0.05)
    # roof sits at the level of the main hall back-top
    d.polygon([(cx, m_back_top - r1ph), (cx - r1hw, m_back_top + r1hd),
               (cx, m_back_top + 2*r1hd)],
              fill=(52, 52, 62, 255), outline=OL)
    d.polygon([(cx, m_back_top - r1ph), (cx + r1hw, m_back_top + r1hd),
               (cx, m_back_top + 2*r1hd)],
              fill=(38, 38, 48, 255), outline=OL)

    # ─── Upper structure ───
    uhw = int(hw*0.55); uhd = uhw//2; uh = int(S*0.14)
    u_fy = m_back_top + 2*mhd  # front of upper structure = front-top of main hall
    # But upper structure actually sits ON TOP of main hall
    u_fy2 = m_back_top + 2*uhd  # position so its back aligns
    boxc(d, cx, u_fy2, uhw, uhd, uh, (188, 52, 42, 255))
    u_back_top = u_fy2 - 2*uhd - uh

    # ─── Upper roof ───
    r2hw = int(uhw*1.18); r2hd = int(uhd*1.18)
    r2ph = int(S*0.05)
    d.polygon([(cx, u_back_top - r2ph), (cx - r2hw, u_back_top + r2hd),
               (cx, u_back_top + 2*r2hd)],
              fill=(48, 48, 58, 255), outline=OL)
    d.polygon([(cx, u_back_top - r2ph), (cx + r2hw, u_back_top + r2hd),
               (cx, u_back_top + 2*r2hd)],
              fill=(35, 35, 45, 255), outline=OL)

    # ─── Torii gate (in front of platform) ───
    pillar_sp = int(hw*0.48)
    pillar_w = max(2, S//48)
    pillar_h = int(S*0.18)
    for dx in [-pillar_sp, pillar_sp]:
        d.rectangle([cx+dx - pillar_w//2, fy - step_h - pillar_h,
                     cx+dx + pillar_w//2, fy - step_h],
                    fill=(208, 62, 42, 255))
    # Crossbeam
    beam_h = max(2, pillar_w*2)
    d.rectangle([cx - pillar_sp - pillar_w, fy - step_h - pillar_h,
                 cx + pillar_sp + pillar_w, fy - step_h - pillar_h + beam_h],
                fill=(208, 62, 42, 255))

    # ─── Lanterns ───
    lr = max(2, S//38)
    for dx in [-int(hw*0.82), int(hw*0.82)]:
        ly = fy - hd - int(S*0.12)
        d.ellipse([cx+dx-lr, ly-lr, cx+dx+lr, ly+lr],
                  fill=(255, 208, 82, 225))


# =====================================================================
# 3×3  BUILDING  (384 px canvas)
# =====================================================================

def draw_stadium(d, S):
    cx = S//2; fy = S - S//16
    hw = int(S*0.44); hd = hw//2

    # ─── Outer oval (stands / structure) ───
    ew = int(hw*0.95); eh = int(hd*0.95)
    oval_cy = fy - hd
    d.ellipse([cx-ew, oval_cy-eh, cx+ew, oval_cy+eh],
              fill=(188, 188, 198, 255), outline=(128, 128, 138))

    # ─── Inner green field ───
    iw = int(ew*0.58); ih = int(eh*0.58)
    d.ellipse([cx-iw, oval_cy-ih, cx+iw, oval_cy+ih],
              fill=(95, 188, 95, 255))

    # Field markings
    d.ellipse([cx - iw//3, oval_cy - ih//3, cx + iw//3, oval_cy + ih//3],
              outline=(255, 255, 255, 155))
    mlw = max(1, S//95)
    d.line([(cx, oval_cy-ih), (cx, oval_cy+ih)],
           fill=(255, 255, 255, 125), width=mlw)

    # ─── Walls / stands ───
    wall_h = int(S*0.18)

    # Left stands wall
    d.polygon([(cx-ew, oval_cy), (cx-ew, oval_cy - wall_h),
               (cx-iw, oval_cy-ih - wall_h), (cx-iw, oval_cy-ih)],
              fill=(168, 168, 182, 255), outline=(128, 128, 138, 155))
    # Right stands wall
    d.polygon([(cx+ew, oval_cy), (cx+ew, oval_cy - wall_h),
               (cx+iw, oval_cy-ih - wall_h), (cx+iw, oval_cy-ih)],
              fill=(148, 148, 162, 255), outline=(128, 128, 138, 155))
    # Back wall
    d.polygon([(cx-iw, oval_cy-ih - wall_h),
               (cx, oval_cy-eh - wall_h - int(S*0.03)),
               (cx+iw, oval_cy-ih - wall_h), (cx, oval_cy-ih)],
              fill=(158, 158, 172, 255), outline=(128, 128, 138, 155))

    # Seat rows (coloured horizontal lines — left=red, right=blue)
    for i in range(6):
        offset = i * wall_h // 7
        slw = max(1, S//75)
        d.line([(cx-ew + int(ew*0.12) + offset,
                 oval_cy - offset - int(wall_h*0.12)),
                (cx-iw + offset//2,
                 oval_cy - ih - offset - int(wall_h*0.12))],
               fill=(208, 82, 82, 205), width=slw)
        d.line([(cx+ew - int(ew*0.12) - offset,
                 oval_cy - offset - int(wall_h*0.12)),
                (cx+iw - offset//2,
                 oval_cy - ih - offset - int(wall_h*0.12))],
               fill=(82, 82, 208, 205), width=slw)

    # ─── Floodlights (4 poles) ───
    pole_w = max(1, S//75)
    pole_h = int(S*0.14)
    for dx in [-ew + int(ew*0.08), ew - int(ew*0.08)]:
        d.rectangle([cx+dx - pole_w//2, oval_cy - wall_h - pole_h,
                     cx+dx + pole_w//2, oval_cy - wall_h],
                    fill=(108, 108, 118, 255))
        lr = max(3, S//55)
        d.ellipse([cx+dx-lr, oval_cy - wall_h - pole_h - lr,
                   cx+dx+lr, oval_cy - wall_h - pole_h + lr],
                  fill=(255, 255, 208, 255))

    # ─── Scoreboard (back, between floodlights) ───
    sbw = int(S*0.06); sbh = int(S*0.028)
    sb_y = oval_cy - eh - wall_h - sbh
    d.rectangle([cx-sbw, sb_y, cx+sbw, sb_y+sbh],
                fill=(32, 32, 42, 255), outline=(62, 62, 72))
    d.rectangle([cx-sbw+2, sb_y+2, cx+sbw-2, sb_y+sbh-2],
                fill=(62, 188, 228, 205))


# =====================================================================
# Generate all
# =====================================================================

buildings = [
    # (name,          tileRows, tileCols, draw_function)
    ("house",         1, 1, draw_house),
    ("park",          2, 2, draw_park),
    ("library",       1, 2, draw_library),
    ("cafeteria",     1, 1, draw_cafeteria),
    ("gym",           2, 1, draw_gym),
    ("art_room",      1, 1, draw_art_room),
    ("science_lab",   1, 2, draw_science_lab),
    ("fountain",      1, 1, draw_fountain),
    ("music_room",    1, 1, draw_music_room),
    ("bookstore",     1, 1, draw_bookstore),
    ("hospital",      2, 2, draw_hospital),
    ("computer_lab",  1, 2, draw_computer_lab),
    ("shrine",        2, 2, draw_shrine),
    ("clock_tower",   1, 1, draw_clock_tower),
    ("stadium",       3, 3, draw_stadium),
]

print(f"Generating {len(buildings)} buildings (direct render, no supersampling)…")
for name, tr, tc, fn in buildings:
    create(name, tr, tc, fn)
print("Done!")
