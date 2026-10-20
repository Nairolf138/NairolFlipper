#!/usr/bin/env python3
"""Generate an original eight-stem electronic loop without external samples."""

from __future__ import annotations

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path


SAMPLE_RATE = 22_050
BPM = 120.0
BEATS = 16
DURATION = BEATS * 60.0 / BPM
OUTPUT_DIR = Path(__file__).parents[1] / "assets" / "audio" / "music"
TAU = math.tau


def sine(hz: float, time: float) -> float:
    return math.sin(TAU * hz * time)


def beat_phase(time: float, division: float = 1.0) -> tuple[int, float]:
    position = time * BPM / 60.0 / division
    return int(position), position % 1.0


def tone(hz: float, time: float) -> float:
    return sine(hz, time) + 0.22 * sine(hz * 2.0, time) + 0.08 * sine(hz * 3.0, time)


def atmosphere(time: float, _rng: random.Random) -> float:
    breathe = 0.72 + 0.28 * sine(0.125, time)
    return 0.13 * breathe * (sine(73.5, time) + 0.55 * sine(110.0, time) + 0.35 * sine(146.8, time))


def piano(time: float, _rng: random.Random) -> float:
    notes = (293.66, 349.23, 440.0, 261.63, 293.66, 392.0, 440.0, 349.23)
    step, phase = beat_phase(time, 2.0)
    envelope = math.exp(-5.8 * phase)
    return 0.28 * tone(notes[step % len(notes)], time) * envelope


def kick(time: float, _rng: random.Random) -> float:
    beat, phase = beat_phase(time)
    if beat % 4 not in (0, 2):
        return 0.0
    envelope = math.exp(-12.0 * phase)
    frequency = 48.0 + 95.0 * math.exp(-18.0 * phase)
    return 0.62 * sine(frequency, time) * envelope


def percussion(time: float, rng: random.Random) -> float:
    step, phase = beat_phase(time, 0.5)
    envelope = math.exp(-24.0 * phase)
    accent = 0.28 if step % 4 == 2 else 0.13
    return accent * rng.uniform(-1.0, 1.0) * envelope


def bass(time: float, _rng: random.Random) -> float:
    notes = (73.42, 73.42, 87.31, 65.41)
    step, phase = beat_phase(time, 4.0)
    envelope = min(1.0, phase * 10.0) * min(1.0, (1.0 - phase) * 8.0)
    hz = notes[step % len(notes)]
    return 0.31 * (sine(hz, time) + 0.28 * sine(hz * 2.0, time)) * envelope


def arp(time: float, _rng: random.Random) -> float:
    notes = (293.66, 349.23, 440.0, 523.25, 440.0, 349.23, 293.66, 261.63)
    step, phase = beat_phase(time, 0.5)
    envelope = math.exp(-5.0 * phase)
    return 0.16 * tone(notes[step % len(notes)], time) * envelope


def lead(time: float, _rng: random.Random) -> float:
    beat = time * BPM / 60.0
    if beat < 8.0:
        return 0.0
    notes = (587.33, 698.46, 880.0, 783.99)
    step, phase = beat_phase(time - 4.0, 2.0)
    envelope = math.sin(math.pi * min(phase, 1.0)) ** 1.5
    vibrato = 1.0 + 0.008 * sine(5.0, time)
    return 0.19 * tone(notes[step % len(notes)] * vibrato, time) * envelope


def impact(time: float, rng: random.Random) -> float:
    beat, phase = beat_phase(time, 8.0)
    if beat > 1:
        return 0.0
    envelope = math.exp(-7.0 * phase)
    return envelope * (0.38 * sine(52.0 + 48.0 * math.exp(-12.0 * phase), time) + 0.08 * rng.uniform(-1.0, 1.0))


STEMS = {
    "atmosphere": atmosphere,
    "piano": piano,
    "kick": kick,
    "percussion": percussion,
    "bass": bass,
    "arp": arp,
    "lead": lead,
    "impact": impact,
}


def render_wav(path: Path, generator, seed: int) -> None:
    rng = random.Random(seed)
    frames = bytearray()
    for index in range(int(DURATION * SAMPLE_RATE)):
        time = index / SAMPLE_RATE
        edge_fade = min(1.0, time * 40.0, (DURATION - time) * 40.0)
        value = max(-1.0, min(1.0, generator(time, rng) * edge_fade))
        frames.extend(struct.pack("<h", int(value * 32767)))
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(frames)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="nairolflipper-music-") as temp_dir:
        for index, (name, generator) in enumerate(STEMS.items()):
            wav_path = Path(temp_dir) / f"{name}.wav"
            render_wav(wav_path, generator, 13_804 + index)
            subprocess.run(
                [
                    "ffmpeg",
                    "-loglevel",
                    "error",
                    "-y",
                    "-i",
                    str(wav_path),
                    "-c:a",
                    "libvorbis",
                    "-q:a",
                    "3",
                    str(OUTPUT_DIR / f"{name}.ogg"),
                ],
                check=True,
            )


if __name__ == "__main__":
    main()
