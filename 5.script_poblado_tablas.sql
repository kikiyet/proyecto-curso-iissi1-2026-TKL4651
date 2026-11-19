-- =============================================================================
-- EquipaUS · Entregable 3 · 5.script_poblado_tablas.sql
-- Procedimientos para insertar datos y datos de ejemplo (al menos 3 filas en
-- cada tabla). Incluyen los escenarios del apartado 5.2.
--
-- Se ejecuta después del script 4, así que los datos pasan por los triggers:
-- se insertan en orden cronológico y los triggers calculan solos los estados
-- de los artículos y de las reservas y las penalizaciones.
-- Las fechas son relativas al momento de la carga (@ahora), para que las
-- consultas del script 3 y las demostraciones del script 4 den resultados en
-- cualquier fecha. Para volver a cargar los datos, ejecutar de nuevo todos los
-- scripts desde el 1.
-- =============================================================================

SET NAMES utf8mb4;
USE EquipaUS;

DROP PROCEDURE IF EXISTS pInsertarUsuario;
DROP PROCEDURE IF EXISTS pAltaModelo;
DROP PROCEDURE IF EXISTS pInsertarArticulo;

DELIMITER //

-- -----------------------------------------------------------------------------
-- PROC-10 · pInsertarUsuario: da de alta un usuario (RI01).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pInsertarUsuario(
  IN pUvus VARCHAR(20), IN pDni CHAR(9), IN pNombre VARCHAR(60), IN pApellidos VARCHAR(100),
  IN pEmail VARCHAR(120), IN pTelefono VARCHAR(15), IN pFechaAlta DATE, IN pTipo VARCHAR(20))
BEGIN
  INSERT INTO Usuarios (uvus, dni, nombre, apellidos, email, telefono, fechaAlta, tipo)
  VALUES (pUvus, pDni, pNombre, pApellidos, pEmail, pTelefono, pFechaAlta, pTipo);
END//
-- Llamada (PROC-10): CALL pInsertarUsuario('ABC1234', '12345678Z', 'Nombre', 'Apellidos',
--                                          'nomape@alum.us.es', NULL, CURDATE(), 'ESTUDIANTE');

-- -----------------------------------------------------------------------------
-- PROC-11 · pAltaModelo: da de alta un modelo junto con su primer artículo en
-- la misma transacción, para que ningún modelo exista sin artículos
-- (asociación A02, multiplicidad 1..*). Si algo falla, no se guarda nada.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pAltaModelo(
  IN pCategoriaId INT, IN pMarca VARCHAR(60), IN pNombreComercial VARCHAR(100),
  IN pDescripcion VARCHAR(1000), IN pEspecificaciones VARCHAR(2000), IN pFotografia VARCHAR(255),
  IN pCodigoInventario VARCHAR(20), IN pNumeroSerie VARCHAR(50), IN pFechaAdquisicion DATE,
  IN pPrecioCompra DECIMAL(10,2), IN pUbicacion VARCHAR(100))
BEGIN
  DECLARE vModeloId INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO Modelos (categoriaId, marca, nombreComercial, descripcion, especificaciones, fotografia)
  VALUES (pCategoriaId, pMarca, pNombreComercial, pDescripcion, pEspecificaciones, pFotografia);
  SET vModeloId = LAST_INSERT_ID();
  INSERT INTO Articulos (modeloId, codigoInventario, numeroSerie, fechaAdquisicion, precioCompra, ubicacion)
  VALUES (vModeloId, pCodigoInventario, pNumeroSerie, pFechaAdquisicion, pPrecioCompra, pUbicacion);
  COMMIT;
END//
-- Llamada (PROC-11): CALL pAltaModelo(1, 'Lenovo', 'ThinkPad X1', 'Portátil ligero', 'Intel Core i7, 16 GB RAM',
--                                     'img/modelos/thinkpad-x1.jpg', 'POR-010', 'LN-X1-0001', '2025-06-01', 1450.00, 'Armario A');

