# Ideas (versión nativa)

[English: `IDEAS.en.md`](IDEAS.en.md) · [Français : `IDEAS.fr.md`](IDEAS.fr.md)

Ideas para más adelante: **nada de esto está decidido ni empezado**. Lo que ya se va a hacer está en
[`PENDIENTES.md`](PENDIENTES.md). La regla del proyecto sigue siendo ser fiel al original y no romper la inmersión: antes de
añadir algo nuevo, se habla con la comunidad.

## Viaje espacial

La exploración espacial se queda: es parte de la identidad del juego (Cornor923). Ideas para que el viaje y la velocidad de la
nave (motores y peso, como en el original) importen más:

- **Combustible** (la favorita por ahora): viajar por el mapa gasta energía según la distancia; una nave pesada gasta más.
  Se recarga con cristales (Citronox, Etherium). Añade estrategia, sin convertir el viaje en un trámite.
- **Desbloquear sistemas** (del original): un tercio de los sistemas salen con candado y se abrían pagando una licencia
  (1500). En el port se ve el candado, pero el botón todavía no hace nada.
- **Planetas lejanos más ricos** (Cornor923): cuanto más lejos del sistema inicial, más minerales raros. Sin tocar los
  biomas originales, solo cuánto mineral sale.
- **Un planeta "base"** (Cornor923).
- **Robot comerciante que se aleja:** viaja más lejos y a veces se va a sistemas lejanos; con una nave rápida lo alcanzas antes.
- **Motores turbo** (Cornor923 recordaba que se encontraban explorando): en los datos del original solo hay un tipo de motor;
  los objetos raros que sí existen son la bomba antigua, la luz negra y el turbo minero (este acelera el excavador). Sería
  un añadido nuevo.

## Agua y lava

- **Lava + agua (o cascada) = basalto** (recuerdo de Sekhmet, "basalto infinito"). El código del cliente original no lo hace:
  la lava solo reemplaza el agua y el basalto solo sale del congelador. Quizá lo hacía el servidor, que no se publicó.
  **Pendiente de decidir.**
- **El nivel del mar baja** al llenar huecos (recuerdo de Sekhmet de la 3.ª versión de las alfas: el mar se extiende y el
  nivel global baja según la proporción agua/espacio, nunca sube). Ahora el mar llena todo hasta su nivel, como el código original.
- **Cubo para coger agua o lava:** descartado por ahora (a Cornor923 no le convence: el traje "ya lo hace").

## Equipo del personaje

Un inventario de equipo aparte (casco, traje, mochila, botas…) con mejoras que se fabrican o se compran al robot:
mochila de gran capacidad (más combustible del jetpack), turbo de jetpack, recarga rápida, botas de salto, botas
antideslizantes (hielo), amortiguadores (cuando haya daño por caída), excavador mejorado, bolsa ampliada, linterna de casco,
imán para los bloques sueltos, traje térmico o tanque de oxígeno (cuando haya oxígeno y daño).

## Contenido nuevo

- **Contenido de Kube** (el juego de bloques anterior de Motion Twin) como planetas nuevos, sin tocar los originales (Cornor923).
- **Fósiles:** en el original no servían para nada y pedían el láser morado, muy raro (Cornor923). Darles un uso.

## Multijugador y web

- **Versión web en Eternaltwin:** Biosha ofrece alojarla con servidor (PostgreSQL, Node/Rust/PHP, entrada con OAuth).
  Primero tiene que funcionar en el navegador para un jugador, y todavía falta bastante.
- **Naves de jugador:** como máximo 17×17×14 (el hangar del original); aparcan dentro de bahías (nave nodriza, gremios).
- **Naves de gremio:** más grandes, con hangar compartido y permisos de quién puede romper bloques. No aparcan dentro: se
  acoplan desde fuera con tubos de acoplamiento.
- **Tiendas de jugadores:** puestos en la zona de comercio de la nave nodriza o un mostrador en la nave de un gremio; un
  tablón de ofertas entre jugadores.
- Cuidar el rendimiento en el navegador (mundos pequeños y fijos, mallas que no se rehacen, límite de jugadores visibles).
