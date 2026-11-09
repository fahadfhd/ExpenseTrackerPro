#!/usr/bin/env python3
"""Final step for the store images (run after store_images_test.dart).

* flattens every PNG to plain RGB: both stores reject transparency;
* builds the two app icons from assets/icon/icon.png;
* checks each image has exactly the size its store slot needs.

Needs Pillow (`pip install pillow`). Run from the repo root.
"""
import os
import sys

from PIL import Image

STORE = "store"
ICON_SOURCE = "assets/icon/icon.png"

# folder (below store/) -> required size in pixels
EXPECTED = {
    "google-play/phone-screenshots": (1080, 1920),
    "google-play/feature-graphic": (1024, 500),
    "google-play/icon": (512, 512),
    "app-store/iphone-6.9": (1320, 2868),
    "app-store/ipad-13": (2064, 2752),
    "app-store/icon": (1024, 1024),
}


def flatten(path: str) -> None:
    image = Image.open(path)
    if image.mode != "RGB":
        flat = Image.new("RGB", image.size, (255, 255, 255))
        if "A" in image.getbands():
            flat.paste(image, mask=image.getchannel("A"))
        else:
            flat = image.convert("RGB")
        image = flat
    image.save(path, optimize=True)


def make_icons() -> None:
    icon = Image.open(ICON_SOURCE).convert("RGB")
    for folder, size in (
        ("app-store/icon", 1024),
        ("google-play/icon", 512),
    ):
        os.makedirs(os.path.join(STORE, folder), exist_ok=True)
        name = f"icon-{size}.png"
        resized = icon if icon.size == (size, size) else icon.resize(
            (size, size), Image.LANCZOS
        )
        resized.save(os.path.join(STORE, folder, name), optimize=True)


def main() -> int:
    make_icons()
    problems = []
    total = 0
    for root, _, files in os.walk(STORE):
        for name in sorted(files):
            if not name.endswith(".png"):
                continue
            path = os.path.join(root, name)
            flatten(path)
            folder = os.path.relpath(root, STORE)
            # Language sub-folders (en / ml) share their parent's size.
            key = folder if folder in EXPECTED else os.path.dirname(folder)
            expected = EXPECTED.get(key)
            image = Image.open(path)
            total += 1
            if expected and image.size != expected:
                problems.append(f"{path}: {image.size}, needs {expected}")
            if image.mode != "RGB":
                problems.append(f"{path}: mode {image.mode}, needs RGB")
            if os.path.getsize(path) > 8 * 1024 * 1024:
                problems.append(f"{path}: over 8 MB")
    print(f"{total} images checked")
    for problem in problems:
        print("PROBLEM:", problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
