---------------------------------------------------------
-- CREACIÓN DE BASE DE DATOS PARA GESTION DE COMERCIO - IGNACIO MARRERO
---------------------------------------------------------

CREATE DATABASE IF NOT EXISTS base_gestion_comercio;
USE base_gestion_comercio;

---------------------------------------------------------
-- TABLA DE TIPO_CLIENTE
---------------------------------------------------------
CREATE TABLE TIPO_CLIENTE (
    id_tipo_cliente INTEGER PRIMARY KEY,
    descripcion TEXT NOT NULL
);

INSERT INTO TIPO_CLIENTE VALUES
(1, 'Minorista'),
(2, 'Mayorista');

---------------------------------------------------------
-- TABLA DE CLIENTE
---------------------------------------------------------
CREATE TABLE CLIENTE (
    id_cliente INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    razon_social TEXT,
    id_tipo_cliente INTEGER NOT NULL,
    documento TEXT,
    direccion TEXT,
    telefono TEXT,
    email TEXT,
    FOREIGN KEY (id_tipo_cliente) REFERENCES TIPO_CLIENTE(id_tipo_cliente)
);

INSERT INTO CLIENTE VALUES
(1, 'Juan Pérez', 'Almacén Pérez', 1, '45678912', 'Rivera 123', '099111222', 'juanperez@gmail.com'),
(2, 'Supermercado Centro', 'Super Centro SA', 2, '21457896', '18 de Julio 1450', '24001234', 'compras@super-centro.com'),
(3, 'Kiosco Ana', NULL, 1, '51234987', 'Agraciada 3456', '097555444', 'kioscoana@gmail.com');

---------------------------------------------------------
-- TABLA DE CATEGORIA_PRODUCTO
---------------------------------------------------------
CREATE TABLE CATEGORIA_PRODUCTO (
    id_categoria INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    descripcion TEXT
);

INSERT INTO CATEGORIA_PRODUCTO VALUES
(1, 'Bebidas', 'Gaseosas, aguas y jugos'),
(2, 'Limpieza', 'Artículos de higiene y limpieza'),
(3, 'Snacks', 'Galletitas, papas, dulces');

---------------------------------------------------------
-- TABLA DE PRODUCTO
---------------------------------------------------------
CREATE TABLE PRODUCTO (
    id_producto INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    id_categoria INTEGER NOT NULL,
    precio_unitario REAL NOT NULL,
    stock_minimo INTEGER DEFAULT 0,
    FOREIGN KEY (id_categoria) REFERENCES CATEGORIA_PRODUCTO(id_categoria)
);

INSERT INTO PRODUCTO VALUES
(1, 'Coca-Cola 2L', 'Bebida cola 2 litros', 1, 140, 10),
(2, 'Agua Salus 1L', 'Agua mineral', 1, 65, 20),
(3, 'Detergente LIMPIA+', 'Detergente multiuso', 2, 120, 5),
(4, 'Papas Lays 120g', 'Snack salado', 3, 95, 8);

---------------------------------------------------------
-- TABLA DE ESTADO_PEDIDO
---------------------------------------------------------
CREATE TABLE ESTADO_PEDIDO (
    id_estado INTEGER PRIMARY KEY,
    descripcion TEXT NOT NULL
);

INSERT INTO ESTADO_PEDIDO VALUES
(1, 'Pendiente'),
(2, 'Facturado'),
(3, 'Cancelado');

---------------------------------------------------------
-- TABLA DE PROVEEDOR
---------------------------------------------------------
CREATE TABLE PROVEEDOR (
    id_proveedor INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    razon_social TEXT,
    documento TEXT,
    direccion TEXT,
    telefono TEXT,
    email TEXT
);

INSERT INTO PROVEEDOR VALUES
(1, 'Distribuidora Norte', 'Distribuidora Norte SA', '21344566', 'Paysandú 2345', '23009922', 'ventas@norte.com'),
(2, 'Importadora XYZ', 'XYZ International', '29887766', 'Ruta 5 km 17', '222334455', 'contacto@xyz.com');

---------------------------------------------------------
-- TABLA DE PEDIDO_VENTA
---------------------------------------------------------
CREATE TABLE PEDIDO_VENTA (
    id_pedido_venta INTEGER PRIMARY KEY,
    fecha TEXT NOT NULL,
    id_cliente INTEGER NOT NULL,
    id_estado INTEGER NOT NULL,
    total_bruto REAL,
    total_descuento REAL,
    total_neto REAL,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    FOREIGN KEY (id_estado) REFERENCES ESTADO_PEDIDO(id_estado)
);

INSERT INTO PEDIDO_VENTA VALUES
(1, '2025-01-15', 1, 1, 300, 20, 280),
(2, '2025-01-20', 2, 2, 540, 0, 540);

---------------------------------------------------------
-- TABLA DE DETALLE_PEDIDO_VENTA
---------------------------------------------------------
CREATE TABLE DETALLE_PEDIDO_VENTA (
    id_pedido_venta INTEGER NOT NULL,
    id_producto INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario REAL NOT NULL,
    descuento REAL,
    subtotal REAL,
    PRIMARY KEY (id_pedido_venta, id_producto),
    FOREIGN KEY (id_pedido_venta) REFERENCES PEDIDO_VENTA(id_pedido_venta),
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto)
);

INSERT INTO DETALLE_PEDIDO_VENTA VALUES
(1, 1, 2, 140, 0, 280),
(2, 3, 3, 120, 0, 360),
(2, 4, 2, 95, 0, 190);

---------------------------------------------------------
-- TABLA DE PEDIDO_COMPRA
---------------------------------------------------------
CREATE TABLE PEDIDO_COMPRA (
    id_pedido_compra INTEGER PRIMARY KEY,
    fecha TEXT NOT NULL,
    id_proveedor INTEGER NOT NULL,
    id_estado INTEGER NOT NULL,
    total REAL,
    FOREIGN KEY (id_proveedor) REFERENCES PROVEEDOR(id_proveedor),
    FOREIGN KEY (id_estado) REFERENCES ESTADO_PEDIDO(id_estado)
);

INSERT INTO PEDIDO_COMPRA VALUES
(1, '2025-01-10', 1, 1, 1500),
(2, '2025-01-25', 2, 2, 2400);

---------------------------------------------------------
-- TABLA DE DETALLE_PEDIDO_COMPRA
---------------------------------------------------------
CREATE TABLE DETALLE_PEDIDO_COMPRA (
    id_pedido_compra INTEGER NOT NULL,
    id_producto INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario REAL NOT NULL,
    subtotal REAL,
    PRIMARY KEY (id_pedido_compra, id_producto),
    FOREIGN KEY (id_pedido_compra) REFERENCES PEDIDO_COMPRA(id_pedido_compra),
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto)
);

INSERT INTO DETALLE_PEDIDO_COMPRA VALUES
(1, 1, 20, 110, 2200),
(1, 3, 10, 90, 900),
(2, 2, 30, 50, 1500),
(2, 4, 20, 80, 1600);

---------------------------------------------------------
-- TABLA DE INVENTARIO
---------------------------------------------------------
CREATE TABLE INVENTARIO (
    id_producto INTEGER PRIMARY KEY,
    stock_actual INTEGER NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto)
);

INSERT INTO INVENTARIO VALUES
(1, 50),
(2, 120),
(3, 35),
(4, 70);