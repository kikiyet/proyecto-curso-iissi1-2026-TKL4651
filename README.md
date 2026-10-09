# Título Proyecto

## Miembros del grupo   L5-AM-7

1. Robles Pérez, Javier 
2. Rodríguez Gallego, Eloy
3. Martínez Adega, Nicolás
4. García Martínez, Daniel

## 1. Introducción al problema

• EquipaUS sustituye el cuaderno de papel y la hoja de cálculo con los que hoy se prestan portátiles, cámaras, gafas de realidad virtual y kits de electrónica en la Escuela, por un sistema que sabe en todo momento qué unidad tiene cada persona y hasta cuándo.

### 1.1. Cliente y usuarios
• Cliente: el Servicio de Préstamo de Material Técnico de la Escuela (técnicos de laboratorio y conserjería), responsable de un inventario de unos 300 equipos cuyo valor supera con holgura los 150.000 €.
• Usuarios: la comunidad universitaria: estudiantes de grado y máster (los más numerosos, sobre todo en épocas de TFG/TFM), Personal Docente e Investigador (PDI) y Personal Técnico, de Gestión y de Administración y Servicios (PTGAS).


### 1.2. Situación actual
• El préstamo funciona así: el estudiante se acerca al mostrador, el técnico mira una hoja de Excel compartida para ver si queda alguna unidad libre, apunta a mano en un cuaderno el nombre, el DNI, el equipo y la fecha prevista de devolución, y entrega el material. Las reservas para días posteriores se piden por correo electrónico y se anotan, si se recuerda, en la misma hoja.

### 1.3. Problemas detectados

|           Problema               |                           Ejemplo real del día a día                          |
|----------------------------------|--------------------------------------------------------------------------------
| Sin trazabilidad                 | Nadie sabe quién tuvo la cámara que apareció con la lente rayada              |
| Dobles reservas                  | Dos grupos cuentan con el mismo proyector para su defensa de TFG el mismo día |
| Retrasos sin consecuencia        | Un portátil se devuelve con tres semanas de retraso                           |
| Equipos averiados en circulación | Se vuelve a prestar unas gafas VR con el cable roto                           |
| Cero datos para decidir          | No se sabe qué equipos tienen lista de espera                                 |

|               Consecuencia                  |
|---------------------------------------------|
| Material dañado o «perdido» sin responsable |
| Conflictos y defensas retrasadas            |
| Otros estudiantes se quedan sin equipo      |
| Mala imagen del servicio y más averías      |
| Se compra material que nadie pide           |

### 1.4. Expectativas
• Que el solicitante consulte en tiempo real el catálogo y la disponibilidad desde el móvil, sin tener que ir al mostrador para preguntar.
• Que sea imposible asignar la misma unidad a dos personas en el mismo periodo.
• Que los retrasos y los daños generen sanciones automáticas, sin depender de que el técnico se acuerde.
• Que un equipo averiado quede fuera de circulación hasta que se repare.
• Que el responsable del servicio disponga de estadísticas de uso para justificar compras y bajas.

## 2. Glosario de términos

- Términos específicos del dominio del problema, ordenados alfabéticamente. Se valorará la presencia de información multimedia.

## 3. Visión general del sistema

### 3.1. Requisitos generales
El sistema debe cubrir cinco áreas:
1. Gestión de usuarios: registro de solicitantes y personal del servicio, con su rol y su situación (activo o penalizado).
2. Catálogo e inventario: alta, modificación y baja de modelos y de cada artículo físico, con su estado en todo momento.
3. Reservas y préstamos: reservar con antelación, convertir la reserva en préstamo al recoger el material y registrar la devolución, garantizando que una unidad nunca se asigna dos veces en el mismo periodo.
4. Incidencias y penalizaciones: registrar daños y pérdidas, retirar de circulación los equipos afectados y sancionar automáticamente retrasos e incidencias graves.
5. Consultas y estadísticas: listados para el día a día (préstamos vencidos, equipos en reparación) y datos de uso para la toma de decisiones.

### 3.2. Usuarios del sistema

