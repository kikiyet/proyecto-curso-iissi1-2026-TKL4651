-- =============================================================================
-- EquipaUS · Entregable 3 · 3.scripts_cursores_consultas.sql
-- Una consulta por cada requisito funcional (RF01 a RF13, apartado 4.4).
-- Encima de cada consulta se indica el requisito y las cláusulas que usa.
-- No se incluyen cursores (no entran este curso).
-- Ejecutar después del script 5 (poblado de tablas).
--
-- Resumen de cláusulas:
--   JOIN     RF01 a RF13
--   GROUP BY RF01, RF02, RF05, RF06, RF11, RF12, RF13
--   HAVING   RF01, RF11
--   ORDER BY RF01, RF03 a RF13
--   SUM      RF01, RF12, RF13
--   COUNT    RF02, RF05, RF06, RF11, RF12, RF13
--   MAX      RF06, RF10, RF11
--   MIN      RF02, RF06, RF11, RF13
--   AVG      RF05, RF13
-- =============================================================================

SET NAMES utf8mb4;
USE EquipaUS;

-- Parámetros de ejemplo (en la aplicación los indicaría el usuario)
SET @solicitante = (SELECT usuarioId FROM Usuarios WHERE uvus = 'LGR5521');     -- Lucía
SET @paula       = (SELECT usuarioId FROM Usuarios WHERE uvus = 'PKN3387');     -- Paula
SET @pablo       = (SELECT usuarioId FROM Usuarios WHERE uvus = 'PMD7788');     -- Pablo
SET @marta       = (SELECT usuarioId FROM Usuarios WHERE uvus = 'JAP2031');     -- Marta
SET @modelo      = (SELECT modeloId FROM Modelos
                     WHERE marca = 'Canon' AND nombreComercial = 'EOS R50');
SET @desde       = NOW() + INTERVAL 2 HOUR;
SET @hasta       = NOW() + INTERVAL 1 DAY + INTERVAL 2 HOUR;
SET @codigo      = 'PRY-001';
SET @motivo      = NULL;    -- RF11: NULL = todos los motivos; o 'RETRASO', etc.
SET @inicioCurso = IF(MONTH(CURDATE()) >= 9,
                      MAKEDATE(YEAR(CURDATE()), 1) + INTERVAL 8 MONTH,
                      MAKEDATE(YEAR(CURDATE()) - 1, 1) + INTERVAL 8 MONTH);   -- 1 de septiembre

-- -----------------------------------------------------------------------------
-- RF01. Consultar el catálogo por categorías
-- Modelos agrupados por categoría y ordenados por marca y nombre, con su número
-- de artículos disponibles. No aparecen los modelos con todos sus artículos de baja.
-- Usa: JOIN, GROUP BY, HAVING, SUM, ORDER BY
-- -----------------------------------------------------------------------------
SELECT c.nombre AS categoria, m.marca, m.nombreComercial, m.descripcion, m.fotografia,
       SUM(a.estado = 'DISPONIBLE') AS disponibles
  FROM Categorias c
  JOIN Modelos m   ON m.categoriaId = c.categoriaId
  JOIN Articulos a ON a.modeloId = m.modeloId
 GROUP BY c.categoriaId, c.nombre, m.modeloId, m.marca, m.nombreComercial, m.descripcion, m.fotografia
HAVING SUM(a.estado <> 'DE_BAJA') > 0
 ORDER BY c.nombre, m.marca, m.nombreComercial;

