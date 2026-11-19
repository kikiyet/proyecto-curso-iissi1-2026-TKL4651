-- =============================================================================
-- EquipaUS · Entregable 3 · 2.scripts_funciones_procedimientos.sql
-- Funciones (FUNC-01 a FUNC-06), procedimientos (PROC-01 a PROC-09), evento de
-- caducidad de reservas (EVT-01) y vistas con los atributos derivados.
-- Debajo de cada función y de cada procedimiento se indica el comando para
-- llamarlo. Los ejemplos usan los datos del script 5: Paula = 1, Carlos = 2,
-- Marta = 3, Javier (técnico) = 4, Lucía = 5, Luis = 8, Elena (técnica) = 9;
-- artículos POR-002 = 2, VR-001 = 7; modelo Dell XPS 15 = 1; reserva pendiente
-- de Paula = 6; préstamos en curso: Lucía = 6, Carlos = 7; penalización activa
-- de Marta = 1. Los procedimientos que insertan datos están en el script 5.
-- =============================================================================

SET NAMES utf8mb4;
USE EquipaUS;

-- =============================================================================
-- FUNCIONES
-- =============================================================================
DELIMITER //

-- -----------------------------------------------------------------------------
-- FUNC-01 · fNumActivos: atributo derivado /numActivos de Solicitante.
-- Número de reservas pendientes más préstamos sin devolver (RN01, R22).
-- -----------------------------------------------------------------------------
CREATE FUNCTION fNumActivos(pSolicitanteId INT) RETURNS INT
READS SQL DATA
BEGIN
  RETURN (SELECT COUNT(*) FROM Reservas
           WHERE solicitanteId = pSolicitanteId AND estado = 'PENDIENTE')
       + (SELECT COUNT(*) FROM Prestamos
           WHERE solicitanteId = pSolicitanteId AND fechaDevolucion IS NULL);
END//
-- Llamada (FUNC-01): SELECT fNumActivos(5);      -- Lucía: devuelve 2

-- -----------------------------------------------------------------------------
-- FUNC-02 · fPenalizadoEn: atributo derivado /penalizado de Solicitante.
-- ¿Tiene el solicitante una penalización activa en la fecha indicada?
-- Activa = ya empezada, no terminada y no levantada (RN03, R24).
-- -----------------------------------------------------------------------------
CREATE FUNCTION fPenalizadoEn(pSolicitanteId INT, pFecha DATE) RETURNS BOOLEAN
READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM Penalizaciones
                  WHERE solicitanteId = pSolicitanteId
                    AND tecnicoLevantaId IS NULL
                    AND fechaInicio <= pFecha
                    AND fechaFin > pFecha);
END//
-- Llamada (FUNC-02): SELECT fPenalizadoEn(3, CURDATE());   -- Marta: devuelve 1

-- -----------------------------------------------------------------------------
-- FUNC-03 · fDuracionMaxima: duración máxima en minutos de un préstamo o de
-- una reserva (RN02, R23). 24 horas si el modelo es de Realidad Virtual; si
-- no, 7 días para el PDI y 3 días para el estudiante.
-- -----------------------------------------------------------------------------
CREATE FUNCTION fDuracionMaxima(pSolicitanteId INT, pArticuloId INT) RETURNS INT
READS SQL DATA
BEGIN
  DECLARE vTipo VARCHAR(20) DEFAULT NULL;
  DECLARE vCategoria VARCHAR(60) DEFAULT NULL;
  SELECT tipo INTO vTipo FROM Usuarios WHERE usuarioId = pSolicitanteId;
  SELECT c.nombre INTO vCategoria
    FROM Articulos a
    JOIN Modelos m ON m.modeloId = a.modeloId
    JOIN Categorias c ON c.categoriaId = m.categoriaId
   WHERE a.articuloId = pArticuloId;
  IF vCategoria = 'Realidad Virtual' THEN
    RETURN 24 * 60;
  ELSEIF vTipo = 'PDI' THEN
    RETURN 7 * 24 * 60;
  ELSE
    RETURN 3 * 24 * 60;
  END IF;
END//
-- Llamada (FUNC-03): SELECT fDuracionMaxima(8, 7);   -- Luis con unas gafas VR: 1440
--                    SELECT fDuracionMaxima(8, 2);   -- Luis con un portátil: 10080

