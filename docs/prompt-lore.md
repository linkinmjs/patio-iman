# Prompt para iterar el lore de Patio Imán

> Copiar y pegar todo lo que está debajo de la línea en la IA con la que se quiera iterar.
> Para rondas siguientes, usar los "comandos de iteración" del final.

---

Sos un diseñador narrativo senior especializado en terror psicológico para videojuegos. Vas a ayudarme a desarrollar el lore de mi juego indie. Trabajamos por iteraciones: en esta primera ronda me entregás **3 conceptos de lore distintos entre sí**, yo elijo, mezclo o descarto, y en rondas siguientes profundizamos.

## El juego (esto ya existe, no lo cambies)

**Patio Imán** es un juego en primera persona para PC hecho en Godot. El jugador es un operario en un patio de chatarra:

- **Loop de juego:** llegan autos al patio → el jugador los inspecciona y les saca piezas valiosas (looteo) → los levanta con una grúa electromagnética (hay una grúa de pórtico fija y una grúa móvil tipo tractor) → los compacta en una prensa → lleva los cubos a una zona de carga que paga dinero → gasta el dinero en una terminal de compras (mejoras).
- **Ciclo día/noche:** la jornada arranca a las 06:00, un día dura 20 minutos reales. De noche el patio se ilumina con faroles y una linterna comprable. El jugador está solo.
- **Progresión:** tienda de mejoras (linterna, kit de despiece, y a futuro: aspiradora magnética, escáner de VIN, robot ayudante, etc.) y tres árboles de talentos planificados: Operador, Capataz e Investigador.
- **Física real:** los autos son cuerpos rígidos con peso, se balancean colgados del imán, se abollan al compactarse. El "feel" industrial de masa y metal es central.

**Semillas narrativas que ya existen y quiero aprovechar (podés reinterpretarlas, no ignorarlas):**

1. **VIN duplicados.** La idea fundacional del juego: entre los autos que llegan aparecen VIN que no deberían existir — duplicados, de autos que ya fueron compactados, de autos que nunca se fabricaron. Hay "expedientes anómalos" que el jugador puede investigar de forma optativa.
2. **El desconocido.** Ya está implementado un evento único: una figura se asoma por encima de una pared del patio y mira fijo al jugador. Si el jugador la ve, se esconde y el jugador murmura para sí mismo ("¿Y ese quién era? Me estaba... ¿mirando?"). Nadie le cree al operario.
3. **El arma.** El jugador podrá comprar una pistola (una Bersa o un revólver) con balas escasas. No es un juego de disparos: el arma tiene mucho retroceso, el operario no sabe usarla, y **nunca sirve contra lo paranormal**. Es un placebo de control: el jugador la compra porque se siente perseguido, y lo más útil que puede hacer con ella es tiro al blanco. Quiero que el lore explote esa impotencia.
4. **Trofeos/objetos con lore.** Objetos coleccionables encontrados en los autos que cuentan historias en miniatura. Ejemplo ya definido: un pinito aromatizante para colgar del espejo... con un mordisco humano.
5. **Tres finales esbozados (negociables):** *Obediencia* (maximizás la productividad, firmás el protocolo de despacho autónomo y dejás el patio funcionando solo), *Auditoría* (juntás pruebas y exponés la red detrás de los autos anómalos), *Rescate* (reconstruís el auto clave en lugar de compactarlo).

## Tono que busco

**Terror psicológico.** No hay zombies, no hay monstruos que persigan ni ataquen, no hay combate contra enemigos. El horror es paranormal y ambiguo: anomalías que no dan mucha información pero asustan. El jugador nunca está seguro de si lo que vio pasó de verdad. El peligro casi nunca es un "game over": es la sensación de que el patio sabe cosas.

Referencias tonales (por si las conocés): *Voices of the Void* (rutina laboral + anomalías que observan pero rara vez atacan), *Paratopic*, *Iron Lung*, el terror de "trabajo mundano que se tuerce" tipo *Mouthwashing*. La rutina del trabajo es el ancla: el terror funciona porque el 90% del tiempo el juego es honestamente un simulador de chatarrería satisfactorio.

## Restricciones duras (si un concepto las viola, descartalo)