-- -----------------------------------------------------------------------------
-- RF02. Consultar la disponibilidad de un modelo en unas fechas
-- Artículos del modelo @modelo libres entre @desde y @hasta para @paula: están
-- operativos y no se solapan con una reserva pendiente ni con un préstamo en
-- curso (RN05, RN06). Si el periodo supera la duración máxima (RN02) o la
-- antelación de 14 días (RN08), se muestra un aviso en lugar del resultado.
-- Usa: JOIN (LEFT JOIN), GROUP BY, COUNT, MIN
-- -----------------------------------------------------------------------------
SELECT m.marca, m.nombreComercial,
       CASE
         WHEN @desde > NOW() + INTERVAL 14 DAY
           THEN 'Aviso: no se puede reservar con más de 14 días de antelación'
         WHEN TIMESTAMPDIFF(MINUTE, @desde, @hasta) > fDuracionMaxima(@paula, MIN(a.articuloId))
           THEN 'Aviso: el periodo supera la duración máxima permitida'
         ELSE CONCAT(COUNT(libre.articuloId), ' artículo(s) libre(s)')
       END AS disponibilidad
  FROM Modelos m
  JOIN Articulos a ON a.modeloId = m.modeloId
  LEFT JOIN Articulos libre
         ON libre.articuloId = a.articuloId
        AND libre.estado IN ('DISPONIBLE', 'PRESTADO')
        AND NOT EXISTS (SELECT 1 FROM Reservas r
                         WHERE r.articuloId = libre.articuloId AND r.estado = 'PENDIENTE'
                           AND r.fechaRecogida < @hasta AND @desde < r.fechaDevolucionPrevista)
        AND NOT EXISTS (SELECT 1 FROM Prestamos p
                         WHERE p.articuloId = libre.articuloId AND p.fechaDevolucion IS NULL
                           AND p.fechaEntrega < @hasta AND @desde < p.fechaLimite)
 WHERE m.modeloId = @modelo
 GROUP BY m.modeloId, m.marca, m.nombreComercial;

-- -----------------------------------------------------------------------------
-- RF03. Consultar mis reservas pendientes
-- Reservas pendientes de @solicitante, de la más próxima a la más lejana, con la
-- hora a partir de la cual caducan (RN09) y sus activos frente al máximo (RN01).
-- Usa: JOIN, ORDER BY
-- -----------------------------------------------------------------------------
SELECT r.reservaId, m.marca, m.nombreComercial, a.codigoInventario,
       r.fechaRecogida, r.fechaDevolucionPrevista,
       r.fechaRecogida + INTERVAL 2 HOUR AS caducaA,
       CONCAT(fNumActivos(u.usuarioId), ' de ', IF(u.tipo = 'PDI', 4, 2)) AS activos
  FROM Reservas r
  JOIN Usuarios u  ON u.usuarioId = r.solicitanteId
  JOIN Articulos a ON a.articuloId = r.articuloId
  JOIN Modelos m   ON m.modeloId = a.modeloId
 WHERE r.solicitanteId = @solicitante AND r.estado = 'PENDIENTE'
 ORDER BY r.fechaRecogida;

-- -----------------------------------------------------------------------------
-- RF04. Consultar el material que tengo prestado
-- Préstamos en curso de @solicitante por fecha límite; los vencidos muestran
-- los días de retraso y la penalización que generarán (RN04).
-- Usa: JOIN, ORDER BY
-- -----------------------------------------------------------------------------
SELECT p.prestamoId, m.marca, m.nombreComercial, a.codigoInventario,
       p.fechaEntrega, p.fechaLimite,
       IF(p.fechaLimite < NOW(), 'Vencido', 'En plazo') AS situacion,
       fDiasRetraso(p.fechaLimite, NULL) AS diasRetraso,
       LEAST(2 * fDiasRetraso(p.fechaLimite, NULL), 60) AS diasPenalizacionPrevista
  FROM Prestamos p
  JOIN Articulos a ON a.articuloId = p.articuloId
  JOIN Modelos m   ON m.modeloId = a.modeloId
 WHERE p.solicitanteId = @solicitante AND p.fechaDevolucion IS NULL
 ORDER BY p.fechaLimite;

-- -----------------------------------------------------------------------------
-- RF05. Consultar mi historial de préstamos
-- Préstamos ya devueltos de @pablo, del más reciente al más antiguo, con los
-- días de retraso y la gravedad de la incidencia si la hubo. Debajo, el retraso
-- medio de sus devoluciones.
-- Usa: JOIN (LEFT JOIN), ORDER BY, GROUP BY, COUNT, AVG
-- -----------------------------------------------------------------------------
SELECT m.marca, m.nombreComercial, a.codigoInventario,
       p.fechaEntrega, p.fechaLimite, p.fechaDevolucion, p.estadoVuelta,
       fDiasRetraso(p.fechaLimite, p.fechaDevolucion) AS diasRetraso,
       i.gravedad AS gravedadIncidencia
  FROM Prestamos p
  JOIN Articulos a ON a.articuloId = p.articuloId
  JOIN Modelos m   ON m.modeloId = a.modeloId
  LEFT JOIN Incidencias i ON i.prestamoId = p.prestamoId
 WHERE p.solicitanteId = @pablo AND p.fechaDevolucion IS NOT NULL
 ORDER BY p.fechaEntrega DESC;

