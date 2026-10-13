#!/usr/bin/env python3
import math
import struct
import wave
from pathlib import Path

OUT_DIR = Path.home() / ".local/share/sounds/f"
RATE = 48000

def note(name: str) -> float:
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
             "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch = name[:-1]
    octave = int(name[-1])
    semitones = names[pitch] + 12 * (octave - 4) - 9
    return 440.0 * (2 ** (semitones / 12))

def tone(freq: float, dur: float, amp: float, start: float,
         buf: list[float], decay: float = 6.0) -> None:
    n0 = int(start * RATE)
    n = int(dur * RATE)
    attack = int(0.006 * RATE)

    for i in range(n):
        idx = n0 + i
        if idx >= len(buf):
            break

        t = i / RATE
        env = math.exp(-decay * t)
        if i < attack:
            env *= i / attack

        sample = (
            math.sin(2 * math.pi * freq * t)
            + 0.34 * math.sin(2 * math.pi * freq * 2.01 * t)
            + 0.10 * math.sin(2 * math.pi * freq * 3.02 * t)
        )
        buf[idx] += sample * env * amp

def reverb(buf: list[float], taps=((0.055, 0.22), (0.098, 0.13),
                                   (0.157, 0.07))) -> None:
    original = list(buf)
    for delay, gain in taps:
        offset = int(delay * RATE)
        for i in range(offset, len(buf)):
            buf[i] += original[i - offset] * gain

def normalize(buf: list[float], peak: float) -> None:
    current = max(abs(v) for v in buf) or 1.0
    scale = peak / current
    for i in range(len(buf)):
        buf[i] *= scale

def write_wav(path: Path, buf: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = bytearray()
    for value in buf:
        v = math.tanh(value)
        frames += struct.pack("<h", int(v * 32767))

    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))

def build_normal() -> list[float]:
    length = int(1.1 * RATE)
    buf = [0.0] * length

    tone(note("F#6"), 0.9, 0.55, 0.000, buf, decay=7.0)
    tone(note("A6"),  0.9, 0.45, 0.075, buf, decay=7.5)
    tone(note("F#5"), 0.9, 0.18, 0.000, buf, decay=5.5)

    reverb(buf)
    normalize(buf, 0.62)
    return buf

def build_critical() -> list[float]:
    length = int(1.6 * RATE)
    buf = [0.0] * length

    tone(note("D5"),  1.3, 0.55, 0.000, buf, decay=4.2)
    tone(note("A#4"), 1.3, 0.50, 0.140, buf, decay=4.0)
    tone(note("D4"),  1.3, 0.22, 0.000, buf, decay=3.4)

    reverb(buf)
    normalize(buf, 0.78)
    return buf

def build_limit() -> list[float]:
    length = int(0.22 * RATE)
    buf = [0.0] * length

    tone(note("A2"), 0.18, 0.60, 0.000, buf, decay=42.0)
    tone(note("E3"), 0.18, 0.28, 0.000, buf, decay=55.0)

    normalize(buf, 0.55)
    return buf

def main() -> None:
    write_wav(OUT_DIR / "notify.wav", build_normal())
    write_wav(OUT_DIR / "critical.wav", build_critical())
    write_wav(OUT_DIR / "limit.wav", build_limit())
    print(f"wrote {OUT_DIR}/notify.wav, critical.wav and limit.wav")

if __name__ == "__main__":
    main()