| Usuario | Quién es | Qué hace en el sistema |
| :--- | :--- | :--- |
| **Solicitante – Estudiante** | Alumnado de grado y máster | Consulta el catálogo, reserva, ve sus préstamos, su historial y sus penalizaciones. |
| **Solicitante – Personal (PDI / PTGAS)** | Profesorado y personal de la universidad | Lo mismo que el estudiante, con un periodo de préstamo más largo y más préstamos simultáneos (ver RN01 y RN02). |
| **Técnico** | Personal del mostrador y de los laboratorios | Entrega y recoge material, registra incidencias, cambia el estado de los artículos y consulta préstamos vencidos. |
| **Responsable del servicio** | Coordinador/a del servicio | Gestiona el catálogo y el inventario, levanta penalizaciones y consulta las estadísticas de uso. |


## 4. Catálogo de requisitos

### 4.1. Requisitos funcionales

• En este entregable solo se recogen requisitos funcionales de listado y consulta. Cada uno indica qué reglas de negocio (apartado 4.1.2) deben respetarse.

#### RF01. Consultar el catálogo por categorías

• Como solicitante quiero ver todos los modelos del catálogo agrupados por categoría, con su foto, descripción y número de unidades disponibles, para saber rápidamente qué material puedo pedir.

#### Prueba de aceptación
• Los modelos aparecen agrupados por categoría y, dentro de cada una, ordenados alfabéticamente por marca y nombre.
• No aparecen modelos cuyas unidades estén todas De baja.
• El número de unidades disponibles no cuenta las que están En revisión, En reparación o De baja. Se debe aplicar la regla de negocio RN06.

#### RF02. Consultar la disponibilidad de un modelo en unas fechas

• Como solicitante quiero indicar un modelo y un periodo de fechas y ver cuántas unidades están libres en ese periodo, para saber si puedo reservarlo antes de planificar mi práctica o mi grabación.

#### Prueba de aceptación
• Si el periodo coincide aunque sea parcialmente con una reserva o préstamo de una unidad, esa unidad no se cuenta como libre. Se debe aplicar la regla de negocio RN05.
• Las unidades no prestables nunca se cuentan como libres. Se debe aplicar la regla de negocio RN06.
• Si el periodo supera la duración máxima del solicitante o empieza con más de 14 días de antelación, se muestra un aviso en lugar del resultado. Se deben aplicar las reglas de negocio RN02 y RN08.

#### RF03. Consultar mis reservas y préstamos activos

• Como solicitante quiero ver mis reservas pendientes y mis préstamos en curso con su fecha límite, para no olvidar ninguna recogida ni devolución.

#### Prueba de aceptación
• Se listan ordenados por fecha límite (o fecha de recogida, en reservas) de la más próxima a la más lejana.
• Los préstamos cuya fecha límite ya ha pasado aparecen marcados como «Vencido» con los días de retraso.
• Se muestra cuántos préstamos activos lleva frente a su máximo permitido (p. ej. «1 de 2»). Se debe aplicar la regla de negocio RN01.


#### RF04. Consultar mi historial de préstamos

• Como solicitante quiero consultar todos los préstamos que he tenido, para saber qué equipos he usado y si alguno se devolvió con retraso o con daños.

#### Prueba de aceptación

• Se listan del más reciente al más antiguo, con modelo, fechas de inicio, límite y devolución real.
• Los préstamos devueltos tarde muestran los días de retraso y los que tuvieron incidencia muestran su gravedad.
• Un solicitante solo puede ver su propio historial.

#### RF05. Consultar mi situación de penalización

• Como solicitante quiero saber si estoy penalizado, por qué y hasta cuándo, para entender por qué no puedo reservar y cuándo podré volver a hacerlo.

#### Prueba de aceptación

• Si hay una penalización activa se muestra su motivo, el préstamo o la incidencia que la originó y la fecha de fin. Se debe aplicar la regla de negocio RN03.
• Los días de penalización mostrados coinciden con el cálculo de la regla correspondiente. Se deben aplicar las reglas de negocio RN04, RN07 y RN09.
• Si no hay penalización activa se indica «Sin penalizaciones» y se muestran las ya cumplidas.

