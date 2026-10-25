# Pruebas

## Tests automáticos

```
godot --headless res://tests/run_tests.tscn
```

### Resultado del 25-oct-2026 (Godot 4.6.3, Linux, sin pantalla)

28 correctas, 0 fallos:

- Las 8 acciones de control existen y tienen una tecla.
- Ratón abajo mira abajo; con "invertir eje Y" al revés; la cámara no pasa de 85°.
- El rayo detecta el regalo que miras; E lo coge, sigue al punto de agarre, E lo suelta y cae.
- Clic lo lanza: avanza 3,6 m en 1/3 de segundo.
- Un segundo portador no puede coger un objeto ya cogido.
- El rayo detecta el botón, E lo pulsa, aparece un regalo nuevo y el tiempo de espera funciona.
- Un objeto y un elfo que caen del mapa reaparecen.

Capturas de la zona de pruebas renderizadas con OpenGL en pantalla virtual: la escena se ve,
el aviso "[E] Pulsar: crear regalo" y el punto de mira aparecen al mirar el botón.

**Qué no cubren estos tests:** las sensaciones (velocidad, salto, sensibilidad), el ratón real,
Windows, ni el multijugador. Eso lo prueba una persona.

### Resultado del 25-oct-2026, Fase 4 (Godot 4.6.3, Linux, sin pantalla)

`tests/run_tests.tscn`: **34 correctas, 0 fallos** (las anteriores, adaptadas a la partida en
modo solo, más: un objeto un portador, solo quien lo lleva puede soltarlo, velocidad de
lanzamiento limitada, objeto liberado si su portador se va, no se coge un objeto lejano).

`tools/run_net_test.sh` (dos procesos reales conectados por ENet en 127.0.0.1), ejecutado 4
veces seguidas, siempre **anfitrión 14/14 y cliente 17/17**:

- El cliente se conecta, recibe la partida y los regalos del nivel, ve el elfo y el nombre del
  anfitrión, y solo controla el suyo. El anfitrión ve 2 elfos con colores distintos.
- El cliente coge un regalo; el anfitrión lo confirma y no puede cogerlo a la vez.
- El cliente lo lanza: se mueve en el anfitrión (2,7 m) y el cliente lo ve volar (3,8 m).
- El anfitrión coge otro regalo y el cliente lo ve en sus manos.
- El cliente pulsa el botón y el regalo nuevo aparece en los dos.
- El cliente sale: su elfo desaparece y la partida sigue para el anfitrión.

**Qué no cubre:** Internet real (latencia, pérdida de paquetes), Windows, 3-4 jugadores,
el anfitrión cerrando con clientes dentro, reconexión.

## Pruebas manuales: Fase 4 (pendiente, las hace teo)

1. Dos ventanas en tu PC (ver README, "Jugar online"). En la primera aparece "Elfos 2/4".
2. Mueve un elfo: en la otra ventana se ve moverse suave, con su nombre encima.
3. Coge un regalo en una ventana: en la otra se ve en sus manos. Lánzalo: vuela en las dos.
4. Intentad coger el mismo regalo a la vez: solo uno se lo queda.
5. Pulsa el botón rojo desde la ventana del cliente: el regalo cae en las dos.
6. Cierra la ventana del cliente: en la del anfitrión desaparece su elfo. Vuelve a unirte.
7. Cierra la del anfitrión: el cliente vuelve al menú con "El anfitrión ha cerrado la partida".
8. Repetidlo con un amigo en otro PC.

## Pruebas manuales: Fase 3 (hechas por teo el 25-oct: "no lo veo mal")

1. Abre el proyecto y pulsa F5. Debes aparecer en una sala con paredes y una mesa con regalos.
2. Mueve el ratón: la cámara gira suave. Esc → mueve "Sensibilidad" → vuelve; se nota el cambio.
3. Marca "Invertir eje vertical": mover el ratón hacia arriba mira hacia abajo.
4. Anda con WASD y salta con Espacio. Sube la rampa verde a la plataforma y salta los bloques blancos.
5. Mira un regalo: se ilumina y aparece "[E] Coger Regalo". Pulsa E: lo llevas delante.
6. Pulsa E otra vez: cae. Cógelo y haz clic: sale lanzado en arco. Intenta encestarlo en la caja verde.
7. Pulsa el botón rojo con E: cae un regalo nuevo.
8. Cierra y vuelve a abrir el juego: la sensibilidad y el eje se mantienen.

Apunta qué se siente lento, rápido, raro o mareante.

## Pruebas de multijugador (a partir de la Fase 4)

Lista de la sección 5.1 del prompt maestro: conexión de dos jugadores, recoger objetos
distintos, disputar el mismo objeto, lanzar y recoger, objeto grande entre dos, misma máquina,
dinero y progreso, abandono, reconexión y continuidad tras un error.
