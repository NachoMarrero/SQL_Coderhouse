USE base_gestion_comercio;

-- VISTAS
-- =========================
CREATE OR REPLACE VIEW vw_ventas_detalladas AS
SELECT
  pv.id_pedido_venta, pv.fecha,
  c.id_cliente, c.nombre AS cliente, tc.descripcion AS tipo_cliente,
  ep.descripcion AS estado,
  p.id_producto, p.nombre AS producto,
  dpv.cantidad, dpv.precio_unitario, dpv.descuento, dpv.subtotal
FROM PEDIDO_VENTA pv
JOIN CLIENTE c ON c.id_cliente = pv.id_cliente
JOIN TIPO_CLIENTE tc ON tc.id_tipo_cliente = c.id_tipo_cliente
JOIN ESTADO_PEDIDO ep ON ep.id_estado = pv.id_estado
JOIN DETALLE_PEDIDO_VENTA dpv ON dpv.id_pedido_venta = pv.id_pedido_venta
JOIN PRODUCTO p ON p.id_producto = dpv.id_producto;

CREATE OR REPLACE VIEW vw_compras_detalladas AS
SELECT
  pc.id_pedido_compra, pc.fecha,
  pr.id_proveedor, pr.nombre AS proveedor,
  ep.descripcion AS estado,
  p.id_producto, p.nombre AS producto,
  dpc.cantidad, dpc.precio_unitario, dpc.subtotal
FROM PEDIDO_COMPRA pc
JOIN PROVEEDOR pr ON pr.id_proveedor = pc.id_proveedor
JOIN ESTADO_PEDIDO ep ON ep.id_estado = pc.id_estado
JOIN DETALLE_PEDIDO_COMPRA dpc ON dpc.id_pedido_compra = pc.id_pedido_compra
JOIN PRODUCTO p ON p.id_producto = dpc.id_producto;

CREATE OR REPLACE VIEW vw_stock_bajo_minimo AS
SELECT
  p.id_producto, p.nombre AS producto,
  cp.nombre AS categoria,
  i.stock_actual, p.stock_minimo,
  (p.stock_minimo - i.stock_actual) AS faltante
FROM INVENTARIO i
JOIN PRODUCTO p ON p.id_producto = i.id_producto
JOIN CATEGORIA_PRODUCTO cp ON cp.id_categoria = p.id_categoria
WHERE i.stock_actual < p.stock_minimo;

CREATE OR REPLACE VIEW vw_totales_por_cliente AS
SELECT
  c.id_cliente, c.nombre AS cliente,
  COUNT(*) AS cant_pedidos,
  SUM(COALESCE(pv.total_neto,0)) AS total_neto_vendido
FROM CLIENTE c
LEFT JOIN PEDIDO_VENTA pv ON pv.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre;

CREATE OR REPLACE VIEW vw_totales_por_proveedor AS
SELECT
  pr.id_proveedor, pr.nombre AS proveedor,
  COUNT(*) AS cant_pedidos,
  SUM(COALESCE(pc.total,0)) AS total_comprado
FROM PROVEEDOR pr
LEFT JOIN PEDIDO_COMPRA pc ON pc.id_proveedor = pr.id_proveedor
GROUP BY pr.id_proveedor, pr.nombre;

CREATE OR REPLACE VIEW vw_productos_mas_vendidos AS
SELECT
  p.id_producto, p.nombre AS producto,
  SUM(dpv.cantidad) AS cantidad_vendida,
  SUM(dpv.subtotal) AS importe_vendido
FROM PRODUCTO p
JOIN DETALLE_PEDIDO_VENTA dpv ON dpv.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre
ORDER BY cantidad_vendida DESC;


-- FUNCIONES
-- =========================
DELIMITER $$

