# Catálogo de mejoras — Tienda del patio

Referencia de diseño para las compras del juego. Inspiración directa: la
aspiradora de *berry bury berry* — compras que agregan **verbos nuevos** o
quitan **fricciones sentidas**, no solo números que suben.

## Filosofía

Cada mejora tiene que cumplir tres condiciones:

1. **Resolver un dolor que el jugador ya sintió.** La compra se "necesita":
   antes de verla en la tienda, el jugador ya se quejó de eso jugando.
2. **Cambio visible en el patio** (regla del documento de diseño): se tiene
   que *ver* o *sentir* de inmediato, no ser solo un stat.
3. **Dejar deseo pendiente**: el nivel comprado insinúa el siguiente
   ("si con la amoladora vuelo... imaginate el plasma").

## Economía de referencia

Con el loop actual, una jornada trabajada rinde aproximadamente:

| Fuente | Por auto | Por día (8 autos) |
|---|---|---|
| Bloque compactado | $120 | ~$960 |
| Partes looteadas (2-3) | ~$90 | ~$500 (no se lootea todo) |
| Bono de maniobra | $40 | ~$80-160 |
| **Total estimado** | | **~$1.200-1.600** |

Guía de precios: la primera compra debe caer al final de la jornada 1-2
(~$400-900); un nivel máximo debe costar 2-3 jornadas enfocadas (~$3.000-5.000).

---

## Tanda 1 — ya comprables en la terminal

### 1. Kit de despiece (3 niveles) — $400 / $1.200 / $3.000
- **Dolor:** lootear tarda 4 s parado al lado del auto, y es la actividad
  que más se repite.
- **N1 Amoladora:** looteo en 2.6 s.
- **N2 Cizalla hidráulica:** looteo en 1.6 s.
- **N3 Cortadora de plasma:** looteo en 1.2 s y **+1 parte por auto**.
- Ya estaba anotado en `pendientes.md` como progresión de looteo.

### 2. Electroimán industrial (2 niveles) — $900 / $2.200
- **Dolor:** hay que dejar el imán casi tocando el auto para que enganche;
  la atracción apenas mueve un auto pesado.
- **N1 Bobina reforzada:** atrae con +50% de fuerza y captura desde 1.4 m.
- **N2 Bobina de obra pesada:** atracción ×2.2 y captura desde 1.9 m —
  los autos "saltan" al imán, se siente poderosísimo.

### 3. Estabilizador giroscópico (2 niveles) — $800 / $2.000
- **Dolor:** el péndulo balancea la carga y arruina el drop perfecto
  (el bono de $40 queda difícil).
- **N1:** amortiguación ×2.2 — el balanceo muere enseguida.
- **N2 Amortiguación activa:** ×4 — el imán viaja clavado; farmear el bono
  de maniobra pasa a ser un plan de negocio.

### 4. Motor repotenciado (grúa móvil, 2 niveles) — $700 / $1.800
- **Dolor:** el tractor es lentísimo cruzando el patio.
- **N1:** +40% de velocidad.
- **N2 Turbo diésel:** ×1.9 y más empuje de tanque.
- *Futuro (nivel 3 u objeto aparte "Oruga reforzada"):* pasar por encima de
  escombros chicos — cierra el pendiente de feel tanque.

### 5. Pistones de alto tonelaje (prensa, 2 niveles) — $1.500 / $3.500
- **Dolor:** la prensa tarda 15 s por ciclo y el bloque siempre vale $120.
- **N1:** bloques +25% ($150) y ciclo 30% más corto.
- **N2:** bloques +50% ($180) y ciclo a la mitad.
- Es el "multiplicador de prensa" de la fórmula visible del documento.

### 6. Contrato ampliado (3 niveles) — $600 / $1.500 / $3.500
- **Dolor:** la recepción corta en 8 autos y la jornada se queda sin materia
  prima justo cuando el jugador ya mejoró sus herramientas.
