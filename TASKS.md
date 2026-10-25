# Tareas

Estados: **Hecho** (implementado y probado), **Implementado** (falta probarlo a mano),
**Pendiente**. Ver TESTING.md para el detalle de las pruebas.

## Fase 2. Entorno

- [x] Proyecto Godot 4.6 con Jolt Physics, capas de colisión con nombre y carpetas. **Hecho**
- [x] Autoload `Settings` con controles, sensibilidad, invertir Y y volumen guardados en disco. **Hecho**
- [x] Tests automáticos sin pantalla (`tests/run_tests.tscn`). **Hecho**
- [x] Herramienta de capturas (`tools/screenshot.tscn`). **Hecho**
- [x] teo abre el proyecto en su PC con Windows y lo ejecuta. **Hecho**

## Fase 3. Movimiento e interacción

- [x] Elfo en primera persona: andar, saltar, cámara con ratón, límite de inclinación. **Implementado**
- [x] Coger, soltar y lanzar objetos (regalo, pelota). **Hecho** (tests automáticos)
- [x] Un objeto solo puede tener un portador. **Hecho** (test)
- [x] Objeto usable: botón que crea regalos, con tiempo de espera y límite de 20. **Hecho** (test)
- [x] Resaltado del objeto que miras y aviso "[E] Coger Regalo". **Implementado** (visto en captura)
- [x] Menú de opciones con Esc. **Implementado**
- [x] Elfos y objetos que caen del mapa reaparecen. **Hecho** (test)
- [x] Prueba de sensaciones por teo. **Hecho** (25-oct: "no lo veo mal")
- [ ] Pantalla para cambiar teclas (la lógica `Settings.rebind()` ya existe). **Pendiente**
- [ ] Los avisos "[E]" deben mostrar la tecla configurada, no la de por defecto. **Pendiente**

## Fase 4. Multijugador

- [x] Autoload `Network`: crear partida, unirse por IP o IP:puerto, salir, máximo 4, lista de jugadores con nombre y color. **Hecho** (test de red)
- [x] Menú principal: nombre, Crear partida, Unirse, Jugar solo, Salir; mensajes de error. **Implementado**
- [x] Escena raíz `Main` con LevelSpawner; la partida la crea el anfitrión y llega a los clientes. **Hecho** (test de red)
- [x] Elfos con autoridad propia, posición/cámara sincronizadas y suavizadas, nombre encima y color. **Hecho** (test de red)
- [x] Coger/soltar/lanzar y usar como peticiones al anfitrión, que valida distancia, portador y velocidad. **Hecho** (tests)
- [x] Física de objetos solo en el anfitrión; clientes reciben posición a 20 Hz y la suavizan. **Hecho** (test de red)
- [x] Objetos creados durante la partida (botón) aparecen en todos. **Hecho** (test de red)
- [x] Un jugador que sale: su elfo desaparece, suelta lo que llevaba y la partida sigue. **Hecho** (test de red)
- [x] Si el anfitrión cierra, los demás vuelven al menú con un mensaje. **Implementado**
- [x] Lista de jugadores en pantalla y "Salir al menú" en la pausa. **Implementado**
- [x] Prueba con dos ventanas / un amigo en el PC de teo. **Hecho** (25-oct: "va bastante bien la conexión")
- [ ] Reconexión: volver a unirse a la misma partida tras salir. **Implementado sin test** (el flujo es el mismo que unirse)
- [ ] Objeto grande que transportan dos jugadores. **Pendiente** (se hará con las máquinas, Fase 5)
- [ ] GodotSteam: lobby, invitaciones y SteamMultiplayerPeer con AppID 480. **Pendiente** (se hará antes de la Fase 11; necesita pruebas con dos cuentas de Steam reales)

## Fase 5. Primera cadena de producción

