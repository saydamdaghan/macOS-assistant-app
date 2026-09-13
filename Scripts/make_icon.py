#!/usr/bin/env python3
import struct
import zlib
from pathlib import Path


def png(width: int, height: int, rgba_fn):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(rgba_fn(x, y))
    compressor = zlib.compressobj(9, zlib.DEFLATED, 15, 8, zlib.Z_DEFAULT_STRATEGY)
    data = compressor.compress(bytes(raw)) + compressor.flush()

    def chunk(tag: bytes, payload: bytes) -> bytes:
        crc = zlib.crc32(tag + payload) & 0xFFFFFFFF
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", crc)

    return b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)),
            chunk(b"IDAT", data),
            chunk(b"IEND", b""),
        ]
    )


def render(size=1024):
    def pixel(x, y):
        nx = (x + 0.5) / size
        ny = (y + 0.5) / size
        # rounded white square
        inset = 0.08
        radius = 0.18
        px = min(max(nx, inset), 1 - inset)
        py = min(max(ny, inset), 1 - inset)
        dx = abs(nx - 0.5) - (0.5 - inset - radius)
        dy = abs(ny - 0.5) - (0.5 - inset - radius)
        outside = False
        if dx > 0 and dy > 0 and (dx * dx + dy * dy) > radius * radius:
            outside = True
        if nx < inset or nx > 1 - inset or ny < inset or ny > 1 - inset:
            outside = True
        if outside:
            return (0, 0, 0, 0)

        # simple serif-less A
        ink = (26, 28, 31, 255)
        white = (255, 255, 255, 255)
        cx = nx - 0.5
        # left and right strokes
        left = abs((ny - 0.78) * 0.42 - cx) < 0.055 and 0.28 < ny < 0.78
        right = abs((ny - 0.78) * -0.42 - cx) < 0.055 and 0.28 < ny < 0.78
        bar = 0.56 < ny < 0.62 and abs(cx) < 0.16
        if left or right or bar:
            return ink
        return white

    return png(size, size, pixel)


def main():
    folder = Path(__file__).resolve().parents[1] / "Asistan" / "Assets.xcassets" / "AppIcon.appiconset"
    master = render(1024)
    (folder / "AppIcon-1024.png").write_bytes(master)
    # smaller sizes from a fresh render so edges stay clean enough
    for size in (16, 32, 64, 128, 256, 512):
        (folder / f"AppIcon-{size}.png").write_bytes(render(size))
    print(folder)


if __name__ == "__main__":
    main()
