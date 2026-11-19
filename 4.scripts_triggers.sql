-- =============================================================================
-- EquipaUS · Entregable 3 · 4.scripts_triggers.sql
-- Triggers (TRIG-01 a TRIG-15). Encima de cada uno se indica la regla de
-- negocio (RN) y las restricciones del modelo (R) que implementa; debajo, el
-- código que demuestra que funciona.
--
-- Las demostraciones usan los datos del script 5, que se carga después de este
-- script. Por eso el código de cada demostración está dentro de un
-- procedimiento (pDemoTrig01 a pDemoTrig15) que se ejecuta después de cargar
-- los datos, por ejemplo: CALL pDemoTrig03();
--   · CALL pProbar('descripción', "sentencia") ejecuta la sentencia, deshace
--     sus cambios y muestra ACEPTADA o RECHAZADA con el mensaje del trigger.
--   · Los bloques START TRANSACTION ... ROLLBACK ejecutan una operación,
--     muestran su efecto con un SELECT y la deshacen.
-- Ninguna demostración modifica los datos. Conviene ejecutarlas en las horas
-- siguientes a cargar el script 5 (las fechas de los datos son relativas al
-- momento de la carga).
-- =============================================================================

SET NAMES utf8mb4;
USE EquipaUS;

DELIMITER //

-- Variables con los identificadores de los datos de ejemplo, para que las
-- demostraciones se lean mejor. La llama cada procedimiento de demostración.
CREATE PROCEDURE pVariablesDemo()
BEGIN
  SET @paula  = (SELECT usuarioId FROM Usuarios WHERE uvus = 'PKN3387');
  SET @carlos = (SELECT usuarioId FROM Usuarios WHERE uvus = 'CMS4412');
  SET @marta  = (SELECT usuarioId FROM Usuarios WHERE uvus = 'JAP2031');  -- PDI, penalizada
  SET @javier = (SELECT usuarioId FROM Usuarios WHERE uvus = 'JPR3240');  -- técnico
  SET @lucia  = (SELECT usuarioId FROM Usuarios WHERE uvus = 'LGR5521');  -- 2 activos
  SET @luis   = (SELECT usuarioId FROM Usuarios WHERE uvus = 'LHC6610');  -- PDI
  SET @elena  = (SELECT usuarioId FROM Usuarios WHERE uvus = 'ENG4455');  -- técnica
  SET @por002 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'POR-002');  -- prestado a Lucía
  SET @cam005 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'CAM-005');  -- reservado por Paula
  SET @cam006 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'CAM-006');  -- prestado a Carlos
  SET @pry001 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'PRY-001');  -- en reparación
  SET @pry002 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'PRY-002');
  SET @vr001  = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'VR-001');   -- en revisión
  SET @vr002  = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'VR-002');
  SET @ard001 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'ARD-001');
  SET @ard002 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'ARD-002');  -- de baja
  SET @tri001 = (SELECT articuloId FROM Articulos WHERE codigoInventario = 'TRI-001');
  SET @dell   = (SELECT modeloId FROM Modelos WHERE marca = 'Dell' AND nombreComercial = 'XPS 15');
END//
-- Reserva pendiente de Paula = 6; préstamos en curso: Lucía = 6 (vencido), Carlos = 7;
-- incidencia grave del proyector = 1; penalizaciones: Marta = 1 (activa), Ana = 2 (levantada).

DELIMITER ;

-- =============================================================================
-- TRIG-01 · tArticulosBI (BEFORE INSERT ON Articulos)
-- Regla de negocio: Ciclo de vida del artículo (apartado 2.1) y RI03 · R37, R9
-- =============================================================================
DELIMITER //
CREATE TRIGGER tArticulosBI BEFORE INSERT ON Articulos FOR EACH ROW
BEGIN
  -- R37: todo artículo se da de alta en estado DISPONIBLE.
  IF NEW.estado <> 'DISPONIBLE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Todo artículo se da de alta en estado DISPONIBLE';
  END IF;
  -- R9: la fecha de adquisición no puede ser posterior a hoy.
  IF NEW.fechaAdquisicion > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La fecha de adquisición no puede ser posterior a la fecha actual';
  END IF;
END//

-- Demostración de TRIG-01. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig01();
CREATE PROCEDURE pDemoTrig01()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('R37: alta de un artículo en estado PRESTADO. Debe rechazarse',
    "INSERT INTO Articulos (modeloId, codigoInventario, numeroSerie, fechaAdquisicion, precioCompra, ubicacion, estado) VALUES (@dell, 'POR-900', 'DL-PRUEBA-900', '2025-01-01', 1599.00, 'Armario A', 'PRESTADO')");
  CALL pProbar('R9: fecha de adquisición posterior a hoy. Debe rechazarse',
    "INSERT INTO Articulos (modeloId, codigoInventario, numeroSerie, fechaAdquisicion, precioCompra, ubicacion) VALUES (@dell, 'POR-901', 'DL-PRUEBA-901', CURDATE() + INTERVAL 1 DAY, 1599.00, 'Armario A')");
  CALL pProbar('Alta correcta de un portátil. Debe aceptarse',
    "INSERT INTO Articulos (modeloId, codigoInventario, numeroSerie, fechaAdquisicion, precioCompra, ubicacion) VALUES (@dell, 'POR-902', 'DL-PRUEBA-902', '2025-01-01', 1599.00, 'Armario A')");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-02 · tArticulosBU (BEFORE UPDATE ON Articulos)
