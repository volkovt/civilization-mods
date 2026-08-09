"""Build a high-contrast 32px unit-flag emblem for Sayajin heroes."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "ART" / "FlagSources"


def build_flag() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    size = 256
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    ivory = (255, 250, 226, 255)
    gold = (255, 188, 24, 255)
    deep_blue = (8, 35, 92, 255)

    # Broad shoulders keep the emblem readable at the game's native 32 px.
    draw.polygon(
        [(35, 238), (51, 196), (91, 176), (128, 187),
         (165, 176), (205, 196), (221, 238)],
        fill=ivory,
    )
    draw.polygon(
        [(67, 230), (80, 201), (105, 191), (128, 207),
         (151, 191), (176, 201), (189, 230)],
        fill=gold,
    )

    # Spiky hair silhouette: a simple, bright Sayajin shape rather than a
    # dark miniature portrait, which disappears inside Civ V's unit disc.
    hair = [
        (67, 127), (35, 75), (84, 84), (78, 29), (116, 67),
        (139, 14), (153, 68), (207, 39), (183, 92), (229, 91),
        (185, 137), (166, 153), (89, 153),
    ]
    draw.polygon(hair, fill=ivory)
    draw.line(hair + [hair[0]], fill=gold, width=9, joint="curve")

    # Face and compact expression remain visible after mipmapping.
    draw.ellipse((82, 83, 174, 190), fill=gold, outline=ivory, width=8)
    draw.polygon([(91, 119), (119, 126), (103, 139)], fill=deep_blue)
    draw.polygon([(165, 119), (137, 126), (153, 139)], fill=deep_blue)
    draw.line([(111, 161), (128, 168), (145, 161)], fill=deep_blue, width=7)

    source = SOURCE_DIR / "SayajinHeroFlag_256_source.png"
    image.save(source)
    icon = image.resize((32, 32), Image.Resampling.LANCZOS)
    icon.save(SOURCE_DIR / "SayajinHero_32.png")
    print(f"HERO_FLAG_OK source={source} output=SayajinHero_32.png")


if __name__ == "__main__":
    build_flag()
