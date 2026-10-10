from PIL import Image

ONE = (255, 0, 255)
ZERO = (0, 255, 255)
GRID_COLS = 12
GRID_ROWS = 8
BASE_CELL = 4

def _int(bits):
    value = 0
    for bit in bits:
        value = (value << 1) | bit
    return value

def _classify(rgb):
    r, g, b = rgb[:3]
    d1 = (r - ONE[0]) ** 2 + (g - ONE[1]) ** 2 + (b - ONE[2]) ** 2
    d0 = (r - ZERO[0]) ** 2 + (g - ZERO[1]) ** 2 + (b - ZERO[2]) ** 2
    if min(d0, d1) > 120 ** 2:
        raise ValueError(f"telemetry cell color is ambiguous: {rgb[:3]}")
    return 1 if d1 < d0 else 0

def decode_telemetry_image(image: Image.Image, *, origin=(0, 0), scale=3):
    """Decode the QA-only 12x8 telemetry grid from a rendered frame."""
    if scale <= 0:
        raise ValueError("scale must be positive")
    im = image.convert("RGB")
    ox, oy = origin
    cell = BASE_CELL * scale
    payload = []
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            x = ox + col * cell + cell // 2
            y = oy + row * cell + cell // 2
            if not (0 <= x < im.width and 0 <= y < im.height):
                raise ValueError("telemetry grid falls outside image")
            payload.append(_classify(im.getpixel((x, y))))

    pos = 0
    def take(width):
        nonlocal pos
        value = _int(payload[pos:pos + width])
        pos += width
        return value

    magic = take(8)
    if magic != 0xA5:
        raise ValueError(f"telemetry magic mismatch: 0x{magic:02x}")
    version = take(4)
    world = take(2)
    level = take(4)
    hardcore = bool(take(1))
    controlled = take(1)
    level_finished = bool(take(1))
    p1x = take(12)
    p1y = take(10)
    p2x = take(12)
    p2y = take(10)
    p1dead = bool(take(1))
    p2dead = bool(take(1))
    piggyback = bool(take(1))
    crate_present = bool(take(1))
    crate_x = take(12)
    crate_y = take(10)
    take(5)  # reserved
    if pos != 96:
        raise AssertionError(pos)

    return {
        "version": version,
        "world": world,
        "level": level,
        "hardcore": hardcore,
        "controlled": controlled,
        "level_finished": level_finished,
        "p1": {"x": p1x, "y": p1y, "dead": p1dead},
        "p2": {"x": p2x, "y": p2y, "dead": p2dead},
        "piggyback": piggyback,
        "crate": {"x": crate_x, "y": crate_y} if crate_present else None,
    }
