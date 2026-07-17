# Arquitectura de sistemas — Patio Imán

Mapa de convenciones para que el juego escale sin perderse. Actualizar al
agregar sistemas nuevos.

## Autoloads

| Autoload | Rol |
|---|---|
| `GameState` | Hub del estado de partida: dinero, jornada, hora, clima, mejoras, munición, trofeos. **Todo dato compartido entre sistemas vive acá**, nunca en un nodo de escena. |
| `DialogueManager` | Plugin Dialogue Manager (addons). Los `.dialogue` viven en `dialogues/`. |

## Patrones establecidos

- **`GameState.effect(clave, valor_base)`** — parámetros modificables por
  progresión. Un sistema lee su valor efectivo pasando su export como base
  (`GameState.effect("loot_time", loot_time)`). Las mejoras de la tienda
  declaran `effects` en el catálogo; los futuros talentos apilan sobre las
  mismas claves sin tocar a los consumidores.
- **`GameState.weather_value(clave)`** — ídem para el clima del día
  (`sun`, `fog_add`, `grey`, `wind`, `rain`). Los sistemas que reaccionan
  al clima leen su parámetro; agregar un clima nuevo es una fila en
  `WEATHERS`.
- **`can_earn()` / `can_sleep()` / `is_night()`** — toda pregunta sobre la
  ventana horaria se hace a GameState; nadie compara horas a mano.
- **Metadata en nodos** para datos por-objeto sin acoplar scripts:
  `grab_top_y` (altura de agarre del imán), `scrap_value` (precio de
  venta), `trophy_id` / `trophy_name` (colección).
- **`on_shot()`** — cualquier nodo con ese método reacciona a un tiro del
  revólver (el player lo invoca tras el raycast). Blancos futuros: solo
  implementar el método.
- **`focus_on(punto, duración)` del player** — zoom dramático reutilizable
  para eventos (Desconocido, OVNI, Merodeador, trofeos futuros).
- **`play_dialogue(recurso)` del player** — congela el control, muestra el
  globo y lo devuelve al terminar.
- **Eventos nocturnos autosuficientes** — cada evento (OVNI, Merodeador)
  es un nodo que se rearma con `GameState.day_started` y sortea su chance
  por noche; no hay un director central todavía (agregarlo cuando haya
  más de ~5 eventos).

## Grupos de nodos

| Grupo | Quién | Para qué |
|---|---|---|
| `player` | el CharacterBody del operario | localizarlo desde eventos/paneles |
| `auto` | autos enteros | imán, prensa, looteo, cupo de recepción |
| `chatarra` | bloques compactados | imán, zona de carga |
| `parte` | partes looteadas | agarre a mano, pozo |
| `trofeo` | coleccionables | guardado con E, estante de la casilla |
| `cartel` | carteles legibles | diálogo con E |

## Capas de colisión

| Capa | Uso |
|---|---|
| 1 | mundo físico general (piso, autos, player, latas, OVNI) |
| 2 | disco del imán (`MagnetBody`) |

Convención de máscaras: los RigidBody "agarrables" usan `collision_mask = 3`
(chocan con mundo e imán). Los raycasts de interacción y disparo usan
máscara 1.

## Reglas de oro

- Texto visible al jugador en español; identificadores en inglés
  (snake_case GDScript).
- Todo número de balance como `@export` (tunable en editor) o en el
  catálogo/tabla de GameState — nada hardcodeado en lógica.
- Cada compra/mejora produce un cambio *visible* en el patio.
- Verificación tras cada cambio: `--headless --import` + `--quit-after N`.
- Los eventos paranormales nunca dañan ni combaten (prompt-lore): el
  peligro es la sensación.
