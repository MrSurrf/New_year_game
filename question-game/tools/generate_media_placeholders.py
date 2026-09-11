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


def exists_any(base):
    return any(os.path.exists(base + ext) for ext in (".wav", ".ogg", ".mp3"))


def make(path, samples):
    # не затираем и не дублируем файлы, которые пользователь уже заменил своими
    if exists_any(os.path.splitext(path)[0]):
        print("пропуск (уже есть свой файл):", os.path.relpath(path, ROOT))
        return
    write_wav(path, samples)
    print("создано:", os.path.relpath(path, ROOT))


def main():
    snd = os.path.join(ROOT, "sound")
    make(os.path.join(snd, "ui", "click.wav"), tone(1200, 0.06, 0.5))
    make(os.path.join(snd, "ui", "switch.wav"),
         concat(tone(600, 0.08), tone(900, 0.10)))
    make(os.path.join(snd, "abilities", "ability.wav"),
         concat(tone(523, 0.10), tone(659, 0.10), tone(784, 0.18)))
    make(os.path.join(snd, "music", "background_loop.wav"), make_music())
    make(os.path.join(snd, "game_start", "game_start.wav"),
         concat(tone(392, 0.12), tone(523, 0.12), tone(659, 0.25)))
    make(os.path.join(snd, "character_select", "character_select.wav"),
         tone(800, 0.09, 0.45))
    make(os.path.join(snd, "category_select", "category_select.wav"),
         concat(tone(700, 0.08), tone(1000, 0.12)))
    make(os.path.join(snd, "steal", "steal.wav"),
         concat(tone(300, 0.12, 0.5), tone(220, 0.20, 0.5)))
    make(os.path.join(snd, "timer", "timer_tick.wav"), tone(1000, 0.05, 0.35))
    make(os.path.join(snd, "timer", "timeout.wav"),
         concat(tone(500, 0.15, 0.5), tone(350, 0.15, 0.5), tone(220, 0.3, 0.5)))
    make(os.path.join(snd, "round_end", "round_end.wav"),
         concat(tone(523, 0.12), tone(392, 0.12), tone(523, 0.22)))
    make(os.path.join(snd, "game_end", "game_end.wav"),
         concat(tone(523, 0.15), tone(659, 0.15), tone(784, 0.15), tone(1047, 0.45)))

    def bg_pixel(x, y):
        t = y / 719
        return (int(20 + 40 * t), int(15 + 25 * t), int(60 + 80 * t))

    write_png(os.path.join(ROOT, "assets", "backgrounds", "main_background.png"),
              1280, 720, bg_pixel)
    print("Готово")


if __name__ == "__main__":
    main()
