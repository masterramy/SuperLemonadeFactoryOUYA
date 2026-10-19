"""Regression: original game SWF version 21 must load the native extension's SWF."""
from pathlib import Path
import sys
import zipfile

ane = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent / "build/ane/SLFPGSSavedGames-dev.ane"
with zipfile.ZipFile(ane) as z:
    assert z.testzip() is None
    for name in ("library.swf", "META-INF/ANE/Android-ARM/library.swf", "META-INF/ANE/Android-ARM64/library.swf"):
        data = z.read(name)
        assert len(data) >= 8 and data[:3] in (b"FWS", b"CWS", b"ZWS"), name
        assert data[3] <= 21, f"{name} SWF v{data[3]} exceeds app SWF v21"
print("PASS: PGS native ANE uses compatible SWF version for root game")
