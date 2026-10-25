# Taller de Elfos

Videojuego indie 3D cooperativo navideño en primera persona para 2-4 jugadores online.
Sois elfos en el taller de Santa: fabricáis juguetes, los envolvéis, llenáis el saco,
mejoráis el taller y repartís los regalos, mientras os empujáis y os robáis cosas de las manos.

- Motor: **Godot 4.6** (versión estándar, no .NET). Lenguaje: **GDScript**.
- Plataforma: Windows primero, publicación prevista en Steam.
- Estado: **Fase 3**, zona de pruebas de movimiento e interacción. Ver [TASKS.md](TASKS.md).

## Cómo abrirlo

1. Instala Godot 4.6 desde https://godotengine.org/download/windows/ (botón *Godot Engine*, no *.NET*).
2. Descarga este repositorio (GitHub Desktop: *File → Clone repository*, o *Code → Download ZIP*).
3. Abre Godot, pulsa **Importar**, elige el archivo `project.godot` de esta carpeta y pulsa **Importar y editar**.
4. Pulsa **F5** (o el botón ▶ arriba a la derecha) para jugar la zona de pruebas.

## Controles

| Acción | Tecla |
|---|---|
| Moverse | W A S D |
| Saltar | Espacio |
| Coger / soltar / usar | E |
| Lanzar lo que llevas | Clic izquierdo |
| Opciones (sensibilidad, invertir eje Y, volumen) | Esc |

Las opciones se guardan automáticamente.

## Tests automáticos

Desde la carpeta del proyecto, con Godot en el PATH:

```
godot --headless res://tests/run_tests.tscn
```

Imprime cada prueba y termina con código 0 si todo pasa.
Capturas de pantalla de revisión: `godot res://tools/screenshot.tscn -- <carpeta>`.

## Estructura

```
scenes/    escenas (.tscn): player, items, props, ui, test
scripts/   código GDScript, misma organización que scenes/
  autoload/  servicios globales (Settings)
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
