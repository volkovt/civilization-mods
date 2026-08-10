"""Build Civ V DDS icon atlases from the five master hero portraits.

The script expects Pillow and Microsoft's DirectXTex `texconv.exe`.
It keeps the square master PNG files untouched, resamples each portrait with
high quality, applies a circular antialiased mask plus a UI-safe inset, and
writes legacy DX9 BC3/DXT5 DDS files with a complete mip chain for Civ V.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


PROJECT_DIR = Path(__file__).resolve().parents[1]
SOURCE_DIR = PROJECT_DIR / "ART" / "Heroes"
OUTPUT_DIR = SOURCE_DIR
SIZES = (256, 128, 80, 64, 45, 32)
HEROES = {
    "Vegeta": "SayajinHeroVegeta",
    "Goku": "SayajinHeroGoku",
    "Gohan": "SayajinHeroGohan",
    "Piccolo": "SayajinHeroPiccolo",
    "Broly": "SayajinHeroBroly",
}


def find_texconv() -> Path:
    candidates = [
        PROJECT_DIR.parents[1] / "tools" / "texconv.exe",
        Path(r"D:\Mods civ5 pessoal\tools\texconv.exe"),
    ]
    on_path = shutil.which("texconv")
    if on_path:
        candidates.insert(0, Path(on_path))
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise FileNotFoundError("texconv.exe não foi encontrado.")


def prepare_png(source: Path, destination: Path, size: int) -> None:
    with Image.open(source) as image:
        image = image.convert("RGBA")
        inset = max(2, round(size * 0.06))
        content_size = size - inset * 2
        image = ImageOps.fit(
            image,
            (content_size, content_size),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.44),
        )
        radius = 0.55 if size >= 128 else 0.35
        percent = 115 if size >= 80 else 125
        image = image.filter(
            ImageFilter.UnsharpMask(radius=radius, percent=percent, threshold=2)
        )

        logical = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        logical.alpha_composite(image, (inset, inset))

        # Supersampling prevents the stair-stepped square/circle edge that is
        # especially visible in the 32px city banner and technology tree.
        supersample = 4
        mask_large = Image.new("L", (size * supersample, size * supersample), 0)
        draw = ImageDraw.Draw(mask_large)
        edge = inset * supersample
        draw.ellipse(
            (edge, edge, size * supersample - edge - 1, size * supersample - edge - 1),
            fill=255,
        )
        mask = mask_large.resize((size, size), Image.Resampling.LANCZOS)
        logical.putalpha(ImageChops.multiply(logical.getchannel("A"), mask))
        image = logical

        # A one-column BC3 texture cannot physically be 45 pixels wide: BC
        # compression works in 4x4 blocks.  Civ V still asks IconHookup for a
        # 45px cell, so keep the art in the top-left 45x45 cell and pad the
        # actual DDS canvas to 48x48.
        if size == 45:
            canvas = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
            canvas.alpha_composite(image, (0, 0))
            image = canvas
        image.save(destination, format="PNG", optimize=True)


def convert_to_dds(texconv: Path, png: Path) -> Path:
    command = [
        str(texconv),
        "-nologo",
        "-y",
        "-dx9",
        "-f",
        "BC3_UNORM",
        "-m",
        "0",
        "-ft",
        "dds",
        "-o",
        str(OUTPUT_DIR),
        str(png),
    ]
    result = subprocess.run(command, check=False, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    return OUTPUT_DIR / f"{png.stem}.dds"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hero", choices=tuple(HEROES), help="Rebuild only one hero atlas family.")
    args = parser.parse_args()
    texconv = find_texconv()
    built: list[Path] = []
    selected_heroes = {args.hero: HEROES[args.hero]} if args.hero else HEROES

    for hero, atlas_name in selected_heroes.items():
        source = SOURCE_DIR / f"{hero}_source.png"
        if not source.is_file():
            raise FileNotFoundError(f"Fonte ausente: {source}")

        for size in SIZES:
            png = OUTPUT_DIR / f"{atlas_name}_{size}.png"
            prepare_png(source, png, size)
            dds = convert_to_dds(texconv, png)
            png.unlink()
            built.append(dds)

    print(f"{len(built)} atlases DDS criados em {OUTPUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
