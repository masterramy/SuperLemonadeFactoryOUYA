#!/usr/bin/env python3
"""Fail closed when a built AIR PGS ANE is incomplete; not a Google-login test."""
from pathlib import Path
import io
import sys
import zipfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
ane_path = root / "native/pgs-ane/build/ane/SLFPGSSavedGames-dev.ane"
try:
    assert ane_path.is_file() and ane_path.stat().st_size > 5000, "Missing/empty built ANE"
    with zipfile.ZipFile(ane_path) as ane:
        assert ane.testzip() is None, "Broken ANE ZIP CRC"
        names = set(ane.namelist())
        assert {"META-INF/ANE/extension.xml", "library.swf", "catalog.xml"} <= names
        extension = ET.fromstring(ane.read("META-INF/ANE/extension.xml"))
        ns = {"x": extension.tag.split("}")[0].lstrip("{")}
        assert extension.findtext("x:id", namespaces=ns) == "com.ramybaheeg.slfport.pgs.savedgames"
        declared = {p.attrib["name"] for p in extension.findall(".//x:platform", ns)}
        for platform in ("Android-ARM", "Android-ARM64"):
            assert platform in declared, f"Missing declared platform {platform}"
            prefix = "META-INF/ANE/" + platform + "/"
            assert {prefix+"SLFPGSNative.jar", prefix+"library.swf", prefix+"platform.xml"} <= names
            assert ane.read(prefix + "library.swf"), "Empty platform SWF"
            pxml = ET.fromstring(ane.read(prefix + "platform.xml"))
            vals = " ".join((node.text or "").strip() for node in pxml.iter())
            assert "com.google.android.gms:play-services-games-v2:22.1.0" in vals, "Missing PGS dependency"
            with zipfile.ZipFile(io.BytesIO(ane.read(prefix+"SLFPGSNative.jar"))) as native:
                assert native.testzip() is None, "Native JAR corrupt"
                assert "com/ramybaheeg/slfport/pgs/PGSExtension.class" in native.namelist(), "Missing Java bridge"
    print("PASS: ANE bytes, 2 platforms, native Java, AIR Gradle dependency verified")
except (AssertionError, OSError, zipfile.BadZipFile, ET.ParseError, KeyError) as exc:
    print(f"FAIL ANE validation: {exc}", file=sys.stderr)
    sys.exit(1)