- [x] Tipos de objeto (`kind`): material, toy, gift. Regla `server_consume()`: un objeto libre se gasta una sola vez. **Hecho** (tests)
- [x] Caja de madera: E te da un bloque en las manos (o encima si ya llevas algo); máximo 12 sueltos. **Hecho** (tests y red)
- [x] Fábrica de juguetes: tolva arriba, 3 s por juguete, cola de 3, sale un coche por la rampa, engranaje girando. **Hecho** (tests y red)
- [x] Mesa de envolver: juguete encima + 3 pulsaciones de E = regalo. **Hecho** (tests)
- [x] Saco de Santa: cuenta regalos libres una vez, escupe lo demás, crece al llenarse. **Hecho** (tests y red)
- [x] Estado compartido del taller (regalos en el saco, objetivo 10) y aviso "¡Saco lleno!". **Hecho** (tests y red)
- [x] Carteles 3D sobre cada estación con su estado. **Implementado** (visto en captura)
- [x] Prueba por teo: ¿se entiende la cadena sin explicarla? **Hecho** (25-oct: "sí que se entiende")
- [ ] Sonidos de la cadena (Fase 10). **Pendiente**

## Fase 6. Progresión incremental

- [x] Dinero común: 10 monedas por regalo en el saco; solo se gasta comprando mejoras. **Hecho** (tests y red)
- [x] Catálogo `Upgrades` con 5 mejoras y precios crecientes; `WorkshopState.server_buy()` valida dinero y nivel máximo. **Hecho** (tests)
- [x] Tablón de mejoras con un botón por mejora: cartel con nivel, precio y efecto; color verde/gris/dorado. **Hecho** (tests, red y captura)
- [x] Fábrica rápida (−25 % por nivel, 3 niveles): la máquina se vuelve dorada y el engranaje gira más rápido. **Hecho** (tests)
- [x] Fábrica grande (+2 en cola, 2 niveles). **Hecho** (tests)
- [x] Botas de elfo (+15 % velocidad, 2 niveles). **Hecho** (tests)
- [x] Cinta transportadora (automatización 1): aparece al comprarla y lleva los juguetes de la fábrica a la mesa. **Hecho** (tests, red y captura)
- [x] Envolvedora automática (automatización 2): la mesa envuelve sola cada 2 s. **Hecho** (tests)
- [x] Aviso en pantalla para todos: "¡Fulano ha comprado X!". **Hecho** (red)
- [ ] Sonido al comprar y de las máquinas (Fase 10, falta conseguir sonidos con licencia). **Pendiente**
- [ ] Mientras llevas algo en las manos, E suelta y no pulsa botones. Valorar tras las pruebas si molesta. **Pendiente**
- [ ] Equilibrar precios y tiempos tras jugar con amigos. **Pendiente**

## Fase 7. Caos entre elfos

- [x] Reglas de bromas en un solo sitio (`Pranks`): alcance, recarga del empujón e inmunidad tras un golpe. **Hecho** (tests)
- [x] Empujón con clic derecho: se cae lo que lleva, sale despedido; se aplica en el PC de quien lo recibe. **Hecho** (tests y red)
- [x] Empujar objetos sueltos con clic derecho. **Hecho** (tests)
- [x] Montón de nieve y bolas de nieve: al dar a otro elfo, se le cae lo que lleva y ve escarcha. **Hecho** (tests, red y captura)
- [x] Palanca que pone la cinta al revés 4 s (recarga 12 s), solo si el equipo tiene cinta. **Hecho** (tests)
- [ ] Sonidos de empujón, golpe de nieve y palanca (Fase 10). **Pendiente**
- [ ] Animación del empujón (ahora el elfo solo sale despedido). **Pendiente**
- [ ] Ajustar fuerza, recarga e inmunidad tras jugar con amigos (que moleste, pero no frustre). **Pendiente**

## Fase 8. Reparto navideño

