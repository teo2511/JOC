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

## Pruebas manuales: Fase 3 (pendiente, las hace teo en Windows)

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