-- -----------------------------------------------------------------------------
-- PROC-12 · pInsertarArticulo: añade otra unidad física a un modelo (RI03).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pInsertarArticulo(
  IN pModeloId INT, IN pCodigoInventario VARCHAR(20), IN pNumeroSerie VARCHAR(50),
  IN pFechaAdquisicion DATE, IN pPrecioCompra DECIMAL(10,2), IN pUbicacion VARCHAR(100))
BEGIN
  INSERT INTO Articulos (modeloId, codigoInventario, numeroSerie, fechaAdquisicion, precioCompra, ubicacion)
  VALUES (pModeloId, pCodigoInventario, pNumeroSerie, pFechaAdquisicion, pPrecioCompra, pUbicacion);
END//
-- Llamada (PROC-12): CALL pInsertarArticulo(1, 'POR-003', 'DL-XPS15-9K4M1S', '2025-03-10', 1599.00, 'Armario A');

DELIMITER ;

-- Se para la caducidad automática mientras se cargan reservas con fechas pasadas.
ALTER EVENT eCaducarReservas DISABLE;

SET @ahora = NOW();

-- =============================================================================
-- Usuarios (ids 1 a 9, en este orden)
-- =============================================================================
CALL pInsertarUsuario('PKN3387', '28745123K', 'Paula',  'Ramírez Soria',     'pramsor@alum.us.es', '611223344', '2025-09-15', 'ESTUDIANTE');  -- 1
CALL pInsertarUsuario('CMS4412', '30987456T', 'Carlos', 'Medina Soto',       'cmedsot@alum.us.es', NULL,        '2025-09-15', 'ESTUDIANTE');  -- 2
CALL pInsertarUsuario('JAP2031', '27654321H', 'Marta',  'Aguilar Ramos',     'aguilarramos@us.es', '954556677', '2024-02-01', 'PDI');         -- 3
CALL pInsertarUsuario('JPR3240', '29111222M', 'Javier', 'Gutierrez Asencio', 'jgutase@us.es',      '954551100', '2023-09-01', 'TECNICO');     -- 4
CALL pInsertarUsuario('LGR5521', 'X1234567L', 'Lucía',  'Gómez Ruiz',        'lgomrui@alum.us.es', '622334455', '2025-09-20', 'ESTUDIANTE');  -- 5
CALL pInsertarUsuario('PMD7788', '31222333B', 'Pablo',  'Moreno Díaz',       'pmordia@alum.us.es', NULL,        '2024-09-18', 'ESTUDIANTE');  -- 6
CALL pInsertarUsuario('ATV1902', '32444555C', 'Ana',    'Torres Vega',       'atorveg@alum.us.es', '633445566', '2025-09-22', 'ESTUDIANTE');  -- 7
CALL pInsertarUsuario('LHC6610', '26777888D', 'Luis',   'Herrera Campos',    'lherrera@us.es',     '954559900', '2020-10-05', 'PDI');         -- 8
CALL pInsertarUsuario('ENG4455', '33666777F', 'Elena',  'Navarro Gil',       'enavarro@us.es',     '954551101', '2022-01-10', 'TECNICO');     -- 9

-- =============================================================================
-- Catálogo: categorías (ids 1 a 5), modelos (ids 1 a 6) y artículos (ids 1 a 11)
-- =============================================================================
INSERT INTO Categorias (categoriaId, nombre, descripcion) VALUES
  (1, 'Informática',            'Portátiles y equipos informáticos'),
  (2, 'Audiovisual',            'Cámaras, proyectores y material de grabación'),
  (3, 'Realidad Virtual',       'Gafas y accesorios de realidad virtual'),
  (4, 'Electrónica y Robótica', 'Kits de electrónica, microcontroladores y robótica'),
  (5, 'Accesorios',             'Trípodes, cables, adaptadores y otros accesorios');

CALL pAltaModelo(1, 'Dell', 'XPS 15', 'Portátil de 15 pulgadas para desarrollo y diseño',
  'Intel Core i7, 16 GB RAM, SSD 512 GB, pantalla 15,6"', 'img/modelos/dell-xps-15.jpg',
  'POR-001', 'DL-XPS15-7H2K9Q', '2025-03-10', 1599.00, 'Armario A');                    -- modelo 1, artículo 1