#### RF06. Listar préstamos vencidos
• Como técnico quiero un listado de los préstamos no devueltos cuya fecha límite ya ha pasado, para reclamar el material a quien lo tiene.

#### Prueba de aceptación


• Solo aparecen préstamos sin fecha de devolución real y con fecha límite anterior al momento actual.
• Se ordenan por días de retraso, de mayor a menor, mostrando nombre, correo y teléfono del solicitante, artículo y penalización prevista. Se debe aplicar la regla de negocio RN04.
• Un préstamo con la fecha límite dentro de una hora no aparece todavía.

#### RF07. Listar la agenda del mostrador del día

• Como técnico quiero ver las reservas que se recogen hoy y los préstamos que vencen hoy, para tener preparado el material y saber qué devoluciones esperar.

#### Prueba de aceptación

• Aparecen en dos bloques (recogidas y devoluciones) ordenados por hora.
• Las reservas que han superado su margen de recogida se marcan como «Caducada». Se debe aplicar la regla de negocio RN09.

#### RF08. Consultar el historial de un artículo

• Como técnico quiero consultar, escaneando su código de inventario, todos los préstamos e incidencias de un artículo, para saber quién lo tenía cuando se estropeó.

#### Prueba de aceptación

• Se muestra el estado actual del artículo y, en orden cronológico inverso, todos sus préstamos (con solicitante y técnicos de entrega y recogida) y todas sus incidencias.
• Si el código no existe se muestra «Artículo no encontrado».

#### RF09. Listar artículos fuera de servicio

• Como técnico quiero listar los artículos En revisión o En reparación con la incidencia que los retiró, para hacer seguimiento de las reparaciones pendientes.

#### Prueba de aceptación

• Solo aparecen artículos en esos dos estados, ordenados por antigüedad de la incidencia.
• Cada fila muestra la gravedad y el coste estimado de reparación. Se deben aplicar las reglas de negocio RN06 y RN07.

#### RF10. Listar solicitantes penalizados

• Como responsable del servicio quiero ver los solicitantes con una penalización activa, para revisar casos y atender reclamaciones.
                  
#### Prueba de aceptación

• Solo aparecen penalizaciones cuya fecha de fin es posterior al momento actual. Se debe aplicar la regla de negocio RN03.
• Se puede filtrar por motivo (retraso, incidencia grave, reservas no recogidas).

#### RF11. Consultar el ranking de modelos más demandados

• Como responsable del servicio quiero ver los 10 modelos con más préstamos del curso académico actual y su porcentaje de ocupación, para justificar la compra de nuevas unidades.

#### Prueba de aceptación

• El curso académico se considera del 1 de septiembre al 31 de agosto.
• Los préstamos se cuentan por modelo, sumando todas sus unidades; las reservas caducadas o canceladas no cuentan.
• En caso de empate se ordena alfabéticamente por modelo.
#### RF12. Consultar el inventario por estado y categoría

• Como responsable del servicio quiero un resumen del número de artículos de cada categoría en cada estado y su valor de compra total, para conocer el estado real del parque tecnológico.

#### Prueba de aceptación
• La suma de todas las celdas coincide con el total de artículos registrados.
• Los artículos De baja aparecen en su propia columna y no suman al valor del inventario activo.

#### 4.1.1. Requisitos de información

#### RI01. Información de usuarios

• Como responsable del servicio quiero almacenar el UVUS, DNI/NIE, nombre, apellidos, correo institucional, teléfono, tipo de usuario (estudiante, PDI, PTGAS, técnico o responsable) y fecha de alta de cada usuario, para identificar a quién se presta cada equipo y poder contactarle.

#### Prueba de aceptación

• No se puede dar de alta un usuario con un UVUS o un DNI/NIE ya registrado.
• El DNI/NIE debe tener formato válido (8 cifras y letra, o X/Y/Z + 7 cifras + letra).
• El correo debe terminar en @us.es o @alum.us.es.
• Todos los campos son obligatorios salvo el teléfono.

#### RI02. Información de categorías y modelos

• Como responsable del servicio quiero almacenar las categorías (nombre y descripción) y, para cada modelo, su marca, nombre comercial, descripción, especificaciones técnicas, fotografía y categoría, para mostrar un catálogo claro a los solicitantes.

