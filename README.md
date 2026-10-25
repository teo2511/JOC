# Taller de Elfos

Videojuego indie 3D cooperativo navideño en primera persona para 2-4 jugadores online.
Sois elfos en el taller de Santa: fabricáis juguetes, los envolvéis, llenáis el saco,
mejoráis el taller y repartís los regalos, mientras os empujáis y os robáis cosas de las manos.

- Motor: **Godot 4.6** (versión estándar, no .NET). Lenguaje: **GDScript**.
- Plataforma: Windows primero, publicación prevista en Steam.
- Estado: **Fase 7**, cadena de producción con mejoras, y bromas entre elfos (empujones, bolas de nieve, palanca de la cinta). Ver [TASKS.md](TASKS.md).

## Cómo abrirlo

1. Instala Godot 4.6 desde https://godotengine.org/download/windows/ (botón *Godot Engine*, no *.NET*).
2. Descarga este repositorio (GitHub Desktop: *File → Clone repository*, o *Code → Download ZIP*).
3. Abre Godot, pulsa **Importar**, elige el archivo `project.godot` de esta carpeta y pulsa **Importar y editar**.
4. Pulsa **F5** (o el botón ▶ arriba a la derecha). Aparece el menú: escribe tu nombre y elige
   **Crear partida**, **Unirse** o **Jugar solo**.

## Jugar online (por ahora, por IP)

- **Dos ventanas en tu PC:** en Godot, menú *Depurar → Personalizar instancias de ejecución...*,
  activa *Habilitar varias instancias*, pon 2 y en los argumentos escribe `--host` en la primera y
  `--join=127.0.0.1` en la segunda. Al pulsar F5 se abren las dos ya conectadas.
- **Con un amigo en tu misma red (WiFi de casa):** tú pulsas *Crear partida*; tu amigo escribe tu
  IP local (en Windows: `ipconfig`, línea "Dirección IPv4", algo como 192.168.1.20) y pulsa *Unirse*.
- **Con un amigo por Internet:** de momento hace falta que el anfitrión abra el puerto **UDP 24680**
  en su router, o que los dos usáis una red virtual gratuita como Tailscale o ZeroTier y os conectáis
  con esa IP. Esto desaparecerá al pasar a Steam, que conecta sin abrir puertos.
- Windows puede preguntar si permites a Godot usar la red: acepta en "redes privadas".

## Cómo se juega (de momento)

1. **Madera:** mira la caja marrón y pulsa E. Te da un bloque de madera en las manos.
2. **Fábrica de juguetes:** echa la madera por el embudo de arriba (lánzala o suéltala encima).
   En 3 segundos sale un coche de juguete por la rampa. Caben 3 bloques en cola.
3. **Mesa de envolver:** deja el juguete encima y pulsa E tres veces mirando la mesa.
4. **Saco de Santa:** echa el regalo dentro. Con 10 regalos se completa la noche.
   Si echas algo que no es un regalo, el saco lo escupe.
5. **Monedas y mejoras:** cada regalo da 10 monedas al equipo. En el **tablón de mejoras** (pared
   izquierda) mira un botón y pulsa E para comprar con el dinero común. Botón verde = te llega,
   gris = falta dinero, dorado = al máximo. Mejoras: Fábrica rápida, Fábrica grande, Botas de elfo,
   Cinta transportadora (lleva los juguetes a la mesa) y Envolvedora automática.
6. **Bromas (nadie sale herido):**
   - **Empujón:** clic derecho con un elfo delante. Se le cae lo que lleva y sale despedido un poco.
     Después tienes que esperar 1,5 s, y quien lo recibe es inmune 2 s.
   - **Bolas de nieve:** coge una del montón blanco que hay detrás de donde apareces (E) y lánzala (clic izquierdo).
     Si da a otro elfo, se le cae lo que lleva y ve escarcha en la pantalla.
   - **Palanca de la cinta:** cuando el equipo compra la cinta, aparece una palanca al lado.
     Tirar de ella pone la cinta al revés 4 segundos (recarga en 12 s).
   - Clic derecho mirando un objeto suelto le da un empujón.

## Controles

| Acción | Tecla |
|---|---|
| Moverse | W A S D |
| Saltar | Espacio |
| Coger / soltar / usar | E |
| Lanzar lo que llevas | Clic izquierdo |
| Empujar a un elfo o un objeto | Clic derecho |
| Opciones (sensibilidad, invertir eje Y, volumen) | Esc |

Las opciones se guardan automáticamente.

## Tests automáticos

Desde la carpeta del proyecto, con Godot en el PATH:

```
godot --headless res://tests/run_tests.tscn
```

Imprime cada prueba y termina con código 0 si todo pasa.

Test de multijugador real (dos procesos conectados en el mismo PC, Linux/macOS o Git Bash):

```
tools/run_net_test.sh ruta/a/godot
```
Capturas de pantalla de revisión: `godot res://tools/screenshot.tscn -- <carpeta>`.

## Estructura

```
scenes/    escenas (.tscn): main (raíz), game (partida), player, items, props, ui, test (nivel)
scripts/   código GDScript, misma organización que scenes/
  autoload/  servicios globales (Settings, Network)
assets/    modelos, texturas, audio y fuentes
tests/     tests automáticos
tools/     utilidades de desarrollo (capturas)
```

## Documentación

- [PROJECT_PLAN.md](PROJECT_PLAN.md): alcance, fases y objetivos.
- [TASKS.md](TASKS.md): tareas pendientes y completadas.
- [TECHNICAL_NOTES.md](TECHNICAL_NOTES.md): decisiones técnicas.
- [TESTING.md](TESTING.md): procedimientos y resultados de pruebas.
- [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md): recursos externos y licencias.