CREATE FUNCTION fn_stock_actual(p_id_producto INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_stock INT;
  SELECT stock_actual INTO v_stock
  FROM INVENTARIO
  WHERE id_producto = p_id_producto;
  RETURN COALESCE(v_stock,0);
END$$

CREATE FUNCTION fn_total_neto_venta(p_id_pedido_venta INT)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(10,2);
  SELECT
    COALESCE(SUM(subtotal),0) - COALESCE(SUM(descuento),0)
  INTO v_total
  FROM DETALLE_PEDIDO_VENTA
  WHERE id_pedido_venta = p_id_pedido_venta;
  RETURN COALESCE(v_total,0);
END $$

CREATE FUNCTION fn_total_compra(p_id_pedido_compra INT)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(10,2);
  SELECT COALESCE(SUM(subtotal),0)
  INTO v_total
  FROM DETALLE_PEDIDO_COMPRA
  WHERE id_pedido_compra = p_id_pedido_compra;
  RETURN COALESCE(v_total,0);
END $$

-- STORED PROCEDURES
-- =========================
CREATE PROCEDURE sp_recalcular_totales_venta(IN p_id_pedido_venta INT)
BEGIN
  UPDATE PEDIDO_VENTA
  SET
    total_bruto = (SELECT COALESCE(SUM(cantidad*precio_unitario),0) FROM DETALLE_PEDIDO_VENTA WHERE id_pedido_venta=p_id_pedido_venta),
    total_descuento = (SELECT COALESCE(SUM(descuento),0) FROM DETALLE_PEDIDO_VENTA WHERE id_pedido_venta=p_id_pedido_venta),
    total_neto = (SELECT COALESCE(SUM(subtotal),0) FROM DETALLE_PEDIDO_VENTA WHERE id_pedido_venta=p_id_pedido_venta)
  WHERE id_pedido_venta = p_id_pedido_venta;
END $$

CREATE PROCEDURE sp_recalcular_total_compra(IN p_id_pedido_compra INT)
BEGIN
  UPDATE PEDIDO_COMPRA
  SET total = (SELECT COALESCE(SUM(subtotal),0) FROM DETALLE_PEDIDO_COMPRA WHERE id_pedido_compra=p_id_pedido_compra)
  WHERE id_pedido_compra = p_id_pedido_compra;
END $$

CREATE PROCEDURE sp_cambiar_estado_pedido_venta(IN p_id_pedido_venta INT, IN p_id_estado INT)
BEGIN
  UPDATE PEDIDO_VENTA SET id_estado = p_id_estado
  WHERE id_pedido_venta = p_id_pedido_venta;
END $$

CREATE PROCEDURE sp_cambiar_estado_pedido_compra(IN p_id_pedido_compra INT, IN p_id_estado INT)
BEGIN
  UPDATE PEDIDO_COMPRA SET id_estado = p_id_estado
  WHERE id_pedido_compra = p_id_pedido_compra;
END $$

-- TRIGGERS
-- =========================
CREATE TRIGGER trg_venta_valida_stock
BEFORE INSERT ON DETALLE_PEDIDO_VENTA
FOR EACH ROW
BEGIN
  IF (SELECT stock_actual FROM INVENTARIO WHERE id_producto = NEW.id_producto) < NEW.cantidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para la venta';
  END IF;
END $$

CREATE TRIGGER trg_venta_resta_stock
AFTER INSERT ON DETALLE_PEDIDO_VENTA
FOR EACH ROW
BEGIN
  UPDATE INVENTARIO
  SET stock_actual = stock_actual - NEW.cantidad
  WHERE id_producto = NEW.id_producto;

  CALL sp_recalcular_totales_venta(NEW.id_pedido_venta);
END $$

CREATE TRIGGER trg_compra_suma_stock
AFTER INSERT ON DETALLE_PEDIDO_COMPRA
FOR EACH ROW
BEGIN
  UPDATE INVENTARIO
  SET stock_actual = stock_actual + NEW.cantidad
  WHERE id_producto = NEW.id_producto;

  CALL sp_recalcular_total_compra(NEW.id_pedido_compra);
END $$

DELIMITER ;