-- -----------------------------------------------------------------------------
-- FUNC-04 · fDiasRetraso: atributo derivado /diasRetraso de Prestamo.
-- Cada fracción de día cuenta como un día completo (RN04, R25). Si el
-- préstamo no se ha devuelto, el retraso se calcula hasta este momento.
-- -----------------------------------------------------------------------------
CREATE FUNCTION fDiasRetraso(pFechaLimite DATETIME, pFechaDevolucion DATETIME) RETURNS INT
NOT DETERMINISTIC NO SQL
BEGIN
  DECLARE vFin DATETIME;
  SET vFin = IFNULL(pFechaDevolucion, NOW());
  IF vFin <= pFechaLimite THEN
    RETURN 0;
  END IF;
  RETURN CEIL(TIMESTAMPDIFF(SECOND, pFechaLimite, vFin) / 86400);
END//
-- Llamada (FUNC-04): SELECT fDiasRetraso('2026-10-20 14:00:00', '2026-10-23 10:00:00');  -- 3
--                    SELECT prestamoId, fDiasRetraso(fechaLimite, fechaDevolucion) FROM Prestamos;

-- -----------------------------------------------------------------------------
-- FUNC-05 · fCuatrimestre: cuatrimestre de una fecha (RN09, R31). El primero
-- va de septiembre a enero y el segundo, de febrero a agosto.
-- -----------------------------------------------------------------------------
CREATE FUNCTION fCuatrimestre(pFecha DATETIME) RETURNS VARCHAR(7)
DETERMINISTIC NO SQL
BEGIN
  IF MONTH(pFecha) >= 9 THEN
    RETURN CONCAT(YEAR(pFecha), '-1');
  ELSEIF MONTH(pFecha) = 1 THEN
    RETURN CONCAT(YEAR(pFecha) - 1, '-1');
  ELSE
    RETURN CONCAT(YEAR(pFecha) - 1, '-2');
  END IF;
END//
-- Llamada (FUNC-05): SELECT fCuatrimestre('2026-11-19');   -- '2026-1'
--                    SELECT fCuatrimestre('2027-03-10');   -- '2026-2'

-- -----------------------------------------------------------------------------
-- FUNC-06 · fUnidadesDisponibles: atributo derivado /unidadesDisponibles de
-- Modelo. Número de artículos del modelo en estado DISPONIBLE (RF01).
-- -----------------------------------------------------------------------------
CREATE FUNCTION fUnidadesDisponibles(pModeloId INT) RETURNS INT
READS SQL DATA
BEGIN
  RETURN (SELECT COUNT(*) FROM Articulos
           WHERE modeloId = pModeloId AND estado = 'DISPONIBLE');
END//
-- Llamada (FUNC-06): SELECT fUnidadesDisponibles(1);   -- Dell XPS 15: 1

DELIMITER ;

-- =============================================================================
-- PROCEDIMIENTOS
-- =============================================================================
DELIMITER //

-- -----------------------------------------------------------------------------
-- PROC-01 · pComprobarSolicitante: el usuario debe ser un Solicitante
-- (estudiante o PDI). Toda la jerarquía de usuarios está en una tabla
-- (apartado 7.1), así que una clave ajena a Usuarios no basta: los triggers
-- llaman a este procedimiento para comprobar el tipo.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pComprobarSolicitante(pUsuarioId INT)
BEGIN
  DECLARE vTipo VARCHAR(20) DEFAULT NULL;
  SELECT tipo INTO vTipo FROM Usuarios WHERE usuarioId = pUsuarioId;
  IF vTipo = 'TECNICO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Solo los solicitantes (estudiantes y PDI) pueden tener reservas, préstamos y penalizaciones';
  END IF;
END//
-- Llamada (PROC-01): CALL pComprobarSolicitante(1);   -- Paula: no hace nada
--                    CALL pComprobarSolicitante(4);   -- Javier: error, es técnico

-- -----------------------------------------------------------------------------
-- PROC-02 · pComprobarTecnico: el usuario, si se indica, debe ser un técnico.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pComprobarTecnico(pUsuarioId INT)
BEGIN
  DECLARE vTipo VARCHAR(20) DEFAULT NULL;
  IF pUsuarioId IS NOT NULL THEN
    SELECT tipo INTO vTipo FROM Usuarios WHERE usuarioId = pUsuarioId;
    IF vTipo <> 'TECNICO' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'Solo un técnico puede entregar, recoger, registrar incidencias o levantar penalizaciones';
    END IF;
  END IF;
