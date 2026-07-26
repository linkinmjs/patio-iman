# Diseño de niveles — Patio Imán

Documento de trabajo. Consolida el rediseño espacial del patio principal y los
sectores periféricos, apoyado en 6 libros de teoría de level design leídos para
este proyecto (ver `docs/pdfs/`). **Es un punto de partida para iterar**, no verdad
absoluta: ante conflicto entre el documento y una decisión del usuario, gana el usuario.

## Dirección elegida (decisiones del usuario)

1. **Forma:** *patio isla de luz + mundo más allá de la reja.* El patio de trabajo es
   un recinto seguro e iluminado; alrededor hay oscuridad/baldíos/ruinas que solo se
   cruzan en eventos de terror puntuales. Máximo contraste seguro↔peligro.
2. **Verticalidad:** *moderada.* Pilas trepables, pasarelas, un altillo/foso. Parkour
   opcional que premia explorar, sin exigir destreza.
3. **Disparo del terror:** *mixto.* Sectores opt-in para el curioso + irrupciones
   forzadas en hitos de la historia.

---

## 1. Lo que converge la teoría (destilado de los 6 libros)

Los seis coinciden en lo mismo una y otra vez. Estos son los principios que rigen
el rediseño, con la fuente entre paréntesis para poder ir al libro.

| # | Principio | Qué dice | Fuente(s) |
|---|---|---|---|
| 1 | **Romper el "todo a la vista"** | El 60×60 plano muestra todas las cartas juntas. Hay que tallar el vacío con bloqueadores de línea de visión (pilas, contenedores, desniveles) para crear jerarquía y rincones. | Galuzin *Ultimate* Ch7/13; Totten *Arch* (figure-ground / form-void); *Preproduction* (sightlines); *In Pursuit* (legibilidad); Totten *Processes* ("la esquina") |
| 2 | **Landmarks a 3 escalas** | Hitos Macro/Meso/Micro rompen la uniformidad y orientan sin mapa. **Ojo con el pórtico:** como *opera recién en late game*, no puede ser el landmark funcional del inicio. La *estructura* del pórtico está presente y oxidada desde el día 1 (hito visual + weenie) y "cobra vida" (se ilumina, funciona) al desbloquearse; el landmark **vivo del early/mid es la prensa**. | *In Pursuit* (micro/meso/macro); Totten *Arch* (*architectural weenies*, Kevin Lynch); *Preproduction* (*focal point*); Totten *Processes* (landmarks ancla) |
| 3 | **Tematizar las 3 zonas (*genius loci*)** | Cada zona con "espíritu" propio: color, material, densidad, luz. De noche se apila un 2º tema (abandonado/cósmico). | Totten *Arch* (*genius loci*); *Preproduction* (*stacking themes*); *In Pursuit* (*area landmarking*); Totten *Processes* (densidad de POI no uniforme) |
| 4 | **Foreshadowing del "lote del fondo"** | Mostrar zonas clausuradas tras reja desde el día 1 (ves el objetivo, no llegás) → siembra curiosidad para el late-game. | Totten *Arch* (*denial spaces / oku*); Galuzin *Ultimate* Ch26; *Preproduction* (focal distante); *In Pursuit* (*teasing = setup & payoff*) |
| 5 | **Revisitar espacio alterado > espacio nuevo** | La palanca más barata y potente para un dev solo: reconfigurar/clausurar/oscurecer una zona ya familiar golpea más que construir metros. | Totten *Processes* ("revising the structure"); *In Pursuit* (*recycling/revisit*, God of War); Galuzin (*backtracking*); Totten *Arch* (*problem of the protagonist*, Metroid) |
| 6 | **Prospect & Refuge / modelo Slender** | El patio nocturno ya es un *prospect* envuelto en *negative space*. Faroles+linterna = refugios aprendidos; la oscuridad entre ellos = pérdida de refugio = tensión. | Totten *Arch* (prospect + negative space); *In Pursuit* (prospect & refuge, *safe havens* tipo Alan Wake) |
| 7 | **Pacing como arco de jornada** | "Calm before the storm": trabajo diurno = valles, irrupción nocturna = picos. Regla *peak-end*: se recuerda el pico y el final de cada noche. Establecé un patrón, rompé uno. | Galuzin *Ultimate* Ch20; *In Pursuit* (intensity/beats/peak-end); Totten *Processes* (anticipación/variety) |
| 8 | **Anticipación en el vacío** | El miedo se cocina en el tramo vacío y seguro *antes* de la amenaza. El trayecto largo y mal iluminado hacia la zona de carga es ese tramo. | Totten *Processes* ("stillness", cap. 9); *In Pursuit* (Emotions) |
| 9 | **Show, don't tell** | Anomalías como props narrativos / escena del crimen, colocados donde el jugador ya pasa, nunca con texto. | *Preproduction* (*show don't tell*); *In Pursuit* (narrativa ambiental); Totten *Arch* (símbolos / advertising) |
| 10 | **Receta del sector de castigo** | Pasillo angosto oscuro, lineal, luz al fondo, *valve* de un sentido (se cierra detrás). La forma del espacio empuja la huida. | Galuzin *Ultimate* Ch43 ("sewers"); Totten *Arch* (narrow space/claustrofobia); *In Pursuit* (valve + forma del espacio); Totten *Processes* (ratchet/valve, "front door cerrada") |
| 11 | **Push/Pull + luz para el ánimo** | Espacios abiertos *atraen*, los estrechos y esquinas *empujan/encierran*: alternarlos crea flujo. La luz define emoción: contraluz = silueta misteriosa, luz desde abajo = aterrador, cálido = santuario / azul-frío = industrial hostil. | *Beginning* Cap.4 (push/pull) y Cap.5 (luz/color/atmósfera) |