- **N1/N2/N3:** +2 / +4 / +7 autos por día (8 → 10 → 12 → 15).
- El límite de 6 autos *simultáneos* no cambia (presupuesto de performance);
  cambia el ritmo de reposición.

---

## Tanda 2 — diseñadas, para próximos hitos

### 7. MagVac (aspiradora imantada, 3 niveles) — $1.000 / $2.400 / $5.000 ⭐
- **El homenaje directo a berry bury berry.** Herramienta de mano equipable.
- **Dolor:** llevar partes al pozo de a una, caminando, es el mayor tiempo
  muerto del juego.
- **N1:** mantener click succiona partes sueltas en un cono de ~4 m;
  tanque de 3. Click derecho las escupe en arco (al pozo o donde apuntes).
- **N2:** tanque de 6, succión más ancha y rápida.
- **N3 Turbina doble:** tanque de 10 y escupida precisa a mayor distancia —
  "ametralladora de repuestos".
- Verbo nuevo + feedback físico (partes volando al pozo). Es la compra
  estrella de la mitad temprana del juego.

### 8. Escáner VIN de mano (2 niveles) — $600 / $2.500 🔍
- **Dolor:** no sabés qué partes tiene un auto (¿vale la pena lootearlo o
  lo prenso directo?).
- **N1:** la tecla F (ya reservada en los bindings) escanea el auto apuntado:
  lista de partes, valor total estimado, tonelaje.
- **N2 Modo forense:** detecta **anomalías** — VIN duplicados, números
  limados. Es la puerta de entrada a la narrativa de expedientes: la mejora
  se compra por plata, pero lo que revela alimenta la historia.

### 9. Guía láser de prensa (1 nivel) — $500
- **Dolor:** el bono de maniobra se juega a ciegas (centro < 0.6 m, < 7°).
- Proyecta la silueta objetivo en el piso de la tolva y cambia de color
  (rojo → verde) cuando el drop actual calificaría como perfecto.
- Barata a propósito: enseña la mecánica del bono y hace desear el
  estabilizador giroscópico.

### 10. Remolque portabloques (2 niveles) — $1.800 / $3.600
- **Dolor:** cada bloque es un viaje del tractor a la zona de carga.
- **N1:** tráiler enganchado a la grúa móvil con 2 posiciones para bloques
  (el imán los apoya encima); en la zona de carga se venden solos.
- **N2:** 4 posiciones y enganche rápido.

### 11. Yardbot "Ciru" (2 niveles) — $4.500 / $8.000 🤖
- Primer paso de la **automatización idle** del documento (mitad de juego).
- **N1:** robotito que patrulla, junta partes sueltas del piso y las lleva
  al pozo (lento, de a una — verlo trabajar es el chiste).
- **N2:** canasto para 3 partes y más velocidad.
- Convierte el "dejé partes tiradas" en ingreso pasivo y llena el patio de
  vida. Antesala del autocargador y el despacho en ausencia.

### 12. Tolva del pozo (1 nivel) — $900
- **Dolor:** hay que embocar las partes dentro del pozo; las que pegan en
  el borde rebotan afuera.
- Boca ensanchada con rampas + succión suave cerca del borde: lo que cae
  cerca, entra. Sinergia obvia con la MagVac.

### 13. Rieles extendidos del pórtico (1 nivel) — $2.800
- **Dolor:** la grúa fija llega hasta donde llega; el resto del patio es
  territorio exclusivo del tractor.
- Extiende el recorrido del carro del pórtico para cubrir la recepción,
  encadenando recepción → prensa sin bajarse.

---

## Notas de balance

- Los efectos se centralizan en `GameState.effect(clave, valor_base)`:
  los sistemas leen su parámetro efectivo ahí, así los talentos (punto 9)
  podrán apilar sobre las mismas claves.
- Precios pensados para que cada jornada permita una compra que se sienta,
  con las de tanda 2 como metas de mediano plazo.
- Orden de implementación sugerido para la tanda 2: guía láser (barata y
  chica) → MagVac (hito propio) → escáner VIN (abre narrativa) → remolque →
  yardbot → tolva → rieles.