END//
-- Llamada (PROC-02): CALL pComprobarTecnico(4);   -- Javier: no hace nada
--                    CALL pComprobarTecnico(1);   -- Paula: error, no es técnica

-- -----------------------------------------------------------------------------
-- PROC-03 · pCaducarReservas: pasa a CADUCADA toda reserva pendiente que no se
-- ha recogido en las 2 horas siguientes a su hora de recogida (RN09, R31).
-- El trigger tReservasAU pone la penalización al llegar a 3 en el cuatrimestre.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pCaducarReservas()
BEGIN
  UPDATE Reservas SET estado = 'CADUCADA'
   WHERE estado = 'PENDIENTE' AND NOW() > fechaRecogida + INTERVAL 2 HOUR;
END//
-- Llamada (PROC-03): CALL pCaducarReservas();
-- La ejecuta además el evento eCaducarReservas cada 15 minutos.

-- -----------------------------------------------------------------------------
-- PROC-04 · pRecogerReserva: el técnico entrega el artículo de una reserva y
-- empieza el préstamo. La fecha límite es la devolución prevista de la reserva,
-- sin pasar de la duración máxima (R23). Los triggers comprueban el resto de
-- reglas y pasan la reserva a RECOGIDA y el artículo a PRESTADO (R14, R36).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pRecogerReserva(pReservaId INT, pTecnicoId INT)
BEGIN
  DECLARE vSolicitante INT DEFAULT NULL;
  DECLARE vArticulo INT DEFAULT NULL;
  DECLARE vDevolucionPrevista DATETIME DEFAULT NULL;
  DECLARE vAhora DATETIME;
  SELECT solicitanteId, articuloId, fechaDevolucionPrevista
    INTO vSolicitante, vArticulo, vDevolucionPrevista
    FROM Reservas WHERE reservaId = pReservaId;
  IF vSolicitante IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva no existe';
  END IF;
  SET vAhora = NOW();
  INSERT INTO Prestamos (solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite)
  VALUES (vSolicitante, vArticulo, pReservaId, pTecnicoId, vAhora,
          LEAST(vDevolucionPrevista,
                vAhora + INTERVAL fDuracionMaxima(vSolicitante, vArticulo) MINUTE));
END//
-- Llamada (PROC-04): CALL pRecogerReserva(6, 4);   -- Javier entrega a Paula su reserva 6

-- -----------------------------------------------------------------------------
-- PROC-05 · pRegistrarDevolucion: el técnico recoge un artículo prestado.
-- Los triggers pasan el artículo a EN_REVISION (R28) y, si hay retraso,
-- crean la penalización (RN04, R25).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pRegistrarDevolucion(pPrestamoId INT, pTecnicoId INT, pEstadoVuelta VARCHAR(20))
BEGIN
  UPDATE Prestamos
     SET fechaDevolucion = NOW(), estadoVuelta = pEstadoVuelta, tecnicoRecogeId = pTecnicoId
   WHERE prestamoId = pPrestamoId AND fechaDevolucion IS NULL;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'El préstamo no existe o su devolución ya está registrada';
  END IF;
END//
-- Llamada (PROC-05): CALL pRegistrarDevolucion(6, 9, 'CORRECTO');    -- Lucía devuelve el portátil
--                    CALL pRegistrarDevolucion(7, 9, 'CON_DAÑOS');   -- Carlos devuelve la cámara dañada

-- -----------------------------------------------------------------------------
-- PROC-06 · pRevisarArticulo: el técnico comprueba un artículo devuelto y lo
-- vuelve a dejar DISPONIBLE (RN06, apartado 2.1).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pRevisarArticulo(pArticuloId INT)
BEGIN
  UPDATE Articulos SET estado = 'DISPONIBLE'
   WHERE articuloId = pArticuloId AND estado = 'EN_REVISION';
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El artículo no existe o no está en revisión';
  END IF;
END//
-- Llamada (PROC-06): CALL pRevisarArticulo(7);   -- las gafas VR-001 vuelven a estar disponibles