**Advertencias honestas de la lectura:** ninguno de estos libros da métricas numéricas
duras (anchos de pasillo, alturas) — solo escala cualitativa con un muñeco de referencia
a escala. El gating formal (metroidvania) apenas se toca; lo cubrimos nosotros abajo.

---

## 2. Diagnóstico del greybox actual

Recinto cuadrado 60×60 m, plano, paredes lisas, todo visible de una sola vez. Zonas
colocadas pero sin jerarquía ni flujo impuesto:

- **SUR (spawn):** recepción, oficina, tienda, casilla/cama, tiro al blanco → *hogar*.
- **CENTRO:** autos, grúa fija (pórtico), grúa móvil (tractor) → *trabajo*.
- **NORTE:** prensa, pozo, zona de carga → *industrial*.

Fallos según la teoría: viola el principio 1 (todo a la vista), no tiene landmarks (2),
las zonas no están tematizadas (3), no hay foreshadowing (4) ni gradiente emocional (7).
La buena noticia: **la triada de zonas SUR→CENTRO→NORTE ya es el arco correcto**
(hogar → trabajo → exposición). Solo hay que *esculpirla*.

---

## 3. Esquema macro: isla de luz + más allá de la reja

```
                    ▓▓▓ MÁS ALLÁ DE LA REJA (oscuridad, baldíos, ruinas) ▓▓▓
        ┌───────────────────  reja / muro de chatarra  ───────────────────┐
        │                                                                   │
        │   NORTE — industrial, frío, foso hundido (la zona más tensa)      │
        │   prensa · pozo · zona de carga · [escotilla → túnel de castigo]  │
        │                            ▲ tramo de anticipación (vacío/oscuro) │
        │   CENTRO — trabajo, neutro                                        │
        │   grúas · autos · PÓRTICO (estructura día 1, opera en late)        │
        │                                                                   │
        │   SUR — hogar, cálido, denso (isla de luz máxima)                 │
        │   casilla · tienda · oficina · recepción · tiro al blanco         │
        │                          ● spawn                                  │
        └───────────  portón de servicio → baldío (sector de castigo)  ─────┘
                    ▓▓▓ MÁS ALLÁ DE LA REJA ▓▓▓
```

La reja es el borde de tu isla. De día es un límite creíble (principio de *believable
boundaries*); de noche, con visión de ~20 m, lo que hay del otro lado es puro *negative
space* que la imaginación llena. Los puntos de fuga hacia el terror: **un portón de
servicio** (sur/oeste) y **una escotilla en el foso** (norte).

---

## 4. Tres alternativas de layout del patio principal

Todas respetan la dirección elegida. Difieren en la **topología del recorrido** y en
dónde vive la tensión. Elegí una, mezclá, o descartá.

### Alternativa A — "Recorrido en U" (flujo doblado)

El recinto deja de ser cuadrado: es una **U**. El trabajo fluye a lo largo de la U y las
pilas de chatarra son las paredes internas, así que desde la casilla NO ves la prensa.

```
   ┌──────────────┐      ┌──────────────┐
   │ NORTE prensa │      │  recepción   │  ← entran autos
   │ pozo · carga │      │   (SUR-este) │
   │  [escotilla] │      └──────┬───────┘
   └──────┬───────┘             │
          │   ╔═══════════╗     │
   codo → │   ║ GRÚA      ║ ← landmark central en el codo
          │   ║ PÓRTICO   ║     │
   ┌──────┴───────╗       ╚═════┴───────┐
   │  CENTRO trabajo (fondo de la U)    │
   │  autos · grúa móvil · despiece     │
   └───────────── SUR hogar ────────────┘
        casilla · tienda · ● spawn
```