-- Regla de negocio: RN06 y ciclo de vida del artículo (apartado 2.1) · R9, R36, R38
-- =============================================================================
DELIMITER //
CREATE TRIGGER tArticulosBU BEFORE UPDATE ON Articulos FOR EACH ROW
BEGIN
  -- R9
  IF NEW.fechaAdquisicion > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La fecha de adquisición no puede ser posterior a la fecha actual';
  END IF;
  -- R38: DE_BAJA es un estado final.
  IF OLD.estado = 'DE_BAJA' AND NEW.estado <> 'DE_BAJA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'DE_BAJA es un estado final: el artículo no puede cambiar de estado';
  END IF;
  -- R36: mientras tiene un préstamo en curso, el artículo está PRESTADO
  -- (salvo que se dé de baja por pérdida, R29).
  IF NEW.estado NOT IN ('PRESTADO', 'DE_BAJA')
     AND EXISTS (SELECT 1 FROM Prestamos
                  WHERE articuloId = NEW.articuloId AND fechaDevolucion IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'El artículo tiene un préstamo en curso: su estado debe ser PRESTADO';
  END IF;
  -- R36: un artículo solo pasa a PRESTADO al entregarse en un préstamo.
  IF NEW.estado = 'PRESTADO' AND OLD.estado <> 'PRESTADO'
     AND NOT EXISTS (SELECT 1 FROM Prestamos
                      WHERE articuloId = NEW.articuloId AND fechaDevolucion IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Un artículo solo pasa a PRESTADO al registrar su préstamo';
  END IF;
END//

-- Demostración de TRIG-02. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig02();
CREATE PROCEDURE pDemoTrig02()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('R38: un artículo dado de baja vuelve a DISPONIBLE. Debe rechazarse',
    "UPDATE Articulos SET estado = 'DISPONIBLE' WHERE articuloId = @ard002");
  CALL pProbar('R36: el portátil que tiene Lucía pasa a DISPONIBLE. Debe rechazarse',
    "UPDATE Articulos SET estado = 'DISPONIBLE' WHERE articuloId = @por002");
  CALL pProbar('R36: un proyector pasa a PRESTADO sin préstamo. Debe rechazarse',
    "UPDATE Articulos SET estado = 'PRESTADO' WHERE articuloId = @pry002");
  CALL pProbar('RN06: el técnico revisa las gafas VR-001 y las deja DISPONIBLE. Debe aceptarse',
    "CALL pRevisarArticulo(@vr001)");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-15 · tArticulosBD (BEFORE DELETE ON Articulos)
-- Regla de negocio: Ciclo de vida del artículo (apartado 2.1): los artículos se dan de baja, no se borran · A02 (1..*)
-- =============================================================================
DELIMITER //
CREATE TRIGGER tArticulosBD BEFORE DELETE ON Articulos FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
    'Los artículos no se eliminan: se dan de baja (estado DE_BAJA)';
END//

-- Demostración de TRIG-15. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig15();
CREATE PROCEDURE pDemoTrig15()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('Borrar un artículo. Debe rechazarse',
    "DELETE FROM Articulos WHERE articuloId = @tri001");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-03 · tReservasBI (BEFORE INSERT ON Reservas)
-- Regla de negocio: RN01, RN02, RN03, RN05 y RN06 · R13, R22, R23, R24, R26, R27 y jerarquía (A03)
-- =============================================================================
DELIMITER //
CREATE TRIGGER tReservasBI BEFORE INSERT ON Reservas FOR EACH ROW
BEGIN
  DECLARE vEstadoArticulo VARCHAR(20) DEFAULT NULL;
  DECLARE vTipo VARCHAR(20) DEFAULT NULL;
  DECLARE vMaximo INT;
  DECLARE vHasta DATE;
  DECLARE vMensaje VARCHAR(255);

  -- A03: la reserva la realiza un solicitante.
  CALL pComprobarSolicitante(NEW.solicitanteId);

  -- R13: toda reserva nueva se crea PENDIENTE.
  IF NEW.estado <> 'PENDIENTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Toda reserva nueva se crea en estado PENDIENTE';
  END IF;

  -- R24 (RN03): un solicitante penalizado no puede reservar.
  IF fPenalizadoEn(NEW.solicitanteId, DATE(NEW.fechaCreacion)) THEN
    SELECT MAX(fechaFin) INTO vHasta FROM Penalizaciones
     WHERE solicitanteId = NEW.solicitanteId AND tecnicoLevantaId IS NULL
       AND fechaInicio <= DATE(NEW.fechaCreacion) AND fechaFin > DATE(NEW.fechaCreacion);
    SET vMensaje = CONCAT('Estás penalizado hasta el ', DATE_FORMAT(vHasta, '%d/%m/%Y'));
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vMensaje;
  END IF;

  -- R22 (RN01): máximo de reservas pendientes y préstamos en curso.
  SELECT tipo INTO vTipo FROM Usuarios WHERE usuarioId = NEW.solicitanteId;
  SET vMaximo = IF(vTipo = 'PDI', 4, 2);
  IF fNumActivos(NEW.solicitanteId) >= vMaximo THEN
    SET vMensaje = CONCAT('Has alcanzado el máximo de ', vMaximo, ' reservas y préstamos activos');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vMensaje;
  END IF;

  -- Se bloquea la fila del artículo hasta el final de la transacción: si dos
  -- personas reservan el mismo artículo a la vez, la segunda espera a que
  -- termine la primera y ya ve su reserva (RN05: solo una se confirma).
  SELECT estado INTO vEstadoArticulo FROM Articulos
   WHERE articuloId = NEW.articuloId FOR UPDATE;

  -- R27 (RN06): no se reservan artículos en revisión, en reparación o de baja.
  IF vEstadoArticulo IN ('EN_REVISION', 'EN_REPARACION', 'DE_BAJA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'El artículo no está operativo (en revisión, en reparación o de baja)';
  END IF;

  -- R23 (RN02): duración máxima del periodo reservado.
  IF TIMESTAMPDIFF(SECOND, NEW.fechaRecogida, NEW.fechaDevolucionPrevista)
     > fDuracionMaxima(NEW.solicitanteId, NEW.articuloId) * 60 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La duración supera el máximo permitido para este solicitante y este artículo';
  END IF;

  -- R26 (RN05): sin solapamiento con otra reserva pendiente o con un préstamo
  -- en curso del mismo artículo.
  IF EXISTS (SELECT 1 FROM Reservas r
              WHERE r.articuloId = NEW.articuloId AND r.estado = 'PENDIENTE'
                AND r.fechaRecogida < NEW.fechaDevolucionPrevista
                AND NEW.fechaRecogida < r.fechaDevolucionPrevista)
     OR EXISTS (SELECT 1 FROM Prestamos p
                 WHERE p.articuloId = NEW.articuloId AND p.fechaDevolucion IS NULL
                   AND p.fechaEntrega < NEW.fechaDevolucionPrevista
                   AND NEW.fechaRecogida < p.fechaLimite) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'El periodo se solapa con otra reserva o préstamo del mismo artículo';
  END IF;
END//

-- Demostración de TRIG-03. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig03();
CREATE PROCEDURE pDemoTrig03()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('RN01 (R22): Lucía ya tiene 2 reservas y préstamos activos. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@lucia, @ard001, NOW() + INTERVAL 3 DAY, NOW() + INTERVAL 4 DAY)");
  CALL pProbar('RN02 (R23): un PDI reserva gafas de RV 48 horas. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@luis, @vr002, NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 3 DAY)");
  CALL pProbar('RN03 (R24): Marta está penalizada e intenta reservar. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@marta, @pry002, NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 2 DAY)");
  CALL pProbar('RN05 (R26): Carlos reserva la cámara de Paula en fechas que se solapan. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@carlos, @cam005, NOW() + INTERVAL 2 HOUR, NOW() + INTERVAL 1 DAY + INTERVAL 2 HOUR)");
  CALL pProbar('RN06 (R27): Paula reserva un proyector en reparación. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@paula, @pry001, NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 2 DAY)");
  CALL pProbar('R13: una reserva nueva se crea ya RECOGIDA. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista, estado) VALUES (@paula, @vr002, NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 1 DAY + INTERVAL 12 HOUR, 'RECOGIDA')");
  CALL pProbar('Jerarquía (A03): un técnico intenta reservar. Debe rechazarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@javier, @vr002, NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 2 DAY)");
  CALL pProbar('RN02: un PDI reserva gafas de RV 24 horas justas. Debe aceptarse',
    "INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista) VALUES (@luis, @vr002, NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 2 DAY)");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-04 · tReservasBU (BEFORE UPDATE ON Reservas)
-- Regla de negocio: RN09 · R14, R31; además, de una reserva solo puede cambiar su estado
-- =============================================================================
DELIMITER //
CREATE TRIGGER tReservasBU BEFORE UPDATE ON Reservas FOR EACH ROW
BEGIN
  IF NEW.solicitanteId <> OLD.solicitanteId OR NEW.articuloId <> OLD.articuloId
     OR NEW.fechaCreacion <> OLD.fechaCreacion OR NEW.fechaRecogida <> OLD.fechaRecogida
     OR NEW.fechaDevolucionPrevista <> OLD.fechaDevolucionPrevista THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'De una reserva solo puede cambiar su estado; para cambiar los datos, cancélela y cree otra';
  END IF;

  IF NEW.estado <> OLD.estado THEN
    -- Una reserva solo cambia de estado mientras está PENDIENTE.
    IF OLD.estado <> 'PENDIENTE' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'Solo una reserva PENDIENTE puede cambiar de estado';
    END IF;
    -- R14: RECOGIDA si y solo si tiene un préstamo asociado.
    IF NEW.estado = 'RECOGIDA'
       AND NOT EXISTS (SELECT 1 FROM Prestamos WHERE reservaId = NEW.reservaId) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'Una reserva solo pasa a RECOGIDA al registrar su préstamo';
    END IF;
    -- R31: solo caduca si han pasado 2 horas desde la hora de recogida.
    IF NEW.estado = 'CADUCADA' AND NOW() <= OLD.fechaRecogida + INTERVAL 2 HOUR THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'La reserva aún está dentro de las 2 horas de margen para recogerla';
    END IF;
  END IF;
END//

-- Demostración de TRIG-04. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig04();
CREATE PROCEDURE pDemoTrig04()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('R14: la reserva de Paula pasa a RECOGIDA sin préstamo. Debe rechazarse',
    "UPDATE Reservas SET estado = 'RECOGIDA' WHERE reservaId = 6");
  CALL pProbar('RN09 (R31): la reserva de Paula caduca antes de las 2 horas de margen. Debe rechazarse',
    "UPDATE Reservas SET estado = 'CADUCADA' WHERE reservaId = 6");
  CALL pProbar('Cambiar la hora de recogida de una reserva. Debe rechazarse',
    "UPDATE Reservas SET fechaRecogida = fechaRecogida + INTERVAL 1 HOUR WHERE reservaId = 6");
  CALL pProbar('Paula cancela su reserva pendiente. Debe aceptarse',
    "CALL pCancelarReserva(6)");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-05 · tReservasAU (AFTER UPDATE ON Reservas)
-- Regla de negocio: RN09 · R31 (penalización por 3 reservas caducadas en el cuatrimestre)
-- =============================================================================
DELIMITER //
CREATE TRIGGER tReservasAU AFTER UPDATE ON Reservas FOR EACH ROW
BEGIN
  DECLARE vCaducadas INT;
  DECLARE vInicio DATE;
  IF NEW.estado = 'CADUCADA' AND OLD.estado <> 'CADUCADA' THEN
    SELECT COUNT(*) INTO vCaducadas FROM Reservas
     WHERE solicitanteId = NEW.solicitanteId AND estado = 'CADUCADA'
       AND fCuatrimestre(fechaRecogida) = fCuatrimestre(NEW.fechaRecogida);
    IF vCaducadas = 3 THEN
      SET vInicio = DATE(NEW.fechaRecogida + INTERVAL 2 HOUR);
      INSERT INTO Penalizaciones (solicitanteId, motivo, fechaInicio, fechaFin)
      VALUES (NEW.solicitanteId, 'RESERVAS_NO_RECOGIDAS', vInicio, vInicio + INTERVAL 7 DAY);
    END IF;
  END IF;
END//

-- Demostración de TRIG-05. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig05();
CREATE PROCEDURE pDemoTrig05()
BEGIN
  CALL pVariablesDemo();
  -- Paula no recoge tres reservas: al caducar la tercera recibe 7 días de penalización.
  START TRANSACTION;
  INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista, fechaCreacion)
  VALUES (@paula, @ard001, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 3 DAY);
  CALL pCaducarReservas();
  INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista, fechaCreacion)
  VALUES (@paula, @pry002, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 3 DAY);
  CALL pCaducarReservas();
  INSERT INTO Reservas (solicitanteId, articuloId, fechaRecogida, fechaDevolucionPrevista, fechaCreacion)
  VALUES (@paula, @tri001, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 3 DAY);
  CALL pCaducarReservas();
  -- Resultado esperado: una penalización RESERVAS_NO_RECOGIDAS de 7 días para Paula
  SELECT motivo, fechaInicio, fechaFin, DATEDIFF(fechaFin, fechaInicio) AS dias
    FROM Penalizaciones WHERE solicitanteId = @paula;
  ROLLBACK;
END//
DELIMITER ;

-- =============================================================================
-- TRIG-06 · tPrestamosBI (BEFORE INSERT ON Prestamos)
-- Regla de negocio: RN01, RN02, RN03, RN05 y RN06 · R14, R22, R23, R24, R26, R27, R31, R33, R36 y jerarquía (A05, A07)
-- =============================================================================
DELIMITER //
CREATE TRIGGER tPrestamosBI BEFORE INSERT ON Prestamos FOR EACH ROW
BEGIN
  DECLARE vEstadoArticulo VARCHAR(20) DEFAULT NULL;
  DECLARE vTipo VARCHAR(20) DEFAULT NULL;
  DECLARE vMaximo INT;
  DECLARE vHasta DATE;
  DECLARE vMensaje VARCHAR(255);
  DECLARE vReservaSolicitante INT DEFAULT NULL;
  DECLARE vReservaArticulo INT DEFAULT NULL;
  DECLARE vReservaEstado VARCHAR(20) DEFAULT NULL;
  DECLARE vReservaRecogida DATETIME DEFAULT NULL;

  -- A05 y A07: lo recibe un solicitante y lo entrega un técnico.
  CALL pComprobarSolicitante(NEW.solicitanteId);
  CALL pComprobarTecnico(NEW.tecnicoEntregaId);

  -- Un préstamo se crea en curso; la devolución se registra después (TRIG-08).
  IF NEW.fechaDevolucion IS NOT NULL OR NEW.estadoVuelta IS NOT NULL
     OR NEW.tecnicoRecogeId IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Un préstamo se crea en curso: la devolución se registra después';
  END IF;

  -- R24 (RN03): un solicitante penalizado no puede recoger material.
  IF fPenalizadoEn(NEW.solicitanteId, DATE(NEW.fechaEntrega)) THEN
    SELECT MAX(fechaFin) INTO vHasta FROM Penalizaciones
     WHERE solicitanteId = NEW.solicitanteId AND tecnicoLevantaId IS NULL
       AND fechaInicio <= DATE(NEW.fechaEntrega) AND fechaFin > DATE(NEW.fechaEntrega);
    SET vMensaje = CONCAT('Estás penalizado hasta el ', DATE_FORMAT(vHasta, '%d/%m/%Y'));
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vMensaje;
  END IF;

  -- R36 y R27 (RN06): solo se entrega un artículo DISPONIBLE. Se bloquea su
  -- fila para que no se entregue dos veces a la vez.
  SELECT estado INTO vEstadoArticulo FROM Articulos
   WHERE articuloId = NEW.articuloId FOR UPDATE;
  IF vEstadoArticulo <> 'DISPONIBLE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Solo se puede entregar un artículo en estado DISPONIBLE';
  END IF;

  -- R23 (RN02): duración máxima del préstamo.
  IF TIMESTAMPDIFF(SECOND, NEW.fechaEntrega, NEW.fechaLimite)
     > fDuracionMaxima(NEW.solicitanteId, NEW.articuloId) * 60 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La duración supera el máximo permitido para este solicitante y este artículo';
  END IF;

  IF NEW.reservaId IS NULL THEN
    -- R22 (RN01): un préstamo sin reserva suma un activo más. Si viene de una
    -- reserva no se comprueba, porque la reserva ya contaba como activa.
    SELECT tipo INTO vTipo FROM Usuarios WHERE usuarioId = NEW.solicitanteId;
    SET vMaximo = IF(vTipo = 'PDI', 4, 2);
    IF fNumActivos(NEW.solicitanteId) >= vMaximo THEN
      SET vMensaje = CONCAT('Has alcanzado el máximo de ', vMaximo, ' reservas y préstamos activos');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vMensaje;
    END IF;
  ELSE
    SELECT solicitanteId, articuloId, estado, fechaRecogida
      INTO vReservaSolicitante, vReservaArticulo, vReservaEstado, vReservaRecogida
      FROM Reservas WHERE reservaId = NEW.reservaId;
    -- R33: mismo solicitante y mismo artículo que la reserva.
    IF vReservaSolicitante <> NEW.solicitanteId OR vReservaArticulo <> NEW.articuloId THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'El préstamo debe ser del mismo solicitante y del mismo artículo que la reserva';
    END IF;
    -- R14: solo se recoge una reserva PENDIENTE.
    IF vReservaEstado <> 'PENDIENTE' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'Solo se puede recoger una reserva PENDIENTE';
    END IF;
    -- R31: pasadas 2 horas de la hora de recogida, la reserva ha caducado.
    IF NEW.fechaEntrega > vReservaRecogida + INTERVAL 2 HOUR THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'La reserva ha caducado: han pasado más de 2 horas desde la hora de recogida';
    END IF;
  END IF;

  -- R26 (RN05): sin solapamiento con reservas pendientes de otras personas ni
  -- con préstamos en curso del mismo artículo.
  IF EXISTS (SELECT 1 FROM Reservas r
              WHERE r.articuloId = NEW.articuloId AND r.estado = 'PENDIENTE'
                AND (NEW.reservaId IS NULL OR r.reservaId <> NEW.reservaId)
                AND r.fechaRecogida < NEW.fechaLimite
                AND NEW.fechaEntrega < r.fechaDevolucionPrevista)
     OR EXISTS (SELECT 1 FROM Prestamos p
                 WHERE p.articuloId = NEW.articuloId AND p.fechaDevolucion IS NULL
                   AND p.fechaEntrega < NEW.fechaLimite
                   AND NEW.fechaEntrega < p.fechaLimite) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'El periodo se solapa con otra reserva o préstamo del mismo artículo';
  END IF;
END//

-- Demostración de TRIG-06. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig06();
CREATE PROCEDURE pDemoTrig06()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('RN06 (R36): entregar el proyector en reparación. Debe rechazarse',
    "INSERT INTO Prestamos (solicitanteId, articuloId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES (@paula, @pry001, @javier, NOW(), NOW() + INTERVAL 1 DAY)");
  CALL pProbar('RN01 (R22): Lucía, con 2 activos, se lleva un kit sin reserva. Debe rechazarse',
    "INSERT INTO Prestamos (solicitanteId, articuloId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES (@lucia, @ard001, @javier, NOW(), NOW() + INTERVAL 1 DAY)");
  CALL pProbar('RN03 (R24): Marta, penalizada, se lleva un proyector. Debe rechazarse',
    "INSERT INTO Prestamos (solicitanteId, articuloId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES (@marta, @pry002, @javier, NOW(), NOW() + INTERVAL 1 DAY)");
  CALL pProbar('RN02 (R23): préstamo de gafas de RV de 48 horas. Debe rechazarse',
    "INSERT INTO Prestamos (solicitanteId, articuloId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES (@luis, @vr002, @javier, NOW(), NOW() + INTERVAL 2 DAY)");
  CALL pProbar('R33: Carlos intenta recoger la reserva de Paula. Debe rechazarse',
    "INSERT INTO Prestamos (solicitanteId, articuloId, reservaId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES (@carlos, @cam005, 6, @javier, NOW(), NOW() + INTERVAL 1 DAY)");
  CALL pProbar('Jerarquía (A07): una estudiante figura como quien entrega. Debe rechazarse',
    "INSERT INTO Prestamos (solicitanteId, articuloId, tecnicoEntregaId, fechaEntrega, fechaLimite) VALUES (@carlos, @vr002, @paula, NOW(), NOW() + INTERVAL 12 HOUR)");
  CALL pProbar('Paula recoge su reserva y Javier se la entrega. Debe aceptarse',
    "CALL pRecogerReserva(6, @javier)");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-07 · tPrestamosAI (AFTER INSERT ON Prestamos)
-- Regla de negocio: R14 y R36: al entregar, la reserva pasa a RECOGIDA y el artículo a PRESTADO
-- =============================================================================
DELIMITER //
CREATE TRIGGER tPrestamosAI AFTER INSERT ON Prestamos FOR EACH ROW
BEGIN
  -- R14: la reserva de la que procede pasa a RECOGIDA.
  IF NEW.reservaId IS NOT NULL THEN
    UPDATE Reservas SET estado = 'RECOGIDA' WHERE reservaId = NEW.reservaId;
  END IF;
  -- R36: el artículo pasa a PRESTADO.
  UPDATE Articulos SET estado = 'PRESTADO' WHERE articuloId = NEW.articuloId;
END//

-- Demostración de TRIG-07. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig07();
CREATE PROCEDURE pDemoTrig07()
BEGIN
  CALL pVariablesDemo();
  START TRANSACTION;
  CALL pRecogerReserva(6, @javier);
  -- Resultado esperado: reserva RECOGIDA y cámara PRESTADO
  SELECT r.reservaId, r.estado AS estadoReserva, a.codigoInventario, a.estado AS estadoArticulo
    FROM Reservas r JOIN Articulos a ON a.articuloId = r.articuloId
   WHERE r.reservaId = 6;
  ROLLBACK;
END//
DELIMITER ;

-- =============================================================================
-- TRIG-08 · tPrestamosBU (BEFORE UPDATE ON Prestamos)
-- Regla de negocio: R17 y jerarquía (A08); además, de un préstamo solo se registra su devolución
-- =============================================================================
DELIMITER //
CREATE TRIGGER tPrestamosBU BEFORE UPDATE ON Prestamos FOR EACH ROW
BEGIN
  IF NEW.solicitanteId <> OLD.solicitanteId OR NEW.articuloId <> OLD.articuloId
     OR NOT (NEW.reservaId <=> OLD.reservaId)
     OR NEW.tecnicoEntregaId <> OLD.tecnicoEntregaId
     OR NEW.fechaEntrega <> OLD.fechaEntrega OR NEW.fechaLimite <> OLD.fechaLimite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'De un préstamo solo se puede registrar su devolución';
  END IF;
  -- R17: la devolución (fecha, estado de vuelta y técnico) se registra una vez.
  IF OLD.fechaDevolucion IS NOT NULL
     AND (NOT (NEW.fechaDevolucion <=> OLD.fechaDevolucion)
          OR NOT (NEW.estadoVuelta <=> OLD.estadoVuelta)
          OR NOT (NEW.tecnicoRecogeId <=> OLD.tecnicoRecogeId)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La devolución de este préstamo ya está registrada';
  END IF;
  -- A08: lo recoge un técnico.
  CALL pComprobarTecnico(NEW.tecnicoRecogeId);
END//

-- Demostración de TRIG-08. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig08();
CREATE PROCEDURE pDemoTrig08()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('Alargar la fecha límite de un préstamo. Debe rechazarse',
    "UPDATE Prestamos SET fechaLimite = fechaLimite + INTERVAL 1 DAY WHERE prestamoId = 6");
  CALL pProbar('R17: volver a registrar la devolución de un préstamo ya devuelto. Debe rechazarse',
    "UPDATE Prestamos SET fechaDevolucion = NOW() WHERE prestamoId = 1");
  CALL pProbar('Jerarquía (A08): una estudiante figura como quien recoge. Debe rechazarse',
    "CALL pRegistrarDevolucion(6, @paula, 'CORRECTO')");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-09 · tPrestamosAU (AFTER UPDATE ON Prestamos)
-- Regla de negocio: RN04 y RN06 · R25, R28
-- =============================================================================
DELIMITER //
CREATE TRIGGER tPrestamosAU AFTER UPDATE ON Prestamos FOR EACH ROW
BEGIN
  DECLARE vDias INT;
  DECLARE vInicio DATE;
  DECLARE vUltimoFin DATE DEFAULT NULL;
  IF OLD.fechaDevolucion IS NULL AND NEW.fechaDevolucion IS NOT NULL THEN
    -- R28 (RN06): el artículo devuelto pasa a EN_REVISION (si se dio de baja
    -- por pérdida, sigue DE_BAJA, R38).
    UPDATE Articulos SET estado = 'EN_REVISION'
     WHERE articuloId = NEW.articuloId AND estado = 'PRESTADO';
    -- R25 (RN04): devolución tardía = penalización de 2 días por día de
    -- retraso, con un máximo de 60. Si ya estaba penalizado, empieza al
    -- terminar la última penalización.
    SET vDias = fDiasRetraso(NEW.fechaLimite, NEW.fechaDevolucion);
    IF vDias > 0 THEN
      SET vInicio = DATE(NEW.fechaDevolucion);
      SELECT MAX(fechaFin) INTO vUltimoFin FROM Penalizaciones
       WHERE solicitanteId = NEW.solicitanteId AND tecnicoLevantaId IS NULL
         AND fechaFin > vInicio;
      IF vUltimoFin IS NOT NULL THEN
        SET vInicio = vUltimoFin;
      END IF;
      INSERT INTO Penalizaciones (solicitanteId, prestamoId, motivo, fechaInicio, fechaFin)
      VALUES (NEW.solicitanteId, NEW.prestamoId, 'RETRASO', vInicio,
              vInicio + INTERVAL LEAST(2 * vDias, 60) DAY);
    END IF;
  END IF;
END//

-- Demostración de TRIG-09. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig09();
CREATE PROCEDURE pDemoTrig09()
BEGIN
  CALL pVariablesDemo();
  -- Lucía devuelve el portátil 2 días y 12 horas tarde (cuenta como 3 días).
  START TRANSACTION;
  CALL pRegistrarDevolucion(6, @elena, 'CORRECTO');
  -- Resultado esperado (R28): el portátil pasa a EN_REVISION
  SELECT codigoInventario, estado FROM Articulos WHERE articuloId = @por002;
  -- Resultado esperado (R25): penalización RETRASO de 6 días para Lucía
  SELECT motivo, fechaInicio, fechaFin, DATEDIFF(fechaFin, fechaInicio) AS dias
    FROM Penalizaciones WHERE prestamoId = 6;
  ROLLBACK;
END//
DELIMITER ;

-- =============================================================================
-- TRIG-10 · tIncidenciasBI (BEFORE INSERT ON Incidencias)
-- Regla de negocio: RI06 · R19, R34 y jerarquía (A11)
-- =============================================================================
DELIMITER //
CREATE TRIGGER tIncidenciasBI BEFORE INSERT ON Incidencias FOR EACH ROW
BEGIN
  DECLARE vPrestamoArticulo INT DEFAULT NULL;
  DECLARE vPrestamoEntrega DATETIME DEFAULT NULL;
  -- A11: la registra un técnico.
  CALL pComprobarTecnico(NEW.tecnicoId);
  IF NEW.prestamoId IS NOT NULL THEN
    SELECT articuloId, fechaEntrega INTO vPrestamoArticulo, vPrestamoEntrega
      FROM Prestamos WHERE prestamoId = NEW.prestamoId;
    -- R34: afecta al mismo artículo que el préstamo en que se detecta.
    IF vPrestamoArticulo <> NEW.articuloId THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'La incidencia debe afectar al mismo artículo que su préstamo';
    END IF;
    -- R19: no puede ser anterior a la entrega del préstamo.
    IF NEW.fecha < vPrestamoEntrega THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'La incidencia no puede ser anterior a la entrega del préstamo';
    END IF;
  END IF;
END//

-- Demostración de TRIG-10. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig10();
CREATE PROCEDURE pDemoTrig10()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('R34: incidencia del préstamo de Lucía sobre otro artículo. Debe rechazarse',
    "INSERT INTO Incidencias (articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad) VALUES (@cam005, 6, @javier, NOW(), 'Prueba', 'LEVE')");
  CALL pProbar('R19: incidencia anterior a la entrega del préstamo. Debe rechazarse',
    "INSERT INTO Incidencias (articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad) VALUES (@por002, 6, @javier, NOW() - INTERVAL 10 DAY, 'Prueba', 'LEVE')");
  CALL pProbar('Jerarquía (A11): una estudiante registra una incidencia. Debe rechazarse',
    "INSERT INTO Incidencias (articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad) VALUES (@tri001, NULL, @paula, NOW(), 'Prueba', 'LEVE')");
  CALL pProbar('Incidencia leve detectada en una revisión. Debe aceptarse',
    "INSERT INTO Incidencias (articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad) VALUES (@tri001, NULL, @elena, NOW(), 'Patas algo flojas', 'LEVE')");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-11 · tIncidenciasAI (AFTER INSERT ON Incidencias)
-- Regla de negocio: RN07 · R29
-- =============================================================================
DELIMITER //
CREATE TRIGGER tIncidenciasAI AFTER INSERT ON Incidencias FOR EACH ROW
BEGIN
  DECLARE vDias INT DEFAULT NULL;
  DECLARE vSolicitante INT DEFAULT NULL;
  IF NEW.gravedad = 'GRAVE' THEN
    UPDATE Articulos SET estado = 'EN_REPARACION' WHERE articuloId = NEW.articuloId;
    SET vDias = 30;
  ELSEIF NEW.gravedad = 'PERDIDA' THEN
    UPDATE Articulos SET estado = 'DE_BAJA' WHERE articuloId = NEW.articuloId;
    SET vDias = 90;
  END IF;
  -- Solo hay solicitante responsable si la incidencia se detecta en un préstamo.
  IF vDias IS NOT NULL AND NEW.prestamoId IS NOT NULL THEN
    SELECT solicitanteId INTO vSolicitante FROM Prestamos WHERE prestamoId = NEW.prestamoId;
    INSERT INTO Penalizaciones (solicitanteId, incidenciaId, motivo, fechaInicio, fechaFin)
    VALUES (vSolicitante, NEW.incidenciaId, 'INCIDENCIA_GRAVE_O_PERDIDA',
            DATE(NEW.fecha), DATE(NEW.fecha) + INTERVAL vDias DAY);
  END IF;
END//

-- Demostración de TRIG-11. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig11();
CREATE PROCEDURE pDemoTrig11()
BEGIN
  CALL pVariablesDemo();
  -- Carlos devuelve la cámara con la pantalla rota y se registra una incidencia grave.
  START TRANSACTION;
  CALL pRegistrarDevolucion(7, @elena, 'CON_DAÑOS');
  INSERT INTO Incidencias (articuloId, prestamoId, tecnicoId, fecha, descripcion, gravedad, costeEstimado)
  VALUES (@cam006, 7, @elena, NOW(), 'Pantalla rota', 'GRAVE', 120.00);
  -- Resultado esperado: cámara EN_REPARACION y 30 días de penalización para Carlos
  SELECT a.codigoInventario, a.estado AS estadoArticulo, u.nombre AS sancionado,
         p.motivo, DATEDIFF(p.fechaFin, p.fechaInicio) AS dias
    FROM Penalizaciones p
    JOIN Incidencias i ON i.incidenciaId = p.incidenciaId
    JOIN Articulos a   ON a.articuloId = i.articuloId
    JOIN Usuarios u    ON u.usuarioId = p.solicitanteId
   WHERE i.prestamoId = 7;
  ROLLBACK;
END//
DELIMITER ;

-- =============================================================================
-- TRIG-12 · tIncidenciasBU (BEFORE UPDATE ON Incidencias)
-- Regla de negocio: R19, R29, R34: de una incidencia solo cambian su estado, descripción, foto y coste
-- =============================================================================
DELIMITER //
CREATE TRIGGER tIncidenciasBU BEFORE UPDATE ON Incidencias FOR EACH ROW
BEGIN
  IF NEW.articuloId <> OLD.articuloId OR NOT (NEW.prestamoId <=> OLD.prestamoId)
     OR NEW.tecnicoId <> OLD.tecnicoId OR NEW.fecha <> OLD.fecha
     OR NEW.gravedad <> OLD.gravedad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'De una incidencia solo pueden cambiar su estado, descripción, foto y coste';
  END IF;
END//

-- Demostración de TRIG-12. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig12();
CREATE PROCEDURE pDemoTrig12()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('Rebajar la gravedad de la incidencia del proyector. Debe rechazarse',
    "UPDATE Incidencias SET gravedad = 'LEVE' WHERE incidenciaId = 1");
  CALL pProbar('Marcar como resuelta la incidencia del proyector. Debe aceptarse',
    "UPDATE Incidencias SET estado = 'RESUELTA', costeEstimado = 135.00 WHERE incidenciaId = 1");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-13 · tPenalizacionesBI (BEFORE INSERT ON Penalizaciones)
-- Regla de negocio: RI07 · R21, R35 y jerarquía (A12, A15)
-- =============================================================================
DELIMITER //
CREATE TRIGGER tPenalizacionesBI BEFORE INSERT ON Penalizaciones FOR EACH ROW
BEGIN
  DECLARE vResponsable INT DEFAULT NULL;
  -- A12 y A15: la recibe un solicitante y, si se levanta, lo hace un técnico.
  CALL pComprobarSolicitante(NEW.solicitanteId);
  CALL pComprobarTecnico(NEW.tecnicoLevantaId);

  -- R21: a qué va asociada según su motivo.
  IF NOT (   (NEW.motivo = 'RETRASO'
              AND NEW.prestamoId IS NOT NULL AND NEW.incidenciaId IS NULL)
          OR (NEW.motivo = 'INCIDENCIA_GRAVE_O_PERDIDA'
              AND NEW.incidenciaId IS NOT NULL AND NEW.prestamoId IS NULL)
          OR (NEW.motivo = 'RESERVAS_NO_RECOGIDAS'
              AND NEW.prestamoId IS NULL AND NEW.incidenciaId IS NULL)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La penalización no está asociada a lo que corresponde a su motivo';
  END IF;

  -- R35: el sancionado es el solicitante del préstamo que la origina,
  -- directamente o a través de la incidencia.
  IF NEW.prestamoId IS NOT NULL THEN
    SELECT solicitanteId INTO vResponsable FROM Prestamos WHERE prestamoId = NEW.prestamoId;
  ELSEIF NEW.incidenciaId IS NOT NULL THEN
    SELECT p.solicitanteId INTO vResponsable
      FROM Incidencias i JOIN Prestamos p ON p.prestamoId = i.prestamoId
     WHERE i.incidenciaId = NEW.incidenciaId;
  END IF;
  IF vResponsable IS NOT NULL AND vResponsable <> NEW.solicitanteId THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'La penalización debe recaer en el solicitante del préstamo que la origina';
  END IF;
END//

-- Demostración de TRIG-13. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig13();
CREATE PROCEDURE pDemoTrig13()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('R21: penalización por retraso sin préstamo. Debe rechazarse',
    "INSERT INTO Penalizaciones (solicitanteId, motivo, fechaInicio, fechaFin) VALUES (@paula, 'RETRASO', CURDATE(), CURDATE() + INTERVAL 2 DAY)");
  CALL pProbar('R35: penalizar a Paula por el retraso del préstamo de Lucía. Debe rechazarse',
    "INSERT INTO Penalizaciones (solicitanteId, prestamoId, motivo, fechaInicio, fechaFin) VALUES (@paula, 6, 'RETRASO', CURDATE(), CURDATE() + INTERVAL 2 DAY)");
  CALL pProbar('Jerarquía (A12): penalizar a un técnico. Debe rechazarse',
    "INSERT INTO Penalizaciones (solicitanteId, motivo, fechaInicio, fechaFin) VALUES (@javier, 'RESERVAS_NO_RECOGIDAS', CURDATE(), CURDATE() + INTERVAL 7 DAY)");
  CALL pProbar('Penalización por reservas no recogidas. Debe aceptarse',
    "INSERT INTO Penalizaciones (solicitanteId, motivo, fechaInicio, fechaFin) VALUES (@paula, 'RESERVAS_NO_RECOGIDAS', CURDATE(), CURDATE() + INTERVAL 7 DAY)");
END//
DELIMITER ;

-- =============================================================================
-- TRIG-14 · tPenalizacionesBU (BEFORE UPDATE ON Penalizaciones)
-- Regla de negocio: RI07 · R21, R35 y jerarquía (A15): de una penalización solo se registra quién la levanta
-- =============================================================================
DELIMITER //
CREATE TRIGGER tPenalizacionesBU BEFORE UPDATE ON Penalizaciones FOR EACH ROW
BEGIN
  IF NEW.solicitanteId <> OLD.solicitanteId
     OR NOT (NEW.prestamoId <=> OLD.prestamoId)
     OR NOT (NEW.incidenciaId <=> OLD.incidenciaId)
     OR NEW.motivo <> OLD.motivo
     OR NEW.fechaInicio <> OLD.fechaInicio OR NEW.fechaFin <> OLD.fechaFin THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'De una penalización solo se puede registrar el técnico que la levanta';
  END IF;
  IF OLD.tecnicoLevantaId IS NOT NULL
     AND NOT (NEW.tecnicoLevantaId <=> OLD.tecnicoLevantaId) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta penalización ya se ha levantado';
  END IF;
  -- A15
  CALL pComprobarTecnico(NEW.tecnicoLevantaId);
END//

-- Demostración de TRIG-14. Ejecutar después de cargar el script 5:
--   CALL pDemoTrig14();
CREATE PROCEDURE pDemoTrig14()
BEGIN
  CALL pVariablesDemo();
  CALL pProbar('Acortar la penalización de Marta. Debe rechazarse',
    "UPDATE Penalizaciones SET fechaFin = fechaFin - INTERVAL 10 DAY WHERE penalizacionId = 1");
  CALL pProbar('Volver a levantar la penalización de Ana. Debe rechazarse',
    "UPDATE Penalizaciones SET tecnicoLevantaId = @javier WHERE penalizacionId = 2");
  CALL pProbar('Jerarquía (A15): una estudiante levanta una penalización. Debe rechazarse',
    "CALL pLevantarPenalizacion(1, @paula)");
  -- Elena levanta la penalización de Marta: deja de estar penalizada.
  START TRANSACTION;
  SELECT fPenalizadoEn(@marta, CURDATE()) AS martaPenalizadaAntes;   -- 1
  CALL pLevantarPenalizacion(1, @elena);
  SELECT fPenalizadoEn(@marta, CURDATE()) AS martaPenalizadaDespues; -- 0
  ROLLBACK;
END//
DELIMITER ;

-- =============================================================================
-- Todas las demostraciones, para ejecutarlas de una vez después del script 5:
-- CALL pDemoTrig01(); CALL pDemoTrig02(); CALL pDemoTrig15(); CALL pDemoTrig03(); CALL pDemoTrig04(); CALL pDemoTrig05(); CALL pDemoTrig06(); CALL pDemoTrig07(); CALL pDemoTrig08(); CALL pDemoTrig09(); CALL pDemoTrig10(); CALL pDemoTrig11(); CALL pDemoTrig12(); CALL pDemoTrig13(); CALL pDemoTrig14();
-- =============================================================================
