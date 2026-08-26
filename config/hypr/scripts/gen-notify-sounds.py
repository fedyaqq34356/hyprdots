#!/usr/bin/env python3
"""Synthesize the notification sounds used by the Quickshell notification popup.

Writes two WAVs to ~/.local/share/sounds/f/:

  notify.wav    soft two-note marimba-ish blip for normal notifications
  critical.wav  lower, slower, slightly dissonant pair for critical ones

Everything is generated here rather than shipped as a binary, so the sounds can
be retuned by editing the note tables below and re-running this script.
Standard library only.
"""

import math
import struct
import wave
from pathlib import Path

OUT_DIR = Path.home() / ".local/share/sounds/f"
RATE = 48000

# Equal temperament, A4 = 440 Hz.
def note(name: str) -> float:
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
             "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch = name[:-1]
    octave = int(name[-1])
    semitones = names[pitch] + 12 * (octave - 4) - 9
    return 440.0 * (2 ** (semitones / 12))


def tone(freq: float, dur: float, amp: float, start: float,
         buf: list[float], decay: float = 6.0) -> None:
    """Add one struck-bar note into buf, mixed in place.

    The timbre is a fundamental plus a quiet octave and a very quiet twelfth,
    which is roughly what a wooden bar does. A short attack ramp avoids the
    click that a hard start would produce, and the whole thing decays
    exponentially so it reads as "struck" rather than "beeped".
    """
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

        # Slight inharmonicity in the partials keeps it from sounding synthetic.
        sample = (
            math.sin(2 * math.pi * freq * t)
            + 0.34 * math.sin(2 * math.pi * freq * 2.01 * t)
            + 0.10 * math.sin(2 * math.pi * freq * 3.02 * t)
        )
        buf[idx] += sample * env * amp


def reverb(buf: list[float], taps=((0.055, 0.22), (0.098, 0.13),
                                   (0.157, 0.07))) -> None:
    """A few cheap delayed copies. Enough to lift it off the dry signal."""
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
        # Soft clip, then to 16-bit. tanh keeps the reverb tail from crackling
        # if the taps push a peak past full scale.
        v = math.tanh(value)
        frames += struct.pack("<h", int(v * 32767))

    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))


def build_normal() -> list[float]:
    """Rising minor third, quiet and quick. Reads as "something arrived"."""
    length = int(1.1 * RATE)
    buf = [0.0] * length

    tone(note("F#6"), 0.9, 0.55, 0.000, buf, decay=7.0)
    tone(note("A6"),  0.9, 0.45, 0.075, buf, decay=7.5)
    # A soft octave below fills it out without adding a third audible note.
    tone(note("F#5"), 0.9, 0.18, 0.000, buf, decay=5.5)

    reverb(buf)
    normalize(buf, 0.62)
    return buf


def build_critical() -> list[float]:
    """Falling pair, lower and longer. Same family, clearly more serious."""
    length = int(1.6 * RATE)
    buf = [0.0] * length

    tone(note("D5"),  1.3, 0.55, 0.000, buf, decay=4.2)
    tone(note("A#4"), 1.3, 0.50, 0.140, buf, decay=4.0)
    tone(note("D4"),  1.3, 0.22, 0.000, buf, decay=3.4)

    reverb(buf)
    normalize(buf, 0.78)
    return buf


def main() -> None:
    write_wav(OUT_DIR / "notify.wav", build_normal())
    write_wav(OUT_DIR / "critical.wav", build_critical())
    print(f"wrote {OUT_DIR}/notify.wav and critical.wav")


if __name__ == "__main__":
    main()
