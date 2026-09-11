"""Генератор заглушек: звуки (WAV) и фон (PNG). Только stdlib."""
import math
import os
import struct
import wave
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RATE = 22050


def write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        w.writeframes(frames)


def tone(freq, duration, volume=0.4, fade=0.01):
    n = int(RATE * duration)
    out = []
    for i in range(n):
        t = i / RATE
        env = 1.0
        if t < fade:
            env = t / fade
        elif t > duration - fade:
            env = (duration - t) / fade
        out.append(volume * env * math.sin(2 * math.pi * freq * t))
    return out


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def make_music():
    # 4 секунды мягкого перебора аккорда, пригодно для зацикливания
    chords = [(261.63, 329.63, 392.00), (220.00, 261.63, 329.63),
              (174.61, 220.00, 261.63), (196.00, 246.94, 293.66)]
    n = RATE  # 1 секунда на аккорд
    out = []
    for chord in chords:
        for i in range(n):
            t = i / RATE
            s = sum(math.sin(2 * math.pi * f * t) for f in chord) / len(chord)
            out.append(0.15 * s)
    return out


def write_png(path, width, height, pixel_fn):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixel_fn(x, y))

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
           + chunk(b"IDAT", zlib.compress(bytes(raw))) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def main():
    snd = os.path.join(ROOT, "sound")
    write_wav(os.path.join(snd, "ui", "click.wav"), tone(1200, 0.06, 0.5))
    write_wav(os.path.join(snd, "ui", "switch.wav"),
              concat(tone(600, 0.08), tone(900, 0.10)))
    write_wav(os.path.join(snd, "abilities", "ability.wav"),
              concat(tone(523, 0.10), tone(659, 0.10), tone(784, 0.18)))
    write_wav(os.path.join(snd, "music", "background_loop.wav"), make_music())

    def bg_pixel(x, y):
        t = y / 719
        return (int(20 + 40 * t), int(15 + 25 * t), int(60 + 80 * t))

    write_png(os.path.join(ROOT, "assets", "backgrounds", "main_background.png"),
              1280, 720, bg_pixel)
    print("Готово")


if __name__ == "__main__":
    main()
