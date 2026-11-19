-- =============================================================================
-- EquipaUS · Entregable 3 · 1.scripts_tablas_restricciones.sql
-- Creación de las tablas con sus restricciones declarativas (PRIMARY KEY,
-- UNIQUE, CHECK y FOREIGN KEY).
-- SGBD: MariaDB 10.5 o superior. Orden de ejecución:
--   1 (tablas) -> 2 (funciones y procedimientos) -> 4 (triggers) ->
--   5 (poblado) -> 3 (consultas) -> demostraciones de los triggers del script 4
-- =============================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS EquipaUS
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE EquipaUS;

-- -----------------------------------------------------------------------------
-- Borrado previo, para poder ejecutar los scripts varias veces.
-- Los triggers se borran solos al borrar su tabla.
-- -----------------------------------------------------------------------------
DROP EVENT     IF EXISTS eCaducarReservas;
DROP PROCEDURE IF EXISTS pComprobarSolicitante;
DROP PROCEDURE IF EXISTS pComprobarTecnico;
DROP PROCEDURE IF EXISTS pCaducarReservas;
DROP PROCEDURE IF EXISTS pRecogerReserva;
DROP PROCEDURE IF EXISTS pRegistrarDevolucion;
DROP PROCEDURE IF EXISTS pRevisarArticulo;
DROP PROCEDURE IF EXISTS pCancelarReserva;
DROP PROCEDURE IF EXISTS pLevantarPenalizacion;
DROP PROCEDURE IF EXISTS pProbar;
DROP PROCEDURE IF EXISTS pInsertarUsuario;
DROP PROCEDURE IF EXISTS pAltaModelo;
DROP PROCEDURE IF EXISTS pInsertarArticulo;
DROP PROCEDURE IF EXISTS pVariablesDemo;
DROP PROCEDURE IF EXISTS pDemoTrig01;
DROP PROCEDURE IF EXISTS pDemoTrig02;
DROP PROCEDURE IF EXISTS pDemoTrig03;
DROP PROCEDURE IF EXISTS pDemoTrig04;
DROP PROCEDURE IF EXISTS pDemoTrig05;
DROP PROCEDURE IF EXISTS pDemoTrig06;
DROP PROCEDURE IF EXISTS pDemoTrig07;
DROP PROCEDURE IF EXISTS pDemoTrig08;
DROP PROCEDURE IF EXISTS pDemoTrig09;
DROP PROCEDURE IF EXISTS pDemoTrig10;
DROP PROCEDURE IF EXISTS pDemoTrig11;
DROP PROCEDURE IF EXISTS pDemoTrig12;
DROP PROCEDURE IF EXISTS pDemoTrig13;
DROP PROCEDURE IF EXISTS pDemoTrig14;
DROP PROCEDURE IF EXISTS pDemoTrig15;
DROP VIEW      IF EXISTS vSolicitantes;
DROP VIEW      IF EXISTS vModelos;
DROP VIEW      IF EXISTS vPrestamos;
DROP VIEW      IF EXISTS vPenalizaciones;
DROP FUNCTION  IF EXISTS fNumActivos;
DROP FUNCTION  IF EXISTS fPenalizadoEn;
DROP FUNCTION  IF EXISTS fDuracionMaxima;
DROP FUNCTION  IF EXISTS fDiasRetraso;
DROP FUNCTION  IF EXISTS fCuatrimestre;
DROP FUNCTION  IF EXISTS fUnidadesDisponibles;
DROP TABLE     IF EXISTS Penalizaciones;
DROP TABLE     IF EXISTS Incidencias;
DROP TABLE     IF EXISTS Prestamos;
DROP TABLE     IF EXISTS Reservas;
DROP TABLE     IF EXISTS Articulos;
DROP TABLE     IF EXISTS Modelos;
DROP TABLE     IF EXISTS Categorias;
DROP TABLE     IF EXISTS Usuarios;