SELECT u.nombre, COUNT(p.prestamoId) AS prestamosDevueltos,
       ROUND(AVG(fDiasRetraso(p.fechaLimite, p.fechaDevolucion)), 2) AS retrasoMedioDias
  FROM Usuarios u
  JOIN Prestamos p ON p.solicitanteId = u.usuarioId
 WHERE u.usuarioId = @pablo AND p.fechaDevolucion IS NOT NULL
 GROUP BY u.usuarioId, u.nombre;

-- -----------------------------------------------------------------------------
-- RF06. Consultar mi situación de penalización
-- Penalizaciones de @marta con su motivo, lo que la originó y si está activa.
-- Debajo, el resumen: si está penalizada y hasta cuándo (RN03).
-- Usa: JOIN (LEFT JOIN), ORDER BY, GROUP BY, COUNT, MAX, MIN
-- -----------------------------------------------------------------------------
SELECT pe.motivo, pe.fechaInicio, pe.fechaFin,
       COALESCE(CONCAT('Préstamo ', pe.prestamoId), CONCAT('Incidencia: ', i.descripcion),
                'Reservas no recogidas') AS origen,
       IF(pe.fechaInicio <= CURDATE() AND pe.fechaFin > CURDATE() AND pe.tecnicoLevantaId IS NULL,
          'Activa', 'Cumplida o levantada') AS situacion
  FROM Penalizaciones pe
  LEFT JOIN Incidencias i ON i.incidenciaId = pe.incidenciaId
 WHERE pe.solicitanteId = @marta
 ORDER BY pe.fechaInicio DESC;

SELECT u.nombre,
       COUNT(pe.penalizacionId) AS penalizacionesActivas,
       MIN(pe.fechaInicio) AS desde,
       MAX(pe.fechaFin) AS penalizadoHasta,
       IF(COUNT(pe.penalizacionId) = 0, 'Sin penalizaciones', 'Penalizado') AS situacion
  FROM Usuarios u
  LEFT JOIN Penalizaciones pe
         ON pe.solicitanteId = u.usuarioId AND pe.tecnicoLevantaId IS NULL
        AND pe.fechaInicio <= CURDATE() AND pe.fechaFin > CURDATE()
 WHERE u.usuarioId = @marta
 GROUP BY u.usuarioId, u.nombre;

-- -----------------------------------------------------------------------------
-- RF07. Listar préstamos vencidos
-- Préstamos no devueltos con la fecha límite pasada, de más a menos retraso,
-- con los datos de contacto del solicitante y la penalización prevista (RN04).
-- Usa: JOIN, ORDER BY
-- -----------------------------------------------------------------------------
SELECT u.nombre, u.apellidos, u.email, u.telefono,
       a.codigoInventario, m.marca, m.nombreComercial, p.fechaLimite,
       fDiasRetraso(p.fechaLimite, NULL) AS diasRetraso,
       LEAST(2 * fDiasRetraso(p.fechaLimite, NULL), 60) AS diasPenalizacionPrevista
  FROM Prestamos p
  JOIN Usuarios u  ON u.usuarioId = p.solicitanteId
  JOIN Articulos a ON a.articuloId = p.articuloId
  JOIN Modelos m   ON m.modeloId = a.modeloId
 WHERE p.fechaDevolucion IS NULL AND p.fechaLimite < NOW()
 ORDER BY diasRetraso DESC, p.fechaLimite;

