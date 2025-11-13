-- Script de inicialización para Oracle Database
-- Este script debe ejecutarse en Oracle Database para producción

-- Crear tablespace para FactuMarket
CREATE TABLESPACE factumarket_data
DATAFILE 'factumarket_data01.dbf' SIZE 100M
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- Crear usuario para la aplicación
CREATE USER factumarket_user IDENTIFIED BY "ChangeMe123!"
DEFAULT TABLESPACE factumarket_data
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON factumarket_data;

-- Otorgar permisos
GRANT CONNECT, RESOURCE TO factumarket_user;
GRANT CREATE SESSION TO factumarket_user;
GRANT CREATE TABLE TO factumarket_user;
GRANT CREATE VIEW TO factumarket_user;
GRANT CREATE SEQUENCE TO factumarket_user;

-- Conectar como factumarket_user y crear tablas

-- Tabla CLIENTES
CREATE TABLE clientes (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR2(255) NOT NULL,
    identificacion VARCHAR2(50) NOT NULL UNIQUE,
    correo VARCHAR2(255) NOT NULL,
    direccion CLOB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clientes_identificacion ON clientes(identificacion);

-- Tabla FACTURAS
CREATE TABLE facturas (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id NUMBER NOT NULL,
    numero_factura VARCHAR2(50) NOT NULL UNIQUE,
    fecha_emision DATE NOT NULL,
    monto NUMBER(10, 2) NOT NULL,
    estado VARCHAR2(20) DEFAULT 'EMITIDA' NOT NULL,
    items CLOB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_facturas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT chk_monto_positive CHECK (monto > 0)
);

CREATE INDEX idx_facturas_cliente_id ON facturas(cliente_id);
CREATE INDEX idx_facturas_fecha_emision ON facturas(fecha_emision);
CREATE INDEX idx_facturas_numero ON facturas(numero_factura);

-- Trigger para actualizar updated_at en CLIENTES
CREATE OR REPLACE TRIGGER trg_clientes_updated_at
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- Trigger para actualizar updated_at en FACTURAS
CREATE OR REPLACE TRIGGER trg_facturas_updated_at
BEFORE UPDATE ON facturas
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

COMMIT;