CALL pInsertarArticulo(1, 'POR-002', 'DL-XPS15-8J3L0R', '2025-03-10', 1599.00, 'Armario A');  -- artículo 2

CALL pAltaModelo(2, 'Canon', 'EOS R50', 'Cámara mirrorless para fotografía y vídeo',
  'Sensor APS-C de 24,2 MP, vídeo 4K, objetivo 18-45 mm', 'img/modelos/canon-eos-r50.jpg',
  'CAM-005', 'CN-R50-000512', '2025-05-20', 799.00, 'Almacén');                         -- modelo 2, artículo 3
CALL pInsertarArticulo(2, 'CAM-006', 'CN-R50-000513', '2025-05-20', 799.00, 'Almacén');      -- artículo 4

CALL pAltaModelo(2, 'Epson', 'EB-L210SW', 'Proyector láser de tiro corto',
  '4000 lúmenes, WXGA, conexión HDMI e inalámbrica', 'img/modelos/epson-eb-l210sw.jpg',
  'PRY-001', 'EP-L210-55A01', '2024-11-05', 1150.00, 'Almacén');                        -- modelo 3, artículo 5
CALL pInsertarArticulo(3, 'PRY-002', 'EP-L210-55A02', '2024-11-05', 1150.00, 'Almacén');     -- artículo 6

CALL pAltaModelo(3, 'Meta', 'Quest 3', 'Gafas de realidad virtual autónomas con mandos',
  '128 GB, pantalla LCD 2064x2208 por ojo', 'img/modelos/meta-quest-3.jpg',
  'VR-001', 'MQ3-2G0YC5ZF8B0123', '2025-09-01', 549.00, 'Armario B');                   -- modelo 4, artículo 7
CALL pInsertarArticulo(4, 'VR-002', 'MQ3-2G0YC5ZF8B0456', '2025-09-01', 549.00, 'Armario B'); -- artículo 8

CALL pAltaModelo(4, 'Arduino', 'Starter Kit', 'Kit de iniciación a la electrónica con Arduino UNO',
  'Placa Arduino UNO R3, protoboard, sensores, motores y libro de proyectos',
  'img/modelos/arduino-starter-kit.jpg', 'ARD-001', 'ARD-SK-1001', '2025-02-14', 95.00, 'Laboratorio 2');  -- modelo 5, artículo 9
CALL pInsertarArticulo(5, 'ARD-002', 'ARD-SK-1002', '2025-02-14', 95.00, 'Laboratorio 2');    -- artículo 10

CALL pAltaModelo(5, 'Manfrotto', 'Compact Action', 'Trípode ligero para cámara y proyector',
  'Altura máxima 155 cm, carga hasta 1,5 kg', 'img/modelos/manfrotto-compact-action.jpg',
  'TRI-001', 'MF-CA-90871', '2024-10-01', 45.00, 'Armario C');                          -- modelo 6, artículo 11

-- =============================================================================
-- Historia del servicio, en orden cronológico. Los triggers hacen el resto:
-- pasan las reservas a RECOGIDA, los artículos a PRESTADO o EN_REVISION y
-- crean las penalizaciones.
-- =============================================================================

-- Hace 28 días · Ana reserva un kit Arduino (no lo recogerá)
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (3, 7, 9, @ahora - INTERVAL 28 DAY, @ahora - INTERVAL 25 DAY, @ahora - INTERVAL 24 DAY);
UPDATE Reservas SET estado = 'CADUCADA' WHERE reservaId = 3;              -- 1.ª caducada de Ana

-- Hace 22 días · casos 1 y 2 del apartado 5.2: Paula y Carlos reservan una cámara cada uno
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (1, 1, 3, @ahora - INTERVAL 22 DAY, @ahora - INTERVAL 20 DAY, @ahora - INTERVAL 18 DAY),
  (2, 2, 4, @ahora - INTERVAL 22 DAY, @ahora - INTERVAL 20 DAY + INTERVAL 1 HOUR,
            @ahora - INTERVAL 18 DAY + INTERVAL 1 HOUR);

