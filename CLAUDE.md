# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este proyecto

**Patio Imán** es un juego en primera persona para PC (Godot 4.7) donde el jugador opera una grúa electromagnética y una prensa compactadora en un patio de chatarra, con una narrativa escondida sobre autos con VIN duplicados. El proyecto está en fase inicial: todavía no hay escenas ni scripts, solo la configuración del engine y el documento de diseño.

El documento de diseño es `docs/analisis-inicial.md` (en español). **Es un análisis inicial, no verdad absoluta**: sirve como referencia de partida para gameplay, economía y progresión (loop completo, tabla de upgrades/talentos, valores de balance, parámetros de feel, finales), pero puede sufrir modificaciones. Ante conflicto entre el documento y una decisión del usuario, gana el usuario.

## Hoja de ruta (prioridades definidas por el usuario)

Trabajar en este orden, un hito por vez:

1. Player jugable (primera persona, a pie)
2. Grúa manipulable
3. Autos con gravedad (RigidBody)
4. Mecánica grúa ↔ autos (imantar, levantar, soltar)
5. Máquina compresora — solo comprime si el auto está bien acomodado
6. Transporte de autos comprimidos a una zona de carga que paga dinero
7. **Checkpoint** (loop mecánico mínimo completo)
8. Armar loop de juego (economía, turnos)
9. Armar talentos
10. etc.

## Configuración del engine

- Godot **4.7**, renderer **Forward Plus**, driver **D3D12** en Windows.
- Física 3D: **Jolt Physics** (ya configurado en `project.godot`).
- Stretch: `canvas_items` / aspect `expand`.
- Ejecutable de Godot (no está en PATH): `C:\Users\Mauri\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe` (la variante `_console` emite stdout/stderr en terminal; la variante sin sufijo abre sin consola).

## Comandos

```powershell
$godot = "C:\Users\Mauri\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe"

# Verificar que el proyecto carga sin errores de script/escena (usar tras cada cambio)
& $godot --headless --path . --import
& $godot --headless --path . --quit-after 2

# Correr el juego (escena principal) — para que el usuario lo pruebe
& $godot --path .

# Correr una escena específica
& $godot --path . res://scenes/algo.tscn
```

El usuario prueba el juego desde el editor de Godot (F5); la verificación headless sirve para detectar errores de parseo y de carga antes de entregarle nada, pero no reemplaza el feedback de "feel" del usuario.

## Decisiones de diseño clave (resumen del documento)

**Loop central:** escanear auto entrante → levantarlo con la grúa → (opcional) despiece de piezas valiosas → compactar en la prensa → cobrar y comprar upgrades → investigar expedientes anómalos. Fórmula económica visible: `ingreso = chatarra + piezas + bono de maniobra + bono de contrato − penalizaciones`, con `chatarra = toneladas ferrosas × 110 × pureza × multiplicador de prensa`.

**Dos modos de control:** a pie (WASD, E interactuar, F escáner, Tab tablet) y grúa (WASD mueve el carro del pórtico, Q/E sube/baja imán, LMB energiza imán, RMB modo precisión, Space suelta/pulso, 1/2/3 cámaras auxiliares). Los bindings completos están en el documento.

**Física híbrida, no simulación total:** autos como RigidBody con puntos ferrosos de anclaje, suspensión simplificada, piezas desprendibles seleccionadas y **4 estados de deformación procedimental** al compactarse — nada de soft-body ni destrucción total. Parámetros de feel propuestos: damping de balanceo 0.72, desvío lateral máx. 18°, ventana de "drop perfecto" (centro < 0.6 m, vel. vertical < 1.4 m/s, ángulo < 7°), modo precisión = velocidad −60% / damping +50%.

**Presupuesto de performance:** 60 FPS en GPU media, máximo **6 autos físicamente "awake"** a la vez, pool de debris de 120–180 piezas, rigidbodies en sleep con activación por proximidad, 2 LODs fuertes para autos lejanos.

**Progresión en cuatro capas:** upgrades de máquina (dinero), tres árboles de talento (Operador / Capataz / Investigador, puntos de operador), automatización idle a mitad de juego (yardbot, autocargador, despacho en ausencia), y meta-progresión por Insignias de Operador que cambian corridas nuevas. Cada mejora debe producir un cambio *visible* en el patio, no solo un número.

**Plan de prototipado:** empezar por el verbo y el feel, no por la historia — greybox mecánico primero (1 patio, 1 auto, 1 grúa, 1 prensa) y validar que levantar/balancear/compactar ya sea divertido antes de agregar sistemas.

## Convenciones

- Todo el texto de diseño, UI y comunicación con el usuario es en **español** (con tildes correctas). Identificadores de código en inglés siguiendo las convenciones de GDScript (snake_case para funciones/variables, PascalCase para clases/nodos).