- **Pros:** flujo natural, sightlines cortadas orgánicamente, un solo landmark domina.
- **Contras:** riesgo de sentirse "pasillo" si los tramos son largos y rectos.
- **Terror:** la esquina del codo (CENTRO→NORTE) es la que doblás cada noche caminando
  hacia lo oculto (Totten *Processes*, "la esquina").

### Alternativa B — "Rueda de radios" (hub central) ⭐ recomendada como esqueleto

Una **plaza central de maniobra** con la grúa de pórtico como hub y landmark. De ella
salen radios (callejones entre chatarra), cada uno con su propio *genius loci*.

```
                 ▓ baldío ▓
              ┌─── radio N ───┐
              │ NORTE: prensa │
              │ pozo · carga  │
              │  [escotilla]  │
   ┌── radio O ──╗         ╔── radio E ──┐
   │ LOTE DEL    ║  PLAZA  ║  recepción   │ ← autos
   │ FONDO 🔒    ║  GRÚA   ║  (entrada)   │
   │ (weenie,    ║ PÓRTICO ║              │
   │  late-game) ╚════╤════╝              │
   └─────────────┐    │   ┌───────────────┘
              ┌── radio S ───┐
              │ SUR: hogar   │
              │ casilla·tienda│ ● spawn
              └──────────────┘
```

- **Pros:** máxima legibilidad (siempre volvés al hub → orientación nocturna trivial),
  expansible (agregás radios), el **lote del fondo** al oeste es el *weenie* que tira al
  late-game. Es el layout que mejor sostiene "isla de luz".
- **Contras:** puede leerse simétrico/artificial si no se rompe con ruido y asimetría.
- **Vertical:** la grúa de pórtico lleva una **pasarela elevada** (prospect sobre toda
  la rueda de día; de noche la niebla te la roba).

### Alternativa C — "Terrazas" (cascada de niveles, aprovecha lo vertical)

El patio en tres cotas. El trabajo "cae" cuesta abajo; la seguridad está arriba.

```
   cota −2  ░░░ NORTE (foso hundido) ░░░  ← lo más tenso, mal iluminado
            prensa hundida · carga · [escotilla]
              ▲ rampa de descenso (tramo de anticipación)
   cota  0  ▒▒▒ CENTRO (trabajo) ▒▒▒
            grúas · autos · grúa de pórtico
              ▲ rampa suave
   cota +2  ▓▓▓ SUR (hogar, terraza alta) ▓▓▓
            casilla · tienda · ● spawn · mirador sobre el patio
            (de día ves todo; de noche la niebla borra el prospect)
```

- **Pros:** usa la verticalidad moderada elegida; el **descenso día→noche** es un
  gradiente emocional potentísimo (seguridad arriba → exposición en el foso); el foso
  NORTE es naturalmente el punto de máxima tensión; ves "más allá de la reja" por sobre
  el muro desde la terraza alta (foreshadowing gratis).
- **Contras:** los desniveles complican el tractor (grúa móvil) y la física de los
  bloques; el más caro de tunear.

### Recomendación: híbrido B + un toque de C

Usar **B (rueda/hub)** como esqueleto de legibilidad, y aplicar el **desnivel de C solo
en el NORTE** (el foso de la prensa, cota −2), dejando CENTRO y SUR a nivel para no
romper la física del tractor. Resultado:

- Legibilidad total (hub central, siempre te reorientás).
- Gradiente emocional donde importa (bajás al foso NORTE = descenso a lo tenso).
- Verticalidad moderada real (pasarela de la grúa + foso + pilas trepables) sin caos físico.
- El *weenie* del oeste (lote del fondo) sostiene el late-game.

---

## 5. Sectores de castigo (más allá de la reja)

Tres bocetos, del más barato al más ambicioso. Todos construidos con sistemas que ya
existen (oscuridad, sonido, física, el Merodeador).

### C1 — La irrupción forzada (el patio vuelto hostil) — el más barato y potente
Ciertas noches-hito: **se corta la luz del patio** y el camino directo a la casilla se
bloquea (un derrumbe de chatarra, un portón que baja). Tenés que **rodear por un tramo
oscuro** con audios que suben. No es una escena nueva: es el patio que ya conocés,
alterado (principio 5, "revisitar espacio alterado"). La "front door cerrada" amplifica
el encierro (Totten *Processes*). Costo de producción: mínimo.