-- -----------------------------------------------------------------------------
-- RF08. Listar la agenda del mostrador del día
-- Recogidas (reservas pendientes que se recogen hoy, marcando las caducadas,
-- RN09) y devoluciones (préstamos que vencen hoy), ordenadas por hora.
-- Usa: JOIN, UNION ALL, ORDER BY
-- -----------------------------------------------------------------------------
SELECT 'Recogida' AS tipo, TIME(r.fechaRecogida) AS hora, u.nombre, u.apellidos,
       a.codigoInventario, m.nombreComercial,
       IF(NOW() > r.fechaRecogida + INTERVAL 2 HOUR, 'Caducada', 'Pendiente') AS situacion
  FROM Reservas r
  JOIN Usuarios u  ON u.usuarioId = r.solicitanteId
  JOIN Articulos a ON a.articuloId = r.articuloId
  JOIN Modelos m   ON m.modeloId = a.modeloId
 WHERE r.estado = 'PENDIENTE' AND DATE(r.fechaRecogida) = CURDATE()
UNION ALL
SELECT 'Devolución', TIME(p.fechaLimite), u.nombre, u.apellidos,
       a.codigoInventario, m.nombreComercial,
       IF(p.fechaLimite < NOW(), 'Vencido', 'En plazo')
  FROM Prestamos p
  JOIN Usuarios u  ON u.usuarioId = p.solicitanteId
  JOIN Articulos a ON a.articuloId = p.articuloId
  JOIN Modelos m   ON m.modeloId = a.modeloId
 WHERE p.fechaDevolucion IS NULL AND DATE(p.fechaLimite) = CURDATE()
 ORDER BY tipo DESC, hora;

-- -----------------------------------------------------------------------------
-- RF09. Consultar el historial de un artículo
-- Estado actual y préstamos del artículo @codigo, del más reciente al más
-- antiguo, con el solicitante y los técnicos que lo entregaron y recogieron.
-- Debajo, sus incidencias. Si el código no existe, «Artículo no encontrado».
-- Usa: JOIN (tres veces Usuarios y LEFT JOIN), ORDER BY
-- -----------------------------------------------------------------------------
SELECT IFNULL((SELECT estado FROM Articulos WHERE codigoInventario = @codigo),
              'Artículo no encontrado') AS estadoActual;

SELECT p.fechaEntrega, p.fechaLimite, p.fechaDevolucion, p.estadoVuelta,
       CONCAT(s.nombre, ' ', s.apellidos) AS solicitante,
       te.nombre AS tecnicoEntrega, tr.nombre AS tecnicoRecoge
  FROM Articulos a
  JOIN Prestamos p      ON p.articuloId = a.articuloId
  JOIN Usuarios s       ON s.usuarioId = p.solicitanteId
  JOIN Usuarios te      ON te.usuarioId = p.tecnicoEntregaId
  LEFT JOIN Usuarios tr ON tr.usuarioId = p.tecnicoRecogeId
 WHERE a.codigoInventario = @codigo
 ORDER BY p.fechaEntrega DESC;

SELECT i.fecha, i.gravedad, i.descripcion, i.estado, i.costeEstimado, t.nombre AS tecnico
  FROM Articulos a
  JOIN Incidencias i ON i.articuloId = a.articuloId
  JOIN Usuarios t    ON t.usuarioId = i.tecnicoId
 WHERE a.codigoInventario = @codigo
 ORDER BY i.fecha DESC;

-- -----------------------------------------------------------------------------
-- RF10. Listar artículos fuera de servicio
-- Artículos en revisión o en reparación con la última incidencia que los
-- retiró, ordenados por la antigüedad de la incidencia (RN06, RN07). Un
-- artículo en revisión tras una devolución correcta no tiene incidencia.
-- Usa: JOIN (LEFT JOIN), MAX (subconsulta), ORDER BY
-- -----------------------------------------------------------------------------
SELECT a.codigoInventario, m.marca, m.nombreComercial, a.estado, a.ubicacion,
       i.fecha AS fechaIncidencia, i.gravedad, i.costeEstimado
  FROM Articulos a
  JOIN Modelos m ON m.modeloId = a.modeloId
  LEFT JOIN Incidencias i
         ON i.articuloId = a.articuloId
        AND i.fecha = (SELECT MAX(i2.fecha) FROM Incidencias i2 WHERE i2.articuloId = a.articuloId)
 WHERE a.estado IN ('EN_REVISION', 'EN_REPARACION')
 ORDER BY i.fecha IS NULL, i.fecha, a.codigoInventario;