#### Prueba de aceptación

• No pueden existir dos categorías con el mismo nombre ni dos modelos con la misma marca y nombre comercial.
• Todo modelo pertenece obligatoriamente a una única categoría.
• No se puede borrar una categoría que tenga modelos asociados.

#### RI03. Información de artículos físicos

• Como técnico quiero almacenar de cada unidad física su código de inventario, número de serie, modelo, fecha de adquisición, precio de compra, ubicación (laboratorio o armario) y estado, para saber exactamente qué equipo es y dónde está.

#### Prueba de aceptación

• El código de inventario y el número de serie son únicos.
• La fecha de adquisición no puede ser posterior a la fecha actual y el precio de compra debe ser mayor que 0.
• El estado solo puede tomar los valores Disponible, Prestado, En revisión, En reparación o De baja.
• Todo artículo pertenece obligatoriamente a un modelo.

#### RI04. Información de reservas

• Como solicitante quiero que se guarde de cada reserva quién la hace, qué artículo, cuándo se creó, la fecha y hora previstas de recogida y de devolución, y su estado (Pendiente, Recogida, Cancelada o Caducada), para asegurarme el material que necesito en una fecha concreta.

#### Prueba de aceptación

• La fecha de recogida no puede ser anterior a la fecha de creación de la reserva.
• La fecha prevista de devolución debe ser posterior a la de recogida.
• Toda reserva nueva se crea en estado Pendiente.

#### RI05. Información de préstamos

• Como técnico quiero almacenar de cada préstamo el solicitante, el artículo, la reserva de la que procede (si la hay), el técnico que lo entrega, la fecha y hora de inicio, la fecha límite de devolución, la fecha y hora de devolución real, el técnico que lo recoge y el estado en que vuelve el material (Correcto o Con daños), para tener la trazabilidad completa de cada equipo.

#### Prueba de aceptación

• La fecha límite debe ser posterior a la fecha de inicio.
• La fecha de devolución real, si existe, no puede ser anterior a la de inicio.
• Si la fecha de devolución real está vacía, el préstamo se considera en curso.
• El técnico que recoge y el estado de vuelta solo pueden registrarse si hay fecha de devolución real.

#### RI06. Información de incidencias

• Como técnico quiero almacenar de cada incidencia el artículo afectado, el préstamo en que se detectó (si lo hay), el técnico que la registra, la fecha, una descripción, una foto opcional del daño, la gravedad (Leve, Grave o Pérdida), el coste estimado de reparación y su estado (Abierta, En reparación, Resuelta o Baja definitiva), para controlar las averías y saber quién es responsable.

#### Prueba de aceptación

• La gravedad y el estado solo admiten los valores indicados.
• El coste estimado, si se indica, debe ser mayor o igual que 0.
• La fecha de la incidencia no puede ser anterior a la fecha de inicio del préstamo asociado.

#### RI07. Información de penalizaciones

• Como responsable del servicio quiero almacenar de cada penalización el solicitante, el motivo (Retraso, Incidencia grave o Reservas no recogidas), el préstamo o la incidencia que la originó, la fecha de inicio, la fecha de fin y si fue levantada manualmente y por quién, para aplicar las sanciones de forma justa y poder revisarlas.

#### Prueba de aceptación
• La fecha de fin debe ser posterior a la de inicio.
• Toda penalización por Retraso o por Incidencia grave debe estar asociada al préstamo o la incidencia que la causó.
• Solo un usuario de tipo responsable puede figurar como quien levanta una penalización.

#### 4.1.2. Reglas de negocio

#### RN01. Máximo de préstamos simultáneos

• Un estudiante no puede tener a la vez más de 2 reservas pendientes o préstamos en curso en total; el personal (PDI/PTGAS), no más de 4. Al intentar superar el límite, la reserva se rechaza con el mensaje «Has alcanzado el máximo de N préstamos activos».

#### RN02. Duración máxima del préstamo

• La fecha límite de devolución no puede superar 3 días naturales desde el inicio del préstamo para estudiantes y 7 días para el personal. Los 
modelos de la categoría Realidad Virtual tienen un máximo de 24 horas para cualquier solicitante, por su alta demanda.

