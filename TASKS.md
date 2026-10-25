# Tareas

Estados: **Hecho** (implementado y probado), **Implementado** (falta probarlo a mano),
**Pendiente**. Ver TESTING.md para el detalle de las pruebas.

## Fase 2. Entorno

- [x] Proyecto Godot 4.6 con Jolt Physics, capas de colisión con nombre y carpetas. **Hecho**
- [x] Autoload `Settings` con controles, sensibilidad, invertir Y y volumen guardados en disco. **Hecho**
- [x] Tests automáticos sin pantalla (`tests/run_tests.tscn`). **Hecho**
- [x] Herramienta de capturas (`tools/screenshot.tscn`). **Hecho**
- [ ] teo abre el proyecto en su PC con Windows y lo ejecuta. **Pendiente**

## Fase 3. Movimiento e interacción

- [x] Elfo en primera persona: andar, saltar, cámara con ratón, límite de inclinación. **Implementado**
- [x] Coger, soltar y lanzar objetos (regalo, pelota). **Hecho** (tests automáticos)
- [x] Un objeto solo puede tener un portador. **Hecho** (test)
- [x] Objeto usable: botón que crea regalos, con tiempo de espera y límite de 20. **Hecho** (test)
- [x] Resaltado del objeto que miras y aviso "[E] Coger Regalo". **Implementado** (visto en captura)
- [x] Menú de opciones con Esc. **Implementado**
- [x] Elfos y objetos que caen del mapa reaparecen. **Hecho** (test)
- [ ] Prueba de sensaciones por teo: velocidad, salto, sensibilidad, fuerza de lanzamiento. **Pendiente**
- [ ] Pantalla para cambiar teclas (la lógica `Settings.rebind()` ya existe). **Pendiente**
- [ ] Los avisos "[E]" deben mostrar la tecla configurada, no la de por defecto. **Pendiente**

## Fase 4. Multijugador (siguiente)

- [ ] Menú mínimo: Crear partida / Unirse por IP (ENet).
- [ ] Aparición y sincronización de elfos (MultiplayerSpawner/Synchronizer).
- [ ] Coger/soltar/lanzar como peticiones al anfitrión.
- [ ] Física de objetos solo en el anfitrión; posiciones sincronizadas.
- [ ] Prueba con dos ventanas en el mismo PC y luego con un amigo.
- [ ] GodotSteam: lobby, invitaciones, SteamMultiplayerPeer con AppID 480.
