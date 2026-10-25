# Taller de Elfos para Roblox

Versión de Roblox del juego (la de Godot sigue en la carpeta principal del repo).
Todo el mapa y la lógica están en código Luau dentro de `src/`; el sitio de Roblox se
genera con [Rojo](https://rojo.space).

## Probarlo (lo más fácil)

1. Instala **Roblox Studio** desde https://create.roblox.com y entra con tu cuenta.
2. Abre el archivo `TallerDeElfos.rbxlx` que te paso en el chat (Archivo > Abrir).
3. Pulsa **Play** (F5). Juegas en primera persona dentro del taller.
4. Para probar con varios jugadores en tu PC: pestaña **Probar**, en "Clientes y servidores"
   elige 2 jugadores y pulsa **Iniciar**. Se abren dos ventanas, una por elfo.

Para jugar con amigos: Archivo > **Publicar en Roblox**, y luego en la configuración del
juego deja que tus amigos entren (o usa **Probar en equipo**).

## Cómo se juega (fase R1)

- **[E]** sobre un objeto: cogerlo. **[E]** otra vez: soltarlo. **Clic**: lanzarlo hacia donde miras.
- **Cajón de madera**: [E] te da un bloque de madera.
- **Fábrica de juguetes**: echa la madera por arriba (suéltala encima o lánzala). Sale un coche.
- **Mesa de envolver**: deja el coche encima y pulsa [F] tres veces. Sale un regalo.
- **Saco de Santa**: echa el regalo dentro. Cada uno da 10 monedas.
- En móvil, los botones de coger y usar salen en pantalla, y al llevar algo aparecen "Soltar" y "Lanzar".

## Para programar (Claude o quien sea)

- `src/shared`: código compartido. `Rules.luau` son las reglas sin Roblox (se prueban con
  `luau tests/run.luau`), `Config.luau` las medidas en studs y colores.
- `src/server`: `Main.server.luau` arranca todo; `MapBuilder` construye el mapa; `Items`
  coge, suelta y lanza; `Stations` es la cadena de producción; `Elves` pone el gorro.
- `src/client`: `Controller` (soltar y lanzar) y `Hud`.
- Generar el sitio: `rojo build default.project.json -o TallerDeElfos.rbxlx`.
- Sincronizar en directo con Studio: `rojo serve` y el plugin de Rojo en Studio.
- Comprobar tipos: `rojo sourcemap default.project.json -o sourcemap.json` y
  `luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json src`.
