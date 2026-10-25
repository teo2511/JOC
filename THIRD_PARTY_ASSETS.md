# Recursos de terceros

Cada recurso externo se registra aquí antes de usarlo, con su licencia comprobada.

| Recurso | Origen | Licencia | Uso en el juego |
|---|---|---|---|
| Godot Engine 4.6 | https://godotengine.org | MIT | Motor. Requiere incluir su aviso de licencia en los créditos del juego publicado |
| Kenney, pack "Mini Arena" 1.0: `character-soldier.glb` y su `colormap.png` | Incluido en https://github.com/KenneyNL/Starter-Kit-Basic-Scene (carpeta `sample/Mini Arena`), descargado el 25-oct-2026 | CC0 (ver `assets/models/kenney/mini_arena/License.txt`) | Base de los elfos (`scripts/player/elf_model.gd`): se le quita el penacho, se recolorea la paleta y se le añaden gorro y orejas. Crédito a Kenney opcional, pero lo pondremos |

El resto de modelos (taller, casas, trineo, estaciones, objetos, árboles) y los materiales
están hechos en el propio proyecto: piezas básicas de Godot montadas por código
(`scripts/props/*_look.gd`, `workshop_building.gd`, `scenery.gd`) y shaders propios en
`shaders/` (tablones de madera, ladrillo, nieve y cielo, sin texturas).

Los efectos de sonido (`assets/audio/sfx/*.wav`) también son propios: los genera
`tools/generate_sounds.py` con síntesis sencilla (numpy), sin muestras de terceros. No hay
música todavía.

## Versión de Roblox (`roblox/`)

No usa recursos de terceros: todo el mapa son piezas de Roblox creadas por código, con los
materiales que trae Roblox (madera, nieve, pizarra...). La nieve que cae usa una textura que
viene con Roblox (`rbxasset://textures/particles/sparkles_main.dds`).

Herramientas de desarrollo (no van dentro del juego): Rojo 7.4.4 (MPL-2.0,
https://github.com/rojo-rbx/rojo), Luau 0.650 (MIT, https://github.com/luau-lang/luau) y
luau-lsp 1.70.1 (MIT, https://github.com/JohnnyMorganz/luau-lsp).

## Fuentes previstas

- Kenney (https://kenney.nl): CC0. Desde el entorno de desarrollo en la nube solo se puede
  descargar lo que Kenney publica en GitHub; kenney.nl está bloqueado. El "Holiday Kit"
  (CC0) quedaría muy bien si teo lo descarga a mano.
- Quaternius (https://quaternius.com): CC0. Bloqueado igual desde la nube.
- Freesound: solo sonidos CC0, o CC-BY anotando el autor aquí.
- GodotSteam (Fase 4): MIT. Steamworks SDK: acuerdo de Valve.
