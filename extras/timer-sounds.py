#!/usr/bin/env python3
"""Synthesise the timer's sound set.

Six alarm voices plus the two utility ticks the countdown makes on its own.
Everything is additive synthesis over a decaying envelope: partials chosen so
the result reads as a struck object (bell, bar, glass) rather than a beep.
Written as 48 kHz mono 16-bit wav, which is what pw-play wants anyway.
"""

import math
import os
import struct
import wave

RATE = 48000
OUT = os.path.expanduser("~/.local/share/sounds/f/timer")

def env(t, dur, attack=0.004, decay=None, curve=3.0):
    """Percussive envelope: near-instant attack, exponential tail."""
    if t < attack:
        return t / attack
    d = decay if decay is not None else dur - attack
    x = (t - attack) / d
    if x >= 1:
        return 0.0
    return math.exp(-curve * x) * (1 - x)

def strike(buf, at, freq, dur, gain, partials, detune=0.0, curve=3.0):
    """Add one struck note at `at` seconds."""
    start = int(at * RATE)
    n = int(dur * RATE)
    for i in range(n):
        t = i / RATE
        e = env(t, dur, curve=curve)
        if e <= 0:
            break
        s = 0.0
        for mult, amp, decay_mult in partials:
            f = freq * mult * (1 + detune * mult * 0.001)
            pe = math.exp(-curve * decay_mult * (t / dur))
            s += amp * pe * math.sin(2 * math.pi * f * t)
        j = start + i
        if j < len(buf):
            buf[j] += s * e * gain

def noise_tick(buf, at, dur, gain, freq):
    """A short filtered click — the body of a tick, not a tone."""
    import random

    rnd = random.Random(7)
    start = int(at * RATE)
    n = int(dur * RATE)
    prev = 0.0
    for i in range(n):
        t = i / RATE
        e = env(t, dur, attack=0.0008, curve=9.0)
        white = rnd.uniform(-1, 1)
        prev = prev * 0.6 + white * 0.4
        s = prev * 0.5 + math.sin(2 * math.pi * freq * t) * 0.5
        j = start + i
        if j < len(buf):
            buf[j] += s * e * gain

def write(name, buf, tail=0.05):
    peak = max(1e-6, max(abs(x) for x in buf))
    scale = 0.89 / peak
    n = len(buf)
    fade = int(tail * RATE)
    frames = bytearray()
    for i, x in enumerate(buf):
        v = x * scale
        if i > n - fade:
            v *= (n - i) / fade
        v = max(-1.0, min(1.0, v))
        frames += struct.pack("<h", int(v * 32767))
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))
    print(path, "%.2fs" % (n / RATE))

def blank(seconds):
    return [0.0] * int(seconds * RATE)

BELL = [(1.0, 1.0, 0.6), (2.0, 0.45, 1.0), (2.76, 0.30, 1.4),
        (5.40, 0.16, 2.2), (8.93, 0.08, 3.2)]
GLASS = [(1.0, 1.0, 0.7), (3.0, 0.34, 1.3), (5.9, 0.18, 2.0), (9.2, 0.07, 3.0)]
MARIMBA = [(1.0, 1.0, 0.8), (3.9, 0.28, 1.9), (10.2, 0.06, 3.4)]
SOFT = [(1.0, 1.0, 0.7), (2.0, 0.22, 1.2), (3.0, 0.08, 1.8)]

os.makedirs(OUT, exist_ok=True)

buf = blank(2.6)
for k, (f, at) in enumerate([(659.26, 0.00), (783.99, 0.16), (1046.50, 0.32)]):
    strike(buf, at, f, 2.2, 0.55 - k * 0.05, BELL, curve=2.4)
strike(buf, 0.32, 523.25, 2.2, 0.22, BELL, curve=2.2)
write("chime", buf)

buf = blank(3.4)
for k, at in enumerate([0.0, 0.9, 1.8]):
    strike(buf, at, 587.33, 1.6, 0.62 - k * 0.08, BELL, curve=2.0)
    strike(buf, at, 880.00, 1.4, 0.20, BELL, curve=2.6)
write("bell", buf)

buf = blank(4.2)
strike(buf, 0.0, 146.83, 4.0, 0.7,
       [(1.0, 1.0, 0.4), (1.5, 0.5, 0.7), (2.4, 0.4, 1.0),
        (3.7, 0.25, 1.5), (5.1, 0.12, 2.2), (7.3, 0.06, 3.0)],
       curve=1.5)
strike(buf, 0.02, 220.0, 3.6, 0.22, BELL, curve=1.8)
write("gong", buf)

buf = blank(2.4)
for k, f in enumerate([523.25, 659.26, 783.99, 1046.50]):
    strike(buf, k * 0.11, f, 1.6, 0.5, GLASS, curve=2.8)
for k, f in enumerate([1046.50, 783.99, 659.26]):
    strike(buf, 0.62 + k * 0.11, f, 1.4, 0.34, GLASS, curve=3.0)
write("arp", buf)

buf = blank(2.2)
for at, f in [(0.0, 440.0), (0.14, 523.25), (0.28, 659.26),
              (0.52, 523.25), (0.66, 659.26), (0.80, 880.0)]:
    strike(buf, at, f, 1.1, 0.5, MARIMBA, curve=3.4)
write("wood", buf)

buf = blank(4.0)
for k, f in enumerate([392.0, 493.88, 587.33, 783.99]):
    at = k * 0.28
    n = int(3.2 * RATE)
    start = int(at * RATE)
    for i in range(n):
        t = i / RATE
        a = min(1.0, t / 0.5)
        e = a * math.exp(-1.1 * (t / 3.2)) * (1 - t / 3.2)
        if e <= 0:
            break
        s = math.sin(2 * math.pi * f * t)
        s += 0.18 * math.sin(2 * math.pi * f * 2 * t)
        s += 0.06 * math.sin(2 * math.pi * f * 3 * t)
        s *= 1 + 0.02 * math.sin(2 * math.pi * 5.5 * t)
        j = start + i
        if j < len(buf):
            buf[j] += s * e * (0.42 - k * 0.04)
write("dawn", buf)

buf = blank(0.09)
noise_tick(buf, 0.0, 0.06, 0.7, 2100)
write("tick", buf, tail=0.02)

buf = blank(1.2)
strike(buf, 0.0, 880.0, 1.0, 0.45, SOFT, curve=3.0)
strike(buf, 0.09, 1174.66, 0.9, 0.25, SOFT, curve=3.4)
write("half", buf, tail=0.06)
