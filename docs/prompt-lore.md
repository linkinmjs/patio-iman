# Prompt para iterar el lore de Patio Imán

> Copiar y pegar todo lo que está debajo de la línea en la IA con la que se quiera iterar.
> Para rondas siguientes, usar los "comandos de iteración" del final.

---

Sos un diseñador narrativo senior especializado en terror psicológico para videojuegos. Vas a ayudarme a desarrollar el lore de mi juego indie. Trabajamos por iteraciones: en esta primera ronda me entregás **3 conceptos de lore distintos entre sí**, yo elijo, mezclo o descarto, y en rondas siguientes profundizamos.

## El juego (esto ya existe, no lo cambies)

**Patio Imán** es un juego en primera persona para PC hecho en Godot. El jugador es un operario en un patio de chatarra:

- **Loop de juego (early/mid/late):** llegan autos al patio → el jugador los inspecciona y les saca piezas valiosas (looteo) → compacta los restos en una prensa → lleva los cubos a una zona de carga que paga dinero → gasta el dinero en una terminal de compras (mejoras). La grúa electromagnética (pórtico fijo + grúa móvil) es una mejora de mid/late game que eventualmente puede automatizarse.
- **Ciclo día/noche:** la jornada arranca a las 09:00 y se congela a las 03:00; el jugador debe dormir en la casilla (E) para pasar al día siguiente. De noche el patio se ilumina solo con faroles distribuidos y una linterna comprable (tecla T). La oscuridad es real: de noche solo se ve ~20 m de radio. El jugador está completamente solo. Hay climas variables (despejado, nublado, niebla, lluvia, ventoso) que afectan visibilidad, sonido y física.
- **Progresión:** tienda de mejoras únicas (linterna, kit de despiece, destornillador, grúa electromagnética, etc.). Cada mejora es un upgrade específico, no un árbol de habilidades.
- **Física real:** los autos son cuerpos rígidos con peso, comportamiento físico realista. El "feel" industrial de masa y metal es central.
- **Assets low-poly:** la visualización es minimalista. Las anomalías narrativas se cuentan más que se ven: sustancias que brotan, sonidos imposibles, comportamientos.

**Semillas narrativas que ya existen y quiero aprovechar:**

1. **El arma + mecánica de luces.** El jugador compra un revólver .38 ($1.200) y cajas de balas ($150). El arma tiene retroceso fuerte, miras de hierro que requieren puntería de novato, sin retícula en pantalla. Su verdadero uso: **algunos foquitos de luz en el patio parpadean de noche** (anomalía paranormal). Si el jugador dispara al foco parpadante y lo rompe, la anomalía se detiene momentáneamente. Si **no** dispara y deja que parpadee, sufre un efecto paranormal fuerte (embriaguez visual, alucinaciones auditivas, pérdida de orientación temporal) durante unos minutos. El arma es un "control falso": sirve para mitigar síntomas, no para resolver el problema. Nunca mata entidades paranormales.
2. **Los desconocidos/acosadores.** Hay múltiples presencias en el patio que se manifiestan de noche:
   - Una **silueta humanoide** ("Merodeador") que camina lentamente hacia el jugador mirándolo fijo. Si el jugador sostiene la linterna encima durante 1.5 s se disuelve; si llega a 3.5 m del jugador: zoom dramático, se desvanece, el jugador murmura ("¿Qué era eso?"). Nunca ataca.
   - Un **disco volador** que aparece algunas noches, se detiene en el medio del patio, después sigue. El jugador puede dispararle con el revólver y obtener un trofeo ("Fragmento del disco").
   - Posiblemente otros seres/entidades por definir en el lore.
3. **Trofeos/objetos con lore.** Objetos coleccionables encontrados en los autos o ganados en combates (disparar al disco, sobrevivir noches) que cuentan historias en miniatura. Ejemplos: un pinito aromatizante con un mordisco humano, un fragmento del disco volador, una foto quemada, etc.
4. **Dos finales esbozados (como ejemplos, podés proponer mejores):** *Aceptación* (el jugador acepta lo que está pasando y continúa trabajando indefinidamente, automatizando lo máximo posible) y *Ruptura* (el jugador intenta escapar o sabotear algo, con consecuencias).

## Tono que busco