- [x] Patio nevado detrás de una puerta en la pared este del taller, con 4 casitas. **Hecho** (captura)
- [x] Trineo fijo: aparece al llenarse el saco, se lleva sus regalos y te da uno con E. **Hecho** (tests y red)
- [x] Chimeneas: cuentan los regalos que entran (también lanzados desde el suelo), cada casa pide 2-3, escupen lo que sobra y fuera del reparto. **Hecho** (tests y red)
- [x] 5 monedas extra por regalo entregado. Los regalos del trineo no valen en el saco (no se cobra dos veces). **Hecho** (tests)
- [x] Fin del reparto: aviso, el trineo se va, las casas se reinician, lo que sobra vuelve al saco y sube la noche. **Hecho** (tests y red)
- [x] HUD: "Noche N", y durante el reparto "Reparto: x / 10" y regalos en el trineo. **Hecho** (red y captura)
- [ ] Flecha o indicador hacia el patio cuando llega el trineo. **Pendiente** (valorar tras probar)
- [ ] Animación del trineo llegando y sonido de cascabeles (Fase 10). **Pendiente**
- [x] Tiempo límite de reparto y resultados de la noche. **Hecho en la Fase 9**

## Fase 9. Ciclo completo

- [x] Fases de cada noche en `WorkshopState`: espera, producción (6 min), reparto (2 min), resultados (15 s) y final. **Hecho** (tests y red)
- [x] Botón EMPEZAR en el taller; tras Nochebuena, SEGUIR JUGANDO y PARTIDA NUEVA. **Hecho** (tests y red)
- [x] Objetivo por noche: 6, 8, 10, 12, 14 con un elfo, +2 por cada elfo más; en modo infinito sigue subiendo. Las casas se reparten el objetivo. **Hecho** (tests y red)
- [x] Si se acaba el tiempo de producción, el trineo se lleva lo que haya. Llenar antes da 1 moneda por cada 5 s sobrantes. **Hecho** (tests)
- [x] Pantalla de resultados de cada noche y final de Nochebuena con récord (guardado en el PC del anfitrión). **Hecho** (tests, red y captura)
- [x] Reloj y fase en el HUD. **Hecho** (red y captura)
- [x] El botón de regalos gratis de la zona de pruebas hacía trampa. **Quitado en la Fase 10**
- [ ] Equilibrar tiempos, objetivos y monedas extra tras jugar (la prima por acabar antes puede ser demasiado alta). **Pendiente**
- [x] Si alguien entra a mitad de partida no veía los resultados. **Hecho en la Fase 10**

## Fase 10. Pulido

- [x] 19 efectos de sonido propios generados por código (`tools/generate_sounds.py`), autoload `Sfx` con sonido 3D y `broadcast` desde el anfitrión. **Hecho** (tests; **falta que teo los escuche**: desde aquí no se pueden oír)
- [x] Coger, lanzar, soltar, fábrica, envolver, saco, monedas, escupir, empujón, nieve, chimenea, casa servida, trineo, inicio de noche, resultados y tic-tac de los últimos 10 s. **Hecho**
- [x] Ambiente de noche: cielo oscuro, luna, faroles cálidos, guirnaldas de luces que parpadean, dos árboles de Navidad y nieve cayendo. **Hecho** (capturas)
- [x] Quitado el botón de regalos gratis. **Hecho**
- [x] Flecha en pantalla hacia el trineo durante el reparto. **Hecho** (tests y captura)
- [x] Animaciones: el que empuja se lanza, el que recibe se aplasta, el trineo llega volando. **Hecho** (tests)
- [x] Quien entra durante los resultados los pide al anfitrión. **Hecho** (red)
- [ ] Música de fondo navideña (propia o CC0). **Pendiente**
- [ ] Modelos más bonitos (elfos, máquinas) con recursos CC0 tipo Kenney o Quaternius. **Pendiente**, valorar con teo
- [ ] Medir rendimiento en el PC de teo (FPS) con 4 jugadores. **Pendiente**
- [ ] Ajustar volúmenes de cada sonido cuando teo los oiga. **Pendiente**
