-- =============================================================================
-- EquipaUS · Entregable 3 · 02_funciones.sql
-- Funciones. Calculan los atributos derivados del modelo conceptual y los
-- valores que necesitan los triggers y las consultas.
-- Debajo de cada función se indica el comando para llamarla. Los ejemplos usan
-- los datos de 05_datos.sql: Paula = 1, Carlos = 2, Marta = 3, Lucía = 5,
-- Luis = 8; artículos POR-002 = 2, VR-001 = 7; modelo Dell XPS 15 = 1.
-- =============================================================================

SET NAMES utf8mb4;
USE EquipaUS;

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
