# Plan del proyecto

Documento de referencia: el prompt maestro de teo (25-oct-2026) y la propuesta de la Fase 1
aprobada el mismo día. Este archivo resume lo acordado; si hay dudas, manda el prompt maestro.

## Objetivo

Un juego pequeño, estable y divertido con amigos, para Steam a 4,99-5,99 €.
Prioridades, en orden: cooperativo online, movimiento en primera persona, físicas divertidas,
cadena de producción clara, progresión incremental, saco y reparto, estética navideña, pulido,
contenido extra.

## Decisiones aprobadas

- Motor Godot 4.6, GDScript, sin otros lenguajes ni frameworks.
- Online con **anfitrión autoritativo** (un jugador hace de servidor). ENet en desarrollo,
  Steam (GodotSteam: lobbies, invitaciones, relay de Valve) para la versión publicada.
- 2-4 jugadores. Sin servidores dedicados.
- El pago de Steam Direct (100 $) se deja para el momento de publicar. Mientras, Steam se
  prueba con el AppID gratuito de pruebas 480.

## Bucle principal (propuesta)

Una partida son **Noches** de unos 8 minutos:
1. Producción (~6 min): pedidos en la pizarra → materiales → Máquina de Juguetes → Mesa de
   Envolver → Saco. Cada regalo válido da dinero común.
2. Reparto (~2 min): el trineo (fijo, no se conduce) aterriza en el patio y hay que llevar o
   lanzar los regalos a las chimeneas de 4-6 casitas.
3. Resultados y tienda (~30 s): mejoras compradas con un botón en el propio taller.
4. Siguiente Noche con más demanda. Tras 5 Noches, Nochebuena (final con récord) y modo infinito.

Pendiente de confirmar con teo: trineo fijo frente a trineo pilotable.

## Alcance de la primera versión jugable

Taller de una sala + patio con 4 casitas · 2 juguetes (osito, coche) · almacén, máquina,
mesa de envolver y saco · 5 mejoras · 1 automatización (cinta) · 3 bromas (empujón que hace
soltar, lanzar, bolas de nieve) · menú crear/unirse/opciones · HUD · resultados · reinicio.

Fuera de alcance: todo lo de la sección 13.3 del prompt maestro.

## Fases

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Análisis y planificación | Hecha |
| 2 | Entorno y proyecto base | Hecha (pendiente de que teo lo abra en su PC) |
| 3 | Prototipo de movimiento e interacción | Hecha (teo la ha probado: "no lo veo mal") |
| 4 | Prototipo multijugador (ENet, luego Steam) | ENet hecho (teo: "va bastante bien la conexión"). Steam pendiente, antes de la Fase 11 |
| 5 | Primera cadena de producción | Hecha (teo: "sí que se entiende") |
| 6 | Progresión incremental | Implementada y probada (tests y red); pendiente de prueba por teo. Falta el sonido |
| 7 | Caos entre jugadores | Implementada y probada (tests y red); pendiente de prueba por teo. Falta sonido y animación |
| 8 | Reparto navideño | Implementada y probada (tests y red); pendiente de prueba por teo. Trineo fijo |
| 9 | Ciclo completo | Pendiente |
| 10 | Pulido y optimización | Pendiente |
| 11 | Preparación para Steam | Pendiente |
