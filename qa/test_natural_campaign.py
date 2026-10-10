import unittest
from PIL import Image, ImageDraw

from natural_campaign import decode_telemetry_image

ONE = (255, 0, 255)
ZERO = (0, 255, 255)

def bits(value, width):
    return [int(x) for x in f"{value:0{width}b}"]

def make_frame(*, world=1, level=2, hardcore=0, controlled=1,
               finished=0, p1x=321, p1y=470, p2x=777, p2y=389,
               p1dead=0, p2dead=0, piggy=0,
               crate_present=1, cratex=763, cratey=373,
               scale=3, offset=(0, 0)):
    payload = (
        bits(0xA5, 8) +
        bits(1, 4) +
        bits(world, 2) +
        bits(level, 4) +
        [hardcore, controlled, finished] +
        bits(p1x, 12) +
        bits(p1y, 10) +
        bits(p2x, 12) +
        bits(p2y, 10) +
        [p1dead, p2dead, piggy, crate_present] +
        bits(cratex, 12) +
        bits(cratey, 10) +
        [0, 0, 0, 0, 0]
    )
    assert len(payload) == 96
    cell = 4 * scale
    ox, oy = offset
    im = Image.new("RGB", (ox + 12 * cell + 20, oy + 8 * cell + 20), (30, 30, 30))
    d = ImageDraw.Draw(im)
    for i, bit in enumerate(payload):
        col, row = i % 12, i // 12
        x0, y0 = ox + col * cell, oy + row * cell
        d.rectangle((x0, y0, x0 + cell - 1, y0 + cell - 1), fill=ONE if bit else ZERO)
    return im

class TelemetryDecodeTests(unittest.TestCase):
    def test_decodes_known_campaign_state_at_3x(self):
        state = decode_telemetry_image(make_frame(), origin=(0, 0), scale=3)
        self.assertEqual(state, {
            "version": 1, "world": 1, "level": 2, "hardcore": False,
            "controlled": 1, "level_finished": False,
            "p1": {"x": 321, "y": 470, "dead": False},
            "p2": {"x": 777, "y": 389, "dead": False},
            "piggyback": False,
            "crate": {"x": 763, "y": 373},
        })

    def test_decodes_offset_4x_frame_and_finished_state(self):
        state = decode_telemetry_image(
            make_frame(world=3, level=12, hardcore=1, controlled=0,
                       finished=1, p1x=2047, p1y=511, p2x=4090, p2y=700,
                       p1dead=1, p2dead=0, piggy=1,
                       crate_present=1, cratex=4000, cratey=700,
                       scale=4, offset=(17, 23)),
            origin=(17, 23), scale=4)
        self.assertEqual(state["world"], 3)
        self.assertEqual(state["level"], 12)
        self.assertTrue(state["hardcore"])
        self.assertTrue(state["level_finished"])
        self.assertEqual(state["p1"], {"x": 2047, "y": 511, "dead": True})
        self.assertEqual(state["p2"], {"x": 4090, "y": 700, "dead": False})
        self.assertTrue(state["piggyback"])
        self.assertEqual(state["crate"], {"x": 4000, "y": 700})

    def test_decodes_missing_crate_as_none(self):
        state = decode_telemetry_image(
            make_frame(crate_present=0, cratex=0, cratey=0),
            origin=(0, 0), scale=3)
        self.assertIsNone(state["crate"])

    def test_rejects_frame_without_magic(self):
        im = make_frame()
        ImageDraw.Draw(im).rectangle((0, 0, 11, 11), fill=ZERO)
        with self.assertRaisesRegex(ValueError, "telemetry magic"):
            decode_telemetry_image(im, origin=(0, 0), scale=3)

if __name__ == "__main__":
    unittest.main()