-- -----------------------------------------------------------------------------
-- PROC-07 · pCancelarReserva: el solicitante cancela una reserva pendiente.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pCancelarReserva(pReservaId INT)
BEGIN
  UPDATE Reservas SET estado = 'CANCELADA'
   WHERE reservaId = pReservaId AND estado = 'PENDIENTE';
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cancelar una reserva pendiente';
  END IF;
END//
-- Llamada (PROC-07): CALL pCancelarReserva(6);   -- Paula cancela su reserva

-- -----------------------------------------------------------------------------
-- PROC-08 · pLevantarPenalizacion: un técnico levanta una penalización tras
-- una reclamación (RI07). Deja de estar activa (/activa).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pLevantarPenalizacion(pPenalizacionId INT, pTecnicoId INT)
BEGIN
  UPDATE Penalizaciones SET tecnicoLevantaId = pTecnicoId
   WHERE penalizacionId = pPenalizacionId AND tecnicoLevantaId IS NULL;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La penalización no existe o ya está levantada';
  END IF;
END//
-- Llamada (PROC-08): CALL pLevantarPenalizacion(1, 9);   -- Elena levanta la penalización de Marta

-- -----------------------------------------------------------------------------
-- PROC-09 · pProbar: procedimiento auxiliar para las demostraciones de
-- 4.scripts_triggers.sql. Ejecuta una sentencia, deshace sus cambios con ROLLBACK y
-- muestra si se aceptó o se rechazó y con qué mensaje. Así el script no se
-- detiene cuando una sentencia falla a propósito.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE pProbar(pDescripcion VARCHAR(200), pSentencia TEXT)
BEGIN
  DECLARE vMensaje TEXT DEFAULT NULL;
  DECLARE vError TEXT DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 vError = MESSAGE_TEXT;
    IF vMensaje IS NULL THEN
      SET vMensaje = vError;
    END IF;
  END;
  START TRANSACTION;
  SET @sentenciaPrueba = pSentencia;
  PREPARE sentenciaPrueba FROM @sentenciaPrueba;
  EXECUTE sentenciaPrueba;
  DEALLOCATE PREPARE sentenciaPrueba;
  ROLLBACK;
  SELECT pDescripcion AS prueba,
         IF(vMensaje IS NULL, 'ACEPTADA', CONCAT('RECHAZADA: ', vMensaje)) AS resultado;
END//
-- Llamada (PROC-09): CALL pProbar('Paula cancela su reserva', "CALL pCancelarReserva(6)");

-- -----------------------------------------------------------------------------
-- EVT-01 · eCaducarReservas: ejecuta pCaducarReservas cada 15 minutos (R31).
-- Requiere activar el planificador de eventos: SET GLOBAL event_scheduler = ON;
-- -----------------------------------------------------------------------------
CREATE EVENT eCaducarReservas
  ON SCHEDULE EVERY 15 MINUTE
  DO CALL pCaducarReservas()//

DELIMITER ;

-- =============================================================================
-- VISTAS con los atributos derivados del modelo conceptual. No se guardan en
-- las tablas: se calculan cada vez que se consultan.
-- Ejemplo: SELECT * FROM vSolicitantes;
-- =============================================================================
-- VISTA-01 · Solicitante: /penalizado y /numActivos
CREATE VIEW vSolicitantes AS
SELECT u.usuarioId, u.uvus, u.nombre, u.apellidos, u.email, u.tipo,
       fPenalizadoEn(u.usuarioId, CURDATE()) AS penalizado,
       fNumActivos(u.usuarioId)              AS numActivos
  FROM Usuarios u
 WHERE u.tipo IN ('ESTUDIANTE', 'PDI');

-- VISTA-02 · Modelo: /unidadesDisponibles
CREATE VIEW vModelos AS
SELECT m.*, fUnidadesDisponibles(m.modeloId) AS unidadesDisponibles
  FROM Modelos m;

-- VISTA-03 · Prestamo: /diasRetraso
CREATE VIEW vPrestamos AS
SELECT p.*, fDiasRetraso(p.fechaLimite, p.fechaDevolucion) AS diasRetraso
  FROM Prestamos p;

-- VISTA-04 · Penalizacion: /activa (empezada, no terminada y no levantada)
CREATE VIEW vPenalizaciones AS
SELECT p.*,
       (p.fechaInicio <= CURDATE() AND p.fechaFin > CURDATE()
        AND p.tecnicoLevantaId IS NULL) AS activa
  FROM Penalizaciones p;