-- Hace 21 días · Ana vuelve a reservar (tampoco lo recogerá)
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (4, 7, 9, @ahora - INTERVAL 21 DAY, @ahora - INTERVAL 18 DAY, @ahora - INTERVAL 17 DAY);

-- Hace 20 días · Paula y Carlos recogen sus cámaras (las reservas pasan a RECOGIDA)
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (1, 1, 3, 1, 4, @ahora - INTERVAL 20 DAY + INTERVAL 5 MINUTE, @ahora - INTERVAL 18 DAY);
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (3, 2, 4, 2, 9, @ahora - INTERVAL 20 DAY + INTERVAL 70 MINUTE, @ahora - INTERVAL 18 DAY + INTERVAL 1 HOUR);

-- Hace 18 días · devuelven las cámaras a tiempo; se revisan y quedan disponibles
UPDATE Prestamos SET fechaDevolucion = @ahora - INTERVAL 18 DAY - INTERVAL 30 MINUTE,
                     estadoVuelta = 'CORRECTO', tecnicoRecogeId = 4 WHERE prestamoId = 1;
UPDATE Prestamos SET fechaDevolucion = @ahora - INTERVAL 18 DAY,
                     estadoVuelta = 'CORRECTO', tecnicoRecogeId = 9 WHERE prestamoId = 3;
CALL pRevisarArticulo(3);
CALL pRevisarArticulo(4);
UPDATE Reservas SET estado = 'CADUCADA' WHERE reservaId = 4;              -- 2.ª caducada de Ana

-- Hace 15 días · Pablo se lleva un portátil sin reserva, durante 3 días
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (4, 6, 1, NULL, 9, @ahora - INTERVAL 15 DAY, @ahora - INTERVAL 12 DAY);

-- Hace 14 días · Ana reserva por tercera vez
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (5, 7, 9, @ahora - INTERVAL 14 DAY, @ahora - INTERVAL 11 DAY, @ahora - INTERVAL 10 DAY);

-- Hace 12 a 10 días · caso 3 del apartado 5.2: Marta (PDI) se lleva un proyector
-- sin reserva y lo devuelve con la óptica dañada. La incidencia grave pasa el
-- proyector a EN_REPARACION y penaliza 30 días a Marta (penalización 1).
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (2, 3, 5, NULL, 4, @ahora - INTERVAL 12 DAY, @ahora - INTERVAL 7 DAY);
UPDATE Prestamos SET fechaDevolucion = @ahora - INTERVAL 10 DAY,
                     estadoVuelta = 'CON_DAÑOS', tecnicoRecogeId = 4 WHERE prestamoId = 2;
INSERT INTO Incidencias (incidenciaId, articuloId, prestamoId, tecnicoId, fecha, descripcion, foto, gravedad, costeEstimado) VALUES
  (1, 5, 2, 4, @ahora - INTERVAL 10 DAY + INTERVAL 15 MINUTE, 'Óptica dañada',
      'img/incidencias/pry-001.jpg', 'GRAVE', 150.00);
UPDATE Incidencias SET estado = 'EN_REPARACION' WHERE incidenciaId = 1;
UPDATE Articulos SET ubicacion = 'Taller de reparación' WHERE articuloId = 5;

-- Hace 11 días · Ana no recoge la tercera reserva: 7 días de penalización
-- (penalización 2, RN09). Después, Elena la levanta tras su reclamación.
UPDATE Reservas SET estado = 'CADUCADA' WHERE reservaId = 5;              -- 3.ª caducada de Ana
UPDATE Penalizaciones SET tecnicoLevantaId = 9 WHERE solicitanteId = 7;

