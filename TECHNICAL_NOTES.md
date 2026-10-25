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

## Multijugador

**Modelo:** anfitrión autoritativo con la API de alto nivel de Godot. El anfitrión es el peer 1.
Transporte actual: `ENetMultiplayerPeer`, puerto UDP 24680. "Jugar solo" usa
`OfflineMultiplayerPeer`, así que el modo solo ejecuta exactamente el mismo código.

**Escenas:**
- `Main` (raíz) tiene `Level` y un `LevelSpawner`. Solo el anfitrión instancia `Game` bajo `Level`;
  el spawner la replica en los clientes en orden, antes que lo que hay dentro. Así se evita el
  error clásico de "nodo no encontrado" cuando el cliente aún no ha cargado la escena.
- `Game` tiene `PlayerSpawner` (con `spawn_function` que recibe `{id, name, color}`) e
  `ItemSpawner` (vigila `TestZone/Items`).
- Los objetos colocados a mano en el nivel se sustituyen al arrancar por copias creadas por el
  anfitrión (los clientes borran los suyos). Así el spawner los conoce y los envía a quien entre
  más tarde.

**Quién decide qué:**

| Cosa | Autoridad | Cómo llega a los demás |
|---|---|---|
| Movimiento y cámara de cada elfo | Su jugador | `MultiplayerSynchronizer` (30 Hz, sin fiabilidad), suavizado en el resto |
| Quién lleva un objeto (`holder_peer`) | Anfitrión | Synchronizer "on change" (fiable) |
| Posición de objetos sueltos | Anfitrión (única física real) | Synchronizer 20 Hz, suavizado en clientes |
| Objeto en las manos | Cada PC lo coloca en las manos del elfo que lo lleva | (no se envía: sale de holder_peer + posición del elfo) |
| Usar botones/máquinas | Anfitrión (señal `used` solo allí) | Efectos con RPC `call_local` |
| Lista de jugadores | Anfitrión | RPC fiable `_sync_players` |

**Validaciones del anfitrión:** distancia máxima 4 m para coger/usar (con la última posición
recibida, `Player.latest_position()`), un objeto un portador, un jugador un objeto, velocidad de
lanzamiento máxima 20 m/s.

**Desconexiones:** si sale un cliente, el anfitrión suelta lo que llevaba y borra su elfo (el
spawner lo borra en los demás). Si sale el anfitrión, los clientes reciben `server_disconnected`
y vuelven al menú. Sin migración de anfitrión.

**Lección aprendida:** una petición fiable (RPC) puede llegar antes que la última posición
(sincronización no fiable). Por eso las distancias se validan con la última posición recibida y
no con la suavizada.

**Siguiente paso de red:** GodotSteam. Solo cambiará `Network.host()` / `join()` (crear lobby,
unirse por invitación, `SteamMultiplayerPeer`). El resto del juego no sabe qué transporte hay.

## Cadena de producción (Fase 5)

- `Station` (hereda de `Interactable`) es la base de todas las estaciones. Solo en el anfitrión,
  cada 0,15 s mira qué objetos libres hay en sus `Area3D` (`server_scan`) y cada frame avanza
  su trabajo (`server_tick`). Se usa sondeo y no `body_entered` porque un objeto soltado dentro
  de la zona no vuelve a disparar la señal.
- Un objeto se gasta con `Carryable.server_consume()`: falla si ya estaba gastado o alguien lo
  lleva. Es la única forma de que algo desaparezca en una estación, así un regalo no cuenta dos
  veces aunque toque el saco varios frames.
- Lo que deben ver todos se sincroniza en cada estación (`status_text`, `queued`, `working`,
  `has_toy`, `wrap_progress`). El porcentaje de la fábrica va de 10 en 10 para no mandar un
  mensaje por frame.
- `WorkshopState` (nodo `Game/State`) guarda regalos en el saco y objetivo; lo cambia solo el
  anfitrión. HUD y saco escuchan su señal `changed`.
- `Game.spawn_item()` crea objetos en el nodo que vigila el `ItemSpawner`.

## Progresión (Fase 6)

- `Upgrades` (scripts/game/upgrades.gd) es solo datos: nombre, precios por nivel y efecto.
- `WorkshopState` guarda `money`, `total_earned` y `upgrade_levels` (PackedInt32Array, se
  reasigna entera al cambiar para que el synchronizer lo detecte). `server_buy()` es la única
  forma de gastar dinero; anuncia la compra a todos con un RPC.
- Cada sistema aplica sus mejoras al cambiar el estado (`Station.on_state_changed`): la fábrica
  recalcula tiempo, cola y color; la mesa activa el modo automático; la cinta se muestra y activa
  su colisión; `Game` ajusta `speed_multiplier` de los elfos.
- La cinta empuja en el anfitrión los objetos libres que tiene encima y, al final, los coloca
  sobre la mesa (marcador `Workshop/TableDrop`). Con cinta, la fábrica escupe más despacio para
  que el juguete caiga encima.

## Tests

`tests/run_tests.tscn` es una escena y no un script `-s` porque los scripts `-s` se compilan
antes de cargar los autoloads, y `Settings` no existiría.
