#!/usr/bin/env python3
"""Genera los efectos de sonido del juego con síntesis sencilla (solo numpy).

Todos los sonidos son propios: no hay licencias de terceros. Uso:
    python3 tools/generate_sounds.py
Escribe archivos .wav (mono, 16 bits, 22 050 Hz) en assets/audio/sfx/.
La semilla es fija, así que el resultado es siempre el mismo.
"""
import os
import wave

import numpy as np

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")
rng = np.random.default_rng(2511)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def env(n, attack=0.005, release=None):
    """Envolvente: subida corta y caída exponencial."""
    x = np.arange(n) / RATE
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    rel = release if release else n / RATE
    return a * np.exp(-x / (rel / 4))


def tone(freq, seconds, harmonics=(1.0,), release=None):
    x = t(seconds)
    s = sum(amp * np.sin(2 * np.pi * freq * (i + 1) * x) for i, amp in enumerate(harmonics))
    return s * env(len(x), release=release)


def bell(freq, seconds=0.6):
    # Campana: parciales inarmónicos que se apagan a distinto ritmo.
    x = t(seconds)
    parts = [(1.0, 1.0, 1.0), (2.0, 0.5, 0.7), (2.76, 0.35, 0.5), (5.4, 0.15, 0.3)]
    s = sum(a * np.sin(2 * np.pi * freq * r * x) * np.exp(-x / (seconds * d / 3)) for r, a, d in parts)
    return s * np.clip(x / 0.002, 0, 1)


def noise(seconds):
    return rng.uniform(-1, 1, int(RATE * seconds))


def lowpass(x, strength):
    """Filtro paso bajo de un polo (0 < strength < 1, más alto = más suave)."""
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = acc * strength + v * (1 - strength)
        y[i] = acc
    return y


def sweep(f0, f1, seconds, release=None):
    x = t(seconds)
    freq = np.linspace(f0, f1, len(x))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    return np.sin(phase) * env(len(x), release=release)


def seq(*parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap:
            out.append(np.zeros(int(RATE * gap)))
    return np.concatenate(out)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def at(sound, seconds, total):
    out = np.zeros(int(RATE * total))
    start = int(RATE * seconds)
    end = min(len(out), start + len(sound))
    out[start:end] += sound[: end - start]
    return out


def save(name, data, volume=0.8):
    data = data / max(np.max(np.abs(data)), 1e-6) * volume
    pcm = (data * 32767).astype(np.int16)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    print("  ", name, f"{len(data) / RATE:.2f} s")


def main():
    os.makedirs(OUT, exist_ok=True)
    print("Generando sonidos en", os.path.normpath(OUT))
    # Coger: "pop" corto hacia arriba.
    save("pick", sweep(300, 700, 0.08, release=0.08), 0.6)
    # Lanzar: soplido de ruido filtrado que sube y baja.
    w = lowpass(noise(0.3), 0.85) * np.sin(np.linspace(0, np.pi, int(RATE * 0.3)))
    save("throw", w, 0.5)
    # Soltar: "pop" hacia abajo.
    save("drop", sweep(500, 250, 0.08, release=0.08), 0.5)
    # Botón o palanca: clic seco.
    save("click", mix(tone(1800, 0.03, release=0.02), lowpass(noise(0.02), 0.3) * 0.5), 0.5)
    # Material del dispensador: "plop" de madera.
    save("wood", mix(tone(220, 0.15, (1, 0.3, 0.2), release=0.1), lowpass(noise(0.05), 0.6) * 0.4), 0.7)
    # Fábrica trabajando: traqueteo.
    clack = mix(tone(140, 0.06, (1, 0.5), release=0.05), lowpass(noise(0.04), 0.5) * 0.6)
    save("machine", seq(clack, clack * 0.8, clack, gap=0.09), 0.6)
    # Algo listo (juguete o regalo): "ding".
    save("ding", bell(1320, 0.7), 0.6)
    # Envolver: papel arrugándose.
    crinkle = noise(0.25) * (rng.uniform(0, 1, int(RATE * 0.25)) > 0.7)
    save("wrap", lowpass(crinkle, 0.4) * env(int(RATE * 0.25), release=0.25), 0.6)
    # Saco: campanita y monedas.
    save("sack", mix(bell(1568, 0.5), at(bell(2093, 0.5), 0.08, 0.6)), 0.6)
    # Monedas (comprar mejora).
    save("coin", seq(tone(1976, 0.07, (1, 0.3)), tone(2637, 0.25, (1, 0.3), release=0.25)), 0.5)
    # Escupir: "boing".
    x = t(0.35)
    boing = np.sin(2 * np.pi * (180 + 60 * np.sin(2 * np.pi * 9 * x)) * x) * env(len(x), release=0.35)
    save("boing", boing, 0.6)
    # Empujón: golpe sordo más un "uf".
    save("push", mix(lowpass(noise(0.12), 0.8) * env(int(RATE * 0.12), release=0.1), sweep(260, 120, 0.18) * 0.7), 0.8)
    # Bola de nieve: crujido suave.
    save("snow", lowpass(noise(0.3), 0.55) * env(int(RATE * 0.3), release=0.25), 0.7)
    # Chimenea: silbido que baja y "ding".
    save("chimney", mix(sweep(1400, 500, 0.35) * 0.5, at(bell(1047, 0.6), 0.3, 0.9)), 0.6)
    # Casa servida: dos campanas alegres.
    save("house_done", mix(bell(1319, 0.6), at(bell(1760, 0.8), 0.12, 0.9)), 0.6)
    # Trineo llegando: cascabeles.
    shake = np.zeros(int(RATE * 1.6))
    for i in range(14):
        jingle = bell(rng.uniform(2600, 3400), 0.25) * rng.uniform(0.4, 1.0)
        shake += at(jingle, i * 0.1 + rng.uniform(0, 0.03), 1.6)
    save("sleigh", shake, 0.6)
    # Empieza la noche: arpegio (do, mi, sol, do).
    notes = [523, 659, 784, 1047]
    save("night_start", mix(*[at(tone(f, 0.5, (1, 0.4, 0.2), release=0.45), i * 0.12, 1.0) for i, f in enumerate(notes)]), 0.6)
    # Resultados: acorde.
    save("results", mix(*[tone(f, 1.2, (1, 0.3), release=1.1) for f in (523, 659, 784)]), 0.6)
    # Últimos segundos: tic.
    save("tick", tone(1000, 0.05, release=0.04), 0.4)


if __name__ == "__main__":
    main()
