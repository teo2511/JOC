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

### Resultado del 25-oct-2026, Fase 5

`tests/run_tests.tscn`: **53 correctas, 0 fallos**. Nuevas: la caja da madera en las manos, la
fábrica se traga la madera y saca un juguete en 3 s, la mesa envuelve con 3 pulsaciones, el saco
cuenta el regalo y lo hace desaparecer, un regalo en las manos no se gasta, el mismo regalo no
cuenta dos veces, el saco escupe lo que no es regalo, el objetivo se completa al llegar a 10.

`tools/run_net_test.sh`, 3 veces seguidas: **anfitrión 17/17, cliente 22/22**. Nuevas: el cliente
saca madera de la caja y la recibe en las manos, ve la fábrica trabajando, ve el saco con 1 regalo
y su pantalla muestra "Saco: 1 / 10".

### Resultado del 25-oct-2026, Fase 6

`tests/run_tests.tscn`: **73 correctas, 0 fallos**. Nuevas: dinero por regalo, no se compra sin
dinero, se descuenta el precio, el precio sube, máximo de nivel sin cobro, efecto de cada mejora,
el botón del tablón compra, la cinta aparece al comprarla y lleva un juguete real de la fábrica a
la mesa, la mesa automática envuelve sin pulsar.

`tools/run_net_test.sh`, 4 veces seguidas: **anfitrión 20/20, cliente 27/27**. Nuevas: el regalo da
monedas al equipo, el cliente ve el dinero, compra la cinta desde el tablón, se descuenta del dinero
común, ve aparecer la cinta y el aviso con su nombre.

### Resultado del 25-oct-2026, Fase 7

`tests/run_tests.tscn`: **96 correctas, 0 fallos**. Nuevas: un amigo te empuja, se te cae lo que
llevas, sales despedido en dirección contraria, recarga del empujón, inmunidad y su fin, no se empuja
desde lejos ni a uno mismo, empujar un objeto suelto, el montón de nieve da bolas, una bola lanzada
golpea y se deshace, una soltada no, la palanca solo aparece con cinta, invierte la cinta, recarga
y la cinta vuelve sola a ir bien.

`tools/run_net_test.sh`, 3 veces seguidas: **anfitrión 27/27, cliente 34/34**. Nuevas: el cliente
empuja al anfitrión (al anfitrión se le cae el regalo y sale despedido unos 2 m), el anfitrión le
devuelve el empujón y el cliente sale despedido en su propia pantalla, el anfitrión le lanza una
bola de nieve que le da, se deshace, y el cliente ve la escarcha.

Captura `nieve`: montón de nieve, bolas y la escarcha en pantalla.

### Resultado del 25-oct-2026, Fase 8

`tests/run_tests.tscn`: **117 correctas, 0 fallos**. Nuevas: las casas piden tantos regalos como el
saco, no hay trineo ni reparto antes de llenar el saco, al llenarlo llega el trineo con los regalos,
el trineo da un regalo en las manos (y no otro si las tienes ocupadas), el saco no acepta regalos
del trineo, **un regalo lanzado desde el suelo con el lanzamiento normal entra por la chimenea**
(mirando 50° hacia arriba a 4 m), 5 monedas por entrega, la casa da las gracias y escupe lo que
sobra, al servir todas se va el trineo, sube la noche, las casas se reinician y lo sobrante vuelve
al saco.

`tools/run_net_test.sh`, 4 veces seguidas tras corregir una carrera del propio test: **anfitrión 32/32,
cliente 41/41**. Nuevas: el saco lleno trae el trineo, el cliente lo ve, lo mira, saca un regalo,
lo suelta, el anfitrión lo mete por la chimenea, el cliente ve la casa con "1 / 3 regalos" y
"Reparto: 1 / 10" en su pantalla, y luego la noche 2 y el aviso de reparto completado.
(La carrera: el anfitrión completaba las demás casas tan rápido que a veces el cliente no llegaba
a ver el estado "1 / 3". El test espera ahora 1,5 s; el juego no cambia.)

Capturas `patio` y `chimenea`.

## Pruebas manuales: Fase 8 (pendiente, las hace teo con amigos)

1. Llenad el saco (10 regalos): aviso y el trineo aparece en el patio (puerta de la pared derecha).
2. Coged regalos del trineo con E y lanzadlos por las chimeneas. ¿Cuesta demasiado acertar?
3. Una casa con sus regalos enciende las ventanas y dice "¡Gracias!".
4. Con todas servidas: aviso de reparto completado y "Noche 2" arriba.
5. ¿Se entiende adónde hay que ir cuando llega el trineo?

## Pruebas manuales: Fase 7 (pendiente, las hace teo con amigos)

1. Empuja a un amigo con clic derecho mientras lleva algo: se le cae y sale despedido.
2. Intenta empujarle otra vez enseguida: no deja (recarga e inmunidad).
3. Ve al montón de nieve (detrás de donde apareces, a la derecha), coge una bola y lánzasela.
4. Compra la cinta y tira de la palanca roja mientras otro usa la cinta.
5. ¿Es divertido o molesta demasiado? ¿Empujón muy fuerte o muy flojo?

## Pruebas manuales: Fase 6 (pendiente, las hace teo)

1. Mete un par de regalos en el saco: arriba suben las monedas.
2. Ve al tablón (pared izquierda) y compra "Fábrica rápida": aviso en pantalla, la fábrica se
   vuelve más dorada y tarda menos.
3. Compra la cinta: aparece entre la fábrica y la mesa y lleva los coches a la mesa sola.
4. Compra la envolvedora: la mesa envuelve sin pulsar E.
5. Con amigos: ¿se nota la progresión en una partida normal? ¿Los precios son muy caros o baratos?

## Pruebas manuales: Fase 5 (hechas por teo el 25-oct: "sí que se entiende")

1. Coge madera de la caja marrón (E) y échala por el embudo de la fábrica azul.
2. Espera el coche rojo, ponlo en la mesa roja y pulsa E tres veces mirando la mesa.
3. Echa el regalo en el saco: el contador de arriba sube y el saco crece.
4. Echa una pelota en el saco: debe salir disparada.
5. Con un amigo: repartíos las tareas. ¿Se entiende sin explicarlo? ¿Algún paso aburre?

## Pruebas manuales: Fase 4 (hechas por teo el 25-oct: "va bastante bien la conexión")

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