#### RN03. Bloqueo por penalización activa
• Un solicitante con una penalización cuya fecha de fin aún no ha llegado no puede crear reservas ni recibir préstamos. Sí puede devolver el material que tenga y consultar sus datos.

#### RN04. Penalización automática por retraso

• Al registrar una devolución posterior a la fecha límite se genera automáticamente una penalización de 2 días por cada día (o fracción) de retraso, con un máximo de 60 días. Si el solicitante ya estaba penalizado, la nueva penalización empieza cuando termine la anterior.

#### RN05. Sin solapamiento sobre un mismo artículo

• Un artículo no puede tener dos reservas pendientes o préstamos en curso cuyos periodos se solapen, aunque sea un minuto. Si dos solicitantes intentan reservar la misma unidad a la vez, solo una de las operaciones se confirma.

#### RN06. Solo se prestan artículos operativos

• Un artículo en estado En revisión, En reparación o De baja no puede asociarse a ninguna reserva ni préstamo nuevo. Toda devolución deja el artículo En revisión hasta que un técnico lo comprueba y lo pasa a Disponible.

#### RN07. Consecuencias de una incidencia grave

• Al registrar una incidencia de gravedad Grave, el artículo pasa automáticamente a En reparación y el solicitante responsable recibe una penalización de 30 días. Si la gravedad es Pérdida, el artículo pasa a De baja y la penalización es de 90 días.

#### RN08. Antelación máxima de las reservas

• No se puede reservar con más de 14 días de antelación, para que los equipos no queden bloqueados semanas por reservas «por si acaso».

#### RN09. Caducidad de reservas no recogidas

• Una reserva que no se recoge en las 2 horas siguientes a su hora de recogida pasa a Caducada y la unidad queda libre. Si un solicitante acumula 3 reservas caducadas en el mismo cuatrimestre, recibe una penalización de 7 días.


#### Pruebas de aceptación de las reglas de negocio

| Regla | Situación inicial | Acción | Resultado esperado |
|-------|-------------------|--------|--------------------|
| RN01 | La estudiante Lucía tiene 2 préstamos en curso | Intenta reservar un kit Arduino | Se rechaza: «Has alcanzado el máximo de 2 préstamos activos» |
| RN02 | Un estudiante reserva unas Meta Quest 3 | Pide devolverlas 48 h después de recogerlas | Se rechaza; la fecha límite máxima permitida es de 24 h |
| RN03 | Pablo tiene una penalización hasta el 30/10 | El 25/10 intenta reservar una cámara | Se rechaza e indica «Penalizado hasta el 30/10» |
| RN04 | Un portátil tenía fecha límite el 20/10 a las 14:00 | Se devuelve el 23/10 a las 10:00 (3 días o fracción de retraso) | Se crea automáticamente una penalización de 6 días |
| RN05 | El proyector PRY-004 está reservado del 20/10 al 22/10 | Otro usuario intenta reservar PRY-004 del 21/10 al 23/10 | Se rechaza; el resto de proyectores libres sigue disponible |
| RN06 | La cámara CAM-002 está En reparación | Un técnico intenta prestarla en el mostrador | Se rechaza y la cámara no cuenta como disponible en RF01/RF02 |
| RN07 | Unas gafas VR vuelven con la lente rota | El técnico registra una incidencia Grave | Las gafas pasan a En reparación y el solicitante recibe 30 días de penalización |
| RN08 | Hoy es 08/10 | Un usuario intenta reservar para el 30/10 | Se rechaza: solo se admite hasta el 22/10 |
| RN09 | Ana tiene 2 reservas caducadas este cuatrimestre | No recoge una tercera reserva en 2 horas | La reserva pasa a Caducada y Ana recibe 7 días de penalización |

### 4.2. Mapa de historias de usuario (opcional)

## Doce consultas repartidas en cuatro actividades

