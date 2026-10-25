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
- [ ] Prueba por teo con amigos: ¿se entiende la cadena sin explicarla? **Pendiente**
- [ ] Sonidos de la cadena (Fase 10). **Pendiente**