### C2 — El túnel de servicio (opt-in) — la receta clásica de castigo
Una **escotilla en el foso NORTE** aparece abierta ciertas noches. Adentro: pasillo
angosto, oscuro, **lineal, luz tenue al fondo, sin bifurcaciones**, *valve* de un sentido
(la puerta se traba detrás). Audios en crescendo. Recompensa: un trofeo con lore al final.
Es la receta literal en la que convergen Galuzin (Ch43), Totten *Arch* (narrow space) y
*In Pursuit* (valve). Entrás si querés.

### C3 — El baldío / lote de afuera (opt-in, más ambicioso) — modelo Slender
Un descampado oscuro más allá del **portón oeste**, con siluetas de autos abandonados a
medio ver. Cruzarlo para llegar a algo (¿un auto que apareció sin camión?) mientras el
Merodeador ronda en el *negative space*. Máxima aplicación del modelo Slender (prospect
abierto + oscuridad omnipotente). El más caro porque requiere geometría nueva afuera.

---

## 6. Progresión espacial (gating mid/late)

El desbloqueo de espacio es la columna de la progresión (principio 5). Cada apertura
debe producir un cambio *visible* (regla de oro del CLAUDE.md).

| Momento | Se abre | Cómo | Efecto |
|---|---|---|---|
| **Día 1** | Patio de trabajo completo | — | El lote del fondo (oeste) ya se ve, **clausurado tras reja** = weenie/foreshadow |
| **Early** | Linterna, revólver | tienda | Resignifican el espacio nocturno (refugio navegable) |
| **Mid** | **Galpón techado** (anexo sombrío) | mejora / llave | Zona de despiece y almacén; primer interior oscuro dentro del patio |
| **Late** | **Grúa de pórtico** operativa | mejora cara (coincide con `mejoras.md`) | La estructura que veías desde el día 1 "cobra vida": se ilumina y funciona; se vuelve el ancla nocturna del patio y cambia el flujo de trabajo |
| **Late** | **Lote del fondo** (oeste) | *hard gate* (mejora cara / evento) | Nueva zona con las anomalías más fuertes; *revisit* del weenie |
| **Late** | **Escotilla → túnel (C2)** | aparece de noche | Sector de castigo opt-in |

Conecta con lo ya anotado en `pendientes.md`: "puntos separados a propósito con
obstáculos → parkour → sustos sutiles" y "grúa fija = mejora late game".

**Trucos de gating baratos** (*Beginning* Cap.6): el *bloodlock económico* — la zona se
abre al cumplir una meta de trabajo ("compactá X bloques" / "juntá $Y para la llave"),
no solo por comprar en la tienda, así el desbloqueo se siente ganado. Y el truco *inside
vs. outside*: una simple puerta en el muro de chatarra esconde un área entera (el galpón,
el túnel) sin construir geometría visible desde afuera — revelación máxima, costo mínimo.

---

## 7. Frameworks a usar al construir (robados de los libros)

- **Bubble diagram → mapa top-down → blockout → iterar** (*In Pursuit*, Galuzin): dibujar
  la distribución en burbujas ANTES de mover geometría en Godot.
- **Top-Down Layout checklist** (*Preproduction*, 18 ítems): boundaries, spacing,
  sightlines, choke points, focal points, pathways, height. Grilla de revisión del rediseño.
- **Cadena espacial de flujo** (*Preproduction*): `Cama > Recepción > Grúa > Prensa >
  Carga > Tienda` — verificar que el recorrido físico fluya en ese orden.
- **Muñeco de escala ~1,8 m** en cada boceto (Galuzin): validar corredores, cama, y el
  radio de 20 m de visión nocturna antes de blockear.
- **Intensity/beats chart de la jornada** (*In Pursuit*): mapear 09:00→03:00 como curva,
  diseñar el pico y el final de cada noche (peak-end).
- **Focus list de blockout** (Galuzin Ch13): Escala · Integración de gameplay ·
  Proporción · Pace & flow · testers. Checklist de cada greybox.
- **Master list de spawns** (Totten *Processes*): planilla de dónde aparece cada auto y
  cada anomalía, para visualizar densidad y evitar avalanchas (principio 7).

---

## 8. Próximos pasos sugeridos

1. Elegir/mezclar alternativa de layout (§4).
2. Dibujar el bubble diagram + top-down definitivo con el muñeco de escala.
3. Re-blockear el patio en Godot con el nuevo layout (volúmenes grandes primero, cortar
   sightlines, plantar el landmark de pórtico), validar que el loop sigue siendo divertido.
4. Tematizar las 3 zonas (materiales/luz) — barato con la paleta low-poly.
5. Prototipar C1 (irrupción forzada) primero: es el sector de castigo más barato.