| Explorar catálogo<br><sub>Solicitante</sub> | Mis préstamos<br><sub>Solicitante</sub> | Atender mostrador<br><sub>Técnico</sub> | Dirigir servicio<br><sub>Responsable</sub> |
| :--- | :--- | :--- | :--- |
| **RF01**<br>Catálogo | **RF03**<br>Préstamos activos | **RF06**<br>Préstamos vencidos | **RF10**<br>Penalizados |
| **RF02**<br>Disponibilidad | **RF04**<br>Mi historial | **RF07**<br>Agenda del día | **RF11**<br>Más demandados |
| | **RF05**<br>Mis penalizaciones | **RF08**<br>Vida de un artículo | **RF12**<br>Inventario |
| | | **RF09**<br>Fuera de servicio | |

*Mapa de historias de usuario · 4 actividades, 12 requisitos funcionales*

*Cada columna es una actividad de un tipo de usuario; debajo, los requisitos funcionales que la cubren.*
### 4.3. Requisitos no funcionales (opcional)

* **RNF01. Integridad ante accesos simultáneos:** Como solicitante quiero que, si otra persona reserva la misma unidad en el mismo instante, solo una de las dos reservas se confirme, para no presentarme en el mostrador y encontrarme sin equipo (soporta RN05).
* **RNF02. Tiempo de respuesta:** Como solicitante quiero que el catálogo y la disponibilidad (RF01, RF02) se muestren en menos de 2 segundos, para poder consultarlos desde el móvil entre clases.
* **RNF03. Protección de datos personales:** Como responsable del servicio quiero que los datos personales (DNI, teléfono) solo sean visibles para el personal del servicio y se traten conforme al RGPD, para cumplir la normativa de la universidad.
* **RNF04. Acceso con la cuenta universitaria:** Como usuario quiero iniciar sesión con mi UVUS, sin crear otra contraseña, para no tener que recordar una cuenta más.
* **RNF05. Uso desde el móvil:** Como solicitante quiero que la aplicación se adapte a la pantalla del móvil, para poder reservar desde cualquier sitio.

**R.N.F. 01. Título requisito no funcional**
Como [tipo de usuario]
quiero [servicio]
para [razón]

-- fin entregable 1 --

## 5. Modelo conceptual

### 5.1. Diagramas de clases UML

- con restricciones.

### 5.2. Escenarios de prueba

- con descripción textual y diagrama de objetos UML.

## 6. Matrices de trazabilidad

- Matriz de trazabilidad entre los elementos del modelo conceptual y los requisitos.

|       | EntidadX   | AsociaciónX  | RestricciónX  | Entidad2 ...   | 
|:------|:-----------|:-----------|:-----------|:-----------|
| RI-1  | X          | X          | X          | X          |
| RI-2  |            | X          |            | X          |
| RF-1  |            | X          |            | X          |
| RF-2  | X          |            | X          | X          |
| RN-1  |            | X          |            |            |
| RN-2  | X          | X          | X          |            |
| ...   |            |            |            |            |

-- fin entregable 2 --

## 7. Modelo relacional en 3FN

- Relaciones obtenidas al aplicar la transformación del modelo conceptual.

### 7.1.  Justificación de la estrategia de transformación de jerarquías

- si se identificaron jerarquías en el MC.


### 8. Matriz de trazabilidad MC/SQL (opcional):

- Restricciones sobre el MC / Elementos del modelo tecnológico (SQL) (Triggers, checks, etc.)
- Incluir Reglas de negocio — Constraints/Triggers en las matrices de trazabilidad para el entregable 3

|       | EntidadX   | AsociaciónX  | RestricciónX  | Entidad2 ...   | 
|:-------|:-------|:-------|:-------|:-------|
| TABLA-1 |        |        |        |        |
| TABLA-2 |        |        |        |        |
| TABLA-3 |        |        |        |        |
| TABLA-4 |        |        |        |        |
| TRIG-1 |        |        |        |        |
| TRIG-2 | X      | X      |        | X      |
| TRIG-3 |        | X      |        | X      |
| TRIG-4 |        |        | X      |        |
| CONST-1 |        |        |        |        |
| CONST-2 | X      | X      |        | X      |
| CONST-3 |        | X      |        | X      |
| CONST-4 |        |        | X      |        |

Se consideran todo tipo de constraints declarativas (aquellas definidas durante el CREATE TABLE).
-- fin entregable 3 --

## Referencias


