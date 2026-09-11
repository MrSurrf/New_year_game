"""Генератор PNG-плейсхолдеров персонажей (stdlib only: zlib, struct).

Создаёт assets/characters/<id>/frame1.png и frame2.png — цветные квадраты
128x128 с «лицом»; второй кадр светлее и с белой рамкой-«вспышкой».
"""
import os
import struct
import zlib

SIZE = 128

CHARACTERS = {
    "mage": (150, 80, 200),
    "sage": (70, 110, 220),
    "chrono": (40, 180, 170),
    "gambler": (220, 180, 40),
    "alchemist": (70, 180, 80),
    "jester": (220, 80, 80),
}


def write_png(path, pixels):
    def chunk(tag, data):
        out = struct.pack(">I", len(data)) + tag + data
        return out + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    raw = b"".join(
        b"\x00" + pixels[y * SIZE * 4:(y + 1) * SIZE * 4] for y in range(SIZE)
    )
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
           + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def lighten(color, k=0.35):
    return tuple(min(255, int(c + (255 - c) * k)) for c in color)


def make_frame(base, flash=False):
    px = bytearray(SIZE * SIZE * 4)
    body = lighten(base) if flash else base

    def rect(x0, y0, w, h, color):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                i = (y * SIZE + x) * 4
                px[i:i + 4] = bytes(color) + b"\xff"

    rect(0, 0, SIZE, SIZE, body)
    # глаза
    eye = (30, 30, 40)
    rect(32, 44, 20, 20, eye)
    rect(76, 44, 20, 20, eye)
    # улыбка
    rect(44, 88, 40, 10, eye)
    if flash:
        # белая рамка-«вспышка»
        white = (255, 255, 255)
        rect(0, 0, SIZE, 8, white)
        rect(0, SIZE - 8, SIZE, 8, white)
        rect(0, 0, 8, SIZE, white)
        rect(SIZE - 8, 0, 8, SIZE, white)
    return bytes(px)


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    for cid, color in CHARACTERS.items():
        folder = os.path.join(root, "assets", "characters", cid)
        os.makedirs(folder, exist_ok=True)
        write_png(os.path.join(folder, "frame1.png"), make_frame(color))
        write_png(os.path.join(folder, "frame2.png"), make_frame(color, flash=True))
        print("OK:", cid)


if __name__ == "__main__":
    main()