-- -----------------------------------------------------------------------------
-- TABLA-01 · Usuarios
-- Toda la jerarquía Usuario / Solicitante / Estudiante / PDI / Tecnico en una
-- sola tabla con el discriminador "tipo" (justificación en el apartado 7.1).
-- -----------------------------------------------------------------------------
CREATE TABLE Usuarios (
  usuarioId  INT          NOT NULL AUTO_INCREMENT,
  uvus       VARCHAR(20)  NOT NULL,
  dni        CHAR(9)      NOT NULL,
  nombre     VARCHAR(60)  NOT NULL,
  apellidos  VARCHAR(100) NOT NULL,
  email      VARCHAR(120) NOT NULL,
  telefono   VARCHAR(15)  NULL,
  fechaAlta  DATE         NOT NULL,
  tipo       ENUM('ESTUDIANTE', 'PDI', 'TECNICO') NOT NULL,
  CONSTRAINT pk_usuarios        PRIMARY KEY (usuarioId),
  CONSTRAINT uq_usuarios_uvus   UNIQUE (uvus),                                   -- R1
  CONSTRAINT uq_usuarios_dni    UNIQUE (dni),                                    -- R2
  CONSTRAINT ck_usuarios_dni    CHECK (dni REGEXP '^([0-9]{8}|[XYZ][0-9]{7})[A-Z]$'),  -- R3
  CONSTRAINT ck_usuarios_email  CHECK (                                          -- R4
    (tipo = 'ESTUDIANTE' AND email LIKE '%@alum.us.es')
    OR (tipo IN ('PDI', 'TECNICO') AND email LIKE '%@us.es'))
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-02 · Categorias
-- -----------------------------------------------------------------------------
CREATE TABLE Categorias (
  categoriaId  INT          NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(60)  NOT NULL,
  descripcion  VARCHAR(500) NOT NULL,
  CONSTRAINT pk_categorias         PRIMARY KEY (categoriaId),
  CONSTRAINT uq_categorias_nombre  UNIQUE (nombre)                               -- R5
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-03 · Modelos
-- -----------------------------------------------------------------------------
CREATE TABLE Modelos (
  modeloId          INT           NOT NULL AUTO_INCREMENT,
  categoriaId       INT           NOT NULL,
  marca             VARCHAR(60)   NOT NULL,
  nombreComercial   VARCHAR(100)  NOT NULL,
  descripcion       VARCHAR(1000) NOT NULL,
  especificaciones  VARCHAR(2000) NOT NULL,
  fotografia        VARCHAR(255)  NOT NULL,
  CONSTRAINT pk_modelos              PRIMARY KEY (modeloId),
  CONSTRAINT uq_modelos_marca_nombre UNIQUE (marca, nombreComercial),           -- R6
  CONSTRAINT fk_modelos_categoria    FOREIGN KEY (categoriaId)                  -- A01, R32
    REFERENCES Categorias (categoriaId) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-04 · Articulos
-- -----------------------------------------------------------------------------
CREATE TABLE Articulos (
  articuloId        INT           NOT NULL AUTO_INCREMENT,
  modeloId          INT           NOT NULL,
  codigoInventario  VARCHAR(20)   NOT NULL,
  numeroSerie       VARCHAR(50)   NOT NULL,
  fechaAdquisicion  DATE          NOT NULL,
  precioCompra      DECIMAL(10,2) NOT NULL,
  ubicacion         VARCHAR(100)  NOT NULL,
  estado            ENUM('DISPONIBLE', 'PRESTADO', 'EN_REVISION', 'EN_REPARACION', 'DE_BAJA')
                    NOT NULL DEFAULT 'DISPONIBLE',
  CONSTRAINT pk_articulos         PRIMARY KEY (articuloId),
  CONSTRAINT uq_articulos_codigo  UNIQUE (codigoInventario),                     -- R7
  CONSTRAINT uq_articulos_serie   UNIQUE (numeroSerie),                          -- R8
  CONSTRAINT ck_articulos_precio  CHECK (precioCompra > 0),                      -- R10
  CONSTRAINT fk_articulos_modelo  FOREIGN KEY (modeloId)                         -- A02
    REFERENCES Modelos (modeloId) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-05 · Reservas
-- -----------------------------------------------------------------------------
CREATE TABLE Reservas (
  reservaId                INT      NOT NULL AUTO_INCREMENT,
  solicitanteId            INT      NOT NULL,
  articuloId               INT      NOT NULL,
  fechaCreacion            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fechaRecogida            DATETIME NOT NULL,
  fechaDevolucionPrevista  DATETIME NOT NULL,
  estado                   ENUM('PENDIENTE', 'RECOGIDA', 'CANCELADA', 'CADUCADA')
                           NOT NULL DEFAULT 'PENDIENTE',
  CONSTRAINT pk_reservas             PRIMARY KEY (reservaId),
  CONSTRAINT ck_reservas_recogida    CHECK (fechaRecogida >= fechaCreacion),               -- R11
  CONSTRAINT ck_reservas_devolucion  CHECK (fechaDevolucionPrevista > fechaRecogida),      -- R12
  CONSTRAINT ck_reservas_antelacion  CHECK (fechaRecogida <= fechaCreacion + INTERVAL 14 DAY), -- R30
  CONSTRAINT fk_reservas_solicitante FOREIGN KEY (solicitanteId)                -- A03
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT,
  CONSTRAINT fk_reservas_articulo    FOREIGN KEY (articuloId)                   -- A04
    REFERENCES Articulos (articuloId) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-06 · Prestamos (clase de asociación Solicitante-Articulo)
-- Tiene clave primaria propia porque un mismo solicitante puede tomar
-- prestado el mismo artículo varias veces.
-- -----------------------------------------------------------------------------
CREATE TABLE Prestamos (
  prestamoId        INT      NOT NULL AUTO_INCREMENT,
  solicitanteId     INT      NOT NULL,
  articuloId        INT      NOT NULL,
  reservaId         INT      NULL,
  tecnicoEntregaId  INT      NOT NULL,
  tecnicoRecogeId   INT      NULL,
  fechaEntrega      DATETIME NOT NULL,
  fechaLimite       DATETIME NOT NULL,
  fechaDevolucion   DATETIME NULL,
  estadoVuelta      ENUM('CORRECTO', 'CON_DAÑOS') NULL,
  CONSTRAINT pk_prestamos              PRIMARY KEY (prestamoId),
  CONSTRAINT uq_prestamos_reserva      UNIQUE (reservaId),                       -- A06 (0..1)
  CONSTRAINT ck_prestamos_limite       CHECK (fechaLimite > fechaEntrega),       -- R15
  CONSTRAINT ck_prestamos_devolucion   CHECK (fechaDevolucion IS NULL            -- R16
                                              OR fechaDevolucion >= fechaEntrega),
  CONSTRAINT ck_prestamos_cierre       CHECK (                                   -- R17
    (fechaDevolucion IS NULL AND estadoVuelta IS NULL AND tecnicoRecogeId IS NULL)
    OR (fechaDevolucion IS NOT NULL AND estadoVuelta IS NOT NULL AND tecnicoRecogeId IS NOT NULL)),
  CONSTRAINT fk_prestamos_solicitante  FOREIGN KEY (solicitanteId)              -- A05
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT,
  CONSTRAINT fk_prestamos_articulo     FOREIGN KEY (articuloId)                 -- A05
    REFERENCES Articulos (articuloId) ON DELETE RESTRICT,
  CONSTRAINT fk_prestamos_reserva      FOREIGN KEY (reservaId)                  -- A06
    REFERENCES Reservas (reservaId) ON DELETE RESTRICT,
  CONSTRAINT fk_prestamos_tecnico_entrega FOREIGN KEY (tecnicoEntregaId)        -- A07
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT,
  CONSTRAINT fk_prestamos_tecnico_recoge  FOREIGN KEY (tecnicoRecogeId)         -- A08
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-07 · Incidencias
-- -----------------------------------------------------------------------------
CREATE TABLE Incidencias (
  incidenciaId   INT           NOT NULL AUTO_INCREMENT,
  articuloId     INT           NOT NULL,
  prestamoId     INT           NULL,
  tecnicoId      INT           NOT NULL,
  fecha          DATETIME      NOT NULL,
  descripcion    VARCHAR(1000) NOT NULL,
  foto           VARCHAR(255)  NULL,
  gravedad       ENUM('LEVE', 'GRAVE', 'PERDIDA') NOT NULL,
  costeEstimado  DECIMAL(10,2) NULL,
  estado         ENUM('ABIERTA', 'EN_REPARACION', 'RESUELTA', 'BAJA_DEFINITIVA')
                 NOT NULL DEFAULT 'ABIERTA',
  CONSTRAINT pk_incidencias           PRIMARY KEY (incidenciaId),
  CONSTRAINT ck_incidencias_coste     CHECK (costeEstimado IS NULL OR costeEstimado >= 0), -- R18
  CONSTRAINT fk_incidencias_articulo  FOREIGN KEY (articuloId)                  -- A09
    REFERENCES Articulos (articuloId) ON DELETE RESTRICT,
  CONSTRAINT fk_incidencias_prestamo  FOREIGN KEY (prestamoId)                  -- A10
    REFERENCES Prestamos (prestamoId) ON DELETE RESTRICT,
  CONSTRAINT fk_incidencias_tecnico   FOREIGN KEY (tecnicoId)                   -- A11
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- TABLA-08 · Penalizaciones
-- La penalización forma parte de su incidencia (composición): si se borra la
-- incidencia, se borra su penalización (ON DELETE CASCADE).
-- -----------------------------------------------------------------------------
CREATE TABLE Penalizaciones (
  penalizacionId    INT  NOT NULL AUTO_INCREMENT,
  solicitanteId     INT  NOT NULL,
  prestamoId        INT  NULL,
  incidenciaId      INT  NULL,
  tecnicoLevantaId  INT  NULL,
  motivo            ENUM('RETRASO', 'INCIDENCIA_GRAVE_O_PERDIDA', 'RESERVAS_NO_RECOGIDAS') NOT NULL,
  fechaInicio       DATE NOT NULL,
  fechaFin          DATE NOT NULL,
  CONSTRAINT pk_penalizaciones             PRIMARY KEY (penalizacionId),
  CONSTRAINT uq_penalizaciones_prestamo    UNIQUE (prestamoId),                  -- A13 (0..1)
  CONSTRAINT uq_penalizaciones_incidencia  UNIQUE (incidenciaId),                -- A14 (0..1)
  CONSTRAINT ck_penalizaciones_fechas      CHECK (fechaFin > fechaInicio),       -- R20
  CONSTRAINT fk_penalizaciones_solicitante FOREIGN KEY (solicitanteId)          -- A12
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT,
  CONSTRAINT fk_penalizaciones_prestamo    FOREIGN KEY (prestamoId)             -- A13
    REFERENCES Prestamos (prestamoId) ON DELETE RESTRICT,
  CONSTRAINT fk_penalizaciones_incidencia  FOREIGN KEY (incidenciaId)           -- A14 (composición)
    REFERENCES Incidencias (incidenciaId) ON DELETE CASCADE,
  CONSTRAINT fk_penalizaciones_tecnico     FOREIGN KEY (tecnicoLevantaId)       -- A15
    REFERENCES Usuarios (usuarioId) ON DELETE RESTRICT
) ENGINE = InnoDB;
