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

## Bromas (Fase 7)

- `Pranks` (nodo `Game/Pranks`) concentra las reglas y solo actúa en el anfitrión: alcance 2,3 m,
  recarga del empujón 1,5 s e inmunidad 2 s para quien recibe un golpe (no se encadenan).
- El jugador pide el empujón con el RPC `Player.request_push_player` / `request_push_item`. El
  anfitrión comprueba la distancia con `latest_position()`, suelta lo que lleva el objetivo y le
  manda `receive_hit` a su dueño, porque cada elfo se simula en el PC de su jugador. `receive_hit`
  solo se acepta si viene del anfitrión. Durante 0,35 s el elfo apenas frena (`KNOCKBACK_ACCEL`),
  para que se note el empujón.
- Bola de nieve: `Carryable` con monitor de contactos. Solo hace daño si se soltó a ≥5 m/s (se lanzó)
  y se deshace en el primer choque. Al dar a un elfo que no es quien la lanzó llama a `server_hit`.
- El montón de nieve reutiliza `material_bin.gd` con la escena de la bola (máximo 8 sueltas).
- La palanca invierte la cinta con `Conveyor.server_reverse(segundos)`, que se avisa a todos por RPC.
- El HUD muestra escarcha (`Frost`) al recibir la señal `Player.hit_received`.

## Reparto (Fase 8)

- `WorkshopState` añade `night`, `delivering`, `sleigh_gifts` y `delivered` (sincronizados) y la
  señal `announced(text)` para los avisos grandes del HUD (por RPC desde el anfitrión).
- En el anfitrión, `goal_reached` llama (diferido) a `server_start_delivery()`: los regalos del saco
  pasan a `sleigh_gifts` y el trineo (`sleigh.gd`) se hace visible y usable.
- El trineo crea un regalo nuevo en las manos de quien lo usa y lo marca `from_sleigh` (solo en el
  anfitrión). El saco escupe esos regalos para que no se cobren dos veces.
- Cada casa (`house.gd`, grupo "house") tiene `wanted` y `received` (sincronizado). La chimenea es un
  Area3D grande sobre el tiro; cuenta en `body_entered` además del escaneo, porque un regalo lanzado
  la cruza en menos de un escaneo (0,15 s).
- `Game.server_check_delivery()` termina la noche cuando todas las casas están servidas: reinicia
  las casas, `server_finish_night()` devuelve al saco lo que sobre en el trineo y sube `night`.
- La suma de `wanted` de las casas es igual al objetivo del saco (10). Si se cambia uno, hay que
  cambiar el otro (la Fase 9 lo hará automático por noche).

## Ciclo de noches (Fase 9)

- `WorkshopState.phase` (LOBBY, PRODUCTION, DELIVERY, RESULTS, FINISHED) y `seconds_left` se
  sincronizan; el reloj real (`_time_left`) solo existe en el anfitrión, que lo baja en `_process` y
  cambia de fase al llegar a cero. `seconds_left` cambia una vez por segundo, así que la red no se
  satura.
- `server_start_night()` fija `goal = goal_for(night, jugadores)`. Las casas calculan su parte con
  `house_index` en todos los PCs, sin sincronizar nada más.
- Al llenarse el saco solo empieza el reparto en PRODUCTION. En la espera el saco cuenta, pero no
  trae el trineo.
- `server_end_delivery()` arma un diccionario de resultados y lo envía por RPC (`results_ready`).
  Ojo: ese RPC puede llegar a un cliente antes que el cambio de fase sincronizado, por eso el HUD
  solo cierra los resultados al **cambiar** a LOBBY o PRODUCTION.
- El récord se guarda en `user://records.cfg` del anfitrión (`record_path`; los tests usan otro
  archivo).

## Sonido y ambiente (Fase 10)

- `Sfx` (autoload) carga los .wav de `assets/audio/sfx/`. `play()` suena solo en este PC;
  `broadcast()` (solo el anfitrión) usa un RPC del autoload, que tiene la misma ruta en todos.
  Los reproductores se borran con un temporizador y no con `finished`, porque sin tarjeta de
  sonido (tests) `finished` puede no llegar.
- Sonidos ligados a cambios que ya se sincronizan (coger un objeto, compras, resultados) suenan
  en cada PC sin RPC extra; los de las estaciones y bromas los manda el anfitrión.
- Guirnaldas: un MultiMesh por color (pocas llamadas de dibujo). Nieve: CPUParticles3D sin sombras.
- Animación de bromas: `Player.play_prank_anim` (RPC any_peer, solo se acepta del anfitrión).
- Ojo con las carreras en red: un RPC fiable puede llegar antes que el cambio sincronizado
  del mismo instante. Los tests de red esperan a la condición en vez de comprobarla de golpe.

## Gráficos

- Shaders en `shaders/`, sin texturas: `wood_planks` calcula los tablones con la posición en el
  mundo (no hace falta UV) y suaviza juntas y veta a lo lejos para evitar dibujos raros; con
  `object_space` van pegados al objeto (madera que se mueve). `snow` y `night_sky` comparten el
  ruido de `noise.gdshaderinc`. Los materiales listos están en `materials/`.
- Decorado montado por código con `MeshKit` (cajas, cilindros...): `workshop_building.gd`,
  `scenery.gd`, `lantern.gd` y los `*_look.gd` (casa, trineo, estaciones, objetos). Son `@tool`,
  así que se ven en el editor. Solo son visuales: las colisiones siguen en las escenas.
- `house_look.gd` expone `window_material`, que `house.gd` enciende al servir la casa.
- Los regalos y coches eligen color con el hash del nombre del nodo, que es igual en todos los PC.
- Elfo: `ElfModel` carga `character-soldier.glb` (Kenney, CC0), quita los triángulos del penacho
  y la cresta (por altura y por zona de la paleta), recolorea la paleta por jugador y cuelga gorro
  y orejas de un `BoneAttachment3D` en el hueso `head`. La animación se elige con la velocidad
  real del elfo, así funciona igual para el propio y para los de los demás sin sincronizar nada.
- El elfo propio va en la capa 2 (tu cámara no la dibuja) y sin sombra.

## Tests

`tests/run_tests.tscn` es una escena y no un script `-s` porque los scripts `-s` se compilan
antes de cargar los autoloads, y `Settings` no existiría.
