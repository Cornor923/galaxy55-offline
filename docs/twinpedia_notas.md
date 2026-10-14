# Notas de la Twinpedia de Galaxy 55 (resumen propio, no copia literal)

Fuentes: copias de Wayback Machine de twinpedia.com/galaxy55 (2012-2014) que el usuario pegó en la conversación.

## Versiones (página "versions")
- Pre-alfa 15-mar-2012: modificar la planeta minando kubes.
- Alfa 1 12-abr-2012: láser para cavar; cargas especiales; halo amarillo = acceso a la nave; producir kubes dentro de la nave; vender mineral a la ESCorp (créditos galácticos); si mueres o usas el botón de volver a la nave, tus kubes y cargas quedan en el sitio.
- Alfa 2 14-may-2012: nuevo tipo de planeta; la nave aparece en el cielo (se sube por una columna luminosa); ordenador de a bordo -> modificar la nave en el hangar del astropuerto; el casco debe ser de kubes blindados (aluminio); sintetizador de kubes en la nave.
- Alfa 3 20-jul-2012: multijugador; 3 tipos de planeta nuevos; muchos kubes nuevos; galaxia por la que se mueve la nave; miniatura de la nave en el espacio; licencias (máx. 3 planetas); dos cargas nuevas (violeta y verde).
- Cierre temporal el 15 de febrero (año no indicado en el texto pegado).

## Modificar la nave (hangar)
- Se entra con el ordenador de a bordo (E sobre él) -> "Modificar la nave". Te teletransporta a un hangar de 19x19x14 kubes; zona construible 17x17x14 (una línea se reserva para moverse). 4 kubes teletransportadores para salir; flechas en el suelo marcan el frente (importa para motores).
- Velocidad en verde si la nave es válida; mensaje rojo con la primera regla incumplida (en orden). Salir con nave inválida pide confirmación y no guarda.
- Reglas: (1) kubes imprescindibles: teletransportador (debajo de 2 kubes completamente vacíos), ordenador de a bordo (al menos una cara al interior), losa de ensamblaje (>=1; 1 kube vacío encima, y encima intangible), sintetizador (accesible, intangible), motor(es) (la cara trasera libre y al exterior). (2) Estanqueidad con kubes de aluminio (blindaje, ventana blindada, puerta cerrada...). (3) Unidad: todo conectado (diagonales no valen por fuera). (4) Propulsión: velocidad = (motores*10)/(total_kubes-1), 2 decimales hacia abajo, mínimo 0,13 PC/s. En la alfa 3 no se podían fabricar motores.
- IDs de kubes de nave (tabla de la wiki): 48 Blindage, 49 Moteur spatial, 50 Vitre blindée, 54 Porte blindée, 55 Dalle blindée, 56 Blindage strié, 57 Ordinateur de bord, 58 Tuyaux blindés, 59 HUD blindé, 60 Téléporteur, 61 Dalle d'assemblage, 204 Vitre blindée teintée.
- NOTA: el cliente YA contiene este editor (EditShip.hx, net/EditShip.hx); aquí se conectó en local (net/EditShipLocal.hx).

## Viajes espaciales
- Ordenador de a bordo -> "Décoller": pasas al mapa del sistema solar; clic donde quieras ir. Cruzar la línea de puntos = salir al sector (cuadrados = sistemas; número esquina inferior derecha = planetas disponibles; esquinas verdes = tienes planetas ahí).
- Nombre de planeta = sistema + letra griega por distancia al sol (5ª = EPSILON).
- Licencias: máx. 3 (tienes 3). Para otra: "supprimer" en el panel izquierdo; el borrado es definitivo. En una planeta nueva: "scanner cette planète".

## Introducción
- Se empieza dentro de la nave en el espacio: eliges sistema -> planeta -> "Escanear este planeta". Recomendados: Tierra Roja, Arenas Áridas, Picos Nevados.
- Para bajar: moverse adelante/atrás sobre la casilla de salida. El rayo amarillo vuelve a la nave.
- Láser mejorado con cargas amarillas (citronox viejo, para Rosh), azules (eterio azul). Rouge'rosh -> pirita/bauxita.
- En la nave: ordenador a la izquierda; 4 baldosas amarillas = losas de ensamblaje; jaula a la derecha = resultado, se coge con Shift.
- Multijugador: en el espacio, "Opciones" de tu licencia -> escribir nombres para invitar.

## Controles oficiales
ZQSD / WASD / flechas; Espacio o Ctrl = jetpack; clic izq mantenido = girar; rueda = elegir; E o Shift = recoger/poner/usar ordenador/sintetizador/puertas; R = soltar todos los kubes de una casilla; Tab = taladro; 1-9; T = escribir; Enter = pantalla completa; Esc = salir de pantalla completa; F = datos (X,Y,Z); H = visera; * (numérico) = cambiar controles clásicos/ratón; F2 = captura.

## Recetas (página "assemblages", ver también DataGen.CRAFT)
60 recetas en el cliente; se comparó cada resultado de la wiki con las salidas del cliente: coinciden todos.