-- -----------------------------------------------------------------------------
-- RF11. Listar solicitantes penalizados
-- Solicitantes con alguna penalización activa (RN03), con el número de
-- penalizaciones, desde cuándo y hasta cuándo. Se puede filtrar por @motivo.
-- Usa: JOIN, GROUP BY, HAVING, COUNT, MIN, MAX, ORDER BY
-- -----------------------------------------------------------------------------
SELECT u.uvus, u.nombre, u.apellidos, u.tipo,
       COUNT(*) AS penalizacionesActivas,
       MIN(pe.fechaInicio) AS desde,
       MAX(pe.fechaFin) AS hasta,
       GROUP_CONCAT(DISTINCT pe.motivo) AS motivos
  FROM Usuarios u
  JOIN Penalizaciones pe ON pe.solicitanteId = u.usuarioId
 WHERE pe.tecnicoLevantaId IS NULL AND pe.fechaInicio <= CURDATE()
   AND (@motivo IS NULL OR pe.motivo = @motivo)
 GROUP BY u.usuarioId, u.uvus, u.nombre, u.apellidos, u.tipo
HAVING MAX(pe.fechaFin) > CURDATE()
 ORDER BY hasta DESC;

-- -----------------------------------------------------------------------------
-- RF12. Consultar el ranking de modelos más demandados
-- Los 10 modelos con más préstamos del curso actual (desde el 1 de septiembre)
-- y su porcentaje de ocupación: horas prestadas entre horas posibles de todos
-- sus artículos. Las reservas canceladas o caducadas no cuentan porque nunca
-- fueron préstamos. En caso de empate, orden alfabético.
-- Usa: JOIN (LEFT JOIN), GROUP BY, COUNT, SUM, ORDER BY, LIMIT
-- -----------------------------------------------------------------------------
SELECT m.marca, m.nombreComercial,
       COUNT(p.prestamoId) AS prestamos,
       ROUND(100 * IFNULL(SUM(TIMESTAMPDIFF(HOUR, p.fechaEntrega,
                                            LEAST(IFNULL(p.fechaDevolucion, NOW()), NOW()))), 0)
             / (COUNT(DISTINCT a.articuloId) * GREATEST(TIMESTAMPDIFF(HOUR, @inicioCurso, NOW()), 1)), 1)
         AS ocupacionPorcentaje
  FROM Modelos m
  JOIN Articulos a      ON a.modeloId = m.modeloId
  LEFT JOIN Prestamos p ON p.articuloId = a.articuloId AND p.fechaEntrega >= @inicioCurso
 GROUP BY m.modeloId, m.marca, m.nombreComercial
 ORDER BY prestamos DESC, m.marca, m.nombreComercial
 LIMIT 10;

-- -----------------------------------------------------------------------------
-- RF13. Consultar el inventario por estado y categoría
-- Número de artículos y valor de compra por categoría y estado. Los artículos
-- de baja se ven por separado y no suman al valor del inventario activo.
-- Debajo, los totales: la suma coincide con el total de artículos registrados.
-- Usa: JOIN, GROUP BY, COUNT, SUM, AVG, MIN, ORDER BY
-- -----------------------------------------------------------------------------
SELECT c.nombre AS categoria, a.estado,
       COUNT(*) AS articulos,
       SUM(a.precioCompra) AS valorCompra,
       ROUND(AVG(a.precioCompra), 2) AS precioMedio,
       MIN(a.fechaAdquisicion) AS adquisicionMasAntigua
  FROM Categorias c
  JOIN Modelos m   ON m.categoriaId = c.categoriaId
  JOIN Articulos a ON a.modeloId = m.modeloId
 GROUP BY c.categoriaId, c.nombre, a.estado
 ORDER BY c.nombre, a.estado;

SELECT COUNT(*) AS totalArticulos,
       SUM(a.estado <> 'DE_BAJA') AS articulosActivos,
       SUM(a.estado = 'DE_BAJA') AS articulosDeBaja,
       SUM(IF(a.estado <> 'DE_BAJA', a.precioCompra, 0)) AS valorInventarioActivo,
       SUM(IF(a.estado = 'DE_BAJA', a.precioCompra, 0)) AS valorDadoDeBaja
  FROM Articulos a
  JOIN Modelos m ON m.modeloId = a.modeloId;
