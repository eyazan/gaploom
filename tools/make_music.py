#!/usr/bin/env python3
"""Procedural ambient music for GAPLOOM (one seamless loop per world).

Everything is synthesized here from sine/triangle partials — no samples, no third-party
material — so the tracks are project-owned. Run:  python3 tools/make_music.py
Writes assets/music/<world>.wav (22.05 kHz, mono, 16-bit). Deterministic (fixed seeds).
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "music")

NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def hz(name, octave):
    return 440.0 * 2 ** ((NOTE[name] + 12 * (octave + 1) - 69) / 12.0)


def env(n, attack, release, total):
    """Linear attack, flat, smooth release over `total` samples (n = length)."""
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return e


def pad(freqs, dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for f in freqs:
        for det in (-0.004, 0.0, 0.0045):          # gentle chorus
            ff = f * (1 + det)
            s += np.sin(2 * np.pi * ff * t) + 0.25 * np.sin(2 * np.pi * 2 * ff * t)
    s *= env(n, dur * 0.35, dur * 0.45, n)
    return s / (len(freqs) * 3.5) * amp


def pluck(f, dur, amp, bright=0.35):
    n = int(dur * SR)
    t = np.arange(n) / SR
    tone = np.sin(2 * np.pi * f * t) + bright * np.sin(2 * np.pi * 2 * f * t) + 0.12 * np.sin(2 * np.pi * 3 * f * t)
    return tone * np.exp(-t * 4.5) * env(n, 0.004, 0.05, n) * amp


def bell(f, dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    tone = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * 2.76 * f * t) + 0.25 * np.sin(2 * np.pi * 5.4 * f * t)
    return tone * np.exp(-t * 1.6) * env(n, 0.002, 0.2, n) * amp


def bass(f, dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * f * t) + 0.2 * np.sin(2 * np.pi * 2 * f * t)) * env(n, 0.08, dur * 0.5, n) * amp


def tick(dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    rng = np.random.default_rng(7)
    return rng.uniform(-1, 1, n) * np.exp(-t * 90) * amp + np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 60) * amp * 0.5


def add(buf, sig, start_s):
    """Add with wrap-around so the loop is seamless."""
    i = int(start_s * SR) % len(buf)
    end = i + len(sig)
    if end <= len(buf):
        buf[i:end] += sig
    else:
        k = len(buf) - i
        buf[i:] += sig[:k]
        rest = sig[k:]
        while len(rest) > 0:
            m = min(len(rest), len(buf))
            buf[:m] += rest[:m]
            rest = rest[m:]


WORLDS = {
    # name: (bpm, chords [(root, [notes with octave])], scale for melody, style)
    "lighthouse": (68, [("C", ["C4", "E4", "G4", "B4"]), ("A", ["A3", "C4", "E4", "G4"]),
                        ("F", ["F3", "A3", "C4", "E4"]), ("G", ["G3", "B3", "D4", "E4"])],
                   ["C5", "D5", "E5", "G5", "A5", "C6"], "plucks"),
    "railway": (84, [("D", ["D4", "F#4", "A4", "C5"]), ("G", ["G3", "B3", "D4", "F#4"]),
                     ("C", ["C4", "E4", "G4", "B4"]), ("A", ["A3", "C#4", "E4", "G4"])],
                ["D5", "E5", "F#5", "A5", "B5", "D6"], "eighths"),
    "greenhouse": (64, [("F", ["F3", "A3", "C4", "E4"]), ("G", ["G3", "B3", "D4", "F#4"]),
                        ("E", ["E3", "G3", "B3", "D4"]), ("A", ["A3", "C4", "E4", "G4"])],
                   ["E5", "F#5", "G5", "B5", "C6", "E6"], "bells"),
    "clocktower": (72, [("A", ["A3", "C4", "E4", "G4"]), ("F", ["F3", "A3", "C4", "E4"]),
                        ("D", ["D4", "F4", "A4", "C5"]), ("E", ["E3", "G#3", "B3", "D4"])],
                   ["A4", "C5", "D5", "E5", "G5", "A5"], "ticks"),
    "glassworks": (66, [("E", ["E3", "G#3", "B3", "D#4"]), ("C#", ["C#4", "E4", "G#4", "B4"]),
                        ("A", ["A3", "C#4", "E4", "G#4"]), ("B", ["B3", "D#4", "F#4", "A4"])],
                   ["E5", "F#5", "G#5", "B5", "C#6", "E6"], "bells"),
}


def parse(n):
    name = n[:-1]
    return hz(name, int(n[-1]))


def render(world, cfg, seed):
    bpm, chords, scale, style = cfg
    beat = 60.0 / bpm
    bar = beat * 4
    bars = 8                                    # two passes over the 4-chord progression
    total = bars * bar
    buf = np.zeros(int(total * SR))
    rng = np.random.default_rng(seed)
    for b in range(bars):
        root, notes = chords[b % len(chords)]
        t0 = b * bar
        add(buf, pad([parse(n) for n in notes], bar * 1.35, 0.55), t0)
        add(buf, bass(hz(root, 2), bar * 0.95, 0.35), t0)
        if style == "eighths":
            for k in range(8):
                if rng.random() < 0.7:
                    add(buf, pluck(parse(scale[rng.integers(len(scale))]), beat * 1.2, 0.16), t0 + k * beat / 2)
        elif style == "plucks":
            for k in range(4):
                if rng.random() < 0.75:
                    add(buf, pluck(parse(scale[rng.integers(len(scale))]), beat * 2.5, 0.18), t0 + k * beat + (beat / 2 if rng.random() < 0.3 else 0))
        elif style == "bells":
            for k in range(2):
                if rng.random() < 0.8:
                    add(buf, bell(parse(scale[rng.integers(len(scale))]), beat * 4, 0.12), t0 + k * 2 * beat + rng.random() * 0.2)
        elif style == "ticks":
            for k in range(4):
                add(buf, tick(0.08, 0.05 if k % 2 else 0.08), t0 + k * beat)
                if rng.random() < 0.5:
                    add(buf, pluck(parse(scale[rng.integers(len(scale))]), beat * 2.0, 0.14, bright=0.2), t0 + k * beat + beat / 2)
    # gentle limiter + normalisation to -3 dBFS peak
    buf = np.tanh(buf * 1.2)
    buf *= 0.7 / max(1e-6, np.max(np.abs(buf)))
    return buf, total


def write(path, buf):
    data = (np.clip(buf, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, (world, cfg) in enumerate(WORLDS.items()):
        buf, total = render(world, cfg, 1000 + i)
        # seam check: wrap-around rendering means the first and last samples are continuous
        seam = abs(buf[0] - buf[-1])
        write(os.path.join(OUT, world + ".wav"), buf)
        print("%-11s %5.1fs  peak=%.2f  seam_jump=%.4f" % (world, total, np.max(np.abs(buf)), seam))
