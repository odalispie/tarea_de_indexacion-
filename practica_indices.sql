-- 1. CREACIÓN DE TABLAS
CREATE TABLE clientes (
    id_cliente      SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    telefono        VARCHAR(20),
    direccion       VARCHAR(255),
    fecha_registro  DATE DEFAULT CURRENT_DATE
);

CREATE TABLE productos (
    id_producto   SERIAL PRIMARY KEY,
    nombre        VARCHAR(150) NOT NULL,
    descripcion   TEXT,
    precio        NUMERIC(10, 2) NOT NULL,
    stock         INT NOT NULL DEFAULT 0,
    categoria     VARCHAR(100)
);

CREATE TABLE compras (
    id_compra        SERIAL PRIMARY KEY,
    id_cliente       INT NOT NULL,
    id_producto      INT NOT NULL,
    cantidad         INT NOT NULL DEFAULT 1,
    precio_unitario  NUMERIC(10, 2) NOT NULL,
    total            NUMERIC(10, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    fecha_compra     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado          VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'completada', 'cancelada')),
    
    CONSTRAINT fk_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- 2. INSERCIÓN DE DATOS SIMULADOS (DATASET GRANDE)
INSERT INTO clientes (nombre, apellido, email, telefono)
SELECT 'Nombre_' || i, 'Apellido_' || i, 'cliente' || i || '@email.com', '555-' || LPAD(i::TEXT, 7, '0')
FROM generate_series(1, 10000) AS i;

INSERT INTO productos (nombre, precio, stock, categoria)
SELECT 'Producto_' || i, (random() * 1000)::NUMERIC(10, 2), (random() * 500)::INT, 
(ARRAY['Electrónica', 'Ropa', 'Alimentos', 'Hogar', 'Deportes'])[ceil(random() * 5)::INT]
FROM generate_series(1, 1000) AS i;

INSERT INTO compras (id_cliente, id_producto, cantidad, precio_unitario, fecha_compra, estado)
SELECT (random() * 9999 + 1)::INT, (random() * 999 + 1)::INT, (random() * 10 + 1)::INT, 
(random() * 1000)::NUMERIC(10, 2), NOW() - (random() * INTERVAL '2 years'), 
(ARRAY['pendiente', 'completada', 'cancelada'])[ceil(random() * 3)::INT]
FROM generate_series(1, 500000) AS i;

-- 3. CONSULTA INICIAL (SIN ÍNDICE)
-- Nota: Aquí se observa un Sequential Scan en el EXPLAIN ANALYZE
EXPLAIN ANALYZE 
SELECT * FROM compras 
WHERE id_cliente = 5420;

-- 4. CREACIÓN DEL ÍNDICE PARA OPTIMIZACIÓN
CREATE INDEX idx_compras_cliente ON compras(id_cliente);

-- 5. CONSULTA FINAL (CON ÍNDICE)
-- Nota: Aquí se observa un Index Scan, reduciendo drásticamente el tiempo de ejecución
EXPLAIN ANALYZE 
SELECT * FROM compras 
WHERE id_cliente = 5420;
