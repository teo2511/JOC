# Notas técnicas

## Motor y configuración

- Godot 4.6 (probado con 4.6.3 stable). Renderer Forward+. Física **Jolt** (por defecto en 4.6).
- 60 ticks de física por segundo.
- Capas de colisión: 1 `mundo`, 2 `jugadores`, 3 `objetos`, 4 `interactuables`.
- Capa visual 2 = cuerpo del propio elfo; la cámara del jugador no la dibuja, así no ves tu
  propio cuerpo por dentro. Los demás jugadores sí lo verán.

## Controles

Las acciones de entrada (`move_forward`, `interact`, `throw`...) se crean en tiempo de ejecución
desde `scripts/autoload/settings.gd` y no en `project.godot`. Así los controles por defecto y los
cambiados por el jugador pasan por el mismo código, y se guardan en `user://settings.cfg`.
Las teclas usan `physical_keycode` (WASD funciona igual en cualquier distribución de teclado).

## Objetos transportables (`Carryable`)

- `RigidBody3D`. Mientras alguien lo lleva queda congelado en modo cinemático y sigue el
  `HoldPoint` de la cámara con interpolación.
- `try_pick()` falla si ya tiene portador: es la regla que en red aplicará el anfitrión para que
  dos jugadores no cojan el mismo objeto.
- Al soltarlo o lanzarlo hereda la velocidad del elfo. Se ignora la colisión con quien lo
  llevaba durante 0,3 s para que no choque con él al salir.
- Limitación conocida: un objeto en las manos puede atravesar paredes visualmente si te pegas a
  ellas. Se revisará si molesta en las pruebas.

## Objetos usables (`Interactable`)

`StaticBody3D` con señal `used` y tiempo de espera. Base para máquinas, palancas y botones.

## Multijugador (plan para la Fase 4)

- Anfitrión autoritativo con la API de alto nivel de Godot. Transporte intercambiable:
  `ENetMultiplayerPeer` en desarrollo, `SteamMultiplayerPeer` de GodotSteam para Steam.
- Cada elfo mueve su propio cuerpo (autoridad del cliente sobre su movimiento) y el anfitrión
  decide todo lo demás: objetos, máquinas, dinero, saco, temporizadores.
- Si se va el anfitrión, la partida termina (sin migración de anfitrión). El progreso se guarda
  al final de cada Noche en el PC del anfitrión.

## Tests

`tests/run_tests.tscn` es una escena y no un script `-s` porque los scripts `-s` se compilan
antes de cargar los autoloads, y `Settings` no existiría.