-- Hace 9 días · Pablo devuelve el portátil 2 días y 20 horas tarde: cuenta como
-- 3 días y recibe 6 días de penalización (penalización 3, RN04), ya cumplida.
UPDATE Prestamos SET fechaDevolucion = @ahora - INTERVAL 12 DAY + INTERVAL 2 DAY + INTERVAL 20 HOUR,
                     estadoVuelta = 'CORRECTO', tecnicoRecogeId = 4 WHERE prestamoId = 4;
CALL pRevisarArticulo(1);

-- Hace 8 días · un kit Arduino no aparece en el inventario: se da de baja
INSERT INTO Incidencias (incidenciaId, articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad, costeEstimado) VALUES
  (3, 10, NULL, 9, @ahora - INTERVAL 8 DAY, 'No aparece en el inventario anual', 'PERDIDA', 95.00);
UPDATE Incidencias SET estado = 'BAJA_DEFINITIVA' WHERE incidenciaId = 3;

-- Hace 6 días · Carlos reserva un proyector y luego cancela la reserva
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (9, 2, 6, @ahora - INTERVAL 6 DAY, @ahora - INTERVAL 3 DAY, @ahora - INTERVAL 2 DAY);
CALL pCancelarReserva(9);

-- Hace 5 días · incidencia leve detectada en una revisión, sin préstamo
INSERT INTO Incidencias (incidenciaId, articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad) VALUES
  (2, 11, NULL, 9, @ahora - INTERVAL 5 DAY, 'Rosca de la rótula algo desgastada', 'LEVE');
UPDATE Incidencias SET estado = 'RESUELTA' WHERE incidenciaId = 2;

-- Hace 4 días y medio · Lucía se lleva un portátil 2 días y no lo devuelve (vencido)
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (6, 5, 2, NULL, 4, @ahora - INTERVAL 4 DAY - INTERVAL 12 HOUR, @ahora - INTERVAL 2 DAY - INTERVAL 12 HOUR);

-- Hace 3 a 1 días · Luis (PDI) reserva unas gafas de RV 24 horas, las recoge y
-- las devuelve; quedan EN_REVISION
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (7, 8, 7, @ahora - INTERVAL 3 DAY, @ahora - INTERVAL 2 DAY, @ahora - INTERVAL 1 DAY);
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (5, 8, 7, 7, 4, @ahora - INTERVAL 2 DAY + INTERVAL 5 MINUTE, @ahora - INTERVAL 1 DAY);
UPDATE Prestamos SET fechaDevolucion = @ahora - INTERVAL 1 DAY - INTERVAL 1 HOUR,
                     estadoVuelta = 'CORRECTO', tecnicoRecogeId = 4 WHERE prestamoId = 5;

-- Hace 1 día · Carlos se lleva una cámara que vence hoy; Paula reserva una
-- cámara para recogerla hoy y Lucía reserva un trípode para mañana
INSERT INTO Prestamos (prestamoId, solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES
  (7, 2, 4, NULL, 9, @ahora - INTERVAL 1 DAY, @ahora + INTERVAL 2 HOUR);
INSERT INTO Reservas (reservaId, solicitanteId, articuloId, fechaCreacion, fechaRecogida, fechaDevolucionPrevista) VALUES
  (6, 1, 3, @ahora - INTERVAL 1 DAY, @ahora + INTERVAL 1 HOUR, @ahora + INTERVAL 1 DAY),
  (8, 5, 11, @ahora - INTERVAL 1 DAY, @ahora + INTERVAL 1 DAY, @ahora + INTERVAL 2 DAY);

-- Se vuelve a activar la caducidad automática de reservas.
ALTER EVENT eCaducarReservas ENABLE;

-- Comprobación rápida: estados de los artículos, penalizaciones y solicitantes
SELECT codigoInventario, estado, ubicacion FROM Articulos ORDER BY articuloId;
SELECT p.penalizacionId, u.nombre, p.motivo, p.fechaInicio, p.fechaFin, p.tecnicoLevantaId
  FROM Penalizaciones p JOIN Usuarios u ON u.usuarioId = p.solicitanteId ORDER BY p.penalizacionId;
SELECT * FROM vSolicitantes;