**Terror psicológico puro, sin crimen.** No hay historias de delito, fraude ni gente muerta. El horror es paranormal, psicodélico, apocalíptico: anomalías que no obedecen lógica humana pero asustan profundamente. El jugador nunca está seguro de si lo que vio pasó de verdad o si su mente se está quebrando. El peligro casi nunca es un "game over": es la **sensación progresiva de que el patio es un lugar donde la realidad funciona diferente**. La luz y la oscuridad son mecánicas emocionales: la noche no es solo un ciclo, es una amenaza.

Referencias tonales: *Voices of the Void* (rutina laboral + anomalías que observan pero rara vez atacan), *Paratopic*, *Iron Lung*, *Cosmic Horror* abstracto tipo Lovecraft sin monstruos visuales, el malestar de *Enter the Gungeon* o *Control*. La rutina del trabajo es el ancla: el terror funciona porque el 90% del tiempo el juego es un simulador de chatarrería satisfactorio, y las anomalías irrumpen sin patrón visible.

## Restricciones duras (si un concepto las viola, descartalo)

- **Nada de crimen, culpa humana, ni muertes explicables.** El horror no viene de "malas personas", viene de lo paranormal e incomprehensible. Sin fraude, sin crímenes, sin gente muerta cuya historia hay que descubrir.
- **Nada de combate.** Las anomalías paranormales no se "pelean". El arma sirve solo para mitiga síntomas (romper focos parpadantes), no para resolverlas.
- **Ambigüedad sostenida.** El lore nunca se explica del todo, ni siquiera en los finales. Cada concepto debe decirme explícitamente qué se revela y qué queda sin explicar jamás. El jugador termina sin certeza.
- **Anomalías baratas de producir.** Soy un solo desarrollador con assets low-poly. Las anomalías deben construirse con lo que el juego ya tiene: autos, la prensa, luces, sonido, clima, la noche, la física. **Ejemplos del tipo de cosa que puedo hacer:**
  - Un auto que drena una sustancia fluorescente permanentemente, dejando un charco que brilla.
  - Un auto que tiembla o emite sonidos (gritos, murmullos, carraspeos) sin razón aparente.
  - Un auto que enciende y apaga sus luces internas en secuencia cuando el jugador se aleja.
  - Una luz de farol que parpadea de forma errática, y si no se dispara al foco sufres alucinaciones auditivas.
  - Un auto cuya prensa sale más pesado de lo que entró, sin explicación.
  - La temperatura cae sin razón (mecánica invisible pero narrada por efectos visuales: niebla anómala, aliento visible).
  - Voces débiles en la radio del patio que dicen cosas sin contexto.
  - Un auto que aparece en el patio sin que llegue ningún camión (teletransporte).
  - Nada de criaturas animadas complejas ni cinemáticas. Todo debe caber en sistemas ya existentes.
- **El trabajo sigue siendo el juego.** La narrativa es optativa y escondida: alimenta curiosidad y duda sin romper el loop. El jugador que solo quiere compactar autos puede ignorarla casi toda.
- **La luz es mecánica de seguridad emocional, no física.** Iluminar con la linterna no hace que las anomalías desaparezcan; pero psicológicamente, estar en la luz se siente mejor. Algunos efectos paranormales (como los focos parpadantes) requieren acción con el arma.
- **Sin gore gratuito ni jumpscares baratos.** Se permite lo perturbador implícito (el pinito mordido, el fragmento del disco) por encima de lo explícito.

## Qué me tenés que entregar (formato por concepto)

Para cada uno de los 3 conceptos:

