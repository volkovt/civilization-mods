"""Rebuild the main Sayajin Civ V icon atlases with safe circular artwork."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


PROJECT_DIR = Path(__file__).resolve().parents[1]
ART_DIR = PROJECT_DIR / "ART"
SOURCE_DIR = ART_DIR / "IconSources"
SIZES = (256, 128, 80, 64, 45, 32)
ATLASES = ("SayajinIcon", "SayajinMonument", "SayajinEmpire", "SayajinTrait")


def find_texconv() -> Path:
    candidates = (
        Path(r"D:\Mods civ5 pessoal\tools\texconv.exe"),
        PROJECT_DIR.parents[1] / "tools" / "texconv.exe",
    )
    on_path = shutil.which("texconv")
    if on_path:
        candidates = (Path(on_path),) + candidates
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise FileNotFoundError("texconv.exe nao foi encontrado")


def prepare_png(source: Path, destination: Path, size: int) -> None:
    inset = max(2, round(size * 0.06))
    content_size = size - inset * 2
    with Image.open(source) as master:
        image = ImageOps.fit(
            master.convert("RGBA"),
            (content_size, content_size),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
        radius = 0.55 if size >= 128 else 0.35
        percent = 115 if size >= 80 else 125
        image = image.filter(ImageFilter.UnsharpMask(radius=radius, percent=percent, threshold=2))

        logical = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        logical.alpha_composite(image, (inset, inset))

        supersample = 4
        mask_large = Image.new("L", (size * supersample, size * supersample), 0)
        edge = inset * supersample
        ImageDraw.Draw(mask_large).ellipse(
            (edge, edge, size * supersample - edge - 1, size * supersample - edge - 1),
            fill=255,
        )
        mask = mask_large.resize((size, size), Image.Resampling.LANCZOS)
        logical.putalpha(ImageChops.multiply(logical.getchannel("A"), mask))

        if size == 45:
            physical = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
            physical.alpha_composite(logical, (0, 0))
            logical = physical
        logical.save(destination, format="PNG", optimize=True)


def convert_to_dds(texconv: Path, png: Path) -> Path:
    command = (
        str(texconv), "-nologo", "-y", "-dx9", "-f", "BC3_UNORM",
        "-m", "0", "-ft", "dds", "-o", str(ART_DIR), str(png),
    )
    result = subprocess.run(command, check=False, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    return ART_DIR / f"{png.stem}.dds"


def main() -> int:
    texconv = find_texconv()
    built = []
    for atlas in ATLASES:
        source = SOURCE_DIR / f"{atlas}_source.png"
        if not source.is_file():
            raise FileNotFoundError(f"Fonte ausente: {source}")
        for size in SIZES:
            temporary = ART_DIR / f"{atlas}_{size}.png"
            prepare_png(source, temporary, size)
            built.append(convert_to_dds(texconv, temporary))
            # SayajinIcon PNGs are explicit legacy project content as well as
            # DDS sources; keep them in sync so ModBuddy can package the mod.
            if atlas != "SayajinIcon":
                temporary.unlink()
    print(f"{len(built)} atlases principais arredondados criados em {ART_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