- **Nada de combate.** Las anomalías no se pelean. El arma existe justamente para subrayar que no sirve.
- **Ambigüedad sostenida.** El lore nunca se explica del todo, ni siquiera en los finales. Cada concepto debe decirme explícitamente qué se revela y qué queda sin explicar jamás.
- **Anomalías baratas de producir.** Soy un solo desarrollador. Las anomalías deben construirse con lo que el juego ya tiene: autos, la grúa, la prensa, luces, sonido, radio, el escáner, la física, la noche. Ejemplo del tipo de cosa que puedo hacer: un auto que aparece en el patio sin que llegue ningún camión, con el motor todavía caliente; la prensa que devuelve un cubo más pesado de lo que entró; un VIN que el escáner se niega a leer dos veces igual. Nada de criaturas animadas complejas ni cinemáticas.
- **El trabajo sigue siendo el juego.** La narrativa es optativa y escondida: alimenta la curiosidad sin romper el loop. El jugador que solo quiere compactar autos puede ignorarla casi toda.
- **Sin gore gratuito ni jumpscares baratos.** Se permite lo perturbador implícito (el pinito mordido) por encima de lo explícito.

## Qué me tenés que entregar (formato por concepto)

Para cada uno de los 3 conceptos:

1. **Logline** (2-3 oraciones): el pitch del lore completo.
2. **Quién es el operario y por qué está ahí.** Su pasado importa: quiero protagonistas con un motivo creíble para no irse del patio aunque pasen cosas raras (deuda, duelo, negación, no tener adónde ir).
3. **Qué son las anomalías** (la "verdad" detrás, aunque el jugador nunca la vea completa): ¿los autos cargan memoria? ¿el patio es un lugar liminal? ¿la red de VIN duplicados esconde algo peor que fraude? Definilo para mí como autor, aunque en el juego quede ambiguo.
4. **Escalada en 4 actos** atada a la progresión: qué anomalías aparecen al principio (sutiles, negables), en el medio, en el final. La progresión económica del jugador (mejoras, talentos, automatización) debería empeorar o revelar el misterio, no ser paralela a él.
5. **10 anomalías jugables concretas**, ordenadas de sutil a fuerte, todas construibles con los sistemas que listé. Cada una en una línea.
6. **Integración con las semillas:** cómo encajan en tu concepto los VIN duplicados, el desconocido, el arma-placebo y 3 trofeos con lore nuevos que propongas (al estilo del pinito mordido).
7. **Qué se explica / qué nunca se explica.** Dos listas explícitas.
8. **Finales:** adaptá los tres finales existentes a tu concepto o proponé mejores, justificando el cambio.
9. **El riesgo del concepto:** vos mismo señalá la mayor debilidad de tu propuesta (cliché, costo de producción, tono).

Los 3 conceptos deben ser genuinamente distintos: por ejemplo, uno más "explícito" (hay una historia concreta detrás: gente, crímenes, fantasmas de alguien), uno más abstracto (lo que pasa no tiene traducción humana: anomalía, entidad, lugar), y uno intermedio o híbrido que vos consideres el más fuerte.

## Cómo te voy a evaluar

- **Coherencia mecánica:** el lore nace de las mecánicas (imán, prensa, VIN, dinero) en vez de estar pegado encima.
- **Producibilidad:** todo lo propuesto lo puede hacer una persona sola con assets simples.
- **Miedo real:** las anomalías dan miedo por contexto y acumulación, no por susto puntual.
- **Ambigüedad con dirección:** misterioso no significa arbitrario; como autor yo tengo que saber la verdad aunque el jugador no.
- **Rejugabilidad de la duda:** idealmente el jugador termina el juego sin poder afirmar qué fue real.

## Comandos de iteración (rondas siguientes)

Después de tu primera entrega te voy a responder con alguno de estos pedidos, respetá el formato:

- `PROFUNDIZAR <concepto>`: desarrollá ese concepto al triple de detalle (cronología completa de la verdad, 20 anomalías, todos los textos de expedientes).
- `MEZCLAR <concepto A> + <concepto B>`: fusioná lo mejor de ambos en un concepto nuevo.
- `MÁS SUTIL` / `MÁS EXPLÍCITO`: recalibrá el último concepto hacia ese extremo del espectro.
- `ANOMALÍAS <tema>`: generá 15 anomalías jugables nuevas sobre ese tema específico.
- `ABOGADO DEL DIABLO`: atacá tu propio último concepto como si fueras un crítico hostil, y después defendelo o corregilo.

Si algo del contexto te resulta ambiguo, no me preguntes: asumí lo más razonable y anotá tus suposiciones al final. Respondé siempre en español.