1. **Logline** (2-3 oraciones): el pitch del lore completo. Recordá: **nada de crimen, muertes humanas ni culpa**.
2. **Quién es el operario y por qué está ahí.** Su pasado importa: quiero protagonistas con un motivo creíble para no irse del patio aunque pasen cosas raras (aislamiento voluntario, curiosidad morbosa, incapacidad de irse, negación, depresión, algo paranormal lo mantiene ahí). Nada de deudas criminales ni culpa por delitos.
3. **Qué son las anomalías** (la "verdad" detrás, aunque el jugador nunca la vea completa): ¿el patio es un lugar liminal entre realidades? ¿los autos son vehículos de algo? ¿la oscuridad tiene propiedades activas? ¿existe una entidad o múltiples? Definilo para mí como autor, aunque en el juego quede ambiguo y nunca se confirme.
4. **Escalada en 4 actos** atada a la progresión: qué anomalías aparecen al principio (sutiles, negables), en el día 5-10 (extrañas pero interpretables), en late game (aterradoras pero aún ambiguas), y en el final (punto de ruptura). La progresión económica del jugador (mejoras, automatización) debería cambiar cómo experimenta las anomalías, no ignorarlas.
5. **10 anomalías jugables concretas**, ordenadas de sutil a fuerte, todas construibles con: autos + comportamiento físico, prensa, luces/faroles, sonido, clima, noche, oscuridad. **Cada una en máximo 1-2 oraciones.** Ejemplos tipo que puedo hacer: auto que drena sustancia, auto que tiembla/grita, auto cuyas luces parpadean, foco que parpadea anómalo, prensa que devuelve peso extra, temperatura invisible que cae, radio que emite voces sin contexto, auto que aparece sin camión.
6. **Integración con las semillas:** cómo encajan el arma-placebo (romper focos parpadantes mitiga síntomas), los desconocidos/acosadores (Merodeador, Disco, posibles otros), y 4 trofeos con lore nuevos que propongas (al estilo del pinito mordido, fragmento del disco). **Sin VIN duplicados.**
7. **Qué se explica / qué nunca se explica.** Dos listas explícitas. La regla: si el jugador puede deducirlo de anomalías + finales, va en "explica". Si es la verdad detrás que solo vos como autor sabés, va en "nunca explica".
8. **Dos finales** (estos son ejemplos negociables): adaptá *Aceptación* y *Ruptura* a tu concepto o proponé mejores. **Cada final debe cambiar el comportamiento del patio visiblemente**, no solo ser un cinemática.
9. **El riesgo del concepto:** vos mismo señalá la mayor debilidad de tu propuesta (¿es demasiado cliché? ¿muy caro de producir? ¿el tono se rompe en algún punto?).

Los 3 conceptos deben ser **genuinamente distintos**: por ejemplo, uno más "cósmico/abstracto" (lo que pasa no tiene traducción humana), uno más "íntimo/psicológico" (algo pasa dentro de la mente del operario), y uno que vos consideres el más fuerte (tal vez híbrido o una tercera perspectiva).

## Cómo te voy a evaluar

- **Coherencia mecánica:** el lore nace de las mecánicas (luz/oscuridad, arma-placebo, prensa, autos, dinero) en vez de estar pegado encima. Las anomalías deberían hacerse más presentes con progresión y oscuridad.
- **Producibilidad extrema:** todo lo propuesto lo puede hacer una persona sola con assets low-poly. Nada de modelos complejos, cinemáticas, criaturas animadas. Solo: comportamientos físicos, luces, sonido, clima, scripts.
- **Miedo por acumulación, no por jump:** las anomalías dan miedo por repetición, patrón, contexto, ambigüedad. No por sorpresas de una sola vez.
- **Ambigüedad con dirección:** misterioso no significa arbitrario. Como autor vos tenés que saber la verdad detrás aunque el jugador nunca la vea. Cada anomalía apunta a algo coherente, aunque sea contradictorio.
- **Nada de crimen en la fundación:** el lore no puede descansar en "alguien hizo algo malo". Puede descansar en "el lugar es raro", "la realidad es diferente acá", "algo existe que no comprendemos".
- **Rejugabilidad de la duda:** idealmente el jugador termina sin poder afirmar: ¿estaba yo cuerdo? ¿qué era real? ¿el patio cambió o yo cambié?

## Comandos de iteración (rondas siguientes)

Después de tu primera entrega te voy a responder con alguno de estos pedidos, respetá el formato:

- `PROFUNDIZAR <concepto>`: desarrollá ese concepto al triple de detalle (cronología completa de la "verdad" detrás, 20 anomalías jugables, diálogos del operario, todos los trofeos con lore).
- `MEZCLAR <concepto A> + <concepto B>`: fusioná lo mejor de ambos en un concepto híbrido nuevo.
- `MÁS SUTIL` / `MÁS PSICODÉLICO`: recalibrá el último concepto hacia ese extremo del espectro.
- `ANOMALÍAS <tema>`: generá 15 anomalías jugables nuevas sobre ese tema específico (ej: "anomalías de luz", "anomalías auditivas", "anomalías de tiempo").
- `EXPANDIR FINALES`: desarrollá en detalle cómo se ve/juega cada final, qué cambia en el patio, qué ve el jugador.
- `ABOGADO DEL DIABLO`: atacá tu propio último concepto como si fueras un crítico hostil señalando clichés, problemas de producción, etc. Después defendelo o corregilo.

Si algo del contexto te resulta ambiguo o queda sin implementar (ej: "¿cuál es el día 1 del jugador?"), no me preguntes: asumí lo más razonable y anotá tus suposiciones al final. Respondé siempre en español.
