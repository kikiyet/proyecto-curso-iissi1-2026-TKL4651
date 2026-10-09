# Título Proyecto

## Miembros del grupo LX-XXX-X (sustituir)

1. Robles Pérez, Javier 
1. Rodríguez Gallego, Eloy
1. Martínez Adega, Nicolás
1. García Martínez, Daniel

## 1. Introducción al problema

- EquipaUS sustituye el cuaderno de papel y la hoja de cálculo con los que hoy se prestan portátiles, cámaras, gafas de realidad virtual y kits de electrónica en la Escuela, por un sistema que sabe en todo momento qué unidad tiene cada persona y hasta cuándo.

## 1.1. Cliente y usuarios
• Cliente: el Servicio de Préstamo de Material Técnico de la Escuela (técnicos de laboratorio y conserjería), responsable de un inventario de unos 300 equipos cuyo valor supera con holgura los 150.000 €.
• Usuarios: la comunidad universitaria: estudiantes de grado y máster (los más numerosos, sobre todo en épocas de TFG/TFM), Personal Docente e Investigador (PDI) y Personal Técnico, de Gestión y de Administración y Servicios (PTGAS).


## 1.2. Situación actual
-El préstamo funciona así: el estudiante se acerca al mostrador, el técnico mira una hoja de Excel compartida para ver si queda alguna unidad libre, apunta a mano en un cuaderno el nombre, el DNI, el equipo y la fecha prevista de devolución, y entrega el material. Las reservas para días posteriores se piden por correo electrónico y se anotan, si se recuerda, en la misma hoja.

## 1.3. Problemas detectados

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

## 4. Catálogo de requisitos

### 4.1. Requisitos funcionales

#### R.F.01. Título requisito funcional

Como [tipo de usuario]
quiero [servicio]
para [razón]

**Prueba de aceptación**
- Descripción de la primera comprobación a realizar
- Descripción de la segunda comprobación a realizar
- Se debe aplicar la regla de negocio R.N.XX.
- ...

#### 4.1.1. Requisitos de información

##### R.I.01. Título requisito de información

Como [tipo de usuario]
quiero [servicio]
para [razón]

**Prueba de aceptación**
- Descripción de la primera comprobación a realizar
- Descripción de la segunda comprobación a realizar
- ...

#### 4.1.2. Reglas de negocio

##### R.N.01. Título regla negocio

Descripción de la regla de negocio.

### 4.2. Mapa de historias de usuario (opcional)

### 4.3. Requisitos no funcionales (opcional)

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


