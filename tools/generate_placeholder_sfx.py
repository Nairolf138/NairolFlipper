#!/usr/bin/env python3
"""Generate small original placeholder SFX without external samples."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
OUTPUT_DIR = Path(__file__).parents[1] / "assets" / "audio" / "sfx"


def write_sound(name: str, duration: float, sample_fn) -> None:
    frames = bytearray()
    sample_count = int(duration * SAMPLE_RATE)
    for index in range(sample_count):
        time = index / SAMPLE_RATE
        value = max(-1.0, min(1.0, sample_fn(time, duration)))
        frames.extend(struct.pack("<h", int(value * 32767)))

    with wave.open(str(OUTPUT_DIR / f"{name}.wav"), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(frames)


def sine(phase: float) -> float:
    return math.sin(phase * math.tau)


def chirp(time: float, start_hz: float, end_hz: float, duration: float) -> float:
    slope = (end_hz - start_hz) / duration
    return sine(start_hz * time + 0.5 * slope * time * time)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rng = random.Random(13_804)

    write_sound(
        "flipper",
        0.07,
        lambda t, d: (0.72 * sine(170 * t) + 0.28 * rng.uniform(-1, 1)) * math.exp(-55 * t),
    )
    write_sound(
        "launcher",
        0.20,
        lambda t, d: 0.7 * chirp(t, 130, 720, d) * math.sin(math.pi * t / d),
    )
    write_sound(
        "kick_bumper",
        0.16,
        lambda t, d: 0.82 * chirp(t, 120, 48, d) * math.exp(-18 * t),
    )
    write_sound(
        "snare_bumper",
        0.13,
        lambda t, d: (0.58 * rng.uniform(-1, 1) + 0.2 * sine(190 * t)) * math.exp(-24 * t),
    )
    write_sound(
        "tom_bumper",
        0.19,
        lambda t, d: 0.78 * chirp(t, 230, 92, d) * math.exp(-13 * t),
    )
    write_sound(
        "ramp",
        0.24,
        lambda t, d: 0.58 * chirp(t, 300, 920, d) * math.sin(math.pi * t / d),
    )
    write_sound(
        "scoop",
        0.28,
        lambda t, d: 0.5 * sine((330 if t < d / 2 else 495) * t) * math.sin(math.pi * t / d),
    )
    write_sound(
        "cue",
        0.36,
        lambda t, d: 0.42
        * sine((440 if t < d / 3 else 554 if t < 2 * d / 3 else 659) * t)
        * math.sin(math.pi * t / d),
    )
    write_sound(
        "safety",
        0.30,
        lambda t, d: 0.5 * chirp(t, 420, 840, d) * math.sin(math.pi * t / d),
    )
    write_sound(
        "drain",
        0.38,
        lambda t, d: 0.62 * chirp(t, 300, 58, d) * math.exp(-4 * t),
    )


if __name__ == "__main__":
    main()
