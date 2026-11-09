#!/usr/bin/env python3
"""Splits Apple's Malayalam font into the two single-face files the image
generator needs.

Flutter loads only the first face of a .ttc, which would leave the Malayalam
headlines without bold. This writes the regular and bold faces of
"Malayalam Sangam MN" to build/store_fonts/ unchanged.

The result must NOT be committed or shared (the font belongs to Apple).
Needs `pip install fonttools`.
"""
import os
import sys

from fontTools.ttLib import TTCollection

SANGAM = "/System/Library/Fonts/Supplemental/Malayalam Sangam MN.ttc"
OUT = "build/store_fonts"

if not os.path.exists(SANGAM):
    sys.exit("Malayalam Sangam MN not found (run this on macOS)")
os.makedirs(OUT, exist_ok=True)
faces = TTCollection(SANGAM).fonts
for index, name in ((0, "SangamML-Regular.ttf"), (1, "SangamML-Bold.ttf")):
    faces[index].save(os.path.join(OUT, name))
    print("wrote", os.path.join(OUT, name))
